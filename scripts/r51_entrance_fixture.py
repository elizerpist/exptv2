"""Bounded optical comparison using the production widget route and a static test packet."""
import hashlib
import io
from pathlib import Path
import struct
import subprocess
import tempfile
import time

from PIL import Image, ImageDraw

PACKET = "/data/user/0/com.fluvi.app/no_backup/balance-orb-frames-v2"
REMOTE = "/data/local/tmp/r51-entrance.mp4"


def static_packet(original):
    assert hashlib.sha256(original[:-32]).digest() == original[-32:]
    version, = struct.unpack_from(">I", original)
    assert version == 2
    offset = 4
    for _ in range(3):
        length, = struct.unpack_from(">H", original, offset)
        offset += 2 + length
    size, tick, origin = struct.unpack_from(">iiq", original, offset)
    assert 32 <= size <= 256 and tick > 0 and origin > 0
    pixel = Image.new("RGBA", (size, size))
    ImageDraw.Draw(pixel).ellipse((1, 1, size - 2, size - 2), fill=(24, 251, 45, 255))
    out = io.BytesIO()
    pixel.save(out, "PNG")
    data = out.getvalue()
    body = original[:offset] + struct.pack(">iiq?ii", size, tick, origin, False, 1, len(data)) + data
    return body + hashlib.sha256(body).digest()


def write_packet(device, work, data, widget):
    local = work / "packet"
    local.write_bytes(data)
    device.adb("push", local, "/data/local/tmp/r51-packet")
    device.shell(f"cat /data/local/tmp/r51-packet > {PACKET}; rm /data/local/tmp/r51-packet")
    device.shell("am", "broadcast", "-a", "android.appwidget.action.APPWIDGET_UPDATE",
                 "-n", "com.fluvi.app/.widget.orb.FluviHeaderOrbWidgetProvider",
                 "--eia", "appWidgetIds", widget)
    assert device.adb("exec-out", "cat", PACKET) == data


def metrics(image):
    width, height = image.size
    interior = []
    green = 0
    for index, (r, g, b) in enumerate(image.getdata()):
        if g >= r + 32 and g >= b + 32:
            green += 1
        x, y = index % width + .5 - width / 2, index // width + .5 - height / 2
        if (x / width) ** 2 + (y / height) ** 2 < .055:
            interior.append(max(0, g - max(r, b)))
    return sum(interior) / len(interior), green


def sample_video(device, path, bounds, size, name):
    x, y, r, b = bounds
    width, height = size
    w, h = r - x, b - y
    # Explicit RGBA→RGB scaling is fixed across baseline and candidate. Save a
    # cropped stream and every sample's color/coverage, including empty frames.
    crop = f"scale={width}:{height}:flags=bilinear,crop={w}:{h}:{x}:{y}:exact=1"
    frame_bytes = subprocess.check_output([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path), "-vf", crop,
        "-fps_mode", "passthrough", "-pix_fmt", "rgb24", "-f", "rawvideo", "-",
    ], timeout=30)
    stamps = [line.strip().split(",")[0] for line in subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
        "frame=best_effort_timestamp_time", "-of", "csv=p=0", str(path),
    ], text=True).splitlines() if line.strip() and line.split(",")[0].strip()]
    frames = [Image.frombytes("RGB", (w, h), frame_bytes[i:i+3*w*h])
              for i in range(0, len(frame_bytes), 3*w*h)]
    assert len(frames) == len(stamps) and len(frames) >= 5, (len(frames), len(stamps))
    values = [metrics(image) for image in frames]
    end = max(brightness for brightness, _ in values)
    peak = max(area for _, area in values)
    assert end > 140 and peak > w*h*.55, ("No static reference-sized green ORB", end, peak)
    text = "frame,pts_seconds,interior_green_difference,green_pixels\n" + "".join(
        f"{n},{stamps[n]},{v[0]:.2f},{v[1]}\n" for n,v in enumerate(values)
    )
    device.save(name + "-pixels.csv", text.encode())
    # The recorder starts on an assigned ON display. Identify the absence
    # interval before the subsequent wake rather than scoring pre-roll.
    idle = next((i for i, (p,_) in enumerate(values) if p < 8), None)
    assert idle is not None, "No pre-entrance absence in the recorded strip"
    first = next((i for i, (p,_) in enumerate(values) if i > idle and p > 14), None)
    assert first is not None, "No post-absence ORB frame"
    full = next(i for i,(p,_) in enumerate(values) if i >= first and p >= end * .94)
    for i in range(max(0, first - 1), min(full + 2, len(frames))):
        frames[i].save(device.output / f"{name}-orb-{i:03d}.png")
    device.note(f"{name} video frames={len(values)} first={first} full={full} samples={values[first:full+1]}")
    assert any(v[0] < 8 for v in values[:first]), "Missing pre-entrance negative video sample"
    return [(brightness / end, area / peak) for brightness, area in values[first:full+1]]


def collect(device, r51, mode, name, work, bounds, size):
    device.shell("settings", "put", "global", "animator_duration_scale", mode)
    device.shell("rm", "-f", REMOTE)
    process = subprocess.Popen(["adb", "shell", "screenrecord", "--time-limit", "20",
                                "--size", "720x1600", "--bit-rate", "6000000", REMOTE],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    try:
        end = time.monotonic() + 4
        while time.monotonic() < end and process.poll() is None:
            if device.shell(f"test -s {REMOTE} && echo ready") == "ready":
                break
            time.sleep(.1)
        assert process.poll() is None, process.communicate()[0].decode(errors="replace")
        device.shell("input", "keyevent", "KEYCODE_SLEEP")
        r51.poll_state(device, name + "-sleep", "OFF", True)
        r51.wake(device, name + "-wake")
        raw, _ = process.communicate(timeout=24)
        assert process.returncode == 0, raw.decode(errors="replace")
    finally:
        if process.poll() is None:
            process.terminate()
            process.communicate(timeout=3)
    movie = work / (name + ".mp4")
    device.adb("pull", REMOTE, movie)
    device.shell("rm", "-f", REMOTE)
    return sample_video(device, movie, bounds, size, name)


def exercise(device, r51, widget, is_baseline):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.type") in ("eng", "userdebug")
    device.adb("root")
    device.adb("wait-for-device")
    assert device.shell("id", "-u") == "0"
    old_scale = device.shell("settings", "get", "global", "animator_duration_scale")
    original = device.adb("exec-out", "cat", PACKET)
    static = static_packet(original)
    with tempfile.TemporaryDirectory() as temp:
        work = Path(temp)
        try:
            write_packet(device, work, static, widget)
            device.shell("input", "keyevent", "KEYCODE_SLEEP")
            r51.poll_state(device, "static-pre-sleep", "OFF", True)
            reference, bounds = r51.wake(device, "static-reference")
            assert metrics(reference.crop(bounds))[0] > 140
            ramp = collect(device, r51, "1", "animator-1x", work, bounds, reference.size)
            off = collect(device, r51, "0", "animator-off", work, bounds, reference.size)
            assert all(brightness >= .88 for brightness, _ in off), f"Animator-off first visible samples: {off}"
            intermediate = [(p,a) for p,a in ramp if .10 < p < .90]
            if is_baseline:
                assert not intermediate, f"Unexpected baseline ramp in {ramp}"
                device.note("RED installed R50 static packet has no sampled WA entrance ramp")
            else:
                assert len(intermediate) >= 2, f"Fade samples did not establish progression: {ramp}"
                assert all(a <= b + .07 for (a,_),(b,_) in zip(ramp,ramp[1:])), ramp
                assert ramp[-1][1] > ramp[0][1] or ramp[0][0] < .2, ramp
                device.note("PASS visible WA entrance progression and animator-off control")
        finally:
            write_packet(device, work, original, widget)
            if old_scale == "null":
                device.shell("settings", "delete", "global", "animator_duration_scale")
            else:
                device.shell("settings", "put", "global", "animator_duration_scale", old_scale)

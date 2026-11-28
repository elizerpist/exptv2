"""Verify the installed lockscreen mask against the exact live Balance packet."""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import struct
import subprocess
import time
import xml.etree.ElementTree as ET
from PIL import Image

import r52_measure as measure

PKG = measure.PKG
DATA = "/data/user/0/" + PKG
PREFS = DATA + "/shared_prefs/fluvi_balance_orb.xml"
PACKET = DATA + "/no_backup/balance-orb-frames-v2"
PALETTES = DATA + "/shared_prefs/dashboard_presentation.xml"


def prefs(device):
    return {node.attrib["name"]: node.get("value", node.text)
            for node in ET.fromstring(device.adb("exec-out", "cat", PREFS))}


def settings(device):
    device.shell("am", "start", "-W", "-n", measure.r51.ACTIVITY)
    current = measure.r51.stock.visible_labels(device.screen(), PKG)
    if "1×1 (56 dp)" not in current:
        if "Debug Console" in current:
            device.shell("input", "keyevent", "KEYCODE_BACK")
        measure.r51.stock.enter_settings(device)


def select_style(device, dp, style):
    label = ("1×1" if dp == 56 else "2×2") + " · " + ("ORB" if style == "orb" else "Fluvi maszk")
    before = prefs(device)
    device.click(label, package=PKG)
    until = time.monotonic() + 5
    while time.monotonic() < until:
        after = prefs(device)
        if after.get(f"style{dp}", "orb") == style:
            preserved = "sizeDp", "active", "epoch", "pending", "pendingCode"
            assert all(after.get(key) == before.get(key) for key in preserved), (before, after)
            device.note(f"STYLE {dp} {style} same active size={after['sizeDp']} widget ID={after['active']}")
            return
        time.sleep(.1)
    raise AssertionError(f"Style {label} did not persist")


def packet(device):
    raw = device.adb("exec-out", "cat", PACKET)
    body = raw[:-32]
    assert hashlib.sha256(body).digest() == raw[-32:]
    data = BytesIO(body)

    def read(types):
        return struct.unpack(types, data.read(struct.calcsize(types)))

    assert read(">I")[0] == 2
    key, epoch, generation = [data.read(read(">H")[0]).decode() for _ in range(3)]
    size, interval, origin, animated, count = read(">IIQ?I")
    assert animated and count >= 3
    frames = []
    for _ in range(count):
        source = data.read(read(">I")[0])
        with Image.open(BytesIO(source)) as im:
            assert im.size == (size, size)
            frames.append(im.convert("RGB"))
    assert not data.read()
    return dict(key=key, epoch=epoch, generation=generation, size=size, interval=interval, origin=origin), frames


def pixels(image, points):
    w, h = image.size
    return [image.getpixel((round((x + .5) * w / 640 - .5), round((y + .5) * h / 640 - .5)))[:3]
            for x, y in points]


def mae(left, right):
    return sum(abs(a - b) for p, q in zip(left, right) for a, b in zip(p, q)) / (3 * len(left))


def areas(asset):
    alpha = asset.getchannel("A")
    radius = 7
    strokes = []
    for a, b in ((158, 240), (344, 490)):
        candidates = [(x, y) for y in range(a, b, 11) for x in range(174, 466, 11)]
        points = [(x, y) for x, y in candidates if alpha.crop(
            (x - radius, y - radius, x + radius + 1, y + radius + 1)).getextrema() == (0, 0)]
        assert len(points) > 40, len(points)
        strokes.append(points)
    gap = [(x, 270) for x in (250, 280, 320, 350, 380)]
    corners = [(24, 24), (616, 24), (24, 616), (616, 616)]
    assert all(asset.getpixel(p) == (240, 240, 240, 255) for p in gap)
    assert all(alpha.getpixel(p) == 0 for p in corners)
    return strokes, gap, corners


def inspect_case(device, dp, expected, name, asset, palette_reference=None):
    current = prefs(device)
    assert int(current["sizeDp"]) == dp and current.get(f"style{dp}", "orb") == expected
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    measure.independent_state(device, name + "-sleep", measure.sleeping)
    device.shell("input", "keyevent", "KEYCODE_WAKEUP")
    measure.r51.poll_state(device, name + "-locked", "ON", True)
    image, bounds = device.observe_orb(name, limit=12)
    density = int(re.findall(r"\d+", device.shell("wm", "density").splitlines()[-1])[-1])
    assert bounds[2] - bounds[0] == round(dp * density / 160), (name, bounds, density)
    assert bounds[3] - bounds[1] == bounds[2] - bounds[0]
    points, gap, corners = areas(asset)
    identity, frames = packet(device)
    size = image.crop(bounds).size
    references = [frame.resize(size, Image.Resampling.BILINEAR) for frame in frames]
    inputs = [[pixels(frame, area) for area in points] for frame in references]
    photos = []
    for index in range(5):
        raw = device.adb("exec-out", "screencap", "-p")
        with Image.open(BytesIO(raw)) as screen:
            photo = screen.convert("RGB").crop(bounds)
        photo.save(device.output / f"{name}-crop-{index}.png")
        visible_strokes = [pixels(photo, area) for area in points]
        score = [[mae(observed, reference) for observed, reference in zip(visible_strokes, pair)]
                 for pair in inputs]
        best = min(range(len(score)), key=lambda i: max(score[i]))
        gap_pixels = pixels(photo, gap)
        matte = all(all(abs(channel - 240) <= 2 for channel in rgb) for rgb in gap_pixels)
        row = dict(frame=best, stroke_mae=score[best], gap=gap_pixels, corners=pixels(photo, corners))
        photos.append((row, visible_strokes, matte))
        time.sleep(.061 + .017 * index)
    device.save(name + "-windows-after.txt", device.adb("shell", "dumpsys", "window", "windows"))
    assert measure.r51.system_state(device, name + "-main-after") == ("ON", "true", "true")
    verify = dict(route=expected, sizeDp=dp, frame_packet=identity, bounds=bounds,
                  photos=[p[0] for p in photos])
    report = device.output / (name + "-mask-report.json")
    report.write_text(json.dumps(verify, indent=2) + "\n")
    assert all(matte == (expected == "fluviMask") for _, _, matte in photos), verify
    good = [photo for photo in photos if max(photo[0]["stroke_mae"]) <= 14]
    assert len(good) >= 2, f"{name} no two observed phases match one live packet frame in both openings"
    sample = next(((a,b) for i, a in enumerate(good) for b in good[i+1:]
                   if a[0]["frame"] != b[0]["frame"] and
                   all(mae(x,y) >= .35 for x,y in zip(a[1], b[1]))), None)
    assert sample, f"{name} both openings need distinct motion samples"
    # Screen pixels at the transparent corners must stay independent of the
    # moving frames. Coverage of the PNG and the active root are independent.
    a, b = sample
    assert mae(a[0]["corners"], b[0]["corners"]) <= 1.5, (name, a[0], b[0])
    if palette_reference is not None:
        assert identity["generation"] != palette_reference[0]["generation"]
        assert all(mae(x,y) >= 8 for x,y in zip(good[0][1], palette_reference[1]))
    verify["accepted_frames"] = [a[0], b[0]]
    report.write_text(json.dumps(verify, indent=2) + "\n")
    device.note(f"PASS {name} {expected} {dp}dp both strokes matched live frames {a[0]['frame']}/{b[0]['frame']}")
    measure.home(device)
    return identity, good[0][1]


def change_palette(device, old):
    # Only this disposable test phone is rooted. Change the ordinary saved
    # Balance palette input, then let the actual dashboard publish new frames.
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("id", "-u") == "0"
    device.shell("am", "force-stop", PKG)
    result = subprocess.run(["adb", "exec-out", "cat", PALETTES], check=False, capture_output=True)
    root = ET.fromstring(result.stdout) if result.returncode == 0 and result.stdout else ET.Element("map")
    before = next((node for node in root if node.get("name") == "balanceHeaderPalette"), None)
    old_palette = int(before.get("value")) if before is not None else 0
    new_palette = 4 if old_palette != 4 else 8
    if before is not None:
        root.remove(before)
    ET.SubElement(root, "int", {"name": "balanceHeaderPalette", "value": str(new_palette)})
    file = device.output / "palette-fixture.xml"
    file.write_bytes(ET.tostring(root, encoding="utf-8"))
    owner = device.shell("stat", "-c", "%u:%g", DATA)
    assert re.fullmatch(r"\d+:\d+", owner)
    device.adb("push", file, "/data/local/tmp/r52-palette.xml")
    device.shell(f"cat /data/local/tmp/r52-palette.xml > {PALETTES} && chown {owner} {PALETTES} && chmod 660 {PALETTES} && restorecon {PALETTES}")
    device.shell("am", "start", "-W", "-n", measure.r51.ACTIVITY)
    assert device.service_connected()
    until = time.monotonic() + 40
    while time.monotonic() < until:
        header, _ = packet(device)
        if header["key"] != old["key"]:
            device.note(f"Balance palette {old_palette} -> {new_palette} published generation {header['generation']}")
            return
        time.sleep(.5)
    raise AssertionError("New saved palette never produced a new real Balance packet")


def exercise(device, args):
    device.adb("root")
    device.adb("wait-for-device")
    args.api = "37.0"
    measure.prepare(device, args)
    with Image.open(args.mask) as png:
        asset = png.convert("RGBA")
    assert asset.size == (640, 640)
    settings(device)
    select_style(device, 56, "fluviMask")
    inspect_case(device, 112, "orb", "112-plain", asset)
    settings(device)
    device.click("1×1 (56 dp)", package=PKG)
    inspect_case(device, 56, "fluviMask", "56-mask", asset)
    settings(device)
    select_style(device, 56, "orb")
    inspect_case(device, 56, "orb", "56-restored-plain", asset)
    settings(device)
    select_style(device, 112, "fluviMask")
    old = prefs(device)
    assert old["sizeDp"] == "56" and old["style56"] == "orb" and old["style112"] == "fluviMask"
    previous = set(device.shell("pidof", PKG).split())
    device.shell("am", "force-stop", PKG)
    settings(device)
    assert device.service_connected()
    assert previous.isdisjoint(device.shell("pidof", PKG).split())
    assert all(prefs(device).get(key) == old[key] for key in ("sizeDp", "style56", "style112", "active"))
    device.note("PASS different styles restored after real process and accessibility-service restart")
    device.click("2×2 (112 dp)", package=PKG)
    reference = inspect_case(device, 112, "fluviMask", "112-mask", asset)
    change_palette(device, reference[0])
    inspect_case(device, 112, "fluviMask", "112-mask-second-palette", asset, reference)
    settings(device)
    select_style(device, 112, "orb")
    inspect_case(device, 112, "orb", "112-restored-full", asset)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--mask", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    device = measure.r51.Device(args.output)
    try:
        exercise(device, args)
    except Exception as error:
        device.note(f"FAIL mask: {error}")
        device.save("first-mask-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

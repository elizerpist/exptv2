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
    # The default 32 px material differs by only a few levels per phase.
    # Require distinct packet frames and changed pixels in both regions.
    # The separate palette control below supplies the visibly different
    # live output and requires an eight-level difference in both strokes.
    sample = next(((a,b) for i, a in enumerate(good) for b in good[i+1:]
                   if a[0]["frame"] != b[0]["frame"] and
                   all(x != y for x,y in zip(a[1], b[1]))), None)
    assert sample, f"{name} both openings need distinct motion samples"
    # Screen pixels at the transparent corners must stay independent of the
    # moving frames. Coverage of the PNG and the active root are independent.
    a, b = sample
    assert mae(a[0]["corners"], b[0]["corners"]) <= 1.5, (name, a[0], b[0])
    if palette_reference is not None:
        assert identity["generation"] != palette_reference[0]["generation"]
        assert all(mae(x,y) >= 8 for x,y in zip(good[0][1], palette_reference[1]))
    verify["accepted_frames"] = [a[0], b[0]]
    verify["phase_mae"] = [mae(x, y) for x, y in zip(a[1], b[1])]
    if palette_reference is not None:
        verify["palette_mae"] = [mae(x,y) for x,y in zip(good[0][1], palette_reference[1])]
    report.write_text(json.dumps(verify, indent=2) + "\n")
    device.note(f"PASS {name} {expected} {dp}dp both strokes matched live frames {a[0]['frame']}/{b[0]['frame']}")
    measure.home(device)
    return identity, good[0][1]


def change_palette(device, old):
    # Exercise the installed app's actual foreground control. A preferences
    # edit and process death do not drive the Flutter tuning listener.
    device.shell("am", "start", "-W", "-n", measure.r51.ACTIVITY)
    tuner = "Header látványhangoló"
    for step in range(4):
        if device.click(tuner, optional=True, limit=5, package=PKG):
            break
        visible = measure.r51.stock.visible_labels(device.screen(), PKG)
        assert any(label in visible for label in (
            "1×1 (56 dp)", "Zárképernyő", "Beállítások", "Settings",
        )), visible
        device.shell("input", "keyevent", "KEYCODE_BACK")
        time.sleep(.35)
    else:
        raise AssertionError("The header tuner was absent on the dashboard")

    def expose(label):
        for index in range(12):
            raw = device.screen()
            device.save(f"tuner-{label.split()[0]}-{index:02d}.xml", raw)
            nodes = list(ET.fromstring(raw).iter("node"))
            if label in measure.r51.stock.visible_labels(raw, PKG):
                return
            bounds = [
                tuple(map(int, re.findall(r"-?\d+", n.get("bounds", ""))))
                for n in nodes
                if n.get("scrollable") == "true" and n.get("visible") == "true"
                and n.get("package") == PKG
            ]
            panels = [(a, b, c, d) for a, b, c, d in bounds if c - a > 150 and d - b > 215]
            assert panels, f"No scroll viewport in the foreground tuner for {label}"
            a, b, c, d = max(panels, key=lambda p: (p[3], p[2] - p[0]))
            x = (a + c) // 2
            device.shell("input", "swipe", x, b + (d - b)*4//5, x, b + (d - b)//5, 380)
            time.sleep(.3)
        raise AssertionError(f"Did not expose {label!r} in the foreground tuner")

    expose("Header animáció")
    device.click("Header animáció", package=PKG)
    expose("Soft rainbow")
    device.click("Soft rainbow", package=PKG)
    device.save("palette-options.xml", device.screen())
    device.click("Balance diverging", package=PKG, limit=10)
    device.save("palette-selected.xml", device.screen())
    visible = measure.r51.stock.visible_labels(device.screen(), PKG)
    assert "Balance diverging" in visible, visible
    until = time.monotonic() + 45
    while time.monotonic() < until:
        try:
            header, _ = packet(device)
        except (AssertionError, subprocess.SubprocessError, ValueError):
            time.sleep(.5)
            continue
        if header["key"] != old["key"]:
            picked = ET.fromstring(device.adb("exec-out", "cat", PALETTES))
            assert any(e.get("name") == "balanceHeaderPalette" and e.get("value") == "4"
                       for e in picked), "Selector change was not persisted"
            device.note(f"Balance palette 0 → 4 published generation {header['generation']}")
            return
        time.sleep(.5)
    raise AssertionError("Foreground palette selection produced no new Balance packet")



def exercise(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    from upgrade import open_dashboard, wait_for_root
    wait_for_root(device)
    args.api = "37.0"
    measure.prepare(device, args)
    with Image.open(args.mask) as png:
        asset = png.convert("RGBA")
    assert asset.size == (640, 640)
    failures = []

    def confirm(name, dp, style, palette=None):
        try:
            return inspect_case(device, dp, style, name, asset, palette)
        except measure.EXPERIMENT_FAILURES as error:
            failures.append(f"{name}: {error}")
            device.note(f"FAIL {name}: {error}")
            measure.home(device)
            return None

    settings(device)
    device.click("1×1 (56 dp)", package=PKG)
    select_style(device, 56, "fluviMask")
    select_style(device, 56, "orb")
    select_style(device, 112, "fluviMask")
    old = prefs(device)
    assert old["sizeDp"] == "56" and old["style56"] == "orb" and old["style112"] == "fluviMask"
    previous = set(device.shell("pidof", PKG).split())
    assert len(previous) == 1 and all(value.isdigit() for value in previous)
    device.shell("kill", "-KILL", next(iter(previous)))
    open_dashboard(device, "mask-restart-ready")
    settings(device)
    assert device.service_connected()
    assert previous.isdisjoint(device.shell("pidof", PKG).split())
    assert all(prefs(device).get(key) == old[key] for key in ("sizeDp", "style56", "style112", "active"))
    device.note("PASS different styles restored after real process and accessibility-service restart")
    device.click("2×2 (112 dp)", package=PKG)
    reference = confirm("112-mask", 112, "fluviMask")
    try:
        change_palette(device, reference[0] if reference else packet(device)[0])
        confirm("112-mask-second-palette", 112, "fluviMask", reference)
    except measure.EXPERIMENT_FAILURES as error:
        failures.append(f"saved palette change: {error}")
        device.note(f"FAIL saved palette change: {error}")
    settings(device)
    select_style(device, 112, "orb")
    confirm("112-restored-full", 112, "orb")
    assert not failures, failures


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

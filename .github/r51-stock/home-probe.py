"""One independent Home Balance provider smoke on the signed R51 APK."""
import argparse
import importlib.util
from pathlib import Path
import re
import time
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location("r51", Path("scripts/test-r51-orb-transitions.py"))
r51 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r51)


def preview_node(device):
    until = time.monotonic() + 8
    while time.monotonic() < until:
        raw = device.screen()
        device.save("home-widget-list.xml", raw)
        for node in ET.fromstring(raw).iter("node"):
            if node.get("visible") == "true" and any(
                "Fluvi · Élő orb" in node.get(key, "") for key in ("text", "content-desc")
            ):
                return node
    raise AssertionError("The launcher returned no exact Fluvi live home ORB preview")


def exercise(device, apk, observer):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    assert b"Success" in device.adb("install", apk, timeout=90)
    assert b"Success" in device.adb("install", observer, timeout=30)
    device.shell("wm", "dismiss-keyguard")
    device.shell("input", "keyevent", "KEYCODE_HOME")
    r51.poll_state(device, "launcher-preflight", "ON", False)
    size = device.shell("wm", "size").splitlines()[-1]
    w, h = map(int, re.findall(r"\d+", size)[-2:])
    device.shell("input", "swipe", w//2, h//4, w//2, h//4, 900)
    device.click("Widgets")
    device.click("Browse widgets", "Browse")
    device.click("Search", optional=True, limit=5)
    device.shell("input", "text", "Fluvi")
    # The launcher groups matching providers under the application.
    device.click("Fluvi", optional=True, limit=5)
    preview = preview_node(device)
    a,b,c,d = map(int, re.findall(r"-?\d+", preview.get("bounds")))
    assert a < c and b < d
    device.shell("input", "tap", (a+c)//2, (b+d)//2)
    if not device.click("Add", "Add widget", optional=True, limit=4):
        device.shell("input", "draganddrop", (a+c)//2, (b+d)//2, w//2, h//3, 900)
    until = time.monotonic() + 10
    while time.monotonic() < until:
        ui = device.screen()
        device.save("home-widget-config.xml", ui)
        labels = r51.stock.visible_labels(ui, r51.PKG)
        if "Orb beállításai" in labels and "Balance" in labels:
            break
    else:
        raise AssertionError("Native home-widget configuration did not reach its default Balance")
    if not device.click("Orb hozzáadása", package=r51.PKG, optional=True, limit=4):
        device.shell("input", "swipe", w//2, h*4//5, w//2, h//3, 450)
        device.click("Orb hozzáadása", package=r51.PKG, limit=6)
    widgets = device.adb("shell", "dumpsys", "appwidget")
    device.save("launcher-widgets.txt", widgets)
    owners = re.findall(rb"(?m)^  \[\d+\] id=(\d+)\n(.*?)(?=^  \[|^Hosts:)", widgets, re.S)
    assert any(b"launcher" in row and
               b"com.fluvi.app.widget.orb.FluviOrbWidgetProvider" in row for _, row in owners), owners
    image, _ = device.capture("home-balance")
    device.save("home-balance-view.xml", device.screen(interactive_windows=True))
    assert image.width == w and image.height == h
    device.note("PASS real launcher host bound the existing home provider in Balance mode")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--observer", type=Path, required=True)
    args = parser.parse_args()
    device = r51.Device(args.output)
    try:
        exercise(device, args.apk, args.observer)
    except Exception as failure:
        device.note(f"FAIL home smoke: {failure}")
        device.save("first-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

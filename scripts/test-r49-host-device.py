#!/usr/bin/env python3
"""Stock emulator setup control using ordinary Android UI consent."""
import argparse
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

PACKAGE = "com.fluvi.app"
WA = "tk.zwander.lockscreenwidgets"
SERVICE = f"{PACKAGE}/{WA}.services.Accessibility"
ORB = "Fluvi · Aktuális header ORB"


class Device:
    def __init__(self, output):
        self.output = output
        output.mkdir(parents=True, exist_ok=True)
        self.steps = []

    def adb(self, *args, timeout=25):
        return subprocess.check_output(["adb", *map(str, args)], timeout=timeout)

    def shell(self, *args, timeout=25):
        return self.adb("shell", *args, timeout=timeout).decode(errors="replace").strip()

    def save(self, name, content):
        (self.output / name).write_bytes(content)

    def screen(self):
        xml = "/data/local/tmp/fluvi-r49-ui.xml"
        self.shell("uiautomator", "dump", xml, timeout=8)
        return self.adb("exec-out", "cat", xml)

    def note(self, name):
        self.steps.append(name)
        (self.output / "steps.txt").write_text("\n".join(self.steps) + "\n")
        print(name, flush=True)

    def click(self, label, *alternatives, optional=False, limit=10):
        names = {value.casefold() for value in (label, *alternatives)}
        end = time.monotonic() + limit
        while time.monotonic() < end:
            try:
                raw = self.screen()
            except (subprocess.SubprocessError, OSError):
                continue
            root = ET.fromstring(raw)
            for node in root.iter("node"):
                if {node.get("text", "").casefold(), node.get("content-desc", "").casefold()} & names:
                    a, b, c, d = map(int, re.findall(r"\d+", node.attrib["bounds"]))
                    if a == c or b == d:
                        continue
                    self.shell("input", "tap", (a + c) // 2, (b + d) // 2)
                    self.note("CLICK " + label)
                    return True
            self.save("latest-ui.xml", raw)
            time.sleep(0.4)
        if not optional:
            raise AssertionError(f"UI did not reach {label!r} within {limit}s")
        return False

    def service_connected(self):
        end = time.monotonic() + 30
        while time.monotonic() < end:
            state = self.adb("shell", "dumpsys", "accessibility")
            self.save("accessibility.txt", state)
            lines = [line for line in state.decode().splitlines() if "boundServices" in line]
            if any(WA + ".services.Accessibility" in line for line in lines):
                return True
            time.sleep(1)
        return False

    def settings_consent(self):
        self.click("Accessibility Settings")
        self.click("Widgets Anywhere", "Fluvi")
        self.click("Use Widgets Anywhere", "Use Fluvi")
        self.click("Allow", "OK")
        enabled = self.shell("settings", "get", "secure", "enabled_accessibility_services")
        assert SERVICE in enabled.split(":"), "The exact component was not consented"
        assert self.service_connected(), "Service connection was not observed"
        self.note("Normal accessibility consent and bound service observed")
        self.shell("input", "keyevent", "KEYCODE_BACK")
        self.shell("input", "keyevent", "KEYCODE_BACK")

    def crop(self, name):
        self.save(name + ".png", self.adb("exec-out", "screencap", "-p"))
        self.save(name + "-windows.txt", self.adb("shell", "dumpsys", "window", "windows"))
        self.save(name + "-widgets.txt", self.adb("shell", "dumpsys", "appwidget"))


def exercise(device, apk, system, control_apk):
    expected_api = system.split(".")[0]
    actual = device.shell("getprop", "ro.build.version.sdk")
    assert actual == expected_api, (actual, expected_api)
    assert "package:" not in device.shell("pm", "path", WA), "Standalone WA is installed"
    assert "package:" not in device.shell("pm", "path", PACKAGE), "Expected a fresh emulator profile"
    device.note(f"STOCK API {actual} {device.shell('getprop', 'ro.build.fingerprint')}")
    device.note(device.adb("install", apk, timeout=90).decode().strip())
    if control_apk:
        device.note(device.adb("install", control_apk, timeout=30).decode().strip())
    device.shell("wm", "dismiss-keyguard")
    device.shell("am", "start", "-W", "-n", f"{PACKAGE}/.MainActivity")
    device.click("Beállítások", "Settings")
    device.click("Zárképernyő")
    device.click("Aktuális fejléc megosztása")
    device.click("Engedélyezem")
    device.click("Zárképernyős widget elhelyezése")
    # Upstream first-run pager. Never grant optional privileges to advance it.
    for _ in range(10):
        raw = device.screen()
        device.save("onboarding.xml", raw)
        if b"Accessibility Settings" in raw:
            device.settings_consent()
        if device.click("Done", "Finish", optional=True, limit=2):
            break
        if not device.click("Next", optional=True, limit=3):
            break
    enabled = device.shell("settings", "get", "secure", "enabled_accessibility_services")
    assert SERVICE in enabled.split(":"), "Ordinary accessibility onboarding did not finish"
    assert device.service_connected()
    device.click("Frame Enabled", "Enable Frame")
    for label in (["R49 Test Marker", ORB] if control_apk else [ORB]):
        device.click("Add Widget")
        device.click(label)
        device.click("Create", "Allow", "Add widget")
    device.crop("bound")
    bindings = (device.output / "bound-widgets.txt").read_text()
    assert re.search(r"(?:hostId=|:)(?:1003)\b", bindings), "Real WA host ID absent"
    assert "FluviHeaderOrbWidgetProvider" in bindings, "Current-header provider was not bound"
    device.note("Normal OS binding and host registration observed")
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    device.shell("input", "keyevent", "KEYCODE_WAKEUP")
    device.crop("main-0")
    time.sleep(0.5)
    device.crop("main-500")
    # The presence of a host registration is intentionally insufficient to
    # pass the visual gate. Keep the images even when the first-view fixture
    # or the inspection cannot establish a matching independent witness.
    raise AssertionError("Optical qualification pending for the recorded normal MAIN samples")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("system")
    parser.add_argument("output", type=Path)
    parser.add_argument("--control-apk", type=Path)
    args = parser.parse_args()
    device = Device(args.output)
    try:
        exercise(device, args.apk, args.system, args.control_apk)
    except (AssertionError, subprocess.SubprocessError, OSError, ET.ParseError) as error:
        device.note(f"FAILED: {error}")
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

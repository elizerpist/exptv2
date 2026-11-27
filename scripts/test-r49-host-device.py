#!/usr/bin/env python3
"""Stock emulator setup control using ordinary Android UI consent."""
import argparse
import base64
import io
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

from PIL import Image

PACKAGE = "com.fluvi.app"
WA = "tk.zwander.lockscreenwidgets"


class Device:
    def __init__(self, output, standalone=False):
        self.output = output
        self.host_package = WA if standalone else PACKAGE
        self.host_label = "Widgets Anywhere" if standalone else "Fluvi"
        self.service = f"{self.host_package}/{WA}.services.Accessibility"
        output.mkdir(parents=True, exist_ok=True)
        self.steps = []

    def adb(self, *args, timeout=25):
        return subprocess.check_output(["adb", *map(str, args)], timeout=timeout)

    def shell(self, *args, timeout=25):
        return self.adb("shell", *args, timeout=timeout).decode(errors="replace").strip()

    def save(self, name, content):
        (self.output / name).write_bytes(content)

    def screen(self, interactive_windows=False):
        options = ["-e", "interactiveWindows", "true"] if interactive_windows else []
        output = self.shell("am", "instrument", "-w", *options,
                            "com.fluvi.r49.fixture/.ReadVisibleHierarchy", timeout=8)
        value = re.search(r"INSTRUMENTATION_RESULT: hierarchy=(.*)", output)
        if not value:
            self.save("observer-error.txt", output.encode())
            raise OSError("No UI hierarchy returned by the non-suppressing observer")
        return base64.b64decode(value.group(1))

    def note(self, name):
        self.steps.append(name)
        (self.output / "steps.txt").write_text("\n".join(self.steps) + "\n")
        print(name, flush=True)

    def click(self, label, *alternatives, optional=False, limit=10, package=None):
        names = {value.casefold() for value in (label, *alternatives)}
        end = time.monotonic() + limit
        while time.monotonic() < end:
            try:
                raw = self.screen()
            except (subprocess.SubprocessError, OSError):
                continue
            root = ET.fromstring(raw)
            for node in root.iter("node"):
                if package and node.get("package") != package:
                    continue
                labels = {line.strip().casefold() for key in ("text", "content-desc")
                          for line in node.get(key, "").splitlines()}
                if labels & names:
                    a, b, c, d = map(int, re.findall(r"-?\d+", node.attrib["bounds"]))
                    if a >= c or b >= d:
                        continue
                    self.shell("input", "tap", (a + c) // 2, (b + d) // 2)
                    self.note("CLICK " + label)
                    return True
            self.save("latest-ui.xml", raw)
            time.sleep(0.4)
        if not optional:
            raise AssertionError(f"UI did not reach {label!r} within {limit}s")
        return False

    def choose_widget(self, app_label, query, evidence):
        self.click("Search", package=self.host_package)
        self.shell("input", "text", query)
        end = time.monotonic() + 10
        while time.monotonic() < end:
            raw = self.screen()
            self.save(evidence + "-picker.xml", raw)
            root = ET.fromstring(raw)
            nodes = [node for node in root.iter("node") if node.get("package") == self.host_package]
            if not any(node.get("text") == query for node in nodes):
                continue
            headings = [node for node in nodes if node.get("text") == app_label]
            if len(headings) != 1:
                continue
            bounds = lambda node: tuple(map(int, re.findall(r"-?\d+", node.attrib["bounds"])))
            heading_bottom = bounds(headings[0])[3]
            cards = {bounds(node) for node in nodes if node.get("clickable") == "true"
                     and node.get("visible") == "true" and bounds(node)[1] >= heading_bottom}
            cards = {(a, b, c, d) for a, b, c, d in cards if c-a > 100 and c-a == d-b}
            if len(cards) == 1:
                a, b, c, d = cards.pop()
                self.save(evidence + "-picker.png", self.adb("exec-out", "screencap", "-p"))
                self.shell("input", "tap", (a+c)//2, (b+d)//2)
                self.note(f"Selected filtered {app_label} card at {a},{b},{c},{d}")
                return
        raise AssertionError(f"Unique visible widget card missing for {app_label} and {query}")

    def service_connected(self):
        end = time.monotonic() + 30
        while time.monotonic() < end:
            state = self.adb("shell", "dumpsys", "accessibility")
            self.save("accessibility.txt", state)
            lines = state.decode().splitlines()
            bound = [line for line in lines if re.search(r"bound\s*services", line, re.IGNORECASE)]
            enabled = [line for line in lines if re.search(r"enabled\s*services", line, re.IGNORECASE)]
            if any(self.service in line for line in enabled) and any(
                self.service in line or f"label={self.host_label}," in line for line in bound
            ):
                records = self.adb("shell", "dumpsys", "activity", "services", self.service)
                self.save("accessibility-binding.txt", records)
                package, class_name = self.service.split("/", 1)
                names = {self.service}
                if class_name.startswith(package + "."):
                    names.add(package + "/" + class_name[len(package):])
                if any(f"cmp={component}".encode() in records for component in names):
                    return True
            time.sleep(1)
        return False

    def settings_consent(self):
        self.click("More Info")
        self.click("Grant")
        settings_package = "com.android.settings"
        if not self.click(self.host_label, package=settings_package, optional=True, limit=4):
            self.click("Downloaded apps", "Installed apps", package=settings_package)
            self.click(self.host_label, package=settings_package)
        self.click(f"Use {self.host_label}", package=settings_package)
        self.click("Allow", "OK")
        # The Settings result can return before its binder updates the service registry.
        # Observe the existing 30-second budget for the real acknowledgement.
        connected = self.service_connected()
        enabled = self.shell("settings", "get", "secure", "enabled_accessibility_services")
        self.save("accessibility-enabled.txt", enabled.encode())
        assert self.service in enabled.split(":"), "The exact component was not consented"
        assert connected, "Service connection was not observed"
        self.note("Normal accessibility consent and bound service observed")
        for _ in range(2):
            root = ET.fromstring(self.screen())
            if not any(n.get("package") == settings_package for n in root.iter("node")):
                break
            self.shell("input", "keyevent", "KEYCODE_BACK")

    def crop(self, name):
        begin = self.shell("cat", "/proc/uptime").split()[0]
        png = self.adb("exec-out", "screencap", "-p")
        end = self.shell("cat", "/proc/uptime").split()[0]
        self.save(name + ".png", png)
        self.save(name + "-windows.txt", self.adb("shell", "dumpsys", "window", "windows"))
        self.save(name + "-widgets.txt", self.adb("shell", "dumpsys", "appwidget"))
        with Image.open(io.BytesIO(png)) as image:
            rgb = image.convert("RGB")
            # Unique saturated marker from the separate real AppWidget.
            matches = sum(1 for r, g, b in rgb.getdata() if r < 15 and 223 <= g <= 237 and 122 <= b <= 142)
        self.note(f"{name} markerPixels={matches} readBracketSec={begin}..{end}")
        return matches

    def wake_lock_screen(self):
        self.shell("input", "keyevent", "KEYCODE_SLEEP")
        time.sleep(0.6)
        self.shell("input", "keyevent", "KEYCODE_WAKEUP")
        end = time.monotonic() + 8
        while time.monotonic() < end:
            policy = self.adb("shell", "dumpsys", "window", "policy")
            self.save("keyguard-precondition.txt", policy)
            if re.search(rb"(?m)^\s*(mShowingLockscreen|showing)=true\b", policy):
                return
            time.sleep(0.4)
        raise AssertionError("Real SystemUI keyguard did not become active after stock sleep/wake")

    def tutorial(self):
        for stage, fingers in enumerate((2, 2, 3), start=1):
            end = time.monotonic() + 10
            hint = None
            while time.monotonic() < end:
                raw = self.screen(interactive_windows=True)
                self.save(f"tutorial-{stage}.xml", raw)
                root = ET.fromstring(raw)
                hint = next((node for node in root.iter("node") if node.get("visible") == "true"
                             and ("Tap the widget frame with" in node.get("text", "") or
                                  "Tap with two fingers" in node.get("text", ""))), None)
                if hint is not None:
                    break
            if hint is None:
                raise AssertionError("WA first-view tutorial absent with actual SystemUI keyguard active")
            x1, y1, x2, y2 = map(int, re.findall(r"-?\d+", hint.attrib["bounds"]))
            result = self.shell(
                "am", "instrument", "-w", "-e", "x", (x1 + x2) // 2,
                "-e", "y", (y1 + y2) // 2, "-e", "fingers", fingers,
                "com.fluvi.r49.fixture/.FrameTutorialTouch",
            )
            assert "gesture=accepted" in result, result
            self.note(f"Tutorial gesture with {fingers} fingers")


def exercise(device, apk, system, control_apk, control_test, observer, external_wa):
    expected_api = system.split(".")[0]
    actual = device.shell("getprop", "ro.build.version.sdk")
    assert actual == expected_api, (actual, expected_api)
    packages = set(device.shell("pm", "list", "packages").splitlines())
    assert f"package:{WA}" not in packages, "Standalone WA is installed"
    assert f"package:{PACKAGE}" not in packages, "Expected a fresh emulator profile"
    device.note(f"STOCK API {actual} {device.shell('getprop', 'ro.build.fingerprint')}")
    device.note(device.adb("install", apk, timeout=90).decode().strip())
    device.note(device.adb("install", control_apk, timeout=30).decode().strip())
    device.note(device.adb("install", control_test, timeout=30).decode().strip())
    device.note(device.adb("install", observer, timeout=30).decode().strip())
    if external_wa:
        device.note(device.adb("install", external_wa, timeout=35).decode().strip())
    device.shell("wm", "dismiss-keyguard")
    launch = device.shell("am", "start", "-W", "-n", f"{PACKAGE}/.MainActivity")
    device.save("fluvi-launch.txt", launch.encode())
    assert "Status: ok" in launch, launch
    assert device.shell("pidof", PACKAGE), "Fluvi exited during launch"
    device.note(f"Fluvi launcher started. Host under test: {device.host_package}")
    device.click("Beállítások", "Settings")
    device.click("Zárképernyő")
    device.click("Aktuális fejléc megosztása")
    device.click("Engedélyezem")
    if external_wa:
        host_launch = device.shell("am", "start", "-W", "-n", f"{WA}/.MainActivity")
        device.save("wa-launch.txt", host_launch.encode())
        assert "Status: ok" in host_launch, host_launch
    else:
        device.click("Zárképernyős widget elhelyezése")
    # Upstream first-run pager. Never grant optional privileges to advance it.
    for step in range(10):
        raw = device.screen()
        device.save(f"onboarding-{step:02d}.xml", raw)
        if b'text="Accessibility"' in raw and device.service not in device.shell(
            "settings", "get", "secure", "enabled_accessibility_services",
        ).split(":"):
            device.settings_consent()
        if device.click("Done", "Finish", optional=True, limit=2):
            break
        if not device.click("Next", optional=True, limit=3):
            break
    enabled = device.shell("settings", "get", "secure", "enabled_accessibility_services")
    assert device.service in enabled.split(":"), "Ordinary accessibility onboarding did not finish"
    assert device.service_connected()
    # WA renders the first feature card's enabled state as a clickable label.
    device.click("Disabled", "Frame Enabled", "Enable Frame")
    for app_label, query, evidence in (("R49 Test Marker", "R49", "marker"), ("Fluvi", "Aktu", "orb")):
        device.click("Add Widget", package=device.host_package)
        device.choose_widget(app_label, query, evidence)
        if evidence == "marker":
            device.click(f"Always allow {device.host_label} to create widgets and access their data",
                         package="com.android.settings")
            device.click("Create", package="com.android.settings")
        else:
            device.click("Create", "Allow", optional=True, limit=5, package="com.android.settings")
        device.save(evidence + "-after-consent-widgets.txt", device.adb("shell", "dumpsys", "appwidget"))
    device.crop("bound")
    bindings = (device.output / "bound-widgets.txt").read_text()
    assert re.search(r"hostId[=:]\s*1003\b", bindings), "Real WA host ID absent"
    assert "FluviHeaderOrbWidgetProvider" in bindings, "Current-header provider was not bound"
    device.note("Normal OS binding and host registration observed")
    # Produce the current header by entering the normal dashboard after consent.
    device.shell("input", "keyevent", "KEYCODE_BACK")
    device.shell("input", "keyevent", "KEYCODE_BACK")
    device.click("Home", package=PACKAGE)
    device.crop("actual-dashboard-reference")
    # Leave setup so its preview buttons and window cannot satisfy the main witness.
    device.shell("input", "keyevent", "KEYCODE_HOME")
    assert device.crop("unlocked-control") < 100, "Marker already visible on unlocked control"
    assert device.shell("getprop", "ro.kernel.qemu") == "1", "Disposable emulator required"
    pin_result = device.shell("locksettings", "set-pin", "4827")
    assert "Pin set" in pin_result, pin_result
    device.shell("settings", "put", "secure", "lock_screen_lock_after_timeout", "0")
    device.note("Real SystemUI credential provisioned in the disposable profile")
    device.wake_lock_screen()
    device.tutorial()
    # A new physical wake clears the last tutorial gesture's temporary hide.
    for wake in range(1, 4):
        device.wake_lock_screen()
        time.sleep(0.6)
        assert device.crop(f"main-{wake}") >= 650, "No independent marker pixels under the real host"
        device.shell("cmd", "statusbar", "expand-notifications")
        early = device.crop(f"shade-{wake}-first-sample")
        settled = device.crop(f"shade-{wake}-settled")
        assert early < 100 and settled < 100, f"Marker persists under shade: {early}, {settled}"
        device.shell("cmd", "statusbar", "collapse")
    device.note("Three real marker wake/shade controls passed. Frame identity and ORB parity remain separate.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("system")
    parser.add_argument("output", type=Path)
    parser.add_argument("--control-apk", type=Path, required=True)
    parser.add_argument("--control-test", type=Path, required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--external-wa", type=Path)
    args = parser.parse_args()
    device = Device(args.output, args.external_wa is not None)
    try:
        exercise(device, args.apk, args.system, args.control_apk, args.control_test, args.observer, args.external_wa)
    except (AssertionError, subprocess.SubprocessError, OSError, ET.ParseError) as error:
        device.note(f"FAILED: {error}")
        device.save("first-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

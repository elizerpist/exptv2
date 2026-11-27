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
    def __init__(self, output):
        self.output = output
        self.service = f"{PACKAGE}/{WA}.services.Accessibility"
        self.host_label = "Fluvi zárképernyős ORB"
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
        settings = "com.android.settings"
        if not self.click(self.host_label, package=settings, optional=True, limit=5):
            self.click("Downloaded apps", "Installed apps", package=settings)
            self.click(self.host_label, package=settings)
        end = time.monotonic() + 10
        attempt = 0
        while time.monotonic() < end:
            raw = self.screen()
            self.save(f"service-switch-{attempt:02d}.xml", raw)
            nodes = list(ET.fromstring(raw).iter("node"))
            matches = [n for n in nodes if n.get("text") == f"Use {self.host_label}"]
            if len(matches) == 1:
                title = matches[0]
                break
            attempt += 1
            time.sleep(.25)
        else:
            raise AssertionError("The Android service-detail switch never appeared")
        _, top, right, bottom = map(int, re.findall(r"-?\d+", title.attrib["bounds"]))
        y = (top + bottom) / 2
        targets = set()
        for node in nodes:
            if node.get("package") != settings or node.get("visible") != "true":
                continue
            left, a, b, c = map(int, re.findall(r"-?\d+", node.attrib["bounds"]))
            if left >= right and a <= y <= c and b - left >= 32 and c - a >= 32:
                targets.add((left, a, b, c))
        assert targets, "No toggle bounds near the measured service row"
        left, top, right, bottom = min(targets, key=lambda p: (p[2] - p[0]) * (p[3] - p[1]))
        self.shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
        self.note(f"Tapped the measured Android service toggle at {left},{top}..{right},{bottom}")
        self.click("Allow", "OK", optional=True, limit=6)
        assert self.service_connected(), "Exact lockscreen service did not connect"
        for _ in range(3):
            screen = self.screen()
            if SETTINGS_ROWS[0] in visible_labels(screen, PACKAGE):
                break
            if any(label in ("Create", "Create widget") for label in visible_labels(screen, "com.android.settings")):
                break
            self.shell("input", "keyevent", "KEYCODE_BACK")

    def capture(self, name):
        begin = self.shell("cat", "/proc/uptime").split()[0]
        png = self.adb("exec-out", "screencap", "-p")
        end = self.shell("cat", "/proc/uptime").split()[0]
        self.save(name + ".png", png)
        windows = self.adb("shell", "dumpsys", "window", "windows")
        self.save(name + "-windows.txt", windows)
        self.note(f"SAMPLE {name} screenshot={begin}..{end} elapsedSeconds")
        return Image.open(io.BytesIO(png)).convert("RGB"), window_bounds(windows)

    def observe_orb(self, name, limit=12):
        until = time.monotonic() + limit
        sample = 0
        while time.monotonic() < until:
            image, bounds = self.capture(f"{name}-{sample:02d}")
            if bounds:
                settled, observed = self.capture(name + "-after-attach")
                if bounds != observed:
                    sample += 1
                    continue
                image = settled
                self.save(name + "-view.xml", self.screen(interactive_windows=True))
                image.crop(bounds).save(self.output / (name + "-crop.png"))
                return image, bounds
            sample += 1
            time.sleep(0.25)
        raise AssertionError(f"Attached visible Balance ORB was not observed at {name}")

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


def window_bounds(windows):
    blocks = re.split(rb"(?m)^\s*Window #\d+ ", windows)
    for block in blocks:
        if b"Fluvi Balance ORB}" not in block.split(b"\n", 1)[0]:
            continue
        if b"mHasSurface=true" not in block or b"mViewVisibility=0x0" not in block:
            continue
        bounds = re.search(rb"\bframe=\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]", block)
        if bounds is None:
            raise AssertionError("The visible overlay did not have an identifiable window frame")
        return tuple(map(int, bounds.groups()))
    return None


def pixel_change(a, b, bounds, threshold=8):
    from PIL import ImageChops

    left, top, right, bottom = bounds
    region = ImageChops.difference(a, b).crop(bounds)
    cx, cy = (right - left) / 2, (bottom - top) / 2
    inside = outside = 0
    for index, rgb in enumerate(region.getdata()):
        if max(rgb) < threshold:
            continue
        x, y = index % region.width + .5 - cx, index // region.width + .5 - cy
        distance = (x / cx) ** 2 + (y / cy) ** 2
        if distance < .7:
            inside += 1
        if distance > 1.13:
            outside += 1
    return inside, outside


def visible_labels(raw, package=None):
    return [
        part.strip()
        for node in ET.fromstring(raw).iter("node")
        if node.get("visible") == "true" and (package is None or node.get("package") == package)
        for key in ("text", "content-desc")
        for part in node.get(key, "").splitlines()
        if part.strip()
    ]


SETTINGS_ROWS = ["Android kisegítő lehetőségek", "1×1 ORB", "2×2 ORB"]


def settings_rows(device):
    until = time.monotonic() + 12
    sample = 0
    while time.monotonic() < until:
        raw = device.screen()
        device.save(f"three-settings-rows-{sample:02d}.xml", raw)
        labels = visible_labels(raw, PACKAGE)
        if all(row in labels for row in SETTINGS_ROWS):
            indices = [labels.index(row) for row in SETTINGS_ROWS]
            assert indices == sorted(indices)
            assert labels.count("Android kisegítő lehetőségek") == 1
            assert "Aktuális fejléc megosztása" not in labels
            assert "Zárképernyős widget elhelyezése" not in labels
            device.note("Three Fluvi setting rows observed in order")
            return
        sample += 1
        time.sleep(.3)
    raise AssertionError("The three settings rows were not identified")


def enter_settings(device):
    device.click("Beállítások", "Settings", limit=25)
    device.click("Zárképernyő", limit=12)
    settings_rows(device)


def prepare_binding(device):
    device.click("Android kisegítő lehetőségek")
    device.settings_consent()
    device.click("Cancel", "Don't allow", package="com.android.settings", limit=8)
    device.save("cancelled-widgets.txt", device.adb("shell", "dumpsys", "appwidget"))
    time.sleep(.5)
    settings_rows(device)
    device.click("1×1 ORB", package=PACKAGE)
    device.save("single-use-grant.xml", device.screen())
    device.click("Create", "Allow", package="com.android.settings", limit=8)
    device.save("after-grant-widgets.txt", device.adb("shell", "dumpsys", "appwidget"))
    end = time.monotonic() + 30
    while time.monotonic() < end:
        logs = device.adb("logcat", "-d", "-s", "FluviBalanceOrb")
        match = re.search(rb"bound host=1003 id=(\d+)", logs)
        if match and re.search(rb"stage=material-ready id=" + match[1] + rb"\b", logs):
            device.note(f"Real host ID 1003, material ready under widget {match[1].decode()}")
            return match[1]
        time.sleep(.55)
    raise AssertionError("Normal single-use bind or offstage Balance frame preparation was not observed")


def hide_sample(device, name):
    _, bounds = device.capture(name + "-first")
    time.sleep(.4)
    _, later = device.capture(name + "-settled")
    assert later is None, f"Overlay remained attached in {name} after settling"
    device.note(f"{name}: first overlay bounds={bounds}; settled overlay absent")


def check_motion(device, size):
    previous, start = device.observe_orb(f"{size}-main")
    width, height = start[2] - start[0], start[3] - start[1]
    assert width == height and width > 20, start
    strict = []
    fine = []
    for index in range(1, 7):
        time.sleep(.017 + index * .017)
        sample, bounds = device.capture(f"{size}-motion-{index:02d}")
        assert bounds == start, f"ORB moved between stationary frame samples: {start}, {bounds}"
        strict.append(pixel_change(previous, sample, bounds))
        fine.append(pixel_change(previous, sample, bounds, threshold=3))
        previous = sample
    device.note(f"{size} consecutive samples delta>=8 {strict}. Additional delta>=3 {fine}")
    passed = sum(inside > max(40, width * width / 100) and outside < inside / 5
                 for inside, outside in strict) >= 2
    return width, passed


def check_drag(device, size):
    image, start = device.observe_orb(f"{size}-drag-start")
    radius = (start[2] - start[0]) // 2
    # The endpoint reaches the WindowManager clamp while keeping the injected
    # pointer away from the Android edge navigation activation strip.
    side = max(20, radius // 3)
    destinations = ((side, image.height // 2), (image.width - side, image.height // 2),
                    (image.width // 2, side), (image.width // 2, image.height - side),
                    (image.width - side, image.height - side))
    faults = []
    for number, (x, y) in enumerate(destinations, start=1):
        cx, cy = (start[0] + start[2]) // 2, (start[1] + start[3]) // 2
        witness = device.shell("am", "instrument", "-w", "-e", "action", "drag",
                               "-e", "x", cx, "-e", "y", cy,
                               "-e", "targetX", x, "-e", "targetY", y,
                               "com.fluvi.r49.fixture/.ReadVisibleHierarchy", timeout=12)
        device.save(f"{size}-injection-{number}.txt", witness.encode())
        assert "gesture=PASS" in witness, witness
        _, after = device.observe_orb(f"{size}-drag-{number}")
        assert (after[2] - after[0], after[3] - after[1]) == (start[2] - start[0], start[3] - start[1])
        assert 0 <= after[0] <= after[2] <= image.width and 0 <= after[1] <= after[3] <= image.height
        device.note(f"{size} drag {number} root {start} -> {after}")
        if after == start:
            faults.append(number)
        start = after
    device.wake_lock_screen()
    _, restored = device.observe_orb(f"{size}-relock")
    device.note(f"{size} relock applied root {restored}; last drop root {start}")
    assert restored == start, f"Root did not restore dropped position: {start} -> {restored}"
    assert not faults, f"Missing committed movement for {size} drags {faults}"


def run_check(device, failures, label, check):
    try:
        check()
        device.note(f"PASS {label}")
    except (AssertionError, OSError, subprocess.SubprocessError) as error:
        device.note(f"FAIL {label}: {error}")
        failures.append(label)


def exercise(device, apk, system, observer):
    actual = device.shell("getprop", "ro.build.version.sdk")
    assert actual == system.split(".")[0], (actual, system)
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    packages = set(device.shell("pm", "list", "packages").splitlines())
    assert f"package:{WA}" not in packages and f"package:{PACKAGE}" not in packages
    device.note(f"STOCK API {actual} {device.shell('getprop', 'ro.build.fingerprint')}")
    device.note(device.adb("install", apk, timeout=90).decode().strip())
    device.note(device.adb("install", observer, timeout=30).decode().strip())
    device.shell("wm", "dismiss-keyguard")
    launch = device.shell("am", "start", "-W", "-n", f"{PACKAGE}/.MainActivity")
    device.save("fluvi-launch.txt", launch.encode())
    assert "Status: ok" in launch
    enter_settings(device)
    own_id = prepare_binding(device)
    assert "Pin set" in device.shell("locksettings", "set-pin", "4827")
    device.shell("settings", "put", "secure", "lock_screen_lock_after_timeout", "0")
    # Background the app before waking. The binding and frames must survive.
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.wake_lock_screen()
    initial, bounds = device.observe_orb("shade-baseline")
    mid = initial.width // 2
    # The captured prior statusbar command left the main clock visible.
    # Exercise the user's top-edge gesture and require separate SystemUI evidence.
    panel_tags = {"Internet", "Bluetooth", "Airplane mode", "No notifications"}
    witnessed = False
    for attempt in range(1, 3):
        device.shell("input", "swipe", mid, 8, mid, initial.height * 2 // 3, 650)
        device.capture(f"panel-entry-{attempt}")
        raw = device.screen(interactive_windows=True)
        device.save(f"panel-entry-{attempt}.xml", raw)
        labels = visible_labels(raw, "com.android.systemui")
        matches = panel_tags.intersection(labels)
        nodes = ET.fromstring(raw).iter("node")
        selectors = {n.get("id") for n in nodes if n.get("visible") == "true"
                     and n.get("id", "").endswith(("/quick_settings_panel", "/tile_label"))}
        device.note(f"Panel witness attempt {attempt} tile labels {matches} selectors {selectors}")
        if matches or selectors:
            witnessed = True
            break
    assert witnessed, "INCONCLUSIVE: Android kept the ordinary lockscreen after the two gestures"
    hide_sample(device, "confirmed-shade")
    device.shell("cmd", "statusbar", "collapse")
    _, returned = device.observe_orb("after-confirmed-shade")
    assert returned == bounds, (bounds, returned)
    logs = device.adb("logcat", "-d", "-s", "FluviBalanceOrb")
    assert set(re.findall(rb"bound host=1003 id=(\d+)", logs)) == {own_id}
    device.note("PASS witnessed restricted shade withdrawal and same-ID readmission")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("system")
    parser.add_argument("output", type=Path)
    parser.add_argument("--observer", type=Path, required=True)
    args = parser.parse_args()
    device = Device(args.output)
    try:
        exercise(device, args.apk, args.system, args.observer)
    except (AssertionError, subprocess.SubprocessError, OSError, ET.ParseError) as error:
        device.note(f"FAILED: {error}")
        device.save("first-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

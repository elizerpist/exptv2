#!/usr/bin/env python3
"""Signed stock AVD comparison. Every sleep and unlock starts at its own visible ORB."""
import argparse
import hashlib
import importlib.util
from pathlib import Path
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location(
    "stock_host", Path(__file__).with_name("test-r50-host-device.py")
)
stock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stock)
PKG = stock.PACKAGE
ACTIVITY = PKG + "/.MainActivity"
WITNESS = "com.fluvi.r49.fixture"
PANEL = "Zárképernyő"
TAG = "FluviBalanceOrb"

class Device(stock.Device):
    def settings_consent(self):
        # A title click returns before Android has attached the switch activity.
        # Wait for its exact visible Use row; keep the prior real consent path.
        settings = "com.android.settings"
        if not self.click(self.host_label, package=settings, optional=True, limit=5):
            self.click("Downloaded apps", "Installed apps", package=settings)
            self.click(self.host_label, package=settings)
        title = f"Use {self.host_label}"
        until = time.monotonic() + 10
        retried = False
        while time.monotonic() < until:
            raw = self.screen()
            self.save("service-switch.xml", raw)
            nodes = list(ET.fromstring(raw).iter("node"))
            found = [node for node in nodes if node.get("text") == title]
            if len(found) == 1:
                break
            if not retried and until - time.monotonic() < 7:
                rows = [node for node in nodes if node.get("text") == self.host_label
                        and node.get("visible") == "true" and node.get("package") == settings]
                if len(rows) == 1:
                    x1, y1, x2, y2 = map(int, re.findall(r"-?\d+", rows[0].get("bounds")))
                    self.shell("input", "tap", (x1 + x2)//2, (y1 + y2)//2)
                    self.note("Retapped the witnessed visible service row after the list remained open")
                    retried = True
            time.sleep(.25)
        else:
            raise AssertionError("Actual Android service switch title did not appear")
        _, top, right, bottom = map(int, re.findall(r"-?\d+", found[0].attrib["bounds"]))
        targets = set()
        for node in nodes:
            if node.get("package") != settings or node.get("visible") != "true":
                continue
            left, a, b, c = map(int, re.findall(r"-?\d+", node.attrib["bounds"]))
            if left >= right and a <= (top + bottom) / 2 <= c and b - left >= 32 and c - a >= 32:
                targets.add((left, a, b, c))
        assert targets, "No actual service toggle by the measured title"
        left, top, right, bottom = min(targets, key=lambda p: (p[2] - p[0]) * (p[3] - p[1]))
        self.shell("input", "tap", (left + right) // 2, (top + bottom) // 2)
        self.click("Allow", "OK", optional=True, limit=6)
        assert self.service_connected(), "Exact accessibility service never bound"
        for _ in range(3):
            raw = self.screen()
            if stock.SETTINGS_ROWS[0] in stock.visible_labels(raw, PKG):
                break
            if any(label in ("Create", "Create widget") for label in stock.visible_labels(raw, settings)):
                break
            self.shell("input", "keyevent", "KEYCODE_BACK")


def system_state(device, name):
    # Read actual public values from a separate test process. Power service
    # dump text changed on API 37 and cannot identify the default display.
    raw = device.adb("shell", "am", "instrument", "-w", "-e", "stateWitness", "true",
                     WITNESS + "/.ReadVisibleHierarchy", timeout=6)
    device.save(name + "-state.txt", raw)
    state = re.search(rb"platform=display=(-?\d+) interactive=(true|false) locked=(true|false)", raw)
    if state is None:
        return ("UNKNOWN", "UNKNOWN", "UNKNOWN")
    display = {1: "OFF", 2: "ON", 3: "DOZE", 4: "DOZE_SUSPEND", -1: "MISSING"}
    return (display.get(int(state[1]), "UNKNOWN"), state[3].decode(), state[2].decode())

def poll_state(device, name, expected_display, locked):
    end = time.monotonic() + 10
    sample = 0
    while time.monotonic() < end:
        state = system_state(device, f"{name}-{sample:02d}")
        if state[:2] == (expected_display, str(locked).lower()):
            return state
        sample += 1
        time.sleep(.12)
    raise AssertionError(f"{name} precondition absent, last display/lock/interactive={state}")


def label_screen(device):
    return stock.visible_labels(device.screen(), PKG)


def panel(device):
    assert "Status: ok" in device.shell("am", "start", "-W", "-n", ACTIVITY)
    for _ in range(3):
        labels = label_screen(device)
        if "Debug Console" in labels:
            break
        if device.click("Debug log", package=PKG, optional=True, limit=3):
            break
        device.shell("input", "keyevent", "KEYCODE_BACK")
        device.shell("am", "start", "-W", "-n", ACTIVITY)
    assert "Debug Console" in label_screen(device), "Real debug console did not open"


def clipboard(device, name, expected_sha):
    device.click("Vágólapra másolás", package=PKG)
    end = time.monotonic() + 5
    while time.monotonic() < end and "Felvétel a vágólapon." not in label_screen(device):
        pass
    assert "Felvétel a vágólapon." in label_screen(device)
    device.shell("run-as", WITNESS, "rm", "-f", "files/paste.txt")
    assert "Status: ok" in device.shell(
        "am", "start", "-S", "-W", "-n", WITNESS + "/.ClipboardWitness", "--ez", "paste", "true")
    end = time.monotonic() + 5
    while time.monotonic() < end:
        output = device.shell("run-as", WITNESS, "ls", "files", timeout=4)
        if "paste.txt" in output.splitlines():
            break
        time.sleep(.15)
    text = device.adb("exec-out", "run-as", WITNESS, "cat", "files/paste.txt")
    assert len(text) <= 131072 and text.startswith(b"FLUVI_WA_LOCKSCREEN_CAPTURE_V1\n")
    body, digest = text.rsplit(b"sha256=", 1)
    assert digest == hashlib.sha256(body).hexdigest().encode() + b"\n"
    assert f"build={expected_sha} purpose=HUMAN_DIAGNOSTIC".encode() in body
    device.save(name + "-clipboard.txt", text)
    device.note(f"{name} actual foreground paste {len(text)} bytes bodySHA={digest.decode().strip()}")
    return text


def visible_orb(device, name):
    first, bounds = device.observe_orb(name, limit=10)
    # Outside the circular paint, use corner pixels as an independent control.
    crop = first.crop(bounds)
    center_x, center_y = crop.width / 2, crop.height / 2
    def painted():
        return sum(
            max(rgb) - min(rgb) >= 28 and max(rgb) >= 92
            for index, rgb in enumerate(crop.getdata())
            if ((index % crop.width - center_x) / center_x) ** 2
            + ((index // crop.width - center_y) / center_y) ** 2 < .55
        )
    if painted() < crop.width * crop.height * .08:
        first, found = device.capture(name + "-visible")
        assert found == bounds
        crop = first.crop(bounds)
    assert painted() >= crop.width * crop.height * .08, (
        f"{name} root inventory was present but colored ORB was not witnessed"
    )
    crop.save(device.output / (name + "-visible-crop.png"))
    return first, bounds


def wake(device, name):
    device.shell("input", "keyevent", "KEYCODE_WAKEUP")
    poll_state(device, name + "-main", "ON", True)
    return visible_orb(device, name)


def held_absence(device, name, expected_display, locked):
    _, first = device.capture(name + "-first-request")
    observed = poll_state(device, name, expected_display, locked)
    device.note(f"{name} observed display/lock/interactive={observed}, first requested root={first}")
    elapsed = time.monotonic() + 5
    samples = 0
    present = []
    while True:
        raw = device.adb("shell", "cat /proc/uptime; dumpsys window windows; cat /proc/uptime")
        device.save(f"{name}-absent-{samples:02d}.txt", raw)
        bounds = stock.window_bounds(raw)
        if bounds is not None:
            present.append((samples, bounds))
        samples += 1
        if time.monotonic() >= elapsed:
            break
        time.sleep(.18)
    _, settled = device.capture(name + "-settled")
    assert system_state(device, name + "-settled")[:2] == (
        expected_display, str(locked).lower()
    ), "Scene stopped matching during absence sampling"
    assert not present and settled is None, f"Visible overlay during verified {name}: {present}, {settled}"
    return first


def locked_sleep(device, name):
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    poll_state(device, name + "-pre-sleep", "OFF", True)
    _, before_sleep = wake(device, name + "-sleep-start")
    started = time.monotonic()
    device.note(f"{name} sleep directly from painted root {before_sleep}")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    assert time.monotonic() - started < 10
    sleep_first = held_absence(device, name + "-locked-sleep", "OFF", True)
    device.note(f"PASS {name} locked sleep, first requested root {sleep_first}")
    return before_sleep


def direct_unlock(device, name, previous, framework):
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    poll_state(device, name + "-pre-unlock", "OFF", True)
    image, before_unlock = wake(device, name + "-unlock-start")
    assert previous is None or before_unlock == previous, (previous, before_unlock)
    # Ordinary swipe-only keyguard. Move outside the ORB's touch region.
    x = image.width // 5
    if framework:
        device.note(f"{name} framework dismiss of swipe-only keyguard from painted root {before_unlock}")
        device.shell("wm", "dismiss-keyguard")
    else:
        device.note(f"{name} genuine swipe unlock directly from painted root {before_unlock}")
        device.shell("input", "swipe", x, int(image.height * .91), x, int(image.height * .34), 290)
    unlocked_first = held_absence(device, name + "-unlock", "ON", False)
    focused = device.adb("shell", "dumpsys window; dumpsys activity activities")
    device.save(name + "-launcher.txt", focused)
    assert re.search(rb"(mCurrentFocus|topResumedActivity|mResumedActivity)=.*(?:launcher|com\.fluvi\.app)", focused, re.I), (
        "Dismissed keyguard had no witnessed launcher or Fluvi focus"
    )
    device.note(f"PASS {name} direct unlock, first requested root {unlocked_first}")


def exercise(device, args):
    api = args.system.split(".")[0]
    assert device.shell("getprop", "ro.build.version.sdk") == api
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    packages = set(device.shell("pm", "list", "packages").splitlines())
    assert all("package:" + name not in packages for name in (PKG, stock.WA))
    device.note(f"STOCK API {api} {device.shell('getprop', 'ro.build.fingerprint')}")
    assert "Success" in device.adb("install", args.apk, timeout=90).decode()
    assert "Success" in device.adb("install", args.observer, timeout=30).decode()
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    device.shell("settings", "put", "secure", "lock_screen_lock_after_timeout", "0")
    assert "Status: ok" in device.shell("am", "start", "-W", "-n", ACTIVITY)
    baseline_labels = stock.visible_labels(device.screen())
    if "Quickstep isn't responding" in baseline_labels:
        device.note("Disposable launcher ANR witnessed before the Fluvi settings entrance")
        device.click("Close app", limit=6)
        device.shell("am", "start", "-W", "-n", ACTIVITY)
    stock.enter_settings(device)
    widget = stock.prepare_binding(device)
    panel(device)
    if args.baseline:
        labels = label_screen(device)
        assert PANEL not in labels
        device.note("RED exact installed R50 Human panel has no lockscreen capture tab")
    else:
        device.click(PANEL, package=PKG)
        device.click("Felvétel indítása", package=PKG)
        assert "Leállítás" in label_screen(device), "Native capture did not acknowledge start"
    device.shell("input", "keyevent", "KEYCODE_HOME")
    failures = []
    for index in range(args.repetitions):
        name = f"warm-{index + 1:02d}"
        previous = None
        try:
            previous = locked_sleep(device, name)
        except (AssertionError, subprocess.SubprocessError, OSError) as error:
            device.note(f"FAIL {name} sleep: {error}")
            failures.append(name + "-sleep")
        try:
            direct_unlock(device, name, previous, args.framework_dismiss)
        except (AssertionError, subprocess.SubprocessError, OSError) as error:
            device.note(f"FAIL {name} unlock: {error}")
            failures.append(name + "-unlock")
            device.shell("input", "keyevent", "KEYCODE_WAKEUP")
            device.shell("wm", "dismiss-keyguard")
        device.shell("input", "keyevent", "KEYCODE_HOME")
        if index == 0 and not args.baseline:
            try:
                panel(device)
                device.click(PANEL, package=PKG)
                assert "Leállítás" in label_screen(device), "Native capture stopped while backgrounded"
                first = clipboard(device, "running-copy", args.app_sha)
                assert b"stop=COPY" in first
                assert b" LOCAL_HIDE " in first and b" REMOVE_RETURN " in first
                panel(device)
                device.click(PANEL, package=PKG)
                assert "Lezárt felvétel" in label_screen(device)
                assert clipboard(device, "recopy", args.app_sha) == first
                device.note("PASS installed debug panel, running-copy freeze, remount, exact UTF-8 recopy")
                device.shell("input", "keyevent", "KEYCODE_HOME")
            except (AssertionError, subprocess.SubprocessError, OSError) as error:
                device.note(f"FAIL clipboard: {error}")
                failures.append("clipboard")
                device.shell("input", "keyevent", "KEYCODE_HOME")
    logs = device.adb("logcat", "-d", "-s", TAG)
    assert set(re.findall(rb"bound host=1003 id=(\d+)", logs)) == {widget}
    if args.effects:
        import r51_entrance_fixture
        try:
            r51_entrance_fixture.exercise(device, sys.modules[__name__], widget.decode(), args.baseline)
        except (AssertionError, subprocess.SubprocessError, OSError) as error:
            device.note(f"FAIL entrance samples: {error}")
            failures.append("entrance")
    assert not failures, f"Preserved failing trials: {failures}"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("system")
    parser.add_argument("output", type=Path)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--app-sha", required=True)
    parser.add_argument("--baseline", action="store_true")
    parser.add_argument("--effects", action="store_true")
    parser.add_argument("--framework-dismiss", action="store_true")
    parser.add_argument("--repetitions", type=int, choices=(1, 3), required=True)
    args = parser.parse_args()
    device = Device(args.output)
    try:
        exercise(device, args)
    except (AssertionError, OSError, subprocess.SubprocessError, ET.ParseError) as error:
        device.note(f"FAIL final: {error}")
        device.save("first-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

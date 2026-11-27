"""Independent R51 secure-scene and native process-restart controls."""
import argparse
import importlib.util
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location(
    "r51", Path("scripts/test-r51-orb-transitions.py")
)
r51 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r51)


def wait_label(device, label):
    until = time.monotonic() + 8
    while time.monotonic() < until:
        if label in r51.label_screen(device):
            return
    raise AssertionError(f"Missing native panel state {label!r}")


def secure(device):
    assert "Pin set" in device.shell("locksettings", "set-pin", "4827")
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    r51.poll_state(device, "pin-pre", "OFF", True)
    _, bounds = r51.wake(device, "pin-visible-start")
    device.note(f"Secure transition starts with painted ORB at {bounds}")
    device.shell("input", "keyevent", "KEYCODE_MENU")
    _, first = device.capture("pin-first-request")
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        nodes = device.screen(interactive_windows=True)
        device.save("pin-witness.xml", nodes)
        if re.search(rb"keyguard_(?:host_view|security_container)|BouncerContent|Enter (?:your )?PIN",
                     nodes, re.I):
            break
    else:
        raise AssertionError("Credential bouncer not independently witnessed")
    _, after = device.capture("pin-confirmed")
    assert r51.system_state(device, "pin-confirmed")[:2] == ("ON", "true")
    assert after is None, "Overlay seen on confirmed credential screen"
    device.note(f"PASS confirmed PIN software withdrawal. First requested root={first}")
    device.shell("input", "text", "4827")
    device.shell("input", "keyevent", "KEYCODE_ENTER")
    r51.poll_state(device, "pin-unlock", "ON", False)


def restart(device, app_sha):
    r51.panel(device)
    device.click(r51.PANEL, package=r51.PKG)
    device.click("Felvétel indítása", package=r51.PKG)
    wait_label(device, "Leállítás")
    device.click("Leállítás", package=r51.PKG)
    wait_label(device, "Lezárt felvétel")
    frozen = r51.clipboard(device, "explicit-stop", app_sha)
    assert b"stop=STOP" in frozen
    r51.panel(device)
    device.click(r51.PANEL, package=r51.PKG)
    device.click("Felvétel indítása", package=r51.PKG)
    wait_label(device, "Leállítás")
    before = device.shell("pidof", r51.PKG).split()
    assert before
    device.shell("am", "force-stop", r51.PKG)
    r51.panel(device)
    device.click(r51.PANEL, package=r51.PKG)
    assert set(before).isdisjoint(device.shell("pidof", r51.PKG).split())
    wait_label(device, "A felvétel megszakadt a folyamat leállásakor")
    assert r51.clipboard(device, "after-process-restart", app_sha) == frozen
    device.note("PASS explicit native stop, previous frozen bytes survive real interrupted process")


def home_smoke(device):
    device.shell("input", "keyevent", "KEYCODE_HOME")
    r51.poll_state(device, "home-smoke", "ON", False)
    raw = device.screen()
    launch = {n.get("package") for n in ET.fromstring(raw).iter("node")}
    assert any("launcher" in (name or "") for name in launch), launch
    width, height = map(int, re.findall(r"\d+", device.shell("wm", "size").splitlines()[-1])[-2:])
    device.shell("input", "swipe", width//2, height//4, width//2, height//4, 900)
    device.click("Widgets", limit=8)
    clicked = device.click("Fluvi", optional=True, limit=4)
    if not clicked:
        device.shell("input", "swipe", width//2, (height*8)//10, width//2, height//4, 500)
        device.click("Fluvi", limit=5)
    screenshot, _ = device.capture("fluvi-home-widget-picker")
    assert screenshot.width > 0
    # The concrete launcher controls differ by image. Record the witness;
    # this check stops at the provider's listing instead of claiming pixels.
    labels = r51.stock.visible_labels(device.screen())
    device.save("home-widget-picker-labels.txt", "\n".join(labels).encode())
    assert any("ORB" in label for label in labels), labels
    device.note("PASS launcher home ORB provider listed. Installed playback separate.")


def run(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    assert b"Success" in device.adb("install", args.apk, timeout=90)
    assert b"Success" in device.adb("install", args.observer)
    device.shell("wm", "dismiss-keyguard")
    assert "Status: ok" in device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
    r51.stock.enter_settings(device)
    r51.stock.prepare_binding(device)
    failures = []
    for what, operation in (
        ("secure PIN", lambda: secure(device)),
        ("real process restart", lambda: restart(device, args.app_sha)),
        ("home picker", lambda: home_smoke(device)),
    ):
        try:
            operation()
        except (AssertionError, OSError, subprocess.SubprocessError, ET.ParseError) as error:
            device.note(f"FAIL {what}: {error}")
            device.save(what.replace(" ", "-") + "-failure.png", device.adb("exec-out", "screencap", "-p"))
            failures.append(what)
    assert not failures, failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--app-sha", required=True)
    args = parser.parse_args()
    device = r51.Device(args.output)
    try:
        run(device, args)
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

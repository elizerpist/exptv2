"""Extra safety controls on a disposable stock AVD, outside the timed pairs."""
import re
import time

import r52_measure as experiment

PKG = experiment.PKG
PIN = "4827"


def lock(device, name):
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    experiment.independent_state(device, name + "-lock", experiment.sleeping)
    return experiment.r51.wake(device, name)


def wait_label(device, text, limit=8):
    until = time.monotonic() + limit
    while time.monotonic() < until:
        if text in experiment.labels(device):
            return
        time.sleep(.15)
    raise AssertionError(f"No native acknowledgement {text!r}")


def wait_restricted(device, label, pattern):
    until = time.monotonic() + 8
    raw = b""
    while time.monotonic() < until:
        raw = device.screen(interactive_windows=True)
        device.save(label + "-restriction.xml", raw)
        if re.search(pattern, raw, re.I):
            break
    else:
        raise AssertionError(f"No independent {label} witness")
    assert experiment.r51.system_state(device, label + "-state") == ("ON", "true", "true")
    _, root = device.capture(label + "-settled")
    assert root is None, f"{label} still owns an ORB window"
    device.note("PASS restricted scene " + label)


def restrictive_controls(device, sha):
    failures = []
    for arm in (50, 0):
        prefix = f"safety-{arm}"
        pin_set = False
        previous_time = device.shell("settings", "get", "system", "time_12_24")
        try:
            experiment.home(device)
            assert "Pin set" in device.shell("locksettings", "set-pin", PIN)
            pin_set = True
            experiment.arm(device, prefix, arm)
            _, bounds = lock(device, prefix + "-main")
            for choice in ("12", "24", "12"):
                device.shell("settings", "put", "system", "time_12_24", choice)
            _, fresh = experiment.r51.visible_orb(device, prefix + "-same-main")
            assert fresh == bounds
            assert experiment.r51.system_state(device, prefix + "-main-still") == ("ON", "true", "true")
            device.shell("input", "swipe", 430, 8, 430, 1210, 350)
            device.capture(prefix + "-shade-first-request")
            wait_restricted(device, prefix + "-shade", rb"quick_settings_panel|tile_label|Settings button|qs_footer")
            device.shell("input", "keyevent", "KEYCODE_BACK")
            experiment.r51.visible_orb(device, prefix + "-main-after-shade")
            device.shell("input", "keyevent", "KEYCODE_MENU")
            device.capture(prefix + "-pin-first-request")
            wait_restricted(device, prefix + "-pin", rb"keyguard_(?:host_view|security_container)|BouncerContent|Enter (?:your )?PIN")
            device.shell("input", "text", PIN)
            device.shell("input", "keyevent", "KEYCODE_ENTER")
            experiment.independent_state(device, prefix + "-pin-unlocked", lambda s: s == ("ON", "false", "true"))
            snapshot = experiment.copy(device, prefix, sha, 2, arm)
            stage = set(map(int, re.findall(rb"event=(32|2048)\b", snapshot)))
            device.note(f"{prefix} retained event types={sorted(stage)}")
        except experiment.EXPERIMENT_FAILURES as error:
            failures.append(f"{prefix}: {error}")
            device.note(f"{prefix} incomplete: {error}")
        finally:
            if pin_set:
                device.shell("locksettings", "clear", "--old", PIN)
            if previous_time == "null":
                device.shell("settings", "delete", "system", "time_12_24")
            else:
                device.shell("settings", "put", "system", "time_12_24", previous_time)
            try:
                experiment.home(device)
                experiment.panel(device)
                if "Leállítás" in experiment.labels(device):
                    device.click("Leállítás", package=PKG)
            except experiment.EXPERIMENT_FAILURES as error:
                failures.append(f"{prefix} cleanup: {error}")
    return failures


def process_lifetime(device, sha, frozen):
    experiment.arm(device, "before-process-death", 0)
    previous = set(device.shell("pidof", PKG).split())
    assert previous
    device.shell("am", "force-stop", PKG)
    experiment.panel(device)
    assert set(device.shell("pidof", PKG).split()).isdisjoint(previous)
    wait_label(device, "A felvétel megszakadt")
    assert experiment.copy(device, "after-process-death", sha, 2) == frozen
    assert device.service_connected(), "Enabled service did not reconnect"
    experiment.panel(device)
    wait_label(device, "Visszaállítva: 50 ms")
    device.note("PASS process death interrupted current B and reconnect read back 50 ms")
    experiment.arm(device, "expiry", 0)
    time.sleep(91)
    experiment.panel(device)
    wait_label(device, "Visszaállítva: 50 ms")
    expired = experiment.copy(device, "expired", sha, 2, 0)
    assert b"stop=LIMIT" in expired
    device.note("PASS 90 s expiry restored the active 0 ms experiment to 50 ms")

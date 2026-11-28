"""Signed R54 -> combined R55 update and independent ordinary/AOD product controls."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import time

import mask_controls as masks
import r52_measure as stock
import receipt
import signed_upgrade as seeded
from upgrade import bind_r52, check_owner, check_sentinel, normal_unlock, open_dashboard, painted_wake, wait_for_root

PKG = stock.PKG
SWITCH = "Permanens ORB"
COPY = "Legutóbbi AOD-próba másolása"


def click_in_settings(device, label):
    masks.settings(device)
    for _ in range(4):
        if device.click(label, package=PKG, optional=True, limit=2):
            return
        device.shell("input", "swipe", "460", "1800", "460", "820", "300")
    raise AssertionError(f"Actual settings action not found: {label}")


def set_permanent(device, value):
    expected = str(value).lower()
    if masks.prefs(device).get("permanentOrb", "false") != expected:
        click_in_settings(device, SWITCH)
    for _ in range(10):
        if masks.prefs(device).get("permanentOrb", "false") == expected:
            return
        time.sleep(.2)
    raise AssertionError(f"The actual UI did not save permanentOrb={expected}")


def ambient_copy(device, name, sha):
    click_in_settings(device, COPY)
    device.click("Az AOD-napló a vágólapon van.", package=PKG, limit=8)
    witness = stock.WITNESS
    device.shell("run-as", witness, "rm", "-f", "files/paste.txt")
    device.shell("am", "start", "-S", "-W", "-n", witness + "/.ClipboardWitness", "--ez", "paste", "true")
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        if subprocess.run(["adb", "shell", "run-as", witness, "test", "-s", "files/paste.txt"],
                          timeout=3, capture_output=True).returncode == 0:
            break
        time.sleep(.15)
    raw = device.adb("exec-out", "run-as", witness, "cat", "files/paste.txt")
    device.save(name + "-clipboard.txt", raw)
    assert raw.startswith(b"FLUVI_WA_AMBIENT_V1\n") and len(raw) <= 4096
    body, digest = raw.rsplit(b"bodySha256=", 1)
    assert hashlib.sha256(body).hexdigest().encode() + b"\n" == digest
    assert f"build={sha} package={PKG} api=37 display=0".encode() in body
    assert b"physicalVisibility=UNOBSERVED" in body
    return body


def upgrade(device, args, work):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    device.note("Stock fingerprint " + device.shell("getprop", "ro.build.fingerprint"))
    wait_for_root(device)
    for apk in (args.baseline, args.observer):
        assert b"Success" in device.adb("install", apk, timeout=90)
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    stock.r51.poll_state(device, "before-r54", "ON", False)
    open_dashboard(device, "r54-before-seed")
    seeded.seed(device, work)
    open_dashboard(device, "r54-after-seed")
    masks.settings(device)
    widget = bind_r52(device)
    device.click("2×2 (112 dp)", package=PKG)
    masks.select_style(device, 56, "fluviMask")
    picture, bounds = painted_wake(device, "r54-before-upgrade")
    x, y = (bounds[0] + bounds[2]) // 2, (bounds[1] + bounds[3]) // 2
    device.shell("input", "draganddrop", x, y, x - 135, y - 135, 1100)
    picture, moved = stock.r51.visible_orb(device, "r54-position")
    assert moved != bounds, (bounds, moved)
    normal_unlock(device, "r54-normal-unlock", picture, moved)
    old, _ = receipt.copy(device, "r54-before-upgrade", receipt.BASE)
    before = seeded.prefs(device, "r54-prefs")
    assert before["active"] == widget.decode() and before["sizeDp"] == "112"
    raw = device.adb("install", "-r", args.apk, timeout=90)
    device.save("r55-install-r.txt", raw)
    assert b"Success" in raw
    device.save("r55-package.txt", device.adb("shell", "dumpsys", "package", PKG))
    open_dashboard(device, "r55-launcher")
    assert device.service_connected()
    check_sentinel(device, work)
    after = seeded.prefs(device, "r55-after-install")
    for key in ("sizeDp", "active", "enabled", "intended", "epoch", "centerX", "centerY", "style56", "style112"):
        assert before.get(key) == after.get(key), (key, before.get(key), after.get(key))
    assert after.get("permanentOrb", "false") == "false"
    retained, _ = receipt.copy(device, "r54-recopied-by-r55", receipt.BASE)
    assert old == retained
    device.note("PASS actual signed install -r, launcher, seeded ledger, binding, positions and styles, default OFF, V1 retained")
    return widget, moved


def normal(device, args, widget, placement, enabled):
    stock.home(device)
    set_permanent(device, enabled)
    setting = "enabled" if enabled else "disabled"
    device.shell("settings", "put", "secure", "doze_always_on", "0")
    frame, bounds = painted_wake(device, f"r55-{setting}")
    assert bounds == placement, (bounds, placement)
    normal_unlock(device, f"r55-{setting}-ordinary", frame, bounds)
    raw, fields = receipt.copy(device, f"r55-{setting}-ordinary", args.sha)
    check_owner(fields, widget)
    if fields["reason"] == "RESTRICTED":
        assert b"APP_WINDOW_PRESENT" in raw and b"confirmation" in raw
    body = ambient_copy(device, f"r55-{setting}-system-aod-off", args.sha)
    assert b"APP_SUBMITTED" not in body
    device.note(f"PASS settled ordinary unlock and actual clipboard with Permanens ORB {setting}")
    return fields["attachment"]


def restart(device):
    stock.home(device)
    set_permanent(device, True)
    old = device.shell("pidof", PKG).split()
    assert old and all(pid.isdecimal() for pid in old)
    device.shell("kill", "-9", *old)
    open_dashboard(device, "r55-service-app-restarted")
    assert set(old).isdisjoint(device.shell("pidof", PKG).split())
    assert device.service_connected() and masks.prefs(device)["permanentOrb"] == "true"
    device.note("PASS preference through real app and service process restart")


def ambient(device, args, enabled):
    stock.home(device)
    set_permanent(device, enabled)
    masks.settings(device)
    device.click("1×1 (56 dp)", package=PKG)
    masks.select_style(device, 56, "fluviMask")
    name = "ambient-on" if enabled else "ambient-off-control"
    device.shell("settings", "put", "secure", "doze_enabled", "1")
    device.shell("settings", "put", "secure", "doze_always_on", "1")
    device.save(name + "-before-power.txt", device.adb("shell", "dumpsys", "power"))
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    began = time.monotonic()
    states = []
    for target in (1, 3, 10):
        time.sleep(max(0, began + target - time.monotonic()))
        state = stock.r51.system_state(device, f"{name}-{target}s")
        states.append(state)
        device.save(f"{name}-{target}s.png", device.adb("exec-out", "screencap", "-p"))
        layers = device.adb("shell", "dumpsys", "SurfaceFlinger", "--list")
        device.save(f"{name}-{target}s-layers.txt", layers)
        assert not (b"Fluvi Ambient ORB" in layers and b"Fluvi Balance ORB" in layers)
    device.shell("input", "keyevent", "KEYCODE_WAKEUP")
    stock.r51.poll_state(device, name + "-wake", "ON", True)
    picture, bounds = stock.r51.visible_orb(device, name + "-normal-return")
    assert b"Fluvi Ambient ORB" not in device.adb("shell", "dumpsys", "window", "windows")
    normal_unlock(device, name + "-ordinary-return", picture, bounds)
    body = ambient_copy(device, name, args.sha)
    requested = f"requested={str(enabled).lower()}".encode()
    assert requested in body, body
    eligible_sample = any(state[0] in {"DOZE", "DOZE_SUSPEND"} for state in states)
    eligible_receipt = re.search(rb"displayState=[34] locked=true interactive=false gate=DOZE\b", body)
    submitted = b"APP_SUBMITTED" in body
    if not enabled:
        assert not submitted
    if submitted:
        assert eligible_receipt and b"REVOKED" in body, body
    outcome = {"states": states, "eligible_system_sample": eligible_sample, "drawable_app_state": bool(eligible_receipt),
               "app_submitted": submitted, "optical": "UNOBSERVED"}
    device.save(name + ".json", (json.dumps(outcome) + "\n").encode())
    if eligible_receipt and enabled:
        assert submitted, "Drawable locked DOZE reached without a static app submission"
    device.note(f"{name} " + ("OBSERVED receipt" if eligible_sample or eligible_receipt else "NOT REACHED true AOD"))


def main():
    parser = argparse.ArgumentParser()
    for key in ("baseline", "apk", "observer", "output"):
        parser.add_argument("--" + key, type=Path, required=True)
    parser.add_argument("--sha", required=True)
    args = parser.parse_args()
    device = stock.r51.Device(args.output)
    steps = {}
    def run(label, run_case):
        try:
            result = run_case()
        except stock.EXPERIMENT_FAILURES as exc:
            steps[label] = f"FAIL {exc}"
            device.note(steps[label])
            device.save(label + "-failure.png", device.adb("exec-out", "screencap", "-p"))
            return None
        steps[label] = "PASS"
        return result
    try:
        with tempfile.TemporaryDirectory() as temp:
            state = run("update", lambda: upgrade(device, args, Path(temp)))
            if state is None:
                raise AssertionError("Signed upgrade prerequisites failed")
            widget, placement = state
            off = run("ordinary-off", lambda: normal(device, args, widget, placement, False))
            on = run("ordinary-on", lambda: normal(device, args, widget, placement, True))
            if off and on:
                assert off != on
            run("restart", lambda: restart(device))
            run("system-aod-off-switch", lambda: ambient(device, args, False))
            run("system-aod-on-switch", lambda: ambient(device, args, True))
            assert all(value == "PASS" for value in steps.values()), steps
    finally:
        device.save("steps.json", (json.dumps(steps, indent=2) + "\n").encode())
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

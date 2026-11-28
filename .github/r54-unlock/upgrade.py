"""Exercise the signed products and recover the real Flutter UI clipboard."""
import argparse
import hashlib
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time

import mask_controls as masks
import r52_measure as stock
import signed_upgrade as prior

R52 = "7705f87c0c8f2bdf930a528b5bc6f87d276676a5"
PKG = stock.PKG
COPY = "Legutóbbi feloldás másolása"
REPORT = prior.DATA + "/no_backup/wa-last-unlock.txt"


def screenshot(device, name):
    device.save(name + ".png", device.adb("exec-out", "screencap", "-p"))


def last_copy(device, name, sha, debug=False):
    if debug:
        stock.panel(device)
        assert "Leállítás" not in stock.labels(device)
    else:
        masks.settings(device)
    device.save(name + "-before.xml", device.screen())
    device.click(COPY, package=PKG)
    device.click("A feloldási napló a vágólapon van.", package=PKG, limit=8)
    device.save(name + "-after.xml", device.screen())
    screenshot(device, name + "-after")
    witness = stock.WITNESS
    device.shell("run-as", witness, "rm", "-f", "files/paste.txt")
    device.shell("am", "start", "-S", "-W", "-n", witness + "/.ClipboardWitness", "--ez", "paste", "true")
    deadline = time.monotonic() + 6
    while time.monotonic() < deadline:
        probe = subprocess.run(["adb", "shell", "run-as", witness, "test", "-s", "files/paste.txt"],
                               timeout=4, check=False, capture_output=True)
        if probe.returncode == 0:
            break
        time.sleep(.15)
    data = device.adb("exec-out", "run-as", witness, "cat", "files/paste.txt")
    device.save(name + "-clipboard.txt", data)
    assert data.startswith(b"FLUVI_WA_LAST_UNLOCK_V1\n") and len(data) <= 4096
    body, digest = data.rsplit(b"bodySha256=", 1)
    assert digest == hashlib.sha256(body).hexdigest().encode() + b"\n"
    fields = dict(re.findall(r"(\w+)=([^\s]+)", body.decode()))
    assert fields["build"] == sha and fields["package"] == PKG
    assert fields["code"] == "7" and fields["version"] == "0.1.5"
    assert fields["reason"] in ("UNLOCKED", "USER_PRESENT")
    device.note(f"COPY {name} bytes={len(data)} SHA-256={hashlib.sha256(data).hexdigest()}")
    return data, fields


def painted_wake(device, name):
    device.shell("input", "keyevent", "KEYCODE_HOME")
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    stock.independent_state(device, name + "-sleep", stock.sleeping)
    return stock.r51.wake(device, name)


def normal_unlock(device, name, image, bounds):
    x = image.width // 5
    if bounds[0] <= x <= bounds[2]:
        x = image.width * 4 // 5
    device.save(name + "-swipe.txt", stock.unlock(device, x, image.height).encode())
    stock.independent_state(device, name, lambda s: s == ("ON", "false", "true"))
    _, after = device.capture(name + "-settled")
    assert after is None, "Attached WA root remained"


def check_sentinel(device, work):
    disk = work / "updated.db"
    device.adb("pull", prior.DB, disk)
    if device.shell(f"if test -f {prior.DB}-wal; then echo present; fi") == "present":
        device.adb("pull", prior.DB + "-wal", str(disk) + "-wal")
    with sqlite3.connect(disk) as db:
        assert db.execute("SELECT note,amount_scaled_100 FROM fluvi_ledger_entries WHERE id=?",
                          (prior.ENTRY,)).fetchone() == ("R52 update fixture", 12345)
        assert db.execute("PRAGMA foreign_key_check").fetchall() == []


def check_owner(fields, widget):
    for key, value in {
        "presenter": "SURFACE_CHILD", "childHide": "APPLIED", "api": "37", "display": "0",
        "widget": widget.decode(), "sizeDp": "112", "style": "ORB", "removeDetached": "true",
        "hostStopStatus": "STOPPED", "physicalLastOrbPixel": "UNOBSERVED",
    }.items():
        assert fields[key] == value, (key, value, fields)
    stages = ("decision", "childHideRequest", "childApplyReturn", "localHide",
              "removeBegin", "detach", "removeReturn", "hostStop")
    times = [int(fields[stage + "ElapsedNs"]) for stage in stages]
    assert times == sorted(times), (stages, times)


def wait_for_root(device):
    """A successful adb root can close the existing transport before replying."""
    deadline = time.monotonic() + 32
    while time.monotonic() < deadline:
        try:
            device.adb("wait-for-device", timeout=6)
            if device.shell("id", "-u", timeout=4) == "0":
                device.note("ADB ready after the userdebug adbd restart")
                return
        except (OSError, subprocess.SubprocessError) as error:
            device.note(f"Awaiting emulator transport {error}")
            time.sleep(.5)
            continue
        try:
            reply = device.adb("root", timeout=5)
            device.note(reply.decode(errors="replace").strip())
        except (OSError, subprocess.SubprocessError) as error:
            device.note(f"adbd restart interrupted the transport {error}")
        time.sleep(1)
    raise AssertionError("The API 37 userdebug adbd did not become root")


def run(device, args, work):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    device.note("Stock fingerprint " + device.shell("getprop", "ro.build.fingerprint"))
    wait_for_root(device)
    for apk in (args.baseline, args.observer):
        assert b"Success" in device.adb("install", apk, timeout=90)
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    stock.r51.poll_state(device, "before-r52", "ON", False)
    device.shell("am", "start", "-W", "-n", stock.r51.ACTIVITY)
    prior.seed(device, work)
    masks.settings(device)
    widget = stock.r51.stock.prepare_binding(device)
    device.click("2×2 (112 dp)", package=PKG)
    masks.select_style(device, 56, "fluviMask")
    _, original = painted_wake(device, "r52-original")
    x, y = (original[0] + original[2]) // 2, (original[1] + original[3]) // 2
    device.shell("input", "draganddrop", x, y, original[0], y - 140, 1100)
    baseline, moved = stock.r51.visible_orb(device, "r52-moved")
    assert original != moved, (original, moved)
    normal_unlock(device, "r52-normal", baseline, moved)
    masks.settings(device)
    device.save("r52-settings.xml", device.screen())
    assert COPY not in stock.labels(device)
    assert device.shell(f"test ! -f {REPORT} && echo absent") == "absent"
    device.note("RED signed R52 ordinary unlock had no settings export")
    before = prior.prefs(device, "r52-prefs")
    assert before["active"] == widget.decode() and before["sizeDp"] == "112"
    stock.arm(device, "r52-compatibility", 50)
    old = stock.copy(device, "r52-frozen", R52, 2, 50)

    installed = device.adb("install", "-r", args.apk, timeout=90)
    device.save("r54-install-r.txt", installed)
    assert b"Success" in installed
    device.save("r54-package.txt", device.adb("shell", "dumpsys", "package", PKG))
    device.shell("am", "start", "-W", "-n", stock.r51.ACTIVITY)
    assert device.service_connected()
    assert {"Beállítások", "Settings"}.intersection(stock.labels(device))
    screenshot(device, "r54-launcher-dashboard")
    device.save("r54-dashboard.xml", device.screen())
    check_sentinel(device, work)
    after = prior.prefs(device, "r54-prefs")
    for key in ("sizeDp", "active", "enabled", "intended", "epoch", "centerX", "centerY", "style56", "style112"):
        assert before.get(key) == after.get(key), (key, before.get(key), after.get(key))
    assert old == stock.copy(device, "r54-frozen-r52-recopy", R52, 2, 50)
    assert device.shell(f"test ! -f {REPORT} && echo absent") == "absent"
    device.note("PASS signed install -r, binding, size, placement, styles, frozen recorder and ledger")

    first, bounds = painted_wake(device, "r54-unarmed")
    assert bounds == moved, (bounds, moved)
    layers = device.adb("shell", "dumpsys", "SurfaceFlinger", "--list")
    device.save("r54-sf-wake.txt", layers)
    assert b"Fluvi Balance ORB" in layers and b"SurfaceControlViewHost" in layers
    device.save("r54-sf-full-wake.txt", device.adb("shell", "dumpsys", "SurfaceFlinger"))
    normal_unlock(device, "r54-unarmed", first, bounds)
    a, fields = last_copy(device, "r54-settings-unlock", args.sha)
    check_owner(fields, widget)
    b, debug = last_copy(device, "r54-debug-unlock", args.sha, debug=True)
    assert debug["attachment"] == fields["attachment"]
    if a != b:
        a, _ = last_copy(device, "r54-settings-unlock-after-receipt", args.sha)
    assert a == b
    device.note("PASS ordinary swipe, product settings and debug clipboard match")

    previous_pid = device.shell("pidof", PKG).split()
    device.shell("am", "force-stop", PKG)
    masks.settings(device)
    assert device.service_connected()
    assert set(previous_pid).isdisjoint(device.shell("pidof", PKG).split())
    assert last_copy(device, "r54-restarted-unlock", args.sha)[0] == a
    device.note("PASS automatic report survived a new app and service process")

    _, origin = painted_wake(device, "r54-new-owner")
    x, y = (origin[0] + origin[2]) // 2, (origin[1] + origin[3]) // 2
    device.shell("input", "draganddrop", x, y, x + 125, y - 125, 1100)
    _, destination = stock.r51.visible_orb(device, "r54-child-moved")
    assert destination != origin, "Embedded AppWidget input failed to drag"
    saved = prior.prefs(device, "r54-prefs-dragged")
    assert (saved["centerX"], saved["centerY"]) != (after["centerX"], after["centerY"])
    device.shell("input", "keyevent", "KEYCODE_SLEEP")
    stock.independent_state(device, "r54-relock", stock.sleeping)
    shown, bounds = stock.r51.wake(device, "r54-relock")
    assert bounds == destination
    assert a == device.adb("exec-out", "cat", REPORT), "Locked sleep overwrote the final unlock"
    normal_unlock(device, "r54-relock-unlock", shown, bounds)
    _, latest = last_copy(device, "r54-relock-unlock", args.sha)
    check_owner(latest, widget)
    assert latest["attachment"] != fields["attachment"]
    device.note("PASS child drag and saved placement, visible locked sleep, fresh successor")


def main():
    parser = argparse.ArgumentParser()
    for key in ("baseline", "apk", "observer", "output"):
        parser.add_argument("--" + key, type=Path, required=True)
    parser.add_argument("--sha", required=True)
    args = parser.parse_args()
    device = stock.r51.Device(args.output)
    try:
        with tempfile.TemporaryDirectory() as work:
            run(device, args, Path(work))
    except stock.EXPERIMENT_FAILURES as error:
        device.note(f"FAIL {error}")
        try:
            screenshot(device, "first-divergence")
        except stock.EXPERIMENT_FAILURES as capture_error:
            device.note(f"Could not capture the failure {capture_error}")
        raise
    finally:
        try:
            device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))
        except stock.EXPERIMENT_FAILURES as log_error:
            device.note(f"Could not retrieve logcat {log_error}")


if __name__ == "__main__":
    main()

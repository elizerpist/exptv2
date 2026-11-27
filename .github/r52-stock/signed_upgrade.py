"""Exact signed R51 to R52 update on a disposable stock AVD."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET

import r52_measure as experiment
r51 = experiment.r51
PKG = r51.PKG
DATA = "/data/user/0/" + PKG
DB = DATA + "/databases/fluvi_core.db"
PREFS = DATA + "/shared_prefs/fluvi_balance_orb.xml"
ENTRY = "01KASP8G240000000000000001"
PARTNER = "01KASP8G240000000000000002"


def prefs(device, name):
    data = device.adb("exec-out", "cat", PREFS)
    device.save(name + ".xml", data)
    return {node.attrib["name"]: node.get("value", node.text) for node in ET.fromstring(data)}


def seed(device, work):
    for _ in range(10):
        if device.shell("if test -f " + DB + "; then echo ready; fi") == "ready":
            break
        time.sleep(.5)
    disk = work / "seed.db"
    device.shell("am", "force-stop", PKG)
    device.adb("pull", DB, disk)
    if device.shell("if test -f " + DB + "-wal; then echo ready; fi") == "ready":
        device.adb("pull", DB + "-wal", str(disk) + "-wal")
    with sqlite3.connect(disk) as db:
        db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        db.execute("PRAGMA journal_mode=DELETE")
        category, = db.execute("SELECT id FROM fluvi_categories WHERE is_system_uncategorized=1").fetchone()
        db.execute("INSERT INTO fluvi_partners VALUES(?, ?, NULL, ?, NULL, 1000, 1000)",
                   (PARTNER, "Synthetic fixture", category))
        db.execute("""INSERT INTO fluvi_ledger_entries VALUES(?, ?, ?, 'partnerDefault',
            ?, 'expense', 12345, 20784, 600, 1795600800000, 'manual', NULL, NULL, 1000, 1000, 1)""",
                   (ENTRY, PARTNER, category, "R52 update fixture"))
    device.adb("push", disk, "/data/local/tmp/r51-seed.db")
    device.shell(f"cat /data/local/tmp/r51-seed.db > {DB}; rm -f {DB}-wal {DB}-shm /data/local/tmp/r51-seed.db")


def upgrade(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    device.note("Disposable signed in-place update on " + device.shell("getprop", "ro.build.fingerprint"))
    device.adb("root")
    device.adb("wait-for-device")
    assert device.shell("id", "-u") == "0"
    assert b"Success" in device.adb("install", args.baseline)
    assert b"Success" in device.adb("install", args.observer)
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
    with tempfile.TemporaryDirectory() as temp:
        work = Path(temp)
        seed(device, work)
        device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
        r51.stock.enter_settings(device)
        widget = r51.stock.prepare_binding(device)
        device.click("2×2 ORB", package=PKG)
        device.shell("input", "keyevent", "KEYCODE_HOME")
        device.shell("input", "keyevent", "KEYCODE_SLEEP")
        r51.poll_state(device, "r50-pre-lock", "OFF", True)
        _, original = r51.wake(device, "r50-original")
        x, y = (original[0] + original[2]) // 2, (original[1] + original[3]) // 2
        device.shell("input", "draganddrop", x, y, 70, y, 1100)
        _, moved = r51.visible_orb(device, "r50-moved")
        before = prefs(device, "r50-prefs")
        assert before["active"] == widget.decode() and before["sizeDp"] == "112"
        # Restore from an actual committed drop if reached; preserve the reported baseline
        # endpoint and state independently of whether this gesture moved the root.
        device.note(f"R51 original root={original} post-drag={moved}")
        device.shell("wm", "dismiss-keyguard")
        r51.poll_state(device, "r50-update-ready", "ON", False)

        experiment.panel(device)
        assert "A · 50 ms" not in experiment.labels(device)
        device.note("RED installed R51 has no 50/0 arm choice")
        device.click("Felvétel indítása", package=PKG)
        old = experiment.copy(device, "r51-original-v1", experiment.BASE, 1)
        receipt = device.adb("install", "-r", args.apk, timeout=90)
        device.save("r52-install-r.txt", receipt)
        assert b"Success" in receipt
        device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
        assert device.service_connected(), "Installed update did not reconnect the same enabled service"
        after = prefs(device, "r52-prefs")
        for key in ("sizeDp", "active", "enabled", "intended", "epoch", "centerX", "centerY"):
            assert before.get(key) == after.get(key), (key, before.get(key), after.get(key))
        appwidget = device.adb("shell", "dumpsys", "appwidget")
        device.save("r52-appwidget.txt", appwidget)
        assert b"FluviHeaderOrbWidgetProvider" in appwidget
        matched = re.search(rb"(?m)^  \[\d+\] id=" + widget + rb"\b(.*?)(?=^  \[|^Hosts:)", appwidget, re.S)
        assert matched and b"hostId:1003" in matched[1] and b"FluviHeaderOrbWidgetProvider" in matched[1]
        device.shell("input", "keyevent", "KEYCODE_HOME")
        device.shell("input", "keyevent", "KEYCODE_SLEEP")
        r51.poll_state(device, "r51-pre-lock", "OFF", True)
        _, restored = r51.wake(device, "r51-restored")
        assert restored == moved, (moved, restored)
        experiment.home(device)
        recopy = experiment.copy(device, "r52-recopy-r51-v1", experiment.BASE, 1)
        assert old == recopy, "V1 frozen report changed after update"
        for timeout in (50, 0):
            name = f"r52-upgrade-{timeout}"
            experiment.arm(device, name, timeout)
            first = experiment.copy(device, name, args.sha, 2, timeout, stop=timeout == 0)
            assert first == experiment.copy(device, name + "-recopy", args.sha, 2, timeout)
        device.note("PASS real updated capture panel, both arm readbacks, 50 ms restore, exact V1 re-copy")
        device.shell("am", "force-stop", PKG)
        disk = work / "after.db"
        device.adb("pull", DB, disk)
        if device.shell("if test -f " + DB + "-wal; then echo ready; fi") == "ready":
            device.adb("pull", DB + "-wal", str(disk) + "-wal")
        with sqlite3.connect(disk) as db:
            assert db.execute("SELECT note,amount_scaled_100 FROM fluvi_ledger_entries WHERE id=?",
                              (ENTRY,)).fetchone() == ("R52 update fixture", 12345)
            assert db.execute("PRAGMA foreign_key_check").fetchall() == []
    device.note("PASS signed adb install -r over R51, synthetic ledger, existing host/widget, size and position")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    device = r51.Device(args.output)
    try:
        upgrade(device, args)
    except (AssertionError, OSError, subprocess.SubprocessError) as failure:
        device.note(f"FAIL update: {failure}")
        device.save("first-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

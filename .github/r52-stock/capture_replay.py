"""Independent V1 replay, actual Human panel and interrupted native capture."""
import argparse
from pathlib import Path
import subprocess
import time

import r52_measure as measure
import auxiliary

PKG = measure.PKG
FROZEN = f"/data/user/0/{PKG}/no_backup/wa-lockscreen-frozen.txt"


def exercise(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    for _ in range(4):
        device.adb("wait-for-device", timeout=8)
        try:
            if device.shell("id", "-u", timeout=4) == "0":
                break
            device.adb("root", timeout=6)
        except subprocess.SubprocessError as error:
            device.note(f"Observer waiting for disposable adbd: {error}")
        time.sleep(.5)
    else:
        raise AssertionError("No rooted disposable AVD")
    args.api = "37.0"
    measure.prepare(device, args)
    fixture = Path(__file__).with_name("synthetic-r51-v1.txt")
    expected = fixture.read_bytes()
    owner = device.shell("stat", "-c", "%u:%g", "/data/user/0/" + PKG)
    device.adb("push", fixture, "/data/local/tmp/r52-previous-synthetic.txt")
    device.shell(f"cat /data/local/tmp/r52-previous-synthetic.txt > {FROZEN} && "
                 f"chown {owner} {FROZEN} && chmod 660 {FROZEN} && restorecon {FROZEN}")
    assert measure.copy(device, "replayed-stock-r51-v1", measure.BASE, 1) == expected
    assert measure.copy(device, "replayed-stock-r51-v1-again", measure.BASE, 1) == expected
    device.note("PASS exact old V1 bytes delivered by the real combined panel twice")
    last = None
    for arm in (50, 0):
        name = f"arm-{arm}"
        measure.arm(device, name, arm)
        last = measure.copy(device, name, args.sha, 2, arm, stop=arm == 0)
    assert last
    measure.arm(device, "interrupted-b", 0)
    owners = device.shell("pidof", PKG).split()
    assert len(owners) == 1 and owners[0].isdigit()
    device.shell("kill", "-KILL", owners[0])
    measure.panel(device)
    assert owners[0] not in device.shell("pidof", PKG).split()
    auxiliary.wait_label(device, "A felvétel megszakadt")
    assert measure.copy(device, "retained-after-death", args.sha, 2) == last
    assert device.service_connected()
    measure.panel(device)
    auxiliary.wait_label(device, "Visszaállítva: 50 ms")
    device.note("PASS new process kept the previous frozen bytes, flagged interrupted B and verified 50 ms")
    measure.arm(device, "expiry", 0)
    time.sleep(91)
    measure.panel(device)
    auxiliary.wait_label(device, "Visszaállítva: 50 ms")
    final = measure.copy(device, "expired-b", args.sha, 2, 0)
    assert b"stop=LIMIT" in final
    device.note("PASS elapsed capture expiry restored the framework value")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    device = measure.r51.Device(args.output)
    try:
        exercise(device, args)
    except Exception as error:
        device.note(f"FAIL replay: {error}")
        device.save("first-replay-divergence.png", device.adb("exec-out", "screencap", "-p"))
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

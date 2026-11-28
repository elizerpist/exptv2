"""Same signed candidate on the last pre-SurfaceView product route."""
import argparse
from pathlib import Path

import mask_controls as masks
import r52_measure as stock
from upgrade import last_copy, normal_unlock, painted_wake, screenshot


def main():
    parser = argparse.ArgumentParser()
    for key in ("apk", "observer", "output"):
        parser.add_argument("--" + key, type=Path, required=True)
    parser.add_argument("--sha", required=True)
    args = parser.parse_args()
    device = stock.r51.Device(args.output)
    try:
        assert device.shell("getprop", "ro.kernel.qemu") == "1"
        assert device.shell("getprop", "ro.build.version.sdk") == "33"
        device.note("Older platform " + device.shell("getprop", "ro.build.fingerprint"))
        for apk in (args.apk, args.observer):
            assert b"Success" in device.adb("install", apk, timeout=90)
        device.shell("wm", "dismiss-keyguard")
        device.shell("locksettings", "set-disabled", "false")
        masks.settings(device)
        widget = stock.r51.stock.prepare_binding(device)
        device.click("2×2 (112 dp)", package=stock.PKG)
        image, bounds = painted_wake(device, "api33")
        screenshot(device, "legacy-painted")
        normal_unlock(device, "api33-normal-unlock", image, bounds)
        _, record = last_copy(device, "api33-normal-unlock", args.sha)
        assert record["widget"] == widget.decode()
        assert record["presenter"] == "LEGACY_API" and record["childHide"] == "UNSUPPORTED"
        assert record["removeDetached"] == "true"
        device.note("PASS same signed product on API 33, visible legacy widget and normal unlock clipboard")
    except stock.EXPERIMENT_FAILURES as error:
        device.note(f"FAIL legacy: {error}")
        screenshot(device, "legacy-first-divergence")
        raise
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

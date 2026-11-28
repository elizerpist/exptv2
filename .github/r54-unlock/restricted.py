"""Independently witness shade and PIN before checking the signed R54 pixels."""
import argparse
from pathlib import Path

import auxiliary
import mask_controls as masks
import r52_measure as stock
from upgrade import painted_wake, screenshot


def run(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    for apk in (args.apk, args.observer):
        assert b"Success" in device.adb("install", apk, timeout=90)
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    masks.settings(device)
    stock.r51.stock.prepare_binding(device)
    device.click("2×2 (112 dp)", package=stock.PKG)
    assert "Pin set" in device.shell("locksettings", "set-pin", auxiliary.PIN)
    failures = []
    try:
        for label, pattern, enter in (
            ("shade", rb"quick_settings_panel|tile_label|Settings button|qs_footer|SplitShade",
             ("cmd", "statusbar", "expand-settings")),
            ("pin", rb"keyguard_(?:host_view|security_container)|BouncerContent|Enter (?:your )?PIN",
             ("input", "keyevent", "KEYCODE_MENU")),
        ):
            try:
                painted_wake(device, "before-" + label)
                device.shell(*enter)
                screenshot(device, label + "-first")
                auxiliary.wait_restricted(device, label, pattern)
            except stock.EXPERIMENT_FAILURES as error:
                failures.append((label, str(error)))
                device.note(f"{label} incomplete {error}")
            finally:
                if label == "shade":
                    device.shell("cmd", "statusbar", "collapse")
                else:
                    device.shell("input", "text", auxiliary.PIN)
                    device.shell("input", "keyevent", "KEYCODE_ENTER")
        assert not failures, failures
    finally:
        device.shell("locksettings", "clear", "--old", auxiliary.PIN)


def main():
    parser = argparse.ArgumentParser()
    for key in ("apk", "observer", "output"):
        parser.add_argument("--" + key, type=Path, required=True)
    args = parser.parse_args()
    device = stock.r51.Device(args.output)
    try:
        run(device, args)
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

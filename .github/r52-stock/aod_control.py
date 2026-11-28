"""One separate AOD attempt after the ordinary OFF experiment was defined."""
import argparse
from pathlib import Path
import time

import r52_measure as measure


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.api = "37.0"
    device = measure.r51.Device(args.output)
    rows = []
    anchors = {}
    try:
        measure.prepare(device, args)
        device.shell("settings", "put", "secure", "doze_enabled", "1")
        device.shell("settings", "put", "secure", "doze_always_on", "1")
        measure.home(device)
        measure.arm(device, "aod-control", 50)
        with measure.witnesses(device, "aod-control"):
            anchors["start"] = measure.set_reference(device, 1, "aod-start")
            time.sleep(.18)
            measure.set_reference(device, 0, "aod-start-neutral")
            rows.append(measure.trial(device, "aod-control-sleep", "sleep"))
            measure.home(device)
            anchors["end"] = measure.set_reference(device, 2, "aod-end")
            time.sleep(.25)
            measure.set_reference(device, 0, "aod-end-neutral")
        software = measure.copy(device, "aod-control", args.sha, 2, 50)
        measure.save_run(device, "aod-control", 50, rows, anchors, software)
        if rows[0].get("state_after", ["UNOBSERVED"])[0] not in ("DOZE", "DOZE_SUSPEND"):
            device.note(f"AOD optical NOT RUN: actual independent state {rows[0].get('state_after')}")
        else:
            device.note(f"AOD state witnessed: {rows[0]['state_after']}")
        assert rows[0]["fixture"] == "VALID_SOFTWARE"
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

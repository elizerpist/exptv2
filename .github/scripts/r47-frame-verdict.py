#!/usr/bin/env python3
"""Conservative frame-correlation decisions; no timing is inferred from a PNG.

Input rows are *observations* produced by a separately validated video/marker
collector. A marker number identifies an app-produced host buffer, not by
itself a SurfaceFlinger display frame or a physical presentation. A case is
conclusive only when the adjacent captured frames are correlated to distinct,
actual display frame tokens, the capture clock is mapped, and both controlled
calibrations are proven. Otherwise the result is NOT_DECIDABLE.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

STATES = {"ALLOWED", "FORBIDDEN", "RELOCK"}
ORBS = {"VISIBLE", "CLEAR", "UNKNOWN"}


def boundary(frames: list[dict]) -> tuple[dict, dict, dict] | None:
    if len(frames) < 3:
        return None
    for index in range(1, len(frames) - 1):
        before, first, after = frames[index - 1:index + 2]
        if before.get("state") != "ALLOWED" or first.get("state") != "FORBIDDEN" or after.get("state") != "FORBIDDEN":
            continue
        ids = [item.get("marker_seq") for item in (before, first, after)]
        if any(type(value) is not int or value < 0 for value in ids) or ids != list(range(ids[0], ids[0] + 3)):
            return None
        captures = [item.get("capture_index") for item in (before, first, after)]
        if any(type(value) is not int for value in captures) or captures != list(range(captures[0], captures[0] + 3)):
            return None
        times = [item.get("capture_elapsed_ns") for item in (before, first, after)]
        if any(type(value) is not int or value < 0 for value in times) or not (times[0] < times[1] < times[2]):
            return None
        if any(item.get("orb") not in ORBS - {"UNKNOWN"} for item in (before, first, after)):
            return None
        if before["orb"] != "VISIBLE":
            return None
        return before, first, after
    return None


def control_verdict(control: dict, kind: str) -> str:
    if control.get("capture_clock") != "VALIDATED" or control.get("scene_calibration") != "PASS":
        return "NOT_DECIDABLE"
    triple = boundary(control.get("frames", []))
    if triple is None:
        return "NOT_DECIDABLE"
    _, first, after = triple
    expected = ("CLEAR", "CLEAR") if kind == "clean" else ("VISIBLE", "CLEAR")
    return "PASS" if (first["orb"], after["orb"]) == expected else "FAIL"


def observation(case: dict, controls: dict) -> dict:
    result = {"status": "NOT_DECIDABLE", "first_forbidden_capture": "UNOBSERVED",
              "first_forbidden_display_token": "UNOBSERVED", "screenshot_frame": "UNOBSERVED",
              "earliest_divergence": "UNPROVEN", "reasons": []}
    if controls.get("clean") != "PASS" or controls.get("one_frame") != "PASS":
        result["reasons"].append("calibration_controls_not_both_passed")
    if case.get("capture_clock") != "VALIDATED":
        result["reasons"].append("capture_clock_unavailable")
    if case.get("scene_calibration") != "PASS":
        result["reasons"].append("scene_not_calibrated")
    owner = case.get("owner", {})
    if not all(type(owner.get(k)) is int and owner[k] > 0 for k in ("window", "attachment", "orb_generation")):
        result["reasons"].append("owner_not_identified")
    times = case.get("times", {})
    keys = ("restriction_elapsed_ns", "conceal_enter_elapsed_ns", "conceal_return_elapsed_ns")
    if not all(type(times.get(k)) is int and times[k] >= 0 for k in keys):
        result["reasons"].append("event_or_conceal_time_missing")
    elif not times[keys[0]] <= times[keys[1]] <= times[keys[2]]:
        result["reasons"].append("event_or_conceal_time_invalid")
    triple = boundary(case.get("frames", []))
    if triple is None:
        result["reasons"].append("first_forbidden_capture_not_identifiable")
        return result
    before, first, after = triple
    result["first_forbidden_capture"] = {"capture_index": first["capture_index"],
        "capture_elapsed_ns": first["capture_elapsed_ns"], "marker_seq": first["marker_seq"], "orb": first["orb"]}
    tokens = [row.get("display_frame_token") for row in (before, first, after)]
    if any(type(token) is not int or token <= 0 for token in tokens) or len(set(tokens)) != 3:
        result["reasons"].append("actual_display_frame_tokens_unobserved")
    elif not all(row.get("presented") is True for row in (before, first, after)):
        result["reasons"].append("actual_presentation_unobserved")
    else:
        result["first_forbidden_display_token"] = first["display_frame_token"]
    shot = case.get("first_screenshot", {})
    screenshot_token = shot.get("display_frame_token")
    if type(screenshot_token) is int and screenshot_token > 0 and screenshot_token in tokens:
        result["screenshot_frame"] = screenshot_token
    else:
        result["reasons"].append("screenshot_display_frame_token_unobserved")
    if not result["reasons"]:
        result["status"] = "ORB_PRESENT" if first["orb"] == "VISIBLE" else "ORB_ABSENT"
        # A commit or elapsed time alone cannot prove which surface caused a
        # stale frame. Only independently timed, explicit evidence may classify.
        if first["orb"] == "VISIBLE" and times[keys[1]] > first["capture_elapsed_ns"]:
            result["earliest_divergence"] = "WITHDRAWAL_AFTER_FORBIDDEN_CAPTURE"
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    data = json.loads(args.input.read_text())
    controls = {name: control_verdict(data.get("controls", {}).get(name, {}), name)
                for name in ("clean", "one_frame")}
    result = {"controls": controls, "cases": [observation(case, controls) for case in data.get("cases", [])]}
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, sort_keys=True))
    return 0 if all(v == "PASS" for v in controls.values()) and all(c["status"] != "NOT_DECIDABLE" for c in result["cases"]) else 1

if __name__ == "__main__":
    raise SystemExit(main())

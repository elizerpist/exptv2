#!/usr/bin/env python3
"""Fail-closed arithmetic for the predeclared R15 two-block comparison.

Input rows must first be extracted from verified installed-package, process,
raw acquisition and independently calibrated recording artifacts. This module
does not manufacture or authenticate those artifacts and cannot qualify an APK.
"""
from __future__ import annotations

import math
import re
import statistics
import uuid

ORDER = ((1, "stock"), (1, "candidate"), (2, "candidate"), (2, "stock"))


def _digest(value: object, length: int) -> bool:
    return isinstance(value, str) and bool(re.fullmatch(f"[0-9a-f]{{{length}}}", value))


def _uuid(value: object) -> bool:
    try:
        return isinstance(value, str) and str(uuid.UUID(value)) == value
    except (ValueError, AttributeError):
        return False


def _positive(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def _nonnegative(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0


def _slot_errors(slot: dict, process: dict, index: int) -> list[str]:
    errors = []
    if slot.get("position") != ("cold" if index == 0 else f"warm{index}"):
        errors.append("position")
    if not all(_positive(slot.get(key)) for key in ("wake", "request", "session")) or not _uuid(slot.get("capture")):
        errors.append("owner")
    if slot.get("arm") != process.get("arm") or slot.get("route") != "SURFACE_LIVE":
        errors.append("arm_or_route")
    if slot.get("eligible") not in (True, False) or not isinstance(slot.get("eligible"), bool):
        errors.append("eligibility")
    status, flags = slot.get("root_call"), slot.get("root_flags")
    if status not in ("called", "no_call") or (status == "no_call" and flags is not None):
        errors.append("root_call")
    if status == "called":
        # A real ineligible first read still uses the production argument in
        # both arms; retain it as an excluded row instead of inventing an
        # eligible opportunity or rejecting the whole observation.
        expected = 0 if process.get("arm") == "candidate" and slot.get("eligible") is True else 36
        if flags != expected:
            errors.append("first_argument_or_opportunity")
    accepted = slot.get("root_accepted")
    if not isinstance(accepted, bool) or (accepted and status != "called"):
        errors.append("root_acceptance")
    child_count, child_flags = slot.get("child_calls"), slot.get("first_child_flags")
    if not isinstance(child_count, int) or isinstance(child_count, bool) or child_count < 0:
        errors.append("child_calls")
    elif (child_count == 0 and child_flags is not None) or (child_count > 0 and child_flags != (36 if accepted else None)):
        errors.append("actual_first_child")
    if slot.get("complete") not in (True, False) or not isinstance(slot.get("complete"), bool):
        errors.append("completeness")
    if not isinstance(slot.get("classification"), str) or not slot.get("classification"):
        errors.append("classification")
    if not isinstance(slot.get("shape"), str) or not slot.get("shape"):
        errors.append("tree_shape")
    for key in ("total_read_ms", "wake_to_decision_ms"):
        if not _nonnegative(slot.get(key)):
            errors.append(key)
    onset = slot.get("onset_ms")
    if onset is not None and (not isinstance(onset, list) or len(onset) != 2
            or not all(_nonnegative(v) for v in onset) or onset[0] > onset[1]):
        errors.append("onset_interval")
    return errors


def compare(dataset: dict) -> dict:
    """Compare only matched warm slots, retaining every exclusion and bound."""
    if not _digest(dataset.get("source"), 40) or not _digest(dataset.get("app_sha256"), 64) or not _digest(dataset.get("test_sha256"), 64):
        raise ValueError("source_or_apk_identity")
    if not dataset.get("device") or not dataset.get("boot_id"):
        raise ValueError("device_or_boot_identity")
    processes = dataset.get("processes")
    if not isinstance(processes, list) or len(processes) != 4:
        raise ValueError("four_processes_required")
    seen_processes, seen_captures, seen_owner = set(), set(), set()
    for process, expected in zip(processes, ORDER):
        if (process.get("block"), process.get("arm")) != expected:
            raise ValueError("reverse_order_blocks")
        if any(process.get(k) != dataset[k] for k in ("source", "app_sha256", "test_sha256", "device", "boot_id")):
            raise ValueError("mixed_source_apk_device_or_boot")
        process_key = (process.get("pid"), process.get("start"))
        if not all(_positive(value) for value in process_key) or process_key in seen_processes:
            raise ValueError("process_identity")
        seen_processes.add(process_key)
        slots = process.get("slots")
        if not isinstance(slots, list) or len(slots) != 4:
            raise ValueError("four_slots_per_process")
        for index, slot in enumerate(slots):
            errors = _slot_errors(slot, process, index)
            if errors:
                raise ValueError("slot_invalid:" + ",".join(errors))
            # A process may have one capture covering its four wakes, but a
            # capture cannot be reused by a different process.
            capture_key = slot["capture"]
            if capture_key in seen_captures and capture_key != slots[0]["capture"]:
                raise ValueError("capture_owner_reused")
            owner_key = (process_key, slot["session"], slot["wake"], slot["request"])
            if owner_key in seen_owner:
                raise ValueError("wake_request_reused")
            seen_owner.add(owner_key)
        captures = {slot["capture"] for slot in slots}
        if seen_captures.intersection(captures):
            raise ValueError("capture_owner_reused")
        seen_captures.update(captures)

    results = []
    for block in (1, 2):
        stock = next(p for p in processes if p["block"] == block and p["arm"] == "stock")
        candidate = next(p for p in processes if p["block"] == block and p["arm"] == "candidate")
        matched, excluded = [], []
        for index in (1, 2, 3):
            a, b = stock["slots"][index], candidate["slots"][index]
            reasons = []
            if not all(row["eligible"] and row["root_call"] == "called" for row in (a, b)):
                reasons.append("first_opportunity_missing")
            if not all(row["root_accepted"] for row in (a, b)):
                reasons.append("active_root_not_accepted")
            if any(a[k] != b[k] for k in ("complete", "classification", "shape")):
                reasons.append("incomparable_first_read")
            if not a["complete"] or a["onset_ms"] is None or b["onset_ms"] is None:
                reasons.append("complete_or_visual_endpoint_missing")
            if reasons:
                excluded.append({"position": a["position"], "reasons": reasons})
                continue
            lo = b["onset_ms"][0] - a["onset_ms"][1]
            hi = b["onset_ms"][1] - a["onset_ms"][0]
            matched.append({"position": a["position"], "onset_delta_ms": [lo, hi],
                            "total_read_delta_ms": b["total_read_ms"] - a["total_read_ms"]})
        median = None if not matched else [statistics.median(row["onset_delta_ms"][0] for row in matched),
                                            statistics.median(row["onset_delta_ms"][1] for row in matched)]
        read_median = None if not matched else statistics.median(row["total_read_delta_ms"] for row in matched)
        results.append({"block": block, "matched": matched, "excluded": excluded,
                        "onset_median_delta_ms": median, "read_median_delta_ms": read_median,
                        "benefit_beyond_uncertainty": bool(matched and median[1] < 0 and read_median < 0)})
    return {"blocks": results,
            "arithmetic_benefit_in_both_blocks": all(block["benefit_beyond_uncertainty"] for block in results),
            "qualification": "NOT_ESTABLISHED_UNTIL_RAW_PROVENANCE_VISUAL_AND_ALL_GATES_PASS"}

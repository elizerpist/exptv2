#!/usr/bin/env python3
"""Synthetic comparison controls; no case here is a device measurement."""
import copy
import importlib.util
import sys
import unittest
import uuid
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("comparison", Path(__file__).with_name("keyguard-r15-comparison.py"))
comparison = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comparison)


def specimen():
    common = dict(source="a" * 40, app_sha256="b" * 64, test_sha256="c" * 64,
                  device="API35-encoder", boot_id=str(uuid.uuid4()))
    processes = []
    for index, (block, arm) in enumerate(comparison.ORDER):
        capture = str(uuid.uuid4())
        slots = []
        for position in range(4):
            slots.append(dict(position="cold" if position == 0 else f"warm{position}",
                session=index + 1, wake=position + 1, request=position + 101, capture=capture,
                arm=arm, route="SURFACE_LIVE", eligible=True, root_call="called",
                root_flags=0 if arm == "candidate" else 36, root_accepted=True,
                child_calls=2, first_child_flags=36, complete=True, classification="SHOW_FULL",
                shape="primary:35", total_read_ms=80 if arm == "candidate" else 100,
                wake_to_decision_ms=95 if arm == "candidate" else 120,
                onset_ms=[70, 80] if arm == "candidate" else [100, 110]))
        processes.append(common | dict(block=block, arm=arm, pid=100 + index, start=1_000 + index, slots=slots))
    return common | {"processes": processes}


class ComparisonControls(unittest.TestCase):
    def test_positive_bound_arithmetic_but_no_automatic_qualification(self):
        result = comparison.compare(specimen())
        self.assertTrue(result["arithmetic_benefit_in_both_blocks"])
        self.assertEqual([-40, -20], result["blocks"][0]["onset_median_delta_ms"])
        self.assertEqual(-20, result["blocks"][1]["read_median_delta_ms"])
        self.assertEqual(3, len(result["blocks"][0]["matched"]))
        self.assertTrue(result["qualification"].startswith("NOT_ESTABLISHED"))

    def test_zero_eligible_first_calls_never_uses_later_stock_row(self):
        data = specimen()
        for row in data["processes"][0]["slots"]:
            row.update(eligible=False, root_call="no_call", root_flags=None, root_accepted=False,
                       child_calls=0, first_child_flags=None)
        result = comparison.compare(data)
        self.assertFalse(result["arithmetic_benefit_in_both_blocks"])
        self.assertEqual([], result["blocks"][0]["matched"])
        self.assertEqual(3, len(result["blocks"][0]["excluded"]))

    def test_claimed_child_with_no_child_call_fails(self):
        data = specimen()
        data["processes"][1]["slots"][1]["child_calls"] = 0
        with self.assertRaisesRegex(ValueError, "actual_first_child"):
            comparison.compare(data)

    def test_ineligible_real_root_is_retained_with_stock_flags_and_excluded(self):
        data = specimen()
        row = data["processes"][1]["slots"][1]
        row.update(eligible=False, root_call="called", root_flags=36)
        result = comparison.compare(data)
        self.assertIn("first_opportunity_missing", result["blocks"][0]["excluded"][0]["reasons"])
        row["root_flags"] = 0
        with self.assertRaisesRegex(ValueError, "first_argument_or_opportunity"):
            comparison.compare(data)

    def test_real_fallback_is_retained_but_not_paired_as_an_active_root(self):
        data = specimen()
        for row in data["processes"][1]["slots"][1:]:
            row.update(root_accepted=False, first_child_flags=None)
        result = comparison.compare(data)
        self.assertEqual([], result["blocks"][0]["matched"])
        self.assertTrue(all("active_root_not_accepted" in row["reasons"] for row in result["blocks"][0]["excluded"]))

    def test_swapped_arm_request_route_and_process_are_rejected(self):
        for change in ("arm", "request", "route", "process", "source", "apk"):
            data = specimen()
            if change == "arm":
                data["processes"][0]["slots"][1]["arm"] = "candidate"
            elif change == "request":
                data["processes"][0]["slots"][1]["request"] = data["processes"][0]["slots"][0]["request"]
                data["processes"][0]["slots"][1]["wake"] = data["processes"][0]["slots"][0]["wake"]
            elif change == "route":
                data["processes"][0]["slots"][1]["route"] = "LEGACY_R11"
            elif change == "process":
                data["processes"][1]["pid"] = data["processes"][0]["pid"]
                data["processes"][1]["start"] = data["processes"][0]["start"]
            elif change == "source":
                data["processes"][1]["source"] = "d" * 40
            else:
                data["processes"][1]["test_sha256"] = "d" * 64
            with self.subTest(change=change), self.assertRaises(ValueError):
                comparison.compare(data)

    def test_incomplete_incomparable_and_unknown_pixels_are_excluded(self):
        data = specimen()
        rows = data["processes"][1]["slots"]
        rows[1]["complete"] = False
        rows[2]["shape"] = "different-window-tree"
        rows[3]["onset_ms"] = None
        result = comparison.compare(data)
        self.assertEqual(0, len(result["blocks"][0]["matched"]))
        self.assertFalse(result["arithmetic_benefit_in_both_blocks"])

    def test_overlapping_or_reversed_bounds_cannot_establish_gain(self):
        for onset in ([105, 115], [90, 110]):
            data = specimen()
            for row in data["processes"][1]["slots"]:
                row["onset_ms"] = copy.copy(onset)
            self.assertFalse(comparison.compare(data)["arithmetic_benefit_in_both_blocks"])

    def test_first_argument_must_correspond_to_selected_arm(self):
        data = specimen()
        data["processes"][1]["slots"][2]["root_flags"] = 36
        with self.assertRaisesRegex(ValueError, "first_argument_or_opportunity"):
            comparison.compare(data)


if __name__ == "__main__":
    unittest.main(verbosity=2)

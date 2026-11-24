#!/usr/bin/env python3
"""Deterministic controls for R41's per-attempt, non-optical timing report."""
import importlib.util
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
path = Path(__file__).with_name("analyze-r41.py")
spec = importlib.util.spec_from_file_location("r41_analyzer", path)
analyzer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyzer)


class R41AnalyzerTest(unittest.TestCase):
    def row(self, **changes):
        row = dict(attempt="1", eligible="true", outcome="SUCCESS", owner="4/8",
                   readOwner="4/8", dispatchOwner="4/8", grantOwner="4/8", wakeNs="100", offerNs="130", workerNs="140", readStartNs="150",
                   readEndNs="210", dispatchNs="220", mainNs="250", grantNs="290",
                   screenNs="120", dropped="0", coverage="COMPLETE")
        row.update(changes)
        return row

    def test_exclusive_segments_reconcile_and_screen_anchor_is_separate(self):
        result = analyzer.analyze(self.row())
        self.assertEqual(result["coverage"], "COMPLETE")
        self.assertEqual(result["total_ns"], 190)
        self.assertEqual(sum(result["segments_ns"].values()), 190)
        self.assertEqual(result["screen_to_grant_ns"], 170)

    def test_missing_endpoint_is_not_zero_or_a_success(self):
        result = analyzer.analyze(self.row(grantNs="UNOBSERVED"))
        self.assertEqual(result["coverage"], "INCOMPLETE")
        self.assertIsNone(result["total_ns"])
        self.assertIn("grantNs", result["missing"])

    def test_lost_or_other_owner_grant_cannot_win(self):
        for change in (dict(outcome="CANCELLED"), dict(grantOwner="4/9"), dict(readOwner="3/8"),
                       dict(dispatchOwner="UNOBSERVED")):
            result = analyzer.analyze(self.row(**change))
            self.assertEqual(result["coverage"], "INCOMPLETE")
            self.assertIsNone(result["total_ns"])

    def test_negative_intervals_are_rejected_not_clamped(self):
        result = analyzer.analyze(self.row(mainNs="199"))
        self.assertEqual(result["coverage"], "INCOMPLETE")
        self.assertTrue(result["invalid"])

    def test_joined_screen_on_can_follow_the_grant(self):
        result = analyzer.analyze(self.row(screenNs="300"))
        self.assertEqual(result["screen_to_grant_ns"], -10)
        self.assertEqual(result["coverage"], "COMPLETE")

    def test_dropped_or_unobserved_eligibility_keeps_coverage_open(self):
        for change in (dict(dropped="1"), dict(eligible="UNOBSERVED"), dict(coverage="INCOMPLETE")):
            self.assertEqual(analyzer.analyze(self.row(**change))["coverage"], "INCOMPLETE")

    def test_exactly_300ms_does_not_pass(self):
        result = analyzer.analyze(self.row(grantNs=str(100 + 300_000_000)))
        self.assertEqual(result["coverage"], "COMPLETE")
        self.assertFalse(result["under_300ms"])

    def test_every_compact_attempt_is_preserved(self):
        report = "\n".join(" R41_CORE attempt=%d eligible=UNOBSERVED" % i for i in range(1, 12))
        rows = analyzer.parse_report(report)
        self.assertEqual([int(row["attempt"]) for row in rows], list(range(1, 12)))


if __name__ == "__main__":
    unittest.main()

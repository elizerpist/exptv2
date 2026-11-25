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

    def test_compact_empty_attempt_cannot_fabricate_missing_boundaries(self):
        report = (" R41_CORE attempt=8 session=9 wake=10 systemEligible=UNOBSERVED "
                  "eligible=UNOBSERVED outcome=UNOBSERVED owner=UNOBSERVED "
                  "missing=ALL_R41_BOUNDARIES h2Claims=0 h2Enabled=false "
                  "requests=0 omitted=0 invalid=0 dropped=0 coverage=INCOMPLETE")
        result = analyzer.analyze(analyzer.parse_report(report)[0])
        self.assertEqual(result["coverage"], "INCOMPLETE")
        self.assertIsNone(result["total_ns"])
        self.assertIsNone(result["screen_to_grant_ns"])
        self.assertIsNone(result["under_300ms"])
        self.assertIn("wakeNs", result["missing"])
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

    def test_incomplete_partition_can_still_report_a_labelled_observed_interval(self):
        result = analyzer.analyze(self.row(coverage="INCOMPLETE", mainNs="UNOBSERVED"))
        self.assertEqual(result["observed_total_ns"], 190)
        self.assertIsNone(result["total_ns"])
        self.assertIsNone(result["under_300ms"])

    def test_exactly_300ms_does_not_pass(self):
        result = analyzer.analyze(self.row(grantNs=str(100 + 300_000_000)))
        self.assertEqual(result["coverage"], "COMPLETE")
        self.assertFalse(result["under_300ms"])

    def test_denial_cannot_also_be_a_success(self):
        result = analyzer.analyze(self.row(eligible="false"))
        self.assertEqual(result["coverage"], "INCOMPLETE")
        self.assertIn("denied_attempt_has_successful_winner", result["invalid"])

    def test_aggregate_requires_eligible_complete_sub_300ms_trials(self):
        denied = analyzer.analyze(self.row(eligible="false", outcome="DENIED"))
        self.assertEqual(analyzer.summarize([denied])["strict_verdict"], "INCOMPLETE")
        incomplete_denial = analyzer.analyze(self.row(eligible="false", outcome="DENIED", coverage="INCOMPLETE"))
        self.assertEqual(incomplete_denial["coverage"], "INCOMPLETE")
        successful = analyzer.analyze(self.row())
        self.assertEqual(analyzer.summarize([successful])["strict_verdict"], "PASS")
        at_limit = analyzer.analyze(self.row(grantNs=str(100 + 300_000_000)))
        self.assertEqual(analyzer.summarize([at_limit])["strict_verdict"], "FAIL")
        incomplete = analyzer.analyze(self.row(coverage="INCOMPLETE"))
        self.assertEqual(analyzer.summarize([incomplete])["strict_verdict"], "INCOMPLETE")

    def test_sampler_dispatch_bracket_is_separate_and_missing_is_not_zero(self):
        row = dict(sample="5", receipt="2", times="10/UNOBSERVED/20/30/35/45/50/70/75/UNOBSERVED",
                   tids="1/UNOBSERVED/1/2/2/2/2/1/1/UNOBSERVED", stateFlags="5")
        lane = analyzer.analyze_sampler(row)
        self.assertEqual(lane["intervals_ns"]["dispatch_to_main"], 20)
        self.assertIsNone(lane["times_ns"]["replaced"])
        self.assertEqual(lane["coverage"], "OBSERVED_BRACKETS_ONLY")
        self.assertFalse(lane["invalid"])

    def test_negative_sampler_interval_is_invalid_not_clamped(self):
        row = dict(times="10/UNOBSERVED/20/30/35/45/70/50/75/UNOBSERVED",
                   tids="1/UNOBSERVED/1/2/2/2/2/1/1/UNOBSERVED")
        lane = analyzer.analyze_sampler(row)
        self.assertIn("dispatch>main", lane["invalid"])
        self.assertNotIn("dispatch_to_main", lane["intervals_ns"])

    def test_fallback_post_callback_is_not_an_authorization_or_pixel(self):
        result = analyzer.analyze(self.row(coverage="INCOMPLETE",
            fallbackCandidateAndPostReceipt="7/8/9/10/1000/1300"))
        fallback = result["fallback_observation"]
        self.assertEqual(fallback["candidate_to_post_callback_ns"], 300)
        self.assertEqual(fallback["effective_grant"], "UNOBSERVED")
        self.assertEqual(fallback["physical_presentation"], "UNOBSERVED")

    def test_every_compact_attempt_is_preserved(self):
        report = "\n".join(" R41_CORE attempt=%d eligible=UNOBSERVED" % i for i in range(1, 12))
        rows = analyzer.parse_report(report)
        self.assertEqual([int(row["attempt"]) for row in rows], list(range(1, 12)))


if __name__ == "__main__":
    unittest.main()

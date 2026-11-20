#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest

root = Path(__file__).parent
spec = importlib.util.spec_from_file_location('stock_tests', root / 'test-r14-stock-oracle.py')
stock_tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stock_tests)
spec = importlib.util.spec_from_file_location('candidate_oracle', root / 'r14_candidate_oracle.py')
candidate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(candidate)


class CandidateOracleControls(stock_tests.StockOracleControls):
    def setUp(self):
        super().setUp()
        self.fixture = self.fixture.replace('actualAttached=true attach=2', 'actualAttached=false attach=1')
        self.fixture = self.fixture.replace('finalAttached=false', 'finalAttached=false finalGeneration=1')
        self.raw = 'OK (1 test)'
        self.capture = ('FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n' + f'build={stock_tests.SOURCE}\n' +
            'omittedCriticalRecordIds=none\n WITHDRAWAL hideOp=8 attach=1 req=30 attachedBefore=true\n' +
            ' R14_RECOVERY attempt=1 seq=1 up=130 phase=DEFERRED r14Recovery=7 r14PreviousHide=8 '
            'r14PreviousAttach=1 r14DeferredA=38 r14OriginalB=52 r14Pending=52 r14Origin=systemUi r14Physical=UNOBSERVED\n' +
            ' R14_RECOVERY attempt=1 seq=2 up=140 phase=SUCCESSOR_HIDDEN_OCCLUDED r14DeferredA=38\n')

    def audit(self, fixture=None, capture=None, raw=None):
        return candidate.evaluate('exclusion', fixture or self.fixture, self.queue, self.root,
                                  stock_tests.SOURCE, self.run, raw or self.raw, capture or self.capture)

    def test_candidate_positive_control(self):
        self.assertEqual([], self.audit())

    def test_missing_deferred_or_wrong_hide_rejected(self):
        self.assertIn('exact_deferred_edge_missing', self.audit(capture=self.capture.replace('phase=DEFERRED', 'phase=OTHER')))
        self.assertIn('previous_hide_owner_unproved', self.audit(capture=self.capture.replace('r14PreviousHide=8', 'r14PreviousHide=9')))

    def test_duplicated_show_or_missing_successor_rejected(self):
        self.assertIn('deferred_a_created_show', self.audit(capture=self.capture + ' EPISODE attempt=1 showOp=2 req=38 \n'))
        self.assertIn('successor_outcome_missing', self.audit(capture=self.capture.replace('SUCCESSOR_HIDDEN_OCCLUDED', 'OTHER')))

    def test_missing_core_and_unexecuted_test_rejected(self):
        self.assertIn('capture_critical_omission', self.audit(capture=self.capture.replace('omittedCriticalRecordIds=none', 'omittedCriticalRecordIds=a1:show1')))
        self.assertIn('instrumentation_not_passed', self.audit(raw='not executed'))

# Inherited stock positive/negative methods check a stock result, so run only
# the explicitly candidate-owned methods in this suite.
if __name__ == '__main__':
    suite = unittest.TestSuite(CandidateOracleControls(name) for name in (
        'test_candidate_positive_control', 'test_missing_deferred_or_wrong_hide_rejected',
        'test_duplicated_show_or_missing_successor_rejected', 'test_missing_core_and_unexecuted_test_rejected'))
    raise SystemExit(not unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful())

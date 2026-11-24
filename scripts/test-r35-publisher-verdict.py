#!/usr/bin/env python3
"""Offline false-positive controls for the synthetic receiver verdict."""
import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location("verdict", pathlib.Path(__file__).with_name("r35-publisher-verdict.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

A = "R35_DEMO_A sequence=2 receiverPid=55 changedPixels=100 sha256=" + "a" * 64
B = "R35_DEMO_B sequence=4 receiverPid=55 changedPixels=100 sha256=" + "b" * 64
EMPTY = "R35_DEMO_EMPTY sequence=7 receiverPid=55 changedPixels=0 sha256=" + "c" * 64
ATTEMPT = "R35_DEMO_B_ATTEMPT storedRevision=2"
RETAINED = "R35_PARENT_B_NO_READY storedRevision=2 receiverPid=55 retainedSequence=2 changedPixels=100 sha256=" + "a" * 64
FIXTURE = "R35_PARENT_FIXTURE: A seeded explicitly; B uses unchanged production store"
RED = "FAILURES!!!\nTests run: 1,  Failures: 1\nB never reached independently prepared READY"
GREEN = "OK (1 test)"


class VerdictTest(unittest.TestCase):
    def test_parent_requires_a_accepted_b_and_live_same_a(self):
        evidence = "\n".join((FIXTURE, A, ATTEMPT, RETAINED))
        self.assertTrue(module.verdict("parent", RED, evidence)[0])
        for missing in (FIXTURE, A, ATTEMPT, RETAINED):
            self.assertFalse(module.verdict("parent", RED, evidence.replace(missing, ""))[0])
        self.assertFalse(module.verdict("parent", RED, evidence.replace("retainedSequence=2", "retainedSequence=1"))[0])
        self.assertFalse(module.verdict("parent", RED, evidence.replace("receiverPid=55 retained", "receiverPid=56 retained"))[0])
        self.assertFalse(module.verdict("parent", RED, evidence + "\n" + B)[0])

    def test_candidate_requires_order_identity_distinct_pixels_and_empty(self):
        evidence = "\n".join((A, ATTEMPT, B, EMPTY))
        self.assertTrue(module.verdict("candidate", GREEN, evidence)[0])
        for missing in (A, ATTEMPT, B, EMPTY):
            self.assertFalse(module.verdict("candidate", GREEN, evidence.replace(missing, ""))[0])
        self.assertFalse(module.verdict("candidate", GREEN, evidence.replace("sequence=4", "sequence=1"))[0])
        self.assertFalse(module.verdict("candidate", GREEN, evidence.replace("receiverPid=55", "receiverPid=56", 1))[0])
        self.assertFalse(module.verdict("candidate", GREEN, evidence.replace("changedPixels=0", "changedPixels=1"))[0])
        self.assertFalse(module.verdict("candidate", GREEN, evidence.replace("b" * 64, "a" * 64))[0])
        self.assertFalse(module.verdict("candidate", "FAILURES!!!\n" + GREEN, evidence)[0])
        self.assertFalse(module.verdict("candidate", GREEN + "\nINSTRUMENTATION_FAILED", evidence)[0])

    def test_setup_failure_cannot_become_parent_red(self):
        self.assertFalse(module.verdict("parent", RED, FIXTURE)[0])
        self.assertFalse(module.verdict("parent", "OK (1 test)", "\n".join((FIXTURE, A, ATTEMPT, RETAINED)))[0])
        self.assertFalse(module.verdict("other", GREEN, A)[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)

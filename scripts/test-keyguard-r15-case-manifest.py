#!/usr/bin/env python3
"""Synthetic parser controls; these never claim an Android-device result."""
import argparse
import importlib.util
import json
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("case_manifest", Path(__file__).with_name("keyguard-r15-case-manifest.py"))
case_manifest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(case_manifest)


class CaseManifestControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = "a" * 40
        self.run_uuid = str(uuid.uuid4())
        self.method = "r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply"
        cls = "com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest"
        raw = (f"INSTRUMENTATION_STATUS: class={cls}\nINSTRUMENTATION_STATUS: numtests=1\n"
               f"INSTRUMENTATION_STATUS: test={self.method}\nINSTRUMENTATION_STATUS_CODE: 1\n"
               f"INSTRUMENTATION_STATUS: class={cls}\nINSTRUMENTATION_STATUS: test={self.method}\n"
               "INSTRUMENTATION_STATUS_CODE: 0\nOK (1 test)\nINSTRUMENTATION_CODE: -1\n")
        contents = {
            "identity": f"source={self.source}\nrun_uuid={self.run_uuid}\nselector={cls}#{self.method}\nmode=LEGACY_R11\n",
            "process": "pid=42 startTicks=1234\n", "transcript": raw, "fixture": "synthetic host fixture\n",
            "app_before": f"expected={'b' * 64} installed={'b' * 64}\n",
            "app_after": f"expected={'b' * 64} installed={'b' * 64}\n",
            "test_before": f"expected={'c' * 64} installed={'c' * 64}\n",
            "test_after": f"expected={'c' * 64} installed={'c' * 64}\n",
            "run_metadata": json.dumps(dict(databaseId=5, headSha=self.source, event="workflow_dispatch", jobs=[dict(databaseId=7)])),
        }
        for name, content in contents.items():
            (self.root / name).write_text(content)
        self.args = argparse.Namespace(source=self.source, scope="r12_contract", row="r12_ordered", route="LEGACY_R11",
            run_id=5, job_id=7, out=self.root / "out", capture=None, report=[],
            **{name: self.root / name for name in contents})
        for name in ("phase_one_fixture", "phase_one_receipt", "phase_one_identity", "phase_one_process", "phase_one_transcript",
                     "phase_one_app_before", "phase_one_app_after", "phase_one_test_before", "phase_one_test_after"):
            setattr(self.args, name, None)

    def tearDown(self):
        self.temp.cleanup()

    def test_actual_identity_and_file_hashes_are_required(self):
        case, errors = case_manifest.make(self.args)
        self.assertEqual([], errors)
        self.assertEqual("PASS", json.loads((self.args.out / case["records"]).read_text().splitlines()[-1])["status"])
        (self.args.out / case["fixture"]).write_text("tampered\n")
        self.assertTrue(any(e.startswith("evidence_hash_mismatch:") for e in case_manifest.aggregate.verify_case(self.args.out, case, self.source)))

    def test_substituted_process_and_post_install_bytes_fail(self):
        self.args.process.write_text("pid=UNOBSERVED startTicks=UNOBSERVED\n")
        with self.assertRaises(ValueError):
            case_manifest.make(self.args)
        self.args.process.write_text("pid=42 startTicks=1234\n")
        self.args.app_after.write_text(f"expected={'b' * 64} installed={'d' * 64}\n")
        with self.assertRaises(ValueError):
            case_manifest.make(self.args)

    def test_missing_visual_result_cannot_be_promoted(self):
        self.args.row = "r12_real_service_first_composite"
        self.args.route = "SURFACE_LIVE"
        method = "firstCorrectServiceComposite"
        cls = "com.fluvi.app.lockscreen.KeyguardR15ServiceContractInstrumentationTest"
        self.args.identity.write_text(f"source={self.source}\nrun_uuid={self.run_uuid}\nselector={cls}#{method}\nmode=SURFACE_LIVE\n")
        self.args.transcript.write_text(self.args.transcript.read_text().replace(
            "com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest", cls).replace(self.method, method))
        case, errors = case_manifest.make(self.args)
        self.assertIn("fixture_not_pass", errors)
        self.assertEqual("NOT_ESTABLISHED", json.loads((self.args.out / case["records"]).read_text().splitlines()[-1])["status"])

    def test_selector_requires_linked_fresh_process_and_prerewrite_read(self):
        self.args.row = "r12_selector_persistence"
        self.args.route = "SURFACE_LIVE"
        method = "routeSelectionSurvivesReattachAndRestart"
        cls = "com.fluvi.app.lockscreen.KeyguardR15ServiceContractInstrumentationTest"
        self.args.identity.write_text(f"source={self.source}\nrun_uuid={self.run_uuid}\nselector={cls}#{method}\nmode=SURFACE_LIVE\n")
        raw = self.args.transcript.read_text().replace("com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest", cls).replace(self.method, method)
        self.args.transcript.write_text(raw)
        self.args.fixture.write_text("stage=PRE_FIXTURE_READ x configured=SURFACE_LIVE pid=42 processStart=1234\n"
            "stage=FIXTURE_START x\nstage=RESTARTED x configured=SURFACE_LIVE effective=LEGACY_R11 fallback=true\n"
            "stage=ELIGIBLE_AGAIN x effective=SURFACE_LIVE\n")
        first = {
            "phase_one_fixture": "stage=FIXTURE_START x\nstage=PENDING x attachment=3 before=LEGACY_R11 selected=SURFACE_LIVE effective=LEGACY_R11 pending=true\n"
                "stage=REATTACHED x attachment=4 configured=SURFACE_LIVE effective=SURFACE_LIVE pending=false\n",
            "phase_one_receipt": f"source={self.source}\ncase={self.run_uuid}\ntarget=SURFACE_LIVE\npid=41\nprocessStart=1200\nresult=PASS\n",
            "phase_one_identity": self.args.identity.read_text(), "phase_one_process": "pid=41 startTicks=1200\n",
            "phase_one_transcript": raw,
        }
        for name, content in first.items():
            path = self.root / name
            path.write_text(content)
            setattr(self.args, name, path)
        for label in ("app_before", "app_after", "test_before", "test_after"):
            setattr(self.args, "phase_one_" + label, getattr(self.args, label))
        case, errors = case_manifest.make(self.args)
        self.assertEqual([], errors)
        self.assertEqual([41, 42], json.loads((self.args.out / case["records"]).read_text().splitlines()[-1])["process_ids"])


if __name__ == "__main__":
    unittest.main(verbosity=2)

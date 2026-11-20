#!/usr/bin/env python3
"""Negative controls for identity, actual execution and evidence coverage."""
import hashlib
import importlib.util
import json
import struct
import sys
import tempfile
import unittest
import uuid
import zlib
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("r14", Path(__file__).with_name("keyguard-r14-aggregate.py"))
r14 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r14)
SOURCE = "a" * 40


def png(white=False, green=False):
    def chunk(name, payload):
        return struct.pack(">I", len(payload)) + name + payload + struct.pack(">I", zlib.crc32(name + payload) & 0xffffffff)
    pixels = (b"\xff\xff\xff\xff" if white else b"\x00\xff\x00\xff" if green else b"\xff\x00\x00\xff") * 4
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 2, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0" + pixels[:8] + b"\0" + pixels[8:])) + chunk(b"IEND", b""))


class AggregateControls(unittest.TestCase):
    def test_legacy_service_controls_cannot_be_relabelled_as_live(self):
        self.assertIn(("r12_ordered", "LEGACY_R11"), r14.REQUIRED)
        self.assertIn(("r12_occlusion", "LEGACY_R11"), r14.REQUIRED)
        self.assertNotIn(("r12_ordered", "SURFACE_LIVE"), r14.REQUIRED)
        self.assertNotIn(("r12_occlusion", "SURFACE_LIVE"), r14.REQUIRED)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.run_uuid = str(uuid.uuid4())
        self.method = "freshMainSuccessorRestoresExactlyOnce"
        self.case = dict(row="r14_fresh_main", route="SURFACE_LIVE", method=self.method,
            source=SOURCE, scope="r14_recovery_candidate", run_id=1, job_id=2, pid=3, process_start=10, run_uuid=self.run_uuid,
            app_sha256="b" * 64, test_sha256="c" * 64,
            installed_app_sha256="b" * 64, installed_test_sha256="c" * 64,
            transcript="raw.txt", records="records.jsonl", app_receipt="app.txt",
            test_receipt="test.txt", run_metadata="run.json")
        self.result = dict(kind="RESULT", row="r14_fresh_main", status="PASS", a=10, a_read_start=100, a_decision_at=110,
            previous_hide=7, initial_attach=4, final_attach=5, a_complete=True,
            a_reason="MAIN_CONFIRMED", pre_a_roots=0, b=11, pending_b=11,
            b_origin="CONTROLLED_SYSTEMUI_PRIMARY", b_event=100, b_callback=101,
            a_adds=0, b_read=11, b_classification="SHOW_FULL", total_new_adds=1, final_roots=1)
        self.raw = (f"INSTRUMENTATION_STATUS: numtests=1\nINSTRUMENTATION_STATUS: test={self.method}\n"
                    f"INSTRUMENTATION_STATUS_CODE: 1\nINSTRUMENTATION_STATUS: test={self.method}\n"
                    "INSTRUMENTATION_STATUS_CODE: 0\nOK (1 test)\nINSTRUMENTATION_CODE: -1\n")
        (self.root / "raw.txt").write_text(self.raw)
        (self.root / "app.txt").write_text(f"expected={'b' * 64} installed={'b' * 64}\n")
        (self.root / "test.txt").write_text(f"expected={'c' * 64} installed={'c' * 64}\n")
        (self.root / "run.json").write_text(json.dumps(dict(databaseId=1, headSha=SOURCE,
            event="workflow_dispatch", jobs=[dict(databaseId=2)])))
        self.write_records()

    def tearDown(self):
        self.tmp.cleanup()

    def write_records(self, process=None, result=None):
        if process is None:
            process = {k: self.case[k] for k in ("source", "run_uuid", "pid", "process_start", "route", "row")}
            process["kind"] = "PROCESS"
        (self.root / "records.jsonl").write_text(json.dumps(process) + "\n" + json.dumps(result or self.result) + "\n")

    def test_positive_control(self):
        self.assertEqual([], r14.verify_case(self.root, self.case, SOURCE))

    def test_wrong_or_missing_source(self):
        for value in (None, "d" * 40):
            self.assertIn("source_mismatch", r14.verify_case(self.root, self.case | {"source": value}, SOURCE))
        self.assertIn("scope_mismatch", r14.verify_case(self.root, self.case | {"scope": "r12_live"}, SOURCE))

    def test_unexecuted_or_failed_instrumentation(self):
        for raw in (self.raw.replace(self.method, "differentTest"), self.raw.replace("OK (1 test)", "FAILURES!!!")):
            (self.root / "raw.txt").write_text(raw)
            self.assertIn("unexecuted_or_failed_test", r14.verify_case(self.root, self.case, SOURCE))

    def test_substituted_process_and_apk(self):
        process = dict(kind="PROCESS", source=SOURCE, run_uuid=self.run_uuid, pid=999, process_start=10, route="SURFACE_LIVE", row="r14_fresh_main")
        self.write_records(process=process)
        self.assertIn("process_mismatch", r14.verify_case(self.root, self.case, SOURCE))
        self.assertIn("installed_apk_mismatch", r14.verify_case(self.root, self.case | {"installed_app_sha256": "d" * 64}, SOURCE))

    def test_visual_file_missing_invalid_or_white(self):
        case = self.case | {"row": "r14_exclusion", "method": "supersededExternalEventSuppressesOnlyTheRecoveryAdd"}
        result = self.result | dict(a_adds=0, b_read=11, b_classification="HIDDEN_SHADE", final_roots=0, independent_exclusion=True)
        result["visual_samples"] = [dict(path="missing.png", sha256="f" * 64)] * 2
        self.assertIn("visual_files_missing_or_corrupt", r14.check_specific(case["row"], case["route"], result, self.root))
        for content, wanted in ((png(), True), (png(True), False), (b"\x89PNG\r\n\x1a\n" + b"x" * 200, False)):
            (self.root / "image.png").write_bytes(content)
            sample = dict(path="image.png", sha256=hashlib.sha256(content).hexdigest())
            self.assertEqual(wanted, r14.visual_file(self.root, sample))

    def test_reused_specimen_and_duplicate_contradictions_fail(self):
        for name in ("one", "two"):
            target = self.root / name
            target.mkdir()
            (target / "r14-case.json").write_text(json.dumps(self.case))
        errors, _ = r14.aggregate(SOURCE, self.root)
        self.assertTrue(any("duplicate_or_contradictory_case" in e for e in errors))
        other = self.case | {"row": "r14_late_only", "method": "postAttachOnlyExclusionNeverDefersPriorAdmission"}
        (self.root / "two" / "r14-case.json").write_text(json.dumps(other))
        errors, _ = r14.aggregate(SOURCE, self.root)
        self.assertTrue(any("reused_specimen" in e for e in errors))
        self.assertTrue(any("reused_or_unidentified_process" in e for e in errors))

    def test_fake_summary_and_absent_coverage_never_pass(self):
        (self.root / "status.txt").write_text("all=PASS\nR14_AGGREGATE=PASS\n")
        errors, lines = r14.aggregate(SOURCE, self.root)
        self.assertTrue(errors)
        self.assertTrue(all("NOT_ESTABLISHED" in line for line in lines))
        self.assertIn("source_invalid", r14.aggregate("bad", self.root)[0])

    def test_independent_occlusion_and_terminal_are_not_admission_a_b_cases(self):
        samples = []
        for name, content in (("before.png", png()), ("after.png", png(green=True))):
            (self.root / name).write_bytes(content)
            samples.append(dict(path=name, sha256=hashlib.sha256(content).hexdigest()))
        occlusion = dict(status="PASS", real_occluder=True, independent_window_identity=True,
                         withdrawn_while_locked=True, fresh_main_return_once=True, visual_samples=samples)
        self.assertEqual([], r14.check_specific("r14_real_occlusion", "SURFACE_LIVE", occlusion, self.root))
        self.assertIn("real_occlusion_return_not_established", r14.check_specific(
            "r14_real_occlusion", "SURFACE_LIVE", occlusion | {"fresh_main_return_once": False}, self.root))
        self.assertIn("real_occlusion_return_not_established", r14.check_specific(
            "r14_real_occlusion", "SURFACE_LIVE", occlusion | {"visual_samples": [samples[0], samples[0]]}, self.root))
        terminal = dict(status="PASS", pending_stale_work=True, terminal_state_observed=True, late_adds=0)
        self.assertEqual([], r14.check_specific("r14_terminal_stale", "SURFACE_LIVE", terminal, self.root))
        self.assertIn("terminal_stale_not_established", r14.check_specific(
            "r14_terminal_stale", "SURFACE_LIVE", terminal | {"late_adds": 1}, self.root))

    def test_bad_timestamps_and_run_provenance_fail(self):
        self.write_records(result=self.result | {"b_callback": 100})
        self.assertIn("r14_b_origin_or_order", r14.verify_case(self.root, self.case, SOURCE))
        (self.root / "run.json").write_text(json.dumps(dict(databaseId=1, headSha="d" * 40,
            event="workflow_dispatch", jobs=[dict(databaseId=2)])))
        self.assertIn("run_or_job_provenance_mismatch", r14.verify_case(self.root, self.case, SOURCE))


if __name__ == "__main__":
    unittest.main(verbosity=2)

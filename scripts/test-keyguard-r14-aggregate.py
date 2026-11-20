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

    def test_legacy_service_controls_use_their_actual_contract_scope(self):
        for row in ("r12_ordered", "r12_occlusion"):
            case = self.case | {"row": row, "route": "LEGACY_R11",
                "method": r14.REQUIRED[(row, "LEGACY_R11")], "scope": "r12_contract"}
            # The synthetic record is intentionally not a passing device case;
            # this assertion tests the collector's scope mapping only.
            self.assertNotIn("scope_mismatch", r14.verify_case(self.root, case, SOURCE))
            self.assertIn("scope_mismatch", r14.verify_case(
                self.root, case | {"scope": "r14_recovery_candidate"}, SOURCE))

    def test_pressure_requires_owned_typed_deferred_and_replacement_edges(self):
        def report(replacement="22", displaced="21", seq="7", hide="7", attempt="1"):
            text = (
                "FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"
                "captureId=11111111-1111-4111-8111-111111111111\n"
                "omittedCriticalRecordIds=none\n"
                " EPISODE attempt=1 showOp=1 attach=4 req=19 withdrawal=7\n"
                " EPISODE attempt=1 showOp=2 attach=5 req=24 withdrawal=8\n"
                " WITHDRAWAL hideOp=7 attach=4 req=18 attachedBefore=true\n"
                " WITHDRAWAL hideOp=8 attach=5 req=25 attachedBefore=true\n"
                " R13_FINANCIAL attempt=1 coverage=keyguardScopesOnly scopes=40 invalid=0\n"
                " R14_RECOVERY attempt=1 seq=6 up=135 phase=DEFERRED r14Recovery=9 "
                "r14PreviousHide=7 r14PreviousAttach=4 r14DeferredA=20 r14OriginalB=21 r14Pending=21\n"
                f" R14_RECOVERY attempt={attempt} seq={seq} up=136 phase=REPLACED r14Recovery=9 "
                f"r14PreviousHide={hide} r14PreviousAttach=4 r14DeferredA=20 r14OriginalB=21 "
                f"r14Pending={replacement} r14Displaced={displaced}\n"
                "END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"
            )
            # The real exporter includes the length of the complete UTF-8 report.
            while True:
                candidate = text.replace("omittedCriticalRecordIds=none\n",
                    f"exportBytes={len(text.encode())}\nomittedCriticalRecordIds=none\n")
                size = len(candidate.encode())
                final = text.replace("omittedCriticalRecordIds=none\n",
                    f"exportBytes={size}\nomittedCriticalRecordIds=none\n")
                if len(final.encode()) == size:
                    return final
                text = final.replace(f"exportBytes={size}\n", "")
        result = {"status": "PASS", "report": "pressure.txt"}
        (self.root / "pressure.txt").write_text(report())
        self.assertEqual([], r14.check_specific("r14_pressure", "LIGHT", result, self.root))
        for broken in (report(displaced="99"), report(replacement="21"), report(seq="5"),
                       report(hide="8"), report(attempt="2")):
            (self.root / "pressure.txt").write_text(broken)
            self.assertIn("recovery_edges_missing", r14.check_specific("r14_pressure", "LIGHT", result, self.root))

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
            test_receipt="test.txt", app_after_receipt="app-after.txt", test_after_receipt="test-after.txt", run_metadata="run.json",
            fixture="fixture.txt", identity_file="identity.txt", process_file="process.txt")
        self.result = dict(kind="RESULT", row="r14_fresh_main", status="PASS", a=10, a_read_start=100, a_decision_at=110,
            previous_hide=7, initial_attach=4, final_attach=5, a_complete=True,
            a_reason="MAIN_CONFIRMED", pre_a_roots=0, b=11, pending_b=11,
            b_origin="CONTROLLED_SYSTEMUI_PRIMARY", b_event=100, b_callback=101,
            a_adds=0, b_read=11, b_classification="SHOW_FULL", total_new_adds=1, final_roots=1)
        class_line = "INSTRUMENTATION_STATUS: class=com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest\n"
        self.raw = (f"{class_line}INSTRUMENTATION_STATUS: numtests=1\nINSTRUMENTATION_STATUS: test={self.method}\n"
                    f"INSTRUMENTATION_STATUS_CODE: 1\n{class_line}INSTRUMENTATION_STATUS: test={self.method}\n"
                    "INSTRUMENTATION_STATUS_CODE: 0\nOK (1 test)\nINSTRUMENTATION_CODE: -1\n")
        (self.root / "raw.txt").write_text(self.raw)
        (self.root / "app.txt").write_text(f"expected={'b' * 64} installed={'b' * 64}\n")
        (self.root / "test.txt").write_text(f"expected={'c' * 64} installed={'c' * 64}\n")
        (self.root / "app-after.txt").write_text(f"expected={'b' * 64} installed={'b' * 64}\n")
        (self.root / "test-after.txt").write_text(f"expected={'c' * 64} installed={'c' * 64}\n")
        (self.root / "run.json").write_text(json.dumps(dict(databaseId=1, headSha=SOURCE,
            event="workflow_dispatch", jobs=[dict(databaseId=2)])))
        (self.root / "identity.txt").write_text(f"source={SOURCE}\nrun_uuid={self.run_uuid}\nselector=com.fluvi.app.lockscreen.KeyguardRecoveryAdmissionInstrumentationTest#{self.method}\n")
        (self.root / "process.txt").write_text("pid=3 startTicks=10\n")
        (self.root / "fixture.txt").write_text("real fixture evidence\n")
        self.write_records()
        self.case["evidence_sha256"] = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
            for path in self.root.iterdir() if path.is_file()}

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
        for raw in (self.raw.replace(self.method, "differentTest"), self.raw.replace("OK (1 test)", "FAILURES!!!"),
                    self.raw.replace("KeyguardRecoveryAdmissionInstrumentationTest", "OtherClass")):
            (self.root / "raw.txt").write_text(raw)
            self.assertIn("unexecuted_or_failed_test", r14.verify_case(self.root, self.case, SOURCE))

    def test_substituted_process_and_apk(self):
        process = dict(kind="PROCESS", source=SOURCE, run_uuid=self.run_uuid, pid=999, process_start=10, route="SURFACE_LIVE", row="r14_fresh_main")
        self.write_records(process=process)
        self.assertIn("process_mismatch", r14.verify_case(self.root, self.case, SOURCE))
        self.assertIn("installed_apk_mismatch", r14.verify_case(self.root, self.case | {"installed_app_sha256": "d" * 64}, SOURCE))
        (self.root / "app-after.txt").write_text(f"expected={'b' * 64} installed={'d' * 64}\n")
        self.assertIn("app_after_receipt_mismatch", r14.verify_case(self.root, self.case, SOURCE))

    def test_visual_file_missing_invalid_or_white(self):
        case = self.case | {"row": "r14_exclusion", "method": "supersededExternalEventSuppressesOnlyTheRecoveryAdd"}
        result = self.result | dict(a_adds=0, b_read=11, b_classification="HIDDEN_SHADE", final_roots=0, independent_exclusion=True)
        result["visual_samples"] = [dict(path="missing.png", sha256="f" * 64)] * 2
        self.assertIn("visual_files_missing_or_corrupt", r14.check_specific(case["row"], case["route"], result, self.root))
        for content, wanted in ((png(), True), (png(True), False), (b"\x89PNG\r\n\x1a\n" + b"x" * 200, False)):
            (self.root / "image.png").write_bytes(content)
            sample = dict(path="image.png", sha256=hashlib.sha256(content).hexdigest())
            self.assertEqual(wanted, r14.visual_file(self.root, sample))

    def test_late_systemui_nonqualifying_type_is_explicit_and_time_bounded(self):
        result = dict(status="PASS", a=81, a_read_start=100, a_decision_at=110,
                      previous_hide=3, initial_attach=1, final_attach=2, a_complete=True,
                      a_reason="MAIN_CONFIRMED", pre_a_roots=0, pending_before_a=82,
                      pending_origin="SYSTEMUI_OTHER_EVENT", pending_type=2048,
                      pending_event=99, pending_callback=100, pending_qualifies=False,
                      a_adds=1, post_c_received=True, final_roots=0)
        errors = r14.check_specific("r14_late_only", "SURFACE_LIVE", result, self.root)
        self.assertNotIn("r14_late_only", errors)
        for changed in (result | {"pending_type": 32}, result | {"pending_callback": 111},
                        result | {"pending_type": None}):
            self.assertIn("r14_late_only", r14.check_specific("r14_late_only", "SURFACE_LIVE", changed, self.root))

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

    def test_selector_phase_one_replay_cannot_prove_a_restart(self):
        owner = dict(source=SOURCE, run_uuid=self.run_uuid, row="r12_selector_persistence", route="SURFACE_LIVE")
        first = [owner | dict(kind="PROCESS", phase=1, pid=3, process_start=10),
                 dict(kind="SELECTOR_WRITE", route="SURFACE_LIVE"), dict(kind="PHASE_COMPLETE")]
        second = [owner | dict(kind="PROCESS", phase=2, pid=4, process_start=20),
                  dict(kind="RESTORED_BEFORE_FIXTURE", route="SURFACE_LIVE"), dict(kind="RESULT")]
        self.assertTrue(r14.restart_lineage_valid(first, second, owner))
        self.assertFalse(r14.restart_lineage_valid(first, first, owner))
        self.assertFalse(r14.restart_lineage_valid(first, [second[0],
            dict(kind="SELECTOR_WRITE", route="SURFACE_LIVE"), second[1], second[2]], owner))
        self.assertFalse(r14.restart_lineage_valid(first, [second[0] | {"route": "LEGACY_R11"}] + second[1:], owner))

    def test_holder_generation_and_timeout_cannot_be_relabelled(self):
        def event(stage, at, generation, holder, operation=7):
            return dict(stage=stage, uptime=at, generation=generation, holder=holder, operation=operation)
        timeline = [event("G1_LOCKED", 10, 1, 100), event("G1_REVOKED", 11, 1, 100),
            event("G1_BARRIER_RELEASED", 12, 1, 100), event("G1_OPERATION_FINISHED", 13, 1, 100),
            event("G1_DESTROY_RETURN", 14, 1, 100), event("G2_CREATED", 15, 2, 200, 8),
            event("G2_POSTED", 16, 2, 200, 8), event("G2_REDRAW_COMPLETED", 17, 2, 200, 8)]
        self.assertTrue(r14.holder_timeline_valid(timeline, barrier_timed_out=False))
        stale = [entry.copy() for entry in timeline]
        stale[6] = stale[6] | {"generation": 1, "holder": 100, "operation": 7}
        self.assertFalse(r14.holder_timeline_valid(stale, barrier_timed_out=False))
        self.assertFalse(r14.holder_timeline_valid(timeline, barrier_timed_out=True))
        self.assertFalse(r14.holder_timeline_valid(timeline + [event("G1_OPERATION_FINISHED", 18, 1, 100)], False))


if __name__ == "__main__":
    unittest.main(verbosity=2)

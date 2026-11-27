"""Host-only checks. All serialized rows are reconstructed technical fixture data."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("r48", SCRIPTS / "r48-admission-report.py")
R48 = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = R48
SPEC.loader.exec_module(R48)
CAPTURE = "aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa"
OTHER = "bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb"
FIXTURE = json.loads((Path(__file__).parent / "fixtures/r48/episodes.json").read_text(encoding="utf-8"))
DIRECT = "FLUVI_STREAM"
WA = "WIDGETS_ANYWHERE"


def envelope(route, summary, spool, capture=CAPTURE):
    body = ("\n".join(["FLUVI_R46_RECORDING_V1", "Árvíztűrő próba",
                      f"captureId={capture} route={route} end=USER_STOP",
                      "clock=uptimeMs source=app_private_spool", "SUMMARY_BEGIN",
                      f"build={R48.SOURCE}", "eventsEvicted=2",
                      "R41_ACCOUNTING sampleEvicted=3", *summary, "SUMMARY_END",
                      "DETAILED_RECORDS_BEGIN", *spool, "DETAILED_RECORDS_END",
                      f"spoolAccepted={len(spool)} spoolWritten={len(spool)} spoolDropped=0", ""])
            .encode("utf-8"))
    return body + (f"bodyBytes={len(body)} bodySha256={hashlib.sha256(body).hexdigest()}\n"
                   "END_FLUVI_R46_RECORDING_V1\n").encode("ascii")


def context(wake, session=1, capture=CAPTURE):
    return (f"context=KeyguardDiagnosticContext(captureId={capture}, attemptId=1, "
            f"serviceSession={session}, originWakeEpoch={wake})")


def decision(wake, req, ord=1, session=1, extra=""):
    return (f"R446_OUTPUT KeyguardR446Observation({context(wake, session)}, armGeneration=3, request={req}, "
            f"decisionOrdinal={ord}, normal=UNKNOWN/NO_MAIN_MARKER, handoff=PRIVATE_NOT_AUTHORIZED, "
            f"eligibility=ELIGIBLE_SAMPLE, backend=NOT_ATTEMPTED{extra})")


def wa_decision(wake, rev, reason="CLEAR", decision="MATERIAL_UNAUTHORIZED", session=1, arm=3):
    exclusion = "CLEAR" if reason == "CLEAR" else "UNKNOWN"
    return (f"R449_ADMISSION KeyguardR449AdmissionObservation({context(wake, session)}, "
            f"arm={arm}, routeGeneration=2, materialGeneration=5, restrictionRevision={rev}, domain=PRIVATE, "
            "readStart=101, readEnd=110, available=true, interactive=true, "
            f"credential={exclusion}, shade={exclusion}, foreign={exclusion}, powerMenu={exclusion}, "
            f"reason={reason}, decision={decision})")


def no_marker(wake, req):
    return (f"R44_READ kind=firstPost wake={wake} req={req} start=101 end=110 scene=2 stale=false "
            "unavailable=false truncated=false legacy=UNKNOWN")


def terminal(wake, route, reason):
    return f"R44_9_OUTCOME capture={CAPTURE} wake={wake} routeConfirmed={route} terminal={reason}"


class AdmissionReportTest(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.path = Path(self.folder.name) / "capture.txt"

    def report(self, route, summary=(), spool=(), labels=()):
        self.path.write_bytes(envelope(route, summary, spool))
        return R48.analyze(self.path, labels)

    def test_recognizes_exact_utf8_seal_and_rejects_edits(self):
        good = envelope(DIRECT, [], [])
        self.path.write_bytes(good)
        report = R48.analyze(self.path)
        self.assertEqual(hashlib.sha256(good).hexdigest(), report["fileSha256"])
        for invalid in [good[:-2], good.replace(b"eventsEvicted=2", b"eventsEvicted=3"),
                        good.replace(b"\n", b"\r\n"), b"x" + good]:
            self.path.write_bytes(invalid)
            with self.subTest(invalid=hashlib.sha256(invalid).hexdigest()), self.assertRaises(ValueError):
                R48.analyze(self.path)

    def test_replay_known_direct_denials_keeps_successors_distinct(self):
        summary, spool = [], []
        for episode in FIXTURE[DIRECT]:
            wake = episode["wake"]
            summary.extend([f"R44_WAKE capture={CAPTURE} session=1 wake={wake}", terminal(wake, DIRECT, episode["terminal"])])
            for ordinal, req in enumerate(episode["currentRequests"], 1):
                summary.append(no_marker(wake, req))
                spool.append(decision(wake, req, ordinal))
            if episode.get("distinctSuccessor"):
                summary.append(no_marker(wake, episode["distinctSuccessor"]))
        # Two representations of the same completed private request, not a twelfth denial.
        summary.append("R44_6_SAMPLE wake=5 req=100 ordinal=5 normal=UNKNOWN/NO_MAIN_MARKER "
                       "eligible=ELIGIBLE_SAMPLE handoff=PRIVATE_NOT_AUTHORIZED backend=NOT_ATTEMPTED")
        report = self.report(DIRECT, summary, spool)
        by_wake = {w["wake"]: w for w in report["wakes"]}
        self.assertEqual([3, 5, 3], [by_wake[w]["retainedDecisions"] for w in [3, 5, 7]])
        self.assertEqual("UNOBSERVED", next(r for r in by_wake[7]["reads"] if r["id"] == "req:162")["decision"])
        self.assertEqual("EVICTED", report["lossAndObserverCost"]["rawSampleEviction"]["state"])
        self.assertTrue(all(w["physical"] == R48.UNKNOWN for w in by_wake.values()))

    def test_wa_incomplete_complete_and_stop_do_not_mix(self):
        summary, spool = [], []
        for episode in FIXTURE[WA]:
            wake = episode["wake"]
            summary.extend([f"R44_WAKE capture={CAPTURE} session=1 wake={wake}", terminal(wake, WA, episode["terminal"])])
            if episode.get("truncated"):
                # The first actual revision is missing. 38 is a fixture key only.
                spool.append(wa_decision(wake, 38, "TRUNCATED", "EXCLUSION_UNKNOWN"))
            for revision in episode.get("completeClearRevisions", []):
                spool.append(wa_decision(wake, revision))
                detail = (f"R45_EVENT KeyguardR45Observation({context(wake)}, route={WA}, stage=MATERIAL_DENIED, "
                          f"revision={revision}, decision=MATERIAL_UNAUTHORIZED, detail=normalSurface=UNKNOWN inventory=CLEAR)")
                spool.append(detail)
            if episode.get("retainedReassessments"):
                for seq in range(1, episode["retainedReassessments"] + 1):
                    spool.append(f"R45_EVENT KeyguardR45Observation({context(wake)}, route={WA}, "
                                 f"stage=INGRESS, sequence={seq}, decision=REASSESS)")
                # A possible pending request deliberately lacks a decision record.
                summary.append(f"EVENT capture={CAPTURE} session=1 wake=17 req=66 stage=INSPECTION_QUEUED up=400 el=800")
        report = self.report(WA, summary, spool)
        rows = {row["wake"]: row for row in report["wakes"]}
        row = rows[13]["reads"]
        self.assertEqual(["TRUNCATED", "COMPLETE_EXCLUSIONS"], [r["readerCompleteness"] for r in row])
        self.assertEqual(["EXCLUSION_UNKNOWN", "MATERIAL_UNAUTHORIZED"], [r["decision"] for r in row])
        self.assertEqual("UNKNOWN", row[1]["normalSurface"])
        self.assertEqual("INCONCLUSIVE", rows[17]["decisionCoverage"])
        self.assertEqual("r46UserStop", rows[17]["terminal"])
        self.assertEqual(43, rows[17]["retainedReassessments"])
        self.assertEqual("QUEUED", rows[17]["reads"][0]["lastProvenStage"])

    def test_mismatched_child_context_never_relabels_a_read(self):
        reports = self.report(WA, [
            f"R44_WAKE capture={CAPTURE} session=1 wake=11",
            "R44_9_ADMISSION wake=11 restrictionRevision=6 domain=PRIVATE decision=ALLOW",
        ], [wa_decision(11, 6), wa_decision(11, 6, session=2, arm=4),
            wa_decision(11, 6, arm=4),
            f"R44_READ {context(11, capture=OTHER)} request=99 start=1 end=2"])
        wakes = reports["wakes"]
        self.assertEqual(["UNOBSERVED", 1, 2], [w["session"] for w in wakes])
        self.assertTrue(all(r["decision"] == "MATERIAL_UNAUTHORIZED" for w in wakes[1:] for r in w["reads"]))
        self.assertEqual(1, reports["excludedForeignRecords"])

    def test_same_stage_contradiction_is_retained_and_not_a_grant(self):
        reports = self.report(WA, [f"R44_WAKE capture={CAPTURE} session=1 wake=11",
            "R44_9_ADMISSION wake=11 arm=3 routeGeneration=2 materialGeneration=5 "
            "restrictionRevision=6 domain=PRIVATE decision=ALLOW"], [wa_decision(11, 6)])
        row = reports["wakes"][0]["reads"][0]
        conflict = row["stages"]["ADMISSION"]["decision"]["conflict"]
        self.assertEqual({"ALLOW", "MATERIAL_UNAUTHORIZED"}, {c["value"] for c in conflict})
        self.assertEqual(R48.UNKNOWN, row["decision"])

    def test_has_exact_output_owner(self):
        report = self.report(DIRECT, [f"R44_WAKE capture={CAPTURE} session=1 wake=3",
            "R44_6_SAMPLE wake=3 req=21 ordinal=1 handoff=TARGET_MISSING progressReq=20 backend=SHADER_DRAW "
            "issue=120 frame=133"],
            [decision(3, 21),
             f"R446_OUTPUT KeyguardR446Observation({context(3)}, request=20, armGeneration=3, "
             "decisionOrdinal=1, handoff=ISSUED, backend=SHADER_DRAW, issuedAt=120, submittedAt=131, frameAt=133)"])
        reads = {row["id"]: row for row in report["wakes"][0]["reads"]}
        self.assertEqual("SHADER_DRAW", reads["req:20"]["backend"])
        self.assertEqual("BACKEND_RECEIPT", reads["req:20"]["lastProvenStage"])
        self.assertEqual("NOT_ATTEMPTED", reads["req:21"]["backend"])
        self.assertNotIn("issue", reads["req:21"]["stages"]["OUTPUT"])

    def test_label_overlapping_transition_is_refused_and_collisions_reject(self):
        def label(wake, scene, start, end):
            return dict(capture=CAPTURE, session=1, wake=wake, scene=scene, start=start, end=end,
                        clock="uptimeMs", source="owner_bookmark")
        def scene(wake, req):
            return (f"R43_SCENE hold=CLOCK_1 source=PASSIVE session=1 wake={wake} req={req} scene=2 up=112 "
                    "ownAmbiguous=false unavailable=false stale=false truncated=false windowOmitted=0 "
                    "resourceLookup=AVAILABLE reportIds=true retrieveWindows=true markers=main:0,credential:0,shade:0,occlusion:0 "
                    "R43_WINDOW win=9/3/1/0/true/false root=SYSTEMUI/true nodes=5/2/0/2/0/0 "
                    "ids=keyguard_root_view@2:1:1,notification_title@3:1:1 unverified=0 idOverflow=0")
        labels = R48.verify_bookmarks([label(3, "MAIN", 100, 119), label(5, "PIN", 100, 119), label(7, "MAIN", 107, 119)])
        report = self.report(DIRECT, [no_marker(w, w) for w in [3, 5, 7]], [scene(w, w) for w in [3, 5, 7]], labels)
        self.assertEqual(["MAIN", "PIN", "UNLABELLED"], [w["reads"][0]["label"] for w in report["wakes"]])
        self.assertNotIn("notification_title", json.dumps(report))
        self.assertEqual("REJECT_NEGATIVE_COLLISION", R48.candidate_matrix([report])[0]["verdict"])
        unlabelled = self.report(DIRECT, [no_marker(3, 3)], [scene(3, 3)])
        self.assertEqual("UNLABELLED", unlabelled["wakes"][0]["reads"][0]["label"])


if __name__ == "__main__":
    unittest.main()

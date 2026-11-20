#!/usr/bin/env python3
"""Host-only slot mapping controls; sample rows are synthetic."""
import importlib.util
import json
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("slots", Path(__file__).with_name("keyguard-r15-slot-evidence.py"))
slots = importlib.util.module_from_spec(spec)
spec.loader.exec_module(slots)
SOURCE = "a" * 40


class SlotEvidenceControls(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for number, (block, arm) in enumerate(slots.ORDER):
            run_id, capture = str(uuid.uuid4()), str(uuid.uuid4())
            directory = self.root / f"block-{block}-{arm}"
            directory.mkdir()
            (directory / "identity.txt").write_text(f"source={SOURCE}\nrun_uuid={run_id}\nblock={block}\narm={arm}\n")
            for label, digest in (("app", "b" * 64), ("test", "c" * 64)):
                for phase in ("before", "after"):
                    (directory / f"installed-{label}-{phase}-sha256.txt").write_text(f"expected={digest} installed={digest}\n")
            base = directory / "probe/files/keyguard-service-probe"
            timing = base / "r12-timing" / run_id
            timing.mkdir(parents=True)
            rows = [f"PROCESS up=10 source={SOURCE} run={run_id} capture={capture} mode=SURFACE_LIVE pid={100 + number} startTicks={1000 + number}"]
            first, reads = [], []
            for index, name in enumerate(slots.POSITIONS):
                wake = 1000 + index * 1000
                rows.append(f"WAKE_TRIGGER up={wake} name={name} wake={wake}")
                first.append(dict(request=index + 1, session=1, wake=index + 1, start=wake + 10, finish=wake + 40,
                                  decision="SHOW_FULL", reason="MAIN_CONFIRMED", rootUnavailable=False, walkTruncated=False, abortedStale=False))
                reads.append(dict(request=index + 1, session=1, wake=index + 1, eligible=True, rootCalled=True,
                                  rootFlags=0 if arm == "candidate" else 36, rootAccepted=True, activeRootMs=20,
                                  childCalls=2, firstChildFlags=36, firstChildMs=5, childMs=10, fallback=None,
                                  inspectionStart=wake + 10, inspectionEnd=wake + (70 if arm == "stock" else 50),
                                  windows=[dict(type=1, display=0, own=False)], visited=35))
            (timing / "fixture.txt").write_text("\n".join(rows) + "\n")
            (timing / "capture.txt").write_text(f"build={SOURCE}\n")
            acquisition = base / "r15" / run_id / "acquisition"
            acquisition.mkdir(parents=True)
            (acquisition / f"{arm}-block{block}-first-inspections.jsonl").write_text("".join(json.dumps(row) + "\n" for row in first))
            (acquisition / f"{arm}-block{block}.jsonl").write_text("".join(json.dumps(row) + "\n" for row in reads))
            (acquisition / f"{arm}-block{block}-overflow.txt").write_text("0\n")

    def tearDown(self):
        self.temp.cleanup()

    def test_16_slots_and_unobserved_compositor_are_preserved(self):
        result = slots.build(self.root, SOURCE)
        self.assertEqual(16, len(result["slots"]))
        self.assertEqual([], result["errors"])
        self.assertEqual("NOT_ESTABLISHED", result["result"])
        self.assertTrue(all(row["first_composite_interval_ms"] is None for row in result["slots"]))
        self.assertTrue(all(row["total_read_delta_ms"] == -20 and row["onset_delta_interval_ms"] is None
                            for row in result["warm_comparisons"]))

    def test_missing_first_record_never_borrows_a_later_request(self):
        directory = self.root / "block-1-candidate"
        identity = slots.values((directory / "identity.txt").read_text())
        acquisition = directory / "probe/files/keyguard-service-probe/r15" / identity["run_uuid"] / "acquisition"
        path = acquisition / "candidate-block1.jsonl"
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        path.write_text("".join(json.dumps(row) + "\n" for row in rows if row["request"] != 2))
        result = slots.build(self.root, SOURCE)
        warm = next(row for row in result["slots"] if row["block"] == 1 and row["arm"] == "candidate" and row["position"] == "warm1")
        self.assertEqual(2, warm["request"])
        self.assertIsNone(warm["eligible"])
        self.assertIn("first_eligible_accepted_opportunity_missing", result["warm_comparisons"][0]["excluded_reasons"])

    def test_malformed_record_is_retained_as_an_error_without_losing_all_slots(self):
        directory = self.root / "block-1-candidate"
        identity = slots.values((directory / "identity.txt").read_text())
        path = directory / "probe/files/keyguard-service-probe/r15" / identity["run_uuid"] / "acquisition/candidate-block1.jsonl"
        with path.open("a") as stream:
            stream.write("{invalid-json\n")
        result = slots.build(self.root, SOURCE)
        self.assertEqual(16, len(result["slots"]))
        self.assertTrue(any("invalid_jsonl" in error for error in result["errors"]))
        self.assertEqual("NOT_ESTABLISHED", result["result"])


if __name__ == "__main__":
    unittest.main(verbosity=2)

#!/usr/bin/env python3
import importlib.util
import struct
import tempfile
import unittest
import uuid
import zlib
from pathlib import Path

spec = importlib.util.spec_from_file_location('r14_stock_oracle', Path(__file__).with_name('r14_stock_oracle.py'))
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)
SOURCE = 'a' * 40


def image(path: Path, color: tuple[int, int, int], width=64, height=64):
    def chunk(tag, content):
        return struct.pack('>I', len(content)) + tag + content + struct.pack('>I', zlib.crc32(tag + content) & 0xffffffff)
    raw = (b'\0' + bytes(color) * width) * height
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)) +
                     chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


class StockOracleControls(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.run = str(uuid.uuid4())
        image(self.root / 'before.png', (8, 12, 20))
        image(self.root / 'green.png', (20, 180, 74))
        image(self.root / 'post.png', (20, 180, 74))
        image(self.root / 'successor.png', (20, 180, 74))
        image(self.root / 'reference.png', (20, 180, 74), 32, 32)
        self.fixture = '\n'.join([
            f'R14 stage=RUN source={SOURCE} run={self.run} case=exclusion pid=12',
            'R14 stage=G1_LIVE session=1 wake=2 attach=1 firstPost=50 submissions=4',
            'R14 stage=G1_WITHDRAWN request=30 session=1 wake=2 attach=1 remove=100',
            'R14 stage=RETURN_ARMED closeRequested=110',
            'R14 stage=A_HELD req=38 start=120 decision=SHOW_FULL reason=MAIN_CONFIRMED session=1 visibility=2 wake=2 interaction=3 attach=1',
            'R14 stage=FRAMEWORK_EQUIVALENCE req=50 framework=true type=32',
            'R14 stage=INDEPENDENT_EXCLUSION visual=true locked=true screenshotEnd=129 screenshot=before-a-occluder.png before=before.png reference=reference.png window=10 display=0',
            'R14 stage=A_DECISION a=38 decision=SHOW_FULL pending=52 at=130 session=1 visibility=2 wake=2 interaction=3 authorityAttach=1 actualAttached=true attach=2',
            'R14 stage=POST_A_WITNESS window=10 display=0 start=131 screenshot=post.png',
            'R14 stage=POST_SUCCESSOR_WITNESS window=10 display=0 start=135 screenshot=successor.png successor=54 locked=true',
            'R14 stage=RESULT a=38 b=52 r=53 successor=54 successorDecision=HIDDEN_OCCLUDED successorReason=FOREIGN_ABOVE lineage=true finalAttached=false',
        ])
        (self.root / 'before-a-occluder.png').write_bytes((self.root / 'green.png').read_bytes())
        (self.root / 'g1-withdrawal-marks.txt').write_text('Mark(sequence=1, stage=8, request=30, attachment=1)\nMark(sequence=2, stage=13, request=0, attachment=1, extra=1)')
        (self.root / 'successor-withdrawal-marks.txt').write_text('Mark(sequence=3, stage=8, request=54, attachment=2)\nMark(sequence=4, stage=13, request=0, attachment=2, extra=1)')
        common = 'session=1 visibility=2 wake=2 interaction=3 attach=1'
        self.queue = '\n'.join([
            f'run={self.run} pid=12 offerOverflow=0 readOverflow=0',
            f'offer=38 parent=0 trigger=window {common} framework=true systemui=false type=32 window=8 display=0 event=110 callback=111',
            f'offer=50 parent=0 trigger=window {common} framework=true systemui=true type=32 window=3 display=0 event=115 callback=116',
            f'offer=52 parent=0 trigger=window {common} framework=false systemui=true type=32 window=3 display=0 event=125 callback=126',
            f'offer=53 parent=52 trigger=authorityReconcile:attach {common}',
            f'offer=54 parent=53 trigger=window {common}',
            'read=38 decision=SHOW_FULL reason=MAIN_CONFIRMED unavailable=false truncated=false stale=false start=120 end=122 applied=SHOW_FULL',
            'read=30 decision=HIDDEN_UNKNOWN reason=NO_MAIN_MARKER unavailable=false truncated=false stale=false start=90 end=92 applied=HIDDEN_UNKNOWN',
            'read=54 decision=HIDDEN_OCCLUDED reason=FOREIGN_ABOVE unavailable=false truncated=false stale=false start=132 end=134 applied=HIDDEN_OCCLUDED',
        ])
        self.raw = 'R14 candidate assertion: pending B must suppress the excess A add'

    def tearDown(self): self.tmp.cleanup()
    def check(self, fixture=None, queue=None, run=None, raw=None, case='exclusion'):
        return oracle.evaluate(case, fixture or self.fixture, queue or self.queue, self.root, SOURCE, run or self.run, raw or self.raw)

    def test_independent_positive_control(self): self.assertEqual([], self.check())
    def test_clock_is_not_a_green_witness(self):
        image(self.root / 'before-a-occluder.png', (12, 12, 15))
        self.assertIn('green_pixels_not_established', self.check())
    def test_wrong_display_window_and_uuid_are_rejected(self):
        self.assertIn('green_owner_or_interval', self.check(fixture=self.fixture.replace('window=10 display=0 start=131', 'window=11 display=0 start=131')))
        self.assertIn('green_owner_or_interval', self.check(fixture=self.fixture.replace('window=10 display=0 start=131', 'window=10 display=1 start=131')))
        self.assertIn('run_identity', self.check(run=str(uuid.uuid4())))
    def test_no_add_and_raw_rejected_a_do_not_pass(self):
        self.assertIn('stock_add_or_actual_decision_missing', self.check(fixture=self.fixture.replace('actualAttached=true', 'actualAttached=false')))
        self.assertIn('stock_add_or_actual_decision_missing', self.check(fixture=self.fixture.replace('A_DECISION a=38 decision=SHOW_FULL', 'A_DECISION a=38 decision=HIDDEN_UNKNOWN')))
    def test_missing_successor_read_or_lineage_does_not_pass(self):
        self.assertIn('successor_read_missing', self.check(queue=self.queue.replace('read=54', 'read=55')))
        self.assertIn('successor_lineage_unproved', self.check(queue=self.queue.replace('offer=54 parent=53', 'offer=54 parent=0')))
    def test_uncorrelated_removal_and_missing_final_green_are_rejected(self):
        (self.root / 'successor-withdrawal-marks.txt').write_text('Mark(sequence=3, stage=8, request=55, attachment=2)')
        self.assertIn('removal_not_correlated:successor-withdrawal-marks.txt', self.check())
        (self.root / 'successor.png').unlink()
        self.assertIn('green_image_missing_or_invalid', self.check())
    def test_late_control_rejects_unknown_or_qualifying_pending(self):
        late = self.fixture.replace('case=exclusion', 'case=late-only') + '\nR14 stage=LATE_WITHDRAWN request=54'
        self.assertIn('pending_origin_unknown', self.check(case='late-only', fixture=late.replace('pending=52', 'pending=999')))
        self.assertIn('late_qualifying_pending', self.check(case='late-only', fixture=late))
    def test_path_without_trace_and_uncalibrated_orb_are_not_proof(self):
        self.assertEqual(['generated_only_anr_path'], oracle.verify_forensic(False, None))
        self.assertEqual([], oracle.verify_forensic(True, None))
        self.assertEqual(['calibrated_orb_frame_missing'], oracle.verify_orb_frame({}))


if __name__ == '__main__': unittest.main(verbosity=2)

#!/usr/bin/env python3
"""Adversarial controls over the five immutable R15-era R14 specimens."""
import importlib.util
import os
from pathlib import Path
import re
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('r16_r14_replay', Path(__file__).with_name('r16_r14_replay.py'))
replay = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(replay)


class ArchivedRecoveryControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(os.environ['R16_R14_FIXTURE_DIR'])
        cls.data = {}
        for label, row in (('exclusion', 'r14_exclusion'), ('fresh-main', 'r14_fresh_main'),
                           ('late-only', 'r14_late_only'), ('real-return', 'r14_real_occlusion'),
                           ('terminal-stale', 'r14_terminal_stale')):
            root = cls.root / label
            identity = dict(line.split('=', 1) for line in (root / 'identity.txt').read_text().splitlines() if '=' in line)
            pid = int((root / 'process-identity.txt').read_text().split()[0].split('=')[1])
            queue = root / 'queue-and-reads.txt'
            cls.data[label] = dict(row=row, fixture=(root / 'fixture.txt').read_text(),
                queue=queue.read_text() if queue.is_file() else '', capture=(root / 'capture.txt').read_text(),
                root=root, source=identity['source'], run_id=identity['run_uuid'], pid=pid,
                raw=(root / 'instrumentation.txt').read_text())

    def evaluate(self, label, **changes):
        return replay.extract(**(self.data[label] | changes))

    def test_five_archived_rows_are_bound_to_original_sources(self):
        for label in self.data:
            with self.subTest(label=label):
                result, errors, _ = self.evaluate(label)
                self.assertEqual([], errors)
                self.assertEqual('PASS', result['status'])
                self.assertEqual('archived_service_control_not_physical_orb', result['meaning'])
        real, _, _ = self.evaluate('real-return')
        self.assertEqual('UNOBSERVED', real['return_visual'])

    def test_swapped_uuid_and_capture_cannot_inherit_a_result(self):
        terminal = self.data['terminal-stale']
        wrong = self.data['real-return']
        result, errors, _ = self.evaluate('terminal-stale', run_id=wrong['run_id'])
        self.assertNotEqual('PASS', result['status'])
        self.assertIn('fixture_identity', errors)
        result, errors, _ = self.evaluate('terminal-stale', capture=wrong['capture'])
        self.assertNotEqual('PASS', result['status'])
        self.assertIn('capture_identity_or_critical_coverage', errors)

    def test_postdated_b_cannot_qualify(self):
        data = self.data['fresh-main']
        fixture = data['fixture'].replace('event=60807 callback=60807', 'event=60899 callback=60899')
        queue = data['queue'].replace('event=60807 callback=60807', 'event=60899 callback=60899')
        self.assertNotEqual(fixture, data['fixture'])
        self.assertNotEqual(queue, data['queue'])
        result, errors, _ = self.evaluate('fresh-main', fixture=fixture, queue=queue)
        self.assertNotEqual('PASS', result['status'])
        self.assertTrue(any('pending' in e or 'identity' in e for e in errors), errors)

    def test_reencoded_or_copied_occluder_cannot_be_the_prior_background(self):
        data = self.data['exclusion']
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for name in ('before-a-green-reference.png', 'before-a-occluder.png',
                         'after-a-occluder.png', 'after-successor-occluder.png',
                         'g1-withdrawal-marks.txt'):
                (root / name).write_bytes((data['root'] / name).read_bytes())
            (root / 'copied-before.png').write_bytes((data['root'] / 'before-a-occluder.png').read_bytes())
            fixture = data['fixture'].replace('before=before-a-before.png', 'before=copied-before.png')
            self.assertNotEqual(fixture, data['fixture'])
            result, errors, _ = self.evaluate('exclusion', fixture=fixture, root=root)
            self.assertNotEqual('PASS', result['status'])
            self.assertIn('green_pixels_not_established', errors)

    def test_wrong_successor_and_terminal_owner_fail(self):
        data = self.data['fresh-main']
        fixture = data['fixture'].replace('successor=88 successorTrigger=', 'successor=89 successorTrigger=')
        self.assertNotEqual(fixture, data['fixture'])
        result, errors, _ = self.evaluate('fresh-main', fixture=fixture)
        self.assertNotEqual('PASS', result['status'])
        self.assertTrue(any('successor' in error for error in errors), errors)
        data = self.data['terminal-stale']
        fixture = data['fixture'].replace('TERMINAL_STALE up=63723 a=36 b=39',
                                          'TERMINAL_STALE up=63723 a=36 b=40')
        self.assertNotEqual(fixture, data['fixture'])
        result, errors, _ = self.evaluate('terminal-stale', fixture=fixture)
        self.assertNotEqual('PASS', result['status'])
        self.assertIn('terminal_request_identity', errors)


if __name__ == '__main__':
    unittest.main(verbosity=2)

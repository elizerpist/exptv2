#!/usr/bin/env python3
"""Conservative acceptance of independent, calibrated R45 frame evidence.

This consumes a witness; it never converts an attach, shader callback or
un-calibrated screenshot into a visible-pixel pass.
"""
import json
import sys
import unittest


def check(witness):
    errors = []
    if not witness or not witness.get('signed_ui'):
        return ['missing signed-UI frame witness']
    cal = witness.get('calibration', {})
    if not all(cal.get(k) for k in ('same_route', 'same_geometry', 'positive', 'negative', 'clock_aligned')):
        errors.append('missing qualified calibration or clock alignment')
    screen, issue, reveal = (witness.get(k) for k in ('screen_on', 'issue', 'reveal'))
    baseline = witness.get('baseline', {})
    if not all(isinstance(x, (int, float)) for x in (screen, issue, reveal, baseline.get('start'), baseline.get('end'))):
        errors.append('missing current-wake boundary')
    elif not (screen <= baseline['start'] <= baseline['end'] < issue <= reveal):
        errors.append('baseline is not strictly after screen-on and before issue')
    if not baseline.get('underlay_match'):
        errors.append('underlay is not independently established')
    frames = sorted(witness.get('frames', []), key=lambda f: f.get('at', -1))
    if not frames or not isinstance(reveal, (int, float)):
        errors.append('no timed independent frames')
    else:
        valid = [f for f in frames if f.get('orb_match') and not f.get('underlay_match')]
        for offset in (200, 500, 1000):
            if not any(abs(f.get('at', -999999) - (reveal + offset)) <= 40 for f in valid):
                errors.append('no matching frame near %d ms' % offset)
        held = [f for f in frames if reveal <= f.get('at', -1) <= reveal + 1000]
        if not held or any(not f.get('orb_match') for f in held):
            errors.append('a sampled hold frame was missing or mismatched')
        if any(b['at'] - a['at'] > 100 for a, b in zip(held, held[1:])):
            errors.append('frame sampling gap exceeds 100 ms')
    forbidden = witness.get('first_forbidden', {})
    if not forbidden.get('observed') or not forbidden.get('underlay_match') or forbidden.get('orb_match'):
        errors.append('first forbidden frame is not a verified underlay')
    return errors


class AcceptanceTests(unittest.TestCase):
    def good(self):
        return {'signed_ui': True, 'calibration': dict.fromkeys(('same_route','same_geometry','positive','negative','clock_aligned'), True),
                'screen_on': 100, 'issue': 150, 'reveal': 200,
                'baseline': {'start': 110, 'end': 140, 'underlay_match': True},
                'frames': [{'at': 200+n, 'orb_match': True, 'underlay_match': False} for n in range(0,1001,50)],
                'first_forbidden': {'observed': True, 'underlay_match': True, 'orb_match': False}}
    def test_calibrated_witness_can_pass(self): self.assertEqual([], check(self.good()))
    def test_receipt_alone_fails(self): self.assertTrue(check({'signed_ui': True}))
    def test_missing_early_baseline_fails(self):
        w=self.good(); w['baseline']['end']=151; self.assertTrue(check(w))
    def test_flash_or_sampling_gap_fails(self):
        w=self.good(); w['frames']=[w['frames'][0],w['frames'][-1]]; self.assertTrue(check(w))
    def test_first_forbidden_orb_fails(self):
        w=self.good(); w['first_forbidden']['orb_match']=True; self.assertTrue(check(w))


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == '--self-test':
        del sys.argv[1:]
        unittest.main()
    else:
        try:
            with open(sys.argv[1], encoding='utf8') as source: evidence=json.load(source)
            if isinstance(evidence, dict) and 'runs' in evidence:
                expected=int(sys.argv[2]) if len(sys.argv)>2 else 1
                runs=evidence['runs']
                failures=[] if len(runs)==expected else ['expected %d independent wakes, got %d' % (expected,len(runs))]
                for i, run in enumerate(runs,1):
                    failures.extend('wake %d: %s' % (i,error) for error in check(run))
            else:
                failures=check(evidence)
        except (IndexError, OSError, ValueError) as error:
            failures=['missing or invalid independent frame witness: '+str(error)]
        print('PASS' if not failures else 'NOT QUALIFIED: '+'; '.join(failures))
        raise SystemExit(0 if not failures else 1)

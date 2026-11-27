#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest

path=Path(__file__).with_name('r47-frame-verdict.py')
spec=importlib.util.spec_from_file_location('r47_frame_verdict', path)
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

def frame(i, state, orb):
    return dict(capture_index=i, marker_seq=100+i, capture_elapsed_ns=1000+i*100,
                state=state, orb=orb, display_frame_token=10000+i, presented=True)

def data(kind):
    vals=['VISIBLE','CLEAR','CLEAR'] if kind=='clean' else ['VISIBLE','VISIBLE','CLEAR']
    return dict(capture_clock='VALIDATED',scene_calibration='PASS',frames=[
        frame(0,'ALLOWED',vals[0]),frame(1,'FORBIDDEN',vals[1]),frame(2,'FORBIDDEN',vals[2])])

def case():
    value=data('one_frame')
    value['owner']=dict(window=42,attachment=1,orb_generation=3)
    value['times']=dict(restriction_elapsed_ns=900,conceal_enter_elapsed_ns=950,conceal_return_elapsed_ns=980)
    value['first_screenshot']=dict(display_frame_token=10001)
    return value

class VerdictTests(unittest.TestCase):
    def test_controls_distinguish_clean_and_exactly_one_frame(self):
        self.assertEqual('PASS',m.control_verdict(data('clean'),'clean'))
        self.assertEqual('PASS',m.control_verdict(data('one_frame'),'one_frame'))
        self.assertEqual('FAIL',m.control_verdict(data('one_frame'),'clean'))
    def test_missing_frame_or_marker_gap_is_not_decidable(self):
        d=data('one_frame');d['frames'][1]['marker_seq']+=1
        self.assertEqual('NOT_DECIDABLE',m.control_verdict(d,'one_frame'))
        d=data('one_frame');d['frames'][1]['orb']='UNKNOWN'
        self.assertEqual('NOT_DECIDABLE',m.control_verdict(d,'one_frame'))
    def test_unknown_compositor_or_screenshot_token_never_qualifies(self):
        for key in ('display_frame_token','presented'):
            c=case();c['frames'][1][key]=None
            self.assertEqual('NOT_DECIDABLE',m.observation(c,dict(clean='PASS',one_frame='PASS'))['status'])
        c=case();c['first_screenshot']={}
        self.assertEqual('NOT_DECIDABLE',m.observation(c,dict(clean='PASS',one_frame='PASS'))['status'])
    def test_known_one_frame_and_control_failure(self):
        self.assertEqual('ORB_PRESENT',m.observation(case(),dict(clean='PASS',one_frame='PASS'))['status'])
        self.assertEqual('NOT_DECIDABLE',m.observation(case(),dict(clean='PASS',one_frame='FAIL'))['status'])
    def test_owner_and_event_time_are_required(self):
        c=case();c['owner']['attachment']=0
        self.assertEqual('NOT_DECIDABLE',m.observation(c,dict(clean='PASS',one_frame='PASS'))['status'])
        c=case();c['times']['conceal_return_elapsed_ns']=920
        self.assertEqual('NOT_DECIDABLE',m.observation(c,dict(clean='PASS',one_frame='PASS'))['status'])
    def test_no_invented_hide_cause(self):
        self.assertEqual('UNPROVEN',m.observation(case(),dict(clean='PASS',one_frame='PASS'))['earliest_divergence'])
        c=case();c['times']=dict(restriction_elapsed_ns=900,conceal_enter_elapsed_ns=1150,conceal_return_elapsed_ns=1200)
        self.assertEqual('WITHDRAWAL_AFTER_FORBIDDEN_CAPTURE',m.observation(c,dict(clean='PASS',one_frame='PASS'))['earliest_divergence'])

if __name__=='__main__': unittest.main(verbosity=2)

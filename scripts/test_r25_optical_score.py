import copy
import unittest
from decimal import Decimal
from r25_optical_score import score


def trial():
    return {'id': 'one', 'device': 'device-a', 'build': 'sha', 'mode': 'FULL',
            'configuration': 'screen-on', 'refresh_hz': 120, 'eligible': True,
            'evidence_id': 'recording-1', 'calibration_id': 'calibration-1', 'eligibility_evidence': 'screen-1',
            'content': 'CORRECT', 'calibration_error_ms': '0',
            'wake': ['0', '0'], 'lockscreen': ['0', '0'], 'first_orb': ['100', '100']}


class OpticalScoringTest(unittest.TestCase):
    def one(self, row, limit='100'):
        return score({'trials': [row]}, Decimal(limit))['trials'][0]

    def test_exactly_100_is_pass(self):
        row = self.one(trial())
        self.assertEqual('PASS', row['combined'])
        self.assertEqual('100', row['physical_wake_to_orb']['upper_ms'])

    def test_interval_crossing_limit_is_inconclusive(self):
        t = trial(); t['first_orb'] = ['99', '101']
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])

    def test_confirmed_absence_and_early_recording(self):
        t = trial(); t['content'] = 'CONFIRMED_ABSENT'; t.pop('first_orb')
        t['observed_until'] = ['100', '101']
        self.assertEqual('FAIL', self.one(t)['combined'])
        t['observed_until'] = ['99', '101']
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])

    def test_missing_evidence_cannot_pass(self):
        t = trial(); t.pop('calibration_error_ms')
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])
        t = trial(); t.pop('wake')
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])
        t = trial(); t['eligible'] = False
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])
        t['ineligible_reason'] = 'credential screen'
        self.assertEqual('INELIGIBLE', self.one(t)['combined'])

    def test_missing_original_evidence_cannot_pass(self):
        t = trial(); t.pop('evidence_id')
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])

    def test_rescore_without_changing_raw_record(self):
        t = trial(); t['first_orb'] = ['80', '80']; original = copy.deepcopy(t)
        for limit, expected in [('100', 'PASS'), ('75', 'FAIL'), ('50', 'FAIL'), ('10', 'FAIL')]:
            self.assertEqual(expected, self.one(t, limit)['combined'])
        self.assertEqual(original, t)

    def test_two_clocks_and_calibration_are_independent(self):
        t = trial(); t['wake'] = ['0', '0']; t['lockscreen'] = ['40', '40']
        t['first_orb'] = ['120', '120']; t['calibration_error_ms'] = '1.5'
        result = self.one(t)
        self.assertEqual('FAIL', result['physical_wake_to_orb']['verdict'])
        self.assertEqual('PASS', result['lockscreen_to_orb']['verdict'])
        self.assertEqual('118.5', result['physical_wake_to_orb']['lower_ms'])
        self.assertEqual('81.5', result['lockscreen_to_orb']['upper_ms'])

    def test_invalid_clock_order_cannot_pass(self):
        t = trial(); t['wake'] = ['101', '101']
        self.assertEqual('INCONCLUSIVE', self.one(t)['combined'])

    def test_maximum_bounds_are_independent(self):
        a = trial(); a['id'] = 'a'; a['first_orb'] = ['99', '100']
        b = trial(); b['id'] = 'b'; b['first_orb'] = ['10', '110']
        result = score({'trials': [a, b]}, '100')['configurations'][0]
        maximum = result['maxima_ms']['physical_wake_to_orb']
        self.assertEqual(('a', 'b'), (maximum['lower_trial_id'], maximum['upper_trial_id']))
        self.assertEqual('INCONCLUSIVE', result['verdict'])

    def test_configuration_maximum_retains_every_trial(self):
        a = trial(); a['id'] = 'a'; a['first_orb'] = ['90', '90']
        b = trial(); b['id'] = 'b'; b['first_orb'] = ['120', '120']
        result = score({'trials': [a, b]}, '100')
        self.assertEqual(2, len(result['trials']))
        self.assertEqual({'PASS': 1, 'FAIL': 1}, result['configurations'][0]['counts'])
        self.assertEqual('b', result['configurations'][0]['maxima_ms']['physical_wake_to_orb']['upper_trial_id'])


if __name__ == '__main__':
    unittest.main()

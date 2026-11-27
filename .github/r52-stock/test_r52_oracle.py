import unittest
from r52_oracle import Frame, classify


class VisualControls(unittest.TestCase):
    def setUp(self):
        self.options = dict(action='unlock', locked_before=True, action_low=30, action_high=32,
                            alignment_ns=2, aligned=True)
        self.clean = [Frame(0, 20, True, 'MAIN'), Frame(1, 45, False, 'LAUNCHER'),
                      Frame(2, 62, False, 'LAUNCHER')]

    def run_case(self, frames=None, **values):
        return classify(self.clean if frames is None else frames, **(self.options | values))['status']

    def test_clean_and_intentional_one_frame_tail(self):
        self.assertEqual('PASS', self.run_case())
        self.assertEqual('FAIL', self.run_case([self.clean[0], Frame(1, 45, True, 'LAUNCHER'), self.clean[2]]))

    def test_pre_action_orb_withheld(self):
        self.assertEqual('INCONCLUSIVE', self.run_case([Frame(0, 20, False, 'MAIN'), *self.clean[1:]]))

    def test_unlocked_sleep(self):
        self.assertEqual('INCONCLUSIVE', self.run_case(action='sleep', locked_before=False))

    def test_excessive_sync_shift(self):
        self.assertEqual('INCONCLUSIVE', self.run_case(aligned=False, alignment_ns=400))

    def test_missing_transition_and_stalled_recording_are_inconclusive(self):
        self.assertEqual('INCONCLUSIVE', self.run_case([self.clean[0], Frame(1, 37, None, None),
                                                       Frame(2, 62, False, 'LAUNCHER')]))
        self.assertEqual('INCONCLUSIVE', self.run_case(self.clean[:1]))
        self.assertEqual('INCONCLUSIVE', self.run_case(action='sleep', power_after=('OFF', True)))


if __name__ == '__main__':
    unittest.main()

"""Conservative classification of separately identified composed frames."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Frame:
    index: int
    pts_ns: int
    orb: bool | None
    scene: str | None


def classify(frames, *, action, locked_before, action_low, action_high,
             alignment_ns, aligned, power_after=None):
    # PTS and action brackets must refer to the same clock *or* to the
    # independently aligned video timeline. Power never supplies a pixel.
    if action not in ('unlock', 'sleep') or locked_before is not True:
        return {'status': 'INCONCLUSIVE', 'reason': 'no locked start'}
    if not aligned or alignment_ns is None:
        return {'status': 'INCONCLUSIVE', 'reason': 'unbounded alignment'}
    if not frames or any(a.pts_ns >= b.pts_ns for a, b in zip(frames, frames[1:])):
        return {'status': 'INCONCLUSIVE', 'reason': 'missing or nonmonotonic frames'}
    prior = [f for f in frames if f.pts_ns + alignment_ns < action_low]
    if not prior or (prior[-1].orb, prior[-1].scene) != (True, 'MAIN'):
        return {'status': 'INCONCLUSIVE', 'reason': 'no painted MAIN precondition'}
    target = 'LAUNCHER' if action == 'unlock' else 'AOD'
    if action == 'sleep' and power_after != ('DOZE', True):
        return {'status': 'INCONCLUSIVE', 'reason': 'OFF or no observed DOZE output'}
    tail = [f for f in frames if f.pts_ns - alignment_ns > action_high]
    if not tail:
        return {'status': 'INCONCLUSIVE', 'reason': 'frame sequence ends before transition'}
    first = next((f for f in tail if f.scene == target), None)
    if first is None:
        return {'status': 'INCONCLUSIVE', 'reason': 'no identified forbidden frame'}
    after = [f for f in tail if f.index >= first.index]
    visible = [f for f in after if f.orb is True]
    last_main = next((f for f in reversed(frames) if f.index < first.index and f.scene == 'MAIN'), None)
    base = dict(last_main=None if last_main is None else last_main.index,
                first_definite_forbidden=first.index,
                last_orb=max((f.index for f in frames if f.orb is True), default=None),
                alignment_uncertainty_ns=alignment_ns)
    if visible:
        last = visible[-1]
        absent = next((f for f in after if f.index > last.index and f.orb is False), None)
        return dict(base, status='FAIL', reason='ORB pixels in an identified forbidden frame',
                    first_sustained_absence=(absent.index if absent and
                        all(f.orb is False for f in after if f.index >= absent.index) else None))
    # A gap between known MAIN and known forbidden can hide the first
    # forbidden frame. This witness must not certify it.
    if last_main is None or last_main.index + 1 != first.index or any(f.orb is not False for f in after):
        return dict(base, status='INCONCLUSIVE', reason='first forbidden frame or sustained absence not covered')
    return dict(base, status='PASS', reason='adjacent identified frames; sustained absence in sample',
                first_sustained_absence=first.index)

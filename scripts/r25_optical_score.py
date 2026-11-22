#!/usr/bin/env python3
"""Score recorded external optical brackets; never used in Android runtime.

Input is a JSON object with a `trials` array. Each trial identifies `device`,
`build`, `mode`, `configuration`, `refresh_hz`, `id`, `evidence_id`,
`calibration_id`, `eligibility_evidence`, and `eligible`. An ineligible trial
needs `ineligible_reason` and `eligibility_evidence`. Eligible trials use `content` CORRECT,
CONFIRMED_ABSENT, CONFIRMED_WRONG, or UNKNOWN, plus `calibration_error_ms`.
Brackets are [low, high] on the same calibrated external clock, in milliseconds:
`wake`, `lockscreen`, `first_orb` and, for confirmed absence, `observed_until`.
ABSENT/WRONG means continuously observed through the entire `observed_until`
bracket, not simply a wrong last frame. Retain raw input and re-run --limit-ms.
"""
from __future__ import annotations

import argparse
import json
from decimal import Decimal, InvalidOperation
from pathlib import Path


def number(value):
    if isinstance(value, bool) or value is None:
        return None
    try:
        result = Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
    return result if result.is_finite() else None


def bracket(value):
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        return None
    low, high = map(number, value)
    return (low, high) if low is not None and high is not None and low <= high else None


def endpoint(trial, name, limit):
    start = bracket(trial.get(name))
    error = number(trial.get('calibration_error_ms'))
    if start is None or error is None or error < 0:
        return {'verdict': 'INCONCLUSIVE', 'reason': 'missing_start_or_calibration'}
    content = trial.get('content')
    if content == 'CORRECT':
        end = bracket(trial.get('first_orb'))
        if end is None:
            return {'verdict': 'INCONCLUSIVE', 'reason': 'missing_first_correct_orb'}
        lower = end[0] - start[1] - error
        upper = end[1] - start[0] + error
        if upper < 0:
            return {'verdict': 'INCONCLUSIVE', 'reason': 'invalid_clock_order'}
        verdict = 'PASS' if upper <= limit else 'FAIL' if lower > limit else 'INCONCLUSIVE'
        return {'verdict': verdict, 'lower_ms': str(lower), 'upper_ms': str(upper)}
    if content in ('CONFIRMED_ABSENT', 'CONFIRMED_WRONG'):
        end = bracket(trial.get('observed_until'))
        if end is None:
            return {'verdict': 'INCONCLUSIVE', 'reason': 'missing_observation_end'}
        covered = end[0] - start[1] - error
        return {'verdict': 'FAIL' if covered >= limit else 'INCONCLUSIVE',
                'reason': 'confirmed_wrong_through_deadline' if covered >= limit else 'recording_ends_early',
                'covered_lower_ms': str(covered)}
    return {'verdict': 'INCONCLUSIVE', 'reason': 'unconfirmed_content'}


def score_trial(trial, limit):
    if trial.get('eligible') is False:
        if not trial.get('ineligible_reason') or not trial.get('eligibility_evidence'):
            return {'raw': trial, 'combined': 'INCONCLUSIVE', 'reason': 'missing_ineligibility_reason'}
        return {'raw': trial, 'combined': 'INELIGIBLE', 'reason': trial['ineligible_reason']}
    if trial.get('eligible') is not True:
        return {'raw': trial, 'combined': 'INCONCLUSIVE', 'reason': 'eligibility_unknown'}
    if not all(trial.get(k) not in (None, '') for k in ('device', 'build', 'mode', 'configuration', 'refresh_hz', 'id', 'evidence_id', 'calibration_id', 'eligibility_evidence')):
        return {'raw': trial, 'combined': 'INCONCLUSIVE', 'reason': 'configuration_incomplete'}
    rate = number(trial.get('refresh_hz'))
    if rate is None or rate <= 0:
        return {'raw': trial, 'combined': 'INCONCLUSIVE', 'reason': 'invalid_refresh_rate'}
    a, b = endpoint(trial, 'wake', limit), endpoint(trial, 'lockscreen', limit)
    verdicts = (a['verdict'], b['verdict'])
    combined = 'FAIL' if 'FAIL' in verdicts else 'PASS' if verdicts == ('PASS', 'PASS') else 'INCONCLUSIVE'
    return {'raw': trial, 'physical_wake_to_orb': a, 'lockscreen_to_orb': b, 'combined': combined}


def score(document, limit):
    if not isinstance(document, dict) or not isinstance(document.get('trials'), list):
        raise ValueError('input must contain a trials array')
    limit = number(limit)
    if limit is None or limit < 0:
        raise ValueError('limit must be a nonnegative finite number')
    rows = [score_trial(t, limit) for t in document['trials']]
    groups = {}
    for result in rows:
        trial = result['raw']
        key = tuple(str(trial.get(k, 'UNKNOWN')) for k in ('device', 'build', 'mode', 'configuration', 'refresh_hz'))
        group = groups.setdefault(key, {'device': key[0], 'build': key[1], 'mode': key[2],
            'configuration': key[3], 'refresh_hz': key[4], 'counts': {}, 'endpoint_counts': {}, 'maxima_ms': {}})
        v = result['combined']; group['counts'][v] = group['counts'].get(v, 0) + 1
        for name in ('physical_wake_to_orb', 'lockscreen_to_orb'):
            value = result.get(name, {})
            if value:
                counts = group['endpoint_counts'].setdefault(name, {})
                ev = value['verdict']; counts[ev] = counts.get(ev, 0) + 1
            if 'upper_ms' in value:
                upper = Decimal(value['upper_ms']); lower = Decimal(value['lower_ms'])
                old = group['maxima_ms'].setdefault(name, {'max_lower_ms': str(lower),
                    'lower_trial_id': trial.get('id'), 'max_upper_ms': str(upper), 'upper_trial_id': trial.get('id')})
                if lower > Decimal(old['max_lower_ms']):
                    old['max_lower_ms'] = str(lower); old['lower_trial_id'] = trial.get('id')
                if upper > Decimal(old['max_upper_ms']):
                    old['max_upper_ms'] = str(upper); old['upper_trial_id'] = trial.get('id')
    for group in groups.values():
        counts = group['counts']
        group['verdict'] = ('FAIL' if counts.get('FAIL') else 'INCONCLUSIVE' if counts.get('INCONCLUSIVE')
                            else 'PASS' if counts.get('PASS') else 'NOT_EVALUATED')
    return {'limit_ms': str(limit), 'trials': rows, 'configurations': list(groups.values())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--limit-ms', type=Decimal, default=Decimal('100'))
    args = parser.parse_args()
    data = json.loads(args.input.read_text(), parse_float=Decimal)
    print(json.dumps(score(data, args.limit_ms), indent=2, default=str, allow_nan=False))


if __name__ == '__main__':
    main()

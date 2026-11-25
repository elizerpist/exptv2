#!/usr/bin/env python3
"""Summarize retained matched-wake artifacts without inventing a grant.

App-side nanoseconds and canvas posts are not physical presentation times.
All source capture hashes and rows, including unknowns, remain in the CSV.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import statistics
import tarfile


def fields(text):
    result = {}
    for token in text.strip().split():
        if '=' in token:
            key, value = token.split('=', 1)
            if key in result:
                raise ValueError(f'duplicate field {key}')
            result[key] = value
    return result


def integer(value):
    try:
        number = int(value)
    except (ValueError, TypeError):
        return None
    return None if number == -(1 << 63) else number


def ms(start, end):
    a, b = integer(start), integer(end)
    return f'{(b-a)/1_000_000:.6f}' if a is not None and b is not None and b >= a else 'UNOBSERVED'


def capture_scalar(text, key):
    match = re.search(r'^' + re.escape(key) + r'=([^\s]+)', text, re.MULTILINE)
    return match.group(1) if match else 'UNOBSERVED'


def analyzed_rows(block, arm, mode, source, trial, report, capture_hash):
    records = [fields(line) for line in report.splitlines() if line.startswith(' R41_CORE ')]
    trial_no = trial.get('trial', 'UNOBSERVED')
    if not records:
        return [dict(block=block, arm=arm, mode=mode, source_sha=source, trial=trial_no,
                     fixture_class=trial.get('class', 'UNOBSERVED'), status='NO_CAPTURE' if mode == 'OFF' else 'NO_CORE',
                     posted=trial.get('workerPost', 'UNOBSERVED'), visible=trial.get('visible', 'UNOBSERVED'),
                     capture_sha256=capture_hash, physical='UNOBSERVED')]
    result = []
    for row in records:
        owner = row.get('owner', 'UNOBSERVED')
        owner_parts = owner.split('/')
        same_owner = owner != 'UNOBSERVED' and all(row.get(key) == owner for key in ('readOwner', 'dispatchOwner', 'grantOwner'))
        same_output = (len(owner_parts) == 3 and owner_parts[1] == trial.get('generation') and
                       trial.get('workerPost') == 'true')
        grant, winner = (integer(row.get(k)) for k in ('grantNs', 'winnerNs'))
        post = integer(trial.get('workerPostNs'))
        cancel = integer(row.get('cancelNs'))
        cancelled_before_post = cancel is not None and grant is not None and post is not None and grant <= cancel <= post
        real_winner = (same_owner and same_output and row.get('invalid') == '0' and grant is not None and
                       winner is not None and post is not None and winner >= grant and post >= grant and
                       not cancelled_before_post)
        eligible = row.get('eligible', 'UNOBSERVED')
        outcome = row.get('outcome', 'UNOBSERVED')
        bound = ms(row.get('wakeNs'), row.get('grantNs')) if real_winner and eligible == 'true' and outcome == 'SUCCESS' else 'UNOBSERVED'
        # Earlier events from the same wake can lack owner/eligibility. Keep
        # their time separately and never silently bind them to the winner.
        same_wake = [integer(other.get('wakeNs')) for other in records
                     if other.get('session') == row.get('session') and other.get('wake') == row.get('wake')]
        earlier = min((n for n in same_wake if n is not None), default=None)
        alternative = ms(str(earlier), row.get('grantNs')) if real_winner and earlier is not None else 'UNOBSERVED'
        result.append(dict(
            block=block, arm=arm, mode=mode, source_sha=source, trial=trial_no,
            fixture_class=trial.get('class', 'UNOBSERVED'), status='MATCHED' if bound != 'UNOBSERVED' else 'UNOBSERVED',
            attempt=row.get('attempt', 'UNOBSERVED'), session=row.get('session', 'UNOBSERVED'), wake=row.get('wake', 'UNOBSERVED'),
            eligible=eligible, outcome=outcome, owner=owner, request=row.get('request', 'UNOBSERVED'),
            posted=trial.get('workerPost', 'UNOBSERVED'), visible=trial.get('visible', 'UNOBSERVED'),
            callback_to_grant_ms=bound, earlier_same_wake_to_grant_ms=alternative,
            screen_to_grant_ms=ms(row.get('screenNs'), row.get('grantNs')) if real_winner else 'UNOBSERVED',
            callback_to_winning_offer_ms=ms(row.get('wakeNs'), row.get('offerNs')),
            offer_to_worker_ms=ms(row.get('offerNs'), row.get('workerNs')),
            worker_to_read_ms=ms(row.get('workerNs'), row.get('readStartNs')),
            read_ms=ms(row.get('readStartNs'), row.get('readEndNs')),
            read_to_dispatch_ms=ms(row.get('readEndNs'), row.get('dispatchNs')),
            dispatch_to_main_ms=ms(row.get('dispatchNs'), row.get('mainNs')),
            main_to_grant_ms=ms(row.get('mainNs'), row.get('grantNs')),
            grant_to_winner_ms=ms(row.get('grantNs'), row.get('winnerNs')),
            cancel_ns=row.get('cancelNs', 'UNOBSERVED'), fallback=row.get('fallbackCandidateAndPostReceipt', 'UNOBSERVED'),
            r42_pre=row.get('r42Pre', 'UNOBSERVED'), r42_stale=row.get('r42Stale', 'UNOBSERVED'),
            coverage=row.get('coverage', 'UNOBSERVED'), invalid=row.get('invalid', 'UNOBSERVED'),
            core_dropped=row.get('dropped', 'UNOBSERVED'), events_recorded=capture_scalar(report, 'eventsRecorded'),
            events_retained=capture_scalar(report, 'eventsRetained'), events_evicted=capture_scalar(report, 'eventsEvicted'),
            export_truncated=capture_scalar(report, 'exportTruncated'), diagnostic_dropped=capture_scalar(report, 'diagnosticDroppedRecords'),
            producer_max_ns=capture_scalar(report, 'diagnosticProducerMaxNs'), capture_sha256=capture_hash,
            physical='UNOBSERVED'))
    return result


def read_member(archive, name):
    member = archive.getmember(name)
    if not member.isfile() or member.size > 2_000_000:
        raise ValueError(f'invalid or excessive artifact member {name}')
    return archive.extractfile(member).read()


def analyze_directory(root):
    all_rows, blocks = [], []
    for path in sorted(root.glob('block-*-*-*')):
        if not path.is_dir():
            continue
        identity = fields((path / 'identity.txt').read_text().replace('\n', ' '))
        block, arm, mode, source = (identity[k] for k in ('block', 'arm', 'mode', 'source'))
        status = (path / 'result.txt').read_text().strip() if (path / 'result.txt').exists() else 'NOT REACHED: block did not finish'
        item = dict(block=block, arm=arm, mode=mode, source_sha=source, result=status, attempted=0)
        tar_path = path / 'device.tar'
        if tar_path.exists() and tar_path.stat().st_size:
            with tarfile.open(tar_path) as archive:
                names = archive.getnames()
                trial_files = [n for n in names if n.endswith('/r41-natural/trials.txt')]
                if len(trial_files) > 1:
                    raise ValueError(f'multiple trial manifests for {path}')
                if trial_files:
                    manifest = trial_files[0]
                    trials = [fields(line) for line in read_member(archive, manifest).decode().splitlines() if line.strip()]
                    item['attempted'] = len(trials)
                    for trial in trials:
                        capture_path = manifest.rsplit('/', 1)[0] + '/capture-' + trial['trial'] + '.txt'
                        if capture_path not in names:
                            all_rows += analyzed_rows(block, arm, mode, source, trial, '', 'UNOBSERVED')
                            continue
                        raw = read_member(archive, capture_path)
                        all_rows += analyzed_rows(block, arm, mode, source, trial, raw.decode('utf-8'), hashlib.sha256(raw).hexdigest())
        blocks.append(item)
    return blocks, all_rows


def summarize(blocks, rows):
    groups = {}
    for block in blocks:
        key = block['arm'] + '/' + block['mode']
        group = groups.setdefault(key, dict(blocks=0, failed_or_unfinished_blocks=0, attempted_wakes=0,
                                            matched_rows=0, below_300=0, at_or_above_300=0, values_ms=[]))
        group['blocks'] += 1
        group['attempted_wakes'] += block['attempted']
        if not block['result'].startswith('PASS:'):
            group['failed_or_unfinished_blocks'] += 1
    for row in rows:
        group = groups[row['arm'] + '/' + row['mode']]
        if row['status'] != 'MATCHED':
            continue
        value = float(row['callback_to_grant_ms'])
        group['matched_rows'] += 1
        group['below_300' if value < 300 else 'at_or_above_300'] += 1
        group['values_ms'].append(value)
    for group in groups.values():
        values = group.pop('values_ms')
        group['observed_min_ms'] = min(values) if values else None
        group['observed_median_ms'] = statistics.median(values) if values else None
        group['observed_max_ms'] = max(values) if values else None
        # Missing/capture-loss rows cannot establish a universal pass.
        group['strict_300ms'] = 'FAIL_OBSERVED_MISS' if group['at_or_above_300'] else 'INCOMPLETE'
    return groups


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('artifact', type=Path)
    parser.add_argument('--csv', type=Path, required=True)
    parser.add_argument('--summary', type=Path, required=True)
    args = parser.parse_args()
    blocks, rows = analyze_directory(args.artifact)
    columns = list(dict.fromkeys(k for row in rows for k in row))
    with args.csv.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)
    args.summary.write_text(json.dumps(dict(blocks=blocks, groups=summarize(blocks, rows),
                                             physical='UNOBSERVED', mode='debug',
                                             optical_and_fallback_grant='UNOBSERVED'), indent=2) + '\n')
    print(json.dumps(summarize(blocks, rows), indent=2))


if __name__ == '__main__':
    main()

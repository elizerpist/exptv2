#!/usr/bin/env python3
"""Fail-closed validator for one fresh, operation-correlated R12 admission specimen."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import tarfile
from pathlib import Path, PurePosixPath
import uuid

METHOD = 'r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply'
CLASS = 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest'
STOCK = '1d19624751169e3af0270b151378cdfcdf1a1129'
ASSERTION = 'compatible B did not start before the held ordered A application'
HEX = re.compile(r'^[0-9a-f]{64}$')
SHA = re.compile(r'^[0-9a-f]{40}$')

class Invalid(ValueError):
    pass

def require(condition, message):
    if not condition:
        raise Invalid(message)

def fields(line):
    result = {}
    for word in line.split():
        if '=' not in word:
            continue
        key, value = word.split('=', 1)
        require(key not in result or result[key] == value, 'conflicting repeated field: ' + key)
        result[key] = value
    return result

def parse_manifest(text):
    result = {}
    for line in text.splitlines():
        if '=' in line:
            key, value = line.split('=', 1)
            require(key not in result, 'duplicate manifest field ' + key)
            result[key] = value
    return result

def validate(manifest, output, fixture, exact, capture, expected):
    require(expected['mode'] in ('baseline', 'candidate'), 'invalid mode')
    require(str(uuid.UUID(expected['run'])) == expected['run'], 'invalid UUID')
    require(SHA.fullmatch(expected['harness']) and SHA.fullmatch(expected['app']), 'unidentified source')
    if expected['mode'] == 'baseline':
        require(expected['app'] == STOCK, 'baseline is not stock R11')
    else:
        require(expected['app'] != STOCK, 'candidate is stock R11')
    for key in ('run', 'mode', 'app', 'harness'):
        require(manifest.get(key) == expected[key], 'manifest identity mismatch ' + key)
    require(manifest.get('api') == '35' and manifest.get('abi') == 'x86_64', 'wrong device')
    for key in ('app_hash', 'test_hash', 'installed_app_hash', 'installed_test_hash'):
        require(HEX.fullmatch(manifest.get(key, '')) is not None, 'missing hash: ' + key)
    require(manifest['app_hash'] == manifest['installed_app_hash'] and
            manifest['test_hash'] == manifest['installed_test_hash'], 'installed APK differs')
    for key in ('instrument_rc', 'log_rc', 'probe_rc', 'window_rc', 'identity_rc', 'extract_rc'):
        require(manifest.get(key) == '0', 'command failed or timed out: ' + key)
    require(manifest.get('preflight') == 'PASS', 'preflight failed')
    require(manifest.get('forced_stop') == 'PASS', 'unverified process cold start')
    require(output.count('INSTRUMENTATION_STATUS: test=' + METHOD) == 2, 'method missing or wrong run count')
    require('INSTRUMENTATION_STATUS: class=' + CLASS in output, 'wrong instrumentation class')
    require('INSTRUMENTATION_STATUS: numtests=1' in output, 'unexpected test count')
    require('INSTRUMENTATION_STATUS_CODE: 1' in output, 'method never began')
    require('INSTRUMENTATION_CODE: -1' in output, 'runner did not complete')
    for forbidden in ('INSTRUMENTATION_FAILED', 'Process crashed', 'Suppressed:', 'Caused by:', 'AssumptionViolatedException'):
        require(forbidden not in output, 'secondary or transport failure: ' + forbidden)
    if expected['mode'] == 'baseline':
        require('INSTRUMENTATION_STATUS_CODE: -2' in output and 'FAILURES!!!' in output,
                'stock expected failure absent')
        require('Tests run: 1,  Failures: 1' in output or 'Tests run: 1, Failures: 1' in output,
                'stock failure count invalid')
        require('java.lang.AssertionError: ' + ASSERTION in output, 'wrong stock failure')
        exceptions = set(re.findall(r'(?:java\.lang\.|junit\.framework\.)[A-Za-z]*?(?:Error|Exception):[^\n]*', output))
        require(exceptions == {'java.lang.AssertionError: ' + ASSERTION}, 'unexpected exception in stock output')
    else:
        require('INSTRUMENTATION_STATUS_CODE: 0' in output and re.search(r'OK \(1 tests?\)', output), 'candidate not green')
        require('FAILURES!!!' not in output and 'AssertionError:' not in output, 'candidate contains failure')
    lines = fixture.splitlines()
    require(lines and all(line.startswith('R12 ') for line in lines), 'invalid fixture shape')
    rows = [fields(line) for line in lines]
    require([r.get('seq') for r in rows] == [str(i) for i in range(1, len(rows)+1)], 'non-contiguous event order')
    require(all(r.get('run') == expected['run'] for r in rows), 'mixed run identity')
    def one(stage, role=None):
        found = [r for r in rows if r.get('stage') == stage and (role is None or r.get('role') == role)]
        require(len(found) == 1, 'missing/duplicate event ' + stage + '/' + str(role))
        return found[0]
    run = one('RUN')
    require(run.get('appSha') == expected['app'] and run.get('harnessSha') == expected['harness'], 'fixture source mismatch')
    require(run.get('mode') == 'FULL' and run.get('pid', '').isdigit(), 'process identity missing')
    require(manifest.get('pid') == run['pid'], 'wrong/old process')
    cap = one('CAPTURE').get('capture')
    require(cap and str(uuid.UUID(cap)) == cap, 'capture identity missing')
    cleanup = one('CLEANUP')
    require(cleanup.get('status') == 'PASS' and cleanup.get('specimen') == 'VALID', 'bad cleanup or specimen')
    for row in rows:
        if row.get('stage') != 'RUN':
            require(row.get('capture') == cap, 'mixed capture identity')
    require('captureId=' + cap in capture and 'processInstance=' + run['pid'] + '-' in capture, 'capture differs')
    a_tree, b_offer = one('A_TREE'), one('B_OFFER')
    a_enter, b_enter = one('APPLY_ENTER', 'A'), one('APPLY_ENTER', 'B')
    a_exit, b_exit = one('APPLY_EXIT', 'A'), one('APPLY_EXIT', 'B')
    a_start, b_start = one('READER_START', 'A'), one('READER_START', 'B')
    a_boundary, release, released, b_tree, order = (one(s) for s in ('A_BOUNDARY', 'A_RELEASE_SIGNAL', 'A_RELEASED', 'B_TREE', 'ORDER'))
    a, b = a_enter['req'], b_enter['req']
    require(a.isdigit() and b.isdigit() and a != b, 'invalid pair')
    require(all(r.get('req') == a for r in (a_tree, a_start, a_exit, a_boundary, release, released)), 'wrong A identity')
    require(all(r.get('req') == b for r in (b_offer, b_start, b_exit, b_tree)), 'wrong B identity')
    require(order.get('a') == a and order.get('b') == b and order.get('specimen') == 'VALID' and order.get('maximumReaders') == '1', 'order pair or reader concurrency mismatch')
    require(a_enter.get('decision') == 'HIDDEN_UNKNOWN' and a_boundary.get('decision') == 'HIDDEN_UNKNOWN', 'wrong actual decision')
    require(a_boundary.get('detached') == 'true' and a_boundary.get('authority') == 'true' and a_boundary.get('b') == b and a_exit.get('detached') == 'true', 'invalid A authority or disclosure')
    freshness = one('A_FRESHNESS')
    require(freshness.get('req') == a and freshness.get('b') == b and freshness.get('outstanding') == 'FRAMEWORK_EVENT' and freshness.get('revision') == b_offer.get('freshnessRevision'), 'freshness changed before apply')
    require(a_boundary.get('active') == b or a_boundary.get('pending') == b, 'B not reserved/active/pending')
    require(a_tree.get('unmasked') == 'MAIN_KEYGUARD' and a_tree.get('masked') == 'UNKNOWN' and a_tree.get('maskedReason') == 'NO_MAIN_MARKER' and a_tree.get('mask') == 'SYNTHETIC_NEGATIVE', 'invalid masked A')
    require(b_tree.get('unmasked') == 'MAIN_KEYGUARD' and b_tree.get('reason') == 'MAIN_CONFIRMED', 'B positive control missing')
    for key in ('session', 'wake', 'epoch', 'interaction', 'attach'):
        require(a_start.get(key) == b_offer.get(key) == b_start.get(key), 'authority mismatch ' + key)
    require(b_offer.get('freshness') == 'FRAMEWORK_EVENT' and b_offer.get('outstanding') == 'FRAMEWORK_EVENT' and b_offer.get('freshnessRevision', '').isdigit(), 'B freshness escalated')
    def seq(row):
        return int(row['seq'])
    require(seq(a_start) < seq(a_tree) < seq(b_offer) < seq(a_enter) < seq(release) < seq(released) < seq(a_exit) < seq(b_enter) < seq(b_exit), 'invalid ordered apply')
    require(seq(a_boundary) < seq(freshness) < seq(release), 'freshness checked at wrong boundary')
    require(seq(b_start) < seq(b_tree) < seq(b_enter), 'invalid B reader order')
    if expected['mode'] == 'baseline':
        require(seq(release) < seq(b_start) and order.get('bStartedBeforeARelease') == 'false', 'stock was not serial')
    else:
        require(seq(b_start) < seq(release) and order.get('bStartedBeforeARelease') == 'true', 'candidate did not read ahead')
    for role, req, tree in (('A', a, a_tree), ('B', b, b_tree)):
        samples = [r for r in rows if r.get('stage') == 'SYSTEM_SAMPLE' and r.get('role') == role]
        require(len(samples) == 2 and [r.get('ordinal') for r in samples] == ['1', '2'], 'missing original system samples')
        require(seq(samples[0]) < seq(tree) < seq(samples[1]), 'system samples are not pre/post tree')
        for sample in samples:
            require(sample.get('req') == req, 'sample belongs to another request')
            for key in ('available', 'primary', 'interactive', 'displayOn', 'locked', 'userUnlocked'):
                require(sample.get(key) == 'true', 'ineligible system sample: ' + key)
            require(sample.get('displayOff') == 'false', 'display off')
    exact_rows = [fields(line) for line in exact.splitlines() if line.strip()]
    require(len(exact_rows) == 2, 'missing exact diagnostic events')
    for row, req, start, wanted in ((exact_rows[0], a, a_start, 'NO_MAIN_MARKER'), (exact_rows[1], b, b_start, 'MAIN_CONFIRMED')):
        require(row.get('capture') == cap and row.get('process', '').startswith(run['pid'] + '-') and row.get('req') == req and row.get('stage') == 'INSPECTION_FINISHED', 'wrong exact event')
        require(row.get('session') == start.get('session') and row.get('wake') == start.get('wake'), 'wrong exact event authority')
        require(row.get('reason') == wanted, 'wrong exact reason')
        for key in ('rootUnavailable', 'walkTruncated', 'abortedStale'):
            require(row.get(key) == 'false', 'incomplete exact event: ' + key)
        require(row.get('requestVisibilityEpoch') == start.get('epoch') and row.get('requestInteractionEpoch') == start.get('interaction') and row.get('requestWakeGeneration') == start.get('wake'), 'exact event epoch mismatch')
    require(exact_rows[0].get('surfaceClassification') == 'HIDDEN_UNKNOWN', 'wrong exact A decision')
    require(exact_rows[1].get('surfaceClassification') in ('SHOW_FULL', 'SHOW_DISCREET'), 'B not positive')
    return {'verdict': 'RED_EXPECTED=actual_service_serial_order' if expected['mode'] == 'baseline' else 'PASS=actual_service_ordered_read_ahead',
            'run': expected['run'], 'capture': cap, 'app': expected['app'], 'harness': expected['harness'], 'a': a, 'b': b, 'pid': run['pid']}

def read_tar(path, run):
    members = {}
    with tarfile.open(path, mode='r:*') as archive:
        for member in archive.getmembers():
            p = PurePosixPath(member.name)
            require(not p.is_absolute() and '..' not in p.parts, 'unsafe tar path')
            require(member.isdir() or member.isfile(), 'unsupported tar member')
            if member.isfile():
                require(len(p.parts) == 2 and p.parts[0] == run, 'stale/foreign tar output')
                require(p.name in ('fixture.txt', 'exact-events.txt', 'capture.txt', 'a-exact-partial.txt'), 'unexpected artifact')
                require(p.name not in members and 0 < member.size <= 131072, 'duplicate/empty/oversize artifact')
                stream = archive.extractfile(member)
                require(stream is not None, 'unreadable artifact')
                members[p.name] = stream.read().decode('utf-8', errors='strict')
    require({'fixture.txt', 'exact-events.txt', 'capture.txt'}.issubset(members), 'incomplete artifact')
    return members

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--dir', type=Path, required=True)
    p.add_argument('--run', required=True)
    p.add_argument('--mode', choices=('baseline', 'candidate'), required=True)
    p.add_argument('--app', required=True)
    p.add_argument('--harness', required=True)
    args = p.parse_args()
    expected = {'run': args.run, 'mode': args.mode, 'app': args.app, 'harness': args.harness}
    try:
        manifest = parse_manifest((args.dir / 'manifest.txt').read_text())
        output = (args.dir / 'instrumentation.txt').read_text()
        archive = read_tar(args.dir / 'probe.tar', args.run)
        for name, value in archive.items():
            (args.dir / name).write_text(value)
        result = validate(manifest, output, archive['fixture.txt'], archive['exact-events.txt'], archive['capture.txt'], expected)
        (args.dir / 'verdict.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
        print(result['verdict'])
    except (Invalid, OSError, ValueError, tarfile.TarError, UnicodeError, KeyError) as error:
        (args.dir / 'verdict.json').write_text(json.dumps({'verdict':'FAIL=baseline_control_not_proven', 'reason':str(error)}, indent=2) + '\n')
        print('FAIL=admission_control_not_proven', error)
        raise SystemExit(1)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Validate pasted bytes; software draw receipts are not optical evidence."""
import hashlib
import os
import re
import sys
from pathlib import Path

payload = Path(sys.argv[1]).read_bytes()
route, expected = sys.argv[2], int(sys.argv[3])
text = payload.decode('utf-8')
assert text.startswith('FLUVI_R46_RECORDING_V1\n'), 'missing versioned header'
assert text.endswith('END_FLUVI_R46_RECORDING_V1\n'), 'missing terminal footer'
assert f'route={route} ' in text, 'wrong route'
body, footer = payload.rsplit(b'bodyBytes=', 1)
match = re.match(rb'(\d+) bodySha256=([0-9a-f]{64})\n', footer)
assert match and int(match.group(1)) == len(body), 'body length mismatch'
assert match.group(2).decode() == hashlib.sha256(body).hexdigest(), 'body digest mismatch'
print('reportIntegrity=PASS')
if len(sys.argv) == 6:
    app, capture = sys.argv[4:]
    assert re.fullmatch(r'[0-9a-f]{40}', app), 'missing expected source'
    header, summary = text.split('SUMMARY_BEGIN\n', 1)
    summary = summary.split('SUMMARY_END\n', 1)[0]
    assert f'captureId={capture} route={route} end=USER_STOP\n' in header, 'wrong recording owner'
    assert 'clock=uptimeMs source=app_private_spool\n' in header, 'wrong report provider'
    assert re.findall(r'^build=(.*)$', summary, re.M) == [app], 'wrong or ambiguous app source'
    assert 'buildMode=profile\n' in summary, 'expected signed Human profile'
    spool = text.split('DETAILED_RECORDS_BEGIN\n', 1)[1].split('DETAILED_RECORDS_END\n', 1)[0]
    counts = re.search(r'^spoolAccepted=(\d+) spoolWritten=(\d+) spoolDropped=0 spoolFailure=none$',
                       text, re.M)
    assert counts and int(counts[1]) == int(counts[2]) == len(spool.splitlines()) > 0, 'spool row count mismatch'
    assert re.search(r'^R44_WAKE capture=' + re.escape(capture) + r' session=[1-9]\d* wake=[1-9]\d*',
                     summary, re.M), 'missing same-capture session/wake'
    assert re.search(r'^R47_MATERIAL origin=active_header_(semantic|frame_package) ', spool, re.M), 'missing active-header receipt'
    assert 'palette=compiled_public_v1' not in spool, 'public fixture material was used'
    print(f'recordingOwner=PASS capture={capture} source={app} route={route} provider=app_private_spool')
    print(f'spoolIntegrity=PASS rows={counts[2]}')
    sys.exit(0)
rows = [line for line in text.splitlines() if line.startswith('R45_EVENT ')]
events = {}
for row in rows:
    wake = re.search(r'originWakeEpoch=(\d+)', row)
    stage = re.search(r'stage=([A-Z_]+)', row)
    route_value = re.search(r'route=([A-Z_]+)', row)
    if wake and stage and route_value:
        if route_value.group(1) != route and stage.group(1) in ('ADD_BEGIN', 'REVEAL', 'FIRST_SHADER_DRAW', 'FIRST_FRAME_DRAW'):
            raise AssertionError('unselected renderer produced output')
        events.setdefault(wake.group(1), set()).add(stage.group(1))
qualified = [wake for wake, stages in events.items()
             if 'REVEAL' in stages and bool({'FIRST_SHADER_DRAW', 'FIRST_FRAME_DRAW'} & stages)]
print(f'route={route} expectedWakes={expected} observedWakeIds={sorted(events)} softwareDrawWakes={qualified}')
for wake, stages in sorted(events.items()): print(f'wake={wake} stages={sorted(stages)}')
assert len(qualified) >= expected, 'NOT REACHED: fewer same-wake software reveal/content-draw receipts than requested'
assert 'spoolDropped=0' in text and 'spoolFailure=none' in text, 'spool incomplete'
if os.environ.get('R47_REQUIRE_ACTIVE_HEADER') == 'true':
    source = set(re.findall(r'R47_MATERIAL origin=(active_header_semantic|active_header_frame_package) token=([a-f0-9-]+)', text))
    draws = set(re.findall(r'origin=(active_header_semantic|active_header_frame_package) token=([a-f0-9-]+)', '\n'.join(
        line for line in text.splitlines() if 'MOTION' in line)))
    assert source and source.intersection(draws), 'NOT REACHED: no matching current-header source and draw token'
    assert 'palette=compiled_public_v1' not in text, 'FAIL: public fixture was used by the owner recording'
    print('matchingCurrentHeaderReceipt=PASS')
print('softwareWakeReceipts=PASS')

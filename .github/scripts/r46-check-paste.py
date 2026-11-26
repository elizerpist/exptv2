#!/usr/bin/env python3
"""Validate pasted bytes; software draw receipts are not optical evidence."""
import hashlib
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
rows = [line for line in text.splitlines() if line.startswith('R45_EVENT ')]
events = {}
for row in rows:
    wake = re.search(r'originWakeEpoch=(\d+)', row)
    stage = re.search(r'stage=([A-Z_]+)', row)
    route_value = re.search(r'route=([A-Z_]+)', row)
    if wake and stage and route_value:
        if route_value.group(1) != route and stage.group(1) in ('ADD_BEGIN', 'REVEAL', 'FIRST_SHADER_DRAW'):
            raise AssertionError('unselected renderer produced output')
        events.setdefault(wake.group(1), set()).add(stage.group(1))
qualified = [wake for wake, stages in events.items() if {'REVEAL', 'FIRST_SHADER_DRAW'} <= stages]
print(f'route={route} expectedWakes={expected} observedWakeIds={sorted(events)} softwareDrawWakes={qualified}')
for wake, stages in sorted(events.items()): print(f'wake={wake} stages={sorted(stages)}')
assert len(qualified) >= expected, 'NOT REACHED: fewer same-wake software reveal/shader receipts than requested'
assert 'spoolDropped=0' in text and 'spoolFailure=none' in text, 'spool incomplete'
print('reportIntegrity=PASS')

#!/usr/bin/env python3
"""Turn retained screenshot brackets into honest, uncalibrated frame records.

Hashes and time intervals are direct observations. They do not establish the
orb silhouette, animation, presentation time or a first forbidden frame. A
pixel PASS additionally needs a calibrated, same-route reference and a frame
stream narrow enough for each checkpoint.
"""
import hashlib
import json
import re
import sys
from pathlib import Path

root, log_path, cycles, output = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]), Path(sys.argv[4])
brackets = {}
pattern = re.compile(r'^\s*\[?\s*(\d+)\.(\d+)\]?\s+.*R46Optical\s*:\s*(before|after)\s+(\d+)\s+(\d+)\s+(\d+)')
for line in log_path.read_text(errors='replace').splitlines():
    m = pattern.search(line)
    if not m:
        continue
    sec, frac, edge, run, wake, frame = m.groups()
    if int(run) != cycles:
        continue
    milliseconds = int(sec) * 1000 + int(frac[:3].ljust(3, '0'))
    brackets.setdefault((int(wake), int(frame)), {})[edge] = milliseconds

runs = []
for wake in range(1, cycles + 1):
    frames = []
    for image in sorted((root / f'{cycles}-{wake}').glob('*.png'), key=lambda p: int(p.stem)):
        timing = brackets.get((wake, int(image.stem)), {})
        frames.append({'file': str(image.relative_to(root)), 'sha256': hashlib.sha256(image.read_bytes()).hexdigest(),
                       'capture_start_up_ms': timing.get('before'), 'capture_end_up_ms': timing.get('after'),
                       'orb_match': None, 'underlay_match': None})
    runs.append({'signed_ui': True, 'wake_index': wake,
                 'calibration': {'same_route': False, 'same_geometry': False, 'positive': False,
                                 'negative': False, 'clock_aligned': False},
                 'frames': frames,
                 'reason': 'PNG intervals retained; same-wake calibrated ORB/underlay and physical presentation are unobserved',
                 'first_forbidden': {'observed': False}})
output.write_text(json.dumps({'runs': runs}, indent=2) + '\n')
print(f'wrote {len(runs)} wake records; optical qualification remains NOT QUALIFIED')

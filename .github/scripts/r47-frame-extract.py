#!/usr/bin/env python3
"""Record every video frame and visual marker; never infer SF/physical identity."""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path
from PIL import Image

case = Path(sys.argv[1])
logs = list(case.glob('probe/**/frame-correlation.txt')) + list(case.glob('probe/**/r47-prepared-visual.txt'))
if len(logs) != 1:
    print('NOT_DECIDABLE: marker log missing or ambiguous')
    raise SystemExit(1)
log_path = logs[0]
log = log_path.read_text()
marker = re.search(r'markerScreen=(\d+),(\d+)', log)
if not marker:
    print('NOT_DECIDABLE: marker screen location missing')
    raise SystemExit(1)
x, y = map(int, marker.groups())
geometry = re.search(r'measured=Rect\((\d+), (\d+) - (\d+), (\d+)\)', log)
size = re.search(r'markerScreen=\d+,\d+ size=(\d+)x(\d+)', log)
control = 'control=' in log.splitlines()[0]
if control and size:
    w, h = map(int, size.groups())
    bounds = (x + w // 2 - 100, y + h // 2 - 100, x + w // 2 + 100, y + h // 2 + 100)
elif geometry:
    bounds = tuple(map(int, geometry.groups()))
else:
    print('NOT_DECIDABLE: orb bounds missing')
    raise SystemExit(1)
video_dir = case / 'video-validated'
summary_path = video_dir / 'decode-summary.json'
summary = json.loads(summary_path.read_text()) if summary_path.exists() else {}
validated = summary.get('timestamp_mapping') == 'VALIDATED'
frame_dir = video_dir / 'frames' if (video_dir / 'frames').is_dir() else case / 'video-fallback-frames'
frames = sorted(frame_dir.glob('*.png'))
times = {}
if validated:
    for line in (video_dir / 'frame-index.jsonl').read_text().splitlines():
        row = json.loads(line)
        times[row['index']] = row['elapsed_ns']
if not frames:
    print('NOT_DECIDABLE: no decoded video frames')
    raise SystemExit(1)
crop_dir = case / 'all-orb-crops'
crop_dir.mkdir(exist_ok=True)
rows = []
for i, path in enumerate(frames):
    with Image.open(path).convert('RGB') as image:
        if x + 52 + 12*20 >= image.width or y+48 >= image.height or bounds[2] > image.width or bounds[3] > image.height:
            state, sequence, orb = 'UNKNOWN', None, 'UNKNOWN'
        else:
            r,g,b = image.getpixel((x+24,y+24))
            state = 'FORBIDDEN' if r > 160 and g < 100 and b < 100 else 'ALLOWED' if b > 160 and r < 100 and g < 100 else 'UNKNOWN'
            sequence = 0
            for bit in range(12):
                rgb = image.getpixel((x+61+bit*20,y+20))
                mean = sum(rgb)/3
                if mean > 190: sequence |= 1 << bit
                elif mean > 65:
                    sequence = None
                    break
            crop = image.crop(bounds)
            crop.save(crop_dir / path.name)
            pix = crop.load(); cw,ch=crop.size
            diffs=[]
            for iy in range(ch//4, 3*ch//4, max(1,ch//40)):
                for ix in range(cw//4, 3*cw//4, max(1,cw//40)):
                    rr,gg,bb=pix[ix,iy]
                    diffs.append(max(abs(rr-11),abs(gg-177),abs(bb-67)))
            fraction=sum(v>25 for v in diffs)/len(diffs)
            orb = 'VISIBLE' if fraction >= .25 else 'CLEAR' if fraction <= .01 else 'UNKNOWN'
        rows.append({'capture_index':i,'capture_elapsed_ns':times.get(i),'state':state,'marker_seq':sequence,
                     'orb':orb,'display_frame_token':None,'presented':None,'image':str(path.relative_to(case))})
with (case/'all-frame-observations.jsonl').open('w') as output:
    for row in rows: output.write(json.dumps(row,sort_keys=True)+'\n')
transitions=[]
for before,after in zip(rows,rows[1:]):
    if before['state']=='ALLOWED' and after['state']=='FORBIDDEN':
        transitions.append({'before':before,'first_sample':after,'next_sample':rows[after['capture_index']+1] if after['capture_index']+1<len(rows) else None})
report={'clock':'VALIDATED' if validated else 'UNOBSERVED','frames':len(rows),'marker_location':[x,y],
        'orb_bounds':bounds,'transitions':transitions,'compositor_frame_id':'UNOBSERVED',
        'screenshot_frame_id':'UNOBSERVED','actual_first_forbidden_frame':'NOT_DECIDABLE',
        'physical_presentation':'UNOBSERVED','note':'Host producer marker and screenrecord sample are not SurfaceFlinger display identity.'}
shot = log_path.parent / 'after-hide-first-full.png'
if shot.exists():
    with Image.open(shot).convert('RGB') as image:
        if x+292 < image.width and y+48 < image.height:
            red, green, blue = image.getpixel((x+24,y+24))
            shot_state = 'FORBIDDEN' if red > 160 and green < 100 and blue < 100 else 'ALLOWED' if blue > 160 and red < 100 and green < 100 else 'UNKNOWN'
            shot_sequence = 0
            for bit in range(12):
                mean = sum(image.getpixel((x+61+bit*20,y+20)))/3
                if mean > 190: shot_sequence |= 1 << bit
                elif mean > 65:
                    shot_sequence = None
                    break
            matches = [row['capture_index'] for row in rows if row['state']==shot_state and row['marker_seq']==shot_sequence]
            report['screenshot_host_marker']={'state':shot_state,'sequence':shot_sequence,'video_sample_indices':matches,
                'identity_meaning':'host producer buffer only; not exact compositor or screenshot presentation frame'}
(case/'frame-extract-summary.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
print(json.dumps(report,sort_keys=True))

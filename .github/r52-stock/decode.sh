#!/usr/bin/env bash
set -euo pipefail
out="$1"
input="${2:-$out/calibration.mp4}"
ffprobe -v error -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp_time,pkt_duration_time,pict_type -of csv=p=0 "$input" > "$out/pts.csv"
mkdir -p "$out/frames"
ffmpeg -v error -threads 2 -i "$input" -fps_mode passthrough -threads 2 "$out/frames/%06d.png"
python3 - "$out" <<'PY'
from pathlib import Path
import csv, json, sys
from PIL import Image, ImageChops
p = Path(sys.argv[1])
times = [float(row[0]) for row in csv.reader((p/'pts.csv').open()) if row and row[0] not in ('', 'N/A')]
imgs = sorted((p/'frames').glob('*.png'))
assert len(imgs) == len(times) and len(times) > 2, (len(imgs), len(times))
gaps = [b-a for a,b in zip(times,times[1:])]
assert min(gaps) > 0, min(gaps)
different = ImageChops.difference(Image.open(imgs[0]).convert('RGB'), Image.open(imgs[-1]).convert('RGB')).getbbox()
assert different, 'calibration visual change missing'
report = dict(frames=len(imgs), first_pts_s=times[0], last_pts_s=times[-1], worst_observed_gap_s=max(gaps), different_box=different)
print(json.dumps(report))
(p/'decode.json').write_text(json.dumps(report)+'\n')
PY

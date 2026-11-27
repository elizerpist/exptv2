"""Evaluate encoded composed output separate from application receipts."""
import csv
import json
import math
from pathlib import Path
import statistics
import subprocess
from PIL import Image, ImageChops, ImageStat

from r52_oracle import Frame, classify

NS = 1_000_000_000
SYNC = {0: (23, 190, 235), 1: (253, 27, 145), 2: (18, 225, 149)}


def color_at(frame):
    cx = int(.16 * frame.width)
    cy = int(.20 * frame.height)
    sample = ImageStat.Stat(frame.crop((cx - 4, cy - 4, cx + 4, cy + 4))).mean
    return next((code for code, rgb in SYNC.items()
                 if max(abs(a - b) for a, b in zip(rgb, sample)) < 34), None)


def orb_fraction(image):
    small = image.resize((38, 38))
    pixels = small.load()
    colorful = 0
    for y in range(38):
        for x in range(38):
            if (x - 18.5) ** 2 + (y - 18.5) ** 2 >= 196:
                continue
            r, g, b = pixels[x, y]
            if max(r, g, b) - min(r, g, b) >= 64 and b > g + 18 and r > g + 10:
                colorful += 1
    return colorful / (math.pi * 196)


def roi(frame, original, box):
    width, height = original
    x1, y1, x2, y2 = box
    return frame.crop((round(x1 * frame.width / width), round(y1 * frame.height / height),
                       round(x2 * frame.width / width), round(y2 * frame.height / height)))


def clock_comparison(image):
    box = (.27, .14, .73, .48)
    return roi(image, (1, 1), box).resize((24, 36)).convert("L")


def frame_stream(path, width, height):
    cmd = ["ffmpeg", "-v", "error", "-threads", "2", "-i", str(path),
           "-pix_fmt", "rgb24", "-fps_mode", "passthrough", "-threads", "1", "-f", "rawvideo", "-"]
    block = width * height * 3
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    try:
        while blob := process.stdout.read(block):
            assert len(blob) == block, f"truncated frame {len(blob)} != {block}"
            yield Image.frombytes("RGB", (width, height), blob)
        assert process.wait(timeout=8) == 0, "decoder failed"
    finally:
        if process.poll() is None:
            process.terminate()
        process.wait(timeout=8)


def analyze_video(output: Path, name, attempts, anchors):
    path = output / (name + ".mp4")
    assert path.is_file() and path.stat().st_size > 0, f"{name} screenrecord MP4 missing"
    payload = subprocess.check_output(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_frames", "-show_streams",
         "-show_entries", "frame=best_effort_timestamp_time:stream=width,height,codec_name",
         "-of", "json", str(path)], timeout=30,
    )
    (output / (name + "-video-meta.json")).write_bytes(payload)
    meta = json.loads(payload)
    times = [round(float(row["best_effort_timestamp_time"]) * NS) for row in meta["frames"]]
    assert len(times) >= 3
    cadence = [b - a for a, b in zip(times, times[1:])]
    assert min(cadence) > 0, "non-increasing PTS"
    width, height = (meta["streams"][0][k] for k in ("width", "height"))
    streams = {}
    references = {}
    sync = {}
    for row in attempts:
        key = row["name"]
        if "bounds" not in row:
            continue
        positive = output / (key + "-painted-pre.png")
        if not positive.exists():
            continue
        with Image.open(positive) as pre:
            clock = clock_comparison(pre)
            strength = orb_fraction(pre.crop(row["bounds"]).convert("RGB"))
        negative = output / (key + "-absent-crop.png")
        absent = None
        if negative.exists():
            with Image.open(negative) as after:
                absent = orb_fraction(after.convert("RGB"))
        valid = strength > .10 and absent is not None and absent < .05
        references[key] = (clock, valid, strength, absent)
        streams[key] = []

    data_path = output / (name + "-frames.csv")
    with data_path.open("w") as handle:
        writer = csv.writer(handle)
        writer.writerow(("frame", "pts_ns", "sync_color", "trial", "orb_fraction", "orb", "scene"))
        count = 0
        for index, frame in enumerate(frame_stream(path, width, height)):
            count += 1
            stamp = times[index]
            color = color_at(frame)
            if color in {1, 2} and color not in sync:
                sync[color] = (index, stamp)
                frame.save(output / f"{name}-sync-{color}.png")
            if not streams:
                writer.writerow((index, stamp, color))
            for row in attempts:
                key = row["name"]
                if key not in streams:
                    continue
                clock, valid, positive, absent = references[key]
                fraction = orb_fraction(roi(frame, row["extent"], row["bounds"]))
                present = True if valid and fraction >= .09 else False if valid and fraction < .045 else None
                scene = None
                if color == 0:
                    scene = "LAUNCHER"
                else:
                    current = clock_comparison(frame)
                    error = ImageStat.Stat(ImageChops.difference(clock, current)).mean[0]
                    if error < 13 and max(clock.getextrema()) - min(clock.getextrema()) > 30:
                        scene = "MAIN"
                streams[key].append(Frame(index, stamp, present, scene))
                writer.writerow((index, stamp, color, key, round(fraction, 4), present, scene))
        assert count == len(times), (count, len(times))

    # Each synchronization edge supplies a permissible elapsed minus PTS
    # interval. A common offset requires their intersection to be nonempty.
    intervals = {
        label: [anchors[label][0] - sync[code][1], anchors[label][1] - sync[code][1]]
        for code, label in ((1, "start"), (2, "end")) if anchors.get(label) is not None and code in sync
    }
    aligned = len(intervals) == 2
    if aligned:
        lo = max(pair[0] for pair in intervals.values())
        hi = min(pair[1] for pair in intervals.values())
        uncertainty = (hi - lo) // 2 + statistics.median(cadence)
        aligned = lo <= hi and uncertainty <= 120_000_000
    else:
        lo = hi = None
        uncertainty = None
    verdicts = []
    for row in attempts:
        key = row["name"]
        sequence = streams.get(key, [])
        lower, upper = row.get("action_bracket_ns", [0, 0])
        before = row.get("state_before", ())
        after = row.get("state_after", ())
        # Keep adjacent blocks of repeated reference changes out of the trial's
        # window by using this action's independently measured five-second hold.
        if aligned and lower:
            offset = (lo + hi) // 2
            sequence = [f for f in sequence if lower - 2 * NS <= f.pts_ns + offset <= upper + 4 * NS]
            lower, upper = lower - offset, upper - offset
        result = classify(sequence, action=row["route"], locked_before=list(before) == ["ON", "true", "true"],
                          action_low=lower, action_high=upper, alignment_ns=uncertainty,
                          aligned=aligned, power_after=tuple(after[:2]))
        if key in references:
            _, valid, positive, absent = references[key]
            result.update(palette_calibrated=valid, positive=positive, absent=absent)
        result["name"] = key
        verdicts.append(result)
    report = dict(frames=len(times), pts_start=times[0], pts_end=times[-1],
                  median_gap_ns=statistics.median(cadence), max_gap_ns=max(cadence),
                  cadence_above_50ms=[(i, gap) for i, gap in enumerate(cadence) if gap > 50_000_000],
                  sync=sync, offset_intervals_ns=intervals, offset_bounds_ns=[lo, hi],
                  alignment_ns=uncertainty, aligned=aligned, verdicts=verdicts)
    (output / (name + "-video.json")).write_text(json.dumps(report, indent=2) + "\n")
    if not attempts:
        assert {1, 2}.issubset(sync), "both independent calibration colors were not decoded"
    return report

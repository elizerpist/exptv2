"""Frame ledger and clock checks for one bounded screenrecord of a synthetic unlock."""

import csv
from dataclasses import asdict
from decimal import Decimal
import json
import statistics
import subprocess

from PIL import Image

from r52_video import frame_stream
from r53_mp4 import MetadataError, from_file
from r53_oracle import Frame, classify, order
from r53_pixels import PixelWitness

MS = 1_000_000
ABSOLUTE_CLOCK_GUARD_NS = 20 * MS


def probe_video(path):
    raw = subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_frames", "-show_streams",
        "-show_entries", "frame=best_effort_timestamp_time:stream=width,height,codec_name",
        "-of", "json", str(path),
    ], timeout=35)
    probe = json.loads(raw)
    pts = tuple(int(Decimal(row["best_effort_timestamp_time"]) * 1_000_000_000) for row in probe["frames"])
    if len(pts) < 2 or any(a >= b for a, b in zip(pts, pts[1:])):
        raise MetadataError("decoded PTS is incomplete or out of order")
    return raw, pts, (probe["streams"][0]["width"], probe["streams"][0]["height"])


def clock_check(metadata, draws, edges, clip_bounds, display, extent):
    """Validate the recorder timebase without assigning any bound to source-image age."""
    errors = []
    delays = {}
    offsets = []
    if metadata is None:
        return ["Winscope metadata unavailable"], delays
    if min(metadata.elapsed_ns) < clip_bounds[0] - ABSOLUTE_CLOCK_GUARD_NS or max(
        metadata.elapsed_ns
    ) > clip_bounds[1] + ABSOLUTE_CLOCK_GUARD_NS:
        errors.append("elapsed timestamp outside recording bracket")
    for phase in (1, 2):
        draw = draws.get(phase)
        edge = edges.get(phase)
        if not draw or edge is None:
            errors.append(f"missing independent draw or encoded color edge {phase}")
            continue
        if draw["display"] != display or tuple(draw["extent"]) != extent:
            errors.append(f"wrong display or extent for draw {phase}")
        start, end = draw["up_before_ms"], draw["up_after_ms"]
        elapsed = draw["elapsed_ns"]
        if not 0 <= end - start <= 5:
            errors.append(f"unbounded draw clock sample {phase}")
        offsets.append((elapsed - (end + 1) * MS, elapsed - start * MS))
        delay = metadata.elapsed_ns[edge] - elapsed
        delays[phase] = delay
        if delay < -ABSOLUTE_CLOCK_GUARD_NS:
            errors.append(f"encoded edge {phase} precedes its draw")
    if len(offsets) == 2 and max(x[0] for x in offsets) - min(x[1] for x in offsets) > 2 * MS:
        errors.append("suspend or elapsed/uptime offset discontinuity")
    valid_references = all(phase in draws and phase in edges for phase in (1, 2))
    if valid_references and not (
        draws[1]["elapsed_ns"] < draws[2]["elapsed_ns"] and edges[1] < edges[2]
        and metadata.elapsed_ns[edges[1]] < draws[2]["elapsed_ns"] + ABSOLUTE_CLOCK_GUARD_NS
    ):
        errors.append("inconsistent reference order")
    return errors, delays


def capture_points(ledger, result, points):
    """Absolute joins on the measured recorder clock. Source/display intervals need separate proof."""
    observed = {}
    marker = points.get("local_hide_ns")
    locked = points.get("locked_read_interval_ns")
    negative = points.get("unlocked_read_interval_ns")
    for key in ("first_definite_restricted", "last_orb", "first_subsequent_absent",
                "first_sustained_sampled_absent", "forbidden_positive"):
        endpoint = result.get(key)
        observed[key] = None
        if endpoint and ledger["absolute_recorder_clock"]:
            t = endpoint["time_ns"]
            bound = (t - ABSOLUTE_CLOCK_GUARD_NS, t + ABSOLUTE_CLOCK_GUARD_NS)
            observed[key] = dict(recorder_interval_ns=bound,
                                 recorder_minus_local_hide_ns=t - marker if marker is not None else None,
                                 recorder_vs_local_hide=order(bound, (marker, marker) if marker is not None else None),
                                 recorder_vs_last_locked_read=order(bound, locked),
                                 recorder_vs_first_unlocked_read=order(bound, negative),
                                 display_or_source_image_order="INCONCLUSIVE")
    return observed


def analyze(output, trial, identity, draws):
    clip = output / "unlock.mp4"
    probe, pts, extent = probe_video(clip)
    (output / "video-ffprobe.json").write_bytes(probe)
    if extent != tuple(trial["extent"]):
        raise MetadataError(f"encoded {extent} differs from original display {trial['extent']}")
    positive = Image.open(output / "painted-main.png").convert("RGB")
    reference = Image.open(output / "neutral-before.png").convert("RGB")
    witness = PixelWitness(positive, reference, tuple(trial["bounds"]))
    pixels = []
    edges = {}
    for i, image in enumerate(frame_stream(clip, *extent)):
        pixel = witness.classify(image)
        pixels.append(pixel)
        if pixel.phase in (1, 2):
            edges.setdefault(pixel.phase, i)
    if len(pixels) != len(pts):
        raise MetadataError(f"decoded and probed frame counts differ {len(pixels)}/{len(pts)}")
    metadata = None
    parse_error = None
    try:
        metadata = from_file(clip, pts)
    except MetadataError as error:
        parse_error = str(error)
    errors, delays = clock_check(metadata, draws, edges, trial["recording_bracket_ns"],
                                 trial["display"], extent)
    if parse_error:
        errors.append(parse_error)
    valid = metadata is not None and not errors
    limit = edges.get(2, len(pts))
    start = edges.get(1, 0)
    elapsed = metadata.elapsed_ns if metadata else (None,) * len(pts)
    legacy = metadata.legacy_us if metadata else (None,) * len(pts)
    frames = [Frame(i, elapsed[i] if valid else pts[i], pixels[i].scene, pixels[i].orb, trial["display"])
              for i in range(start, limit)]
    result = classify(frames, action="unlock", action_bracket=trial.get("action_bracket_ns"),
                      locked_before=tuple(trial.get("state_before", ())) == ("ON", "true", "true"),
                      destination_witnessed=trial.get("destination_witnessed", False),
                      display=trial["display"], owner=identity.get("owner"),
                      clock_valid=valid, uncertainty_ns=ABSOLUTE_CLOCK_GUARD_NS)
    gaps = [b - a for a, b in zip(pts, pts[1:])]
    transition_indices = [f.index for f in frames if result.get("last_main") is not None
                          and result["last_main"]["index"] <= f.index
                          <= (result.get("first_subsequent_absent") or result.get("first_definite_restricted")
                              or {"index": limit - 1})["index"]]
    ledger = {
        "output": "AVD_MIRRORED_SCREENRECORD",
        "source_image_age_bound_ns": None,
        "display_present_mapping": "UNOBSERVED",
        "pts_count": len(pts),
        "extent": extent,
        "absolute_recorder_clock": valid,
        "absolute_recorder_uncertainty_guard_ns": ABSOLUTE_CLOCK_GUARD_NS if valid else None,
        "metadata": ({"sample_locations": metadata.locations, "max_relative_pts_error_ns": metadata.max_pts_error_ns,
                      "legacy_agreement_ns": metadata.max_legacy_error_ns,
                      "realtime_offset_ns": metadata.realtime_offset_ns} if metadata else None),
        "clock_errors": errors,
        "calibration_draws": draws,
        "calibration_encoded_first": edges,
        "draw_to_first_encoded_color_ns": delays,
        "median_pts_gap_ns": statistics.median(gaps),
        "max_pts_gap_ns": max(gaps),
        "transition_max_pts_gap_ns": max((gaps[i] for i in transition_indices[:-1]), default=None),
        "gaps_above_50ms": [(i, gap) for i, gap in enumerate(gaps) if gap > 50 * MS],
        "timing_clock": "RECORDER_ELAPSED" if valid else "RELATIVE_PTS",
        "verdict": result,
    }
    ledger["orders"] = capture_points(ledger, result, identity)
    report = output / "frame-report.json"
    report.write_text(json.dumps(ledger, indent=2) + "\n")
    with (output / "frames.csv").open("w") as csv_file:
        fields = ["index", "pts_ns", "recorder_elapsed_ns", "legacy_elapsed_us", "display",
                  "present_identity", "source_age_ns", "scene", "orb", "phase",
                  "clock_mae", "quadrant_match", "corner_leak", "absent_fraction"]
        writer = csv.DictWriter(csv_file, fields)
        writer.writeheader()
        for i, pixel in enumerate(pixels):
            writer.writerow(dict(index=i, pts_ns=pts[i], recorder_elapsed_ns=elapsed[i],
                                 legacy_elapsed_us=legacy[i], display=trial["display"], **asdict(pixel)))
    candidates = set(edges.values())
    for key in ("last_main", "first_definite_restricted", "last_orb", "first_subsequent_absent",
                "first_sustained_sampled_absent", "forbidden_positive"):
        item = result.get(key)
        if item:
            candidates.update(range(max(0, item["index"] - 2), min(len(pts), item["index"] + 3)))
    for i, frame in enumerate(frame_stream(clip, *extent)):
        if i in candidates:
            frame.save(output / f"decoded-frame-{i:05d}.png")
    return ledger

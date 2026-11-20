#!/usr/bin/env python3
"""Conservative host primitives for independently recorded R15 frames.

These functions do not decide whether an Android case passed. They reject
unusable metadata, clock and calibration inputs; actual device provenance and
the service/scene transition must be checked by the case collector separately.
"""
from __future__ import annotations

import hashlib
import math
import re
import struct
import uuid
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageStat

MAGIC = b"#VV1NSC0PET1ME2#"


def winscope_v2(data: bytes, presentation_ns: list[int], tolerance_ns: int = 2_000_000) -> tuple[int, list[int]]:
    """Parse Android 15's one-sample data track and verify its frame mapping.

    The offset and timestamps are observations made by screenrecord.  The
    media sample's own write time is deliberately not used as a frame time.
    """
    if len(data) < 32 or data[:16] != MAGIC:
        raise ValueError("winscope_magic_or_length")
    version, offset, count = struct.unpack_from("<IqI", data, 16)
    if version != 2 or count == 0 or len(data) != 32 + 8 * count:
        raise ValueError("winscope_version_count_or_length")
    if count != len(presentation_ns):
        raise ValueError("frame_count_mismatch")
    elapsed = list(struct.unpack_from(f"<{count}Q", data, 32))
    if any(b <= a for a, b in zip(elapsed, elapsed[1:])):
        raise ValueError("elapsed_frame_order")
    if any(not isinstance(v, int) for v in presentation_ns) or any(
            b <= a for a, b in zip(presentation_ns, presentation_ns[1:])):
        raise ValueError("presentation_frame_order")
    if any(abs((e - elapsed[0]) - (p - presentation_ns[0])) > tolerance_ns
           for e, p in zip(elapsed, presentation_ns)):
        raise ValueError("frame_clock_mapping_mismatch")
    return offset, elapsed


def awake_offset(snapshots: Iterable[tuple[int, int]], tolerance_ns: int = 2_000_000) -> tuple[int, int]:
    """Return bounded elapsed-minus-uptime only over a verified awake segment."""
    pairs = list(snapshots)
    if len(pairs) < 2 or any(u < 0 or e < u for u, e in pairs):
        raise ValueError("clock_snapshot_missing")
    if any(ub <= ua or eb <= ea for (ua, ea), (ub, eb) in zip(pairs, pairs[1:])):
        raise ValueError("clock_snapshot_order")
    offsets = [e - u for u, e in pairs]
    if max(offsets) - min(offsets) > tolerance_ns:
        raise ValueError("suspend_or_unknown_clock_offset")
    return min(offsets), max(offsets)


def encoded_roi(roi: tuple[int, int, int, int], logical: tuple[int, int],
                encoded: tuple[int, int], rotation: int) -> tuple[int, int, int, int]:
    """Map the actual logical display rectangle into unrotated encoded pixels."""
    width, height = logical
    out_width, out_height = encoded
    left, top, right, bottom = roi
    if rotation != 0:
        raise ValueError("rotation_not_calibrated")
    if min(width, height, out_width, out_height) <= 0 or not (0 <= left < right <= width and 0 <= top < bottom <= height):
        raise ValueError("invalid_display_or_roi")
    return (math.floor(left * out_width / width), math.floor(top * out_height / height),
            math.ceil(right * out_width / width), math.ceil(bottom * out_height / height))


def validate_frame_records(records: list[dict], expected: dict, presentation_ns: list[int], root: Path) -> None:
    """Check decoded-frame identity; extraction from the MP4 is a separate gate."""
    try:
        if (not re.fullmatch(r"[0-9a-f]{40}", expected.get("source", ""))
                or not re.fullmatch(r"[0-9a-f]{64}", expected.get("video_sha256", ""))
                or str(uuid.UUID(expected.get("capture", ""))) != expected.get("capture")
                or expected.get("display") != 0
                or not all(isinstance(expected.get(k), int) and expected[k] > 0 for k in ("window_id", "attachment", "generation"))
                or not isinstance(expected.get("roi"), list) or len(expected["roi"]) != 4
                or not isinstance(expected.get("size"), list) or len(expected["size"]) != 2):
            raise ValueError("expected_frame_owner_missing")
        left, top, right, bottom = expected["roi"]
        width, height = expected["size"]
        if not all(isinstance(value, int) for value in (left, top, right, bottom, width, height)) or not (
                0 <= left < right <= width and 0 <= top < bottom <= height):
            raise ValueError("expected_frame_geometry_invalid")
    except (TypeError, AttributeError) as exc:
        raise ValueError("expected_frame_owner_missing") from exc
    if not records or len(records) != len(presentation_ns):
        raise ValueError("frame_records_missing")
    base = root.resolve()
    seen_paths = set()
    for index, (record, stamp) in enumerate(zip(records, presentation_ns)):
        if not isinstance(record, dict) or record.get("index") != index or record.get("presentation_ns") != stamp:
            raise ValueError("frame_order_or_timestamp_mismatch")
        if any(record.get(key) != expected.get(key) for key in
               ("source", "capture", "video_sha256", "display", "window_id", "attachment", "generation", "roi", "size")):
            raise ValueError("frame_owner_or_geometry_mismatch")
        name = record.get("path")
        if not isinstance(name, str) or not name:
            raise ValueError("frame_path_missing")
        path = (base / name).resolve()
        if not path.is_relative_to(base) or not path.is_file() or path in seen_paths:
            raise ValueError("frame_path_reused_or_external")
        seen_paths.add(path)
        if hashlib.sha256(path.read_bytes()).hexdigest() != record.get("sha256"):
            raise ValueError("frame_hash_mismatch")
        try:
            with Image.open(path) as image:
                image.load()
                if image.format != "PNG" or list(image.size) != expected.get("size"):
                    raise ValueError("frame_format_or_size")
        except OSError as exc:
            raise ValueError("corrupt_frame") from exc
    if any(b <= a for a, b in zip(presentation_ns, presentation_ns[1:])):
        raise ValueError("frame_timestamps_not_in_presentation_order")


def _difference(a: Image.Image, b: Image.Image, mask: Image.Image) -> float:
    difference = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
    return sum(ImageStat.Stat(difference, mask).mean) / 3.0


def _outlier_fraction(a: Image.Image, b: Image.Image, mask: Image.Image, threshold: float) -> float:
    left, right, included = a.convert("RGB").tobytes(), b.convert("RGB").tobytes(), mask.tobytes()
    total = bad = 0
    for index, enabled in enumerate(included):
        if enabled:
            total += 1
            start = index * 3
            bad += max(abs(left[start + channel] - right[start + channel]) for channel in range(3)) > threshold
    return bad / total if total else 1.0


def _masks(size: tuple[int, int]) -> tuple[Image.Image, Image.Image, Image.Image]:
    width, height = size
    if width != height or width < 16:
        raise ValueError("uncalibrated_orb_geometry")
    masks = [Image.new("L", size, 0) for _ in range(3)]
    pixels = [mask.load() for mask in masks]
    centre = (width - 1) / 2
    for y in range(height):
        for x in range(width):
            radius = math.hypot(x - centre, y - centre) / width
            if radius <= 0.40:
                pixels[0][x, y] = 255
            elif 0.43 <= radius <= 0.48:
                pixels[1][x, y] = 255
            elif radius >= 0.53:
                pixels[2][x, y] = 255
    if any(not mask.getbbox() for mask in masks):
        raise ValueError("insufficient_mask_area")
    return tuple(masks)


def _load(path: Path, roi: tuple[int, int, int, int]) -> Image.Image:
    with Image.open(path) as image:
        image.load()
        if image.format != "PNG" or image.width < roi[2] or image.height < roi[3]:
            raise ValueError("invalid_or_mismatched_frame")
        return image.crop(roi).convert("RGB")


def calibrate(training: dict[str, list[Path]], heldout: dict[str, list[Path]],
              roi: tuple[int, int, int, int], canonical_full: Path,
              observed_bounds: tuple[int, int, int, int], codec_tolerance: float = 8.0) -> dict:
    """Train on independent frames and reject overlapping or blank references.

    The caller must independently establish each reference's scene and owner;
    filenames, callbacks and this classifier alone never establish them.
    """
    if roi != observed_bounds:
        raise ValueError("roi_does_not_match_independent_bounds")
    classes = ("FULL", "DISCREET", "BACKGROUND")
    if set(training) != set(classes) or set(heldout) != set(classes):
        raise ValueError("reference_classes_missing")
    all_paths = [p.resolve() for group in (training, heldout) for values in group.values() for p in values]
    if len(set(all_paths)) != len(all_paths) or any(len(training[c]) < 2 or len(heldout[c]) < 1 for c in classes):
        raise ValueError("reference_samples_not_disjoint")
    reference_paths = all_paths + [canonical_full.resolve()]
    reference_hashes = [hashlib.sha256(path.read_bytes()).digest() for path in reference_paths]
    if len(set(reference_paths)) != len(reference_paths) or len(set(reference_hashes)) != len(reference_hashes):
        raise ValueError("copied_reference_frame")
    samples = {c: [_load(p, roi) for p in training[c]] for c in classes}
    checks = {c: [_load(p, roi) for p in heldout[c]] for c in classes}
    canonical = _load(canonical_full, roi)
    masks = _masks(canonical.size)
    # Require a recognisable interior/contour and background separation.
    background = samples["BACKGROUND"][0]
    full = samples["FULL"][0]
    if sum(ImageStat.Stat(background, masks[0]).mean) / 3 <= 5:
        raise ValueError("background_black_or_redacted")
    if (_difference(full, background, masks[0]) <= codec_tolerance * 2
            or _difference(full, background, masks[1]) <= codec_tolerance
            or _difference(full, background, masks[2]) > codec_tolerance * 2):
        raise ValueError("full_reference_not_independently_distinct")
    if _difference(full, canonical, masks[0]) > codec_tolerance * 2:
        raise ValueError("canonical_full_mismatch")
    for a in classes:
        for b in classes:
            if a < b and _difference(samples[a][0], samples[b][0], masks[0]) <= codec_tolerance * 2:
                raise ValueError("class_references_overlap")
    calibration = {"samples": samples, "masks": masks, "tolerance": codec_tolerance}
    for label in classes:
        for image in checks[label]:
            if classify(image, calibration) != label:
                raise ValueError("heldout_classification_failed")
    return calibration


def classify(image: Image.Image, calibration: dict) -> str:
    matches = []
    tolerance = calibration["tolerance"]
    for label, references in calibration["samples"].items():
        if not references or image.size != references[0].size:
            return "UNKNOWN"
        if any(all(_difference(image, reference, mask) <= tolerance
                       and _outlier_fraction(image, reference, mask, max(24, tolerance * 3)) <= 0.01
                       for mask in calibration["masks"])
               for reference in references):
            matches.append(label)
    return matches[0] if len(matches) == 1 else "UNKNOWN"


def first_persistent_transition(times_ns: list[int], labels: list[str],
                                previous: str, current: str) -> tuple[int, int] | None:
    """Return sampled bounds only for an adjacent, independently classified edge."""
    if len(times_ns) != len(labels) or any(b <= a for a, b in zip(times_ns, times_ns[1:])):
        raise ValueError("transition_frame_order_or_count")
    if previous == current or "UNKNOWN" in (previous, current):
        raise ValueError("transition_class_invalid")
    for index in range(1, len(labels) - 1):
        if labels[index - 1] == previous and labels[index:index + 2] == [current, current]:
            return times_ns[index - 1], times_ns[index]
    return None


def motion_observed(images: list[Image.Image], noise: float) -> bool:
    if len(images) < 3 or any(image.size != images[0].size for image in images):
        raise ValueError("motion_sample_missing")
    inside, _, _ = _masks(images[0].size)
    return sum(_difference(a, b, inside) > noise for a, b in zip(images, images[1:])) >= 2

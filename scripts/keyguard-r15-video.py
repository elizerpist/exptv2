#!/usr/bin/env python3
"""Archive and decode one independent screenrecord without frame resampling.

This checks MP4/frame-clock integrity only. Scene calibration, owner binding,
privacy and system transition identification remain separate required gates.
"""
from __future__ import annotations

import argparse
import decimal
import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("r15visual", Path(__file__).with_name("keyguard-r15-visual.py"))
visual = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(visual)


def run(command: list[str], stdout: Path, stderr: Path) -> None:
    with stdout.open("wb") as out, stderr.open("wb") as err:
        completed = subprocess.run(command, stdout=out, stderr=err, check=False)
    if completed.returncode:
        raise ValueError(f"command_failed:{Path(command[0]).name}:{completed.returncode}")


def frame_timestamps(frame_document: dict) -> list[int]:
    frames = frame_document.get("frames")
    if not isinstance(frames, list) or not frames:
        raise ValueError("decoded_video_frames_missing")
    try:
        result = [int(decimal.Decimal(frame["best_effort_timestamp_time"]) * 1_000_000_000) for frame in frames]
    except (KeyError, TypeError, ValueError, decimal.InvalidOperation) as exc:
        raise ValueError("decoded_video_timestamps_missing") from exc
    if any(b <= a for a, b in zip(result, result[1:])):
        raise ValueError("decoded_video_timestamps_not_in_presentation_order")
    return result


def metadata_track(payloads: list[bytes], timestamps: list[int]) -> tuple[int, int, list[int]]:
    candidates = [(index, data) for index, data in enumerate(payloads) if data.startswith(visual.MAGIC)]
    if len(candidates) != 1:
        raise ValueError("winscope_v2_track_missing_or_ambiguous")
    index, data = candidates[0]
    offset, elapsed = visual.winscope_v2(data, timestamps)
    return index, offset, elapsed


def decode(video: Path, output: Path, roi: tuple[int, int, int, int] | None) -> dict:
    if not video.is_file() or video.stat().st_size == 0:
        raise ValueError("video_missing")
    output.mkdir(parents=True, exist_ok=False)
    digest = hashlib.sha256()
    with video.open("rb") as incoming:
        for block in iter(lambda: incoming.read(1024 * 1024), b""):
            digest.update(block)
    info = {"video": str(video.resolve()), "video_sha256": digest.hexdigest(),
            "video_bytes": video.stat().st_size, "visual_qualification": "NOT_ESTABLISHED"}
    try:
        probe = output / "ffprobe.json"
        run(["ffprobe", "-v", "error", "-show_streams", "-show_packets", "-of", "json", str(video)],
            probe, output / "ffprobe.stderr")
        streams = json.loads(probe.read_text()).get("streams", [])
        video_streams = [stream for stream in streams if stream.get("codec_type") == "video"]
        data_streams = [stream for stream in streams if stream.get("codec_type") == "data"]
        if len(video_streams) != 1 or not data_streams:
            raise ValueError("video_or_data_stream_missing")
        frame_probe = output / "ffprobe-frames.json"
        run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_frames", "-of", "json", str(video)],
            frame_probe, output / "ffprobe-frames.stderr")
        timestamps = frame_timestamps(json.loads(frame_probe.read_text()))
        payloads = []
        for stream in data_streams:
            index = int(stream["index"])
            target = output / f"data-stream-{index}.bin"
            run(["ffmpeg", "-v", "error", "-i", str(video), "-map", f"0:{index}", "-c", "copy",
                 "-f", "data", str(target)], output / f"data-stream-{index}.stdout", output / f"data-stream-{index}.stderr")
            payloads.append(target.read_bytes())
        selected, offset, elapsed = metadata_track(payloads, timestamps)
        frames = output / "frames"
        frames.mkdir()
        run(["ffmpeg", "-v", "error", "-i", str(video), "-map", "0:v:0", "-fps_mode", "passthrough",
             "-start_number", "0", str(frames / "%08d.png")], output / "frames.stdout", output / "frames.stderr")
        paths = sorted(frames.glob("*.png"))
        if len(paths) != len(timestamps):
            raise ValueError("extracted_frame_count_mismatch")
        width, height = int(video_streams[0]["width"]), int(video_streams[0]["height"])
        if roi is not None and not (0 <= roi[0] < roi[2] <= width and 0 <= roi[1] < roi[3] <= height):
            raise ValueError("crop_outside_video")
        crop_dir = output / "crops"
        if roi is not None:
            crop_dir.mkdir()
        with (output / "frame-index.jsonl").open("w", encoding="utf-8") as index_file:
            for index, (path, pts, time) in enumerate(zip(paths, timestamps, elapsed)):
                with Image.open(path) as image:
                    image.load()
                    if image.size != (width, height):
                        raise ValueError("frame_geometry_changed")
                    row = {"index": index, "presentation_ns": pts, "elapsed_ns": time,
                           "path": str(path.relative_to(output)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                    if roi is not None:
                        crop_path = crop_dir / path.name
                        image.crop(roi).save(crop_path)
                        row.update(crop=str(crop_path.relative_to(output)), crop_sha256=hashlib.sha256(crop_path.read_bytes()).hexdigest())
                    index_file.write(json.dumps(row, sort_keys=True) + "\n")
        gaps = [b - a for a, b in zip(elapsed, elapsed[1:])]
        info.update(frame_count=len(paths), encoded_size=[width, height], selected_data_stream=int(data_streams[selected]["index"]),
                    real_minus_elapsed_offset_ns=offset, first_elapsed_ns=elapsed[0], last_elapsed_ns=elapsed[-1],
                    gaps_ns=gaps, roi=list(roi) if roi is not None else None, timestamp_mapping="VALIDATED")
        return info
    except Exception as exc:
        info.update(timestamp_mapping="NOT_ESTABLISHED", failure=f"{type(exc).__name__}:{exc}")
        raise
    finally:
        (output / "decode-summary.json").write_text(json.dumps(info, indent=2, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--roi", help="encoded left,top,right,bottom; must be derived from independently recorded bounds")
    args = parser.parse_args()
    try:
        roi = tuple(map(int, args.roi.split(","))) if args.roi else None
        if roi is not None and len(roi) != 4:
            raise ValueError("roi_invalid")
        result = decode(args.video, args.out, roi)
        print(json.dumps(result, sort_keys=True))
        return 0
    except (ValueError, OSError, KeyError, json.JSONDecodeError) as exc:
        print(f"VIDEO_NOT_ESTABLISHED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

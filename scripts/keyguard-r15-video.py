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


def metadata_track(payloads: list[bytes], timestamps: list[int], video: Path | None = None,
                   stream_indexes: list[int] | None = None) -> tuple[int, int, list[int]]:
    candidates = [(index, data) for index, data in enumerate(payloads) if data.startswith(visual.MAGIC)]
    if len(candidates) > 1:
        raise ValueError("winscope_v2_track_missing_or_ambiguous")
    if candidates:
        index, data = candidates[0]
    elif video is not None:
        # Android's real metadata sample can exist in a valid `mett` track
        # even when the installed ffmpeg exposes zero data packets. Follow the
        # verified ISO-BMFF sample tables; never scan for a magic substring.
        spec = importlib.util.spec_from_file_location("r16bmff", Path(__file__).with_name("keyguard-r16-bmff.py"))
        reader = importlib.util.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(reader)
        index, sample = reader.choose_v2(video.read_bytes())
        if index >= len(payloads) or payloads[index] and payloads[index] != sample["payload"]:
            raise ValueError("ffmpeg_and_sample_table_disagree")
        if stream_indexes is not None and (index >= len(stream_indexes) or stream_indexes[index] != sample["track_index"]):
            raise ValueError("ffprobe_track_order_disagrees_with_sample_table")
        data = sample["payload"]
    else:
        raise ValueError("winscope_v2_track_missing_or_ambiguous")
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
        selected, offset, elapsed = metadata_track(payloads, timestamps, video, [int(s["index"]) for s in data_streams])
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


def decode_streamed(video: Path, output: Path, roi: tuple[int, int, int, int] | None, selected_frames: set[int]) -> dict:
    """Keep every native crop/hash and selected lossless full frames, not a PNG sequence."""
    if not video.is_file() or video.stat().st_size == 0:
        raise ValueError("video_missing")
    output.mkdir(parents=True, exist_ok=False)
    info = {"video_sha256": hashlib.sha256(video.read_bytes()).hexdigest(),
            "video_bytes": video.stat().st_size, "visual_qualification": "NOT_ESTABLISHED"}
    try:
        probe = output / "ffprobe.json"
        run(["ffprobe", "-v", "error", "-show_streams", "-show_packets", "-of", "json", str(video)],
            probe, output / "ffprobe.stderr")
        streams = json.loads(probe.read_text()).get("streams", [])
        videos = [s for s in streams if s.get("codec_type") == "video"]
        data_streams = [s for s in streams if s.get("codec_type") == "data"]
        if len(videos) != 1 or not data_streams:
            raise ValueError("video_or_data_stream_missing")
        width, height = int(videos[0]["width"]), int(videos[0]["height"])
        if roi is not None and not (0 <= roi[0] < roi[2] <= width and 0 <= roi[1] < roi[3] <= height):
            raise ValueError("crop_outside_video")
        run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_frames", "-of", "json", str(video)],
            output / "ffprobe-frames.json", output / "ffprobe-frames.stderr")
        timestamps = frame_timestamps(json.loads((output / "ffprobe-frames.json").read_text()))
        payloads = []
        for stream in data_streams:
            index = int(stream["index"]); target = output / f"data-stream-{index}.bin"
            run(["ffmpeg", "-v", "error", "-i", str(video), "-map", f"0:{index}", "-c", "copy", "-f", "data", str(target)],
                output / f"data-stream-{index}.stdout", output / f"data-stream-{index}.stderr")
            payloads.append(target.read_bytes())
        chosen, offset, elapsed = metadata_track(payloads, timestamps, video, [int(s["index"]) for s in data_streams])
        if any(i < 0 or i >= len(timestamps) for i in selected_frames):
            raise ValueError("selected_frame_out_of_range")
        crops = output / "crops"
        if roi is not None: crops.mkdir()
        selected_dir = output / "selected"; selected_dir.mkdir()
        frame_bytes = width * height * 3
        with (output / "frames.stderr").open("wb") as error, (output / "frame-index.jsonl").open("w") as index_file:
            process = subprocess.Popen(["ffmpeg", "-v", "error", "-i", str(video), "-map", "0:v:0",
                "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "pipe:1"],
                stdout=subprocess.PIPE, stderr=error)
            try:
                for index, (pts, at) in enumerate(zip(timestamps, elapsed)):
                    chunks = bytearray()
                    while len(chunks) < frame_bytes:
                        part = process.stdout.read(frame_bytes - len(chunks))
                        if not part: raise ValueError("extracted_frame_count_mismatch")
                        chunks.extend(part)
                    image = Image.frombytes("RGB", (width, height), bytes(chunks))
                    row = {"index": index, "presentation_ns": pts, "elapsed_ns": at,
                           "native_rgb_sha256": hashlib.sha256(chunks).hexdigest()}
                    if roi is not None:
                        crop = crops / f"{index:08d}.png"
                        image.crop(roi).save(crop)
                        row.update(crop=str(crop.relative_to(output)), crop_sha256=hashlib.sha256(crop.read_bytes()).hexdigest())
                    if index in selected_frames:
                        full = selected_dir / f"{index:08d}.png"; image.save(full)
                        row.update(selected=str(full.relative_to(output)), selected_sha256=hashlib.sha256(full.read_bytes()).hexdigest())
                    index_file.write(json.dumps(row, sort_keys=True) + "\n")
                if process.stdout.read(1): raise ValueError("extracted_frame_count_mismatch")
                if process.wait() != 0: raise ValueError("ffmpeg_decode_failed")
            finally:
                if process.poll() is None:
                    process.kill(); process.wait()
        gaps = [b - a for a, b in zip(elapsed, elapsed[1:])]
        info.update(frame_count=len(timestamps), encoded_size=[width, height], roi=list(roi) if roi is not None else None,
                    selected_data_stream=int(data_streams[chosen]["index"]), real_minus_elapsed_offset_ns=offset,
                    first_elapsed_ns=elapsed[0], last_elapsed_ns=elapsed[-1], gaps_ns=gaps,
                    selected_frames=sorted(selected_frames), timestamp_mapping="VALIDATED",
                    frame_hash_meaning="decoded_rgb24_not_physical_presentation")
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
    parser.add_argument("--stream", action="store_true", help="stream native frames; save all crops and only selected full frames")
    parser.add_argument("--selected", default="", help="comma-separated native frame indices to retain in full")
    args = parser.parse_args()
    try:
        roi = tuple(map(int, args.roi.split(","))) if args.roi else None
        if roi is not None and len(roi) != 4:
            raise ValueError("roi_invalid")
        selected = {int(value) for value in args.selected.split(",") if value}
        result = decode_streamed(args.video, args.out, roi, selected) if args.stream else decode(args.video, args.out, roi)
        print(json.dumps(result, sort_keys=True))
        return 0
    except (ValueError, OSError, KeyError, json.JSONDecodeError) as exc:
        print(f"VIDEO_NOT_ESTABLISHED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

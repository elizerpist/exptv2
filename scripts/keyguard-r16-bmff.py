#!/usr/bin/env python3
"""Read actual one-sample MP4 metadata tracks using ISO-BMFF sample tables.

Some ffmpeg versions report Android screenrecord's `mett` tracks but expose no
data packets. This strict fallback uses their stsc/stsz/chunk-offset tables,
not a search for a magic string anywhere in the file. Unknown or fragmented
layouts are rejected. It makes no scene, privacy, or physical-display claim.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import struct
import sys
from pathlib import Path

MAGIC = b"#VV1NSC0PET1ME2#"


def boxes(data: bytes, start: int, end: int) -> list[tuple[bytes, int, int]]:
    found = []
    position = start
    while position < end:
        if position + 8 > end:
            raise ValueError("box_header_truncated")
        size, kind = struct.unpack_from(">I4s", data, position)
        header = 8
        if size == 1:
            if position + 16 > end:
                raise ValueError("extended_box_header_truncated")
            size, header = struct.unpack_from(">Q", data, position + 8)[0], 16
        elif size == 0:
            size = end - position
        if size < header or position + size > end:
            raise ValueError("box_size_invalid")
        found.append((kind, position + header, position + size))
        position += size
    return found


def only(entries: list[tuple[bytes, int, int]], name: bytes) -> tuple[bytes, int, int]:
    selected = [entry for entry in entries if entry[0] == name]
    if len(selected) != 1:
        raise ValueError("missing_or_duplicate_box:" + name.decode("ascii", "replace"))
    return selected[0]


def u32(data: bytes, pos: int, end: int) -> int:
    if pos + 4 > end:
        raise ValueError("truncated_u32")
    return struct.unpack_from(">I", data, pos)[0]


def metadata_samples(data: bytes) -> list[dict]:
    top = boxes(data, 0, len(data))
    moov = only(top, b"moov")
    media_ranges = [(start, end) for kind, start, end in top if kind == b"mdat"]
    if not media_ranges:
        raise ValueError("mdat_missing")
    result = []
    for track_index, track in enumerate(item for item in boxes(data, moov[1], moov[2]) if item[0] == b"trak"):
        mdia = only(boxes(data, track[1], track[2]), b"mdia")
        children = boxes(data, mdia[1], mdia[2])
        hdlr = only(children, b"hdlr")
        if hdlr[1] + 12 > hdlr[2]:
            raise ValueError("handler_truncated")
        if data[hdlr[1] + 8:hdlr[1] + 12] != b"meta":
            continue
        minf = only(children, b"minf")
        stbl = only(boxes(data, minf[1], minf[2]), b"stbl")
        entries = boxes(data, stbl[1], stbl[2])
        stsd, stsz, stsc = (only(entries, name) for name in (b"stsd", b"stsz", b"stsc"))
        if u32(data, stsd[1] + 4, stsd[2]) != 1:
            raise ValueError("metadata_sample_description_count")
        descriptions = boxes(data, stsd[1] + 8, stsd[2])
        if len(descriptions) != 1 or descriptions[0][0] != b"mett":
            raise ValueError("metadata_sample_description_not_mett")
        default_size = u32(data, stsz[1] + 4, stsz[2])
        if u32(data, stsz[1] + 8, stsz[2]) != 1:
            raise ValueError("metadata_sample_count_not_one")
        sample_size = default_size or u32(data, stsz[1] + 12, stsz[2])
        if u32(data, stsc[1] + 4, stsc[2]) != 1 or tuple(u32(data, stsc[1] + offset, stsc[2]) for offset in (8, 12, 16)) != (1, 1, 1):
            raise ValueError("metadata_chunk_mapping_unsupported")
        offsets = [entry for entry in entries if entry[0] in (b"stco", b"co64")]
        if len(offsets) != 1 or u32(data, offsets[0][1] + 4, offsets[0][2]) != 1:
            raise ValueError("metadata_chunk_offset_count")
        kind, begin, end = offsets[0]
        if kind == b"co64":
            if begin + 16 > end:
                raise ValueError("truncated_chunk_offset")
            offset = struct.unpack_from(">Q", data, begin + 8)[0]
        else:
            offset = u32(data, begin + 8, end)
        if sample_size <= 0 or sum(start <= offset and offset + sample_size <= end for start, end in media_ranges) != 1:
            raise ValueError("metadata_sample_outside_mdat")
        payload = data[offset:offset + sample_size]
        result.append(dict(track_index=track_index, offset=offset, size=sample_size,
                           sha256=hashlib.sha256(payload).hexdigest(), payload=payload))
    ranges = sorted((item["offset"], item["offset"] + item["size"]) for item in result)
    if any(a[1] > b[0] for a, b in zip(ranges, ranges[1:])):
        raise ValueError("metadata_samples_overlap")
    return result


def choose_v2(data: bytes) -> tuple[int, dict]:
    samples = metadata_samples(data)
    selected = [(index, sample) for index, sample in enumerate(samples) if sample["payload"].startswith(MAGIC)]
    if len(selected) != 1:
        raise ValueError("winscope_v2_sample_missing_or_ambiguous")
    return selected[0]


def decode(video: Path, output: Path, app_source: Path) -> dict:
    index, sample = choose_v2(video.read_bytes())
    spec = importlib.util.spec_from_file_location("r15_video", app_source / "scripts/keyguard-r15-video.py")
    decoder = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(decoder)
    chosen: dict = {}

    def validated_track(payloads: list[bytes], timestamps: list[int]):
        if index >= len(payloads):
            raise ValueError("metadata_track_count_mismatch")
        exposed = payloads[index]
        if exposed and exposed != sample["payload"]:
            raise ValueError("ffmpeg_and_sample_table_disagree")
        offset, elapsed = decoder.visual.winscope_v2(sample["payload"], timestamps)
        chosen.update(metadata_track_index=sample["track_index"], metadata_data_stream_ordinal=index,
                      metadata_offset=sample["offset"], metadata_size=sample["size"],
                      metadata_sha256=sample["sha256"], ffmpeg_payload_bytes=len(exposed))
        return index, offset, elapsed

    decoder.metadata_track = validated_track
    result = decoder.decode(video, output, None)
    if result["selected_data_stream"] != sample["track_index"]:
        raise ValueError("ffprobe_track_order_disagrees_with_sample_table")
    (output / "sample-table-proof.json").write_text(json.dumps(chosen, indent=2, sort_keys=True) + "\n")
    return result | chosen | {"metadata_extraction": "ISO_BMFF_SAMPLE_TABLE"}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--app-source", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = decode(args.video, args.out, args.app_source)
        print(json.dumps(result, sort_keys=True))
        return 0
    except (OSError, ValueError, struct.error, json.JSONDecodeError) as error:
        print(f"RECORDING_NOT_ESTABLISHED: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

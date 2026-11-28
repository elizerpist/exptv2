"""Read Android screenrecord's two Winscope metadata tracks by MP4 sample location."""

from dataclasses import dataclass
import mmap
from pathlib import Path
import struct

V2_MAGIC = b"#VV1NSC0PET1ME2#"
LEGACY_MAGIC = b"#VV1NSC0PET1ME!#"
MAX_FRAMES = 30_000  # This harness records at most one short, bounded clip.
PTS_TOLERANCE_NS = 10_000
LEGACY_TOLERANCE_NS = 2_000


class MetadataError(ValueError):
    pass


@dataclass(frozen=True)
class Box:
    kind: bytes
    payload: int
    end: int


def boxes(data, start, end):
    while start < end:
        if end - start < 8:
            raise MetadataError("truncated box header")
        size, kind = struct.unpack_from(">I4s", data, start)
        header = 8
        if size == 1:
            if end - start < 16:
                raise MetadataError("truncated extended box header")
            size = struct.unpack_from(">Q", data, start + 8)[0]
            header = 16
        elif size == 0:
            size = end - start
        if size < header or size > end - start:
            raise MetadataError("invalid box extent")
        yield Box(kind, start + header, start + size)
        start += size


def children(data, parent):
    return list(boxes(data, parent.payload, parent.end))


def one(items, kind):
    matching = [box for box in items if box.kind == kind]
    if len(matching) != 1:
        raise MetadataError(f"expected one {kind.decode()} box, found {len(matching)}")
    return matching[0]


def counted_rows(data, box, fmt):
    if box.end - box.payload < 8 or data[box.payload:box.payload + 4] != b"\x00" * 4:
        raise MetadataError(f"invalid {box.kind.decode()} version or header")
    count = struct.unpack_from(">I", data, box.payload + 4)[0]
    first = box.payload + 8
    if first + count * struct.calcsize(fmt) != box.end:
        raise MetadataError(f"truncated or inconsistent {box.kind.decode()} table")
    return struct.iter_unpack(fmt, data[first:box.end])


def metadata_samples(data):
    top = list(boxes(data, 0, len(data)))
    movie = one(top, b"moov")
    media = [box for box in top if box.kind == b"mdat"]
    samples = {}
    for track in children(data, movie):
        if track.kind != b"trak":
            continue
        root = track
        for kind in (b"mdia", b"minf", b"stbl"):
            root = one(children(data, root), kind)
        tables = children(data, root)
        description = one(tables, b"stsd")
        if description.end - description.payload < 8:
            raise MetadataError("truncated stsd")
        entries = list(boxes(data, description.payload + 8, description.end))
        if struct.unpack_from(">I", data, description.payload + 4)[0] != len(entries):
            raise MetadataError("inconsistent stsd entry count")
        if not any(entry.kind == b"mett" for entry in entries):
            continue
        size_box = one(tables, b"stsz")
        if size_box.end - size_box.payload < 12:
            raise MetadataError("truncated stsz")
        flags, fixed_size, count = struct.unpack_from(">III", data, size_box.payload)
        if flags or count != 1 or size_box.end - size_box.payload != (12 if fixed_size else 16):
            raise MetadataError("expected exactly one complete metadata sample")
        size = fixed_size or struct.unpack_from(">I", data, size_box.payload + 12)[0]
        chunk_table = [box for box in tables if box.kind in (b"stco", b"co64")]
        if len(chunk_table) != 1:
            raise MetadataError("missing or ambiguous metadata chunk offsets")
        chunk = chunk_table[0]
        offsets = list(counted_rows(data, chunk, ">I" if chunk.kind == b"stco" else ">Q"))
        mapping = list(counted_rows(data, one(tables, b"stsc"), ">III"))
        if len(offsets) != 1 or len(mapping) != 1 or mapping[0][:2] != (1, 1):
            raise MetadataError("expected one metadata chunk and one sample per chunk")
        entry = mapping[0][2]
        if not 1 <= entry <= len(entries) or entries[entry - 1].kind != b"mett":
            raise MetadataError("metadata sample does not use a mett entry")
        offset = offsets[0][0]
        if not 0 < size <= 32 + 8 * MAX_FRAMES or not any(
            box.payload <= offset < offset + size <= box.end for box in media
        ):
            raise MetadataError("metadata sample is outside mdat or exceeds its bound")
        payload = data[offset:offset + size]
        magic = next((tag for tag in (V2_MAGIC, LEGACY_MAGIC) if payload.startswith(tag)), None)
        if magic is None or magic in samples:
            raise MetadataError("unknown or duplicate Winscope metadata sample")
        samples[magic] = (offset, payload)
    if set(samples) != {V2_MAGIC, LEGACY_MAGIC}:
        raise MetadataError("both Winscope V2 and legacy tracks are required")
    return samples


@dataclass(frozen=True)
class Metadata:
    elapsed_ns: tuple
    legacy_us: tuple
    realtime_offset_ns: int
    locations: dict
    max_pts_error_ns: int
    max_legacy_error_ns: int


def read_metadata(data, pts_ns):
    samples = metadata_samples(data)
    v2_offset, v2 = samples[V2_MAGIC]
    legacy_offset, legacy = samples[LEGACY_MAGIC]
    if len(v2) < len(V2_MAGIC) + 16 or len(legacy) < len(LEGACY_MAGIC) + 4:
        raise MetadataError("truncated Winscope header")
    # The AOSP writer stores a uint32 count, including in V2.
    version, realtime_offset, count = struct.unpack_from("<IqI", v2, len(V2_MAGIC))
    legacy_count = struct.unpack_from("<I", legacy, len(LEGACY_MAGIC))[0]
    v2_start = len(V2_MAGIC) + 16
    legacy_start = len(LEGACY_MAGIC) + 4
    if version != 2:
        raise MetadataError(f"unsupported Winscope version {version}")
    if not 1 < count <= MAX_FRAMES or count != legacy_count or count != len(pts_ns):
        raise MetadataError("metadata and decoded frame counts disagree")
    if len(v2) != v2_start + count * 8 or len(legacy) != legacy_start + count * 8:
        raise MetadataError("truncated or inconsistent Winscope frame array")
    elapsed = tuple(row[0] for row in struct.iter_unpack("<Q", v2[v2_start:]))
    legacy_us = tuple(row[0] for row in struct.iter_unpack("<Q", legacy[legacy_start:]))
    for label, times in (("V2", elapsed), ("legacy", legacy_us), ("decoded PTS", pts_ns)):
        if times[0] < 0 or any(a >= b for a, b in zip(times, times[1:])):
            raise MetadataError(f"nonmonotonic {label} frame order")
    legacy_error = max(abs(a - 1_000 * b) for a, b in zip(elapsed, legacy_us))
    pts_error = max(abs((a - elapsed[0]) - (p - pts_ns[0])) for a, p in zip(elapsed, pts_ns))
    if elapsed[0] == 0 or realtime_offset <= 0 or legacy_error > LEGACY_TOLERANCE_NS:
        raise MetadataError("elapsed units or legacy agreement invalid")
    if pts_error > PTS_TOLERANCE_NS:
        raise MetadataError("relative PTS disagrees with Winscope order")
    locations = {"v2": [v2_offset, len(v2)], "legacy": [legacy_offset, len(legacy)]}
    return Metadata(elapsed, legacy_us, realtime_offset, locations, pts_error, legacy_error)


def from_file(path: Path, pts_ns):
    with path.open("rb") as f:
        if not 0 < path.stat().st_size <= 256 * 1024**2:
            raise MetadataError("empty or oversized clip")
        with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as data:
            return read_metadata(data, pts_ns)

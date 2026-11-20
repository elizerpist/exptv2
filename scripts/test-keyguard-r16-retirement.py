#!/usr/bin/env python3
"""Synthetic MP4 sample-table controls; no device conclusion is implied."""
import struct
import unittest
import tempfile

import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location("reader", Path(__file__).with_name("keyguard-r16-bmff.py"))
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
video_spec = importlib.util.spec_from_file_location("video", Path(__file__).with_name("keyguard-r15-video.py"))
video = importlib.util.module_from_spec(video_spec)
video_spec.loader.exec_module(video)


def box(kind, content):
    return struct.pack(">I4s", len(content) + 8, kind) + content


def u32(*values):
    return struct.pack(">" + "I" * len(values), *values)


def track(offset, size, chunks=(1, 1, 1), *, use_co64=False, count=1):
    hdlr = box(b"hdlr", b"\0" * 8 + b"meta" + b"\0" * 12)
    stsd = box(b"stsd", b"\0" * 4 + u32(1) + box(b"mett", b"application/octet-stream\0"))
    stsz = box(b"stsz", b"\0" * 4 + u32(0, count, size))
    stsc = box(b"stsc", b"\0" * 4 + u32(1, *chunks))
    location = struct.pack(">Q", offset) if use_co64 else u32(offset)
    stco = box(b"co64" if use_co64 else b"stco", b"\0" * 4 + u32(1) + location)
    stbl = box(b"stbl", stsd + stsz + stsc + stco)
    return box(b"trak", box(b"mdia", hdlr + box(b"minf", stbl)))


def sample(payloads, *, bad_chunk=False, duplicate=False, outside=False):
    ftyp = box(b"ftyp", b"isom\0\0\0\0")
    mdat = box(b"mdat", b"".join(payloads))
    offset = len(ftyp) + 8
    tracks = []
    for index, payload in enumerate(payloads):
        position = len(ftyp) + len(mdat) + 100 if outside and index == 0 else offset
        tracks.append(track(position, len(payload), (1, 2, 1) if bad_chunk and index == 0 else (1, 1, 1), use_co64=index % 2 == 1))
        offset += len(payload)
    if duplicate:
        tracks.append(track(len(ftyp) + 8, len(payloads[0])))
    return ftyp + mdat + box(b"moov", b"".join(tracks))


class SampleTableControls(unittest.TestCase):
    def test_real_track_offsets_select_v2_over_legacy(self):
        data = sample([b"legacy-payload", reader.MAGIC + b"payload"])
        ordinal, selected = reader.choose_v2(data)
        self.assertEqual(1, ordinal)
        self.assertEqual(reader.MAGIC + b"payload", selected["payload"])
        self.assertEqual(1, selected["track_index"])

    def test_forged_magic_outside_track_does_not_count(self):
        with self.assertRaisesRegex(ValueError, "missing_or_ambiguous"):
            reader.choose_v2(sample([b"ordinary"]) + box(b"free", reader.MAGIC + b"fake"))

    def test_unknown_chunk_shape_and_outside_mdat_fail(self):
        with self.assertRaisesRegex(ValueError, "chunk_mapping_unsupported"):
            reader.choose_v2(sample([reader.MAGIC], bad_chunk=True))
        with self.assertRaisesRegex(ValueError, "outside_mdat"):
            reader.choose_v2(sample([reader.MAGIC], outside=True))

    def test_overlapping_and_duplicate_metadata_fail(self):
        with self.assertRaisesRegex(ValueError, "overlap"):
            reader.choose_v2(sample([reader.MAGIC], duplicate=True))
        with self.assertRaisesRegex(ValueError, "missing_or_ambiguous"):
            reader.choose_v2(sample([reader.MAGIC + b"a", reader.MAGIC + b"b"]))

    def test_empty_ffmpeg_track_uses_actual_container_table_and_checks_pts(self):
        payload = reader.MAGIC + struct.pack("<IqI", 2, -1234, 2) + struct.pack("<2Q", 1_000_000_000, 1_016_000_000)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "real-table.mp4"
            path.write_bytes(sample([b"legacy", payload]))
            self.assertEqual((1, -1234, [1_000_000_000, 1_016_000_000]),
                             video.metadata_track([b"legacy", b""], [0, 16_000_000], path, [0, 1]))
            with self.assertRaisesRegex(ValueError, "ffmpeg_and_sample_table_disagree"):
                video.metadata_track([b"legacy", b"wrong"], [0, 16_000_000], path, [0, 1])
            with self.assertRaises(ValueError):
                video.metadata_track([b"legacy", b""], [0], path, [0, 1])
            with self.assertRaisesRegex(ValueError, "track_order"):
                video.metadata_track([b"legacy", b""], [0, 16_000_000], path, [1, 0])

    def test_truncated_container_fails(self):
        with self.assertRaises(ValueError):
            reader.choose_v2(sample([reader.MAGIC])[:-1])


if __name__ == "__main__":
    unittest.main(verbosity=2)

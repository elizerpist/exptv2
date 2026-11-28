from dataclasses import replace
import struct
import unittest

from PIL import Image, ImageDraw

from r52_oracle import Frame as OldFrame, classify as old_classify
from r53_mp4 import LEGACY_MAGIC, V2_MAGIC, MetadataError, read_metadata
from r53_oracle import Frame, PresentCoverage, classify, order
from r53_pixels import BACKGROUND, CELL, COLORS, PATTERNS, PixelWitness, reference_phase
from r53_video import clock_check

MS = 1_000_000
OWNER = ("com.fluvi.app", 97, 3, 4, 22)


def sequence():
    return [Frame(i, ms * MS, scene, orb, 0, OWNER, token, 500_000)
            for i, (ms, scene, orb, token) in enumerate([
                (0, "MAIN", True, 150), (16, "REFERENCE", False, 154), (32, "REFERENCE", False, 155)])]


def verdict(frames, **options):
    inputs = dict(action="unlock", action_bracket=(10 * MS, 20 * MS), locked_before=True,
                  destination_witnessed=True, display=0, owner=OWNER, clock_valid=True,
                  uncertainty_ns=MS, proof=PresentCoverage(0, (150, 154, 155), 21 * MS, 2 * MS))
    return classify(frames, **(inputs | options))


class OracleControls(unittest.TestCase):
    def test_adjacent_indices_500ms_gap_reproduces_old_false_pass(self):
        frames = sequence()
        frames[1] = replace(frames[1], time_ns=500 * MS)
        frames[2] = replace(frames[2], time_ns=517 * MS)
        archived = [OldFrame(f.index, f.time_ns, f.orb, "MAIN" if i == 0 else "LAUNCHER")
                    for i, f in enumerate(frames)]
        self.assertEqual("PASS", old_classify(archived, action="unlock", locked_before=True,
                                             action_low=10 * MS, action_high=12 * MS,
                                             alignment_ns=MS, aligned=True)["status"])
        self.assertEqual("INCONCLUSIVE", verdict(frames)["status"])

    def test_proof_passes_clean_and_positive_during_swipe_fails_even_if_sparse(self):
        frames = sequence()
        self.assertEqual("PASS", verdict(frames)["status"])
        frames[1] = replace(frames[1], orb=True)
        frames[2] = replace(frames[2], index=4, time_ns=180 * MS)
        result = verdict(frames, proof=None)
        self.assertEqual("FAIL", result["status"])
        self.assertEqual(1, result["forbidden_positive"]["index"])
        self.assertEqual("INCONCLUSIVE", result["first_display_frame"])

    def test_missing_coverage_duplicate_interpolated_or_unknown_sample_cannot_pass(self):
        clean = sequence()
        variants = (
            clean,
            [clean[0], clean[1], replace(clean[2], index=4)],
            [clean[0], clean[1], replace(clean[2], time_ns=clean[1].time_ns)],
            [clean[0], clean[1], replace(clean[2], present=clean[1].present)],
            [clean[0], clean[1], replace(clean[2], image_age_ns=None)],
            [clean[0], replace(clean[1], scene="UNKNOWN", orb=None), clean[2]],
            [replace(row, owner=None) for row in clean],
            clean[1:],
        )
        self.assertEqual("INCONCLUSIVE", verdict(variants[0], proof=None)["status"])
        for rows in variants[1:]:
            with self.subTest(rows=rows):
                self.assertEqual("INCONCLUSIVE", verdict(rows)["status"])

    def test_invalid_join_wrong_package_display_next_wake_and_other_routes(self):
        for patch in ({"display": 1}, {"owner": ("com.fluvi.other", *OWNER[1:])},
                      {"owner": (OWNER[0], OWNER[1], 4, OWNER[3], OWNER[4])},
                      {"owner": (OWNER[0], OWNER[1], OWNER[2], 9, OWNER[4])}):
            rows = sequence()
            rows[1] = replace(rows[1], **patch)
            self.assertEqual("INCONCLUSIVE", verdict(rows)["status"])
        for route in ("sleep", "shade", "doze"):
            self.assertEqual("INCONCLUSIVE", verdict(sequence(), action=route)["status"])
        self.assertEqual("INCONCLUSIVE", verdict(sequence(), owner=None)["status"])
        self.assertEqual("INCONCLUSIVE", verdict(sequence(), clock_valid=False)["status"])
        self.assertEqual("INCONCLUSIVE", order((7, 20), (10, 25)))
        self.assertEqual("AFTER", order((23, 28), (11, 22)))


def box(kind, payload):
    return struct.pack(">I4s", len(payload) + 8, kind) + payload


def table(kind, row):
    return box(kind, struct.pack(">II", 0, 1) + row)


def track(offset, size, *, wide=False):
    desc = table(b"stsd", box(b"mett", b""))
    sample = table(b"stsc", struct.pack(">III", 1, 1, 1))
    sizes = box(b"stsz", struct.pack(">IIII", 0, 0, 1, size))
    chunks = table(b"co64" if wide else b"stco", struct.pack(">Q" if wide else ">I", offset))
    return box(b"trak", box(b"mdia", box(b"minf", box(b"stbl", desc + sample + sizes + chunks))))


def movie(*, elapsed=(1_000 * MS, 1_016 * MS, 1_032 * MS), version=2, legacy=None, broken=False):
    body = V2_MAGIC + struct.pack("<IqI", version, 1_590_000_000_000_000_000, len(elapsed))
    body += b"".join(struct.pack("<Q", item) for item in elapsed)
    legacy = legacy or [item // 1000 for item in elapsed]
    old = LEGACY_MAGIC + struct.pack("<I", len(legacy)) + b"".join(struct.pack("<Q", us) for us in legacy)
    # The track order is deliberately opposite the sample order.
    metadata = track(8 + len(body), len(old), wide=True) + track(8, len(body) + int(broken))
    return box(b"mdat", body + old) + box(b"moov", metadata)


class MetadataControls(unittest.TestCase):
    def test_mett_tables_extract_legacy_and_v2_by_offset(self):
        metadata = read_metadata(movie(), (0, 16 * MS, 32 * MS))
        self.assertEqual((1000 * MS, 1016 * MS, 1032 * MS), metadata.elapsed_ns)
        self.assertEqual((1_000_000, 1_016_000, 1_032_000), metadata.legacy_us)
        self.assertEqual(8, metadata.locations["v2"][0])
        self.assertEqual(0, metadata.max_pts_error_ns)

    def test_invalid_size_version_count_and_nonmonotonic_metadata(self):
        variants = ((movie()[:-1], (0, 16, 32)),
                    (movie(version=3), (0, 16 * MS, 32 * MS)),
                    (movie(broken=True), (0, 16 * MS, 32 * MS)),
                    (movie(legacy=(101_000, 102_000)), (0, 16 * MS, 32 * MS)),
                    (movie(), (0, 16 * MS)),
                    (movie(elapsed=(1000 * MS, 1016 * MS, 1009 * MS)), (0, 16 * MS, 32 * MS)),
                    (movie(), (0, 16 * MS, 34 * MS)))
        for blob, pts in variants:
            with self.subTest(length=len(blob), pts=pts), self.assertRaises(MetadataError):
                read_metadata(blob, pts)

    def test_clock_checks_preserve_relative_data_on_unknown_absolute_join(self):
        metadata = read_metadata(movie(), (0, 16 * MS, 32 * MS))
        draws = {1: dict(display=0, extent=(1080, 2400), elapsed_ns=999 * MS,
                         up_before_ms=999, up_after_ms=999),
                 2: dict(display=0, extent=(1080, 2400), elapsed_ns=1031 * MS,
                         up_before_ms=1031, up_after_ms=1031)}
        args = ({1: 0, 2: 2}, (980 * MS, 1040 * MS), 0, (1080, 2400))
        self.assertEqual(([], {1: MS, 2: MS}), clock_check(metadata, draws, *args))
        draws[2]["up_before_ms"] -= 80
        draws[2]["up_after_ms"] -= 80
        errors, _ = clock_check(metadata, draws, *args)
        self.assertIn("suspend or elapsed/uptime offset discontinuity", errors)
        self.assertEqual(3, len(metadata.elapsed_ns))
        draws.pop(2)
        errors, _ = clock_check(metadata, draws, *args)
        self.assertTrue(any("missing independent" in e for e in errors))


class PixelControls(unittest.TestCase):
    def test_reference_absence_and_shape_matched_forbidden_positive(self):
        bounds = (410, 1090, 690, 1370)
        extent = (1080, 2400)
        ref = Image.new("RGB", extent, BACKGROUND)
        draw = ImageDraw.Draw(ref)
        for (x, y, pattern), tint in zip(PATTERNS, COLORS[0]):
            for row, line in enumerate(pattern):
                for col, character in enumerate(line):
                    if character == "1":
                        a, b = (x + col * CELL[0]) * extent[0], (y + row * CELL[1]) * extent[1]
                        draw.rectangle((a, b, a + CELL[0] * extent[0], b + CELL[1] * extent[1]), fill=tint)
        main = Image.new("RGB", extent, (33, 39, 47))
        painter = ImageDraw.Draw(main)
        painter.rectangle((390, 490, 670, 760), fill=(240, 240, 240))
        painter.ellipse(bounds, fill=(182, 112, 245))
        witness = PixelWitness(main, ref, bounds)
        positive = ref.copy()
        ImageDraw.Draw(positive).ellipse(bounds, fill=(183, 120, 241))
        self.assertEqual(("REFERENCE", True), (witness.classify(positive).scene, witness.classify(positive).orb))
        self.assertIs(witness.classify(ref).orb, False)
        patch = ref.copy()
        ImageDraw.Draw(patch).rectangle((490, 1130, 525, 1330), fill=(182, 112, 245))
        self.assertIsNone(witness.classify(patch).orb)
        black = Image.new("RGB", extent)
        ImageDraw.Draw(black).rectangle((0, 0, 1080, 25), fill="white")
        self.assertIsNone(witness.classify(black).orb)
        self.assertIsNone(reference_phase(ref, (0, 0, 300, 1200)))

#!/usr/bin/env python3
"""Synthetic host controls only; these files are never device evidence."""
import importlib.util
import hashlib
import struct
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("visual", Path(__file__).with_name("keyguard-r15-visual.py"))
visual = importlib.util.module_from_spec(spec)
spec.loader.exec_module(visual)
video_spec = importlib.util.spec_from_file_location("video", Path(__file__).with_name("keyguard-r15-video.py"))
video = importlib.util.module_from_spec(video_spec)
video_spec.loader.exec_module(video)


def payload(times, offset=-1234, version=2):
    return visual.MAGIC + struct.pack("<IqI", version, offset, len(times)) + struct.pack(f"<{len(times)}Q", *times)


class VisualControls(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.counter = 0

    def tearDown(self):
        self.tmp.cleanup()

    def frame(self, label):
        self.counter += 1
        image = Image.new("RGB", (64, 64), (35, 35, 35))
        if label != "BACKGROUND":
            color = (210, 65, 25) if label == "FULL" else (55, 130, 210)
            ImageDraw.Draw(image).ellipse((2, 2, 61, 61), fill=color)
        image.putpixel((0, 0), (self.counter, 35, 35))
        path = self.root / f"frame-{self.counter}.png"
        image.save(path)
        return path

    def references(self):
        labels = ("FULL", "DISCREET", "BACKGROUND")
        training = {label: [self.frame(label), self.frame(label)] for label in labels}
        heldout = {label: [self.frame(label)] for label in labels}
        return training, heldout, self.frame("FULL")

    def test_winscope_v2_and_mapping(self):
        data = payload([1_000_000_000, 1_016_000_000, 1_033_000_000])
        offset, frames = visual.winscope_v2(data, [0, 16_000_000, 33_000_000])
        self.assertEqual(-1234, offset)
        self.assertEqual(3, len(frames))
        for broken, pts in ((data[:-1], [0, 16_000_000, 33_000_000]),
                            (payload([1, 2], version=1), [0, 1]),
                            (data, [0, 16_000_000]),
                            (payload([1, 1]), [0, 1]),
                            (data, [0, 16_000_000, 16_000_000]),
                            (data, [0, 25_000_000, 33_000_000]),
                            (b"X" + data[1:], [0, 16_000_000, 33_000_000])):
            with self.assertRaises(ValueError):
                visual.winscope_v2(broken, pts)

    def test_video_metadata_selection_requires_one_exact_mapped_track(self):
        pts = video.frame_timestamps({"frames": [{"best_effort_timestamp_time": "0.000"},
                                                  {"best_effort_timestamp_time": "0.016"}]})
        data = payload([1_000_000_000, 1_016_000_000])
        self.assertEqual((1, -1234, [1_000_000_000, 1_016_000_000]), video.metadata_track([b"legacy", data], pts))
        for tracks in ([b"legacy"], [data, data], [data[:-1]], [payload([1_000_000_000])]):
            with self.assertRaises(ValueError):
                video.metadata_track(tracks, pts)
        with self.assertRaises(ValueError):
            video.frame_timestamps({"frames": [{"best_effort_timestamp_time": "0.1"},
                                                {"best_effort_timestamp_time": "0.1"}]})

    def test_awake_clock_and_suspend(self):
        self.assertEqual((5, 6), visual.awake_offset([(100, 105), (200, 206)], 2))
        for samples in ([(100, 105)], [(100, 105), (200, 300)], [(100, 105), (99, 106)]):
            with self.assertRaises(ValueError):
                visual.awake_offset(samples, 2)

    def test_roi_mapping_and_rotation_fail_closed(self):
        self.assertEqual((10, 20, 30, 40), visual.encoded_roi((20, 40, 60, 80), (100, 200), (50, 100), 0))
        for roi, rotation in (((-1, 0, 10, 10), 0), ((0, 0, 100, 201), 0), ((0, 0, 10, 10), 90)):
            with self.assertRaises(ValueError):
                visual.encoded_roi(roi, (100, 200), (50, 100), rotation)

    def test_frame_identity_geometry_corruption_and_order(self):
        import copy
        expected = dict(source="a" * 40, capture=str(uuid.uuid4()), video_sha256="b" * 64,
                        display=0, window_id=123, attachment=1, generation=3, roi=[0, 0, 64, 64], size=[64, 64])
        paths = [self.frame("FULL"), self.frame("FULL")]
        records = [expected | dict(index=i, presentation_ns=(i + 1) * 10, path=p.name,
                    sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for i, p in enumerate(paths)]
        visual.validate_frame_records(records, expected, [10, 20], self.root)
        for mutate in ("generation", "roi", "copied", "order", "corrupt"):
            broken = copy.deepcopy(records)
            if mutate == "generation": broken[1]["generation"] = 4
            if mutate == "roi": broken[1]["roi"] = [0, 0, 32, 32]
            if mutate == "copied": broken[1]["path"] = broken[0]["path"]
            if mutate == "order": broken.reverse()
            if mutate == "corrupt": broken[1]["sha256"] = "0" * 64
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                visual.validate_frame_records(broken, expected, [10, 20], self.root)

    def test_calibration_heldout_and_unknown(self):
        training, heldout, canonical = self.references()
        calibration = visual.calibrate(training, heldout, (0, 0, 64, 64), canonical, (0, 0, 64, 64))
        self.assertEqual("FULL", visual.classify(visual._load(heldout["FULL"][0], (0, 0, 64, 64)), calibration))
        self.assertEqual("UNKNOWN", visual.classify(Image.new("RGB", (64, 64), "black"), calibration))

    def test_wallpaper_copied_reference_and_wrong_roi_do_not_calibrate(self):
        training, heldout, canonical = self.references()
        copied = self.root / "copied.png"
        copied.write_bytes(training["FULL"][0].read_bytes())
        for changed_training, changed_heldout, roi in (
                (training, heldout | {"FULL": [copied]}, (0, 0, 64, 64)),
                (training | {"FULL": training["BACKGROUND"]}, heldout, (0, 0, 64, 64)),
                (training, heldout, (0, 0, 32, 32))):
            with self.assertRaises(ValueError):
                visual.calibrate(changed_training, changed_heldout, roi, canonical, (0, 0, 64, 64))

    def test_static_reference_does_not_prove_motion(self):
        one = Image.new("RGB", (64, 64), (20, 50, 80))
        self.assertFalse(visual.motion_observed([one, one.copy(), one.copy()], 2.0))
        moving = [Image.new("RGB", (64, 64), (v, 50, 80)) for v in (20, 40, 60)]
        self.assertTrue(visual.motion_observed(moving, 2.0))

    def test_black_reference_is_not_a_privacy_baseline(self):
        training, heldout, canonical = self.references()
        for index, path in enumerate(training["BACKGROUND"] + heldout["BACKGROUND"]):
            image = Image.new("RGB", (64, 64), "black")
            image.putpixel((0, 0), (index + 1, 0, 0))
            image.save(path)
        with self.assertRaisesRegex(ValueError, "background_black_or_redacted"):
            visual.calibrate(training, heldout, (0, 0, 64, 64), canonical, (0, 0, 64, 64))

    def test_transition_is_bracketed_and_one_frame_is_not_enough(self):
        stamps = [10, 20, 30, 40]
        self.assertEqual((20, 30), visual.first_persistent_transition(
            stamps, ["BACKGROUND", "BACKGROUND", "FULL", "FULL"], "BACKGROUND", "FULL"))
        self.assertIsNone(visual.first_persistent_transition(
            stamps, ["BACKGROUND", "FULL", "BACKGROUND", "FULL"], "BACKGROUND", "FULL"))
        self.assertIsNone(visual.first_persistent_transition(
            stamps, ["BACKGROUND", "UNKNOWN", "FULL", "FULL"], "BACKGROUND", "FULL"))
        with self.assertRaises(ValueError):
            visual.first_persistent_transition([10, 30, 20], ["BACKGROUND", "FULL", "FULL"], "BACKGROUND", "FULL")


if __name__ == "__main__":
    unittest.main(verbosity=2)

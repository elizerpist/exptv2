"""Image witness for the 56 dp matte, its two live openings and the return activity."""
from pathlib import Path

from PIL import Image
from mask_controls import areas, mae, packet, pixels
from r53_pixels import PixelError, PixelResult, clock_key, different_clock, distance, reference_phase


MASK = Path(__file__).resolve().parents[1] / "r52-stock" / "expected-lock-mask.png"


def points():
    with Image.open(MASK) as mask:
        return areas(mask.convert("RGBA"))


def nearly_all(left, right, tolerance):
    return sum(distance(a, b) <= tolerance for a, b in zip(left, right)) / len(left)


class MaskWitness:
    def __init__(self, positive, neutral, rect):
        self.rect = rect
        self.extent = neutral.size
        self.clock = clock_key(positive)
        strokes, self.matte, self.outside = points()
        self.strokes = strokes
        self.positive = positive.crop(rect)
        self.negative = neutral.crop(rect)
        if positive.size != neutral.size or reference_phase(neutral, rect) != 0:
            raise PixelError("unidentified neutral destination or mismatched display")
        if different_clock(self.clock, neutral) <= 14:
            raise PixelError("the lock clock and the neutral destination did not separate")
        self.locked_corners = pixels(self.positive, self.outside)
        self.reference_corners = pixels(self.negative, self.outside)
        if self.classify(positive).orb is not True or self.classify(neutral).orb is not False:
            raise PixelError("the painted and absent calibration images did not separate")

    def classify(self, frame):
        if frame.size != self.extent:
            raise PixelError("display extent changed")
        phase = reference_phase(frame, self.rect)
        clock_error = different_clock(self.clock, frame)
        scene = ("REFERENCE" if phase == 0 else "CALIBRATION" if phase is not None
                 else "MAIN" if clock_error < 10 else "UNKNOWN")
        crop = frame.crop(self.rect)
        samples = [pixels(crop, group) for group in self.strokes]
        match = [nearly_all(actual, pixels(self.positive, group), 52)
                 for actual, group in zip(samples, self.strokes)]
        differs = [1 - nearly_all(actual, pixels(self.negative, group), 33)
                   for actual, group in zip(samples, self.strokes)]
        matte = pixels(crop, self.matte)
        white = all(distance(rgb, (240, 240, 240)) <= 18 for rgb in matte)
        corners = pixels(crop, self.outside)
        reference_corners = nearly_all(corners, self.reference_corners, 30)
        lock_corners = nearly_all(corners, self.locked_corners, 30)
        absent = min(nearly_all(pixels(crop, group), pixels(self.negative, group), 25)
                     for group in [*self.strokes, self.matte, self.outside])
        outside_ok = reference_corners if scene == "REFERENCE" else max(reference_corners, lock_corners)
        if white and min(match) >= .8 and min(differs) >= .8 and outside_ok == 1:
            observed = True
        elif scene == "REFERENCE" and absent >= .98 and not white:
            observed = False
        else:
            observed = None
        return PixelResult(scene, observed, phase, clock_error, match, 1 - outside_ok, absent)


def verify_motion(device, rect, name, shots, frames):
    strokes, gap, corners = points()
    size = shots[0][1].crop(rect).size
    refs = [[pixels(frame.resize(size, Image.Resampling.BILINEAR), area) for area in strokes] for frame in frames]
    usable = []
    rows = []
    for when, image in shots:
        crop = image.crop(rect)
        actual = [pixels(crop, area) for area in strokes]
        scores = [[mae(a, r) for a, r in zip(actual, candidate)] for candidate in refs]
        best = min(range(len(scores)), key=lambda i: max(scores[i]))
        matte = all(distance(rgb, (240, 240, 240)) <= 4 for rgb in pixels(crop, gap))
        rows.append(dict(elapsed_ns=when, phase=best, mae=scores[best], matte=matte))
        if max(scores[best]) <= 14 and matte:
            usable.append((when, best, actual, pixels(crop, corners)))
    import json
    device.save(name + "-phases.json", (json.dumps(rows, indent=2) + "\n").encode())
    if not any((b[0] - a[0] >= 1_000_000_000 and a[1] != b[1]
                and mae(a[3], b[3]) <= 1.5
                and all(mae(x, y) >= .12 for x, y in zip(a[2], b[2])))
               for i, a in enumerate(usable) for b in usable[i + 1:]):
        raise PixelError("no distinct live phases over one settled second with stationary outer controls")

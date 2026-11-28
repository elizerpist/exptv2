"""Independent destination, lock clock and calibrated ORB crop witnesses."""

from dataclasses import dataclass
from PIL import Image, ImageChops, ImageStat

BACKGROUND = (18, 25, 37)
COLORS = (((252, 229, 93), (41, 231, 232)),
          ((252, 106, 36), (154, 248, 79)),
          ((250, 104, 166), (115, 169, 255)))
PATTERNS = ((.065, .215, ("1000", "1000", "1110")),
            (.795, .725, ("0110", "0001", "1111")))
CELL = (.028, .013)
PATCH_SIZE = 48


def distance(a, b):
    return max(abs(x - y) for x, y in zip(a, b))


def contains(bounds, x, y, radius=0):
    left, top, right, bottom = bounds
    return left - radius <= x <= right + radius and top - radius <= y <= bottom + radius


def reference_phase(frame, bounds=None):
    """Match the positive and background cells of both asymmetric marks."""
    measures = []
    for x, y, pattern in PATTERNS:
        group = []
        for row, line in enumerate(pattern):
            for column, category in enumerate(line):
                px = int((x + (column + .5) * CELL[0]) * frame.width)
                py = int((y + (row + .5) * CELL[1]) * frame.height)
                radius = max(2, int(min(CELL[0] * frame.width, CELL[1] * frame.height) / 6))
                if bounds and contains(bounds, px, py, radius):
                    return None
                rgb = ImageStat.Stat(frame.crop((px-radius, py-radius, px+radius, py+radius))).mean
                group.append((category, rgb))
        measures.append(group)
    return next((phase for phase, pair in enumerate(COLORS)
                 if all(distance(rgb, color if cell == "1" else BACKGROUND) <= 31
                        for group, color in zip(measures, pair) for cell, rgb in group)), None)


def miniature(frame, bounds):
    return list(frame.crop(bounds).resize((PATCH_SIZE, PATCH_SIZE), Image.Resampling.BILINEAR).getdata())


def clock_key(frame):
    rect = tuple(round(v * n) for v, n in zip((.28, .17, .72, .425), frame.size * 2))
    return frame.crop(rect).resize((28, 40), Image.Resampling.BILINEAR).convert("L")


def different_clock(reference, image):
    return ImageStat.Stat(ImageChops.difference(reference, clock_key(image))).mean[0]


SIDE = PATCH_SIZE / 2
INSIDE = tuple((ix, iy, iy * PATCH_SIZE + ix) for iy in range(PATCH_SIZE) for ix in range(PATCH_SIZE)
               if ((ix + .5 - SIDE) / SIDE) ** 2 + ((iy + .5 - SIDE) / SIDE) ** 2 < .80)
CORNERS = tuple(iy * PATCH_SIZE + ix for iy in range(PATCH_SIZE) for ix in range(PATCH_SIZE)
                if ((ix + .5 - SIDE) / SIDE) ** 2 + ((iy + .5 - SIDE) / SIDE) ** 2 > 1.25)


def colorful(rgb):
    return max(rgb) - min(rgb) >= 52 and max(rgb) >= 100


class PixelError(ValueError):
    pass


@dataclass
class PixelResult:
    scene: str
    orb: bool | None
    phase: int | None
    clock_mae: float
    quadrant_match: list
    corner_leak: float
    absent_fraction: float


class PixelWitness:
    def __init__(self, before, settled_reference, bounds):
        left, top, right, bottom = bounds
        if before.size != settled_reference.size or not (
            0 <= left < right <= before.width and 0 <= top < bottom <= before.height
            and (right - left) == (bottom - top)
        ):
            raise PixelError("ORB bounds or display extent not established")
        if reference_phase(settled_reference, bounds) != 0:
            raise PixelError("neutral reference has no independent optical signature outside the ORB")
        self.extent = before.size
        self.bounds = bounds
        self.clock = clock_key(before)
        if self.clock.getextrema()[1] - self.clock.getextrema()[0] < 38 or different_clock(
            self.clock, settled_reference
        ) <= 14:
            raise PixelError("MAIN clock sample cannot be distinguished from the return screen")
        self.positive = miniature(before, bounds)
        self.negative = miniature(settled_reference, bounds)
        self.quadrants = [[i for x, y, i in INSIDE
                           if (x < SIDE, y < SIDE) == (x_left, y_top)
                           and colorful(self.positive[i]) and distance(self.positive[i], self.negative[i]) > 45]
                          for x_left in (True, False) for y_top in (True, False)]
        if min(map(len, self.quadrants)) < 30:
            raise PixelError("painted ORB failed four-quadrant calibration")
        if self.classify(before).orb is not True or self.classify(settled_reference).orb is not False:
            raise PixelError("positive and absent controls did not separate")

    def classify(self, frame):
        if frame.size != self.extent:
            raise PixelError("display extent changed")
        phase = reference_phase(frame, self.bounds)
        clock_error = different_clock(self.clock, frame)
        scene = ("REFERENCE" if phase == 0 else "CALIBRATION" if phase is not None
                 else "MAIN" if clock_error < 10 else "UNKNOWN")
        patch = miniature(frame, self.bounds)
        ratios = [sum(colorful(patch[i]) and distance(patch[i], self.positive[i]) <= 65 for i in points)
                  / len(points) for points in self.quadrants]
        corner_leak = sum(colorful(patch[i]) and distance(patch[i], self.negative[i]) > 39 for i in CORNERS) / len(CORNERS)
        absent = sum(distance(a, b) <= 32 for a, b in zip(patch, self.negative)) / len(patch)
        # Colored bars and corner patches can be high energy without matching the disc.
        orb = (True if min(ratios) >= .52 and corner_leak <= .18
               else False if scene == "REFERENCE" and absent >= .989 and max(ratios) <= .04
               else None)
        return PixelResult(scene, orb, phase, clock_error, ratios, corner_leak, absent)

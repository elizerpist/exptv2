"""Decisive geometry and image controls, shared by the device driver."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Bounds:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self):
        return self.right - self.left

    @property
    def height(self):
        return self.bottom - self.top

    @property
    def center(self):
        return ((self.left + self.right) / 2, (self.top + self.bottom) / 2)


def same_center(first, second, tolerance=1):
    return all(abs(a-b) <= tolerance for a, b in zip(first, second))


def validate_drag(before_root, before_orb, root, orb, side, usable):
    assert root.width == root.height == side, "window failed to fit the entire circle"
    assert orb.width == orb.height == side, "orb edge clipped or resized"
    assert same_center(orb.center, root.center), "orb drifted inside the root"
    assert same_center(
        tuple(b-a for a, b in zip(before_root.center, root.center)),
        tuple(b-a for a, b in zip(before_orb.center, orb.center)),
    ), "root and orb moved differently"
    assert (usable.left <= root.left < root.right <= usable.right
            and usable.top <= root.top < root.bottom <= usable.bottom), "window overflow"


def validate_colors_and_motion(samples, reference, moving, limit=18):
    assert len(samples) >= 3 and len(reference) == len(samples)
    assert all(len(a) == len(b) and a for a, b in zip(samples, reference))
    distance = lambda a, b: sum(abs(x-y) for x, y in zip(a, b)) / len(a)
    assert all(distance(a, b) <= limit for a, b in zip(samples, reference)), "wrong palette or phase"
    deltas = [distance(a, b) for a, b in zip(samples, samples[1:])]
    if moving:
        assert min(deltas) > 1, "first-frame-only or repeated motion sample"
    else:
        assert max(deltas) <= 1, "static content changed"


if __name__ == "__main__":
    def reject(name, operation):
        try:
            operation()
        except AssertionError as error:
            print(f"PASS rejects {name}: {error}")
        else:
            raise AssertionError(f"weak oracle accepted {name}")

    viewport = Bounds(0, 25, 500, 550)
    start = Bounds(200, 200, 256, 256)
    right = Bounds(444, 494, 500, 550)
    validate_drag(start, start, right, right, 56, viewport)
    reject("child-only movement", lambda: validate_drag(start, start, start, right, 56, viewport))
    reject("undersized host", lambda: validate_drag(start, start, Bounds(448, 494, 500, 550), right, 56, viewport))
    reject("clipped circle", lambda: validate_drag(start, start, right, Bounds(444, 494, 496, 550), 56, viewport))
    animated = [(20, 100, 220), (30, 110, 190), (40, 120, 155)]
    validate_colors_and_motion(animated, animated, moving=True)
    validate_colors_and_motion([animated[0]] * 3, [animated[0]] * 3, moving=False)
    reject("wrong-palette input", lambda: validate_colors_and_motion(
        [(240, 30, 50)] * 3, animated, moving=True))
    narrow_animation = [(20, 100, 220), (23, 103, 217), (26, 106, 214)]
    reject("first-frame-only input", lambda: validate_colors_and_motion(
        [narrow_animation[0]] * 3, narrow_animation, moving=True))

"""Classify the observed output and require a separate display continuity proof for PASS."""

from dataclasses import dataclass

UNKNOWN = "INCONCLUSIVE"


@dataclass(frozen=True)
class Frame:
    index: int
    time_ns: int
    scene: str
    orb: bool | None
    display: int
    owner: tuple | None = None
    present: int | None = None
    image_age_ns: int | None = None


@dataclass(frozen=True)
class PresentCoverage:
    display: int
    tokens: tuple
    maximum_present_gap_ns: int
    maximum_image_age_ns: int


def order(first, second):
    """Strict interval order on a shared clock, with no assertion on overlaps."""
    if first is not None and second is not None:
        if first[1] < second[0]:
            return "BEFORE"
        if first[0] > second[1]:
            return "AFTER"
    return UNKNOWN


def snapshot(frame):
    return None if frame is None else dict(index=frame.index, time_ns=frame.time_ns,
                                           scene=frame.scene, orb=frame.orb)


def classify(frames, *, action, action_bracket, locked_before, destination_witnessed,
             display, owner, clock_valid, uncertainty_ns, proof=None):
    def inconclusive(reason, **endpoints):
        return dict(status=UNKNOWN, first_display_frame=UNKNOWN, reason=reason, **endpoints)

    if action != "unlock" or not locked_before or not destination_witnessed:
        return inconclusive("direct unlock or independent before/after state unestablished")
    if not frames or any(a.time_ns >= b.time_ns or a.index >= b.index for a, b in zip(frames, frames[1:])):
        return inconclusive("duplicated, missing or nonmonotonic sample order")
    if not owner or any(frame.display != display or
                        (frame.owner is not None and frame.owner != owner) for frame in frames):
        return inconclusive("wrong or unmatched display/attachment")

    # A clip can contain calibration and the ordinary reference before lock.
    # Start the transition at a separately calibrated painted MAIN sample.
    # A recorder with no absolute join can still supply ordered same-image evidence.
    if clock_valid:
        if action_bracket is None or uncertainty_ns is None or action_bracket[0] > action_bracket[1]:
            return inconclusive("invalid action clock bracket")
        before = [i for i, f in enumerate(frames)
                  if f.time_ns + uncertainty_ns < action_bracket[0] and f.scene == "MAIN" and f.orb is True]
    else:
        before = [i for i, f in enumerate(frames) if f.scene == "MAIN" and f.orb is True]
    if not before:
        return inconclusive("no calibrated painted MAIN sample before unlock")
    # With a relative-only clock, use the first painted MAIN in the single trial.
    start = before[-1] if clock_valid else before[0]
    tail = frames[start + 1:]
    if clock_valid:
        tail = [f for f in tail if f.time_ns + uncertainty_ns >= action_bracket[0]]
    restricted = [f for f in tail if f.scene == "REFERENCE"]
    first = restricted[0] if restricted else None
    last_main = next((f for f in reversed(frames[start:]) if f.scene == "MAIN"
                      and (first is None or f.index < first.index)), None)
    last_orb = next((f for f in reversed(frames[start:]) if f.orb is True), None)
    # A later empty-looking unknown scene never closes the interval.
    absent = next((f for f in restricted if last_orb and f.index > last_orb.index and f.orb is False), None)
    sustained = next(
        (f for f in restricted if f.orb is False
         and all(x.scene == "REFERENCE" and x.orb is False for x in tail if x.index >= f.index)
         and any(x.index > f.index for x in tail)), None)
    endpoints = dict(last_main=snapshot(last_main), first_definite_restricted=snapshot(first),
                     last_orb=snapshot(last_orb), first_subsequent_absent=snapshot(absent),
                     first_sustained_sampled_absent=snapshot(sustained))
    positive = next((f for f in restricted if f.orb is True), None)
    if positive:
        # A definite same-image witness remains evidence even if surrounding
        # samples are missing, including while the swipe command is in flight.
        return dict(status="FAIL", first_display_frame=UNKNOWN,
                    reason="ORB present in an independently identified restricted image",
                    forbidden_positive=snapshot(positive), **endpoints)
    if not first or not sustained or first.index != sustained.index or last_main is None:
        return inconclusive("first restricted image or sustained sampled absence unestablished", **endpoints)
    if not clock_valid or not proof or proof.display != display:
        return inconclusive("same-display present coverage or clock join missing", **endpoints)

    section = frames[start:]
    if (not section or tuple(f.present for f in section) != proof.tokens or None in proof.tokens
            or len(set(proof.tokens)) != len(proof.tokens)):
        return inconclusive("frames do not match the independently ordered display presents", **endpoints)
    if any(f.scene not in ("MAIN", "REFERENCE") or f.owner != owner or f.image_age_ns is None
           or not 0 <= f.image_age_ns <= proof.maximum_image_age_ns for f in section):
        return inconclusive("unknown scene, ownership or source buffer age", **endpoints)
    if any(a.index + 1 != b.index or b.time_ns - a.time_ns + 2 * uncertainty_ns > proof.maximum_present_gap_ns
           for a, b in zip(section, section[1:])):
        return inconclusive("coverage gap across transition", **endpoints)
    if any(f.orb is not False for f in section if f.index >= first.index):
        return inconclusive("unclassified or painted frame in covered restricted samples", **endpoints)
    return dict(status="PASS", first_display_frame="PASS",
                reason="independently covered same-display transition with sustained absence", **endpoints)

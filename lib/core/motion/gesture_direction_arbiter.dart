/// The first unambiguous axis for a pointer sequence.
///
/// Consumers keep their own gesture semantics, but share this small neutral
/// ownership rule so sibling surfaces do not drift into conflicting slop and
/// dominance thresholds.
enum GestureDirectionIntent { horizontal, vertical }

abstract final class GestureDirectionArbiter {
  /// Returns no winner until movement exceeds [touchSlop] and one axis is at
  /// least [dominanceRatio] stronger than the other.
  static GestureDirectionIntent? resolve({
    required double dx,
    required double dy,
    required double touchSlop,
    double dominanceRatio = 1.25,
  }) {
    assert(touchSlop >= 0);
    assert(dominanceRatio >= 1);
    final horizontal = dx.abs();
    final vertical = dy.abs();
    if (horizontal < touchSlop && vertical < touchSlop) return null;
    if (horizontal >= vertical * dominanceRatio) {
      return GestureDirectionIntent.horizontal;
    }
    if (vertical >= horizontal * dominanceRatio) {
      return GestureDirectionIntent.vertical;
    }
    return null;
  }
}

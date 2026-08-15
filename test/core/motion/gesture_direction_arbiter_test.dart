import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/motion/gesture_direction_arbiter.dart';

void main() {
  test(
    'RED: keeps a pointer undecided until slop and dominance are proven',
    () {
      expect(
        GestureDirectionArbiter.resolve(dx: -7, dy: 1, touchSlop: 8),
        isNull,
      );
      expect(
        GestureDirectionArbiter.resolve(dx: -16, dy: 13, touchSlop: 8),
        isNull,
      );
      expect(
        GestureDirectionArbiter.resolve(dx: -20, dy: 8, touchSlop: 8),
        GestureDirectionIntent.horizontal,
      );
      expect(
        GestureDirectionArbiter.resolve(dx: -8, dy: 20, touchSlop: 8),
        GestureDirectionIntent.vertical,
      );
    },
  );
}

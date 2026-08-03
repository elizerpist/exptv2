import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_motion.dart';

void main() {
  test('numeric motion trace retains the newest fixed-size events', () {
    final trace = RailMotionTrace(capacity: 3);

    for (var index = 0; index < 5; index += 1) {
      trace.record(
        RailMotionEventKind.semanticSettle,
        epoch: index,
        physicalIndex: index,
      );
    }

    expect(trace.events, hasLength(3));
    expect(trace.events.map((event) => event.epoch), <int>[2, 3, 4]);
    expect(trace.events.map((event) => event.physicalIndex), <int>[2, 3, 4]);
  });
}

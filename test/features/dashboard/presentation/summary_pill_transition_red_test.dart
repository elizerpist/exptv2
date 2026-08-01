import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

void main() {
  test('vertical transition exposes no horizontal component', () {
    for (final value in <double>[0, .25, .5, .75, 1]) {
      final offsets = SummaryPillTextTransitionMath.verticalOffsets(
        value,
        SummaryTransitionDirection.forward,
      );

      expect(offsets.incoming.dx, 0);
      expect(offsets.outgoing.dx, 0);
    }
  });

  test('horizontal transition exposes no vertical component', () {
    for (final value in <double>[0, .25, .5, .75, 1]) {
      final offsets = SummaryPillTextTransitionMath.horizontalOffsets(
        value,
        SummaryTransitionDirection.forward,
      );

      expect(offsets.incoming.dy, 0);
      expect(offsets.outgoing.dy, 0);
    }
  });

  test(
    'subtitle-only vertical transition stays within the compact rail-toggle range',
    () {
      final offsets = SummaryPillTextTransitionMath.verticalOffsets(
        0,
        SummaryTransitionDirection.forward,
        incomingDistance: 5,
        outgoingDistance: 4,
      );

      expect(offsets.incoming.dy, 5);
      expect(offsets.outgoing.dy, 0);
    },
  );
}

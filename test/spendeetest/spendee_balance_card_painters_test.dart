import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_card_painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B3M-A3 no-spend moon painter', () {
    test('maps the frozen 15px CSS moon and plus to explicit geometry', () {
      final geometry = const SpendeeBalanceMoonPainter().geometryForSize(
        const Size.square(15),
      );

      expect(geometry.moonCircle, const Rect.fromLTWH(0, 0, 15, 15));
      expect(geometry.insetShadowCircle, const Rect.fromLTWH(6, -2, 15, 15));
      expect(geometry.plusHorizontalBar, const Rect.fromLTWH(5, 6.25, 5, 1.5));
      expect(geometry.plusVerticalBar, const Rect.fromLTWH(6.75, 4.5, 1.5, 5));
    });

    test('does not repaint because its explicit geometry is immutable', () {
      expect(
        const SpendeeBalanceMoonPainter().shouldRepaint(
          const SpendeeBalanceMoonPainter(),
        ),
        isFalse,
      );
    });
  });

  group('B3M-A3 permanent variable-budget progress painter', () {
    test('normalizes 0%, 1%, 50%, 100%, and overflow geometry', () {
      const size = Size(100, 22);
      final cases = <(double, double)>[
        (0, 0),
        (.01, 1),
        (.5, 50),
        (1, 100),
        (1.25, 100),
      ];

      for (final (progress, expectedX) in cases) {
        final geometry = SpendeeBalanceBudgetProgressPainter(
          progress: progress,
        ).geometryForSize(size);

        expect(
          geometry.trackRect,
          const Rect.fromLTWH(0, 5, 100, 12),
          reason: 'track geometry at progress $progress',
        );
        expect(
          geometry.fillRect,
          Rect.fromLTWH(0, 5, expectedX, 12),
          reason: 'fill geometry at progress $progress',
        );
        expect(
          geometry.markerCenter,
          Offset(expectedX, 11),
          reason: 'marker center at progress $progress',
        );
        expect(
          geometry.markerOuterRect,
          Rect.fromCircle(center: Offset(expectedX, 11), radius: 11),
          reason: '22px marker at progress $progress',
        );
        expect(
          geometry.markerInnerRect,
          Rect.fromCircle(center: Offset(expectedX, 11), radius: 6),
          reason: '5px marker border at progress $progress',
        );
      }
    });

    test('keeps the frozen permanent visual layer specification', () {
      expect(SpendeeBalanceBudgetProgressPainter.trackHeight, 12);
      expect(SpendeeBalanceBudgetProgressPainter.markerDiameter, 22);
      expect(SpendeeBalanceBudgetProgressPainter.markerBorderWidth, 5);
      expect(
        SpendeeBalanceBudgetProgressPainter.trackColor,
        const Color(0xFFEEF0F7),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.fillGradient,
        const LinearGradient(colors: [Color(0xFFFF4D79), Color(0xFFE94FCB)]),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.trackInsetShadow,
        const BoxShadow(
          color: Color(0x0A444E8B),
          offset: Offset(0, 1),
          blurRadius: 1,
          blurStyle: BlurStyle.inner,
        ),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.fillShadow,
        const BoxShadow(
          color: Color(0x33EA4FBA),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.markerShadow,
        const BoxShadow(
          color: Color(0x4DF43D7A),
          offset: Offset(0, 3),
          blurRadius: 9,
        ),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.markerRingColor,
        const Color(0x38FF5F91),
      );
      expect(
        SpendeeBalanceBudgetProgressPainter.markerColor,
        const Color(0xFFFF4677),
      );
    });

    test('builds a hollow shifted mask for the true inset track shadow', () {
      const size = Size(100, 22);
      const painter = SpendeeBalanceBudgetProgressPainter(progress: .5);
      final mask = painter.trackInsetShadowPathForSize(size);

      expect(mask.fillType, PathFillType.evenOdd);
      expect(mask.contains(const Offset(50, 5)), isTrue);
      expect(mask.contains(const Offset(50, 11)), isFalse);
      expect(mask.contains(const Offset(50, 17)), isFalse);
    });

    test('repaints only when the source progress changes', () {
      const painter = SpendeeBalanceBudgetProgressPainter(progress: .5);

      expect(
        painter.shouldRepaint(
          const SpendeeBalanceBudgetProgressPainter(progress: .5),
        ),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          const SpendeeBalanceBudgetProgressPainter(progress: .51),
        ),
        isTrue,
      );
    });
  });
}

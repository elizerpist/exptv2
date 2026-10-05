import 'package:fluvi/core/design/fluvi_bounded_curve.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wider renderer span keeps endpoints and control bounds', () {
    const points = [Offset(0, 40), Offset(20, 0), Offset(40, 80)];
    final segments = fluviBoundedMonotoneSegments(
      points,
      controlSpan: .48,
      create:
          ({
            required start,
            required controlOne,
            required controlTwo,
            required end,
            required isLinear,
          }) => (start, controlOne, controlTwo, end),
    );
    expect(segments.first.$1, points.first);
    expect(segments.first.$4, points[1]);
    expect(segments.last.$4, points.last);
    expect(segments.first.$2.dx, 9.6);
    expect(segments.first.$3.dy, 0);
    expect(segments.last.$2.dy, 0);
    for (final (start, one, two, end) in segments) {
      final low = start.dy < end.dy ? start.dy : end.dy;
      final high = start.dy > end.dy ? start.dy : end.dy;
      expect(one.dy, inInclusiveRange(low, high));
      expect(two.dy, inInclusiveRange(low, high));
      expect(one.dx, lessThan(two.dx));
    }
  });
  test(
    'WR-26 preserves the existing Mind segment constructor and exact controls',
    () {
      final segments = mindDetailedSumCurveSegments(
        points: const [
          Offset(0, 50),
          Offset(20, 5),
          Offset(40, 80),
          Offset(60, 30),
        ],
        interpolationMode: MindSumLineInterpolationMode.monotoneCubic,
        catmullRomTension: .35,
      );
      expect(segments, hasLength(3));
      expect(
        segments.first.runtimeType.toString(),
        'MindDetailedSumCurveSegment',
      );
      expect(segments.map((s) => s.controlOne), [
        Offset(20 / 3, 35),
        Offset(20 + 20 / 3, 5),
        Offset(40 + 20 / 3, 80),
      ]);
      expect(segments.map((s) => s.controlTwo), [
        Offset(20 - 20 / 3, 5),
        Offset(40 - 20 / 3, 80),
        Offset(60 - 20 / 3, 30 + 50 / 3),
      ]);
      expect(segments.every((s) => !s.isLinear), isTrue);
      final duplicate = mindDetailedSumCurveSegments(
        points: const [Offset(40, 80), Offset(40, 30)],
        interpolationMode: MindSumLineInterpolationMode.monotoneCubic,
        catmullRomTension: .35,
      ).single;
      expect(duplicate.isLinear, isTrue);
      expect(duplicate.controlOne, duplicate.start);
      expect(duplicate.controlTwo, duplicate.end);
    },
  );
}

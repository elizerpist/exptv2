import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  test(
    'DSUM-02 RED: full-year is the minimum zoom and focal time stays stable while zooming',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2025);
      final focal = const LocalDate(year: 2025, month: 5, day: 16).epochDay;

      expect(
        home.startEpochDay,
        const LocalDate(year: 2025, month: 1, day: 1).epochDay,
      );
      expect(
        home.endEpochDay,
        const LocalDate(year: 2025, month: 12, day: 31).epochDay,
      );

      final zoomed = home.zoom(scaleDelta: 2, focalEpochDay: focal);
      expect(zoomed.visibleDayCount, lessThan(home.visibleDayCount));
      expect(
        zoomed.normalizedPositionOf(focal),
        closeTo(home.normalizedPositionOf(focal), .02),
      );
      expect(
        home.zoom(scaleDelta: .25, focalEpochDay: focal),
        home,
        reason: 'The home Jan–Dec window is the farthest zoom-out extent.',
      );
    },
  );

  test(
    'DSUM-03 RED: LOD retains real extrema and reveals more actual days as temporal density increases',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2025);
      final points = <MindSumHeatmapDailyPoint>[
        for (var day = 1; day <= 24; day += 1)
          MindSumHeatmapDailyPoint(
            date: LocalDate(year: 2025, month: 1, day: day),
            total: day == 2 ? 900 : 100 + day,
          ),
        MindSumHeatmapDailyPoint(
          date: const LocalDate(year: 2025, month: 8, day: 4),
          total: 700,
        ),
        MindSumHeatmapDailyPoint(
          date: const LocalDate(year: 2025, month: 12, day: 31),
          total: 300,
        ),
      ];

      final overview = MindDetailedSumLod.sample(
        points: points,
        window: home,
        pixelWidth: 1,
      );
      final close = MindDetailedSumLod.sample(
        points: points,
        window: home.zoom(
          scaleDelta: 8,
          focalEpochDay: const LocalDate(year: 2025, month: 1, day: 2).epochDay,
        ),
        pixelWidth: 120,
      );

      expect(overview.any((point) => point.total == 900), isTrue);
      expect(
        overview.every(points.contains),
        isTrue,
        reason: 'LOD may select only supplied immutable financial anchors.',
      );
      expect(
        overview.length,
        lessThanOrEqualTo(4),
        reason:
            'One visual bucket retains at most chronological endpoints plus '
            'its minimum and maximum source anchors.',
      );
      expect(close.length, greaterThanOrEqualTo(overview.length));
      expect(close.every(points.contains), isTrue);
      expect(
        close.map((point) => point.date),
        contains(const LocalDate(year: 2025, month: 1, day: 2)),
      );
    },
  );
}

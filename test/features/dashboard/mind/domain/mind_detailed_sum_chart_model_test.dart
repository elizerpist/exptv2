import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  test(
    'SUM3-ZOOM-01 RED: a normal cumulative pinch reaches a useful half-year window',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2025);
      final focal =
          const LocalDate(year: 2025, month: 7, day: 1).epochDay * 1440 + 720;

      final first = home.zoomForGesture(
        scaleDelta: 1.12,
        focalEpochMinute: focal,
      );
      final second = first.zoomForGesture(
        scaleDelta: 1.12,
        focalEpochMinute: focal,
      );

      expect(first.visibleDayCount, lessThan(home.visibleDayCount));
      expect(
        second.visibleDayCount,
        lessThanOrEqualTo(184),
        reason:
            'Two ordinary pinch sessions must reach a materially useful '
            'half-year-or-less temporal extent, rather than 12→11 months.',
      );
      expect(
        second.normalizedPositionOfEpochMinute(focal),
        closeTo(home.normalizedPositionOfEpochMinute(focal), .03),
        reason: 'Gesture amplification cannot make the focal time jump.',
      );
    },
  );

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
      final points = <MindSumHeatmapDetailPoint>[
        for (var day = 1; day <= 24; day += 1)
          MindSumHeatmapDetailPoint(
            epochMinute:
                LocalDate(year: 2025, month: 1, day: day).epochDay * 1440 + 720,
            total: day == 2 ? 900 : 100 + day,
          ),
        MindSumHeatmapDetailPoint(
          epochMinute:
              const LocalDate(year: 2025, month: 8, day: 4).epochDay * 1440 +
              720,
          total: 700,
        ),
        MindSumHeatmapDetailPoint(
          epochMinute:
              const LocalDate(year: 2025, month: 12, day: 31).epochDay * 1440 +
              720,
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
        close.map((point) => point.epochMinute),
        contains(
          const LocalDate(year: 2025, month: 1, day: 2).epochDay * 1440 + 720,
        ),
      );
    },
  );

  test(
    'DSUM-LOD-01 RED: a full-year overview is materially calmer and a deep day preserves every source transaction',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2025);
      final points = <MindSumHeatmapDetailPoint>[
        for (var day = 0; day < home.homeDayCount; day += 1)
          for (var sample = 0; sample < 3; sample += 1)
            MindSumHeatmapDetailPoint(
              epochMinute: home.homeStartEpochMinute + day * 1440 + sample * 90,
              total: sample == 2 && day == 120 ? 9000 : 100 + sample,
              ordinal: day * 3 + sample,
            ),
      ];

      final overview = MindDetailedSumLod.sample(
        points: points,
        window: home,
        pixelWidth: 336,
      );
      final dayStart = home.homeStartEpochMinute + 120 * 1440;
      final deep = MindDetailedSumLod.sample(
        points: points,
        window: home.zoomAtMinute(
          scaleDelta: home.homeMinuteCount.toDouble() / 1440,
          focalEpochMinute: dayStart + 90,
        ),
        pixelWidth: 336,
      );

      expect(overview.length, lessThan(points.length ~/ 4));
      expect(overview.any((point) => point.total == 9000), isTrue);
      expect(deep, hasLength(3));
      expect(deep.map((point) => point.ordinal), <int>[360, 361, 362]);
    },
  );
}

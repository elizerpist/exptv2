import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
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

  test(
    'XR-SUM-04 RED: same-resolution LOD anchors stay stable through an overlapping pan',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2025);
      final source = <MindSumHeatmapDetailPoint>[
        for (var day = 0; day < home.homeDayCount; day += 1)
          for (var sample = 0; sample < 4; sample += 1)
            MindSumHeatmapDetailPoint(
              epochMinute:
                  home.homeStartEpochMinute + day * 1440 + sample * 180,
              total: day == 190 && sample == 3 ? 9000 : 100 + sample + day,
              ordinal: day * 4 + sample,
            ),
      ];
      final first = home.zoomAtMinute(
        scaleDelta: 4,
        focalEpochMinute: home.homeStartEpochMinute + 180 * 1440,
      );
      final second = first.panByDays(20);
      final interiorStart = second.startEpochMinute + 7 * 1440;
      final interiorEnd = first.endEpochMinute - 7 * 1440;

      Set<int> interiorOrdinals(MindDetailedSumTimeWindow window) =>
          MindDetailedSumLod.sample(
                points: source,
                window: window,
                pixelWidth: 140,
              )
              .where(
                (point) =>
                    point.epochMinute >= interiorStart &&
                    point.epochMinute <= interiorEnd,
              )
              .map((point) => point.ordinal!)
              .toSet();

      expect(interiorOrdinals(first), isNotEmpty);
      expect(
        interiorOrdinals(second),
        interiorOrdinals(first),
        reason:
            'At a fixed zoom level, a pan may crop or translate the '
            'line but may not re-bucket the overlapping financial anchors.',
      );
    },
  );

  test(
    'SUM-PAN-EDGE-01 RED: paint continuity keeps real neighbour anchors without making them inspectable',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2027);
      final window = home.zoomAtMinute(
        scaleDelta: home.homeMinuteCount / (12 * 1440),
        focalEpochMinute: home.homeStartEpochMinute + 180 * 1440,
      );
      final leftNeighbour = MindSumHeatmapDetailPoint(
        epochMinute: window.startEpochMinute - 120,
        total: 90,
        ordinal: 1,
      );
      final firstVisible = MindSumHeatmapDetailPoint(
        epochMinute: window.startEpochMinute + 120,
        total: 100,
        ordinal: 2,
      );
      final lastVisible = MindSumHeatmapDetailPoint(
        epochMinute: window.endEpochMinute - 120,
        total: 300,
        ordinal: 3,
      );
      final rightNeighbour = MindSumHeatmapDetailPoint(
        epochMinute: window.endEpochMinute + 120,
        total: 80,
        ordinal: 4,
      );

      final selection = MindDetailedSumLod.select(
        points: <MindSumHeatmapDetailPoint>[
          leftNeighbour,
          firstVisible,
          lastVisible,
          rightNeighbour,
        ],
        window: window,
        pixelWidth: 280,
      );

      expect(selection.inspectablePoints, <MindSumHeatmapDetailPoint>[
        firstVisible,
        lastVisible,
      ]);
      expect(selection.paintPoints, <MindSumHeatmapDetailPoint>[
        leftNeighbour,
        firstVisible,
        lastVisible,
        rightNeighbour,
      ]);
      expect(selection.hasLeftPaintContinuation, isTrue);
      expect(selection.hasRightPaintContinuation, isTrue);
      expect(
        selection.paintPoints.where(
          (point) =>
              point.epochMinute < window.startEpochMinute ||
              point.epochMinute > window.endEpochMinute,
        ),
        isNotEmpty,
        reason:
            'The real outside anchors are painter context only, not fake '
            'in-window financial observations.',
      );
    },
  );

  test(
    'SUM-DENSITY-GEOMETRY: one pure resolver shares the one/two-band viewport contract',
    () {
      final two = MindSumChartDensityGeometry.resolve(
        availableHeight: 260,
        yearCount: 3,
        preference: MindSumVisibleChartCount.two,
      );
      final one = MindSumChartDensityGeometry.resolve(
        availableHeight: 260,
        yearCount: 3,
        preference: MindSumVisibleChartCount.one,
      );
      final singleYear = MindSumChartDensityGeometry.resolve(
        availableHeight: 260,
        yearCount: 1,
        preference: MindSumVisibleChartCount.two,
      );

      expect(two.visibleBandCount, 2);
      expect(two.bandHeight, closeTo(126, .001));
      expect(one.visibleBandCount, 1);
      expect(one.bandHeight, 260);
      expect(singleYear.visibleBandCount, 1);
      expect(singleYear.bandHeight, 260);
    },
  );

  test(
    'SUM-AXIS-01 RED: detailed Sum uses full Hungarian month names only when the zoomed viewport has room for them',
    () {
      final home = MindDetailedSumTimeWindow.fullYear(2027);
      final sixMonthWindow = home.zoomAtMinute(
        scaleDelta: home.homeMinuteCount / (180 * 1440),
        focalEpochMinute:
            LocalDate(year: 2027, month: 6, day: 15).epochDay * 1440 + 720,
      );

      expect(
        MindDetailedSumAxisLabelDensity.forWindow(
          year: 2027,
          window: home,
          availableWidth: 280,
        ),
        MindDetailedSumAxisLabelDensity.initials,
      );
      expect(
        MindDetailedSumAxisLabelDensity.forWindow(
          year: 2027,
          window: sixMonthWindow,
          availableWidth: 280,
        ),
        MindDetailedSumAxisLabelDensity.fullNames,
      );
      expect(
        MindDetailedSumAxisLabelDensity.forWindow(
          year: 2027,
          window: sixMonthWindow,
          availableWidth: 120,
        ),
        MindDetailedSumAxisLabelDensity.initials,
        reason: 'Full labels never win if their actual slot width would clash.',
      );
    },
  );

  test(
    'SUM-CURVE-01 RED: weighted presentation smoothing preserves raw extrema and deep strength returns raw points',
    () {
      const points = <MindSumHeatmapDetailPoint>[
        MindSumHeatmapDetailPoint(epochMinute: 0, total: 100, ordinal: 1),
        MindSumHeatmapDetailPoint(epochMinute: 1440, total: 120, ordinal: 2),
        MindSumHeatmapDetailPoint(epochMinute: 2880, total: 900, ordinal: 3),
        MindSumHeatmapDetailPoint(epochMinute: 4320, total: 140, ordinal: 4),
        MindSumHeatmapDetailPoint(epochMinute: 5760, total: 160, ordinal: 5),
      ];

      final raw = MindDetailedSumVisualSmoothing.apply(
        points: points,
        window: MindSumSmoothingWindow.days7,
        strength: 0,
      );
      final smooth = MindDetailedSumVisualSmoothing.apply(
        points: points,
        window: MindSumSmoothingWindow.days7,
        strength: 1,
      );
      final deep = MindDetailedSumVisualSmoothing.apply(
        points: points,
        window: MindSumSmoothingWindow.days7,
        strength: .003,
      );

      expect(raw, same(points));
      expect(smooth[2].total, 900, reason: 'Real spike stays a real spike.');
      expect(smooth[1].total, isNot(points[1].total));
      expect(deep[1].total, closeTo(points[1].total, 2));
      expect(
        smooth.map((point) => point.ordinal),
        points.map((point) => point.ordinal),
        reason: 'Paint smoothing does not discard eligible anchors.',
      );
    },
  );
}

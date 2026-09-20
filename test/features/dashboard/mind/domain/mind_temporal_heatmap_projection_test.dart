import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const fullRange = QueryAmountRangeValues(
    minimumScaled100: 100,
    maximumScaled100: 1000,
    lowerScaled100: 100,
    upperScaled100: 1000,
  );

  final contributions = <MindYearHeatmapPreparedContribution>[
    _contribution(0, 100, const LocalDate(year: 2025, month: 1, day: 2)),
    _contribution(1, 500, const LocalDate(year: 2025, month: 5, day: 3)),
    _contribution(2, 1000, const LocalDate(year: 2025, month: 5, day: 3)),
    _contribution(3, 200, const LocalDate(year: 2026, month: 1, day: 4)),
  ];

  test(
    'RED SUM-HM-02: amount membership is filtered before Sum month aggregation',
    () {
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      );

      final frame = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 100,
          upperScaled100: 500,
        ),
      );

      expect(frame.years, const <int>[2025, 2026]);
      expect(frame.month(year: 2025, month: 1).total, 100);
      expect(frame.month(year: 2025, month: 5).total, 500);
      expect(frame.month(year: 2026, month: 1).total, 200);
      expect(frame.yearTotal(2025), 600);
      expect(frame.yearTotal(2026), 200);
      expect(frame.minimumNonEmptyTotal, 100);
      expect(frame.maximumNonEmptyTotal, 500);
      expect(frame.month(year: 2025, month: 1).intensity, 0);
      expect(frame.month(year: 2025, month: 5).intensity, 1);
      expect(frame.month(year: 2026, month: 1).intensity, .25);
    },
  );

  test(
    'SUM-HM-08/09/10: Sum keeps empty months neutral and represents one-value domains explicitly',
    () {
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 300, const LocalDate(year: 2027, month: 6, day: 2)),
        ],
      );

      final frame = projection.preview(fullRange);
      final active = frame.month(year: 2027, month: 6);
      final empty = frame.month(year: 2027, month: 7);
      expect(active.total, 300);
      expect(active.kind, MindYearHeatmapTileKind.equalRange);
      expect(active.intensity, .72);
      expect(
        active.paletteIntensity,
        MindYearHeatmapPaletteIntensity.equalRange,
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.kind, MindYearHeatmapTileKind.empty);
      expect(empty.paletteIntensity, MindYearHeatmapPaletteIntensity.empty);
      expect(frame.yearTotal(2027), 300);
    },
  );

  test(
    'SUM-LINE-01 RED: Sum exposes only real local-day range-preview points from resident buckets',
    () {
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 100, const LocalDate(year: 2025, month: 1, day: 2)),
          _contribution(1, 400, const LocalDate(year: 2025, month: 1, day: 2)),
          _contribution(2, 700, const LocalDate(year: 2025, month: 2, day: 14)),
          _contribution(
            3,
            900,
            const LocalDate(year: 2025, month: 11, day: 30),
          ),
        ],
      );

      final full = projection.preview(fullRange);
      expect(
        full.dailyPointsForYear(2025),
        <Matcher>[
          isA<MindSumHeatmapDailyPoint>()
              .having(
                (point) => point.date,
                'date',
                const LocalDate(year: 2025, month: 1, day: 2),
              )
              .having((point) => point.total, 'total', 500),
          isA<MindSumHeatmapDailyPoint>()
              .having(
                (point) => point.date,
                'date',
                const LocalDate(year: 2025, month: 2, day: 14),
              )
              .having((point) => point.total, 'total', 700),
          isA<MindSumHeatmapDailyPoint>()
              .having(
                (point) => point.date,
                'date',
                const LocalDate(year: 2025, month: 11, day: 30),
              )
              .having((point) => point.total, 'total', 900),
        ],
        reason:
            'No empty or interpolated calendar day may become a financial point.',
      );

      final narrowed = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 350,
          upperScaled100: 750,
        ),
      );
      expect(
        narrowed.dailyPointsForYear(2025).map((point) => point.total),
        <int>[400, 700],
      );
      expect(projection.preparedContributionTouches, 4);
    },
  );

  test(
    'SUM-DETAIL-01 RED: a deep Sum detail window retains separately timed eligible transactions from resident prepared input',
    () {
      const date = LocalDate(year: 2025, month: 5, day: 3);
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(3, 100, date, localTimeMinutes: 20),
          _contribution(7, 500, date, localTimeMinutes: 720),
          _contribution(9, 900, date, localTimeMinutes: 720),
          _contribution(
            10,
            400,
            const LocalDate(year: 2025, month: 5, day: 4),
            localTimeMinutes: 60,
          ),
        ],
      );
      final frame = projection.preview(fullRange);
      final start = date.epochDay * 1440;

      expect(
        frame.detailPointsForYear(
          year: 2025,
          startEpochMinute: start,
          endEpochMinute: start + 1439,
        ),
        <Matcher>[
          isA<MindSumHeatmapDetailPoint>()
              .having((point) => point.epochMinute, 'time', start + 20)
              .having((point) => point.total, 'amount', 100)
              .having((point) => point.ordinal, 'ordinal', 3),
          isA<MindSumHeatmapDetailPoint>()
              .having((point) => point.epochMinute, 'time', start + 720)
              .having((point) => point.total, 'amount', 500)
              .having((point) => point.ordinal, 'ordinal', 7),
          isA<MindSumHeatmapDetailPoint>()
              .having((point) => point.epochMinute, 'time', start + 720)
              .having((point) => point.total, 'amount', 900)
              .having((point) => point.ordinal, 'ordinal', 9),
        ],
        reason:
            'Daily aggregation cannot satisfy deep zoom: same-day points must '
            'retain their prepared local time and stable ordinal.',
      );

      final narrowed = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 450,
          upperScaled100: 950,
        ),
      );
      expect(
        narrowed
            .detailPointsForYear(
              year: 2025,
              startEpochMinute: start,
              endEpochMinute: start + 1439,
            )
            .map((point) => point.ordinal),
        <int>[7, 9],
      );
      expect(projection.preparedContributionTouches, 4);
    },
  );

  test(
    'MONTH-RHYTHM-02 RED: Month keeps slider-before daily comparison bars resident beside the live preview',
    () {
      final projection = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 100, const LocalDate(year: 2025, month: 5, day: 2)),
          _contribution(1, 700, const LocalDate(year: 2025, month: 5, day: 2)),
          _contribution(2, 900, const LocalDate(year: 2025, month: 5, day: 9)),
        ],
      );
      final frame = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 500,
          upperScaled100: 800,
        ),
      );

      expect(
        frame.fullDailyRhythmPoints
            .where((point) => point.total > 0)
            .map((point) => (point.ordinal, point.total)),
        <(int, int)>[(2, 800), (9, 900)],
        reason:
            'The gray comparison remains the admitted membership before only the live slider refinement.',
      );
      expect(
        frame.dailyRhythmPoints
            .where((point) => point.total > 0)
            .map((point) => (point.ordinal, point.total)),
        <(int, int)>[(2, 700)],
      );
    },
  );

  test(
    'RED MONTH-HM-02: selected Month projects real daily filtered totals',
    () {
      final projection = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      );

      final frame = projection.preview(fullRange);

      expect(frame.year, 2025);
      expect(frame.month, 5);
      expect(frame.days, hasLength(31));
      expect(frame.day(3).total, 1500);
      expect(frame.activeDayCount, 1);
      expect(frame.total, 1500);
      expect(frame.day(2).isEmpty, isTrue);
    },
  );

  test('MONTH-HM-02/05/14: leap February retains 29 real days only', () {
    final projection = MindMonthHeatmapProjection.build(
      identity: const MindTemporalHeatmapIdentity(
        upstreamScopeKey: 'income|month:2024-02',
        indexGeneration: 1,
        coreRevision: 1,
        timeScopeKey: 'month:2024-02',
      ),
      year: 2024,
      month: 2,
      contributions: <MindYearHeatmapPreparedContribution>[
        _contribution(0, 400, const LocalDate(year: 2024, month: 2, day: 29)),
      ],
    );

    final frame = projection.preview(fullRange);
    expect(frame.days, hasLength(29));
    expect(frame.day(29).total, 400);
    expect(frame.activeDayCount, 1);
    expect(frame.total, 400);
  });

  test(
    'MONTH-RHYTHM-01 RED: Month exposes a continuous bounded daily aggregate domain for the rhythm card',
    () {
      final projection = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 200, const LocalDate(year: 2025, month: 5, day: 2)),
          _contribution(1, 700, const LocalDate(year: 2025, month: 5, day: 2)),
          _contribution(2, 400, const LocalDate(year: 2025, month: 5, day: 31)),
        ],
      );

      final frame = projection.preview(fullRange);

      expect(frame.dailyRhythmPoints, hasLength(31));
      expect(
        frame.dailyRhythmPoints.map((point) => (point.ordinal, point.total)),
        <(int, int)>[
          for (var day = 1; day <= 31; day += 1)
            (
              day,
              day == 2
                  ? 900
                  : day == 31
                  ? 400
                  : 0,
            ),
        ],
        reason:
            'The chart has one truthful current-range aggregate for each real calendar day, including empty days as zero visual positions.',
      );
      expect(projection.preparedContributionTouches, 3);
    },
  );

  test('DAY-DATA-01 RED: selected Day keeps 24 local-hour amount buckets', () {
    const selected = LocalDate(year: 2026, month: 7, day: 14);
    final projection = MindDayHeatmapProjection.build(
      identity: const MindTemporalHeatmapIdentity(
        upstreamScopeKey: 'expense|day:2026-07-14',
        indexGeneration: 1,
        coreRevision: 1,
        timeScopeKey: 'day:2026-07-14',
      ),
      date: selected,
      contributions: <MindYearHeatmapPreparedContribution>[
        _contribution(0, 100, selected, localTimeMinutes: 0),
        _contribution(1, 200, selected, localTimeMinutes: 59),
        _contribution(2, 300, selected, localTimeMinutes: 60),
        _contribution(3, 400, selected, localTimeMinutes: 1439),
        _contribution(4, 500, selected, localTimeMinutes: 61),
        _contribution(
          5,
          999,
          const LocalDate(year: 2026, month: 7, day: 13),
          localTimeMinutes: 60,
        ),
      ],
    );

    final frame = projection.preview(fullRange);
    expect(frame.hours, hasLength(24));
    expect(frame.hour(0).total, 300);
    expect(frame.hour(1).total, 800);
    expect(frame.hour(23).total, 400);
    expect(frame.hour(2).isEmpty, isTrue);
    expect(frame.activeHourCount, 3);
    expect(frame.total, 1500);
    expect(projection.preparedContributionTouches, 6);
  });

  test(
    'DAY-DATA-03: Day range preview retains bounded hour buckets without a source-row scan',
    () {
      const selected = LocalDate(year: 2026, month: 7, day: 14);
      final projection = MindDayHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|day:2026-07-14',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'day:2026-07-14',
        ),
        date: selected,
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 100, selected, localTimeMinutes: 60),
          _contribution(1, 500, selected, localTimeMinutes: 60),
          _contribution(2, 900, selected, localTimeMinutes: 120),
        ],
      );

      final frame = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 400,
          upperScaled100: 950,
        ),
      );

      expect(frame.hour(1).total, 500);
      expect(frame.hour(2).total, 900);
      expect(frame.hour(0).isEmpty, isTrue);
      expect(frame.activeHourCount, 2);
      expect(frame.total, 1400);
      expect(
        frame.hours,
        hasLength(24),
        reason: 'The preview loop is bounded to the frame\'s 24 buckets.',
      );
    },
  );

  test(
    'DAY-TIMELINE-01 RED: Day retains exact resident transaction markers and filters them by the live amount range',
    () {
      const selected = LocalDate(year: 2026, month: 7, day: 14);
      final projection = MindDayHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|day:2026-07-14',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'day:2026-07-14',
        ),
        date: selected,
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(8, 100, selected, localTimeMinutes: 15),
          _contribution(2, 700, selected, localTimeMinutes: 721),
          _contribution(5, 400, selected, localTimeMinutes: 721),
          _contribution(9, 900, selected, localTimeMinutes: 1438),
          _contribution(
            10,
            999,
            const LocalDate(year: 2026, month: 7, day: 13),
            localTimeMinutes: 120,
          ),
        ],
      );

      final frame = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 350,
          upperScaled100: 800,
        ),
      );

      expect(frame.timelineEvents, <Matcher>[
        isA<MindDayTimelineEvent>()
            .having((event) => event.timeMinutes, 'time', 721)
            .having((event) => event.total, 'total', 700)
            .having((event) => event.ordinal, 'ordinal', 2),
        isA<MindDayTimelineEvent>()
            .having((event) => event.timeMinutes, 'time', 721)
            .having((event) => event.total, 'total', 400)
            .having((event) => event.ordinal, 'ordinal', 5),
      ]);
      expect(projection.preparedContributionTouches, 5);
    },
  );

  test(
    'DAY-TIMELINE-02 RED: Day keeps resident slider-before events for the gray comparison series',
    () {
      const selected = LocalDate(year: 2026, month: 7, day: 14);
      final projection = MindDayHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|day:2026-07-14',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'day:2026-07-14',
        ),
        date: selected,
        contributions: <MindYearHeatmapPreparedContribution>[
          _contribution(0, 100, selected, localTimeMinutes: 15),
          _contribution(1, 700, selected, localTimeMinutes: 721),
          _contribution(2, 900, selected, localTimeMinutes: 1438),
        ],
      );
      final frame = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 500,
          upperScaled100: 800,
        ),
      );

      expect(frame.fullTimelineEvents.map((event) => event.total), <int>[
        100,
        700,
        900,
      ]);
      expect(frame.timelineEvents.map((event) => event.total), <int>[700]);
      expect(frame.fullTimelineTotal, 1700);
    },
  );
}

MindYearHeatmapPreparedContribution _contribution(
  int ordinal,
  int amount,
  LocalDate date, {
  int localTimeMinutes = 0,
}) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  bookedLocalEpochDay: date.epochDay,
  bookedLocalTimeMinutes: localTimeMinutes,
  amountMinor: amount,
);

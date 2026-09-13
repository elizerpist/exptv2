import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  MindYearHeatmapProjection build({
    required int year,
    required List<DashboardLedgerEntry> entries,
    MindYearHeatmapSourceWorkCounter? counter,
  }) => MindYearHeatmapProjection.build(
    identity: MindYearHeatmapIdentity(
      upstreamScopeKey: 'expense|year:$year|category:food|partner:-',
      indexGeneration: 17,
      coreRevision: 42,
      year: year,
      navigationEpoch: 9,
    ),
    entries: entries,
    sourceWorkCounter: counter,
  );

  QueryAmountRangeValues range(int lower, int upper) => QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: lower,
    upperScaled100: upper,
  );

  test('RED MYH-03: ordinary and leap years expose only valid local days', () {
    final ordinary = build(
      year: 2025,
      entries: const <DashboardLedgerEntry>[],
    ).preview(range(1, 1000));
    final leap = build(
      year: 2024,
      entries: const <DashboardLedgerEntry>[],
    ).preview(range(1, 1000));

    expect(ordinary.days, hasLength(365));
    expect(leap.days, hasLength(366));
    expect(ordinary.month(2), hasLength(28));
    expect(leap.month(2), hasLength(29));
    expect(
      leap.dayFor(const LocalDate(year: 2024, month: 2, day: 29)).kind,
      MindYearHeatmapTileKind.empty,
    );
    expect(
      () => ordinary.dayFor(const LocalDate(year: 2025, month: 2, day: 29)),
      throwsArgumentError,
    );
  });

  test('RED MYH-08: normalization is global across months, not per month', () {
    final frame = build(
      year: 2025,
      entries: <DashboardLedgerEntry>[
        _entry('jan-min', 100, const LocalDate(year: 2025, month: 1, day: 2)),
        _entry(
          'feb-middle',
          300,
          const LocalDate(year: 2025, month: 2, day: 2),
        ),
        _entry('sep-max', 500, const LocalDate(year: 2025, month: 9, day: 2)),
      ],
    ).preview(range(1, 1000));

    expect(
      frame.dayFor(const LocalDate(year: 2025, month: 1, day: 2)).kind,
      MindYearHeatmapTileKind.minimum,
    );
    expect(
      frame.dayFor(const LocalDate(year: 2025, month: 2, day: 2)).intensity,
      closeTo(.5, .0001),
    );
    expect(
      frame.dayFor(const LocalDate(year: 2025, month: 9, day: 2)).kind,
      MindYearHeatmapTileKind.maximum,
    );
  });

  test(
    'RED MYH-04: the range applies to individual matching contributions',
    () {
      final projection = build(
        year: 2025,
        entries: <DashboardLedgerEntry>[
          _entry('low', 100, const LocalDate(year: 2025, month: 3, day: 3)),
          _entry(
            'included',
            300,
            const LocalDate(year: 2025, month: 3, day: 3),
          ),
          _entry('high', 900, const LocalDate(year: 2025, month: 4, day: 4)),
        ],
      );

      final frame = projection.preview(range(200, 500));
      expect(
        frame.dayFor(const LocalDate(year: 2025, month: 3, day: 3)).total,
        300,
      );
      expect(
        frame.dayFor(const LocalDate(year: 2025, month: 4, day: 4)).kind,
        MindYearHeatmapTileKind.empty,
      );
    },
  );

  test(
    'RED MYH-08: empty, minimum and equal-range tiles stay deterministic',
    () {
      final empty = build(
        year: 2025,
        entries: const <DashboardLedgerEntry>[],
      ).preview(range(1, 1000));
      expect(
        empty.days.every((day) => day.kind == MindYearHeatmapTileKind.empty),
        isTrue,
      );

      final equal = build(
        year: 2025,
        entries: <DashboardLedgerEntry>[
          _entry('a', 250, const LocalDate(year: 2025, month: 5, day: 1)),
          _entry('b', 250, const LocalDate(year: 2025, month: 8, day: 1)),
        ],
      ).preview(range(1, 1000));
      expect(
        equal.dayFor(const LocalDate(year: 2025, month: 5, day: 1)).kind,
        MindYearHeatmapTileKind.equalRange,
      );
      expect(
        equal
            .dayFor(const LocalDate(year: 2025, month: 5, day: 1))
            .paletteIntensity,
        MindYearHeatmapPaletteIntensity.equalRange,
      );
    },
  );

  test('RED MYH-05: slider previews do not revisit source ledger rows', () {
    final counter = MindYearHeatmapSourceWorkCounter(
      measurePreviewDurations: true,
    );
    final projection = build(
      year: 2025,
      counter: counter,
      entries: List<DashboardLedgerEntry>.generate(
        12000,
        (index) => _entry(
          'row-$index',
          index % 1000 + 1,
          LocalDate(year: 2025, month: index % 12 + 1, day: index % 27 + 1),
        ),
        growable: false,
      ),
    );
    final sourceTouchesAfterBuild = counter.sourceRowTouches;

    for (var value = 1; value <= 20; value += 1) {
      projection.preview(range(value, 1000 - value));
    }

    expect(counter.sourceRowTouches, sourceTouchesAfterBuild);
    expect(counter.sourceRowTouchesDuringPreview, 0);
    expect(counter.repositoryAccessesDuringPreview, 0);
    expect(counter.indexBuildsDuringPreview, 0);
    expect(counter.maxDayBucketsVisitedPerPreview, lessThanOrEqualTo(365));
    final timing = counter.previewDurationSummary();
    expect(timing['sampleCount'], 20);
    expect(timing['p50Micros'], greaterThanOrEqualTo(0));
    expect(timing['p95Micros'], greaterThanOrEqualTo(timing['p50Micros']!));
    expect(timing['maxMicros'], greaterThanOrEqualTo(timing['p95Micros']!));
  });
}

DashboardLedgerEntry _entry(String id, int amount, LocalDate date) =>
    DashboardLedgerEntry(
      id: id,
      partnerId: 'partner',
      categoryId: 'food',
      direction: 'expense',
      amountMinor: amount,
      bookedLocalEpochDay: date.epochDay,
      bookedLocalTimeMinutes: 12 * 60,
    );

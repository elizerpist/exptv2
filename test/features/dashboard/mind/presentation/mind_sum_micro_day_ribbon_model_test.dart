import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_sum_micro_day_ribbon_model.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  test(
    'MDR-03 RED: a normal year packs exactly 365 real days into five continuous rows without a month-boundary gap',
    () {
      final model = MindSumMicroDayRibbonModel.fromFrame(
        _frameForYear(2025),
      ).year(2025);

      expect(model.cells, hasLength(365));
      expect(model.rowCount, 5);
      expect(model.totalMicroColumns, 79);
      expect(model.month(1).microColumnCount, 7);
      expect(model.month(2).microColumnCount, 6);
      expect(model.cellFor(month: 1, day: 31).column, 6);
      expect(model.cellFor(month: 2, day: 1).column, 7);

      final geometry = MindSumMicroDayRibbonGeometry.resolve(
        availableWidth: 316,
        totalMicroColumns: model.totalMicroColumns,
      );
      expect(
        geometry.horizontalGapBetween(column: 6, nextColumn: 7),
        closeTo(geometry.microGap, .0001),
      );
    },
  );

  test(
    'MDR-03 RED: leap February contributes day 29 but still has five rows',
    () {
      final model = MindSumMicroDayRibbonModel.fromFrame(
        _frameForYear(2024),
      ).year(2024);

      expect(model.cells, hasLength(366));
      expect(model.rowCount, 5);
      expect(
        model.cellFor(month: 2, day: 29).date,
        const LocalDate(year: 2024, month: 2, day: 29),
      );
      expect(() => model.cellFor(month: 2, day: 30), throwsRangeError);
    },
  );

  test(
    'MDR-04 RED: the ribbon uses slider-filtered daily points and live year total',
    () {
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'sum',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 1_000, const LocalDate(year: 2025, month: 1, day: 1)),
          _entry(1, 25_000, const LocalDate(year: 2025, month: 1, day: 1)),
          _entry(2, 50_000, const LocalDate(year: 2025, month: 3, day: 4)),
        ],
      );
      final full = MindSumMicroDayRibbonModel.fromFrame(
        projection.preview(_range(lower: 100, upper: 100_000)),
      ).year(2025);
      final narrowed = MindSumMicroDayRibbonModel.fromFrame(
        projection.preview(_range(lower: 20_000, upper: 100_000)),
      ).year(2025);

      expect(full.total, 76_000);
      expect(narrowed.total, 75_000);
      expect(full.cellFor(month: 1, day: 1).total, 26_000);
      expect(narrowed.cellFor(month: 1, day: 1).total, 25_000);
      expect(narrowed.cellFor(month: 1, day: 2).isEmpty, isTrue);
    },
  );
}

MindSumHeatmapFrame _frameForYear(int year) => MindSumHeatmapProjection.build(
  identity: MindTemporalHeatmapIdentity(
    upstreamScopeKey: 'expense',
    indexGeneration: 1,
    coreRevision: 1,
    timeScopeKey: '$year-sum',
  ),
  contributions: <MindYearHeatmapPreparedContribution>[
    for (var month = 1; month <= 12; month += 1)
      _entry(month, 1_000 + month, LocalDate(year: year, month: month, day: 1)),
  ],
).preview(_range(lower: 100, upper: 100_000));

MindYearHeatmapPreparedContribution _entry(
  int ordinal,
  int amount,
  LocalDate date,
) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  amountMinor: amount,
  bookedLocalEpochDay: date.epochDay,
);

QueryAmountRangeValues _range({required int lower, required int upper}) =>
    QueryAmountRangeValues(
      minimumScaled100: 100,
      maximumScaled100: 100_000,
      lowerScaled100: lower,
      upperScaled100: upper,
    );

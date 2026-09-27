import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_category_movers_presentation.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'MOVERS-WINDOWS-RED: every visible label is derived from actual current and reference windows',
    () {
      final historicalMonth = _presentation(
        scope: const MonthScope(YearMonth(year: 2025, month: 2)),
        current: _window(2025, 2, 1, 2025, 2, 28),
        reference: _window(2025, 1, 1, 2025, 1, 31),
      );
      expect(balanceCategoryMoverScopeLabel(historicalMonth), 'FEBR 2025');
      expect(
        balanceCategoryMoverLegendLabels(historicalMonth).current,
        'Február 2025',
      );

      final monthToDate = _presentation(
        scope: const MonthScope(YearMonth(year: 2026, month: 9)),
        current: _window(2026, 9, 1, 2026, 9, 27),
        reference: _window(2026, 8, 1, 2026, 8, 27),
      );
      expect(balanceCategoryMoverScopeLabel(monthToDate), 'SZEPT 2026');
      expect(
        balanceCategoryMoverLegendLabels(monthToDate).current,
        'Szept. 1–27.',
      );
      expect(
        balanceCategoryMoverLegendLabels(monthToDate).reference,
        'Aug. 1–27.',
      );

      final historicalYear = _presentation(
        scope: const YearScope(2024),
        current: _window(2024, 1, 1, 2024, 12, 31),
        reference: _window(2023, 1, 1, 2023, 12, 31),
      );
      expect(balanceCategoryMoverLegendLabels(historicalYear).current, '2024');
      expect(
        balanceCategoryMoverLegendLabels(historicalYear).reference,
        '2023',
      );

      final currentYear = _presentation(
        scope: const YearScope(2026),
        current: _window(2026, 1, 1, 2026, 9, 27),
        reference: _window(2025, 1, 1, 2025, 9, 27),
      );
      expect(balanceCategoryMoverLegendLabels(currentYear).current, '2026 YTD');
      expect(
        balanceCategoryMoverLegendLabels(currentYear).reference,
        '2025 azonos időszak',
      );

      final allTime = _presentation(
        scope: const AllTimeScope(),
        current: _window(2026, 1, 1, 2026, 9, 27),
        reference: _window(2025, 1, 1, 2025, 9, 27),
      );
      expect(balanceCategoryMoverLegendLabels(allTime).current, '2026 YTD');

      final day = _presentation(
        scope: const DayScope(LocalDate(year: 2026, month: 9, day: 27)),
        current: _window(2026, 9, 27, 2026, 9, 27),
        reference: _window(2026, 9, 26, 2026, 9, 26),
      );
      expect(balanceCategoryMoverLegendLabels(day).current, '2026. szept. 27.');
      expect(
        balanceCategoryMoverLegendLabels(day).reference,
        '2026. szept. 26.',
      );
      expect(
        balanceCategoryMoverWindowLabel(day.currentWindow),
        '2026. szept. 27.',
      );
    },
  );

  test('MOVERS-CUMULATIVE-RED: chart values are cumulative before paint', () {
    final series = balanceCategoryMoverCumulativeSeries(
      const <DashboardBalanceCategoryMoverTrendPoint>[
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 1,
          currentMinor: 100,
          referenceMinor: 50,
        ),
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 2,
          currentMinor: 0,
          referenceMinor: 0,
        ),
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 3,
          currentMinor: 200,
          referenceMinor: 70,
        ),
      ],
    );

    expect(series.currentMinor, <int>[100, 100, 300]);
    expect(series.referenceMinor, <int>[50, 50, 120]);
    expect(series.currentTotalMinor, 300);
    expect(series.referenceTotalMinor, 120);
  });
}

DashboardBalanceCategoryMoversPresentation _presentation({
  required LedgerTimeScope scope,
  required DashboardBalanceCategoryComparisonWindow current,
  required DashboardBalanceCategoryComparisonWindow reference,
}) => DashboardBalanceCategoryMoversPresentation(
  identity: const DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'test',
    indexGeneration: 1,
    coreRevision: 1,
  ),
  timeScope: scope,
  selectedDirection: LedgerDirection.expense,
  logicalAsOfDate: current.endInclusive,
  currentWindow: current,
  referenceWindow: reference,
  movers: const <DashboardBalanceCategoryMover>[],
);

DashboardBalanceCategoryComparisonWindow _window(
  int startYear,
  int startMonth,
  int startDay,
  int endYear,
  int endMonth,
  int endDay,
) => DashboardBalanceCategoryComparisonWindow(
  startInclusive: LocalDate(year: startYear, month: startMonth, day: startDay),
  endInclusive: LocalDate(year: endYear, month: endMonth, day: endDay),
);

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/balance_daily_calculation_mode.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_header_context_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final rows = <(int, int, int, int, int)>[
    (2023, 12, 31, 10000, 1000),
    (2024, 1, 1, 2000, 100),
    (2024, 2, 1, 3000, 200),
    (2024, 2, 12, 45000, 0),
    (2024, 2, 15, 0, 18000),
    (2024, 2, 29, 1000, 500),
    (2024, 3, 1, 9000, 800),
    (2025, 1, 1, 7000, 900),
  ];
  var income = 0;
  var expense = 0;
  final points = <DashboardBalanceHistoryPoint>[];
  for (final (y, m, d, i, e) in rows) {
    income += i;
    expense += e;
    final day = LocalDate(year: y, month: m, day: d).epochDay;
    points.add(
      DashboardBalanceHistoryPoint(
        entryId: '$y-$m-$d',
        epochDay: day,
        epochMinute: day * 1440 + 600,
        incomeTotalMinor: income,
        expenseTotalMinor: expense,
        balanceMinor: income - expense,
      ),
    );
  }
  final source = DashboardBalancePresentation(
    scopeKey: 'query',
    coreRevision: 7,
    incomeTotalMinor: income,
    expenseTotalMinor: expense,
    netTotalMinor: income - expense,
    formattedNetTotal: 'total',
    presentationId: 42,
    history: DashboardBalanceHistorySeries(
      startInclusiveEpochMinute: points.first.epochMinute,
      endInclusiveEpochMinute: points.last.epochMinute,
      points: points,
    ),
  );
  final projection = DashboardBalanceHeaderContextProjection();
  DashboardBalanceHeaderContextPresentation read(
    LedgerTimeScope scope, [
    BalanceDailyCalculationMode mode = BalanceDailyCalculationMode.monthToDate,
  ]) => projection.project(
    source: source,
    fallbackScope: scope,
    dailyCalculationMode: mode,
  )!;
  DayScope day(int y, int m, int d) =>
      DayScope(LocalDate(year: y, month: m, day: d));
  void expectTotals(
    DashboardBalanceHeaderContextPresentation result,
    int i,
    int e,
  ) {
    expect(result.incomeTotalMinor, i);
    expect(result.expenseTotalMinor, e);
    expect(result.netTotalMinor, i - e);
    expect(result.coreRevision, 7);
    expect(result.scopeKey, 'query');
  }

  test('SUM independent of earlier temporal selection', () {
    read(day(2024, 2, 15));
    expectTotals(read(const AllTimeScope()), income, expense);
  });
  test('year and month subtract opening cumulative flows separately', () {
    expectTotals(read(const YearScope(2024)), 60000, 19600);
    expectTotals(
      read(const MonthScope(YearMonth(year: 2024, month: 2))),
      49000,
      18700,
    );
  });
  test('month-to-date carries income across empty and expense-only days', () {
    expectTotals(read(day(2024, 2, 13)), 48000, 200);
    expectTotals(read(day(2024, 2, 15)), 48000, 18200);
    expectTotals(read(day(2024, 2, 16)), 48000, 18200);
  });
  test(
    'all-time-to-date includes opening history, excludes later transactions',
    () {
      expectTotals(
        read(day(2024, 2, 15), BalanceDailyCalculationMode.allTimeToDate),
        60000,
        19300,
      );
      expectTotals(
        read(day(2024, 2, 16), BalanceDailyCalculationMode.allTimeToDate),
        60000,
        19300,
      );
      expectTotals(
        read(day(2023, 1, 1), BalanceDailyCalculationMode.allTimeToDate),
        0,
        0,
      );
    },
  );
  test('month first day, leap last day and month transition', () {
    expectTotals(read(day(2024, 2, 1)), 3000, 200);
    final last = read(day(2024, 2, 29));
    final month = read(const MonthScope(YearMonth(year: 2024, month: 2)));
    expect(last.netTotalMinor, month.netTotalMinor);
    expect(last.incomeTotalMinor, month.incomeTotalMinor);
    expect(last.expenseTotalMinor, month.expenseTotalMinor);
    expectTotals(read(day(2024, 3, 1)), 9000, 800);
  });
  test('year transition resets MTD but never all-time-to-date', () {
    expectTotals(read(day(2025, 1, 1)), 7000, 900);
    expectTotals(
      read(day(2025, 1, 1), BalanceDailyCalculationMode.allTimeToDate),
      income,
      expense,
    );
  });
  test(
    'accepted publication scope wins over pending navigation and memoizes',
    () {
      final accepted = source.copyWith(headerTimeScope: day(2024, 2, 15));
      final a = projection.project(
        source: accepted,
        fallbackScope: const YearScope(2025),
        dailyCalculationMode: BalanceDailyCalculationMode.monthToDate,
      )!;
      expectTotals(a, 48000, 18200);
      final b = projection.project(
        source: accepted,
        fallbackScope: const AllTimeScope(),
        dailyCalculationMode: BalanceDailyCalculationMode.monthToDate,
      );
      expect(identical(a, b), isTrue);
      final c = projection.project(
        source: accepted,
        fallbackScope: const AllTimeScope(),
        dailyCalculationMode: BalanceDailyCalculationMode.allTimeToDate,
      )!;
      expectTotals(c, 60000, 19300);
      expect(c.timeScope, a.timeScope);
    },
  );
  test(
    'unavailable history does not fabricate scoped zero; empty source can',
    () {
      final incomplete = DashboardBalancePresentation(
        scopeKey: 'q',
        coreRevision: 8,
        incomeTotalMinor: 100,
        expenseTotalMinor: 0,
        netTotalMinor: 100,
        formattedNetTotal: '1 Ft',
        presentationId: 8,
      );
      expect(
        projection.project(
          source: incomplete,
          fallbackScope: day(2024, 2, 1),
          dailyCalculationMode: BalanceDailyCalculationMode.monthToDate,
        ),
        isNull,
      );
      final empty = incomplete.copyWith(
        incomeTotalMinor: 0,
        netTotalMinor: 0,
        presentationId: 9,
      );
      expect(
        projection
            .project(
              source: empty,
              fallbackScope: day(2024, 2, 1),
              dailyCalculationMode: BalanceDailyCalculationMode.monthToDate,
            )!
            .netTotalMinor,
        0,
      );
    },
  );
}

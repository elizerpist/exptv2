import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_year_focused_chart_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  BalanceAlternativeIncomeExpenseBarPresentation source() =>
      BalanceAlternativeIncomeExpenseBarPresentation(
        domain: BalanceAlternativeBarDomain.months,
        groups: [
          for (var month = 1; month <= 12; month++)
            BalanceAlternativeIncomeExpenseBarGroup(
              key: month,
              label: '$month',
              incomeMinor: month == 1
                  ? 100
                  : month == 2
                  ? 20
                  : month == 12
                  ? 30
                  : 0,
              expenseMinor: month == 1
                  ? 10
                  : month == 2
                  ? 20
                  : month == 3
                  ? 40
                  : 0,
            ),
        ],
        incomeTotalMinor: 150,
        expenseTotalMinor: 70,
        sourcePresentationId: 42,
      );

  test('all perspectives share exact monthly totals and year-local prefix', () {
    final model = BalanceYearFocusedChartPresentation.fromIncomeExpense(
      source(),
      year: 2025,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 1),
      transactionCounts: {
        for (var month = 1; month <= 12; month++)
          month: month < 4 || month == 12 ? 1 : 0,
      },
    );
    expect(model.months.length, 12);
    expect(model.months.map((point) => point.cumulativeNetMinor).take(4), [
      90,
      90,
      50,
      50,
    ]);
    expect(model.months.last.cumulativeNetMinor, model.annualNetMinor);
    expect(model.annualIncomeMinor, 150);
    expect(model.annualExpenseMinor, 70);
    expect(model.annualNetMinor, 80);
    expect(model.months[1].availability, BalanceYearMonthAvailability.recorded);
    expect(model.months[3].availability, BalanceYearMonthAvailability.noData);
    expect(model.closedMonthCount, 12);
    expect(model.positiveClosedMonthCount, 2);
    expect(model.bestMonth?.month, 1);
    expect(model.maxAbsNetMinor, 90);
    expect(model.maximumFlowMinor, 100);
    expect(model.minCumulativeNetMinor, 0);
    expect(model.maxCumulativeNetMinor, 90);
    expect(() => model.months.clear(), throwsUnsupportedError);
  });

  test(
    'current and future periods are explicit, booked future flows remain real',
    () {
      final model = BalanceYearFocusedChartPresentation.fromIncomeExpense(
        source(),
        year: 2026,
        logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 15),
        transactionCounts: {
          for (var month = 1; month <= 12; month++)
            month: month < 4 || month == 12 ? 1 : 0,
        },
      );
      expect(model.closedMonthCount, 3);
      expect(model.positiveClosedMonthCount, 1);
      expect(
        model.months[3].availability,
        BalanceYearMonthAvailability.current,
      );
      expect(model.months[4].availability, BalanceYearMonthAvailability.future);
      expect(model.months.last.isFuture, isTrue);
      expect(model.months.last.hasRecordedTransactions, isTrue);
      expect(model.months.last.hasCumulativeClose, isFalse);
      expect(model.annualNetMinor, 80);
      expect(model.months.last.cumulativeNetMinor, 80);
    },
  );

  test('unknown calendar metadata does not invent closed or future months', () {
    final model = BalanceYearFocusedChartPresentation.fromIncomeExpense(
      source(),
      year: 2026,
    );
    expect(model.closedMonthCount, 0);
    expect(model.bestMonth, isNull);
    expect(model.months[3].availability, BalanceYearMonthAvailability.unknown);
    expect(model.months.every((point) => !point.isFuture), isTrue);
  });

  test('explicit zero transactions differ from absent transactions', () {
    const pair = DashboardBalancePrimaryPeriodPair(
      value: 1,
      incomeMinor: 0,
      expenseMinor: 0,
      transactionCount: 1,
    );
    expect(pair.transactionCount, 1);
    final model = BalanceYearFocusedChartPresentation.fromIncomeExpense(
      source(),
      year: 2025,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 1),
      transactionCounts: {4: 1, 5: 0},
    );
    expect(model.months[3].availability, BalanceYearMonthAvailability.recorded);
    expect(model.months[4].availability, BalanceYearMonthAvailability.noData);
  });
}

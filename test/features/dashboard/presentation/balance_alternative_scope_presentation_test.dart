import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 3,
    coreRevision: 7,
  );

  test('ALT2-01: scope adapter routes canonical SUM and YEAR bar payloads', () {
    final sum = BalanceAlternativeScopePresentation.fromPrimary(
      DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: const AllTimeScope(),
        mode: DashboardBalancePrimaryMode.sum,
        incomeTotalMinor: 600000,
        expenseTotalMinor: 380000,
        periodPairs: const <DashboardBalancePrimaryPeriodPair>[
          DashboardBalancePrimaryPeriodPair(
            value: 2024,
            incomeMinor: 200000,
            expenseMinor: 120000,
          ),
          DashboardBalancePrimaryPeriodPair(
            value: 2026,
            incomeMinor: 400000,
            expenseMinor: 260000,
          ),
        ],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
      ),
    );
    expect(sum, isA<BalanceAlternativeSumPresentation>());
    final sumChart = (sum as BalanceAlternativeSumPresentation).incomeExpense;
    expect(sumChart.domain, BalanceAlternativeBarDomain.years);
    expect(sumChart.groups.map((group) => group.key), <int>[2024, 2026]);
    expect(sumChart.groups.map((group) => group.label), <String>[
      '2024',
      '2026',
    ]);
    expect(sumChart.incomeTotalMinor, 600000);
    expect(sumChart.expenseTotalMinor, 380000);
    expect(sumChart.netTotalMinor, 220000);

    final year = BalanceAlternativeScopePresentation.fromPrimary(
      DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: const YearScope(2026),
        mode: DashboardBalancePrimaryMode.year,
        incomeTotalMinor: 780000,
        expenseTotalMinor: 330000,
        periodPairs: <DashboardBalancePrimaryPeriodPair>[
          for (var month = 1; month <= 12; month += 1)
            DashboardBalancePrimaryPeriodPair(
              value: month,
              incomeMinor: month == 12 ? 90000 : 0,
              expenseMinor: month == 1 ? 40000 : 0,
            ),
        ],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
      ),
    );
    expect(year, isA<BalanceAlternativeYearPresentation>());
    final yearChart =
        (year as BalanceAlternativeYearPresentation).incomeExpense;
    expect(yearChart.domain, BalanceAlternativeBarDomain.months);
    expect(yearChart.groups, hasLength(12));
    expect(
      yearChart.groups.map((group) => group.key),
      List<int>.generate(12, (index) => index + 1),
    );
    expect(yearChart.groups.map((group) => group.label), <String>[
      'JAN',
      'FEB',
      'MÁR',
      'ÁPR',
      'MÁJ',
      'JÚN',
      'JÚL',
      'AUG',
      'SZE',
      'OKT',
      'NOV',
      'DEC',
    ]);
    expect(yearChart.groups[5].incomeMinor, 0);
    expect(yearChart.groups[5].expenseMinor, 0);
  });

  test(
    'ALT2-01: Month and Day have independent alternative presentation types',
    () {
      final month = BalanceAlternativeScopePresentation.fromPrimary(
        DashboardBalancePrimaryPresentation(
          identity: identity,
          timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
          mode: DashboardBalancePrimaryMode.month,
          incomeTotalMinor: 0,
          expenseTotalMinor: 0,
          periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
          dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
        ),
      );
      final day = BalanceAlternativeScopePresentation.fromPrimary(
        DashboardBalancePrimaryPresentation(
          identity: identity,
          timeScope: DayScope(const LocalDate(year: 2026, month: 8, day: 7)),
          mode: DashboardBalancePrimaryMode.unsupportedDay,
          incomeTotalMinor: 0,
          expenseTotalMinor: 0,
          periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
          dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
        ),
      );
      expect(month, isA<BalanceAlternativeMonthPresentation>());
      expect(day, isA<BalanceAlternativeDayPresentation>());
    },
  );
}

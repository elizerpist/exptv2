import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

const identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 3,
  coreRevision: 7,
);

void main() {
  test(
    'ALT2-01: primary-only scope adapter retains an empty SUM distribution fallback',
    () {
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
      final sumPresentation = sum as BalanceAlternativeSumPresentation;
      expect(sumPresentation.distribution.histogram.sampleCount, 0);
      expect(sumPresentation.savings.netMinor, 220000);
      expect(
        sumPresentation.savings.retentionBasisPoints,
        3667,
        reason:
            'A primary-only scope still has a resident income/expense ratio, so the Budget 3D savings ring must receive a real progress value.',
      );

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
    },
  );

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

  test(
    'ALT-HAVI2-RED: Month mixed presentation derives daily expense, no-spend, retention, and prior-month comparison from linked DTOs',
    () {
      final alternative =
          BalanceAlternativeScopePresentation.fromLinked(_linkedMonth())
              as BalanceAlternativeMonthPresentation;

      expect(
        alternative.dailySpend.points.map((point) => point.expenseMinor),
        <int>[10000, 0, 25000, 0],
      );
      expect(alternative.dailySpend.noSpendDayCount, 2);
      expect(alternative.dailySpend.previousExpenseMinor, 80000);
      expect(alternative.dailySpend.expenseChangeBasisPoints, -4375);
      expect(alternative.savings.retentionBasisPoints, 7750);
      expect(alternative.incomeExpense.incomeMinor, 200000);
      expect(alternative.incomeExpense.expenseMinor, 45000);
    },
  );

  test(
    'ALT-EVES-RED: Year alternative derives closing buckets and the selected real savings value from linked DTOs',
    () {
      final alternative =
          BalanceAlternativeScopePresentation.fromLinked(_linkedYear())
              as BalanceAlternativeYearPresentation;

      expect(alternative.closings.buckets, hasLength(12));
      expect(alternative.closings.buckets[0].netMinor, 50000);
      expect(alternative.closings.buckets[1].netMinor, -30000);
      expect(alternative.closings.positiveBucketCount, 1);
      expect(alternative.savings.netMinor, 20000);
      expect(alternative.incomeExpense.groups, hasLength(12));
    },
  );

  test(
    'SUM-ADAPTER: linked SUM maps its established stability sample, savings and distribution without a second ledger query',
    () {
      final alternative =
          BalanceAlternativeScopePresentation.fromLinked(_linkedSum())
              as BalanceAlternativeSumPresentation;

      expect(alternative.stability.sampleCount, 8);
      expect(alternative.distribution.histogram.sampleCount, 8);
      expect(alternative.distribution.histogram.assignedSampleCount, 8);
      expect(alternative.distribution.longestPositiveStreak.length, 3);
      expect(alternative.savings.retentionBasisPoints, 6250);
      expect(alternative.savings.netMinor, 250000);
    },
  );

  test(
    'ALT-HTML-RED: shared logical tokens are calculated from Havi 2 CSS',
    () {
      expect(BalanceAlternativeHtmlTokens.logical(26.73), closeTo(12, .001));
      expect(BalanceAlternativeHtmlTokens.logical(6.68), closeTo(3, .002));
      expect(
        BalanceAlternativeHtmlTokens.dailyCardPadding.left,
        closeTo(BalanceAlternativeHtmlTokens.logical(24), .001),
      );
      expect(
        BalanceAlternativeHtmlTokens.childBorderRadius,
        closeTo(BalanceAlternativeHtmlTokens.logical(25), .001),
      );
    },
  );
}

DashboardBalanceLinkedPresentation _linkedMonth() =>
    DashboardBalanceLinkedPresentation(
      identity: identity,
      timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
      selectedDirection: LedgerDirection.expense,
      cashflow: DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
        mode: DashboardBalancePrimaryMode.month,
        incomeTotalMinor: 200000,
        expenseTotalMinor: 45000,
        periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[
          DashboardBalancePrimaryDayPoint(
            day: 1,
            incomeMinor: 0,
            expenseMinor: 10000,
          ),
          DashboardBalancePrimaryDayPoint(
            day: 2,
            incomeMinor: 0,
            expenseMinor: 10000,
          ),
          DashboardBalancePrimaryDayPoint(
            day: 3,
            incomeMinor: 0,
            expenseMinor: 35000,
          ),
          DashboardBalancePrimaryDayPoint(
            day: 4,
            incomeMinor: 200000,
            expenseMinor: 35000,
          ),
        ],
      ),
      closings: DashboardBalanceClosingsPresentation(
        identity: identity,
        timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
        buckets: const <DashboardBalanceClosingBucket>[],
      ),
      retention: DashboardBalanceRetentionPresentation(
        identity: identity,
        timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
        periods: const <DashboardBalanceRetentionPeriod>[
          DashboardBalanceRetentionPeriod(
            id: 'month:2026-2',
            label: '2026 FEB',
            incomeMinor: 150000,
            expenseMinor: 80000,
            state: DashboardBalanceRetentionState.value,
            selected: false,
            retentionBasisPoints: 4667,
          ),
          DashboardBalanceRetentionPeriod(
            id: 'month:2026-3',
            label: '2026 MÁR',
            incomeMinor: 200000,
            expenseMinor: 45000,
            state: DashboardBalanceRetentionState.value,
            selected: true,
            retentionBasisPoints: 7750,
          ),
        ],
      ),
      latestTransactions: const <DashboardBalanceScopedTransaction>[],
      topCategories: const <DashboardBalanceRankedItem>[],
      topPartners: const <DashboardBalanceRankedItem>[],
    );

DashboardBalanceLinkedPresentation _linkedYear() =>
    DashboardBalanceLinkedPresentation(
      identity: identity,
      timeScope: const YearScope(2026),
      selectedDirection: LedgerDirection.expense,
      cashflow: DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: const YearScope(2026),
        mode: DashboardBalancePrimaryMode.year,
        incomeTotalMinor: 120000,
        expenseTotalMinor: 100000,
        periodPairs: <DashboardBalancePrimaryPeriodPair>[
          for (var month = 1; month <= 12; month += 1)
            DashboardBalancePrimaryPeriodPair(
              value: month,
              incomeMinor: month == 1 ? 80000 : 0,
              expenseMinor: month == 2 ? 30000 : 0,
            ),
        ],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
      ),
      closings: DashboardBalanceClosingsPresentation(
        identity: identity,
        timeScope: const YearScope(2026),
        buckets: <DashboardBalanceClosingBucket>[
          const DashboardBalanceClosingBucket(
            id: 'month:2026-1',
            label: 'JAN',
            incomeMinor: 80000,
            expenseMinor: 30000,
          ),
          const DashboardBalanceClosingBucket(
            id: 'month:2026-2',
            label: 'FEB',
            incomeMinor: 0,
            expenseMinor: 30000,
          ),
          for (var month = 3; month <= 12; month += 1)
            DashboardBalanceClosingBucket(
              id: 'month:2026-$month',
              label: '$month',
              incomeMinor: 0,
              expenseMinor: 0,
            ),
        ],
      ),
      retention: DashboardBalanceRetentionPresentation(
        identity: identity,
        timeScope: const YearScope(2026),
        periods: const <DashboardBalanceRetentionPeriod>[
          DashboardBalanceRetentionPeriod(
            id: 'year:2026',
            label: '2026',
            incomeMinor: 120000,
            expenseMinor: 100000,
            state: DashboardBalanceRetentionState.value,
            selected: true,
            retentionBasisPoints: 1667,
          ),
        ],
      ),
      latestTransactions: const <DashboardBalanceScopedTransaction>[],
      topCategories: const <DashboardBalanceRankedItem>[],
      topPartners: const <DashboardBalanceRankedItem>[],
    );

DashboardBalanceLinkedPresentation _linkedSum() =>
    DashboardBalanceLinkedPresentation(
      identity: identity,
      timeScope: const AllTimeScope(),
      selectedDirection: LedgerDirection.expense,
      cashflow: DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: const AllTimeScope(),
        mode: DashboardBalancePrimaryMode.sum,
        incomeTotalMinor: 400000,
        expenseTotalMinor: 150000,
        periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
      ),
      retention: DashboardBalanceRetentionPresentation(
        identity: identity,
        timeScope: const AllTimeScope(),
        periods: const <DashboardBalanceRetentionPeriod>[
          DashboardBalanceRetentionPeriod(
            id: 'all',
            label: 'Összesen',
            incomeMinor: 400000,
            expenseMinor: 150000,
            state: DashboardBalanceRetentionState.value,
            selected: true,
            retentionBasisPoints: 6250,
          ),
        ],
      ),
      stability: DashboardBalanceStabilityPresentation(
        identity: identity,
        timeScope: const AllTimeScope(),
        observations: <DashboardBalanceMonthlyNetObservation>[
          for (final (index, net) in <int>[
            -10,
            20,
            30,
            40,
            0,
            10,
            20,
            -5,
          ].indexed)
            DashboardBalanceMonthlyNetObservation(
              id: 'month:$index',
              label: '2024 M$index',
              month: YearMonth(year: 2024, month: index + 1),
              incomeMinor: net > 0 ? net : 0,
              expenseMinor: net < 0 ? -net : 0,
            ),
        ],
        medianNetTimesTwo: 30,
        typicalDeviationTimesTwo: 35,
      ),
      latestTransactions: const <DashboardBalanceScopedTransaction>[],
      topCategories: const <DashboardBalanceRankedItem>[],
      topPartners: const <DashboardBalanceRankedItem>[],
    );

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../application/dashboard_balance_monthly_net_distribution_projection.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_balance_retention_stability_projection.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

/// Render-only adapter boundary for the scope-specific alternative Balance
/// dashboard. It intentionally copies only immutable values that established
/// Balance linked projections already prepared.
sealed class BalanceAlternativeScopePresentation {
  const BalanceAlternativeScopePresentation({
    required this.timeScope,
    required this.sourcePresentationId,
  });

  final LedgerTimeScope timeScope;
  final int sourcePresentationId;

  factory BalanceAlternativeScopePresentation.fromPrimary(
    DashboardBalancePrimaryPresentation primary,
  ) => switch (primary.timeScope) {
    AllTimeScope() => () {
      final stability = _unavailableStability(
        identity: primary.identity,
        timeScope: primary.timeScope,
      );
      return BalanceAlternativeSumPresentation(
        timeScope: primary.timeScope,
        sourcePresentationId: primary.presentationId,
        stability: stability,
        distribution: DashboardBalanceMonthlyNetDistributionProjection.build(
          stability: stability,
        ),
        savings: BalanceAlternativeSavingsPresentation.fromTotals(
          incomeMinor: primary.incomeTotalMinor,
          expenseMinor: primary.expenseTotalMinor,
          retentionBasisPoints: null,
        ),
      );
    }(),
    YearScope() => BalanceAlternativeYearPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
      incomeExpense: BalanceAlternativeIncomeExpenseBarPresentation.fromPrimary(
        primary,
        domain: BalanceAlternativeBarDomain.months,
      ),
      closings: BalanceAlternativeYearClosingsPresentation.fromPeriodPairs(
        primary.periodPairs,
      ),
      savings: BalanceAlternativeSavingsPresentation.fromTotals(
        incomeMinor: primary.incomeTotalMinor,
        expenseMinor: primary.expenseTotalMinor,
        retentionBasisPoints: null,
      ),
    ),
    MonthScope() => BalanceAlternativeMonthPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
      dailySpend: BalanceAlternativeMonthlySpendPresentation.fromPrimary(
        primary,
      ),
      savings: BalanceAlternativeSavingsPresentation.fromTotals(
        incomeMinor: primary.incomeTotalMinor,
        expenseMinor: primary.expenseTotalMinor,
        retentionBasisPoints: null,
      ),
      incomeExpense:
          BalanceAlternativeIncomeExpenseStripPresentation.fromPrimary(primary),
    ),
    DayScope() => BalanceAlternativeDayPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
      dailyInsights: DashboardBalanceDailyInsightsPresentation.unavailable(
        identity: primary.identity,
        timeScope: primary.timeScope,
      ),
    ),
  };

  /// Uses the established linked immutable presentation without introducing a
  /// new financial projection. Only render-ready values cross this boundary.
  factory BalanceAlternativeScopePresentation.fromLinked(
    DashboardBalanceLinkedPresentation linked,
  ) => switch (linked.timeScope) {
    AllTimeScope() => BalanceAlternativeSumPresentation(
      timeScope: linked.timeScope,
      sourcePresentationId: linked.presentationId,
      stability: linked.stability,
      distribution: DashboardBalanceMonthlyNetDistributionProjection.build(
        stability: linked.stability,
      ),
      savings: BalanceAlternativeSavingsPresentation.fromRetention(
        linked.retention,
        fallbackIncomeMinor: linked.cashflow.incomeTotalMinor,
        fallbackExpenseMinor: linked.cashflow.expenseTotalMinor,
      ),
    ),
    YearScope() => BalanceAlternativeYearPresentation(
      timeScope: linked.timeScope,
      sourcePresentationId: linked.presentationId,
      incomeExpense: BalanceAlternativeIncomeExpenseBarPresentation.fromPrimary(
        linked.cashflow,
        domain: BalanceAlternativeBarDomain.months,
      ),
      closings: BalanceAlternativeYearClosingsPresentation.fromClosings(
        linked.closings,
      ),
      savings: BalanceAlternativeSavingsPresentation.fromRetention(
        linked.retention,
        fallbackIncomeMinor: linked.cashflow.incomeTotalMinor,
        fallbackExpenseMinor: linked.cashflow.expenseTotalMinor,
      ),
    ),
    MonthScope() => () {
      final selectedIndex = linked.retention.periods.indexWhere(
        (period) => period.selected,
      );
      final previousExpenseMinor = selectedIndex > 0
          ? linked.retention.periods[selectedIndex - 1].expenseMinor
          : null;
      return BalanceAlternativeMonthPresentation(
        timeScope: linked.timeScope,
        sourcePresentationId: linked.presentationId,
        dailySpend: BalanceAlternativeMonthlySpendPresentation.fromPrimary(
          linked.cashflow,
          previousExpenseMinor: previousExpenseMinor,
        ),
        savings: BalanceAlternativeSavingsPresentation.fromRetention(
          linked.retention,
          fallbackIncomeMinor: linked.cashflow.incomeTotalMinor,
          fallbackExpenseMinor: linked.cashflow.expenseTotalMinor,
        ),
        incomeExpense:
            BalanceAlternativeIncomeExpenseStripPresentation.fromPrimary(
              linked.cashflow,
            ),
      );
    }(),
    DayScope() => BalanceAlternativeDayPresentation(
      timeScope: linked.timeScope,
      sourcePresentationId: linked.presentationId,
      dailyInsights: linked.dailyInsights,
    ),
  };

  static DashboardBalanceStabilityPresentation _unavailableStability({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
  }) => DashboardBalanceStabilityPresentation(
    identity: identity,
    timeScope: timeScope,
    observations: const <DashboardBalanceMonthlyNetObservation>[],
    medianNetTimesTwo: null,
    typicalDeviationTimesTwo: null,
  );
}

final class BalanceAlternativeSumPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeSumPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.stability,
    required this.distribution,
    required this.savings,
  });

  final DashboardBalanceStabilityPresentation stability;
  final DashboardBalanceMonthlyNetDistributionPresentation distribution;
  final BalanceAlternativeSavingsPresentation savings;
}

final class BalanceAlternativeYearPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeYearPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.incomeExpense,
    required this.closings,
    required this.savings,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation incomeExpense;
  final BalanceAlternativeYearClosingsPresentation closings;
  final BalanceAlternativeSavingsPresentation savings;
}

final class BalanceAlternativeMonthPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeMonthPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.dailySpend,
    required this.savings,
    required this.incomeExpense,
  });

  final BalanceAlternativeMonthlySpendPresentation dailySpend;
  final BalanceAlternativeSavingsPresentation savings;
  final BalanceAlternativeIncomeExpenseStripPresentation incomeExpense;
}

final class BalanceAlternativeDayPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeDayPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.dailyInsights,
  });

  final DashboardBalanceDailyInsightsPresentation dailyInsights;
}

enum BalanceAlternativeBarDomain { years, months }

@immutable
final class BalanceAlternativeIncomeExpenseBarPresentation {
  BalanceAlternativeIncomeExpenseBarPresentation({
    required this.domain,
    required List<BalanceAlternativeIncomeExpenseBarGroup> groups,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required this.sourcePresentationId,
  }) : groups = List<BalanceAlternativeIncomeExpenseBarGroup>.unmodifiable(
         groups,
       );

  factory BalanceAlternativeIncomeExpenseBarPresentation.fromPrimary(
    DashboardBalancePrimaryPresentation primary, {
    required BalanceAlternativeBarDomain domain,
  }) {
    assert(
      (domain == BalanceAlternativeBarDomain.years &&
              primary.timeScope is AllTimeScope) ||
          (domain == BalanceAlternativeBarDomain.months &&
              primary.timeScope is YearScope),
      'The alternative Card 3 domain must match the canonical time scope.',
    );
    final groups = <BalanceAlternativeIncomeExpenseBarGroup>[
      for (final pair in primary.periodPairs)
        BalanceAlternativeIncomeExpenseBarGroup(
          key: pair.value,
          label: switch (domain) {
            BalanceAlternativeBarDomain.years => '${pair.value}',
            BalanceAlternativeBarDomain.months =>
              _monthLabels[pair.value.clamp(1, 12) - 1],
          },
          incomeMinor: pair.incomeMinor,
          expenseMinor: pair.expenseMinor,
        ),
    ];
    if (domain == BalanceAlternativeBarDomain.months) {
      assert(
        groups.length == 12 &&
            groups.asMap().entries.every(
              (entry) => entry.value.key == entry.key + 1,
            ),
        'The canonical YEAR projection must retain every calendar month.',
      );
    }
    return BalanceAlternativeIncomeExpenseBarPresentation(
      domain: domain,
      groups: groups,
      incomeTotalMinor: primary.incomeTotalMinor,
      expenseTotalMinor: primary.expenseTotalMinor,
      sourcePresentationId: primary.presentationId,
    );
  }

  final BalanceAlternativeBarDomain domain;
  final List<BalanceAlternativeIncomeExpenseBarGroup> groups;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  final int sourcePresentationId;

  int get netTotalMinor => incomeTotalMinor - expenseTotalMinor;

  int get maximumMinor => groups.fold<int>(
    0,
    (maximum, group) =>
        math.max(maximum, math.max(group.incomeMinor, group.expenseMinor)),
  );
}

@immutable
final class BalanceAlternativeIncomeExpenseBarGroup {
  const BalanceAlternativeIncomeExpenseBarGroup({
    required this.key,
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final int key;
  final String label;
  final int incomeMinor;
  final int expenseMinor;
}

/// One point in Havi 2's daily expense line. Values are individual daily
/// expenses, derived by differencing the already cumulative primary points.
@immutable
final class BalanceAlternativeDailySpendPoint {
  const BalanceAlternativeDailySpendPoint({
    required this.day,
    required this.expenseMinor,
  });

  final int day;
  final int expenseMinor;
}

@immutable
final class BalanceAlternativeMonthlySpendPresentation {
  BalanceAlternativeMonthlySpendPresentation({
    required List<BalanceAlternativeDailySpendPoint> points,
    required this.currentExpenseMinor,
    required this.previousExpenseMinor,
  }) : points = List<BalanceAlternativeDailySpendPoint>.unmodifiable(points);

  factory BalanceAlternativeMonthlySpendPresentation.fromPrimary(
    DashboardBalancePrimaryPresentation primary, {
    int? previousExpenseMinor,
  }) {
    var priorCumulativeExpense = 0;
    final points = <BalanceAlternativeDailySpendPoint>[
      for (final point in primary.dailyPoints)
        () {
          final expense = math.max(
            0,
            point.expenseMinor - priorCumulativeExpense,
          );
          priorCumulativeExpense = point.expenseMinor;
          return BalanceAlternativeDailySpendPoint(
            day: point.day,
            expenseMinor: expense,
          );
        }(),
    ];
    return BalanceAlternativeMonthlySpendPresentation(
      points: points,
      currentExpenseMinor: primary.expenseTotalMinor,
      previousExpenseMinor: previousExpenseMinor,
    );
  }

  final List<BalanceAlternativeDailySpendPoint> points;
  final int currentExpenseMinor;
  final int? previousExpenseMinor;

  int get noSpendDayCount =>
      points.where((point) => point.expenseMinor == 0).length;

  /// Signed relative spending change. Negative means the current month has
  /// lower expense than its comparable predecessor.
  int? get expenseChangeBasisPoints {
    final previous = previousExpenseMinor;
    if (previous == null || previous <= 0) return null;
    return ((currentExpenseMinor - previous) * 10000 / previous).round();
  }
}

@immutable
final class BalanceAlternativeSavingsPresentation {
  const BalanceAlternativeSavingsPresentation({
    required this.netMinor,
    required this.retentionBasisPoints,
  });

  factory BalanceAlternativeSavingsPresentation.fromTotals({
    required int incomeMinor,
    required int expenseMinor,
    required int? retentionBasisPoints,
  }) {
    // Linked retention has priority, but all primary scopes already contain
    // the two truthful totals needed for the same ratio. Leaving this null
    // made the shared Budget 3D chrome receive zero progress even while a
    // Savings amount was present. This is a render-ready scalar derivation,
    // not another financial projection.
    final resolvedRetention =
        retentionBasisPoints ??
        (incomeMinor <= 0
            ? null
            : ((incomeMinor - expenseMinor) * 10000 / incomeMinor).round());
    return BalanceAlternativeSavingsPresentation(
      netMinor: incomeMinor - expenseMinor,
      retentionBasisPoints: resolvedRetention,
    );
  }

  factory BalanceAlternativeSavingsPresentation.fromRetention(
    DashboardBalanceRetentionPresentation retention, {
    required int fallbackIncomeMinor,
    required int fallbackExpenseMinor,
  }) {
    final selected = retention.selectedPeriod;
    return BalanceAlternativeSavingsPresentation.fromTotals(
      incomeMinor: selected?.incomeMinor ?? fallbackIncomeMinor,
      expenseMinor: selected?.expenseMinor ?? fallbackExpenseMinor,
      retentionBasisPoints: selected?.retentionBasisPoints,
    );
  }

  final int netMinor;
  final int? retentionBasisPoints;
}

@immutable
final class BalanceAlternativeIncomeExpenseStripPresentation {
  const BalanceAlternativeIncomeExpenseStripPresentation({
    required this.incomeMinor,
    required this.expenseMinor,
  });

  factory BalanceAlternativeIncomeExpenseStripPresentation.fromPrimary(
    DashboardBalancePrimaryPresentation primary,
  ) => BalanceAlternativeIncomeExpenseStripPresentation(
    incomeMinor: primary.incomeTotalMinor,
    expenseMinor: primary.expenseTotalMinor,
  );

  final int incomeMinor;
  final int expenseMinor;

  int get totalMinor => incomeMinor + expenseMinor;

  int get incomeBasisPoints =>
      totalMinor <= 0 ? 5000 : (incomeMinor * 10000 / totalMinor).round();
}

@immutable
final class BalanceAlternativeYearClosingBucket {
  const BalanceAlternativeYearClosingBucket({
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String label;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

@immutable
final class BalanceAlternativeYearClosingsPresentation {
  BalanceAlternativeYearClosingsPresentation({
    required List<BalanceAlternativeYearClosingBucket> buckets,
  }) : buckets = List<BalanceAlternativeYearClosingBucket>.unmodifiable(
         buckets,
       );

  factory BalanceAlternativeYearClosingsPresentation.fromClosings(
    DashboardBalanceClosingsPresentation closings,
  ) => BalanceAlternativeYearClosingsPresentation(
    buckets: <BalanceAlternativeYearClosingBucket>[
      for (final bucket in closings.buckets)
        BalanceAlternativeYearClosingBucket(
          label: bucket.label,
          incomeMinor: bucket.incomeMinor,
          expenseMinor: bucket.expenseMinor,
        ),
    ],
  );

  factory BalanceAlternativeYearClosingsPresentation.fromPeriodPairs(
    List<DashboardBalancePrimaryPeriodPair> pairs,
  ) => BalanceAlternativeYearClosingsPresentation(
    buckets: <BalanceAlternativeYearClosingBucket>[
      for (final pair in pairs)
        BalanceAlternativeYearClosingBucket(
          label: _monthLabels[pair.value.clamp(1, 12) - 1],
          incomeMinor: pair.incomeMinor,
          expenseMinor: pair.expenseMinor,
        ),
    ],
  );

  final List<BalanceAlternativeYearClosingBucket> buckets;

  int get positiveBucketCount =>
      buckets.where((bucket) => bucket.netMinor > 0).length;
}

const List<String> _monthLabels = <String>[
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
];

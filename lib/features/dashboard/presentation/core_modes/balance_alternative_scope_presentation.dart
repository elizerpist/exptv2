import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_primary_projection.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

/// Render-only adapter boundary for the scope-specific alternative Balance
/// dashboard. It intentionally copies only immutable values that the existing
/// Balance primary projection already prepared.
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
    AllTimeScope() => BalanceAlternativeSumPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
      incomeExpense: BalanceAlternativeIncomeExpenseBarPresentation.fromPrimary(
        primary,
        domain: BalanceAlternativeBarDomain.years,
      ),
    ),
    YearScope() => BalanceAlternativeYearPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
      incomeExpense: BalanceAlternativeIncomeExpenseBarPresentation.fromPrimary(
        primary,
        domain: BalanceAlternativeBarDomain.months,
      ),
    ),
    MonthScope() => BalanceAlternativeMonthPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
    ),
    DayScope() => BalanceAlternativeDayPresentation(
      timeScope: primary.timeScope,
      sourcePresentationId: primary.presentationId,
    ),
  };
}

final class BalanceAlternativeSumPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeSumPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.incomeExpense,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation incomeExpense;
}

final class BalanceAlternativeYearPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeYearPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
    required this.incomeExpense,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation incomeExpense;
}

final class BalanceAlternativeMonthPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeMonthPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
  });
}

final class BalanceAlternativeDayPresentation
    extends BalanceAlternativeScopePresentation {
  const BalanceAlternativeDayPresentation({
    required super.timeScope,
    required super.sourcePresentationId,
  });
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

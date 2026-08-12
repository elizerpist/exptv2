import 'package:flutter/foundation.dart';

import '../../time_navigation/domain/ledger_time_scope.dart';
import 'current_ledger_query_scope.dart';
import 'ledger_direction.dart';

/// The two independent applied filter templates represented by one dashboard.
///
/// A template never contains a navigated parent/child time scope: its
/// [CurrentLedgerQueryScope.temporalFilter] is the Query constraint and the
/// time-navigation owner decorates it later.  Keeping both templates here
/// lets one immutable prepared dashboard index represent different income and
/// expense universes without introducing a second applied-query controller.
@immutable
final class DashboardDirectionalQuerySet {
  DashboardDirectionalQuerySet({
    required CurrentLedgerQueryScope income,
    required CurrentLedgerQueryScope expense,
  }) : income = _templateFor(income, LedgerDirection.income),
       expense = _templateFor(expense, LedgerDirection.expense);

  factory DashboardDirectionalQuerySet.fromInitial(
    CurrentLedgerQueryScope initialScope,
  ) {
    final template = initialScope.copyWith(timeScope: const AllTimeScope());
    final income = template.direction == LedgerDirection.income
        ? template
        : template.copyWith(direction: LedgerDirection.income);
    final expense = template.direction == LedgerDirection.expense
        ? template
        : template.copyWith(direction: LedgerDirection.expense);
    return DashboardDirectionalQuerySet(income: income, expense: expense);
  }

  final CurrentLedgerQueryScope income;
  final CurrentLedgerQueryScope expense;

  CurrentLedgerQueryScope scopeFor(LedgerDirection direction) =>
      switch (direction) {
        LedgerDirection.income => income,
        LedgerDirection.expense => expense,
      };

  DashboardDirectionalQuerySet replaceDirection(
    LedgerDirection direction,
    CurrentLedgerQueryScope scope,
  ) => switch (direction) {
    LedgerDirection.income => DashboardDirectionalQuerySet(
      income: scope,
      expense: expense,
    ),
    LedgerDirection.expense => DashboardDirectionalQuerySet(
      income: income,
      expense: scope,
    ),
  };

  /// Canonical cache/request identity. Each half includes its direction, so
  /// swapping otherwise equal filters remains impossible.
  late final String canonicalKey =
      'income=${income.key.value}|expense=${expense.key.value}';

  static CurrentLedgerQueryScope _templateFor(
    CurrentLedgerQueryScope scope,
    LedgerDirection direction,
  ) {
    if (scope.direction != direction || scope.timeScope is! AllTimeScope) {
      throw ArgumentError.value(
        scope,
        'scope',
        'Directional query templates require their own direction and AllTimeScope.',
      );
    }
    return scope;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardDirectionalQuerySet &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(income, expense);
}

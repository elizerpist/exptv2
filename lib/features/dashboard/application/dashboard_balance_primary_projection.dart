import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/year_month.dart';

/// Immutable upstream provenance for one Balance primary-card projection.
///
/// Its input is limited to the already admitted directional prepared
/// memberships. It intentionally has no repository, Query, scene, or widget
/// capability.
@immutable
final class DashboardBalancePrimaryIdentity {
  const DashboardBalancePrimaryIdentity({
    required this.upstreamScopeKey,
    required this.indexGeneration,
    required this.coreRevision,
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;

  @override
  bool operator ==(Object other) =>
      other is DashboardBalancePrimaryIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision;

  @override
  int get hashCode =>
      Object.hash(upstreamScopeKey, indexGeneration, coreRevision);
}

enum DashboardBalancePrimaryMode { sum, year, month, unsupportedDay }

/// One paired Income/Expense period used by the SUM and YEAR bar charts.
@immutable
final class DashboardBalancePrimaryPeriodPair {
  const DashboardBalancePrimaryPeriodPair({
    required this.value,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  /// Calendar year for SUM and one-based calendar month for YEAR.
  final int value;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

/// One month-local cumulative day point for the MONTH step chart.
@immutable
final class DashboardBalancePrimaryDayPoint {
  const DashboardBalancePrimaryDayPoint({
    required this.day,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final int day;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

/// Render-only immutable Balance primary-card payload owned by Dashboard Core.
@immutable
final class DashboardBalancePrimaryPresentation {
  DashboardBalancePrimaryPresentation({
    required this.identity,
    required this.timeScope,
    required this.mode,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required List<DashboardBalancePrimaryPeriodPair> periodPairs,
    required List<DashboardBalancePrimaryDayPoint> dailyPoints,
  }) : periodPairs = List<DashboardBalancePrimaryPeriodPair>.unmodifiable(
         periodPairs,
       ),
       dailyPoints = List<DashboardBalancePrimaryDayPoint>.unmodifiable(
         dailyPoints,
       ),
       presentationId = Object.hash(
         identity,
         timeScope.canonicalKey,
         mode,
         incomeTotalMinor,
         expenseTotalMinor,
       );

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final DashboardBalancePrimaryMode mode;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  final List<DashboardBalancePrimaryPeriodPair> periodPairs;
  final List<DashboardBalancePrimaryDayPoint> dailyPoints;
  final int presentationId;

  int get netTotalMinor => incomeTotalMinor - expenseTotalMinor;
}

/// Thin two-direction temporal read model over resident prepared membership.
///
/// This deliberately mirrors the bounded projection style used by Mind while
/// keeping Balance data independent from Mind state and UI. It never visits a
/// repository or asks the prepared index to build a frame.
abstract final class DashboardBalancePrimaryProjection {
  static DashboardBalancePrimaryPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    return switch (timeScope) {
      AllTimeScope() => _sum(identity, incomeEntries, expenseEntries),
      YearScope(:final year) => _year(
        identity,
        year,
        incomeEntries,
        expenseEntries,
      ),
      MonthScope(:final value) => _month(
        identity,
        value.year,
        value.month,
        incomeEntries,
        expenseEntries,
      ),
      DayScope() => DashboardBalancePrimaryPresentation(
        identity: identity,
        timeScope: timeScope,
        mode: DashboardBalancePrimaryMode.unsupportedDay,
        incomeTotalMinor: 0,
        expenseTotalMinor: 0,
        periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
        dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
      ),
    };
  }

  static DashboardBalancePrimaryPresentation _sum(
    DashboardBalancePrimaryIdentity identity,
    Iterable<DashboardLedgerEntry> income,
    Iterable<DashboardLedgerEntry> expense,
  ) {
    // Membership, not a non-zero aggregate, establishes that a year is real.
    // A genuine zero-valued transaction year therefore remains selectable.
    // Aggregate each resident list once: target changes must not turn a
    // short chart projection into a repeated full-membership scan.
    final incomeTotals = _annualTotals(income);
    final expenseTotals = _annualTotals(expense);
    final years = <int>{
      ...incomeTotals.byYear.keys,
      ...expenseTotals.byYear.keys,
    }.toList()..sort();
    final pairs = <DashboardBalancePrimaryPeriodPair>[
      for (final year in years)
        DashboardBalancePrimaryPeriodPair(
          value: year,
          incomeMinor: incomeTotals.byYear[year] ?? 0,
          expenseMinor: expenseTotals.byYear[year] ?? 0,
        ),
    ];
    return DashboardBalancePrimaryPresentation(
      identity: identity,
      timeScope: const AllTimeScope(),
      mode: DashboardBalancePrimaryMode.sum,
      incomeTotalMinor: incomeTotals.totalMinor,
      expenseTotalMinor: expenseTotals.totalMinor,
      periodPairs: pairs,
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );
  }

  static DashboardBalancePrimaryPresentation _year(
    DashboardBalancePrimaryIdentity identity,
    int year,
    Iterable<DashboardLedgerEntry> income,
    Iterable<DashboardLedgerEntry> expense,
  ) {
    final incomeTotals = _monthlyTotals(income, year);
    final expenseTotals = _monthlyTotals(expense, year);
    final pairs = <DashboardBalancePrimaryPeriodPair>[
      for (var month = 1; month <= 12; month += 1)
        DashboardBalancePrimaryPeriodPair(
          value: month,
          incomeMinor: incomeTotals.byMonth[month] ?? 0,
          expenseMinor: expenseTotals.byMonth[month] ?? 0,
        ),
    ];
    return DashboardBalancePrimaryPresentation(
      identity: identity,
      timeScope: YearScope(year),
      mode: DashboardBalancePrimaryMode.year,
      incomeTotalMinor: incomeTotals.totalMinor,
      expenseTotalMinor: expenseTotals.totalMinor,
      periodPairs: pairs,
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );
  }

  static DashboardBalancePrimaryPresentation _month(
    DashboardBalancePrimaryIdentity identity,
    int year,
    int month,
    Iterable<DashboardLedgerEntry> income,
    Iterable<DashboardLedgerEntry> expense,
  ) {
    final days = DateTime.utc(year, month + 1, 0).day;
    final incomeByDay = _totalsByDay(income, year, month);
    final expenseByDay = _totalsByDay(expense, year, month);
    var incomeCumulative = 0;
    var expenseCumulative = 0;
    final points = <DashboardBalancePrimaryDayPoint>[
      for (var day = 1; day <= days; day += 1)
        () {
          incomeCumulative += incomeByDay[day] ?? 0;
          expenseCumulative += expenseByDay[day] ?? 0;
          return DashboardBalancePrimaryDayPoint(
            day: day,
            incomeMinor: incomeCumulative,
            expenseMinor: expenseCumulative,
          );
        }(),
    ];
    return DashboardBalancePrimaryPresentation(
      identity: identity,
      timeScope: MonthScope(
        // Keep the externally visible scope exact without importing a second
        // date model into the renderer.
        YearMonth(year: year, month: month),
      ),
      mode: DashboardBalancePrimaryMode.month,
      incomeTotalMinor: incomeCumulative,
      expenseTotalMinor: expenseCumulative,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: points,
    );
  }

  static _BalanceAnnualTotals _annualTotals(
    Iterable<DashboardLedgerEntry> entries,
  ) {
    final byYear = <int, int>{};
    var totalMinor = 0;
    for (final entry in entries) {
      final year = _date(entry.bookedLocalEpochDay).year;
      totalMinor += entry.amountMinor;
      byYear.update(
        year,
        (total) => total + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return _BalanceAnnualTotals(
      byYear: Map<int, int>.unmodifiable(byYear),
      totalMinor: totalMinor,
    );
  }

  static _BalanceMonthlyTotals _monthlyTotals(
    Iterable<DashboardLedgerEntry> entries,
    int year,
  ) {
    final byMonth = <int, int>{};
    var totalMinor = 0;
    for (final entry in entries) {
      final date = _date(entry.bookedLocalEpochDay);
      if (date.year != year) continue;
      totalMinor += entry.amountMinor;
      byMonth.update(
        date.month,
        (total) => total + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return _BalanceMonthlyTotals(
      byMonth: Map<int, int>.unmodifiable(byMonth),
      totalMinor: totalMinor,
    );
  }

  static Map<int, int> _totalsByDay(
    Iterable<DashboardLedgerEntry> entries,
    int year,
    int month,
  ) {
    final totals = <int, int>{};
    for (final entry in entries) {
      final date = _date(entry.bookedLocalEpochDay);
      if (date.year != year || date.month != month) continue;
      totals.update(
        date.day,
        (total) => total + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return Map<int, int>.unmodifiable(totals);
  }

  static DateTime _date(int epochDay) =>
      DateTime.utc(1970).add(Duration(days: epochDay));
}

@immutable
final class _BalanceAnnualTotals {
  const _BalanceAnnualTotals({required this.byYear, required this.totalMinor});

  final Map<int, int> byYear;
  final int totalMinor;
}

@immutable
final class _BalanceMonthlyTotals {
  const _BalanceMonthlyTotals({
    required this.byMonth,
    required this.totalMinor,
  });

  final Map<int, int> byMonth;
  final int totalMinor;
}

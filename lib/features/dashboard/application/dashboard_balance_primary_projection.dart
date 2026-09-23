import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import 'dashboard_balance_closings_momentum_projection.dart';
import 'dashboard_balance_retention_stability_projection.dart';

const _balanceLinkedMaximumRows = 5;

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

/// One scope-local transaction used by the linked Balance carousel details.
///
/// This stays deliberately compact: it retains immutable entry identity and
/// display metadata but never imports LogBox rows, scene resources or a
/// repository-facing capability into Balance presentation.
@immutable
final class DashboardBalanceScopedTransaction {
  const DashboardBalanceScopedTransaction({
    required this.entryId,
    required this.title,
    required this.categoryTitle,
    required this.amountMinor,
    required this.direction,
    required this.occurredOrder,
    required this.epochDay,
  });

  final String entryId;
  final String title;
  final String categoryTitle;
  final int amountMinor;
  final LedgerDirection direction;
  final int occurredOrder;
  final int epochDay;
}

/// One active-direction rank for Balance's Category or Partner detail.
@immutable
final class DashboardBalanceRankedItem {
  const DashboardBalanceRankedItem({
    required this.id,
    required this.label,
    required this.direction,
    required this.amountMinor,
    required this.transactionCount,
    required this.categoryColorId,
    required this.categoryIconId,
  });

  final String id;
  final String label;
  final LedgerDirection direction;
  final int amountMinor;
  final int transactionCount;
  final String categoryColorId;
  final String categoryIconId;
}

/// One immutable Summary-aware Balance payload for all linked card topics.
///
/// The all-time Header presentation intentionally remains separate. This value
/// is rebuilt or reused only from resident prepared membership when an exact
/// visible Summary scope or active direction changes.
@immutable
final class DashboardBalanceLinkedPresentation {
  DashboardBalanceLinkedPresentation({
    required this.identity,
    required this.timeScope,
    required this.selectedDirection,
    required this.cashflow,
    DashboardBalanceClosingsPresentation? closings,
    DashboardBalanceMomentumPresentation? momentum,
    DashboardBalanceRetentionPresentation? retention,
    DashboardBalanceStabilityPresentation? stability,
    required List<DashboardBalanceScopedTransaction> latestTransactions,
    required List<DashboardBalanceRankedItem> topCategories,
    required List<DashboardBalanceRankedItem> topPartners,
  }) : latestTransactions =
           List<DashboardBalanceScopedTransaction>.unmodifiable(
             latestTransactions.take(_balanceLinkedMaximumRows),
           ),
       topCategories = List<DashboardBalanceRankedItem>.unmodifiable(
         topCategories.take(_balanceLinkedMaximumRows),
       ),
       topPartners = List<DashboardBalanceRankedItem>.unmodifiable(
         topPartners.take(_balanceLinkedMaximumRows),
       ),
       closings =
           closings ??
           DashboardBalanceClosingsPresentation(
             identity: identity,
             timeScope: timeScope,
             buckets: const <DashboardBalanceClosingBucket>[],
           ),
       momentum =
           momentum ??
           DashboardBalanceMomentumPresentation.unavailable(
             identity: identity,
             timeScope: timeScope,
           ),
       retention =
           retention ??
           DashboardBalanceRetentionPresentation(
             identity: identity,
             timeScope: timeScope,
             periods: const <DashboardBalanceRetentionPeriod>[],
           ),
       stability =
           stability ??
           DashboardBalanceStabilityPresentation(
             identity: identity,
             timeScope: timeScope,
             observations: const <DashboardBalanceMonthlyNetObservation>[],
             medianNetTimesTwo: null,
             typicalDeviationTimesTwo: null,
           );

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final LedgerDirection selectedDirection;
  final DashboardBalancePrimaryPresentation cashflow;
  final DashboardBalanceClosingsPresentation closings;
  final DashboardBalanceMomentumPresentation momentum;
  final DashboardBalanceRetentionPresentation retention;
  final DashboardBalanceStabilityPresentation stability;
  final List<DashboardBalanceScopedTransaction> latestTransactions;
  final List<DashboardBalanceRankedItem> topCategories;
  final List<DashboardBalanceRankedItem> topPartners;
  int get presentationId => Object.hashAll(<Object?>[
    identity,
    timeScope.canonicalKey,
    selectedDirection,
    cashflow.presentationId,
    closings.presentationId,
    momentum.presentationId,
    retention.presentationId,
    stability.presentationId,
    for (final transaction in latestTransactions.take(
      _balanceLinkedMaximumRows,
    ))
      '${transaction.entryId}:${transaction.occurredOrder}',
    for (final category in topCategories.take(_balanceLinkedMaximumRows))
      '${category.id}:${category.amountMinor}:${category.transactionCount}',
    for (final partner in topPartners.take(_balanceLinkedMaximumRows))
      '${partner.id}:${partner.amountMinor}:${partner.transactionCount}',
  ]);
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
      DayScope(:final date) => _day(
        identity,
        date.epochDay,
        timeScope,
        incomeEntries,
        expenseEntries,
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

  static DashboardBalancePrimaryPresentation _day(
    DashboardBalancePrimaryIdentity identity,
    int epochDay,
    LedgerTimeScope timeScope,
    Iterable<DashboardLedgerEntry> income,
    Iterable<DashboardLedgerEntry> expense,
  ) => DashboardBalancePrimaryPresentation(
    identity: identity,
    timeScope: timeScope,
    mode: DashboardBalancePrimaryMode.unsupportedDay,
    incomeTotalMinor: _totalForEpochDay(income, epochDay),
    expenseTotalMinor: _totalForEpochDay(expense, epochDay),
    periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
    dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
  );

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

  static int _totalForEpochDay(
    Iterable<DashboardLedgerEntry> entries,
    int epochDay,
  ) => entries
      .where((entry) => entry.bookedLocalEpochDay == epochDay)
      .fold<int>(0, (total, entry) => total + entry.amountMinor);

  static DateTime _date(int epochDay) =>
      DateTime.utc(1970).add(Duration(days: epochDay));
}

/// Summary/direction-local Balance read model over resident prepared rows.
///
/// It deliberately performs no frame admission: the Core supplies already
/// immutable memberships for both canonical directions.
abstract final class DashboardBalanceLinkedProjection {
  static DashboardBalanceLinkedPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LedgerDirection selectedDirection,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
    LocalDate logicalAsOfDate = const LocalDate(year: 2026, month: 1, day: 1),
    int logicalAsOfLocalTimeMinutes = 12 * 60,
  }) {
    final income = _entriesForScope(incomeEntries, timeScope);
    final expense = _entriesForScope(expenseEntries, timeScope);
    final directional = selectedDirection == LedgerDirection.income
        ? income
        : expense;
    return DashboardBalanceLinkedPresentation(
      identity: identity,
      timeScope: timeScope,
      selectedDirection: selectedDirection,
      cashflow: DashboardBalancePrimaryProjection.build(
        identity: identity,
        timeScope: timeScope,
        incomeEntries: income,
        expenseEntries: expense,
      ),
      closings: DashboardBalanceClosingsProjection.build(
        identity: identity,
        timeScope: timeScope,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
      ),
      momentum: DashboardBalanceMomentumProjection.build(
        identity: identity,
        timeScope: timeScope,
        logicalAsOfDate: logicalAsOfDate,
        logicalAsOfLocalTimeMinutes: logicalAsOfLocalTimeMinutes,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
      ),
      retention: DashboardBalanceRetentionProjection.build(
        identity: identity,
        timeScope: timeScope,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
      ),
      stability: DashboardBalanceStabilityProjection.build(
        identity: identity,
        timeScope: timeScope,
        logicalAsOfDate: logicalAsOfDate,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
      ),
      latestTransactions: _latestTransactions(income, expense),
      topCategories: _rank(
        directional,
        selectedDirection,
        _BalanceRankKind.category,
      ),
      topPartners: _rank(
        directional,
        selectedDirection,
        _BalanceRankKind.partner,
      ),
    );
  }

  static List<DashboardLedgerEntry> _entriesForScope(
    Iterable<DashboardLedgerEntry> entries,
    LedgerTimeScope timeScope,
  ) {
    final boundaries = timeScope.boundaries;
    if (boundaries == null) {
      return List<DashboardLedgerEntry>.unmodifiable(entries);
    }
    final start = boundaries.startInclusive.epochDay;
    final end = boundaries.endExclusive.epochDay;
    return List<DashboardLedgerEntry>.unmodifiable(
      entries.where(
        (entry) =>
            entry.bookedLocalEpochDay >= start &&
            entry.bookedLocalEpochDay < end,
      ),
    );
  }

  static List<DashboardBalanceScopedTransaction> _latestTransactions(
    List<DashboardLedgerEntry> income,
    List<DashboardLedgerEntry> expense,
  ) {
    final ordered = <DashboardLedgerEntry>[...income, ...expense]
      ..sort(_newestFirst);
    return List<DashboardBalanceScopedTransaction>.unmodifiable(
      ordered.take(_balanceLinkedMaximumRows).map(_transactionFor),
    );
  }

  static DashboardBalanceScopedTransaction _transactionFor(
    DashboardLedgerEntry entry,
  ) {
    final direction = entry.direction == LedgerDirection.expense.name
        ? LedgerDirection.expense
        : LedgerDirection.income;
    return DashboardBalanceScopedTransaction(
      entryId: entry.id,
      title: _transactionTitle(entry),
      categoryTitle: _categoryLabel(entry),
      amountMinor: entry.amountMinor.abs(),
      direction: direction,
      occurredOrder: _occurredOrder(entry),
      epochDay: entry.bookedLocalEpochDay,
    );
  }

  static List<DashboardBalanceRankedItem> _rank(
    List<DashboardLedgerEntry> entries,
    LedgerDirection direction,
    _BalanceRankKind kind,
  ) {
    final buckets = <String, _BalanceRankAccumulator>{};
    for (final entry in entries) {
      final id = kind == _BalanceRankKind.category
          ? entry.categoryId
          : entry.partnerId;
      final label = kind == _BalanceRankKind.category
          ? _categoryLabel(entry)
          : _partnerLabel(entry);
      final bucket = buckets.putIfAbsent(
        id,
        () => _BalanceRankAccumulator(
          id: id,
          label: label,
          representative: entry,
        ),
      );
      bucket.amountMinor += entry.amountMinor.abs();
      bucket.transactionCount += 1;
      if (_newestFirst(entry, bucket.representative) < 0) {
        bucket.representative = entry;
        bucket.label = label;
      }
    }
    final ranked = buckets.values.toList(growable: false)
      ..sort((left, right) {
        final metric = kind == _BalanceRankKind.category
            ? right.amountMinor.compareTo(left.amountMinor)
            : right.transactionCount.compareTo(left.transactionCount);
        if (metric != 0) return metric;
        final label = left.label.compareTo(right.label);
        return label != 0 ? label : left.id.compareTo(right.id);
      });
    return List<DashboardBalanceRankedItem>.unmodifiable(
      ranked
          .take(_balanceLinkedMaximumRows)
          .map(
            (bucket) => DashboardBalanceRankedItem(
              id: bucket.id,
              label: bucket.label,
              direction: direction,
              amountMinor: bucket.amountMinor,
              transactionCount: bucket.transactionCount,
              categoryColorId:
                  bucket.representative.categoryColorId ?? 'fallback',
              categoryIconId:
                  bucket.representative.categoryIconId ?? 'fallback',
            ),
          ),
    );
  }

  static int _newestFirst(
    DashboardLedgerEntry left,
    DashboardLedgerEntry right,
  ) {
    final order = _occurredOrder(right).compareTo(_occurredOrder(left));
    return order != 0 ? order : right.id.compareTo(left.id);
  }

  static int _occurredOrder(DashboardLedgerEntry entry) =>
      entry.occurredAtUtcMs ??
      entry.bookedLocalEpochDay * (24 * 60) + entry.bookedLocalTimeMinutes;

  static String _transactionTitle(DashboardLedgerEntry entry) {
    final partner = entry.partnerDisplayName?.trim();
    if (partner != null && partner.isNotEmpty) return partner;
    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return _categoryLabel(entry);
  }

  static String _categoryLabel(DashboardLedgerEntry entry) {
    final label = entry.categoryDisplayName?.trim();
    return label == null || label.isEmpty ? 'Kategorizálatlan' : label;
  }

  static String _partnerLabel(DashboardLedgerEntry entry) {
    final label = entry.partnerDisplayName?.trim();
    return label == null || label.isEmpty ? _transactionTitle(entry) : label;
  }
}

enum _BalanceRankKind { category, partner }

final class _BalanceRankAccumulator {
  _BalanceRankAccumulator({
    required this.id,
    required this.label,
    required this.representative,
  });

  final String id;
  String label;
  int amountMinor = 0;
  int transactionCount = 0;
  DashboardLedgerEntry representative;
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

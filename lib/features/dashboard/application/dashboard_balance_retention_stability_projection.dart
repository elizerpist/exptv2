import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import 'dashboard_balance_primary_projection.dart';

/// A finite retention state. No-income and no-data are deliberately separate:
/// an expense-only period does not have a defined retention percentage.
enum DashboardBalanceRetentionState { value, noIncome, noData }

/// One immutable all-history, annual, or sibling-month Retention observation.
@immutable
final class DashboardBalanceRetentionPeriod {
  const DashboardBalanceRetentionPeriod({
    required this.id,
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.state,
    required this.selected,
    this.retentionBasisPoints,
  });

  final String id;
  final String label;
  final int incomeMinor;
  final int expenseMinor;
  final DashboardBalanceRetentionState state;
  final bool selected;

  /// Signed percentage in basis points, only when Income is positive.
  final int? retentionBasisPoints;

  int get netMinor => incomeMinor - expenseMinor;
}

/// Immutable linked Retention payload. It is a Core projection, shared by the
/// compact card and lower renderer without widget-side financial arithmetic.
@immutable
final class DashboardBalanceRetentionPresentation {
  DashboardBalanceRetentionPresentation({
    required this.identity,
    required this.timeScope,
    required List<DashboardBalanceRetentionPeriod> periods,
  }) : periods = List<DashboardBalanceRetentionPeriod>.unmodifiable(periods),
       presentationId = Object.hashAll(<Object?>[
         identity,
         timeScope.canonicalKey,
         for (final period in periods)
           '${period.id}:${period.incomeMinor}:${period.expenseMinor}:${period.selected}',
       ]);

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final List<DashboardBalanceRetentionPeriod> periods;
  final int presentationId;

  DashboardBalanceRetentionPeriod? get selectedPeriod {
    for (final period in periods) {
      if (period.selected) return period;
    }
    return null;
  }
}

/// Pure dual-direction Retention projection over resident prepared membership.
abstract final class DashboardBalanceRetentionProjection {
  static DashboardBalanceRetentionPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final income = List<DashboardLedgerEntry>.unmodifiable(incomeEntries);
    final expense = List<DashboardLedgerEntry>.unmodifiable(expenseEntries);
    final all = <DashboardLedgerEntry>[...income, ...expense];
    final periods = switch (timeScope) {
      AllTimeScope() => <DashboardBalanceRetentionPeriod>[
        _period(
          id: 'all',
          label: 'Összesen',
          incomeMinor: _total(income),
          expenseMinor: _total(expense),
          selected: true,
        ),
      ],
      YearScope(:final year) => _yearSiblings(
        all: all,
        income: income,
        expense: expense,
        selectedYear: year,
      ),
      MonthScope(:final value) => _monthSiblings(
        all: all,
        income: income,
        expense: expense,
        selectedMonth: value,
      ),
      DayScope(:final date) => _monthSiblings(
        all: all,
        income: income,
        expense: expense,
        selectedMonth: YearMonth(year: date.year, month: date.month),
      ),
    };
    return DashboardBalanceRetentionPresentation(
      identity: identity,
      timeScope: timeScope,
      periods: periods,
    );
  }

  static List<DashboardBalanceRetentionPeriod> _yearSiblings({
    required List<DashboardLedgerEntry> all,
    required List<DashboardLedgerEntry> income,
    required List<DashboardLedgerEntry> expense,
    required int selectedYear,
  }) {
    final years = _years(all);
    if (years == null) return const <DashboardBalanceRetentionPeriod>[];
    final incomeTotals = _totalsByYear(income);
    final expenseTotals = _totalsByYear(expense);
    return List<DashboardBalanceRetentionPeriod>.unmodifiable(
      <DashboardBalanceRetentionPeriod>[
        for (var year = years.$1; year <= years.$2; year += 1)
          _period(
            id: 'year:$year',
            label: '$year',
            incomeMinor: incomeTotals[year] ?? 0,
            expenseMinor: expenseTotals[year] ?? 0,
            selected: year == selectedYear,
          ),
      ],
    );
  }

  static List<DashboardBalanceRetentionPeriod> _monthSiblings({
    required List<DashboardLedgerEntry> all,
    required List<DashboardLedgerEntry> income,
    required List<DashboardLedgerEntry> expense,
    required YearMonth selectedMonth,
  }) {
    final range = _monthRange(all);
    if (range == null) return const <DashboardBalanceRetentionPeriod>[];
    final incomeTotals = _totalsByMonth(income);
    final expenseTotals = _totalsByMonth(expense);
    final selectedOrdinal = _monthOrdinal(selectedMonth);
    return List<DashboardBalanceRetentionPeriod>.unmodifiable(
      <DashboardBalanceRetentionPeriod>[
        for (var ordinal = range.$1; ordinal <= range.$2; ordinal += 1)
          () {
            final month = _monthFromOrdinal(ordinal);
            return _period(
              id: 'month:${month.year}-${month.month}',
              label: '${month.year} ${_monthLabel(month.month)}',
              incomeMinor: incomeTotals[ordinal] ?? 0,
              expenseMinor: expenseTotals[ordinal] ?? 0,
              selected: ordinal == selectedOrdinal,
            );
          }(),
      ],
    );
  }

  static DashboardBalanceRetentionPeriod _period({
    required String id,
    required String label,
    required int incomeMinor,
    required int expenseMinor,
    required bool selected,
  }) {
    final state = incomeMinor > 0
        ? DashboardBalanceRetentionState.value
        : expenseMinor > 0
        ? DashboardBalanceRetentionState.noIncome
        : DashboardBalanceRetentionState.noData;
    return DashboardBalanceRetentionPeriod(
      id: id,
      label: label,
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      state: state,
      selected: selected,
      retentionBasisPoints: state == DashboardBalanceRetentionState.value
          ? _ratioBasisPoints(incomeMinor - expenseMinor, incomeMinor)
          : null,
    );
  }
}

/// One bounded truthful complete-calendar-month net observation.
@immutable
final class DashboardBalanceMonthlyNetObservation {
  const DashboardBalanceMonthlyNetObservation({
    required this.id,
    required this.label,
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String id;
  final String label;
  final YearMonth month;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

/// Immutable stability distribution. Values represented as `*TimesTwo` keep
/// an even-count median exact to half a minor unit; the deviation uses the
/// same scale and an explicitly deterministic floor midpoint when necessary.
@immutable
final class DashboardBalanceStabilityPresentation {
  DashboardBalanceStabilityPresentation({
    required this.identity,
    required this.timeScope,
    required List<DashboardBalanceMonthlyNetObservation> observations,
    required this.medianNetTimesTwo,
    required this.typicalDeviationTimesTwo,
  }) : observations = List<DashboardBalanceMonthlyNetObservation>.unmodifiable(
         observations,
       ),
       presentationId = Object.hashAll(<Object?>[
         identity,
         timeScope.canonicalKey,
         medianNetTimesTwo,
         typicalDeviationTimesTwo,
         for (final observation in observations)
           '${observation.id}:${observation.netMinor}',
       ]);

  static const minimumObservationCount = 3;

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final List<DashboardBalanceMonthlyNetObservation> observations;
  final int? medianNetTimesTwo;
  final int? typicalDeviationTimesTwo;
  final int presentationId;

  int get sampleCount => observations.length;
  bool get isAvailable =>
      sampleCount >= minimumObservationCount &&
      medianNetTimesTwo != null &&
      typicalDeviationTimesTwo != null;
  int? get typicalBandLowerTimesTwo =>
      isAvailable ? medianNetTimesTwo! - typicalDeviationTimesTwo! : null;
  int? get typicalBandUpperTimesTwo =>
      isAvailable ? medianNetTimesTwo! + typicalDeviationTimesTwo! : null;
}

/// Pure robust monthly-net stability projection over resident membership.
abstract final class DashboardBalanceStabilityProjection {
  static DashboardBalanceStabilityPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LocalDate logicalAsOfDate,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final income = List<DashboardLedgerEntry>.unmodifiable(incomeEntries);
    final expense = List<DashboardLedgerEntry>.unmodifiable(expenseEntries);
    final all = <DashboardLedgerEntry>[...income, ...expense];
    final established = _monthRange(all);
    final latestComplete = _monthOrdinal(
      YearMonth(
        year: logicalAsOfDate.year,
        month: logicalAsOfDate.month,
      ).previous(),
    );
    final requestedRange = _requestedMonthRange(
      timeScope: timeScope,
      established: established,
      latestComplete: latestComplete,
      logicalAsOfDate: logicalAsOfDate,
    );
    final incomeTotals = _totalsByMonth(income);
    final expenseTotals = _totalsByMonth(expense);
    final observations = requestedRange == null
        ? const <DashboardBalanceMonthlyNetObservation>[]
        : List<DashboardBalanceMonthlyNetObservation>.unmodifiable(
            <DashboardBalanceMonthlyNetObservation>[
              for (
                var ordinal = requestedRange.$1;
                ordinal <= requestedRange.$2;
                ordinal += 1
              )
                () {
                  final month = _monthFromOrdinal(ordinal);
                  return DashboardBalanceMonthlyNetObservation(
                    id: 'month:${month.year}-${month.month}',
                    label: '${month.year} ${_monthLabel(month.month)}',
                    month: month,
                    incomeMinor: incomeTotals[ordinal] ?? 0,
                    expenseMinor: expenseTotals[ordinal] ?? 0,
                  );
                }(),
            ],
          );
    final netValues = observations
        .map((observation) => observation.netMinor)
        .toList(growable: false);
    final median =
        netValues.length >=
            DashboardBalanceStabilityPresentation.minimumObservationCount
        ? _medianMinorTimesTwo(netValues)
        : null;
    final deviation = median == null
        ? null
        : _medianTwiceMinor(
            netValues
                .map((net) => (net * 2 - median).abs())
                .toList(growable: false),
          );
    return DashboardBalanceStabilityPresentation(
      identity: identity,
      timeScope: timeScope,
      observations: observations,
      medianNetTimesTwo: median,
      typicalDeviationTimesTwo: deviation,
    );
  }

  static (int, int)? _requestedMonthRange({
    required LedgerTimeScope timeScope,
    required (int, int)? established,
    required int latestComplete,
    required LocalDate logicalAsOfDate,
  }) {
    if (established == null) return null;
    final upperBound = established.$2 < latestComplete
        ? established.$2
        : latestComplete;
    if (upperBound < established.$1) return null;
    final range = switch (timeScope) {
      AllTimeScope() => (established.$1, upperBound),
      YearScope(:final year) => (
        _monthOrdinal(YearMonth(year: year, month: 1)),
        _monthOrdinal(YearMonth(year: year, month: 12)),
      ),
      MonthScope(:final value) => _trailingRange(
        selectedMonth: value,
        logicalAsOfDate: logicalAsOfDate,
      ),
      DayScope(:final date) => _trailingRange(
        selectedMonth: YearMonth(year: date.year, month: date.month),
        logicalAsOfDate: logicalAsOfDate,
      ),
    };
    final start = range.$1 < established.$1 ? established.$1 : range.$1;
    final endFromRange = range.$2 < upperBound ? range.$2 : upperBound;
    return start <= endFromRange ? (start, endFromRange) : null;
  }

  static (int, int) _trailingRange({
    required YearMonth selectedMonth,
    required LocalDate logicalAsOfDate,
  }) {
    final current = _monthOrdinal(
      YearMonth(year: logicalAsOfDate.year, month: logicalAsOfDate.month),
    );
    final selected = _monthOrdinal(selectedMonth);
    final anchor = selected >= current ? selected - 1 : selected;
    return (anchor - 11, anchor);
  }
}

int _total(Iterable<DashboardLedgerEntry> entries) =>
    entries.fold<int>(0, (total, entry) => total + entry.amountMinor.abs());

Map<int, int> _totalsByYear(Iterable<DashboardLedgerEntry> entries) {
  final totals = <int, int>{};
  for (final entry in entries) {
    final year = _date(entry.bookedLocalEpochDay).year;
    totals.update(
      year,
      (total) => total + entry.amountMinor.abs(),
      ifAbsent: () => entry.amountMinor.abs(),
    );
  }
  return Map<int, int>.unmodifiable(totals);
}

Map<int, int> _totalsByMonth(Iterable<DashboardLedgerEntry> entries) {
  final totals = <int, int>{};
  for (final entry in entries) {
    final date = _date(entry.bookedLocalEpochDay);
    final ordinal = _monthOrdinal(
      YearMonth(year: date.year, month: date.month),
    );
    totals.update(
      ordinal,
      (total) => total + entry.amountMinor.abs(),
      ifAbsent: () => entry.amountMinor.abs(),
    );
  }
  return Map<int, int>.unmodifiable(totals);
}

(int, int)? _years(Iterable<DashboardLedgerEntry> entries) {
  final values = entries
      .map((entry) => _date(entry.bookedLocalEpochDay).year)
      .toList(growable: false);
  if (values.isEmpty) return null;
  return (
    values.reduce((left, right) => left < right ? left : right),
    values.reduce((left, right) => left > right ? left : right),
  );
}

(int, int)? _monthRange(Iterable<DashboardLedgerEntry> entries) {
  final values = entries
      .map((entry) {
        final date = _date(entry.bookedLocalEpochDay);
        return _monthOrdinal(YearMonth(year: date.year, month: date.month));
      })
      .toList(growable: false);
  if (values.isEmpty) return null;
  return (
    values.reduce((left, right) => left < right ? left : right),
    values.reduce((left, right) => left > right ? left : right),
  );
}

int _monthOrdinal(YearMonth month) => month.year * 12 + month.month - 1;

YearMonth _monthFromOrdinal(int ordinal) =>
    YearMonth(year: ordinal ~/ 12, month: ordinal % 12 + 1);

DateTime _date(int epochDay) =>
    DateTime.utc(1970).add(Duration(days: epochDay));

String _monthLabel(int month) => const <String>[
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
][month - 1];

int _ratioBasisPoints(int numerator, int denominator) {
  final scaled = numerator * 10000;
  final sign = scaled < 0 ? -1 : 1;
  return sign * ((scaled.abs() + denominator ~/ 2) ~/ denominator);
}

int _medianMinorTimesTwo(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle] * 2
      : sorted[middle - 1] + sorted[middle];
}

int _medianTwiceMinor(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) ~/ 2;
}

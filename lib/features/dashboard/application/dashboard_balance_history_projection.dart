import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import 'dashboard_balance_presentation.dart';

/// A Balance-only visual selection over one immutable, already-prepared
/// all-time history. These modes never alter the all-time Header amount or
/// latest transaction.
enum BalanceHeaderChartMode {
  adaptiveSummary,
  allTime,
  monthEndClosingExperimental,
  compound;

  String get tunerLabel => switch (this) {
    BalanceHeaderChartMode.adaptiveSummary => 'Adaptive / Summary',
    BalanceHeaderChartMode.allTime => 'All-time / Sum',
    BalanceHeaderChartMode.monthEndClosingExperimental =>
      'Hóvégi záróérték — kísérleti',
    BalanceHeaderChartMode.compound => 'Compound',
  };
}

/// Core-only construction of the immutable all-time financial trend used by
/// Balance Header. It consumes prepared transport rows, not LogBox widgets,
/// repository reads or painter state.
abstract final class DashboardBalanceHistoryProjection {
  /// Uses every admitted transaction as an exact cumulative sample. This is
  /// intentionally more truthful than daily closes: a same-day income/expense
  /// reversal cannot erase a real financial extremum from the Header history.
  static DashboardBalanceHistorySeries? build({
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final ordered =
        <_BalanceHistoryEntry>[
          for (final entry in incomeEntries) _BalanceHistoryEntry(entry, true),
          for (final entry in expenseEntries)
            _BalanceHistoryEntry(entry, false),
        ]..sort((left, right) {
          final time = left.epochMinute.compareTo(right.epochMinute);
          if (time != 0) return time;
          // Existing Balance latest-item ordering uses entry ID as the stable
          // final tie-break. Keep its inverse chronology compatible here.
          return left.entry.id.compareTo(right.entry.id);
        });
    if (ordered.isEmpty) return null;

    var incomeTotalMinor = 0;
    var expenseTotalMinor = 0;
    final points = <DashboardBalanceHistoryPoint>[];
    for (final item in ordered) {
      if (item.isIncome) {
        incomeTotalMinor += item.entry.amountMinor;
      } else {
        expenseTotalMinor += item.entry.amountMinor;
      }
      points.add(
        DashboardBalanceHistoryPoint(
          entryId: item.entry.id,
          epochDay: item.entry.bookedLocalEpochDay,
          epochMinute: item.epochMinute,
          incomeTotalMinor: incomeTotalMinor,
          expenseTotalMinor: expenseTotalMinor,
          balanceMinor: incomeTotalMinor - expenseTotalMinor,
        ),
      );
    }
    return DashboardBalanceHistorySeries(
      startInclusiveEpochMinute: points.first.epochMinute,
      endInclusiveEpochMinute: points.last.epochMinute,
      points: points,
    );
  }
}

/// Bounded read-only projections for Balance Header presentation. The caller
/// supplies an immutable Core history and an already-admitted Summary scope;
/// no repository, index, Query or renderer data path is reachable here.
abstract final class DashboardBalanceHistoryViewProjection {
  static DashboardBalanceHistorySeries? project({
    required DashboardBalanceHistorySeries source,
    required BalanceHeaderChartMode mode,
    required LedgerTimeScope adaptiveScope,
  }) => switch (mode) {
    BalanceHeaderChartMode.allTime => source,
    BalanceHeaderChartMode.adaptiveSummary => _adaptive(source, adaptiveScope),
    BalanceHeaderChartMode.monthEndClosingExperimental => _monthEnds(source),
    BalanceHeaderChartMode.compound => _compound(source, adaptiveScope),
  };

  /// Compound deliberately follows the selected Summary dimension without
  /// changing the all-time Header amount: long views use truthful calendar
  /// closes; the enlarged Month/Day views retain real transaction extrema.
  static DashboardBalanceHistorySeries? _compound(
    DashboardBalanceHistorySeries source,
    LedgerTimeScope scope,
  ) => switch (scope) {
    AllTimeScope() => _monthEnds(source),
    YearScope(:final year) => _forYear(_monthEnds(source), year),
    MonthScope() || DayScope() => _adaptive(source, scope),
  };

  static DashboardBalanceHistorySeries? _forYear(
    DashboardBalanceHistorySeries? source,
    int year,
  ) {
    if (source == null) return null;
    final points = source.points
        .where((point) => _calendarDate(point.epochDay).year == year)
        .toList(growable: false);
    if (points.isEmpty) return null;
    return DashboardBalanceHistorySeries(
      startInclusiveEpochMinute: points.first.epochMinute,
      endInclusiveEpochMinute: points.last.epochMinute,
      points: points,
    );
  }

  static DashboardBalanceHistorySeries? _adaptive(
    DashboardBalanceHistorySeries source,
    LedgerTimeScope scope,
  ) {
    final boundaries = scope.boundaries;
    if (boundaries == null) return source;
    final startDay = boundaries.startInclusive.epochDay;
    final endExclusiveDay = boundaries.endExclusive.epochDay;
    final points = source.points
        .where(
          (point) =>
              point.epochDay >= startDay && point.epochDay < endExclusiveDay,
        )
        .toList(growable: false);
    if (points.isEmpty) return null;
    return DashboardBalanceHistorySeries(
      startInclusiveEpochMinute: points.first.epochMinute,
      endInclusiveEpochMinute: points.last.epochMinute,
      points: points,
    );
  }

  static DashboardBalanceHistorySeries? _monthEnds(
    DashboardBalanceHistorySeries source,
  ) {
    final first = _calendarDate(source.points.first.epochDay);
    final last = _calendarDate(source.points.last.epochDay);
    final lastCompleteMonthEnd = _monthEndEpochDay(last.year, last.month);
    // A source point during the current calendar month is not a month close.
    // Projecting it onto that future month-end coordinate would make the
    // chart claim a financial value that has not happened yet. Empty months
    // between the first point and the final *completed* month still carry the
    // preceding close below.
    final finalMonthEnd = source.points.last.epochDay == lastCompleteMonthEnd
        ? lastCompleteMonthEnd
        : _monthEndEpochDay(last.year, last.month - 1);
    if (finalMonthEnd < source.points.first.epochDay) return null;
    final points = <DashboardBalanceHistoryPoint>[];
    DashboardBalanceHistoryPoint? priorClose;
    var cursorYear = first.year;
    var cursorMonth = first.month;
    var sourceIndex = 0;
    while (_monthEndEpochDay(cursorYear, cursorMonth) <= finalMonthEnd) {
      final endDay = _monthEndEpochDay(cursorYear, cursorMonth);
      DashboardBalanceHistoryPoint? close = priorClose;
      while (sourceIndex < source.points.length &&
          source.points[sourceIndex].epochDay <= endDay) {
        close = source.points[sourceIndex];
        sourceIndex += 1;
      }
      if (close != null) {
        points.add(
          DashboardBalanceHistoryPoint(
            entryId:
                'month-close:$cursorYear-${cursorMonth.toString().padLeft(2, '0')}',
            epochDay: endDay,
            epochMinute: endDay * 1440 + 1439,
            incomeTotalMinor: close.incomeTotalMinor,
            expenseTotalMinor: close.expenseTotalMinor,
            balanceMinor: close.balanceMinor,
          ),
        );
        priorClose = close;
      }
      if (cursorMonth == 12) {
        cursorYear += 1;
        cursorMonth = 1;
      } else {
        cursorMonth += 1;
      }
    }
    if (points.isEmpty) return null;
    return DashboardBalanceHistorySeries(
      startInclusiveEpochMinute: points.first.epochMinute,
      endInclusiveEpochMinute: points.last.epochMinute,
      points: points,
    );
  }

  static DateTime _calendarDate(int epochDay) =>
      DateTime.utc(1970).add(Duration(days: epochDay));

  static int _monthEndEpochDay(int year, int month) =>
      DateTime.utc(year, month + 1).difference(DateTime.utc(1970)).inDays - 1;
}

final class _BalanceHistoryEntry {
  const _BalanceHistoryEntry(this.entry, this.isIncome);

  final DashboardLedgerEntry entry;
  final bool isIncome;

  int get epochMinute =>
      entry.bookedLocalEpochDay * 1440 + entry.bookedLocalTimeMinutes;
}

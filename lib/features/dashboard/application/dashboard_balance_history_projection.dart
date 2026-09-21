import '../query/data/dashboard_ledger_entry.dart';
import 'dashboard_balance_presentation.dart';

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

final class _BalanceHistoryEntry {
  const _BalanceHistoryEntry(this.entry, this.isIncome);

  final DashboardLedgerEntry entry;
  final bool isIncome;

  int get epochMinute =>
      entry.bookedLocalEpochDay * 1440 + entry.bookedLocalTimeMinutes;
}

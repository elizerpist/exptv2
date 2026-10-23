import 'package:flutter/foundation.dart';
import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import 'dashboard_balance_primary_identity.dart';

enum DashboardBalanceMonthSpendingLevelStatus {
  available,
  insufficientHistory,
  zeroReference,
  future,
}

@immutable
final class DashboardBalanceMonthSpendingLevelPresentation {
  const DashboardBalanceMonthSpendingLevelPresentation({
    required this.identity,
    required this.currentExpenseMinor,
    required this.referenceExpenseTimesTwo,
    required this.comparableMonthCount,
    required this.status,
  });
  final DashboardBalancePrimaryIdentity identity;
  final int currentExpenseMinor;
  final int? referenceExpenseTimesTwo;
  final int comparableMonthCount;
  final DashboardBalanceMonthSpendingLevelStatus status;
  double? get ratio =>
      status == DashboardBalanceMonthSpendingLevelStatus.available
      ? currentExpenseMinor * 2 / referenceExpenseTimesTwo!
      : null;
  double? get rawRatio => ratio;
  int get presentationId => Object.hash(
    identity,
    currentExpenseMinor,
    referenceExpenseTimesTwo,
    comparableMonthCount,
    status,
  );
}

abstract final class DashboardBalanceMonthSpendingLevelProjection {
  static DashboardBalanceMonthSpendingLevelPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required MonthScope timeScope,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
    required LocalDate logicalAsOfDate,
  }) {
    final year = timeScope.value.year, month = timeScope.value.month;
    final targetIndex = year * 12 + month,
        nowIndex = logicalAsOfDate.year * 12 + logicalAsOfDate.month;
    if (targetIndex > nowIndex) {
      return DashboardBalanceMonthSpendingLevelPresentation(
        identity: identity,
        currentExpenseMinor: 0,
        referenceExpenseTimesTwo: null,
        comparableMonthCount: 0,
        status: DashboardBalanceMonthSpendingLevelStatus.future,
      );
    }
    final partial = targetIndex == nowIndex;

    final starts = [
      for (var offset = 1; offset <= 3; offset++)
        DateTime.utc(year, month - offset),
    ];
    final totals = List<int>.filled(4, 0);
    int? earliestDay;
    for (final entry in incomeEntries) {
      final day = entry.bookedLocalEpochDay;
      if (earliestDay == null || day < earliestDay) earliestDay = day;
    }
    for (final entry in expenseEntries) {
      final day = entry.bookedLocalEpochDay;
      if (earliestDay == null || day < earliestDay) earliestDay = day;
      final date = DateTime.utc(1970).add(Duration(days: day));
      final index = date.year * 12 + date.month;
      final offset = targetIndex - index;
      if (offset < 0 || offset > 3) continue;
      if (partial && date.day > logicalAsOfDate.day) continue;
      totals[offset] += entry.amountMinor.abs();
    }
    // Exclude a potentially partial first ledger month unless coverage starts
    // on its first day. Later empty months are genuine comparable zeros.
    final oldest = earliestDay == null
        ? null
        : DateTime.utc(1970).add(Duration(days: earliestDay));
    final oldestIndex = oldest == null ? null : oldest.year * 12 + oldest.month;
    final references = <int>[];
    for (var i = 0; i < starts.length; i++) {
      final reference = starts[i];
      if (oldestIndex != null &&
          (reference.year * 12 + reference.month > oldestIndex ||
              (reference.year * 12 + reference.month == oldestIndex &&
                  oldest!.day == 1))) {
        references.add(totals[i + 1]);
      }
    }
    references.sort();
    final median = references.length == 3 ? references[1] * 2 : null;
    return DashboardBalanceMonthSpendingLevelPresentation(
      identity: identity,
      currentExpenseMinor: totals[0],
      referenceExpenseTimesTwo: median,
      comparableMonthCount: references.length,
      status: median == null
          ? DashboardBalanceMonthSpendingLevelStatus.insufficientHistory
          : median == 0
          ? DashboardBalanceMonthSpendingLevelStatus.zeroReference
          : DashboardBalanceMonthSpendingLevelStatus.available,
    );
  }
}

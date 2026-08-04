import '../../query/application/dashboard_presentation_store.dart';
import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import 'dashboard_log_viewport_state.dart';

export 'dashboard_log_viewport_state.dart';

/// Pure snapshot-to-view-model adapter. It has no repository, navigation,
/// paging, or widget side effects and can be exercised independently.
abstract final class DashboardLogViewModelProjector {
  static DashboardLogViewportState presentSnapshot(
    DashboardPresentationSnapshot snapshot,
  ) {
    final groupsByDate = <LocalDate, List<DashboardLedgerEntry>>{};
    for (final entry in snapshot.entries) {
      final date = _dateFromEpochDay(entry.bookedLocalEpochDay);
      groupsByDate.putIfAbsent(date, () => <DashboardLedgerEntry>[]).add(entry);
    }
    final dates = groupsByDate.keys.toList()
      ..sort((left, right) => _epochDay(right).compareTo(_epochDay(left)));
    final groups = <DashboardDayLogGroupViewModel>[];
    for (final date in dates) {
      final rows = groupsByDate[date]!
        ..sort((left, right) {
          final time = right.bookedLocalTimeMinutes.compareTo(
            left.bookedLocalTimeMinutes,
          );
          return time == 0 ? right.id.compareTo(left.id) : time;
        });
      groups.add(
        DashboardDayLogGroupViewModel(
          dateKey: date.isoString,
          dayLabel: DashboardTimeLabelFormatter.date(
            YearMonth(year: date.year, month: date.month),
            date.day,
          ),
          rows: List.unmodifiable(rows.map(presentRow)),
        ),
      );
    }
    final scope = snapshot.scope;
    final direction = scope?.direction ?? _directionFromKey(snapshot.queryKey);
    return DashboardLogViewportState(
      queryKey: snapshot.queryKey,
      revision: snapshot.coreRevision,
      groups: groups,
      entryCount: snapshot.entryCount ?? 0,
      nextCursor: snapshot.nextCursor,
      isPreview: snapshot.isPreview,
      isCommitted: !snapshot.isPreview,
      direction: direction,
    );
  }

  static DashboardLogRowViewModel presentRow(DashboardLedgerEntry entry) {
    final isExpense = entry.direction == LedgerDirection.expense.name;
    final amount = SummaryMetricsPresentation.formatTotalMinor(
      entry.amountMinor.abs(),
    );
    final formattedAmount = isExpense && entry.amountMinor != 0
        ? '-$amount'
        : amount;
    final displayName = _displayName(entry);
    final category = entry.categoryDisplayName?.trim();
    final categoryDisplayName = category == null || category.isEmpty
        ? 'Kategorizálatlan'
        : category;
    return DashboardLogRowViewModel(
      entryId: entry.id,
      displayName: displayName,
      categoryDisplayName: categoryDisplayName,
      formattedAmount: formattedAmount,
      displayTime: _formatLocalTime(entry.bookedLocalTimeMinutes),
      amountStyle: isExpense ? LogAmountStyle.expense : LogAmountStyle.income,
      categoryColorId: entry.categoryColorId ?? 'fallback',
      categoryIconId: entry.categoryIconId ?? 'fallback',
      semanticLabel:
          '$displayName, $formattedAmount, '
          '${isExpense ? 'kiadás' : 'bevétel'}, $categoryDisplayName',
    );
  }

  static String _displayName(DashboardLedgerEntry entry) {
    final partner = entry.partnerDisplayName?.trim();
    if (partner != null && partner.isNotEmpty) return partner;
    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    final category = entry.categoryDisplayName?.trim();
    if (category != null && category.isNotEmpty) return category;
    return 'Tranzakció';
  }

  static String _formatLocalTime(int minutes) {
    final normalized = minutes.clamp(0, (24 * 60) - 1);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static LocalDate _dateFromEpochDay(int epochDay) {
    final date = DateTime.utc(1970).add(Duration(days: epochDay));
    return LocalDate(year: date.year, month: date.month, day: date.day);
  }

  static int _epochDay(LocalDate date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;

  static LedgerDirection _directionFromKey(LedgerQueryKey key) =>
      key.value.startsWith('income|')
      ? LedgerDirection.income
      : LedgerDirection.expense;
}

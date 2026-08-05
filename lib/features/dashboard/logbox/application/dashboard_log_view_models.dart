import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import 'dashboard_log_viewport_state.dart';

export 'dashboard_log_viewport_state.dart';

/// Pure snapshot-to-view-model adapter. It has no repository, navigation,
/// paging, or widget side effects and can be exercised independently.
abstract final class DashboardLogViewModelProjector {
  /// Projects rows that already arrive in stable date/time/id descending
  /// order. This performs one contiguous pass and never groups or sorts.
  static DashboardLogViewportState presentPreparedOrdered({
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> entries,
    required int entryCount,
    required Map<String, Object?>? nextCursor,
  }) {
    final groups = <DashboardDayLogGroupViewModel>[];
    LocalDate? currentDate;
    var currentRows = <DashboardLogRowViewModel>[];

    void flushGroup() {
      final date = currentDate;
      if (date == null) return;
      groups.add(
        DashboardDayLogGroupViewModel(
          dateKey: date.isoString,
          dayLabel: DashboardTimeLabelFormatter.date(
            YearMonth(year: date.year, month: date.month),
            date.day,
          ),
          rows: currentRows,
        ),
      );
    }

    for (final entry in entries) {
      final date = _dateFromEpochDay(entry.bookedLocalEpochDay);
      if (currentDate != date) {
        flushGroup();
        currentDate = date;
        currentRows = <DashboardLogRowViewModel>[];
      }
      currentRows.add(presentRow(entry));
    }
    flushGroup();

    return DashboardLogViewportState(
      queryKey: scope.key,
      revision: revision,
      groups: groups,
      entryCount: entryCount,
      nextCursor: nextCursor,
      direction: scope.direction,
    );
  }

  static DashboardLogRowViewModel presentRow(DashboardLedgerEntry entry) {
    final isExpense = entry.direction == LedgerDirection.expense.name;
    final amount = DashboardPreparedFormatter.amountMinor(
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
}

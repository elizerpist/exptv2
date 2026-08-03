import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_repository.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/dashboard_log_models.dart';

/// Immutable, preformatted values consumed by the LogBox widgets.
///
/// Projection happens while a committed page is bound or appended, never from
/// a scrolling widget build. This keeps formatters and name fallback logic out
/// of the render hot path.
enum LogAmountStyle { income, expense }

@immutable
class DashboardLogRowViewModel {
  const DashboardLogRowViewModel({
    required this.entryId,
    required this.displayName,
    required this.categoryDisplayName,
    required this.formattedAmount,
    required this.displayTime,
    required this.amountStyle,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.semanticLabel,
  });

  final String entryId;
  final String displayName;
  final String categoryDisplayName;
  final String formattedAmount;
  final String displayTime;
  final LogAmountStyle amountStyle;
  final String categoryColorId;
  final String categoryIconId;
  final String semanticLabel;
}

@immutable
class DashboardDayLogGroupViewModel {
  const DashboardDayLogGroupViewModel({
    required this.dateKey,
    required this.dayLabel,
    required this.rows,
  });

  final String dateKey;
  final String dayLabel;
  final List<DashboardLogRowViewModel> rows;
}

abstract final class DashboardLogViewModelProjector {
  static List<DashboardDayLogGroupViewModel> presentGroups(
    List<DashboardDayLogGroup> groups,
  ) => List<DashboardDayLogGroupViewModel>.unmodifiable(
    groups.map(presentGroup),
  );

  static DashboardDayLogGroupViewModel presentGroup(
    DashboardDayLogGroup group,
  ) {
    final date = group.localDate;
    return DashboardDayLogGroupViewModel(
      dateKey: date.isoString,
      dayLabel: DashboardTimeLabelFormatter.date(
        YearMonth(year: date.year, month: date.month),
        date.day,
      ),
      rows: List<DashboardLogRowViewModel>.unmodifiable(
        group.rows.map(presentRow),
      ),
    );
  }

  static DashboardLogRowViewModel presentRow(DashboardLedgerEntry entry) {
    final isExpense = entry.direction == 'expense';
    final absoluteAmount = entry.amountMinor.abs();
    final rawFormatted = SummaryMetricsPresentation.formatTotalMinor(
      absoluteAmount,
    );
    final formattedAmount = isExpense && absoluteAmount != 0
        ? '-$rawFormatted'
        : rawFormatted;
    final displayName = _displayName(entry);
    final category = entry.categoryDisplayName?.trim().isNotEmpty == true
        ? entry.categoryDisplayName!.trim()
        : 'Kategorizálatlan';
    return DashboardLogRowViewModel(
      entryId: entry.id,
      displayName: displayName,
      categoryDisplayName: category,
      formattedAmount: formattedAmount,
      displayTime: _formatLocalTime(entry.bookedLocalTimeMinutes),
      amountStyle: isExpense ? LogAmountStyle.expense : LogAmountStyle.income,
      categoryColorId: entry.categoryColorId ?? 'fallback',
      categoryIconId: entry.categoryIconId ?? 'fallback',
      semanticLabel:
          '$displayName, $formattedAmount, ${isExpense ? 'kiadás' : 'bevétel'}, $category',
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
}

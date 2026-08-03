import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_presentation_store.dart';
import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

/// Immutable, preformatted values consumed by LogBox widgets.
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

/// The complete immutable LogBox presentation derived from one dashboard
/// snapshot. The viewport never receives raw transaction DTOs.
@immutable
class DashboardLogViewportState {
  DashboardLogViewportState({
    required this.queryKey,
    required this.revision,
    required List<DashboardDayLogGroupViewModel> groups,
    required this.entryCount,
    required Map<String, Object?>? nextCursor,
    required this.isPreview,
    required this.isCommitted,
    required this.direction,
  }) : groups = List.unmodifiable(groups),
       nextCursor = nextCursor == null ? null : Map.unmodifiable(nextCursor);

  DashboardLogViewportState._preserve({
    required this.queryKey,
    required this.revision,
    required this.groups,
    required this.entryCount,
    required this.nextCursor,
    required this.isPreview,
    required this.isCommitted,
    required this.direction,
  });

  final LedgerQueryKey queryKey;
  final int? revision;
  final List<DashboardDayLogGroupViewModel> groups;
  final int entryCount;
  final Map<String, Object?>? nextCursor;
  final bool isPreview;
  final bool isCommitted;
  final LedgerDirection direction;

  bool get hasNextPage => nextCursor != null && isCommitted;

  DashboardLogViewportState copyWith({
    LedgerQueryKey? queryKey,
    int? revision,
    List<DashboardDayLogGroupViewModel>? groups,
    int? entryCount,
    Map<String, Object?>? nextCursor,
    bool clearNextCursor = false,
    bool? isPreview,
    bool? isCommitted,
    LedgerDirection? direction,
  }) => DashboardLogViewportState._preserve(
    queryKey: queryKey ?? this.queryKey,
    revision: revision ?? this.revision,
    groups: groups ?? this.groups,
    entryCount: entryCount ?? this.entryCount,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    isPreview: isPreview ?? this.isPreview,
    isCommitted: isCommitted ?? this.isCommitted,
    direction: direction ?? this.direction,
  );

  bool hasSameVisualValue(DashboardLogViewportState other) {
    if (queryKey != other.queryKey ||
        revision != other.revision ||
        entryCount != other.entryCount ||
        direction != other.direction ||
        groups.length != other.groups.length) {
      return false;
    }
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
      final leftGroup = groups[groupIndex];
      final rightGroup = other.groups[groupIndex];
      if (leftGroup.dateKey != rightGroup.dateKey ||
          leftGroup.dayLabel != rightGroup.dayLabel ||
          leftGroup.rows.length != rightGroup.rows.length) {
        return false;
      }
      for (var rowIndex = 0; rowIndex < leftGroup.rows.length; rowIndex += 1) {
        final left = leftGroup.rows[rowIndex];
        final right = rightGroup.rows[rowIndex];
        if (left.entryId != right.entryId ||
            left.displayName != right.displayName ||
            left.categoryDisplayName != right.categoryDisplayName ||
            left.formattedAmount != right.formattedAmount ||
            left.displayTime != right.displayTime ||
            left.amountStyle != right.amountStyle ||
            left.categoryColorId != right.categoryColorId ||
            left.categoryIconId != right.categoryIconId) {
          return false;
        }
      }
    }
    return true;
  }
}

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

import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';

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
  DashboardDayLogGroupViewModel({
    required this.dateKey,
    required this.dayLabel,
    required List<DashboardLogRowViewModel> rows,
  }) : rows = List<DashboardLogRowViewModel>.unmodifiable(rows);

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
    required this.direction,
  }) : groups = List<DashboardDayLogGroupViewModel>.unmodifiable(groups),
       nextCursor = nextCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(nextCursor);

  const DashboardLogViewportState._preserve({
    required this.queryKey,
    required this.revision,
    required this.groups,
    required this.entryCount,
    required this.nextCursor,
    required this.direction,
  });

  final LedgerQueryKey queryKey;
  final int? revision;
  final List<DashboardDayLogGroupViewModel> groups;
  final int entryCount;
  final Map<String, Object?>? nextCursor;
  final LedgerDirection direction;

  DashboardLogViewportState copyWith({
    LedgerQueryKey? queryKey,
    int? revision,
    List<DashboardDayLogGroupViewModel>? groups,
    int? entryCount,
    Map<String, Object?>? nextCursor,
    bool clearNextCursor = false,
    LedgerDirection? direction,
  }) => DashboardLogViewportState._preserve(
    queryKey: queryKey ?? this.queryKey,
    revision: revision ?? this.revision,
    groups: groups ?? this.groups,
    entryCount: entryCount ?? this.entryCount,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
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

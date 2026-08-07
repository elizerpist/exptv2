import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';

/// Immutable, preformatted values consumed by LogBox widgets.
enum LogAmountStyle { income, expense }

@immutable
class DashboardLogRowViewModel {
  DashboardLogRowViewModel({
    required this.entryId,
    required this.displayName,
    required this.categoryDisplayName,
    required this.formattedAmount,
    required this.displayTime,
    required this.amountStyle,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.semanticLabel,
  }) : categoryColorHandle = CategoryColorCatalog.handleOf(categoryColorId),
       categoryIconHandle = CategoryIconCatalog.handleOf(categoryIconId);

  final String entryId;
  final String displayName;
  final String categoryDisplayName;
  final String formattedAmount;
  final String displayTime;
  final LogAmountStyle amountStyle;
  final String categoryColorId;
  final String categoryIconId;
  final int categoryColorHandle;
  final int categoryIconHandle;
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

/// One immutable transaction slot of the LogBox's single lazy sliver.
///
/// A group's optional gap and header are decoration inside its first row slot.
/// Consequently 24 monthly preview rows remain 24 lazy children instead of
/// expanding to as many as 71 header/row/gap children.
@immutable
final class DashboardLogViewportItemViewModel {
  const DashboardLogViewportItemViewModel({
    required this.stableId,
    required this.row,
    required this.showSeparator,
    required this.dayLabel,
    required this.hasGroupGapBefore,
    required this.groupIndex,
    required this.flatRowIndex,
  });

  factory DashboardLogViewportItemViewModel.row({
    required DashboardLogRowViewModel row,
    required bool showSeparator,
    required String? dayLabel,
    required bool hasGroupGapBefore,
    required int groupIndex,
    required int flatRowIndex,
  }) => DashboardLogViewportItemViewModel(
    stableId: 'row:${row.entryId}',
    row: row,
    showSeparator: showSeparator,
    dayLabel: dayLabel,
    hasGroupGapBefore: hasGroupGapBefore,
    groupIndex: groupIndex,
    flatRowIndex: flatRowIndex,
  );

  final String stableId;
  final DashboardLogRowViewModel row;
  final bool showSeparator;
  final String? dayLabel;
  final bool hasGroupGapBefore;
  final int groupIndex;
  final int flatRowIndex;
}

/// Prepared group geometry expressed as row/header counts rather than pixels.
/// The painter resolves these against the canonical LogBox design tokens.
@immutable
final class DashboardLogGroupLayoutViewModel {
  const DashboardLogGroupLayoutViewModel({
    required this.dateKey,
    required this.groupIndex,
    required this.precedingRowCount,
    required this.rowCount,
  });

  final String dateKey;
  final int groupIndex;
  final int precedingRowCount;
  final int rowCount;
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
           : Map<String, Object?>.unmodifiable(nextCursor),
       flatItems = _flatten(groups),
       groupLayouts = _groupLayouts(groups),
       stableRowIdentities = _rowIdentities(groups),
       stableAssetIdentities = _assetIdentities(groups),
       viewportId = _viewportId(
         queryKey: queryKey,
         revision: revision,
         entryCount: entryCount,
         direction: direction,
         groups: groups,
         nextCursor: nextCursor,
       );

  final LedgerQueryKey queryKey;
  final int? revision;
  final List<DashboardDayLogGroupViewModel> groups;
  final List<DashboardLogViewportItemViewModel> flatItems;
  final List<DashboardLogGroupLayoutViewModel> groupLayouts;
  final List<String> stableRowIdentities;
  final List<String> stableAssetIdentities;
  final int viewportId;
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
  }) => DashboardLogViewportState(
    queryKey: queryKey ?? this.queryKey,
    revision: revision ?? this.revision,
    groups: groups ?? this.groups,
    entryCount: entryCount ?? this.entryCount,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    direction: direction ?? this.direction,
  );

  bool hasSameVisualValue(DashboardLogViewportState other) =>
      viewportId == other.viewportId;

  static List<DashboardLogViewportItemViewModel> _flatten(
    List<DashboardDayLogGroupViewModel> groups,
  ) {
    final items = <DashboardLogViewportItemViewModel>[];
    var flatRowIndex = 0;
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
      final group = groups[groupIndex];
      for (var rowIndex = 0; rowIndex < group.rows.length; rowIndex += 1) {
        items.add(
          DashboardLogViewportItemViewModel.row(
            row: group.rows[rowIndex],
            showSeparator: rowIndex != 0,
            dayLabel: rowIndex == 0 ? group.dayLabel : null,
            hasGroupGapBefore: groupIndex != 0 && rowIndex == 0,
            groupIndex: groupIndex,
            flatRowIndex: flatRowIndex,
          ),
        );
        flatRowIndex += 1;
      }
    }
    return List<DashboardLogViewportItemViewModel>.unmodifiable(items);
  }

  static List<DashboardLogGroupLayoutViewModel> _groupLayouts(
    List<DashboardDayLogGroupViewModel> groups,
  ) {
    var precedingRows = 0;
    final result = <DashboardLogGroupLayoutViewModel>[];
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      result.add(
        DashboardLogGroupLayoutViewModel(
          dateKey: group.dateKey,
          groupIndex: index,
          precedingRowCount: precedingRows,
          rowCount: group.rows.length,
        ),
      );
      precedingRows += group.rows.length;
    }
    return List<DashboardLogGroupLayoutViewModel>.unmodifiable(result);
  }

  static List<String> _rowIdentities(
    List<DashboardDayLogGroupViewModel> groups,
  ) => List<String>.unmodifiable(
    groups.expand((group) => group.rows.map((row) => row.entryId)),
  );

  static List<String> _assetIdentities(
    List<DashboardDayLogGroupViewModel> groups,
  ) => List<String>.unmodifiable(<String>{
    for (final group in groups)
      for (final row in group.rows)
        '${row.categoryColorId}|${row.categoryIconId}',
  });

  static int _viewportId({
    required LedgerQueryKey queryKey,
    required int? revision,
    required int entryCount,
    required LedgerDirection direction,
    required List<DashboardDayLogGroupViewModel> groups,
    required Map<String, Object?>? nextCursor,
  }) => Object.hash(
    queryKey,
    revision,
    entryCount,
    direction,
    Object.hashAll(
      groups.map(
        (group) => Object.hash(
          group.dateKey,
          group.dayLabel,
          Object.hashAll(group.rows.map((row) => row.entryId)),
        ),
      ),
    ),
    nextCursor?['entryId'],
  );
}

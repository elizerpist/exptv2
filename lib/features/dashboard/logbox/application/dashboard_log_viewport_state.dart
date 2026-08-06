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

enum DashboardLogViewportItemKind { dayHeader, row, groupGap }

/// One immutable, already ordered child of the LogBox's single lazy sliver.
///
/// Flattening happens while prepared data is projected. The widget therefore
/// performs neither group traversal nor per-frame list construction when the
/// selected rail period changes.
@immutable
final class DashboardLogViewportItemViewModel {
  const DashboardLogViewportItemViewModel._({
    required this.kind,
    required this.stableId,
    this.dayLabel,
    this.row,
    this.showSeparator = false,
  });

  const DashboardLogViewportItemViewModel.dayHeader({
    required String dateKey,
    required String dayLabel,
  }) : this._(
         kind: DashboardLogViewportItemKind.dayHeader,
         stableId: 'day-header:$dateKey',
         dayLabel: dayLabel,
       );

  factory DashboardLogViewportItemViewModel.row({
    required DashboardLogRowViewModel row,
    required bool showSeparator,
  }) => DashboardLogViewportItemViewModel._(
    kind: DashboardLogViewportItemKind.row,
    stableId: 'row:${row.entryId}',
    row: row,
    showSeparator: showSeparator,
  );

  const DashboardLogViewportItemViewModel.groupGap({required String dateKey})
    : this._(
        kind: DashboardLogViewportItemKind.groupGap,
        stableId: 'group-gap:$dateKey',
      );

  final DashboardLogViewportItemKind kind;
  final String stableId;
  final String? dayLabel;
  final DashboardLogRowViewModel? row;
  final bool showSeparator;
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
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
      final group = groups[groupIndex];
      items.add(
        DashboardLogViewportItemViewModel.dayHeader(
          dateKey: group.dateKey,
          dayLabel: group.dayLabel,
        ),
      );
      for (var rowIndex = 0; rowIndex < group.rows.length; rowIndex += 1) {
        items.add(
          DashboardLogViewportItemViewModel.row(
            row: group.rows[rowIndex],
            showSeparator: rowIndex != 0,
          ),
        );
      }
      if (groupIndex < groups.length - 1) {
        items.add(
          DashboardLogViewportItemViewModel.groupGap(dateKey: group.dateKey),
        );
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

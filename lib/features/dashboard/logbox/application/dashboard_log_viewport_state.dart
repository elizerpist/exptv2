import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

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
    this.partnerAvatarColorId = 'fallback',
    this.partnerAvatarIconId = 'fallback',
    required this.semanticLabel,
    this.isPendingGhost = false,
    this.hasGhostOrigin = false,
    this.hasCategoryOverride = false,
    this.amountIsUnknown = false,
    this.categoryId = '',
    this.partnerId = '',
    this.partnerDisplayName = '',
    this.visualIdentity = 0,
    this.entryRevision = 0,
  }) : categoryColorHandle = CategoryColorCatalog.handleOf(categoryColorId),
       categoryIconHandle = CategoryIconCatalog.handleOf(categoryIconId),
       partnerAvatarColorHandle = CategoryColorCatalog.handleOf(
         partnerAvatarColorId,
       ),
       partnerAvatarIconHandle = CategoryIconCatalog.handleOf(
         partnerAvatarIconId,
       ),
       textLayoutId = Object.hash(
         entryId,
         displayName,
         categoryDisplayName,
         formattedAmount,
         displayTime,
         amountStyle,
         isPendingGhost,
         hasGhostOrigin,
         hasCategoryOverride,
         categoryId,
         partnerId,
         categoryColorId,
         categoryIconId,
         partnerAvatarColorId,
         partnerAvatarIconId,
         visualIdentity,
       );

  /// Rich per-row presentation is intentionally created only by a bounded
  /// exact LogBox projection, never by whole-index binary decoding.
  factory DashboardLogRowViewModel.fromLedgerEntry(DashboardLedgerEntry entry) {
    final isExpense = entry.direction == LedgerDirection.expense.name;
    final amount = entry.amountIsUnknown
        ? 'Változó összeg'
        : DashboardPreparedFormatter.amountMinor(entry.amountMinor.abs());
    final formattedAmount =
        !entry.amountIsUnknown && isExpense && entry.amountMinor != 0
        ? '-$amount'
        : amount;
    final displayName = _displayName(entry);
    final category = entry.categoryDisplayName?.trim();
    final resolvedCategoryDisplayName = category == null || category.isEmpty
        ? 'Kategorizálatlan'
        : category;
    final categoryDisplayName = entry.isPendingGhost
        ? 'Várható · $resolvedCategoryDisplayName'
        : resolvedCategoryDisplayName;
    return DashboardLogRowViewModel(
      entryId: entry.id,
      displayName: displayName,
      categoryDisplayName: categoryDisplayName,
      formattedAmount: formattedAmount,
      displayTime: _formatLocalTime(entry.bookedLocalTimeMinutes),
      amountStyle: isExpense ? LogAmountStyle.expense : LogAmountStyle.income,
      categoryColorId: entry.categoryColorId ?? 'fallback',
      categoryIconId: entry.categoryIconId ?? 'fallback',
      partnerAvatarColorId: entry.partnerAvatarColorId ?? 'fallback',
      partnerAvatarIconId: entry.partnerAvatarIconId ?? 'fallback',
      categoryId: entry.categoryId,
      partnerId: entry.partnerId,
      partnerDisplayName: entry.partnerDisplayName ?? displayName,
      visualIdentity: entry.visualIdentity,
      entryRevision: entry.visualRevision,
      semanticLabel:
          '${entry.isPendingGhost ? 'Várható, ' : ''}$displayName, $formattedAmount, '
          '${isExpense ? 'kiadás' : 'bevétel'}, $categoryDisplayName',
      isPendingGhost: entry.isPendingGhost,
      hasGhostOrigin: entry.recurrenceOccurrenceId != null,
      hasCategoryOverride: entry.assignmentMode == 'entryOverride',
      amountIsUnknown: entry.amountIsUnknown,
    );
  }

  final String entryId;
  final String displayName;
  final String categoryDisplayName;
  final String formattedAmount;
  final String displayTime;
  final LogAmountStyle amountStyle;
  final String categoryColorId;
  final String categoryIconId;
  final String partnerAvatarColorId;
  final String partnerAvatarIconId;

  /// Semantic source identities are retained with the prepared row so an
  /// interaction can request transient focus without an entry-id lookup.
  final String categoryId;
  final String partnerId;
  final String partnerDisplayName;
  final int visualIdentity;
  final int entryRevision;
  final int categoryColorHandle;
  final int categoryIconHandle;
  final int partnerAvatarColorHandle;
  final int partnerAvatarIconHandle;
  final bool isPendingGhost;
  final bool hasGhostOrigin;
  final bool hasCategoryOverride;
  final bool amountIsUnknown;

  /// Prepared once with the immutable row so paint-time lookup is O(1).
  final int textLayoutId;
  final String semanticLabel;

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

  /// Reuses every formatted financial field while replacing the Core-resolved
  /// visual metadata of one persisted entry.  This is intentionally a row
  /// paint projection, not a substitute for the following revision-owned
  /// index and aggregate publication.
  DashboardLogRowViewModel withVisualPatch(DashboardLedgerVisualPatch patch) {
    if (patch.entryId != entryId) {
      throw ArgumentError.value(patch.entryId, 'patch.entryId');
    }
    final categoryDisplay = isPendingGhost
        ? 'Várható · ${patch.categoryDisplayName}'
        : patch.categoryDisplayName;
    final directionLabel = amountStyle == LogAmountStyle.expense
        ? 'kiadás'
        : 'bevétel';
    return DashboardLogRowViewModel(
      entryId: entryId,
      displayName: patch.partnerDisplayName,
      categoryDisplayName: categoryDisplay,
      formattedAmount: formattedAmount,
      displayTime: displayTime,
      amountStyle: amountStyle,
      categoryColorId: patch.categoryColorId,
      categoryIconId: patch.categoryIconId,
      partnerAvatarColorId: patch.partnerAvatarColorId,
      partnerAvatarIconId: patch.partnerAvatarIconId,
      categoryId: patch.categoryId,
      partnerId: partnerId,
      partnerDisplayName: patch.partnerDisplayName,
      visualIdentity: patch.visualIdentity,
      entryRevision: patch.entryRevision,
      semanticLabel:
          '${isPendingGhost ? 'Várható, ' : ''}${patch.partnerDisplayName}, '
          '$formattedAmount, $directionLabel, $categoryDisplay',
      isPendingGhost: isPendingGhost,
      hasGhostOrigin: hasGhostOrigin,
      hasCategoryOverride: patch.assignmentMode == 'entryOverride',
      amountIsUnknown: amountIsUnknown,
    );
  }
}

/// Bounded, immutable-index-owned rich row projection pool.
///
/// The binary decoder keeps native rows compact. Exact scene windows project
/// only the rows they consume through this pool, so overlapping all/month/day
/// scopes share one immutable row presentation without making every sparse
/// frame eager. Eviction only drops the pool's lookup reference; any active
/// viewport/scene still owns its immutable row object directly.
enum DashboardLogVisualPatchResult {
  applied,
  alreadyCurrent,
  staleEntryRevision,
  rowNotFound,
  financialIdentityMismatch,
}

final class DashboardLogRowProjectionCache {
  DashboardLogRowProjectionCache(
    List<DashboardLedgerEntry> rows, {
    this.maximumEntries = 4096,
  }) : _rows = List<DashboardLedgerEntry>.unmodifiable(rows) {
    if (maximumEntries <= 0) {
      throw ArgumentError.value(maximumEntries, 'maximumEntries');
    }
  }

  final List<DashboardLedgerEntry> _rows;
  final int maximumEntries;
  late final Map<String, int> _rowIndexById = <String, int>{
    for (var index = 0; index < _rows.length; index += 1)
      _rows[index].id: index,
  };
  final Map<int, DashboardLedgerEntry> _visualOverlays =
      <int, DashboardLedgerEntry>{};
  final Map<int, DashboardLogRowViewModel> _projected =
      <int, DashboardLogRowViewModel>{};
  final Map<String, int> _acceptedVisualRevisions = <String, int>{};
  int _visualGeneration = 0;
  int _newProjectionCount = 0;
  int _reusedProjectionCount = 0;
  int _projectionMicros = 0;

  int get projectedCount => _projected.length;
  int get newProjectionCount => _newProjectionCount;
  int get reusedProjectionCount => _reusedProjectionCount;
  int get projectionMicros => _projectionMicros;
  int get visualGeneration => _visualGeneration;

  DashboardLedgerEntry entryAt(int index) {
    if (index < 0 || index >= _rows.length) {
      throw const FormatException('Prepared row reference is out of range.');
    }
    return _visualOverlays[index] ?? _rows[index];
  }

  /// Admits the resolved, persisted visual state once for every resident
  /// ghost-mode projection that shares this row table. It intentionally does
  /// not edit financial membership, ordering or amounts: the following Core
  /// revision still owns those values.
  DashboardLogVisualPatchResult acceptVisualPatch(
    DashboardLedgerVisualPatch patch,
  ) {
    final index = _rowIndexById[patch.entryId];
    if (index == null) return DashboardLogVisualPatchResult.rowNotFound;
    final current = entryAt(index);
    final acceptedRevision =
        _acceptedVisualRevisions[patch.entryId] ?? current.visualRevision;
    if (patch.entryRevision < acceptedRevision) {
      return DashboardLogVisualPatchResult.staleEntryRevision;
    }
    if (patch.entryRevision == acceptedRevision &&
        current.visualIdentity == patch.visualIdentity) {
      return DashboardLogVisualPatchResult.alreadyCurrent;
    }
    if (current.direction != patch.direction ||
        current.amountMinor != patch.amountMinor ||
        current.bookedLocalEpochDay != patch.bookedLocalEpochDay ||
        current.bookedLocalTimeMinutes != patch.bookedLocalTimeMinutes) {
      return DashboardLogVisualPatchResult.financialIdentityMismatch;
    }
    final patched = current.withVisualPatch(patch);
    _visualOverlays[index] = patched;
    _acceptedVisualRevisions[patch.entryId] = patch.entryRevision;
    // A pre-projected row may already be used by another prepared ghost
    // mode. Replace only that single row; no icon/paragraph work for its
    // unaffected neighbours is repeated.
    if (_projected.containsKey(index)) {
      _projected[index] = DashboardLogRowViewModel.fromLedgerEntry(patched);
    }
    _visualGeneration += 1;
    return DashboardLogVisualPatchResult.applied;
  }

  DashboardLogRowViewModel projectAt(int index) {
    final existing = _projected.remove(index);
    if (existing != null) {
      _reusedProjectionCount += 1;
      _projected[index] = existing;
      return existing;
    }
    final started = Stopwatch()..start();
    final row = DashboardLogRowViewModel.fromLedgerEntry(entryAt(index));
    started.stop();
    _newProjectionCount += 1;
    _projectionMicros += started.elapsedMicroseconds;
    _projected[index] = row;
    if (_projected.length > maximumEntries) {
      _projected.remove(_projected.keys.first);
    }
    return row;
  }
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

/// Immutable, compact geometry for the bounded Phase-A preview payload.
///
/// The rich LogBox projection deliberately remains deferred until a scene
/// owner prepares it.  A visible Phase-A frame must nevertheless use the
/// exact same day-header, group-gap and row-origin geometry as that future
/// rich/committed rendering.  This table is therefore assembled with the
/// prepared frame, never by a painter or live interaction tick.
@immutable
final class DashboardLogSemanticPreviewGeometry {
  DashboardLogSemanticPreviewGeometry._({
    required List<DashboardLogSemanticPreviewSlot> slots,
    required List<DashboardLogSemanticPreviewGroup> groups,
  }) : slots = List<DashboardLogSemanticPreviewSlot>.unmodifiable(slots),
       groups = List<DashboardLogSemanticPreviewGroup>.unmodifiable(groups);

  factory DashboardLogSemanticPreviewGeometry.fromGroups(
    List<DashboardDayLogGroupViewModel> source,
  ) {
    final groups = <DashboardLogSemanticPreviewGroup>[];
    final slots = <DashboardLogSemanticPreviewSlot>[];
    var precedingRowCount = 0;
    for (var groupIndex = 0; groupIndex < source.length; groupIndex += 1) {
      final group = source[groupIndex];
      final rowCount = group.rows.length;
      groups.add(
        DashboardLogSemanticPreviewGroup(
          groupIndex: groupIndex,
          precedingRowCount: precedingRowCount,
          rowCount: rowCount,
          dayLabel: group.dayLabel,
        ),
      );
      for (var rowIndex = 0; rowIndex < rowCount; rowIndex += 1) {
        slots.add(
          DashboardLogSemanticPreviewSlot(
            ordinal: precedingRowCount + rowIndex,
            groupIndex: groupIndex,
            precedingRowCount: precedingRowCount,
            rowIndexInGroup: rowIndex,
            groupRowCount: rowCount,
            dayLabel: rowIndex == 0 ? group.dayLabel : null,
          ),
        );
      }
      precedingRowCount += rowCount;
    }
    return DashboardLogSemanticPreviewGeometry._(slots: slots, groups: groups);
  }

  /// Builds only date/group coordinates from compact prepared ledger rows.
  /// It deliberately does not project row view-models, format text, or create
  /// paragraph resources.
  factory DashboardLogSemanticPreviewGeometry.fromPreparedReferences({
    required DashboardLogRowProjectionCache rowProjectionCache,
    required List<int> rowIndices,
  }) {
    final groupStarts = <int>[];
    final groupDates = <LocalDate>[];
    LocalDate? previousDate;
    for (var ordinal = 0; ordinal < rowIndices.length; ordinal += 1) {
      final entry = rowProjectionCache.entryAt(rowIndices[ordinal]);
      final date = _dateFromEpochDay(entry.bookedLocalEpochDay);
      if (date != previousDate) {
        groupStarts.add(ordinal);
        groupDates.add(date);
        previousDate = date;
      }
    }

    final groups = <DashboardLogSemanticPreviewGroup>[];
    final slots = <DashboardLogSemanticPreviewSlot>[];
    for (var groupIndex = 0; groupIndex < groupStarts.length; groupIndex += 1) {
      final precedingRowCount = groupStarts[groupIndex];
      final end = groupIndex + 1 < groupStarts.length
          ? groupStarts[groupIndex + 1]
          : rowIndices.length;
      final rowCount = end - precedingRowCount;
      final date = groupDates[groupIndex];
      final dayLabel = DashboardTimeLabelFormatter.date(
        YearMonth(year: date.year, month: date.month),
        date.day,
      );
      groups.add(
        DashboardLogSemanticPreviewGroup(
          groupIndex: groupIndex,
          precedingRowCount: precedingRowCount,
          rowCount: rowCount,
          dayLabel: dayLabel,
        ),
      );
      for (var rowIndex = 0; rowIndex < rowCount; rowIndex += 1) {
        slots.add(
          DashboardLogSemanticPreviewSlot(
            ordinal: precedingRowCount + rowIndex,
            groupIndex: groupIndex,
            precedingRowCount: precedingRowCount,
            rowIndexInGroup: rowIndex,
            groupRowCount: rowCount,
            dayLabel: rowIndex == 0 ? dayLabel : null,
          ),
        );
      }
    }
    return DashboardLogSemanticPreviewGeometry._(slots: slots, groups: groups);
  }

  final List<DashboardLogSemanticPreviewSlot> slots;
  final List<DashboardLogSemanticPreviewGroup> groups;

  int get groupCount => groups.length;

  DashboardLogSemanticPreviewSlot? slotAt(int ordinal) =>
      ordinal < 0 || ordinal >= slots.length ? null : slots[ordinal];

  /// The exact bounded content height shared by Phase A, rich preview and
  /// committed page zero. The viewport-sized structural host is handled by
  /// the render-domain/extent owner separately.
  double contentExtent(double rowHeight) {
    if (slots.isEmpty) return 0;
    final last = slots.last;
    return last.rowTop(rowHeight) + rowHeight;
  }
}

@immutable
final class DashboardLogSemanticPreviewGroup {
  const DashboardLogSemanticPreviewGroup({
    required this.groupIndex,
    required this.precedingRowCount,
    required this.rowCount,
    required this.dayLabel,
  });

  final int groupIndex;
  final int precedingRowCount;
  final int rowCount;
  final String dayLabel;

  double headerTop(double rowHeight) =>
      groupIndex * DashboardLogBoxTokens.dayHeaderHeight +
      groupIndex * DashboardLogBoxTokens.dayGroupGap +
      precedingRowCount * rowHeight;

  double rowTop(double rowHeight) =>
      headerTop(rowHeight) + DashboardLogBoxTokens.dayHeaderHeight;
}

@immutable
final class DashboardLogSemanticPreviewSlot {
  const DashboardLogSemanticPreviewSlot({
    required this.ordinal,
    required this.groupIndex,
    required this.precedingRowCount,
    required this.rowIndexInGroup,
    required this.groupRowCount,
    required this.dayLabel,
  });

  final int ordinal;
  final int groupIndex;
  final int precedingRowCount;
  final int rowIndexInGroup;
  final int groupRowCount;

  /// Non-null only for the first row of an exact day group.
  final String? dayLabel;

  bool get showsSeparator => rowIndexInGroup != 0;

  double headerTop(double rowHeight) =>
      groupIndex * DashboardLogBoxTokens.dayHeaderHeight +
      groupIndex * DashboardLogBoxTokens.dayGroupGap +
      precedingRowCount * rowHeight;

  double rowTop(double rowHeight) =>
      headerTop(rowHeight) +
      DashboardLogBoxTokens.dayHeaderHeight +
      rowIndexInGroup * rowHeight;
}

/// The complete immutable LogBox presentation derived from one dashboard
/// snapshot. The viewport never receives raw transaction DTOs from rendering.
///
/// Prepared index decoding can retain [_DeferredViewportProjection] instead
/// of eagerly allocating rich rows/groups for every sparse scope. The first
/// exact scene window that consumes this viewport projects it once; no rail
/// crossing, render or paint path is permitted to do that work.
@immutable
class DashboardLogViewportState {
  DashboardLogViewportState({
    required this.queryKey,
    required this.revision,
    required List<DashboardDayLogGroupViewModel> groups,
    required this.entryCount,
    required Map<String, Object?>? nextCursor,
    required this.direction,
  }) : _eagerGroups = List<DashboardDayLogGroupViewModel>.unmodifiable(groups),
       _deferred = null,
       _semanticPreviewGeometryHolder =
           _DashboardLogSemanticPreviewGeometryHolder(
             DashboardLogSemanticPreviewGeometry.fromGroups(groups),
           ),
       nextCursor = nextCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(nextCursor);

  /// Compact prepared-index frame. It owns raw preview references only until
  /// a bounded scene window requests rich LogBox presentation.
  factory DashboardLogViewportState.deferredPreparedReferences({
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> rowTable,
    DashboardLogRowProjectionCache? rowProjectionCache,
    required List<int> rowIndices,
    required int entryCount,
    required Map<String, Object?>? nextCursor,
  }) {
    final cache =
        rowProjectionCache ?? DashboardLogRowProjectionCache(rowTable);
    final deferred = _DeferredViewportProjection(
      rowProjectionCache: cache,
      rowIndices: rowIndices,
    );
    return DashboardLogViewportState._deferred(
      queryKey: scope.key,
      revision: revision,
      entryCount: entryCount,
      nextCursor: nextCursor,
      direction: scope.direction,
      deferred: deferred,
    );
  }

  /// Explicit committed pages are already bounded to one page. They use the
  /// same deferred rich-projection representation so formatting ownership is
  /// identical across preview and committed page preparation.
  factory DashboardLogViewportState.deferredPreparedOrdered({
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> entries,
    required int entryCount,
    required Map<String, Object?>? nextCursor,
  }) => DashboardLogViewportState.deferredPreparedReferences(
    scope: scope,
    revision: revision,
    rowTable: entries,
    rowProjectionCache: DashboardLogRowProjectionCache(entries),
    rowIndices: List<int>.generate(entries.length, (index) => index),
    entryCount: entryCount,
    nextCursor: nextCursor,
  );

  DashboardLogViewportState._deferred({
    required this.queryKey,
    required this.revision,
    required this.entryCount,
    required Map<String, Object?>? nextCursor,
    required this.direction,
    required _DeferredViewportProjection deferred,
  }) : _eagerGroups = null,
       _deferred = deferred,
       _semanticPreviewGeometryHolder =
           _DashboardLogSemanticPreviewGeometryHolder(),
       nextCursor = nextCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(nextCursor);

  final LedgerQueryKey queryKey;
  final int? revision;
  final List<DashboardDayLogGroupViewModel>? _eagerGroups;
  final _DeferredViewportProjection? _deferred;
  final _DashboardLogSemanticPreviewGeometryHolder
  _semanticPreviewGeometryHolder;

  /// Whether the bounded Phase-A geometry has been prepared by a resource
  /// owner. Sparse prepared-index frames deliberately start without this
  /// memoized table: materializing it for every calendar candidate at index
  /// construction would turn one 24-row visual aid into whole-index work.
  bool get hasPreparedSemanticPreviewGeometry =>
      _semanticPreviewGeometryHolder.value != null;

  /// The already-prepared Phase-A geometry, if its resource owner has armed
  /// the payload. Render-domain selection uses this non-materializing view so
  /// widget build and paint can never create date grouping or text resources.
  DashboardLogSemanticPreviewGeometry? get preparedSemanticPreviewGeometry =>
      _semanticPreviewGeometryHolder.value;

  /// Arms the compact geometry while an existing scene/resource preparation
  /// owner is already traversing this bounded payload. This is a pure
  /// memoized derivation of immutable ledger references; it is not rich row
  /// projection, TextPainter creation, or a live paint-path allocation.
  DashboardLogSemanticPreviewGeometry prepareSemanticPreviewGeometry() =>
      _semanticPreviewGeometryHolder.value ??=
          _deferred?.prepareSemanticPreviewGeometry() ??
          DashboardLogSemanticPreviewGeometry.fromGroups(_eagerGroups!);

  /// Exact Phase-A geometry after [prepareSemanticPreviewGeometry] has armed
  /// it. Callers in renderer/build paths must use
  /// [preparedSemanticPreviewGeometry] first rather than triggering work.
  DashboardLogSemanticPreviewGeometry get semanticPreviewGeometry {
    final geometry = _semanticPreviewGeometryHolder.value;
    if (geometry != null) return geometry;
    throw StateError(
      'Phase-A geometry must be prepared before a deferred LogBox payload '
      'can enter a render path.',
    );
  }

  final int entryCount;
  final Map<String, Object?>? nextCursor;
  final LedgerDirection direction;

  final _DashboardLogViewportProjectionHolder _projectionHolder =
      _DashboardLogViewportProjectionHolder();

  _DashboardLogViewportProjection get _resolvedProjection {
    final deferred = _deferred;
    if (deferred != null) {
      // A materialized holder cannot bypass the shared row-cache generation.
      // `project()` refreshes/deletes an obsolete rich projection first, then
      // this holder follows that exact accepted result.
      final projection = deferred.project();
      _projectionHolder.value = projection;
      return projection;
    }
    return _projectionHolder.value ??=
        _DashboardLogViewportProjection.fromGroups(_eagerGroups!);
  }

  List<DashboardDayLogGroupViewModel> get groups => _resolvedProjection.groups;
  List<DashboardLogViewportItemViewModel> get flatItems =>
      _resolvedProjection.flatItems;
  List<DashboardLogGroupLayoutViewModel> get groupLayouts =>
      _resolvedProjection.groupLayouts;
  List<String> get stableRowIdentities =>
      _deferred?.stableRowIdentities ?? _resolvedProjection.stableRowIdentities;
  List<String> get stableAssetIdentities =>
      _deferred?.stableAssetIdentities ??
      _resolvedProjection.stableAssetIdentities;
  int get previewRowCount =>
      _deferred?.previewRowCount ?? _resolvedProjection.flatItems.length;

  /// Returns one exact source identity without requesting the deferred rich
  /// row projection. Phase-A interaction paint uses it only to distinguish
  /// already-resident semantic slots while Phase-B prepares text/layout.
  String? semanticPreviewRowIdentityAt(int ordinal) {
    if (ordinal < 0 || ordinal >= previewRowCount) return null;
    final deferred = _deferred;
    if (deferred != null) return deferred.rowIdentityAt(ordinal);
    return _resolvedProjection.flatItems[ordinal].row.entryId;
  }

  DashboardLogSemanticPreviewSlot? semanticPreviewSlotAt(int ordinal) =>
      _semanticPreviewGeometryHolder.value?.slotAt(ordinal);

  /// Provides the resident immutable ledger entry for the compact Phase-A
  /// renderer.  It is deliberately unavailable for an already-resolved rich
  /// projection: that path has a complete row scene and must use it instead.
  DashboardLedgerEntry? semanticPreviewLedgerEntryAt(int ordinal) {
    if (ordinal < 0 || ordinal >= previewRowCount) return null;
    return _deferred?.entryAt(ordinal);
  }

  /// Bounded lookup used only for a save-result visual patch. The active
  /// preview contains at most one viewport page, so this never scans the
  /// prepared index or queries the repository. It works before and after the
  /// rich scene has been materialized.
  DashboardLedgerEntry? semanticPreviewLedgerEntryForId(String entryId) {
    final deferred = _deferred;
    if (deferred != null) return deferred.entryForId(entryId);
    for (final item in _resolvedProjection.flatItems) {
      final row = item.row;
      if (row.entryId != entryId) continue;
      return DashboardLedgerEntry(
        id: row.entryId,
        partnerId: row.partnerId,
        categoryId: row.categoryId,
        direction: row.amountStyle == LogAmountStyle.expense
            ? 'expense'
            : 'income',
        amountMinor: 0,
        bookedLocalEpochDay: 0,
        bookedLocalTimeMinutes: 0,
        partnerDisplayName: row.partnerDisplayName,
        partnerAvatarColorId: row.partnerAvatarColorId,
        partnerAvatarIconId: row.partnerAvatarIconId,
        categoryDisplayName: row.categoryDisplayName,
        categoryColorId: row.categoryColorId,
        categoryIconId: row.categoryIconId,
        assignmentMode: row.hasCategoryOverride
            ? 'entryOverride'
            : 'partnerDefault',
        visualRevision: row.entryRevision,
      );
    }
    return null;
  }

  int get groupCount => prepareSemanticPreviewGeometry().groupCount;
  int get viewportId =>
      _deferred?.viewportId(
        queryKey: queryKey,
        revision: revision,
        entryCount: entryCount,
        direction: direction,
        nextCursor: nextCursor,
      ) ??
      _resolvedProjection.viewportId(
        queryKey: queryKey,
        revision: revision,
        entryCount: entryCount,
        direction: direction,
        nextCursor: nextCursor,
      );

  bool get isRichProjected => _deferred?.isProjected ?? true;
  int get richProjectedRowCount =>
      _deferred?.richProjectedRowCount ?? stableRowIdentities.length;
  DashboardLogRichProjectionMetrics get richProjectionMetrics =>
      _deferred?.richProjectionMetrics ??
      DashboardLogRichProjectionMetrics.eager(
        rowCount: stableRowIdentities.length,
        frameCount: 1,
      );
  Object get richProjectionOwner => _deferred?.richProjectionOwner ?? this;

  /// Compact identity iteration for metrics/composition.  It must not force
  /// rich row/group/view-model allocation across the sparse index.
  void forEachStableRowIdentity(void Function(String identity) visitor) {
    final deferred = _deferred;
    if (deferred != null) {
      deferred.forEachStableRowIdentity(visitor);
      return;
    }
    for (final identity in _resolvedProjection.stableRowIdentities) {
      visitor(identity);
    }
  }

  /// Explicit scene preparation calls this before TextPainter work. It is
  /// intentionally not used by a widget build, rail crossing or painter.
  void materializeRichProjection() => _resolvedProjection;

  /// Advances one private rich-projection unit for the existing scene
  /// preparation owner. Until it returns true, no groups/items/layouts can be
  /// observed through this state.
  bool prepareNextRichProjectionWorkUnit() =>
      _deferred?.prepareNextWorkUnit() ?? true;

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

  /// Applies a Core-confirmed editor visual patch to an already resident row.
  /// Financial membership, ordering, cursors and counts remain unchanged
  /// until the authoritative revision publication arrives.
  DashboardLogViewportState? withVisualPatch(DashboardLedgerVisualPatch patch) {
    final deferred = _deferred;
    if (deferred != null) {
      final patched = deferred.withVisualPatch(patch);
      if (patched == null) return null;
      if (identical(patched, deferred)) return this;
      final replacement = DashboardLogViewportState._deferred(
        queryKey: queryKey,
        revision: revision,
        entryCount: entryCount,
        nextCursor: nextCursor,
        direction: direction,
        deferred: patched,
      );
      // Row text changes do not alter slot geometry. Preserve the explicit
      // Phase-A readiness contract when this payload had already entered a
      // renderer/resource bank, without materializing its rich projection.
      if (_semanticPreviewGeometryHolder.value != null) {
        replacement.prepareSemanticPreviewGeometry();
      }
      return replacement;
    }
    var matched = false;
    var changed = false;
    final groups = <DashboardDayLogGroupViewModel>[];
    for (final group in _eagerGroups!) {
      final rows = <DashboardLogRowViewModel>[];
      for (final row in group.rows) {
        if (row.entryId == patch.entryId) {
          matched = true;
          if (patch.entryRevision < row.entryRevision) {
            return null;
          }
          if (patch.entryRevision == row.entryRevision &&
              patch.visualIdentity == row.visualIdentity) {
            rows.add(row);
            continue;
          }
          changed = true;
          rows.add(row.withVisualPatch(patch));
        } else {
          rows.add(row);
        }
      }
      groups.add(
        DashboardDayLogGroupViewModel(
          dateKey: group.dateKey,
          dayLabel: group.dayLabel,
          rows: rows,
        ),
      );
    }
    if (!matched) return null;
    if (!changed) return this;
    return DashboardLogViewportState(
      queryKey: queryKey,
      revision: revision,
      groups: groups,
      entryCount: entryCount,
      nextCursor: nextCursor,
      direction: direction,
    );
  }

  /// Compact, no-rich-projection visual identity for the Phase-A lookup.
  /// It lets the prepared bank reject a stale paragraph resource even when a
  /// save keeps the global Core revision unchanged.
  int? semanticPreviewVisualIdentityForId(String entryId) {
    final deferred = _deferred;
    if (deferred != null) return deferred.entryForId(entryId)?.visualIdentity;
    for (final item in _resolvedProjection.flatItems) {
      if (item.row.entryId == entryId) return item.row.visualIdentity;
    }
    return null;
  }

  bool hasSameVisualValue(DashboardLogViewportState other) =>
      viewportId == other.viewportId;
}

/// Keeps deferred materialization private without making the immutable
/// viewport value itself own a mutable public projection field.
final class _DashboardLogViewportProjectionHolder {
  _DashboardLogViewportProjection? value;
}

/// Private mutable memoization holder. The outer viewport value remains
/// semantically immutable: this caches only a pure derivation of its stable
/// rows, just like [_DashboardLogViewportProjectionHolder] caches rich
/// projection work behind the explicit scene owner.
final class _DashboardLogSemanticPreviewGeometryHolder {
  _DashboardLogSemanticPreviewGeometryHolder([this.value]);

  DashboardLogSemanticPreviewGeometry? value;
}

final class _DeferredViewportProjection {
  _DeferredViewportProjection({
    required DashboardLogRowProjectionCache rowProjectionCache,
    required List<int> rowIndices,
    Map<int, DashboardLedgerEntry> entryOverrides =
        const <int, DashboardLedgerEntry>{},
  }) : _rowProjectionCache = rowProjectionCache,
       _rowIndices = List<int>.unmodifiable(rowIndices),
       _entryOverrides = Map<int, DashboardLedgerEntry>.unmodifiable(
         entryOverrides,
       );

  final DashboardLogRowProjectionCache _rowProjectionCache;
  final List<int> _rowIndices;
  final Map<int, DashboardLedgerEntry> _entryOverrides;
  late final DashboardLogSemanticPreviewGeometry _semanticPreviewGeometry =
      DashboardLogSemanticPreviewGeometry.fromPreparedReferences(
        rowProjectionCache: _rowProjectionCache,
        rowIndices: _rowIndices,
      );
  List<String>? _stableRowIdentities;
  List<String>? _stableAssetIdentities;
  int _observedVisualGeneration = -1;
  bool _isProjected = false;
  int _richProjectedRowCount = 0;
  int _richProjectionMicros = 0;
  _DeferredRichProjectionBuilder? _builder;
  _DashboardLogViewportProjection? _rich;

  bool get isProjected {
    _refreshSharedVisualProjectionIfNeeded();
    return _isProjected;
  }

  int get richProjectedRowCount => _richProjectedRowCount;
  Object get richProjectionOwner {
    _refreshSharedVisualProjectionIfNeeded();
    return _entryOverrides.isEmpty ? _rowProjectionCache : this;
  }

  DashboardLogRichProjectionMetrics get richProjectionMetrics {
    _refreshSharedVisualProjectionIfNeeded();
    return DashboardLogRichProjectionMetrics(
      richRowProjectionMicros: _rowProjectionCache.projectionMicros,
      richFrameProjectionMicros: _richProjectionMicros,
      projectedUniqueRowCount: _rowProjectionCache.newProjectionCount,
      projectedFrameCount: _isProjected ? 1 : 0,
      reusedProjectedRowCount: _rowProjectionCache.reusedProjectionCount,
      reusedProjectedFrameCount: 0,
    );
  }

  int get previewRowCount => _rowIndices.length;

  DashboardLogSemanticPreviewGeometry prepareSemanticPreviewGeometry() =>
      _semanticPreviewGeometry;

  int get _groupContentIdentity => _rawGroupContentIdentity();

  _DashboardLogViewportProjection project() {
    _refreshSharedVisualProjectionIfNeeded();
    while (!isProjected) {
      prepareNextWorkUnit();
    }
    return _rich!;
  }

  /// Processes one row/group/frame construction unit while keeping all
  /// partially built collections private. The scene cache owns scheduling and
  /// calls this between its existing cooperative checkpoints.
  bool prepareNextWorkUnit() {
    _refreshSharedVisualProjectionIfNeeded();
    if (_isProjected) return true;
    final started = Stopwatch()..start();
    final builder = _builder ??= _DeferredRichProjectionBuilder(this);
    final completed = builder.processNextWorkUnit();
    started.stop();
    _richProjectionMicros += started.elapsedMicroseconds;
    if (completed case final _DashboardLogViewportProjection projection) {
      _rich = projection;
      _isProjected = true;
    }
    return _isProjected;
  }

  void forEachStableRowIdentity(void Function(String identity) visitor) {
    _refreshSharedVisualProjectionIfNeeded();
    for (final index in _rowIndices) {
      visitor(_entryAt(index).id);
    }
  }

  String rowIdentityAt(int ordinal) {
    _refreshSharedVisualProjectionIfNeeded();
    if (ordinal < 0 || ordinal >= _rowIndices.length) {
      throw RangeError.index(ordinal, _rowIndices, 'ordinal');
    }
    return _entryAt(_rowIndices[ordinal]).id;
  }

  DashboardLedgerEntry entryAt(int ordinal) {
    _refreshSharedVisualProjectionIfNeeded();
    if (ordinal < 0 || ordinal >= _rowIndices.length) {
      throw RangeError.index(ordinal, _rowIndices, 'ordinal');
    }
    return _entryAt(_rowIndices[ordinal]);
  }

  DashboardLedgerEntry? entryForId(String entryId) {
    _refreshSharedVisualProjectionIfNeeded();
    for (final index in _rowIndices) {
      final entry = _entryAt(index);
      if (entry.id == entryId) return entry;
    }
    return null;
  }

  _DeferredViewportProjection? withVisualPatch(
    DashboardLedgerVisualPatch patch,
  ) {
    int? rowIndex;
    for (final candidate in _rowIndices) {
      if (_entryAt(candidate).id == patch.entryId) {
        rowIndex = candidate;
        break;
      }
    }
    if (rowIndex == null) return null;
    final result = _rowProjectionCache.acceptVisualPatch(patch);
    if (result == DashboardLogVisualPatchResult.alreadyCurrent) return this;
    if (result == DashboardLogVisualPatchResult.rowNotFound ||
        result == DashboardLogVisualPatchResult.financialIdentityMismatch ||
        result == DashboardLogVisualPatchResult.staleEntryRevision) {
      return null;
    }
    return _DeferredViewportProjection(
      rowProjectionCache: _rowProjectionCache,
      rowIndices: _rowIndices,
    );
  }

  int viewportId({
    required LedgerQueryKey queryKey,
    required int? revision,
    required int entryCount,
    required LedgerDirection direction,
    required Map<String, Object?>? nextCursor,
  }) {
    _refreshSharedVisualProjectionIfNeeded();
    return Object.hash(
      queryKey,
      revision,
      entryCount,
      direction,
      _groupContentIdentity,
      nextCursor?['entryId'],
    );
  }

  List<String> get stableRowIdentities {
    _refreshSharedVisualProjectionIfNeeded();
    return _stableRowIdentities ??= List<String>.unmodifiable(
      _rowIndices.map((index) => _entryAt(index).id),
    );
  }

  List<String> get stableAssetIdentities {
    _refreshSharedVisualProjectionIfNeeded();
    return _stableAssetIdentities ??= List<String>.unmodifiable(<String>{
      for (final index in _rowIndices)
        '${_entryAt(index).categoryColorId ?? 'fallback'}|'
            '${_entryAt(index).categoryIconId ?? 'fallback'}|'
            '${_entryAt(index).partnerAvatarColorId ?? 'fallback'}|'
            '${_entryAt(index).partnerAvatarIconId ?? 'fallback'}',
    });
  }

  void _refreshSharedVisualProjectionIfNeeded() {
    // Local overrides already describe a one-off immutable overlay. Shared
    // cache updates are used only by the normal prepared ghost variants.
    if (_entryOverrides.isNotEmpty) return;
    final nextGeneration = _rowProjectionCache.visualGeneration;
    if (_observedVisualGeneration == nextGeneration) return;
    _observedVisualGeneration = nextGeneration;
    _stableRowIdentities = null;
    _stableAssetIdentities = null;
    if (!_isProjected) return;
    // A previously visited ghost mode may own a rich scene assembled before
    // an editor save. Drop that bounded derivation so its next presentation
    // obtains the same accepted row as every other mode, without rebuilding
    // the prepared financial index or reading the repository.
    _isProjected = false;
    _builder = null;
    _rich = null;
    _richProjectedRowCount = 0;
    _richProjectionMicros = 0;
  }

  int _rawGroupContentIdentity() {
    // A frame identity needs only exact compact row ordering. Day labels and
    // all rich group/view-model objects are intentionally deferred until the
    // scene window consumes this payload.
    return Object.hashAll(<Object?>[
      ..._rowIndices,
      _rowProjectionCache.visualGeneration,
      for (final entry in _entryOverrides.entries)
        Object.hash(
          entry.key,
          entry.value.partnerDisplayName,
          entry.value.partnerAvatarColorId,
          entry.value.partnerAvatarIconId,
          entry.value.categoryId,
          entry.value.categoryDisplayName,
          entry.value.categoryColorId,
          entry.value.categoryIconId,
          entry.value.assignmentMode,
          entry.value.visualRevision,
        ),
    ]);
  }

  DashboardLedgerEntry _entryAt(int index) {
    return _entryOverrides[index] ?? _rowProjectionCache.entryAt(index);
  }

  DashboardLogRowViewModel _projectRow(int index, DashboardLedgerEntry entry) =>
      _entryOverrides.containsKey(index)
      ? DashboardLogRowViewModel.fromLedgerEntry(entry)
      : _rowProjectionCache.projectAt(index);
}

/// Private resumable rich projection. It performs at most one source-row or
/// one final empty-frame unit per call and never exposes its mutable groups to
/// a renderer, scene bank or visible frame.
final class _DeferredRichProjectionBuilder {
  _DeferredRichProjectionBuilder(this._owner);

  final _DeferredViewportProjection _owner;
  final List<DashboardDayLogGroupViewModel> _groups =
      <DashboardDayLogGroupViewModel>[];
  final List<DashboardLogViewportItemViewModel> _flatItems =
      <DashboardLogViewportItemViewModel>[];
  final List<DashboardLogGroupLayoutViewModel> _groupLayouts =
      <DashboardLogGroupLayoutViewModel>[];
  final List<String> _stableRowIdentities = <String>[];
  final Set<String> _stableAssetIdentities = <String>{};
  final Set<String> _seen = <String>{};
  LocalDate? _currentDate;
  List<DashboardLogRowViewModel> _currentRows = <DashboardLogRowViewModel>[];
  DashboardLedgerEntry? _previous;
  int _nextSourceRow = 0;
  int _flatRowIndex = 0;
  int _precedingRows = 0;
  _DashboardLogViewportProjection? _completed;

  _DashboardLogViewportProjection? processNextWorkUnit() {
    final existing = _completed;
    if (existing != null) return existing;
    if (_nextSourceRow < _owner._rowIndices.length) {
      _projectOneRow(_owner._rowIndices[_nextSourceRow]);
      _nextSourceRow += 1;
      return null;
    }
    _flushCurrentGroup();
    final projection = _DashboardLogViewportProjection.fromPreparedParts(
      groups: _groups,
      flatItems: _flatItems,
      groupLayouts: _groupLayouts,
      stableRowIdentities: _stableRowIdentities,
      stableAssetIdentities: _stableAssetIdentities.toList(growable: false),
    );
    _completed = projection;
    return projection;
  }

  void _projectOneRow(int rowIndex) {
    final entry = _owner._entryAt(rowIndex);
    if (!_seen.add(entry.id)) {
      throw const FormatException('Prepared frame repeats a row reference.');
    }
    final previous = _previous;
    if (previous != null && !_isOrderedAfter(previous, entry)) {
      throw const FormatException('Prepared row references are not ordered.');
    }
    _previous = entry;
    final date = _dateFromEpochDay(entry.bookedLocalEpochDay);
    if (_currentDate != date) {
      _flushCurrentGroup();
      _currentDate = date;
      _currentRows = <DashboardLogRowViewModel>[];
    }
    final row = _owner._projectRow(rowIndex, entry);
    final groupIndex = _groups.length;
    final rowIndexInGroup = _currentRows.length;
    _currentRows.add(row);
    _flatItems.add(
      DashboardLogViewportItemViewModel.row(
        row: row,
        showSeparator: rowIndexInGroup != 0,
        dayLabel: rowIndexInGroup == 0
            ? DashboardTimeLabelFormatter.date(
                YearMonth(year: date.year, month: date.month),
                date.day,
              )
            : null,
        hasGroupGapBefore: groupIndex != 0 && rowIndexInGroup == 0,
        groupIndex: groupIndex,
        flatRowIndex: _flatRowIndex,
      ),
    );
    _flatRowIndex += 1;
    _stableRowIdentities.add(row.entryId);
    _stableAssetIdentities.add(
      '${row.categoryColorId}|${row.categoryIconId}|'
      '${row.partnerAvatarColorId}|${row.partnerAvatarIconId}',
    );
    _owner._richProjectedRowCount += 1;
  }

  void _flushCurrentGroup() {
    final date = _currentDate;
    if (date == null) return;
    final groupIndex = _groups.length;
    _groups.add(
      DashboardDayLogGroupViewModel(
        dateKey: date.isoString,
        dayLabel: DashboardTimeLabelFormatter.date(
          YearMonth(year: date.year, month: date.month),
          date.day,
        ),
        rows: _currentRows,
      ),
    );
    _groupLayouts.add(
      DashboardLogGroupLayoutViewModel(
        dateKey: date.isoString,
        groupIndex: groupIndex,
        precedingRowCount: _precedingRows,
        rowCount: _currentRows.length,
      ),
    );
    _precedingRows += _currentRows.length;
    _currentDate = null;
  }
}

/// Snapshot of exact bounded rich projection work.  Compact index assembly
/// remains at zero until the existing scene/page owner materializes a frame.
@immutable
final class DashboardLogRichProjectionMetrics {
  const DashboardLogRichProjectionMetrics({
    required this.richRowProjectionMicros,
    required this.richFrameProjectionMicros,
    required this.projectedUniqueRowCount,
    required this.projectedFrameCount,
    required this.reusedProjectedRowCount,
    required this.reusedProjectedFrameCount,
  });

  factory DashboardLogRichProjectionMetrics.eager({
    required int rowCount,
    required int frameCount,
  }) => DashboardLogRichProjectionMetrics(
    richRowProjectionMicros: 0,
    richFrameProjectionMicros: 0,
    projectedUniqueRowCount: rowCount,
    projectedFrameCount: frameCount,
    reusedProjectedRowCount: 0,
    reusedProjectedFrameCount: 0,
  );

  final int richRowProjectionMicros;
  final int richFrameProjectionMicros;
  final int projectedUniqueRowCount;
  final int projectedFrameCount;
  final int reusedProjectedRowCount;
  final int reusedProjectedFrameCount;
}

final class _DashboardLogViewportProjection {
  _DashboardLogViewportProjection.fromGroups(
    List<DashboardDayLogGroupViewModel> source,
  ) : groups = List<DashboardDayLogGroupViewModel>.unmodifiable(source),
      flatItems = _flatten(source),
      groupLayouts = _groupLayouts(source),
      stableRowIdentities = _rowIdentities(source),
      stableAssetIdentities = _assetIdentities(source);

  /// The deferred builder has already assembled every immutable public list
  /// in bounded work units. Views prevent mutation without another full-frame
  /// copy at its atomic publication boundary.
  _DashboardLogViewportProjection.fromPreparedParts({
    required List<DashboardDayLogGroupViewModel> groups,
    required List<DashboardLogViewportItemViewModel> flatItems,
    required List<DashboardLogGroupLayoutViewModel> groupLayouts,
    required List<String> stableRowIdentities,
    required List<String> stableAssetIdentities,
  }) : groups = UnmodifiableListView<DashboardDayLogGroupViewModel>(groups),
       flatItems = UnmodifiableListView<DashboardLogViewportItemViewModel>(
         flatItems,
       ),
       groupLayouts = UnmodifiableListView<DashboardLogGroupLayoutViewModel>(
         groupLayouts,
       ),
       stableRowIdentities = UnmodifiableListView<String>(stableRowIdentities),
       stableAssetIdentities = UnmodifiableListView<String>(
         stableAssetIdentities,
       );

  final List<DashboardDayLogGroupViewModel> groups;
  final List<DashboardLogViewportItemViewModel> flatItems;
  final List<DashboardLogGroupLayoutViewModel> groupLayouts;
  final List<String> stableRowIdentities;
  final List<String> stableAssetIdentities;

  int viewportId({
    required LedgerQueryKey queryKey,
    required int? revision,
    required int entryCount,
    required LedgerDirection direction,
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
          Object.hashAll(group.rows.map((row) => row.textLayoutId)),
        ),
      ),
    ),
    nextCursor?['entryId'],
  );

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
        '${row.categoryColorId}|${row.categoryIconId}|'
            '${row.partnerAvatarColorId}|${row.partnerAvatarIconId}',
  });
}

LocalDate _dateFromEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return LocalDate(year: date.year, month: date.month, day: date.day);
}

bool _isOrderedAfter(
  DashboardLedgerEntry previous,
  DashboardLedgerEntry current,
) =>
    previous.bookedLocalEpochDay > current.bookedLocalEpochDay ||
    (previous.bookedLocalEpochDay == current.bookedLocalEpochDay &&
        (previous.bookedLocalTimeMinutes > current.bookedLocalTimeMinutes ||
            (previous.bookedLocalTimeMinutes ==
                    current.bookedLocalTimeMinutes &&
                previous.id.compareTo(current.id) > 0)));

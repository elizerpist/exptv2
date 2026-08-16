import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
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
    required this.semanticLabel,
    this.categoryId = '',
    this.partnerId = '',
    this.partnerDisplayName = '',
  }) : categoryColorHandle = CategoryColorCatalog.handleOf(categoryColorId),
       categoryIconHandle = CategoryIconCatalog.handleOf(categoryIconId),
       textLayoutId = Object.hash(
         entryId,
         displayName,
         categoryDisplayName,
         formattedAmount,
         displayTime,
         amountStyle,
       );

  /// Rich per-row presentation is intentionally created only by a bounded
  /// exact LogBox projection, never by whole-index binary decoding.
  factory DashboardLogRowViewModel.fromLedgerEntry(DashboardLedgerEntry entry) {
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
      categoryId: entry.categoryId,
      partnerId: entry.partnerId,
      partnerDisplayName: entry.partnerDisplayName ?? displayName,
      semanticLabel:
          '$displayName, $formattedAmount, '
          '${isExpense ? 'kiadás' : 'bevétel'}, $categoryDisplayName',
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

  /// Semantic source identities are retained with the prepared row so an
  /// interaction can request transient focus without an entry-id lookup.
  final String categoryId;
  final String partnerId;
  final String partnerDisplayName;
  final int categoryColorHandle;
  final int categoryIconHandle;

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
}

/// Bounded, immutable-index-owned rich row projection pool.
///
/// The binary decoder keeps native rows compact. Exact scene windows project
/// only the rows they consume through this pool, so overlapping all/month/day
/// scopes share one immutable row presentation without making every sparse
/// frame eager. Eviction only drops the pool's lookup reference; any active
/// viewport/scene still owns its immutable row object directly.
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
  final Map<int, DashboardLogRowViewModel> _projected =
      <int, DashboardLogRowViewModel>{};
  int _newProjectionCount = 0;
  int _reusedProjectionCount = 0;
  int _projectionMicros = 0;

  int get projectedCount => _projected.length;
  int get newProjectionCount => _newProjectionCount;
  int get reusedProjectionCount => _reusedProjectionCount;
  int get projectionMicros => _projectionMicros;

  DashboardLedgerEntry entryAt(int index) {
    if (index < 0 || index >= _rows.length) {
      throw const FormatException('Prepared row reference is out of range.');
    }
    return _rows[index];
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
       nextCursor = nextCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(nextCursor);

  final LedgerQueryKey queryKey;
  final int? revision;
  final List<DashboardDayLogGroupViewModel>? _eagerGroups;
  final _DeferredViewportProjection? _deferred;
  final int entryCount;
  final Map<String, Object?>? nextCursor;
  final LedgerDirection direction;

  final _DashboardLogViewportProjectionHolder _projectionHolder =
      _DashboardLogViewportProjectionHolder();

  _DashboardLogViewportProjection get _resolvedProjection =>
      _projectionHolder.value ??= _eagerGroups == null
      ? _deferred!.project()
      : _DashboardLogViewportProjection.fromGroups(_eagerGroups);

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
  int get groupCount =>
      _deferred?.groupCount ?? _resolvedProjection.groups.length;
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

  bool hasSameVisualValue(DashboardLogViewportState other) =>
      viewportId == other.viewportId;
}

/// Keeps deferred materialization private without making the immutable
/// viewport value itself own a mutable public projection field.
final class _DashboardLogViewportProjectionHolder {
  _DashboardLogViewportProjection? value;
}

final class _DeferredViewportProjection {
  _DeferredViewportProjection({
    required DashboardLogRowProjectionCache rowProjectionCache,
    required List<int> rowIndices,
  }) : _rowProjectionCache = rowProjectionCache,
       _rowIndices = List<int>.unmodifiable(rowIndices);

  final DashboardLogRowProjectionCache _rowProjectionCache;
  final List<int> _rowIndices;
  late final List<String> stableRowIdentities = List<String>.unmodifiable(
    _rowIndices.map((index) => _entryAt(index).id),
  );
  late final List<String> stableAssetIdentities =
      List<String>.unmodifiable(<String>{
        for (final index in _rowIndices)
          '${_entryAt(index).categoryColorId ?? 'fallback'}|'
              '${_entryAt(index).categoryIconId ?? 'fallback'}',
      });
  bool _isProjected = false;
  int _richProjectedRowCount = 0;
  int _richProjectionMicros = 0;
  _DeferredRichProjectionBuilder? _builder;
  _DashboardLogViewportProjection? _rich;

  bool get isProjected => _isProjected;
  int get richProjectedRowCount => _richProjectedRowCount;
  Object get richProjectionOwner => _rowProjectionCache;
  DashboardLogRichProjectionMetrics get richProjectionMetrics =>
      DashboardLogRichProjectionMetrics(
        richRowProjectionMicros: _rowProjectionCache.projectionMicros,
        richFrameProjectionMicros: _richProjectionMicros,
        projectedUniqueRowCount: _rowProjectionCache.newProjectionCount,
        projectedFrameCount: _isProjected ? 1 : 0,
        reusedProjectedRowCount: _rowProjectionCache.reusedProjectionCount,
        reusedProjectedFrameCount: 0,
      );
  int get previewRowCount => _rowIndices.length;
  int get groupCount => _groupCount;

  late final int _groupContentIdentity = _rawGroupContentIdentity();
  late final int _groupCount = _rawGroupCount();

  _DashboardLogViewportProjection project() {
    while (!isProjected) {
      prepareNextWorkUnit();
    }
    return _rich!;
  }

  /// Processes one row/group/frame construction unit while keeping all
  /// partially built collections private. The scene cache owns scheduling and
  /// calls this between its existing cooperative checkpoints.
  bool prepareNextWorkUnit() {
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
    for (final index in _rowIndices) {
      visitor(_entryAt(index).id);
    }
  }

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
    _groupContentIdentity,
    nextCursor?['entryId'],
  );

  int _rawGroupContentIdentity() {
    // A frame identity needs only exact compact row ordering. Day labels and
    // all rich group/view-model objects are intentionally deferred until the
    // scene window consumes this payload.
    return Object.hashAll(_rowIndices);
  }

  int _rawGroupCount() {
    LocalDate? previousDate;
    var count = 0;
    for (final index in _rowIndices) {
      final date = _dateFromEpochDay(_entryAt(index).bookedLocalEpochDay);
      if (date != previousDate) {
        count += 1;
        previousDate = date;
      }
    }
    return count;
  }

  DashboardLedgerEntry _entryAt(int index) {
    return _rowProjectionCache.entryAt(index);
  }
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
    final row = _owner._rowProjectionCache.projectAt(rowIndex);
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
    _stableAssetIdentities.add('${row.categoryColorId}|${row.categoryIconId}');
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
          Object.hashAll(group.rows.map((row) => row.entryId)),
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
        '${row.categoryColorId}|${row.categoryIconId}',
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

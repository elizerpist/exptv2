import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../core/financial_limits/domain/financial_limit.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../runtime/domain/prepared_budget_rhythm_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/time_label_formatter.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_budget_target.dart';
import 'dashboard_budget_limit_edit_controller.dart';
import 'dashboard_budget_period.dart';
import 'transaction_direction_controller.dart';

/// Immutable, presentation-only target input for the Budget rail. Aggregate
/// targets deliberately have no category ID and therefore cannot leak into
/// category filtering or inventory ownership.
@immutable
final class DashboardBudgetTargetPresentationItem {
  const DashboardBudgetTargetPresentationItem({
    required this.target,
    required this.title,
    required this.baseColorArgb,
    required this.iconAssetKey,
    this.colorId,
    this.iconId,
    this.gradientStartArgb,
    this.gradientEndArgb,
  });

  final DashboardBudgetTarget target;
  final String title;
  final int baseColorArgb;
  final String iconAssetKey;
  final String? colorId;
  final String? iconId;
  final int? gradientStartArgb;
  final int? gradientEndArgb;

  String get stableId => switch (target.identity) {
    DashboardBudgetAggregateTarget() => 'aggregate',
    DashboardBudgetCategoryTarget(:final categoryId) => 'category:$categoryId',
  };
}

@immutable
final class DashboardBudgetLiveSelectionState {
  const DashboardBudgetLiveSelectionState._({
    required this.direction,
    required this.target,
    required this.title,
    required this.actualScaled100,
    required this.limitScaled100,
    required this.limitKey,
    required this.coreRevision,
    required this.analysisScopeLabel,
    required this.visual,
  });

  factory DashboardBudgetLiveSelectionState.unavailable({
    required LedgerDirection direction,
    required DashboardBudgetTarget target,
    required String title,
  }) => DashboardBudgetLiveSelectionState._(
    direction: direction,
    target: target,
    title: title,
    actualScaled100: null,
    limitScaled100: null,
    limitKey: null,
    coreRevision: null,
    analysisScopeLabel: '—',
    visual: BudgetCategoryAvatarSelectedLimitVisualState.unavailable(
      targetHandle: target.handle,
    ),
  );

  factory DashboardBudgetLiveSelectionState.available({
    required LedgerDirection direction,
    required DashboardBudgetTarget target,
    required String title,
    required int actualScaled100,
    required int? limitScaled100,
    required FinancialLimitKey limitKey,
    required int coreRevision,
    required String analysisScopeLabel,
  }) => DashboardBudgetLiveSelectionState._(
    direction: direction,
    target: target,
    title: title,
    actualScaled100: actualScaled100,
    limitScaled100: limitScaled100,
    limitKey: limitKey,
    coreRevision: coreRevision,
    analysisScopeLabel: analysisScopeLabel,
    visual: BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: target.handle,
      limitKey: limitKey,
      actualScaled100: actualScaled100,
      effectiveLimitScaled100: limitScaled100,
    ),
  );

  final LedgerDirection direction;
  final DashboardBudgetTarget target;
  final String title;
  final int? actualScaled100;
  final int? limitScaled100;
  final FinancialLimitKey? limitKey;
  final int? coreRevision;
  final String analysisScopeLabel;
  final BudgetCategoryAvatarSelectedLimitVisualState visual;

  bool get isAvailable => actualScaled100 != null;
  bool get hasLimit => limitScaled100 != null;

  DashboardBudgetLimitEditContext? get limitEditContext =>
      !isAvailable || limitKey == null || coreRevision == null
      ? null
      : DashboardBudgetLimitEditContext(
          key: limitKey!,
          coreRevision: coreRevision!,
          targetHandle: target.handle,
          actualScaled100: actualScaled100!,
          confirmedLimitScaled100: limitScaled100,
        );
}

/// Rendering adapter for the header. It owns no independent data: all values
/// are proxied from the exact same immutable selection used by the ring.
@immutable
final class DashboardBudgetHeaderPresentation {
  const DashboardBudgetHeaderPresentation(this._selection);

  final DashboardBudgetLiveSelectionState _selection;

  DashboardBudgetTarget get target => _selection.target;
  String get title => _selection.title;
  int? get actualScaled100 => _selection.actualScaled100;
  int? get limitScaled100 => _selection.limitScaled100;
  FinancialLimitKey? get limitKey => _selection.limitKey;
  int? get coreRevision => _selection.coreRevision;
  String get analysisScopeLabel => _selection.analysisScopeLabel;
  bool get isAvailable => _selection.isAvailable;
  bool get hasLimit => _selection.hasLimit;
  DashboardBudgetLimitEditContext? get limitEditContext =>
      _selection.limitEditContext;
}

/// One resolved category segment. This remains scalar so the painter can walk
/// the prepared bank in canonical order without allocating a category list on
/// an optimistic semantic tick.
@immutable
final class DashboardBudgetPartitionSegmentPresentation {
  const DashboardBudgetPartitionSegmentPresentation._({
    required this.opaqueRatio,
    required this.translucentRatio,
  });

  static const empty = DashboardBudgetPartitionSegmentPresentation._(
    opaqueRatio: 0,
    translucentRatio: 0,
  );

  final double opaqueRatio;
  final double translucentRatio;

  double get totalRatio => opaqueRatio + translucentRatio;
}

/// Immutable, same-publication Budget allocation partition. It retains the
/// prepared direction bank and catalog references; renderer traversal derives
/// only each individual segment while the allocation total is already a scalar.
@immutable
final class DashboardBudgetPartitionPresentation {
  const DashboardBudgetPartitionPresentation._({
    required this.direction,
    required this.period,
    required this.periodSliceIndex,
    required this.coreRevision,
    required this.bank,
    required this.catalog,
    required this.aggregateActualScaled100,
    required this.effectiveAggregateLimitScaled100,
    required this.preparedAllocatedTotalScaled100,
    required this.optimisticAllocationDeltaScaled100,
    required this.categoryOverlay,
  });

  const DashboardBudgetPartitionPresentation.unavailable({
    required this.direction,
  }) : period = null,
       periodSliceIndex = null,
       coreRevision = null,
       bank = null,
       catalog = null,
       aggregateActualScaled100 = null,
       effectiveAggregateLimitScaled100 = null,
       preparedAllocatedTotalScaled100 = 0,
       optimisticAllocationDeltaScaled100 = 0,
       categoryOverlay = DashboardBudgetCategoryAllocationOverlay.empty;

  final LedgerDirection direction;
  final BudgetLimitPeriod? period;
  final int? periodSliceIndex;
  final int? coreRevision;
  final PreparedBudgetLimitDirectionBank? bank;
  final DashboardBudgetTargetCatalog? catalog;
  final int? aggregateActualScaled100;
  final int? effectiveAggregateLimitScaled100;
  final int preparedAllocatedTotalScaled100;
  final int optimisticAllocationDeltaScaled100;
  final DashboardBudgetCategoryAllocationOverlay categoryOverlay;

  bool get isAvailable =>
      period != null &&
      periodSliceIndex != null &&
      bank != null &&
      catalog != null;
  bool get hasPositiveAggregateLimit =>
      effectiveAggregateLimitScaled100 != null &&
      effectiveAggregateLimitScaled100! > 0;
  int get liveAllocatedTotalScaled100 {
    final total =
        preparedAllocatedTotalScaled100 + optimisticAllocationDeltaScaled100;
    return total > 0 ? total : 0;
  }

  double get allocationRawRatio {
    final denominator = effectiveAggregateLimitScaled100;
    if (denominator == null || denominator <= 0) return 0;
    return liveAllocatedTotalScaled100 / denominator;
  }

  double get allocationVisualCoverage =>
      allocationRawRatio.clamp(0.0, 1.0).toDouble();

  int? effectiveLimitForCategoryHandle(int handle) {
    final directionBank = bank;
    final targetCatalog = catalog;
    final slice = periodSliceIndex;
    if (directionBank == null || targetCatalog == null || slice == null) {
      return null;
    }
    if (handle <= 0 || handle >= directionBank.targetCount) return null;
    final target = targetCatalog.targetAtHandle(handle);
    final categoryId = target.category?.id;
    if (categoryId == null) return null;
    return categoryOverlay.hasOverrideForCategoryId(categoryId)
        ? categoryOverlay.effectiveLimitForCategoryId(categoryId)
        : directionBank
              .cellAt(periodSliceIndex: slice, targetHandle: handle)
              .limitScaled100;
  }

  DashboardBudgetPartitionSegmentPresentation segmentForCategoryHandle(
    int handle,
  ) {
    final denominator = effectiveAggregateLimitScaled100;
    final directionBank = bank;
    final slice = periodSliceIndex;
    if (denominator == null ||
        denominator <= 0 ||
        directionBank == null ||
        slice == null) {
      return DashboardBudgetPartitionSegmentPresentation.empty;
    }
    final limit = effectiveLimitForCategoryHandle(handle);
    if (limit == null || limit <= 0) {
      return DashboardBudgetPartitionSegmentPresentation.empty;
    }
    final actual = directionBank
        .cellAt(periodSliceIndex: slice, targetHandle: handle)
        .actualScaled100;
    final opaqueAmount = actual.clamp(0, limit);
    return DashboardBudgetPartitionSegmentPresentation._(
      opaqueRatio: opaqueAmount / denominator,
      translucentRatio: (limit - opaqueAmount) / denominator,
    );
  }
}

@immutable
final class DashboardBudgetPresentationState {
  const DashboardBudgetPresentationState({
    required this.items,
    required this.selectedHandle,
    required this.liveSelection,
    required this.partition,
  });

  final List<DashboardBudgetTargetPresentationItem> items;
  final int selectedHandle;
  final DashboardBudgetLiveSelectionState liveSelection;
  final DashboardBudgetPartitionPresentation partition;

  DashboardBudgetHeaderPresentation get header =>
      DashboardBudgetHeaderPresentation(liveSelection);
  BudgetCategoryAvatarSelectedLimitVisualState get selectedLimitVisual =>
      liveSelection.visual;
}

/// Headless, CoreDashboard-lifetime binding between immutable target visuals,
/// an exact prepared limit bank and the local Budget header. It owns no I/O,
/// carousel physics, Query or LogBox state. A semantic target change resolves
/// one dense RAM cell and publishes only this narrow presentation state.
final class DashboardBudgetPresentationController
    extends ValueNotifier<DashboardBudgetPresentationState> {
  DashboardBudgetPresentationController({
    required ValueListenable<List<FluviCategory>> categoryCollection,
    required ValueListenable<DashboardVisibleFrame?> visibleFrame,
    required TransactionDirectionController transactionDirection,
    required PreparedBudgetLimitSnapshot? Function() snapshotForCurrentFrame,
    DashboardBudgetLimitEditController? limitEditController,
    ValueChanged<int>? onInputUpdated,
  }) : _categoryCollection = categoryCollection,
       _visibleFrame = visibleFrame,
       _transactionDirection = transactionDirection,
       _snapshotForCurrentFrame = snapshotForCurrentFrame,
       _limitEditController = limitEditController,
       _onInputUpdated = onInputUpdated,
       super(_initialState()) {
    _categoryCollection.addListener(_refreshCatalogForCategoryInput);
    _visibleFrame.addListener(_refreshForVisibleFrame);
    _transactionDirection.addListener(_refreshCatalogForDirection);
    _limitEditController?.addListener(_refreshForOptimisticLimitEdit);
    _refreshCatalog(notifyCategoryInput: true);
  }

  final ValueListenable<List<FluviCategory>> _categoryCollection;
  final ValueListenable<DashboardVisibleFrame?> _visibleFrame;
  final TransactionDirectionController _transactionDirection;
  final PreparedBudgetLimitSnapshot? Function() _snapshotForCurrentFrame;
  final DashboardBudgetLimitEditController? _limitEditController;
  final ValueChanged<int>? _onInputUpdated;

  static DashboardBudgetPresentationState _initialState() {
    const aggregate = DashboardBudgetTarget.aggregate();
    return DashboardBudgetPresentationState(
      items: const <DashboardBudgetTargetPresentationItem>[],
      selectedHandle: 0,
      liveSelection: DashboardBudgetLiveSelectionState.unavailable(
        direction: LedgerDirection.expense,
        target: aggregate,
        title: 'Budget',
      ),
      partition: const DashboardBudgetPartitionPresentation.unavailable(
        direction: LedgerDirection.expense,
      ),
    );
  }

  DashboardBudgetTargetCatalog? _catalog;
  PreparedBudgetLimitSnapshot? _snapshotUsedForCatalog;
  final Map<LedgerDirection, DashboardBudgetTargetIdentity?>
  _selectedIdentityByDirection =
      <LedgerDirection, DashboardBudgetTargetIdentity?>{};
  List<FluviCategory>? _lastReportedCategoryInput;
  int? _lastHeaderDiagnosticSignature;
  int? _lastProgressDiagnosticSignature;
  int? _lastPartitionDiagnosticSignature;
  int? _lastDirectionDomainDiagnosticSignature;

  /// Called by the shared carousel only on semantic selection changes, never
  /// for a pixel or animation tick.
  void setTargetHandle(int handle) {
    final catalog = _catalog;
    if (catalog == null || handle < 0 || handle >= catalog.targetCount) return;
    if (handle == value.selectedHandle) return;
    final target = catalog.targetAtHandle(handle);
    _selectedIdentityByDirection[_direction] = target.identity;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_TARGET_SELECTION_CHANGED',
        direction: _direction.name,
        scope:
            'targetHandle=$handle '
            'targetKind=${target.isAggregate ? 'aggregate' : 'category'} '
            'categoryId=${target.category?.id ?? '-'} logicalIndex=$handle',
      ),
    );
    _publishHeaderOnly(catalog: catalog, selectedHandle: handle);
  }

  /// Category collection changes are the only source of rail-item rebuilding.
  /// A semantic time tick deliberately bypasses this lane and resolves only the
  /// dense header cell below.
  void _refreshCatalogForCategoryInput() {
    _refreshCatalog(notifyCategoryInput: true);
  }

  /// Direction changes alter only the aggregate visual and its direction
  /// vector; they do not represent another category-inventory publication.
  void _refreshCatalogForDirection() {
    _refreshCatalog();
  }

  void _refreshForVisibleFrame() {
    final snapshot = _snapshotForCurrentFrame();
    if (!identical(snapshot, _snapshotUsedForCatalog)) {
      // A new exact revision can carry a changed ordered category domain. Do
      // the structural join once, then keep semantic time ticks list-free.
      _refreshCatalog();
      return;
    }
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  void _refreshForOptimisticLimitEdit() {
    final catalog = _catalog;
    if (catalog == null) return;
    _publishHeaderOnly(catalog: catalog, selectedHandle: value.selectedHandle);
  }

  void _refreshCatalog({bool notifyCategoryInput = false}) {
    final catalog = _buildCompatibleCatalog();
    final selectedHandle =
        _handleForIdentity(catalog, _selectedIdentityByDirection[_direction]) ??
        0;
    _selectedIdentityByDirection[_direction] = catalog
        .targetAtHandle(selectedHandle)
        .identity;
    _catalog = catalog;
    _snapshotUsedForCatalog = _snapshotForCurrentFrame();
    _publishCatalog(catalog: catalog, selectedHandle: selectedHandle);
    _recordDirectionDomain(catalog, _snapshotUsedForCatalog);
    if (notifyCategoryInput &&
        !_sameCategoryInput(
          _lastReportedCategoryInput,
          _categoryCollection.value,
        )) {
      _lastReportedCategoryInput = List<FluviCategory>.unmodifiable(
        _categoryCollection.value,
      );
      // This diagnostic retains its established inventory meaning: aggregate
      // targets are Budget-domain presentation entries, not categories.
      _onInputUpdated?.call(_categoryCollection.value.length);
    }
  }

  DashboardBudgetTargetCatalog _buildCompatibleCatalog() {
    final snapshot = _snapshotForCurrentFrame();
    final categories = _categoryCollection.value;
    final categoryById = <String, FluviCategory>{
      for (final category in categories) category.id: category,
    };
    // Prepared membership/order is the only Budget target-domain authority.
    // Until an exact direction bank arrives, expose aggregate only rather
    // than leaking the category inventory from the opposite direction.
    if (snapshot == null) {
      return DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[],
      );
    }
    final ordered = snapshot.directionBank(_direction).orderedCategoryIds;
    // A category collection from another core revision must never pair with
    // dense vectors from this one. Keep the aggregate only until an exact
    // compatible publication arrives.
    if (ordered.any((id) => !categoryById.containsKey(id))) {
      return DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[],
      );
    }
    return DashboardBudgetTargetCatalog.fromCategories(
      List<DashboardBudgetCategoryVisual>.unmodifiable([
        for (final id in ordered)
          DashboardBudgetCategoryVisual(
            id: categoryById[id]!.id,
            displayName: categoryById[id]!.name,
            colorId: categoryById[id]!.colorId,
            iconId: categoryById[id]!.iconId,
          ),
      ]),
    );
  }

  int? _handleForIdentity(
    DashboardBudgetTargetCatalog catalog,
    DashboardBudgetTargetIdentity? identity,
  ) {
    if (identity == null) return null;
    for (final target in catalog.targets) {
      if (target.identity == identity) return target.handle;
    }
    return null;
  }

  static bool _sameCategoryInput(
    List<FluviCategory>? previous,
    List<FluviCategory> next,
  ) {
    if (previous == null || previous.length != next.length) return false;
    for (var index = 0; index < next.length; index += 1) {
      final left = previous[index];
      final right = next[index];
      if (left.id != right.id ||
          left.name != right.name ||
          left.colorId != right.colorId ||
          left.iconId != right.iconId ||
          left.updatedAtUtcMs != right.updatedAtUtcMs) {
        return false;
      }
    }
    return true;
  }

  void _publishCatalog({
    required DashboardBudgetTargetCatalog catalog,
    required int selectedHandle,
  }) {
    final items = List<DashboardBudgetTargetPresentationItem>.unmodifiable([
      for (final target in catalog.targets) _itemFor(target),
    ]);
    final selectedTarget = catalog.targetAtHandle(selectedHandle);
    final liveSelection = _liveSelectionFor(selectedTarget);
    final partition = _partitionFor(catalog: catalog);
    value = DashboardBudgetPresentationState(
      items: items,
      selectedHandle: selectedHandle,
      liveSelection: liveSelection,
      partition: partition,
    );
    _recordHeaderBinding(liveSelection);
    _recordProgressBinding(liveSelection);
    _recordPartitionBinding(partition, selectedHandle: selectedHandle);
  }

  /// The hot semantic tick path: retained catalog + selected dense RAM cell.
  /// It intentionally performs no category projection, item-list build, sort,
  /// search, repository read or native bridge call.
  void _publishHeaderOnly({
    required DashboardBudgetTargetCatalog catalog,
    required int selectedHandle,
  }) {
    final selectedTarget = catalog.targetAtHandle(selectedHandle);
    final liveSelection = _liveSelectionFor(selectedTarget);
    final partition = _partitionFor(catalog: catalog);
    value = DashboardBudgetPresentationState(
      items: value.items,
      selectedHandle: selectedHandle,
      liveSelection: liveSelection,
      partition: partition,
    );
    _recordHeaderBinding(liveSelection);
    _recordProgressBinding(liveSelection);
    _recordPartitionBinding(partition, selectedHandle: selectedHandle);
  }

  DashboardBudgetTargetPresentationItem _itemFor(DashboardBudgetTarget target) {
    if (target.isAggregate) {
      final aggregate = DashboardBudgetAggregateVisual.forDirection(_direction);
      return DashboardBudgetTargetPresentationItem(
        target: target,
        title: aggregate.title,
        baseColorArgb: aggregate.middleColorArgb,
        iconAssetKey: aggregate.iconAssetKey,
        gradientStartArgb: aggregate.startColorArgb,
        gradientEndArgb: aggregate.endColorArgb,
      );
    }
    final category = target.category!;
    return DashboardBudgetTargetPresentationItem(
      target: target,
      title: category.displayName,
      baseColorArgb: 0,
      iconAssetKey: 'category',
      colorId: category.colorId,
      iconId: category.iconId,
    );
  }

  DashboardBudgetLiveSelectionState _liveSelectionFor(
    DashboardBudgetTarget target,
  ) {
    final frame = _visibleFrame.value;
    final snapshot = _snapshotForCurrentFrame();
    final title = _titleFor(target);
    if (frame == null ||
        snapshot == null ||
        snapshot.coreRevision != frame.coreRevision ||
        target.handle >= snapshot.targetCountFor(_direction)) {
      _limitEditController?.invalidateIfContextChanged(null);
      return DashboardBudgetLiveSelectionState.unavailable(
        direction: _direction,
        target: target,
        title: title,
      );
    }
    final visibleScope = frame.scope.timeScope;
    final persistedLimitPeriod = DashboardBudgetPeriodResolver.fromTimeScope(
      visibleScope,
    );
    final key = _financialLimitKeyFor(target, period: persistedLimitPeriod);
    _limitEditController?.invalidateIfContextChanged(key);
    late final PreparedBudgetLimitCell cell;
    try {
      cell = snapshot.cellAt(
        direction: _direction,
        period: persistedLimitPeriod,
        targetHandle: target.handle,
      );
    } on RangeError {
      // A prepared period outside the exact RAM window is unavailable, never a
      // reason to repair the snapshot through an interaction-time read.
      return DashboardBudgetLiveSelectionState.unavailable(
        direction: _direction,
        target: target,
        title: title,
      );
    }
    _limitEditController?.observePreparedLimit(
      key: key,
      coreRevision: snapshot.coreRevision,
      confirmedLimitScaled100: cell.limitScaled100,
    );
    // [effectiveLimitFor] already resolves the complete overlay contract and
    // must not be coalesced back to a stale prepared cell.
    final effectiveLimitScaled100 = _limitEditController == null
        ? cell.limitScaled100
        : _limitEditController.effectiveLimitFor(key, cell.limitScaled100);
    final analysisActualScaled100 = _analysisActualFor(
      snapshot: snapshot,
      direction: _direction,
      targetHandle: target.handle,
      scope: visibleScope,
      persistedActualScaled100: cell.actualScaled100,
    );
    return DashboardBudgetLiveSelectionState.available(
      direction: _direction,
      target: target,
      title: title,
      actualScaled100: analysisActualScaled100,
      limitScaled100: effectiveLimitScaled100,
      limitKey: key,
      coreRevision: snapshot.coreRevision,
      analysisScopeLabel: _analysisScopeLabel(visibleScope),
    );
  }

  DashboardBudgetPartitionPresentation _partitionFor({
    required DashboardBudgetTargetCatalog catalog,
  }) {
    final frame = _visibleFrame.value;
    final snapshot = _snapshotForCurrentFrame();
    if (frame == null ||
        snapshot == null ||
        snapshot.coreRevision != frame.coreRevision) {
      return DashboardBudgetPartitionPresentation.unavailable(
        direction: _direction,
      );
    }
    final period = DashboardBudgetPeriodResolver.fromTimeScope(
      frame.scope.timeScope,
    );
    final bank = snapshot.directionBank(_direction);
    final aggregate = catalog.targetAtHandle(0);
    final aggregateKey = _financialLimitKeyFor(aggregate, period: period);
    late final int slice;
    late final PreparedBudgetLimitCell aggregateCell;
    try {
      slice = snapshot.sliceIndexFor(period);
      aggregateCell = bank.cellAt(periodSliceIndex: slice, targetHandle: 0);
    } on RangeError {
      return DashboardBudgetPartitionPresentation.unavailable(
        direction: _direction,
      );
    }
    final edits = _limitEditController;
    if (edits != null && edits.hasOverlayFor(aggregateKey)) {
      edits.observePreparedLimit(
        key: aggregateKey,
        coreRevision: snapshot.coreRevision,
        confirmedLimitScaled100: aggregateCell.limitScaled100,
      );
    }
    final effectiveAggregateLimitScaled100 = edits == null
        ? aggregateCell.limitScaled100
        : edits.effectiveLimitFor(aggregateKey, aggregateCell.limitScaled100);
    final financialDirection = switch (_direction) {
      LedgerDirection.income => FinancialLimitDirection.income,
      LedgerDirection.expense => FinancialLimitDirection.expense,
    };
    edits?.observePreparedCategoryAllocationScope(
      direction: financialDirection,
      period: aggregateKey.period,
      coreRevision: snapshot.coreRevision,
      confirmedLimitForCategoryId: (categoryId) {
        final handle = catalog.handleForCategoryId(categoryId);
        return handle == null
            ? null
            : bank
                  .cellAt(periodSliceIndex: slice, targetHandle: handle)
                  .limitScaled100;
      },
    );
    final categoryOverlay =
        edits?.categoryAllocationOverlayFor(
          direction: financialDirection,
          period: aggregateKey.period,
        ) ??
        DashboardBudgetCategoryAllocationOverlay.empty;
    return DashboardBudgetPartitionPresentation._(
      direction: _direction,
      period: period,
      periodSliceIndex: slice,
      coreRevision: snapshot.coreRevision,
      bank: bank,
      catalog: catalog,
      aggregateActualScaled100: _analysisActualFor(
        snapshot: snapshot,
        direction: _direction,
        targetHandle: 0,
        scope: frame.scope.timeScope,
        persistedActualScaled100: aggregateCell.actualScaled100,
      ),
      effectiveAggregateLimitScaled100: effectiveAggregateLimitScaled100,
      preparedAllocatedTotalScaled100:
          bank.allocatedCategoryLimitTotalScaled100ByPeriodSlice[slice],
      optimisticAllocationDeltaScaled100:
          categoryOverlay.allocationDeltaScaled100,
      categoryOverlay: categoryOverlay,
    );
  }

  static String _analysisScopeLabel(LedgerTimeScope scope) => switch (scope) {
    AllTimeScope() => 'Összesen',
    YearScope(:final year) => '$year',
    MonthScope(:final value) => DashboardTimeLabelFormatter.yearMonth(value),
    DayScope(:final date) => DashboardTimeLabelFormatter.date(
      YearMonth(year: date.year, month: date.month),
      date.day,
    ),
  };

  /// Actuals follow the exact visible ledger child. Financial-limit storage
  /// remains intentionally coarser: a Day child uses its containing Month
  /// limit key while its numerator comes from the existing sparse daily bank.
  static int _analysisActualFor({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LedgerTimeScope scope,
    required int persistedActualScaled100,
  }) => switch (scope) {
    DayScope(:final date) => _dailyActual(
      snapshot.rhythmSnapshot,
      direction: direction,
      targetHandle: targetHandle,
      year: date.year,
      month: date.month,
      day: date.day,
    ),
    _ => persistedActualScaled100,
  };

  static int _dailyActual(
    PreparedBudgetRhythmSnapshot? rhythm, {
    required LedgerDirection direction,
    required int targetHandle,
    required int year,
    required int month,
    required int day,
  }) {
    if (rhythm == null || rhythm.coreRevision <= 0) return 0;
    final epochDay =
        DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final points = rhythm
        .directionBank(direction)
        .pointsForTargetHandle(targetHandle);
    for (final point in points) {
      if (point.epochDay == epochDay) return point.actualScaled100;
      if (point.epochDay > epochDay) break;
    }
    return 0;
  }

  String _titleFor(DashboardBudgetTarget target) => target.isAggregate
      ? DashboardBudgetAggregateVisual.forDirection(_direction).title
      : target.category!.displayName;

  FinancialLimitKey _financialLimitKeyFor(
    DashboardBudgetTarget target, {
    required BudgetLimitPeriod period,
  }) => FinancialLimitKey(
    direction: switch (_direction) {
      LedgerDirection.income => FinancialLimitDirection.income,
      LedgerDirection.expense => FinancialLimitDirection.expense,
    },
    target: target.isAggregate
        ? const FinancialLimitAggregateTarget()
        : FinancialLimitCategoryTarget(target.category!.id),
    period: switch (period) {
      BudgetLimitSumPeriod() => const FinancialLimitSumPeriod(),
      BudgetLimitYearPeriod(:final year) => FinancialLimitYearPeriod(year),
      BudgetLimitMonthPeriod(:final year, :final month) =>
        FinancialLimitMonthPeriod(year, month),
    },
  );

  void _recordHeaderBinding(DashboardBudgetLiveSelectionState header) {
    final frame = _visibleFrame.value;
    final signature = Object.hash(
      frame?.coreRevision,
      _direction,
      frame?.scope.timeScope,
      header.target.handle,
      header.title,
      header.analysisScopeLabel,
      header.actualScaled100,
      header.limitScaled100,
    );
    if (_lastHeaderDiagnosticSignature == signature) return;
    _lastHeaderDiagnosticSignature = signature;
    if (!header.isAvailable) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PREPARED_VALUE_MISSING',
          coreRevision: frame?.coreRevision,
          direction: _direction.name,
          scope: 'targetHandle=${header.target.handle}',
        ),
      );
      return;
    }
    final scope = frame?.scope.timeScope;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_HEADER_VALUE_BOUND',
        coreRevision: frame?.coreRevision,
        direction: _direction.name,
        totalMinor: header.actualScaled100,
        scope:
            'plane=${_planeDiagnosticName(scope)} '
            'targetHandle=${header.target.handle} '
            'actualScaled100=${header.actualScaled100} '
            'hasLimit=${header.hasLimit} '
            'limitScaled100=${header.limitScaled100 ?? '-'}',
      ),
    );
  }

  void _recordDirectionDomain(
    DashboardBudgetTargetCatalog catalog,
    PreparedBudgetLimitSnapshot? snapshot,
  ) {
    final signature = Object.hash(
      _direction,
      snapshot?.coreRevision,
      catalog.targetCount,
    );
    if (_lastDirectionDomainDiagnosticSignature == signature) return;
    _lastDirectionDomainDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DIRECTION_DOMAIN_READY',
        coreRevision: snapshot?.coreRevision,
        direction: _direction.name,
        scope:
            'categoryCount=${catalog.targetCount - 1} '
            'targetCount=${catalog.targetCount}',
      ),
    );
  }

  void _recordProgressBinding(DashboardBudgetLiveSelectionState selection) {
    final visual = selection.visual;
    final signature = Object.hash(
      visual.targetHandle,
      visual.limitKey,
      visual.actualScaled100,
      visual.effectiveLimitScaled100,
      visual.rawProgress,
      visual.visualProgress,
      selection.direction,
    );
    if (_lastProgressDiagnosticSignature == signature) return;
    _lastProgressDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PROGRESS_BOUND',
        totalMinor: visual.actualScaled100,
        direction: selection.direction.name,
        scope:
            'direction=${selection.direction.name} '
            'targetHandle=${visual.targetHandle} '
            'targetIdentity=${visual.limitKey?.target.runtimeType ?? '-'} '
            'hasPositiveLimit=${visual.hasPositiveLimit} '
            'effectiveLimitScaled100=${visual.effectiveLimitScaled100 ?? '-'} '
            'rawProgress=${visual.rawProgress} '
            'visualProgress=${visual.visualProgress}',
      ),
    );
    if (visual.rawProgress < 1 && visual.visualProgress >= 1) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_PROGRESS_IDENTITY_MISMATCH',
          scope:
              'targetHandle=${visual.targetHandle} '
              'rawProgress=${visual.rawProgress} '
              'visualProgress=${visual.visualProgress}',
        ),
      );
    }
  }

  void _recordPartitionBinding(
    DashboardBudgetPartitionPresentation partition, {
    required int selectedHandle,
  }) {
    final signature = Object.hash(
      partition.direction,
      partition.period,
      partition.periodSliceIndex,
      partition.coreRevision,
      partition.aggregateActualScaled100,
      partition.effectiveAggregateLimitScaled100,
      partition.preparedAllocatedTotalScaled100,
      partition.optimisticAllocationDeltaScaled100,
      partition.liveAllocatedTotalScaled100,
      selectedHandle,
      partition.categoryOverlay,
    );
    if (_lastPartitionDiagnosticSignature == signature) return;
    _lastPartitionDiagnosticSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PARTITION_BOUND',
        coreRevision: partition.coreRevision,
        direction: partition.direction.name,
        totalMinor: partition.aggregateActualScaled100,
        scope:
            'period=${_budgetPeriodDiagnosticName(partition.period)} '
            'slice=${partition.periodSliceIndex ?? '-'} '
            'aggregateBudgetLimitScaled100=${partition.effectiveAggregateLimitScaled100 ?? '-'} '
            'aggregateActualScaled100=${partition.aggregateActualScaled100 ?? '-'} '
            'preparedAllocatedTotalScaled100=${partition.preparedAllocatedTotalScaled100} '
            'optimisticAllocationDeltaScaled100=${partition.optimisticAllocationDeltaScaled100} '
            'liveAllocatedTotalScaled100=${partition.liveAllocatedTotalScaled100} '
            'allocationRawRatio=${partition.allocationRawRatio} '
            'allocationVisualCoverage=${partition.allocationVisualCoverage} '
            'selectedTargetHandle=$selectedHandle '
            'segmentCount=${partition.bank?.targetCount == null ? 0 : partition.bank!.targetCount - 1} '
            'source=prepared+optimistic',
      ),
    );
  }

  static String _budgetPeriodDiagnosticName(BudgetLimitPeriod? period) =>
      switch (period) {
        BudgetLimitSumPeriod() => 'sum',
        BudgetLimitYearPeriod(:final year) => 'year:$year',
        BudgetLimitMonthPeriod(:final year, :final month) =>
          'month:$year-$month',
        null => 'unavailable',
      };

  String _planeDiagnosticName(LedgerTimeScope? scope) => switch (scope) {
    AllTimeScope() => 'sum',
    YearScope() => 'year',
    MonthScope() => 'month',
    DayScope() => 'day',
    null => 'unavailable',
  };

  LedgerDirection get _direction => switch (_transactionDirection.direction) {
    TransactionDirection.income => LedgerDirection.income,
    TransactionDirection.expense => LedgerDirection.expense,
  };

  @override
  void dispose() {
    _categoryCollection.removeListener(_refreshCatalogForCategoryInput);
    _visibleFrame.removeListener(_refreshForVisibleFrame);
    _transactionDirection.removeListener(_refreshCatalogForDirection);
    _limitEditController?.removeListener(_refreshForOptimisticLimitEdit);
    super.dispose();
  }
}

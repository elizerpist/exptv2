import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/debug/debug_console.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/category_limit.dart';
import '../../../models/budget_goal_kind.dart';
import '../../../models/transaction_category.dart';
import '../../../models/transaction_log_entry.dart';
import '../../../models/transaction_record.dart';
import '../../../slots/category_color_resolver.dart';
import '../../../slots/category_color_manager.dart';
import '../../../state/budget_v2_limit_persistence_coordinator.dart';
import '../../../state/transaction_store.dart';
import '../balance/spendee_balance_collapse_controller.dart';
import '../balance/spendee_balance_post_content.dart';
import '../balance/spendee_balance_transaction_log.dart';
import '../balance/spendee_balance_visual_spec.dart';
import '../balance/spendee_budget_v2_components.dart';
import 'budget_v2_limit_edit_controller.dart';
import 'budget_v2_diagnostics_scope.dart';
import 'budget_v2_interaction_diagnostics.dart';
import 'budget_v2_selection_controller.dart';
import 'budget_v2_log_projection.dart';
import 'budget_v2_query_controller.dart';
import 'budget_v2_snapshot.dart';

typedef BudgetV2TransactionDeleteRequest =
    FutureOr<bool> Function(TransactionRecord record);

/// Public clean-room owner for the Budget V2 route.
///
/// Expensive store projections are resolved once per store revision. The
/// reviewed avatar rail owns every pointer frame locally; this widget hears
/// only interaction boundaries and a final settled avatar.
class SpendeeBudgetV2Dashboard extends StatefulWidget {
  const SpendeeBudgetV2Dashboard({
    super.key,
    required this.store,
    required this.brand,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.logBottomPadding,
    this.menuButton,
    this.onFilterPressed,
    this.onHeaderTap,
    this.onRenameMerchantRequested,
    this.avatarAppearance = const BudgetV2AvatarAppearance(),
  });

  final TransactionStore store;
  final Widget brand;
  final Widget? menuButton;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final BudgetV2TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onHeaderTap;
  final ValueChanged<TransactionRecord>? onRenameMerchantRequested;
  final double logBottomPadding;
  final BudgetV2AvatarAppearance avatarAppearance;

  @override
  State<SpendeeBudgetV2Dashboard> createState() =>
      _SpendeeBudgetV2DashboardState();
}

class _SpendeeBudgetV2DashboardState extends State<SpendeeBudgetV2Dashboard>
    with SingleTickerProviderStateMixin {
  static const _commitIdleDelay = Duration(milliseconds: 360);

  final _snapshotCache = BudgetV2StoreSnapshotCache();
  final _logProjectionCache = BudgetV2LogProjectionCache();
  final _interactionDiagnostics = BudgetV2InteractionDiagnostics();
  late final SpendeeBalanceCollapseController _collapseController;
  late final AnimationController _collapseAnimationController;
  Animation<double>? _collapseAnimation;
  late final BudgetV2LimitPersistenceCoordinator _limitPersistence;
  late BudgetV2SelectionController _selection;
  late BudgetV2QueryController _query;
  late BudgetV2LimitEditController _limitEdit;
  Timer? _commitTimer;
  List<CategoryBudgetBarData> _sourceBars = const <CategoryBudgetBarData>[];
  String _queryAvatarSignature = '';
  Object? _activeLogQueryKey;
  _BudgetV2DashboardExternalScopeKey? _activeExternalScopeKey;
  var _logRowLimit = TransactionStore.visibleDisplayLogPageSize;
  var _externalSelectionEpoch = 0;
  var _vendorSelectionEpoch = 0;
  var _railRuntimeEpoch = 0;
  var _activeGeneration = 0;
  var _timeRailExpanded = false;
  BudgetV2InteractionSession? _interactionSession;
  var _interactionResolveCountAtStart = 0;
  var _interactionPreparationCountAtStart = 0;
  var _interactionQueryResolveCountAtStart = 0;
  var _interactionQueryCacheMissCountAtStart = 0;
  var _interactionLogProjectionCountAtStart = 0;
  var _diagnosticSourceRevision = 0;
  var _diagnosticRecordCount = 0;
  var _diagnosticBarCount = 0;
  var _rawPointerSessionAwaitingCarouselStart = false;

  @override
  void initState() {
    super.initState();
    _collapseController = SpendeeBalanceCollapseController()
      ..addListener(_handleCollapseChanged);
    _collapseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_handleCollapseAnimation);
    final source = BudgetV2SnapshotSource.fromStore(widget.store);
    _snapshotCache.resolve(source);
    _updateDiagnosticSource(source);
    _sourceBars = _barsForSource(source);
    _query = _createQueryController(_sourceBars);
    final externalScope = _externalQueryScope();
    _activeExternalScopeKey = _BudgetV2DashboardExternalScopeKey(externalScope);
    final reconciliation = _query.reconcileExternalScope(externalScope);
    final selectedAvatarKey =
        _validAvatarKey(reconciliation.avatarKeyToAdopt, _sourceBars) ??
        _initialAvatarKey(_sourceBars);
    _selection = BudgetV2SelectionController(
      initialAvatarKey: selectedAvatarKey ?? '',
    );
    _limitPersistence = BudgetV2LimitPersistenceCoordinator(
      initialStoreIdentity: widget.store,
    );
    _limitEdit = _createLimitEditController();
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetV2Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.store, widget.store)) {
      _finishInteractionAsCancelled();
      _cancelPendingCommit(reason: 'store_replaced');
      _limitPersistence.replaceStoreIdentity(widget.store);
      _limitEdit.dispose();
      _limitEdit = _createLimitEditController();
      final source = BudgetV2SnapshotSource.fromStore(widget.store);
      _snapshotCache.resolve(source);
      _updateDiagnosticSource(source);
      _sourceBars = _barsForSource(source);
      _query = _createQueryController(_sourceBars);
      final externalScope = _externalQueryScope();
      _activeExternalScopeKey = _BudgetV2DashboardExternalScopeKey(
        externalScope,
      );
      final reconciliation = _query.reconcileExternalScope(externalScope);
      final initial =
          _validAvatarKey(reconciliation.avatarKeyToAdopt, _sourceBars) ??
          _initialAvatarKey(_sourceBars) ??
          '';
      _selection.dispose();
      _selection = BudgetV2SelectionController(initialAvatarKey: initial);
      _activeLogQueryKey = null;
      _logRowLimit = TransactionStore.visibleDisplayLogPageSize;
      _activeGeneration = 0;
      _externalSelectionEpoch += 1;
      _vendorSelectionEpoch += 1;
      _railRuntimeEpoch += 1;
    }
  }

  @override
  void dispose() {
    _finishInteractionAsCancelled();
    _commitTimer?.cancel();
    _collapseAnimationController
      ..removeListener(_handleCollapseAnimation)
      ..dispose();
    _collapseController
      ..removeListener(_handleCollapseChanged)
      ..dispose();
    _selection.dispose();
    _limitEdit.dispose();
    _limitPersistence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = BudgetV2SnapshotSource.fromStore(widget.store);
    final prepared = _snapshotCache.resolve(source);
    _updateDiagnosticSource(source);
    final bars = _barsForSource(source);
    final collapseVisuals = SpendeeBalanceCollapseVisuals.forProgress(
      _collapseController.progress,
    );
    _sourceBars = bars;
    _ensureQueryController(bars);
    final externalScope = _externalQueryScope();
    _trackExternalScope(externalScope);
    _applyQueryReconciliation(
      bars,
      _query.reconcileExternalScope(externalScope),
    );
    _reconcileSelectedKey(bars);
    final selectedAvatarKey = _validAvatarKey(_localAvatarKey, bars);
    final logQueryKey = _logQueryKey(
      selectedAvatarKey,
      prepared.sourceRevision,
    );
    final logScope = _logScope(selectedAvatarKey);
    if (_activeLogQueryKey != logQueryKey) {
      _activeLogQueryKey = logQueryKey;
      _logRowLimit = TransactionStore.visibleDisplayLogPageSize;
    }
    final logProjection = selectedAvatarKey == null
        ? const BudgetV2LogProjection(
            entries: <TransactionLogEntry>[],
            visibleRowCount: 0,
            totalRowCount: 0,
          )
        : _logProjectionCache.resolve(
            snapshot: prepared,
            query: BudgetV2LogQuery(
              avatarKey: selectedAvatarKey,
              scope: logScope,
              selectedVendorKey: _query.selectedVendorKey,
              rowLimit: _logRowLimit,
            ),
          );

    return BudgetV2DiagnosticsScope(
      allowLegacyChartDiagnostics: false,
      child: FocusTraversalGroup(
        key: const ValueKey('spendee-budget-v2-focus-traversal'),
        policy: ReadingOrderTraversalPolicy(),
        child: ColoredBox(
          color: SpendeeBalanceVisualSpec.pageBackground,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              key: const ValueKey('spendee-budget-v2-dashboard'),
              width: SpendeeBalanceVisualSpec.canvas.width,
              height: SpendeeBalanceVisualSpec.canvas.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    top: 33.3,
                    right: 0,
                    left: 0,
                    height: 70,
                    child: widget.brand,
                  ),
                  Positioned(
                    top: SpendeeBalanceVisualSpec.heroTop,
                    right: SpendeeBalanceVisualSpec.canvasContentInset,
                    left: SpendeeBalanceVisualSpec.canvasContentInset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragStart: (_) => _beginCollapseDrag(),
                      onVerticalDragUpdate: (details) =>
                          _updateCollapseDrag(details.delta.dy),
                      onVerticalDragEnd: (_) => _endCollapseDrag(),
                      onVerticalDragCancel: _endCollapseDrag,
                      child: _BudgetV2SnapshotRegion(
                        bars: bars,
                        preparedSnapshot: prepared,
                        selectedVendorKey: _query.selectedVendorKey,
                        vendorSelectionEpoch: _vendorSelectionEpoch,
                        selectedIndex: _selectedIndex(bars),
                        externalSelectionEpoch: _externalSelectionEpoch,
                        railRuntimeEpoch: _railRuntimeEpoch,
                        limitEdit: _limitEdit,
                        appearance: widget.avatarAppearance,
                        collapseVisuals: collapseVisuals,
                        onHeaderTap: widget.onHeaderTap,
                        onRawPointerDown: _beginRawPointerInteraction,
                        onRawPointerUp: _finishRawPointerWithoutCarousel,
                        onDirectInteractionStarted: _beginCarouselInteraction,
                        onInteractionCancelled: _cancelPointerInteraction,
                        onInteractionCompleted: _completePointerInteraction,
                        onPreview: _previewAvatar,
                        onSettled: _settleAvatar,
                        onAvatarRequested: _requestAvatar,
                        onVendorSelected: _selectVendor,
                        onLongPressStart: _beginLimitEdit,
                        onLongPressMoveUpdate: _updateLimitEdit,
                        onLongPressEnd: _finishLimitEdit,
                        onLongPressCancel: _cancelLimitEdit,
                        onLimitChanged: _limitEdit.persist,
                      ),
                    ),
                  ),
                  Positioned(
                    top: SpendeeBalanceVisualSpec.actionTop,
                    right: SpendeeBalanceVisualSpec.canvasContentInset,
                    left: SpendeeBalanceVisualSpec.canvasContentInset,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        collapseVisuals.scrollContentTranslateY +
                            collapseVisuals.postTranslateY,
                      ),
                      child: _buildPostContent(
                        projection: logProjection,
                        queryKey: logQueryKey,
                      ),
                    ),
                  ),
                  if (widget.menuButton case final menu?)
                    Positioned(
                      top: SpendeeBalanceVisualSpec.menuTop,
                      right: SpendeeBalanceVisualSpec.menuRight,
                      child: menu,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent({
    required BudgetV2LogProjection projection,
    required Object queryKey,
  }) {
    final store = widget.store;
    final entries = projection.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SpendeeBalanceActionToggle(
          activeType: store.activeType,
          onChanged: store.setActiveType,
        ),
        const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
        SpendeeBalanceSummary(
          label: store.activeSummaryTitle,
          amount: store.activeSummary.formattedFor(store.activeType),
          scopeExpanded: _timeRailExpanded,
          onOpenScopePicker: () =>
              setState(() => _timeRailExpanded = !_timeRailExpanded),
          onSummaryTap: widget.onPickSummaryMonth,
          onResetCurrentMonth: () =>
              unawaited(store.resetSummaryToCurrentMonth()),
          onShiftPeriod: (direction) =>
              unawaited(store.shiftSummaryPeriod(direction)),
          onCycleScope: () => unawaited(store.cycleSummaryWindow()),
        ),
        const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
        SpendeeBalanceSearchFilter(
          query: store.searchQuery,
          filters: _searchChips(),
          onQueryChanged: store.setSearchQuery,
          onRemoveFilter: _removeFilter,
          onFilterPressed: widget.onFilterPressed ?? () {},
          onCycleScope: () => unawaited(store.cycleSummaryWindow()),
        ),
        if (_timeRailExpanded) ...<Widget>[
          const SizedBox(height: 3),
          SpendeeBalanceTimeScopeRail(
            label: '',
            currentLabel: '',
            selectedKey: store.summaryWindow.name,
            options: const <SpendeeBalanceTimeScopeItem>[
              SpendeeBalanceTimeScopeItem(key: 'monthly', label: 'Hónap'),
              SpendeeBalanceTimeScopeItem(key: 'yearly', label: 'Év'),
              SpendeeBalanceTimeScopeItem(key: 'allTime', label: 'Összes'),
            ],
            collapseProgress: _collapseController.progress,
            showChrome: false,
            onSelected: _selectScope,
            onCollapseDragStart: _beginCollapseDrag,
            onCollapseDragUpdate: _updateCollapseDrag,
            onCollapseDragEnd: _endCollapseDrag,
            onCollapseToggle: _toggleCollapse,
          ),
        ],
        SpendeeBalanceCollapseControl(
          transactionCount: entries.where((entry) => !entry.isHeader).length,
          collapseProgress: _collapseController.progress,
          dragging: _collapseController.dragging,
          onDragStart: _beginCollapseDrag,
          onDragUpdate: _updateCollapseDrag,
          onDragEnd: _endCollapseDrag,
          onToggle: _toggleCollapse,
        ),
        const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
        RepaintBoundary(
          key: const ValueKey('spendee-balance-transaction-repaint-boundary'),
          child: SpendeeBalanceTransactionLog.fromEntries(
            entries: entries,
            categoriesById: store.categoriesById,
            queryKey: queryKey,
            hasMore: projection.hasMore,
            onLoadMore: projection.hasMore ? _loadMoreLogEntries : null,
            bottomPadding: widget.logBottomPadding,
            onFastFilter: (record, _) => _selectVendor(record.displayMerchant),
            onRecordTap: widget.onEditTransaction ?? (_) {},
            onDeleteRequested:
                widget.onDeleteTransactionRequested ?? (_) async => false,
            onCategoryFilter: store.setCategoryFilter,
            onEditTransaction: widget.onEditTransaction ?? (_) {},
            onRenameMerchantRequested: widget.onRenameMerchantRequested,
            onResetMerchantName: (record) =>
                unawaited(store.resetTransactionNamesByMerchant(record)),
          ),
        ),
      ],
    );
  }

  List<SpendeeBalanceSearchChip> _searchChips() {
    final store = widget.store;
    final chips = <SpendeeBalanceSearchChip>[];
    for (final id in store.activeCategoryIds) {
      final category = store.categoriesById[id];
      chips.add(
        SpendeeBalanceSearchChip(
          keyValue: 'category:$id',
          label: category?.name ?? 'Kategória',
          color: CategoryColorResolver.color(category: category),
        ),
      );
    }
    for (final merchant in store.activeMerchantFilters) {
      chips.add(
        SpendeeBalanceSearchChip(
          keyValue: 'merchant:$merchant',
          label: merchant,
          color: const Color(0xFFE84CAE),
        ),
      );
    }
    return List<SpendeeBalanceSearchChip>.unmodifiable(chips);
  }

  void _removeFilter(SpendeeBalanceSearchChip chip) {
    final separator = chip.keyValue.indexOf(':');
    if (separator < 0) return;
    final type = chip.keyValue.substring(0, separator);
    final value = chip.keyValue.substring(separator + 1);
    if (type == 'category') {
      final id = int.tryParse(value);
      if (id != null) widget.store.clearCategoryFilterId(id);
    } else if (type == 'merchant') {
      _query.selectVendor(null);
      _query.acknowledgeVendor(const <String>{});
      setState(_resetLogWindow);
      widget.store.clearMerchantFilter(value);
    }
  }

  void _selectScope(SpendeeBalanceTimeScopeItem item) {
    final date = widget.store.summaryReferenceDate;
    switch (item.key) {
      case 'monthly':
        unawaited(widget.store.setSummaryMonth(date.year, date.month));
      case 'yearly':
        unawaited(widget.store.setSummaryYear(date.year));
      case 'allTime':
        unawaited(widget.store.setSummaryAllTime());
    }
  }

  void _handleCollapseChanged() {
    if (mounted) setState(() {});
  }

  void _handleCollapseAnimation() {
    final animation = _collapseAnimation;
    if (animation != null) _collapseController.jumpTo(animation.value);
  }

  void _beginCollapseDrag() {
    _collapseAnimationController.stop();
    _collapseAnimation = null;
    _collapseController.beginDrag();
  }

  void _updateCollapseDrag(double dy) => _collapseController.dragBy(dy);

  void _endCollapseDrag() {
    final start = _collapseController.offset;
    final target = _collapseController.release();
    _animateCollapseTo(
      target == SpendeeBalanceCollapseTarget.collapsed
          ? SpendeeBalanceCollapseController.maxOffset
          : 0,
      start: start,
    );
  }

  void _toggleCollapse() {
    final destination =
        _collapseController.toggleTarget ==
            SpendeeBalanceCollapseTarget.collapsed
        ? SpendeeBalanceCollapseController.maxOffset
        : 0.0;
    _animateCollapseTo(destination, start: _collapseController.offset);
  }

  void _animateCollapseTo(double destination, {required double start}) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _collapseController.jumpTo(destination);
      return;
    }
    _collapseAnimationController.stop();
    _collapseAnimation = Tween<double>(begin: start, end: destination).animate(
      CurvedAnimation(
        parent: _collapseAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    unawaited(
      _collapseAnimationController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _collapseAnimation = null;
        _collapseController.jumpTo(destination);
      }),
    );
  }

  void _beginRawPointerInteraction({required int physicalFrameCount}) {
    _discardPendingPrimaryQuery();
    _cancelPendingCommit(reason: 'new_interaction');
    if (_selection.phase == BudgetV2SelectionPhase.physical) {
      _recordInteractionProgress(physicalFrameCount: physicalFrameCount);
    }
    _finishInteractionAsCancelled();
    _activeGeneration = _selection.beginPointerDown();
    _startInteractionDiagnostics();
    _rawPointerSessionAwaitingCarouselStart = true;
  }

  void _beginCarouselInteraction({required bool directDrag}) {
    if (!directDrag) return;
    if (_rawPointerSessionAwaitingCarouselStart) {
      _rawPointerSessionAwaitingCarouselStart = false;
      return;
    }
    _discardPendingPrimaryQuery();
    _cancelPendingCommit(reason: 'carousel_interaction');
    _finishInteractionAsCancelled();
    _activeGeneration = _selection.beginPointerDown();
    _startInteractionDiagnostics();
  }

  void _finishRawPointerWithoutCarousel() {
    if (!_rawPointerSessionAwaitingCarouselStart || _limitEdit.isEditing) {
      return;
    }
    _finishInteractionAsCancelled();
  }

  void _startInteractionDiagnostics() {
    if (_interactionSession != null) return;
    _interactionSession = _interactionDiagnostics.begin(
      sourceRevision: _diagnosticSourceRevision,
      recordCount: _diagnosticRecordCount,
      barCount: _diagnosticBarCount,
    );
    _interactionResolveCountAtStart = _snapshotCache.resolveCount;
    _interactionPreparationCountAtStart = _snapshotCache.preparationCount;
    final queryDiagnostics = _logProjectionCache.diagnostics;
    _interactionQueryResolveCountAtStart = queryDiagnostics.resolveCount;
    _interactionQueryCacheMissCountAtStart = queryDiagnostics.cacheMissCount;
    _interactionLogProjectionCountAtStart = queryDiagnostics.projectionCount;
  }

  void _cancelPointerInteraction() {
    _cancelPendingCommit(reason: 'gesture_cancel');
  }

  void _completePointerInteraction({
    required int settledIndex,
    required int physicalFrameCount,
    required bool cancelled,
  }) {
    if (_interactionSession == null) return;
    _recordInteractionProgress(physicalFrameCount: physicalFrameCount);
    if (cancelled) _finishInteractionAsCancelled(settledIndex: settledIndex);
  }

  void _recordInteractionProgress({required int physicalFrameCount}) {
    final session = _interactionSession;
    if (session == null) return;
    session
      ..recordPhysicalFrames(physicalFrameCount)
      ..recordDirectSnapshotWork(
        resolveCount:
            _snapshotCache.resolveCount - _interactionResolveCountAtStart,
        preparationCount:
            _snapshotCache.preparationCount -
            _interactionPreparationCountAtStart,
      )
      ..recordDirectQueryWork(
        resolveCount:
            _logProjectionCache.diagnostics.resolveCount -
            _interactionQueryResolveCountAtStart,
        cacheMissCount:
            _logProjectionCache.diagnostics.cacheMissCount -
            _interactionQueryCacheMissCountAtStart,
        projectionCount:
            _logProjectionCache.diagnostics.projectionCount -
            _interactionLogProjectionCountAtStart,
      );
  }

  void _previewAvatar(int index, {required bool directDrag}) {
    if (!directDrag || index < 0 || index >= _sourceBars.length) return;
    _selection.updatePhysical(offset: index.toDouble());
  }

  void _settleAvatar(int index, {required bool directDrag}) {
    if (index < 0 || index >= _sourceBars.length) return;
    if (_selection.phase != BudgetV2SelectionPhase.physical) {
      _activeGeneration = _selection.beginPointerDown();
    }
    final bar = _sourceBars[index];
    if (!_selection.settleAvatar(bar.key, generation: _activeGeneration)) {
      return;
    }
    _prepareLocalAvatarIntent(bar);
    setState(_resetLogWindow);
    _scheduleAvatarCommit(bar);
  }

  void _scheduleAvatarCommit(CategoryBudgetBarData bar) {
    _commitTimer?.cancel();
    final generation = _activeGeneration;
    _commitTimer = Timer(
      _commitIdleDelay,
      () => _commitAvatar(generation, bar.key),
    );
    DebugConsole.log(
      '[BudgetV2Carousel] phase=filter_schedule key=${bar.key} '
      'generation=$generation delay_ms=${_commitIdleDelay.inMilliseconds}',
    );
  }

  void _commitAvatar(int generation, String avatarKey) {
    _commitTimer = null;
    final previousAvatarKey = _selection.committedAvatarKey;
    if (!mounted || !_selection.commitIfCurrent(generation)) return;
    final bar = _barForKey(avatarKey);
    if (bar == null || avatarKey == previousAvatarKey) {
      _finishInteractionAsCommitted(commitCount: 0);
      return;
    }
    final selectedVendorKey = _query.selectedVendorKey;
    final stopwatch = Stopwatch()..start();
    setState(_resetLogWindow);
    final category = bar.targetType == LimitTargetType.category
        ? bar.category
        : null;
    _query.acknowledgeAvatar(
      avatarKey: avatarKey,
      categoryIds: category == null
          ? const <int>{}
          : <int>{category.transactionCategoryID},
    );
    _query.acknowledgeVendor(
      selectedVendorKey == null
          ? const <String>{}
          : <String>{selectedVendorKey},
    );
    widget.store.applyBudgetV2AvatarFilter(
      category: category,
      selectedVendor: selectedVendorKey,
    );
    stopwatch.stop();
    _finishInteractionAsCommitted(
      commitCount: 1,
      finalCommitDuration: stopwatch.elapsed,
    );
    DebugConsole.log(
      '[BudgetV2Carousel] phase=commit key=$avatarKey '
      'generation=$generation category=${category?.transactionCategoryID ?? 'overview'}',
    );
  }

  void _cancelPendingCommit({required String reason}) {
    if (_commitTimer == null) return;
    _commitTimer?.cancel();
    _commitTimer = null;
    DebugConsole.log('[BudgetV2Carousel] phase=filter_cancel reason=$reason');
  }

  void _finishInteractionAsCommitted({
    required int commitCount,
    Duration finalCommitDuration = Duration.zero,
  }) {
    final session = _interactionSession;
    _interactionSession = null;
    _rawPointerSessionAwaitingCarouselStart = false;
    session?.complete(
      settledIndex: _selectedIndex(_sourceBars),
      commitCount: commitCount,
      finalCommitDuration: finalCommitDuration,
    );
  }

  void _finishInteractionAsCancelled({int? settledIndex}) {
    final session = _interactionSession;
    _interactionSession = null;
    _rawPointerSessionAwaitingCarouselStart = false;
    session?.cancel(settledIndex: settledIndex ?? _selectedIndex(_sourceBars));
  }

  void _updateDiagnosticSource(BudgetV2SnapshotSource source) {
    _diagnosticSourceRevision = source.revision.hashCode;
    _diagnosticRecordCount = source.records.length;
    _diagnosticBarCount = source.bars.length;
  }

  void _requestAvatar(CategoryBudgetBarData bar) {
    final index = _sourceBars.indexWhere(
      (candidate) => candidate.key == bar.key,
    );
    if (index < 0) return;
    _cancelPendingCommit(reason: 'remote_request');
    _activeGeneration = _selection.beginPointerDown();
    if (!_selection.settleAvatar(bar.key, generation: _activeGeneration)) {
      return;
    }
    _prepareLocalAvatarIntent(bar);
    setState(() {
      _externalSelectionEpoch += 1;
      _resetLogWindow();
    });
    _scheduleAvatarCommit(bar);
  }

  void _prepareLocalAvatarIntent(CategoryBudgetBarData bar) {
    if (bar.key == _selection.committedAvatarKey) return;
    _query.selectVendor(null);
  }

  void _selectVendor(String vendorKey) {
    final value = vendorKey.trim();
    if (value.isEmpty) return;
    _query.selectVendor(value);
    _query.acknowledgeVendor(<String>{value});
    setState(_resetLogWindow);
    final pendingPrimary =
        _selection.phase == BudgetV2SelectionPhase.settled &&
        _selection.settledAvatarKey != _selection.committedAvatarKey;
    if (!pendingPrimary) widget.store.setMerchantFilter(value);
  }

  void _beginLimitEdit(
    CategoryBudgetBarData bar,
    LongPressStartDetails details,
  ) {
    _cancelPendingCommit(reason: 'limit_edit');
    _startInteractionDiagnostics();
    _limitEdit.begin(
      avatarKey: bar.key,
      initialAmount: bar.limitAmount,
      globalY: details.globalPosition.dy,
    );
  }

  void _updateLimitEdit(LongPressMoveUpdateDetails details) {
    _limitEdit.update(globalY: details.globalPosition.dy);
  }

  void _finishLimitEdit(LongPressEndDetails _) {
    _limitEdit.finish();
    _finishInteractionAsCommitted(commitCount: 0);
  }

  void _cancelLimitEdit() {
    final wasEditing = _limitEdit.isEditing;
    _limitEdit.cancel();
    if (wasEditing) _finishInteractionAsCancelled();
  }

  BudgetV2LimitEditController _createLimitEditController() =>
      BudgetV2LimitEditController(
        allocateOperationId: () =>
            _limitPersistence.allocateOperationId(widget.store),
        onPersist: _persistLimit,
      );

  void _persistLimit(String avatarKey, double amount, int operationId) {
    final bar = _barForKey(avatarKey);
    if (bar == null) return;
    final store = widget.store;
    final limitEdit = _limitEdit;
    unawaited(
      _limitPersistence.schedule(
        storeIdentity: store,
        avatarKey: avatarKey,
        operationId: operationId,
        write: (isCurrentRuntime) => store.saveCategoryLimitForBarInline(
          bar,
          limitAmount: amount,
          alertActive: amount > 0,
          shouldApplyResult: isCurrentRuntime,
        ),
        onSuccess: (completedOperationId) {
          limitEdit.acknowledgePersisted(
            avatarKey,
            operationId: completedOperationId,
          );
        },
        onError: (failedOperationId, error, stackTrace) {
          DebugConsole.log(
            '[BudgetV2Limit] phase=persist_error key=$avatarKey '
            'operation_id=$failedOperationId error=$error',
          );
        },
      ),
    );
  }

  CategoryBudgetBarData? _barForKey(String key) {
    for (final bar in _sourceBars) {
      if (bar.key == key) return bar;
    }
    return null;
  }

  int _selectedIndex(List<CategoryBudgetBarData> bars) {
    final index = bars.indexWhere((bar) => bar.key == _localAvatarKey);
    return index < 0 ? 0 : index;
  }

  void _reconcileSelectedKey(List<CategoryBudgetBarData> bars) {
    if (bars.isEmpty) return;
    if (bars.any((bar) => bar.key == _localAvatarKey)) return;
    _adoptPrimaryAvatar(_initialAvatarKey(bars)!);
  }

  String get _localAvatarKey =>
      _selection.phase == BudgetV2SelectionPhase.settled
      ? _selection.settledAvatarKey
      : _selection.committedAvatarKey;

  BudgetV2ExternalQueryScope _logScope(String? avatarKey) {
    final external = _query.externalScope;
    if (_selection.phase != BudgetV2SelectionPhase.settled ||
        avatarKey == null ||
        avatarKey == _selection.committedAvatarKey) {
      return external;
    }
    final bar = _barForKey(avatarKey);
    final category = bar?.targetType == LimitTargetType.category
        ? bar?.category
        : null;
    return external.copyWith(
      categoryIds: category == null
          ? const <int>{}
          : <int>{category.transactionCategoryID},
      merchantKeys: const <String>{},
    );
  }

  void _loadMoreLogEntries() {
    setState(() => _logRowLimit += TransactionStore.visibleDisplayLogPageSize);
  }

  void _resetLogWindow() {
    _activeLogQueryKey = null;
    _logRowLimit = TransactionStore.visibleDisplayLogPageSize;
  }

  BudgetV2ExternalQueryScope _externalQueryScope() =>
      BudgetV2ExternalQueryScope(
        searchQuery: widget.store.searchQuery,
        categoryIds: widget.store.activeCategoryIds,
        merchantKeys: widget.store.activeMerchantFilters,
      );

  BudgetV2QueryController _createQueryController(
    List<CategoryBudgetBarData> bars,
  ) {
    _queryAvatarSignature = bars.map((bar) => bar.key).join('\u001f');
    final unfiltered = bars
        .where((bar) => bar.targetType == LimitTargetType.overview)
        .firstOrNull;
    return BudgetV2QueryController(
      unfilteredAvatarKey: unfiltered?.key ?? bars.firstOrNull?.key ?? '',
      avatarKeyByCategoryId: <int, String>{
        for (final bar in bars)
          if (bar.targetType == LimitTargetType.category) bar.targetId: bar.key,
      },
    );
  }

  void _ensureQueryController(List<CategoryBudgetBarData> bars) {
    final signature = bars.map((bar) => bar.key).join('\u001f');
    if (signature == _queryAvatarSignature) return;
    _query = _createQueryController(bars);
    _resetLogWindow();
  }

  void _applyQueryReconciliation(
    List<CategoryBudgetBarData> bars,
    BudgetV2QueryReconciliation reconciliation,
  ) {
    final adopted = _validAvatarKey(reconciliation.avatarKeyToAdopt, bars);
    if (adopted != null && adopted != _selection.committedAvatarKey) {
      _adoptPrimaryAvatar(adopted);
      return;
    }
    if (reconciliation.clearExternalAvatar) {
      final unfiltered = _validAvatarKey(_query.unfilteredAvatarKey, bars);
      if (unfiltered != null && unfiltered != _selection.committedAvatarKey) {
        _adoptPrimaryAvatar(unfiltered);
      }
    }
  }

  void _adoptPrimaryAvatar(String avatarKey) {
    _discardPendingPrimaryQuery();
    _finishInteractionAsCancelled();
    _cancelPendingCommit(reason: 'external_query');
    _selection.adoptCommittedAvatar(avatarKey);
    _activeGeneration = 0;
    _externalSelectionEpoch += 1;
    _railRuntimeEpoch += 1;
    _resetLogWindow();
  }

  void _discardPendingPrimaryQuery() {
    final pendingPrimary =
        _selection.phase == BudgetV2SelectionPhase.settled &&
        _selection.settledAvatarKey != _selection.committedAvatarKey;
    if (!pendingPrimary) return;
    final externalMerchants = widget.store.activeMerchantFilters;
    _query.selectVendor(
      externalMerchants.length == 1 ? externalMerchants.single : null,
    );
    _resetLogWindow();
  }

  static String? _validAvatarKey(
    String? avatarKey,
    List<CategoryBudgetBarData> bars,
  ) {
    if (avatarKey == null) return null;
    return bars.any((bar) => bar.key == avatarKey) ? avatarKey : null;
  }

  Object _logQueryKey(
    String? avatarKey,
    BudgetV2SnapshotRevision sourceRevision,
  ) => _BudgetV2DashboardLogQueryKey(
    sourceRevision: sourceRevision,
    avatarKey: avatarKey,
    selectedVendorKey: _query.selectedVendorKey,
  );

  void _trackExternalScope(BudgetV2ExternalQueryScope scope) {
    final next = _BudgetV2DashboardExternalScopeKey(scope);
    if (next == _activeExternalScopeKey) return;
    _activeExternalScopeKey = next;
    _vendorSelectionEpoch += 1;
  }

  static String? _initialAvatarKey(List<CategoryBudgetBarData> bars) =>
      bars.isEmpty ? null : bars.first.key;

  static List<CategoryBudgetBarData> _barsForSource(
    BudgetV2SnapshotSource source,
  ) {
    final overview = source.overviewItems
        .where(
          (item) =>
              item.kind.transactionType ==
              source.revision.activeType.nativeValue,
        )
        .firstOrNull;
    return List<CategoryBudgetBarData>.unmodifiable(<CategoryBudgetBarData>[
      if (overview != null)
        CategoryBudgetBarData(
          key: overview.key,
          targetType: LimitTargetType.overview,
          targetId: 0,
          transactionType: source.revision.activeType,
          window: overview.window,
          periodKey: overview.periodKey,
          title: overview.title,
          spent: overview.amount,
          hasLimit: overview.hasLimit,
          limitAmount: overview.limitAmount,
          alertActive: overview.alertActive,
          color: CategoryColorManager.color(switch (overview.kind) {
            BudgetGoalKind.expenseBudget => 11,
            BudgetGoalKind.incomeGoal => 16,
            BudgetGoalKind.savingGoal => 14,
          }),
          iconSlot: null,
          category: null,
          sourceLimit: overview.sourceLimit,
        ),
      ...source.bars,
    ]);
  }
}

class _BudgetV2SnapshotRegion extends StatelessWidget {
  const _BudgetV2SnapshotRegion({
    required this.bars,
    required this.preparedSnapshot,
    required this.selectedVendorKey,
    required this.vendorSelectionEpoch,
    required this.selectedIndex,
    required this.externalSelectionEpoch,
    required this.railRuntimeEpoch,
    required this.limitEdit,
    required this.appearance,
    required this.collapseVisuals,
    required this.onHeaderTap,
    required this.onRawPointerDown,
    required this.onRawPointerUp,
    required this.onDirectInteractionStarted,
    required this.onInteractionCancelled,
    required this.onInteractionCompleted,
    required this.onPreview,
    required this.onSettled,
    required this.onAvatarRequested,
    required this.onVendorSelected,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
    required this.onLimitChanged,
  });

  final List<CategoryBudgetBarData> bars;
  final BudgetV2PreparedSnapshot preparedSnapshot;
  final String? selectedVendorKey;
  final int vendorSelectionEpoch;
  final int selectedIndex;
  final int externalSelectionEpoch;
  final int railRuntimeEpoch;
  final BudgetV2LimitEditController limitEdit;
  final BudgetV2AvatarAppearance appearance;
  final SpendeeBalanceCollapseVisuals collapseVisuals;
  final VoidCallback? onHeaderTap;
  final void Function({required int physicalFrameCount}) onRawPointerDown;
  final VoidCallback onRawPointerUp;
  final void Function({required bool directDrag}) onDirectInteractionStarted;
  final VoidCallback onInteractionCancelled;
  final void Function({
    required int settledIndex,
    required int physicalFrameCount,
    required bool cancelled,
  })
  onInteractionCompleted;
  final BudgetV2AvatarPreviewCallback onPreview;
  final BudgetV2AvatarSettledCallback onSettled;
  final ValueChanged<CategoryBudgetBarData> onAvatarRequested;
  final ValueChanged<String> onVendorSelected;
  final void Function(CategoryBudgetBarData, LongPressStartDetails)
  onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;
  final GestureLongPressCancelCallback onLongPressCancel;
  final void Function(String avatarKey, double amount) onLimitChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: limitEdit,
      builder: (context, _) {
        final previewBars = <CategoryBudgetBarData>[
          for (final bar in bars)
            _withLimitPreview(
              bar,
              limitEdit.previewAmount(bar.key, fallback: bar.limitAmount),
            ),
        ];
        if (previewBars.isEmpty) {
          return const SizedBox(
            key: ValueKey('spendee-budget-v2-empty'),
            height: 438,
          );
        }
        final selected = selectedIndex.clamp(0, previewBars.length - 1);
        return SizedBox(
          height: 438,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                height: collapseVisuals.heroHeight,
                child: SpendeeBudgetV2Header(
                  bars: previewBars,
                  collapseProgress: collapseVisuals.progress,
                  onTap: onHeaderTap,
                ),
              ),
              Positioned(
                top: 137,
                right: 0,
                left: 0,
                height: 80,
                child: IgnorePointer(
                  ignoring: !collapseVisuals.insightsInteractive,
                  child: ExcludeFocus(
                    excluding: !collapseVisuals.insightsInteractive,
                    child: ExcludeSemantics(
                      excluding: !collapseVisuals.insightsInteractive,
                      child: Opacity(
                        opacity: collapseVisuals.insightOpacity,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            collapseVisuals.scrollContentTranslateY +
                                collapseVisuals.insightTranslateY,
                          ),
                          child: Transform.scale(
                            alignment: Alignment.topCenter,
                            scale: collapseVisuals.insightScale,
                            child: KeyedSubtree(
                              key: ValueKey(
                                'spendee-budget-v2-rail-runtime-'
                                '$railRuntimeEpoch',
                              ),
                              child: SpendeeBudgetV2AvatarBelt(
                                bars: previewBars,
                                selectedIndex: selected,
                                externalSelectionEpoch: externalSelectionEpoch,
                                onPreview: onPreview,
                                onSettled: onSettled,
                                onRawPointerDown: onRawPointerDown,
                                onRawPointerUp: onRawPointerUp,
                                onDirectInteractionStarted:
                                    onDirectInteractionStarted,
                                onInteractionCancelled: onInteractionCancelled,
                                onInteractionCompleted: onInteractionCompleted,
                                onAvatarLongPressStart: onLongPressStart,
                                onAvatarLongPressMoveUpdate:
                                    onLongPressMoveUpdate,
                                onAvatarLongPressEnd: onLongPressEnd,
                                onAvatarLongPressCancel: onLongPressCancel,
                                appearance: appearance,
                                pressedAvatarKey: limitEdit.activeAvatarKey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 228,
                right: 0,
                left: 0,
                height: 210,
                child: IgnorePointer(
                  ignoring: !collapseVisuals.detailsInteractive,
                  child: ExcludeFocus(
                    excluding: !collapseVisuals.detailsInteractive,
                    child: ExcludeSemantics(
                      excluding: !collapseVisuals.detailsInteractive,
                      child: Opacity(
                        opacity: collapseVisuals.detailOpacity,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            collapseVisuals.scrollContentTranslateY +
                                collapseVisuals.detailTranslateY,
                          ),
                          child: Transform.scale(
                            alignment: Alignment.topCenter,
                            scale: collapseVisuals.detailScale,
                            child:
                                SpendeeBudgetV2MotherCard.fromPreparedSnapshot(
                                  key: ValueKey(
                                    'spendee-budget-v2-mother-card-state-'
                                    '$railRuntimeEpoch',
                                  ),
                                  bar: previewBars[selected],
                                  allBars: previewBars,
                                  snapshot: preparedSnapshot,
                                  selectedVendorKey: selectedVendorKey,
                                  vendorSelectionEpoch: vendorSelectionEpoch,
                                  onLimitChanged: (amount) => onLimitChanged(
                                    previewBars[selected].key,
                                    amount,
                                  ),
                                  onAvatarRequested: onAvatarRequested,
                                  onVendorSelected: onVendorSelected,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

CategoryBudgetBarData _withLimitPreview(
  CategoryBudgetBarData bar,
  double amount,
) {
  final normalized = amount < 0 ? 0.0 : amount;
  return CategoryBudgetBarData(
    key: bar.key,
    targetType: bar.targetType,
    targetId: bar.targetId,
    transactionType: bar.transactionType,
    window: bar.window,
    periodKey: bar.periodKey,
    title: bar.title,
    spent: bar.spent,
    hasLimit: normalized > 0,
    limitAmount: normalized,
    alertActive: normalized > 0 && bar.alertActive,
    color: bar.color,
    iconSlot: bar.iconSlot,
    category: bar.category,
    sourceLimit: bar.sourceLimit,
  );
}

@immutable
class _BudgetV2DashboardLogQueryKey {
  const _BudgetV2DashboardLogQueryKey({
    required this.sourceRevision,
    required this.avatarKey,
    required this.selectedVendorKey,
  });

  final BudgetV2SnapshotRevision sourceRevision;
  final String? avatarKey;
  final String? selectedVendorKey;

  @override
  bool operator ==(Object other) =>
      other is _BudgetV2DashboardLogQueryKey &&
      other.sourceRevision == sourceRevision &&
      other.avatarKey == avatarKey &&
      other.selectedVendorKey == selectedVendorKey;

  @override
  int get hashCode => Object.hash(sourceRevision, avatarKey, selectedVendorKey);
}

@immutable
class _BudgetV2DashboardExternalScopeKey {
  _BudgetV2DashboardExternalScopeKey(BudgetV2ExternalQueryScope scope)
    : normalizedSearch = scope.searchQuery.trim().toLowerCase(),
      categoryIds = List<int>.unmodifiable(scope.categoryIds.toList()..sort()),
      merchantKeys = List<String>.unmodifiable(
        scope.merchantKeys.toList()..sort(),
      );

  final String normalizedSearch;
  final List<int> categoryIds;
  final List<String> merchantKeys;

  @override
  bool operator ==(Object other) =>
      other is _BudgetV2DashboardExternalScopeKey &&
      other.normalizedSearch == normalizedSearch &&
      listEquals(other.categoryIds, categoryIds) &&
      listEquals(other.merchantKeys, merchantKeys);

  @override
  int get hashCode => Object.hash(
    normalizedSearch,
    Object.hashAll(categoryIds),
    Object.hashAll(merchantKeys),
  );
}

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/debug/debug_console.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/category_limit.dart';
import '../../../models/budget_goal_kind.dart';
import '../../../models/transaction_category.dart';
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
import 'budget_v2_selection_controller.dart';
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
  late final SpendeeBalanceCollapseController _collapseController;
  late final AnimationController _collapseAnimationController;
  Animation<double>? _collapseAnimation;
  late final BudgetV2LimitPersistenceCoordinator _limitPersistence;
  late BudgetV2SelectionController _selection;
  late BudgetV2LimitEditController _limitEdit;
  Timer? _commitTimer;
  List<CategoryBudgetBarData> _sourceBars = const <CategoryBudgetBarData>[];
  String? _selectedAvatarKey;
  String? _requestedAvatarKey;
  var _externalSelectionEpoch = 0;
  var _railRuntimeEpoch = 0;
  var _activeGeneration = 0;
  var _timeRailExpanded = false;

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
    _sourceBars = _barsForSource(source);
    _selectedAvatarKey = _initialAvatarKey(_sourceBars);
    _selection = BudgetV2SelectionController(
      initialAvatarKey: _selectedAvatarKey ?? '',
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
      _cancelPendingCommit(reason: 'store_replaced');
      _limitPersistence.replaceStoreIdentity(widget.store);
      _limitEdit.dispose();
      _limitEdit = _createLimitEditController();
      final source = BudgetV2SnapshotSource.fromStore(widget.store);
      _snapshotCache.resolve(source);
      _sourceBars = _barsForSource(source);
      final initial = _initialAvatarKey(_sourceBars) ?? '';
      _selection.dispose();
      _selection = BudgetV2SelectionController(initialAvatarKey: initial);
      _selectedAvatarKey = initial;
      _requestedAvatarKey = null;
      _activeGeneration = 0;
      _externalSelectionEpoch += 1;
      _railRuntimeEpoch += 1;
    }
  }

  @override
  void dispose() {
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
    final bars = _barsForSource(source);
    final collapseVisuals = SpendeeBalanceCollapseVisuals.forProgress(
      _collapseController.progress,
    );
    _sourceBars = bars;
    _reconcileSelectedKey(bars);

    return FocusTraversalGroup(
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
                      selectedIndex: _selectedIndex(bars),
                      externalSelectionEpoch: _externalSelectionEpoch,
                      railRuntimeEpoch: _railRuntimeEpoch,
                      limitEdit: _limitEdit,
                      appearance: widget.avatarAppearance,
                      collapseVisuals: collapseVisuals,
                      onHeaderTap: widget.onHeaderTap,
                      onPointerDown: _beginPointerInteraction,
                      onInteractionCancelled: _cancelPointerInteraction,
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
                    child: _buildPostContent(),
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
    );
  }

  Widget _buildPostContent() {
    final store = widget.store;
    final entries = store.balanceVisibleDisplayLogEntries;
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
            queryKey: _logQueryKey(),
            hasMore: store.hasMoreBalanceVisibleDisplayLogEntries,
            onLoadMore: store.loadMoreBalanceVisibleDisplayLogEntries,
            bottomPadding: widget.logBottomPadding,
            onFastFilter: (record, _) =>
                store.setMerchantFilter(record.displayMerchant),
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

  void _beginPointerInteraction() {
    _cancelPendingCommit(reason: 'new_interaction');
    if (_selection.phase == BudgetV2SelectionPhase.physical) return;
    _activeGeneration = _selection.beginPointerDown();
  }

  void _cancelPointerInteraction() {
    _cancelPendingCommit(reason: 'gesture_cancel');
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
    _requestedAvatarKey = null;
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
    if (!mounted || !_selection.commitIfCurrent(generation)) return;
    final bar = _barForKey(avatarKey);
    if (bar == null || avatarKey == _selectedAvatarKey) return;
    setState(() {
      _selectedAvatarKey = avatarKey;
      _requestedAvatarKey = null;
    });
    final category = bar.targetType == LimitTargetType.category
        ? bar.category
        : null;
    widget.store.applyBudgetV2AvatarFilter(category: category);
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

  void _requestAvatar(CategoryBudgetBarData bar) {
    final index = _sourceBars.indexWhere(
      (candidate) => candidate.key == bar.key,
    );
    if (index < 0) return;
    _cancelPendingCommit(reason: 'remote_request');
    setState(() {
      _requestedAvatarKey = bar.key;
      _externalSelectionEpoch += 1;
    });
  }

  void _selectVendor(String merchant) {
    final value = merchant.trim();
    if (value.isEmpty) return;
    widget.store.setMerchantFilter(value);
  }

  void _beginLimitEdit(
    CategoryBudgetBarData bar,
    LongPressStartDetails details,
  ) {
    _cancelPendingCommit(reason: 'limit_edit');
    _limitEdit.begin(
      avatarKey: bar.key,
      initialAmount: bar.limitAmount,
      globalY: details.globalPosition.dy,
    );
    DebugConsole.log(
      '[BudgetV2Limit] phase=start key=${bar.key} '
      'amount=${bar.limitAmount.round()}',
    );
  }

  void _updateLimitEdit(LongPressMoveUpdateDetails details) {
    final key = _limitEdit.activeAvatarKey;
    final bar = key == null ? null : _barForKey(key);
    final before = key == null
        ? null
        : _limitEdit.previewAmount(key, fallback: bar?.limitAmount ?? 0);
    _limitEdit.update(globalY: details.globalPosition.dy);
    final after = key == null
        ? null
        : _limitEdit.previewAmount(key, fallback: bar?.limitAmount ?? 0);
    DebugConsole.log('[BudgetV2Limit] phase=move key=${key ?? 'none'}');
    if (key != null && before != after) {
      DebugConsole.log(
        '[Perf] SpendeeTest budget_limit_tick key=$key '
        'amount=${after?.round() ?? 0} source=drag '
        'persistence=release_only',
      );
    }
    DebugConsole.log(
      '[BudgetV2Limit] phase=tick key=${key ?? 'none'} '
      'persistence=release_only',
    );
  }

  void _finishLimitEdit(LongPressEndDetails _) {
    final key = _limitEdit.activeAvatarKey;
    DebugConsole.log('[BudgetV2Limit] phase=end key=${key ?? 'none'}');
    _limitEdit.finish();
    DebugConsole.log('[BudgetV2Limit] phase=release key=${key ?? 'none'}');
  }

  void _cancelLimitEdit() {
    final key = _limitEdit.activeAvatarKey;
    _limitEdit.cancel();
    if (key != null) {
      DebugConsole.log('[BudgetV2Limit] phase=cancel key=$key');
    }
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
    final key = _requestedAvatarKey ?? _selectedAvatarKey;
    final index = bars.indexWhere((bar) => bar.key == key);
    return index < 0 ? 0 : index;
  }

  void _reconcileSelectedKey(List<CategoryBudgetBarData> bars) {
    if (bars.isEmpty) {
      _selectedAvatarKey = null;
      return;
    }
    if (bars.any((bar) => bar.key == _selectedAvatarKey)) return;
    _selectedAvatarKey = _initialAvatarKey(bars);
  }

  String _logQueryKey() {
    final store = widget.store;
    final categories = store.activeCategoryIds.toList()..sort();
    final merchants = store.activeMerchantFilters.toList()..sort();
    return <String>[
      store.activeType.name,
      store.summaryWindow.name,
      store.summaryReferenceDate.toIso8601String(),
      store.searchQuery,
      categories.join(','),
      merchants.join('|'),
    ].join('::');
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
    required this.selectedIndex,
    required this.externalSelectionEpoch,
    required this.railRuntimeEpoch,
    required this.limitEdit,
    required this.appearance,
    required this.collapseVisuals,
    required this.onHeaderTap,
    required this.onPointerDown,
    required this.onInteractionCancelled,
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
  final int selectedIndex;
  final int externalSelectionEpoch;
  final int railRuntimeEpoch;
  final BudgetV2LimitEditController limitEdit;
  final BudgetV2AvatarAppearance appearance;
  final SpendeeBalanceCollapseVisuals collapseVisuals;
  final VoidCallback? onHeaderTap;
  final VoidCallback onPointerDown;
  final VoidCallback onInteractionCancelled;
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
                                onPointerDown: onPointerDown,
                                onInteractionStarted: onPointerDown,
                                onInteractionCancelled: onInteractionCancelled,
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

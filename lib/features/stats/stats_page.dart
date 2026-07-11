import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
import '../transactions/models/summary_window.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/widgets/calendar_menu/calendar_joystick_range.dart';
import '../transactions/widgets/category_menu/category_menu_panel.dart';
import '../transactions/widgets/header_card/header_fast_info_surface.dart';
import '../transactions/widgets/header_card/magnet_strip.dart';
import '../transactions/widgets/header_card/transaction_header_card.dart';
import '../transactions/widgets/header_card/transaction_header_metrics.dart';
import '../transactions/widgets/slide_up_menu_card.dart';
import '../transactions/widgets/search_pill.dart';
import '../transactions/widgets/summary_pill.dart';
import '../transactions/widgets/summary_scope_picker_sheet.dart';
import '../transactions/widgets/transaction_menu_metrics.dart';
import '../transactions/widgets/transaction_type_pills.dart';
import 'data/stats_page2_metrics.dart';
import 'data/stats_render_frame.dart';
import 'data/stats_snapshot.dart';
import 'data/stats_year_data.dart';
import 'widgets/stats_fast_info_graph.dart';
import 'widgets/stats_year_calendar.dart';

class StatsPageController {
  VoidCallback? _openThresholdSheet;
  ValueChanged<int>? _stepSnapshot;
  ValueChanged<int>? _stepThreshold;

  void openThresholdSheet() {
    _openThresholdSheet?.call();
  }

  void stepSnapshot(int direction) {
    _stepSnapshot?.call(direction);
  }

  void stepThreshold(int multiplier) {
    _stepThreshold?.call(multiplier);
  }

  void _attach({
    required VoidCallback openThresholdSheet,
    required ValueChanged<int> stepSnapshot,
    required ValueChanged<int> stepThreshold,
  }) {
    _openThresholdSheet = openThresholdSheet;
    _stepSnapshot = stepSnapshot;
    _stepThreshold = stepThreshold;
  }

  void _detach(VoidCallback openThresholdSheet) {
    if (_openThresholdSheet == openThresholdSheet) {
      _openThresholdSheet = null;
      _stepSnapshot = null;
      _stepThreshold = null;
    }
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.store,
    this.controller,
    this.expenseTheme,
    this.onCategoryMenuRequested,
    this.onVendorSheetRequested,
    this.onAddCategoryEditorRequested,
    this.onEditCategoryEditorRequested,
    this.snapshotRepository,
    this.renderFrameCache,
  });

  final TransactionStore store;
  final StatsPageController? controller;
  final ExpenseTheme? expenseTheme;
  final CategoryMenuSheetRequested? onCategoryMenuRequested;
  final ValueChanged<TransactionType>? onVendorSheetRequested;
  final VoidCallback? onAddCategoryEditorRequested;
  final ValueChanged<TransactionCategory>? onEditCategoryEditorRequested;
  final StatsSnapshotRepository? snapshotRepository;
  final StatsRenderFrameCache? renderFrameCache;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<StatsPage> {
  var _year = 0;
  var _month = 1;
  var _yearScopeEnabled = true;
  var _monthScopeEnabled = false;
  var _activeType = TransactionType.expense;
  var _thresholdValue = 5000.0;
  int? _focusedMonth;
  var _scopeSheetOpen = false;
  late final ValueNotifier<double> _fastInfoExtent;
  late final AnimationController _headerPullController;
  var _contentPageIndex = 0;
  var _searchQuery = '';
  final _selectedScopeByType = <TransactionType, Set<int>>{
    TransactionType.income: <int>{},
    TransactionType.expense: <int>{},
  };
  late StatsRenderFrameCache _renderFrameCache;
  StatsRenderFrame? _lastRenderFrame;
  late StatsSnapshotRepository _snapshotRepository;
  List<StatsSnapshot> _snapshots = const <StatsSnapshot>[];
  var _selectedSnapshotIndex = -1;
  final _snapshotRecallGeneration = StatsSnapshotRecallGeneration();

  @override
  void initState() {
    super.initState();
    _syncSummaryFromStore();
    widget.store.addListener(_handleStoreChanged);
    _snapshotRepository =
        widget.snapshotRepository ?? InMemoryStatsSnapshotRepository();
    _renderFrameCache = widget.renderFrameCache ?? StatsRenderFrameCache();
    unawaited(_loadSnapshots());
    _fastInfoExtent = ValueNotifier<double>(0);
    _headerPullController = AnimationController.unbounded(vsync: this)
      ..addListener(_syncHeaderPullFromController);
    widget.controller?._attach(
      openThresholdSheet: _openThresholdControlSheet,
      stepSnapshot: _stepSnapshot,
      stepThreshold: _stepThreshold,
    );
  }

  @override
  void didUpdateWidget(covariant StatsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshotRepository != widget.snapshotRepository &&
        widget.snapshotRepository != null) {
      _snapshotRepository = widget.snapshotRepository!;
      unawaited(_loadSnapshots());
    }
    if (oldWidget.renderFrameCache != widget.renderFrameCache) {
      _renderFrameCache = widget.renderFrameCache ?? StatsRenderFrameCache();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_openThresholdControlSheet);
      widget.controller?._attach(
        openThresholdSheet: _openThresholdControlSheet,
        stepSnapshot: _stepSnapshot,
        stepThreshold: _stepThreshold,
      );
    }
  }

  @override
  void dispose() {
    _fastInfoExtent.dispose();
    _headerPullController.dispose();
    widget.store.removeListener(_handleStoreChanged);
    widget.controller?._detach(_openThresholdControlSheet);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _handleStoreChanged() {
    var changed = _syncSummaryFromStore();
    if (!widget.store.loading && widget.store.error == null) {
      final nextThreshold = _clampThresholdToCurrentScope(_thresholdValue);
      if (nextThreshold != _thresholdValue) {
        _thresholdValue = nextThreshold;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  bool _syncSummaryFromStore() {
    final reference = widget.store.summaryReferenceDate;
    final nextYear = reference.year;
    final nextMonth = reference.month.clamp(1, 12).toInt();
    final nextYearEnabled = widget.store.summaryWindow != SummaryWindow.allTime;
    final nextMonthEnabled =
        widget.store.summaryWindow == SummaryWindow.monthly;
    final changed =
        _year != nextYear ||
        _month != nextMonth ||
        _yearScopeEnabled != nextYearEnabled ||
        _monthScopeEnabled != nextMonthEnabled;
    _year = nextYear;
    _month = nextMonth;
    _yearScopeEnabled = nextYearEnabled;
    _monthScopeEnabled = nextMonthEnabled;
    _focusedMonth = nextMonthEnabled ? nextMonth : null;
    return changed;
  }

  Future<void> _loadSnapshots() async {
    final snapshots = await _snapshotRepository.load();
    if (!mounted) return;
    setState(() => _snapshots = snapshots);
  }

  StatsSnapshotState _currentSnapshotState() {
    return StatsSnapshotState(
      categoryScopeIds: _selectedScopeByType[_activeType] ?? const <int>{},
      vendorScopeNames: widget.store.activeMerchantFilters,
      activeType: _activeType,
      threshold: _thresholdValue,
      layoutMode: _layoutMode,
      activeYear: _year,
      activeMonth: _month,
      pageIndex: _contentPageIndex,
    );
  }

  StatsLayoutMode get _layoutMode {
    if (!_yearScopeEnabled) return StatsLayoutMode.sum;
    if (_monthScopeEnabled) return StatsLayoutMode.month;
    return StatsLayoutMode.year;
  }

  Future<List<StatsSnapshot>> _saveSnapshot(
    _StatsSnapshotDraft draft,
    StatsSnapshot? existing,
  ) async {
    final now = DateTime.now();
    final state = _currentSnapshotState();
    final snapshot = StatsSnapshot(
      id: existing?.id ?? 'stats-${now.microsecondsSinceEpoch}',
      name: draft.name.trim().isEmpty ? 'Mentett nézet' : draft.name.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      includeCategoryScope: draft.includeCategoryScope,
      includeVendorScope: draft.includeVendorScope,
      includeActiveType: draft.includeActiveType,
      includeThreshold: draft.includeThreshold,
      includeLayoutMode: draft.includeLayoutMode,
      includePageIndex: draft.includePageIndex,
      categoryScopeIds: draft.includeCategoryScope
          ? state.categoryScopeIds
          : const <int>{},
      vendorScopeNames: draft.includeVendorScope
          ? state.vendorScopeNames
          : const <String>{},
      activeType: draft.includeActiveType ? state.activeType : null,
      threshold: draft.includeThreshold ? state.threshold : null,
      layoutMode: draft.includeLayoutMode ? state.layoutMode : null,
      activeYear: draft.includeLayoutMode ? state.activeYear : null,
      activeMonth: draft.includeLayoutMode ? state.activeMonth : null,
      pageIndex: draft.includePageIndex ? state.pageIndex : null,
    );
    await _snapshotRepository.upsert(snapshot);
    await _loadSnapshots();
    return _snapshotRepository.load();
  }

  Future<_StatsSnapshotRecallResult> _applySnapshot(
    StatsSnapshot snapshot,
  ) async {
    final recall = _snapshotRecallGeneration.begin();
    final applied = snapshot.applyTo(_currentSnapshotState());
    final mutation = await widget.store.prepareStatsViewMutation(
      merchantFilters: snapshot.includeVendorScope
          ? applied.vendorScopeNames
          : null,
      summaryWindow: snapshot.includeLayoutMode
          ? switch (applied.layoutMode) {
              StatsLayoutMode.sum => SummaryWindow.allTime,
              StatsLayoutMode.year => SummaryWindow.yearly,
              StatsLayoutMode.month => SummaryWindow.monthly,
            }
          : null,
      year: snapshot.includeLayoutMode ? applied.activeYear : null,
      month: snapshot.includeLayoutMode ? applied.activeMonth : null,
    );
    if (!mounted || !recall.isLatest) {
      return _ignoredSnapshotRecallResult();
    }
    final targetVendors =
        mutation.merchantFilters ?? widget.store.activeMerchantFilters;
    final targetCategoryIds = snapshot.includeCategoryScope
        ? applied.categoryScopeIds
        : _selectedScopeByType[applied.activeType] ?? const <int>{};
    final targetObservedMaximum = StatsYearData.observedMaximumFor(
      year: applied.activeYear,
      activeType: applied.activeType,
      transactions: widget.store.transactions,
      categories: widget.store.categories,
      selectedCategoryIds: targetCategoryIds,
      vendorFilters: targetVendors,
      summaryScope: switch (applied.layoutMode) {
        StatsLayoutMode.sum => StatsSummaryScope.allTime,
        StatsLayoutMode.year => StatsSummaryScope.yearly,
        StatsLayoutMode.month => StatsSummaryScope.monthly,
      },
      month: applied.activeMonth,
      query: _searchQuery,
    );
    final clampedThreshold = _statsThresholdRange(
      observedMax: targetObservedMaximum,
      fallbackMax: 50000,
    ).snap(applied.threshold);
    final finalFrame = _resolveRenderFrameFor(
      activeType: applied.activeType,
      threshold: clampedThreshold,
      layoutMode: applied.layoutMode,
      year: applied.activeYear,
      month: applied.activeMonth,
      categoryIds: targetCategoryIds,
      vendorNames: targetVendors,
    );
    _activeType = applied.activeType;
    _thresholdValue = clampedThreshold;
    if (snapshot.includeCategoryScope) {
      _selectedScopeByType[applied.activeType] = applied.categoryScopeIds;
    }
    if (snapshot.includeLayoutMode) {
      _applySnapshotLayoutLocally(applied);
    }
    _selectedSnapshotIndex = _snapshots.indexWhere(
      (item) => item.id == snapshot.id,
    );
    widget.store.commitStatsViewMutation(mutation);
    return _StatsSnapshotRecallResult(
      threshold: clampedThreshold,
      observedMax: finalFrame.observedMaximum,
      applied: true,
    );
  }

  void _applySnapshotLayoutLocally(StatsSnapshotState applied) {
    _year = applied.activeYear;
    _month = applied.activeMonth.clamp(1, 12).toInt();
    _yearScopeEnabled = applied.layoutMode != StatsLayoutMode.sum;
    _monthScopeEnabled = applied.layoutMode == StatsLayoutMode.month;
    _focusedMonth = _monthScopeEnabled ? _month : null;
  }

  _StatsSnapshotRecallResult _ignoredSnapshotRecallResult() {
    return _StatsSnapshotRecallResult(
      threshold: _thresholdValue,
      observedMax: _lastRenderFrame?.observedMaximum ?? 0,
      applied: false,
    );
  }

  void _stepSnapshot(int direction) {
    if (_snapshots.isEmpty || direction == 0) return;
    final nextIndex =
        (_selectedSnapshotIndex + (direction > 0 ? 1 : -1)) % _snapshots.length;
    final wrappedIndex = nextIndex < 0
        ? nextIndex + _snapshots.length
        : nextIndex;
    unawaited(_applySnapshot(_snapshots[wrappedIndex]).then<void>((_) {}));
  }

  void _handleContentHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;
    _stepSnapshot(velocity < 0 ? 1 : -1);
  }

  void _toggleContentPage() {
    setState(() => _contentPageIndex = _contentPageIndex == 0 ? 1 : 0);
  }

  void _stepThreshold(int multiplier) {
    if (multiplier == 0) return;
    final range = _statsThresholdRange(
      observedMax: _resolveRenderFrame().observedMaximum,
      fallbackMax: 50000,
    );
    final next = range.snap(_thresholdValue + multiplier * range.step);
    if (next == _thresholdValue) return;
    setState(() => _thresholdValue = next);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final resolvedTheme =
        widget.expenseTheme ??
        ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    return ColoredBox(
      key: const ValueKey('stats-page'),
      color: resolvedTheme.appBackground,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.bottomNavHeight),
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            if (widget.store.loading) {
              return Center(
                child: CircularProgressIndicator(color: resolvedTheme.accent),
              );
            }
            if (widget.store.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    widget.store.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ),
              );
            }
            final frame = _resolveRenderFrame();
            final data = frame.yearData;
            final focusedMonth = _focusedMonth == null
                ? null
                : data.months[(_focusedMonth! - 1).clamp(
                    0,
                    data.months.length - 1,
                  )];
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    const SizedBox(height: TransactionHeaderMetrics.contentTop),
                    TransactionTypePills(
                      activeType: _activeType,
                      surfaceColor: resolvedTheme.logBox,
                      surfaceStyle: resolvedTheme.buttonSurfaceStyle,
                      accentColor: resolvedTheme.accent,
                      shadowEnabled: true,
                      onChanged: _setActiveType,
                    ),
                    SummaryPill(
                      title: widget.store.activePeriodLabel,
                      value: data.summaryValue,
                      surfaceColor: resolvedTheme.logBox,
                      surfaceStyle: resolvedTheme.summaryPillSurfaceStyle,
                      shadowEnabled: true,
                      onTap: _openSummaryScopePicker,
                      onIntervalSwipe: _cycleSummaryScope,
                      onPeriodSwipe: _shiftSummaryScope,
                      onResetToCurrentMonth: _resetSummaryScope,
                    ),
                    SearchPill(
                      query: _searchQuery,
                      onQueryChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _thresholdValue = _clampThresholdToCurrentScope(
                            _thresholdValue,
                          );
                        });
                      },
                      surfaceColor: resolvedTheme.logBox,
                      surfaceStyle: resolvedTheme.summaryPillSurfaceStyle,
                      merchantFilters: _merchantSearchFilters(
                        resolvedTheme.accent,
                      ),
                      categoryFilters: _categorySearchFilters(),
                      onVendorListPressed: widget.onVendorSheetRequested == null
                          ? null
                          : () => widget.onVendorSheetRequested!(_activeType),
                      accentColor: resolvedTheme.accent,
                    ),
                    _StatsPageHeader(
                      transactionCount: frame.filteredTransactionCount,
                      activeIndex: _contentPageIndex,
                    ),
                    Expanded(
                      child: _StatsPageSwitcher(
                        key: const ValueKey('stats-content-switcher'),
                        activeIndex: _contentPageIndex,
                        onTogglePage: _toggleContentPage,
                        onHorizontalDragEnd: _handleContentHorizontalDragEnd,
                        pageOne: RepaintBoundary(
                          key: const ValueKey('stats-page-1-boundary'),
                          child: KeyedSubtree(
                            key: const ValueKey('stats-page-1'),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: _pageOneContent(
                                frame: frame,
                                focusedMonth: focusedMonth,
                                monthCardColor: resolvedTheme.statsMonthCard,
                              ),
                            ),
                          ),
                        ),
                        pageTwo: RepaintBoundary(
                          key: const ValueKey('stats-page-2-boundary'),
                          child: _StatsPageTwoSummary(
                            key: const ValueKey('stats-page-2'),
                            data: data,
                            categories: widget.store.categories,
                            activeType: _activeType,
                            thresholdValue: _thresholdValue,
                            metrics: frame.page2Metrics,
                            largestVendor: frame.largestVisibleVendor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                HeaderFastInfoSurface.listenable(
                  key: const ValueKey('stats-fastinfo-extent-builder'),
                  visibleFastInfoExtentListenable: _fastInfoExtent,
                  cardColor: resolvedTheme.headerCard,
                  surfaceStyle: resolvedTheme.contentSurfaceStyle,
                  fastInfo: StatsFastInfoGraph(
                    data: data,
                    series: frame.categoryScopeSeries,
                  ),
                  header: _buildHeaderCard(
                    frame: frame,
                    expenseTheme: resolvedTheme,
                    drawSurface: false,
                  ),
                ),
                if (_scopeSheetOpen)
                  Positioned.fill(
                    child: SlideUpMenuCard(
                      cardKey: const ValueKey('stats-scope-slide-card'),
                      debugLabel: 'StatsCategoryScope',
                      panelHeight: _scopePanelHeight(context),
                      onDismissed: _closeScopeSheet,
                      dismissOnVeilTap: false,
                      focusVeilPassthroughTop:
                          TransactionMenuMetrics.summaryPillTop,
                      dragFromHandleOnly: true,
                      dragHandleExtent: 72,
                      verticalDragBias: 1.2,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: CategoryMenuPanel(
                          key: const ValueKey('stats-scope-sheet'),
                          activeType: _activeType,
                          categories: widget.store.categories,
                          categoryTransactionCounts:
                              widget.store.categoryTransactionCounts,
                          activeCategory: null,
                          selectedCategoryIds:
                              _selectedScopeByType[_activeType] ??
                              const <int>{},
                          onSelect: (_) {},
                          onApply: _applyScopeSelection,
                          onModify: _openModifyCategory,
                          onDelete: widget.store.deleteCategory,
                          onAdd: _openAddCategory,
                          onClose: _closeScopeSheet,
                          surfaceColor: resolvedTheme.categoryMenu,
                          cardSurfaceColor: resolvedTheme.categoryCard,
                          cardSurfaceStyle:
                              resolvedTheme.categoryCardSurfaceStyle,
                          avatarSurfaceStyle: resolvedTheme.buttonSurfaceStyle,
                          accentColor: resolvedTheme.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  StatsRenderFrame _resolveRenderFrame() {
    return _resolveRenderFrameFor(
      activeType: _activeType,
      threshold: _thresholdValue,
      layoutMode: _layoutMode,
      year: _year,
      month: _month,
      categoryIds: _selectedScopeByType[_activeType] ?? const <int>{},
      vendorNames: widget.store.activeMerchantFilters,
    );
  }

  StatsRenderFrame _resolveRenderFrameFor({
    required TransactionType activeType,
    required double threshold,
    required StatsLayoutMode layoutMode,
    required int year,
    required int month,
    required Set<int> categoryIds,
    required Set<String> vendorNames,
  }) {
    final summaryScope = switch (layoutMode) {
      StatsLayoutMode.sum => StatsSummaryScope.allTime,
      StatsLayoutMode.year => StatsSummaryScope.yearly,
      StatsLayoutMode.month => StatsSummaryScope.monthly,
    };
    final key = StatsRenderFrameKey(
      dataRevision: (
        transactions: widget.store.transactions,
        categories: widget.store.categories,
      ),
      activeType: activeType,
      summaryScope: summaryScope,
      year: year,
      month: month,
      categoryIds: categoryIds,
      vendorNames: vendorNames,
      query: _searchQuery,
      threshold: threshold,
    );
    final frame = _renderFrameCache.resolve(key, () {
      return StatsRenderFrame.build(
        year: year,
        activeType: activeType,
        thresholdValue: threshold,
        transactions: widget.store.transactions,
        categories: widget.store.categories,
        selectedCategoryIds: categoryIds,
        vendorFilters: vendorNames,
        summaryScope: summaryScope,
        month: month,
        query: _searchQuery,
        today: widget.store.currentDate,
      );
    });
    _lastRenderFrame = frame;
    return frame;
  }

  Widget _buildHeaderCard({
    required StatsRenderFrame frame,
    required ExpenseTheme expenseTheme,
    bool drawSurface = true,
  }) {
    final data = frame.yearData;
    final categorySeries = frame.categoryScopeSeries;
    final visual = _headerVisual(frame);
    final headerLabel = 'SZŰRÉS PONTSZÁM';
    final headerValue = '${categorySeries.kontrollScore.round()}/100';
    return RepaintBoundary(
      child: TransactionHeaderCard(
        labelText: headerLabel,
        balanceText: headerValue,
        showBalanceVisibilityButton: false,
        magnetType: MagnetType.fade,
        backheaderStyle: expenseTheme.settings.backheaderStyle,
        accent: expenseTheme.accent,
        cardColor: expenseTheme.headerCard,
        surfaceStyle: expenseTheme.contentSurfaceStyle,
        buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
        totalIncome: data.canonicalIncomeTotal,
        totalExpense: data.canonicalExpenseTotal,
        leadingChipText: _scopeChipText(data),
        leadingChipColor: const Color(0xFFFBBF24),
        magnetGradientColors: visual.gradientColors,
        magnetMarkerPosition: visual.markerPosition,
        magnetMarkerStyle: MagnetMarkerStyle.line,
        magnetKey: 'stats-magnet-${data.mode.name}',
        drawSurface: drawSurface,
        onCategoryPressed: _openScopeSheet,
        onExpandPressed: () {},
        onVerticalDragUpdate: _handleHeaderDragUpdate,
        onVerticalDragEnd: _handleHeaderDragEnd,
      ),
    );
  }

  double _clampThresholdToCurrentScope(double value) {
    final observedMax = _resolveRenderFrame().observedMaximum;
    return _statsThresholdRange(
      observedMax: observedMax,
      fallbackMax: 50000,
    ).snap(value);
  }

  String _scopeChipText(StatsYearData data) {
    final selectedCount = data.selectedCategoryIds.length;
    return selectedCount == 0 ? 'MIND' : selectedCount.toString();
  }

  _StatsHeaderVisual _headerVisual(StatsRenderFrame frame) {
    final score = frame.categoryScopeSeries.kontrollScore;
    return _StatsHeaderVisual(
      gradientColors: const [
        Color(0xFFEF4444),
        Color(0xFFFBBF24),
        Color(0xFF22C55E),
      ],
      markerPosition: score / 100,
    );
  }

  void _setActiveType(TransactionType type) {
    if (_activeType == type) return;
    setState(() {
      _activeType = type;
      _thresholdValue = _clampThresholdToCurrentScope(_thresholdValue);
    });
  }

  Widget _pageOneContent({
    required StatsRenderFrame frame,
    required StatsMonthData? focusedMonth,
    required Color monthCardColor,
  }) {
    final data = frame.yearData;
    if (!_yearScopeEnabled) {
      return _StatsSumYearCards(
        summaries: frame.sumYearSummaries,
        categories: widget.store.categories,
        activeType: _activeType,
        activeYear: _year,
        selectedCategoryIds: _selectedScopeByType[_activeType] ?? const <int>{},
        onYearSelected: (year) {
          unawaited(_setSummaryYear(year));
        },
      );
    }
    if (focusedMonth == null) {
      return StatsYearCalendar(
        data: data,
        monthCardColor: monthCardColor,
        heatColor: _selectedHeatColor(),
        onMonthSelected: _selectMonth,
      );
    }
    return _StatsFocusedMonthView(
      data: data,
      month: focusedMonth,
      cardColor: monthCardColor,
      heatColor: _selectedHeatColor(),
    );
  }

  Future<void> _openSummaryScopePicker() async {
    final selection = await showModalBottomSheet<SummaryScopeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SummaryScopePickerSheet(
          initialSelection: SummaryScopeSelection(
            yearEnabled: _yearScopeEnabled,
            monthEnabled: _monthScopeEnabled,
            year: _year,
            month: _month,
          ),
          accentColor: _expenseTheme.accent,
          buttonSurfaceStyle: _expenseTheme.buttonSurfaceStyle,
          onApply: (selection) => Navigator.of(context).pop(selection),
        );
      },
    );
    if (!mounted || selection == null) return;
    if (!selection.yearEnabled) {
      await widget.store.setSummaryAllTime();
      return;
    }
    if (!selection.monthEnabled) {
      await widget.store.setSummaryYear(selection.year);
      return;
    }
    await widget.store.setSummaryMonth(selection.year, selection.month);
  }

  void _cycleSummaryScope() {
    unawaited(widget.store.cycleSummaryWindow());
  }

  void _shiftSummaryScope(int direction) {
    unawaited(widget.store.shiftSummaryPeriod(direction));
  }

  void _resetSummaryScope() {
    unawaited(widget.store.resetSummaryToCurrentMonth());
  }

  void _selectMonth(StatsMonthData month) {
    unawaited(_setSummaryMonth(month.year, month.month));
  }

  Future<void> _setSummaryYear(int year) async {
    setState(() {
      _yearScopeEnabled = true;
      _monthScopeEnabled = false;
      _focusedMonth = null;
      _year = year;
    });
    await widget.store.setSummaryYear(year);
  }

  Future<void> _setSummaryMonth(int year, int month) async {
    final boundedMonth = month.clamp(1, 12).toInt();
    setState(() {
      _yearScopeEnabled = true;
      _monthScopeEnabled = true;
      _year = year;
      _month = boundedMonth;
      _focusedMonth = boundedMonth;
    });
    await widget.store.setSummaryMonth(year, boundedMonth);
  }

  void _openScopeSheet() {
    final externalPicker = widget.onCategoryMenuRequested;
    if (externalPicker != null) {
      setState(() => _scopeSheetOpen = false);
      externalPicker(
        CategoryMenuSheetRequest(
          cardKey: const ValueKey('stats-scope-slide-card'),
          panelKey: const ValueKey('stats-scope-sheet'),
          debugLabel: 'StatsCategoryScope',
          topOffset: TransactionMenuMetrics.summaryPillTop,
          activeType: _activeType,
          activeCategory: null,
          selectedCategoryIds:
              _selectedScopeByType[_activeType] ?? const <int>{},
          onSelect: (_) {},
          onApply: _applyScopeSelection,
          onModify: _openModifyCategory,
          onDelete: widget.store.deleteCategory,
          onAdd: _openAddCategory,
          onClosed: _closeScopeSheet,
        ),
      );
      return;
    }
    setState(() => _scopeSheetOpen = true);
  }

  void _closeScopeSheet() {
    if (!_scopeSheetOpen) return;
    setState(() => _scopeSheetOpen = false);
  }

  void _applyScopeSelection(Set<int> ids) {
    setState(() {
      _selectedScopeByType[_activeType] = ids;
      _thresholdValue = _clampThresholdToCurrentScope(_thresholdValue);
      _scopeSheetOpen = false;
    });
  }

  List<SearchPillFilter> _merchantSearchFilters(Color accentColor) {
    final filters = widget.store.activeMerchantFilters.toList()..sort();
    return [
      for (final vendor in filters)
        SearchPillFilter(
          id: vendor,
          label: vendor,
          color: accentColor,
          onClear: () {
            final next = {...widget.store.activeMerchantFilters}
              ..remove(vendor);
            widget.store.setMerchantFilters(next);
          },
        ),
    ];
  }

  List<SearchPillFilter> _categorySearchFilters() {
    final selected = _selectedScopeByType[_activeType] ?? const <int>{};
    if (selected.isEmpty) return const <SearchPillFilter>[];
    final categories =
        widget.store.categories
            .where(
              (category) =>
                  category.normalizedType == _activeType &&
                  selected.contains(category.transactionCategoryID),
            )
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return [
      for (final category in categories)
        SearchPillFilter(
          id: category.transactionCategoryID.toString(),
          label: category.name,
          color: category.slotColor,
          onClear: () {
            setState(() {
              _selectedScopeByType[_activeType] = {...selected}
                ..remove(category.transactionCategoryID);
              _thresholdValue = _clampThresholdToCurrentScope(_thresholdValue);
            });
          },
        ),
    ];
  }

  Color _selectedHeatColor() {
    final selected = _selectedScopeByType[_activeType] ?? const <int>{};
    if (selected.length != 1) return AppColors.primary;
    final selectedId = selected.single;
    for (final category in widget.store.categories) {
      if (category.normalizedType == _activeType &&
          category.transactionCategoryID == selectedId) {
        return category.slotColor;
      }
    }
    return AppColors.primary;
  }

  void _openAddCategory() {
    widget.onAddCategoryEditorRequested?.call();
  }

  void _openModifyCategory(TransactionCategory category) {
    widget.onEditCategoryEditorRequested?.call(category);
  }

  double _scopePanelHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight - TransactionMenuMetrics.summaryPillTop)
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  Future<void> _openThresholdControlSheet() async {
    final observedMax = _lastRenderFrame?.observedMaximum ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StatsThresholdControlSheet(
          thresholdValue: _thresholdValue,
          observedMax: observedMax,
          fallbackMax: 50000,
          accentColor: _expenseTheme.accent,
          snapshots: _snapshots,
          selectedSnapshotIndex: _selectedSnapshotIndex,
          categoryNamesById: {
            for (final category in widget.store.categories)
              category.transactionCategoryID: category.name,
          },
          onAddSnapshot: _saveSnapshot,
          onSnapshotSelected: _applySnapshot,
          onThresholdChanged: (value) {
            setState(() => _thresholdValue = value);
          },
        );
      },
    );
  }

  ExpenseTheme get _expenseTheme =>
      widget.expenseTheme ??
      ExpenseTheme.fromSettings(AppThemeSettings.defaults());

  void _syncHeaderPullFromController() {
    final rawNext = _headerPullController.value
        .clamp(-12.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    final next = rawNext.abs() < 0.5 ? 0.0 : rawNext;
    if ((next - _fastInfoExtent.value).abs() < 0.01) return;
    _fastInfoExtent.value = next;
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    _headerPullController.stop();
    final resistedDelta = details.delta.dy > 0
        ? details.delta.dy * 0.85
        : details.delta.dy;
    final current = _fastInfoExtent.value;
    final next = (current + resistedDelta)
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    if (next == current) return;
    _headerPullController.value = next;
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    final start = _fastInfoExtent.value
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    if (start == 0) {
      _headerPullController.value = 0;
      return;
    }
    _headerPullController.value = start;
    final releaseVelocity = details.velocity.pixelsPerSecond.dy;
    final closingVelocity = releaseVelocity < 0 ? releaseVelocity : 0.0;
    final spring = _headerPullController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 0.75, stiffness: 620, damping: 16),
        start,
        0,
        closingVelocity,
      ),
    );
    unawaited(
      spring.orCancel
          .then<void>((_) {
            if (!mounted) return;
            _headerPullController.value = 0;
            if (_fastInfoExtent.value == 0) return;
            _fastInfoExtent.value = 0;
          })
          .catchError((_) {}),
    );
  }
}

class _StatsHeaderVisual {
  const _StatsHeaderVisual({
    required this.gradientColors,
    required this.markerPosition,
  });

  final List<Color> gradientColors;
  final double markerPosition;
}

class _StatsPageHeader extends StatelessWidget {
  const _StatsPageHeader({
    required this.transactionCount,
    required this.activeIndex,
  });

  final int transactionCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stats-page-header'),
      height: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              heightFactor: 1,
              child: Text(
                '$transactionCount tranzakció',
                key: const ValueKey('stats-page-header-count'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _StatsPageIndicator(
                key: const ValueKey('stats-page-indicator'),
                activeIndex: activeIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPageSwitcher extends StatelessWidget {
  const _StatsPageSwitcher({
    super.key,
    required this.activeIndex,
    required this.pageOne,
    required this.pageTwo,
    required this.onTogglePage,
    required this.onHorizontalDragEnd,
  });

  static const _transitionDuration = Duration(milliseconds: 220);

  final int activeIndex;
  final Widget pageOne;
  final Widget pageTwo;
  final VoidCallback onTogglePage;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final activePage = activeIndex == 0 ? pageOne : pageTwo;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          key: const ValueKey('stats-content-gesture-surface'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: _transitionDuration,
              reverseDuration: _transitionDuration,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [...previousChildren, ?currentChild],
                );
              },
              transitionBuilder: (child, animation) {
                final childIndex =
                    child.key == const ValueKey('stats-page-2-boundary')
                    ? 1
                    : 0;
                final incoming = childIndex == activeIndex;
                final begin = switch ((activeIndex, incoming)) {
                  (1, true) => const Offset(1, 0),
                  (1, false) => const Offset(-1, 0),
                  (0, true) => const Offset(-1, 0),
                  (0, false) => const Offset(1, 0),
                  _ => Offset.zero,
                };
                return SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                );
              },
              child: activePage,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            key: const ValueKey('stats-page-chevron'),
            behavior: HitTestBehavior.opaque,
            onTap: onTogglePage,
            child: Container(
              width: 32,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xEFFFFFFF),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    offset: Offset(-1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                activeIndex == 0
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.gray700,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsPageIndicator extends StatelessWidget {
  const _StatsPageIndicator({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 2; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          AnimatedContainer(
            key: ValueKey('stats-page-indicator-dot-$index'),
            duration: const Duration(milliseconds: 180),
            width: activeIndex == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: activeIndex == index
                  ? AppColors.primary
                  : AppColors.gray300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsSumYearCards extends StatelessWidget {
  const _StatsSumYearCards({
    required this.summaries,
    required this.categories,
    required this.activeType,
    required this.activeYear,
    required this.selectedCategoryIds,
    required this.onYearSelected,
  });

  final List<StatsSumYearSummary> summaries;
  final List<TransactionCategory> categories;
  final TransactionType activeType;
  final int activeYear;
  final Set<int> selectedCategoryIds;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('stats-sum-year-cards'),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: summaries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.88,
        mainAxisSpacing: 15,
        mainAxisExtent: 154,
      ),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return GestureDetector(
          key: ValueKey('stats-year-card-${summary.year}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onYearSelected(summary.year),
          child: Container(
            key: ValueKey('stats-year-card-surface-${summary.year}'),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: summary.year == activeYear
                    ? AppColors.primary
                    : AppColors.gray200,
              ),
              boxShadow: [
                BoxShadow(
                  color: summary.year == activeYear
                      ? AppColors.primary.withValues(alpha: 0.24)
                      : Colors.black.withValues(alpha: 0.10),
                  offset: Offset(0, summary.year == activeYear ? 2 : 1),
                  blurRadius: summary.year == activeYear ? 8 : 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                children: [
                  SizedBox(
                    height: 26,
                    child: Center(
                      child: Text(
                        summary.year.toString(),
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'zárás',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 6.8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatSignedHuf(summary.closingAmount),
                          style: TextStyle(
                            color: _statsClosingColor(summary.closingAmount),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _heatColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$_scopeLabel ${formatHuf(summary.scopeTotal)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gray600,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    key: ValueKey('stats-year-month-grid-${summary.year}'),
                    height: 70,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellWidth = constraints.maxWidth / 6;
                          final cellHeight = constraints.maxHeight / 2;
                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 12,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  childAspectRatio: cellWidth / cellHeight,
                                ),
                            itemBuilder: (context, monthIndex) {
                              final month = monthIndex + 1;
                              final amount = summary.monthTotals[month] ?? 0;
                              final intensity = summary.maxMonthTotal <= 0
                                  ? 0.0
                                  : (amount / summary.maxMonthTotal)
                                        .clamp(0.0, 1.0)
                                        .toDouble();
                              return Padding(
                                key: ValueKey(
                                  'stats-year-month-cell-${summary.year}-$month',
                                ),
                                padding: const EdgeInsets.all(1),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: amount <= 0
                                        ? AppColors.white
                                        : _heatColor.withValues(
                                            alpha: 0.10 + intensity * 0.90,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _monthLabels[monthIndex],
                                      style: TextStyle(
                                        color: amount <= 0
                                            ? AppColors.gray500
                                            : AppColors.gray800,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color get _heatColor {
    if (selectedCategoryIds.length != 1) return AppColors.primary;
    final selectedId = selectedCategoryIds.single;
    for (final category in categories) {
      if (category.normalizedType == activeType &&
          category.transactionCategoryID == selectedId) {
        return category.slotColor;
      }
    }
    return AppColors.primary;
  }

  String get _scopeLabel {
    final type = activeType.label.toLowerCase();
    if (selectedCategoryIds.isEmpty) return type;
    if (selectedCategoryIds.length == 1) {
      for (final category in categories) {
        if (category.transactionCategoryID == selectedCategoryIds.single) {
          return '$type ${category.name}';
        }
      }
    }
    return '$type ${selectedCategoryIds.length} kategória';
  }
}

const _monthLabels = [
  'Jan',
  'Feb',
  'Már',
  'Ápr',
  'Máj',
  'Jún',
  'Júl',
  'Aug',
  'Sze',
  'Okt',
  'Nov',
  'Dec',
];

String _formatSignedHuf(double value) {
  if (value == 0) return '0 Ft';
  return '${value > 0 ? '+' : '-'}${formatHuf(value.abs())}';
}

Color _statsClosingColor(double value) {
  if (value > 0) return const Color(0xFF15803D);
  if (value < 0) return const Color(0xFFB91C1C);
  return AppColors.gray700;
}

class _StatsPageTwoSummary extends StatelessWidget {
  const _StatsPageTwoSummary({
    super.key,
    required this.data,
    required this.categories,
    required this.activeType,
    required this.thresholdValue,
    required this.metrics,
    required this.largestVendor,
  });

  final StatsYearData data;
  final List<TransactionCategory> categories;
  final TransactionType activeType;
  final double thresholdValue;
  final StatsPage2Metrics metrics;
  final String largestVendor;

  @override
  Widget build(BuildContext context) {
    final titlePrefix = activeType == TransactionType.income
        ? 'bevétel'
        : 'kiadás';
    return SingleChildScrollView(
      key: const ValueKey('stats-page-2-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktuális szűrés · ${data.year}',
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activeType == TransactionType.income
                          ? 'Bevételi éves statisztika'
                          : 'Kiadási éves statisztika',
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (thresholdValue > 0)
            _StatsThresholdWarning(thresholdValue: thresholdValue),
          Row(
            children: [
              Expanded(
                child: _StatsMetricTile(
                  title: 'Havi átlag',
                  value: formatHuf(metrics.monthlyAverage),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Legnagyobb bevétel'
                      : 'Legnagyobb kiadás',
                  value: formatHuf(metrics.largestAmount),
                  detail: largestVendor,
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Legerősebb hónap'
                      : 'Legdrágább hónap',
                  value: formatHuf(metrics.topMonthAmount),
                  detail: metrics.topMonthLabel,
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatsMetricTile(
                  title: 'Napi tranzakcióátlag',
                  value: metrics.dailyAverageTransactionCount.toStringAsFixed(
                    1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsMetricTile(
                  title:
                      'Napi $titlePrefix'
                      'átlag',
                  value: formatHuf(metrics.dailyAverageAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Bevételmentes nap'
                      : 'Költésmentes nap',
                  value: '${metrics.zeroActivityDays} nap',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Átlagos bevétel'
                      : 'Átlagos kiadás',
                  value: formatHuf(metrics.averageEventAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatsCategoryRankingPanel(
            data: data,
            categories: categories,
            thresholdValue: thresholdValue,
          ),
          const SizedBox(height: 12),
          _StatsVendorRankingPanel(
            data: data,
            activeType: activeType,
            thresholdValue: thresholdValue,
          ),
        ],
      ),
    );
  }
}

class _StatsCategoryRankingPanel extends StatelessWidget {
  const _StatsCategoryRankingPanel({
    required this.data,
    required this.categories,
    required this.thresholdValue,
  });

  final StatsYearData data;
  final List<TransactionCategory> categories;
  final double thresholdValue;

  @override
  Widget build(BuildContext context) {
    final categoriesById = {
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    final rows = data.categoryTotals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final total = rows.fold<double>(0, (sum, row) => sum + row.value);
    final singleSelected = data.selectedCategoryIds.length == 1;
    return _StatsPanel(
      title: singleSelected ? 'Szűrt kategória' : 'Kategória rangsor',
      thresholdValue: thresholdValue,
      children: [
        if (!singleSelected && rows.length > 1) ...[
          Center(
            child: SizedBox.square(
              key: const ValueKey('stats-category-donut'),
              dimension: 208,
              child: CustomPaint(
                painter: _StatsDonutPainter(
                  slices: [
                    for (final row in rows)
                      _StatsDonutSlice(
                        fraction: total <= 0 ? 0 : row.value / total,
                        color:
                            categoriesById[row.key]?.slotColor ??
                            AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final row in rows)
          _StatsProgressRow(
            label: categoriesById[row.key]?.name ?? 'Kategória ${row.key}',
            value: formatHuf(row.value),
            fraction: total <= 0 ? 0 : row.value / total,
            color: categoriesById[row.key]?.slotColor ?? AppColors.primary,
            showPercent: !singleSelected,
          ),
      ],
    );
  }
}

class _StatsDonutSlice {
  const _StatsDonutSlice({required this.fraction, required this.color});

  final double fraction;
  final Color color;
}

class _StatsDonutPainter extends CustomPainter {
  const _StatsDonutPainter({required this.slices});

  final List<_StatsDonutSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -1.5707963267948966;
    for (final slice in slices) {
      final sweep = slice.fraction.clamp(0.0, 1.0) * 6.283185307179586;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = slice.color);
      start += sweep;
    }
    canvas.drawCircle(center, 52, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_StatsDonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _StatsVendorRankingPanel extends StatelessWidget {
  const _StatsVendorRankingPanel({
    required this.data,
    required this.activeType,
    required this.thresholdValue,
  });

  final StatsYearData data;
  final TransactionType activeType;
  final double thresholdValue;

  @override
  Widget build(BuildContext context) {
    final rows = data.vendorSummaries.take(5).toList(growable: false);
    final listedTotal = rows.fold<double>(0, (sum, row) => sum + row.total);
    final title = activeType == TransactionType.income
        ? 'Top 5 forrás'
        : 'Top 5 kereskedő';
    return _StatsPanel(
      title: '$title · ${rows.length} / ${data.vendorSummaries.length}',
      thresholdValue: thresholdValue,
      children: [
        for (final row in rows)
          _StatsProgressRow(
            label: row.name,
            value: formatHuf(row.total),
            fraction: listedTotal <= 0 ? 0 : row.total / listedTotal,
            color: row.color,
            showPercent: false,
          ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.title,
    required this.thresholdValue,
    required this.children,
  });

  final String title;
  final double thresholdValue;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (thresholdValue > 0) ...[
            const SizedBox(height: 8),
            _StatsThresholdWarning(thresholdValue: thresholdValue),
          ],
          const SizedBox(height: 10),
          if (children.isEmpty)
            const Text(
              'Nincs adat',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _StatsProgressRow extends StatelessWidget {
  const _StatsProgressRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    this.showPercent = true,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                showPercent ? '$value · $percent%' : value,
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.gray100,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsMetricTile extends StatelessWidget {
  const _StatsMetricTile({
    required this.title,
    required this.value,
    this.detail,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final String? detail;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: highlighted ? 82 : 68),
      padding: EdgeInsets.symmetric(
        horizontal: highlighted ? 8 : 10,
        vertical: highlighted ? 10 : 9,
      ),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.white : AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gray800,
              fontSize: highlighted ? 13 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsThresholdWarning extends StatelessWidget {
  const _StatsThresholdWarning({required this.thresholdValue});

  final double thresholdValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_compactThreshold(thresholdValue)} Ft alatti tranzakciók rejtve',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _compactThreshold(double value) {
    if (value >= 1000 && value % 1000 == 0) {
      return '${(value / 1000).round()}k';
    }
    return formatHuf(value).replaceAll(' Ft', '');
  }
}

class _StatsFocusedMonthView extends StatelessWidget {
  const _StatsFocusedMonthView({
    required this.data,
    required this.month,
    required this.cardColor,
    required this.heatColor,
  });

  final StatsYearData data;
  final StatsMonthData month;
  final Color cardColor;
  final Color heatColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('calendar-focus-month-view'),
      builder: (context, constraints) {
        const bottomInset = 24.0;
        final contentHeight = (constraints.maxHeight - bottomInset)
            .clamp(0.0, double.infinity)
            .toDouble();
        final widthFromHeight = contentHeight * StatsMonthCard.cardAspectRatio;
        final cardWidth = constraints.maxWidth < widthFromHeight
            ? constraints.maxWidth
            : widthFromHeight;
        final cardHeight = cardWidth / StatsMonthCard.cardAspectRatio;
        return Padding(
          padding: const EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              key: const ValueKey('calendar-focus-month-canvas'),
              width: cardWidth,
              height: cardHeight,
              child: StatsMonthCard(
                key: const ValueKey('stats-focused-month-card'),
                month: month,
                scopeLabel: _scopeLabel,
                cardColor: cardColor,
                heatColor: heatColor,
              ),
            ),
          ),
        );
      },
    );
  }

  String get _scopeLabel {
    final type = data.activeType.label.toLowerCase();
    if (data.selectedCategoryIds.isEmpty) return type;
    if (data.selectedCategoryIds.length == 1) return '$type ${data.scopeLabel}';
    return '$type ${data.selectedCategoryIds.length} kategória';
  }
}

class _StatsThresholdControlSheet extends StatefulWidget {
  const _StatsThresholdControlSheet({
    required this.thresholdValue,
    required this.observedMax,
    required this.fallbackMax,
    required this.accentColor,
    required this.snapshots,
    required this.selectedSnapshotIndex,
    required this.categoryNamesById,
    required this.onAddSnapshot,
    required this.onSnapshotSelected,
    required this.onThresholdChanged,
  });

  final double thresholdValue;
  final double observedMax;
  final double fallbackMax;
  final Color accentColor;
  final List<StatsSnapshot> snapshots;
  final int selectedSnapshotIndex;
  final Map<int, String> categoryNamesById;
  final Future<List<StatsSnapshot>> Function(
    _StatsSnapshotDraft,
    StatsSnapshot?,
  )
  onAddSnapshot;
  final Future<_StatsSnapshotRecallResult> Function(StatsSnapshot)
  onSnapshotSelected;
  final ValueChanged<double> onThresholdChanged;

  @override
  State<_StatsThresholdControlSheet> createState() =>
      _StatsThresholdControlSheetState();
}

class _StatsThresholdControlSheetState
    extends State<_StatsThresholdControlSheet> {
  late double _thresholdValue;
  late double _observedMax;
  late final TextEditingController _amountController;
  late List<StatsSnapshot> _snapshots;
  late int _selectedSnapshotIndex;
  double? _pendingThresholdPublication;
  var _thresholdPublicationScheduled = false;

  @override
  void initState() {
    super.initState();
    _observedMax = widget.observedMax;
    _thresholdValue = _range.snap(widget.thresholdValue);
    _amountController = TextEditingController(
      text: _thresholdValue.toStringAsFixed(0),
    );
    _snapshots = widget.snapshots;
    _selectedSnapshotIndex = widget.selectedSnapshotIndex;
  }

  @override
  void didUpdateWidget(covariant _StatsThresholdControlSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshots != widget.snapshots) {
      _snapshots = widget.snapshots;
    }
    if (oldWidget.selectedSnapshotIndex != widget.selectedSnapshotIndex) {
      _selectedSnapshotIndex = widget.selectedSnapshotIndex;
    }
    if (oldWidget.observedMax != widget.observedMax) {
      _observedMax = widget.observedMax;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Material(
      key: const ValueKey('stats-threshold-sheet'),
      color: AppColors.gray100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _StatsSnapshotStrip(
                snapshots: _snapshots,
                selectedSnapshotIndex: _selectedSnapshotIndex,
                categoryNamesById: widget.categoryNamesById,
                onAddSnapshot: _openSnapshotDialog,
                onSnapshotSelected: (snapshot) {
                  unawaited(_recallSnapshot(snapshot));
                },
                onSnapshotEdit: (snapshot) {
                  unawaited(_openSnapshotDialog(snapshot));
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Küszöb',
                      style: TextStyle(
                        color: AppColors.gray800,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    formatHuf(_thresholdValue),
                    key: const ValueKey('stats-threshold-current-value'),
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: widget.accentColor,
                  inactiveTrackColor: AppColors.gray200,
                  thumbColor: widget.accentColor,
                  overlayColor: widget.accentColor.withValues(alpha: 0.16),
                  trackHeight: 5,
                ),
                child: Slider(
                  key: const ValueKey('stats-threshold-slider'),
                  min: range.min,
                  max: range.max,
                  divisions: ((range.max - range.min) / range.step).round(),
                  value: range.clamp(_thresholdValue),
                  onChanged: _setThreshold,
                  onChangeEnd: (_) => _flushThresholdPublication(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.gray200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                child: TextField(
                  key: const ValueKey('stats-threshold-amount-input'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    suffixText: 'Ft',
                    suffixStyle: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onSubmitted: _submitManualAmount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CalendarJoystickRange get _range => _statsThresholdRange(
    observedMax: _observedMax,
    fallbackMax: widget.fallbackMax,
  );

  Future<void> _openSnapshotDialog([StatsSnapshot? snapshot]) async {
    final draft = await showDialog<_StatsSnapshotDraft>(
      context: context,
      builder: (context) {
        return _StatsSnapshotDialog(initialSnapshot: snapshot);
      },
    );
    if (draft == null) return;
    final snapshots = await widget.onAddSnapshot(draft, snapshot);
    if (!mounted) return;
    final selectedId = snapshot?.id;
    setState(() {
      _snapshots = snapshots;
      _selectedSnapshotIndex = selectedId == null
          ? snapshots.length - 1
          : snapshots.indexWhere((item) => item.id == selectedId);
    });
  }

  Future<void> _recallSnapshot(StatsSnapshot snapshot) async {
    final result = await widget.onSnapshotSelected(snapshot);
    if (!mounted || !result.applied) return;
    setState(() {
      _selectedSnapshotIndex = _snapshots.indexOf(snapshot);
      _observedMax = result.observedMax;
      final next = _range.snap(result.threshold);
      _thresholdValue = next;
      _amountController.text = next.toStringAsFixed(0);
    });
  }

  void _setThreshold(double value) {
    final next = _range.snap(value);
    if (next == _thresholdValue) return;
    _syncThreshold(next);
    _scheduleThresholdPublication(next);
  }

  void _scheduleThresholdPublication(double value) {
    _pendingThresholdPublication = value;
    if (_thresholdPublicationScheduled) return;
    _thresholdPublicationScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _thresholdPublicationScheduled = false;
      if (!mounted) return;
      _flushThresholdPublication();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _flushThresholdPublication() {
    final value = _pendingThresholdPublication;
    _pendingThresholdPublication = null;
    if (value != null) widget.onThresholdChanged(value);
  }

  void _syncThreshold(double value, {double? observedMax}) {
    setState(() {
      if (observedMax != null) _observedMax = observedMax;
      final next = _range.snap(value);
      _thresholdValue = next;
      _amountController.text = next.toStringAsFixed(0);
    });
  }

  void _submitManualAmount(String rawValue) {
    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      _amountController.text = _thresholdValue.toStringAsFixed(0);
      return;
    }
    _setThreshold(parsed);
  }
}

class _StatsSnapshotRecallResult {
  const _StatsSnapshotRecallResult({
    required this.threshold,
    required this.observedMax,
    required this.applied,
  });

  final double threshold;
  final double observedMax;
  final bool applied;
}

CalendarJoystickRange _statsThresholdRange({
  required double observedMax,
  required double fallbackMax,
}) {
  const step = 5000.0;
  final sourceMax = observedMax > fallbackMax ? observedMax : fallbackMax;
  final safeMax = sourceMax > 0 ? sourceMax : step;
  final max = (safeMax / step).ceil() * step;
  return CalendarJoystickRange(min: 0, max: max.toDouble(), step: step);
}

class _StatsSnapshotStrip extends StatelessWidget {
  const _StatsSnapshotStrip({
    required this.snapshots,
    required this.selectedSnapshotIndex,
    required this.categoryNamesById,
    required this.onAddSnapshot,
    required this.onSnapshotSelected,
    required this.onSnapshotEdit,
  });

  final List<StatsSnapshot> snapshots;
  final int selectedSnapshotIndex;
  final Map<int, String> categoryNamesById;
  final VoidCallback onAddSnapshot;
  final ValueChanged<StatsSnapshot> onSnapshotSelected;
  final ValueChanged<StatsSnapshot> onSnapshotEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mentett nézetek',
          style: TextStyle(
            color: AppColors.gray800,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView(
            key: const ValueKey('stats-snapshot-row'),
            scrollDirection: Axis.horizontal,
            children: [
              _StatsSnapshotAddCard(onTap: onAddSnapshot),
              for (var i = 0; i < snapshots.length; i += 1) ...[
                const SizedBox(width: 8),
                _StatsSnapshotPreviewCard(
                  snapshot: snapshots[i],
                  selected: i == selectedSnapshotIndex,
                  categoryNamesById: categoryNamesById,
                  onTap: () => onSnapshotSelected(snapshots[i]),
                  onLongPress: () => onSnapshotEdit(snapshots[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsSnapshotAddCard extends StatelessWidget {
  const _StatsSnapshotAddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('stats-snapshot-add-card'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Center(
          child: Icon(
            Icons.photo_camera_rounded,
            color: AppColors.gray700,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _StatsSnapshotPreviewCard extends StatelessWidget {
  const _StatsSnapshotPreviewCard({
    required this.snapshot,
    required this.selected,
    required this.categoryNamesById,
    required this.onTap,
    required this.onLongPress,
  });

  final StatsSnapshot snapshot;
  final bool selected;
  final Map<int, String> categoryNamesById;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = _snapshotTokens(snapshot, categoryNamesById);
    return GestureDetector(
      key: ValueKey('stats-snapshot-card-${snapshot.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 112,
        height: 74,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFFCF6) : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.income : AppColors.gray200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Pillanatkép neve: ${snapshot.name}',
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              snapshot.name,
                              softWrap: false,
                              style: const TextStyle(
                                color: AppColors.gray800,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Tooltip(
                        message: 'Pillanatkép részletei',
                        child: IconButton(
                          key: ValueKey('stats-snapshot-info-${snapshot.id}'),
                          onPressed: () => _showDetails(context, tokens),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 14,
                            height: 14,
                          ),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(14, 14),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(child: _snapshotTokenRow(tokens.take(3))),
                const SizedBox(height: 3),
                Expanded(child: _snapshotTokenRow(tokens.skip(3))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    List<_StatsSnapshotTokenData> tokens,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const ValueKey('stats-snapshot-details-dialog'),
          title: Text(snapshot.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final token in tokens) ...[
                  Text(token.description),
                  if (token != tokens.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('stats-snapshot-details-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bezárás'),
            ),
          ],
        );
      },
    );
  }

  Widget _snapshotTokenRow(Iterable<_StatsSnapshotTokenData> tokens) {
    final rowTokens = tokens.toList(growable: false);
    if (rowTokens.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var index = 0; index < rowTokens.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 3),
          Expanded(
            child: _StatsSnapshotToken(
              key: ValueKey(
                'stats-snapshot-token-${rowTokens[index].field}-${snapshot.id}',
              ),
              data: rowTokens[index],
            ),
          ),
        ],
      ],
    );
  }

  static List<_StatsSnapshotTokenData> _snapshotTokens(
    StatsSnapshot snapshot,
    Map<int, String> categoryNamesById,
  ) {
    final tokens = <_StatsSnapshotTokenData>[];
    if (snapshot.includeActiveType) {
      final income = snapshot.activeType == TransactionType.income;
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'type',
          compact: snapshot.activeType == null ? 'T?' : (income ? 'BEV' : 'KI'),
          description: snapshot.activeType == null
              ? 'Típus: ismeretlen'
              : (income ? 'Típus: bevétel' : 'Típus: kiadás'),
        ),
      );
    }
    if (snapshot.includeLayoutMode) {
      final period = switch (snapshot.layoutMode) {
        StatsLayoutMode.sum => ('SUM', 'Időszak: összes'),
        StatsLayoutMode.year => (
          'É ${snapshot.activeYear ?? '-'}',
          'Időszak: ${snapshot.activeYear ?? 'ismeretlen'} év',
        ),
        StatsLayoutMode.month => (
          'H ${(snapshot.activeMonth ?? 0).toString().padLeft(2, '0')}/${snapshot.activeYear ?? '-'}',
          'Időszak: ${snapshot.activeYear ?? 'ismeretlen'} év, ${snapshot.activeMonth ?? 'ismeretlen'} hónap',
        ),
        null => ('N?', 'Időszak: ismeretlen'),
      };
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'layout',
          compact: period.$1,
          description: period.$2,
        ),
      );
    }
    if (snapshot.includePageIndex) {
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'page',
          compact: snapshot.pageIndex == null
              ? 'O?'
              : 'O${snapshot.pageIndex! + 1}',
          description: snapshot.pageIndex == null
              ? 'Mentett oldal: ismeretlen. A visszahívás megtartja az aktuális oldalt.'
              : 'Mentett oldal: ${snapshot.pageIndex! + 1}. A visszahívás megtartja az aktuális oldalt.',
        ),
      );
    }
    if (snapshot.includeThreshold) {
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'threshold',
          compact: snapshot.threshold == null
              ? '? Ft'
              : formatHuf(snapshot.threshold!),
          description: snapshot.threshold == null
              ? 'Küszöb: ismeretlen'
              : 'Küszöb: ${formatHuf(snapshot.threshold!)}',
        ),
      );
    }
    if (snapshot.includeCategoryScope) {
      final ids = snapshot.categoryScopeIds.toList()..sort();
      final categoryNames = [
        for (final id in ids) categoryNamesById[id] ?? '#$id',
      ];
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'categories',
          compact: 'K${ids.length}',
          description: ids.isEmpty
              ? 'Kategória szűrés: mind'
              : 'Kategória szűrés: ${categoryNames.join(', ')}',
        ),
      );
    }
    if (snapshot.includeVendorScope) {
      final vendors = snapshot.vendorScopeNames.toList()..sort();
      tokens.add(
        _StatsSnapshotTokenData(
          field: 'vendors',
          compact: 'V${vendors.length}',
          description: vendors.isEmpty
              ? 'Kereskedő szűrés: mind'
              : 'Kereskedő szűrés: ${vendors.join(', ')}',
        ),
      );
    }
    return tokens;
  }
}

class _StatsSnapshotTokenData {
  const _StatsSnapshotTokenData({
    required this.field,
    required this.compact,
    required this.description,
  });

  final String field;
  final String compact;
  final String description;
}

class _StatsSnapshotToken extends StatelessWidget {
  const _StatsSnapshotToken({super.key, required this.data});

  final _StatsSnapshotTokenData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: data.description,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.compact,
              softWrap: false,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsSnapshotDialog extends StatefulWidget {
  const _StatsSnapshotDialog({this.initialSnapshot});

  final StatsSnapshot? initialSnapshot;

  @override
  State<_StatsSnapshotDialog> createState() => _StatsSnapshotDialogState();
}

class _StatsSnapshotDialogState extends State<_StatsSnapshotDialog> {
  late final TextEditingController _nameController;
  late final Set<String> _selectedFields;

  @override
  void initState() {
    super.initState();
    final snapshot = widget.initialSnapshot;
    _nameController = TextEditingController(text: snapshot?.name ?? '');
    _selectedFields = snapshot == null
        ? <String>{
            'Kategória szűrés',
            'Kereskedő szűrés',
            'Küszöb',
            'Nézet mód',
            'Bevétel / kiadás',
            'Aktív oldal',
          }
        : <String>{
            if (snapshot.includeCategoryScope) 'Kategória szűrés',
            if (snapshot.includeVendorScope) 'Kereskedő szűrés',
            if (snapshot.includeThreshold) 'Küszöb',
            if (snapshot.includeLayoutMode) 'Nézet mód',
            if (snapshot.includeActiveType) 'Bevétel / kiadás',
            if (snapshot.includePageIndex) 'Aktív oldal',
          };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('stats-snapshot-dialog'),
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.initialSnapshot == null
            ? 'Pillanatkép mentése'
            : 'Pillanatkép szerkesztése',
        style: const TextStyle(
          color: AppColors.gray800,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('stats-snapshot-name-input'),
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Név',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            for (final field in const [
              'Kategória szűrés',
              'Kereskedő szűrés',
              'Küszöb',
              'Nézet mód',
              'Bevétel / kiadás',
              'Aktív oldal',
            ])
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  field,
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                value: _selectedFields.contains(field),
                activeColor: AppColors.primary,
                onChanged: (selected) {
                  setState(() {
                    if (selected ?? false) {
                      _selectedFields.add(field);
                    } else {
                      _selectedFields.remove(field);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        FilledButton(
          key: const ValueKey('stats-snapshot-save-button'),
          onPressed: () => Navigator.of(context).pop(
            _StatsSnapshotDraft(
              name: _nameController.text,
              includeCategoryScope: _selectedFields.contains(
                'Kategória szűrés',
              ),
              includeVendorScope: _selectedFields.contains('Kereskedő szűrés'),
              includeThreshold: _selectedFields.contains('Küszöb'),
              includeLayoutMode: _selectedFields.contains('Nézet mód'),
              includeActiveType: _selectedFields.contains('Bevétel / kiadás'),
              includePageIndex: _selectedFields.contains('Aktív oldal'),
            ),
          ),
          child: const Text('Mentés'),
        ),
      ],
    );
  }
}

class _StatsSnapshotDraft {
  const _StatsSnapshotDraft({
    required this.name,
    required this.includeCategoryScope,
    required this.includeVendorScope,
    required this.includeActiveType,
    required this.includeThreshold,
    required this.includeLayoutMode,
    required this.includePageIndex,
  });

  final String name;
  final bool includeCategoryScope;
  final bool includeVendorScope;
  final bool includeActiveType;
  final bool includeThreshold;
  final bool includeLayoutMode;
  final bool includePageIndex;
}

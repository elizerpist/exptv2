import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
import '../transactions/models/calendar_menu_mode.dart';
import '../transactions/models/calendar_render_models.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/widgets/calendar_menu/calendar_joystick_range.dart';
import '../transactions/widgets/calendar_menu/focused_month_canvas.dart';
import '../transactions/widgets/calendar_menu/month_stats_charts.dart';
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
import 'data/stats_category_scope_series.dart';
import 'data/stats_year_data.dart';
import 'widgets/stats_fast_info_graph.dart';
import 'widgets/stats_year_calendar.dart';

class StatsPageController {
  VoidCallback? _openThresholdSheet;

  void openThresholdSheet() {
    _openThresholdSheet?.call();
  }

  void _attach({required VoidCallback openThresholdSheet}) {
    _openThresholdSheet = openThresholdSheet;
  }

  void _detach(VoidCallback openThresholdSheet) {
    if (_openThresholdSheet == openThresholdSheet) {
      _openThresholdSheet = null;
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
  });

  final TransactionStore store;
  final StatsPageController? controller;
  final ExpenseTheme? expenseTheme;
  final CategoryMenuSheetRequested? onCategoryMenuRequested;
  final VoidCallback? onVendorSheetRequested;
  final VoidCallback? onAddCategoryEditorRequested;
  final ValueChanged<TransactionCategory>? onEditCategoryEditorRequested;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<StatsPage> {
  late int _year;
  late int _month;
  var _yearScopeEnabled = true;
  var _monthScopeEnabled = false;
  var _activeType = TransactionType.expense;
  final _renderMode = StatsRenderMode.common;
  var _thresholdValue = 5000.0;
  int? _focusedMonth;
  var _scopeSheetOpen = false;
  late final ValueNotifier<double> _fastInfoExtent;
  late final AnimationController _headerPullController;
  late final PageController _contentPageController;
  var _contentPageIndex = 0;
  var _searchQuery = '';
  final _selectedScopeByType = <TransactionType, Set<int>>{
    TransactionType.income: <int>{},
    TransactionType.expense: <int>{},
  };

  @override
  void initState() {
    super.initState();
    _year = widget.store.currentDate.year;
    _month = widget.store.currentDate.month;
    _fastInfoExtent = ValueNotifier<double>(0);
    _headerPullController = AnimationController.unbounded(vsync: this)
      ..addListener(_syncHeaderPullFromController);
    _contentPageController = PageController();
    widget.controller?._attach(openThresholdSheet: _openThresholdControlSheet);
  }

  @override
  void didUpdateWidget(covariant StatsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?._detach(_openThresholdControlSheet);
    widget.controller?._attach(openThresholdSheet: _openThresholdControlSheet);
  }

  @override
  void dispose() {
    _fastInfoExtent.dispose();
    _headerPullController.dispose();
    _contentPageController.dispose();
    widget.controller?._detach(_openThresholdControlSheet);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

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
            final data = _buildStatsData();
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
                      title: _summaryTitle(),
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
                        setState(() => _searchQuery = value);
                      },
                      surfaceColor: resolvedTheme.logBox,
                      surfaceStyle: resolvedTheme.summaryPillSurfaceStyle,
                      merchantFilters: _merchantSearchFilters(
                        resolvedTheme.accent,
                      ),
                      onVendorListPressed: widget.onVendorSheetRequested,
                      accentColor: resolvedTheme.accent,
                    ),
                    const SizedBox(height: 6),
                    _StatsPageIndicator(activeIndex: _contentPageIndex),
                    const SizedBox(height: 4),
                    Expanded(
                      child: PageView.builder(
                        key: const ValueKey('stats-content-pager'),
                        controller: _contentPageController,
                        onPageChanged: (index) {
                          setState(() => _contentPageIndex = index);
                        },
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          if (index == 1) {
                            return _StatsPageTwoSummary(
                              key: const ValueKey('stats-page-2'),
                              data: data,
                              categories: widget.store.categories,
                              activeType: _activeType,
                              thresholdValue: _thresholdValue,
                            );
                          }
                          return KeyedSubtree(
                            key: const ValueKey('stats-page-1'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _pageOneContent(
                                data: data,
                                focusedMonth: focusedMonth,
                                monthCardColor: resolvedTheme.statsMonthCard,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                HeaderFastInfoSurface.listenable(
                  key: const ValueKey('stats-fastinfo-extent-builder'),
                  visibleFastInfoExtentListenable: _fastInfoExtent,
                  cardColor: resolvedTheme.headerCard,
                  surfaceStyle: resolvedTheme.contentSurfaceStyle,
                  fastInfo: StatsFastInfoGraph(data: data),
                  header: _buildHeaderCard(
                    data: data,
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

  StatsYearData _buildStatsData() {
    return StatsYearData.build(
      year: _year,
      activeType: _activeType,
      mode: _renderMode,
      thresholdValue: _thresholdValue,
      transactions: widget.store.transactions,
      categories: widget.store.categories,
      selectedCategoryIds: _selectedScopeByType[_activeType] ?? const <int>{},
      vendorFilters: widget.store.activeMerchantFilters,
      summaryScope: !_yearScopeEnabled
          ? StatsSummaryScope.allTime
          : _monthScopeEnabled
          ? StatsSummaryScope.monthly
          : StatsSummaryScope.yearly,
      month: _month,
      today: widget.store.currentDate,
    );
  }

  Widget _buildHeaderCard({
    required StatsYearData data,
    required ExpenseTheme expenseTheme,
    bool drawSurface = true,
  }) {
    final categorySeries = StatsCategoryScopeSeries.fromYearData(data);
    final visual = _headerVisual(data);
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
        totalIncome: _yearTotal(TransactionType.income),
        totalExpense: _yearTotal(TransactionType.expense),
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

  double _yearTotal(TransactionType type) {
    var total = 0.0;
    for (final record in widget.store.transactions) {
      final date = DateTime.tryParse(record.normalizedDate);
      if (date == null || date.year != _year || record.type != type) continue;
      total += record.amount.abs();
    }
    return total;
  }

  double _observedMaxScopeAmount(StatsYearData data) {
    var max = 0.0;
    for (final month in data.months) {
      for (final day in month.days) {
        if (day.scopeAmount > max) max = day.scopeAmount;
      }
    }
    return max;
  }

  String _scopeChipText(StatsYearData data) {
    final selectedCount = data.selectedCategoryIds.length;
    return selectedCount == 0 ? 'MIND' : selectedCount.toString();
  }

  _StatsHeaderVisual _headerVisual(StatsYearData data) {
    return _StatsHeaderVisual(
      gradientColors: const [
        Color(0xFFEF4444),
        Color(0xFFFBBF24),
        Color(0xFF22C55E),
      ],
      markerPosition:
          StatsCategoryScopeSeries.fromYearData(data).kontrollScore / 100,
    );
  }

  void _setActiveType(TransactionType type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
  }

  Widget _pageOneContent({
    required StatsYearData data,
    required StatsMonthData? focusedMonth,
    required Color monthCardColor,
  }) {
    if (!_yearScopeEnabled) {
      return _StatsSumYearCards(
        transactions: widget.store.transactions,
        categories: widget.store.categories,
        activeType: _activeType,
        selectedCategoryIds: _selectedScopeByType[_activeType] ?? const <int>{},
        vendorFilters: widget.store.activeMerchantFilters,
        thresholdValue: _thresholdValue,
        onYearSelected: (year) {
          setState(() {
            _yearScopeEnabled = true;
            _monthScopeEnabled = false;
            _focusedMonth = null;
            _year = year;
          });
        },
        onMonthSelected: (year, month) {
          setState(() {
            _yearScopeEnabled = true;
            _monthScopeEnabled = true;
            _year = year;
            _month = month;
            _focusedMonth = month;
          });
        },
      );
    }
    if (focusedMonth == null) {
      return StatsYearCalendar(
        data: data,
        monthCardColor: monthCardColor,
        onMonthSelected: _selectMonth,
      );
    }
    return _StatsFocusedMonthView(
      data: data,
      month: focusedMonth,
      transactions: widget.store.transactions,
      categories: widget.store.categories,
      onBack: () {
        setState(() => _focusedMonth = null);
      },
    );
  }

  String _summaryTitle() {
    if (!_yearScopeEnabled) return 'Sum · ${_activeType.label}';
    if (_monthScopeEnabled) {
      return '${_monthName(_month)} $_year · ${_activeType.label}';
    }
    return 'Éves · $_year · ${_activeType.label}';
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
    setState(() {
      _yearScopeEnabled = selection.yearEnabled;
      _monthScopeEnabled = selection.monthEnabled && selection.yearEnabled;
      _year = selection.year;
      _month = selection.month.clamp(1, 12).toInt();
      if (!_monthScopeEnabled) _focusedMonth = null;
      if (_monthScopeEnabled) _focusedMonth = _month;
    });
  }

  void _cycleSummaryScope() {
    setState(() {
      if (_monthScopeEnabled) {
        _yearScopeEnabled = false;
        _monthScopeEnabled = false;
        _focusedMonth = null;
      } else if (_yearScopeEnabled) {
        _monthScopeEnabled = true;
        _focusedMonth = _month;
      } else {
        _yearScopeEnabled = true;
        _monthScopeEnabled = false;
        _focusedMonth = null;
      }
    });
  }

  void _shiftSummaryScope(int direction) {
    if (direction == 0 || !_yearScopeEnabled) return;
    setState(() {
      if (_monthScopeEnabled) {
        final nextMonth = _month + direction;
        if (nextMonth < 1) {
          _month = 12;
          _year -= 1;
        } else if (nextMonth > 12) {
          _month = 1;
          _year += 1;
        } else {
          _month = nextMonth;
        }
        _focusedMonth = _month;
        return;
      }
      _year += direction;
    });
  }

  void _resetSummaryScope() {
    final now = widget.store.currentDate;
    setState(() {
      _yearScopeEnabled = true;
      _monthScopeEnabled = true;
      _year = now.year;
      _month = now.month;
      _focusedMonth = _month;
    });
  }

  static String _monthName(int month) {
    const names = [
      'Január',
      'Február',
      'Március',
      'Április',
      'Május',
      'Június',
      'Július',
      'Augusztus',
      'Szeptember',
      'Október',
      'November',
      'December',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  void _selectMonth(StatsMonthData month) {
    setState(() {
      _yearScopeEnabled = true;
      _monthScopeEnabled = true;
      _month = month.month;
      _focusedMonth = month.month;
    });
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
    final observedMax = _observedMaxScopeAmount(_buildStatsData());
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

class _StatsPageIndicator extends StatelessWidget {
  const _StatsPageIndicator({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('stats-page-indicator'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 2; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: activeIndex == index ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: activeIndex == index
                  ? AppColors.gray700
                  : AppColors.gray300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _StatsSumYearCards extends StatelessWidget {
  const _StatsSumYearCards({
    required this.transactions,
    required this.categories,
    required this.activeType,
    required this.selectedCategoryIds,
    required this.vendorFilters,
    required this.thresholdValue,
    required this.onYearSelected,
    required this.onMonthSelected,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final TransactionType activeType;
  final Set<int> selectedCategoryIds;
  final Set<String> vendorFilters;
  final double thresholdValue;
  final ValueChanged<int> onYearSelected;
  final void Function(int year, int month) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final summaries = _buildSummaries();
    return ListView.separated(
      key: const ValueKey('stats-sum-year-cards'),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: summaries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return GestureDetector(
          key: ValueKey('stats-year-card-${summary.year}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onYearSelected(summary.year),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.year.toString(),
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      formatHuf(summary.total),
                      style: const TextStyle(
                        color: AppColors.gray700,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    childAspectRatio: 2.9,
                  ),
                  itemBuilder: (context, monthIndex) {
                    final month = monthIndex + 1;
                    final amount = summary.monthTotals[month] ?? 0;
                    final intensity = summary.maxMonthTotal <= 0
                        ? 0.0
                        : (amount / summary.maxMonthTotal)
                              .clamp(0.0, 1.0)
                              .toDouble();
                    return GestureDetector(
                      key: ValueKey(
                        'stats-year-month-cell-${summary.year}-$month',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMonthSelected(summary.year, month),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: amount <= 0
                              ? AppColors.white
                              : _heatColor.withValues(
                                  alpha: 0.10 + intensity * 0.70,
                                ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          month.toString(),
                          style: TextStyle(
                            color: amount <= 0
                                ? AppColors.gray500
                                : AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color get _heatColor => activeType == TransactionType.income
      ? AppColors.income
      : AppColors.primary;

  List<_StatsYearSummary> _buildSummaries() {
    final activeCategoryIds = categories
        .where((category) => category.normalizedType == activeType)
        .map((category) => category.transactionCategoryID)
        .toSet();
    final selected = selectedCategoryIds
        .where(activeCategoryIds.contains)
        .toSet();
    final useAllCategories =
        selected.isEmpty || selected.length == activeCategoryIds.length;
    final byYear = <int, Map<int, double>>{};
    for (final record in transactions) {
      if ((record.amount > 0) != (activeType == TransactionType.income)) {
        continue;
      }
      final amount = record.amount.abs();
      if (thresholdValue > 0 && amount < thresholdValue) continue;
      final categoryId = record.transactionCategoryID;
      if (!useAllCategories && !selected.contains(categoryId)) continue;
      if (vendorFilters.isNotEmpty &&
          !vendorFilters.contains(record.displayMerchant) &&
          !vendorFilters.contains(record.merchant)) {
        continue;
      }
      final parsed = DateTime.tryParse(record.normalizedDate);
      if (parsed == null) continue;
      byYear
          .putIfAbsent(parsed.year, () => <int, double>{})
          .update(
            parsed.month,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
    }
    final summaries = [
      for (final entry in byYear.entries)
        _StatsYearSummary(
          year: entry.key,
          monthTotals: Map.unmodifiable(entry.value),
        ),
    ]..sort((left, right) => right.year.compareTo(left.year));
    return summaries;
  }
}

class _StatsYearSummary {
  const _StatsYearSummary({required this.year, required this.monthTotals});

  final int year;
  final Map<int, double> monthTotals;

  double get total =>
      monthTotals.values.fold<double>(0, (sum, value) => sum + value);

  double get maxMonthTotal => monthTotals.values.fold<double>(
    0,
    (max, value) => value > max ? value : max,
  );
}

class _StatsPageTwoSummary extends StatelessWidget {
  const _StatsPageTwoSummary({
    super.key,
    required this.data,
    required this.categories,
    required this.activeType,
    required this.thresholdValue,
  });

  final StatsYearData data;
  final List<TransactionCategory> categories;
  final TransactionType activeType;
  final double thresholdValue;

  @override
  Widget build(BuildContext context) {
    final total = data.summaryTotal;
    final largestMonth = data.months.fold<StatsMonthData?>(
      null,
      (best, month) =>
          best == null || month.activeTotal > best.activeTotal ? month : best,
    );
    final activeDays = data.months.fold<int>(
      0,
      (sum, month) =>
          sum + month.days.where((day) => day.activeAmount > 0).length,
    );
    final dayCount = data.months.fold<int>(
      0,
      (sum, month) => sum + month.days.length,
    );
    final dailyAverage = dayCount == 0 ? 0.0 : total / dayCount;
    final noActivityDays = (dayCount - activeDays).clamp(0, dayCount);
    final titlePrefix = activeType == TransactionType.income
        ? 'bevétel'
        : 'kiadás';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (thresholdValue > 0)
            _StatsThresholdWarning(thresholdValue: thresholdValue),
          Row(
            children: [
              Expanded(
                child: _StatsMetricTile(
                  title: 'Havi átlag',
                  value: formatHuf(total / 12),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Legnagyobb bevétel'
                      : 'Legnagyobb kiadás',
                  value: formatHuf(_largestDayAmount()),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Legerősebb hónap'
                      : 'Legdrágább hónap',
                  value: formatHuf(largestMonth?.activeTotal ?? 0),
                  detail: largestMonth?.name ?? '-',
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
                  value: _dailyTransactionAverageText(dayCount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsMetricTile(
                  title:
                      'Napi $titlePrefix'
                      'átlag',
                  value: formatHuf(dailyAverage),
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
                  value: '$noActivityDays nap',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsMetricTile(
                  title: activeType == TransactionType.income
                      ? 'Átlagos bevétel'
                      : 'Átlagos kiadás',
                  value: formatHuf(_averageEventAmount()),
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

  double _largestDayAmount() {
    var largest = 0.0;
    for (final month in data.months) {
      for (final day in month.days) {
        if (day.activeAmount > largest) largest = day.activeAmount;
      }
    }
    return largest;
  }

  double _averageEventAmount() {
    var total = 0.0;
    var count = 0;
    for (final month in data.months) {
      for (final day in month.days) {
        if (day.activeAmount <= 0) continue;
        total += day.activeAmount;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  String _dailyTransactionAverageText(int dayCount) {
    if (dayCount == 0) return '0';
    final count = data.months.fold<int>(
      0,
      (sum, month) => sum + month.transactionCount,
    );
    return (count / dayCount).toStringAsFixed(1);
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
    required this.transactions,
    required this.categories,
    required this.onBack,
  });

  final StatsYearData data;
  final StatsMonthData month;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final calendarMode = _calendarMode;
    final calendarMonth = _calendarMonth(calendarMode);
    return SingleChildScrollView(
      key: const ValueKey('calendar-focus-month-view'),
      padding: const EdgeInsets.only(bottom: 144),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: IconButton(
                    key: const ValueKey('calendar-focus-back'),
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.gray700,
                    ),
                    tooltip: 'Vissza az éves nézethez',
                  ),
                ),
                Text(
                  '${month.name} ${month.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FocusedMonthCanvas(
            month: calendarMonth,
            mode: calendarMode,
            thresholdValue: data.thresholdValue,
            heatmapMinValue: 0,
            heatmapCurrentValue: _heatmapCurrentValue,
          ),
          const SizedBox(height: 14),
          MonthStatsCharts(
            year: month.year,
            month: month.month,
            transactions: transactions,
            categories: categories,
          ),
        ],
      ),
    );
  }

  CalendarMenuMode get _calendarMode => CalendarMenuMode.category;

  double get _heatmapCurrentValue {
    var max = data.thresholdValue;
    for (final day in month.days) {
      if (day.scopeAmount > max) max = day.scopeAmount;
    }
    return max <= 0 ? 1 : max;
  }

  CalendarMonthRenderData _calendarMonth(CalendarMenuMode calendarMode) {
    final visualAsExpense = calendarMode != CalendarMenuMode.summary;
    final income = !visualAsExpense && data.activeType == TransactionType.income
        ? month.activeTotal
        : 0.0;
    final expense =
        visualAsExpense || data.activeType == TransactionType.expense
        ? month.activeTotal
        : 0.0;
    return CalendarMonthRenderData(
      year: month.year,
      month: month.month,
      name: month.name,
      weekdayLabels: month.weekdayLabels,
      leadingBlankDays: month.leadingBlankDays,
      days: [
        for (final day in month.days)
          _calendarDay(day, visualAsExpense: visualAsExpense),
      ],
      income: income,
      expense: expense,
      balance: income - expense,
      transactionCount: month.transactionCount,
    );
  }

  CalendarDayRenderData _calendarDay(
    StatsDayData day, {
    required bool visualAsExpense,
  }) {
    final income = !visualAsExpense && data.activeType == TransactionType.income
        ? day.activeAmount
        : 0.0;
    final expense =
        visualAsExpense || data.activeType == TransactionType.expense
        ? day.activeAmount
        : 0.0;
    return CalendarDayRenderData(
      date: day.date,
      day: day.day,
      income: income,
      expense: expense,
      hasIncome:
          !visualAsExpense &&
          data.activeType == TransactionType.income &&
          day.hasActiveTypeActivity,
      hasExpense:
          !visualAsExpense &&
          data.activeType == TransactionType.expense &&
          day.hasActiveTypeActivity,
      meetsThreshold: day.meetsThreshold,
      heatmapPercentage: day.heatmapIntensity,
      dominantCategoryId: day.dominantCategoryId,
      dominantCategoryColor: day.dominantCategoryColor,
      isToday: day.isToday,
    );
  }
}

class _StatsThresholdControlSheet extends StatefulWidget {
  const _StatsThresholdControlSheet({
    required this.thresholdValue,
    required this.observedMax,
    required this.fallbackMax,
    required this.accentColor,
    required this.onThresholdChanged,
  });

  final double thresholdValue;
  final double observedMax;
  final double fallbackMax;
  final Color accentColor;
  final ValueChanged<double> onThresholdChanged;

  @override
  State<_StatsThresholdControlSheet> createState() =>
      _StatsThresholdControlSheetState();
}

class _StatsThresholdControlSheetState
    extends State<_StatsThresholdControlSheet> {
  late double _thresholdValue;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _thresholdValue = _range.snap(widget.thresholdValue);
    _amountController = TextEditingController(
      text: _thresholdValue.toStringAsFixed(0),
    );
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
              _StatsSnapshotStrip(onAddSnapshot: _openSnapshotDialog),
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
                  divisions: ((range.max - range.min) / range.step)
                      .round()
                      .clamp(1, 1000)
                      .toInt(),
                  value: range.clamp(_thresholdValue),
                  onChanged: _setThreshold,
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

  CalendarJoystickRange get _range => CalendarJoystickRange.adaptive(
    currentValue: widget.thresholdValue,
    observedMax: widget.observedMax,
    fallbackMax: widget.fallbackMax,
  );

  Future<void> _openSnapshotDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const _StatsSnapshotDialog();
      },
    );
  }

  void _setThreshold(double value) {
    final next = _range.snap(value);
    if (next == _thresholdValue) return;
    setState(() {
      _thresholdValue = next;
      _amountController.text = next.toStringAsFixed(0);
    });
    widget.onThresholdChanged(next);
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

class _StatsSnapshotStrip extends StatelessWidget {
  const _StatsSnapshotStrip({required this.onAddSnapshot});

  final VoidCallback onAddSnapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pillanatképek',
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
              const SizedBox(width: 8),
              const _StatsSnapshotPreviewCard(
                title: 'Kiadás',
                detail: 'Éves · 5k',
              ),
              const SizedBox(width: 8),
              const _StatsSnapshotPreviewCard(
                title: 'Bevétel',
                detail: 'Hónap · 0',
              ),
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
  const _StatsSnapshotPreviewCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSnapshotDialog extends StatefulWidget {
  const _StatsSnapshotDialog();

  @override
  State<_StatsSnapshotDialog> createState() => _StatsSnapshotDialogState();
}

class _StatsSnapshotDialogState extends State<_StatsSnapshotDialog> {
  final _selectedFields = <String>{
    'Kategória scope',
    'Vendor scope',
    'Küszöb',
    'Layout mód',
    'Bevétel / kiadás',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('stats-snapshot-dialog'),
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Snapshot mentése',
        style: TextStyle(
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
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Név',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            for (final field in const [
              'Kategória scope',
              'Vendor scope',
              'Küszöb',
              'Layout mód',
              'Bevétel / kiadás',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mentés'),
        ),
      ],
    );
  }
}

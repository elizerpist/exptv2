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
import '../transactions/widgets/calendar_menu/calendar_value_slider_panel.dart';
import '../transactions/widgets/calendar_menu/focused_month_canvas.dart';
import '../transactions/widgets/calendar_menu/month_stats_charts.dart';
import '../transactions/widgets/category_menu/category_menu_panel.dart';
import '../transactions/widgets/header_card/header_fast_info_surface.dart';
import '../transactions/widgets/header_card/magnet_strip.dart';
import '../transactions/widgets/header_card/transaction_header_card.dart';
import '../transactions/widgets/header_card/transaction_header_metrics.dart';
import '../transactions/widgets/slide_up_menu_card.dart';
import '../transactions/widgets/summary_pill.dart';
import '../transactions/widgets/summary_scope_picker_sheet.dart';
import '../transactions/widgets/transaction_menu_metrics.dart';
import '../transactions/widgets/transaction_type_pills.dart';
import 'data/stats_category_scope_series.dart';
import 'data/stats_closing_series.dart';
import 'data/stats_year_data.dart';
import 'widgets/stats_fast_info_graph.dart';
import 'widgets/stats_year_calendar.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.store,
    this.expenseTheme,
    this.onCategoryMenuRequested,
    this.onAddCategoryEditorRequested,
    this.onEditCategoryEditorRequested,
  });

  final TransactionStore store;
  final ExpenseTheme? expenseTheme;
  final CategoryMenuSheetRequested? onCategoryMenuRequested;
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
  var _renderMode = StatsRenderMode.categoryScope;
  var _thresholdValue = 5000.0;
  int? _focusedMonth;
  var _scopeSheetOpen = false;
  late final ValueNotifier<double> _fastInfoExtent;
  late final AnimationController _headerPullController;
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
  }

  @override
  void dispose() {
    _fastInfoExtent.dispose();
    _headerPullController.dispose();
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
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: focusedMonth == null
                            ? StatsYearCalendar(
                                data: data,
                                monthCardColor: resolvedTheme.statsMonthCard,
                                onMonthSelected: _selectMonth,
                              )
                            : _StatsFocusedMonthView(
                                data: data,
                                month: focusedMonth,
                                transactions: widget.store.transactions,
                                categories: widget.store.categories,
                                onBack: () {
                                  setState(() => _focusedMonth = null);
                                },
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
                  fastInfo: StatsFastInfoGraph(data: data),
                  header: _buildHeaderCard(
                    data: data,
                    expenseTheme: resolvedTheme,
                    drawSurface: false,
                  ),
                ),
                CalendarValueSliderPanel.threshold(
                  value: _thresholdValue,
                  observedMax: _observedMaxScopeAmount(data),
                  fallbackMax: 50000,
                  onTap: _openThresholdControlSheet,
                  onChanged: (value) {
                    setState(() => _thresholdValue = value);
                  },
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
    final categorySeries = data.mode == StatsRenderMode.categoryScope
        ? StatsCategoryScopeSeries.fromYearData(data)
        : null;
    final visual = _headerVisual(data);
    final headerLabel = categorySeries == null
        ? data.headerLabel
        : data.activeType == TransactionType.income
        ? 'INCOME SCORE'
        : 'SCOPE SCORE';
    final headerValue = categorySeries == null
        ? data.headerValue
        : '${categorySeries.kontrollScore.round()}/100';
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
    return selectedCount == 0 ? 'ALL' : selectedCount.toString();
  }

  _StatsHeaderVisual _headerVisual(StatsYearData data) {
    return switch (data.mode) {
      StatsRenderMode.categoryScope => _StatsHeaderVisual(
        gradientColors: const [
          Color(0xFFEF4444),
          Color(0xFFFBBF24),
          Color(0xFF22C55E),
        ],
        markerPosition:
            StatsCategoryScopeSeries.fromYearData(data).kontrollScore / 100,
      ),
      StatsRenderMode.heatmap => _StatsHeaderVisual(
        gradientColors: const [
          Color(0xFFE2E8F0),
          Color(0xFFFFFFFF),
          Color(0xFFDDF8FD),
          Color(0xFF67E8F9),
          Color(0xFF06B6D4),
        ],
        markerPosition: _heatConcentration(data),
      ),
      StatsRenderMode.closing => _StatsHeaderVisual(
        gradientColors: const [
          Color(0xFFEF4444),
          Color(0xFFFEE2E2),
          Color(0xFFFFFFFF),
          Color(0xFFDCFCE7),
          Color(0xFF22C55E),
        ],
        markerPosition: StatsClosingSeries.fromYearData(data).driftMarker,
      ),
    };
  }

  double _heatConcentration(StatsYearData data) {
    var activeDays = 0;
    for (final month in data.graphMonths) {
      for (final day in month.days) {
        if (day.scopeAmount > 0) activeDays += 1;
      }
    }
    if (activeDays == 0) return 0;
    return (data.totalThresholdHitDays / activeDays).clamp(0.0, 1.0).toDouble();
  }

  void _setActiveType(TransactionType type) {
    if (_activeType == type) return;
    setState(() => _activeType = type);
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
          activeMode: _renderMode,
          thresholdValue: _thresholdValue,
          observedMax: observedMax,
          fallbackMax: 50000,
          accentColor: _expenseTheme.accent,
          onModeSelected: (mode) {
            setState(() => _renderMode = mode);
          },
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

  CalendarMenuMode get _calendarMode => switch (data.mode) {
    StatsRenderMode.categoryScope => CalendarMenuMode.category,
    StatsRenderMode.closing => CalendarMenuMode.summary,
    StatsRenderMode.heatmap => CalendarMenuMode.heatmap,
  };

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
    required this.activeMode,
    required this.thresholdValue,
    required this.observedMax,
    required this.fallbackMax,
    required this.accentColor,
    required this.onModeSelected,
    required this.onThresholdChanged,
  });

  final StatsRenderMode activeMode;
  final double thresholdValue;
  final double observedMax;
  final double fallbackMax;
  final Color accentColor;
  final ValueChanged<StatsRenderMode> onModeSelected;
  final ValueChanged<double> onThresholdChanged;

  @override
  State<_StatsThresholdControlSheet> createState() =>
      _StatsThresholdControlSheetState();
}

class _StatsThresholdControlSheetState
    extends State<_StatsThresholdControlSheet> {
  late StatsRenderMode _activeMode;
  late double _thresholdValue;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.activeMode;
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
              Row(
                key: const ValueKey('stats-render-mode-selector'),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final mode in StatsRenderMode.values)
                    _StatsRenderModeButton(
                      mode: mode,
                      active: mode == _activeMode,
                      accentColor: widget.accentColor,
                      onTap: () {
                        setState(() => _activeMode = mode);
                        widget.onModeSelected(mode);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
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

class _StatsRenderModeButton extends StatelessWidget {
  const _StatsRenderModeButton({
    required this.mode,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final StatsRenderMode mode;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('stats-render-mode-${mode.name}'),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: active ? 34 : 30,
              height: active ? 34 : 30,
              decoration: BoxDecoration(
                color: _modeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? accentColor : AppColors.gray200,
                  width: active ? 3 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          offset: const Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ]
                    : const [],
              ),
              child: Icon(_icon, size: 17, color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              mode.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _modeColor => switch (mode) {
    StatsRenderMode.categoryScope => const Color(0xFFF97316),
    StatsRenderMode.closing => AppColors.income,
    StatsRenderMode.heatmap => accentColor,
  };

  IconData get _icon => switch (mode) {
    StatsRenderMode.categoryScope => Icons.scatter_plot_outlined,
    StatsRenderMode.closing => Icons.stacked_bar_chart_rounded,
    StatsRenderMode.heatmap => Icons.grid_view_rounded,
  };
}

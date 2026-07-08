import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
import '../transactions/models/calendar_menu_mode.dart';
import '../transactions/models/calendar_render_models.dart';
import '../transactions/models/transaction_category.dart';
import '../transactions/models/transaction_record.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/widgets/calendar_menu/calendar_value_slider_panel.dart';
import '../transactions/widgets/calendar_menu/focused_month_canvas.dart';
import '../transactions/widgets/calendar_menu/month_stats_charts.dart';
import '../transactions/widgets/header_card/header_fast_info_surface.dart';
import '../transactions/widgets/header_card/transaction_header_card.dart';
import '../transactions/widgets/header_card/transaction_header_metrics.dart';
import '../transactions/widgets/summary_pill.dart';
import '../transactions/widgets/transaction_type_pills.dart';
import 'data/stats_category_scope_series.dart';
import 'data/stats_closing_series.dart';
import 'data/stats_year_data.dart';
import 'widgets/stats_category_scope_sheet.dart';
import 'widgets/stats_fast_info_graph.dart';
import 'widgets/stats_year_calendar.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.store, this.expenseTheme});

  final TransactionStore store;
  final ExpenseTheme? expenseTheme;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<StatsPage> {
  late int _year;
  var _activeType = TransactionType.expense;
  var _renderMode = StatsRenderMode.categoryScope;
  var _thresholdValue = 5000.0;
  int? _focusedMonth;
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
                      shadowEnabled:
                          resolvedTheme.settings.headerPillShadowEnabled,
                      onChanged: _setActiveType,
                    ),
                    SummaryPill(
                      title: 'Éves · $_year · ${_activeType.label}',
                      value: data.summaryValue,
                      surfaceColor: resolvedTheme.logBox,
                      surfaceStyle: resolvedTheme.contentSurfaceStyle,
                      shadowEnabled:
                          resolvedTheme.settings.summaryPillShadowEnabled,
                      onIntervalSwipe: () {},
                      onPeriodSwipe: (direction) {
                        if (direction == 0) return;
                        setState(() => _year += direction);
                      },
                      onResetToCurrentMonth: () {
                        setState(() => _year = widget.store.currentDate.year);
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: focusedMonth == null
                            ? StatsYearCalendar(
                                data: data,
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
                  onTap: _openRenderModeSelector,
                  onChanged: (value) {
                    setState(() => _thresholdValue = value);
                  },
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
      today: widget.store.currentDate,
    );
  }

  Widget _buildHeaderCard({
    required StatsYearData data,
    required ExpenseTheme expenseTheme,
    bool drawSurface = true,
  }) {
    final visual = _headerVisual(data);
    return RepaintBoundary(
      child: TransactionHeaderCard(
        labelText: data.headerLabel,
        balanceText: data.headerValue,
        showBalanceVisibilityButton: false,
        magnetType: MagnetType.fade,
        accent: expenseTheme.accent,
        cardColor: expenseTheme.headerCard,
        surfaceStyle: expenseTheme.contentSurfaceStyle,
        buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
        totalIncome: _yearTotal(TransactionType.income),
        totalExpense: _yearTotal(TransactionType.expense),
        leadingChipText: _scopeChipText(data),
        leadingChipColor: visual.chipColor,
        magnetGradientColors: visual.gradientColors,
        magnetMarkerPosition: visual.markerPosition,
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
        chipColor: const Color(0xFFF97316),
        gradientColors: const [
          Color(0xFFEF4444),
          Color(0xFFF97316),
          Color(0xFF10B981),
        ],
        markerPosition:
            StatsCategoryScopeSeries.fromYearData(data).kontrollScore / 100,
      ),
      StatsRenderMode.heatmap => _StatsHeaderVisual(
        chipColor: AppColors.primary,
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
        chipColor: data.activeType == TransactionType.income
            ? AppColors.income
            : AppColors.expense,
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

  void _selectMonth(StatsMonthData month) {
    setState(() => _focusedMonth = month.month);
  }

  Future<void> _openScopeSheet() async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.72;
        return SizedBox(
          height: height,
          child: StatsCategoryScopeSheet(
            activeType: _activeType,
            categories: widget.store.categories,
            selectedCategoryIds:
                _selectedScopeByType[_activeType] ?? const <int>{},
            accentColor: _expenseTheme.accent,
            onApply: (ids) => Navigator.of(context).pop(ids),
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedScopeByType[_activeType] = result;
    });
  }

  Future<void> _openRenderModeSelector() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StatsRenderModeSheet(
          activeMode: _renderMode,
          accentColor: _expenseTheme.accent,
          onSelected: (mode) {
            setState(() => _renderMode = mode);
            Navigator.of(context).pop();
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
    required this.chipColor,
    required this.gradientColors,
    required this.markerPosition,
  });

  final Color chipColor;
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

class _StatsRenderModeSheet extends StatelessWidget {
  const _StatsRenderModeSheet({
    required this.activeMode,
    required this.accentColor,
    required this.onSelected,
  });

  final StatsRenderMode activeMode;
  final Color accentColor;
  final ValueChanged<StatsRenderMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('stats-render-mode-selector'),
      color: AppColors.gray100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final mode in StatsRenderMode.values)
                    _StatsRenderModeButton(
                      mode: mode,
                      active: mode == activeMode,
                      accentColor: accentColor,
                      onTap: () => onSelected(mode),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

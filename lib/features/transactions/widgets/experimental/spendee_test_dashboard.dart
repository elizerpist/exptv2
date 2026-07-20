import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/platform/browser_fullscreen_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/category_color_manager.dart';
import '../../../settings/theme/expense_theme.dart';
import '../../../stats/data/stats_category_scope_series.dart';
import '../../../stats/data/stats_render_frame.dart';
import '../../../stats/data/stats_year_data.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/summary_window.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_log_entry.dart';
import '../../models/transaction_record.dart';
import '../../state/transaction_store.dart';
import '../glossy_category_avatar.dart';
import '../search_pill.dart';
import '../transaction_log_box.dart';
import 'fluvi_logo.dart';
import 'spendee_center_carousel_controller.dart';
import 'spendee_acrylic_surface.dart';
import 'spendee_header_glass.dart';
import 'spendee_liquid_glass_surface.dart';
import 'spendee_header_stage_controller.dart';
import 'spendee_header_visual_spec.dart';
import 'spendee_mind_stats_adapter.dart';

final _budgetHeaderVisualSpec = SpendeeHeaderVisualSpec.budgetDefault();
const _defaultHeaderLiquidSoftness = .68;

enum _HeaderSurface { normal, htmlC2Glass, liquidGlass, acrylic }

enum _PanelSurface { background, glass, htmlC2Glass, liquidGlass, acrylic }

enum _ChartListSurface { none, original, htmlC2Glass, liquidGlass, acrylic }

enum _Stage2BudgetPage { categories, vendors }

enum _HeaderBackgroundMode { budget, mind }

class _MindStatsFrameCacheKey {
  _MindStatsFrameCacheKey({
    required this.summaryWindow,
    required this.referenceYear,
    required this.referenceMonth,
    required this.referenceDay,
    required this.currentYear,
    required this.currentMonth,
    required this.currentDay,
    required this.searchQuery,
    required this.activeCategoryIds,
    required this.activeMerchantFilters,
    required this.transactions,
    required this.categories,
  });

  factory _MindStatsFrameCacheKey.fromStore(TransactionStore store) {
    final reference = store.summaryReferenceDate;
    final current = store.currentDate;
    return _MindStatsFrameCacheKey(
      summaryWindow: store.summaryWindow,
      referenceYear: reference.year,
      referenceMonth: reference.month,
      referenceDay: reference.day,
      currentYear: current.year,
      currentMonth: current.month,
      currentDay: current.day,
      searchQuery: store.searchQuery,
      activeCategoryIds: (store.activeCategoryIds.toList()..sort()),
      activeMerchantFilters: (store.activeMerchantFilters.toList()..sort()),
      transactions: store.transactions,
      categories: store.categories,
    );
  }

  final SummaryWindow summaryWindow;
  final int referenceYear;
  final int referenceMonth;
  final int referenceDay;
  final int currentYear;
  final int currentMonth;
  final int currentDay;
  final String searchQuery;
  final List<int> activeCategoryIds;
  final List<String> activeMerchantFilters;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;

  String get categoryFilterLabel =>
      activeCategoryIds.isEmpty ? 'all' : activeCategoryIds.join(',');
  String get merchantFilterLabel =>
      activeMerchantFilters.isEmpty ? 'all' : activeMerchantFilters.join('|');

  @override
  bool operator ==(Object other) {
    return other is _MindStatsFrameCacheKey &&
        other.summaryWindow == summaryWindow &&
        other.referenceYear == referenceYear &&
        other.referenceMonth == referenceMonth &&
        other.referenceDay == referenceDay &&
        other.currentYear == currentYear &&
        other.currentMonth == currentMonth &&
        other.currentDay == currentDay &&
        other.searchQuery == searchQuery &&
        identical(other.transactions, transactions) &&
        identical(other.categories, categories) &&
        _listEquals(other.activeCategoryIds, activeCategoryIds) &&
        _listEquals(other.activeMerchantFilters, activeMerchantFilters);
  }

  @override
  int get hashCode => Object.hash(
    summaryWindow,
    referenceYear,
    referenceMonth,
    referenceDay,
    currentYear,
    currentMonth,
    currentDay,
    searchQuery,
    identityHashCode(transactions),
    identityHashCode(categories),
    Object.hashAll(activeCategoryIds),
    Object.hashAll(activeMerchantFilters),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

enum _HeaderDesignMenuAction {
  headerBackgroundBudget,
  headerBackgroundMind,
  headerNormal,
  headerHtmlC2Glass,
  headerLiquidGlass,
  headerAcrylic,
  avatarsBackground,
  avatarsGlass,
  avatarsHtmlC2Glass,
  avatarsLiquidGlass,
  avatarsAcrylic,
  chartGlass,
  chartBackground,
  chartHtmlC2Glass,
  chartLiquidGlass,
  chartAcrylic,
  chartListNone,
  chartListOriginal,
  chartListHtmlC2Glass,
  chartListLiquidGlass,
  chartListAcrylic,
  mindStage1Background,
  mindStage1Glass,
  mindStage1HtmlC2Glass,
  mindStage1LiquidGlass,
  mindStage1Acrylic,
  mindStage2Background,
  mindStage2Glass,
  mindStage2HtmlC2Glass,
  mindStage2LiquidGlass,
  mindStage2Acrylic,
}

class _HeaderLiquidSoftnessMenuEntry
    extends PopupMenuEntry<_HeaderDesignMenuAction> {
  const _HeaderLiquidSoftnessMenuEntry({
    super.key,
    required this.label,
    required this.sliderKey,
    required this.valueKey,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Key sliderKey;
  final Key valueKey;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  double get height => 86;

  @override
  bool represents(_HeaderDesignMenuAction? value) => false;

  @override
  State<_HeaderLiquidSoftnessMenuEntry> createState() =>
      _HeaderLiquidSoftnessMenuEntryState();
}

class _HeaderLiquidSoftnessMenuEntryState
    extends State<_HeaderLiquidSoftnessMenuEntry> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _clampUnit(widget.value);
  }

  @override
  void didUpdateWidget(_HeaderLiquidSoftnessMenuEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = _clampUnit(widget.value);
    }
  }

  void _handleChanged(double value) {
    final next = _clampUnit(value);
    setState(() => _value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF14213A),
      fontWeight: FontWeight.w700,
    );
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF64748B),
      fontWeight: FontWeight.w800,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: SizedBox(
        width: 224,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.label, style: labelStyle)),
                Text(
                  '${(_value * 100).round()}%',
                  key: widget.valueKey,
                  style: valueStyle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: const Color(0xFF06B6D4),
                inactiveTrackColor: const Color(0xFFCBD5E1),
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF06B6D4).withValues(alpha: .13),
                valueIndicatorColor: const Color(0xFF14213A),
              ),
              child: Slider(
                key: widget.sliderKey,
                value: _value,
                min: 0,
                max: 1,
                onChanged: _handleChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarLayoutConfig {
  const _AvatarLayoutConfig({
    this.centerSize = 0,
    this.innerSize = 0,
    this.outerSize = 0,
    this.innerOffset = 0,
    this.outerOffset = 0,
  });

  final double centerSize;
  final double innerSize;
  final double outerSize;
  final double innerOffset;
  final double outerOffset;

  _AvatarLayoutConfig copyWith({
    double? centerSize,
    double? innerSize,
    double? outerSize,
    double? innerOffset,
    double? outerOffset,
  }) {
    return _AvatarLayoutConfig(
      centerSize: _sliderValue(centerSize ?? this.centerSize),
      innerSize: _sliderValue(innerSize ?? this.innerSize),
      outerSize: _sliderValue(outerSize ?? this.outerSize),
      innerOffset: _sliderValue(innerOffset ?? this.innerOffset),
      outerOffset: _sliderValue(outerOffset ?? this.outerOffset),
    );
  }

  double xForLogicalOffset(double logicalOffset) {
    final sign = logicalOffset.sign;
    final distance = logicalOffset.abs();
    if (distance < .001) return 0;
    final innerDistance = _ContextAvatarBelt._slotDistance + innerOffset * 18.0;
    final outerDistance =
        _ContextAvatarBelt._slotDistance * 2 + outerOffset * 28.0;
    if (distance <= 1) return sign * _lerpDouble(0, innerDistance, distance);
    if (distance <= 2) {
      return sign * _lerpDouble(innerDistance, outerDistance, distance - 1);
    }
    return sign *
        (outerDistance + (distance - 2) * _ContextAvatarBelt._slotDistance);
  }

  double sizeForLogicalOffset(double logicalOffset) {
    final base = _budgetHeaderVisualSpec.budget.avatarSizes;
    final center = (base[2] + centerSize * 16.0).clamp(52.0, 84.0).toDouble();
    final inner = (base[1] + innerSize * 14.0).clamp(34.0, 64.0).toDouble();
    final outer = (base[0] + outerSize * 12.0).clamp(26.0, 52.0).toDouble();
    final distance = logicalOffset.abs();
    if (distance <= 1) return _lerpDouble(center, inner, distance);
    return _lerpDouble(inner, outer, (distance - 1).clamp(0.0, 1.0).toDouble());
  }

  double iconSizeForLogicalOffset(double logicalOffset) {
    final baseSizes = _budgetHeaderVisualSpec.budget.avatarSizes;
    final baseIcons = _budgetHeaderVisualSpec.budget.avatarIconSizes;
    final size = sizeForLogicalOffset(logicalOffset);
    final distance = logicalOffset.abs();
    final baseSize = distance <= 1
        ? _lerpDouble(baseSizes[2], baseSizes[1], distance)
        : _lerpDouble(
            baseSizes[1],
            baseSizes[0],
            (distance - 1).clamp(0.0, 1.0).toDouble(),
          );
    final baseIcon = distance <= 1
        ? _lerpDouble(baseIcons[2], baseIcons[1], distance)
        : _lerpDouble(
            baseIcons[1],
            baseIcons[0],
            (distance - 1).clamp(0.0, 1.0).toDouble(),
          );
    return size * (baseIcon / baseSize);
  }

  static double _sliderValue(double value) => value.clamp(-1.0, 1.0).toDouble();
}

class _AvatarLayoutMenuSheet extends StatelessWidget {
  const _AvatarLayoutMenuSheet({
    required this.config,
    required this.onChanged,
    required this.progressThickness,
    required this.onProgressThicknessChanged,
  });

  final _AvatarLayoutConfig config;
  final ValueChanged<_AvatarLayoutConfig> onChanged;
  final double progressThickness;
  final ValueChanged<double> onProgressThicknessChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('spendee-test-avatar-layout-menu'),
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              offset: const Offset(0, 16),
              blurRadius: 34,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avatar layout',
              style: TextStyle(
                color: Color(0xFF14213A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-center-size-slider',
              ),
              label: 'Középső méret',
              value: config.centerSize,
              onChanged: (value) =>
                  onChanged(config.copyWith(centerSize: value)),
            ),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-inner-size-slider',
              ),
              label: 'Belső méret',
              value: config.innerSize,
              onChanged: (value) =>
                  onChanged(config.copyWith(innerSize: value)),
            ),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-outer-size-slider',
              ),
              label: 'Külső méret',
              value: config.outerSize,
              onChanged: (value) =>
                  onChanged(config.copyWith(outerSize: value)),
            ),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-progress-thickness-slider',
              ),
              label: 'Kör vastagság',
              value: progressThickness,
              min: 0,
              max: 1,
              onChanged: onProgressThicknessChanged,
            ),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-inner-offset-slider',
              ),
              label: 'Belső X offset',
              value: config.innerOffset,
              onChanged: (value) =>
                  onChanged(config.copyWith(innerOffset: value)),
            ),
            _AvatarLayoutSlider(
              sliderKey: const ValueKey(
                'spendee-test-avatar-layout-outer-offset-slider',
              ),
              label: 'Külső X offset',
              value: config.outerOffset,
              onChanged: (value) =>
                  onChanged(config.copyWith(outerOffset: value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarLayoutSlider extends StatelessWidget {
  const _AvatarLayoutSlider({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -1,
    this.max = 1,
  });

  final Key sliderKey;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: const Color(0xFF06B6D4),
                inactiveTrackColor: const Color(0xFFCBD5E1),
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF06B6D4).withValues(alpha: .13),
                valueIndicatorColor: const Color(0xFF14213A),
              ),
              child: Slider(
                key: sliderKey,
                value: value,
                min: min,
                max: max,
                divisions: 40,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpendeeTestDashboard extends StatefulWidget {
  const SpendeeTestDashboard({
    super.key,
    required this.store,
    required this.expenseTheme,
    this.browserFullscreenController,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final BrowserFullscreenController? browserFullscreenController;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  @override
  State<SpendeeTestDashboard> createState() => _SpendeeTestDashboardState();
}

class _SpendeeTestDashboardState extends State<SpendeeTestDashboard>
    with SingleTickerProviderStateMixin {
  SpendeeHeaderStageController? _stageController;
  SpendeeHeaderStage _stage = SpendeeHeaderStage.stage0;
  var _headerHeight = 104.0;
  var _dragging = false;
  var _springBack = false;
  var _carouselLiveTicked = false;
  var _carouselVisualDx = 0.0;
  SpendeeCenterCarouselController? _carouselController;
  late final AnimationController _carouselReleaseController;
  var _carouselMotionSerial = 0;
  String? _selectedBudgetItemKey;
  String? _pulsingBudgetItemKey;
  var _stage2Page = _Stage2BudgetPage.categories;
  var _headerSurface = _HeaderSurface.normal;
  var _avatarSurface = _PanelSurface.glass;
  var _chartSurface = _PanelSurface.glass;
  var _chartListSurface = _ChartListSurface.original;
  final _avatarBodyHighlightEnabled = true;
  final _avatarBodyHighlightStrength = 1.0;
  var _avatarProgressThickness = .5;
  var _avatarLayoutConfig = const _AvatarLayoutConfig();
  var _headerLiquidSoftness = _defaultHeaderLiquidSoftness;
  var _avatarSurfaceSoftness = 0.0;
  var _chartSurfaceSoftness = 0.0;
  var _chartListSurfaceSoftness = 0.0;
  var _headerBackgroundMode = _HeaderBackgroundMode.budget;
  var _mindStage1Surface = _PanelSurface.glass;
  var _mindStage2Surface = _PanelSurface.glass;
  var _mindStage1Softness = 0.0;
  var _mindStage2Softness = 0.0;
  _MindStatsFrameCacheKey? _mindStatsFrameCacheKey;
  SpendeeMindStatsFrame? _mindStatsFrameCache;
  Stopwatch? _headerDragStopwatch;
  var _headerDragUpdateCount = 0;
  Stopwatch? _carouselDragStopwatch;
  var _carouselDragUpdateCount = 0;
  late final ValueNotifier<SpendeeHeaderStage> _stageNotifier;
  late Widget _homeContent;
  Timer? _budgetLimitVeryLongTimer;
  Timer? _budgetLimitAutoTickTimer;
  BackheaderBudgetItem? _budgetLimitEditItem;
  double? _budgetLimitEditActivationGlobalY;
  var _budgetLimitEditLastDy = 0.0;
  var _budgetLimitEditAccumulator = 0.0;
  var _budgetLimitClearedByVeryLong = false;
  final _budgetPendingLimitAmountsByKey = <String, double>{};
  final Map<FluviLogoArc, FluviLogoFill> _logoFills =
      Map<FluviLogoArc, FluviLogoFill>.of(FluviLogoSvg.defaultFills);

  @override
  void initState() {
    super.initState();
    _stageNotifier = ValueNotifier<SpendeeHeaderStage>(_stage);
    _homeContent = _buildHomeContent();
    _carouselReleaseController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant SpendeeTestDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.expenseTheme != widget.expenseTheme ||
        oldWidget.onPickSummaryMonth != widget.onPickSummaryMonth ||
        oldWidget.onEditTransaction != widget.onEditTransaction ||
        oldWidget.onDeleteTransactionRequested !=
            widget.onDeleteTransactionRequested ||
        oldWidget.onVendorSheetRequested != widget.onVendorSheetRequested ||
        oldWidget.logBottomPadding != widget.logBottomPadding) {
      _homeContent = _buildHomeContent();
    }
  }

  @override
  void dispose() {
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitAutoTickTimer?.cancel();
    _stageNotifier.dispose();
    _carouselReleaseController.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return _SpendeeHomeContent(
      key: const ValueKey('spendee-test-home-content'),
      store: widget.store,
      expenseTheme: widget.expenseTheme,
      stageListenable: _stageNotifier,
      onPickSummaryMonth: widget.onPickSummaryMonth,
      onEditTransaction: widget.onEditTransaction,
      onDeleteTransactionRequested: widget.onDeleteTransactionRequested,
      onVendorSheetRequested: widget.onVendorSheetRequested,
      logBottomPadding: widget.logBottomPadding,
    );
  }

  void _setStage(SpendeeHeaderStage stage) {
    _stage = stage;
    if (_stageNotifier.value != stage) {
      _stageNotifier.value = stage;
    }
  }

  SpendeeHeaderStageGeometry _geometryFor(BuildContext context) {
    return SpendeeHeaderStageGeometry.html(
      screenHeight: MediaQuery.sizeOf(context).height,
    );
  }

  SpendeeHeaderStageController _controllerFor(BuildContext context) {
    final geometry = _geometryFor(context);
    final existing = _stageController;
    if (existing != null) {
      existing.replaceGeometry(geometry);
      _headerHeight = existing.currentHeight;
      return existing;
    }
    final controller = SpendeeHeaderStageController(geometry: geometry);
    _stageController = controller;
    _setStage(controller.stage);
    _headerHeight = controller.currentHeight;
    return controller;
  }

  List<BackheaderBudgetItem> get _budgetItems =>
      widget.store.backheaderBudgetItems;

  BackheaderBudgetItem? _selectedBudgetItemFor(
    List<BackheaderBudgetItem> items,
  ) {
    if (items.isEmpty) return null;
    final selectedKey = _selectedBudgetItemKey ?? _defaultBudgetItemKey(items);
    if (selectedKey != null) {
      for (final item in items) {
        if (item.key == selectedKey) return item;
      }
    }
    return _firstCategoryBudgetItem(items) ?? items.first;
  }

  String? _defaultBudgetItemKey(List<BackheaderBudgetItem> items) {
    final activeCategoryId = widget.store.activeCategory?.transactionCategoryID;
    if (activeCategoryId != null) {
      for (final item in items) {
        final category = item.category?.category;
        if (category?.transactionCategoryID == activeCategoryId) {
          return item.key;
        }
      }
    }
    return _firstCategoryBudgetItem(items)?.key ?? items.first.key;
  }

  BackheaderBudgetItem? _firstCategoryBudgetItem(
    List<BackheaderBudgetItem> items,
  ) {
    for (final item in items) {
      if (item.category?.category != null) return item;
    }
    return null;
  }

  SpendeeMindStatsFrame _mindStatsFrameFor(
    TransactionStore store, {
    required String reason,
  }) {
    final key = _MindStatsFrameCacheKey.fromStore(store);
    final cachedKey = _mindStatsFrameCacheKey;
    final cachedFrame = _mindStatsFrameCache;
    if (cachedKey == key && cachedFrame != null) {
      return _mindStatsFrameWithActiveType(cachedFrame, store.activeType);
    }

    final stopwatch = Stopwatch()..start();
    final frame = SpendeeMindStatsFrame.fromStore(store, reason: reason);
    stopwatch.stop();
    _mindStatsFrameCacheKey = key;
    _mindStatsFrameCache = frame;
    DebugConsole.log(
      '[Perf] SpendeeTest MindStats cache_miss reason=$reason '
      'mode=${frame.modeKey} scope=${frame.summaryScope.name} '
      'type=${store.activeType.name} transactions=${store.transactions.length} '
      'categories=${store.categories.length} '
      'categoryFilter=${key.categoryFilterLabel} '
      'merchantFilter=${key.merchantFilterLabel} '
      'query=${store.searchQuery.isEmpty ? "-" : store.searchQuery} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    return frame;
  }

  SpendeeMindStatsFrame _mindStatsFrameWithActiveType(
    SpendeeMindStatsFrame frame,
    TransactionType activeType,
  ) {
    final activeFrame = activeType == TransactionType.income
        ? frame.incomeFrame
        : frame.expenseFrame;
    if (identical(frame.activeFrame, activeFrame)) return frame;
    return SpendeeMindStatsFrame(
      summaryScope: frame.summaryScope,
      periodLabel: frame.periodLabel,
      modeKey: frame.modeKey,
      activeFrame: activeFrame,
      expenseFrame: frame.expenseFrame,
      incomeFrame: frame.incomeFrame,
    );
  }

  void _startInteractionPerf(String interaction) {
    if (interaction == 'header_drag') {
      _headerDragUpdateCount = 0;
      _headerDragStopwatch = Stopwatch()..start();
      return;
    }
    if (interaction == 'carousel_drag') {
      _carouselDragUpdateCount = 0;
      _carouselDragStopwatch = Stopwatch()..start();
    }
  }

  void _logHeaderDragPerf({
    required SpendeeHeaderStage targetStage,
    required double targetHeight,
    required bool springBack,
  }) {
    final stopwatch = _headerDragStopwatch;
    stopwatch?.stop();
    DebugConsole.log(
      '[Perf] SpendeeTest header_drag background=${_headerBackgroundMode.name} '
      'surface=${_headerSurface.name} targetStage=${targetStage.name} '
      'updates=$_headerDragUpdateCount height=${targetHeight.toStringAsFixed(1)} '
      'springBack=$springBack elapsed=${stopwatch?.elapsedMilliseconds ?? 0}ms',
    );
    _headerDragStopwatch = null;
    _headerDragUpdateCount = 0;
  }

  void _logCarouselDragPerf(String outcome, {double? velocityDx}) {
    final stopwatch = _carouselDragStopwatch;
    stopwatch?.stop();
    DebugConsole.log(
      '[Perf] SpendeeTest carousel_drag background=${_headerBackgroundMode.name} '
      'surface=${_avatarSurface.name} outcome=$outcome '
      'updates=$_carouselDragUpdateCount '
      'selected=${_selectedBudgetItemKey ?? 'none'} '
      'residual=${_carouselVisualDx.toStringAsFixed(1)} '
      'velocity=${(velocityDx ?? 0).toStringAsFixed(1)} '
      'elapsed=${stopwatch?.elapsedMilliseconds ?? 0}ms',
    );
    _carouselDragStopwatch = null;
    _carouselDragUpdateCount = 0;
  }

  void _beginHeaderDrag(DragStartDetails details) {
    final controller = _controllerFor(context);
    controller.beginDrag();
    _startInteractionPerf('header_drag');
    setState(() {
      _dragging = true;
      _springBack = false;
    });
  }

  void _updateHeaderDrag(DragUpdateDetails details) {
    final controller = _controllerFor(context);
    final update = controller.dragBy(details.delta.dy);
    _headerDragUpdateCount += 1;
    for (var index = 0; index < update.tickCount; index++) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _headerHeight = update.height;
      _setStage(controller.stage);
    });
  }

  void _endHeaderDrag(DragEndDetails details) {
    final controller = _controllerFor(context);
    final release = controller.release();
    _logHeaderDragPerf(
      targetStage: release.targetStage,
      targetHeight: release.targetHeight,
      springBack: release.springBack,
    );
    setState(() {
      _dragging = false;
      _springBack = release.springBack;
      _setStage(release.targetStage);
      _headerHeight = release.targetHeight;
    });
  }

  void _selectCategory(
    TransactionCategory category, {
    bool haptic = true,
    bool animateCarousel = false,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    final item = _budgetItemForCategory(category);
    if (item == null) {
      if (haptic) HapticFeedback.selectionClick();
      widget.store.setCategoryFilter(category);
      return;
    }
    _selectBudgetItem(
      item,
      haptic: haptic,
      animateCarousel: animateCarousel,
      carouselMotionSource: carouselMotionSource,
      carouselStepDuration: carouselStepDuration,
    );
  }

  BackheaderBudgetItem? _budgetItemForCategory(TransactionCategory category) {
    for (final item in _budgetItems) {
      final itemCategory = item.category?.category;
      if (itemCategory?.transactionCategoryID ==
          category.transactionCategoryID) {
        return item;
      }
    }
    return null;
  }

  BackheaderBudgetItem? _overviewBudgetItemForActiveType() {
    for (final item in _budgetItems) {
      final overview = item.overview;
      if (overview != null &&
          overview.kind.transactionType ==
              widget.store.activeType.nativeValue) {
        return item;
      }
    }
    return _budgetItems.isEmpty ? null : _budgetItems.first;
  }

  void _selectOverviewBudgetItem({
    bool haptic = true,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    final item = _overviewBudgetItemForActiveType();
    if (item == null) return;
    _selectBudgetItem(
      item,
      haptic: haptic,
      animateCarousel: true,
      carouselMotionSource: carouselMotionSource,
      carouselStepDuration: carouselStepDuration,
    );
  }

  void _showStage2Page(_Stage2BudgetPage page) {
    if (_stage2Page == page) return;
    HapticFeedback.selectionClick();
    setState(() => _stage2Page = page);
  }

  void _showPreviousStage2Page() {
    _showStage2Page(
      _stage2Page == _Stage2BudgetPage.categories
          ? _Stage2BudgetPage.vendors
          : _Stage2BudgetPage.categories,
    );
  }

  void _showNextStage2Page() {
    _showStage2Page(
      _stage2Page == _Stage2BudgetPage.vendors
          ? _Stage2BudgetPage.categories
          : _Stage2BudgetPage.vendors,
    );
  }

  void _selectBudgetItem(
    BackheaderBudgetItem item, {
    bool haptic = true,
    bool animateCarousel = false,
    bool publishFilter = true,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    if (animateCarousel) {
      unawaited(
        _animateCarouselToBudgetItem(
          item,
          haptic: haptic,
          publishFilter: publishFilter,
          source: carouselMotionSource,
          stepDuration: carouselStepDuration,
        ),
      );
      return;
    }
    _applySelectedBudgetItem(
      item,
      haptic: haptic,
      publishFilter: publishFilter,
    );
  }

  void _applySelectedBudgetItem(
    BackheaderBudgetItem item, {
    bool haptic = true,
    bool publishFilter = true,
  }) {
    if (haptic) HapticFeedback.selectionClick();
    if (publishFilter) _publishBudgetItemFilter(item);
    if (!mounted) return;
    setState(() {
      _selectedBudgetItemKey = item.key;
    });
  }

  void _publishBudgetItemFilter(BackheaderBudgetItem item) {
    final category = item.category?.category;
    if (category != null) {
      final activeIds = widget.store.activeCategoryIds;
      final alreadyActive =
          widget.store.activeType == category.normalizedType &&
          activeIds.length == 1 &&
          activeIds.contains(category.transactionCategoryID) &&
          widget.store.searchQuery.isEmpty &&
          widget.store.activeMerchantFilters.isEmpty;
      if (!alreadyActive) widget.store.setCategoryFilter(category);
      return;
    }
    final alreadyOverview =
        widget.store.activeCategoryIds.isEmpty &&
        widget.store.activeMerchantFilters.isEmpty &&
        widget.store.searchQuery.isEmpty;
    if (!alreadyOverview) widget.store.clearCategoryFilter();
  }

  Future<void> _animateCarouselToBudgetItem(
    BackheaderBudgetItem item, {
    bool haptic = true,
    bool publishFilter = true,
    String source = 'avatar',
    Duration stepDuration = const Duration(milliseconds: 150),
  }) async {
    final items = _budgetItems;
    final targetIndex = items.indexWhere(
      (candidate) => candidate.key == item.key,
    );
    if (targetIndex < 0) return;
    final initialIndex = _selectedBudgetItemIndex(items);
    if (targetIndex == initialIndex) {
      _applySelectedBudgetItem(
        item,
        haptic: haptic,
        publishFilter: publishFilter,
      );
      return;
    }
    _carouselMotionSerial += 1;
    final serial = _carouselMotionSerial;
    _carouselReleaseController.stop();
    DebugConsole.log(
      '[Perf] SpendeeTest carousel_motion_start source=$source '
      'stepMs=${stepDuration.inMilliseconds} '
      'from=${items[initialIndex].key} to=${item.key}',
    );
    final controller = SpendeeCenterCarouselController(
      itemCount: items.length,
      initialIndex: initialIndex,
    );
    setState(() {
      _carouselLiveTicked = false;
      _carouselVisualDx = 0;
      _carouselController = controller;
    });
    try {
      var guard = 0;
      while (controller.index != targetIndex && guard < items.length) {
        guard += 1;
        final remaining = controller.travelToIndex(targetIndex);
        if (remaining.abs() < .5) break;
        final stepTravel = remaining
            .clamp(-controller.slotDistance, controller.slotDistance)
            .toDouble();
        await _animateCarouselTravel(
          controller: controller,
          travel: stepTravel,
          duration: stepDuration,
          curve: Curves.easeOutCubic,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        _applySelectedBudgetItem(
          item,
          haptic: false,
          publishFilter: publishFilter,
        );
        setState(() {
          _carouselVisualDx = 0;
        });
      }
    }
  }

  int _selectedBudgetItemIndex([List<BackheaderBudgetItem>? sourceItems]) {
    final items = sourceItems ?? _budgetItems;
    if (items.isEmpty) return 0;
    final selectedKey = _selectedBudgetItemFor(items)?.key;
    final index = items.indexWhere((item) => item.key == selectedKey);
    return index < 0 ? 0 : index;
  }

  void _handleCarouselDragStart(DragStartDetails details) {
    _finishBudgetLimitEdit(saveFinal: false);
    _carouselMotionSerial += 1;
    _carouselReleaseController.stop();
    _startInteractionPerf('carousel_drag');
    final items = _budgetItems;
    setState(() {
      _carouselLiveTicked = false;
      _carouselVisualDx = 0;
      _carouselController = SpendeeCenterCarouselController(
        itemCount: items.length,
        initialIndex: _selectedBudgetItemIndex(items),
      );
    });
  }

  void _handleCarouselDragUpdate(DragUpdateDetails details) {
    final items = _budgetItems;
    if (items.length < 2) return;
    _carouselDragUpdateCount += 1;
    final controller = _carouselController ??= SpendeeCenterCarouselController(
      itemCount: items.length,
      initialIndex: _selectedBudgetItemIndex(items),
    );
    final update = controller.applyDragDelta(details.delta.dx);
    BackheaderBudgetItem? latestItem;
    for (final index in update.tickedIndexes) {
      _carouselLiveTicked = true;
      latestItem = items[index % items.length];
      HapticFeedback.selectionClick();
    }
    setState(() {
      if (latestItem != null) _selectedBudgetItemKey = latestItem.key;
      _carouselVisualDx = update.residualDx;
    });
  }

  void _handleCarouselDragEnd(DragEndDetails details) {
    final items = _budgetItems;
    final controller = _carouselController;
    if (items.length < 2 || controller == null) {
      return;
    }
    _logCarouselDragPerf(
      'release',
      velocityDx: details.velocity.pixelsPerSecond.dx,
    );
    unawaited(
      _releaseCarouselBelt(
        controller: controller,
        velocityDx: details.velocity.pixelsPerSecond.dx,
        liveTicked: _carouselLiveTicked,
        serial: _carouselMotionSerial,
      ),
    );
  }

  void _handleCarouselDragCancel() {
    final controller = _carouselController;
    if (controller == null) return;
    _logCarouselDragPerf('cancel');
    unawaited(
      _cancelCarouselBelt(
        controller: controller,
        serial: _carouselMotionSerial,
      ),
    );
  }

  Future<void> _cancelCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required int serial,
  }) async {
    _carouselLiveTicked = false;
    final travel = controller.cancelTravel();
    try {
      if (travel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: travel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        setState(() => _carouselVisualDx = 0);
      }
    }
  }

  Future<void> _releaseCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required double velocityDx,
    required bool liveTicked,
    required int serial,
  }) async {
    final motion = controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: liveTicked,
    );
    _carouselLiveTicked = false;
    try {
      if (motion.initialTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: motion.initialTravel,
          duration: motion.initialDuration,
          curve: motion.inertial ? Curves.easeOutQuad : Curves.easeOutCubic,
        );
      }
      if (!mounted || serial != _carouselMotionSerial) return;
      final settleTravel = controller.settleTravel(
        preferredDxDirection: motion.preferredDxDirection,
        allowDirectionalSnap: motion.directionalSnapAllowed,
      );
      if (settleTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: settleTravel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        final item = _selectedBudgetItemFor(_budgetItems);
        if (item != null) _publishBudgetItemFilter(item);
        setState(() {
          _carouselVisualDx = 0;
        });
      }
    }
  }

  Future<void> _animateCarouselTravel({
    required SpendeeCenterCarouselController controller,
    required double travel,
    required Duration duration,
    required Curve curve,
  }) async {
    _carouselReleaseController.stop();
    _carouselReleaseController.duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(begin: 0, end: travel).animate(
      CurvedAnimation(parent: _carouselReleaseController, curve: curve),
    );
    void applyFrame() {
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta == 0 || !mounted) return;
      _applyCarouselMotionDelta(controller, delta);
    }

    animation.addListener(applyFrame);
    try {
      await _carouselReleaseController.forward(from: 0).orCancel;
    } finally {
      animation.removeListener(applyFrame);
    }
  }

  void _applyCarouselMotionDelta(
    SpendeeCenterCarouselController controller,
    double deltaDx,
  ) {
    final items = _budgetItems;
    if (items.length < 2) return;
    final update = controller.applyDragDelta(deltaDx);
    BackheaderBudgetItem? latestItem;
    for (final index in update.tickedIndexes) {
      latestItem = items[index % items.length];
      HapticFeedback.selectionClick();
      DebugConsole.log(
        '[Perf] SpendeeTest carousel_tick source=motion '
        'selected=${latestItem.key}',
      );
    }
    setState(() {
      if (latestItem != null) _selectedBudgetItemKey = latestItem.key;
      _carouselVisualDx = update.residualDx;
    });
  }

  void _openLogoEditor() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LogoEditorSheet(
          fills: _logoFills,
          onFillChanged: (arc, fill) {
            setState(() {
              _logoFills[arc] = fill;
            });
          },
        );
      },
    );
  }

  Future<void> _openHeaderDesignMenu(BuildContext menuContext) async {
    HapticFeedback.selectionClick();
    final action = await showMenu<_HeaderDesignMenuAction>(
      context: menuContext,
      position: _headerDesignMenuPosition(menuContext),
      color: Colors.white.withValues(alpha: .94),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 14,
      items: [
        const PopupMenuItem<_HeaderDesignMenuAction>(
          key: ValueKey('spendee-test-header-design-menu'),
          enabled: false,
          height: 34,
          child: Text(
            'Header design',
            style: TextStyle(
              color: Color(0xFF14213A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Header background'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-background-budget'),
          value: _HeaderDesignMenuAction.headerBackgroundBudget,
          checked: _headerBackgroundMode == _HeaderBackgroundMode.budget,
          height: 38,
          child: const Text('Background: Budget'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-background-mind'),
          value: _HeaderDesignMenuAction.headerBackgroundMind,
          checked: _headerBackgroundMode == _HeaderBackgroundMode.mind,
          height: 38,
          child: const Text('Background: Mind'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Header'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-surface-normal'),
          value: _HeaderDesignMenuAction.headerNormal,
          checked: _headerSurface == _HeaderSurface.normal,
          height: 38,
          child: const Text('Header: normál'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.headerHtmlC2Glass,
          checked: _headerSurface == _HeaderSurface.htmlC2Glass,
          height: 38,
          child: const Text('Header: C2 design'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.headerLiquidGlass,
          checked: _headerSurface == _HeaderSurface.liquidGlass,
          height: 38,
          child: const Text('Header: liquid glass'),
        ),
        if (_headerSurface == _HeaderSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-header-liquid-softness-entry'),
            label: 'Header liquid lágyság',
            sliderKey: const ValueKey(
              'spendee-test-header-liquid-softness-slider',
            ),
            valueKey: const ValueKey(
              'spendee-test-header-liquid-softness-value',
            ),
            value: _headerLiquidSoftness,
            onChanged: _setHeaderLiquidSoftness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-header-surface-acrylic'),
          value: _HeaderDesignMenuAction.headerAcrylic,
          checked: _headerSurface == _HeaderSurface.acrylic,
          height: 38,
          child: const Text('Header: Acrylic'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Avatarok'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-avatar-surface-background'),
          value: _HeaderDesignMenuAction.avatarsBackground,
          checked: _avatarSurface == _PanelSurface.background,
          height: 38,
          child: const Text('Avatarok: nincs háttér'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-avatar-surface-glass'),
          value: _HeaderDesignMenuAction.avatarsGlass,
          checked: _avatarSurface == _PanelSurface.glass,
          height: 38,
          child: const Text('Avatarok: régi glass'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-avatar-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.avatarsHtmlC2Glass,
          checked: _avatarSurface == _PanelSurface.htmlC2Glass,
          height: 38,
          child: const Text('Avatarok: HTML C2 glass'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-avatar-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.avatarsLiquidGlass,
          checked: _avatarSurface == _PanelSurface.liquidGlass,
          height: 38,
          child: const Text('Avatarok: liquid glass'),
        ),
        if (_avatarSurface == _PanelSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-avatar-surface-softness-entry'),
            label: 'Avatar liquid lágyság',
            sliderKey: const ValueKey(
              'spendee-test-avatar-surface-softness-slider',
            ),
            valueKey: const ValueKey(
              'spendee-test-avatar-surface-softness-value',
            ),
            value: _avatarSurfaceSoftness,
            onChanged: _setAvatarSurfaceSoftness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-avatar-surface-acrylic'),
          value: _HeaderDesignMenuAction.avatarsAcrylic,
          checked: _avatarSurface == _PanelSurface.acrylic,
          height: 38,
          child: const Text('Avatarok: Acrylic'),
        ),
        _HeaderLiquidSoftnessMenuEntry(
          key: const ValueKey('spendee-test-avatar-progress-thickness-entry'),
          label: 'Circle progress vastagság',
          sliderKey: const ValueKey(
            'spendee-test-avatar-progress-thickness-slider',
          ),
          valueKey: const ValueKey(
            'spendee-test-avatar-progress-thickness-value',
          ),
          value: _avatarProgressThickness,
          onChanged: _setAvatarProgressThickness,
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Diagram'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-surface-glass'),
          value: _HeaderDesignMenuAction.chartGlass,
          checked: _chartSurface == _PanelSurface.glass,
          height: 38,
          child: const Text('Chart: üvegkonténer'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-surface-background'),
          value: _HeaderDesignMenuAction.chartBackground,
          checked: _chartSurface == _PanelSurface.background,
          height: 38,
          child: const Text('Chart: háttér'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.chartHtmlC2Glass,
          checked: _chartSurface == _PanelSurface.htmlC2Glass,
          height: 38,
          child: const Text('Chart: HTML C2 glass'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.chartLiquidGlass,
          checked: _chartSurface == _PanelSurface.liquidGlass,
          height: 38,
          child: const Text('Chart: liquid glass'),
        ),
        if (_chartSurface == _PanelSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-chart-surface-softness-entry'),
            label: 'Chart liquid lágyság',
            sliderKey: const ValueKey(
              'spendee-test-chart-surface-softness-slider',
            ),
            valueKey: const ValueKey(
              'spendee-test-chart-surface-softness-value',
            ),
            value: _chartSurfaceSoftness,
            onChanged: _setChartSurfaceSoftness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-surface-acrylic'),
          value: _HeaderDesignMenuAction.chartAcrylic,
          checked: _chartSurface == _PanelSurface.acrylic,
          height: 38,
          child: const Text('Chart: Acrylic'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Chart lista mode'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-list-surface-none'),
          value: _HeaderDesignMenuAction.chartListNone,
          checked: _chartListSurface == _ChartListSurface.none,
          height: 38,
          child: const Text('Lista: nincs pill'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-list-surface-original'),
          value: _HeaderDesignMenuAction.chartListOriginal,
          checked: _chartListSurface == _ChartListSurface.original,
          height: 38,
          child: const Text('Lista: eredeti'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-list-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.chartListHtmlC2Glass,
          checked: _chartListSurface == _ChartListSurface.htmlC2Glass,
          height: 38,
          child: const Text('Lista: C2 CSS'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-list-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.chartListLiquidGlass,
          checked: _chartListSurface == _ChartListSurface.liquidGlass,
          height: 38,
          child: const Text('Lista: liquid'),
        ),
        if (_chartListSurface == _ChartListSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-chart-list-softness-entry'),
            label: 'Lista liquid lágyság',
            sliderKey: const ValueKey(
              'spendee-test-chart-list-softness-slider',
            ),
            valueKey: const ValueKey('spendee-test-chart-list-softness-value'),
            value: _chartListSurfaceSoftness,
            onChanged: _setChartListSurfaceSoftness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-chart-list-surface-acrylic'),
          value: _HeaderDesignMenuAction.chartListAcrylic,
          checked: _chartListSurface == _ChartListSurface.acrylic,
          height: 38,
          child: const Text('Lista: Acrylic'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Mind stage1 container'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage1-surface-background'),
          value: _HeaderDesignMenuAction.mindStage1Background,
          checked: _mindStage1Surface == _PanelSurface.background,
          height: 38,
          child: const Text('Mind S1: nincs container'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage1-surface-glass'),
          value: _HeaderDesignMenuAction.mindStage1Glass,
          checked: _mindStage1Surface == _PanelSurface.glass,
          height: 38,
          child: const Text('Mind S1: régi glass'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage1-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.mindStage1HtmlC2Glass,
          checked: _mindStage1Surface == _PanelSurface.htmlC2Glass,
          height: 38,
          child: const Text('Mind S1: C2 CSS'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage1-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.mindStage1LiquidGlass,
          checked: _mindStage1Surface == _PanelSurface.liquidGlass,
          height: 38,
          child: const Text('Mind S1: liquid'),
        ),
        if (_mindStage1Surface == _PanelSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-mind-stage1-softness-entry'),
            label: 'Mind stage1 lágyság',
            sliderKey: const ValueKey(
              'spendee-test-mind-stage1-softness-slider',
            ),
            valueKey: const ValueKey('spendee-test-mind-stage1-softness-value'),
            value: _mindStage1Softness,
            onChanged: _setMindStage1Softness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage1-surface-acrylic'),
          value: _HeaderDesignMenuAction.mindStage1Acrylic,
          checked: _mindStage1Surface == _PanelSurface.acrylic,
          height: 38,
          child: const Text('Mind S1: Acrylic'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_HeaderDesignMenuAction>(
          enabled: false,
          height: 28,
          child: Text('Mind stage2 container'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage2-surface-background'),
          value: _HeaderDesignMenuAction.mindStage2Background,
          checked: _mindStage2Surface == _PanelSurface.background,
          height: 38,
          child: const Text('Mind S2: nincs container'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage2-surface-glass'),
          value: _HeaderDesignMenuAction.mindStage2Glass,
          checked: _mindStage2Surface == _PanelSurface.glass,
          height: 38,
          child: const Text('Mind S2: régi glass'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage2-surface-html-c2-glass'),
          value: _HeaderDesignMenuAction.mindStage2HtmlC2Glass,
          checked: _mindStage2Surface == _PanelSurface.htmlC2Glass,
          height: 38,
          child: const Text('Mind S2: C2 CSS'),
        ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage2-surface-liquid-glass'),
          value: _HeaderDesignMenuAction.mindStage2LiquidGlass,
          checked: _mindStage2Surface == _PanelSurface.liquidGlass,
          height: 38,
          child: const Text('Mind S2: liquid'),
        ),
        if (_mindStage2Surface == _PanelSurface.liquidGlass)
          _HeaderLiquidSoftnessMenuEntry(
            key: const ValueKey('spendee-test-mind-stage2-softness-entry'),
            label: 'Mind stage2 lágyság',
            sliderKey: const ValueKey(
              'spendee-test-mind-stage2-softness-slider',
            ),
            valueKey: const ValueKey('spendee-test-mind-stage2-softness-value'),
            value: _mindStage2Softness,
            onChanged: _setMindStage2Softness,
          ),
        CheckedPopupMenuItem<_HeaderDesignMenuAction>(
          key: const ValueKey('spendee-test-mind-stage2-surface-acrylic'),
          value: _HeaderDesignMenuAction.mindStage2Acrylic,
          checked: _mindStage2Surface == _PanelSurface.acrylic,
          height: 38,
          child: const Text('Mind S2: Acrylic'),
        ),
      ],
    );
    if (action == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      switch (action) {
        case _HeaderDesignMenuAction.headerBackgroundBudget:
          _headerBackgroundMode = _HeaderBackgroundMode.budget;
        case _HeaderDesignMenuAction.headerBackgroundMind:
          _headerBackgroundMode = _HeaderBackgroundMode.mind;
        case _HeaderDesignMenuAction.headerNormal:
          _headerSurface = _HeaderSurface.normal;
        case _HeaderDesignMenuAction.headerHtmlC2Glass:
          _headerSurface = _HeaderSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.headerLiquidGlass:
          _headerSurface = _HeaderSurface.liquidGlass;
        case _HeaderDesignMenuAction.headerAcrylic:
          _headerSurface = _HeaderSurface.acrylic;
        case _HeaderDesignMenuAction.avatarsBackground:
          _avatarSurface = _PanelSurface.background;
        case _HeaderDesignMenuAction.avatarsGlass:
          _avatarSurface = _PanelSurface.glass;
        case _HeaderDesignMenuAction.avatarsHtmlC2Glass:
          _avatarSurface = _PanelSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.avatarsLiquidGlass:
          _avatarSurface = _PanelSurface.liquidGlass;
        case _HeaderDesignMenuAction.avatarsAcrylic:
          _avatarSurface = _PanelSurface.acrylic;
        case _HeaderDesignMenuAction.chartGlass:
          _chartSurface = _PanelSurface.glass;
        case _HeaderDesignMenuAction.chartBackground:
          _chartSurface = _PanelSurface.background;
        case _HeaderDesignMenuAction.chartHtmlC2Glass:
          _chartSurface = _PanelSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.chartLiquidGlass:
          _chartSurface = _PanelSurface.liquidGlass;
        case _HeaderDesignMenuAction.chartAcrylic:
          _chartSurface = _PanelSurface.acrylic;
        case _HeaderDesignMenuAction.chartListNone:
          _chartListSurface = _ChartListSurface.none;
        case _HeaderDesignMenuAction.chartListOriginal:
          _chartListSurface = _ChartListSurface.original;
        case _HeaderDesignMenuAction.chartListHtmlC2Glass:
          _chartListSurface = _ChartListSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.chartListLiquidGlass:
          _chartListSurface = _ChartListSurface.liquidGlass;
        case _HeaderDesignMenuAction.chartListAcrylic:
          _chartListSurface = _ChartListSurface.acrylic;
        case _HeaderDesignMenuAction.mindStage1Background:
          _mindStage1Surface = _PanelSurface.background;
        case _HeaderDesignMenuAction.mindStage1Glass:
          _mindStage1Surface = _PanelSurface.glass;
        case _HeaderDesignMenuAction.mindStage1HtmlC2Glass:
          _mindStage1Surface = _PanelSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.mindStage1LiquidGlass:
          _mindStage1Surface = _PanelSurface.liquidGlass;
        case _HeaderDesignMenuAction.mindStage1Acrylic:
          _mindStage1Surface = _PanelSurface.acrylic;
        case _HeaderDesignMenuAction.mindStage2Background:
          _mindStage2Surface = _PanelSurface.background;
        case _HeaderDesignMenuAction.mindStage2Glass:
          _mindStage2Surface = _PanelSurface.glass;
        case _HeaderDesignMenuAction.mindStage2HtmlC2Glass:
          _mindStage2Surface = _PanelSurface.htmlC2Glass;
        case _HeaderDesignMenuAction.mindStage2LiquidGlass:
          _mindStage2Surface = _PanelSurface.liquidGlass;
        case _HeaderDesignMenuAction.mindStage2Acrylic:
          _mindStage2Surface = _PanelSurface.acrylic;
      }
    });
  }

  Future<void> _openAvatarLayoutMenu() async {
    HapticFeedback.selectionClick();
    var sheetConfig = _avatarLayoutConfig;
    var sheetProgressThickness = _avatarProgressThickness;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(_AvatarLayoutConfig next) {
              setSheetState(() => sheetConfig = next);
              if (!mounted) return;
              setState(() => _avatarLayoutConfig = next);
            }

            void updateProgressThickness(double next) {
              final clamped = _clampUnit(next);
              setSheetState(() => sheetProgressThickness = clamped);
              if (!mounted) return;
              setState(() => _avatarProgressThickness = clamped);
            }

            return _AvatarLayoutMenuSheet(
              config: sheetConfig,
              onChanged: update,
              progressThickness: sheetProgressThickness,
              onProgressThicknessChanged: updateProgressThickness,
            );
          },
        );
      },
    );
  }

  void _setHeaderLiquidSoftness(double value) {
    final next = _clampUnit(value);
    if ((_headerLiquidSoftness - next).abs() < .001) return;
    setState(() => _headerLiquidSoftness = next);
  }

  void _setAvatarSurfaceSoftness(double value) {
    final next = _clampUnit(value);
    if ((_avatarSurfaceSoftness - next).abs() < .001) return;
    setState(() => _avatarSurfaceSoftness = next);
  }

  void _setAvatarProgressThickness(double value) {
    final next = _clampUnit(value);
    if ((_avatarProgressThickness - next).abs() < .001) return;
    setState(() => _avatarProgressThickness = next);
  }

  void _setChartSurfaceSoftness(double value) {
    final next = _clampUnit(value);
    if ((_chartSurfaceSoftness - next).abs() < .001) return;
    setState(() => _chartSurfaceSoftness = next);
  }

  void _setChartListSurfaceSoftness(double value) {
    final next = _clampUnit(value);
    if ((_chartListSurfaceSoftness - next).abs() < .001) return;
    setState(() => _chartListSurfaceSoftness = next);
  }

  void _setMindStage1Softness(double value) {
    final next = _clampUnit(value);
    if ((_mindStage1Softness - next).abs() < .001) return;
    setState(() => _mindStage1Softness = next);
  }

  void _setMindStage2Softness(double value) {
    final next = _clampUnit(value);
    if ((_mindStage2Softness - next).abs() < .001) return;
    setState(() => _mindStage2Softness = next);
  }

  List<CategoryBudgetBarData> _previewBudgetBars(
    List<CategoryBudgetBarData> bars,
  ) {
    return [
      for (final bar in bars)
        _budgetPendingLimitAmountsByKey.containsKey(bar.key)
            ? _previewBudgetBar(
                bar,
                _budgetPendingLimitAmountsByKey[bar.key] ?? 0,
              )
            : bar,
    ];
  }

  CategoryBudgetBarData _previewBudgetBar(
    CategoryBudgetBarData bar,
    double amount,
  ) {
    final normalized = math.max(0.0, amount).toDouble();
    final hasLimit = normalized > 0;
    return CategoryBudgetBarData(
      key: bar.key,
      targetType: bar.targetType,
      targetId: bar.targetId,
      transactionType: bar.transactionType,
      window: bar.window,
      periodKey: bar.periodKey,
      title: bar.title,
      spent: bar.spent,
      hasLimit: hasLimit,
      limitAmount: hasLimit ? normalized : 0,
      alertActive: hasLimit,
      color: bar.color,
      iconSlot: bar.iconSlot,
      category: bar.category,
      sourceLimit: bar.sourceLimit,
    );
  }

  List<OverviewBudgetData> _previewOverviewBudgetItems(
    List<OverviewBudgetData> items,
  ) {
    return [
      for (final item in items)
        _budgetPendingLimitAmountsByKey.containsKey(item.key)
            ? _previewOverviewBudgetItem(
                item,
                _budgetPendingLimitAmountsByKey[item.key] ?? 0,
              )
            : item,
    ];
  }

  OverviewBudgetData _previewOverviewBudgetItem(
    OverviewBudgetData item,
    double amount,
  ) {
    final normalized = math.max(0.0, amount).toDouble();
    final hasLimit = normalized > 0;
    return OverviewBudgetData(
      kind: item.kind,
      window: item.window,
      periodKey: item.periodKey,
      amount: item.amount,
      hasLimit: hasLimit,
      limitAmount: hasLimit ? normalized : 0,
      alertActive: hasLimit,
      sourceLimit: item.sourceLimit,
    );
  }

  List<BackheaderBudgetItem> _previewBudgetItems({
    required List<OverviewBudgetData> overviewItems,
    required List<CategoryBudgetBarData> bars,
  }) {
    return [
      for (final overview in overviewItems)
        BackheaderBudgetItem.overview(overview),
      for (final bar in bars) BackheaderBudgetItem.category(bar),
    ];
  }

  double _budgetItemLimitAmount(BackheaderBudgetItem item) {
    final pending = _budgetPendingLimitAmountsByKey[item.key];
    if (pending != null) return pending;
    final overview = item.overview;
    if (overview != null) return overview.hasLimit ? overview.limitAmount : 0;
    final category = item.category;
    if (category != null) return category.hasLimit ? category.limitAmount : 0;
    return 0;
  }

  void _handleBudgetItemLongPressStart(
    BackheaderBudgetItem item,
    LongPressStartDetails details,
  ) {
    _carouselReleaseController.stop();
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitEditItem = item;
    _budgetLimitEditActivationGlobalY = details.globalPosition.dy;
    _budgetLimitEditLastDy = 0;
    _budgetLimitEditAccumulator = 0;
    _budgetLimitClearedByVeryLong = false;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    if (mounted) setState(() {});
    HapticFeedback.mediumImpact();
    _budgetLimitVeryLongTimer = Timer(const Duration(milliseconds: 720), () {
      if (!mounted || _budgetLimitEditItem?.key != item.key) return;
      if (_budgetLimitEditLastDy.abs() > 5) return;
      _budgetLimitClearedByVeryLong = true;
      _budgetLimitAutoTickTimer?.cancel();
      _budgetLimitAutoTickTimer = null;
      HapticFeedback.heavyImpact();
      DebugConsole.log(
        '[Perf] SpendeeTest budget_limit_clear key=${item.key} '
        'strength=strong',
      );
      _setBudgetItemLimitAmount(item, 0, notifyStore: true);
    });
  }

  void _handleBudgetItemLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
  ) {
    final item = _budgetLimitEditItem;
    final activationY = _budgetLimitEditActivationGlobalY;
    if (item == null || activationY == null) return;
    final dy = details.globalPosition.dy - activationY;
    final delta = dy - _budgetLimitEditLastDy;
    _budgetLimitEditLastDy = dy;
    if (dy.abs() > 5) _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitEditAccumulator += -delta;
    _drainBudgetLimitTicks(item, dy.abs());
    _scheduleBudgetLimitAutoTick(item);
  }

  void _drainBudgetLimitTicks(BackheaderBudgetItem item, double distance) {
    final largeStep = distance >= 50;
    final tickDistance = largeStep ? 18.0 : 12.0;
    final amountStep = largeStep ? 10000.0 : 1000.0;
    while (_budgetLimitEditAccumulator.abs() >= tickDistance) {
      final direction = _budgetLimitEditAccumulator > 0 ? 1 : -1;
      _budgetLimitEditAccumulator -= direction * tickDistance;
      _applyBudgetLimitTick(
        item,
        direction: direction,
        amountStep: amountStep,
        source: 'drag',
      );
    }
  }

  void _scheduleBudgetLimitAutoTick(BackheaderBudgetItem item) {
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    if (_budgetLimitEditItem?.key != item.key) return;
    final distance = _budgetLimitEditLastDy.abs();
    if (distance < 14) return;
    final intervalMs = (440 - distance * 5.2).clamp(80.0, 440.0).round();
    _budgetLimitAutoTickTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (!mounted || _budgetLimitEditItem?.key != item.key) return;
      final direction = _budgetLimitEditLastDy < 0 ? 1 : -1;
      final amountStep = _budgetLimitEditLastDy.abs() >= 50 ? 10000.0 : 1000.0;
      _applyBudgetLimitTick(
        item,
        direction: direction,
        amountStep: amountStep,
        source: 'auto',
      );
      _scheduleBudgetLimitAutoTick(item);
    });
  }

  void _applyBudgetLimitTick(
    BackheaderBudgetItem item, {
    required int direction,
    required double amountStep,
    required String source,
  }) {
    final next = math
        .max(0.0, _budgetItemLimitAmount(item) + direction * amountStep)
        .toDouble();
    _setBudgetItemLimitAmount(item, next);
    HapticFeedback.selectionClick();
    DebugConsole.log(
      '[Perf] SpendeeTest budget_limit_tick key=${item.key} '
      'direction=$direction step=${amountStep.round()} '
      'amount=${next.round()} source=$source',
    );
  }

  void _finishBudgetLimitEdit({bool saveFinal = true}) {
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitVeryLongTimer = null;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    final item = _budgetLimitEditItem;
    if (saveFinal && item != null && !_budgetLimitClearedByVeryLong) {
      unawaited(_saveBudgetItemLimit(item, _budgetItemLimitAmount(item)));
    }
    _budgetLimitEditItem = null;
    _budgetLimitEditActivationGlobalY = null;
    _budgetLimitEditLastDy = 0;
    _budgetLimitEditAccumulator = 0;
    _budgetLimitClearedByVeryLong = false;
    if (mounted) setState(() {});
  }

  void _setBudgetItemLimitAmount(
    BackheaderBudgetItem item,
    double amount, {
    bool notifyStore = false,
  }) {
    final normalized = amount <= 0 ? 0.0 : (amount / 1000).round() * 1000.0;
    setState(() {
      _budgetPendingLimitAmountsByKey[item.key] = normalized;
    });
    unawaited(_saveBudgetItemLimit(item, normalized, notifyStore: notifyStore));
  }

  Future<void> _saveBudgetItemLimit(
    BackheaderBudgetItem item,
    double amount, {
    bool notifyStore = true,
  }) async {
    final normalized = math.max(0.0, amount).toDouble();
    final overview = item.overview;
    final category = item.category;
    try {
      if (overview != null) {
        await widget.store.saveOverviewLimitInline(
          overview.kind,
          limitAmount: normalized,
          alertActive: normalized > 0,
          notify: notifyStore,
        );
      } else if (category != null) {
        await widget.store.saveCategoryLimitForBarInline(
          category,
          limitAmount: normalized,
          alertActive: normalized > 0,
          notify: notifyStore,
        );
      }
    } catch (error) {
      DebugConsole.log(
        '[Perf] SpendeeTest budget_limit_save_error key=${item.key} '
        'amount=${normalized.round()} error=$error',
      );
    }
  }

  RelativeRect _headerDesignMenuPosition(BuildContext menuContext) {
    final button = menuContext.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(menuContext).context.findRenderObject()! as RenderBox;
    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    return RelativeRect.fromRect(
      Rect.fromLTRB(
        buttonTopLeft.dx,
        buttonBottomRight.dy + 6,
        buttonBottomRight.dx,
        buttonBottomRight.dy + 6,
      ),
      Offset.zero & overlay.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controllerFor(context);
    final geometry = controller.geometry;
    final budgetBars = _previewBudgetBars(widget.store.categoryBudgetBars);
    final overviewBudgetItems = _previewOverviewBudgetItems(
      widget.store.overviewBudgetItems,
    );
    final budgetItems = _previewBudgetItems(
      overviewItems: overviewBudgetItems,
      bars: budgetBars,
    );
    final selectedBudgetItem = _selectedBudgetItemFor(budgetItems);
    final selectedBar = selectedBudgetItem?.category;
    final selectedCategory = selectedBar?.category;
    var overviewBudgetLimit = 0.0;
    for (final item in overviewBudgetItems) {
      if (item.hasLimit && item.limitAmount > 0) {
        overviewBudgetLimit = item.limitAmount;
        break;
      }
    }
    final contentTop = geometry.headerTop + _headerHeight + geometry.contentGap;
    final animationDuration = _dragging
        ? Duration.zero
        : const Duration(milliseconds: 360);
    final animationCurve = _springBack
        ? Curves.elasticOut
        : Curves.easeOutCubic;

    final isMindBackground =
        _headerBackgroundMode == _HeaderBackgroundMode.mind;
    final mindStatsFrame = isMindBackground
        ? _mindStatsFrameFor(widget.store, reason: 'header-background-mind')
        : null;

    return ColoredBox(
      key: ValueKey('spendee-test-dashboard-stage-${_stage.name}'),
      color: const Color(0xFFF1F5F9),
      child: Stack(
        key: const ValueKey('spendee-test-dashboard'),
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: animationDuration,
            curve: animationCurve,
            top: contentTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: _homeContent,
          ),
          Positioned(
            left: 20,
            right: 20,
            top: geometry.headerTop,
            child: AnimatedContainer(
              key: const ValueKey('spendee-test-header-card'),
              duration: animationDuration,
              curve: animationCurve,
              height: _headerHeight,
              child: RepaintBoundary(
                key: const ValueKey('spendee-test-header-golden-boundary'),
                child: _SpendeeBudgetHeaderCard(
                  stage: _stage,
                  selectedBudgetItem: selectedBudgetItem,
                  selectedCategory: selectedCategory,
                  bars: budgetBars,
                  transactions: widget.store.windowedTransactions,
                  budgetLimitAmount: overviewBudgetLimit,
                  budgetItems: budgetItems,
                  stage2Page: _stage2Page,
                  headerBackgroundMode: _headerBackgroundMode,
                  mindStatsFrame: mindStatsFrame,
                  onHandleDragStart: _beginHeaderDrag,
                  onHandleDragUpdate: _updateHeaderDrag,
                  onHandleDragEnd: _endHeaderDrag,
                  onBudgetItemTap: (item) =>
                      _selectBudgetItem(item, animateCarousel: true),
                  onPieCategoryTap: (category) => _selectCategory(
                    category,
                    animateCarousel: true,
                    carouselMotionSource: 'diagram',
                    carouselStepDuration: const Duration(milliseconds: 72),
                  ),
                  onPieCenterTap: () => _selectOverviewBudgetItem(
                    carouselMotionSource: 'diagram',
                    carouselStepDuration: const Duration(milliseconds: 72),
                  ),
                  onStage2PreviousPage: _showPreviousStage2Page,
                  onStage2NextPage: _showNextStage2Page,
                  pulsingBudgetItemKey: _pulsingBudgetItemKey,
                  carouselOffset: _carouselVisualDx,
                  pressedBudgetItemKey: _budgetLimitEditItem?.key,
                  avatarBodyHighlightEnabled: _avatarBodyHighlightEnabled,
                  avatarBodyHighlightStrength: _avatarBodyHighlightStrength,
                  avatarProgressThickness: _avatarProgressThickness,
                  avatarLayoutConfig: _avatarLayoutConfig,
                  onBudgetItemLongPressStart: _handleBudgetItemLongPressStart,
                  onBudgetItemLongPressMoveUpdate:
                      _handleBudgetItemLongPressMoveUpdate,
                  onBudgetItemLongPressEnd: (_) => _finishBudgetLimitEdit(),
                  onBudgetItemLongPressCancel: _finishBudgetLimitEdit,
                  headerSurface: _headerSurface,
                  avatarSurface: _avatarSurface,
                  chartSurface: _chartSurface,
                  chartListSurface: _chartListSurface,
                  headerLiquidSoftness: _headerLiquidSoftness,
                  avatarSurfaceSoftness: _avatarSurfaceSoftness,
                  chartSurfaceSoftness: _chartSurfaceSoftness,
                  chartListSurfaceSoftness: _chartListSurfaceSoftness,
                  mindStage1Surface: _mindStage1Surface,
                  mindStage2Surface: _mindStage2Surface,
                  mindStage1Softness: _mindStage1Softness,
                  mindStage2Softness: _mindStage2Softness,
                  onHeaderDesignMenuPressed: _openHeaderDesignMenu,
                  onHeaderBackgroundTap: _openAvatarLayoutMenu,
                  onCarouselDragStart: _handleCarouselDragStart,
                  onCarouselDragUpdate: _handleCarouselDragUpdate,
                  onCarouselDragEnd: _handleCarouselDragEnd,
                  onCarouselDragCancel: _handleCarouselDragCancel,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 33.3,
            height: 118,
            child: _SpendeeBrandLockup(
              key: const ValueKey('spendee-test-brand-lockup'),
              logoFills: _logoFills,
              onLogoTap: _openLogoEditor,
            ),
          ),
          if (widget.browserFullscreenController case final controller?)
            Positioned(
              top: 48,
              right: 20,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  if (!controller.isAvailable) {
                    return const SizedBox.shrink();
                  }
                  return _AppCornerFullscreenButton(
                    fullscreen: controller.isFullscreen,
                    requestPending: controller.requestPending,
                    onPressed: () => unawaited(controller.toggle()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SpendeeBudgetHeaderCard extends StatelessWidget {
  const _SpendeeBudgetHeaderCard({
    required this.stage,
    required this.selectedBudgetItem,
    required this.selectedCategory,
    required this.bars,
    required this.transactions,
    required this.budgetLimitAmount,
    required this.budgetItems,
    required this.stage2Page,
    required this.headerBackgroundMode,
    required this.mindStatsFrame,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
    required this.onBudgetItemTap,
    required this.onPieCategoryTap,
    required this.onPieCenterTap,
    required this.onStage2PreviousPage,
    required this.onStage2NextPage,
    required this.pulsingBudgetItemKey,
    required this.carouselOffset,
    required this.pressedBudgetItemKey,
    required this.avatarBodyHighlightEnabled,
    required this.avatarBodyHighlightStrength,
    required this.avatarProgressThickness,
    required this.avatarLayoutConfig,
    required this.onBudgetItemLongPressStart,
    required this.onBudgetItemLongPressMoveUpdate,
    required this.onBudgetItemLongPressEnd,
    required this.onBudgetItemLongPressCancel,
    required this.headerSurface,
    required this.avatarSurface,
    required this.chartSurface,
    required this.chartListSurface,
    required this.headerLiquidSoftness,
    required this.avatarSurfaceSoftness,
    required this.chartSurfaceSoftness,
    required this.chartListSurfaceSoftness,
    required this.mindStage1Surface,
    required this.mindStage2Surface,
    required this.mindStage1Softness,
    required this.mindStage2Softness,
    required this.onHeaderDesignMenuPressed,
    required this.onHeaderBackgroundTap,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
    required this.onCarouselDragCancel,
  });

  final SpendeeHeaderStage stage;
  final BackheaderBudgetItem? selectedBudgetItem;
  final TransactionCategory? selectedCategory;
  final List<CategoryBudgetBarData> bars;
  final List<TransactionRecord> transactions;
  final double budgetLimitAmount;
  final List<BackheaderBudgetItem> budgetItems;
  final _Stage2BudgetPage stage2Page;
  final _HeaderBackgroundMode headerBackgroundMode;
  final SpendeeMindStatsFrame? mindStatsFrame;
  final GestureDragStartCallback onHandleDragStart;
  final GestureDragUpdateCallback onHandleDragUpdate;
  final GestureDragEndCallback onHandleDragEnd;
  final ValueChanged<BackheaderBudgetItem> onBudgetItemTap;
  final ValueChanged<TransactionCategory> onPieCategoryTap;
  final VoidCallback onPieCenterTap;
  final VoidCallback onStage2PreviousPage;
  final VoidCallback onStage2NextPage;
  final String? pulsingBudgetItemKey;
  final double carouselOffset;
  final String? pressedBudgetItemKey;
  final bool avatarBodyHighlightEnabled;
  final double avatarBodyHighlightStrength;
  final double avatarProgressThickness;
  final _AvatarLayoutConfig avatarLayoutConfig;
  final void Function(BackheaderBudgetItem, LongPressStartDetails)
  onBudgetItemLongPressStart;
  final GestureLongPressMoveUpdateCallback onBudgetItemLongPressMoveUpdate;
  final GestureLongPressEndCallback onBudgetItemLongPressEnd;
  final GestureLongPressCancelCallback onBudgetItemLongPressCancel;
  final _HeaderSurface headerSurface;
  final _PanelSurface avatarSurface;
  final _PanelSurface chartSurface;
  final _ChartListSurface chartListSurface;
  final double headerLiquidSoftness;
  final double avatarSurfaceSoftness;
  final double chartSurfaceSoftness;
  final double chartListSurfaceSoftness;
  final _PanelSurface mindStage1Surface;
  final _PanelSurface mindStage2Surface;
  final double mindStage1Softness;
  final double mindStage2Softness;
  final ValueChanged<BuildContext> onHeaderDesignMenuPressed;
  final VoidCallback onHeaderBackgroundTap;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;
  final GestureDragCancelCallback onCarouselDragCancel;

  @override
  Widget build(BuildContext context) {
    final budgetSpec = _budgetHeaderVisualSpec.budget;
    final headerValue = _budgetHeaderValue(selectedBudgetItem);

    final budgetContent = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 20,
          top: 28,
          child: Text('BUDGET', style: _headerLabelStyle),
        ),
        Positioned(
          left: 20,
          right: 78,
          top: 48,
          child: _HeaderValueText(headerValue),
        ),
        Positioned(
          key: const ValueKey('spendee-test-header-background-tap-target'),
          left: 112,
          right: 86,
          top: 18,
          height: 58,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onHeaderBackgroundTap,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          key: const ValueKey('spendee-test-header-core-partition'),
          left: 20,
          right: 20,
          top: 78,
          child: _PartitionBar(
            key: const ValueKey('spendee-test-partition-bar'),
            bars: bars,
            totalLimit: budgetLimitAmount,
            height: 5,
          ),
        ),
        if (stage != SpendeeHeaderStage.stage0 &&
            avatarSurface != _PanelSurface.htmlC2Glass)
          Positioned(
            left: 20,
            right: 20,
            top: 88,
            child: _PartitionSummaryLabel(
              bars: bars,
              totalLimit: budgetLimitAmount,
            ),
          ),
        Positioned(
          top: _budgetHeaderVisualSpec.menu.top,
          right: _budgetHeaderVisualSpec.menu.right,
          child: Builder(
            builder: (menuContext) {
              return SpendeeHeaderMenuButton(
                spec: _budgetHeaderVisualSpec,
                onPressed: () => onHeaderDesignMenuPressed(menuContext),
              );
            },
          ),
        ),
        if (stage != SpendeeHeaderStage.stage0)
          Positioned(
            left: budgetSpec.stage1HorizontalInset,
            right: budgetSpec.stage1HorizontalInset,
            top: budgetSpec.stage1Top,
            height: budgetSpec.stage1Height,
            child: _BudgetExtendedInfo(
              items: budgetItems,
              selectedItem: selectedBudgetItem,
              onItemTap: onBudgetItemTap,
              pulsingItemKey: pulsingBudgetItemKey,
              carouselOffset: carouselOffset,
              pressedItemKey: pressedBudgetItemKey,
              avatarBodyHighlightEnabled: avatarBodyHighlightEnabled,
              avatarBodyHighlightStrength: avatarBodyHighlightStrength,
              avatarProgressThickness: avatarProgressThickness,
              avatarLayoutConfig: avatarLayoutConfig,
              onItemLongPressStart: onBudgetItemLongPressStart,
              onItemLongPressMoveUpdate: onBudgetItemLongPressMoveUpdate,
              onItemLongPressEnd: onBudgetItemLongPressEnd,
              onItemLongPressCancel: onBudgetItemLongPressCancel,
              surface: avatarSurface,
              softness: avatarSurfaceSoftness,
              showSelectedLabel: avatarSurface != _PanelSurface.htmlC2Glass,
              onCarouselDragStart: onCarouselDragStart,
              onCarouselDragUpdate: onCarouselDragUpdate,
              onCarouselDragEnd: onCarouselDragEnd,
              onCarouselDragCancel: onCarouselDragCancel,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _budgetHeaderVisualSpec.handle.hitHeight,
          child: SpendeeHeaderHandle(
            spec: _budgetHeaderVisualSpec,
            onVerticalDragStart: onHandleDragStart,
            onVerticalDragUpdate: onHandleDragUpdate,
            onVerticalDragEnd: onHandleDragEnd,
          ),
        ),
        if (stage == SpendeeHeaderStage.stage2)
          Positioned(
            left: budgetSpec.stage1HorizontalInset,
            right: budgetSpec.stage1HorizontalInset,
            top: budgetSpec.stage2Top,
            bottom: budgetSpec.stage2Bottom,
            child: _BudgetPieStage2Layer(
              bars: bars,
              transactions: transactions,
              selectedCategory: selectedCategory,
              page: stage2Page,
              onCategoryTap: onPieCategoryTap,
              onCenterTap: onPieCenterTap,
              onPreviousPage: onStage2PreviousPage,
              onNextPage: onStage2NextPage,
              surface: chartSurface,
              listSurface: chartListSurface,
              softness: chartSurfaceSoftness,
              listSoftness: chartListSurfaceSoftness,
            ),
          ),
      ],
    );
    final isMindBackground = headerBackgroundMode == _HeaderBackgroundMode.mind;
    final content = isMindBackground
        ? _SpendeeMindHeaderContent(
            stage: stage,
            statsFrame: mindStatsFrame!,
            stage1Surface: mindStage1Surface,
            stage2Surface: mindStage2Surface,
            stage1Softness: mindStage1Softness,
            stage2Softness: mindStage2Softness,
            onHeaderDesignMenuPressed: onHeaderDesignMenuPressed,
            onHandleDragStart: onHandleDragStart,
            onHandleDragUpdate: onHandleDragUpdate,
            onHandleDragEnd: onHandleDragEnd,
          )
        : budgetContent;

    return _HeaderSurfaceFrame(
      surface: headerSurface,
      liquidSoftness: headerLiquidSoftness,
      background: isMindBackground
          ? const _MindHeaderGradientBackground(
              key: ValueKey('spendee-test-mind-page-mind'),
            )
          : null,
      child: content,
    );
  }
}

class _SpendeeMindHeaderContent extends StatelessWidget {
  const _SpendeeMindHeaderContent({
    required this.stage,
    required this.statsFrame,
    required this.stage1Surface,
    required this.stage2Surface,
    required this.stage1Softness,
    required this.stage2Softness,
    required this.onHeaderDesignMenuPressed,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
  });

  final SpendeeHeaderStage stage;
  final SpendeeMindStatsFrame statsFrame;
  final _PanelSurface stage1Surface;
  final _PanelSurface stage2Surface;
  final double stage1Softness;
  final double stage2Softness;
  final ValueChanged<BuildContext> onHeaderDesignMenuPressed;
  final GestureDragStartCallback onHandleDragStart;
  final GestureDragUpdateCallback onHandleDragUpdate;
  final GestureDragEndCallback onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    final score = statsFrame.activeFrame.categoryScopeSeries.kontrollScore;
    final modeKey = statsFrame.modeKey;
    const scoreChartRightInset = 18.0;
    const scoreChartLeft = 112.0;
    const scoreChartTop = 43.0;
    const scoreChartHeight = 47.0;
    const scorePlotLeftInset = 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 20,
          top: 28,
          child: Text('MIND', style: _headerLabelStyle),
        ),
        Positioned(
          left: 20,
          right: 78,
          top: 48,
          child: _HeaderValueText(
            '${score.round()}/100',
            valueKey: const ValueKey('spendee-test-mind-header-score-value'),
          ),
        ),
        Positioned(
          key: const ValueKey('spendee-test-mind-score-chart'),
          left: scoreChartLeft,
          right: scoreChartRightInset,
          top: scoreChartTop,
          height: scoreChartHeight,
          child: _MindFastInfoScoreChart(
            activeType: statsFrame.activeFrame.yearData.activeType,
            series: statsFrame.activeFrame.categoryScopeSeries,
            bareLine: false,
            plotLeftInset: scorePlotLeftInset,
          ),
        ),
        if (stage != SpendeeHeaderStage.stage0)
          Positioned(
            left: _budgetHeaderVisualSpec.budget.stage1HorizontalInset,
            right: _budgetHeaderVisualSpec.budget.stage1HorizontalInset,
            top: _budgetHeaderVisualSpec.budget.stage1Top,
            height: _budgetHeaderVisualSpec.budget.stage1Height,
            child: _MindStage1BoxedGraphs(
              key: ValueKey('spendee-test-mind-stage1-$modeKey'),
              statsFrame: statsFrame,
              surface: stage1Surface,
              softness: stage1Softness,
            ),
          ),
        if (stage == SpendeeHeaderStage.stage2)
          Positioned(
            left: _budgetHeaderVisualSpec.budget.stage1HorizontalInset,
            right: _budgetHeaderVisualSpec.budget.stage1HorizontalInset,
            top: _budgetHeaderVisualSpec.budget.stage2Top,
            bottom: _budgetHeaderVisualSpec.budget.stage2Bottom,
            child: _MindStage2Panel(
              statsFrame: statsFrame,
              surface: stage2Surface,
              softness: stage2Softness,
            ),
          ),
        Positioned(
          top: _budgetHeaderVisualSpec.menu.top,
          right: _budgetHeaderVisualSpec.menu.right,
          child: Builder(
            builder: (menuContext) {
              return SpendeeHeaderMenuButton(
                spec: _budgetHeaderVisualSpec,
                onPressed: () => onHeaderDesignMenuPressed(menuContext),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _budgetHeaderVisualSpec.handle.hitHeight,
          child: SpendeeHeaderHandle(
            spec: _budgetHeaderVisualSpec,
            onVerticalDragStart: onHandleDragStart,
            onVerticalDragUpdate: onHandleDragUpdate,
            onVerticalDragEnd: onHandleDragEnd,
          ),
        ),
      ],
    );
  }
}

class _MindFastInfoScoreChart extends StatelessWidget {
  const _MindFastInfoScoreChart({
    required this.activeType,
    required this.series,
    required this.bareLine,
    this.plotLeftInset = 0,
  });

  final TransactionType activeType;
  final StatsCategoryScopeSeries series;
  final bool bareLine;
  final double plotLeftInset;

  @override
  Widget build(BuildContext context) {
    final keySuffix = activeType == TransactionType.income
        ? 'income'
        : 'expense';
    return RepaintBoundary(
      key: ValueKey('spendee-test-mind-score-fastinfo-$keySuffix'),
      child: CustomPaint(
        key: const ValueKey('spendee-test-mind-score-fastinfo-paint'),
        painter: _MindFastInfoScorePainter(
          activeType: activeType,
          series: series,
          bareLine: bareLine,
          plotLeftInset: plotLeftInset,
        ),
      ),
    );
  }
}

class _MindFastInfoScorePainter extends CustomPainter {
  const _MindFastInfoScorePainter({
    required this.activeType,
    required this.series,
    required this.bareLine,
    required this.plotLeftInset,
  });

  final TransactionType activeType;
  final StatsCategoryScopeSeries series;
  final bool bareLine;
  final double plotLeftInset;

  double get score => series.kontrollScore;
  bool get drawsBackground => !bareLine;
  bool get drawsEndpointBadge => !bareLine;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = bareLine
        ? Rect.fromLTRB(
            2 + plotLeftInset,
            4,
            math.max(3 + plotLeftInset, size.width - 2),
            math.max(5, size.height - 4),
          )
        : Rect.fromLTRB(
            18,
            5,
            math.max(19, size.width - 4),
            math.max(6, size.height - 13),
          );
    if (!bareLine) {
      final rect = Offset.zero & size;
      final panel = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(
        panel,
        Paint()..color = Colors.white.withValues(alpha: .56),
      );
      _drawSoftScoreZones(canvas, chart);
      _drawScoreGrid(canvas, chart);
    }
    _drawSegmentedScorePath(canvas, chart, series.scoreLine);
    if (!bareLine) {
      _drawScoreEndpoint(canvas, chart, series.scoreLine);
      _drawEndpointBadge(
        canvas,
        chart,
        series.scoreLine,
        '${score.round()}/100',
        _mindScoreColor(score),
      );
      _drawAxisValueLabels(canvas, chart);
      _drawMonthTicks(canvas, chart, series.monthTicks);
    }
  }

  void _drawSoftScoreZones(Canvas canvas, Rect chart) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(chart, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x2122C55E),
            Color(0x0A22C55E),
            Color(0x14FBBF24),
            Color(0x0AEF4444),
            Color(0x21EF4444),
          ],
          stops: [0, .38, .50, .62, 1],
        ).createShader(chart),
    );
  }

  void _drawScoreGrid(Canvas canvas, Rect chart) {
    final gridPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: .55)
      ..strokeWidth = .8;
    for (var index = 0; index <= 4; index += 1) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final neutralY = chart.bottom - chart.height * .5;
    canvas.drawLine(
      Offset(chart.left, neutralY),
      Offset(chart.right, neutralY),
      Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: .50)
        ..strokeWidth = 1,
    );
  }

  void _drawSegmentedScorePath(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final path = _smoothPathForPoints(chart, points);
    const zones = [
      _MindFastInfoScoreZone(from: 0, to: 45, color: Color(0xFFEF4444)),
      _MindFastInfoScoreZone(from: 45, to: 60, color: Color(0xFFFBBF24)),
      _MindFastInfoScoreZone(from: 60, to: 100, color: Color(0xFF22C55E)),
    ];
    for (final zone in zones) {
      final top = chart.bottom - chart.height * zone.to / 100;
      final bottom = chart.bottom - chart.height * zone.from / 100;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(chart.left - 4, top, chart.right + 4, bottom),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = zone.color.withValues(alpha: .96)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }
  }

  void _drawScoreEndpoint(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final offset = _offsetForPoint(
      chart,
      points.last,
      points.length - 1,
      points.length,
    );
    canvas.drawCircle(offset, 4.6, Paint()..color = Colors.white);
    canvas.drawCircle(
      offset,
      3,
      Paint()..color = _mindScoreColor(points.last.value),
    );
  }

  void _drawEndpointBadge(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
    String label,
    Color color,
  ) {
    if (points.isEmpty || chart.width < 80) return;
    final offset = _offsetForPoint(
      chart,
      points.last,
      points.length - 1,
      points.length,
    );
    final painter = _textPainter(
      label,
      TextStyle(color: color, fontSize: 6.2, fontWeight: FontWeight.w800),
      maxWidth: 42,
    );
    final width = painter.width + 8;
    final left = (offset.dx - width - 2).clamp(
      chart.left + 2,
      chart.right - width,
    );
    final top = (offset.dy - 7).clamp(chart.top + 1, chart.bottom - 12);
    final badge = Rect.fromLTWH(left.toDouble(), top.toDouble(), width, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: .90),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(6)),
      Paint()
        ..color = color
        ..strokeWidth = .9
        ..style = PaintingStyle.stroke,
    );
    painter.paint(
      canvas,
      Offset(
        badge.left + badge.width / 2 - painter.width / 2,
        badge.top + badge.height / 2 - painter.height / 2,
      ),
    );
  }

  void _drawAxisValueLabels(Canvas canvas, Rect chart) {
    const labels = [
      _MindFastInfoAxisLabel(label: '100', value: 1),
      _MindFastInfoAxisLabel(label: '50', value: .5),
      _MindFastInfoAxisLabel(label: '0', value: 0),
    ];
    const style = TextStyle(
      color: AppColors.gray600,
      fontSize: 5.8,
      fontWeight: FontWeight.w800,
    );
    for (final label in labels) {
      final painter = _textPainter(label.label, style, maxWidth: 18);
      final y = chart.bottom - chart.height * label.value;
      painter.paint(
        canvas,
        Offset(
          chart.left - painter.width - 4,
          (y - painter.height / 2).clamp(
            chart.top,
            chart.bottom - painter.height,
          ),
        ),
      );
    }
  }

  void _drawMonthTicks(Canvas canvas, Rect chart, List<StatsMonthTick> ticks) {
    if (ticks.isEmpty || chart.width < 90) return;
    const style = TextStyle(
      color: AppColors.gray600,
      fontSize: 5.6,
      fontWeight: FontWeight.w800,
    );
    for (final tick in ticks.take(5)) {
      final painter = _textPainter(tick.label, style, maxWidth: 24);
      final x = chart.left + chart.width * tick.position.clamp(0.0, 1.0);
      painter.paint(
        canvas,
        Offset(
          (x - painter.width / 2).clamp(
            chart.left,
            chart.right - painter.width,
          ),
          chart.bottom + 3,
        ),
      );
    }
  }

  Path _smoothPathForPoints(Rect chart, List<StatsSeriesPoint> points) {
    final offsets = [
      for (var index = 0; index < points.length; index += 1)
        _offsetForPoint(chart, points[index], index, points.length),
    ];
    final path = Path();
    if (offsets.isEmpty) return path;
    path.moveTo(offsets.first.dx, offsets.first.dy);
    if (offsets.length < 3) {
      for (final offset in offsets.skip(1)) {
        path.lineTo(offset.dx, offset.dy);
      }
      return path;
    }
    for (var index = 0; index < offsets.length - 1; index += 1) {
      final p0 = index == 0 ? offsets[index] : offsets[index - 1];
      final p1 = offsets[index];
      final p2 = offsets[index + 1];
      final p3 = index + 2 < offsets.length ? offsets[index + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  Offset _offsetForPoint(
    Rect chart,
    StatsSeriesPoint point,
    int index,
    int count,
  ) {
    final position = point.position ?? (count <= 1 ? .5 : index / (count - 1));
    return Offset(
      chart.left + chart.width * position.clamp(0.0, 1.0),
      chart.bottom - chart.height * (point.value / 100).clamp(0.0, 1.0),
    );
  }

  TextPainter _textPainter(
    String text,
    TextStyle style, {
    required double maxWidth,
  }) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
  }

  @override
  bool shouldRepaint(covariant _MindFastInfoScorePainter oldDelegate) {
    return oldDelegate.activeType != activeType ||
        oldDelegate.series != series ||
        oldDelegate.bareLine != bareLine ||
        oldDelegate.plotLeftInset != plotLeftInset;
  }
}

class _MindFastInfoScoreZone {
  const _MindFastInfoScoreZone({
    required this.from,
    required this.to,
    required this.color,
  });

  final double from;
  final double to;
  final Color color;
}

class _MindFastInfoAxisLabel {
  const _MindFastInfoAxisLabel({required this.label, required this.value});

  final String label;
  final double value;
}

class _MindHeaderGradientBackground extends StatelessWidget {
  const _MindHeaderGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFFF8C1A),
            Color(0xFFF4DF24),
            Color(0xFF35C76E),
          ],
          stops: const [0, .5, 1],
        ),
      ),
    );
  }
}

Widget _wrapPanelSurface({
  required _PanelSurface surface,
  required double softness,
  required String keyBase,
  required double borderRadius,
  required Widget child,
}) {
  if (surface == _PanelSurface.background) {
    return KeyedSubtree(key: ValueKey('$keyBase-background'), child: child);
  }
  if (surface == _PanelSurface.htmlC2Glass) {
    return _C2GlassSurface(
      key: ValueKey('$keyBase-html-c2-glass'),
      clipKey: ValueKey('$keyBase-html-c2-clip'),
      paintKey: ValueKey('$keyBase-html-c2-paint'),
      maskKey: ValueKey('$keyBase-html-c2-mask'),
      borderRadius: borderRadius,
      useBottomFade: false,
      child: child,
    );
  }
  if (surface == _PanelSurface.liquidGlass) {
    return SpendeeLiquidGlassSurface(
      key: ValueKey('$keyBase-liquid-glass'),
      fallbackKey: ValueKey('$keyBase-liquid-fallback'),
      glareKey: ValueKey('$keyBase-liquid-glare'),
      borderRadius: borderRadius,
      softness: softness,
      child: child,
    );
  }
  if (surface == _PanelSurface.acrylic) {
    return SpendeeAcrylicSurface(
      key: ValueKey('$keyBase-acrylic'),
      fluentKey: ValueKey('$keyBase-acrylic-fluent'),
      borderRadius: borderRadius,
      child: child,
    );
  }
  return DecoratedBox(
    key: ValueKey('$keyBase-glossy'),
    decoration: _stage1GlassDecoration(),
    child: child,
  );
}

class _MindStage1BoxedGraphs extends StatelessWidget {
  const _MindStage1BoxedGraphs({
    super.key,
    required this.statsFrame,
    required this.surface,
    required this.softness,
  });

  final SpendeeMindStatsFrame statsFrame;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final activeType = statsFrame.activeFrame.yearData.activeType;
    final keySuffix = _mindTypeSuffix(activeType);
    final typeLabel = activeType == TransactionType.income
        ? 'Bevételi'
        : 'Kiadási';
    final accent = activeType == TransactionType.income
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final content = Padding(
      key: const ValueKey('spendee-test-mind-stage1-boxed-graphs'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'előző időszakhoz képest',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _smallCapsStyle,
                  ),
                ),
                Text(
                  '${statsFrame.activeFrame.categoryScopeSeries.kontrollScore.round()}/100',
                  key: const ValueKey('spendee-test-mind-score-value'),
                  style: _pieValueStyle.copyWith(
                    color: _mindScoreColor(
                      statsFrame.activeFrame.categoryScopeSeries.kontrollScore,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MindGraphCard(
                      key: ValueKey(
                        'spendee-test-mind-volume-chart-$keySuffix',
                      ),
                      surface: surface,
                      softness: softness,
                      surfaceKeyBase: 'spendee-test-mind-volume-card',
                      paintKey: const ValueKey(
                        'spendee-test-mind-volume-paint',
                      ),
                      label: '$typeLabel volumen',
                      value: _formatFt(
                        statsFrame.activeFrame.yearData.summaryTotal,
                      ),
                      color: accent,
                      painter: _MindVolumeMiniPainter(
                        activeType: activeType,
                        volumePoints: statsFrame.activeVolumePoints,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MindGraphCard(
                      key: ValueKey(
                        'spendee-test-mind-pattern-chart-$keySuffix',
                      ),
                      surface: surface,
                      softness: softness,
                      surfaceKeyBase: 'spendee-test-mind-pattern-card',
                      paintKey: const ValueKey(
                        'spendee-test-mind-pattern-paint',
                      ),
                      label: '$typeLabel minták',
                      value: '${statsFrame.activePatternBars.length} minta',
                      color: accent,
                      painter: _MindPatternMiniPainter(
                        activeType: activeType,
                        patternBars: statsFrame.activePatternBars,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return content;
  }
}

class _MindGraphCard extends StatelessWidget {
  const _MindGraphCard({
    super.key,
    required this.surface,
    required this.softness,
    required this.surfaceKeyBase,
    required this.paintKey,
    required this.label,
    required this.value,
    required this.color,
    required this.painter,
  });

  final _PanelSurface surface;
  final double softness;
  final String surfaceKeyBase;
  final Key paintKey;
  final String label;
  final String value;
  final Color color;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pieFocusLabelStyle,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pieFocusMetaStyle.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              key: paintKey,
              painter: painter,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
    return _wrapPanelSurface(
      surface: surface,
      softness: softness,
      keyBase: surfaceKeyBase,
      borderRadius: 13,
      child: content,
    );
  }
}

class _MindStage2Panel extends StatelessWidget {
  const _MindStage2Panel({
    required this.statsFrame,
    required this.surface,
    required this.softness,
  });

  final SpendeeMindStatsFrame statsFrame;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final content = switch (statsFrame.modeKey) {
      'monthly' => _MindMonthlyHeatmap(
        key: const ValueKey('spendee-test-mind-stage2-monthly'),
        frame: statsFrame.activeFrame,
        surface: surface,
        softness: softness,
      ),
      'yearly' => _MindYearlyHeatmap(
        key: const ValueKey('spendee-test-mind-stage2-yearly'),
        frame: statsFrame.activeFrame,
        surface: surface,
        softness: softness,
      ),
      _ => _MindSumHeatmap(
        key: const ValueKey('spendee-test-mind-stage2-sum'),
        frame: statsFrame.activeFrame,
        surface: surface,
        softness: softness,
      ),
    };
    return content;
  }
}

class _MindMonthlyHeatmap extends StatelessWidget {
  const _MindMonthlyHeatmap({
    super.key,
    required this.frame,
    required this.surface,
    required this.softness,
  });

  final StatsRenderFrame frame;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final month = frame.yearData.graphMonths.isNotEmpty
        ? frame.yearData.graphMonths.first
        : frame.yearData.months[frame.yearData.graphStartMonth - 1];
    return _MindHeatmapSurface(
      key: const ValueKey('spendee-test-mind-monthly-heatmap'),
      child: _MindMonthCard(
        month: month,
        surface: surface,
        softness: softness,
        surfaceKeyBase: 'spendee-test-mind-month-${month.month}',
        single: true,
      ),
    );
  }
}

class _MindYearlyHeatmap extends StatelessWidget {
  const _MindYearlyHeatmap({
    super.key,
    required this.frame,
    required this.surface,
    required this.softness,
  });

  final StatsRenderFrame frame;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final months = frame.yearData.graphMonths.isNotEmpty
        ? frame.yearData.graphMonths
        : frame.yearData.months;
    return _MindHeatmapSurface(
      key: const ValueKey('spendee-test-mind-yearly-heatmap'),
      child: GridView.count(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.18,
        children: [
          for (final month in months.take(12))
            _MindMonthCard(
              month: month,
              surface: surface,
              softness: softness,
              surfaceKeyBase: 'spendee-test-mind-month-${month.month}',
            ),
        ],
      ),
    );
  }
}

class _MindSumHeatmap extends StatelessWidget {
  const _MindSumHeatmap({
    super.key,
    required this.frame,
    required this.surface,
    required this.softness,
  });

  final StatsRenderFrame frame;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final years = frame.sumYearSummaries.isNotEmpty
        ? frame.sumYearSummaries
        : [
            StatsSumYearSummary(
              year: frame.yearData.year,
              monthTotals: {
                for (final month in frame.yearData.months)
                  month.month: month.scopeTotal,
              },
              closingAmount:
                  frame.yearData.canonicalIncomeTotal -
                  frame.yearData.canonicalExpenseTotal,
            ),
          ];
    return _MindHeatmapSurface(
      key: const ValueKey('spendee-test-mind-sum-heatmap'),
      child: GridView.count(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.55,
        children: [
          for (final year in years.take(6))
            _MindYearSummaryCard(
              year: year,
              surface: surface,
              softness: softness,
            ),
        ],
      ),
    );
  }
}

class _MindHeatmapSurface extends StatelessWidget {
  const _MindHeatmapSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(10), child: child);
  }
}

class _MindMonthCard extends StatelessWidget {
  const _MindMonthCard({
    required this.month,
    required this.surface,
    required this.softness,
    required this.surfaceKeyBase,
    this.single = false,
  });

  final StatsMonthData month;
  final _PanelSurface surface;
  final double softness;
  final String surfaceKeyBase;
  final bool single;

  @override
  Widget build(BuildContext context) {
    final days = single ? month.days : month.days.take(21).toList();
    final content = Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pieFocusLabelStyle,
          ),
          const SizedBox(height: 5),
          Expanded(
            child: GridView.count(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: single ? 7 : 5,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: [
                for (final day in days)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF06B6D4,
                      ).withValues(alpha: .16 + day.heatmapIntensity * .60),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: const Color(
                            0xFF14213A,
                          ).withValues(alpha: single ? .72 : 0),
                          fontSize: single ? 7 : 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatFt(month.scopeTotal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pieFocusMetaStyle,
          ),
        ],
      ),
    );
    return _wrapPanelSurface(
      surface: surface,
      softness: softness,
      keyBase: surfaceKeyBase,
      borderRadius: 13,
      child: content,
    );
  }
}

class _MindYearSummaryCard extends StatelessWidget {
  const _MindYearSummaryCard({
    required this.year,
    required this.surface,
    required this.softness,
  });

  final StatsSumYearSummary year;
  final _PanelSurface surface;
  final double softness;

  @override
  Widget build(BuildContext context) {
    final maxMonth = year.maxMonthTotal <= 0 ? 1 : year.maxMonthTotal;
    final content = Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${year.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pieFocusLabelStyle,
                ),
              ),
              Text(
                _formatFt(year.scopeTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pieValueStyle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.count(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var month = 1; month <= 12; month += 1)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF35C76E).withValues(
                        alpha:
                            .16 +
                            ((year.monthTotals[month] ?? 0) / maxMonth) * .60,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        StatsYearData.monthNames[month - 1].characters.first,
                        style: const TextStyle(
                          color: Color(0xFF14213A),
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return _wrapPanelSurface(
      surface: surface,
      softness: softness,
      keyBase: 'spendee-test-mind-year-${year.year}',
      borderRadius: 13,
      child: content,
    );
  }
}

class _MindVolumeMiniPainter extends CustomPainter {
  const _MindVolumeMiniPainter({
    required this.activeType,
    required this.volumePoints,
    required this.color,
  });

  final TransactionType activeType;
  final List<StatsSeriesPoint> volumePoints;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _drawMiniGrid(canvas, size);
    final baselineY = size.height - 1;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = const Color(0xFF14213A).withValues(alpha: .35)
        ..strokeWidth = 1,
    );
    final barWidth = volumePoints.isEmpty
        ? 0.0
        : (size.width / (volumePoints.length * 1.8)).clamp(3.0, 9.0);
    for (var index = 0; index < volumePoints.length; index += 1) {
      final point = volumePoints[index];
      final normalized = (point.value / 100).clamp(0.0, 1.0).toDouble();
      final height = math.max(1.0, normalized * size.height * .82);
      final x =
          (point.position ??
              _normalizedMiniPosition(index, volumePoints.length)) *
          size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, baselineY - height, barWidth, height),
          const Radius.circular(3),
        ),
        Paint()..color = color.withValues(alpha: .78),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindVolumeMiniPainter oldDelegate) {
    return oldDelegate.activeType != activeType ||
        oldDelegate.volumePoints != volumePoints ||
        oldDelegate.color != color;
  }
}

class _MindPatternMiniPainter extends CustomPainter {
  const _MindPatternMiniPainter({
    required this.activeType,
    required this.patternBars,
    required this.color,
  });

  final TransactionType activeType;
  final List<StatsHelperBar> patternBars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _drawMiniGrid(canvas, size);
    final baselineY = size.height - 1;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = const Color(0xFF14213A).withValues(alpha: .35)
        ..strokeWidth = 1,
    );
    final barWidth = patternBars.isEmpty
        ? 0.0
        : patternBars.length <= 12
        ? (size.width / math.max(patternBars.length * 7, 18)).clamp(4.0, 8.0)
        : (size.width / (patternBars.length * 1.35)).clamp(1.2, 7.0);
    for (final bar in patternBars) {
      final normalized = (bar.value / 100).clamp(0.0, 1.0).toDouble();
      final height = math.max(1.0, normalized * size.height * .82);
      final x = bar.position.clamp(0.0, 1.0) * size.width;
      final barColor = _mindHexColor(bar.colorHex, fallback: color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 2, baselineY - height, barWidth, height),
          Radius.circular(math.min(2.4, barWidth / 2)),
        ),
        Paint()
          ..color = barColor.withValues(
            alpha: (0.34 + normalized * 0.5).clamp(0.34, 0.84),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindPatternMiniPainter oldDelegate) {
    return oldDelegate.activeType != activeType ||
        oldDelegate.patternBars != patternBars ||
        oldDelegate.color != color;
  }
}

void _drawMiniGrid(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = const Color(0xFF14213A).withValues(alpha: .10)
    ..strokeWidth = 1;
  for (var i = 1; i <= 3; i += 1) {
    final y = size.height * i / 4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

double _normalizedMiniPosition(int index, int count) {
  if (count <= 1) return .5;
  return index / (count - 1);
}

String _mindTypeSuffix(TransactionType type) {
  return type == TransactionType.income ? 'income' : 'expense';
}

Color _mindHexColor(String hex, {required Color fallback}) {
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) return fallback;
  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? fallback : Color(value);
}

Color _mindScoreColor(double score) {
  if (score < 45) return const Color(0xFFEF4444);
  if (score < 60) return const Color(0xFFFBBF24);
  return const Color(0xFF22C55E);
}

class _BudgetExtendedInfo extends StatelessWidget {
  const _BudgetExtendedInfo({
    required this.items,
    required this.selectedItem,
    required this.onItemTap,
    required this.pulsingItemKey,
    required this.carouselOffset,
    required this.pressedItemKey,
    required this.avatarBodyHighlightEnabled,
    required this.avatarBodyHighlightStrength,
    required this.avatarProgressThickness,
    required this.avatarLayoutConfig,
    required this.onItemLongPressStart,
    required this.onItemLongPressMoveUpdate,
    required this.onItemLongPressEnd,
    required this.onItemLongPressCancel,
    required this.surface,
    required this.softness,
    required this.showSelectedLabel,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
    required this.onCarouselDragCancel,
  });

  final List<BackheaderBudgetItem> items;
  final BackheaderBudgetItem? selectedItem;
  final ValueChanged<BackheaderBudgetItem> onItemTap;
  final String? pulsingItemKey;
  final double carouselOffset;
  final String? pressedItemKey;
  final bool avatarBodyHighlightEnabled;
  final double avatarBodyHighlightStrength;
  final double avatarProgressThickness;
  final _AvatarLayoutConfig avatarLayoutConfig;
  final void Function(BackheaderBudgetItem, LongPressStartDetails)
  onItemLongPressStart;
  final GestureLongPressMoveUpdateCallback onItemLongPressMoveUpdate;
  final GestureLongPressEndCallback onItemLongPressEnd;
  final GestureLongPressCancelCallback onItemLongPressCancel;
  final _PanelSurface surface;
  final double softness;
  final bool showSelectedLabel;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;
  final GestureDragCancelCallback onCarouselDragCancel;

  @override
  Widget build(BuildContext context) {
    final avatarAreaKey = surface == _PanelSurface.htmlC2Glass
        ? const ValueKey('spendee-test-budget-stage1-html-c2-avatar-area')
        : null;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          key: avatarAreaKey,
          left: 10,
          right: 10,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            key: const ValueKey('spendee-test-context-carousel-gesture'),
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: onCarouselDragStart,
            onHorizontalDragUpdate: onCarouselDragUpdate,
            onHorizontalDragEnd: onCarouselDragEnd,
            onHorizontalDragCancel: onCarouselDragCancel,
            child: AnimatedContainer(
              key: const ValueKey('spendee-test-context-carousel'),
              duration: Duration.zero,
              curve: Curves.easeOutQuad,
              transform: Matrix4.identity(),
              child: _ContextAvatarBelt(
                items: items,
                selectedItem: selectedItem,
                pulsingItemKey: pulsingItemKey,
                carouselOffset: carouselOffset,
                pressedItemKey: pressedItemKey,
                avatarBodyHighlightEnabled: avatarBodyHighlightEnabled,
                avatarBodyHighlightStrength: avatarBodyHighlightStrength,
                avatarProgressThickness: avatarProgressThickness,
                avatarLayoutConfig: avatarLayoutConfig,
                onItemTap: onItemTap,
                onItemLongPressStart: onItemLongPressStart,
                onItemLongPressMoveUpdate: onItemLongPressMoveUpdate,
                onItemLongPressEnd: onItemLongPressEnd,
                onItemLongPressCancel: onItemLongPressCancel,
              ),
            ),
          ),
        ),
        if (showSelectedLabel && selectedItem != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 9,
            child: Text(
              selectedItem!.title,
              key: const ValueKey('spendee-test-context-avatar-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: _contextAvatarLabelStyle,
            ),
          ),
      ],
    );

    if (surface == _PanelSurface.background) {
      return SizedBox.expand(
        key: const ValueKey('spendee-test-budget-stage1-background'),
        child: content,
      );
    }

    if (surface == _PanelSurface.htmlC2Glass) {
      return _C2GlassSurface(
        key: const ValueKey('spendee-test-budget-stage1-html-c2-glass'),
        clipKey: const ValueKey('spendee-test-budget-stage1-html-c2-clip'),
        paintKey: const ValueKey('spendee-test-budget-stage1-html-c2-paint'),
        maskKey: const ValueKey('spendee-test-budget-stage1-html-c2-mask'),
        borderRadius: 17,
        useBottomFade: false,
        child: content,
      );
    }

    if (surface == _PanelSurface.liquidGlass) {
      return SpendeeLiquidGlassSurface(
        key: const ValueKey('spendee-test-budget-stage1-liquid-glass'),
        fallbackKey: const ValueKey(
          'spendee-test-budget-stage1-liquid-fallback',
        ),
        glareKey: const ValueKey('spendee-test-budget-stage1-liquid-glare'),
        borderRadius: 17,
        softness: softness,
        child: content,
      );
    }

    if (surface == _PanelSurface.acrylic) {
      return SpendeeAcrylicSurface(
        key: const ValueKey('spendee-test-budget-stage1-acrylic'),
        fluentKey: const ValueKey('spendee-test-budget-stage1-acrylic-fluent'),
        borderRadius: 17,
        child: content,
      );
    }

    return DecoratedBox(
      key: const ValueKey('spendee-test-budget-stage1-glossy'),
      decoration: _stage1GlassDecoration(),
      child: content,
    );
  }
}

class _HeaderSurfaceFrame extends StatelessWidget {
  const _HeaderSurfaceFrame({
    required this.surface,
    required this.liquidSoftness,
    required this.child,
    this.background,
  });

  final _HeaderSurface surface;
  final double liquidSoftness;
  final Widget child;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    if (surface == _HeaderSurface.normal) {
      return SpendeeHeaderGlassSurface(
        spec: _budgetHeaderVisualSpec,
        child: _buildForegroundWithBackground(child),
      );
    }

    final radius = _budgetHeaderVisualSpec.glass.radius;
    final coloredContent = _buildColoredSurfaceContent(child);
    final surfaceChild = switch (surface) {
      _HeaderSurface.normal => coloredContent,
      _HeaderSurface.htmlC2Glass => _C2GlassSurface(
        key: const ValueKey('spendee-test-header-c2-glass'),
        clipKey: const ValueKey('spendee-test-header-c2-clip'),
        paintKey: const ValueKey('spendee-test-header-c2-paint'),
        maskKey: const ValueKey('spendee-test-header-c2-mask'),
        borderRadius: radius,
        useBottomFade: false,
        child: coloredContent,
      ),
      _HeaderSurface.liquidGlass => SpendeeLiquidGlassSurface(
        key: const ValueKey('spendee-test-header-liquid-glass'),
        fallbackKey: const ValueKey('spendee-test-header-liquid-fallback'),
        glareKey: const ValueKey('spendee-test-header-liquid-glare'),
        borderRadius: radius,
        softness: liquidSoftness,
        child: coloredContent,
      ),
      _HeaderSurface.acrylic => SpendeeAcrylicSurface(
        key: const ValueKey('spendee-test-header-acrylic'),
        fluentKey: const ValueKey('spendee-test-header-acrylic-fluent'),
        highlightKey: const ValueKey('spendee-test-header-acrylic-highlight'),
        borderRadius: radius,
        child: coloredContent,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _budgetHeaderVisualSpec.glass.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: surfaceChild,
      ),
    );
  }

  Widget _buildForegroundWithBackground(Widget foreground) {
    final background = this.background;
    if (background == null) return foreground;
    return Stack(fit: StackFit.expand, children: [background, foreground]);
  }

  Widget _buildColoredSurfaceContent(Widget foreground) {
    return Stack(
      fit: StackFit.expand,
      children: [background ?? const _HeaderColoredBase(), foreground],
    );
  }
}

class _HeaderColoredBase extends StatelessWidget {
  const _HeaderColoredBase();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      key: const ValueKey('spendee-test-header-colored-base'),
      opacity: _budgetHeaderVisualSpec.graphicLayerOpacity,
      child: CustomPaint(
        painter: SpendeeHeaderGlassPainter(_budgetHeaderVisualSpec),
      ),
    );
  }
}

class _C2GlassSurface extends StatelessWidget {
  const _C2GlassSurface({
    super.key,
    required this.clipKey,
    required this.paintKey,
    required this.maskKey,
    required this.borderRadius,
    required this.useBottomFade,
    required this.child,
  });

  final Key clipKey;
  final Key paintKey;
  final Key maskKey;
  final double borderRadius;
  final bool useBottomFade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = CustomPaint(
      painter: _C2GlassShadowPainter(borderRadius: borderRadius),
      child: ClipRRect(
        key: clipKey,
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: CustomPaint(
            key: paintKey,
            foregroundPainter: _C2GlassSurfacePainter(
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
    if (!useBottomFade) return surface;

    return ShaderMask(
      key: maskKey,
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, .75, 1],
      ).createShader(bounds),
      child: surface,
    );
  }
}

class _C2GlassShadowPainter extends CustomPainter {
  const _C2GlassShadowPainter({required this.borderRadius});

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(
      rrect.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color.fromRGBO(15, 23, 42, .08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _C2GlassShadowPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius;
  }
}

class _C2GlassSurfacePainter extends CustomPainter {
  const _C2GlassSurfacePainter({required this.borderRadius});

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.save();
    canvas.clipRRect(rrect, doAntiAlias: true);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, const [
          Color.fromRGBO(255, 255, 255, .36),
          Color.fromRGBO(255, 255, 255, .16),
        ]),
    );

    final radialCenter = Offset(size.width * .14, size.height * .08);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          radialCenter,
          _farthestCornerRadius(rect, radialCenter),
          const [
            Color.fromRGBO(255, 255, 255, .62),
            Color.fromRGBO(255, 255, 255, 0),
          ],
          const [0, .36],
        ),
    );

    canvas.drawLine(
      const Offset(0, .5),
      Offset(size.width, .5),
      Paint()
        ..color = const Color.fromRGBO(255, 255, 255, .46)
        ..strokeWidth = 1,
    );

    canvas.restore();
  }

  double _farthestCornerRadius(Rect rect, Offset center) {
    return math.max(
      math.max(
        (center - rect.topLeft).distance,
        (center - rect.topRight).distance,
      ),
      math.max(
        (center - rect.bottomLeft).distance,
        (center - rect.bottomRight).distance,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _C2GlassSurfacePainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius;
  }
}

BoxDecoration _stage1GlassDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(17),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: .36),
        Colors.white.withValues(alpha: .16),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: .46),
        offset: const Offset(0, 1),
        blurRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: .08),
        offset: const Offset(0, 6),
        blurRadius: 18,
      ),
    ],
  );
}

class _ContextAvatarBelt extends StatelessWidget {
  const _ContextAvatarBelt({
    required this.items,
    required this.selectedItem,
    required this.pulsingItemKey,
    required this.carouselOffset,
    required this.pressedItemKey,
    required this.avatarBodyHighlightEnabled,
    required this.avatarBodyHighlightStrength,
    required this.avatarProgressThickness,
    required this.avatarLayoutConfig,
    required this.onItemTap,
    required this.onItemLongPressStart,
    required this.onItemLongPressMoveUpdate,
    required this.onItemLongPressEnd,
    required this.onItemLongPressCancel,
  });

  final List<BackheaderBudgetItem> items;
  final BackheaderBudgetItem? selectedItem;
  final String? pulsingItemKey;
  final double carouselOffset;
  final String? pressedItemKey;
  final bool avatarBodyHighlightEnabled;
  final double avatarBodyHighlightStrength;
  final double avatarProgressThickness;
  final _AvatarLayoutConfig avatarLayoutConfig;
  final ValueChanged<BackheaderBudgetItem> onItemTap;
  final void Function(BackheaderBudgetItem, LongPressStartDetails)
  onItemLongPressStart;
  final GestureLongPressMoveUpdateCallback onItemLongPressMoveUpdate;
  final GestureLongPressEndCallback onItemLongPressEnd;
  final GestureLongPressCancelCallback onItemLongPressCancel;

  static const _slotDistance = 64.0;
  static const _verticalLift = 4.0;
  static const _slotOffsets = <int>[-2, -1, 0, 1, 2];
  static const _slotBuildOrder = <int>[0, -1, 1, -2, 2];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2 - _verticalLift,
        );
        final slots = _visibleAvatarSlots()
          ..sort((left, right) {
            final leftDistance = _logicalOffsetFor(left.slotOffset).abs();
            final rightDistance = _logicalOffsetFor(right.slotOffset).abs();
            return rightDistance.compareTo(leftDistance);
          });
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final slot in slots)
              _PositionedContextAvatar(
                slot: slot,
                center: center,
                logicalOffset: _logicalOffsetFor(slot.slotOffset),
                onTap: () => onItemTap(slot.item),
                onLongPressStart: (details) =>
                    onItemLongPressStart(slot.item, details),
                onLongPressMoveUpdate: onItemLongPressMoveUpdate,
                onLongPressEnd: onItemLongPressEnd,
                onLongPressCancel: onItemLongPressCancel,
                pulsing: slot.item.key == pulsingItemKey,
                pressed: slot.item.key == pressedItemKey,
                avatarBodyHighlightEnabled: avatarBodyHighlightEnabled,
                avatarBodyHighlightStrength: avatarBodyHighlightStrength,
                avatarProgressThickness: avatarProgressThickness,
                avatarLayoutConfig: avatarLayoutConfig,
              ),
          ],
        );
      },
    );
  }

  double _logicalOffsetFor(int slotOffset) =>
      slotOffset + carouselOffset / _slotDistance;

  List<_ContextAvatarSlot> _visibleAvatarSlots() {
    final selectedIndex = items.indexWhere(
      (item) => item.key == selectedItem?.key,
    );
    final centerIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final movingRight = carouselOffset > .001;
    final movingLeft = carouselOffset < -.001;
    final moving = movingRight || movingLeft;
    final visibleCount = math.min(
      items.length,
      _slotOffsets.length + (moving ? 1 : 0),
    );
    final buildOrder = <int>[
      ..._slotBuildOrder,
      if (movingRight) -3,
      if (movingLeft) 3,
    ];
    final slots = <_ContextAvatarSlot>[];
    final usedIndexes = <int>{};
    for (final offset in buildOrder) {
      if (slots.length == visibleCount) break;
      final index = _wrappedIndex(centerIndex + offset);
      if (!usedIndexes.add(index)) continue;
      slots.add(
        _ContextAvatarSlot(
          item: items[index],
          slotOffset: offset,
          selected: offset == 0,
        ),
      );
    }
    slots.sort((left, right) => left.slotOffset.compareTo(right.slotOffset));
    return slots;
  }

  int _wrappedIndex(int index) {
    final wrapped = index % items.length;
    return wrapped < 0 ? wrapped + items.length : wrapped;
  }
}

class _ContextAvatarSlot {
  const _ContextAvatarSlot({
    required this.item,
    required this.slotOffset,
    required this.selected,
  });

  final BackheaderBudgetItem item;
  final int slotOffset;
  final bool selected;
}

class _PositionedContextAvatar extends StatelessWidget {
  const _PositionedContextAvatar({
    required this.slot,
    required this.center,
    required this.logicalOffset,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
    required this.pulsing,
    required this.pressed,
    required this.avatarBodyHighlightEnabled,
    required this.avatarBodyHighlightStrength,
    required this.avatarProgressThickness,
    required this.avatarLayoutConfig,
  });

  final _ContextAvatarSlot slot;
  final Offset center;
  final double logicalOffset;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;
  final GestureLongPressCancelCallback onLongPressCancel;
  final bool pulsing;
  final bool pressed;
  final bool avatarBodyHighlightEnabled;
  final double avatarBodyHighlightStrength;
  final double avatarProgressThickness;
  final _AvatarLayoutConfig avatarLayoutConfig;

  @override
  Widget build(BuildContext context) {
    final position = _visualPosition();
    final size = _visualSize(position);
    final iconSize = _visualIconSize(position);
    final opacity = _visualOpacity(position);
    final x = avatarLayoutConfig.xForLogicalOffset(position);
    return Positioned(
      key: ValueKey('spendee-test-context-avatar-slot-${slot.slotOffset}'),
      left: center.dx + x - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: _ContextAvatar(
        item: slot.item,
        size: size,
        iconSize: iconSize,
        opacity: opacity,
        selected: slot.selected,
        pulsing: pulsing,
        pressed: pressed,
        avatarBodyHighlightEnabled: avatarBodyHighlightEnabled,
        avatarBodyHighlightStrength: avatarBodyHighlightStrength,
        avatarProgressThickness: avatarProgressThickness,
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        onLongPressMoveUpdate: onLongPressMoveUpdate,
        onLongPressEnd: onLongPressEnd,
        onLongPressCancel: onLongPressCancel,
      ),
    );
  }

  double _visualPosition() => logicalOffset;

  double _visualSize(double position) {
    return avatarLayoutConfig.sizeForLogicalOffset(position);
  }

  double _visualIconSize(double position) {
    return avatarLayoutConfig.iconSizeForLogicalOffset(position);
  }

  double _visualOpacity(double position) {
    if (slot.selected) return 1;
    final distance = position.abs();
    if (distance <= 1) return _lerpDouble(1, .9, distance);
    return _lerpDouble(.9, .72, (distance - 1).clamp(0.0, 1.0).toDouble());
  }
}

double _clampUnit(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

double _lerpDouble(double begin, double end, double amount) {
  return begin + (end - begin) * _clampUnit(amount);
}

class _ContextAvatar extends StatefulWidget {
  const _ContextAvatar({
    required this.item,
    required this.size,
    required this.iconSize,
    required this.opacity,
    required this.selected,
    required this.pulsing,
    required this.pressed,
    required this.avatarBodyHighlightEnabled,
    required this.avatarBodyHighlightStrength,
    required this.avatarProgressThickness,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  final BackheaderBudgetItem item;
  final double size;
  final double iconSize;
  final double opacity;
  final bool selected;
  final bool pulsing;
  final bool pressed;
  final bool avatarBodyHighlightEnabled;
  final double avatarBodyHighlightStrength;
  final double avatarProgressThickness;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;
  final GestureLongPressEndCallback onLongPressEnd;
  final GestureLongPressCancelCallback onLongPressCancel;

  @override
  State<_ContextAvatar> createState() => _ContextAvatarState();
}

class _ContextAvatarState extends State<_ContextAvatar> {
  var _pointerPressed = false;

  void _setPointerPressed(bool pressed) {
    if (_pointerPressed == pressed || !mounted) return;
    setState(() => _pointerPressed = pressed);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    widget.onLongPressStart(details);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _setPointerPressed(false);
    widget.onLongPressEnd(details);
  }

  void _handleLongPressCancel() {
    _setPointerPressed(false);
    widget.onLongPressCancel();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.item.category?.category;
    final progress = _budgetItemProgress(widget.item);
    final keyBase = _budgetAvatarKeyBase(widget.item);
    final selected = widget.selected;
    final pressed = widget.pressed || _pointerPressed;
    return Listener(
      onPointerDown: (_) => _setPointerPressed(true),
      onPointerUp: (_) => _setPointerPressed(false),
      onPointerCancel: (_) => _setPointerPressed(false),
      child: GestureDetector(
        key: _budgetAvatarKey(widget.item, selected: selected),
        onTap: widget.onTap,
        onLongPressStart: _handleLongPressStart,
        onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
        onLongPressEnd: _handleLongPressEnd,
        onLongPressCancel: _handleLongPressCancel,
        child: AnimatedScale(
          key: ValueKey('spendee-test-avatar-press-scale-$keyBase'),
          scale: pressed ? .8 : 1.0,
          duration: const Duration(milliseconds: 115),
          curve: Curves.easeOutQuad,
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: ValueKey(
                          'spendee-test-avatar-outer-halo-progress-$keyBase',
                        ),
                        painter: _BudgetAvatarOuterHaloProgressPainter(
                          progress: progress,
                          selected: selected,
                          thickness: _avatarProgressStrokeWidth(
                            widget.avatarProgressThickness,
                            selected: selected,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (category != null)
                  GlossyCategoryAvatar(
                    category: category,
                    size: widget.size,
                    iconSize: widget.iconSize,
                    selected: selected,
                    pulsing: widget.pulsing,
                    opacity: widget.opacity,
                    showTopHighlight: false,
                    showBodyHighlight: widget.avatarBodyHighlightEnabled,
                    bodyHighlightStrength: widget.avatarBodyHighlightStrength,
                    bodyHighlightKey: ValueKey(
                      'spendee-test-avatar-body-highlight-$keyBase',
                    ),
                    showBodyBorder: !selected,
                    animateBodySize: false,
                    showSelectedOuterGlow: false,
                    scaleSelection: false,
                    debugSource: 'spendee-test-context-avatar',
                  )
                else
                  GlossyCategoryAvatar(
                    category: null,
                    size: widget.size,
                    iconSize: widget.iconSize,
                    selected: selected,
                    pulsing: widget.pulsing,
                    opacity: widget.opacity,
                    avatarGradient: _budgetItemAvatarGradient(widget.item),
                    centerChild: Icon(
                      widget.item.overview?.kind == BudgetGoalKind.incomeGoal
                          ? Icons.trending_up_rounded
                          : Icons.account_balance_wallet_rounded,
                      size: widget.iconSize,
                      color: Colors.white.withValues(alpha: .94),
                    ),
                    showTopHighlight: false,
                    showBodyHighlight: widget.avatarBodyHighlightEnabled,
                    bodyHighlightStrength: widget.avatarBodyHighlightStrength,
                    bodyHighlightKey: ValueKey(
                      'spendee-test-avatar-body-highlight-$keyBase',
                    ),
                    showBodyBorder: !selected,
                    animateBodySize: false,
                    showSelectedOuterGlow: false,
                    scaleSelection: false,
                    debugSource: 'spendee-test-context-avatar-overview',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _budgetAvatarKeyBase(BackheaderBudgetItem item) {
  final category = item.category?.category;
  if (category != null) {
    return 'category-${category.transactionCategoryID}';
  }
  return item.key;
}

Key _budgetAvatarKey(BackheaderBudgetItem item, {required bool selected}) {
  final category = item.category?.category;
  if (category != null) {
    return ValueKey(
      selected
          ? 'spendee-test-category-avatar-${category.transactionCategoryID}-selected'
          : 'spendee-test-category-avatar-${category.transactionCategoryID}',
    );
  }
  final key = 'spendee-test-budget-avatar-${item.key}';
  return ValueKey(selected ? '$key-selected' : key);
}

double _budgetItemProgress(BackheaderBudgetItem item) {
  final overview = item.overview;
  if (overview != null) {
    if (!overview.hasLimit || overview.limitAmount <= 0) return 0;
    return (overview.amount / overview.limitAmount).clamp(0.0, 1.0).toDouble();
  }
  final category = item.category;
  if (category == null || !category.hasLimit || category.limitAmount <= 0) {
    return 0;
  }
  return (category.spent / category.limitAmount).clamp(0.0, 1.0).toDouble();
}

Color _budgetItemAccent(BackheaderBudgetItem item) {
  final category = item.category;
  if (category != null) return category.color;
  final overview = item.overview;
  if (overview?.kind == BudgetGoalKind.incomeGoal) {
    return const Color(0xFF22C55E);
  }
  return const Color(0xFF06B6D4);
}

Gradient _budgetItemAvatarGradient(BackheaderBudgetItem item) {
  final accent = _budgetItemAccent(item);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accent.withValues(alpha: .96),
      accent.withValues(alpha: .84),
      const Color(0xFF0F172A).withValues(alpha: .76),
    ],
    stops: const [0, .56, 1],
  );
}

String _budgetHeaderValue(BackheaderBudgetItem? item) {
  if (item == null) return 'Nincs limit';
  final overview = item.overview;
  if (overview != null) {
    return overview.hasLimit
        ? '${_formatFt(overview.amount)} / ${_formatFt(overview.limitAmount)}'
        : _formatFt(overview.amount);
  }
  final category = item.category;
  if (category == null) return 'Nincs limit';
  return category.hasLimit
      ? '${_formatFt(category.spent)} / ${_formatFt(category.limitAmount)}'
      : _formatFt(category.spent);
}

class _BudgetAvatarOuterHaloProgressPainter extends CustomPainter {
  const _BudgetAvatarOuterHaloProgressPainter({
    required this.progress,
    required this.selected,
    required this.thickness,
  });

  final double progress;
  final bool selected;
  final double thickness;
  Color get progressColor {
    if (progress >= .90) return const Color(0xFFEF4444);
    if (progress >= .75) return const Color(0xFFFBBF24);
    return Colors.white;
  }

  bool get usesOuterGlassHalo => true;
  bool get drawsInsideAvatarBody => false;
  bool get usesRadialFadeStroke => false;
  int get progressDrawPassCount => 1;
  int get visibleProgressRingCount => progress > 0 ? 1 : 0;
  int get trackDrawPassCount => 0;
  int get glowDrawPassCount => 0;
  bool get usesStrokeBlur => false;
  bool get drawsSeparateInnerProgressRing => false;
  bool get clockwise => true;
  double get startRadians => -math.pi / 2;
  double get strokeWidth => thickness;
  double get avatarOutset => strokeWidth / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
    final outset = avatarOutset;
    final rect = Rect.fromLTWH(
      -outset,
      -outset,
      size.width + outset * 2,
      size.height + outset * 2,
    );
    if (progress <= 0) return;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final progressAlpha = _lerpDouble(
      selected ? .44 : .30,
      selected ? .70 : .50,
      clampedProgress,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor.withValues(alpha: progressAlpha);
    if (clampedProgress >= .999) {
      canvas.drawCircle(
        rect.center,
        math.min(rect.width, rect.height) / 2,
        paint,
      );
      return;
    }
    canvas.drawArc(
      rect,
      startRadians,
      math.pi * 2 * clampedProgress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _BudgetAvatarOuterHaloProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.selected != selected ||
        oldDelegate.thickness != thickness;
  }
}

double _avatarProgressStrokeWidth(double value, {required bool selected}) {
  final clamped = _clampUnit(value);
  final min = selected ? 6.0 : 5.0;
  final max = selected ? 14.0 : 12.0;
  return _lerpDouble(min, max, clamped);
}

class _PartitionBar extends StatelessWidget {
  const _PartitionBar({
    super.key,
    required this.bars,
    required this.totalLimit,
    this.height = 10,
  });

  final List<CategoryBudgetBarData> bars;
  final double totalLimit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars
        .where((bar) => bar.spent > 0 || bar.limitAmount > 0)
        .toList();
    final allocated = visibleBars.fold<double>(
      0,
      (sum, bar) => sum + (bar.limitAmount > 0 ? bar.limitAmount : bar.spent),
    );
    final free = math.max(0.0, totalLimit - allocated);
    final scaleTotal = math.max(totalLimit, allocated);
    if (visibleBars.isEmpty || scaleTotal <= 0) {
      return Container(
        key: const ValueKey('spendee-test-partition-segment-free'),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final bar in visibleBars) ...[
              _partitionSegment(
                key: ValueKey(
                  'spendee-test-partition-segment-used-${bar.targetId}',
                ),
                amount: bar.limitAmount > 0
                    ? math.min(bar.spent, bar.limitAmount)
                    : bar.spent,
                scaleTotal: scaleTotal,
                bar: bar,
                opacity: 1,
              ),
              _partitionSegment(
                key: ValueKey(
                  'spendee-test-partition-segment-remaining-${bar.targetId}',
                ),
                amount: math.max(0.0, bar.limitAmount - bar.spent),
                scaleTotal: scaleTotal,
                bar: bar,
                opacity: .28,
              ),
            ],
            _partitionFreeSegment(amount: free, scaleTotal: scaleTotal),
          ],
        ),
      ),
    );
  }

  Widget _partitionSegment({
    required Key key,
    required double amount,
    required double scaleTotal,
    required CategoryBudgetBarData bar,
    required double opacity,
  }) {
    if (amount <= 0) return SizedBox.shrink(key: key);
    return Flexible(
      key: key,
      flex: math.max(1, (amount / scaleTotal * 10000).round()),
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: CategoryColorManager.gradient(bar.category?.colorSlot),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _partitionFreeSegment({
    required double amount,
    required double scaleTotal,
  }) {
    const key = ValueKey('spendee-test-partition-segment-free');
    if (amount <= 0) return const SizedBox.shrink(key: key);
    return Flexible(
      key: key,
      flex: math.max(1, (amount / scaleTotal * 10000).round()),
      child: ColoredBox(
        color: Colors.white.withValues(alpha: .42),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BudgetPieStage2Layer extends StatefulWidget {
  const _BudgetPieStage2Layer({
    required this.bars,
    required this.transactions,
    required this.selectedCategory,
    required this.page,
    required this.onCategoryTap,
    required this.onCenterTap,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.surface,
    required this.listSurface,
    required this.softness,
    required this.listSoftness,
  });

  final List<CategoryBudgetBarData> bars;
  final List<TransactionRecord> transactions;
  final TransactionCategory? selectedCategory;
  final _Stage2BudgetPage page;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final VoidCallback onCenterTap;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final _PanelSurface surface;
  final _ChartListSurface listSurface;
  final double softness;
  final double listSoftness;

  @override
  State<_BudgetPieStage2Layer> createState() => _BudgetPieStage2LayerState();
}

class _BudgetPieStage2LayerState extends State<_BudgetPieStage2Layer> {
  var _dragDx = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('spendee-test-budget-pie-stage2-layer'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
      onHorizontalDragEnd: (_) {
        final dx = _dragDx;
        _dragDx = 0;
        if (dx <= -48) {
          widget.onNextPage();
        } else if (dx >= 48) {
          widget.onPreviousPage();
        }
      },
      onHorizontalDragCancel: () => _dragDx = 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 0, 1, 12),
        child: _BudgetPiePanel(
          bars: widget.bars,
          transactions: widget.transactions,
          selectedCategory: widget.selectedCategory,
          page: widget.page,
          onCategoryTap: widget.onCategoryTap,
          onCenterTap: widget.onCenterTap,
          surface: widget.surface,
          listSurface: widget.listSurface,
          softness: widget.softness,
          listSoftness: widget.listSoftness,
        ),
      ),
    );
  }
}

class _BudgetShareEntry {
  const _BudgetShareEntry({
    required this.key,
    required this.rowKey,
    required this.rowSurfaceKeyBase,
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.dotGradient,
    this.category,
  });

  final String key;
  final Key rowKey;
  final String rowSurfaceKeyBase;
  final String title;
  final double amount;
  final int count;
  final Color color;
  final Gradient dotGradient;
  final TransactionCategory? category;
}

class _VendorShareAccumulator {
  const _VendorShareAccumulator({
    required this.name,
    required this.amount,
    required this.count,
    required this.categoryAmounts,
  });

  final String name;
  final double amount;
  final int count;
  final Map<int, double> categoryAmounts;

  _VendorShareAccumulator add(double nextAmount, int? categoryId) {
    final nextCategoryAmounts = Map<int, double>.of(categoryAmounts);
    if (categoryId != null) {
      nextCategoryAmounts.update(
        categoryId,
        (amount) => amount + nextAmount,
        ifAbsent: () => nextAmount,
      );
    }
    return _VendorShareAccumulator(
      name: name,
      amount: amount + nextAmount,
      count: count + 1,
      categoryAmounts: nextCategoryAmounts,
    );
  }

  TransactionCategory? dominantCategory(
    Map<int, TransactionCategory> categoriesById,
  ) {
    if (categoryAmounts.isEmpty) return null;
    final dominant = categoryAmounts.entries.reduce((left, right) {
      final amountOrder = left.value.compareTo(right.value);
      if (amountOrder != 0) return amountOrder >= 0 ? left : right;
      return left.key <= right.key ? left : right;
    });
    return categoriesById[dominant.key];
  }
}

class _BudgetPiePanel extends StatelessWidget {
  const _BudgetPiePanel({
    required this.bars,
    required this.transactions,
    required this.selectedCategory,
    required this.page,
    required this.onCategoryTap,
    required this.onCenterTap,
    required this.surface,
    required this.listSurface,
    required this.softness,
    required this.listSoftness,
  });

  final List<CategoryBudgetBarData> bars;
  final List<TransactionRecord> transactions;
  final TransactionCategory? selectedCategory;
  final _Stage2BudgetPage page;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final VoidCallback onCenterTap;
  final _PanelSurface surface;
  final _ChartListSurface listSurface;
  final double softness;
  final double listSoftness;

  @override
  Widget build(BuildContext context) {
    final rawEntries = switch (page) {
      _Stage2BudgetPage.categories => _categoryEntries(),
      _Stage2BudgetPage.vendors => _vendorEntries(),
    };
    final rawTotal = rawEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final entries = _withoutRoundedZeroShares(rawEntries, rawTotal);
    if (entries.isEmpty) {
      return const SizedBox.shrink(
        key: ValueKey('spendee-test-budget-pie-empty-hidden'),
      );
    }
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final selectedKey = switch (page) {
      _Stage2BudgetPage.categories =>
        selectedCategory?.transactionCategoryID.toString(),
      _Stage2BudgetPage.vendors => entries.isEmpty ? null : entries.first.key,
    };
    final selectedEntry = entries.cast<_BudgetShareEntry?>().firstWhere(
      (entry) => entry?.key == selectedKey,
      orElse: () => entries.isEmpty ? null : entries.first,
    );
    final selectedPercent = selectedEntry == null || total <= 0
        ? 0
        : (selectedEntry.amount / total * 100).round();
    final content = _BudgetPieContent(
      key: ValueKey(
        page == _Stage2BudgetPage.categories
            ? 'spendee-test-stage2-page-categories'
            : 'spendee-test-stage2-page-vendors',
      ),
      budgetSpec: _budgetHeaderVisualSpec.budget,
      entries: entries,
      total: total,
      selectedKey: selectedEntry?.key,
      selectedEntry: selectedEntry,
      selectedPercent: selectedPercent,
      focusLabel: page == _Stage2BudgetPage.categories
          ? 'kiemelt kategória'
          : 'kiemelt vendor',
      focusTitleKey: ValueKey(
        page == _Stage2BudgetPage.categories
            ? 'spendee-test-budget-pie-focus-title'
            : 'spendee-test-budget-vendor-focus-title',
      ),
      focusSuffix: page == _Stage2BudgetPage.categories
          ? 'a kategória-kosárból'
          : selectedCategory == null
          ? 'a scopeból'
          : 'a kategóriából',
      listSurface: listSurface,
      listSoftness: listSoftness,
      onCenterTap: onCenterTap,
      onEntryTap: (entry) {
        final category = entry.category;
        if (category != null) onCategoryTap(category);
      },
    );

    if (surface == _PanelSurface.background) {
      return KeyedSubtree(
        key: const ValueKey('spendee-test-budget-pie-background'),
        child: content,
      );
    }

    if (surface == _PanelSurface.htmlC2Glass) {
      return _C2GlassSurface(
        key: const ValueKey('spendee-test-budget-pie-html-c2-glass'),
        clipKey: const ValueKey('spendee-test-budget-pie-html-c2-clip'),
        paintKey: const ValueKey('spendee-test-budget-pie-html-c2-paint'),
        maskKey: const ValueKey('spendee-test-budget-pie-html-c2-mask'),
        borderRadius: 17,
        useBottomFade: false,
        child: content,
      );
    }

    if (surface == _PanelSurface.liquidGlass) {
      return SpendeeLiquidGlassSurface(
        key: const ValueKey('spendee-test-budget-pie-liquid-glass'),
        fallbackKey: const ValueKey('spendee-test-budget-pie-liquid-fallback'),
        glareKey: const ValueKey('spendee-test-budget-pie-liquid-glare'),
        borderRadius: 17,
        softness: softness,
        child: content,
      );
    }

    if (surface == _PanelSurface.acrylic) {
      return SpendeeAcrylicSurface(
        key: const ValueKey('spendee-test-budget-pie-acrylic'),
        fluentKey: const ValueKey('spendee-test-budget-pie-acrylic-fluent'),
        borderRadius: 17,
        child: content,
      );
    }

    return Container(
      key: const ValueKey('spendee-test-budget-pie-panel'),
      decoration: _budgetPieGlassDecoration(),
      child: ClipRRect(borderRadius: BorderRadius.circular(17), child: content),
    );
  }

  List<_BudgetShareEntry> _categoryEntries() {
    return [
      for (final bar in bars.where((bar) => bar.spent > 0))
        _BudgetShareEntry(
          key: bar.targetId.toString(),
          rowKey: ValueKey('spendee-test-budget-pie-row-${bar.targetId}'),
          rowSurfaceKeyBase: 'spendee-test-budget-pie-row-${bar.targetId}',
          title: bar.title,
          amount: bar.spent,
          count: 1,
          color: bar.color,
          dotGradient: CategoryColorManager.gradient(bar.category?.colorSlot),
          category: bar.category,
        ),
    ];
  }

  List<_BudgetShareEntry> _vendorEntries() {
    final categoryId = selectedCategory?.transactionCategoryID;
    final categoriesById = {
      for (final bar in bars)
        if (bar.category != null)
          bar.category!.transactionCategoryID: bar.category!,
    };
    final totals = <String, _VendorShareAccumulator>{};
    for (final record in transactions) {
      if (categoryId != null && record.transactionCategoryID != categoryId) {
        continue;
      }
      final amount = record.amount.abs();
      if (amount <= 0) continue;
      final rawName = record.displayMerchant.trim();
      final fallbackName = record.merchant.trim();
      final name = rawName.isNotEmpty
          ? rawName
          : fallbackName.isNotEmpty
          ? fallbackName
          : 'Ismeretlen vendor';
      final recordCategoryId = record.transactionCategoryID;
      totals.update(
        name,
        (rollup) => rollup.add(amount, recordCategoryId),
        ifAbsent: () => _VendorShareAccumulator(
          name: name,
          amount: amount,
          count: 1,
          categoryAmounts: recordCategoryId == null
              ? const <int, double>{}
              : <int, double>{recordCategoryId: amount},
        ),
      );
    }
    final vendors = totals.values.toList()
      ..sort((left, right) {
        final totalOrder = right.amount.compareTo(left.amount);
        if (totalOrder != 0) return totalOrder;
        return left.name.compareTo(right.name);
      });
    return [
      for (var index = 0; index < vendors.length; index++)
        _vendorShareEntry(
          vendors[index],
          index,
          vendors[index].dominantCategory(categoriesById),
        ),
    ];
  }

  _BudgetShareEntry _vendorShareEntry(
    _VendorShareAccumulator vendor,
    int index,
    TransactionCategory? category,
  ) {
    final fallbackColor =
        _stage2VendorPalette[index % _stage2VendorPalette.length];
    final fallbackGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        fallbackColor.withValues(alpha: .78),
        _stage2VendorPalette[(index + 2) % _stage2VendorPalette.length],
      ],
    );
    return _BudgetShareEntry(
      key: vendor.name,
      rowKey: ValueKey('spendee-test-budget-vendor-row-$index'),
      rowSurfaceKeyBase: 'spendee-test-budget-vendor-row-$index',
      title: vendor.name,
      amount: vendor.amount,
      count: vendor.count,
      color: category?.slotColor ?? fallbackColor,
      dotGradient: category == null
          ? fallbackGradient
          : CategoryColorManager.gradient(category.colorSlot),
      category: category,
    );
  }
}

List<_BudgetShareEntry> _withoutRoundedZeroShares(
  List<_BudgetShareEntry> entries,
  double total,
) {
  if (total <= 0) return entries;
  final visible = [
    for (final entry in entries)
      if ((entry.amount / total * 100).round() > 0) entry,
  ];
  if (visible.isNotEmpty) return visible;
  return entries.isEmpty ? entries : <_BudgetShareEntry>[entries.first];
}

BoxDecoration _budgetPieGlassDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(17),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x5CFFFFFF), Color(0x26FFFFFF)],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: .52),
        offset: const Offset(0, 1),
        blurRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: .08),
        offset: const Offset(0, 7),
        blurRadius: 18,
      ),
    ],
  );
}

class _BudgetPieContent extends StatelessWidget {
  const _BudgetPieContent({
    super.key,
    required this.budgetSpec,
    required this.entries,
    required this.total,
    required this.selectedKey,
    required this.selectedEntry,
    required this.selectedPercent,
    required this.focusLabel,
    required this.focusTitleKey,
    required this.focusSuffix,
    required this.listSurface,
    required this.listSoftness,
    required this.onCenterTap,
    required this.onEntryTap,
  });

  final SpendeeBudgetStageSpec budgetSpec;
  final List<_BudgetShareEntry> entries;
  final double total;
  final String? selectedKey;
  final _BudgetShareEntry? selectedEntry;
  final int selectedPercent;
  final String focusLabel;
  final Key focusTitleKey;
  final String focusSuffix;
  final _ChartListSurface listSurface;
  final double listSoftness;
  final VoidCallback onCenterTap;
  final ValueChanged<_BudgetShareEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: const ValueKey('spendee-test-budget-pie-fixed-top'),
            height: budgetSpec.donutVisualSize,
            child: Row(
              children: [
                SizedBox(
                  key: const ValueKey('spendee-test-budget-pie-donut'),
                  width: budgetSpec.donutVisualSize,
                  height: budgetSpec.donutVisualSize,
                  child: _BudgetPieHitRegion(
                    entries: entries,
                    total: total,
                    onEntryTap: onEntryTap,
                    onCenterTap: onCenterTap,
                    child: CustomPaint(
                      painter: _BudgetPiePainter(
                        entries: entries,
                        total: total,
                        selectedKey: selectedKey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetPieFocus(
                    key: const ValueKey('spendee-test-budget-pie-focus'),
                    titleKey: focusTitleKey,
                    entry: selectedEntry,
                    percent: selectedPercent,
                    label: focusLabel,
                    suffix: focusSuffix,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('spendee-test-budget-pie-list-scroll'),
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _BudgetPieRow(
                  entry: entry,
                  total: total,
                  selected: entry.key == selectedKey,
                  surface: listSurface,
                  softness: listSoftness,
                  onTap: () => onEntryTap(entry),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPieHitRegion extends StatelessWidget {
  const _BudgetPieHitRegion({
    required this.entries,
    required this.total,
    required this.onEntryTap,
    required this.onCenterTap,
    required this.child,
  });

  final List<_BudgetShareEntry> entries;
  final double total;
  final ValueChanged<_BudgetShareEntry> onEntryTap;
  final VoidCallback onCenterTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox;
        final target = _hitTest(details.localPosition, box.size);
        if (target == _BudgetPieTapTarget.center) {
          onCenterTap();
          return;
        }
        final entry = target.entry;
        if (entry != null) onEntryTap(entry);
      },
      child: child,
    );
  }

  _BudgetPieTapTarget _hitTest(Offset position, Size size) {
    final budgetSpec = _budgetHeaderVisualSpec.budget;
    final center = Offset(size.width / 2, size.height / 2);
    final scale =
        math.min(size.width, size.height) / budgetSpec.donutCoordinateSize;
    final radius = budgetSpec.donutRadius * scale;
    final selectedStrokeWidth = budgetSpec.donutSelectedStrokeWidth * scale;
    final centerRadius = budgetSpec.donutCenterRadius * scale;
    final distance = (position - center).distance;
    if (distance <= centerRadius) return _BudgetPieTapTarget.center;
    if (total <= 0 || entries.isEmpty) return _BudgetPieTapTarget.none;
    if (distance > radius + selectedStrokeWidth / 2 + 8) {
      return _BudgetPieTapTarget.none;
    }
    if (distance < centerRadius + 3) return _BudgetPieTapTarget.none;

    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    var normalized = angle + math.pi / 2;
    while (normalized < 0) {
      normalized += math.pi * 2;
    }
    while (normalized >= math.pi * 2) {
      normalized -= math.pi * 2;
    }

    var cursor = 0.0;
    for (final entry in entries) {
      final sweep = (entry.amount / total) * math.pi * 2;
      if (normalized >= cursor && normalized <= cursor + sweep) {
        return _BudgetPieTapTarget.entry(entry);
      }
      cursor += sweep;
    }
    return _BudgetPieTapTarget.entry(entries.last);
  }
}

class _BudgetPieTapTarget {
  const _BudgetPieTapTarget._({this.entry, this.isCenter = false});

  const _BudgetPieTapTarget.entry(_BudgetShareEntry entry)
    : this._(entry: entry);

  static const none = _BudgetPieTapTarget._();
  static const center = _BudgetPieTapTarget._(isCenter: true);

  final _BudgetShareEntry? entry;
  final bool isCenter;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _BudgetPieTapTarget &&
            other.entry == entry &&
            other.isCenter == isCenter;
  }

  @override
  int get hashCode => Object.hash(entry, isCenter);
}

class _BudgetPieRow extends StatelessWidget {
  const _BudgetPieRow({
    required this.entry,
    required this.total,
    required this.selected,
    required this.surface,
    required this.softness,
    required this.onTap,
  });

  final _BudgetShareEntry entry;
  final double total;
  final bool selected;
  final _ChartListSurface surface;
  final double softness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (entry.amount / total * 100).round();
    final child = _BudgetPieRowBody(entry: entry, percent: percent);
    return GestureDetector(
      key: entry.rowKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: switch (surface) {
        _ChartListSurface.none => _BudgetPieRowPaddedSurface(
          key: ValueKey('${entry.rowSurfaceKeyBase}-pillless'),
          child: child,
        ),
        _ChartListSurface.original => Container(
          key: ValueKey('${entry.rowSurfaceKeyBase}-original'),
          constraints: const BoxConstraints(minHeight: 25),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: _budgetPieRowOriginalDecoration(entry, selected),
          child: child,
        ),
        _ChartListSurface.htmlC2Glass => _C2GlassSurface(
          key: ValueKey('${entry.rowSurfaceKeyBase}-html-c2-glass'),
          clipKey: ValueKey('${entry.rowSurfaceKeyBase}-html-c2-clip'),
          paintKey: ValueKey('${entry.rowSurfaceKeyBase}-html-c2-paint'),
          maskKey: ValueKey('${entry.rowSurfaceKeyBase}-html-c2-mask'),
          borderRadius: 12,
          useBottomFade: false,
          child: _BudgetPieRowPaddedSurface(child: child),
        ),
        _ChartListSurface.liquidGlass => SpendeeLiquidGlassSurface(
          key: ValueKey('${entry.rowSurfaceKeyBase}-liquid-glass'),
          fallbackKey: ValueKey('${entry.rowSurfaceKeyBase}-liquid-fallback'),
          glareKey: ValueKey('${entry.rowSurfaceKeyBase}-liquid-glare'),
          borderRadius: 12,
          softness: softness,
          child: _BudgetPieRowPaddedSurface(child: child),
        ),
        _ChartListSurface.acrylic => SpendeeAcrylicSurface(
          key: ValueKey('${entry.rowSurfaceKeyBase}-acrylic'),
          fluentKey: ValueKey('${entry.rowSurfaceKeyBase}-acrylic-fluent'),
          borderRadius: 12,
          child: _BudgetPieRowPaddedSurface(child: child),
        ),
      },
    );
  }
}

class _BudgetPieRowPaddedSurface extends StatelessWidget {
  const _BudgetPieRowPaddedSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}

class _BudgetPieRowBody extends StatelessWidget {
  const _BudgetPieRowBody({required this.entry, required this.percent});

  final _BudgetShareEntry entry;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          key: ValueKey('${entry.rowSurfaceKeyBase}-dot'),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: entry.dotGradient,
            boxShadow: [
              BoxShadow(
                color: entry.color.withValues(alpha: .48),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entry.title,
            overflow: TextOverflow.ellipsis,
            style: _pieRowStyle,
          ),
        ),
        Text('$percent% · ${_formatFt(entry.amount)}', style: _pieValueStyle),
      ],
    );
  }
}

BoxDecoration _budgetPieRowOriginalDecoration(
  _BudgetShareEntry entry,
  bool selected,
) {
  return BoxDecoration(
    gradient: selected
        ? RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.1,
            colors: [
              Colors.white.withValues(alpha: .50),
              entry.color.withValues(alpha: .18),
            ],
          )
        : null,
    color: selected ? null : Colors.white.withValues(alpha: .18),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      if (selected)
        BoxShadow(
          color: entry.color.withValues(alpha: .24),
          offset: const Offset(0, 8),
          blurRadius: 18,
        ),
      BoxShadow(
        color: Colors.white.withValues(alpha: selected ? .42 : .24),
        offset: const Offset(0, 1),
        blurRadius: 0,
      ),
    ],
  );
}

class _BudgetPieFocus extends StatelessWidget {
  const _BudgetPieFocus({
    super.key,
    required this.titleKey,
    required this.entry,
    required this.percent,
    required this.label,
    required this.suffix,
  });

  final Key titleKey;
  final _BudgetShareEntry? entry;
  final int percent;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _pieFocusLabelStyle),
        const SizedBox(height: 5),
        Text(
          entry?.title ?? 'Nincs adat',
          key: titleKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _pieFocusTitleStyle,
        ),
        const SizedBox(height: 5),
        Text(
          entry == null
              ? '0 Ft $suffix'
              : '${_formatFt(entry!.amount)} · $percent% $suffix',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _pieFocusMetaStyle,
        ),
      ],
    );
  }
}

class _BudgetPiePainter extends CustomPainter {
  const _BudgetPiePainter({
    required this.entries,
    required this.total,
    required this.selectedKey,
  });

  final List<_BudgetShareEntry> entries;
  final double total;
  final String? selectedKey;

  @override
  void paint(Canvas canvas, Size size) {
    final budgetSpec = _budgetHeaderVisualSpec.budget;
    final center = Offset(size.width / 2, size.height / 2);
    final scale =
        math.min(size.width, size.height) / budgetSpec.donutCoordinateSize;
    final radius = budgetSpec.donutRadius * scale;
    final baseStrokeWidth = budgetSpec.donutBaseStrokeWidth * scale;
    final selectedStrokeWidth = budgetSpec.donutSelectedStrokeWidth * scale;
    final centerRadius = budgetSpec.donutCenterRadius * scale;
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius + 3));
    canvas.drawShadow(
      shadowPath,
      const Color(0xFF0F172A).withValues(alpha: .16),
      10,
      false,
    );
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStrokeWidth
      ..color = Colors.white.withValues(alpha: .40);
    canvas.drawCircle(center, radius, basePaint);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final entry in entries) {
      final sweep = (entry.amount / total) * math.pi * 2;
      final selected = entry.key == selectedKey;
      if (selected) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selectedStrokeWidth
          ..strokeCap = StrokeCap.butt
          ..color = entry.color.withValues(
            alpha: budgetSpec.donutSelectedGlowOpacity,
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            budgetSpec.donutSelectedGlowBlur * scale,
          );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          glowPaint,
        );
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? selectedStrokeWidth : baseStrokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = selected ? entry.color : entry.color.withValues(alpha: .74);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      centerRadius,
      Paint()..color = Colors.white.withValues(alpha: .40),
    );
    canvas.drawCircle(
      center,
      centerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .48),
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetPiePainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.total != total ||
        oldDelegate.selectedKey != selectedKey;
  }
}

class _SpendeeHomeContent extends StatefulWidget {
  const _SpendeeHomeContent({
    super.key,
    required this.store,
    required this.expenseTheme,
    required this.stageListenable,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final ValueListenable<SpendeeHeaderStage> stageListenable;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  @override
  State<_SpendeeHomeContent> createState() => _SpendeeHomeContentState();
}

class _SpendeeHomeLogSnapshot {
  const _SpendeeHomeLogSnapshot({
    required this.transactionCount,
    required this.entries,
    required this.categoriesById,
  });

  final int transactionCount;
  final List<TransactionLogEntry> entries;
  final Map<int, TransactionCategory> categoriesById;
}

class _SpendeeHomeContentState extends State<_SpendeeHomeContent> {
  static const _summaryDragLimit = 64.0;
  static const _summaryShiftDistance = 34.0;
  static const _summaryWindowCycleDistance = 34.0;

  var _summaryDragDx = 0.0;
  var _summaryDragDy = 0.0;
  var _summaryDragging = false;
  var _summaryTicked = false;
  Axis? _summaryDragAxis;
  Offset? _summaryDragStart;
  _SpendeeHomeLogSnapshot? _logSnapshot;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_handleStoreChanged);
  }

  @override
  void didUpdateWidget(covariant _SpendeeHomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_handleStoreChanged);
      widget.store.addListener(_handleStoreChanged);
      _logSnapshot = null;
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChanged);
    super.dispose();
  }

  void _handleStoreChanged() {
    _logSnapshot = null;
    if (!mounted) return;
    setState(() {});
  }

  _SpendeeHomeLogSnapshot _snapshotLogInputs() {
    final cached = _logSnapshot;
    if (cached != null) return cached;
    final snapshot = _SpendeeHomeLogSnapshot(
      transactionCount: widget.store.visibleTransactions.length,
      entries: widget.store.visibleDisplayLogEntries,
      categoriesById: widget.store.categoriesById,
    );
    _logSnapshot = snapshot;
    return snapshot;
  }

  List<SearchPillFilter> _categorySearchFilters() {
    final filters = <SearchPillFilter>[];
    final ids = widget.store.activeCategoryIds.toList()..sort();
    for (final id in ids) {
      final category = widget.store.categoriesById[id];
      if (category == null) continue;
      filters.add(
        SearchPillFilter(
          id: id.toString(),
          label: category.name,
          color: category.slotColor,
          onClear: () => widget.store.clearCategoryFilterId(id),
        ),
      );
    }
    if (filters.isEmpty) return const <SearchPillFilter>[];
    return filters;
  }

  List<SearchPillFilter> _merchantSearchFilters() {
    final merchants = widget.store.activeMerchantFilters.toList()..sort();
    return [
      for (final merchant in merchants)
        SearchPillFilter(
          id: merchant,
          label: merchant,
          color: widget.expenseTheme.accent,
          onClear: () => widget.store.clearMerchantFilter(merchant),
        ),
    ];
  }

  void _handleSummaryPointerDown(PointerDownEvent event) {
    _summaryDragStart = event.position;
    if (_summaryDragDx == 0 && _summaryDragDy == 0 && !_summaryDragging) {
      return;
    }
    setState(() {
      _summaryDragging = false;
      _summaryDragDx = 0;
      _summaryDragDy = 0;
      _summaryTicked = false;
      _summaryDragAxis = null;
    });
  }

  void _handleSummaryPointerMove(PointerMoveEvent event) {
    final start = _summaryDragStart;
    if (start == null) return;
    final delta = event.position - start;
    if (!_summaryDragging) {
      if (delta.distance < 8) return;
      _summaryDragAxis = delta.dx.abs() >= delta.dy.abs()
          ? Axis.horizontal
          : Axis.vertical;
    }
    final axis = _summaryDragAxis ?? Axis.horizontal;
    final nextDx = axis == Axis.horizontal
        ? delta.dx.clamp(-_summaryDragLimit, _summaryDragLimit).toDouble()
        : 0.0;
    final nextDy = axis == Axis.vertical
        ? delta.dy.clamp(-_summaryDragLimit, _summaryDragLimit).toDouble()
        : 0.0;
    final threshold = axis == Axis.vertical
        ? _summaryWindowCycleDistance
        : _summaryShiftDistance;
    if (!_summaryTicked) {
      final travelled = axis == Axis.vertical ? nextDy.abs() : nextDx.abs();
      if (travelled >= threshold) {
        _summaryTicked = true;
        HapticFeedback.selectionClick();
        DebugConsole.log(
          '[Perf] SpendeeTest summary_tick axis=${axis.name} '
          'direction=${axis == Axis.vertical ? nextDy.sign : nextDx.sign}',
        );
      }
    }
    if ((nextDx - _summaryDragDx).abs() < .1 &&
        (nextDy - _summaryDragDy).abs() < .1) {
      return;
    }
    setState(() {
      _summaryDragging = true;
      _summaryDragDx = nextDx;
      _summaryDragDy = nextDy;
    });
  }

  void _handleSummaryPointerUp(PointerUpEvent event) {
    final start = _summaryDragStart;
    final delta = start == null
        ? Offset(_summaryDragDx, 0)
        : event.position - start;
    final horizontal = delta.dx.abs();
    final vertical = delta.dy.abs();
    if (horizontal >= _summaryShiftDistance && horizontal >= vertical) {
      if (widget.store.summaryWindow != SummaryWindow.allTime) {
        unawaited(widget.store.shiftSummaryPeriod(delta.dx < 0 ? 1 : -1));
      }
    } else if (vertical >= _summaryWindowCycleDistance &&
        vertical > horizontal) {
      unawaited(widget.store.cycleSummaryWindow());
    }
    _resetSummaryDrag();
  }

  void _handleSummaryPointerCancel(PointerCancelEvent event) {
    _resetSummaryDrag();
  }

  void _resetSummaryDrag() {
    _summaryDragStart = null;
    if (!_summaryDragging && _summaryDragDx == 0 && _summaryDragDy == 0) {
      return;
    }
    setState(() {
      _summaryDragging = false;
      _summaryDragDx = 0;
      _summaryDragDy = 0;
      _summaryTicked = false;
      _summaryDragAxis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final onPickSummaryMonth = widget.onPickSummaryMonth;
    final onEditTransaction = widget.onEditTransaction;
    final onDeleteTransactionRequested = widget.onDeleteTransactionRequested;
    final onVendorSheetRequested = widget.onVendorSheetRequested;
    final logBottomPadding = widget.logBottomPadding;

    return ValueListenableBuilder<SpendeeHeaderStage>(
      valueListenable: widget.stageListenable,
      builder: (context, stage, _) {
        final contentStartedAt = DateTime.now();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final elapsed = DateTime.now()
              .difference(contentStartedAt)
              .inMilliseconds;
          if (elapsed <= 32) return;
          DebugConsole.log(
            '[Perf] SpendeeTest content_frame stage=${stage.name} '
            'type=${store.activeType.name} elapsed=${elapsed}ms '
            'jank=true',
          );
        });
        return LayoutBuilder(
          builder: (context, constraints) {
            const fixedDashboardControlsHeight = 66.0 + 59.0 + 12.0 + 45.0;
            const transactionHeaderHeight = 24.0;
            final canShowTransactionLog =
                stage != SpendeeHeaderStage.stage2 &&
                constraints.maxHeight >=
                    fixedDashboardControlsHeight + transactionHeaderHeight;
            final logSnapshot = canShowTransactionLog
                ? _snapshotLogInputs()
                : null;
            return Column(
              children: [
                SizedBox(
                  key: const ValueKey('spendee-test-type-row'),
                  height: 66,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SpendeeTypePill(
                            key: const ValueKey(
                              'spendee-test-income-type-pill',
                            ),
                            label: 'Bevétel',
                            active: store.activeType == TransactionType.income,
                            activeGradient: const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                            boxShadows: const <BoxShadow>[
                              BoxShadow(
                                color: Color.fromRGBO(15, 23, 42, .08),
                                offset: Offset(0, 10),
                                blurRadius: 23,
                              ),
                            ],
                            textColor:
                                store.activeType == TransactionType.income
                                ? const Color(0xFF14213A)
                                : AppColors.gray500,
                            onTap: () =>
                                store.setActiveType(TransactionType.income),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SpendeeTypePill(
                            key: const ValueKey(
                              'spendee-test-expense-type-pill',
                            ),
                            label: 'Kiadás',
                            active: store.activeType == TransactionType.expense,
                            activeGradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFB15C),
                                Color(0xFFFF6B6B),
                                Color(0xFFF5368D),
                              ],
                            ),
                            boxShadows: const <BoxShadow>[
                              BoxShadow(
                                color: Color.fromRGBO(15, 23, 42, .08),
                                offset: Offset(0, 12),
                                blurRadius: 24,
                              ),
                            ],
                            textColor:
                                store.activeType == TransactionType.expense
                                ? Colors.white
                                : AppColors.gray500,
                            onTap: () =>
                                store.setActiveType(TransactionType.expense),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Listener(
                  onPointerDown: _handleSummaryPointerDown,
                  onPointerMove: _handleSummaryPointerMove,
                  onPointerUp: _handleSummaryPointerUp,
                  onPointerCancel: _handleSummaryPointerCancel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPickSummaryMonth,
                    onDoubleTap: store.resetSummaryToCurrentMonth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: AnimatedContainer(
                        key: const ValueKey('spendee-test-summary-pill'),
                        duration: _summaryDragging
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(
                          _summaryDragDx,
                          _summaryDragDy,
                          0,
                        ),
                        height: 59,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: _softWhiteDecoration(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                store.activeSummaryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              store.activeSummary.formattedFor(
                                store.activeType,
                              ),
                              style: const TextStyle(
                                color: AppColors.gray800,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    height: 45,
                    child: SearchPill(
                      key: const ValueKey('spendee-test-search-pill'),
                      query: store.searchQuery,
                      onQueryChanged: store.setSearchQuery,
                      surfaceColor: widget.expenseTheme.logBox,
                      surfaceStyle: widget.expenseTheme.contentSurfaceStyle,
                      merchantFilters: _merchantSearchFilters(),
                      categoryFilters: _categorySearchFilters(),
                      accentColor: widget.expenseTheme.accent,
                      shadowEnabled: true,
                      surfaceMargin: EdgeInsets.zero,
                      surfaceConstraints: const BoxConstraints.tightFor(
                        height: 45,
                      ),
                      surfacePadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      onVendorListPressed: onVendorSheetRequested,
                    ),
                  ),
                ),
                if (canShowTransactionLog) ...[
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: Text(
                        '${logSnapshot!.transactionCount} tranzakció',
                        key: const ValueKey('spendee-test-transaction-count'),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _SpendeeLogList(
                      entries: logSnapshot.entries,
                      categoriesById: logSnapshot.categoriesById,
                      bottomPadding: logBottomPadding,
                      onFastFilter: (record, _) =>
                          store.setMerchantFilter(record.displayMerchant),
                      onRecordTap: onEditTransaction,
                      onDeleteRequested: onDeleteTransactionRequested,
                      onCategoryFilter: store.setCategoryFilter,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SpendeeTypePill extends StatelessWidget {
  const _SpendeeTypePill({
    super.key,
    required this.label,
    required this.active,
    required this.activeGradient,
    required this.boxShadows,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Gradient activeGradient;
  final List<BoxShadow> boxShadows;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: active ? activeGradient : null,
          color: active ? null : Colors.white,
          boxShadow: boxShadows,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SpendeeLogList extends StatelessWidget {
  const _SpendeeLogList({
    required this.entries,
    required this.categoriesById,
    required this.bottomPadding,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
  });

  final List<TransactionLogEntry> entries;
  final Map<int, TransactionCategory> categoriesById;
  final double bottomPadding;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord>? onRecordTap;
  final TransactionDeleteRequest? onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottomPadding),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final header = entry.header;
        if (header != null) {
          return SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
              child: Text(
                header,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }
        final record = entry.record;
        if (record == null) return const SizedBox.shrink();
        final category = categoriesById[record.transactionCategoryID];
        return _SpendeeLogBox(
          record: record,
          category: category,
          onTap: onRecordTap,
          onFastFilter: onFastFilter,
          onDeleteRequested: onDeleteRequested,
          onCategoryFilter: onCategoryFilter,
        );
      },
    );
  }
}

class _SpendeeLogBox extends StatefulWidget {
  const _SpendeeLogBox({
    required this.record,
    required this.category,
    required this.onTap,
    required this.onFastFilter,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
  });

  final TransactionRecord record;
  final TransactionCategory? category;
  final ValueChanged<TransactionRecord>? onTap;
  final TransactionLogContextCallback onFastFilter;
  final TransactionDeleteRequest? onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;

  @override
  State<_SpendeeLogBox> createState() => _SpendeeLogBoxState();
}

class _SpendeeLogBoxState extends State<_SpendeeLogBox> {
  static const _filterDistance = 80.0;
  static const _deleteDistance = 70.0;
  static const _minFlingVelocity = 200.0;
  static const _maxVisualOffset = 28.0;

  double _dragDx = 0;
  bool _triggered = false;

  void _startDrag() {
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    setState(() => _dragDx += details.delta.dx);
    _dispatchByDistance();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_triggered) {
      final velocityDx = details.velocity.pixelsPerSecond.dx;
      if (_dragDx <= -_filterDistance || velocityDx < -_minFlingVelocity) {
        _triggerFastFilter();
      } else if (_dragDx >= _deleteDistance || velocityDx > _minFlingVelocity) {
        _triggerDeleteRequest();
      }
    }
    if (mounted) setState(() => _dragDx = 0);
  }

  void _dispatchByDistance() {
    if (_dragDx <= -_filterDistance) {
      _triggerFastFilter();
    } else if (_dragDx >= _deleteDistance) {
      _triggerDeleteRequest();
    }
  }

  void _triggerFastFilter() {
    if (_triggered) return;
    _triggered = true;
    widget.onFastFilter(widget.record, widget.category);
  }

  void _triggerDeleteRequest() {
    if (_triggered || widget.onDeleteRequested == null) return;
    _triggered = true;
    unawaited(
      Future<bool>.sync(() => widget.onDeleteRequested!(widget.record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final category = widget.category;
    final amountColor = record.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return GestureDetector(
      key: ValueKey('spendee-test-logbox-${record.id}'),
      onTap: () => widget.onTap?.call(record),
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragCancel: () => setState(() => _dragDx = 0),
      onHorizontalDragEnd: _handleDragEnd,
      child: Transform.translate(
        key: ValueKey('spendee-test-logbox-card-${record.id}'),
        offset: Offset(_dragDx.clamp(-_maxVisualOffset, _maxVisualOffset), 0),
        child: Container(
          height: 64.8,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: _softWhiteDecoration(18),
          child: Row(
            children: [
              GestureDetector(
                onTap: category == null
                    ? null
                    : () => widget.onCategoryFilter(category),
                child: GlossyCategoryAvatar(
                  category: category,
                  size: 46,
                  iconSize: 28,
                  showQuestionMark: category == null,
                  showTopHighlight: false,
                  debugSource: 'spendee-test-logbox',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayMerchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category?.name ?? 'Kategória nélkül',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gray500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.displayAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.displayTime,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

class _AppCornerFullscreenButton extends StatelessWidget {
  const _AppCornerFullscreenButton({
    required this.fullscreen,
    required this.requestPending,
    required this.onPressed,
  });

  final bool fullscreen;
  final bool requestPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .62)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .54),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1F2D46).withValues(alpha: .10),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: IconButton(
        key: const ValueKey('spendee-test-app-fullscreen-button'),
        tooltip: fullscreen
            ? 'Kilépés a teljes képernyőből'
            : 'Teljes képernyő',
        padding: EdgeInsets.zero,
        onPressed: requestPending ? null : onPressed,
        icon: Icon(
          fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: const Color(0xFF14213A),
          size: 20,
        ),
      ),
    );
  }
}

class _SpendeeBrandLockup extends StatelessWidget {
  const _SpendeeBrandLockup({
    super.key,
    required this.logoFills,
    required this.onLogoTap,
  });

  static const _logoSize = 47.88;

  final Map<FluviLogoArc, FluviLogoFill> logoFills;
  final VoidCallback onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 30,
          top: 6,
          width: _logoSize,
          height: _logoSize,
          child: GestureDetector(
            key: const ValueKey('spendee-test-brand-logo-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: onLogoTap,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: const Offset(0, 3),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0x1A0F172A),
                        BlendMode.srcIn,
                      ),
                      child: FluviLogo(fills: logoFills),
                    ),
                  ),
                ),
                FluviLogo(
                  key: const ValueKey('spendee-test-brand-logo'),
                  fills: logoFills,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 82.25,
          top: 10.602,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'fluvi',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF14213A),
                  fontSize: 30.096,
                  height: .96,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 1.368),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'your personal '),
                    TextSpan(
                      text: 'financial trainer',
                      style: TextStyle(color: Color(0xFF06AECA)),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFF536078),
                  fontSize: 13.84416,
                  height: 1.02,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoEditorSheet extends StatefulWidget {
  const _LogoEditorSheet({required this.fills, required this.onFillChanged});

  final Map<FluviLogoArc, FluviLogoFill> fills;
  final void Function(FluviLogoArc arc, FluviLogoFill fill) onFillChanged;

  @override
  State<_LogoEditorSheet> createState() => _LogoEditorSheetState();
}

class _LogoEditorSheetState extends State<_LogoEditorSheet> {
  late _LogoPaletteChoice _selectedFill = _categoryLogoChoice(7);
  late final List<_CustomLogoGradientSlot> _customSlots =
      _CustomLogoGradientSlot.defaults();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('spendee-test-logo-editor-sheet'),
        margin: const EdgeInsets.only(top: 72),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              offset: const Offset(0, -10),
              blurRadius: 30,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF536078).withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                key: const ValueKey('spendee-test-logo-editor-preview'),
                height: 178,
                child: Center(
                  child: _LogoComponentPreview(
                    fills: widget.fills,
                    onComponentTap: _applySelectedFill,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _htmlSelectedLogoPalette)
                    _LogoSwatchButton(
                      key: ValueKey(
                        'spendee-test-logo-palette-selected-${choice.id}',
                      ),
                      fill: choice.fill,
                      selected: _selectedFill.id == choice.id,
                      onTap: () => setState(() => _selectedFill = choice),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _htmlAppLogoPalette)
                    _LogoSwatchButton(
                      key: ValueKey(
                        'spendee-test-logo-palette-app-${choice.id}',
                      ),
                      fill: choice.fill,
                      selected: _selectedFill.id == choice.id,
                      onTap: () => setState(() => _selectedFill = choice),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in CategoryColorManager.slots)
                    _LogoSwatchButton(
                      key: ValueKey('spendee-test-logo-palette-slot-$slot'),
                      fill: _categoryLogoChoice(slot).fill,
                      selected: _selectedFill.id == 'slot-$slot',
                      onTap: () {
                        setState(() {
                          _selectedFill = _categoryLogoChoice(slot);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final slot in _customSlots) ...[
                _CustomLogoGradientSlotEditor(
                  key: ValueKey('spendee-test-logo-custom-slot-${slot.id}'),
                  slot: slot,
                  selectedFill: () => _selectedFill,
                  selected: _selectedFill.id == 'custom-${slot.id}',
                  onSelect: () {
                    setState(() => _selectedFill = slot.toChoice());
                  },
                  onChanged: () {
                    setState(() {
                      if (_selectedFill.id == 'custom-${slot.id}') {
                        _selectedFill = slot.toChoice();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _applySelectedFill(FluviLogoArc arc) {
    widget.onFillChanged(arc, _selectedFill.fill);
    setState(() {});
  }
}

class _LogoComponentPreview extends StatelessWidget {
  const _LogoComponentPreview({
    required this.fills,
    required this.onComponentTap,
  });

  final Map<FluviLogoArc, FluviLogoFill> fills;
  final ValueChanged<FluviLogoArc> onComponentTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              FluviLogo(
                key: const ValueKey('spendee-test-fluvi-logo-preview'),
                fills: fills,
              ),
              Positioned(
                left: width * .22,
                right: width * .12,
                top: height * .12,
                height: height * .34,
                child: _LogoComponentButton(
                  arc: FluviLogoArc.top,
                  onTap: onComponentTap,
                ),
              ),
              Positioned(
                left: width * .22,
                right: width * .28,
                top: height * .46,
                height: height * .40,
                child: _LogoComponentButton(
                  arc: FluviLogoArc.bottom,
                  onTap: onComponentTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogoComponentButton extends StatelessWidget {
  const _LogoComponentButton({required this.arc, required this.onTap});

  final FluviLogoArc arc;
  final ValueChanged<FluviLogoArc> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('spendee-test-logo-component-${arc.name}'),
      behavior: HitTestBehavior.translucent,
      onTap: () => onTap(arc),
      child: const ColoredBox(color: Colors.transparent),
    );
  }
}

class _LogoSwatchButton extends StatelessWidget {
  const _LogoSwatchButton({
    super.key,
    required this.fill,
    required this.selected,
    required this.onTap,
  });

  final FluviLogoFill fill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: fill.gradient,
          border: Border.all(
            color: selected ? const Color(0xFF14213A) : Colors.white,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              offset: const Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomLogoGradientSlotEditor extends StatelessWidget {
  const _CustomLogoGradientSlotEditor({
    super.key,
    required this.slot,
    required this.selectedFill,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final _CustomLogoGradientSlot slot;
  final ValueGetter<_LogoPaletteChoice> selectedFill;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoSwatchButton(
          key: ValueKey('spendee-test-logo-custom-swatch-${slot.id}'),
          fill: slot.toFill(),
          selected: selected,
          onTap: onSelect,
        ),
        const SizedBox(width: 10),
        _EndpointButton(
          key: ValueKey('spendee-test-logo-custom-left-${slot.id}'),
          label: 'L',
          fill: FluviLogoFill.solid(slot.left),
          onTap: () {
            slot.left = selectedFill().fill.left;
            onChanged();
          },
        ),
        const SizedBox(width: 8),
        _EndpointButton(
          key: ValueKey('spendee-test-logo-custom-right-${slot.id}'),
          label: 'R',
          fill: FluviLogoFill.solid(slot.right),
          onTap: () {
            slot.right = selectedFill().fill.right;
            onChanged();
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Slider(
            key: ValueKey('spendee-test-logo-custom-boundary-${slot.id}'),
            value: slot.boundary,
            min: 0,
            max: 100,
            onChanged: (value) {
              slot.boundary = value;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}

class _EndpointButton extends StatelessWidget {
  const _EndpointButton({
    super.key,
    required this.label,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final FluviLogoFill fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: fill.gradient,
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF14213A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LogoPaletteChoice {
  const _LogoPaletteChoice({required this.id, required this.fill});

  _LogoPaletteChoice.solid(String id, Color color)
    : this(id: id, fill: FluviLogoFill.solid(color));

  final String id;
  final FluviLogoFill fill;
}

class _CustomLogoGradientSlot {
  _CustomLogoGradientSlot({
    required this.id,
    required this.left,
    required this.right,
    required this.boundary,
  });

  final int id;
  Color left;
  Color right;
  double boundary;

  FluviLogoFill toFill() {
    return FluviLogoFill(left: left, right: right, boundary: boundary);
  }

  _LogoPaletteChoice toChoice() {
    return _LogoPaletteChoice(id: 'custom-$id', fill: toFill());
  }

  static List<_CustomLogoGradientSlot> defaults() {
    return <_CustomLogoGradientSlot>[
      _CustomLogoGradientSlot(
        id: 1,
        left: Colors.white,
        right: const Color(0xFF0F172A),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 2,
        left: const Color(0xFFF8FAFC),
        right: const Color(0xFF06B6D4),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 3,
        left: const Color(0xFF22C55E),
        right: const Color(0xFF8B5CF6),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 4,
        left: const Color(0xFFFBF8CC),
        right: const Color(0xFFB9FBC0),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 5,
        left: const Color(0xFFD9ED92),
        right: const Color(0xFF184E77),
        boundary: 50,
      ),
    ];
  }
}

_LogoPaletteChoice _categoryLogoChoice(int slot) {
  final colors = CategoryColorManager.gradientStops(slot);
  return _LogoPaletteChoice(
    id: 'slot-$slot',
    fill: FluviLogoFill(
      left: colors.first,
      middle: colors.length > 2 ? colors[1] : null,
      right: colors.last,
      boundary: 52,
    ),
  );
}

final _htmlSelectedLogoPalette = <_LogoPaletteChoice>[
  _LogoPaletteChoice.solid('D1', Color(0xFFFFFFFF)),
  _LogoPaletteChoice.solid('N5', Color(0xFFFCFCFD)),
  _LogoPaletteChoice.solid('O5', Color(0xFFFAFAFA)),
  _LogoPaletteChoice.solid('E1', Color(0xFFF8FAFC)),
  _LogoPaletteChoice.solid('P5', Color(0xFFF7F8FB)),
  _LogoPaletteChoice.solid('A6', Color(0xFFF4F6F8)),
  _LogoPaletteChoice.solid('F1', Color(0xFFF1F5F9)),
  _LogoPaletteChoice.solid('B6', Color(0xFFEEF2F6)),
  _LogoPaletteChoice.solid('N3', Color(0xFFF4F0E8)),
];

final _htmlAppLogoPalette = <_LogoPaletteChoice>[
  _LogoPaletteChoice.solid('white', Color(0xFFFFFFFF)),
  _LogoPaletteChoice.solid('gray50', Color(0xFFF8FAFC)),
  _LogoPaletteChoice.solid('gray100', Color(0xFFF1F5F9)),
  _LogoPaletteChoice.solid('gray200', Color(0xFFE2E8F0)),
  _LogoPaletteChoice.solid('gray300', Color(0xFFCBD5E1)),
  _LogoPaletteChoice.solid('gray400', Color(0xFF94A3B8)),
  _LogoPaletteChoice.solid('gray500', Color(0xFF64748B)),
  _LogoPaletteChoice.solid('gray600', Color(0xFF475569)),
  _LogoPaletteChoice.solid('gray700', Color(0xFF334155)),
  _LogoPaletteChoice.solid('gray800', Color(0xFF1E293B)),
  _LogoPaletteChoice.solid('gray900', Color(0xFF0F172A)),
  _LogoPaletteChoice.solid('primary', Color(0xFF06B6D4)),
  _LogoPaletteChoice.solid('primaryDark', Color(0xFF0891B2)),
  _LogoPaletteChoice.solid('primaryLight', Color(0xFF67E8F9)),
  _LogoPaletteChoice.solid('income', Color(0xFF22C55E)),
  _LogoPaletteChoice.solid('expense', Color(0xFFEF4444)),
];

BoxDecoration _softWhiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1F2D46).withValues(alpha: .08),
        offset: const Offset(0, 8),
        blurRadius: 20,
      ),
      BoxShadow(
        color: const Color(0xFF1F2D46).withValues(alpha: .04),
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
    ],
  );
}

String _formatFt(double value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
  }
  buffer.write(' Ft');
  return buffer.toString();
}

class _HeaderValueText extends StatelessWidget {
  const _HeaderValueText(
    this.value, {
    this.valueKey = const ValueKey('spendee-test-header-value'),
  });

  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _headerValueStyle.copyWith(
            shadows: const <Shadow>[],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .45
              ..color = const Color(0x33FFFFFF),
          ),
        ),
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _headerValueStyle,
        ),
      ],
    );
  }
}

class _PartitionSummaryLabel extends StatelessWidget {
  const _PartitionSummaryLabel({required this.bars, required this.totalLimit});

  final List<CategoryBudgetBarData> bars;
  final double totalLimit;

  @override
  Widget build(BuildContext context) {
    final spent = bars.fold<double>(0, (sum, bar) => sum + bar.spent);
    final effectiveLimit = _effectiveLimit();
    final spentPercent = effectiveLimit > 0
        ? (math.max(0.0, spent) / effectiveLimit * 100).round()
        : 0;
    final remaining = math.max(0.0, effectiveLimit - spent);
    return Row(
      key: const ValueKey('spendee-test-partition-summary-label'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Elköltve: $spentPercent%', style: _partitionSummaryStyle),
        Text('Maradt: ${_formatFt(remaining)}', style: _partitionSummaryStyle),
      ],
    );
  }

  double _effectiveLimit() {
    if (totalLimit > 0) return totalLimit;
    return bars
        .where((bar) => bar.spent > 0 || bar.limitAmount > 0)
        .fold<double>(
          0,
          (sum, bar) =>
              sum + (bar.limitAmount > 0 ? bar.limitAmount : bar.spent),
        );
  }
}

const _headerLabelStyle = TextStyle(
  color: Color(0xB814213A),
  fontSize: 11,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .44,
);

const _headerValueStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 23,
  height: 1.08,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.9,
  shadows: [
    Shadow(color: Color(0x6BFFFFFF), offset: Offset(0, 1)),
    Shadow(color: Color(0x38FFFFFF), offset: Offset(0, 2), blurRadius: 8),
  ],
);

const _partitionSummaryStyle = TextStyle(
  color: Color(0x9414213A),
  fontSize: 9,
  height: 1,
  fontWeight: FontWeight.w800,
);

const _contextAvatarLabelStyle = TextStyle(
  color: Color(0xB814213A),
  fontSize: 11,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .1,
);

const _stage2VendorPalette = <Color>[
  Color(0xFF06B6D4),
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
  Color(0xFFEAB308),
  Color(0xFFEC4899),
];

const _smallCapsStyle = TextStyle(
  color: Color(0xA814213A),
  fontSize: 10,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .5,
);

const _pieFocusLabelStyle = TextStyle(
  color: Color(0x8514213A),
  fontSize: 8,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .48,
);

const _pieFocusTitleStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 18,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: -.72,
);

const _pieFocusMetaStyle = TextStyle(
  color: Color(0x9414213A),
  fontSize: 8,
  height: 1.2,
  fontWeight: FontWeight.w800,
);

const _pieRowStyle = TextStyle(
  color: Color(0xC214213A),
  fontSize: 9,
  height: 1,
  fontWeight: FontWeight.w900,
);

const _pieValueStyle = TextStyle(
  color: Color(0x9E14213A),
  fontSize: 8,
  height: 1,
  fontWeight: FontWeight.w900,
);

part of '../spendee_test_dashboard.dart';

class SpendeeBudgetModeHost extends StatefulWidget {
  const SpendeeBudgetModeHost._({
    super.key,
    required _SpendeeTestDashboardState dashboard,
    required SpendeeDashboardMode variant,
    required Object cacheRevision,
  }) : _dashboard = dashboard,
       _variant = variant,
       _cacheRevision = cacheRevision;

  final _SpendeeTestDashboardState _dashboard;
  final SpendeeDashboardMode _variant;
  final Object _cacheRevision;

  @override
  State<SpendeeBudgetModeHost> createState() => _SpendeeBudgetModeHostState();
}

class _SpendeeBudgetModeHostState extends State<SpendeeBudgetModeHost>
    with TickerProviderStateMixin {
  late final _SpendeeBudgetInteractionRuntime _runtime;
  final _budgetV2LimitPreviewRevision = ValueNotifier<int>(0);
  Widget? _budgetV2DashboardCache;

  @override
  void initState() {
    super.initState();
    _runtime = _SpendeeBudgetInteractionRuntime(vsync: this);
    widget._dashboard._attachBudgetRuntime(
      _runtime,
      _budgetV2LimitPreviewRevision,
    );
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._dashboard != widget._dashboard) {
      oldWidget._dashboard._detachBudgetRuntime(
        _runtime,
        _budgetV2LimitPreviewRevision,
      );
      widget._dashboard._attachBudgetRuntime(
        _runtime,
        _budgetV2LimitPreviewRevision,
      );
    }
    if (oldWidget._variant != widget._variant ||
        oldWidget._cacheRevision != widget._cacheRevision) {
      _budgetV2DashboardCache = null;
    }
  }

  @override
  void dispose() {
    widget._dashboard._detachBudgetRuntime(
      _runtime,
      _budgetV2LimitPreviewRevision,
    );
    _budgetV2DashboardCache = null;
    _runtime.dispose();
    _budgetV2LimitPreviewRevision.dispose();
    super.dispose();
  }

  Widget _budgetV2Dashboard({required bool refresh}) {
    final cached = _budgetV2DashboardCache;
    if (!refresh && cached != null) return cached;
    final input = BalanceFrameInput.fromStore(widget._dashboard.widget.store);
    final frame = BudgetV2FrameData.fromStore(
      widget._dashboard.widget.store,
      input: input,
    );
    final dashboard = widget._dashboard._buildBalanceDashboard(
      input: input,
      presentation: SpendeeBalancePresentation.budgetV2,
      budgetV2Runtime: _BudgetV2DashboardRuntime(
        sourceBars: frame.bars,
        limitPreviewRevision: _budgetV2LimitPreviewRevision,
        pressedAvatarKey: _runtime._budgetLimitEditItem?.category?.key,
        previewBars: widget._dashboard._previewBudgetBars,
        onLimitChanged: (bar, amount) =>
            unawaited(_saveBudgetV2Limit(bar, amount)),
        onAvatarSettled: _applyBudgetV2AvatarFilter,
        onVendorSelected: _applyBudgetV2VendorFilter,
        onAvatarLongPressStart: (bar, details) =>
            widget._dashboard._handleBudgetItemLongPressStart(
              BackheaderBudgetItem.category(bar),
              details,
              diagnosticsSource: 'budget_v2',
            ),
        onAvatarLongPressMoveUpdate: (details) =>
            widget._dashboard._handleBudgetItemLongPressMoveUpdate(
              details,
              diagnosticsSource: 'budget_v2',
            ),
        onAvatarLongPressEnd: (_) => widget._dashboard._finishBudgetLimitEdit(
          diagnosticsSource: 'budget_v2',
          reason: 'end',
        ),
        onAvatarLongPressCancel: () => widget._dashboard._finishBudgetLimitEdit(
          diagnosticsSource: 'budget_v2',
          reason: 'cancel',
        ),
      ),
    );
    _budgetV2DashboardCache = dashboard;
    return dashboard;
  }

  Future<void> _saveBudgetV2Limit(
    CategoryBudgetBarData bar,
    double amount,
  ) async {
    try {
      await widget._dashboard.widget.store.saveCategoryLimitForBarInline(
        bar,
        limitAmount: math.max(0, amount),
        alertActive: amount > 0,
      );
    } catch (error) {
      DebugConsole.log(
        '[Perf] BudgetV2 limit save failed key=${bar.key} error=$error',
      );
    }
  }

  void _applyBudgetV2AvatarFilter(CategoryBudgetBarData bar) {
    final stopwatch = Stopwatch()..start();
    final category = bar.targetType == LimitTargetType.category
        ? bar.category
        : null;
    DebugConsole.log(
      '[BudgetV2Carousel] phase=filter_begin key=${bar.key} '
      'category=${category?.transactionCategoryID ?? 'overview'}',
    );
    final store = widget._dashboard.widget.store;
    store.applyBudgetV2AvatarFilter(category: category);
    DebugConsole.log(
      '[BudgetV2] avatar_filter key=${bar.key} '
      'category=${category?.transactionCategoryID ?? 'overview'} '
      'window=${store.summaryWindow.name}',
    );
    DebugConsole.log(
      '[BudgetV2Carousel] phase=filter_published key=${bar.key} '
      'elapsed_ms=${stopwatch.elapsedMilliseconds}',
    );
  }

  void _applyBudgetV2VendorFilter(String merchant) {
    final normalized = merchant.trim();
    if (normalized.isEmpty) return;
    final store = widget._dashboard.widget.store;
    store.setMerchantFilter(normalized);
    DebugConsole.log(
      '[BudgetV2] vendor_filter merchant=$normalized '
      'categories=${store.activeCategoryIds.join(',')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-budget'),
      child: switch (widget._variant) {
        SpendeeDashboardMode.budget => _buildSpendeeLegacyModeContent(
          context,
          widget._dashboard,
        ),
        SpendeeDashboardMode.budgetV2 => _budgetV2Dashboard(refresh: true),
        _ => throw StateError('Budget host received a non-Budget variant.'),
      },
    );
  }
}

Widget _buildSpendeeLegacyModeContent(
  BuildContext context,
  _SpendeeTestDashboardState dashboard,
) {
  final controller = dashboard._controllerFor(context);
  final geometry = controller.geometry;
  final store = dashboard.widget.store;
  final budgetBars = dashboard._previewBudgetBars(store.categoryBudgetBars);
  final overviewBudgetItems = dashboard._previewOverviewBudgetItems(
    store.overviewBudgetItems,
  );
  final budgetItems = dashboard._previewBudgetItems(
    overviewItems: overviewBudgetItems,
    bars: budgetBars,
  );
  final selectedBudgetItem = dashboard._selectedBudgetItemFor(budgetItems);
  final selectedBar = selectedBudgetItem?.category;
  final selectedCategory = selectedBar?.category;
  var overviewBudgetLimit = 0.0;
  for (final item in overviewBudgetItems) {
    if (item.hasLimit && item.limitAmount > 0) {
      overviewBudgetLimit = item.limitAmount;
      break;
    }
  }
  final contentTop =
      geometry.headerTop + dashboard._headerHeight + geometry.contentGap;
  final animationDuration = dashboard._dragging
      ? Duration.zero
      : const Duration(milliseconds: 360);
  final animationCurve = dashboard._springBack
      ? Curves.elasticOut
      : Curves.easeOutCubic;

  final isMindBackground =
      dashboard._headerBackgroundMode == _HeaderBackgroundMode.mind;
  final mindStatsFrame = isMindBackground
      ? dashboard._mindStatsFrameFor(store, reason: 'header-background-mind')
      : null;
  final mindSumVolumeFrame = mindStatsFrame?.modeKey == 'sum'
      ? dashboard._mindSumVolumeFrameFor(store)
      : null;
  final mindSumYears = mindSumVolumeFrame != null
      ? dashboard._mindSumYearsFor(mindSumVolumeFrame)
      : const <int>[];
  final mindSumSelectedYear = mindSumYears.isEmpty
      ? null
      : dashboard._selectedMindSumYearFor(mindSumYears);
  final mindSumPublishedYear = mindSumYears.isEmpty
      ? null
      : dashboard._publishedMindSumYearFor(mindSumYears);
  final mindSumStage2Frame =
      dashboard._stage == SpendeeHeaderStage.stage2 &&
          mindSumPublishedYear != null
      ? dashboard._mindSumYearFrameFor(store, year: mindSumPublishedYear)
      : null;
  final mindSumStage2Content = mindSumStage2Frame == null
      ? null
      : dashboard._mindSumStage2WidgetFor(
          frame: mindSumStage2Frame,
          year: mindSumPublishedYear!,
        );
  final mindSumActiveType =
      mindStatsFrame?.activeFrame.yearData.activeType ?? store.activeType;

  return ColoredBox(
    color: const Color(0xFFF1F5F9),
    child: Stack(
      key: const ValueKey('spendee-test-dashboard'),
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: KeyedSubtree(
            key: ValueKey(
              'spendee-test-dashboard-stage-${dashboard._stage.name}',
            ),
            child: const SizedBox.expand(),
          ),
        ),
        AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          top: contentTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: dashboard._homeContent,
        ),
        Positioned(
          left: 20,
          right: 20,
          top: geometry.headerTop,
          child: AnimatedContainer(
            key: const ValueKey('spendee-test-header-card'),
            duration: animationDuration,
            curve: animationCurve,
            height: dashboard._headerHeight,
            child: RepaintBoundary(
              key: const ValueKey('spendee-test-header-golden-boundary'),
              child: _SpendeeBudgetHeaderCard(
                stage: dashboard._stage,
                selectedBudgetItem: selectedBudgetItem,
                selectedCategory: selectedCategory,
                bars: budgetBars,
                transactions: store.windowedTransactions,
                budgetLimitAmount: overviewBudgetLimit,
                budgetItems: budgetItems,
                stage2Page: dashboard._stage2Page,
                headerBackgroundMode: dashboard._headerBackgroundMode,
                headerBackgroundOpacity: dashboard._headerBackgroundOpacity,
                mindStatsFrame: mindStatsFrame,
                onHandleDragStart: dashboard._beginHeaderDrag,
                onHandleDragUpdate: dashboard._updateHeaderDrag,
                onHandleDragEnd: dashboard._endHeaderDrag,
                onBudgetItemTap: (item) =>
                    dashboard._selectBudgetItem(item, animateCarousel: true),
                onPieCategoryTap: (category) => dashboard._selectCategory(
                  category,
                  animateCarousel: true,
                  carouselMotionSource: 'diagram',
                  carouselStepDuration: const Duration(milliseconds: 72),
                ),
                onPieCenterTap: () => dashboard._selectOverviewBudgetItem(
                  carouselMotionSource: 'diagram',
                  carouselStepDuration: const Duration(milliseconds: 72),
                ),
                onStage2PreviousPage: dashboard._showPreviousStage2Page,
                onStage2NextPage: dashboard._showNextStage2Page,
                pulsingBudgetItemKey: dashboard._pulsingBudgetItemKey,
                carouselOffset: dashboard._carouselVisualDx,
                pressedBudgetItemKey: dashboard._budgetLimitEditItem?.key,
                avatarBodyHighlightEnabled:
                    dashboard._avatarBodyHighlightEnabled,
                avatarBodyHighlightStrength:
                    dashboard._avatarBodyHighlightStrength,
                avatarProgressThickness: dashboard._avatarProgressThickness,
                avatarProgressFadeInner: dashboard._avatarProgressFadeInner,
                avatarProgressFadeOuter: dashboard._avatarProgressFadeOuter,
                avatarProgressFadeCurve: dashboard._avatarProgressFadeCurve,
                avatarRemainingEnabled: dashboard._avatarRemainingEnabled,
                avatarRemainingOpacity: dashboard._avatarRemainingOpacity,
                avatarDangerProgressColor: dashboard._avatarDangerProgressColor,
                avatarWarningProgressColor:
                    dashboard._avatarWarningProgressColor,
                avatarBorderEnabled: dashboard._avatarBorderEnabled,
                avatarLayoutConfig: dashboard._avatarLayoutConfig,
                onBudgetItemLongPressStart:
                    dashboard._handleBudgetItemLongPressStart,
                onBudgetItemLongPressMoveUpdate:
                    dashboard._handleBudgetItemLongPressMoveUpdate,
                onBudgetItemLongPressEnd: (_) =>
                    dashboard._finishBudgetLimitEdit(),
                onBudgetItemLongPressCancel: dashboard._finishBudgetLimitEdit,
                headerSurface: dashboard._headerSurface,
                avatarSurface: dashboard._avatarSurface,
                chartSurface: dashboard._chartSurface,
                chartListSurface: dashboard._chartListSurface,
                headerLiquidSoftness: dashboard._headerLiquidSoftness,
                avatarSurfaceSoftness: dashboard._avatarSurfaceSoftness,
                chartSurfaceSoftness: dashboard._chartSurfaceSoftness,
                chartListSurfaceSoftness: dashboard._chartListSurfaceSoftness,
                mindStage1Surface: mindStatsFrame?.modeKey == 'sum'
                    ? dashboard._mindSumStage1Surface
                    : dashboard._mindStage1Surface,
                mindStage2Surface: mindStatsFrame?.modeKey == 'sum'
                    ? dashboard._mindSumStage2Surface
                    : dashboard._mindStage2Surface,
                mindStage1Softness: dashboard._mindStage1Softness,
                mindStage2Softness: dashboard._mindStage2Softness,
                mindSumYears: mindSumYears,
                mindSumYearSummaries:
                    mindSumVolumeFrame?.yearData.sumYearSummaries ??
                    const <StatsSumYearSummary>[],
                mindSumSelectedYear: mindSumSelectedYear,
                mindSumActiveType: mindSumActiveType,
                mindSumStage2Content: mindSumStage2Content,
                mindSumYearCarouselOffset:
                    dashboard._mindSumYearCarouselVisualDx,
                mindSumYearRailConfig: dashboard._mindSumYearRailConfig,
                mindSumStage1Opacity: dashboard._mindSumStage1Opacity,
                mindSumYearCardEnabled: dashboard._mindSumYearCardEnabled,
                mindSumYearCardSurface: dashboard._mindSumYearCardSurface,
                mindSumYearCardOpacity: dashboard._mindSumYearCardOpacity,
                mindSumYearVolumeBarsEnabled:
                    dashboard._mindSumYearVolumeBarsEnabled,
                onHeaderDesignMenuPressed: dashboard._openHeaderDesignMenu,
                onHeaderBackgroundTap: dashboard._openAvatarLayoutMenu,
                onCarouselDragStart: dashboard._handleCarouselDragStart,
                onCarouselDragUpdate: dashboard._handleCarouselDragUpdate,
                onCarouselDragEnd: dashboard._handleCarouselDragEnd,
                onCarouselDragCancel: dashboard._handleCarouselDragCancel,
                onMindSumYearTap: (year) =>
                    unawaited(dashboard._animateMindSumYearCarouselTo(year)),
                onMindSumYearCarouselDragStart:
                    dashboard._handleMindSumYearCarouselDragStart,
                onMindSumYearCarouselDragUpdate:
                    dashboard._handleMindSumYearCarouselDragUpdate,
                onMindSumYearCarouselDragEnd:
                    dashboard._handleMindSumYearCarouselDragEnd,
                onMindSumYearCarouselDragCancel:
                    dashboard._handleMindSumYearCarouselDragCancel,
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
            logoFills: dashboard._logoFills,
            onLogoTap: dashboard._openLogoEditor,
          ),
        ),
        if (dashboard.widget.browserFullscreenController case final controller?)
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

@immutable
class _BudgetV2DashboardRuntime {
  const _BudgetV2DashboardRuntime({
    required this.sourceBars,
    required this.limitPreviewRevision,
    required this.pressedAvatarKey,
    required this.previewBars,
    required this.onLimitChanged,
    required this.onAvatarSettled,
    required this.onVendorSelected,
    required this.onAvatarLongPressStart,
    required this.onAvatarLongPressMoveUpdate,
    required this.onAvatarLongPressEnd,
    required this.onAvatarLongPressCancel,
  });

  final List<CategoryBudgetBarData> sourceBars;
  final ValueListenable<int> limitPreviewRevision;
  final String? pressedAvatarKey;
  final List<CategoryBudgetBarData> Function(List<CategoryBudgetBarData>)
  previewBars;
  final void Function(CategoryBudgetBarData, double) onLimitChanged;
  final ValueChanged<CategoryBudgetBarData> onAvatarSettled;
  final ValueChanged<String> onVendorSelected;
  final void Function(CategoryBudgetBarData, LongPressStartDetails)
  onAvatarLongPressStart;
  final GestureLongPressMoveUpdateCallback onAvatarLongPressMoveUpdate;
  final GestureLongPressEndCallback onAvatarLongPressEnd;
  final GestureLongPressCancelCallback onAvatarLongPressCancel;
}

class _SpendeeBudgetInteractionRuntime {
  _SpendeeBudgetInteractionRuntime({required TickerProvider vsync})
    : _carouselReleaseController = AnimationController(vsync: vsync);

  static const _carouselFilterPublishIdleDelay = Duration(milliseconds: 360);

  SpendeeHeaderStageController? _stageController;
  SpendeeHeaderStage _stage = SpendeeHeaderStage.stage0;
  var _headerHeight = 104.0;
  var _dragging = false;
  var _springBack = false;
  var _carouselLiveTicked = false;
  var _carouselVisualDx = 0.0;
  SpendeeCenterCarouselController? _carouselController;
  final AnimationController _carouselReleaseController;
  Timer? _budgetFilterPublishTimer;
  BackheaderBudgetItem? _pendingBudgetFilterItem;
  var _carouselMotionSerial = 0;
  String? _selectedBudgetItemKey;
  String? _pulsingBudgetItemKey;
  var _stage2Page = _Stage2BudgetPage.categories;
  Stopwatch? _headerDragStopwatch;
  var _headerDragUpdateCount = 0;
  Stopwatch? _carouselDragStopwatch;
  var _carouselDragUpdateCount = 0;
  Timer? _budgetLimitVeryLongTimer;
  Timer? _budgetLimitAutoTickTimer;
  BackheaderBudgetItem? _budgetLimitEditItem;
  double? _budgetLimitEditActivationGlobalY;
  var _budgetLimitEditLastDy = 0.0;
  var _budgetLimitEditAccumulator = 0.0;
  var _budgetLimitClearedByVeryLong = false;
  final _budgetPendingLimitAmountsByKey = <String, double>{};
  void dispose() {
    _budgetFilterPublishTimer?.cancel();
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitAutoTickTimer?.cancel();
    _carouselReleaseController.dispose();
  }
}

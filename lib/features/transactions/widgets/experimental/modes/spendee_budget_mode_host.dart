part of '../spendee_test_dashboard.dart';

class SpendeeBudgetModeHost extends StatefulWidget {
  const SpendeeBudgetModeHost._({
    super.key,
    required _SpendeeTestDashboardState dashboard,
    required SpendeeDashboardMode variant,
  }) : _dashboard = dashboard,
       _variant = variant;

  final _SpendeeTestDashboardState _dashboard;
  final SpendeeDashboardMode _variant;

  @override
  State<SpendeeBudgetModeHost> createState() => _SpendeeBudgetModeHostState();
}

class _SpendeeBudgetModeHostState extends State<SpendeeBudgetModeHost>
    with TickerProviderStateMixin {
  _SpendeeLegacyInteractionCoordinator? _coordinator;
  ValueNotifier<SpendeeHeaderStage>? _stageNotifier;
  _SpendeeHomeContentDependencies? _legacyHomeContentDependencies;
  Widget? _legacyHomeContent;

  bool get _ownsLegacyBudget => widget._variant == SpendeeDashboardMode.budget;

  @override
  void initState() {
    super.initState();
    if (_ownsLegacyBudget) {
      _stageNotifier = ValueNotifier<SpendeeHeaderStage>(
        SpendeeHeaderStage.stage0,
      );
      _refreshLegacyHomeContent();
      _coordinator = _SpendeeLegacyInteractionCoordinator(
        vsync: this,
        bridge: _legacyBridge(),
        rebuildHost: _rebuild,
      );
    }
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ownsLegacyBudget) {
      _refreshLegacyHomeContent();
      _coordinator?.replaceBridge(_legacyBridge());
    }
  }

  _SpendeeLegacyInteractionBridge _legacyBridge() {
    return _legacyInteractionBridgeFor(
      context,
      widget._dashboard,
      publishStage: _publishLegacyHeaderStage,
      resolveMindStage2Year: () => null,
      publishMindStage2Year: (_) {},
    );
  }

  void _publishLegacyHeaderStage(SpendeeHeaderStage stage) {
    final notifier = _stageNotifier;
    if (notifier != null && notifier.value != stage) {
      notifier.value = stage;
    }
  }

  void _refreshLegacyHomeContent() {
    final dependencies = _SpendeeHomeContentDependencies.fromDashboard(
      widget._dashboard,
    );
    final previous = _legacyHomeContentDependencies;
    if (previous != null && dependencies.matches(previous)) return;
    _legacyHomeContentDependencies = dependencies;
    _legacyHomeContent = _buildLegacyHomeContent(dependencies);
  }

  Widget _buildLegacyHomeContent(_SpendeeHomeContentDependencies dependencies) {
    return _SpendeeHomeContent(
      key: const ValueKey('spendee-test-home-content'),
      store: dependencies.store,
      expenseTheme: dependencies.expenseTheme,
      stageListenable: _stageNotifier!,
      onPickSummaryMonth: dependencies.onPickSummaryMonth,
      onEditTransaction: dependencies.onEditTransaction,
      onDeleteTransactionRequested: dependencies.onDeleteTransactionRequested,
      onVendorSheetRequested: dependencies.onVendorSheetRequested,
      logBottomPadding: dependencies.logBottomPadding,
    );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coordinator?.dispose();
    _stageNotifier?.dispose();
    super.dispose();
  }

  Widget _buildBudgetV2Dashboard() {
    final dashboard = widget._dashboard;
    final store = dashboard.widget.store;
    return SpendeeBudgetV2Dashboard(
      store: store,
      brand: _SpendeeBrandLockup(
        key: const ValueKey('spendee-test-brand-lockup'),
        logoFills: dashboard._logoFills,
        onLogoTap: dashboard._openLogoEditor,
      ),
      menuButton: Builder(
        builder: (menuContext) => SpendeeHeaderMenuButton(
          spec: _budgetHeaderVisualSpec,
          onPressed: () => dashboard._openHeaderDesignMenu(menuContext),
        ),
      ),
      avatarAppearance: BudgetV2AvatarAppearance(
        progressThickness: dashboard._avatarProgressThickness,
        progressFadeInner: dashboard._avatarProgressFadeInner,
        progressFadeOuter: dashboard._avatarProgressFadeOuter,
        progressFadeCurve: dashboard._avatarProgressFadeCurve,
        remainingEnabled: dashboard._avatarRemainingEnabled,
        remainingOpacity: dashboard._avatarRemainingOpacity,
        dangerProgressColor: dashboard._avatarDangerProgressColor,
        warningProgressColor: dashboard._avatarWarningProgressColor,
        showBodyBorder: dashboard._avatarBorderEnabled,
        centerSize: dashboard._avatarLayoutConfig.centerSize,
        innerSize: dashboard._avatarLayoutConfig.innerSize,
        outerSize: dashboard._avatarLayoutConfig.outerSize,
        innerOffset: dashboard._avatarLayoutConfig.innerOffset,
        outerOffset: dashboard._avatarLayoutConfig.outerOffset,
      ),
      onHeaderTap: dashboard._openAvatarLayoutMenu,
      onPickSummaryMonth: dashboard.widget.onPickSummaryMonth,
      onFilterPressed: dashboard.widget.onBalanceFilterRequested,
      onEditTransaction: dashboard.widget.onEditTransaction,
      onDeleteTransactionRequested:
          dashboard.widget.onDeleteTransactionRequested,
      onRenameMerchantRequested: dashboard._requestBalanceMerchantRename,
      logBottomPadding: dashboard.widget.logBottomPadding,
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
          _coordinator!,
          homeContent: _legacyHomeContent!,
        ),
        SpendeeDashboardMode.budgetV2 => _buildBudgetV2Dashboard(),
        _ => throw StateError('Budget host received a non-Budget variant.'),
      },
    );
  }
}

@immutable
class _SpendeeHomeContentDependencies {
  const _SpendeeHomeContentDependencies({
    required this.store,
    required this.expenseTheme,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  factory _SpendeeHomeContentDependencies.fromDashboard(
    _SpendeeTestDashboardState dashboard,
  ) {
    final widget = dashboard.widget;
    return _SpendeeHomeContentDependencies(
      store: widget.store,
      expenseTheme: widget.expenseTheme,
      onPickSummaryMonth: widget.onPickSummaryMonth,
      onEditTransaction: widget.onEditTransaction,
      onDeleteTransactionRequested: widget.onDeleteTransactionRequested,
      onVendorSheetRequested: widget.onVendorSheetRequested,
      logBottomPadding: widget.logBottomPadding,
    );
  }

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  bool matches(_SpendeeHomeContentDependencies other) {
    return identical(store, other.store) &&
        identical(expenseTheme, other.expenseTheme) &&
        identical(onPickSummaryMonth, other.onPickSummaryMonth) &&
        identical(onEditTransaction, other.onEditTransaction) &&
        identical(
          onDeleteTransactionRequested,
          other.onDeleteTransactionRequested,
        ) &&
        identical(onVendorSheetRequested, other.onVendorSheetRequested) &&
        logBottomPadding == other.logBottomPadding;
  }
}

@immutable
class _SpendeeLegacyMindRuntime {
  const _SpendeeLegacyMindRuntime({
    required this.statsFrameFor,
    required this.sumVolumeFrameFor,
    required this.sumYearsFor,
    required this.selectedYearFor,
    required this.publishedYearFor,
    required this.sumYearFrameFor,
    required this.sumStage2WidgetFor,
  });

  final SpendeeMindStatsFrame Function(
    TransactionStore store, {
    required String reason,
  })
  statsFrameFor;
  final StatsRenderFrame Function(TransactionStore store) sumVolumeFrameFor;
  final List<int> Function(StatsRenderFrame frame) sumYearsFor;
  final int Function(List<int> years) selectedYearFor;
  final int Function(List<int> years) publishedYearFor;
  final StatsRenderFrame Function(TransactionStore store, {required int year})
  sumYearFrameFor;
  final Widget Function({required StatsRenderFrame frame, required int year})
  sumStage2WidgetFor;
}

Widget _buildSpendeeLegacyModeContent(
  BuildContext context,
  _SpendeeTestDashboardState dashboard,
  _SpendeeLegacyInteractionCoordinator coordinator, {
  required Widget homeContent,
  _SpendeeLegacyMindRuntime? mindRuntime,
}) {
  final controller = coordinator.controllerFor();
  final geometry = controller.geometry;
  final store = dashboard.widget.store;
  final budgetBars = coordinator.previewBudgetBars(store.categoryBudgetBars);
  final overviewBudgetItems = coordinator.previewOverviewBudgetItems(
    store.overviewBudgetItems,
  );
  final budgetItems = coordinator.previewBudgetItems(
    overviewItems: overviewBudgetItems,
    bars: budgetBars,
  );
  final selectedBudgetItem = coordinator.selectedBudgetItemFor(budgetItems);
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
      geometry.headerTop + coordinator.headerHeight + geometry.contentGap;
  final animationDuration = coordinator.dragging
      ? Duration.zero
      : const Duration(milliseconds: 360);
  final animationCurve = coordinator.springBack
      ? Curves.elasticOut
      : Curves.easeOutCubic;

  final isMindBackground =
      mindRuntime != null &&
      dashboard._headerBackgroundMode == _HeaderBackgroundMode.mind;
  final mindStatsFrame = isMindBackground
      ? mindRuntime.statsFrameFor(store, reason: 'header-background-mind')
      : null;
  final mindSumVolumeFrame = mindStatsFrame?.modeKey == 'sum'
      ? mindRuntime!.sumVolumeFrameFor(store)
      : null;
  final mindSumYears = mindSumVolumeFrame != null
      ? mindRuntime!.sumYearsFor(mindSumVolumeFrame)
      : const <int>[];
  final mindSumPublishedYear = mindSumYears.isEmpty
      ? null
      : mindRuntime!.publishedYearFor(mindSumYears);
  final mindSumStage2Frame =
      coordinator.stage == SpendeeHeaderStage.stage2 &&
          mindSumPublishedYear != null
      ? mindRuntime!.sumYearFrameFor(store, year: mindSumPublishedYear)
      : null;
  final mindSumStage2Content = mindSumStage2Frame == null
      ? null
      : mindRuntime!.sumStage2WidgetFor(
          frame: mindSumStage2Frame,
          year: mindSumPublishedYear!,
        );
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
              'spendee-test-dashboard-stage-${coordinator.stage.name}',
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
          child: homeContent,
        ),
        Positioned(
          left: 20,
          right: 20,
          top: geometry.headerTop,
          child: AnimatedContainer(
            key: const ValueKey('spendee-test-header-card'),
            duration: animationDuration,
            curve: animationCurve,
            height: coordinator.headerHeight,
            child: RepaintBoundary(
              key: const ValueKey('spendee-test-header-golden-boundary'),
              child: _SpendeeBudgetHeaderCard(
                stage: coordinator.stage,
                selectedBudgetItem: selectedBudgetItem,
                selectedCategory: selectedCategory,
                bars: budgetBars,
                transactions: store.windowedTransactions,
                budgetLimitAmount: overviewBudgetLimit,
                budgetItems: budgetItems,
                stage2Page: coordinator.stage2Page,
                headerBackgroundMode: dashboard._headerBackgroundMode,
                headerBackgroundOpacity: dashboard._headerBackgroundOpacity,
                mindStatsFrame: mindStatsFrame,
                onHandleDragStart: coordinator.beginHeaderDrag,
                onHandleDragUpdate: coordinator.updateHeaderDrag,
                onHandleDragEnd: coordinator.endHeaderDrag,
                onBudgetItemTap: (item) =>
                    coordinator.selectBudgetItem(item, animateCarousel: true),
                onPieCategoryTap: (category) => coordinator.selectCategory(
                  category,
                  animateCarousel: true,
                  carouselMotionSource: 'diagram',
                  carouselStepDuration: const Duration(milliseconds: 72),
                ),
                onPieCenterTap: () => coordinator.selectOverviewBudgetItem(
                  carouselMotionSource: 'diagram',
                  carouselStepDuration: const Duration(milliseconds: 72),
                ),
                onStage2PreviousPage: coordinator.showPreviousStage2Page,
                onStage2NextPage: coordinator.showNextStage2Page,
                pulsingBudgetItemKey: coordinator.pulsingBudgetItemKey,
                carouselOffset: coordinator.carouselVisualDx,
                pressedBudgetItemKey: coordinator.budgetLimitEditItem?.key,
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
                    coordinator.handleBudgetItemLongPressStart,
                onBudgetItemLongPressMoveUpdate:
                    coordinator.handleBudgetItemLongPressMoveUpdate,
                onBudgetItemLongPressEnd: (_) =>
                    coordinator.finishBudgetLimitEdit(),
                onBudgetItemLongPressCancel: coordinator.finishBudgetLimitEdit,
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
                mindSumStage2Content: mindSumStage2Content,
                mindSumStage1Opacity: dashboard._mindSumStage1Opacity,
                onHeaderDesignMenuPressed: dashboard._openHeaderDesignMenu,
                onHeaderBackgroundTap: dashboard._openAvatarLayoutMenu,
                onCarouselDragStart: coordinator.handleCarouselDragStart,
                onCarouselDragUpdate: coordinator.handleCarouselDragUpdate,
                onCarouselDragEnd: coordinator.handleCarouselDragEnd,
                onCarouselDragCancel: coordinator.handleCarouselDragCancel,
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
class _SpendeeLegacyInteractionBridge {
  const _SpendeeLegacyInteractionBridge({
    required this.store,
    required this.hostContext,
    required this.headerBackgroundMode,
    required this.headerSurface,
    required this.avatarSurface,
    required this.publishStage,
    required this.resolveMindStage2Year,
    required this.publishMindStage2Year,
  });

  final TransactionStore store;
  final BuildContext hostContext;
  final _HeaderBackgroundMode headerBackgroundMode;
  final _HeaderSurface headerSurface;
  final _PanelSurface avatarSurface;
  final ValueChanged<SpendeeHeaderStage> publishStage;
  final int? Function() resolveMindStage2Year;
  final ValueChanged<int?> publishMindStage2Year;

  bool hasSameDependenciesAs(_SpendeeLegacyInteractionBridge other) {
    return identical(store, other.store) &&
        identical(hostContext, other.hostContext) &&
        headerBackgroundMode == other.headerBackgroundMode &&
        headerSurface == other.headerSurface &&
        avatarSurface == other.avatarSurface;
  }
}

_SpendeeLegacyInteractionBridge _legacyInteractionBridgeFor(
  BuildContext hostContext,
  _SpendeeTestDashboardState dashboard, {
  required ValueChanged<SpendeeHeaderStage> publishStage,
  required int? Function() resolveMindStage2Year,
  required ValueChanged<int?> publishMindStage2Year,
}) {
  final store = dashboard.widget.store;
  final headerBackgroundMode = dashboard._headerBackgroundMode;
  return _SpendeeLegacyInteractionBridge(
    store: store,
    hostContext: hostContext,
    headerBackgroundMode: headerBackgroundMode,
    headerSurface: dashboard._headerSurface,
    avatarSurface: dashboard._avatarSurface,
    publishStage: publishStage,
    resolveMindStage2Year: resolveMindStage2Year,
    publishMindStage2Year: publishMindStage2Year,
  );
}

class _SpendeeLegacyInteractionCoordinator {
  _SpendeeLegacyInteractionCoordinator({
    required TickerProvider vsync,
    required _SpendeeLegacyInteractionBridge bridge,
    required VoidCallback rebuildHost,
    ValueNotifier<int>? limitPreviewRevision,
  }) : _bridge = bridge,
       _rebuildHost = rebuildHost,
       _limitPreviewRevision = limitPreviewRevision,
       _carouselReleaseController = AnimationController(vsync: vsync);

  static const _carouselFilterPublishIdleDelay = Duration(milliseconds: 360);

  _SpendeeLegacyInteractionBridge _bridge;
  final VoidCallback _rebuildHost;
  final ValueNotifier<int>? _limitPreviewRevision;
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
  var _generation = 0;
  var _disposed = false;

  SpendeeHeaderStage get stage => _stage;
  double get headerHeight => _headerHeight;
  bool get dragging => _dragging;
  bool get springBack => _springBack;
  double get carouselVisualDx => _carouselVisualDx;
  String? get pulsingBudgetItemKey => _pulsingBudgetItemKey;
  _Stage2BudgetPage get stage2Page => _stage2Page;
  BackheaderBudgetItem? get budgetLimitEditItem => _budgetLimitEditItem;

  void replaceBridge(_SpendeeLegacyInteractionBridge nextBridge) {
    if (_disposed || _bridge.hasSameDependenciesAs(nextBridge)) return;
    _invalidateInteractionIdentity();
    _bridge = nextBridge;
    _publishStage(_stage);
  }

  void _invalidateInteractionIdentity() {
    _generation += 1;
    _carouselMotionSerial += 1;
    _budgetFilterPublishTimer?.cancel();
    _budgetFilterPublishTimer = null;
    _pendingBudgetFilterItem = null;
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitVeryLongTimer = null;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    _carouselReleaseController.stop();
    _carouselController = null;
    _carouselLiveTicked = false;
    _carouselVisualDx = 0;
    _selectedBudgetItemKey = null;
    _pulsingBudgetItemKey = null;
    _stage2Page = _Stage2BudgetPage.categories;
    _budgetLimitEditItem = null;
    _budgetLimitEditActivationGlobalY = null;
    _budgetLimitEditLastDy = 0;
    _budgetLimitEditAccumulator = 0;
    _budgetLimitClearedByVeryLong = false;
    _budgetPendingLimitAmountsByKey.clear();
    _carouselDragStopwatch = null;
    _carouselDragUpdateCount = 0;
  }

  bool _ownsGeneration(int generation) =>
      !_disposed && generation == _generation;

  bool _ownsMotion(int generation, int serial) =>
      _ownsGeneration(generation) && serial == _carouselMotionSerial;

  void _mutate(VoidCallback mutation) {
    if (_disposed) return;
    mutation();
    _rebuildHost();
  }

  void _publishStage(SpendeeHeaderStage stage) {
    _stage = stage;
    _bridge.publishStage(stage);
  }

  SpendeeHeaderStageController controllerFor() {
    final geometry = SpendeeHeaderStageGeometry.html(
      screenHeight: MediaQuery.sizeOf(_bridge.hostContext).height,
    );
    final existing = _stageController;
    if (existing != null) {
      existing.replaceGeometry(geometry);
      _headerHeight = existing.currentHeight;
      return existing;
    }
    final controller = SpendeeHeaderStageController(geometry: geometry);
    _stageController = controller;
    _publishStage(controller.stage);
    _headerHeight = controller.currentHeight;
    return controller;
  }

  List<BackheaderBudgetItem> get _budgetItems =>
      _bridge.store.backheaderBudgetItems;

  BackheaderBudgetItem? selectedBudgetItemFor(
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
    final activeCategoryId =
        _bridge.store.activeCategory?.transactionCategoryID;
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
      '[Perf] SpendeeTest header_drag '
      'background=${_bridge.headerBackgroundMode.name} '
      'surface=${_bridge.headerSurface.name} '
      'targetStage=${targetStage.name} '
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
      '[Perf] SpendeeTest carousel_drag '
      'background=${_bridge.headerBackgroundMode.name} '
      'surface=${_bridge.avatarSurface.name} outcome=$outcome '
      'updates=$_carouselDragUpdateCount '
      'selected=${_selectedBudgetItemKey ?? 'none'} '
      'residual=${_carouselVisualDx.toStringAsFixed(1)} '
      'velocity=${(velocityDx ?? 0).toStringAsFixed(1)} '
      'elapsed=${stopwatch?.elapsedMilliseconds ?? 0}ms',
    );
    _carouselDragStopwatch = null;
    _carouselDragUpdateCount = 0;
  }

  void beginHeaderDrag(DragStartDetails details) {
    if (_disposed) return;
    final controller = controllerFor();
    controller.beginDrag();
    _startInteractionPerf('header_drag');
    _mutate(() {
      _dragging = true;
      _springBack = false;
    });
  }

  void updateHeaderDrag(DragUpdateDetails details) {
    if (_disposed) return;
    final controller = controllerFor();
    final update = controller.dragBy(details.delta.dy);
    _headerDragUpdateCount += 1;
    for (var index = 0; index < update.tickCount; index++) {
      HapticFeedback.selectionClick();
    }
    _mutate(() {
      _headerHeight = update.height;
      _publishStage(controller.stage);
    });
  }

  void endHeaderDrag(DragEndDetails details) {
    if (_disposed) return;
    final controller = controllerFor();
    final release = controller.release();
    final stage2MindSumYear = release.targetStage == SpendeeHeaderStage.stage2
        ? _bridge.resolveMindStage2Year()
        : null;
    _logHeaderDragPerf(
      targetStage: release.targetStage,
      targetHeight: release.targetHeight,
      springBack: release.springBack,
    );
    _mutate(() {
      _dragging = false;
      _springBack = release.springBack;
      _publishStage(release.targetStage);
      if (release.targetStage == SpendeeHeaderStage.stage2) {
        _bridge.publishMindStage2Year(stage2MindSumYear);
      }
      _headerHeight = release.targetHeight;
    });
  }

  void selectCategory(
    TransactionCategory category, {
    bool haptic = true,
    bool animateCarousel = false,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    if (_disposed) return;
    final item = _budgetItemForCategory(category);
    if (item == null) {
      if (haptic) HapticFeedback.selectionClick();
      _cancelPendingBudgetFilterPublish();
      _bridge.store.setCategoryFilter(category);
      return;
    }
    selectBudgetItem(
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
              _bridge.store.activeType.nativeValue) {
        return item;
      }
    }
    return _budgetItems.isEmpty ? null : _budgetItems.first;
  }

  void selectOverviewBudgetItem({
    bool haptic = true,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    if (_disposed) return;
    final item = _overviewBudgetItemForActiveType();
    if (item == null) return;
    selectBudgetItem(
      item,
      haptic: haptic,
      animateCarousel: true,
      carouselMotionSource: carouselMotionSource,
      carouselStepDuration: carouselStepDuration,
    );
  }

  void _showStage2Page(_Stage2BudgetPage page) {
    if (_disposed) return;
    if (page == _Stage2BudgetPage.vendors &&
        !_stage2VendorPageAvailableFor(selectedBudgetItemFor(_budgetItems))) {
      return;
    }
    if (_stage2Page == page) return;
    HapticFeedback.selectionClick();
    _mutate(() => _stage2Page = page);
  }

  void showPreviousStage2Page() {
    _showStage2Page(
      _stage2Page == _Stage2BudgetPage.categories
          ? _Stage2BudgetPage.vendors
          : _Stage2BudgetPage.categories,
    );
  }

  void showNextStage2Page() {
    _showStage2Page(
      _stage2Page == _Stage2BudgetPage.vendors
          ? _Stage2BudgetPage.categories
          : _Stage2BudgetPage.vendors,
    );
  }

  void selectBudgetItem(
    BackheaderBudgetItem item, {
    bool haptic = true,
    bool animateCarousel = false,
    bool publishFilter = true,
    String carouselMotionSource = 'avatar',
    Duration carouselStepDuration = const Duration(milliseconds: 150),
  }) {
    if (_disposed) return;
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
    if (_disposed) return;
    if (haptic) HapticFeedback.selectionClick();
    if (publishFilter) {
      _cancelPendingBudgetFilterPublish();
      _publishBudgetItemFilter(item);
    }
    _mutate(() {
      _selectedBudgetItemKey = item.key;
      if (_stage2Page == _Stage2BudgetPage.vendors &&
          !_stage2VendorPageAvailableFor(item)) {
        _stage2Page = _Stage2BudgetPage.categories;
      }
    });
  }

  bool _stage2VendorPageAvailableFor(BackheaderBudgetItem? item) {
    final bars = previewBudgetBars(_bridge.store.categoryBudgetBars);
    if (!bars.any((bar) => bar.spent > 0)) return false;
    final categoryId = item?.category?.category?.transactionCategoryID;
    if (categoryId == null) return true;
    return bars.any((bar) => bar.targetId == categoryId && bar.spent > 0);
  }

  void _publishBudgetItemFilter(BackheaderBudgetItem item) {
    if (_disposed) return;
    final store = _bridge.store;
    final category = item.category?.category;
    if (category != null) {
      final activeIds = store.activeCategoryIds;
      final alreadyActive =
          store.activeType == category.normalizedType &&
          activeIds.length == 1 &&
          activeIds.contains(category.transactionCategoryID) &&
          store.searchQuery.isEmpty &&
          store.activeMerchantFilters.isEmpty;
      if (!alreadyActive) store.setCategoryFilter(category);
      return;
    }
    final alreadyOverview =
        store.activeCategoryIds.isEmpty &&
        store.activeMerchantFilters.isEmpty &&
        store.searchQuery.isEmpty;
    if (!alreadyOverview) store.clearCategoryFilter();
  }

  void _scheduleBudgetItemFilterPublish(BackheaderBudgetItem item) {
    if (_disposed) return;
    final generation = _generation;
    _pendingBudgetFilterItem = item;
    _budgetFilterPublishTimer?.cancel();
    _budgetFilterPublishTimer = Timer(_carouselFilterPublishIdleDelay, () {
      if (!_ownsGeneration(generation)) return;
      final pendingItem = _pendingBudgetFilterItem;
      _pendingBudgetFilterItem = null;
      _budgetFilterPublishTimer = null;
      if (pendingItem == null) return;
      BackheaderBudgetItem? currentItem;
      for (final candidate in _budgetItems) {
        if (candidate.key == pendingItem.key) {
          currentItem = candidate;
          break;
        }
      }
      if (currentItem == null) return;
      DebugConsole.log(
        '[Perf] SpendeeTest carousel_filter_publish '
        'selected=${currentItem.key} delayMs='
        '${_carouselFilterPublishIdleDelay.inMilliseconds}',
      );
      _publishBudgetItemFilter(currentItem);
    });
    DebugConsole.log(
      '[Perf] SpendeeTest carousel_filter_schedule selected=${item.key} '
      'delayMs=${_carouselFilterPublishIdleDelay.inMilliseconds}',
    );
  }

  void _cancelPendingBudgetFilterPublish() {
    _budgetFilterPublishTimer?.cancel();
    _budgetFilterPublishTimer = null;
    _pendingBudgetFilterItem = null;
  }

  Future<void> _animateCarouselToBudgetItem(
    BackheaderBudgetItem item, {
    bool haptic = true,
    bool publishFilter = true,
    String source = 'avatar',
    Duration stepDuration = const Duration(milliseconds: 150),
  }) async {
    if (_disposed) return;
    final items = _budgetItems;
    final targetIndex = items.indexWhere(
      (candidate) => candidate.key == item.key,
    );
    if (targetIndex < 0) return;
    final initialIndex = _selectedBudgetItemIndex(items);
    if (targetIndex == initialIndex) {
      _applySelectedBudgetItem(item, haptic: haptic, publishFilter: false);
      if (publishFilter) _scheduleBudgetItemFilterPublish(item);
      return;
    }
    _carouselMotionSerial += 1;
    final serial = _carouselMotionSerial;
    final generation = _generation;
    _carouselReleaseController.stop();
    _cancelPendingBudgetFilterPublish();
    DebugConsole.log(
      '[Perf] SpendeeTest carousel_motion_start source=$source '
      'stepMs=${stepDuration.inMilliseconds} '
      'from=${items[initialIndex].key} to=${item.key}',
    );
    final controller = SpendeeCenterCarouselController(
      itemCount: items.length,
      initialIndex: initialIndex,
    );
    _mutate(() {
      _carouselLiveTicked = false;
      _carouselVisualDx = 0;
      _carouselController = controller;
    });
    try {
      var guard = 0;
      while (controller.index != targetIndex &&
          guard < items.length &&
          _ownsMotion(generation, serial)) {
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
          generation: generation,
          serial: serial,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (_ownsMotion(generation, serial)) {
        _carouselController = null;
        _applySelectedBudgetItem(item, haptic: false, publishFilter: false);
        if (publishFilter) _scheduleBudgetItemFilterPublish(item);
        _mutate(() => _carouselVisualDx = 0);
      }
    }
  }

  int _selectedBudgetItemIndex([List<BackheaderBudgetItem>? sourceItems]) {
    final items = sourceItems ?? _budgetItems;
    if (items.isEmpty) return 0;
    final selectedKey = selectedBudgetItemFor(items)?.key;
    final index = items.indexWhere((item) => item.key == selectedKey);
    return index < 0 ? 0 : index;
  }

  BackheaderBudgetItem? _budgetItemAtCarouselIndex(
    List<BackheaderBudgetItem> items,
    int index,
  ) {
    if (items.isEmpty) return null;
    final wrapped = index % items.length;
    return items[wrapped < 0 ? wrapped + items.length : wrapped];
  }

  void handleCarouselDragStart(DragStartDetails details) {
    if (_disposed) return;
    finishBudgetLimitEdit(reason: 'carousel_drag');
    final items = _budgetItems;
    final activeController = _carouselController;
    _carouselMotionSerial += 1;
    _carouselReleaseController.stop();
    _cancelPendingBudgetFilterPublish();
    _startInteractionPerf('carousel_drag');
    final selectedKey = selectedBudgetItemFor(items)?.key;
    final canResumeController =
        activeController != null &&
        activeController.itemCount == items.length &&
        _budgetItemAtCarouselIndex(items, activeController.index)?.key ==
            selectedKey;
    final controller = canResumeController
        ? activeController
        : SpendeeCenterCarouselController(
            itemCount: items.length,
            initialIndex: _selectedBudgetItemIndex(items),
          );
    controller.beginDragFromCurrentMotion();
    _mutate(() {
      _carouselLiveTicked = false;
      _carouselVisualDx = controller.residualDx;
      _carouselController = controller;
    });
  }

  void handleCarouselDragUpdate(DragUpdateDetails details) {
    if (_disposed) return;
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
    _mutate(() {
      if (latestItem != null) _selectedBudgetItemKey = latestItem.key;
      _carouselVisualDx = update.residualDx;
    });
  }

  void handleCarouselDragEnd(DragEndDetails details) {
    if (_disposed) return;
    final items = _budgetItems;
    final controller = _carouselController;
    if (items.length < 2 || controller == null) return;
    _logCarouselDragPerf(
      'release',
      velocityDx: details.velocity.pixelsPerSecond.dx,
    );
    unawaited(
      _releaseCarouselBelt(
        controller: controller,
        velocityDx: details.velocity.pixelsPerSecond.dx,
        liveTicked: _carouselLiveTicked,
        generation: _generation,
        serial: _carouselMotionSerial,
      ),
    );
  }

  void handleCarouselDragCancel() {
    if (_disposed) return;
    final controller = _carouselController;
    if (controller == null) return;
    _logCarouselDragPerf('cancel');
    unawaited(
      _cancelCarouselBelt(
        controller: controller,
        generation: _generation,
        serial: _carouselMotionSerial,
      ),
    );
  }

  Future<void> _cancelCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required int generation,
    required int serial,
  }) async {
    if (!_ownsMotion(generation, serial)) return;
    _carouselLiveTicked = false;
    final travel = controller.cancelTravel();
    try {
      if (travel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: travel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          generation: generation,
          serial: serial,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (_ownsMotion(generation, serial)) {
        _carouselController = null;
        _mutate(() => _carouselVisualDx = 0);
      }
    }
  }

  Future<void> _releaseCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required double velocityDx,
    required bool liveTicked,
    required int generation,
    required int serial,
  }) async {
    if (!_ownsMotion(generation, serial)) return;
    final motion = controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: liveTicked,
    );
    final releaseItem = _budgetItemAtCarouselIndex(
      _budgetItems,
      controller.index,
    );
    DebugConsole.log(
      '[Perf] SpendeeTest carousel_release_plan '
      'selected=${releaseItem?.key ?? "none"} '
      'residual=${controller.residualDx.toStringAsFixed(1)} '
      'velocity=${velocityDx.toStringAsFixed(1)} '
      'initialTravel=${motion.initialTravel.toStringAsFixed(1)} '
      'inertial=${motion.inertial} '
      'snapAllowed=${motion.directionalSnapAllowed}',
    );
    _carouselLiveTicked = false;
    try {
      if (motion.initialTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: motion.initialTravel,
          duration: motion.initialDuration,
          curve: motion.inertial ? Curves.easeOutQuad : Curves.easeOutCubic,
          generation: generation,
          serial: serial,
        );
      }
      if (!_ownsMotion(generation, serial)) return;
      final settleTravel = controller.settleTravel(
        preferredDxDirection: motion.preferredDxDirection,
        allowDirectionalSnap: motion.directionalSnapAllowed,
      );
      final settleItem = _budgetItemAtCarouselIndex(
        _budgetItems,
        controller.index,
      );
      DebugConsole.log(
        '[Perf] SpendeeTest carousel_release_settle '
        'selected=${settleItem?.key ?? "none"} '
        'residual=${controller.residualDx.toStringAsFixed(1)} '
        'settleTravel=${settleTravel.toStringAsFixed(1)}',
      );
      if (settleTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: settleTravel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          generation: generation,
          serial: serial,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (_ownsMotion(generation, serial)) {
        final item = _budgetItemAtCarouselIndex(_budgetItems, controller.index);
        _mutate(() {
          _carouselController = null;
          if (item != null) _selectedBudgetItemKey = item.key;
          _carouselVisualDx = 0;
        });
        if (item != null) _scheduleBudgetItemFilterPublish(item);
      }
    }
  }

  Future<void> _animateCarouselTravel({
    required SpendeeCenterCarouselController controller,
    required double travel,
    required Duration duration,
    required Curve curve,
    required int generation,
    required int serial,
  }) async {
    if (!_ownsMotion(generation, serial)) return;
    _carouselReleaseController.stop();
    _carouselReleaseController.duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(begin: 0, end: travel).animate(
      CurvedAnimation(parent: _carouselReleaseController, curve: curve),
    );
    void applyFrame() {
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta == 0 || !_ownsMotion(generation, serial)) return;
      _applyCarouselMotionDelta(controller, delta);
    }

    animation.addListener(applyFrame);
    var completed = false;
    try {
      await _carouselReleaseController.forward(from: 0).orCancel;
      completed = true;
    } finally {
      animation.removeListener(applyFrame);
    }
    if (!completed || !_ownsMotion(generation, serial)) return;
    final remaining = travel - lastValue;
    if (remaining.abs() > .001) {
      _applyCarouselMotionDelta(controller, remaining);
    }
  }

  void _applyCarouselMotionDelta(
    SpendeeCenterCarouselController controller,
    double deltaDx,
  ) {
    if (_disposed) return;
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
    _mutate(() {
      if (latestItem != null) _selectedBudgetItemKey = latestItem.key;
      _carouselVisualDx = update.residualDx;
    });
  }

  List<CategoryBudgetBarData> previewBudgetBars(
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

  List<OverviewBudgetData> previewOverviewBudgetItems(
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

  List<BackheaderBudgetItem> previewBudgetItems({
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

  void handleBudgetItemLongPressStart(
    BackheaderBudgetItem item,
    LongPressStartDetails details, {
    String diagnosticsSource = 'budget',
  }) {
    if (_disposed) return;
    final generation = _generation;
    _carouselReleaseController.stop();
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitEditItem = item;
    _budgetLimitEditActivationGlobalY = details.globalPosition.dy;
    _budgetLimitEditLastDy = 0;
    _budgetLimitEditAccumulator = 0;
    _budgetLimitClearedByVeryLong = false;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    if (diagnosticsSource == 'budget_v2') {
      DebugConsole.log(
        '[BudgetV2Limit] phase=start key=${item.key} '
        'amount=${_budgetItemLimitAmount(item).round()} '
        'global_y=${details.globalPosition.dy.toStringAsFixed(1)}',
      );
    }
    _rebuildHost();
    HapticFeedback.mediumImpact();
    _budgetLimitVeryLongTimer = Timer(const Duration(milliseconds: 720), () {
      if (!_ownsGeneration(generation) ||
          _budgetLimitEditItem?.key != item.key) {
        return;
      }
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

  void handleBudgetItemLongPressMoveUpdate(
    LongPressMoveUpdateDetails details, {
    String diagnosticsSource = 'budget',
  }) {
    if (_disposed) return;
    final item = _budgetLimitEditItem;
    final activationY = _budgetLimitEditActivationGlobalY;
    if (item == null || activationY == null) return;
    final dy = details.globalPosition.dy - activationY;
    final delta = dy - _budgetLimitEditLastDy;
    _budgetLimitEditLastDy = dy;
    if (dy.abs() > 5) _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitEditAccumulator += -delta;
    if (diagnosticsSource == 'budget_v2') {
      DebugConsole.log(
        '[BudgetV2Limit] phase=move key=${item.key} '
        'dy=${dy.toStringAsFixed(1)} delta=${delta.toStringAsFixed(1)} '
        'accumulator=${_budgetLimitEditAccumulator.toStringAsFixed(1)}',
      );
    }
    _drainBudgetLimitTicks(
      item,
      dy.abs(),
      diagnosticsSource: diagnosticsSource,
    );
    _scheduleBudgetLimitAutoTick(item, diagnosticsSource: diagnosticsSource);
  }

  void _drainBudgetLimitTicks(
    BackheaderBudgetItem item,
    double distance, {
    required String diagnosticsSource,
  }) {
    final largeStep = distance >= 50;
    final tickDistance = largeStep ? 18.0 : 12.0;
    final amountStep = largeStep ? 10000.0 : 1000.0;
    final direction = _budgetLimitEditAccumulator > 0 ? 1 : -1;
    final tickCount = (_budgetLimitEditAccumulator.abs() / tickDistance)
        .floor();
    if (tickCount < 1) return;
    _budgetLimitEditAccumulator -= direction * tickDistance * tickCount;
    _applyBudgetLimitTick(
      item,
      direction: direction,
      amountStep: amountStep,
      tickCount: tickCount,
      source: 'drag',
      diagnosticsSource: diagnosticsSource,
    );
  }

  void _scheduleBudgetLimitAutoTick(
    BackheaderBudgetItem item, {
    required String diagnosticsSource,
  }) {
    if (_disposed) return;
    final generation = _generation;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    if (_budgetLimitEditItem?.key != item.key) return;
    final distance = _budgetLimitEditLastDy.abs();
    if (distance < 14) return;
    final intervalMs = (440 - distance * 5.2).clamp(80.0, 440.0).round();
    _budgetLimitAutoTickTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (!_ownsGeneration(generation) ||
          _budgetLimitEditItem?.key != item.key) {
        return;
      }
      final direction = _budgetLimitEditLastDy < 0 ? 1 : -1;
      final amountStep = _budgetLimitEditLastDy.abs() >= 50 ? 10000.0 : 1000.0;
      _applyBudgetLimitTick(
        item,
        direction: direction,
        amountStep: amountStep,
        tickCount: 1,
        source: 'auto',
        diagnosticsSource: diagnosticsSource,
      );
      _scheduleBudgetLimitAutoTick(item, diagnosticsSource: diagnosticsSource);
    });
  }

  void _applyBudgetLimitTick(
    BackheaderBudgetItem item, {
    required int direction,
    required double amountStep,
    required int tickCount,
    required String source,
    required String diagnosticsSource,
  }) {
    if (_disposed) return;
    final next = math
        .max(
          0.0,
          _budgetItemLimitAmount(item) + direction * amountStep * tickCount,
        )
        .toDouble();
    _setBudgetItemLimitAmount(
      item,
      next,
      persist: false,
      rebuildHost: diagnosticsSource != 'budget_v2',
    );
    HapticFeedback.selectionClick();
    DebugConsole.log(
      '[Perf] SpendeeTest budget_limit_tick key=${item.key} '
      'direction=$direction step=${amountStep.round()} '
      'coalesced_ticks=$tickCount amount=${next.round()} source=$source '
      'persistence=release_only',
    );
    if (diagnosticsSource == 'budget_v2') {
      DebugConsole.log(
        '[BudgetV2Limit] phase=tick key=${item.key} '
        'direction=$direction step=${amountStep.round()} '
        'coalesced_ticks=$tickCount amount=${next.round()} source=$source '
        'persistence=release_only',
      );
    }
  }

  void finishBudgetLimitEdit({
    bool saveFinal = true,
    String diagnosticsSource = 'budget',
    String reason = 'end',
  }) {
    if (_disposed) return;
    _budgetLimitVeryLongTimer?.cancel();
    _budgetLimitVeryLongTimer = null;
    _budgetLimitAutoTickTimer?.cancel();
    _budgetLimitAutoTickTimer = null;
    final item = _budgetLimitEditItem;
    if (item == null) return;
    if (diagnosticsSource == 'budget_v2') {
      DebugConsole.log(
        '[BudgetV2Limit] phase=$reason key=${item.key} '
        'amount=${_budgetItemLimitAmount(item).round()} '
        'save_final=$saveFinal',
      );
    }
    if (saveFinal && !_budgetLimitClearedByVeryLong) {
      unawaited(_saveBudgetItemLimit(item, _budgetItemLimitAmount(item)));
    }
    _budgetLimitEditItem = null;
    _budgetLimitEditActivationGlobalY = null;
    _budgetLimitEditLastDy = 0;
    _budgetLimitEditAccumulator = 0;
    _budgetLimitClearedByVeryLong = false;
    _rebuildHost();
    if (diagnosticsSource == 'budget_v2') {
      DebugConsole.log(
        '[BudgetV2Limit] phase=release key=${item.key} '
        'interactive=true persistence=${saveFinal ? 'final' : 'none'}',
      );
    }
  }

  void _setBudgetItemLimitAmount(
    BackheaderBudgetItem item,
    double amount, {
    bool notifyStore = false,
    bool persist = true,
    bool rebuildHost = true,
  }) {
    if (_disposed) return;
    final normalized = amount <= 0 ? 0.0 : (amount / 1000).round() * 1000.0;
    if (_budgetItemLimitAmount(item) == normalized) return;
    _budgetPendingLimitAmountsByKey[item.key] = normalized;
    if (rebuildHost) {
      _rebuildHost();
    } else {
      final revision = _limitPreviewRevision;
      if (revision != null) revision.value += 1;
    }
    if (persist) {
      unawaited(
        _saveBudgetItemLimit(item, normalized, notifyStore: notifyStore),
      );
    }
  }

  Future<void> _saveBudgetItemLimit(
    BackheaderBudgetItem item,
    double amount, {
    bool notifyStore = true,
  }) async {
    final store = _bridge.store;
    final normalized = math.max(0.0, amount).toDouble();
    final overview = item.overview;
    final category = item.category;
    try {
      if (overview != null) {
        await store.saveOverviewLimitInline(
          overview.kind,
          limitAmount: normalized,
          alertActive: normalized > 0,
          notify: notifyStore,
        );
      } else if (category != null) {
        await store.saveCategoryLimitForBarInline(
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

  void dispose() {
    if (_disposed) return;
    _invalidateInteractionIdentity();
    _disposed = true;
    _carouselReleaseController.dispose();
  }
}

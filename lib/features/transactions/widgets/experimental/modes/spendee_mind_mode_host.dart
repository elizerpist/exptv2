part of '../spendee_test_dashboard.dart';

class SpendeeMindModeHost extends StatefulWidget {
  const SpendeeMindModeHost._({super.key, required dashboard})
    : _dashboard = dashboard;

  final _SpendeeTestDashboardState _dashboard;

  @override
  State<SpendeeMindModeHost> createState() => _SpendeeMindModeHostState();
}

class _SpendeeMindModeHostState extends State<SpendeeMindModeHost>
    with TickerProviderStateMixin {
  late final _SpendeeLegacyInteractionCoordinator _coordinator;
  late final ValueNotifier<SpendeeHeaderStage> _stageNotifier;
  late final ValueNotifier<_MindGlobalRailPresentation>
  _mindGlobalRailPresentation;

  var _mindSumYearCarouselLiveTicked = false;
  var _mindSumYearCarouselVisualDx = 0.0;
  SpendeeCenterCarouselController? _mindSumYearCarouselController;
  late final AnimationController _mindSumYearCarouselReleaseController;
  var _mindSumYearCarouselMotionSerial = 0;
  var _mindRuntimeGeneration = 0;
  var _mindRuntimeDisposed = false;

  int? _selectedMindSumYear;
  int? _publishedMindSumYear;
  _MindStatsFrameCacheKey? _mindStatsFrameCacheKey;
  SpendeeMindStatsFrame? _mindStatsFrameCache;
  _MindSumVolumeFrameCacheKey? _mindSumVolumeFrameCacheKey;
  StatsRenderFrame? _mindSumVolumeFrameCache;
  final _mindSumYearFrameCache =
      <_MindSumYearFrameCacheKey, StatsRenderFrame>{};
  _MindSumStage2WidgetCacheKey? _mindSumStage2WidgetCacheKey;
  Widget? _mindSumStage2WidgetCache;

  @override
  void initState() {
    super.initState();
    _stageNotifier = ValueNotifier<SpendeeHeaderStage>(
      SpendeeHeaderStage.stage0,
    );
    _mindGlobalRailPresentation = ValueNotifier(
      _currentMindGlobalRailPresentation(),
    );
    _mindSumYearCarouselReleaseController = AnimationController(vsync: this);
    _coordinator = _SpendeeLegacyInteractionCoordinator(
      vsync: this,
      bridge: _legacyBridge(),
      rebuildHost: _rebuild,
    );
  }

  @override
  void didUpdateWidget(covariant SpendeeMindModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMindGlobalRailPresentation();
    _coordinator.replaceBridge(_legacyBridge());
  }

  _SpendeeLegacyInteractionBridge _legacyBridge() {
    return _legacyInteractionBridgeFor(
      context,
      widget._dashboard,
      publishStage: _publishLegacyHeaderStage,
      resolveMindStage2Year: _resolveMindStage2Year,
      publishMindStage2Year: (year) =>
          _publishMindSumYearForStage2(year, source: 'stage_enter'),
    );
  }

  void _publishLegacyHeaderStage(SpendeeHeaderStage stage) {
    if (_mindRuntimeDisposed || _stageNotifier.value == stage) return;
    _stageNotifier.value = stage;
  }

  int? _resolveMindStage2Year() {
    if (_mindRuntimeDisposed ||
        widget._dashboard._headerBackgroundMode != _HeaderBackgroundMode.mind ||
        widget._dashboard.widget.store.summaryWindow != SummaryWindow.allTime) {
      return null;
    }
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    return _selectedMindSumYearFor(_mindSumYearsFor(frame));
  }

  _MindGlobalRailPresentation _currentMindGlobalRailPresentation() {
    final dashboard = widget._dashboard;
    return _MindGlobalRailPresentation(
      enabled: dashboard._headerBackgroundMode == _HeaderBackgroundMode.mind,
      railConfig: dashboard._mindSumYearRailConfig,
      railSurface: dashboard._mindGlobalRailSurface,
      railOpacity: dashboard._mindGlobalRailOpacity,
      yearCardEnabled: dashboard._mindSumYearCardEnabled,
      yearCardSurface: dashboard._mindSumYearCardSurface,
      yearCardOpacity: dashboard._mindSumYearCardOpacity,
      showVolumeBars: dashboard._mindSumYearVolumeBarsEnabled,
      selectedYear: _selectedMindSumYear,
    );
  }

  void _syncMindGlobalRailPresentation() {
    if (_mindRuntimeDisposed) return;
    _mindGlobalRailPresentation.value = _currentMindGlobalRailPresentation();
  }

  Widget _buildMindHomeContent() {
    final dashboard = widget._dashboard;
    return _SpendeeHomeContent(
      key: const ValueKey('spendee-test-home-content'),
      store: dashboard.widget.store,
      expenseTheme: dashboard.widget.expenseTheme,
      stageListenable: _stageNotifier,
      mindGlobalRailPresentationListenable: _mindGlobalRailPresentation,
      onMindSumYearSelected: _setSelectedMindSumYear,
      onPickSummaryMonth: dashboard.widget.onPickSummaryMonth,
      onEditTransaction: dashboard.widget.onEditTransaction,
      onDeleteTransactionRequested:
          dashboard.widget.onDeleteTransactionRequested,
      onVendorSheetRequested: dashboard.widget.onVendorSheetRequested,
      logBottomPadding: dashboard.widget.logBottomPadding,
    );
  }

  _SpendeeLegacyMindRuntime get _mindRuntime {
    return _SpendeeLegacyMindRuntime(
      statsFrameFor: _mindStatsFrameFor,
      sumVolumeFrameFor: _mindSumVolumeFrameFor,
      sumYearsFor: _mindSumYearsFor,
      selectedYearFor: _selectedMindSumYearFor,
      publishedYearFor: _publishedMindSumYearFor,
      sumYearFrameFor: _mindSumYearFrameFor,
      sumStage2WidgetFor: _mindSumStage2WidgetFor,
      sumYearCarouselVisualDx: () => _mindSumYearCarouselVisualDx,
      animateSumYearCarouselTo: _animateMindSumYearCarouselTo,
      onSumYearCarouselDragStart: _handleMindSumYearCarouselDragStart,
      onSumYearCarouselDragUpdate: _handleMindSumYearCarouselDragUpdate,
      onSumYearCarouselDragEnd: _handleMindSumYearCarouselDragEnd,
      onSumYearCarouselDragCancel: _handleMindSumYearCarouselDragCancel,
    );
  }

  void _rebuild() {
    if (!_mindRuntimeDisposed && mounted) setState(() {});
  }

  bool get _isMindRuntimeActive => !_mindRuntimeDisposed && mounted;

  bool _ownsMindMotion(int serial, int generation) {
    return _isMindRuntimeActive &&
        generation == _mindRuntimeGeneration &&
        serial == _mindSumYearCarouselMotionSerial;
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

  List<int> _mindSumYearsFor(StatsRenderFrame frame) {
    final years = <int>{
      for (final summary in frame.yearData.sumYearSummaries)
        if (summary.monthTotals.isNotEmpty) summary.year,
    }.toList()..sort((left, right) => right.compareTo(left));
    if (years.isNotEmpty) return years;
    return [frame.yearData.year];
  }

  int _selectedMindSumYearFor(List<int> years) {
    final selected = _selectedMindSumYear;
    if (selected != null && years.contains(selected)) return selected;
    return years.first;
  }

  int _publishedMindSumYearFor(List<int> years) {
    final published = _publishedMindSumYear;
    if (published != null && years.contains(published)) return published;
    return _selectedMindSumYearFor(years);
  }

  int _mindSumYearIndex(List<int> years) {
    final selectedYear = _selectedMindSumYearFor(years);
    final index = years.indexOf(selectedYear);
    return index < 0 ? 0 : index;
  }

  StatsRenderFrame _mindSumVolumeFrameFor(TransactionStore store) {
    final key = _MindSumVolumeFrameCacheKey(
      statsKey: _MindStatsFrameCacheKey.fromStore(store),
      activeType: store.activeType,
    );
    final cachedKey = _mindSumVolumeFrameCacheKey;
    final cachedFrame = _mindSumVolumeFrameCache;
    if (cachedKey == key && cachedFrame != null) return cachedFrame;

    final frame = SpendeeMindStatsFrame.sumYearVolumeFrameFromStore(
      store,
      activeType: store.activeType,
    );
    _mindSumVolumeFrameCacheKey = key;
    _mindSumVolumeFrameCache = frame;
    return frame;
  }

  StatsRenderFrame _mindSumYearFrameFor(
    TransactionStore store, {
    required int year,
  }) {
    final key = _MindSumYearFrameCacheKey(
      statsKey: _MindStatsFrameCacheKey.fromStore(store),
      year: year,
      activeType: store.activeType,
    );
    final cachedFrame = _mindSumYearFrameCache[key];
    if (cachedFrame != null) return cachedFrame;

    final frame = SpendeeMindStatsFrame.sumYearFrameFromStore(
      store,
      year: year,
      activeType: store.activeType,
    );
    if (_mindSumYearFrameCache.length >= 12) {
      _mindSumYearFrameCache.remove(_mindSumYearFrameCache.keys.first);
    }
    _mindSumYearFrameCache[key] = frame;
    return frame;
  }

  Widget _mindSumStage2WidgetFor({
    required StatsRenderFrame frame,
    required int year,
  }) {
    final dashboard = widget._dashboard;
    final key = _MindSumStage2WidgetCacheKey(
      frame: frame,
      year: year,
      outerEnabled: dashboard._mindSumStage2OuterEnabled,
      outerSurface: dashboard._mindSumStage2Surface,
      outerSoftness: dashboard._mindStage2Softness,
      outerOpacity: dashboard._mindSumStage2Opacity,
      monthCardEnabled: dashboard._mindSumMonthCardEnabled,
      monthCardSurface: dashboard._mindSumMonthCardSurface,
      monthCardOpacity: dashboard._mindSumMonthCardOpacity,
    );
    final cachedKey = _mindSumStage2WidgetCacheKey;
    final cachedWidget = _mindSumStage2WidgetCache;
    if (cachedKey == key && cachedWidget != null) return cachedWidget;

    final result = RepaintBoundary(
      key: const ValueKey('spendee-test-mind-sum-stage2-repaint-boundary'),
      child: _MindSumSelectedYearHeatmap(
        frame: frame,
        selectedYear: year,
        outerEnabled: dashboard._mindSumStage2OuterEnabled,
        outerSurface: dashboard._mindSumStage2Surface,
        outerSoftness: dashboard._mindStage2Softness,
        outerOpacity: dashboard._mindSumStage2Opacity,
        monthCardEnabled: dashboard._mindSumMonthCardEnabled,
        monthCardSurface: dashboard._mindSumMonthCardSurface,
        monthCardOpacity: dashboard._mindSumMonthCardOpacity,
      ),
    );
    _mindSumStage2WidgetCacheKey = key;
    _mindSumStage2WidgetCache = result;
    return result;
  }

  void _publishMindSumYearForStage2(int? year, {required String source}) {
    if (_mindRuntimeDisposed || year == null || _publishedMindSumYear == year) {
      return;
    }
    _publishedMindSumYear = year;
    DebugConsole.log(
      '[Perf] SpendeeTest mind_sum_stage2_publish '
      'source=$source selected=$year',
    );
  }

  void _setSelectedMindSumYear(int year, {bool haptic = true}) {
    if (!_isMindRuntimeActive || _selectedMindSumYear == year) return;
    if (haptic) HapticFeedback.selectionClick();
    setState(() {
      _selectedMindSumYear = year;
      if (_stageNotifier.value == SpendeeHeaderStage.stage2) {
        _publishMindSumYearForStage2(year, source: 'rail');
      }
      _syncMindGlobalRailPresentation();
    });
  }

  void _handleMindSumYearCarouselDragStart(DragStartDetails details) {
    if (!_isMindRuntimeActive) return;
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    final years = _mindSumYearsFor(frame);
    final activeController = _mindSumYearCarouselController;
    _mindSumYearCarouselMotionSerial += 1;
    _mindSumYearCarouselReleaseController.stop();
    final selectedYear = _selectedMindSumYearFor(years);
    final canResumeController =
        activeController != null &&
        activeController.itemCount == years.length &&
        years[activeController.index] == selectedYear;
    final controller = canResumeController
        ? activeController
        : SpendeeCenterCarouselController(
            itemCount: years.length,
            initialIndex: _mindSumYearIndex(years),
          );
    controller.beginDragFromCurrentMotion();
    setState(() {
      _mindSumYearCarouselLiveTicked = false;
      _mindSumYearCarouselVisualDx = controller.residualDx;
      _mindSumYearCarouselController = controller;
    });
  }

  void _handleMindSumYearCarouselDragUpdate(DragUpdateDetails details) {
    if (!_isMindRuntimeActive) return;
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    final years = _mindSumYearsFor(frame);
    if (years.length < 2) return;
    final controller = _mindSumYearCarouselController ??=
        SpendeeCenterCarouselController(
          itemCount: years.length,
          initialIndex: _mindSumYearIndex(years),
        );
    final update = controller.applyDragDelta(details.delta.dx);
    int? latestYear;
    for (final index in update.tickedIndexes) {
      _mindSumYearCarouselLiveTicked = true;
      latestYear = years[index % years.length];
      HapticFeedback.selectionClick();
      DebugConsole.log(
        '[Perf] SpendeeTest mind_sum_year_tick source=drag selected=$latestYear',
      );
    }
    setState(() {
      if (latestYear != null) _selectedMindSumYear = latestYear;
      _mindSumYearCarouselVisualDx = update.residualDx;
      _syncMindGlobalRailPresentation();
    });
  }

  void _handleMindSumYearCarouselDragEnd(DragEndDetails details) {
    final controller = _mindSumYearCarouselController;
    if (!_isMindRuntimeActive ||
        controller == null ||
        controller.itemCount < 2) {
      return;
    }
    final generation = _mindRuntimeGeneration;
    unawaited(
      _releaseMindSumYearCarousel(
        controller: controller,
        velocityDx: details.velocity.pixelsPerSecond.dx,
        serial: _mindSumYearCarouselMotionSerial,
        generation: generation,
      ),
    );
  }

  void _handleMindSumYearCarouselDragCancel() {
    final controller = _mindSumYearCarouselController;
    if (!_isMindRuntimeActive || controller == null) return;
    final generation = _mindRuntimeGeneration;
    unawaited(
      _cancelMindSumYearCarousel(
        controller: controller,
        serial: _mindSumYearCarouselMotionSerial,
        generation: generation,
      ),
    );
  }

  Future<void> _cancelMindSumYearCarousel({
    required SpendeeCenterCarouselController controller,
    required int serial,
    required int generation,
  }) async {
    _mindSumYearCarouselLiveTicked = false;
    final travel = controller.cancelTravel();
    try {
      if (travel.abs() >= .5) {
        await _animateMindSumYearCarouselTravel(
          controller: controller,
          travel: travel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          serial: serial,
          generation: generation,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      _finishMindSumYearCarousel(
        controller: controller,
        serial: serial,
        generation: generation,
        source: 'drag_cancel',
      );
    }
  }

  Future<void> _releaseMindSumYearCarousel({
    required SpendeeCenterCarouselController controller,
    required double velocityDx,
    required int serial,
    required int generation,
  }) async {
    final motion = controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: _mindSumYearCarouselLiveTicked,
    );
    _mindSumYearCarouselLiveTicked = false;
    try {
      if (motion.initialTravel.abs() >= .5) {
        await _animateMindSumYearCarouselTravel(
          controller: controller,
          travel: motion.initialTravel,
          duration: motion.initialDuration,
          curve: motion.inertial ? Curves.easeOutQuad : Curves.easeOutCubic,
          serial: serial,
          generation: generation,
        );
      }
      if (!_ownsMindMotion(serial, generation)) return;
      final settleTravel = controller.settleTravel(
        preferredDxDirection: motion.preferredDxDirection,
        allowDirectionalSnap: motion.directionalSnapAllowed,
      );
      if (settleTravel.abs() >= .5) {
        await _animateMindSumYearCarouselTravel(
          controller: controller,
          travel: settleTravel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          serial: serial,
          generation: generation,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      _finishMindSumYearCarousel(
        controller: controller,
        serial: serial,
        generation: generation,
        source: 'drag_settle',
      );
    }
  }

  void _finishMindSumYearCarousel({
    required SpendeeCenterCarouselController controller,
    required int serial,
    required int generation,
    required String source,
  }) {
    if (!_ownsMindMotion(serial, generation)) return;
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    final years = _mindSumYearsFor(frame);
    final year = years[controller.index % years.length];
    _mindSumYearCarouselController = null;
    setState(() {
      _selectedMindSumYear = year;
      if (_stageNotifier.value == SpendeeHeaderStage.stage2) {
        _publishMindSumYearForStage2(year, source: source);
      }
      _mindSumYearCarouselVisualDx = 0;
      _syncMindGlobalRailPresentation();
    });
  }

  Future<void> _animateMindSumYearCarouselTravel({
    required SpendeeCenterCarouselController controller,
    required double travel,
    required Duration duration,
    required Curve curve,
    required int serial,
    required int generation,
  }) async {
    if (!_ownsMindMotion(serial, generation)) return;
    _mindSumYearCarouselReleaseController.stop();
    _mindSumYearCarouselReleaseController.duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(begin: 0, end: travel).animate(
      CurvedAnimation(
        parent: _mindSumYearCarouselReleaseController,
        curve: curve,
      ),
    );
    void applyFrame() {
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta == 0 || !_ownsMindMotion(serial, generation)) return;
      _applyMindSumYearCarouselMotionDelta(controller, delta);
    }

    animation.addListener(applyFrame);
    var completed = false;
    try {
      await _mindSumYearCarouselReleaseController.forward(from: 0).orCancel;
      completed = true;
    } finally {
      animation.removeListener(applyFrame);
    }
    if (!completed || !_ownsMindMotion(serial, generation)) return;
    final remaining = travel - lastValue;
    if (remaining.abs() > .001) {
      _applyMindSumYearCarouselMotionDelta(controller, remaining);
    }
  }

  void _applyMindSumYearCarouselMotionDelta(
    SpendeeCenterCarouselController controller,
    double deltaDx,
  ) {
    if (!_isMindRuntimeActive) return;
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    final years = _mindSumYearsFor(frame);
    if (years.length < 2) return;
    final update = controller.applyDragDelta(deltaDx);
    int? latestYear;
    for (final index in update.tickedIndexes) {
      latestYear = years[index % years.length];
      HapticFeedback.selectionClick();
      DebugConsole.log(
        '[Perf] SpendeeTest mind_sum_year_tick '
        'source=motion selected=$latestYear',
      );
    }
    setState(() {
      if (latestYear != null) _selectedMindSumYear = latestYear;
      _mindSumYearCarouselVisualDx = update.residualDx;
      _syncMindGlobalRailPresentation();
    });
  }

  Future<void> _animateMindSumYearCarouselTo(int year) async {
    if (!_isMindRuntimeActive) return;
    final frame = _mindSumVolumeFrameFor(widget._dashboard.widget.store);
    final years = _mindSumYearsFor(frame);
    final targetIndex = years.indexOf(year);
    if (targetIndex < 0) return;
    final initialIndex = _mindSumYearIndex(years);
    if (targetIndex == initialIndex) {
      _setSelectedMindSumYear(year);
      return;
    }
    _mindSumYearCarouselMotionSerial += 1;
    final serial = _mindSumYearCarouselMotionSerial;
    final generation = _mindRuntimeGeneration;
    _mindSumYearCarouselReleaseController.stop();
    final controller = SpendeeCenterCarouselController(
      itemCount: years.length,
      initialIndex: initialIndex,
    );
    setState(() {
      _mindSumYearCarouselLiveTicked = false;
      _mindSumYearCarouselVisualDx = 0;
      _mindSumYearCarouselController = controller;
    });
    try {
      var guard = 0;
      while (_ownsMindMotion(serial, generation) &&
          controller.index != targetIndex &&
          guard < years.length) {
        guard += 1;
        final remaining = controller.travelToIndex(targetIndex);
        if (remaining.abs() < .5) break;
        final stepTravel = remaining
            .clamp(-controller.slotDistance, controller.slotDistance)
            .toDouble();
        await _animateMindSumYearCarouselTravel(
          controller: controller,
          travel: stepTravel,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          serial: serial,
          generation: generation,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      _finishMindSumYearCarousel(
        controller: controller,
        serial: serial,
        generation: generation,
        source: 'tap_settle',
      );
    }
  }

  @override
  void dispose() {
    _mindRuntimeDisposed = true;
    _mindRuntimeGeneration += 1;
    _mindSumYearCarouselMotionSerial += 1;
    _mindSumYearCarouselReleaseController.stop();
    _mindSumYearCarouselController = null;
    _mindSumYearFrameCache.clear();
    _mindSumStage2WidgetCache = null;
    _mindSumStage2WidgetCacheKey = null;
    _mindSumVolumeFrameCache = null;
    _mindSumVolumeFrameCacheKey = null;
    _mindStatsFrameCache = null;
    _mindStatsFrameCacheKey = null;
    _coordinator.dispose();
    _stageNotifier.dispose();
    _mindGlobalRailPresentation.dispose();
    _mindSumYearCarouselReleaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('spendee-mode-host-mind'),
      child: _buildSpendeeLegacyModeContent(
        context,
        widget._dashboard,
        _coordinator,
        homeContent: _buildMindHomeContent(),
        mindRuntime: _mindRuntime,
      ),
    );
  }
}

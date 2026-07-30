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
  late TransactionStore _mindStore;
  _SpendeeHomeContentDependencies? _mindHomeContentDependencies;
  Widget? _mindHomeContent;

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
    _mindStore = widget._dashboard.widget.store;
    _stageNotifier = ValueNotifier<SpendeeHeaderStage>(
      SpendeeHeaderStage.stage0,
    );
    _mindGlobalRailPresentation = ValueNotifier(
      _currentMindGlobalRailPresentation(),
    );
    _refreshMindHomeContent();
    _coordinator = _SpendeeLegacyInteractionCoordinator(
      vsync: this,
      bridge: _legacyBridge(),
      rebuildHost: _rebuild,
    );
  }

  @override
  void didUpdateWidget(covariant SpendeeMindModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStore = widget._dashboard.widget.store;
    if (!identical(_mindStore, nextStore)) {
      _invalidateMindRuntimeForStoreReplacement();
      _mindStore = nextStore;
    }
    _refreshMindHomeContent();
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
    final frame = _mindSumVolumeFrameFor(_mindStore);
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

  void _refreshMindHomeContent() {
    final dependencies = _SpendeeHomeContentDependencies.fromDashboard(
      widget._dashboard,
    );
    final previous = _mindHomeContentDependencies;
    if (previous != null && dependencies.matches(previous)) return;
    _mindHomeContentDependencies = dependencies;
    _mindHomeContent = _buildMindHomeContent(dependencies);
  }

  Widget _buildMindHomeContent(_SpendeeHomeContentDependencies dependencies) {
    return _SpendeeHomeContent(
      key: const ValueKey('spendee-test-home-content'),
      store: dependencies.store,
      expenseTheme: dependencies.expenseTheme,
      stageListenable: _stageNotifier,
      mindGlobalRailPresentationListenable: _mindGlobalRailPresentation,
      onMindSumYearSelected: _setSelectedMindSumYear,
      onPickSummaryMonth: dependencies.onPickSummaryMonth,
      onEditTransaction: dependencies.onEditTransaction,
      onDeleteTransactionRequested: dependencies.onDeleteTransactionRequested,
      onVendorSheetRequested: dependencies.onVendorSheetRequested,
      logBottomPadding: dependencies.logBottomPadding,
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
    );
  }

  void _rebuild() {
    if (!_mindRuntimeDisposed && mounted) setState(() {});
  }

  bool get _isMindRuntimeActive => !_mindRuntimeDisposed && mounted;

  void _invalidateMindRuntimeForStoreReplacement() {
    _selectedMindSumYear = null;
    _publishedMindSumYear = null;
    _clearMindRuntimeCaches();
  }

  void _clearMindRuntimeCaches() {
    _mindSumYearFrameCache.clear();
    _mindSumStage2WidgetCache = null;
    _mindSumStage2WidgetCacheKey = null;
    _mindSumVolumeFrameCache = null;
    _mindSumVolumeFrameCacheKey = null;
    _mindStatsFrameCache = null;
    _mindStatsFrameCacheKey = null;
  }

  SpendeeMindStatsFrame _mindStatsFrameFor(
    TransactionStore _, {
    required String reason,
  }) {
    final store = _mindStore;
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

  StatsRenderFrame _mindSumVolumeFrameFor(TransactionStore _) {
    final store = _mindStore;
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
    TransactionStore _, {
    required int year,
  }) {
    final store = _mindStore;
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

  @override
  void dispose() {
    _mindRuntimeDisposed = true;
    _clearMindRuntimeCaches();
    _mindHomeContent = null;
    _mindHomeContentDependencies = null;
    _coordinator.dispose();
    _stageNotifier.dispose();
    _mindGlobalRailPresentation.dispose();
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
        homeContent: _mindHomeContent!,
        mindRuntime: _mindRuntime,
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/financial_limits/domain/financial_limit_repository.dart';
import '../../../core/financial_limits/presentation/budget_ring_presentation.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_logbox_layout_profile.dart';
import '../../../core/design/dashboard_body_order.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/motion/dashboard_motion_host.dart';
import '../application/dashboard_core_controller.dart';
import '../application/dashboard_core_mode_controller.dart';
import '../application/dashboard_mode_spec.dart';
import '../application/dashboard_budget_presentation_controller.dart';
import '../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../application/dashboard_spending_rhythm_controller.dart';
import '../application/dashboard_budget_limit_edit_controller.dart';
import '../application/dashboard_ephemeral_focus_controller.dart';
import '../application/dashboard_performance_counters.dart';
import '../query/domain/ledger_direction.dart';
import '../query/domain/query_amount_range.dart';
import 'core_modes/dashboard_core_mode_host.dart';
import 'core_modes/dashboard_header_visual_engine.dart';
import 'core_modes/dashboard_header_visual_tuner.dart';
import 'core_modes/budget_category_distribution_visual_bank.dart';
import 'core_modes/budget_distribution_pager.dart';
import 'core_modes/budget_target_avatar_rail_controller.dart';
import 'widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'widgets/dashboard_logbox_partner_swipe.dart';
import 'widgets/dashboard_logbox_render_surface.dart';
import '../application/transaction_direction_controller.dart';
import 'summary_navigation_motion_controller.dart';
import 'budget_content_card_style.dart';
import 'budget_section_order.dart';
import 'dashboard_corner_roundness.dart';
import 'dashboard_border_style.dart';
import 'dashboard_logbox_height.dart';
import 'dashboard_logbox_amount_palette.dart';
import 'dashboard_logbox_search_pill_visibility.dart';
import 'dashboard_budget_header_presentation.dart';
import 'dashboard_shell_presentation.dart';
import 'dashboard_shadow_style.dart';
import 'summary_pill_variant.dart';
import 'dashboard_summary_presentation.dart';
import 'dashboard_summary_auto_reset_controller.dart';
import 'dashboard_upper_vertical_gesture_coordinator.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import 'widgets/dashboard_collapse_handle.dart';
import 'widgets/dashboard_logbox_viewport.dart';
import 'widgets/dashboard_render_phase_probe.dart';
import 'widgets/dashboard_summary_pill.dart';
import 'widgets/summary_pill_experiments.dart';
import 'widgets/fluvi_brand_lockup.dart';
import 'widgets/summary_pill_text_transition.dart';
import 'widgets/transaction_direction_toggle.dart';

/// Shared dashboard composition with one bounded, separately-owned mode domain.
class CoreDashboard extends StatefulWidget {
  const CoreDashboard({
    super.key,
    required this.controller,
    required this.modeController,
    required this.categoryCollection,
    this.financialLimitRepository,
    this.onBudgetCategoryInputUpdated,
    this.preparedLogBoxRasters,
    this.onLogBoxWarmupSurfaceAttached,
    this.onLogBoxWarmupSurfaceLaidOut,
    this.onLogBoxWarmupTextLayoutsPrepared,
    this.onLogBoxWarmupError,
    this.shellPresentation,
  });

  final DashboardCoreController controller;
  final DashboardCoreModeController modeController;
  final ValueListenable<List<FluviCategory>> categoryCollection;
  final FinancialLimitRepository? financialLimitRepository;
  final ValueChanged<int>? onBudgetCategoryInputUpdated;
  final PreparedLogBoxRasterSet? preparedLogBoxRasters;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onLogBoxWarmupError;
  final DashboardShellPresentationController? shellPresentation;

  @override
  State<CoreDashboard> createState() => _CoreDashboardState();
}

class _CoreDashboardState extends State<CoreDashboard>
    with TickerProviderStateMixin {
  late final SummaryNavigationMotionController _summaryMotionController;
  late final SummaryPillVariantController _summaryPillVariantController;
  late final DashboardBodyOrderController _bodyOrderController;
  late final BudgetContentCardStyleController _budgetContentCardStyle;
  late final BudgetSectionOrderController _budgetSectionOrderController;
  late final DashboardSummaryPresentationController
  _summaryPresentationController;
  late final DashboardCornerRoundnessController _cornerRoundnessController;
  late final DashboardShadowStyleController _shadowStyleController;
  late final DashboardBorderController _borderController;
  late final DashboardLogBoxHeightController _logBoxHeightController;
  late final DashboardLogBoxAmountPaletteController
  _logBoxAmountPaletteController;
  late final DashboardLogBoxSearchPillController _logBoxSearchPillController;
  late final DashboardBudgetHeaderPresentationController
  _budgetHeaderPresentationController;
  late final BudgetRingPresentationController _budgetRingPresentationController;
  late final DashboardLogBoxPreparedSceneCache _preparedSceneCache;
  late final DashboardLogBoxPartnerSwipeController _partnerSwipe;
  late final DashboardBudgetPresentationController _budgetPresentation;
  late final DashboardBudgetLogboxDrilldownCoordinator _budgetDrilldown;
  late final DashboardSpendingRhythmController _budgetRhythm;
  late final DashboardBudgetDistributionDrawableController
  _budgetDistributionDrawables;
  late final BudgetTargetAvatarRailController _budgetAvatarRailController;
  late final BudgetDistributionPageController _budgetDistributionPageController;
  late final DashboardHeaderVisualController _headerVisualController;
  late final DashboardHeaderStaticColorPolicy _balanceHeaderColorPolicy;
  late final DashboardBudgetHeaderColorPolicy _budgetHeaderColorPolicy;
  late final DashboardHeaderStaticColorPolicy _mindHeaderColorPolicy;
  late final DashboardSummaryAutoResetController _summaryAutoResetController;
  late final DashboardSummaryAutoResetMotionRegistry _summaryAutoResetMotions;
  late final DashboardUpperVerticalGestureCoordinator _upperVerticalGestures;
  DashboardBudgetLimitEditController? _budgetLimitEdit;
  double _devicePixelRatio = 1;
  int? _lastMindRangeDiagnosticSignature;
  int? _lastLayerStackDiagnosticSignature;

  DashboardCoreController get controller => widget.controller;
  DashboardCoreModeController get modeController => widget.modeController;

  @override
  void initState() {
    super.initState();
    _summaryMotionController = SummaryNavigationMotionController();
    _summaryMotionController.addListener(_onSummaryTextMotionChanged);
    _summaryPillVariantController = SummaryPillVariantController();
    _bodyOrderController = DashboardBodyOrderController();
    _budgetContentCardStyle = BudgetContentCardStyleController();
    _budgetSectionOrderController = BudgetSectionOrderController();
    _summaryPresentationController = DashboardSummaryPresentationController();
    _summaryAutoResetController = DashboardSummaryAutoResetController();
    _summaryAutoResetMotions = DashboardSummaryAutoResetMotionRegistry();
    _upperVerticalGestures = DashboardUpperVerticalGestureCoordinator(
      expansion: controller.expansion,
      mapViewportDelta: (delta) => delta,
      onForegroundInteraction: _cancelSummaryAutoReset,
    );
    _cornerRoundnessController = DashboardCornerRoundnessController();
    _shadowStyleController = DashboardShadowStyleController();
    _borderController = DashboardBorderController();
    _logBoxHeightController = DashboardLogBoxHeightController();
    _logBoxAmountPaletteController = DashboardLogBoxAmountPaletteController();
    _logBoxSearchPillController = DashboardLogBoxSearchPillController();
    _budgetHeaderPresentationController =
        DashboardBudgetHeaderPresentationController();
    _budgetRingPresentationController = BudgetRingPresentationController();
    _logBoxHeightController.addListener(_onLogBoxHeightChanged);
    _summaryPillVariantController.addListener(_onLayoutPresentationChanged);
    _bodyOrderController.addListener(_onLayoutPresentationChanged);
    _budgetSectionOrderController.addListener(_onLayoutPresentationChanged);
    final financialLimitRepository = widget.financialLimitRepository;
    if (financialLimitRepository != null) {
      _budgetLimitEdit = DashboardBudgetLimitEditController(
        repository: financialLimitRepository,
        isKeyCurrent: (key) => _budgetPresentation.isLimitEditKeyCurrent(key),
        isYearContextCurrent: (context) =>
            _budgetPresentation.isYearLimitEditContextCurrent(context),
      );
    }
    _budgetPresentation = DashboardBudgetPresentationController(
      categoryCollection: widget.categoryCollection,
      visibleFrame: controller.visibleFrames,
      liveInteractions: controller.liveInteractions,
      transactionDirection: controller.transactionDirection,
      snapshotForCurrentFrame: () =>
          controller.activePreparedRevisionBundle?.budgetLimitSnapshot,
      logicalAsOfDate: controller.logicalAsOfDate,
      limitEditController: _budgetLimitEdit,
      onInputUpdated: widget.onBudgetCategoryInputUpdated,
    );
    _headerVisualController = DashboardHeaderVisualController(vsync: this);
    _balanceHeaderColorPolicy = DashboardHeaderStaticColorPolicy(
      DashboardModePaletteResolver.resolve(
        DashboardModeSpec.balance,
      ).upcomingHeaderTone,
    );
    _budgetHeaderColorPolicy = DashboardBudgetHeaderColorPolicy(
      tuning: _headerVisualController.tuning,
      budgetPresentation: _budgetPresentation,
    );
    _mindHeaderColorPolicy = DashboardHeaderStaticColorPolicy(
      DashboardModePaletteResolver.resolve(
        DashboardModeSpec.mind,
      ).upcomingHeaderTone,
    );
    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(
        stage: 'HEADER_VISUAL_POLICY_BOUND',
        message:
            'sharedController=DashboardHeaderVisualController '
            'modePolicies=balance:static,budget:live,mind:static '
            'tickerOwners=1',
      ),
    );
    _budgetDrilldown = DashboardBudgetLogboxDrilldownCoordinator(
      core: controller,
      presentation: _budgetPresentation,
    );
    _budgetRhythm = DashboardSpendingRhythmController(
      presentation: _budgetPresentation,
      snapshotForCurrentFrame: () =>
          controller.activePreparedRevisionBundle?.budgetLimitSnapshot,
    );
    _budgetDistributionDrawables =
        DashboardBudgetDistributionDrawableController(
          categories: widget.categoryCollection,
          snapshotForCurrentFrame: () =>
              controller.activePreparedRevisionBundle?.budgetLimitSnapshot,
          partnerSnapshotForCurrentFrame: () => controller
              .activePreparedRevisionBundle
              ?.partnerDistributionSnapshot,
          directChildScopesFor: _budgetDirectChildScopesFor,
          isForegroundInputActive: () => controller.foregroundInputMotion.value,
        );
    modeController.addListener(_syncBudgetDistributionTimePublicationPreparer);
    _syncBudgetDistributionTimePublicationPreparer();
    controller.visibleFrames.addListener(_onBudgetDistributionVisibleFrame);
    controller.liveInteractions.addListener(_onBudgetDistributionVisibleFrame);
    _budgetPresentation.addListener(_onBudgetDistributionVisibleFrame);
    controller.foregroundInputMotion.addListener(
      _onBudgetDistributionVisibleFrame,
    );
    _onBudgetDistributionVisibleFrame();
    _budgetAvatarRailController = BudgetTargetAvatarRailController(
      onExplicitTargetIntent: (request) => unawaited(
        _budgetDrilldown.commitBudgetTargetHandle(
          targetHandle: request.targetHandle,
          source: request.source.name,
        ),
      ),
    );
    _budgetDistributionPageController = BudgetDistributionPageController();
    _preparedSceneCache = DashboardLogBoxPreparedSceneCache();
    _preparedSceneCache.addListener(_recordSceneCacheMetrics);
    _partnerSwipe = DashboardLogBoxPartnerSwipeController(vsync: this);
    controller.attachLogBoxSceneWindowCoordinator(
      prepare: (window, {required retainViewportId}) =>
          _preparedSceneCache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            devicePixelRatio: _devicePixelRatio,
            maxContiguousUiSliceMicros: DashboardLogBoxPreparedSceneCache
                .defaultMaxContiguousUiSliceMicros,
            yieldToBackground: _yieldScenePreparationToScheduler,
          ),
      stageFromActiveResources: (window, {required retainViewportId}) =>
          _preparedSceneCache.stageWindowFromActiveResources(window),
      discardStagedActiveResources:
          _preparedSceneCache.discardStagedActiveResourceWindow,
      prepareCandidate:
          (window, {required candidateKey, required retainViewportId}) =>
              _preparedSceneCache.prepareCandidateWindow(
                candidateKey: candidateKey,
                window: window,
                retainViewportId: retainViewportId,
                devicePixelRatio: _devicePixelRatio,
                maxContiguousUiSliceMicros: DashboardLogBoxPreparedSceneCache
                    .defaultMaxContiguousUiSliceMicros,
                yieldToBackground: _yieldScenePreparationToScheduler,
              ),
      discardCandidate: _preparedSceneCache.discardCandidateWindow,
      hasCandidate: (window, {required candidateKey}) => _preparedSceneCache
          .hasCandidateWindow(window, candidateKey: candidateKey),
      setCandidateHotset: _preparedSceneCache.setProtectedCandidateKeys,
      planCandidateHotset: _preparedSceneCache.admitCandidateHotset,
      planRetainedSceneWindow: _preparedSceneCache.admitRetainedWindow,
      prepareRetained:
          (window, {required retainedKey, required retainViewportId}) =>
              _preparedSceneCache.prepareRetainedWindow(
                retainedKey: retainedKey,
                window: window,
                surfaceWidth: controller.committedLogViewport.surfaceWidth,
                retainViewportId: retainViewportId,
                devicePixelRatio: _devicePixelRatio,
                maxContiguousUiSliceMicros: DashboardLogBoxPreparedSceneCache
                    .defaultMaxContiguousUiSliceMicros,
                yieldToBackground: _yieldScenePreparationToScheduler,
              ),
      hasRetained: _preparedSceneCache.hasRetainedWindow,
      retainActive: (window, {required retainedKey}) => _preparedSceneCache
          .retainActiveWindow(retainedKey: retainedKey, window: window),
      discardRetainedFocus: _preparedSceneCache.discardRetainedFocusBaseWindow,
      activate: _preparedSceneCache.activateWindow,
      cancel: _preparedSceneCache.cancelInFlightPreparation,
      scheduleRebase: _scheduleSceneRebaseOnNextFrame,
      report: _preparedSceneCache.report,
    );
  }

  void _scheduleSceneRebaseOnNextFrame(void Function() task) {
    WidgetsBinding.instance.scheduleFrameCallback((_) => task());
  }

  /// Cooperatively yields a bounded scene-layout slice without turning every
  /// checkpoint into an `endOfFrame` wait. Flutter runs higher priority input
  /// tasks before this animation-priority task, while preparation may continue
  /// in the same wall-clock frame when the scheduler has budget.
  Future<void> _yieldScenePreparationToScheduler() {
    // The automated binding owns a fake event loop. Leaving an animation task
    // queued while a test disposes the widget is reported as a leaked timer,
    // even though production would run it before the next input turn. Cache
    // unit/widget tests need deterministic completion, while the actual app
    // keeps the higher-priority scheduler path below.
    if (WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      return Future<void>.microtask(() {});
    }
    return SchedulerBinding.instance.scheduleTask<void>(
      () {},
      Priority.animation,
      debugLabel: 'CoreDashboard.scenePreparationYield',
    );
  }

  void _onSummaryTextMotionChanged() {
    controller.setMotionLaneActive(
      DashboardMotionLane.summaryText,
      _summaryMotionController.stagedText.isAxisMotionActive,
    );
  }

  void _onLogBoxHeightChanged() {
    controller.updateLogBoxLayoutProfile(
      DashboardLogBoxLayoutProfile(_logBoxHeightController.value),
    );
  }

  void _syncBudgetDistributionTimePublicationPreparer() {
    if (modeController.committedMode != DashboardModeSpec.budget) {
      controller.detachBudgetDistributionTimePublicationPreparer();
      return;
    }
    // Distribution warmup was previously the only Budget mode-entry action.
    // It can make Card2 current while Header/Ring retain an unavailable
    // previous frame. Replay the one atomic Budget presentation first, using
    // the mode owner's monotonic visible identity rather than a fake Avatar
    // selection or delayed retry.
    _budgetPresentation.publishForVisibleBudgetEpoch(
      modeController.committedModeEpoch,
    );
    controller.attachBudgetDistributionTimePublicationPreparer(
      prepare: (candidate) => _budgetDistributionDrawables
          .prepareForTimeScope(candidate.effectiveScope)
          .then((_) => true),
      warmHotset: _budgetDistributionDrawables.warmHotsetFor,
    );
    _onBudgetDistributionVisibleFrame();
  }

  void _recordSceneCacheMetrics() {
    controller.recordLogBoxTextLayoutCache(
      preparedRowCount: _preparedSceneCache.preparedRowCount,
      preparedDayHeaderCount: _preparedSceneCache.preparedDayHeaderCount,
      estimatedBytes: _preparedSceneCache.estimatedBytes,
    );
  }

  void _onBudgetDistributionVisibleFrame() {
    if (modeController.committedMode != DashboardModeSpec.budget) return;
    final snapshot =
        controller.activePreparedRevisionBundle?.budgetLimitSnapshot;
    final budget = _budgetPresentation.value;
    final liveAnalysis = budget.liveAnalysis;
    if (snapshot == null ||
        !liveAnalysis.isAvailable ||
        liveAnalysis.coreRevision != snapshot.coreRevision) {
      return;
    }
    final scope = liveAnalysis.scope!;
    if (!controller.foregroundInputMotion.value) {
      _warmBudgetDistributionPreviewHotset(
        scope: scope,
        direction: liveAnalysis.direction,
      );
    }
    final partnerId = controller.focus.state?.partner?.id;
    final publication = _budgetDistributionDrawables
        .publishCurrentScopeForeground(
          scope,
          direction: budget.liveSelection.direction,
          targetHandle: budget.selectedHandle,
          partnerId: partnerId,
        );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_BOUND',
        coreRevision: liveAnalysis.coreRevision,
        direction: liveAnalysis.direction.name,
        scope:
            'generation=${liveAnalysis.interactionGeneration} '
            'analysisScope=${scope.canonicalKey} '
            'targetHandle=${budget.selectedHandle} '
            'cacheHit=${publication.cacheHit} '
            'published=${publication.published}',
      ),
    );
  }

  Iterable<LedgerTimeScope> _budgetDirectChildScopesFor(
    DashboardNavigationState state,
  ) {
    final index = controller.activePreparedRevisionBundle?.index;
    if (index == null) return <LedgerTimeScope>[state.retainedChildScope];
    try {
      return <LedgerTimeScope>[
        for (final entry in index.catalogFor(state.parentQueryScope).entries)
          entry.scope.timeScope,
      ];
    } on Object {
      return <LedgerTimeScope>[state.retainedChildScope];
    }
  }

  void _warmBudgetDistributionPreviewHotset({
    required LedgerTimeScope scope,
    required LedgerDirection direction,
  }) {
    final index = controller.activePreparedRevisionBundle?.index;
    final parentScope = switch (scope) {
      AllTimeScope() || YearScope() => const AllTimeScope(),
      MonthScope(:final value) => YearScope(value.year),
      DayScope(:final date) => MonthScope(
        YearMonth(year: date.year, month: date.month),
      ),
    };
    final siblingScopes = index
        ?.catalogForIdentity(direction: direction, timeScope: parentScope)
        ?.entries
        .map((entry) => entry.scope.timeScope)
        .toList(growable: false);
    unawaited(
      _budgetDistributionDrawables.warmHotsetForPreviewScope(
        parentScope: parentScope,
        siblingScopes: siblingScopes ?? <LedgerTimeScope>[scope],
      ),
    );
  }

  @override
  void dispose() {
    _summaryAutoResetController.cancel();
    _summaryAutoResetMotions.cancelActiveResetMotion();
    _summaryAutoResetController.dispose();
    _upperVerticalGestures.cancel();
    controller.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
    controller.setMotionLaneActive(DashboardMotionLane.summaryText, false);
    controller.visibleFrames.removeListener(_onBudgetDistributionVisibleFrame);
    controller.liveInteractions.removeListener(
      _onBudgetDistributionVisibleFrame,
    );
    _budgetPresentation.removeListener(_onBudgetDistributionVisibleFrame);
    controller.foregroundInputMotion.removeListener(
      _onBudgetDistributionVisibleFrame,
    );
    modeController.removeListener(
      _syncBudgetDistributionTimePublicationPreparer,
    );
    controller.detachBudgetDistributionTimePublicationPreparer();
    controller.detachLogBoxSceneWindowCoordinator();
    _summaryMotionController.removeListener(_onSummaryTextMotionChanged);
    _summaryMotionController.dispose();
    _summaryPillVariantController.removeListener(_onLayoutPresentationChanged);
    _bodyOrderController.removeListener(_onLayoutPresentationChanged);
    _budgetSectionOrderController.removeListener(_onLayoutPresentationChanged);
    _summaryPillVariantController.dispose();
    _bodyOrderController.dispose();
    _budgetContentCardStyle.dispose();
    _budgetSectionOrderController.dispose();
    _summaryPresentationController.dispose();
    _cornerRoundnessController.dispose();
    _shadowStyleController.dispose();
    _borderController.dispose();
    _logBoxAmountPaletteController.dispose();
    _logBoxSearchPillController.dispose();
    _budgetHeaderPresentationController.dispose();
    _budgetRingPresentationController.dispose();
    _logBoxHeightController
      ..removeListener(_onLogBoxHeightChanged)
      ..dispose();
    _budgetDistributionDrawables.dispose();
    _budgetDistributionPageController.dispose();
    _budgetAvatarRailController.dispose();
    _budgetRhythm.dispose();
    _balanceHeaderColorPolicy.dispose();
    _budgetHeaderColorPolicy.dispose();
    _mindHeaderColorPolicy.dispose();
    _headerVisualController.dispose();
    _budgetPresentation.dispose();
    _budgetLimitEdit?.dispose();
    _preparedSceneCache.removeListener(_recordSceneCacheMetrics);
    _preparedSceneCache.dispose();
    _partnerSwipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _devicePixelRatio = View.of(context).devicePixelRatio;
    final logBoxRasters =
        widget.preparedLogBoxRasters ??
        PreparedVectorAssetAtlas.instance.logBoxRastersFor(
          View.of(context).devicePixelRatio,
        );
    final layoutMetrics = kIsWeb
        ? controller.metrics.forWebContentOrigin
        : controller.metrics;
    final contentTopPadding = kIsWeb ? 20.0 : 0.0;

    return DashboardMotionHost(
      controller: controller,
      modeController: modeController,
      layoutMetrics: layoutMetrics,
      bodyOrder: _bodyOrderController.value,
      hasPhysicalRail:
          _summaryPillVariantController.value == SummaryPillVariant.legacy,
      modeContentExtraHeight:
          modeController.committedMode == DashboardModeSpec.budget &&
              _budgetSectionOrderController.value ==
                  BudgetSectionOrder.chartThenAvatars
          ? BudgetSectionOrder.chartThenAvatarsExtraModeContentHeight
          : 0,
      builder: (context, frame) {
        final geometry = frame.geometry;
        _recordLayerStack(frame);
        _upperVerticalGestures.updateViewportMapper(
          geometry.mapViewportVerticalDragToController,
        );
        Widget profileRenderProbe({
          required Widget child,
          required DashboardPerformanceMetric layoutMetric,
          required DashboardPerformanceMetric paintMetric,
          required DashboardPerformanceMetric layoutDurationMetric,
          required DashboardPerformanceMetric paintDurationMetric,
        }) {
          if (controller.railFlightRecorder?.isEnabled != true) return child;
          return DashboardRenderPhaseProbe(
            counters: controller.performanceCounters,
            layoutMetric: layoutMetric,
            paintMetric: paintMetric,
            layoutDurationMetric: layoutDurationMetric,
            paintDurationMetric: paintDurationMetric,
            child: child,
          );
        }

        return DashboardLogBoxSearchPillScope(
          controller: _logBoxSearchPillController,
          child: BudgetRingPresentationScope(
            controller: _budgetRingPresentationController,
            child: DashboardBudgetHeaderPresentationScope(
              controller: _budgetHeaderPresentationController,
              child: DashboardLogBoxLayoutScope(
                controller: _logBoxHeightController,
                child: DashboardLogBoxAmountPaletteScope(
                  controller: _logBoxAmountPaletteController,
                  child: DashboardBorderScope(
                    controller: _borderController,
                    child: DashboardShadowStyleScope(
                      controller: _shadowStyleController,
                      child: DashboardCornerRoundnessScope(
                        controller: _cornerRoundnessController,
                        child: DashboardRenderPhaseProbe(
                          counters: controller.performanceCounters,
                          child: ColoredBox(
                            key: const ValueKey('core-dashboard'),
                            color: frame.palette.pageBackground,
                            child: Padding(
                              key: const ValueKey('dashboard-content-inset'),
                              padding: EdgeInsets.only(top: contentTopPadding),
                              child: SizedBox.expand(
                                child: Stack(
                                  fit: StackFit.expand,
                                  clipBehavior: Clip.none,
                                  children: [
                                    _FramePosition(
                                      bounds: geometry.brandLockupBounds,
                                      child: FluviBrandLockup(
                                        bounds: geometry.brandLockupBounds,
                                      ),
                                    ),
                                    DashboardCoreModeHost(
                                      controller: modeController,
                                      headerVisualController:
                                          _headerVisualController,
                                      balanceHeaderVisualFrame:
                                          _balanceHeaderColorPolicy,
                                      budgetHeaderVisualFrame:
                                          _budgetHeaderColorPolicy,
                                      mindHeaderVisualFrame:
                                          _mindHeaderColorPolicy,
                                      mindQueryAmountRange:
                                          _mindQueryAmountRange,
                                      mindQueryAmountRangeChanges:
                                          controller.currentQuery,
                                      onMindQueryAmountRangeCommitted:
                                          _commitMindQueryAmountRange,
                                      budgetPresentation: _budgetPresentation,
                                      budgetLimitEditController:
                                          _budgetLimitEdit,
                                      budgetDistributionDrawables:
                                          _budgetDistributionDrawables,
                                      budgetAvatarRailController:
                                          _budgetAvatarRailController,
                                      budgetDistributionPageController:
                                          _budgetDistributionPageController,
                                      budgetContentCardStyle:
                                          _budgetContentCardStyle,
                                      budgetSectionOrder:
                                          _budgetSectionOrderController,
                                      budgetRhythm: _budgetRhythm,
                                      budgetDrilldown: _budgetDrilldown,
                                      onBudgetAvatarDirectInputStarted:
                                          controller
                                              .noteBudgetAvatarDirectPointerDown,
                                      onBudgetAvatarMotionActiveChanged:
                                          (active) {
                                            if (active) {
                                              _cancelSummaryAutoReset();
                                              controller
                                                  .beginBudgetAvatarMotion();
                                            } else {
                                              controller
                                                  .endBudgetAvatarMotion();
                                            }
                                          },
                                      presentationFor: frame.presentationFor,
                                      onVerticalExpansionStart:
                                          _upperVerticalGestures.begin,
                                      onVerticalExpansionDragBy:
                                          _upperVerticalGestures.dragByViewport,
                                      onVerticalExpansionEnd:
                                          _upperVerticalGestures.end,
                                      upperVerticalGestures:
                                          _upperVerticalGestures,
                                    ),
                                    _FramePosition(
                                      bounds: geometry.actionBounds,
                                      child: Semantics(
                                        key: const ValueKey(
                                          'dashboard-action-row',
                                        ),
                                        label:
                                            frame.selectedDirection ==
                                                TransactionDirection.income
                                            ? 'Bevétel'
                                            : 'Kiadás',
                                        child: TransactionDirectionToggle(
                                          bounds: geometry.actionBounds,
                                          palette: frame.palette,
                                          selectedDirection:
                                              frame.selectedDirection,
                                          incomeIconScale:
                                              frame.incomeIconScale,
                                          expenseIconScale:
                                              frame.expenseIconScale,
                                          selectedIconScaleAnimation:
                                              frame.directionPulseScale,
                                          performanceCounters:
                                              controller.performanceCounters,
                                          onSelected: (direction) {
                                            _cancelSummaryAutoReset();
                                            controller.selectDirection(
                                              direction,
                                            );
                                          },
                                          onVerticalDragStart: (_) =>
                                              _upperVerticalGestures.begin(),
                                          onVerticalDragUpdate: (details) =>
                                              _upperVerticalGestures
                                                  .dragByViewport(
                                                    details.delta.dy,
                                                  ),
                                          onVerticalDragEnd: (_) =>
                                              _upperVerticalGestures.end(),
                                        ),
                                      ),
                                    ),
                                    _FramePosition(
                                      bounds: geometry.summaryBounds,
                                      child: _DashboardSummaryRegion(
                                        bounds: geometry.summaryBounds,
                                        controller: controller,
                                        summaryPillVariants:
                                            _summaryPillVariantController,
                                        summaryPresentation:
                                            _summaryPresentationController,
                                        motionController:
                                            _summaryMotionController,
                                        onMotionActiveChanged: (active) =>
                                            controller.setMotionLaneActive(
                                              DashboardMotionLane.summaryShell,
                                              active,
                                            ),
                                        onAmountMotionActiveChanged: (active) =>
                                            controller.setMotionLaneActive(
                                              DashboardMotionLane.amount,
                                              active,
                                            ),
                                        autoResetController:
                                            _summaryAutoResetController,
                                        autoResetMotions:
                                            _summaryAutoResetMotions,
                                        upperVerticalGestures:
                                            _upperVerticalGestures,
                                      ),
                                    ),
                                    _FramePosition(
                                      bounds: geometry.railBounds,
                                      child: ValueListenableBuilder<SummaryPillVariant>(
                                        valueListenable:
                                            _summaryPillVariantController,
                                        builder: (context, variant, _) {
                                          if (variant !=
                                              SummaryPillVariant.legacy) {
                                            // DAY remains the canonical month child query in
                                            // an experiment, but its legacy rail must not add
                                            // a second visible control surface.
                                            return const SizedBox.expand();
                                          }
                                          return Opacity(
                                            opacity: frame.railReveal,
                                            child: IgnorePointer(
                                              ignoring:
                                                  !geometry.isRailExpanded,
                                              child: profileRenderProbe(
                                                layoutMetric:
                                                    DashboardPerformanceMetric
                                                        .railLayout,
                                                paintMetric:
                                                    DashboardPerformanceMetric
                                                        .railPaint,
                                                layoutDurationMetric:
                                                    DashboardPerformanceMetric
                                                        .railLayoutMicros,
                                                paintDurationMetric:
                                                    DashboardPerformanceMetric
                                                        .railPaintMicros,
                                                child: TimeRefinementRail(
                                                  bounds: geometry.railBounds,
                                                  motion: controller.motion,
                                                  onPreviewLogicalIndexChanged:
                                                      (oldIndex, newIndex) =>
                                                          _summaryMotionController
                                                              .triggerRailTick(
                                                                oldLogicalIndex:
                                                                    oldIndex,
                                                                newLogicalIndex:
                                                                    newIndex,
                                                              ),
                                                  onMotionBaselineEstablished:
                                                      _summaryMotionController
                                                          .resetRailTickBaseline,
                                                  onMotionStarted: controller
                                                      .beginRailMotion,
                                                  performanceCounters:
                                                      controller
                                                          .performanceCounters,
                                                  motionDiagnostics: controller
                                                      .railFlightRecorder,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      left: geometry.logBoxHeaderBounds.left,
                                      top: geometry.logBoxHeaderBounds.top,
                                      width: geometry.logBoxHeaderBounds.width,
                                      bottom: 0,
                                      child: profileRenderProbe(
                                        layoutMetric: DashboardPerformanceMetric
                                            .logLayout,
                                        paintMetric:
                                            DashboardPerformanceMetric.logPaint,
                                        layoutDurationMetric:
                                            DashboardPerformanceMetric
                                                .logLayoutMicros,
                                        paintDurationMetric:
                                            DashboardPerformanceMetric
                                                .logPaintMicros,
                                        child: DashboardLogBoxViewport(
                                          bounds: geometry.logBoxHeaderBounds,
                                          visibleFrames:
                                              controller.visibleFrames,
                                          preparedRasters: logBoxRasters,
                                          committedViewport:
                                              controller.committedLogViewport,
                                          renderCriticalPayloads: controller
                                              .renderCriticalLogBoxPayloads,
                                          sceneWindowProvider: controller
                                              .renderCriticalLogBoxSceneWindow,
                                          preparedSceneCache:
                                              _preparedSceneCache,
                                          onLoadNextPage:
                                              (desiredLastReadyOrdinal) {
                                                unawaited(
                                                  controller
                                                      .requestForwardPageDemand(
                                                        desiredLastReadyOrdinal,
                                                      ),
                                                );
                                              },
                                          onLoadPreviousPage: () {
                                            unawaited(
                                              controller.loadPreviousPage(),
                                            );
                                          },
                                          onVerticalPointerDown: controller
                                              .noteVerticalPointerDown,
                                          onVerticalPointerIntentStarted: controller
                                              .noteVerticalPointerIntentStarted,
                                          onVerticalPointerIntentEnded: controller
                                              .noteVerticalPointerIntentEnded,
                                          onVerticalScrollStarted: controller
                                              .beginVerticalInteraction,
                                          onVerticalScrollEnded: controller
                                              .resumeSceneWindowMaintenanceAfterVerticalInput,
                                          verticalBackgroundWork: () =>
                                              controller.verticalBackgroundWork,
                                          performanceCounters:
                                              controller.performanceCounters,
                                          renderDiagnostics: controller
                                              .renderReadinessDiagnostics,
                                          renderDiagnosticContextProvider: () =>
                                              controller
                                                  .renderDiagnosticContext,
                                          onExtentPublished: controller
                                              .recordLogBoxRenderExtent,
                                          onCommittedScopeReset: controller
                                              .recordVerticalCommittedScopeReset,
                                          currentQuery: controller.currentQuery,
                                          onRemoveQueryCategory: controller
                                              .removeAppliedQueryCategory,
                                          onRemoveQueryPartner: controller
                                              .removeAppliedQueryPartner,
                                          onClearQuery:
                                              controller.clearAppliedQuery,
                                          focus: controller.focus,
                                          onClearFocusCategory: () {
                                            unawaited(
                                              controller.clearCategoryFocus(),
                                            );
                                          },
                                          onClearFocusPartner: () {
                                            unawaited(
                                              controller.clearPartnerFocus(),
                                            );
                                          },
                                          onClearFocusSearch: () {
                                            unawaited(
                                              controller.updateLiveSearch(''),
                                            );
                                          },
                                          onClearFocus: () {
                                            unawaited(
                                              controller
                                                  .clearAllEphemeralFocus(),
                                            );
                                          },
                                          onSearchChanged: (value) {
                                            unawaited(
                                              controller.updateLiveSearch(
                                                value,
                                              ),
                                            );
                                          },
                                          onAvatarTap: (row) {
                                            if (row.categoryId.isEmpty) return;
                                            unawaited(
                                              controller.requestCategoryFocus(
                                                DashboardFocusFacet(
                                                  id: row.categoryId,
                                                  displayName:
                                                      row.categoryDisplayName,
                                                  colorId: row.categoryColorId,
                                                  iconId: row.categoryIconId,
                                                ),
                                              ),
                                            );
                                          },
                                          partnerSwipe: _partnerSwipe,
                                          onPartnerFocus: (row) {
                                            if (row.partnerId.isEmpty) {
                                              return Future<bool>.value(false);
                                            }
                                            return controller
                                                .requestPartnerFocus(
                                                  DashboardFocusFacet(
                                                    id: row.partnerId,
                                                    displayName:
                                                        row.partnerDisplayName,
                                                    colorId:
                                                        row.categoryColorId,
                                                    iconId: row.categoryIconId,
                                                  ),
                                                );
                                          },
                                          onWarmupSurfaceAttached: widget
                                              .onLogBoxWarmupSurfaceAttached,
                                          onWarmupSurfaceLaidOut: widget
                                              .onLogBoxWarmupSurfaceLaidOut,
                                          onWarmupTextLayoutsPrepared: (viewportId) {
                                            controller
                                                .recordInitialSceneWindowActivation(
                                                  controller
                                                      .renderCriticalLogBoxSceneWindow(),
                                                );
                                            widget
                                                .onLogBoxWarmupTextLayoutsPrepared
                                                ?.call(viewportId);
                                          },
                                          onWarmupError:
                                              widget.onLogBoxWarmupError,
                                          onTextLayoutsPrepared: controller
                                              .recordLogBoxTextLayoutCache,
                                        ),
                                      ),
                                    ),
                                    _FramePosition(
                                      bounds: geometry.collapseHandleBounds,
                                      child: DashboardCollapseHandle(
                                        bounds: geometry.collapseHandleBounds,
                                        isDragging: frame.isExpansionDragging,
                                        onTap: controller.expansion.toggle,
                                        onVerticalDragStart: (_) =>
                                            _upperVerticalGestures.begin(),
                                        onVerticalDragUpdate: (details) =>
                                            _upperVerticalGestures
                                                .dragByViewport(
                                                  details.delta.dy,
                                                ),
                                        onVerticalDragEnd: (_) =>
                                            _upperVerticalGestures.end(),
                                      ),
                                    ),
                                    _DashboardHeaderVisualTunerOverlay(
                                      controller: _headerVisualController,
                                      summaryPillVariants:
                                          _summaryPillVariantController,
                                      bodyOrder: _bodyOrderController,
                                      budgetContentCardStyle:
                                          _budgetContentCardStyle,
                                      budgetSectionOrder:
                                          _budgetSectionOrderController,
                                      summaryPresentation:
                                          _summaryPresentationController,
                                      cornerRoundness:
                                          _cornerRoundnessController,
                                      shadowStyle: _shadowStyleController,
                                      border: _borderController,
                                      logBoxHeight: _logBoxHeightController,
                                      amountPalette:
                                          _logBoxAmountPaletteController,
                                      searchPillVisibility:
                                          _logBoxSearchPillController,
                                      budgetHeaderPresentation:
                                          _budgetHeaderPresentationController,
                                      budgetRingPresentation:
                                          _budgetRingPresentationController,
                                      shellPresentation:
                                          widget.shellPresentation,
                                      headerBounds: geometry.headerBounds,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Records the real production composition order at bounded collapse
  /// milestones. It deliberately identifies candidates and geometry only; it
  /// never paints a diagnostic layer or changes pixel ownership.
  void _recordLayerStack(DashboardVisualFrame frame) {
    final geometry = frame.geometry;
    final mode = modeController.committedMode;
    final pageController = _budgetDistributionPageController.pageController;
    final page = pageController.hasClients ? pageController.page : null;
    final lowerMotion = geometry.lowerCardMotion;
    final collapseMilestone =
        (geometry.collapseProgress / controller.metrics.collapseTravel * 20)
            .round();
    final pagerMilestone = page == null ? null : (page * 4).round();
    final signature = Object.hash(
      mode,
      collapseMilestone,
      _budgetContentCardStyle.value,
      _budgetSectionOrderController.value,
      pagerMilestone,
    );
    if (_lastLayerStackDiagnosticSignature == signature) return;
    _lastLayerStackDiagnosticSignature = signature;

    String bounds(DashboardBounds value) =>
        '${value.left.toStringAsFixed(1)},${value.top.toStringAsFixed(1)} '
        '${value.width.toStringAsFixed(1)}x${value.height.toStringAsFixed(1)}';

    final queryScope = controller.currentQuery.scope;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'HOME|LAYER_STACK',
        queryKey: queryScope.key.value,
        coreRevision: controller.visibleFrames.value?.coreRevision,
        direction: queryScope.direction.name,
        scope:
            'mode=${mode.mode.name} '
            'collapseProgress=${geometry.collapseProgress.toStringAsFixed(1)} '
            'collapseMilestone=$collapseMilestone '
            'budgetLayout=${_budgetContentCardStyle.value.name} '
            'budgetOrder=${_budgetSectionOrderController.value.name} '
            'zone2=${bounds(geometry.zone2Bounds)} '
            'modeContent=${bounds(geometry.modeContentBounds)} '
            'collapseHandle=${bounds(geometry.collapseHandleBounds)} '
            'logBoxHeader=${bounds(geometry.logBoxHeaderBounds)} '
            'lowerOpacity=${lowerMotion?.opacity.toStringAsFixed(3) ?? '-'} '
            'lowerScale=${lowerMotion?.scale.toStringAsFixed(3) ?? '-'} '
            'pagerPage=${page?.toStringAsFixed(3) ?? '-'} '
            'pagerMilestone=${pagerMilestone ?? '-'} '
            'pagerControllerIdentity=${identityHashCode(pageController)} '
            'physicalSurface=${mode == DashboardModeSpec.budget && _budgetContentCardStyle.value == BudgetContentLayout.unifiedCard ? 'BudgetUnifiedContentCard' : 'BudgetDistributionCardShell'} '
            'contentClip=BudgetDistributionCardShell.ClipRRect '
            'paintOrder=DashboardCoreModeHost<DashboardLogBoxViewport<DashboardCollapseHandle',
      ),
    );
  }

  QueryAmountRangeValues? _mindQueryAmountRange() {
    final direction =
        controller.presentation.navigation.state.parentQueryScope.direction;
    final scope = controller.currentQuery.scopeFor(direction);
    final domain = controller.currentQuery
        .facetPresentationFor(direction)
        ?.amountDomain;
    final binding = QueryAmountRangeBinding.ready(
      scope: scope,
      amountDomain: domain,
    );
    final values = binding?.values;
    final signature = Object.hash(
      modeController.committedMode,
      direction,
      scope.key,
      domain?.minimumAmountScaled100,
      domain?.maximumAmountScaled100,
      values,
    );
    if (_lastMindRangeDiagnosticSignature != signature) {
      _lastMindRangeDiagnosticSignature = signature;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|SLIDER_RENDER_GATE',
          queryKey: scope.key.value,
          direction: direction.name,
          coreRevision: controller.visibleFrames.value?.coreRevision,
          scope:
              'mode=${modeController.committedMode.mode.name} '
              'expectedMode=mind shouldRender=${values != null} '
              'amountDomain=${domain == null ? 'unavailable' : 'ready'} '
              'minimum=${domain?.minimumAmountScaled100 ?? '-'} '
              'maximum=${domain?.maximumAmountScaled100 ?? '-'} '
              'rangeLower=${values?.lowerScaled100 ?? '-'} '
              'rangeUpper=${values?.upperScaled100 ?? '-'} '
              'currentQueryGeneration=${controller.currentQuery.generationFor(direction)}',
        ),
      );
    }
    // Unknown is not the 1,000 HUF floor. Query Menu hides its control until
    // this exact canonical data owner is ready; Mind mirrors that explicit
    // state instead of manufacturing a collapsed disabled RangeSlider.
    return values;
  }

  void _commitMindQueryAmountRange(QueryAmountRangeValues values) {
    final direction =
        controller.presentation.navigation.state.parentQueryScope.direction;
    final current = controller.currentQuery.scopeFor(direction);
    final binding = QueryAmountRangeBinding.ready(
      scope: current,
      amountDomain: controller.currentQuery
          .facetPresentationFor(direction)
          ?.amountDomain,
    );
    if (binding == null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|SLIDER_COMMIT_REJECTED',
          queryKey: current.key.value,
          direction: direction.name,
          scope: 'reason=canonicalAmountDomainUnavailable',
        ),
      );
      return;
    }
    final next = binding.apply(values);
    if (next == current) return;
    unawaited(
      controller.applyQuery(next, facetPresentationSource: 'mindAmountRange'),
    );
  }

  void _onLayoutPresentationChanged() {
    if (mounted) setState(() {});
  }

  void _cancelSummaryAutoReset() {
    _summaryAutoResetController.cancel();
    _summaryAutoResetMotions.cancelActiveResetMotion();
  }
}

class _DashboardSummaryRegion extends StatelessWidget {
  const _DashboardSummaryRegion({
    required this.bounds,
    required this.controller,
    required this.summaryPillVariants,
    required this.summaryPresentation,
    required this.motionController,
    required this.onMotionActiveChanged,
    required this.onAmountMotionActiveChanged,
    required this.autoResetController,
    required this.autoResetMotions,
    required this.upperVerticalGestures,
  });

  final DashboardBounds bounds;
  final DashboardCoreController controller;
  final SummaryPillVariantController summaryPillVariants;
  final DashboardSummaryPresentationController summaryPresentation;
  final SummaryNavigationMotionController motionController;
  final ValueChanged<bool> onMotionActiveChanged;
  final ValueChanged<bool> onAmountMotionActiveChanged;
  final DashboardSummaryAutoResetController autoResetController;
  final DashboardSummaryAutoResetMotionRegistry autoResetMotions;
  final DashboardUpperVerticalGestureCoordinator upperVerticalGestures;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<SummaryPillVariant>(
        valueListenable: summaryPillVariants,
        builder: (context, variant, _) =>
            ValueListenableBuilder<DashboardSummaryPresentationSettings>(
              valueListenable: summaryPresentation,
              builder: (context, presentation, _) => switch (variant) {
                SummaryPillVariant.legacy => _legacyPill(),
                SummaryPillVariant.segmented => SummaryPillExperiment(
                  variant: variant,
                  bounds: bounds,
                  navigation: controller.navigation,
                  visibleFrames: controller.visibleFrames,
                  performanceCounters: controller.performanceCounters,
                  onAmountMotionActiveChanged: onAmountMotionActiveChanged,
                  presentation: presentation,
                  onSelectorMotionActiveChanged: (active) {
                    if (active) {
                      if (!autoResetMotions.isExecuting) {
                        autoResetController.cancel();
                      }
                      controller.beginSegmentedSummaryMotion();
                    } else {
                      controller.endSegmentedSummaryMotion();
                    }
                  },
                  onSelectorDirectInputStarted: () {
                    autoResetController.cancel();
                    autoResetMotions.cancelActiveResetMotion();
                  },
                  onBackgroundTap: () {
                    // A second background tap supersedes even a reset that
                    // is currently waiting for a selector to mount.
                    autoResetMotions.cancelActiveResetMotion();
                    final navigation = controller.navigation.state;
                    final plan = DashboardSummaryAutoResetPlan.resolve(
                      plane: navigation.plane,
                      isRailOpen: navigation.isRailOpen,
                      year: navigation.yearCursor,
                      month: navigation.monthCursor.month,
                      logicalToday: controller.logicalAsOfDate,
                    );
                    unawaited(
                      autoResetController.start(
                        plan: plan,
                        runStep: autoResetMotions.run,
                      ),
                    );
                  },
                  onBackgroundVerticalDragStart: (_) =>
                      upperVerticalGestures.begin(),
                  onBackgroundVerticalDragUpdate: (details) =>
                      upperVerticalGestures.dragByViewport(details.delta.dy),
                  onBackgroundVerticalDragEnd: (_) =>
                      upperVerticalGestures.end(),
                  autoResetMotionRegistry: autoResetMotions,
                  componentCandidateProjector:
                      ({
                        required base,
                        required plane,
                        required isRailOpen,
                        required component,
                        required offset,
                      }) => controller
                          .experimentalTemporalComponentOffsetCandidate(
                            plane: plane,
                            isRailOpen: isRailOpen,
                            component: component,
                            offset: offset,
                            base: base,
                          ),
                  onLevelCrossed: (plane, isRailOpen) =>
                      controller.navigateExperimentalTemporalSelection(
                        plane: plane,
                        isRailOpen: isRailOpen,
                      ),
                  onComponentCrossed: (candidate, component) =>
                      controller.navigateExperimentalTemporalComponentCandidate(
                        candidate: candidate,
                        component: component,
                      ),
                ),
              },
            ),
      );

  Widget _legacyPill() {
    return DashboardSummaryPill(
      bounds: bounds,
      navigation: controller.navigation,
      visibleFrames: controller.visibleFrames,
      navigationMotionController: motionController,
      onMotionActiveChanged: onMotionActiveChanged,
      onAmountMotionActiveChanged: onAmountMotionActiveChanged,
      onDirectInputStarted: controller.noteSummaryDirectPointerDown,
      horizontalCandidateBuilder: _horizontalCandidate,
      performanceCounters: controller.performanceCounters,
      onToggleRail: controller.toggleRail,
      onMoveFiner: () {
        controller.navigatePlane(finer: true);
      },
      onMoveBroader: () {
        controller.navigatePlane(finer: false);
      },
      onMovePrevious: () {
        unawaited(
          controller.navigateParent(
            DashboardTimeNavigationChangeDirection.backward,
          ),
        );
      },
      onMoveNext: () {
        unawaited(
          controller.navigateParent(
            DashboardTimeNavigationChangeDirection.forward,
          ),
        );
      },
    );
  }

  SummaryTextContent? _horizontalCandidate(
    SummaryTransitionDirection direction,
  ) {
    final preview = controller.previewParent(
      direction == SummaryTransitionDirection.forward
          ? DashboardTimeNavigationChangeDirection.forward
          : DashboardTimeNavigationChangeDirection.backward,
    );
    if (preview == null) return null;
    final presentation = SummaryNavigationProjector.project(preview);
    return SummaryTextContent(
      title: presentation.planeTitle,
      subtitle: presentation.subtitle,
    );
  }
}

class _FramePosition extends StatelessWidget {
  const _FramePosition({required this.bounds, required this.child});

  final DashboardBounds bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: child,
    );
  }
}

/// A bounded in-dashboard slide-up card. Its available rectangle starts only
/// below the live Header bottom, so the Dashboard expansion controller remains
/// the sole source of geometry and the tuner cannot cover the Header.
final class _DashboardHeaderVisualTunerOverlay extends StatelessWidget {
  const _DashboardHeaderVisualTunerOverlay({
    required this.controller,
    required this.summaryPillVariants,
    required this.bodyOrder,
    required this.budgetContentCardStyle,
    required this.budgetSectionOrder,
    required this.summaryPresentation,
    required this.cornerRoundness,
    required this.shadowStyle,
    required this.border,
    required this.logBoxHeight,
    required this.amountPalette,
    required this.searchPillVisibility,
    required this.budgetHeaderPresentation,
    required this.budgetRingPresentation,
    this.shellPresentation,
    required this.headerBounds,
  });

  final DashboardHeaderVisualController controller;
  final SummaryPillVariantController summaryPillVariants;
  final DashboardBodyOrderController bodyOrder;
  final BudgetContentCardStyleController budgetContentCardStyle;
  final BudgetSectionOrderController budgetSectionOrder;
  final DashboardSummaryPresentationController summaryPresentation;
  final DashboardCornerRoundnessController cornerRoundness;
  final DashboardShadowStyleController shadowStyle;
  final DashboardBorderController border;
  final DashboardLogBoxHeightController logBoxHeight;
  final DashboardLogBoxAmountPaletteController amountPalette;
  final DashboardLogBoxSearchPillController searchPillVisibility;
  final DashboardBudgetHeaderPresentationController budgetHeaderPresentation;
  final BudgetRingPresentationController budgetRingPresentation;
  final DashboardShellPresentationController? shellPresentation;
  final DashboardBounds headerBounds;

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final viewportHeight = view.physicalSize.height / view.devicePixelRatio;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      // The mode host intentionally lays out its complete dashboard body,
      // which can be taller than the physical screen. The tuner is a viewport
      // overlay, so it uses the FlutterView instead of that scene height.
      height: viewportHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          final reducedMotion = MediaQuery.disableAnimationsOf(context);
          final placement = DashboardHeaderVisualTunerPlacement.resolve(
            headerBottom: headerBounds.bottom,
            viewportHeight: constraints.maxHeight,
            safeBottom: safeBottom,
          );
          return ValueListenableBuilder<bool>(
            valueListenable: controller.tunerOpen,
            builder: (context, isOpen, child) => Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                placement.top,
                12,
                safeBottom + 12,
              ),
              child: IgnorePointer(
                key: const ValueKey<String>(
                  'dashboard-header-visual-tuner-input',
                ),
                ignoring: !isOpen,
                child: AnimatedSlide(
                  offset: isOpen ? Offset.zero : const Offset(0, 1),
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isOpen ? 1 : 0,
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: math.min(640, placement.maxHeight),
                        child: DashboardHeaderVisualTuner(
                          controller: controller,
                          summaryPillVariants: summaryPillVariants,
                          bodyOrder: bodyOrder,
                          budgetContentCardStyle: budgetContentCardStyle,
                          budgetSectionOrder: budgetSectionOrder,
                          summaryPresentation: summaryPresentation,
                          cornerRoundness: cornerRoundness,
                          shadowStyle: shadowStyle,
                          border: border,
                          logBoxHeight: logBoxHeight,
                          amountPalette: amountPalette,
                          searchPillVisibility: searchPillVisibility,
                          budgetHeaderPresentation: budgetHeaderPresentation,
                          budgetRingPresentation: budgetRingPresentation,
                          shellPresentation: shellPresentation,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

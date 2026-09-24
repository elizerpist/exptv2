import 'package:flutter/foundation.dart' show Listenable, ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_balance_presentation.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_spending_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../application/dashboard_core_mode_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../mind/domain/mind_year_heatmap_projection.dart';
import '../../mind/domain/mind_temporal_heatmap_frame.dart';
import '../../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../../mind/domain/mind_behavioral_score_projection.dart';
import '../../mind/domain/mind_header_score_chart_presentation.dart';
import '../../mind/presentation/mind_header_score_chart.dart';
import '../../query/domain/query_amount_range.dart';
import '../../query/application/dashboard_applied_query_facet_loader.dart';
import '../../query/presentation/query_amount_range_control.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_dashboard_core_surface.dart';
import 'balance_header_history_chart.dart';
import 'balance_presentation_settings.dart';
import 'budget_dashboard_core_surface.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
import 'budget_target_avatar_rail_controller.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';
import 'dashboard_header_visual_tuner.dart';
import 'mind_dashboard_core_surface.dart';
import '../budget_content_card_style.dart';
import '../budget_section_order.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';

typedef DashboardCoreModePresentationLookup =
    DashboardCoreModePresentation Function(DashboardModeSpec mode);

/// The one-root presentation boundary for the committed dashboard core mode.
///
/// Its header keeps the existing vertical expansion lane. Mode switching is a
/// stationary, atomic replacement commanded only by the explicit Header icon;
/// Header horizontal drags are intentionally not a navigation affordance.
class DashboardCoreModeHost extends StatefulWidget {
  const DashboardCoreModeHost({
    super.key,
    required this.controller,
    required this.presentationFor,
    this.balancePresentation,
    this.balanceLinkedPresentation,
    this.balancePresentationSettings,
    this.balanceAdaptiveScope = const AllTimeScope(),
    this.budgetPresentation,
    this.budgetLimitEditController,
    this.budgetDistributionDrawables,
    this.budgetAvatarRailController,
    this.budgetDistributionPageController,
    this.budgetContentCardStyle,
    this.budgetSectionOrder,
    this.budgetRhythm,
    this.budgetDrilldown,
    this.performanceCounters,
    this.onBudgetAvatarDirectInputStarted,
    this.onBudgetAvatarMotionActiveChanged,
    this.headerVisualController,
    this.balanceHeaderVisualFrame,
    this.budgetHeaderVisualFrame,
    this.mindHeaderVisualFrame,
    this.mindBehavioralScore,
    this.mindHeaderScoreChartPresentation,
    this.mindQueryAmountRange,
    this.mindQueryAmountRangeChanges,
    this.mindQueryAmountRangeLifecycleChanges,
    this.mindQueryAmountRangeState,
    this.mindQueryAmountRangeError,
    this.mindYearHeatmap,
    this.mindTemporalHeatmap,
    this.mindTemporalHeatmapPlane,
    this.mindYearHeatmapPresentation,
    this.mindYearHeatmapVisible = false,
    this.mindTemporalHeatmapVisible = false,
    this.mindTemporalDayVisible = false,
    this.onMindQueryAmountRangeRetry,
    this.onMindQueryAmountRangeCommitted,
    this.onMindQueryAmountRangePreviewChanged,
    this.onMindQueryAmountRangeInteractionStarted,
    this.onMindQueryAmountRangeInteractionEnded,
    this.onMindQueryAmountRangeInteractionSummary,
    this.onMindTemporalEntryFrameStage,
    required this.onVerticalExpansionStart,
    required this.onVerticalExpansionDragBy,
    required this.onVerticalExpansionEnd,
    this.upperVerticalGestures,
  });

  final DashboardCoreModeController controller;
  final DashboardCoreModePresentationLookup presentationFor;
  final ValueListenable<DashboardBalancePresentation?>? balancePresentation;
  final ValueListenable<DashboardBalanceLinkedPresentation?>?
  balanceLinkedPresentation;
  final ValueListenable<BalancePresentationSettings>?
  balancePresentationSettings;
  final LedgerTimeScope balanceAdaptiveScope;
  final DashboardBudgetPresentationController? budgetPresentation;
  final DashboardBudgetLimitEditController? budgetLimitEditController;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>?
  budgetDistributionDrawables;
  final BudgetTargetAvatarRailController? budgetAvatarRailController;
  final BudgetDistributionPageController? budgetDistributionPageController;
  final ValueListenable<BudgetContentLayout>? budgetContentCardStyle;
  final ValueListenable<BudgetSectionOrder>? budgetSectionOrder;
  final ValueListenable<DashboardSpendingRhythmState?>? budgetRhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? budgetDrilldown;
  final DashboardPerformanceCounters? performanceCounters;
  final VoidCallback? onBudgetAvatarDirectInputStarted;
  final ValueChanged<bool>? onBudgetAvatarMotionActiveChanged;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? balanceHeaderVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? budgetHeaderVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? mindHeaderVisualFrame;
  final ValueListenable<MindBehavioralScoreFrame?>? mindBehavioralScore;
  final ValueListenable<MindHeaderScoreChartPresentationSettings>?
  mindHeaderScoreChartPresentation;
  final QueryAmountRangeValues? Function()? mindQueryAmountRange;
  final Listenable? mindQueryAmountRangeChanges;
  final Listenable? mindQueryAmountRangeLifecycleChanges;
  final DashboardAppliedQueryFacetLoadState Function()?
  mindQueryAmountRangeState;
  final Object? Function()? mindQueryAmountRangeError;
  final ValueListenable<MindYearHeatmapFrame?>? mindYearHeatmap;
  final ValueListenable<MindTemporalHeatmapFrame?>? mindTemporalHeatmap;
  final TimePlane? mindTemporalHeatmapPlane;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  mindYearHeatmapPresentation;
  final bool mindYearHeatmapVisible;
  final bool mindTemporalHeatmapVisible;
  final bool mindTemporalDayVisible;
  final VoidCallback? onMindQueryAmountRangeRetry;
  final ValueChanged<QueryAmountRangeValues>? onMindQueryAmountRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>?
  onMindQueryAmountRangePreviewChanged;
  final VoidCallback? onMindQueryAmountRangeInteractionStarted;
  final VoidCallback? onMindQueryAmountRangeInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>?
  onMindQueryAmountRangeInteractionSummary;
  final MindTemporalEntryFrameStageReporter? onMindTemporalEntryFrameStage;
  final VoidCallback onVerticalExpansionStart;
  final ValueChanged<double> onVerticalExpansionDragBy;
  final VoidCallback onVerticalExpansionEnd;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<DashboardCoreModeHost> createState() => _DashboardCoreModeHostState();
}

class _DashboardCoreModeHostState extends State<DashboardCoreModeHost> {
  final MindHeaderScoreChartPointerObserver _mindHeaderScoreChartPointers =
      MindHeaderScoreChartPointerObserver();
  final BalanceHeaderHistoryChartPointerObserver
  _balanceHeaderHistoryChartPointers =
      BalanceHeaderHistoryChartPointerObserver();
  bool _verticalExpansionStarted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onModeChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardCoreModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onModeChanged);
      widget.controller.addListener(_onModeChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  void _beginVerticalSequence() {
    _verticalExpansionStarted = false;
  }

  void _applyVerticalDelta(double delta) {
    if (delta == 0) return;
    if (!_verticalExpansionStarted) {
      _verticalExpansionStarted = true;
      widget.onVerticalExpansionStart();
    }
    widget.onVerticalExpansionDragBy(delta);
  }

  void _onHeaderVerticalStart(DragStartDetails _) => _beginVerticalSequence();

  void _onHeaderVerticalUpdate(DragUpdateDetails details) =>
      _applyVerticalDelta(details.delta.dy);

  void _onHeaderVerticalEnd(DragEndDetails _) => _finishPointerSequence();

  void _switchModeFromHeaderIcon() {
    widget.controller.switchMode(DashboardCoreModeDirection.forward);
  }

  /// Content cards are an extension of Header vertical expansion, never a
  /// mode-switch surface. Keeping this separate from the Header's pan path
  /// keeps horizontal card motion outside both navigation and expansion.
  void _onContentVerticalStart(DragStartDetails details) {
    _beginVerticalSequence();
  }

  void _onContentVerticalUpdate(DragUpdateDetails details) {
    _applyVerticalDelta(details.delta.dy);
  }

  void _onContentVerticalEnd(DragEndDetails _) => _finishPointerSequence();

  void _finishPointerSequence() {
    if (_verticalExpansionStarted) {
      widget.onVerticalExpansionEnd();
    }
    _verticalExpansionStarted = false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.controller.committedMode;
    final presentation = widget.presentationFor(mode);
    final headerBounds = presentation.geometry.headerBounds;
    final brandBounds = presentation.geometry.brandLockupBounds;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The mode surface itself must own a real full-sized hit-test parent.
        // A non-positioned wrapper can shrink to the visual Stack's zero-size
        // layout child even while its positioned cards paint below it, which
        // was the physical reason Card2 drags were insensitive.
        const SizedBox.expand(),
        Positioned.fill(
          // Mind owns an invariant surface around its shared fixed footer.
          // Its Day-only expansion gesture is placed inside that surface, so
          // Sum/Year/Month retain exclusive viewport ownership without
          // reparenting a held RangeSlider across TimePlane changes.
          child: mode.mode == DashboardMode.mind
              ? _buildModeSurface(mode, presentation)
              : GestureDetector(
                  key: const ValueKey(
                    'dashboard-core-mode-content-gesture-region',
                  ),
                  behavior: HitTestBehavior.translucent,
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: _onContentVerticalStart,
                  onVerticalDragUpdate: _onContentVerticalUpdate,
                  onVerticalDragEnd: _onContentVerticalEnd,
                  onVerticalDragCancel: _finishPointerSequence,
                  child: _buildModeSurface(mode, presentation),
                ),
        ),
        Positioned(
          left: headerBounds.left,
          top: headerBounds.top,
          width: headerBounds.width,
          height: headerBounds.height,
          child: DashboardHeaderTapWaveGestureLayer(
            controller: widget.headerVisualController,
            onPointerDown: switch (mode.mode) {
              DashboardMode.mind =>
                _mindHeaderScoreChartPointers.observePointerDown,
              DashboardMode.balance =>
                _balanceHeaderHistoryChartPointers.observePointerDown,
              DashboardMode.budget => null,
            },
            onPointerMove: switch (mode.mode) {
              DashboardMode.mind =>
                _mindHeaderScoreChartPointers.observePointerMove,
              DashboardMode.balance =>
                _balanceHeaderHistoryChartPointers.observePointerMove,
              DashboardMode.budget => null,
            },
            onPointerUp: switch (mode.mode) {
              DashboardMode.mind =>
                _mindHeaderScoreChartPointers.observePointerUp,
              DashboardMode.balance =>
                _balanceHeaderHistoryChartPointers.observePointerUp,
              DashboardMode.budget => null,
            },
            onPointerCancel: switch (mode.mode) {
              DashboardMode.mind =>
                _mindHeaderScoreChartPointers.observePointerCancel,
              DashboardMode.balance =>
                _balanceHeaderHistoryChartPointers.observePointerCancel,
              DashboardMode.budget => null,
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GestureDetector(
                  key: const ValueKey(
                    'dashboard-core-mode-header-gesture-region',
                  ),
                  behavior: HitTestBehavior.translucent,
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: _onHeaderVerticalStart,
                  onVerticalDragUpdate: _onHeaderVerticalUpdate,
                  onVerticalDragEnd: _onHeaderVerticalEnd,
                  onVerticalDragCancel: _finishPointerSequence,
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: _modeHeaderIcon(mode.mode),
                ),
              ],
            ),
          ),
        ),
        if (widget.headerVisualController case final controller?)
          Positioned(
            left: headerBounds.right - 50,
            top: brandBounds.top + (brandBounds.height - 42) / 2,
            width: 42,
            height: 42,
            child: DashboardHeaderVisualTunerButton(controller: controller),
          ),
      ],
    );
  }

  Widget _modeHeaderIcon(DashboardMode mode) {
    final frames = switch (mode) {
      DashboardMode.balance => widget.balanceHeaderVisualFrame,
      DashboardMode.budget => widget.budgetHeaderVisualFrame,
      DashboardMode.mind => widget.mindHeaderVisualFrame,
    };
    if (frames == null) {
      return DashboardHeaderModeIconButton(
        mode: mode,
        onPressed: _switchModeFromHeaderIcon,
      );
    }
    return ValueListenableBuilder<DashboardHeaderVisualFrame>(
      valueListenable: frames,
      builder: (context, frame, _) => DashboardHeaderModeIconButton(
        mode: mode,
        color: frame.headerIconColor,
        onPressed: _switchModeFromHeaderIcon,
      ),
    );
  }

  Widget _buildModeSurface(
    DashboardModeSpec mode,
    DashboardCoreModePresentation presentation,
  ) {
    return switch (mode.mode) {
      DashboardMode.balance => BalanceDashboardCoreSurface(
        presentation: presentation,
        balancePresentation: widget.balancePresentation,
        balanceLinkedPresentation: widget.balanceLinkedPresentation,
        presentationSettings: widget.balancePresentationSettings,
        adaptiveScope: widget.balanceAdaptiveScope,
        headerHistoryChartPointerObserver: _balanceHeaderHistoryChartPointers,
        headerVisualController: widget.headerVisualController,
        headerVisualFrame: widget.balanceHeaderVisualFrame,
      ),
      DashboardMode.budget => BudgetDashboardCoreSurface(
        presentation: presentation,
        presentationController: widget.budgetPresentation,
        limitEditController: widget.budgetLimitEditController,
        distributionDrawables: widget.budgetDistributionDrawables,
        avatarRailController: widget.budgetAvatarRailController,
        distributionPageController: widget.budgetDistributionPageController,
        contentCardStyle: widget.budgetContentCardStyle,
        sectionOrder: widget.budgetSectionOrder,
        rhythm: widget.budgetRhythm,
        drilldown: widget.budgetDrilldown,
        performanceCounters: widget.performanceCounters,
        onAvatarDirectInputStarted: widget.onBudgetAvatarDirectInputStarted,
        onAvatarMotionActiveChanged: widget.onBudgetAvatarMotionActiveChanged,
        upperVerticalGestures: widget.upperVerticalGestures,
        headerVisualController: widget.headerVisualController,
        headerVisualFrame: widget.budgetHeaderVisualFrame,
      ),
      DashboardMode.mind => MindDashboardCoreSurface(
        presentation: presentation,
        queryAmountRange: widget.mindQueryAmountRange,
        queryAmountRangeChanges: widget.mindQueryAmountRangeChanges,
        queryAmountRangeLifecycleChanges:
            widget.mindQueryAmountRangeLifecycleChanges,
        queryAmountRangeState: widget.mindQueryAmountRangeState,
        queryAmountRangeError: widget.mindQueryAmountRangeError,
        yearHeatmap: widget.mindYearHeatmap,
        temporalHeatmap: widget.mindTemporalHeatmap,
        temporalPlane: widget.mindTemporalHeatmapPlane,
        yearHeatmapPresentation: widget.mindYearHeatmapPresentation,
        showYearHeatmap: widget.mindYearHeatmapVisible,
        showTemporalHeatmap: widget.mindTemporalHeatmapVisible,
        showTemporalDayHeatmap: widget.mindTemporalDayVisible,
        onQueryAmountRangeRetry: widget.onMindQueryAmountRangeRetry,
        onQueryAmountRangeCommitted: widget.onMindQueryAmountRangeCommitted,
        onQueryAmountRangePreviewChanged:
            widget.onMindQueryAmountRangePreviewChanged,
        onQueryAmountRangeInteractionStarted:
            widget.onMindQueryAmountRangeInteractionStarted,
        onQueryAmountRangeInteractionEnded:
            widget.onMindQueryAmountRangeInteractionEnded,
        onQueryAmountRangeInteractionSummary:
            widget.onMindQueryAmountRangeInteractionSummary,
        onContentVerticalDragStart: _onContentVerticalStart,
        onContentVerticalDragUpdate: _onContentVerticalUpdate,
        onContentVerticalDragEnd: _onContentVerticalEnd,
        onContentVerticalDragCancel: _finishPointerSequence,
        upperVerticalGestures: widget.upperVerticalGestures,
        headerVisualController: widget.headerVisualController,
        headerVisualFrame: widget.mindHeaderVisualFrame,
        behavioralScore: widget.mindBehavioralScore,
        headerScoreChartPresentation: widget.mindHeaderScoreChartPresentation,
        headerScoreChartPointerObserver: _mindHeaderScoreChartPointers,
        onTemporalEntryFrameStage: widget.onMindTemporalEntryFrameStage,
      ),
    };
  }
}

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/gesture_direction_arbiter.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_budget_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../application/dashboard_core_mode_controller.dart';
import '../../application/dashboard_mode_spec.dart';
import 'balance_dashboard_core_surface.dart';
import 'budget_dashboard_core_surface.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
import 'budget_target_avatar_rail_controller.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_header_visual_engine.dart';
import 'dashboard_header_visual_tuner.dart';
import 'mind_dashboard_core_surface.dart';
import '../budget_content_card_style.dart';

typedef DashboardCoreModePresentationLookup =
    DashboardCoreModePresentation Function(DashboardModeSpec mode);

/// The one-root presentation boundary for the committed dashboard core mode.
///
/// Its header arbitrates one pointer sequence between the existing vertical
/// expansion lane and one immediate horizontal mode command. It deliberately
/// has neither progress nor a target surface: mode switching is a stationary,
/// atomic replacement rather than a visual transition.
class DashboardCoreModeHost extends StatefulWidget {
  const DashboardCoreModeHost({
    super.key,
    required this.controller,
    required this.presentationFor,
    this.budgetPresentation,
    this.budgetLimitEditController,
    this.budgetDistributionDrawables,
    this.budgetAvatarRailController,
    this.budgetDistributionPageController,
    this.budgetContentCardStyle,
    this.budgetRhythm,
    this.budgetDrilldown,
    this.onBudgetAvatarMotionActiveChanged,
    this.headerVisualController,
    this.balanceHeaderVisualFrame,
    this.budgetHeaderVisualFrame,
    this.mindHeaderVisualFrame,
    required this.onVerticalExpansionStart,
    required this.onVerticalExpansionDragBy,
    required this.onVerticalExpansionEnd,
  });

  final DashboardCoreModeController controller;
  final DashboardCoreModePresentationLookup presentationFor;
  final DashboardBudgetPresentationController? budgetPresentation;
  final DashboardBudgetLimitEditController? budgetLimitEditController;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>?
  budgetDistributionDrawables;
  final BudgetTargetAvatarRailController? budgetAvatarRailController;
  final BudgetDistributionPageController? budgetDistributionPageController;
  final ValueListenable<BudgetContentLayout>? budgetContentCardStyle;
  final ValueListenable<DashboardBudgetRhythmState?>? budgetRhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? budgetDrilldown;
  final ValueChanged<bool>? onBudgetAvatarMotionActiveChanged;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? balanceHeaderVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? budgetHeaderVisualFrame;
  final ValueListenable<DashboardHeaderVisualFrame>? mindHeaderVisualFrame;
  final VoidCallback onVerticalExpansionStart;
  final ValueChanged<double> onVerticalExpansionDragBy;
  final VoidCallback onVerticalExpansionEnd;

  @override
  State<DashboardCoreModeHost> createState() => _DashboardCoreModeHostState();
}

class _DashboardCoreModeHostState extends State<DashboardCoreModeHost> {
  GestureDirectionIntent? _pointerAxis;
  Offset? _pointerOrigin;
  double _appliedVerticalDisplacement = 0;
  bool _verticalExpansionStarted = false;
  bool _horizontalModeSwitched = false;

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

  void _onPanStart(DragStartDetails details) {
    _pointerAxis = null;
    _pointerOrigin = details.globalPosition;
    _appliedVerticalDisplacement = 0;
    _verticalExpansionStarted = false;
    _horizontalModeSwitched = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final origin = _pointerOrigin;
    if (origin == null) return;
    final displacement = details.globalPosition - origin;
    final axis =
        _pointerAxis ??
        GestureDirectionArbiter.resolve(
          dx: displacement.dx,
          dy: displacement.dy,
          touchSlop: kTouchSlop,
        );
    if (axis == null) return;
    _pointerAxis ??= axis;

    switch (_pointerAxis!) {
      case GestureDirectionIntent.vertical:
        _applyVerticalDisplacement(displacement.dy);
      case GestureDirectionIntent.horizontal:
        _switchHorizontalModeOnce(displacement.dx);
    }
  }

  void _applyVerticalDisplacement(double displacement) {
    if (!_verticalExpansionStarted) {
      _verticalExpansionStarted = true;
      widget.onVerticalExpansionStart();
    }
    final delta = displacement - _appliedVerticalDisplacement;
    _appliedVerticalDisplacement = displacement;
    widget.onVerticalExpansionDragBy(delta);
  }

  void _switchHorizontalModeOnce(double displacement) {
    if (_horizontalModeSwitched) return;
    _horizontalModeSwitched = true;
    widget.controller.switchMode(
      displacement < 0
          ? DashboardCoreModeDirection.forward
          : DashboardCoreModeDirection.backward,
    );
  }

  void _onPanEnd(DragEndDetails _) => _finishPointerSequence();

  void _onPanCancel() => _finishPointerSequence();

  void _finishPointerSequence() {
    if (_pointerAxis == GestureDirectionIntent.vertical &&
        _verticalExpansionStarted) {
      widget.onVerticalExpansionEnd();
    }
    _pointerAxis = null;
    _pointerOrigin = null;
    _appliedVerticalDisplacement = 0;
    _verticalExpansionStarted = false;
    _horizontalModeSwitched = false;
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.controller.committedMode;
    final presentation = widget.presentationFor(mode);
    final headerBounds = presentation.geometry.headerBounds;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildModeSurface(mode, presentation),
        Positioned(
          left: headerBounds.left,
          top: headerBounds.top,
          width: headerBounds.width,
          height: headerBounds.height,
          child: DashboardHeaderTapWaveGestureLayer(
            controller: widget.headerVisualController,
            child: GestureDetector(
              key: const ValueKey('dashboard-core-mode-header-gesture-region'),
              behavior: HitTestBehavior.translucent,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
            ),
          ),
        ),
        if (widget.headerVisualController case final controller?)
          Positioned(
            left: headerBounds.right - 50,
            top: headerBounds.top + 8,
            width: 42,
            height: 42,
            child: DashboardHeaderVisualTunerButton(controller: controller),
          ),
      ],
    );
  }

  Widget _buildModeSurface(
    DashboardModeSpec mode,
    DashboardCoreModePresentation presentation,
  ) {
    return switch (mode.mode) {
      DashboardMode.balance => BalanceDashboardCoreSurface(
        presentation: presentation,
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
        rhythm: widget.budgetRhythm,
        drilldown: widget.budgetDrilldown,
        onAvatarMotionActiveChanged: widget.onBudgetAvatarMotionActiveChanged,
        headerVisualController: widget.headerVisualController,
        headerVisualFrame: widget.budgetHeaderVisualFrame,
      ),
      DashboardMode.mind => MindDashboardCoreSurface(
        presentation: presentation,
        headerVisualController: widget.headerVisualController,
        headerVisualFrame: widget.mindHeaderVisualFrame,
      ),
    };
  }
}

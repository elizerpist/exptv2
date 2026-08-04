import 'package:flutter/material.dart';

import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/application/dashboard_performance_counters.dart';
import '../../features/dashboard/application/transaction_direction_controller.dart';
import '../design/dashboard_geometry_resolver.dart';
import '../design/dashboard_layout_frame.dart';
import '../design/dashboard_layout_metrics.dart';
import '../design/dashboard_mode_palette.dart';

/// Immutable visual state supplied by the motion owner to dashboard rendering.
@immutable
class DashboardVisualFrame {
  const DashboardVisualFrame({
    required this.geometry,
    required this.palette,
    required this.railReveal,
    required this.selectedDirection,
    required this.directionPulseScale,
    required this.isExpansionDragging,
  });

  final DashboardLayoutFrame geometry;
  final DashboardModePalette palette;
  final double railReveal;
  final TransactionDirection selectedDirection;
  final Animation<double> directionPulseScale;
  final bool isExpansionDragging;

  double get incomeIconScale => selectedDirection == TransactionDirection.income
      ? directionPulseScale.value
      : DashboardMotionTokens.restingScale;

  double get expenseIconScale =>
      selectedDirection == TransactionDirection.expense
      ? directionPulseScale.value
      : DashboardMotionTokens.restingScale;
}

typedef DashboardVisualFrameBuilder =
    Widget Function(BuildContext context, DashboardVisualFrame frame);

/// The dashboard's only Flutter ticker owner.
///
/// It observes only structural expansion, rail and direction signals, derives
/// geometry centrally, and supplies presentation-only state to input-only
/// leaves. Query, cache and LogBox notifications never enter this rebuild
/// boundary.
class DashboardMotionHost extends StatefulWidget {
  const DashboardMotionHost({
    super.key,
    required this.controller,
    required this.mode,
    required this.builder,
    this.layoutMetrics,
    DashboardModePaletteLookup? paletteResolver,
  }) : paletteResolver =
           paletteResolver ?? DashboardModePaletteResolver.resolve;

  final DashboardCoreController controller;
  final DashboardModeSpec mode;
  final DashboardVisualFrameBuilder builder;
  final DashboardLayoutMetrics? layoutMetrics;
  final DashboardModePaletteLookup paletteResolver;

  @override
  State<DashboardMotionHost> createState() => _DashboardMotionHostState();
}

class _DashboardMotionHostState extends State<DashboardMotionHost>
    with TickerProviderStateMixin {
  late final AnimationController _collapseController;
  late final AnimationController _railController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Listenable _structuralMotion;
  late (Object, Object, bool, int) _railStructure;
  late int _pulseRevision;
  late DashboardModePalette _palette;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _palette = widget.paletteResolver(widget.mode);
    _collapseController = AnimationController.unbounded(
      vsync: this,
      value: widget.controller.expansion.progress,
    );
    _railController = AnimationController(
      vsync: this,
      duration: DashboardMotionTokens.railDuration,
      value: widget.controller.rail.isExpanded
          ? DashboardMotionTokens.shownReveal
          : DashboardMotionTokens.hiddenReveal,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: DashboardMotionTokens.pulseDuration,
      value: DashboardMotionTokens.restingScale,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: DashboardMotionTokens.pulseStartScale,
          end: DashboardMotionTokens.pulsePeakScale,
        ),
        weight: DashboardMotionTokens.pulseRiseWeight,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: DashboardMotionTokens.pulsePeakScale,
          end: DashboardMotionTokens.pulseSettleScale,
        ),
        weight: DashboardMotionTokens.pulseSettleWeight,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: DashboardMotionTokens.pulseSettleScale,
          end: DashboardMotionTokens.restingScale,
        ),
        weight: DashboardMotionTokens.pulseRestWeight,
      ),
    ]).animate(_pulseController);
    _structuralMotion = Listenable.merge([
      _collapseController,
      _railController,
    ]);
    _pulseRevision = widget.controller.transactionDirection.pulseRevision;
    _railStructure = _readRailStructure();
    _attachController(widget.controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextDisableAnimations = MediaQuery.disableAnimationsOf(context);
    if (nextDisableAnimations == _disableAnimations) return;
    _disableAnimations = nextDisableAnimations;
    _synchronizeVisualState();
  }

  @override
  void didUpdateWidget(covariant DashboardMotionHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.mode, widget.mode) ||
        !identical(oldWidget.paletteResolver, widget.paletteResolver)) {
      _palette = widget.paletteResolver(widget.mode);
    }
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);
      _resetVisualStateForReplacementController();
    }
  }

  void _attachController(DashboardCoreController controller) {
    controller.expansion.addListener(_onExpansionChanged);
    controller.rail.addListener(_onRailChanged);
    controller.transactionDirection.addListener(_onDirectionChanged);
  }

  void _detachController(DashboardCoreController controller) {
    controller.expansion.removeListener(_onExpansionChanged);
    controller.rail.removeListener(_onRailChanged);
    controller.transactionDirection.removeListener(_onDirectionChanged);
  }

  void _onExpansionChanged() {
    _synchronizeVisualState();
    if (mounted) setState(() {});
  }

  void _onRailChanged() {
    final next = _readRailStructure();
    if (next == _railStructure) return;
    _railStructure = next;
    _synchronizeVisualState();
    if (mounted) setState(() {});
  }

  void _onDirectionChanged() {
    _synchronizeVisualState();
    if (mounted) setState(() {});
  }

  (Object, Object, bool, int) _readRailStructure() {
    final state = widget.controller.rail.state;
    return (state.plane, state.parentScope, state.isRailOpen, state.deckEpoch);
  }

  void _synchronizeVisualState() {
    final targetProgress = widget.controller.expansion.progress;
    final targetRailReveal = widget.controller.rail.isExpanded
        ? DashboardMotionTokens.shownReveal
        : DashboardMotionTokens.hiddenReveal;
    final pulseRevision = widget.controller.transactionDirection.pulseRevision;

    if (_disableAnimations) {
      _collapseController
        ..stop()
        ..value = targetProgress;
      _railController
        ..stop()
        ..value = targetRailReveal;
      _pulseController
        ..stop()
        ..value = DashboardMotionTokens.restingScale;
      _pulseRevision = pulseRevision;
      return;
    }

    if (widget.controller.expansion.isDragging) {
      _collapseController.value = targetProgress;
    } else {
      _collapseController.animateTo(
        targetProgress,
        duration: DashboardMotionTokens.collapseDuration,
        curve: DashboardMotionTokens.transitionCurve,
      );
    }
    _railController.animateTo(
      targetRailReveal,
      duration: DashboardMotionTokens.railDuration,
      curve: DashboardMotionTokens.transitionCurve,
    );
    if (pulseRevision != _pulseRevision) {
      _pulseRevision = pulseRevision;
      _pulseController.forward(from: 0);
    }
  }

  /// Adopts a replacement aggregate controller without continuing any motion
  /// that belonged to the previous controller.
  void _resetVisualStateForReplacementController() {
    final targetProgress = widget.controller.expansion.progress;
    final targetRailReveal = widget.controller.rail.isExpanded
        ? DashboardMotionTokens.shownReveal
        : DashboardMotionTokens.hiddenReveal;

    _collapseController.stop();
    _railController.stop();
    _pulseController.stop();

    _collapseController.value = targetProgress;
    _railController.value = targetRailReveal;
    _pulseController.value = DashboardMotionTokens.restingScale;
    _pulseRevision = widget.controller.transactionDirection.pulseRevision;
    _railStructure = _readRailStructure();
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    _collapseController.dispose();
    _railController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _structuralMotion,
      builder: (context, _) {
        widget.controller.performanceCounters.increment(
          DashboardPerformanceMetric.dashboardRootBuild,
        );
        final direction = widget.controller.transactionDirection.direction;
        final baseMetrics = widget.layoutMetrics ?? widget.controller.metrics;
        final viewportMetrics = baseMetrics.fitToViewport(
          MediaQuery.sizeOf(context),
        );
        final geometry = DashboardGeometryResolver.resolve(
          metrics: viewportMetrics,
          mode: widget.mode,
          collapseProgress:
              _collapseController.value /
              widget.controller.metrics.collapseTravel *
              viewportMetrics.collapseTravel,
          isRailExpanded: widget.controller.rail.isExpanded,
        );
        return widget.builder(
          context,
          DashboardVisualFrame(
            geometry: geometry,
            palette: _palette,
            railReveal: _railController.value,
            selectedDirection: direction,
            directionPulseScale: _disableAnimations
                ? const AlwaysStoppedAnimation<double>(
                    DashboardMotionTokens.restingScale,
                  )
                : _pulseScale,
            isExpansionDragging: widget.controller.expansion.isDragging,
          ),
        );
      },
    );
  }
}

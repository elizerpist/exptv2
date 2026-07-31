import 'package:flutter/material.dart';

import '../../features/dashboard/application/dashboard_core_controller.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/application/transaction_direction_controller.dart';
import '../design/dashboard_geometry_resolver.dart';
import '../design/dashboard_layout_frame.dart';
import '../design/dashboard_mode_palette.dart';

/// Immutable visual state supplied by the motion owner to dashboard rendering.
@immutable
class DashboardVisualFrame {
  const DashboardVisualFrame({
    required this.geometry,
    required this.palette,
    required this.railReveal,
    required this.incomeIconScale,
    required this.expenseIconScale,
  });

  final DashboardLayoutFrame geometry;
  final DashboardModePalette palette;
  final double railReveal;
  final double incomeIconScale;
  final double expenseIconScale;
}

typedef DashboardVisualFrameBuilder =
    Widget Function(BuildContext context, DashboardVisualFrame frame);

/// The dashboard's only Flutter ticker owner.
///
/// It observes the aggregate controller once, derives geometry centrally, and
/// supplies presentation-only state to input-only leaves.
class DashboardMotionHost extends StatefulWidget {
  const DashboardMotionHost({
    super.key,
    required this.controller,
    required this.mode,
    required this.builder,
  });

  final DashboardCoreController controller;
  final DashboardModeSpec mode;
  final DashboardVisualFrameBuilder builder;

  @override
  State<DashboardMotionHost> createState() => _DashboardMotionHostState();
}

class _DashboardMotionHostState extends State<DashboardMotionHost>
    with TickerProviderStateMixin {
  late final AnimationController _collapseController;
  late final AnimationController _railController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late int _pulseRevision;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
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
    _pulseRevision = widget.controller.transactionDirection.pulseRevision;
    widget.controller.addListener(_onControllerChanged);
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
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _pulseRevision = widget.controller.transactionDirection.pulseRevision;
    _synchronizeVisualState();
  }

  void _onControllerChanged() {
    _synchronizeVisualState();
    if (mounted) setState(() {});
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

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _collapseController.dispose();
    _railController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _collapseController,
        _railController,
        _pulseController,
      ]),
      builder: (context, _) {
        final direction = widget.controller.transactionDirection.direction;
        final selectedScale = _disableAnimations
            ? DashboardMotionTokens.restingScale
            : _pulseScale.value;
        final geometry = DashboardGeometryResolver.resolve(
          metrics: widget.controller.metrics,
          mode: widget.mode,
          collapseProgress: _collapseController.value,
          isRailExpanded: widget.controller.rail.isExpanded,
        );
        final palette = DashboardModePaletteResolver.resolve(widget.mode);
        return widget.builder(
          context,
          DashboardVisualFrame(
            geometry: geometry,
            palette: palette,
            railReveal: _railController.value,
            incomeIconScale: direction == TransactionDirection.income
                ? selectedScale
                : DashboardMotionTokens.restingScale,
            expenseIconScale: direction == TransactionDirection.expense
                ? selectedScale
                : DashboardMotionTokens.restingScale,
          ),
        );
      },
    );
  }
}

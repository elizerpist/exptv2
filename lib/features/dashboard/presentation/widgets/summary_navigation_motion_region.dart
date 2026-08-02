import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../presentation/summary_navigation_motion_controller.dart';
import 'summary_pill_text_transition.dart';

/// Paint-only motion lanes for the SummaryPill navigation text.
///
/// The axis transition and rail tick impulse share [SummaryNavigationTextBlock]
/// but have independent controllers. This widget has no navigation, query,
/// amount or haptic write path.
class SummaryNavigationMotionRegion extends StatefulWidget {
  const SummaryNavigationMotionRegion({
    super.key,
    required this.controller,
    required this.content,
    required this.axis,
    required this.direction,
    required this.animateAxis,
    this.animateTitle = true,
    this.compact = false,
    this.height = 36,
  });

  final SummaryNavigationMotionController controller;
  final SummaryTextContent content;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final bool animateAxis;
  final bool animateTitle;
  final bool compact;
  final double height;

  @override
  State<SummaryNavigationMotionRegion> createState() =>
      _SummaryNavigationMotionRegionState();
}

class _SummaryNavigationMotionRegionState
    extends State<SummaryNavigationMotionRegion>
    with TickerProviderStateMixin {
  static const _maximumLift = -4.0;
  static const _impulsePerTick = -2.2;

  late final AnimationController _tickController;
  SummaryRailTick? _observedRailTick;
  late SummaryStagedTextTransition _stagedText;

  @override
  void initState() {
    super.initState();
    _observedRailTick = widget.controller.railTick;
    _stagedText = widget.controller.stagedText;
    _tickController = AnimationController.unbounded(vsync: this, value: 0);
    widget.controller.addListener(_handleMotionIntent);
  }

  @override
  void didUpdateWidget(covariant SummaryNavigationMotionRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleMotionIntent);
      _observedRailTick = widget.controller.railTick;
      _stagedText = widget.controller.stagedText;
      widget.controller.addListener(_handleMotionIntent);
    }
  }

  void _handleMotionIntent() {
    final tick = widget.controller.railTick;
    final nextStagedText = widget.controller.stagedText;
    final stagedTextChanged = !identical(nextStagedText, _stagedText);
    if (stagedTextChanged) {
      _stagedText = nextStagedText;
    }
    final hasNewRailTick = tick != null && tick != _observedRailTick;
    if (hasNewRailTick) {
      _observedRailTick = tick;
    }
    if (_stagedText.isAxisMotionActive) {
      _tickController
        ..stop()
        ..value = 0;
    } else if (hasNewRailTick) {
      _triggerTickImpulse();
    }
    if (stagedTextChanged && mounted) setState(() {});
  }

  void _triggerTickImpulse() {
    _tickController.stop();
    final nextStart = math.max(
      _maximumLift,
      _tickController.value + _impulsePerTick,
    );
    _tickController.value = nextStart;
    _tickController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 1800, damping: 85),
        nextStart,
        0,
        0,
        tolerance: const Tolerance(distance: .01, velocity: .01),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _tickController,
        child: _buildAxisLane(),
        builder: (context, child) => Transform.translate(
          key: const ValueKey('summary-navigation-tick-transform'),
          offset: Offset(0, _tickController.value),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAxisLane() {
    final stagedText = _stagedText;
    if (stagedText.phase == SummaryStagedTextPhase.holding) {
      return _fixedStagedText(stagedText.outgoing!);
    }
    if (stagedText.phase == SummaryStagedTextPhase.transitioning) {
      return SummaryPillTextTransition(
        key: ValueKey('summary-navigation-staged-${stagedText.generation}'),
        content: stagedText.incoming!,
        axis: stagedText.axis,
        direction: stagedText.direction,
        initialPreviousContent: stagedText.outgoing,
        animateTitle: true,
        compact: widget.compact,
        height: widget.height,
        onTransitionCompleted: () => widget.controller.completeTextTransition(
          generation: stagedText.generation,
        ),
      );
    }

    return SummaryPillTextTransition(
      content: widget.content,
      axis: widget.axis,
      direction: widget.direction,
      animate: widget.animateAxis,
      animateTitle: widget.animateTitle,
      compact: widget.compact,
      height: widget.height,
    );
  }

  Widget _fixedStagedText(SummaryTextContent content) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: SummaryNavigationTextBlock(
          title: content.title,
          subtitle: content.subtitle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleMotionIntent);
    _tickController.dispose();
    super.dispose();
  }
}

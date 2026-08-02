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
    this.horizontalCandidate,
    this.horizontalCandidateBuilder,
    this.animateTitle = true,
    this.compact = false,
    this.height = 36,
  });

  final SummaryNavigationMotionController controller;
  final SummaryTextContent content;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final bool animateAxis;
  final SummaryTextContent? horizontalCandidate;
  final SummaryTextContent? Function(SummaryTransitionDirection direction)?
  horizontalCandidateBuilder;
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
  static const _horizontalResistanceDistance = 5.0;

  late final AnimationController _tickController;
  late final AnimationController _returnController;
  SummaryRailTick? _observedRailTick;
  SummaryTextContent? _committedOutgoingContent;
  double _returnStartProgress = 0;
  int? _returnMotionGeneration;
  double _committedStartProgress = 0;

  @override
  void initState() {
    super.initState();
    _observedRailTick = widget.controller.railTick;
    _tickController = AnimationController.unbounded(vsync: this, value: 0);
    _returnController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 125),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed || !mounted) return;
          final generation = _returnMotionGeneration;
          _returnMotionGeneration = null;
          if (generation != null) {
            widget.controller.clearHorizontalMotion(generation: generation);
          }
        });
    widget.controller.addListener(_handleMotionIntent);
  }

  @override
  void didUpdateWidget(covariant SummaryNavigationMotionRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleMotionIntent);
      _observedRailTick = widget.controller.railTick;
      widget.controller.addListener(_handleMotionIntent);
    }
    final motion = widget.controller.horizontalMotion;
    if (oldWidget.content != widget.content &&
        widget.axis == SummaryTransitionAxis.horizontal &&
        motion.phase == SummaryHorizontalMotionPhase.committed) {
      _committedStartProgress =
          SummaryPillTextTransitionMath.easeOutCubicInputForVisualProgress(
            motion.progress,
          );
    }
  }

  void _handleMotionIntent() {
    final tick = widget.controller.railTick;
    final stagedText = widget.controller.stagedText;
    final hasNewRailTick = tick != null && tick != _observedRailTick;
    if (hasNewRailTick) {
      _observedRailTick = tick;
    }
    if (stagedText.isAxisMotionActive) {
      _tickController
        ..stop()
        ..value = 0;
    } else if (hasNewRailTick) {
      _triggerTickImpulse();
    }

    final motion = widget.controller.horizontalMotion;
    if (motion.phase == SummaryHorizontalMotionPhase.cancelled) {
      _returnStartProgress = motion.progress;
      _returnMotionGeneration = motion.generation;
      _returnController
        ..value = 0
        ..forward();
    } else {
      _returnController.stop();
      _returnMotionGeneration = null;
      if (motion.phase == SummaryHorizontalMotionPhase.committed) {
        _committedStartProgress =
            SummaryPillTextTransitionMath.easeOutCubicInputForVisualProgress(
              motion.progress,
            );
        _committedOutgoingContent = widget.content;
      }
    }
    if (mounted) setState(() {});
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
    final stagedText = widget.controller.stagedText;
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

    final motion = widget.controller.horizontalMotion;
    return switch (motion.phase) {
      SummaryHorizontalMotionPhase.dragging => _HorizontalDragPreview(
        current: widget.content,
        candidate: _horizontalCandidateFor(motion.direction),
        direction: motion.direction,
        progress: motion.progress,
        height: widget.height,
      ),
      SummaryHorizontalMotionPhase.resisting => _HorizontalDragPreview(
        current: widget.content,
        direction: motion.direction,
        progress: motion.progress,
        height: widget.height,
        resistanceDistance: _horizontalResistanceDistance,
      ),
      SummaryHorizontalMotionPhase.cancelled => AnimatedBuilder(
        animation: _returnController,
        builder: (context, _) => _HorizontalDragPreview(
          current: widget.content,
          candidate: motion.canNavigate
              ? _horizontalCandidateFor(motion.direction)
              : null,
          direction: motion.direction,
          progress:
              _returnStartProgress *
              (1 - Curves.easeOutCubic.transform(_returnController.value)),
          height: widget.height,
          resistanceDistance: motion.canNavigate
              ? null
              : _horizontalResistanceDistance,
        ),
      ),
      _ => SummaryPillTextTransition(
        content: widget.content,
        axis: widget.axis,
        direction: widget.direction,
        animate: widget.animateAxis,
        animateTitle: widget.animateTitle,
        compact: widget.compact,
        height: widget.height,
        initialProgress: motion.phase == SummaryHorizontalMotionPhase.committed
            ? _committedStartProgress
            : 0,
        initialPreviousContent:
            motion.phase == SummaryHorizontalMotionPhase.committed &&
                _committedOutgoingContent != widget.content
            ? _committedOutgoingContent
            : null,
        onTransitionCompleted: () {
          if (widget.controller.horizontalMotion.phase ==
              SummaryHorizontalMotionPhase.committed) {
            widget.controller.clearHorizontalMotion();
            _committedOutgoingContent = null;
          }
        },
      ),
    };
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

  SummaryTextContent? _horizontalCandidateFor(
    SummaryTransitionDirection direction,
  ) =>
      widget.horizontalCandidateBuilder?.call(direction) ??
      widget.horizontalCandidate;

  @override
  void dispose() {
    widget.controller.removeListener(_handleMotionIntent);
    _tickController.dispose();
    _returnController.dispose();
    super.dispose();
  }
}

class _HorizontalDragPreview extends StatelessWidget {
  const _HorizontalDragPreview({
    required this.current,
    required this.direction,
    required this.progress,
    required this.height,
    this.candidate,
    this.resistanceDistance,
  });

  final SummaryTextContent current;
  final SummaryTextContent? candidate;
  final SummaryTransitionDirection direction;
  final double progress;
  final double height;
  final double? resistanceDistance;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final resistance = resistanceDistance;
    if (candidate == null || resistance != null) {
      final sign = direction == SummaryTransitionDirection.forward ? -1.0 : 1.0;
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Transform.translate(
          key: const ValueKey('summary-navigation-drag-outgoing'),
          offset: Offset(sign * safeProgress * (resistance ?? 0), 0),
          child: Opacity(
            opacity: resistance == null
                ? 1 - safeProgress
                : 1 - safeProgress * .05,
            child: SummaryNavigationTextBlock(
              title: current.title,
              subtitle: current.subtitle,
            ),
          ),
        ),
      );
    }

    final offsets = SummaryPillTextTransitionMath.horizontalOffsets(
      safeProgress,
      direction,
    );
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Opacity(
              opacity: 1 - safeProgress,
              child: Transform.translate(
                key: const ValueKey('summary-navigation-drag-outgoing'),
                offset: offsets.outgoing,
                child: SummaryNavigationTextBlock(
                  title: current.title,
                  subtitle: current.subtitle,
                ),
              ),
            ),
            Opacity(
              opacity: safeProgress,
              child: Transform.translate(
                key: const ValueKey('summary-navigation-drag-incoming'),
                offset: offsets.incoming,
                child: SummaryNavigationTextBlock(
                  title: candidate!.title,
                  subtitle: candidate!.subtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

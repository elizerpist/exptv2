import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/motion/gesture_direction_arbiter.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../dashboard_amount_update_policy.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../summary_navigation_motion_controller.dart';
import 'summary_navigation_motion_region.dart';
import 'summary_pill_text_transition.dart';

/// Stable SummaryPill shell with independently listening navigation and amount
/// leaves. Prepared amount text is consumed directly; preview frames never
/// format values or enqueue animations.
final class DashboardSummaryPill extends StatefulWidget {
  const DashboardSummaryPill({
    super.key,
    required this.bounds,
    required this.navigation,
    required this.visibleFrames,
    required this.navigationMotionController,
    this.onMotionActiveChanged,
    this.onAmountMotionActiveChanged,
    this.onDirectInputStarted,
    required this.horizontalCandidateBuilder,
    required this.onToggleRail,
    required this.onMoveFiner,
    required this.onMoveBroader,
    required this.onMovePrevious,
    required this.onMoveNext,
    this.onSelectionHaptic,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardNavigationController navigation;
  final DashboardVisibleFrameStore visibleFrames;
  final SummaryNavigationMotionController navigationMotionController;
  final ValueChanged<bool>? onMotionActiveChanged;
  final ValueChanged<bool>? onAmountMotionActiveChanged;

  /// Runs on the raw pointer-down boundary, before the pan recognizer has an
  /// opportunity to wait on another gesture arena member. The Core uses this
  /// only to preempt stale maintenance; it does not make the pointer an input
  /// lock or manufacture a navigation action.
  final VoidCallback? onDirectInputStarted;
  final SummaryTextContent? Function(SummaryTransitionDirection direction)
  horizontalCandidateBuilder;
  final VoidCallback onToggleRail;
  final VoidCallback onMoveFiner;
  final VoidCallback onMoveBroader;
  final VoidCallback onMovePrevious;
  final VoidCallback onMoveNext;
  final VoidCallback? onSelectionHaptic;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  State<DashboardSummaryPill> createState() => _DashboardSummaryPillState();
}

final class _DashboardSummaryPillState extends State<DashboardSummaryPill>
    with SingleTickerProviderStateMixin {
  static const _touchSlop = 8.0;
  // A persistent amount lane leaves the minimum supported Summary width
  // enough room for its complete temporal label. It is a layout decision,
  // not a crossfade-only animation envelope.
  static const _amountSlotWidthFraction = .20;
  static const _shellDragFactor = .10;
  static const _maximumShellTravel = 8.0;
  static const _maximumSumResistance = 5.0;
  static const _shellReturnDuration = Duration(milliseconds: 100);

  _SummaryGestureAxis? _axis;
  double _dx = 0;
  double _dy = 0;
  Offset _returnStartOffset = Offset.zero;
  bool _didEmitThresholdHaptic = false;
  int _shellGeneration = 0;
  int? _returnShellGeneration;
  int? _stagedTextGeneration;
  bool _returnStartsTextTransition = false;
  late final ValueNotifier<Offset> _shellOffset;
  late final AnimationController _shellReturnController;
  late Listenable _navigationChanges;

  @override
  void initState() {
    super.initState();
    _navigationChanges = Listenable.merge([
      widget.navigation,
      widget.visibleFrames.navigationLane,
    ]);
    _shellOffset = ValueNotifier(Offset.zero);
    _shellReturnController =
        AnimationController(vsync: this, duration: _shellReturnDuration)
          ..addListener(_handleShellReturnTick)
          ..addStatusListener(_handleShellReturnStatus);
  }

  @override
  void didUpdateWidget(covariant DashboardSummaryPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.navigation, widget.navigation) ||
        !identical(oldWidget.visibleFrames, widget.visibleFrames)) {
      _navigationChanges = Listenable.merge([
        widget.navigation,
        widget.visibleFrames.navigationLane,
      ]);
    }
  }

  SummaryNavigationPresentation get _navigationPresentation {
    final state = widget.navigation.state;
    final base = SummaryNavigationProjector.project(state);
    final visible = widget.visibleFrames.value;
    if (!state.isRailOpen ||
        visible == null ||
        visible.parentQueryKey != state.parentQueryKey ||
        visible.navigationEpoch != state.navigationEpoch) {
      return base;
    }
    return SummaryNavigationPresentation(
      plane: base.plane,
      planeTitle: base.planeTitle,
      subtitle: SummaryNavigationProjector.liveRailChildSubtitle(
        plane: visible.plane,
        visibleChildScope: visible.scope.timeScope,
        fallback: visible.childLabel,
      ),
      isRailOpen: true,
      revision: visible.frameGeneration,
      changeReason: SummaryContentChangeReason.railPreviewTick,
      direction: base.direction,
      isPreview: visible.mode == DashboardVisibleMode.preview,
    );
  }

  void _handleShellReturnTick() {
    _setShellOffset(
      Offset.lerp(
        _returnStartOffset,
        Offset.zero,
        Curves.easeOutCubic.transform(_shellReturnController.value),
      )!,
    );
  }

  void _handleShellReturnStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final generation = _returnShellGeneration;
    if (generation == null || generation != _shellGeneration) return;
    final textGeneration = _stagedTextGeneration;
    final startsText = _returnStartsTextTransition;
    _setShellOffset(Offset.zero);
    _returnShellGeneration = null;
    _stagedTextGeneration = null;
    _returnStartsTextTransition = false;
    if (startsText && textGeneration != null) {
      widget.navigationMotionController.completeShellReturn(
        generation: textGeneration,
      );
    }
    widget.onMotionActiveChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.summaryPillBuild,
    );
    final horizontalInset = widget.bounds.width <= 320
        ? 6.0
        : FluviVisualTokens.controlHorizontalInset;
    final borderRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.summaryPill,
          size: Size(widget.bounds.width, widget.bounds.height),
        );
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.summaryPill);
    final shell = FluviRoundedBox(
      color: depth.surfaceColor ?? FluviVisualTokens.surface,
      border: DashboardBorderScope.profileOf(
        context,
      ).borderFor(DashboardBorderSurface.summary),
      borderRadius: borderRadius,
      boxShadow: depth.shadows,
      child: Row(
        children: [
          SizedBox(width: horizontalInset),
          const Icon(
            Icons.calendar_month_outlined,
            color: FluviVisualTokens.textSecondary,
            size: FluviVisualTokens.iconSize,
          ),
          const SizedBox(width: FluviVisualTokens.controlInnerGap),
          Expanded(
            child: _SummaryNavigationTextSlot(
              listenable: _navigationChanges,
              presentation: () => _navigationPresentation,
              motionController: widget.navigationMotionController,
              performanceCounters: widget.performanceCounters,
            ),
          ),
          SummaryPillPreparedAmountSlot(
            visibleFrames: widget.visibleFrames,
            performanceCounters: widget.performanceCounters,
            onMotionActiveChanged: widget.onAmountMotionActiveChanged,
            alignment: Alignment.centerRight,
            slotWidth: widget.bounds.width * _amountSlotWidthFraction,
          ),
          _SummaryChevronSlot(
            navigation: widget.navigation,
            onTap: widget.onToggleRail,
          ),
          SizedBox(width: horizontalInset),
        ],
      ),
    );
    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => widget.onDirectInputStarted?.call(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _beginGesture(),
          onPanUpdate: _updateGesture,
          onPanEnd: _finishGesture,
          onPanCancel: _startShellReturn,
          child: ValueListenableBuilder<Offset>(
            valueListenable: _shellOffset,
            child: RepaintBoundary(
              key: const ValueKey('dashboard-summary-shell-repaint-boundary'),
              child: shell,
            ),
            builder: (context, offset, child) => Transform.translate(
              key: const ValueKey('dashboard-summary-shell-transform'),
              offset: offset,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  void _beginGesture() {
    widget.onMotionActiveChanged?.call(true);
    _shellReturnController.stop();
    _shellGeneration += 1;
    _returnShellGeneration = null;
    _stagedTextGeneration = null;
    _returnStartsTextTransition = false;
    widget.navigationMotionController.cancelStagedTextMotion();
    _axis = null;
    _dx = 0;
    _dy = 0;
    _setShellOffset(Offset.zero);
    _didEmitThresholdHaptic = false;
  }

  void _updateGesture(DragUpdateDetails details) {
    _dx += details.delta.dx;
    _dy += details.delta.dy;
    _axis ??= _axisFor(_dx, _dy);
    final axis = _axis;
    if (axis == null) return;
    final distance = axis == _SummaryGestureAxis.vertical ? _dy : _dx;
    final direction = distance < 0
        ? SummaryTransitionDirection.forward
        : SummaryTransitionDirection.backward;
    final candidate = axis == _SummaryGestureAxis.horizontal
        ? widget.horizontalCandidateBuilder(direction)
        : null;
    final canNavigate =
        axis != _SummaryGestureAxis.horizontal || candidate != null;
    if (distance.abs() >= 28 && !_didEmitThresholdHaptic && canNavigate) {
      _emitSelectionHaptic();
    }
    if (axis == _SummaryGestureAxis.horizontal) {
      final maximum = canNavigate ? _maximumShellTravel : _maximumSumResistance;
      _setShellOffset(
        Offset((_dx * _shellDragFactor).clamp(-maximum, maximum).toDouble(), 0),
      );
    } else {
      _setShellOffset(
        Offset(
          0,
          (_dy * _shellDragFactor)
              .clamp(-_maximumShellTravel, _maximumShellTravel)
              .toDouble(),
        ),
      );
    }
  }

  void _finishGesture(DragEndDetails details) {
    final axis = _axis;
    if (axis == null) {
      _startShellReturn();
      return;
    }
    final distance = axis == _SummaryGestureAxis.vertical ? _dy : _dx;
    final velocity = axis == _SummaryGestureAxis.vertical
        ? details.velocity.pixelsPerSecond.dy
        : details.velocity.pixelsPerSecond.dx;
    final shouldCommit = distance.abs() >= 28 || velocity.abs() >= 360;
    final forward = distance.abs() >= 28 ? distance < 0 : velocity < 0;
    final direction = forward
        ? SummaryTransitionDirection.forward
        : SummaryTransitionDirection.backward;
    if (!shouldCommit ||
        (axis == _SummaryGestureAxis.horizontal &&
            widget.horizontalCandidateBuilder(direction) == null)) {
      _startShellReturn();
      return;
    }
    if (!_didEmitThresholdHaptic) _emitSelectionHaptic();
    _commitWithShellReturn(
      axis: axis == _SummaryGestureAxis.horizontal
          ? SummaryTransitionAxis.horizontal
          : SummaryTransitionAxis.vertical,
      direction: direction,
      onCommit: axis == _SummaryGestureAxis.horizontal
          ? (forward ? widget.onMoveNext : widget.onMovePrevious)
          // `forward` remains the physical visual direction: negative/up is
          // forward and positive/down is backward. The temporal plane order
          // is SUM -> YEAR -> MONTH, so physical down selects finer while up
          // selects broader.
          : (forward ? widget.onMoveBroader : widget.onMoveFiner),
    );
  }

  void _commitWithShellReturn({
    required SummaryTransitionAxis axis,
    required SummaryTransitionDirection direction,
    required VoidCallback onCommit,
  }) {
    final generation = widget.navigationMotionController.holdTextForShellReturn(
      outgoing: _textContent(_navigationPresentation),
      axis: axis,
      direction: direction,
    );
    // Structural motion starts synchronously. Data preparation continues in
    // its independent owner and is never awaited by this animation.
    onCommit();
    widget.navigationMotionController.bindShellReturnIncoming(
      generation: generation,
      incoming: _textContent(_navigationPresentation),
    );
    _startShellReturn(stagedTextGeneration: generation);
  }

  SummaryTextContent _textContent(SummaryNavigationPresentation value) =>
      SummaryTextContent(title: value.planeTitle, subtitle: value.subtitle);

  void _startShellReturn({int? stagedTextGeneration}) {
    _returnStartOffset = _shellOffset.value;
    _axis = null;
    _dx = 0;
    _dy = 0;
    _didEmitThresholdHaptic = false;
    _returnShellGeneration = _shellGeneration;
    _stagedTextGeneration = stagedTextGeneration;
    _returnStartsTextTransition = stagedTextGeneration != null;
    _shellReturnController
      ..value = 0
      ..forward();
  }

  void _setShellOffset(Offset value) {
    if (_shellOffset.value != value) _shellOffset.value = value;
  }

  void _emitSelectionHaptic() {
    if (_didEmitThresholdHaptic) return;
    _didEmitThresholdHaptic = true;
    widget.onSelectionHaptic?.call();
    if (widget.onSelectionHaptic == null) HapticFeedback.selectionClick();
  }

  _SummaryGestureAxis? _axisFor(double dx, double dy) {
    return switch (GestureDirectionArbiter.resolve(
      dx: dx,
      dy: dy,
      touchSlop: _touchSlop,
    )) {
      GestureDirectionIntent.horizontal => _SummaryGestureAxis.horizontal,
      GestureDirectionIntent.vertical => _SummaryGestureAxis.vertical,
      null => null,
    };
  }

  @override
  void dispose() {
    widget.onMotionActiveChanged?.call(false);
    _shellReturnController.dispose();
    _shellOffset.dispose();
    super.dispose();
  }
}

final class _SummaryNavigationTextSlot extends StatelessWidget {
  const _SummaryNavigationTextSlot({
    required this.listenable,
    required this.presentation,
    required this.motionController,
    required this.performanceCounters,
  });

  final Listenable listenable;
  final SummaryNavigationPresentation Function() presentation;
  final SummaryNavigationMotionController motionController;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: listenable,
    builder: (context, _) {
      performanceCounters?.increment(
        DashboardPerformanceMetric.summaryNavigationTextBuild,
      );
      final value = presentation();
      return SummaryNavigationMotionRegion(
        controller: motionController,
        content: SummaryTextContent(
          title: value.planeTitle,
          subtitle: value.subtitle,
        ),
        axis: value.transitionAxis,
        direction: value.direction,
        animateAxis:
            !value.isPreview &&
            value.transitionAxis != SummaryTransitionAxis.none,
        animateTitle:
            !value.isPreview &&
            value.transitionAxis != SummaryTransitionAxis.none,
        compact:
            value.changeReason == SummaryContentChangeReason.railOpened ||
            value.changeReason == SummaryContentChangeReason.railClosed ||
            value.changeReason == SummaryContentChangeReason.childSettled,
      );
    },
  );
}

final class _SummaryChevronSlot extends StatelessWidget {
  const _SummaryChevronSlot({required this.navigation, required this.onTap});

  final DashboardNavigationController navigation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: navigation,
    builder: (context, _) {
      final open = navigation.state.isRailOpen;
      final icon = open
          ? FluviHighlightMask(
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: FluviVisualTokens.iconSize,
              ),
            )
          : const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FluviVisualTokens.textSecondary,
              size: FluviVisualTokens.iconSize,
            );
      return Semantics(
        button: true,
        label: open ? 'Időválasztó bezárása' : 'Időválasztó megnyitása',
        child: GestureDetector(
          key: const ValueKey('dashboard-summary-chevron'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(4), child: icon),
        ),
      );
    },
  );
}

/// Shared prepared amount leaf used by each SummaryPill experiment.
///
/// It listens only to the visible prepared-frame amount lane, preserving the
/// established direct-preview/no-formatting hot path.
final class SummaryPillPreparedAmountSlot extends StatelessWidget {
  const SummaryPillPreparedAmountSlot({
    super.key,
    required this.visibleFrames,
    required this.performanceCounters,
    required this.onMotionActiveChanged,
    this.alignment = Alignment.centerRight,
    this.slotWidth,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onMotionActiveChanged;

  /// The outer Summary layout chooses this persistent amount anchor. It is
  /// intentionally independent from preview/crossfade/motion state.
  final AlignmentGeometry alignment;

  /// A fixed amount envelope owned by the enclosing Summary layout. When it
  /// is supplied, idle, preview and committed crossfade all reserve exactly
  /// this same Row width; [alignment] only controls paint inside the slot.
  final double? slotWidth;

  @override
  Widget build(BuildContext context) {
    final content = ValueListenableBuilder(
      valueListenable: visibleFrames.amountLane,
      builder: (context, frame, _) => _PreparedAmountCrossfade(
        frame: frame,
        performanceCounters: performanceCounters,
        onMotionActiveChanged: onMotionActiveChanged,
        alignment: alignment,
      ),
    );
    final width = slotWidth;
    if (width == null) return content;
    return SizedBox(
      key: const ValueKey('dashboard-summary-amount-slot'),
      width: width,
      child: Align(alignment: alignment, child: content),
    );
  }
}

final class _PreparedAmountCrossfade extends StatefulWidget {
  const _PreparedAmountCrossfade({
    required this.frame,
    required this.performanceCounters,
    required this.onMotionActiveChanged,
    required this.alignment,
  });

  final DashboardVisibleFrame? frame;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onMotionActiveChanged;
  final AlignmentGeometry alignment;

  @override
  State<_PreparedAmountCrossfade> createState() =>
      _PreparedAmountCrossfadeState();
}

final class _PreparedAmountCrossfadeState
    extends State<_PreparedAmountCrossfade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _current;
  late int _currentAmount;
  String? _previous;

  @override
  void initState() {
    super.initState();
    _current = widget.frame?.amount.formattedAmount ?? '0 Ft';
    _currentAmount = widget.frame?.amount.totalMinor ?? 0;
    _controller =
        AnimationController(
          vsync: this,
          duration: DashboardAmountUpdatePolicy.animationDuration,
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              mounted &&
              _previous != null) {
            setState(() => _previous = null);
            widget.onMotionActiveChanged?.call(false);
          }
        });
  }

  @override
  void didUpdateWidget(covariant _PreparedAmountCrossfade oldWidget) {
    super.didUpdateWidget(oldWidget);
    final frame = widget.frame;
    final next = frame?.amount.formattedAmount ?? '0 Ft';
    final targetAmount = frame?.amount.totalMinor ?? 0;
    final decision = DashboardAmountUpdatePolicy.resolve(
      previousAmount: _currentAmount,
      targetAmount: targetAmount,
      isPreview: frame?.mode == DashboardVisibleMode.preview,
      isRailMotionActive: frame?.mode == DashboardVisibleMode.preview,
      requiresDirectReplacement: frame == null,
    );
    if (decision.mode == DashboardAmountUpdateMode.noOp && next == _current) {
      return;
    }
    _currentAmount = targetAmount;
    if (decision.mode == DashboardAmountUpdateMode.directPreview ||
        decision.mode == DashboardAmountUpdateMode.noOp) {
      _controller
        ..stop()
        ..value = 1;
      _previous = null;
      _current = next;
      widget.onMotionActiveChanged?.call(false);
      return;
    }
    _previous = _current;
    _current = next;
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.amountAnimationStarted,
    );
    widget.onMotionActiveChanged?.call(true);
    _controller
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final counters = widget.performanceCounters;
    final measure = counters?.measuresDurations ?? false;
    final started = measure ? developer.Timeline.now : 0;
    counters?.increment(DashboardPerformanceMetric.amountBuild);
    final result = Padding(
      padding: const EdgeInsets.only(right: FluviVisualTokens.controlInnerGap),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = Curves.easeOutCubic.transform(_controller.value);
          if (_previous == null) return _amountText(_current);
          // A crossfade shares the same bounded, intrinsic layout contract as
          // the static amount. In particular, do not wrap this in an Align:
          // Align expands to the parent's finite max width and would make the
          // Row reserve a different envelope only while crossfading.
          return Stack(
            alignment: widget.alignment,
            children: [
              Opacity(opacity: 1 - value, child: _amountText(_previous!)),
              Opacity(opacity: value, child: _amountText(_current)),
            ],
          );
        },
      ),
    );
    if (measure) {
      counters!.increment(
        DashboardPerformanceMetric.amountBindMicros,
        by: developer.Timeline.now - started,
      );
    }
    return result;
  }

  Widget _amountText(String value) => FittedBox(
    alignment: widget.alignment,
    fit: BoxFit.scaleDown,
    child: Text(
      value,
      maxLines: 1,
      style: FluviVisualTokens.summaryAmountTextStyle,
    ),
  );

  @override
  void dispose() {
    widget.onMotionActiveChanged?.call(false);
    _controller.dispose();
    super.dispose();
  }
}

enum _SummaryGestureAxis { horizontal, vertical }

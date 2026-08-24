import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../dashboard_amount_update_policy.dart';
import '../summary_navigation_motion_controller.dart';
import '../summary_text_content.dart';
import 'summary_navigation_motion_region.dart';
import 'summary_pill_primary_controls.dart';

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
    required this.horizontalCandidateBuilder,
    required this.onToggleRail,
    required this.onMoveFiner,
    required this.onMoveBroader,
    required this.onMovePrevious,
    required this.onMoveNext,
    this.onSelectPlaneTarget,
    this.motherLabelForOffset,
    this.onSelectMotherOffset,
    this.onSelectionHaptic,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardNavigationController navigation;
  final DashboardVisibleFrameStore visibleFrames;
  final SummaryNavigationMotionController navigationMotionController;
  final ValueChanged<bool>? onMotionActiveChanged;
  final ValueChanged<bool>? onAmountMotionActiveChanged;
  final SummaryTextContent? Function(SummaryTransitionDirection direction)
  horizontalCandidateBuilder;
  final VoidCallback onToggleRail;
  final VoidCallback onMoveFiner;
  final VoidCallback onMoveBroader;
  final VoidCallback onMovePrevious;
  final VoidCallback onMoveNext;
  final void Function(TimePlane target, {required bool finer})?
  onSelectPlaneTarget;
  final String? Function(int offset)? motherLabelForOffset;
  final ValueChanged<int>? onSelectMotherOffset;
  final VoidCallback? onSelectionHaptic;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  State<DashboardSummaryPill> createState() => _DashboardSummaryPillState();
}

final class _DashboardSummaryPillState extends State<DashboardSummaryPill> {
  late Listenable _navigationChanges;

  @override
  void initState() {
    super.initState();
    _navigationChanges = Listenable.merge([
      widget.navigation,
      widget.visibleFrames.navigationLane,
    ]);
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

  @override
  Widget build(BuildContext context) {
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.summaryPillBuild,
    );
    final horizontalInset = widget.bounds.width <= 320
        ? 6.0
        : FluviVisualTokens.controlHorizontalInset;
    final shell = FluviRoundedBox(
      color: FluviVisualTokens.surface,
      child: Row(
        children: [
          SizedBox(width: horizontalInset),
          Expanded(
            child: SummaryPillPrimaryControls(
              height: widget.bounds.height,
              navigation: widget.navigation,
              onMotionActiveChanged: widget.onMotionActiveChanged,
              onSelectPlaneTarget:
                  widget.onSelectPlaneTarget ?? _legacyPlaneTarget,
              motherLabelForOffset:
                  widget.motherLabelForOffset ?? _legacyMotherLabel,
              onSelectMotherOffset:
                  widget.onSelectMotherOffset ?? _legacyMotherOffset,
              railFeedback: _SummaryRailFeedbackSlot(
                listenable: _navigationChanges,
                navigation: widget.navigation,
                visibleFrames: widget.visibleFrames,
                motionController: widget.navigationMotionController,
                performanceCounters: widget.performanceCounters,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.bounds.width * .40),
            child: _PreparedAmountSlot(
              visibleFrames: widget.visibleFrames,
              performanceCounters: widget.performanceCounters,
              onMotionActiveChanged: widget.onAmountMotionActiveChanged,
            ),
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
      child: Transform.translate(
        key: const ValueKey('dashboard-summary-shell-transform'),
        offset: Offset.zero,
        child: RepaintBoundary(
          key: const ValueKey('dashboard-summary-shell-repaint-boundary'),
          child: shell,
        ),
      ),
    );
  }

  void _legacyPlaneTarget(TimePlane target, {required bool finer}) {
    if (target == widget.navigation.state.plane) return;
    if (finer) {
      widget.onMoveFiner();
    } else {
      widget.onMoveBroader();
    }
  }

  String? _legacyMotherLabel(int offset) {
    if (offset == 0) {
      final state = widget.navigation.state;
      return switch (state.plane) {
        TimePlane.sum => 'Minden időszak',
        TimePlane.year => state.yearCursor.toString(),
        TimePlane.month => DashboardTimeLabelFormatter.yearMonth(
          state.monthCursor,
        ),
      };
    }
    final candidate = widget.horizontalCandidateBuilder(
      offset.isNegative
          ? SummaryTransitionDirection.backward
          : SummaryTransitionDirection.forward,
    );
    return candidate?.subtitle;
  }

  void _legacyMotherOffset(int offset) {
    if (offset.isNegative) {
      widget.onMovePrevious();
    } else {
      widget.onMoveNext();
    }
  }
}

/// The current mother remains the primary label; an open child rail adds its
/// existing live child/context subtitle beneath it. The same bounded region
/// consumes rail ticks, so accepted rail feedback remains paint-only and does
/// not alter the SummaryPill's fixed geometry or either primary gesture zone.
final class _SummaryRailFeedbackSlot extends StatelessWidget {
  const _SummaryRailFeedbackSlot({
    required this.listenable,
    required this.navigation,
    required this.visibleFrames,
    required this.motionController,
    required this.performanceCounters,
  });

  final Listenable listenable;
  final DashboardNavigationController navigation;
  final DashboardVisibleFrameStore visibleFrames;
  final SummaryNavigationMotionController motionController;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: listenable,
    builder: (context, _) {
      performanceCounters?.increment(
        DashboardPerformanceMetric.summaryNavigationTextBuild,
      );
      final state = navigation.state;
      if (!state.isRailOpen) return const SizedBox.shrink();
      final childLabel = _liveChildLabel(state);
      return Semantics(
        key: const ValueKey('dashboard-summary-open-child-feedback-semantics'),
        label: 'Aktív finomítás: $childLabel',
        child: ExcludeSemantics(
          child: SummaryNavigationMotionRegion(
            controller: motionController,
            content: SummaryTextContent(
              title: SummaryNavigationProjector.parentLabel(state),
              subtitle: childLabel,
            ),
            axis: SummaryTransitionAxis.none,
            direction: SummaryTransitionDirection.forward,
            animateAxis: false,
            compact: true,
          ),
        ),
      );
    },
  );

  String _liveChildLabel(DashboardNavigationState state) {
    final visible = visibleFrames.value;
    if (visible != null &&
        visible.parentQueryKey == state.parentQueryKey &&
        visible.navigationEpoch == state.navigationEpoch) {
      return SummaryNavigationProjector.liveRailChildSubtitle(
        plane: visible.plane,
        visibleChildScope: visible.scope.timeScope,
        fallback: visible.childLabel,
      );
    }
    return SummaryNavigationProjector.project(state).subtitle;
  }
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

final class _PreparedAmountSlot extends StatelessWidget {
  const _PreparedAmountSlot({
    required this.visibleFrames,
    required this.performanceCounters,
    required this.onMotionActiveChanged,
  });

  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onMotionActiveChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: visibleFrames.amountLane,
    builder: (context, frame, _) => _PreparedAmountCrossfade(
      frame: frame,
      performanceCounters: performanceCounters,
      onMotionActiveChanged: onMotionActiveChanged,
    ),
  );
}

final class _PreparedAmountCrossfade extends StatefulWidget {
  const _PreparedAmountCrossfade({
    required this.frame,
    required this.performanceCounters,
    required this.onMotionActiveChanged,
  });

  final DashboardVisibleFrame? frame;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onMotionActiveChanged;

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
          return SizedBox(
            width: MediaQuery.sizeOf(context).width * .32,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Opacity(opacity: 1 - value, child: _amountText(_previous!)),
                Opacity(opacity: value, child: _amountText(_current)),
              ],
            ),
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

  Widget _amountText(String value) => Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: FluviVisualTokens.summaryAmountTextStyle,
  );

  @override
  void dispose() {
    widget.onMotionActiveChanged?.call(false);
    _controller.dispose();
    super.dispose();
  }
}

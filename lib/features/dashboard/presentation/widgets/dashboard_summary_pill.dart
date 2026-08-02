import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../time_navigation/application/summary_timing_debug.dart';
import '../../time_navigation/presentation/summary_amount_presentation.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';
import '../../time_navigation/presentation/summary_pill_view_model.dart';
import 'summary_pill_text_transition.dart';

/// Presentation-only summary and time-navigation entry point.
class DashboardSummaryPill extends StatefulWidget {
  const DashboardSummaryPill({
    super.key,
    required this.bounds,
    this.navigationPresentation,
    this.amountPresentation,
    // Kept source-compatible for the original primitive tests/callers.
    this.viewModel,
    this.onToggleRail,
    this.onMoveFiner,
    this.onMoveBroader,
    this.onMovePrevious,
    this.onMoveNext,
    this.isRailVisible,
    this.onChevronTap,
    this.onSelectionHaptic,
  });

  final DashboardBounds bounds;
  final SummaryNavigationPresentation? navigationPresentation;
  final SummaryAmountPresentation? amountPresentation;
  final SummaryPillViewModel? viewModel;
  final VoidCallback? onToggleRail;
  final VoidCallback? onMoveFiner;
  final VoidCallback? onMoveBroader;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onMoveNext;
  final bool? isRailVisible;
  final VoidCallback? onChevronTap;
  final VoidCallback? onSelectionHaptic;

  @override
  State<DashboardSummaryPill> createState() => _DashboardSummaryPillState();
}

class _DashboardSummaryPillState extends State<DashboardSummaryPill>
    with SingleTickerProviderStateMixin {
  static const _touchSlop = 8.0;
  _SummaryGestureAxis? _axis;
  double _dx = 0;
  double _dy = 0;
  Offset _gestureOffset = Offset.zero;
  Offset _returnStartOffset = Offset.zero;
  bool _didEmitThresholdHaptic = false;
  late final AnimationController _returnController;

  @override
  void initState() {
    super.initState();
    _returnController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 125),
        )..addListener(() {
          if (!mounted) return;
          setState(() {
            _gestureOffset = Offset.lerp(
              _returnStartOffset,
              Offset.zero,
              Curves.easeOutCubic.transform(_returnController.value),
            )!;
          });
        });
  }

  SummaryNavigationPresentation get _navigation =>
      widget.navigationPresentation ?? _legacyNavigation;

  SummaryAmountPresentation get _amount =>
      widget.amountPresentation ?? _legacyAmount;

  SummaryNavigationPresentation get _legacyNavigation {
    final model = widget.viewModel;
    return SummaryNavigationPresentation(
      plane: model?.plane ?? TimePlane.month,
      planeTitle: model?.planeLabel ?? 'Havi',
      subtitle: model?.periodLabel ?? 'Aktuális hónap',
      isRailOpen: model?.isRailOpen ?? widget.isRailVisible ?? false,
      revision: 0,
      changeReason: SummaryContentChangeReason.initial,
      direction: SummaryTransitionDirection.forward,
    );
  }

  SummaryAmountPresentation get _legacyAmount {
    final model = widget.viewModel;
    return SummaryAmountPresentation(
      formattedAmount: model?.amountText ?? '0 Ft',
      scopeKey: 'legacy',
      isLoading: model?.isLoading ?? false,
      isStale: model?.isLoading ?? false,
      hasError: model?.hasError ?? false,
    );
  }

  VoidCallback get _toggleRail =>
      widget.onToggleRail ?? widget.onChevronTap ?? () {};

  @override
  Widget build(BuildContext context) {
    final navigation = _navigation;
    final amount = _amount;
    DashboardSummaryTimingDebug.mark(
      navigation.isPreview
          ? 'P3 previewSubtitleBuild'
          : 'S7 summaryPillCommittedSubtitleBuild',
      value: navigation.subtitle,
    );
    final chevron = navigation.isRailOpen
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
    final chevronWidget = navigation.isRailOpen
        ? FluviHighlightMask(
            child: Icon(
              chevron,
              color: Colors.white,
              size: FluviVisualTokens.iconSize,
            ),
          )
        : Icon(
            chevron,
            color: FluviVisualTokens.textSecondary,
            size: FluviVisualTokens.iconSize,
          );

    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _beginGesture(),
        onPanUpdate: _updateGesture,
        onPanEnd: _finishGesture,
        onPanCancel: _cancelGesture,
        child: Transform.translate(
          offset: _gestureOffset,
          child: FluviRoundedBox(
            color: FluviVisualTokens.surface,
            child: Row(
              children: [
                const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: FluviVisualTokens.textSecondary,
                  size: FluviVisualTokens.iconSize,
                ),
                const SizedBox(width: FluviVisualTokens.controlInnerGap),
                Expanded(
                  child: SummaryPillTextTransition(
                    content: SummaryTextContent(
                      title: navigation.planeTitle,
                      subtitle: navigation.subtitle,
                    ),
                    axis: navigation.transitionAxis,
                    direction: navigation.direction,
                    animateTitle: _animatesTitle(navigation.changeReason),
                    compact: _isCompactSubtitleTransition(
                      navigation.changeReason,
                    ),
                  ),
                ),
                _SummaryAmountCrossfade(presentation: amount),
                Semantics(
                  button: true,
                  label: navigation.isRailOpen
                      ? 'Időválasztó bezárása'
                      : 'Időválasztó megnyitása',
                  child: GestureDetector(
                    key: const ValueKey('dashboard-summary-chevron'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleRail,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: chevronWidget,
                    ),
                  ),
                ),
                const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _animatesTitle(SummaryContentChangeReason reason) {
    return reason == SummaryContentChangeReason.verticalPlaneForward ||
        reason == SummaryContentChangeReason.verticalPlaneBackward;
  }

  bool _isCompactSubtitleTransition(SummaryContentChangeReason reason) {
    return reason == SummaryContentChangeReason.railOpened ||
        reason == SummaryContentChangeReason.railClosed ||
        reason == SummaryContentChangeReason.childSettled;
  }

  void _beginGesture() {
    _returnController.stop();
    setState(() {
      _axis = null;
      _dx = 0;
      _dy = 0;
      _gestureOffset = Offset.zero;
      _didEmitThresholdHaptic = false;
    });
  }

  void _updateGesture(DragUpdateDetails details) {
    _dx += details.delta.dx;
    _dy += details.delta.dy;
    _axis ??= _axisFor(_dx, _dy);
    final axis = _axis;
    if (axis == null) return;

    final primaryDistance = axis == _SummaryGestureAxis.vertical ? _dy : _dx;
    final distanceTriggered = primaryDistance.abs() >= 28;
    if (distanceTriggered && !_didEmitThresholdHaptic) {
      _emitSelectionHaptic();
    }

    setState(() {
      _gestureOffset = axis == _SummaryGestureAxis.vertical
          ? Offset(0, (_dy * .10).clamp(-8.0, 8.0))
          : Offset((_dx * .08).clamp(-7.0, 7.0), 0);
    });
  }

  void _finishGesture(DragEndDetails details) {
    final axis = _axis;
    if (axis == null) {
      _animateGestureBack();
      return;
    }

    final primaryDistance = axis == _SummaryGestureAxis.vertical ? _dy : _dx;
    final primaryVelocity = axis == _SummaryGestureAxis.vertical
        ? details.velocity.pixelsPerSecond.dy
        : details.velocity.pixelsPerSecond.dx;
    final shouldCommit =
        primaryDistance.abs() >= 28 || primaryVelocity.abs() >= 360;

    if (!shouldCommit) {
      _animateGestureBack();
      return;
    }

    if (!_didEmitThresholdHaptic) _emitSelectionHaptic();

    final isForward = primaryDistance.abs() >= 28
        ? primaryDistance < 0
        : primaryVelocity < 0;
    final callback = axis == _SummaryGestureAxis.vertical
        ? (isForward ? widget.onMoveFiner : widget.onMoveBroader)
        : (isForward ? widget.onMoveNext : widget.onMovePrevious);

    _resetGestureState();
    callback?.call();
  }

  void _cancelGesture() => _animateGestureBack();

  void _animateGestureBack() {
    _returnStartOffset = _gestureOffset;
    _returnController
      ..value = 0
      ..forward();
    _resetGestureState(keepOffset: true);
  }

  void _resetGestureState({bool keepOffset = false}) {
    setState(() {
      _axis = null;
      _dx = 0;
      _dy = 0;
      if (!keepOffset) _gestureOffset = Offset.zero;
      _didEmitThresholdHaptic = false;
    });
  }

  void _emitSelectionHaptic() {
    if (_didEmitThresholdHaptic) return;
    _didEmitThresholdHaptic = true;
    final callback = widget.onSelectionHaptic;
    if (callback != null) {
      callback();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  _SummaryGestureAxis? _axisFor(double dx, double dy) {
    if (dx.abs() < _touchSlop && dy.abs() < _touchSlop) return null;
    if (dx.abs() > dy.abs() * 1.25) return _SummaryGestureAxis.horizontal;
    if (dy.abs() > dx.abs() * 1.25) return _SummaryGestureAxis.vertical;
    return null;
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }
}

class _SummaryAmountCrossfade extends StatefulWidget {
  const _SummaryAmountCrossfade({required this.presentation});

  final SummaryAmountPresentation presentation;

  @override
  State<_SummaryAmountCrossfade> createState() =>
      _SummaryAmountCrossfadeState();
}

class _SummaryAmountCrossfadeState extends State<_SummaryAmountCrossfade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _current;
  String? _previous;
  String? _lastRenderedDiagnosticKey;

  @override
  void initState() {
    super.initState();
    _current = widget.presentation.formattedAmount;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 120),
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _previous = null);
          }
        });
  }

  @override
  void didUpdateWidget(covariant _SummaryAmountCrossfade oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.presentation.formattedAmount;
    if (next == _current) return;
    _previous = _current;
    _current = next;
    _controller
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    final diagnosticKey = [
      presentation.flowId,
      presentation.scopeKey,
      presentation.coreRevision,
      presentation.totalMinor,
      presentation.formattedAmount,
    ].join('|');
    if (diagnosticKey != _lastRenderedDiagnosticKey) {
      _lastRenderedDiagnosticKey = diagnosticKey;
      DashboardQueryDebug.mark(
        'D10 summaryAmountViewRendered',
        queryKey: presentation.scopeKey,
        flowId: presentation.flowId,
        coreRevision: presentation.coreRevision,
        totalMinor: presentation.totalMinor,
        entryCount: presentation.entryCount,
        formattedTotal: presentation.formattedAmount,
        detail:
            'formatted=${presentation.formattedAmount} '
            'loading=${presentation.isLoading} '
            'stale=${presentation.isStale} '
            'error=${presentation.hasError}',
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: FluviVisualTokens.controlInnerGap),
      child: Opacity(
        opacity: presentation.isStale ? .7 : 1,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeOut.transform(_controller.value);
            if (_previous == null) return _amountText(_current);
            return SizedBox(
              width: _amountWidth(context),
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
      ),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: FluviVisualTokens.summaryAmountTextStyle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _amountWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width * .32;
  }
}

enum _SummaryGestureAxis { horizontal, vertical }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_highlight.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../summary_navigation_motion_controller.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../time_navigation/application/summary_timing_debug.dart';
import '../../time_navigation/presentation/summary_amount_presentation.dart';
import '../../time_navigation/presentation/summary_navigation_presentation.dart';
import '../../time_navigation/presentation/summary_pill_view_model.dart';
import 'summary_navigation_motion_region.dart';
import 'summary_pill_text_transition.dart';

/// Presentation-only summary and time-navigation entry point.
class DashboardSummaryPill extends StatefulWidget {
  const DashboardSummaryPill({
    super.key,
    required this.bounds,
    this.navigationPresentation,
    this.navigationListenable,
    this.navigationPresentationBuilder,
    this.navigationMotionController,
    this.horizontalCandidateBuilder,
    this.amountPresentation,
    this.amountListenable,
    this.amountPresentationBuilder,
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

  /// The rail owns preview state. When supplied, only the navigation text and
  /// chevron listen to it; the amount region stays outside the preview hot
  /// path.
  final Listenable? navigationListenable;
  final SummaryNavigationPresentation Function()? navigationPresentationBuilder;
  final SummaryNavigationMotionController? navigationMotionController;
  final SummaryTextContent? Function(SummaryTransitionDirection direction)?
  horizontalCandidateBuilder;
  final SummaryAmountPresentation? amountPresentation;

  /// Amount has its own presentation owner. It can update from a bounded
  /// child-summary index during rail preview without rebuilding navigation or
  /// the dashboard motion host.
  final Listenable? amountListenable;
  final SummaryAmountPresentation Function()? amountPresentationBuilder;
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
  static const _shellDragFactor = .10;
  static const _maximumShellTravel = 8.0;
  static const _maximumSumResistance = 5.0;
  static const _shellReturnDuration = Duration(milliseconds: 100);

  _SummaryGestureAxis? _axis;
  double _dx = 0;
  double _dy = 0;
  Offset _gestureOffset = Offset.zero;
  Offset _returnStartOffset = Offset.zero;
  bool _didEmitThresholdHaptic = false;
  int _shellGeneration = 0;
  int? _returnShellGeneration;
  int? _stagedTextGeneration;
  bool _returnStartsTextTransition = false;
  late final AnimationController _shellReturnController;
  late final SummaryNavigationMotionController _ownedMotionController;

  SummaryNavigationMotionController get _motionController =>
      widget.navigationMotionController ?? _ownedMotionController;

  @override
  void initState() {
    super.initState();
    _ownedMotionController = SummaryNavigationMotionController();
    _shellReturnController =
        AnimationController(vsync: this, duration: _shellReturnDuration)
          ..addListener(_handleShellReturnTick)
          ..addStatusListener(_handleShellReturnStatus);
  }

  void _handleShellReturnTick() {
    if (!mounted) return;
    setState(() {
      _gestureOffset = Offset.lerp(
        _returnStartOffset,
        Offset.zero,
        Curves.easeOutCubic.transform(_shellReturnController.value),
      )!;
    });
  }

  void _handleShellReturnStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final shellGeneration = _returnShellGeneration;
    if (shellGeneration == null || shellGeneration != _shellGeneration) {
      return;
    }

    final stagedTextGeneration = _stagedTextGeneration;
    final startsTextTransition = _returnStartsTextTransition;
    setState(() => _gestureOffset = Offset.zero);
    _returnShellGeneration = null;
    _stagedTextGeneration = null;
    _returnStartsTextTransition = false;

    if (startsTextTransition && stagedTextGeneration != null) {
      _motionController.completeShellReturn(generation: stagedTextGeneration);
    }
  }

  SummaryNavigationPresentation get _navigation =>
      widget.navigationPresentationBuilder?.call() ??
      widget.navigationPresentation ??
      _legacyNavigation;

  SummaryAmountPresentation get _amount =>
      widget.amountPresentationBuilder?.call() ??
      widget.amountPresentation ??
      _legacyAmount;

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
          key: const ValueKey('dashboard-summary-shell-transform'),
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
                  child: _SummaryNavigationTextSlot(
                    listenable: widget.navigationListenable,
                    navigation: _readNavigation,
                    motionController: _motionController,
                    horizontalCandidateBuilder:
                        widget.horizontalCandidateBuilder,
                  ),
                ),
                _SummaryAmountSlot(
                  listenable: widget.amountListenable,
                  amount: _readAmount,
                ),
                _SummaryNavigationChevronSlot(
                  listenable: widget.navigationListenable,
                  navigation: _readNavigation,
                  onTap: _toggleRail,
                ),
                const SizedBox(width: FluviVisualTokens.controlHorizontalInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SummaryNavigationPresentation _readNavigation() => _navigation;

  SummaryAmountPresentation _readAmount() => _amount;

  void _beginGesture() {
    _shellReturnController.stop();
    _shellGeneration += 1;
    _returnShellGeneration = null;
    _stagedTextGeneration = null;
    _returnStartsTextTransition = false;
    _motionController.cancelStagedTextMotion();
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
    final isForward = primaryDistance < 0;
    final direction = isForward
        ? SummaryTransitionDirection.forward
        : SummaryTransitionDirection.backward;
    final horizontalCandidate = axis == _SummaryGestureAxis.horizontal
        ? widget.horizontalCandidateBuilder?.call(direction)
        : null;
    final canNavigate = axis == _SummaryGestureAxis.horizontal
        ? _canNavigateHorizontally(horizontalCandidate)
        : false;
    final distanceTriggered = primaryDistance.abs() >= 28;
    if (distanceTriggered &&
        !_didEmitThresholdHaptic &&
        (axis == _SummaryGestureAxis.vertical || canNavigate)) {
      _emitSelectionHaptic();
    }

    if (axis == _SummaryGestureAxis.horizontal) {
      final maximumTravel = canNavigate
          ? _maximumShellTravel
          : _maximumSumResistance;
      setState(() {
        _gestureOffset = Offset(
          (_dx * _shellDragFactor)
              .clamp(-maximumTravel, maximumTravel)
              .toDouble(),
          0,
        );
      });
      return;
    }

    setState(() {
      _gestureOffset = Offset(
        0,
        (_dy * _shellDragFactor)
            .clamp(-_maximumShellTravel, _maximumShellTravel)
            .toDouble(),
      );
    });
  }

  void _finishGesture(DragEndDetails details) {
    final axis = _axis;
    if (axis == null) {
      _startShellReturn();
      return;
    }

    final primaryDistance = axis == _SummaryGestureAxis.vertical ? _dy : _dx;
    final primaryVelocity = axis == _SummaryGestureAxis.vertical
        ? details.velocity.pixelsPerSecond.dy
        : details.velocity.pixelsPerSecond.dx;
    final shouldCommit =
        primaryDistance.abs() >= 28 || primaryVelocity.abs() >= 360;

    final isForward = primaryDistance.abs() >= 28
        ? primaryDistance < 0
        : primaryVelocity < 0;
    final direction = isForward
        ? SummaryTransitionDirection.forward
        : SummaryTransitionDirection.backward;

    if (axis == _SummaryGestureAxis.horizontal) {
      final candidate = widget.horizontalCandidateBuilder?.call(direction);
      final canNavigate = _canNavigateHorizontally(candidate);
      if (!shouldCommit || !canNavigate) {
        DashboardSummaryTimingDebug.mark(
          'S-HORIZONTAL',
          value:
              'direction=${direction.name} '
              'from=${_navigation.subtitle} '
              'to=${candidate?.subtitle ?? '-'} committed=false',
        );
        _startShellReturn();
        return;
      }

      if (!_didEmitThresholdHaptic) _emitSelectionHaptic();
      DashboardSummaryTimingDebug.mark(
        'S-HORIZONTAL',
        value:
            'direction=${direction.name} '
            'from=${_navigation.subtitle} '
            'to=${candidate?.subtitle ?? '-'} committed=true',
      );
      _commitWithShellReturn(
        axis: SummaryTransitionAxis.horizontal,
        direction: direction,
        onCommit: isForward ? widget.onMoveNext : widget.onMovePrevious,
      );
      return;
    }

    if (!shouldCommit) {
      _startShellReturn();
      return;
    }

    if (!_didEmitThresholdHaptic) _emitSelectionHaptic();
    _commitWithShellReturn(
      axis: SummaryTransitionAxis.vertical,
      direction: direction,
      onCommit: isForward ? widget.onMoveFiner : widget.onMoveBroader,
    );
  }

  void _cancelGesture() {
    _startShellReturn();
  }

  void _commitWithShellReturn({
    required SummaryTransitionAxis axis,
    required SummaryTransitionDirection direction,
    required VoidCallback? onCommit,
  }) {
    final generation = _motionController.holdTextForShellReturn(
      outgoing: _textContent(_navigation),
      axis: axis,
      direction: direction,
    );

    // Navigation and its query path commit synchronously in the release turn.
    // The following shell/text choreography is presentation-only and never
    // awaits this callback.
    onCommit?.call();
    _motionController.bindShellReturnIncoming(
      generation: generation,
      incoming: _textContent(_navigation),
    );
    _startShellReturn(stagedTextGeneration: generation);
  }

  SummaryTextContent _textContent(SummaryNavigationPresentation presentation) =>
      SummaryTextContent(
        title: presentation.planeTitle,
        subtitle: presentation.subtitle,
      );

  void _startShellReturn({int? stagedTextGeneration}) {
    _returnStartOffset = _gestureOffset;
    final shellGeneration = _shellGeneration;
    setState(() {
      _axis = null;
      _dx = 0;
      _dy = 0;
      _didEmitThresholdHaptic = false;
      _returnShellGeneration = shellGeneration;
      _stagedTextGeneration = stagedTextGeneration;
      _returnStartsTextTransition = stagedTextGeneration != null;
    });
    _shellReturnController
      ..value = 0
      ..forward();
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

  /// Production navigation supplies a pure candidate builder so the drag can
  /// render the incoming text. Older primitive callers only supply movement
  /// callbacks; keep their non-SUM horizontal navigation semantics intact.
  bool _canNavigateHorizontally(SummaryTextContent? candidate) =>
      candidate != null ||
      (widget.horizontalCandidateBuilder == null &&
          _navigation.plane != TimePlane.sum);

  _SummaryGestureAxis? _axisFor(double dx, double dy) {
    if (dx.abs() < _touchSlop && dy.abs() < _touchSlop) return null;
    if (dx.abs() > dy.abs() * 1.25) return _SummaryGestureAxis.horizontal;
    if (dy.abs() > dx.abs() * 1.25) return _SummaryGestureAxis.vertical;
    return null;
  }

  @override
  void dispose() {
    _shellReturnController.dispose();
    _ownedMotionController.dispose();
    super.dispose();
  }
}

/// The only summary subtree rebuilt for a rail preview. Keeping this separate
/// from [_SummaryAmountCrossfade] prevents a high-frequency carousel preview
/// from touching amount layout, amount animation, or amount diagnostics.
class _SummaryNavigationTextSlot extends StatelessWidget {
  const _SummaryNavigationTextSlot({
    required this.listenable,
    required this.navigation,
    required this.motionController,
    required this.horizontalCandidateBuilder,
  });

  final Listenable? listenable;
  final SummaryNavigationPresentation Function() navigation;
  final SummaryNavigationMotionController motionController;
  final SummaryTextContent? Function(SummaryTransitionDirection direction)?
  horizontalCandidateBuilder;

  @override
  Widget build(BuildContext context) {
    final source = listenable;
    if (source == null) return _buildText(navigation());
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) => _buildText(navigation()),
    );
  }

  Widget _buildText(SummaryNavigationPresentation presentation) {
    DashboardSummaryTimingDebug.mark(
      presentation.isPreview
          ? 'P3 previewSubtitleBuild'
          : 'S7 summaryPillCommittedSubtitleBuild',
      value: presentation.subtitle,
    );
    return SummaryNavigationMotionRegion(
      controller: motionController,
      content: SummaryTextContent(
        title: presentation.planeTitle,
        subtitle: presentation.subtitle,
      ),
      axis: presentation.transitionAxis,
      direction: presentation.direction,
      horizontalCandidateBuilder: horizontalCandidateBuilder,
      animateAxis:
          !presentation.isPreview &&
          (presentation.changeReason ==
                  SummaryContentChangeReason.verticalPlaneForward ||
              presentation.changeReason ==
                  SummaryContentChangeReason.verticalPlaneBackward ||
              presentation.changeReason ==
                  SummaryContentChangeReason.horizontalParentForward ||
              presentation.changeReason ==
                  SummaryContentChangeReason.horizontalParentBackward),
      animateTitle:
          presentation.changeReason ==
              SummaryContentChangeReason.verticalPlaneForward ||
          presentation.changeReason ==
              SummaryContentChangeReason.verticalPlaneBackward ||
          presentation.changeReason ==
              SummaryContentChangeReason.horizontalParentForward ||
          presentation.changeReason ==
              SummaryContentChangeReason.horizontalParentBackward,
      compact:
          presentation.changeReason == SummaryContentChangeReason.railOpened ||
          presentation.changeReason == SummaryContentChangeReason.railClosed ||
          presentation.changeReason == SummaryContentChangeReason.childSettled,
    );
  }
}

class _SummaryNavigationChevronSlot extends StatelessWidget {
  const _SummaryNavigationChevronSlot({
    required this.listenable,
    required this.navigation,
    required this.onTap,
  });

  final Listenable? listenable;
  final SummaryNavigationPresentation Function() navigation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = listenable;
    if (source == null) return _buildChevron(navigation());
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) => _buildChevron(navigation()),
    );
  }

  Widget _buildChevron(SummaryNavigationPresentation presentation) {
    final chevron = presentation.isRailOpen
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
    final icon = presentation.isRailOpen
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
    return Semantics(
      button: true,
      label: presentation.isRailOpen
          ? 'Időválasztó bezárása'
          : 'Időválasztó megnyitása',
      child: GestureDetector(
        key: const ValueKey('dashboard-summary-chevron'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(4), child: icon),
      ),
    );
  }
}

class _SummaryAmountSlot extends StatelessWidget {
  const _SummaryAmountSlot({required this.listenable, required this.amount});

  final Listenable? listenable;
  final SummaryAmountPresentation Function() amount;

  @override
  Widget build(BuildContext context) {
    final source = listenable;
    if (source == null) {
      return _SummaryAmountCrossfade(presentation: amount());
    }
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) => _SummaryAmountCrossfade(presentation: amount()),
    );
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
  late SummaryAmountPresentation _currentPresentation;
  SummaryAmountPresentation? _previousPresentation;
  String? _lastStateDiagnosticKey;
  int _transitionGeneration = 0;
  int _activeTransitionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.presentation.formattedAmount;
    _currentPresentation = widget.presentation;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 120),
          value: 1,
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed || !mounted) return;
          final generation = _activeTransitionGeneration;
          if (generation != _transitionGeneration) return;
          final previous = _previousPresentation;
          final current = _currentPresentation;
          DashboardQueryDebug.mark(
            'D10D AMOUNT_TRANSITION_COMPLETED',
            queryKey: current.scopeKey,
            flowId: current.flowId,
            coreRevision: current.coreRevision,
            totalMinor: current.totalMinor,
            entryCount: current.entryCount,
            formattedTotal: current.formattedAmount,
            detail: _transitionDetail(
              previous: previous,
              target: current,
              displayed: current,
            ),
          );
          setState(() {
            _previous = null;
            _previousPresentation = null;
          });
        });
    if (!_currentPresentation.isPreview) {
      _scheduleStateBoundDiagnostic(
        previous: null,
        target: _currentPresentation,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _SummaryAmountCrossfade oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.presentation;
    final previousPresentation = _currentPresentation;
    if (_mustReplaceImmediately(previousPresentation, target)) {
      // The centered rail can cross several items in one fling. Keep that
      // hot path to one text replacement. A scope transition also represents
      // an active pill/rail interaction, so it must not leave an old amount in
      // a competing 120-ms crossfade while the new scope is already selected.
      if (!target.isPreview) {
        _scheduleStateBoundDiagnostic(
          previous: previousPresentation,
          target: target,
        );
      }
      _replaceImmediately(target);
      return;
    }
    _scheduleStateBoundDiagnostic(
      previous: previousPresentation,
      target: target,
    );
    final next = target.formattedAmount;
    if (next != _current) {
      final transitionGeneration = ++_transitionGeneration;
      _previous = _current;
      _previousPresentation = previousPresentation;
      _current = next;
      _currentPresentation = target;
      _activeTransitionGeneration = transitionGeneration;
      _controller
        ..stop()
        ..value = 0
        ..forward();
      DashboardQueryDebug.mark(
        'D10B AMOUNT_TRANSITION_STARTED',
        queryKey: target.scopeKey,
        flowId: target.flowId,
        coreRevision: target.coreRevision,
        totalMinor: target.totalMinor,
        entryCount: target.entryCount,
        formattedTotal: target.formattedAmount,
        detail: _transitionDetail(
          previous: previousPresentation,
          target: target,
          displayed: previousPresentation,
        ),
      );
      _scheduleFirstFramePaint(
        generation: transitionGeneration,
        previous: previousPresentation,
        target: target,
      );
      return;
    }
    _currentPresentation = target;
  }

  bool _mustReplaceImmediately(
    SummaryAmountPresentation previous,
    SummaryAmountPresentation target,
  ) =>
      target.isPreview ||
      target.isStale ||
      previous.isStale ||
      target.scopeKey != previous.scopeKey;

  void _replaceImmediately(SummaryAmountPresentation target) {
    _transitionGeneration += 1;
    _activeTransitionGeneration = _transitionGeneration;
    _controller
      ..stop()
      ..reset();
    _previous = null;
    _previousPresentation = null;
    _current = target.formattedAmount;
    _currentPresentation = target;
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    return Padding(
      padding: const EdgeInsets.only(right: FluviVisualTokens.controlInnerGap),
      child: Opacity(
        opacity: presentation.isStale ? .7 : 1,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeOutCubic.transform(_controller.value);
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

  void _scheduleStateBoundDiagnostic({
    required SummaryAmountPresentation? previous,
    required SummaryAmountPresentation target,
  }) {
    final presentation = target;
    final diagnosticKey = [
      presentation.flowId,
      presentation.scopeKey,
      presentation.coreRevision,
      presentation.totalMinor,
      presentation.entryCount,
      presentation.formattedAmount,
      presentation.isLoading,
      presentation.isStale,
      presentation.hasError,
    ].join('|');
    if (diagnosticKey == _lastStateDiagnosticKey) return;
    _lastStateDiagnosticKey = diagnosticKey;
    DashboardQueryDebug.mark(
      'D10A AMOUNT_STATE_BOUND',
      queryKey: presentation.scopeKey,
      flowId: presentation.flowId,
      coreRevision: presentation.coreRevision,
      totalMinor: presentation.totalMinor,
      entryCount: presentation.entryCount,
      formattedTotal: presentation.formattedAmount,
      detail: _transitionDetail(
        previous: previous,
        target: presentation,
        displayed: _currentPresentation,
      ),
    );
  }

  void _scheduleFirstFramePaint({
    required int generation,
    required SummaryAmountPresentation previous,
    required SummaryAmountPresentation target,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _transitionGeneration) return;
      DashboardQueryDebug.mark(
        'D10C AMOUNT_FIRST_FRAME_PAINTED',
        queryKey: target.scopeKey,
        flowId: target.flowId,
        coreRevision: target.coreRevision,
        totalMinor: target.totalMinor,
        entryCount: target.entryCount,
        formattedTotal: target.formattedAmount,
        detail: _transitionDetail(
          previous: previous,
          target: target,
          displayed: target,
        ),
      );
    });
  }

  static String _transitionDetail({
    required SummaryAmountPresentation? previous,
    required SummaryAmountPresentation target,
    required SummaryAmountPresentation? displayed,
  }) =>
      'previousAmount=${previous?.totalMinor ?? '-'} '
      'targetAmount=${target.totalMinor ?? '-'} '
      'displayedAmount=${displayed?.totalMinor ?? '-'} '
      'durationMs=120 loading=${target.isLoading} stale=${target.isStale}';

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

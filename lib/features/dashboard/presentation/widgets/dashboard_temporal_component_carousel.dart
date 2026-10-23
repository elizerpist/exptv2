import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_segmented_target_acceptance.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../dashboard_summary_presentation.dart';
import '../dashboard_summary_auto_reset_controller.dart';

typedef DashboardTemporalCarouselVisualBuilder =
    Widget Function(
      BuildContext context,
      DashboardTemporalCarouselVisualState state,
    );

@immutable
final class DashboardTemporalCarouselVisualState {
  const DashboardTemporalCarouselVisualState({
    required this.controller,
    required this.rawIndex,
    required this.isMoving,
    required this.origin,
    this.isFollowing = false,
  });
  final bool isFollowing;
  final Listenable controller;
  final double rawIndex;
  final bool isMoving;
  final DashboardNavigationState origin;
}

enum DashboardTemporalMotionSource { summaryPill, balanceRhythm }

/// Logical navigation feedback only. Rich financial scenes remain Core-owned.
@immutable
final class DashboardTemporalDayVisualMotion {
  const DashboardTemporalDayVisualMotion({
    required this.origin,
    required this.rawIndex,
    required this.isMoving,
    required this.source,
    required this.generation,
    this.acceptedTarget,
  });
  final DashboardNavigationState origin;
  final double rawIndex;
  final bool isMoving;
  final DashboardTemporalMotionSource source;
  final int generation;
  final DashboardNavigationState? acceptedTarget;
}

/// One physical producer, two axis-specific renderers. Followers never drive a
/// controller, acquire a Core motion lane, or emit semantic crossings.
final class DashboardTemporalCarouselCoordinator extends ChangeNotifier {
  final Map<Object, VoidCallback> _cancellers = {};
  int _motionEpoch = 0;
  bool _disposed = false;
  Object? _activeOwner;
  DashboardTemporalDayVisualMotion? _dayVisualMotion;
  int get motionEpoch => _motionEpoch;
  Object? get activeOwner => _activeOwner;
  DashboardTemporalDayVisualMotion? get dayVisualMotion => _dayVisualMotion;
  int noteMotionStarted() => ++_motionEpoch;
  void attach(Object owner, VoidCallback cancel) => _cancellers[owner] = cancel;
  void detach(Object owner) {
    _cancellers.remove(owner);
    if (identical(_activeOwner, owner)) {
      _activeOwner = null;
      _dayVisualMotion = null;
      // Unmount can occur in a layout/settings build. Reconcile the surviving
      // follower on the next frame, without notifying during that build or
      // overriding a newer physical producer.
      final generation = _motionEpoch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && generation == _motionEpoch && _activeOwner == null) {
          notifyListeners();
        }
      });
    }
  }

  void preemptAll() => claim(this);
  void claim(Object owner) {
    _motionEpoch += 1;
    _activeOwner = owner;
    _dayVisualMotion = null;
    for (final entry in _cancellers.entries.toList()) {
      if (!identical(entry.key, owner)) entry.value();
    }
    notifyListeners();
  }

  void publishDayMotion(Object owner, DashboardTemporalDayVisualMotion frame) {
    if (!identical(_activeOwner, owner) || frame.generation != _motionEpoch) {
      return;
    }
    _dayVisualMotion = frame;
    notifyListeners();
  }

  void finishDayMotion(
    Object owner,
    int generation, {
    DashboardNavigationState? acceptedTarget,
    double? acceptedOffset,
  }) {
    if (!identical(_activeOwner, owner) || generation != _motionEpoch) return;
    final previous = _dayVisualMotion;
    _dayVisualMotion = previous == null || acceptedTarget == null
        ? null
        : DashboardTemporalDayVisualMotion(
            origin: previous.origin,
            rawIndex: acceptedOffset ?? previous.rawIndex,
            isMoving: false,
            source: previous.source,
            generation: generation,
            acceptedTarget: acceptedTarget,
          );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancellers.clear();
    super.dispose();
  }
}

final class DashboardTemporalComponentCarousel extends StatefulWidget {
  const DashboardTemporalComponentCarousel({
    super.key,
    required this.height,
    required this.visualContentOffset,
    required this.navigation,
    required this.semanticsLabel,
    required this.candidateForOffset,
    required this.labelForCandidate,
    required this.onCrossed,
    this.paintedTargets,
    this.onVisualTargetPainted,
    this.onSettled,
    required this.presentation,
    required this.component,
    this.onMotionActiveChanged,
    this.autoResetMotionRegistry,
    this.onDirectInputStarted,
    this.onPointerDownDecision,
    this.motionDiagnostics,
    this.scrollDirection = Axis.vertical,
    this.itemExtent,
    this.visibleItemCount = 1,
    this.visualBuilder,
    this.coordinator,
    this.releaseMotionOnDispose = false,
    this.motionSource = DashboardTemporalMotionSource.summaryPill,
  });

  final DashboardTemporalMotionSource motionSource;
  final bool releaseMotionOnDispose;
  final Axis scrollDirection;
  final double? itemExtent;
  final int visibleItemCount;
  final DashboardTemporalCarouselVisualBuilder? visualBuilder;
  final DashboardTemporalCarouselCoordinator? coordinator;
  final double height;
  final double visualContentOffset;
  final DashboardNavigationController navigation;
  final String semanticsLabel;
  final DashboardNavigationState? Function(
    DashboardNavigationState origin,
    int offset,
  )
  candidateForOffset;
  final String Function(DashboardNavigationState candidate) labelForCandidate;
  final DashboardSegmentedTargetAcceptance Function(
    DashboardNavigationState candidate,
  )
  onCrossed;
  final ValueListenable<DashboardSegmentedTargetPainted?>? paintedTargets;
  final ValueChanged<DashboardNavigationState>? onVisualTargetPainted;
  final ValueChanged<DashboardNavigationState>? onSettled;
  final SummaryTemporalFlingPresentation presentation;
  final DashboardTemporalAnchorComponent component;
  final ValueChanged<bool>? onMotionActiveChanged;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final VoidCallback? onDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onPointerDownDecision;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;

  @override
  State<DashboardTemporalComponentCarousel> createState() =>
      DashboardTemporalComponentCarouselState();
}

final class DashboardTemporalComponentCarouselState
    extends State<DashboardTemporalComponentCarousel> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: 0);
  late final DashboardSummaryAutoResetMotionRunner _resetRunner = _runResetStep;
  late final VoidCallback _resetCanceller = _cancelResetMotion;
  DashboardNavigationState? _motionOrigin;
  DashboardNavigationState? _currentSemanticTarget;
  DashboardNavigationState? _lastEmittedTarget;
  DashboardNavigationState? _latestDesiredTarget;
  DashboardNavigationState? _latestAcceptedTarget;
  DashboardNavigationState? _latestPaintSelectedTarget;
  DashboardNavigationState? _settleTarget;
  DashboardSummaryAutoResetMotionRegistry? _attachedRegistry;
  var _rebaseAfterDirectPreemption = false;
  var _visualTargetFrameEpoch = 0;
  var _motionIdle = false;
  var _ownsActiveMotion = false;
  var _preemptedUntilDirectPointer = false;
  int? _ownedMotionEpoch;
  int? _latestAcceptedOffset;

  Listenable get _visualChanges => Listenable.merge([
    _controller,
    widget.navigation,
    if (widget.coordinator != null) widget.coordinator!,
  ]);

  @visibleForTesting
  DashboardTemporalCarouselVisualState get visualState {
    final frame = widget.component == DashboardTemporalAnchorComponent.day
        ? widget.coordinator?.dayVisualMotion
        : null;
    final follows =
        frame != null && !identical(widget.coordinator?.activeOwner, this);
    if (frame != null &&
        (frame.origin.parentQueryKey !=
                widget.navigation.state.parentQueryKey ||
            frame.origin.plane != widget.navigation.state.plane ||
            frame.origin.isRailOpen != widget.navigation.state.isRailOpen ||
            frame.origin.monthCursor != widget.navigation.state.monthCursor)) {
      return DashboardTemporalCarouselVisualState(
        controller: _visualChanges,
        rawIndex: 0,
        isMoving: false,
        origin: widget.navigation.state,
      );
    }
    // An idle preview can wait for exact Core publication. Once its accepted
    // canonical day is installed, render from that canonical origin at zero.
    final useFrame =
        frame != null &&
        (frame.isMoving ||
            (frame.acceptedTarget != null &&
                !_sameOwnedSemanticTarget(
                  frame.acceptedTarget,
                  widget.navigation.state,
                )));
    if (frame != null && !useFrame) {
      return DashboardTemporalCarouselVisualState(
        controller: _visualChanges,
        rawIndex: 0,
        isMoving: false,
        origin: widget.navigation.state,
      );
    }
    return DashboardTemporalCarouselVisualState(
      controller: _visualChanges,
      rawIndex: useFrame
          ? frame.rawIndex
          : _preemptedUntilDirectPointer
          ? 0
          : _controller.rawCenteredLogicalIndex,
      isMoving: useFrame
          ? frame.isMoving
          : !_preemptedUntilDirectPointer &&
                _controller.hasActiveScrollActivity,
      origin: useFrame
          ? frame.origin
          : _motionOrigin ?? widget.navigation.state,
      isFollowing: useFrame && follows,
    );
  }

  void _publishPhysicalDayMotion() {
    if (!_ownsActiveMotion ||
        _preemptedUntilDirectPointer ||
        widget.component != DashboardTemporalAnchorComponent.day ||
        _motionOrigin == null ||
        _ownedMotionEpoch == null) {
      return;
    }
    widget.coordinator?.publishDayMotion(
      this,
      DashboardTemporalDayVisualMotion(
        origin: _motionOrigin!,
        rawIndex: _controller.rawCenteredLogicalIndex,
        isMoving: true,
        source: widget.motionSource,
        generation: _ownedMotionEpoch!,
        acceptedTarget: _latestAcceptedTarget,
      ),
    );
  }

  DashboardSummaryAutoResetStepKind get _resetStepKind =>
      switch (widget.component) {
        DashboardTemporalAnchorComponent.year =>
          DashboardSummaryAutoResetStepKind.year,
        DashboardTemporalAnchorComponent.month =>
          DashboardSummaryAutoResetStepKind.month,
        DashboardTemporalAnchorComponent.day => throw StateError(
          'DAY is never a Summary reset target.',
        ),
      };

  @override
  void initState() {
    super.initState();
    _attachResetRunner();
    _controller.addListener(_publishPhysicalDayMotion);
    widget.coordinator?.attach(this, _preemptFromOtherSurface);
    widget.paintedTargets?.addListener(_onPaintedTargetChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardTemporalComponentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.coordinator, widget.coordinator)) {
      oldWidget.coordinator?.detach(this);
      widget.coordinator?.attach(this, _preemptFromOtherSurface);
    }
    if (!identical(
      oldWidget.autoResetMotionRegistry,
      widget.autoResetMotionRegistry,
    )) {
      _detachResetRunner(oldWidget.autoResetMotionRegistry);
      _attachResetRunner();
    }
    if (!identical(oldWidget.paintedTargets, widget.paintedTargets)) {
      oldWidget.paintedTargets?.removeListener(_onPaintedTargetChanged);
      widget.paintedTargets?.addListener(_onPaintedTargetChanged);
    }
  }

  void _preemptFromOtherSurface() {
    _ownsActiveMotion = false;
    _preemptedUntilDirectPointer = true;
    _clearMotionTargets();
    _controller.interruptAndJumpToIndexSilently(0);
    _rebaseAfterDirectPreemption = false;
    widget.onMotionActiveChanged?.call(false);
  }

  void _onPaintedTargetChanged() {
    final painted = widget.paintedTargets?.value;
    if (painted == null || painted.component != widget.component) return;
    if (!_sameOwnedSemanticTarget(_latestAcceptedTarget, painted.target) ||
        !_sameOwnedSemanticTarget(_latestPaintSelectedTarget, painted.target)) {
      return;
    }
    // Rich paint is Phase-B evidence only.  It may enrich diagnostics, but a
    // delayed/failed scene must not replace the latest accepted month as the
    // release target.
  }

  void _clearMotionTargets() {
    _visualTargetFrameEpoch += 1;
    _currentSemanticTarget = null;
    _lastEmittedTarget = null;
    _latestDesiredTarget = null;
    _latestAcceptedTarget = null;
    _latestAcceptedOffset = null;
    _latestPaintSelectedTarget = null;
    _settleTarget = null;
    _motionOrigin = null;
    _motionIdle = false;
  }

  void _scheduleVisualTargetPaint(DashboardNavigationState target) {
    final scheduledEpoch = ++_visualTargetFrameEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          scheduledEpoch != _visualTargetFrameEpoch ||
          !_sameOwnedSemanticTarget(_latestAcceptedTarget, target)) {
        return;
      }
      widget.onVisualTargetPainted?.call(target);
    });
  }

  /// Core synchronously promotes the last accepted semantic target when a
  /// replacement pointer preempts a Time flight. The carousel's physical
  /// logical offset still belongs to the old gesture at that exact boundary.
  /// Keep the existing controller/position/physics, but structurally recenter
  /// it after Core has promoted the semantic origin and before a new gesture
  /// can snapshot that origin.
  void _rebaseAfterCoreDirectPreemption() {
    if (!_rebaseAfterDirectPreemption) return;
    _rebaseAfterDirectPreemption = false;
    _controller.interruptAndJumpToIndexSilently(0);
  }

  bool _trySettleAcceptedTarget() {
    if (!_motionIdle) return false;
    final settled = _settleTarget;
    if (settled == null ||
        !_sameOwnedSemanticTarget(_lastEmittedTarget, settled) ||
        !_sameOwnedSemanticTarget(_latestDesiredTarget, settled) ||
        !_sameOwnedSemanticTarget(_latestAcceptedTarget, settled)) {
      return false;
    }
    widget.onSettled?.call(settled);
    _clearMotionTargets();
    return true;
  }

  void _attachResetRunner() {
    final registry = widget.autoResetMotionRegistry;
    if (registry == null ||
        widget.component == DashboardTemporalAnchorComponent.day) {
      return;
    }
    _attachedRegistry = registry;
    registry.attach(
      kind: _resetStepKind,
      runner: _resetRunner,
      cancelMotion: _resetCanceller,
    );
  }

  void _detachResetRunner(DashboardSummaryAutoResetMotionRegistry? registry) {
    if (widget.component != DashboardTemporalAnchorComponent.day) {
      registry?.detach(
        kind: _resetStepKind,
        runner: _resetRunner,
        cancelMotion: _resetCanceller,
      );
    }
    if (identical(_attachedRegistry, registry)) _attachedRegistry = null;
  }

  Future<void> _runResetStep(DashboardSummaryAutoResetStep step) async {
    if (step.kind != _resetStepKind || step.targetValue == null) return;
    if (widget.component == DashboardTemporalAnchorComponent.day) return;
    final current = switch (widget.component) {
      DashboardTemporalAnchorComponent.year =>
        widget.navigation.state.yearCursor,
      DashboardTemporalAnchorComponent.month =>
        widget.navigation.state.monthCursor.month,
      DashboardTemporalAnchorComponent.day => 0,
    };
    final offset = switch (widget.component) {
      DashboardTemporalAnchorComponent.month => _shortestMonthOffset(
        current: current,
        target: step.targetValue!,
      ),
      DashboardTemporalAnchorComponent.year => _shortestYearOffset(
        current: current,
        target: step.targetValue!,
      ),
      DashboardTemporalAnchorComponent.day => 0,
    };
    if (offset == 0) return;
    await _controller.animateToIndex(
      offset,
      duration: Duration(milliseconds: 95 * offset.abs().clamp(1, 6).toInt()),
      curve: Curves.easeOutCubic,
    );
  }

  void _cancelResetMotion() => _controller.jumpToIndexSilently(0);

  int _shortestMonthOffset({required int current, required int target}) {
    final values =
        widget.navigation.temporalAvailability.monthsForYear(
          widget.navigation.state.yearCursor,
        ) ??
        List<int>.generate(12, (index) => index + 1);
    final currentIndex = values.indexOf(current);
    final targetIndex = values.indexOf(target);
    if (currentIndex < 0 || targetIndex < 0) return 0;
    final forward = (targetIndex - currentIndex) % values.length;
    return forward > values.length / 2 ? forward - values.length : forward;
  }

  int _shortestYearOffset({required int current, required int target}) {
    final values = widget.navigation.temporalAvailability.allowedYears;
    if (values == null) return target - current;
    final currentIndex = values.indexOf(current);
    final targetIndex = values.indexOf(target);
    if (currentIndex < 0 || targetIndex < 0) return 0;
    final forward = (targetIndex - currentIndex) % values.length;
    return forward > values.length / 2 ? forward - values.length : forward;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CenteredCarousel<int>(
          dataSource: GeneratedCarouselDataSource<int>((index) => index),
          controller: _controller,
          spec: CenteredCarouselSpec(
            itemExtent: widget.itemExtent ?? widget.height,
            scrollDirection: widget.scrollDirection,
            visibleItemCount: widget.visibleItemCount,
            minScale: 1,
            neighborScale: 1,
            outerScale: 1,
            minOpacity: 1,
            neighborOpacity: 1,
            outerOpacity: 1,
            enableHaptics: true,
          ),
          height: widget.height,
          viewportKey: ValueKey<String>('${widget.key}-viewport'),
          motionDiagnostics: widget.motionDiagnostics,
          onDirectPointerDown: () {
            widget.onDirectInputStarted?.call();
            widget.coordinator?.claim(this);
            _preemptedUntilDirectPointer = false;
            _rebaseAfterCoreDirectPreemption();
          },
          onPointerDownDecision: widget.onPointerDownDecision,
          onMotionStarted: (origin) {
            if (_preemptedUntilDirectPointer) return;
            _ownsActiveMotion = true;
            _ownedMotionEpoch = widget.coordinator?.noteMotionStarted();
            final semanticOrigin = widget.navigation.state;
            _motionOrigin = semanticOrigin;
            _currentSemanticTarget = semanticOrigin;
            _lastEmittedTarget = null;
            _latestDesiredTarget = null;
            _latestAcceptedTarget = null;
            _latestPaintSelectedTarget = null;
            _settleTarget = null;
            _motionIdle = false;
            widget.onMotionActiveChanged?.call(true);
            _publishPhysicalDayMotion();
          },
          onMotionInterrupted: () {
            _ownsActiveMotion = false;
            _clearMotionTargets();
            _rebaseAfterDirectPreemption = true;
            widget.onMotionActiveChanged?.call(false);
          },
          onSelectedChanged: (offset) {
            if (_preemptedUntilDirectPointer) return;
            final origin = _motionOrigin ?? widget.navigation.state;
            final candidate = widget.candidateForOffset(origin, offset);
            if (candidate == null ||
                _sameOwnedSemanticTarget(_currentSemanticTarget, candidate)) {
              return;
            }
            _currentSemanticTarget = candidate;
            _lastEmittedTarget = candidate;
            _latestDesiredTarget = candidate;
            final acceptance = widget.onCrossed(candidate);
            if (!acceptance.isAcceptedSemanticIntent) return;
            // An exact target has synchronously entered the shared visible
            // lane. A cold target remains the latest physical semantic intent
            // but Core retains the old valid visible frame until its exact
            // painter resource binds. In both cases an emitted/rejected
            // candidate cannot own release settlement.
            _latestAcceptedTarget = candidate;
            _latestAcceptedOffset = offset;
            _latestPaintSelectedTarget = candidate;
            // An accepted exact Phase-A frame owns release settlement. Rich
            // paint remains diagnostic evidence owned by the coordinator.
            _settleTarget = candidate;
            if (acceptance.isExactLivePublication) {
              _scheduleVisualTargetPaint(candidate);
            }
          },
          onMotionIdle: (_) {
            if (_preemptedUntilDirectPointer) return;
            _motionIdle = true;
            if (widget.component == DashboardTemporalAnchorComponent.day &&
                _ownedMotionEpoch != null) {
              widget.coordinator?.finishDayMotion(
                this,
                _ownedMotionEpoch!,
                acceptedTarget: _latestAcceptedTarget,
                acceptedOffset: _latestAcceptedOffset?.toDouble(),
              );
            }
            _ownsActiveMotion = false;
            widget.onMotionActiveChanged?.call(false);
            // Commit semantic ownership before recentering. The old order
            // jumped to zero first, briefly restoring the previous origin
            // while the rich-paint acknowledgement was still pending.
            if (_trySettleAcceptedTarget()) {
              _controller.jumpToIndexSilently(0);
            } else if (widget.component ==
                DashboardTemporalAnchorComponent.day) {
              // Rejected/cold physical release must not strand the producer
              // on a date that Core never accepted. An accepted deferred day
              // remains a shared visual preview until its exact publication.
              _clearMotionTargets();
              _controller.jumpToIndexSilently(0);
            }
          },
          itemBuilder: (context, offset, metrics) {
            if (widget.visualBuilder != null) return const SizedBox.shrink();
            // Overlay renderers own the visible content. The generated cells
            // only supply shared physics; they must not project unused dates.
            if (widget.visualBuilder != null ||
                widget.presentation ==
                    SummaryTemporalFlingPresentation.dynamicTrio ||
                (widget.component == DashboardTemporalAnchorComponent.day &&
                    widget.coordinator != null)) {
              return const SizedBox.shrink();
            }
            final origin = _motionOrigin ?? widget.navigation.state;
            final candidate =
                widget.candidateForOffset(origin, offset) ?? origin;
            return Transform.translate(
              offset: Offset(widget.visualContentOffset, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.labelForCandidate(candidate),
                  maxLines: 1,
                  style: FluviVisualTokens.summaryTitleTextStyle.copyWith(
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.visualBuilder != null)
          ExcludeSemantics(
            child: IgnorePointer(
              child: ClipRect(
                child: ListenableBuilder(
                  listenable: _visualChanges,
                  builder: (context, _) =>
                      widget.visualBuilder!(context, visualState),
                ),
              ),
            ),
          ),
        if (widget.visualBuilder == null &&
            (widget.presentation ==
                    SummaryTemporalFlingPresentation.dynamicTrio ||
                (widget.component == DashboardTemporalAnchorComponent.day &&
                    widget.coordinator != null)))
          Transform.translate(
            offset: Offset(widget.visualContentOffset, 0),
            child: ExcludeSemantics(
              child: ClipRect(
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: _visualChanges,
                    builder: (context, _) => _DynamicTrioValues(
                      height: widget.height,
                      compactSpacing:
                          widget.presentation ==
                          SummaryTemporalFlingPresentation.dynamicTrio,
                      rawIndex: visualState.rawIndex,
                      isMoving: visualState.isMoving,
                      origin: visualState.origin,
                      candidateForOffset: widget.candidateForOffset,
                      labelForCandidate: widget.labelForCandidate,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  bool _sameOwnedSemanticTarget(
    DashboardNavigationState? left,
    DashboardNavigationState right,
  ) {
    if (left == null) return false;
    return switch (widget.component) {
      DashboardTemporalAnchorComponent.year =>
        left.yearCursor == right.yearCursor,
      DashboardTemporalAnchorComponent.month =>
        left.monthCursor.month == right.monthCursor.month,
      DashboardTemporalAnchorComponent.day =>
        left.yearCursor == right.yearCursor &&
            left.monthCursor == right.monthCursor &&
            left.dayCursor == right.dayCursor,
    };
  }

  @override
  void dispose() {
    if (widget.releaseMotionOnDispose &&
        _ownsActiveMotion &&
        !_preemptedUntilDirectPointer) {
      final coordinator = widget.coordinator;
      final epoch = coordinator?.motionEpoch;
      final release = widget.onMotionActiveChanged;
      // Disposing during a settings/layout build must not notify Core until
      // that frame completes. A newer temporal owner invalidates this release.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (coordinator == null || coordinator.motionEpoch == epoch) {
          release?.call(false);
        }
      });
    }
    _ownsActiveMotion = false;
    // A hierarchy track can disappear while the persistent mode selector is
    // still dragging across a level. Only that selector owns the segmented
    // adapter's variant-unmount release; clearing here would incorrectly end
    // its shared Summary lane during an in-place track replacement.
    _visualTargetFrameEpoch += 1;
    widget.coordinator?.detach(this);
    widget.paintedTargets?.removeListener(_onPaintedTargetChanged);
    _detachResetRunner(_attachedRegistry);
    _controller.removeListener(_publishPhysicalDayMotion);
    _controller.dispose();
    super.dispose();
  }
}

final class _DynamicTrioValues extends StatelessWidget {
  const _DynamicTrioValues({
    required this.height,
    required this.compactSpacing,
    required this.rawIndex,
    required this.isMoving,
    required this.origin,
    required this.candidateForOffset,
    required this.labelForCandidate,
  });

  final double height;
  final bool compactSpacing;
  final double rawIndex;
  final bool isMoving;
  final DashboardNavigationState origin;
  final DashboardNavigationState? Function(DashboardNavigationState, int)
  candidateForOffset;
  final String Function(DashboardNavigationState) labelForCandidate;

  @override
  Widget build(BuildContext context) {
    final offsets = SummaryDynamicTrioGeometry.offsetsFor(
      rawIndex: rawIndex,
      isMoving: isMoving,
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[for (final offset in offsets) _item(offset)],
    );
  }

  Widget _item(int offset) {
    final candidate = candidateForOffset(origin, offset) ?? origin;
    final geometry = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: offset,
      rawIndex: rawIndex,
    );
    return Positioned(
      left: 0,
      right: 0,
      top:
          (compactSpacing
              ? geometry.centerY
              : height / 2 + (offset - rawIndex) * height) -
          10,
      height: 20,
      child: Transform.scale(
        scale: compactSpacing ? geometry.scale : 1,
        child: Center(
          child: Text(
            key: ValueKey<String>('summary-pill-dynamic-trio-$offset'),
            labelForCandidate(candidate),
            maxLines: 1,
            style: FluviVisualTokens.summaryTitleTextStyle.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

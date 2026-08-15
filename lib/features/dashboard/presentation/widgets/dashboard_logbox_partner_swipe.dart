import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/motion/gesture_direction_arbiter.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';

/// The physical role a row occupied in its canonical day-group before a
/// horizontal interaction began. It is captured by hit testing and never
/// recalculated from the transient displacement.
enum DashboardLogBoxBlockSegmentRole { singleton, top, middle, bottom }

extension DashboardLogBoxBlockSegmentRoleGeometry
    on DashboardLogBoxBlockSegmentRole {
  bool get ownsBottomShadow =>
      this == DashboardLogBoxBlockSegmentRole.singleton ||
      this == DashboardLogBoxBlockSegmentRole.bottom;

  RRect bodyFor(Rect rect) => switch (this) {
    DashboardLogBoxBlockSegmentRole.singleton =>
      FluviVisualTokens.logBoxGroupRadius.toRRect(rect),
    DashboardLogBoxBlockSegmentRole.top => RRect.fromRectAndCorners(
      rect,
      topLeft: FluviVisualTokens.logBoxGroupRadius.topLeft,
      topRight: FluviVisualTokens.logBoxGroupRadius.topRight,
    ),
    DashboardLogBoxBlockSegmentRole.middle => RRect.fromRectAndRadius(
      rect,
      Radius.zero,
    ),
    DashboardLogBoxBlockSegmentRole.bottom => RRect.fromRectAndCorners(
      rect,
      bottomLeft: FluviVisualTokens.logBoxGroupRadius.bottomLeft,
      bottomRight: FluviVisualTokens.logBoxGroupRadius.bottomRight,
    ),
  };
}

/// One exact visible row hit, expressed in the dashboard coordinate space.
///
/// It transports already-prepared semantics only; it owns neither scrolling,
/// Query state nor text preparation.
@immutable
final class DashboardLogBoxRowHitTarget {
  const DashboardLogBoxRowHitTarget({
    required this.row,
    required this.globalRowBounds,
    required this.globalAvatarBounds,
    required this.localRowTop,
    required this.blockSegmentRole,
  });

  final DashboardLogRowViewModel row;
  final Rect globalRowBounds;
  final Rect globalAvatarBounds;

  /// Canonical content-local y coordinate frozen before the horizontal
  /// interaction starts. It lets the active segment use the exact prepared
  /// block geometry without recomputing topology while tracking.
  final double localRowTop;
  final DashboardLogBoxBlockSegmentRole blockSegmentRole;
}

/// Stable bridge from the viewport's one gesture owner to the current
/// single-surface painter. It is not another cache: the renderer binds the
/// exact current canonical hit lookup while it is mounted.
final class DashboardLogBoxSurfaceHitTestController {
  DashboardLogBoxRowHitTarget? Function(Offset globalPosition)? _hitAtGlobal;

  DashboardLogBoxRowHitTarget? hitAtGlobal(Offset globalPosition) =>
      _hitAtGlobal?.call(globalPosition);

  void bind({
    required DashboardLogBoxRowHitTarget? Function(Offset globalPosition)
    hitAtGlobal,
  }) {
    _hitAtGlobal = hitAtGlobal;
  }

  void unbind() {
    _hitAtGlobal = null;
  }
}

@immutable
final class DashboardLogBoxPartnerSwipeState {
  const DashboardLogBoxPartnerSwipeState({
    required this.target,
    required this.translationX,
    required this.activationThreshold,
    this.awaitingFocusPublication = false,
  });

  final DashboardLogBoxRowHitTarget target;
  final double translationX;
  final double activationThreshold;
  final bool awaitingFocusPublication;

  Rect get translatedGlobalBounds =>
      target.globalRowBounds.translate(translationX, 0);

  DashboardLogBoxPartnerSwipeState copyWith({
    double? translationX,
    bool? awaitingFocusPublication,
  }) => DashboardLogBoxPartnerSwipeState(
    target: target,
    translationX: translationX ?? this.translationX,
    activationThreshold: activationThreshold,
    awaitingFocusPublication:
        awaitingFocusPublication ?? this.awaitingFocusPublication,
  );
}

/// The one owner of the transient row translation.
///
/// It deliberately has no repository or committed-Query capability. A caller
/// receives the prepared semantic row only after an intentional release, then
/// asks the application-layer focus owner to publish a new effective scope.
final class DashboardLogBoxPartnerSwipeController extends ChangeNotifier {
  DashboardLogBoxPartnerSwipeController({required TickerProvider vsync})
    : _returnController = AnimationController.unbounded(vsync: vsync) {
    _returnController.addListener(_advanceReturnAnimation);
    _returnController.addStatusListener(_finishReturnAnimation);
  }

  static const double touchSlop = 8;
  static const double directionalDominance = 1.25;
  static const Duration _returnDuration = Duration(milliseconds: 140);

  final AnimationController _returnController;
  final ValueNotifier<double> _translation = ValueNotifier<double>(0);
  DashboardLogBoxPartnerSwipeState? _state;
  _DashboardLogBoxPartnerSwipePerformance? _performance;
  double _returnFrom = 0;

  DashboardLogBoxPartnerSwipeState? get state => _state;

  /// Translation is intentionally separate from [ChangeNotifier]. Structural
  /// listeners own source-slot omission/start/end; this one scalar drives the
  /// isolated canonical segment's retained transform only.
  ValueListenable<double> get translation => _translation;
  Listenable get structuralChanges => this;
  bool get isActive => _state != null;
  String? get activeEntryId => _state?.target.row.entryId;

  /// Starts primitive-only accounting for a pointer that landed on a possible
  /// partner row. It has no rendering or gesture-arena side effect. A summary
  /// is emitted only if that pointer actually leases a canonical segment.
  void notePointerDown() {
    if (_state != null) return;
    _performance = _DashboardLogBoxPartnerSwipePerformance()..clock.start();
  }

  /// Samples raw pointer travel without allocation or notification. This is
  /// intentionally called from the recognizer rather than the full surface
  /// painter, so pointer arithmetic remains separate from paint ownership.
  void notePointerMove(double rawTranslationX) {
    final performance = _performance;
    if (performance == null) return;
    performance.pointerMoveCount += 1;
    performance.rawHorizontalTravel = math.max(
      performance.rawHorizontalTravel,
      -math.min(0.0, rawTranslationX),
    );
    final now = performance.clock.elapsedMicroseconds;
    final prior = performance.lastPointerMoveMicros;
    if (prior != null) {
      performance.maximumFrameIntervalMicros = math.max(
        performance.maximumFrameIntervalMicros,
        now - prior,
      );
    }
    performance.lastPointerMoveMicros = now;
  }

  /// Records the exact arbitration transition without changing presentation.
  /// If a candidate already follows the finger, [state.translationX] remains
  /// untouched; this is metrics only, not another static repaint trigger.
  void noteAcquired() {
    final performance = _performance;
    final state = _state;
    if (performance == null || state == null) return;
    performance.pointerDownToAcquiredMicros =
        performance.clock.elapsedMicroseconds;
    performance.acquisitionDx = state.translationX;
  }

  bool begin(DashboardLogBoxRowHitTarget target) {
    if (target.row.partnerId.isEmpty || target.globalRowBounds.left <= 0) {
      return false;
    }
    final existing = _state;
    if (existing != null &&
        existing.target.row.entryId == target.row.entryId &&
        existing.target.globalRowBounds == target.globalRowBounds) {
      // The recognizer may first lease this row as a provisional horizontal
      // candidate and later win the gesture arena. That ownership promotion
      // must retain the visual dx already attached to the finger.
      return true;
    }
    _returnController.stop();
    final activationThreshold =
        DashboardLogBoxPartnerSwipeKinematics.activationThreshold(
          globalLeft: target.globalRowBounds.left,
          rowWidth: target.globalRowBounds.width,
        );
    _state = DashboardLogBoxPartnerSwipeState(
      target: target,
      translationX: 0,
      activationThreshold: activationThreshold,
    );
    _performance ??= _DashboardLogBoxPartnerSwipePerformance()..clock.start();
    _performance!.activationThreshold = activationThreshold;
    _performance!.physicalMaximumTravel =
        DashboardLogBoxPartnerSwipeKinematics.maximumVisualTravel(
          globalLeft: target.globalRowBounds.left,
          rowWidth: target.globalRowBounds.width,
        );
    _translation.value = 0;
    notifyListeners();
    return true;
  }

  void update(double rawTranslationX) {
    final current = _state;
    if (current == null || current.awaitingFocusPublication) return;
    final next = DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
      globalLeft: current.target.globalRowBounds.left,
      rowWidth: current.target.globalRowBounds.width,
      requestedTranslation: rawTranslationX,
    );
    final performance = _performance;
    if (performance != null) {
      performance.horizontalUpdateCount += 1;
      performance.compositorTransformUpdateCount += 1;
      if (next != rawTranslationX) performance.translationSaturationCount += 1;
      performance.maximumVisualTravel = math.max(
        performance.maximumVisualTravel,
        -next,
      );
      performance.firstVisualDx ??= next;
    }
    if (next == current.translationX) return;
    _state = current.copyWith(translationX: next);
    _translation.value = next;
  }

  /// Holds the already-acquired row in place until the application owner has
  /// atomically published the focused presentation. A failed/superseded focus
  /// snaps back instead of leaving stale overlay pixels behind.
  DashboardLogRowViewModel? finish() {
    final current = _state;
    if (current == null) return null;
    if (DashboardLogBoxPartnerSwipeKinematics.commits(
      translationX: current.translationX,
      activationThreshold: current.activationThreshold,
    )) {
      _performance?.committed = true;
      _state = current.copyWith(awaitingFocusPublication: true);
      notifyListeners();
      return current.target.row;
    }
    snapBack();
    return null;
  }

  void completeFocusPublication() => _clear();

  void rejectFocusPublication() => snapBack();

  void snapBack() {
    final current = _state;
    if (current == null) return;
    if (current.translationX == 0) {
      _performance?.cancelled = true;
      _clear();
      return;
    }
    final performance = _performance;
    if (performance != null) {
      performance.cancelled = true;
      performance.snapBackStartedMicros = performance.clock.elapsedMicroseconds;
    }
    _returnFrom = current.translationX;
    _returnController
      ..value = 0
      ..animateTo(1, duration: _returnDuration, curve: Curves.easeOutCubic);
  }

  void cancel() {
    _returnController.stop();
    _performance?.cancelled = true;
    _clear();
  }

  void _advanceReturnAnimation() {
    final current = _state;
    if (current == null) return;
    _state = current.copyWith(
      translationX: _returnFrom * (1 - _returnController.value),
      awaitingFocusPublication: false,
    );
    _translation.value = _state!.translationX;
    final performance = _performance;
    if (performance != null) {
      performance.compositorTransformUpdateCount += 1;
      performance.maximumVisualTravel = math.max(
        performance.maximumVisualTravel,
        -_state!.translationX,
      );
    }
  }

  void _finishReturnAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) _clear();
  }

  void _clear() {
    final state = _state;
    if (state == null) return;
    _emitPerformanceSummary(state);
    _state = null;
    _translation.value = 0;
    notifyListeners();
  }

  /// These callbacks are invoked by the two separate paint owners. They are
  /// primitive counters only: translation never notifies the static painter,
  /// and an unexpected increment immediately exposes that regression in the
  /// one end-of-gesture summary.
  void recordStaticSurfacePaint() {
    final performance = _performance;
    if (_state != null && performance != null) {
      performance.staticSurfacePaintCountDuringTracking += 1;
    }
  }

  void recordActiveSegmentRasterPaint(int durationMicros) {
    final performance = _performance;
    if (_state == null || performance == null) return;
    performance.activeSegmentPaintCountDuringTracking += 1;
    performance.activeSegmentRasterPaintCountDuringTracking += 1;
    performance.maximumSwipePaintMicros = math.max(
      performance.maximumSwipePaintMicros,
      durationMicros,
    );
  }

  void _emitPerformanceSummary(DashboardLogBoxPartnerSwipeState state) {
    final performance = _performance;
    _performance = null;
    if (performance == null) return;
    performance.clock.stop();
    final snapStarted = performance.snapBackStartedMicros;
    final snapBackDurationMicros = snapStarted == null
        ? 0
        : math.max(0, performance.clock.elapsedMicroseconds - snapStarted);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'PARTNER_SWIPE_PERF_SUMMARY',
        entryCount: 1,
        message:
            'entryId=${state.target.row.entryId} '
            'pointerDownToAcquiredMs='
            '${(performance.pointerDownToAcquiredMicros ?? -1) ~/ 1000} '
            'pointerMoveCount=${performance.pointerMoveCount} '
            'horizontalUpdateCount=${performance.horizontalUpdateCount} '
            'rawHorizontalTravel=${performance.rawHorizontalTravel.round()} '
            'visualHorizontalTravel=${performance.maximumVisualTravel.round()} '
            'acquisitionDx=${performance.acquisitionDx.round()} '
            'firstVisualDx=${performance.firstVisualDx?.round() ?? 0} '
            'maxVisualTravel=${performance.physicalMaximumTravel.round()} '
            'commitThreshold=${performance.activationThreshold.round()} '
            'translationSaturationCount=${performance.translationSaturationCount} '
            'staticSurfacePaintCountDuringTracking='
            '${performance.staticSurfacePaintCountDuringTracking} '
            'activeSegmentPaintCountDuringTracking='
            '${performance.activeSegmentPaintCountDuringTracking} '
            'activeSegmentRasterPaintCountDuringTracking='
            '${performance.activeSegmentRasterPaintCountDuringTracking} '
            'compositorTransformUpdateCount='
            '${performance.compositorTransformUpdateCount} '
            'maximumFrameIntervalMicros=${performance.maximumFrameIntervalMicros} '
            'maximumSwipePaintMicros=${performance.maximumSwipePaintMicros} '
            'snapBackDurationMs=${snapBackDurationMicros ~/ 1000} '
            'blockRole=${state.target.blockSegmentRole.name} '
            'committed=${performance.committed} '
            'cancelled=${performance.cancelled}',
      ),
    );
  }

  @override
  void dispose() {
    _returnController
      ..removeListener(_advanceReturnAnimation)
      ..removeStatusListener(_finishReturnAnimation)
      ..dispose();
    _translation.dispose();
    super.dispose();
  }
}

final class _DashboardLogBoxPartnerSwipePerformance {
  final Stopwatch clock = Stopwatch();
  int? lastPointerMoveMicros;
  int? pointerDownToAcquiredMicros;
  int? snapBackStartedMicros;
  int pointerMoveCount = 0;
  int horizontalUpdateCount = 0;
  int translationSaturationCount = 0;
  int staticSurfacePaintCountDuringTracking = 0;
  int activeSegmentPaintCountDuringTracking = 0;
  int activeSegmentRasterPaintCountDuringTracking = 0;
  int compositorTransformUpdateCount = 0;
  int maximumFrameIntervalMicros = 0;
  int maximumSwipePaintMicros = 0;
  double rawHorizontalTravel = 0;
  double maximumVisualTravel = 0;
  double acquisitionDx = 0;
  double activationThreshold = 0;
  double physicalMaximumTravel = 0;
  double? firstVisualDx;
  bool committed = false;
  bool cancelled = false;
}

/// Pure physical limits for the one active-row translation. Keeping these
/// numbers outside the renderer makes the exact screen-edge contract testable
/// without rendering an avatar or creating a paragraph.
abstract final class DashboardLogBoxPartnerSwipeKinematics {
  /// The intentional focus commit distance. It is not a layout-gutter size
  /// and does not cap visual travel.
  static const double maximumActivationTravel = 36;

  /// Returns the actual card/row band, not the full transparent render
  /// surface. The distinction matters because the normal row starts inset
  /// from the screen while its active canonical segment may travel beyond
  /// that inset toward a true offscreen physical cap.
  static Rect rowBounds({
    required Offset surfaceGlobalOrigin,
    required double surfaceWidth,
    required double rowTop,
    required double rowHeight,
    required double contentGutter,
  }) {
    final gutter = contentGutter.clamp(0.0, surfaceWidth / 2).toDouble();
    return Rect.fromLTWH(
      surfaceGlobalOrigin.dx + gutter,
      surfaceGlobalOrigin.dy + rowTop,
      math.max(0, surfaceWidth - gutter * 2),
      rowHeight,
    );
  }

  static double activationThreshold({
    required double globalLeft,
    required double rowWidth,
  }) => math.min(math.max(0, rowWidth), maximumActivationTravel);

  /// The row reaches screen x=0 at `-globalLeft`; its physical offscreen cap
  /// is one full row width farther left. A gutter is therefore a waypoint,
  /// never the maximum swipe displacement.
  static double maximumVisualTravel({
    required double globalLeft,
    required double rowWidth,
  }) => math.max(0, globalLeft + rowWidth);

  static double clampTranslation({
    required double globalLeft,
    required double rowWidth,
    required double requestedTranslation,
  }) => requestedTranslation
      .clamp(
        -maximumVisualTravel(globalLeft: globalLeft, rowWidth: rowWidth),
        0.0,
      )
      .toDouble();

  /// Consumes only the arbitration distance. The first accepted visual value
  /// is zero, avoiding a replayed slop-sized jump; subsequent pointer motion
  /// remains one-to-one until [clampTranslation]'s physical cap.
  static double translationFromAcquisition({
    required double rawTranslation,
    required double acquiredRawTranslation,
  }) => math.min(0, rawTranslation - acquiredRawTranslation);

  /// A provisional horizontal candidate has already painted raw finger
  /// displacement before the arena resolves. Preserve that exact continuity
  /// when it becomes the accepted horizontal owner.
  static double translationFromCandidate({required double rawTranslation}) =>
      math.min(0, rawTranslation);

  static bool commits({
    required double translationX,
    required double activationThreshold,
  }) => -translationX >= activationThreshold;
}

/// Gesture-arena participant for one row at a time.
///
/// It begins undecided, rejects itself as soon as vertical/rightward intent is
/// clear, and only accepts an intentional left-horizontal sequence. This
/// leaves the existing [Scrollable] as the sole vertical drag/ballistic owner.
final class DashboardLogBoxPartnerSwipeGestureRecognizer
    extends OneSequenceGestureRecognizer {
  DashboardLogBoxPartnerSwipeGestureRecognizer({super.debugOwner});

  DashboardLogBoxRowHitTarget? Function(Offset globalPosition)? hitTest;
  VoidCallback? onSwipeTrackingStarted;
  ValueChanged<double>? onSwipePointerMove;
  ValueChanged<DashboardLogBoxRowHitTarget>? onSwipeCandidate;
  ValueChanged<DashboardLogBoxRowHitTarget>? onSwipeAcquired;
  ValueChanged<double>? onSwipeUpdate;
  VoidCallback? onSwipeEnd;
  VoidCallback? onSwipeCancelled;
  VoidCallback? onVerticalIntent;

  int? _pointer;
  Offset? _origin;
  DashboardLogBoxRowHitTarget? _target;
  bool _claimed = false;
  bool _accepted = false;
  bool _finished = false;
  bool _candidateStarted = false;
  bool _cancelNotified = false;
  double _latestDx = 0;
  double _acquiredDx = 0;

  /// This is only a sub-pixel/jitter filter, not gesture arbitration or the
  /// focus commit threshold. Once a pointer is clearly left/horizontal, its
  /// candidate segment tracks the raw dx before the arena has formally
  /// resolved ownership, which removes the visible eight-pixel dead zone.
  static const double _candidateVisualSlop = 1.0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_pointer != null) {
      resolvePointer(event.pointer, GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      return;
    }
    final target = hitTest?.call(event.position);
    if (target == null || target.row.partnerId.isEmpty) {
      resolvePointer(event.pointer, GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      return;
    }
    _pointer = event.pointer;
    _origin = event.position;
    _target = target;
    onSwipeTrackingStarted?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      _handleMove(event);
    } else if (event is PointerUpEvent) {
      if (_accepted) {
        _finished = true;
        onSwipeEnd?.call();
      } else {
        _notifyCancelledIfNeeded();
        resolvePointer(event.pointer, GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      _notifyCancelledIfNeeded();
      resolvePointer(event.pointer, GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }
  }

  void _handleMove(PointerMoveEvent event) {
    final origin = _origin;
    if (origin == null) return;
    final dx = event.position.dx - origin.dx;
    final dy = event.position.dy - origin.dy;
    _latestDx = dx;
    onSwipePointerMove?.call(dx);
    if (!_claimed) {
      _startOrUpdateHorizontalCandidate(dx: dx, dy: dy);
      switch (GestureDirectionArbiter.resolve(
        dx: dx,
        dy: dy,
        touchSlop: DashboardLogBoxPartnerSwipeController.touchSlop,
        dominanceRatio:
            DashboardLogBoxPartnerSwipeController.directionalDominance,
      )) {
        case GestureDirectionIntent.horizontal when dx < 0:
          _claimed = true;
          resolvePointer(event.pointer, GestureDisposition.accepted);
        case GestureDirectionIntent.vertical:
          _notifyCancelledIfNeeded();
          onVerticalIntent?.call();
          resolvePointer(event.pointer, GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        case GestureDirectionIntent.horizontal:
          _notifyCancelledIfNeeded();
          resolvePointer(event.pointer, GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        case null:
          break;
      }
      return;
    }
    if (_accepted) {
      onSwipeUpdate?.call(_visualTranslationFor(dx));
    }
  }

  void _startOrUpdateHorizontalCandidate({
    required double dx,
    required double dy,
  }) {
    final target = _target;
    if (target == null || dx >= 0) return;
    final horizontalDominates =
        dx.abs() >= _candidateVisualSlop &&
        dx.abs() >=
            DashboardLogBoxPartnerSwipeController.directionalDominance *
                dy.abs();
    if (!horizontalDominates) return;
    if (!_candidateStarted) {
      _candidateStarted = true;
      onSwipeCandidate?.call(target);
    }
    // A candidate remains presentation-only until arena acceptance. Its raw
    // displacement lets the first accepted frame preserve finger continuity.
    onSwipeUpdate?.call(dx);
  }

  double _visualTranslationFor(double rawTranslation) => _candidateStarted
      ? DashboardLogBoxPartnerSwipeKinematics.translationFromCandidate(
          rawTranslation: rawTranslation,
        )
      : DashboardLogBoxPartnerSwipeKinematics.translationFromAcquisition(
          rawTranslation: rawTranslation,
          acquiredRawTranslation: _acquiredDx,
        );

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer != _pointer || _accepted) return;
    final target = _target;
    if (target == null) return;
    _accepted = true;
    _acquiredDx = _latestDx;
    onSwipeAcquired?.call(target);
    onSwipeUpdate?.call(_visualTranslationFor(_latestDx));
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer != _pointer) return;
    if ((_accepted || _candidateStarted) && !_finished) {
      _notifyCancelledIfNeeded();
    }
  }

  void _notifyCancelledIfNeeded() {
    if (_cancelNotified || (!_accepted && !_candidateStarted)) return;
    _cancelNotified = true;
    onSwipeCancelled?.call();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    _origin = null;
    _target = null;
    _claimed = false;
    _accepted = false;
    _finished = false;
    _candidateStarted = false;
    _cancelNotified = false;
    _latestDx = 0;
    _acquiredDx = 0;
  }

  @override
  String get debugDescription => 'logbox partner left swipe';
}

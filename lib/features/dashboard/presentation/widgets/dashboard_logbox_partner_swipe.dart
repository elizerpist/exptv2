import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
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
    required this.blockSegmentRole,
  });

  final DashboardLogRowViewModel row;
  final Rect globalRowBounds;
  final Rect globalAvatarBounds;
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
  DashboardLogBoxPartnerSwipeState? _state;
  double _returnFrom = 0;

  DashboardLogBoxPartnerSwipeState? get state => _state;
  bool get isActive => _state != null;
  String? get activeEntryId => _state?.target.row.entryId;

  bool begin(DashboardLogBoxRowHitTarget target) {
    if (target.row.partnerId.isEmpty || target.globalRowBounds.left <= 0) {
      return false;
    }
    _returnController.stop();
    final activationThreshold =
        DashboardLogBoxPartnerSwipeKinematics.activationThreshold(
          globalLeft: target.globalRowBounds.left,
        );
    _state = DashboardLogBoxPartnerSwipeState(
      target: target,
      translationX: 0,
      activationThreshold: activationThreshold,
    );
    notifyListeners();
    return true;
  }

  void update(double rawTranslationX) {
    final current = _state;
    if (current == null || current.awaitingFocusPublication) return;
    final next = DashboardLogBoxPartnerSwipeKinematics.clampTranslation(
      globalLeft: current.target.globalRowBounds.left,
      requestedTranslation: rawTranslationX,
    );
    if (next == current.translationX) return;
    _state = current.copyWith(translationX: next);
    notifyListeners();
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
      _clear();
      return;
    }
    _returnFrom = current.translationX;
    _returnController
      ..value = 0
      ..animateTo(1, duration: _returnDuration, curve: Curves.easeOutCubic);
  }

  void cancel() {
    _returnController.stop();
    _clear();
  }

  void _advanceReturnAnimation() {
    final current = _state;
    if (current == null) return;
    _state = current.copyWith(
      translationX: _returnFrom * (1 - _returnController.value),
      awaitingFocusPublication: false,
    );
    notifyListeners();
  }

  void _finishReturnAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) _clear();
  }

  void _clear() {
    if (_state == null) return;
    _state = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _returnController
      ..removeListener(_advanceReturnAnimation)
      ..removeStatusListener(_finishReturnAnimation)
      ..dispose();
    super.dispose();
  }
}

/// Pure physical limits for the one active-row translation. Keeping these
/// numbers outside the renderer makes the exact screen-edge contract testable
/// without rendering an avatar or creating a paragraph.
abstract final class DashboardLogBoxPartnerSwipeKinematics {
  static const double maximumActivationTravel = 36;

  /// Returns the actual card/row band, not the full transparent render
  /// surface. The distinction matters because a swiped row starts at the
  /// LogBox gutter and is allowed to travel only until its own left edge
  /// reaches the real screen/viewport edge.
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

  static double activationThreshold({required double globalLeft}) =>
      math.min(globalLeft, maximumActivationTravel);

  static double clampTranslation({
    required double globalLeft,
    required double requestedTranslation,
  }) => requestedTranslation.clamp(-globalLeft, 0.0).toDouble();

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
  double _latestDx = 0;

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
        resolvePointer(event.pointer, GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      if (_accepted) onSwipeCancelled?.call();
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
    if (!_claimed) {
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
          onVerticalIntent?.call();
          resolvePointer(event.pointer, GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        case GestureDirectionIntent.horizontal:
          resolvePointer(event.pointer, GestureDisposition.rejected);
          stopTrackingPointer(event.pointer);
          return;
        case null:
          break;
      }
      return;
    }
    if (_accepted) onSwipeUpdate?.call(dx);
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer != _pointer || _accepted) return;
    final target = _target;
    if (target == null) return;
    _accepted = true;
    onSwipeAcquired?.call(target);
    onSwipeUpdate?.call(_latestDx);
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer != _pointer) return;
    if (_accepted && !_finished) onSwipeCancelled?.call();
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    _origin = null;
    _target = null;
    _claimed = false;
    _accepted = false;
    _finished = false;
    _latestDx = 0;
  }

  @override
  String get debugDescription => 'logbox partner left swipe';
}

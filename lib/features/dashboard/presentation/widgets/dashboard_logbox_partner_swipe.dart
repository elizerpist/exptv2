import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/motion/gesture_direction_arbiter.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../logbox/presentation/dashboard_logbox_prepared_row_text_layout.dart';

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
  });

  final DashboardLogRowViewModel row;
  final Rect globalRowBounds;
  final Rect globalAvatarBounds;
}

/// A temporary direct-paint source for exactly one swiped row.
///
/// The row text is the same prepared paragraph object used by the stable
/// surface. No image snapshot or second text-layout owner is created.
@immutable
final class DashboardLogBoxTransientRowPresentation {
  const DashboardLogBoxTransientRowPresentation({
    required this.target,
    required this.preparedText,
    required this.badge,
    required this.glyph,
    required this.showSeparator,
  });

  final DashboardLogBoxRowHitTarget target;
  final DashboardPreparedLogBoxRowTextLayout preparedText;
  final PreparedLogBoxVectorBadge badge;
  final PreparedLogBoxVectorGlyph glyph;
  final bool showSeparator;
}

/// Stable bridge from the viewport's one gesture owner to the current
/// single-surface painter. It is not another cache: the renderer binds exact
/// current hit/presentation lookups while it is mounted.
final class DashboardLogBoxSurfaceHitTestController {
  DashboardLogBoxRowHitTarget? Function(Offset globalPosition)? _hitAtGlobal;
  DashboardLogBoxTransientRowPresentation? Function(Offset globalPosition)?
  _presentationAtGlobal;

  DashboardLogBoxRowHitTarget? hitAtGlobal(Offset globalPosition) =>
      _hitAtGlobal?.call(globalPosition);

  DashboardLogBoxTransientRowPresentation? presentationAtGlobal(
    Offset globalPosition,
  ) => _presentationAtGlobal?.call(globalPosition);

  void bind({
    required DashboardLogBoxRowHitTarget? Function(Offset globalPosition)
    hitAtGlobal,
    required DashboardLogBoxTransientRowPresentation? Function(
      Offset globalPosition,
    )
    presentationAtGlobal,
  }) {
    _hitAtGlobal = hitAtGlobal;
    _presentationAtGlobal = presentationAtGlobal;
  }

  void unbind() {
    _hitAtGlobal = null;
    _presentationAtGlobal = null;
  }
}

@immutable
final class DashboardLogBoxPartnerSwipeState {
  const DashboardLogBoxPartnerSwipeState({
    required this.presentation,
    required this.translationX,
    required this.activationThreshold,
    this.awaitingFocusPublication = false,
  });

  final DashboardLogBoxTransientRowPresentation presentation;
  final double translationX;
  final double activationThreshold;
  final bool awaitingFocusPublication;

  Rect get translatedGlobalBounds =>
      presentation.target.globalRowBounds.translate(translationX, 0);

  DashboardLogBoxPartnerSwipeState copyWith({
    double? translationX,
    bool? awaitingFocusPublication,
  }) => DashboardLogBoxPartnerSwipeState(
    presentation: presentation,
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
  String? get activeEntryId => _state?.presentation.target.row.entryId;

  bool begin(DashboardLogBoxTransientRowPresentation presentation) {
    if (presentation.target.row.partnerId.isEmpty ||
        presentation.target.globalRowBounds.left <= 0) {
      return false;
    }
    _returnController.stop();
    final activationThreshold =
        DashboardLogBoxPartnerSwipeKinematics.activationThreshold(
          globalLeft: presentation.target.globalRowBounds.left,
        );
    _state = DashboardLogBoxPartnerSwipeState(
      presentation: presentation,
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
      globalLeft: current.presentation.target.globalRowBounds.left,
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
      return current.presentation.target.row;
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

  /// A full-width group card may have no outer gutter, while an individual
  /// row's visible content still begins at the existing row inset. The
  /// transient row therefore uses the first real visual inset as its start
  /// edge, allowing a deliberate left swipe to reach x=0 without changing the
  /// normal group-card layout.
  static double interactionGutter({
    required double contentGutter,
    required double rowHorizontalInset,
  }) => math.max(contentGutter, rowHorizontalInset);

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

  /// Prepared row text is measured in the full render-surface coordinate
  /// system. Moving it relative to the card left edge would shift both text
  /// columns by the gutter, so the transient overlay keeps that source origin
  /// and applies only the active swipe translation.
  static double contentOriginX({
    required Rect globalRowBounds,
    required double contentGutter,
    required double translationX,
    required double coordinateSpaceOriginX,
  }) =>
      globalRowBounds.left -
      contentGutter +
      translationX -
      coordinateSpaceOriginX;

  static Rect translatedToCoordinateSpace({
    required Rect globalBounds,
    required double translationX,
    required Offset coordinateSpaceOrigin,
  }) => globalBounds.translate(translationX, 0).shift(-coordinateSpaceOrigin);

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

/// One full-dashboard, paint-only overlay for the active row. It is clipped at
/// the real stack boundary, not at the LogBox content margin, so its left edge
/// can reach screen x=0 while inactive rows keep their normal geometry.
final class DashboardLogBoxPartnerSwipeOverlay extends StatelessWidget {
  const DashboardLogBoxPartnerSwipeOverlay({
    super.key,
    required this.controller,
    required this.coordinateSpaceKey,
  });

  final DashboardLogBoxPartnerSwipeController controller;
  final GlobalKey coordinateSpaceKey;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state == null) return const SizedBox.expand();
        final coordinateSpace =
            coordinateSpaceKey.currentContext?.findRenderObject() as RenderBox?;
        final origin =
            coordinateSpace?.localToGlobal(Offset.zero) ?? Offset.zero;
        return CustomPaint(
          key: const ValueKey('dashboard-logbox-partner-swipe-overlay'),
          painter: _DashboardLogBoxPartnerSwipePainter(
            state: state,
            coordinateSpaceOrigin: origin,
          ),
          child: const SizedBox.expand(),
        );
      },
    ),
  );
}

final class _DashboardLogBoxPartnerSwipePainter extends CustomPainter {
  const _DashboardLogBoxPartnerSwipePainter({
    required this.state,
    required this.coordinateSpaceOrigin,
  });

  final DashboardLogBoxPartnerSwipeState state;
  final Offset coordinateSpaceOrigin;

  static final Paint _dividerPaint = Paint()..color = FluviVisualTokens.border;

  @override
  void paint(Canvas canvas, Size size) {
    final source = state.presentation;
    final bounds = state.translatedGlobalBounds.shift(-coordinateSpaceOrigin);
    if (bounds.isEmpty) return;
    final interactionGutter =
        DashboardLogBoxPartnerSwipeKinematics.interactionGutter(
          contentGutter: DashboardLogBoxTokens.horizontalGutter,
          rowHorizontalInset: DashboardLogBoxTokens.rowHorizontalInset,
        );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final body = FluviVisualTokens.logBoxGroupRadius.toRRect(bounds);
    final foot = body.shift(FluviVisualTokens.cardFootShadow.offset);
    final depth = Paint()..color = FluviVisualTokens.cardFootShadow.color;
    final surface = Paint()..color = FluviVisualTokens.surface;
    canvas.drawRRect(foot, depth);
    canvas.drawRRect(body, surface);
    if (source.showSeparator) {
      canvas.drawRect(
        Rect.fromLTWH(
          bounds.left +
              DashboardLogBoxTokens.avatarSize +
              DashboardLogBoxTokens.rowGap,
          bounds.top,
          math.max(
            0,
            bounds.width -
                DashboardLogBoxTokens.avatarSize -
                DashboardLogBoxTokens.rowGap -
                DashboardLogBoxTokens.rowHorizontalInset,
          ),
          DashboardLogBoxTokens.dividerHeight,
        ),
        _dividerPaint,
      );
    }
    final badgeRect =
        DashboardLogBoxPartnerSwipeKinematics.translatedToCoordinateSpace(
          globalBounds: source.target.globalAvatarBounds,
          translationX: state.translationX,
          coordinateSpaceOrigin: coordinateSpaceOrigin,
        );
    _drawVectorResource(canvas, source.badge, badgeRect);
    _drawVectorResource(
      canvas,
      source.glyph,
      Rect.fromCenter(
        center: badgeRect.center,
        width: DashboardLogBoxTokens.avatarIconSize,
        height: DashboardLogBoxTokens.avatarIconSize,
      ),
    );
    canvas.save();
    canvas.translate(
      DashboardLogBoxPartnerSwipeKinematics.contentOriginX(
        globalRowBounds: source.target.globalRowBounds,
        contentGutter: interactionGutter,
        translationX: state.translationX,
        coordinateSpaceOriginX: coordinateSpaceOrigin.dx,
      ),
      bounds.top,
    );
    source.preparedText.paint(canvas, 0);
    canvas.restore();
    canvas.restore();
  }

  static void _drawVectorResource(
    Canvas canvas,
    PreparedLogBoxVectorResource resource,
    Rect target,
  ) {
    final logicalSize = resource.logicalSize;
    if (logicalSize.isEmpty || target.isEmpty) return;
    canvas.save();
    canvas.translate(target.left, target.top);
    canvas.scale(
      target.width / logicalSize.width,
      target.height / logicalSize.height,
    );
    canvas.drawPicture(resource.picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DashboardLogBoxPartnerSwipePainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.coordinateSpaceOrigin != coordinateSpaceOrigin;
}

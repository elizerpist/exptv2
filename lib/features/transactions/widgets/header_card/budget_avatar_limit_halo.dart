import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The one interaction shell used by every editable Budget avatar.
///
/// Both the original Budget carousel and Budget V2 deliberately use this
/// component: long press activation, press scale and cancellation semantics
/// must never drift between the two presentations.
class BudgetAvatarInteraction extends StatefulWidget {
  const BudgetAvatarInteraction({
    super.key,
    required this.child,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
    this.externallyPressed = false,
    this.scaleKey,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final GestureLongPressCancelCallback? onLongPressCancel;
  final bool externallyPressed;
  final Key? scaleKey;

  @override
  State<BudgetAvatarInteraction> createState() =>
      _BudgetAvatarInteractionState();
}

class _BudgetAvatarInteractionState extends State<BudgetAvatarInteraction> {
  var _pointerPressed = false;

  void _setPointerPressed(bool pressed) {
    if (_pointerPressed == pressed || !mounted) return;
    setState(() => _pointerPressed = pressed);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _setPointerPressed(true),
    onPointerUp: (_) => _setPointerPressed(false),
    onPointerCancel: (_) => _setPointerPressed(false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPressStart: widget.onLongPressStart,
      onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
      onLongPressEnd: (details) {
        _setPointerPressed(false);
        widget.onLongPressEnd?.call(details);
      },
      onLongPressCancel: () {
        _setPointerPressed(false);
        widget.onLongPressCancel?.call();
      },
      child: AnimatedScale(
        key: widget.scaleKey,
        scale: widget.externallyPressed || _pointerPressed ? .8 : 1.0,
        duration: const Duration(milliseconds: 115),
        curve: Curves.easeOutQuad,
        child: widget.child,
      ),
    ),
  );
}

/// Shared Budget limit ring. The geometry and radial glass fade are the
/// established Budget implementation, not a Budget V2 approximation.
class BudgetAvatarLimitHalo extends StatelessWidget {
  const BudgetAvatarLimitHalo({
    super.key,
    required this.progress,
    required this.hasPositiveLimit,
    required this.selected,
    required this.thickness,
    required this.fadeInnerEndpoint,
    required this.fadeOuterEndpoint,
    required this.fadeCurveBalance,
    required this.remainingEnabled,
    required this.remainingOpacity,
    required this.dangerProgressColor,
    required this.warningProgressColor,
    this.paintKey,
  });

  final double progress;
  final bool hasPositiveLimit;
  final bool selected;
  final double thickness;
  final double fadeInnerEndpoint;
  final double fadeOuterEndpoint;
  final double fadeCurveBalance;
  final bool remainingEnabled;
  final double remainingOpacity;
  final Color dangerProgressColor;
  final Color warningProgressColor;
  final Key? paintKey;

  static double strokeWidth(double value, {required bool selected}) {
    final clamped = _clampUnit(value);
    final min = selected ? 6.0 : 5.0;
    final max = selected ? 14.0 : 12.0;
    return _lerpDouble(min, max, clamped);
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: paintKey,
    painter: BudgetAvatarOuterHaloProgressPainter(
      progress: progress,
      hasPositiveLimit: hasPositiveLimit,
      selected: selected,
      thickness: thickness,
      fadeInnerEndpoint: fadeInnerEndpoint,
      fadeOuterEndpoint: fadeOuterEndpoint,
      fadeCurveBalance: fadeCurveBalance,
      remainingEnabled: remainingEnabled,
      remainingOpacity: remainingOpacity,
      dangerProgressColor: dangerProgressColor,
      warningProgressColor: warningProgressColor,
    ),
  );
}

class BudgetAvatarOuterHaloProgressPainter extends CustomPainter {
  const BudgetAvatarOuterHaloProgressPainter({
    required this.progress,
    required this.hasPositiveLimit,
    required this.selected,
    required this.thickness,
    required double fadeInnerEndpoint,
    required double fadeOuterEndpoint,
    required double fadeCurveBalance,
    required this.remainingEnabled,
    required double remainingOpacity,
    required this.dangerProgressColor,
    required this.warningProgressColor,
  }) : _fadeInnerEndpoint = fadeInnerEndpoint,
       _fadeOuterEndpoint = fadeOuterEndpoint,
       _fadeCurveBalance = fadeCurveBalance,
       _remainingOpacity = remainingOpacity;

  final double progress;
  final bool hasPositiveLimit;
  final bool selected;
  final double thickness;
  final double _fadeInnerEndpoint;
  final double _fadeOuterEndpoint;
  final double _fadeCurveBalance;
  final bool remainingEnabled;
  final double _remainingOpacity;
  final Color dangerProgressColor;
  final Color warningProgressColor;

  Color get progressColor {
    if (progress >= .90) return dangerProgressColor;
    if (progress >= .75) return warningProgressColor;
    return Colors.white;
  }

  Color get remainingColor => Colors.white;
  bool get usesOuterGlassHalo => true;
  bool get drawsInsideAvatarBody => false;
  bool get usesRadialFadeStroke => false;
  bool get usesRadialBandFade => true;
  bool get usesAngularFadeStroke => false;
  bool get usesSolidThresholdColors => true;
  bool get usesLinearRadialFade => (fadeCurveBalance - .5).abs() < .001;
  int get progressDrawPassCount => progress > 0 ? 1 : 0;
  int get progressPathDrawPassCount => progress > 0 ? 1 : 0;
  int get remainingDrawPassCount => drawsRemainingSegment ? 1 : 0;
  int get remainingPathDrawPassCount => drawsRemainingSegment ? 1 : 0;
  int get progressStrokeDrawPassCount => 0;
  int get visibleProgressRingCount =>
      progressPathDrawPassCount > 0 || remainingPathDrawPassCount > 0 ? 1 : 0;
  int get trackDrawPassCount => 0;
  int get glowDrawPassCount => 0;
  bool get usesStrokeBlur => false;
  bool get drawsSeparateInnerProgressRing => false;
  bool get clockwise => true;
  double get startRadians => -math.pi / 2;
  double get strokeWidth => thickness;
  double get avatarOutset => strokeWidth;
  double get clampedProgress => progress.clamp(0.0, 1.0).toDouble();
  double get fadeInnerEndpoint =>
      _clampProgressFadeEndpoint(_fadeInnerEndpoint);
  double get fadeOuterEndpoint =>
      _clampProgressFadeEndpoint(_fadeOuterEndpoint);
  double get fadeCurveBalance => _clampUnit(_fadeCurveBalance);
  double get innerEdgeAlpha => fadeInnerEndpoint;
  double get outerEdgeAlpha => fadeOuterEndpoint;
  double get remainingOpacity => _clampUnit(_remainingOpacity);
  bool get drawsRemainingSegment =>
      remainingEnabled &&
      hasPositiveLimit &&
      remainingOpacity > 0 &&
      clampedProgress < .999;
  double get remainingProgress =>
      drawsRemainingSegment ? 1 - clampedProgress : 0;
  double get outerTransitionStartUnit {
    if (fadeCurveBalance <= .5) return 0;
    return _lerpDouble(0, .94, (fadeCurveBalance - .5) / .5);
  }

  double get innerTransitionEndUnit {
    if (fadeCurveBalance >= .5) return 1;
    return _lerpDouble(.06, 1, fadeCurveBalance / .5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 && !drawsRemainingSegment) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2;
    final innerRadius = baseRadius;
    final outerRadius = baseRadius + strokeWidth;
    if (drawsRemainingSegment) {
      final remainingPath = _progressRingPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        progress: remainingProgress,
        startRadians: startRadians + math.pi * 2 * clampedProgress,
      );
      canvas.drawPath(
        remainingPath,
        _ringPaint(
          center: center,
          innerRadius: innerRadius,
          outerRadius: outerRadius,
          color: remainingColor,
          opacity: remainingOpacity,
        ),
      );
    }
    if (progress <= 0) return;
    final ringPath = _progressRingPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      progress: clampedProgress,
      startRadians: startRadians,
    );
    canvas.drawPath(
      ringPath,
      _ringPaint(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        color: progressColor,
        opacity: 1,
      ),
    );
  }

  Paint _ringPaint({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required Color color,
    required double opacity,
  }) => Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true
    ..shader = _radialFadeGradient(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      color: color,
      opacity: opacity,
    );

  Shader _radialFadeGradient({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required Color color,
    required double opacity,
  }) {
    final alphaMultiplier = _clampUnit(opacity);
    final innerColor = color.withValues(
      alpha: innerEdgeAlpha * alphaMultiplier,
    );
    final outerColor = color.withValues(
      alpha: outerEdgeAlpha * alphaMultiplier,
    );
    final innerStop = innerRadius / outerRadius;
    double stopForUnit(double unit) =>
        innerStop + (1 - innerStop) * _clampUnit(unit);

    if (usesLinearRadialFade) {
      return ui.Gradient.radial(
        center,
        outerRadius,
        <Color>[innerColor, outerColor],
        <double>[innerStop, 1],
      );
    }
    if (fadeCurveBalance > .5) {
      return ui.Gradient.radial(
        center,
        outerRadius,
        <Color>[innerColor, innerColor, outerColor],
        <double>[innerStop, stopForUnit(outerTransitionStartUnit), 1],
      );
    }
    return ui.Gradient.radial(
      center,
      outerRadius,
      <Color>[innerColor, outerColor, outerColor],
      <double>[innerStop, stopForUnit(innerTransitionEndUnit), 1],
    );
  }

  Path _progressRingPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double progress,
    required double startRadians,
  }) {
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    if (progress >= .999) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(outerRect)
        ..addOval(innerRect);
    }
    final sweep = math.pi * 2 * progress;
    final endRadians = startRadians + sweep;
    return Path()
      ..moveTo(
        center.dx + math.cos(startRadians) * outerRadius,
        center.dy + math.sin(startRadians) * outerRadius,
      )
      ..arcTo(outerRect, startRadians, sweep, false)
      ..lineTo(
        center.dx + math.cos(endRadians) * innerRadius,
        center.dy + math.sin(endRadians) * innerRadius,
      )
      ..arcTo(innerRect, endRadians, -sweep, false)
      ..close();
  }

  @override
  bool shouldRepaint(
    covariant BudgetAvatarOuterHaloProgressPainter oldDelegate,
  ) =>
      oldDelegate.progress != progress ||
      oldDelegate.hasPositiveLimit != hasPositiveLimit ||
      oldDelegate.selected != selected ||
      oldDelegate.thickness != thickness ||
      oldDelegate.fadeInnerEndpoint != fadeInnerEndpoint ||
      oldDelegate.fadeOuterEndpoint != fadeOuterEndpoint ||
      oldDelegate.fadeCurveBalance != fadeCurveBalance ||
      oldDelegate.remainingEnabled != remainingEnabled ||
      oldDelegate.remainingOpacity != remainingOpacity ||
      oldDelegate.dangerProgressColor != dangerProgressColor ||
      oldDelegate.warningProgressColor != warningProgressColor;
}

double _clampUnit(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

double _clampProgressFadeEndpoint(double value) {
  if (value <= .1) return .1;
  if (value >= 1) return 1;
  return value;
}

double _lerpDouble(double begin, double end, double amount) =>
    begin + (end - begin) * _clampUnit(amount);

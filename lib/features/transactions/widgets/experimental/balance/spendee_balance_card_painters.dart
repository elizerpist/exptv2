import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Paints the CSS-authored crescent used by the B3M-A3 no-spend card.
class SpendeeBalanceMoonPainter extends CustomPainter {
  const SpendeeBalanceMoonPainter();

  static const designSize = 15.0;
  static const insetShadowOffset = Offset(6, -2);
  static const moonColor = Color(0xFF5F55EC);
  static const insetShadowColor = Color(0xFFF0EFFF);
  static const plusColor = Color(0xFF8A80FF);

  @visibleForTesting
  SpendeeBalanceMoonGeometry geometryForSize(Size size) {
    final scale = math.min(size.width, size.height) / designSize;
    final origin = Offset(
      (size.width - designSize * scale) / 2,
      (size.height - designSize * scale) / 2,
    );
    Rect scaledRect(double left, double top, double width, double height) {
      return Rect.fromLTWH(
        origin.dx + left * scale,
        origin.dy + top * scale,
        width * scale,
        height * scale,
      );
    }

    return SpendeeBalanceMoonGeometry(
      moonCircle: scaledRect(0, 0, 15, 15),
      insetShadowCircle: scaledRect(
        insetShadowOffset.dx,
        insetShadowOffset.dy,
        15,
        15,
      ),
      plusHorizontalBar: scaledRect(5, 6.25, 5, 1.5),
      plusVerticalBar: scaledRect(6.75, 4.5, 1.5, 5),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = geometryForSize(size);
    canvas
      ..save()
      ..clipPath(Path()..addOval(geometry.moonCircle))
      ..drawOval(geometry.moonCircle, Paint()..color = moonColor)
      ..drawOval(geometry.insetShadowCircle, Paint()..color = insetShadowColor)
      ..restore();

    final plusPaint = Paint()..color = plusColor;
    final plusRadius = Radius.circular(geometry.plusHorizontalBar.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(geometry.plusHorizontalBar, plusRadius),
      plusPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(geometry.plusVerticalBar, plusRadius),
      plusPaint,
    );
  }

  @override
  bool shouldRepaint(SpendeeBalanceMoonPainter oldDelegate) => false;
}

@immutable
class SpendeeBalanceMoonGeometry {
  const SpendeeBalanceMoonGeometry({
    required this.moonCircle,
    required this.insetShadowCircle,
    required this.plusHorizontalBar,
    required this.plusVerticalBar,
  });

  final Rect moonCircle;
  final Rect insetShadowCircle;
  final Rect plusHorizontalBar;
  final Rect plusVerticalBar;
}

/// Exact compact/permanent B3M-A3 variable-budget threshold.
class SpendeeBalanceBudgetProgressPainter extends CustomPainter {
  const SpendeeBalanceBudgetProgressPainter({required this.progress});

  static const trackHeight = 6.0;
  static const markerDiameter = 16.0;
  static const markerBorderWidth = 4.0;
  static const trackColor = Color(0xFFEEF0F7);
  static const markerColor = Color(0xFFFF4677);
  static const markerRingColor = Color(0x38FF5F91);
  static const fillGradient = LinearGradient(
    colors: [Color(0xFFFF4D79), Color(0xFFE94FCB)],
  );
  static const trackInsetShadow = BoxShadow(
    color: Color(0x0A444E8B),
    offset: Offset(0, 1),
    blurRadius: 1,
    blurStyle: BlurStyle.inner,
  );
  static const fillShadow = BoxShadow(
    color: Color(0x33EA4FBA),
    offset: Offset(0, 2),
    blurRadius: 5,
  );
  static const markerShadow = BoxShadow(
    color: Color(0x4DF43D7A),
    offset: Offset(0, 3),
    blurRadius: 9,
  );

  final double progress;

  double get normalizedProgress => progress.clamp(0, 1).toDouble();

  @visibleForTesting
  SpendeeBalanceBudgetProgressGeometry geometryForSize(Size size) {
    final trackTop = (size.height - trackHeight) / 2;
    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);
    final fillRect = Rect.fromLTWH(
      trackRect.left,
      trackRect.top,
      trackRect.width * normalizedProgress,
      trackRect.height,
    );
    final markerCenter = Offset(fillRect.right, size.height / 2);
    return SpendeeBalanceBudgetProgressGeometry(
      trackRect: trackRect,
      fillRect: fillRect,
      markerCenter: markerCenter,
      markerOuterRect: Rect.fromCircle(
        center: markerCenter,
        radius: markerDiameter / 2,
      ),
      markerInnerRect: Rect.fromCircle(
        center: markerCenter,
        radius: markerDiameter / 2 - markerBorderWidth,
      ),
    );
  }

  @visibleForTesting
  Path trackInsetShadowPathForSize(Size size) {
    final track = RRect.fromRectAndRadius(
      geometryForSize(size).trackRect,
      const Radius.circular(99),
    );
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(track.outerRect.inflate(trackInsetShadow.blurRadius * 4))
      ..addRRect(track.shift(trackInsetShadow.offset));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = geometryForSize(size);
    final track = RRect.fromRectAndRadius(
      geometry.trackRect,
      const Radius.circular(99),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    canvas
      ..save()
      ..clipRRect(track)
      ..drawPath(
        trackInsetShadowPathForSize(size),
        BoxShadow(
          color: trackInsetShadow.color,
          blurRadius: trackInsetShadow.blurRadius,
        ).toPaint(),
      )
      ..restore();

    if (geometry.fillRect.width > 0) {
      final fill = RRect.fromRectAndRadius(
        geometry.fillRect,
        const Radius.circular(99),
      );
      canvas.drawRRect(fill.shift(fillShadow.offset), fillShadow.toPaint());
      canvas.drawRRect(
        fill,
        Paint()..shader = fillGradient.createShader(geometry.fillRect),
      );
    }

    canvas.drawOval(
      geometry.markerOuterRect.shift(markerShadow.offset),
      markerShadow.toPaint(),
    );
    canvas.drawOval(
      geometry.markerOuterRect.inflate(1),
      Paint()..color = markerRingColor,
    );
    canvas.drawOval(geometry.markerOuterRect, Paint()..color = Colors.white);
    canvas.drawOval(geometry.markerInnerRect, Paint()..color = markerColor);
  }

  @override
  bool shouldRepaint(SpendeeBalanceBudgetProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

@immutable
class SpendeeBalanceBudgetProgressGeometry {
  const SpendeeBalanceBudgetProgressGeometry({
    required this.trackRect,
    required this.fillRect,
    required this.markerCenter,
    required this.markerOuterRect,
    required this.markerInnerRect,
  });

  final Rect trackRect;
  final Rect fillRect;
  final Offset markerCenter;
  final Rect markerOuterRect;
  final Rect markerInnerRect;
}

/// Filled 30-day chart. The HTML reduces the 30 values to six consecutive
/// five-day averages and maps them into the vertical 22%…78% plot band.
class SpendeeBalanceDailyChartPainter extends CustomPainter {
  const SpendeeBalanceDailyChartPainter({required this.dailyValues})
    : assert(dailyValues.length == 30);

  final List<double> dailyValues;

  List<double> get bucketAverages {
    return List<double>.generate(6, (bucketIndex) {
      final start = bucketIndex * 5;
      final bucket = dailyValues.skip(start).take(5);
      return bucket.reduce((sum, value) => sum + value) / 5;
    }, growable: false);
  }

  @visibleForTesting
  List<Offset> pointsForSize(Size size) {
    final buckets = bucketAverages;
    final minimum = buckets.reduce(math.min);
    final range = buckets.reduce(math.max) - minimum;
    final safeRange = range == 0 ? 1.0 : range;
    return List<Offset>.generate(buckets.length, (index) {
      final normalized = (buckets[index] - minimum) / safeRange;
      final x = size.width * index / (buckets.length - 1);
      final y = size.height * (78 - normalized * 56) / 100;
      return Offset(x, y);
    }, growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final points = pointsForSize(size);
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x268B7DFA), Color(0x088B7DFA)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(SpendeeBalanceDailyChartPainter oldDelegate) {
    return !listEquals(oldDelegate.dailyValues, dailyValues);
  }
}

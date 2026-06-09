import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GhostBadge extends StatelessWidget {
  const GhostBadge({
    super.key,
    this.size = 18,
    this.backgroundColor = AppColors.white,
    this.strokeColor = AppColors.gray300,
    this.ghostColor = AppColors.gray500,
  });

  final double size;
  final Color backgroundColor;
  final Color strokeColor;
  final Color ghostColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: GhostBadgePainter(
          backgroundColor: backgroundColor,
          strokeColor: strokeColor,
          ghostColor: ghostColor,
        ),
      ),
    );
  }
}

class GhostBadgePainter extends CustomPainter {
  const GhostBadgePainter({
    required this.backgroundColor,
    required this.strokeColor,
    required this.ghostColor,
  });

  final Color backgroundColor;
  final Color strokeColor;
  final Color ghostColor;

  @override
  void paint(Canvas canvas, Size size) {
    final minSide = size.shortestSide;
    final radius = minSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final badgePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = minSide * 0.08;

    canvas.drawCircle(center, radius, badgePaint);
    canvas.drawCircle(center, radius - strokePaint.strokeWidth / 2, strokePaint);

    final ghostPaint = Paint()
      ..color = ghostColor
      ..style = PaintingStyle.fill;
    final ghost = Path()
      ..moveTo(minSide * 0.30, minSide * 0.68)
      ..lineTo(minSide * 0.30, minSide * 0.44)
      ..cubicTo(
        minSide * 0.30,
        minSide * 0.28,
        minSide * 0.42,
        minSide * 0.20,
        minSide * 0.50,
        minSide * 0.20,
      )
      ..cubicTo(
        minSide * 0.58,
        minSide * 0.20,
        minSide * 0.70,
        minSide * 0.28,
        minSide * 0.70,
        minSide * 0.44,
      )
      ..lineTo(minSide * 0.70, minSide * 0.68)
      ..quadraticBezierTo(
        minSide * 0.64,
        minSide * 0.62,
        minSide * 0.58,
        minSide * 0.68,
      )
      ..quadraticBezierTo(
        minSide * 0.52,
        minSide * 0.74,
        minSide * 0.46,
        minSide * 0.68,
      )
      ..quadraticBezierTo(
        minSide * 0.40,
        minSide * 0.62,
        minSide * 0.34,
        minSide * 0.68,
      )
      ..close();
    canvas.drawPath(
      ghost.shift(Offset((size.width - minSide) / 2, 0)),
      ghostPaint,
    );

    final eyePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.43, size.height * 0.43),
      minSide * 0.035,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.57, size.height * 0.43),
      minSide * 0.035,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant GhostBadgePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.ghostColor != ghostColor;
  }
}

class DashedRoundedBorder extends StatelessWidget {
  const DashedRoundedBorder({
    super.key,
    required this.child,
    required this.borderRadius,
    this.color = AppColors.gray400,
    this.strokeWidth = 1.4,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedRoundedBorderPainter(
        borderRadius: borderRadius,
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class DashedRoundedBorderPainter extends CustomPainter {
  const DashedRoundedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final BorderRadius borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()
      ..addRRect(borderRadius.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    drawDashedPath(
      canvas: canvas,
      path: path,
      paint: paint,
      dashLength: dashLength,
      gapLength: gapLength,
    );
  }

  @override
  bool shouldRepaint(covariant DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

void drawDashedPath({
  required Canvas canvas,
  required Path path,
  required Paint paint,
  required double dashLength,
  required double gapLength,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dashLength > metric.length
          ? metric.length
          : distance + dashLength;
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gapLength;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../domain/mind_behavioral_score_projection.dart';

/// The reference-derived composition for the expanded Mind Header chart.
/// These are Header-local layout measures, not an alternate dashboard layout
/// or a second physical card.
abstract final class MindHeaderScoreChartStyle {
  static const plotLeft = 16.0;
  static const plotTop = 48.0;
  static const plotWidth = 346.0;
  static const plotHeight = 60.0;
  static const lineColor = FluviVisualTokens.textOnAction;
  static const lineWidth = 1.6;
  static const endpointRadius = 4.3;
  static const endpointStrokeWidth = 2.0;
  static const verticalPadding = 3.5;
  static const guideRelativeY = .36;
  static const guideDash = 2.0;
  static const guideGap = 3.0;
  static const guideOpacity = .24;
  static const areaFadeStartOpacity = .30;
  static const areaFadeEndOpacity = 0.0;
}

/// A paint-only chart reveal physically clipped by the dashboard-owned Header
/// expansion. It has no animation or financial state; callers provide one
/// immutable score series from the live Mind score publication.
final class MindHeaderScoreChart extends StatelessWidget {
  const MindHeaderScoreChart({
    super.key,
    required this.series,
    required this.expansionProgress,
  });

  final MindBehavioralScoreChartSeries series;
  final double expansionProgress;

  @override
  Widget build(BuildContext context) {
    final reveal = expansionProgress.clamp(0.0, 1.0).toDouble();
    if (reveal <= 0 || series.points.isEmpty) return const SizedBox.shrink();
    return Positioned(
      key: const ValueKey<String>('mind-header-score-chart'),
      left: MindHeaderScoreChartStyle.plotLeft,
      top: MindHeaderScoreChartStyle.plotTop,
      width: MindHeaderScoreChartStyle.plotWidth,
      height: MindHeaderScoreChartStyle.plotHeight,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const ValueKey<String>('mind-header-score-chart-reveal'),
            width: MindHeaderScoreChartStyle.plotWidth,
            height: MindHeaderScoreChartStyle.plotHeight * reveal,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: MindHeaderScoreChartStyle.plotWidth,
                  height: MindHeaderScoreChartStyle.plotHeight,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>(
                        'mind-header-score-chart-paint',
                      ),
                      painter: MindHeaderScoreChartPainter(
                        points: series.points,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the one reference-faithful chart: a soft white under-line fade, a
/// minimal white score line and its subtle outlined latest-value marker.
/// It consumes already-calculated score points only.
final class MindHeaderScoreChartPainter extends CustomPainter {
  MindHeaderScoreChartPainter({required List<MindBehavioralScorePoint> points})
    : points = List<MindBehavioralScorePoint>.unmodifiable(points);

  final List<MindBehavioralScorePoint> points;

  Color get lineColor => MindHeaderScoreChartStyle.lineColor;
  double get lineWidth => MindHeaderScoreChartStyle.lineWidth;
  double get endpointRadius => MindHeaderScoreChartStyle.endpointRadius;
  bool get smoothsBetweenDailySamples => true;
  double get areaFadeStartOpacity =>
      MindHeaderScoreChartStyle.areaFadeStartOpacity;
  double get areaFadeEndOpacity => MindHeaderScoreChartStyle.areaFadeEndOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || points.isEmpty) return;
    final line = Path();
    Offset pointAt(int index) {
      final x = points.length == 1
          ? size.width
          : size.width * index / (points.length - 1);
      final score = points[index].score.clamp(0.0, 100.0).toDouble();
      final drawableHeight =
          size.height - MindHeaderScoreChartStyle.verticalPadding * 2;
      return Offset(
        x,
        MindHeaderScoreChartStyle.verticalPadding +
            (1 - score / 100) * drawableHeight,
      );
    }

    final first = pointAt(0);
    line.moveTo(first.dx, first.dy);
    if (points.length > 1) {
      for (var index = 0; index < points.length - 1; index += 1) {
        final current = pointAt(index);
        final next = pointAt(index + 1);
        final midpoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        line.quadraticBezierTo(
          current.dx,
          current.dy,
          midpoint.dx,
          midpoint.dy,
        );
      }
      final last = pointAt(points.length - 1);
      line.quadraticBezierTo(last.dx, last.dy, last.dx, last.dy);
    }

    _drawGuide(canvas, size);
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fadeRect = Offset.zero & size;
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withValues(alpha: areaFadeStartOpacity),
            lineColor.withValues(alpha: areaFadeEndOpacity),
          ],
        ).createShader(fadeRect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    final endpoint = pointAt(points.length - 1);
    canvas.drawCircle(
      endpoint,
      endpointRadius,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = MindHeaderScoreChartStyle.endpointStrokeWidth
        ..isAntiAlias = true,
    );
  }

  void _drawGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(
        alpha: MindHeaderScoreChartStyle.guideOpacity,
      )
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round;
    final y = size.height * MindHeaderScoreChartStyle.guideRelativeY;
    for (
      var start = 0.0;
      start < size.width;
      start +=
          MindHeaderScoreChartStyle.guideDash +
          MindHeaderScoreChartStyle.guideGap
    ) {
      canvas.drawLine(
        Offset(start, y),
        Offset(
          (start + MindHeaderScoreChartStyle.guideDash).clamp(0, size.width),
          y,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindHeaderScoreChartPainter oldDelegate) =>
      !listEquals(oldDelegate.points, points);
}

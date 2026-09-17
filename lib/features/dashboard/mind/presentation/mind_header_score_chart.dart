import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../domain/mind_behavioral_score_projection.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

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
  static const timeLabelTop = plotTop + plotHeight + 4.0;
  static const timeLabelHeight = 12.0;
  static const timeLabelRevealExtent = plotHeight + 4.0 + timeLabelHeight;
  static const timeLabelTextStyle = TextStyle(
    color: Color(0xD9FFFFFF),
    fontSize: 8.5,
    height: 1,
    fontWeight: FontWeight.w700,
  );
}

/// A paint-only chart reveal physically clipped by the dashboard-owned Header
/// expansion. It has no animation or financial state; callers provide one
/// immutable score series from the live Mind score publication.
final class MindHeaderScoreChart extends StatelessWidget {
  const MindHeaderScoreChart({
    super.key,
    required this.series,
    required this.expansionProgress,
    this.showTimeLabels = false,
  });

  final MindBehavioralScoreChartSeries series;
  final double expansionProgress;
  final bool showTimeLabels;

  /// Five semantic quarter positions over the immutable score-series time
  /// domain. These are dates first and pixels second, so scope/range/history
  /// changes cannot leave a stale artificial axis behind.
  @visibleForTesting
  static List<int> projectedTimeLabelEpochDays(
    MindBehavioralScoreChartSeries series,
  ) {
    final span = series.endInclusiveEpochDay - series.startInclusiveEpochDay;
    return List<int>.generate(
      5,
      (index) => series.startInclusiveEpochDay + (span * index / 4).round(),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reveal = expansionProgress.clamp(0.0, 1.0).toDouble();
    if (reveal <= 0 || series.points.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      key: const ValueKey<String>('mind-header-score-chart'),
      child: IgnorePointer(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: MindHeaderScoreChartStyle.plotLeft,
              top: MindHeaderScoreChartStyle.plotTop,
              width: MindHeaderScoreChartStyle.plotWidth,
              height: MindHeaderScoreChartStyle.plotHeight,
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
            if (showTimeLabels)
              _MindHeaderScoreChartTimeLabels(
                series: series,
                expansionProgress: reveal,
              ),
          ],
        ),
      ),
    );
  }
}

/// A five-label, no-axis projection under the accepted plot. Its clipping is
/// derived from the same Header expansion scalar as the line itself; it has no
/// ticker, entrance animation or independent time model.
final class _MindHeaderScoreChartTimeLabels extends StatelessWidget {
  const _MindHeaderScoreChartTimeLabels({
    required this.series,
    required this.expansionProgress,
  });

  final MindBehavioralScoreChartSeries series;
  final double expansionProgress;

  @override
  Widget build(BuildContext context) {
    final visibleHeight =
        (MindHeaderScoreChartStyle.timeLabelRevealExtent * expansionProgress -
                MindHeaderScoreChartStyle.plotHeight -
                4)
            .clamp(0.0, MindHeaderScoreChartStyle.timeLabelHeight)
            .toDouble();
    if (visibleHeight <= 0) return const SizedBox.shrink();
    final labels = MindHeaderScoreChart.projectedTimeLabelEpochDays(series)
        .map(
          (epochDay) => _formatEpochDay(
            epochDay,
            startInclusiveEpochDay: series.startInclusiveEpochDay,
            endInclusiveEpochDay: series.endInclusiveEpochDay,
          ),
        )
        .toList(growable: false);
    return Positioned(
      left: MindHeaderScoreChartStyle.plotLeft,
      top: MindHeaderScoreChartStyle.timeLabelTop,
      width: MindHeaderScoreChartStyle.plotWidth,
      height: visibleHeight,
      child: ClipRect(
        child: SizedBox(
          height: MindHeaderScoreChartStyle.timeLabelHeight,
          child: ExcludeSemantics(
            child: Stack(
              children: List<Widget>.generate(5, (index) {
                // Alignment maps -1/-.5/0/.5/1 to the actual plot-domain
                // fractions 0/.25/.5/.75/1. A five-way Row would visually
                // place quarter labels at 30% and 70%, which is not the
                // requested temporal projection.
                final fraction = index / 4;
                final label = Text(
                  labels[index],
                  key: ValueKey<String>(
                    'mind-header-score-chart-time-label-$index',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: MindHeaderScoreChartStyle.timeLabelTextStyle,
                );
                if (index == 0) {
                  return Align(alignment: Alignment.centerLeft, child: label);
                }
                if (index == 4) {
                  return Align(alignment: Alignment.centerRight, child: label);
                }
                return Align(
                  alignment: Alignment(-1 + fraction * 2, 0),
                  // A zero-width anchor keeps the text's centre at the
                  // temporal fraction instead of letting its own glyph width
                  // displace the 25/50/75% coordinate.
                  child: SizedBox(
                    width: 0,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      alignment: Alignment.center,
                      child: label,
                    ),
                  ),
                );
              }, growable: false),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatEpochDay(
    int epochDay, {
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
  }) {
    final date = DateTime.utc(1970).add(Duration(days: epochDay));
    final start = DateTime.utc(
      1970,
    ).add(Duration(days: startInclusiveEpochDay));
    final end = DateTime.utc(1970).add(Duration(days: endInclusiveEpochDay));
    final spanDays = endInclusiveEpochDay - startInclusiveEpochDay;
    if (spanDays <= 40) return '${date.day}.';
    if (start.year == end.year) {
      return DashboardTimeLabelFormatter.shortMonthName(date.month);
    }
    return '${date.year}. ${DashboardTimeLabelFormatter.shortMonthName(date.month)}';
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

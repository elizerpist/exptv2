import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';

/// Shared, Header-local visual measurements for every truthful trend chart.
/// They are deliberately independent of score or money semantics.
abstract final class DashboardHeaderTrendChartStyle {
  static const detailLeft = 16.0;
  static const detailTop = 16.0;
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

/// One domain value rendered by the neutral Header trend painter.
@immutable
final class DashboardHeaderTrendPoint {
  const DashboardHeaderTrendPoint({
    required this.temporalCoordinate,
    required this.value,
  });

  final int temporalCoordinate;
  final double value;
}

/// Typed immutable input for the neutral Header trend painter.
@immutable
final class DashboardHeaderTrendSeries {
  DashboardHeaderTrendSeries({
    required this.startInclusiveTemporalCoordinate,
    required this.endInclusiveTemporalCoordinate,
    required List<DashboardHeaderTrendPoint> points,
  }) : assert(
         startInclusiveTemporalCoordinate <= endInclusiveTemporalCoordinate,
       ),
       points = List<DashboardHeaderTrendPoint>.unmodifiable(points);

  final int startInclusiveTemporalCoordinate;
  final int endInclusiveTemporalCoordinate;
  final List<DashboardHeaderTrendPoint> points;
}

/// One actual-domain X projection shared by painter, labels and inspection.
@immutable
final class DashboardHeaderTrendTemporalProjection {
  const DashboardHeaderTrendTemporalProjection({
    required this.startInclusiveTemporalCoordinate,
    required this.endInclusiveTemporalCoordinate,
  }) : assert(
         startInclusiveTemporalCoordinate <= endInclusiveTemporalCoordinate,
       );

  final int startInclusiveTemporalCoordinate;
  final int endInclusiveTemporalCoordinate;

  double normalizedCoordinate(num coordinate) {
    final span =
        endInclusiveTemporalCoordinate - startInclusiveTemporalCoordinate;
    if (span == 0) return .5;
    return ((coordinate - startInclusiveTemporalCoordinate) / span)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double plotXForCoordinate(num coordinate, double plotWidth) =>
      normalizedCoordinate(coordinate) * plotWidth;

  double coordinateForPlotX(double plotX, double plotWidth) {
    if (plotWidth <= 0) return startInclusiveTemporalCoordinate.toDouble();
    final fraction = (plotX / plotWidth).clamp(0.0, 1.0).toDouble();
    return startInclusiveTemporalCoordinate +
        (endInclusiveTemporalCoordinate - startInclusiveTemporalCoordinate) *
            fraction;
  }

  int nearestPointIndexForPlotX(
    List<DashboardHeaderTrendPoint> points,
    double plotX,
    double plotWidth,
  ) {
    if (points.isEmpty) {
      throw StateError('Cannot inspect an empty Header trend series.');
    }
    final target = coordinateForPlotX(plotX, plotWidth);
    var nearestIndex = 0;
    for (var index = 1; index < points.length; index += 1) {
      final candidate = points[index];
      final nearest = points[nearestIndex];
      final candidateDistance = (candidate.temporalCoordinate - target).abs();
      final nearestDistance = (nearest.temporalCoordinate - target).abs();
      if (candidateDistance < nearestDistance ||
          (candidateDistance == nearestDistance &&
              candidate.temporalCoordinate < nearest.temporalCoordinate)) {
        nearestIndex = index;
      }
    }
    return nearestIndex;
  }
}

/// The shared reference-faithful visual kernel: smooth white trend line,
/// under-line fade, guide, selected crosshair and outlined latest endpoint.
/// It maps arbitrary financial or behavioral values only for paint geometry;
/// it neither reinterprets nor stores the source values.
final class DashboardHeaderTrendPainter extends CustomPainter {
  DashboardHeaderTrendPainter({
    required this.series,
    required this.minimumValue,
    required this.maximumValue,
    this.selectedTemporalCoordinate,
  }) : assert(maximumValue >= minimumValue);

  final DashboardHeaderTrendSeries series;
  final double minimumValue;
  final double maximumValue;
  final int? selectedTemporalCoordinate;

  @override
  void paint(Canvas canvas, Size size) {
    final points = series.points;
    if (size.isEmpty || points.isEmpty) return;
    final projection = DashboardHeaderTrendTemporalProjection(
      startInclusiveTemporalCoordinate: series.startInclusiveTemporalCoordinate,
      endInclusiveTemporalCoordinate: series.endInclusiveTemporalCoordinate,
    );
    final line = Path();
    final first = pointOffsetAt(0, size, projection);
    line.moveTo(first.dx, first.dy);
    if (points.length > 1) {
      for (var index = 0; index < points.length - 1; index += 1) {
        final current = pointOffsetAt(index, size, projection);
        final next = pointOffsetAt(index + 1, size, projection);
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
      final last = pointOffsetAt(points.length - 1, size, projection);
      line.quadraticBezierTo(last.dx, last.dy, last.dx, last.dy);
    }

    _drawGuide(canvas, size);
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            DashboardHeaderTrendChartStyle.lineColor.withValues(
              alpha: DashboardHeaderTrendChartStyle.areaFadeStartOpacity,
            ),
            DashboardHeaderTrendChartStyle.lineColor.withValues(
              alpha: DashboardHeaderTrendChartStyle.areaFadeEndOpacity,
            ),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = DashboardHeaderTrendChartStyle.lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = DashboardHeaderTrendChartStyle.lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    _drawSelection(canvas, size, projection);
    canvas.drawCircle(
      pointOffsetAt(points.length - 1, size, projection),
      DashboardHeaderTrendChartStyle.endpointRadius,
      Paint()
        ..color = DashboardHeaderTrendChartStyle.lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = DashboardHeaderTrendChartStyle.endpointStrokeWidth
        ..isAntiAlias = true,
    );
  }

  @visibleForTesting
  Offset pointOffsetAt(
    int index,
    Size size,
    DashboardHeaderTrendTemporalProjection projection,
  ) {
    final value = series.points[index].value;
    final span = maximumValue - minimumValue;
    final normalized = span == 0
        ? .5
        : ((value - minimumValue) / span).clamp(0.0, 1.0).toDouble();
    final drawableHeight =
        size.height - DashboardHeaderTrendChartStyle.verticalPadding * 2;
    return Offset(
      projection.plotXForCoordinate(
        series.points[index].temporalCoordinate,
        size.width,
      ),
      DashboardHeaderTrendChartStyle.verticalPadding +
          (1 - normalized) * drawableHeight,
    );
  }

  void _drawSelection(
    Canvas canvas,
    Size size,
    DashboardHeaderTrendTemporalProjection projection,
  ) {
    final selected = selectedTemporalCoordinate;
    if (selected == null) return;
    final index = series.points.indexWhere(
      (point) => point.temporalCoordinate == selected,
    );
    if (index < 0) return;
    final offset = pointOffsetAt(index, size, projection);
    canvas.drawLine(
      Offset(offset.dx, 0),
      Offset(offset.dx, size.height),
      Paint()
        ..color = DashboardHeaderTrendChartStyle.lineColor
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      offset,
      2.6,
      Paint()
        ..color = DashboardHeaderTrendChartStyle.lineColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  void _drawGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardHeaderTrendChartStyle.lineColor.withValues(
        alpha: DashboardHeaderTrendChartStyle.guideOpacity,
      )
      ..strokeWidth = .7
      ..strokeCap = StrokeCap.round;
    final y = size.height * DashboardHeaderTrendChartStyle.guideRelativeY;
    for (
      var start = 0.0;
      start < size.width;
      start +=
          DashboardHeaderTrendChartStyle.guideDash +
          DashboardHeaderTrendChartStyle.guideGap
    ) {
      canvas.drawLine(
        Offset(start, y),
        Offset(
          (start + DashboardHeaderTrendChartStyle.guideDash).clamp(
            0,
            size.width,
          ),
          y,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashboardHeaderTrendPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.minimumValue != minimumValue ||
      oldDelegate.maximumValue != maximumValue ||
      oldDelegate.selectedTemporalCoordinate != selectedTemporalCoordinate;
}

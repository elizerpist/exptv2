import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pulse_models.dart';

enum PulseChartSize { compact, expanded }

class PulseArcGauge extends StatelessWidget {
  const PulseArcGauge({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.arcGauge);
}

class PulseThresholdBar extends StatelessWidget {
  const PulseThresholdBar({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.thresholdBar);
}

class PulseTrendChart extends StatelessWidget {
  const PulseTrendChart({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.trend);
}

class PulseForecastChart extends StatelessWidget {
  const PulseForecastChart({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.forecast);
}

class PulseRatioChart extends StatelessWidget {
  const PulseRatioChart({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.ratio);
}

class PulseTimelineChart extends StatelessWidget {
  const PulseTimelineChart({super.key, required this.indicator, required this.size});
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  @override
  Widget build(BuildContext context) => _PulseChartCanvas(indicator: indicator, size: size, kind: PulseChartKind.timeline);
}

Widget pulseChartFor(PulseIndicatorSnapshot indicator, PulseChartSize size) => switch (indicator.chartKind) {
  PulseChartKind.arcGauge => PulseArcGauge(indicator: indicator, size: size),
  PulseChartKind.thresholdBar => PulseThresholdBar(indicator: indicator, size: size),
  PulseChartKind.trend => PulseTrendChart(indicator: indicator, size: size),
  PulseChartKind.forecast => PulseForecastChart(indicator: indicator, size: size),
  PulseChartKind.ratio => PulseRatioChart(indicator: indicator, size: size),
  PulseChartKind.timeline => PulseTimelineChart(indicator: indicator, size: size),
};

class _PulseChartCanvas extends StatelessWidget {
  const _PulseChartCanvas({
    required this.indicator,
    required this.size,
    required this.kind,
  });
  final PulseIndicatorSnapshot indicator;
  final PulseChartSize size;
  final PulseChartKind kind;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _PulseChartPainter(
        indicator: indicator,
        kind: kind,
        color: Theme.of(context).colorScheme.primary,
        muted: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
  );
}

class _PulseChartPainter extends CustomPainter {
  const _PulseChartPainter({
    required this.indicator,
    required this.kind,
    required this.color,
    required this.muted,
  });
  final PulseIndicatorSnapshot indicator;
  final PulseChartKind kind;
  final Color color;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final threshold = indicator.thresholds.firstOrNull?.value;
    final data = _values(indicator);
    switch (kind) {
      case PulseChartKind.arcGauge:
        _arc(canvas, size, data, threshold);
      case PulseChartKind.thresholdBar:
      case PulseChartKind.ratio:
        _bars(canvas, size, data, threshold);
      case PulseChartKind.timeline:
        _timeline(canvas, size, data, threshold);
      case PulseChartKind.trend:
      case PulseChartKind.forecast:
        _line(canvas, size, data, threshold);
    }
  }

  List<_ChartValue> _values(PulseIndicatorSnapshot input) {
    final values = <_ChartValue>[];
    for (final series in input.series) {
      for (final point in series.points) {
        final value = point.actual ?? point.baseline ?? point.momentum ?? point.reference;
        if (value != null) values.add(_ChartValue(point.x, value.toDouble(), series.key));
      }
    }
    return values;
  }

  void _arc(Canvas canvas, Size size, List<_ChartValue> data, double? threshold) {
    final rect = Rect.fromLTWH(12, 6, size.width - 24, (size.height * 2 - 12).clamp(1, size.width));
    final track = Paint()..color = muted.withValues(alpha: .55)..style = PaintingStyle.stroke..strokeWidth = math.min(11, size.height / 6)..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    final value = indicator.value ?? 0;
    final maxValue = math.max(100.0, math.max(value, threshold ?? 0) * 1.08);
    final progress = (value / maxValue).clamp(0.0, 1.0);
    final foreground = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = track.strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * progress, false, foreground);
    if (threshold != null) {
      final angle = math.pi + math.pi * (threshold / maxValue).clamp(0.0, 1.0);
      final center = rect.center;
      final radius = rect.width / 2;
      final marker = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      canvas.drawCircle(marker, track.strokeWidth * .43, Paint()..color = Colors.white);
      canvas.drawCircle(marker, track.strokeWidth * .25, Paint()..color = color.withValues(alpha: .72));
    }
  }

  void _bars(Canvas canvas, Size size, List<_ChartValue> data, double? threshold) {
    final rect = Rect.fromLTWH(2, 12, size.width - 4, size.height - 24);
    final grouped = data.take(5).toList();
    if (grouped.isEmpty) {
      _empty(canvas, rect);
      return;
    }
    final maxValue = math.max(1.0, grouped.map((e) => e.value).reduce(math.max));
    final barHeight = rect.height / grouped.length;
    for (var index = 0; index < grouped.length; index++) {
      final item = grouped[index];
      final y = rect.top + index * barHeight + barHeight * .22;
      final track = RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, y, rect.width, barHeight * .5), const Radius.circular(20));
      canvas.drawRRect(track, Paint()..color = muted.withValues(alpha: .42));
      final fill = RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, y, rect.width * (item.value / maxValue).clamp(0.0, 1.0), barHeight * .5), const Radius.circular(20));
      canvas.drawRRect(fill, Paint()..color = color.withValues(alpha: .78));
      if (threshold != null && indicator.unit != PulseUnit.currency) {
        final markerX = rect.left + rect.width * (threshold / maxValue).clamp(0.0, 1.0);
        canvas.drawLine(Offset(markerX, y - 2), Offset(markerX, y + barHeight * .5 + 2), Paint()..color = color.withValues(alpha: .45)..strokeWidth = 1.5);
      }
    }
  }

  void _timeline(Canvas canvas, Size size, List<_ChartValue> data, double? threshold) {
    final y = size.height * .5;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), Paint()..color = muted.withValues(alpha: .7)..strokeWidth = 2);
    if (data.isEmpty) {
      _empty(canvas, Rect.fromLTWH(8, y - 8, size.width - 16, 16));
      return;
    }
    final sorted = data..sort((a, b) => a.x.compareTo(b.x));
    final minX = sorted.first.x.toDouble();
    final maxX = math.max(minX + 1, sorted.last.x.toDouble());
    for (final item in sorted) {
      final x = 8 + (size.width - 16) * ((item.x - minX) / (maxX - minX));
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = color);
    }
    if (threshold != null && indicator.unit == PulseUnit.days) {
      final x = 8 + (size.width - 16) * (threshold / 31).clamp(0.0, 1.0);
      canvas.drawLine(Offset(x, y - 14), Offset(x, y + 14), Paint()..color = color.withValues(alpha: .55)..strokeWidth = 1.5);
    }
  }

  void _line(Canvas canvas, Size size, List<_ChartValue> data, double? threshold) {
    final rect = Rect.fromLTWH(4, 5, size.width - 8, size.height - 10);
    if (data.isEmpty) {
      _empty(canvas, rect);
      return;
    }
    final rows = <String, List<_ChartValue>>{};
    for (final item in data) {
      (rows[item.series] ??= []).add(item);
    }
    final all = data.map((item) => item.value);
    final minY = math.min(0.0, all.reduce(math.min));
    final maxY = math.max(minY + 1, all.reduce(math.max));
    for (final row in rows.entries) {
      final points = row.value..sort((a, b) => a.x.compareTo(b.x));
      final minX = points.first.x.toDouble();
      final maxX = math.max(minX + 1, points.last.x.toDouble());
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final item = points[index];
        final x = rect.left + rect.width * ((item.x - minX) / (maxX - minX));
        final y = rect.bottom - rect.height * ((item.value - minY) / (maxY - minY));
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = switch (row.key) {
          'momentum' || 'netMomentum' => color.withValues(alpha: .56),
          'baseline' || 'netBaseline' => color.withValues(alpha: .82),
          'limit' => muted,
          _ => color,
        }
        ..strokeWidth = row.key == 'limit' ? 1 : 2.25
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (row.key == 'baseline' || row.key == 'momentum') paint.strokeCap = StrokeCap.butt;
      canvas.drawPath(path, paint);
    }
    if (threshold != null && indicator.unit != PulseUnit.currency) {
      final y = rect.bottom - rect.height * ((threshold - minY) / (maxY - minY)).clamp(0.0, 1.0);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), Paint()..color = color.withValues(alpha: .36)..strokeWidth = 1);
    }
  }

  void _empty(Canvas canvas, Rect rect) {
    canvas.drawLine(rect.topLeft, rect.bottomRight, Paint()..color = muted.withValues(alpha: .55)..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _PulseChartPainter oldDelegate) => oldDelegate.indicator != indicator || oldDelegate.color != color || oldDelegate.muted != muted;
}

class _ChartValue {
  const _ChartValue(this.x, this.value, this.series);
  final int x;
  final double value;
  final String series;
}

extension on List<PulseThresholdValue> {
  PulseThresholdValue? get firstOrNull => isEmpty ? null : first;
}

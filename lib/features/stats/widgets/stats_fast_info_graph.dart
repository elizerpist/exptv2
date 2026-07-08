import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/stats_category_scope_series.dart';
import '../data/stats_closing_series.dart';
import '../data/stats_heatmap_series.dart';
import '../data/stats_year_data.dart';

class StatsFastInfoGraph extends StatelessWidget {
  const StatsFastInfoGraph({super.key, required this.data});

  final StatsYearData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('stats-fastinfo-graph'),
      height: 328,
      width: double.infinity,
      child: CustomPaint(
        key: ValueKey('stats-fastinfo-${data.mode.name}'),
        painter: _StatsFastInfoGraphPainter(data),
      ),
    );
  }
}

class _StatsFastInfoGraphPainter extends CustomPainter {
  const _StatsFastInfoGraphPainter(this.data);

  final StatsYearData data;

  @override
  void paint(Canvas canvas, Size size) {
    final width = (size.width - 68).clamp(1.0, double.infinity).toDouble();
    final topChart = Rect.fromLTWH(34, 38, width, 104);
    final pulseChart = Rect.fromLTWH(34, 162, width, 46);
    final bottomChart = Rect.fromLTWH(34, 232, width, 70);
    switch (data.mode) {
      case StatsRenderMode.categoryScope:
        _drawCategoryScope(canvas, topChart, pulseChart, bottomChart);
      case StatsRenderMode.closing:
        _drawClosing(canvas, topChart, pulseChart, bottomChart);
      case StatsRenderMode.heatmap:
        _drawHeatmap(canvas, topChart, pulseChart, bottomChart);
    }
  }

  void _drawGrid(Canvas canvas, Rect chart, {int horizontal = 3}) {
    final gridPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i <= horizontal; i += 1) {
      final y = chart.top + chart.height * i / horizontal;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
  }

  void _drawCategoryScope(
    Canvas canvas,
    Rect topChart,
    Rect pulseChart,
    Rect bottomChart,
  ) {
    final series = StatsCategoryScopeSeries.fromYearData(data);
    _drawTitle(canvas, '1. Előfordulás vs értékindex', topChart);
    _drawGrid(canvas, topChart);
    _drawRiskSegments(canvas, topChart, series.riskSegments);
    _drawLine(
      canvas,
      topChart,
      series.occurrence.map((point) => point.value).toList(),
      const Color(0xFFEF4444),
      maxValue: 100,
    );
    _drawLine(
      canvas,
      topChart,
      series.valueIndex.map((point) => point.value).toList(),
      const Color(0xFF0EA5A4),
      maxValue: 100,
    );
    _drawTitle(canvas, 'Alt: Behavior MACD', pulseChart);
    _drawSignedBars(
      canvas,
      pulseChart,
      series.macd.map((bar) => bar.value).toList(),
      positiveColor: const Color(0xFFEF4444),
      negativeColor: const Color(0xFF22C55E),
    );
    _drawTitle(canvas, '2. Havi scope Ft + impact line', bottomChart);
    _drawMonthlyScopeBars(canvas, bottomChart, series.monthlyBars);
  }

  void _drawHeatmap(
    Canvas canvas,
    Rect topChart,
    Rect pulseChart,
    Rect bottomChart,
  ) {
    final series = StatsHeatmapSeries.fromYearData(data);
    _drawTitle(canvas, 'S1 · Klaszter-sűrűség', topChart);
    _drawGrid(canvas, topChart);
    _drawLine(
      canvas,
      topChart,
      series.density.map((point) => point.value).toList(),
      const Color(0xFF06B6D4),
      maxValue: 1,
      fillColor: const Color(0xFF67E8F9).withValues(alpha: 0.20),
    );
    _drawTitle(canvas, 'S2 · Heat Pulse', pulseChart);
    _drawSignedBars(
      canvas,
      pulseChart,
      series.pulse.map((bar) => bar.value).toList(),
      positiveColor: const Color(0xFF06B6D4),
      negativeColor: const Color(0xFFCBD5E1),
    );
    _drawTitle(canvas, 'H1 · Havi heat load', bottomChart);
    _drawHeatMonthlyBars(canvas, bottomChart, series.monthlyBars);
  }

  void _drawClosing(
    Canvas canvas,
    Rect topChart,
    Rect pulseChart,
    Rect bottomChart,
  ) {
    final series = StatsClosingSeries.fromYearData(data);
    _drawTitle(canvas, 'S2 · Close Pulse', topChart);
    _drawSignedBars(
      canvas,
      topChart,
      series.closePulseBars.map((bar) => bar.value).toList(),
      positiveColor: const Color(0xFFEF4444),
      negativeColor: const Color(0xFF22C55E),
    );
    _drawTitle(canvas, 'H1 · Havi zárás + hit napok', bottomChart);
    _drawClosingMonthlyBars(canvas, bottomChart, series.monthlyCloseBars);
  }

  void _drawTitle(Canvas canvas, String text, Rect chart) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.gray700,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: chart.width);
    painter.paint(canvas, Offset(chart.left, chart.top - 18));
  }

  void _drawRiskSegments(
    Canvas canvas,
    Rect chart,
    List<StatsRiskSegment> segments,
  ) {
    for (final segment in segments) {
      final colorHex = segment.colorHex;
      if (colorHex == null) continue;
      final left = _xForIndex(chart, segment.startIndex, segments.length + 1);
      final right = _xForIndex(chart, segment.endIndex, segments.length + 1);
      canvas.drawRect(
        Rect.fromLTRB(left, chart.top, right, chart.bottom),
        Paint()..color = _color(colorHex).withValues(alpha: 0.20),
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect chart,
    List<double> values,
    Color color, {
    required double maxValue,
    Color? fillColor,
  }) {
    if (values.isEmpty) return;
    final safeMax = maxValue <= 0
        ? _max(values).clamp(1.0, double.infinity)
        : maxValue;
    final path = Path();
    for (var i = 0; i < values.length; i += 1) {
      final x = _xForIndex(chart, i, values.length);
      final y =
          chart.bottom - chart.height * (values[i] / safeMax).clamp(0.0, 1.0);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = fillColor;
    if (fill != null && values.length > 1) {
      final fillPath = Path.from(path)
        ..lineTo(chart.right, chart.bottom)
        ..lineTo(chart.left, chart.bottom)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = fill);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawSignedBars(
    Canvas canvas,
    Rect chart,
    List<double> values, {
    required Color positiveColor,
    required Color negativeColor,
  }) {
    _drawGrid(canvas, chart, horizontal: 2);
    if (values.isEmpty) return;
    final maxAbs = values
        .fold<double>(0, (max, value) => math.max(max, value.abs()))
        .clamp(1.0, double.infinity);
    final zeroY = chart.center.dy;
    canvas.drawLine(
      Offset(chart.left, zeroY),
      Offset(chart.right, zeroY),
      Paint()
        ..color = AppColors.gray500.withValues(alpha: 0.50)
        ..strokeWidth = 1,
    );
    final barWidth = (chart.width / (values.length * 1.8)).clamp(3.0, 14.0);
    for (var i = 0; i < values.length; i += 1) {
      final value = values[i];
      final centerX = _xForBarIndex(chart, i, values.length);
      final height = chart.height * 0.45 * (value.abs() / maxAbs);
      final top = value >= 0 ? zeroY - height : zeroY;
      final rect = Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = value >= 0 ? positiveColor : negativeColor,
      );
    }
  }

  void _drawMonthlyScopeBars(
    Canvas canvas,
    Rect chart,
    List<StatsMonthlyScopeBar> bars,
  ) {
    _drawGrid(canvas, chart, horizontal: 2);
    final maxValue = bars
        .map((bar) => bar.totalAmount)
        .fold<double>(0, math.max)
        .clamp(1.0, double.infinity);
    final barWidth = (chart.width / (bars.length * 1.8)).clamp(5.0, 18.0);
    for (var i = 0; i < bars.length; i += 1) {
      final bar = bars[i];
      final centerX = _xForBarIndex(chart, i, bars.length);
      var bottom = chart.bottom;
      for (final segment in bar.segments) {
        final height = chart.height * segment.amount / maxValue;
        final rect = Rect.fromLTWH(
          centerX - barWidth / 2,
          bottom - height,
          barWidth,
          height,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = _color(segment.colorHex),
        );
        bottom -= height;
      }
    }
  }

  void _drawHeatMonthlyBars(
    Canvas canvas,
    Rect chart,
    List<StatsHeatmapMonthlyBar> bars,
  ) {
    _drawGrid(canvas, chart, horizontal: 2);
    final maxValue = bars
        .map((bar) => bar.heatLoad)
        .fold<double>(0, math.max)
        .clamp(1.0, double.infinity);
    final barWidth = (chart.width / (bars.length * 1.8)).clamp(5.0, 18.0);
    for (var i = 0; i < bars.length; i += 1) {
      final bar = bars[i];
      final centerX = _xForBarIndex(chart, i, bars.length);
      var bottom = chart.bottom;
      for (final segment in bar.segments) {
        final height = chart.height * segment.value / maxValue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              centerX - barWidth / 2,
              bottom - height,
              barWidth,
              height,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = _color(segment.colorHex),
        );
        bottom -= height;
      }
    }
  }

  void _drawClosingMonthlyBars(
    Canvas canvas,
    Rect chart,
    List<StatsMonthlyCloseBar> bars,
  ) {
    _drawGrid(canvas, chart, horizontal: 2);
    final maxValue = bars
        .map((bar) => bar.amount)
        .fold<double>(0, math.max)
        .clamp(1.0, double.infinity);
    final barWidth = (chart.width / (bars.length * 1.8)).clamp(5.0, 18.0);
    for (var i = 0; i < bars.length; i += 1) {
      final bar = bars[i];
      final centerX = _xForBarIndex(chart, i, bars.length);
      final height = chart.height * bar.amount / maxValue;
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        chart.bottom - height,
        barWidth,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_color(bar.secondaryBarColorHex), _color(bar.barColorHex)],
          ).createShader(rect),
      );
      if (bar.thresholdHitDays > 0) {
        canvas.drawCircle(
          Offset(centerX, chart.bottom - height - 5),
          3,
          Paint()..color = _color(bar.thresholdPointColorHex),
        );
      }
    }
  }

  double _xForIndex(Rect chart, int index, int count) {
    if (count <= 1) return chart.center.dx;
    return chart.left + chart.width * index / (count - 1);
  }

  double _xForBarIndex(Rect chart, int index, int count) {
    if (count <= 1) return chart.center.dx;
    return chart.left + chart.width * (index + 0.5) / count;
  }

  double _max(List<double> values) {
    if (values.isEmpty) return 0;
    var max = values.first;
    for (final value in values.skip(1)) {
      if (value > max) max = value;
    }
    return max;
  }

  Color _color(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  @override
  bool shouldRepaint(_StatsFastInfoGraphPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/stats_category_scope_series.dart';
import '../data/stats_closing_series.dart';
import '../data/stats_heatmap_series.dart';
import '../data/stats_year_data.dart';

class StatsFastInfoLayout {
  const StatsFastInfoLayout({
    required this.topChart,
    required this.pulseChart,
    required this.bottomChart,
  });

  static const _chartLeft = 34.0;
  static const _titleOffset = 24.0;

  final Rect topChart;
  final Rect pulseChart;
  final Rect bottomChart;

  double get topTitleTop => topChart.top - _titleOffset;
  Rect get categoryControlChart =>
      Rect.fromLTWH(topChart.left, topChart.top, topChart.width, 118);
  Rect get categorySecondaryChart =>
      Rect.fromLTWH(bottomChart.left, 222, bottomChart.width, 80);

  static StatsFastInfoLayout resolve(Size size) {
    final width = (size.width - _chartLeft * 2)
        .clamp(1.0, double.infinity)
        .toDouble();
    return StatsFastInfoLayout(
      topChart: Rect.fromLTWH(_chartLeft, 66, width, 82),
      pulseChart: Rect.fromLTWH(_chartLeft, 176, width, 38),
      bottomChart: Rect.fromLTWH(_chartLeft, 246, width, 56),
    );
  }
}

class StatsFastInfoSpec {
  const StatsFastInfoSpec({required this.charts});

  final List<StatsFastInfoChartMetadata> charts;

  static StatsFastInfoSpec forMode(StatsRenderMode mode) {
    return switch (mode) {
      StatsRenderMode.categoryScope => const StatsFastInfoSpec(
        charts: [
          StatsFastInfoChartMetadata(
            title: '1. Kontroll histogram',
            yAxisLabel: '50 = atlag',
            xAxisLabel: 'honapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'romlik',
                color: Color(0xFFEF4444),
              ),
              StatsFastInfoLegendItem(label: 'javul', color: Color(0xFF22C55E)),
              StatsFastInfoLegendItem(label: '50', color: AppColors.gray500),
            ],
          ),
          StatsFastInfoChartMetadata(
            title: '2. Ft/kiugras',
            yAxisLabel: 'Ft',
            xAxisLabel: 'honapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'Ft/kiugras',
                color: Color(0xFFF97316),
              ),
            ],
          ),
        ],
      ),
      StatsRenderMode.heatmap => const StatsFastInfoSpec(
        charts: [
          StatsFastInfoChartMetadata(
            title: 'S1 · Klaszter-sűrűség',
            yAxisLabel: 'forró arány',
            xAxisLabel: 'aktív napok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'sűrűség',
                color: Color(0xFF06B6D4),
              ),
              StatsFastInfoLegendItem(
                label: 'kitöltés',
                color: Color(0xFF67E8F9),
              ),
            ],
          ),
          StatsFastInfoChartMetadata(
            title: 'S2 · Heat Pulse',
            yAxisLabel: 'impulzus',
            xAxisLabel: 'napok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'erősödik',
                color: Color(0xFF06B6D4),
              ),
              StatsFastInfoLegendItem(
                label: 'gyengül',
                color: AppColors.gray300,
              ),
              StatsFastInfoLegendItem(label: '0', color: AppColors.gray500),
            ],
          ),
          StatsFastInfoChartMetadata(
            title: 'H1 · Havi heat load',
            yAxisLabel: 'hőterhelés',
            xAxisLabel: 'hónapok',
            legendItems: [
              StatsFastInfoLegendItem(label: '1x', color: Color(0xFFDDF8FD)),
              StatsFastInfoLegendItem(label: '2x', color: Color(0xFF67E8F9)),
              StatsFastInfoLegendItem(
                label: '3x cap',
                color: Color(0xFF06B6D4),
              ),
            ],
          ),
        ],
      ),
      StatsRenderMode.closing => const StatsFastInfoSpec(
        charts: [
          StatsFastInfoChartMetadata(
            title: 'S2 · Close Pulse',
            yAxisLabel: 'drift',
            xAxisLabel: 'hónapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'romlik',
                color: Color(0xFFEF4444),
              ),
              StatsFastInfoLegendItem(label: 'javul', color: Color(0xFF22C55E)),
              StatsFastInfoLegendItem(label: '0', color: AppColors.gray500),
            ],
          ),
          StatsFastInfoChartMetadata(
            title: 'H1 · Havi zárás + hit napok',
            yAxisLabel: 'Ft / hit nap',
            xAxisLabel: 'hónapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'havi zárás',
                color: Color(0xFFEF4444),
              ),
              StatsFastInfoLegendItem(
                label: 'threshold pont',
                color: Color(0xFF22C55E),
              ),
            ],
          ),
        ],
      ),
    };
  }
}

class StatsFastInfoChartMetadata {
  const StatsFastInfoChartMetadata({
    required this.title,
    required this.yAxisLabel,
    required this.xAxisLabel,
    required this.legendItems,
  });

  final String title;
  final String yAxisLabel;
  final String xAxisLabel;
  final List<StatsFastInfoLegendItem> legendItems;

  List<String> get legendLabels => [for (final item in legendItems) item.label];

  StatsFastInfoChartMetadata copyWith({
    String? title,
    String? yAxisLabel,
    String? xAxisLabel,
    List<StatsFastInfoLegendItem>? legendItems,
  }) {
    return StatsFastInfoChartMetadata(
      title: title ?? this.title,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      xAxisLabel: xAxisLabel ?? this.xAxisLabel,
      legendItems: legendItems ?? this.legendItems,
    );
  }
}

class StatsFastInfoLegendItem {
  const StatsFastInfoLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class StatsFastInfoGraph extends StatelessWidget {
  const StatsFastInfoGraph({super.key, required this.data});

  final StatsYearData data;

  static StatsFastInfoLayout layoutForTesting(Size size) {
    return StatsFastInfoLayout.resolve(size);
  }

  static StatsFastInfoSpec specForTesting(StatsRenderMode mode) {
    return StatsFastInfoSpec.forMode(mode);
  }

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
    final layout = StatsFastInfoLayout.resolve(size);
    final spec = StatsFastInfoSpec.forMode(data.mode);
    switch (data.mode) {
      case StatsRenderMode.categoryScope:
        _drawCategoryScope(canvas, layout, spec);
      case StatsRenderMode.closing:
        _drawClosing(canvas, layout, spec);
      case StatsRenderMode.heatmap:
        _drawHeatmap(canvas, layout, spec);
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
    StatsFastInfoLayout layout,
    StatsFastInfoSpec spec,
  ) {
    final series = StatsCategoryScopeSeries.fromYearData(data);
    final topChart = layout.categoryControlChart;
    final bottomChart = layout.categorySecondaryChart;
    _drawChartHeader(canvas, spec.charts[0], topChart);
    _drawGrid(canvas, topChart);
    _drawControlBars(canvas, topChart, series.controlBars);
    _drawAxisLabels(canvas, spec.charts[0], topChart, drawXAxisLabel: false);
    _drawMonthLabels(canvas, topChart, series.monthLabels);
    final secondaryMetadata = spec.charts[1].copyWith(
      title: '2. ${series.secondaryMetricLabel}',
      legendItems: [
        StatsFastInfoLegendItem(
          label: series.secondaryMetricLabel,
          color: const Color(0xFFF97316),
        ),
      ],
    );
    _drawChartHeader(canvas, secondaryMetadata, bottomChart);
    _drawGrid(canvas, bottomChart, horizontal: 2);
    _drawSecondaryLine(canvas, bottomChart, series.secondaryLine);
    _drawAxisLabels(
      canvas,
      secondaryMetadata,
      bottomChart,
      drawXAxisLabel: false,
    );
    _drawMonthLabels(canvas, bottomChart, series.monthLabels);
  }

  void _drawHeatmap(
    Canvas canvas,
    StatsFastInfoLayout layout,
    StatsFastInfoSpec spec,
  ) {
    final series = StatsHeatmapSeries.fromYearData(data);
    final topChart = layout.topChart;
    final pulseChart = layout.pulseChart;
    final bottomChart = layout.bottomChart;
    _drawChartHeader(canvas, spec.charts[0], topChart);
    _drawGrid(canvas, topChart);
    _drawLine(
      canvas,
      topChart,
      series.density.map((point) => point.value).toList(),
      const Color(0xFF06B6D4),
      maxValue: 1,
      fillColor: const Color(0xFF67E8F9).withValues(alpha: 0.20),
    );
    _drawAxisLabels(canvas, spec.charts[0], topChart);
    _drawChartHeader(canvas, spec.charts[1], pulseChart);
    _drawSignedBars(
      canvas,
      pulseChart,
      series.pulse.map((bar) => bar.value).toList(),
      positiveColor: const Color(0xFF06B6D4),
      negativeColor: const Color(0xFFCBD5E1),
    );
    _drawAxisLabels(canvas, spec.charts[1], pulseChart);
    _drawChartHeader(canvas, spec.charts[2], bottomChart);
    _drawHeatMonthlyBars(canvas, bottomChart, series.monthlyBars);
    _drawAxisLabels(canvas, spec.charts[2], bottomChart);
  }

  void _drawClosing(
    Canvas canvas,
    StatsFastInfoLayout layout,
    StatsFastInfoSpec spec,
  ) {
    final series = StatsClosingSeries.fromYearData(data);
    final topChart = layout.topChart;
    final bottomChart = layout.bottomChart;
    _drawChartHeader(canvas, spec.charts[0], topChart);
    _drawSignedBars(
      canvas,
      topChart,
      series.closePulseBars.map((bar) => bar.value).toList(),
      positiveColor: const Color(0xFFEF4444),
      negativeColor: const Color(0xFF22C55E),
    );
    _drawAxisLabels(canvas, spec.charts[0], topChart);
    _drawChartHeader(canvas, spec.charts[1], bottomChart);
    _drawClosingMonthlyBars(canvas, bottomChart, series.monthlyCloseBars);
    _drawAxisLabels(canvas, spec.charts[1], bottomChart);
  }

  void _drawChartHeader(
    Canvas canvas,
    StatsFastInfoChartMetadata metadata,
    Rect chart,
  ) {
    _drawText(
      canvas,
      metadata.title,
      Offset(chart.left, chart.top - 24),
      const TextStyle(
        color: AppColors.gray700,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: chart.width,
    );
    _drawLegend(canvas, metadata.legendItems, chart);
  }

  void _drawLegend(
    Canvas canvas,
    List<StatsFastInfoLegendItem> items,
    Rect chart,
  ) {
    var x = chart.left;
    final y = chart.top - 10;
    final maxX = chart.right;
    for (final item in items) {
      final labelPainter = _textPainter(
        item.label,
        const TextStyle(
          color: AppColors.gray500,
          fontSize: 7.2,
          fontWeight: FontWeight.w600,
        ),
        maxWidth: chart.width,
      );
      final itemWidth = 9 + labelPainter.width + 8;
      if (x + itemWidth > maxX) break;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y + 5, 6, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = item.color,
      );
      labelPainter.paint(canvas, Offset(x + 9, y));
      x += itemWidth;
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    StatsFastInfoChartMetadata metadata,
    Rect chart, {
    bool drawXAxisLabel = true,
  }) {
    _drawText(
      canvas,
      metadata.yAxisLabel,
      Offset(chart.left - 30, chart.top + 1),
      const TextStyle(
        color: AppColors.gray500,
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
      maxWidth: 28,
    );
    if (!drawXAxisLabel) return;
    final xPainter = _textPainter(
      metadata.xAxisLabel,
      const TextStyle(
        color: AppColors.gray500,
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
      maxWidth: chart.width,
    );
    xPainter.paint(
      canvas,
      Offset(chart.right - xPainter.width, chart.bottom + 3),
    );
  }

  void _drawMonthLabels(Canvas canvas, Rect chart, List<String> labels) {
    if (labels.isEmpty) return;
    final textStyle = const TextStyle(
      color: AppColors.gray500,
      fontSize: 6.6,
      fontWeight: FontWeight.w700,
    );
    final segmentWidth = labels.length <= 1
        ? chart.width
        : chart.width / (labels.length - 1);
    for (var i = 0; i < labels.length; i += 1) {
      final painter = _textPainter(
        labels[i],
        textStyle,
        maxWidth: segmentWidth.clamp(18.0, 42.0),
      );
      final x = labels.length <= 1
          ? chart.center.dx
          : chart.left + chart.width * i / (labels.length - 1);
      final left = (x - painter.width / 2).clamp(
        chart.left,
        chart.right - painter.width,
      );
      painter.paint(canvas, Offset(left, chart.bottom + 3));
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    _textPainter(text, style, maxWidth: maxWidth).paint(canvas, offset);
  }

  TextPainter _textPainter(
    String text,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter;
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

  void _drawControlBars(Canvas canvas, Rect chart, List<StatsControlBar> bars) {
    final baselineY = chart.bottom - chart.height * 0.5;
    canvas.drawLine(
      Offset(chart.left, baselineY),
      Offset(chart.right, baselineY),
      Paint()
        ..color = AppColors.gray500.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );
    if (bars.isEmpty) return;
    final barWidth = (chart.width / (bars.length * 1.35)).clamp(1.1, 11.0);
    for (var i = 0; i < bars.length; i += 1) {
      final bar = bars[i];
      final centerX = _xForBarIndex(chart, i, bars.length);
      final normalized = ((bar.value - 50).abs() / 50).clamp(0.0, 1.0);
      final height = math.max(1.0, chart.height * 0.48 * normalized);
      final top = bar.value >= 50 ? baselineY - height : baselineY;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height),
          const Radius.circular(1.8),
        ),
        Paint()..color = _color(bar.colorHex),
      );
    }
  }

  void _drawSecondaryLine(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final values = points.map((point) => point.value).toList(growable: false);
    final maxValue = values
        .fold<double>(0, math.max)
        .clamp(1.0, double.infinity);
    final path = Path();
    for (var i = 0; i < values.length; i += 1) {
      final x = _xForIndex(chart, i, values.length);
      final y =
          chart.bottom - chart.height * (values[i] / maxValue).clamp(0.0, 1.0);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF97316)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final latest = values.last;
    if (latest <= 0) return;
    final label = '${(latest / 1000).toStringAsFixed(1)}k';
    final labelPainter = _textPainter(
      label,
      const TextStyle(
        color: Color(0xFFF97316),
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
      maxWidth: 34,
    );
    final latestY =
        chart.bottom - chart.height * (latest / maxValue).clamp(0.0, 1.0);
    labelPainter.paint(
      canvas,
      Offset(
        chart.right - labelPainter.width,
        (latestY - labelPainter.height / 2).clamp(
          chart.top,
          chart.bottom - labelPainter.height,
        ),
      ),
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

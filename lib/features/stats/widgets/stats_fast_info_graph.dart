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
    required this.categoryPanel,
    required this.categoryControlChart,
    required this.categorySecondaryChart,
    required this.categoryAxisLabelLeft,
  });

  static const _chartLeft = 34.0;
  static const _titleOffset = 24.0;
  static const _categoryPanelHorizontalPadding = 14.0;

  final Rect topChart;
  final Rect pulseChart;
  final Rect bottomChart;
  final Rect categoryPanel;
  final Rect categoryControlChart;
  final Rect categorySecondaryChart;
  final double categoryAxisLabelLeft;

  double get topTitleTop => topChart.top - _titleOffset;

  static StatsFastInfoLayout resolve(Size size) {
    final width = (size.width - _chartLeft * 2)
        .clamp(1.0, double.infinity)
        .toDouble();
    final categoryPanelLeft = _categoryPanelHorizontalPadding;
    final categoryPanelWidth =
        (size.width - _categoryPanelHorizontalPadding * 2)
            .clamp(1.0, double.infinity)
            .toDouble();
    final categoryPanel = Rect.fromLTWH(
      categoryPanelLeft,
      42,
      categoryPanelWidth,
      (size.height - 60).clamp(1.0, double.infinity).toDouble(),
    );
    final categoryAxisLabelLeft = categoryPanel.left + 12;
    final categoryChartLeft = categoryPanel.left + 52;
    final categoryChartRight = categoryPanel.right - 14;
    final categoryChartWidth = (categoryChartRight - categoryChartLeft)
        .clamp(1.0, double.infinity)
        .toDouble();
    final categoryControlChart = Rect.fromLTWH(
      categoryChartLeft,
      categoryPanel.top + 48,
      categoryChartWidth,
      (categoryPanel.height - 84).clamp(180.0, 210.0).toDouble(),
    );
    final categorySecondaryChart = Rect.fromLTWH(
      categoryChartLeft,
      categoryPanel.bottom - 22,
      categoryChartWidth,
      0,
    );
    return StatsFastInfoLayout(
      topChart: Rect.fromLTWH(_chartLeft, 66, width, 82),
      pulseChart: Rect.fromLTWH(_chartLeft, 176, width, 38),
      bottomChart: Rect.fromLTWH(_chartLeft, 246, width, 56),
      categoryPanel: categoryPanel,
      categoryControlChart: categoryControlChart,
      categorySecondaryChart: categorySecondaryChart,
      categoryAxisLabelLeft: categoryAxisLabelLeft,
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
            title: '1. Kontroll + kiugras',
            yAxisLabel: 'index',
            xAxisLabel: 'honapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'romlik',
                color: Color(0xFFEF4444),
              ),
              StatsFastInfoLegendItem(label: 'javul', color: Color(0xFF22C55E)),
              StatsFastInfoLegendItem(label: '50', color: AppColors.gray500),
              StatsFastInfoLegendItem(
                label: 'kiugras',
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

class StatsFastInfoVisualStyle {
  const StatsFastInfoVisualStyle({
    required this.legendFontSize,
    required this.legendMarkerWidth,
    required this.legendMarkerHeight,
    required this.secondaryLineSmoothingEnabled,
    required this.secondaryLineDashed,
    required this.controlVisualSensitivity,
    required this.categoryYAxisValueLabelCount,
  });

  final double legendFontSize;
  final double legendMarkerWidth;
  final double legendMarkerHeight;
  final bool secondaryLineSmoothingEnabled;
  final bool secondaryLineDashed;
  final double controlVisualSensitivity;
  final int categoryYAxisValueLabelCount;
}

class StatsFastInfoGraph extends StatelessWidget {
  const StatsFastInfoGraph({super.key, required this.data});

  final StatsYearData data;

  static const visualStyle = StatsFastInfoVisualStyle(
    legendFontSize: 10.37,
    legendMarkerWidth: 8.64,
    legendMarkerHeight: 4.32,
    secondaryLineSmoothingEnabled: true,
    secondaryLineDashed: true,
    controlVisualSensitivity: 3.0,
    categoryYAxisValueLabelCount: 3,
  );

  static StatsFastInfoLayout layoutForTesting(Size size) {
    return StatsFastInfoLayout.resolve(size);
  }

  static StatsFastInfoSpec specForTesting(StatsRenderMode mode) {
    return StatsFastInfoSpec.forMode(mode);
  }

  static StatsFastInfoVisualStyle visualStyleForTesting() {
    return visualStyle;
  }

  static double visualControlValueForTesting(double value) {
    return _emphasizeControlValue(value);
  }

  static double _emphasizeControlValue(double value) {
    return (50 + (value - 50) * visualStyle.controlVisualSensitivity)
        .clamp(0, 100)
        .toDouble();
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

  void _drawCategoryPanel(Canvas canvas, Rect panel) {
    final rrect = RRect.fromRectAndRadius(panel, const Radius.circular(14));
    final shadowPath = Path()..addRRect(rrect);
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.08),
      4,
      false,
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.gray200.withValues(alpha: 0.85)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawCategoryScope(
    Canvas canvas,
    StatsFastInfoLayout layout,
    StatsFastInfoSpec spec,
  ) {
    final series = StatsCategoryScopeSeries.fromYearData(data);
    _drawCategoryPanel(canvas, layout.categoryPanel);
    final chart = layout.categoryControlChart;
    final metadata = spec.charts[0].copyWith(
      legendItems: [
        ...spec.charts[0].legendItems.take(3),
        StatsFastInfoLegendItem(
          label: series.secondaryMetricLabel,
          color: const Color(0xFFF97316),
        ),
      ],
    );
    _drawChartHeader(canvas, metadata, chart);
    _drawGrid(canvas, chart, horizontal: 4);
    _drawControlBars(canvas, chart, series.controlBars);
    _drawSecondaryIndexLine(canvas, chart, series.secondaryLine);
    _drawControlAxisValueLabels(canvas, chart);
    _drawAxisLabels(
      canvas,
      metadata,
      chart,
      drawXAxisLabel: false,
      yAxisLabelLeft: layout.categoryAxisLabelLeft,
      yAxisLabelTop: chart.top - 14,
      yAxisLabelWidth: chart.left - layout.categoryAxisLabelLeft - 6,
    );
    _drawMonthLabels(canvas, chart, series.monthLabels);
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
        TextStyle(
          color: AppColors.gray500,
          fontSize: StatsFastInfoGraph.visualStyle.legendFontSize,
          fontWeight: FontWeight.w600,
        ),
        maxWidth: chart.width,
      );
      final itemWidth =
          StatsFastInfoGraph.visualStyle.legendMarkerWidth +
          4 +
          labelPainter.width +
          8;
      if (x + itemWidth > maxX) break;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            y + 5,
            StatsFastInfoGraph.visualStyle.legendMarkerWidth,
            StatsFastInfoGraph.visualStyle.legendMarkerHeight,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = item.color,
      );
      labelPainter.paint(
        canvas,
        Offset(x + StatsFastInfoGraph.visualStyle.legendMarkerWidth + 4, y),
      );
      x += itemWidth;
    }
  }

  void _drawAxisLabels(
    Canvas canvas,
    StatsFastInfoChartMetadata metadata,
    Rect chart, {
    bool drawXAxisLabel = true,
    double? yAxisLabelLeft,
    double? yAxisLabelTop,
    double? yAxisLabelWidth,
  }) {
    _drawText(
      canvas,
      metadata.yAxisLabel,
      Offset(yAxisLabelLeft ?? chart.left - 30, yAxisLabelTop ?? chart.top + 1),
      const TextStyle(
        color: AppColors.gray500,
        fontSize: 7,
        fontWeight: FontWeight.w600,
      ),
      maxWidth: yAxisLabelWidth ?? 28,
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

  void _drawControlAxisValueLabels(Canvas canvas, Rect chart) {
    _drawYAxisValueLabels(canvas, chart, const [
      _YAxisValueLabel(label: '100', normalizedValue: 1),
      _YAxisValueLabel(label: '50', normalizedValue: 0.5),
      _YAxisValueLabel(label: '0', normalizedValue: 0),
    ]);
  }

  void _drawYAxisValueLabels(
    Canvas canvas,
    Rect chart,
    List<_YAxisValueLabel> labels,
  ) {
    final style = const TextStyle(
      color: AppColors.gray500,
      fontSize: 6.8,
      fontWeight: FontWeight.w700,
    );
    for (final label in labels) {
      final painter = _textPainter(label.label, style, maxWidth: 34);
      final y = chart.bottom - chart.height * label.normalizedValue;
      painter.paint(
        canvas,
        Offset(
          chart.left - painter.width - 5,
          (y - painter.height / 2).clamp(
            chart.top,
            chart.bottom - painter.height,
          ),
        ),
      );
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
      final visualValue = StatsFastInfoGraph._emphasizeControlValue(bar.value);
      final centerX = _xForBarIndex(chart, i, bars.length);
      final normalized = ((visualValue - 50).abs() / 50).clamp(0.0, 1.0);
      final height = math.max(1.0, chart.height * 0.48 * normalized);
      final top = visualValue >= 50 ? baselineY - height : baselineY;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height),
          const Radius.circular(1.8),
        ),
        Paint()..color = _color(bar.colorHex),
      );
    }
  }

  void _drawSecondaryIndexLine(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final values = points
        .map((point) => point.value.clamp(0, 100).toDouble())
        .toList(growable: false);
    final path = _smoothPathForValues(chart, values, 100);
    final paint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (!StatsFastInfoGraph.visualStyle.secondaryLineDashed) {
      canvas.drawPath(path, paint);
      return;
    }
    _drawDashedPath(canvas, path, paint, dash: 7, gap: 5);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  Path _smoothPathForValues(Rect chart, List<double> values, double maxValue) {
    final offsets = [
      for (var i = 0; i < values.length; i += 1)
        Offset(
          _xForIndex(chart, i, values.length),
          chart.bottom - chart.height * (values[i] / maxValue).clamp(0.0, 1.0),
        ),
    ];
    final path = Path();
    if (offsets.isEmpty) return path;
    path.moveTo(offsets.first.dx, offsets.first.dy);
    if (!StatsFastInfoGraph.visualStyle.secondaryLineSmoothingEnabled ||
        offsets.length < 3) {
      for (final offset in offsets.skip(1)) {
        path.lineTo(offset.dx, offset.dy);
      }
      return path;
    }
    for (var i = 0; i < offsets.length - 1; i += 1) {
      final p0 = i == 0 ? offsets[i] : offsets[i - 1];
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final p3 = i + 2 < offsets.length ? offsets[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
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

class _YAxisValueLabel {
  const _YAxisValueLabel({required this.label, required this.normalizedValue});

  final String label;
  final double normalizedValue;
}

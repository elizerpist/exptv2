import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transactions/models/transaction_category.dart';
import '../data/stats_category_scope_series.dart';
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
    required this.categoryTitleOffset,
    required this.categoryLegendY,
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
  final Offset categoryTitleOffset;
  final double categoryLegendY;

  double get topTitleTop => topChart.top - _titleOffset;

  static StatsFastInfoLayout resolve(
    Size size, {
    TransactionType categoryActiveType = TransactionType.expense,
  }) {
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
    final categoryChartLeft = categoryPanel.left + 33;
    final categoryChartRight = categoryPanel.right - 14;
    final categoryChartWidth = (categoryChartRight - categoryChartLeft)
        .clamp(1.0, double.infinity)
        .toDouble();
    final contentBottom = categoryPanel.top + categoryPanel.height - 16;
    final isIncome = categoryActiveType == TransactionType.income;
    final upperLift = isIncome ? 12.0 : 0.0;
    final titleY = categoryPanel.top + 22 - upperLift;
    final titleDrawY = isIncome ? titleY + 5 : titleY;
    final legendY = titleY + 17;
    final helperH = isIncome ? 42.0 : 26.0;
    final helperGap = isIncome ? 26.0 : 34.0;
    final chartY = legendY + 23;
    final chartBottom = contentBottom - helperH - 4 - helperGap - upperLift;
    final categoryControlChart = Rect.fromLTWH(
      categoryChartLeft,
      chartY,
      categoryChartWidth,
      (chartBottom - chartY).clamp(1.0, double.infinity).toDouble(),
    );
    final categorySecondaryChart = Rect.fromLTWH(
      categoryChartLeft,
      contentBottom - helperH - 4,
      categoryChartWidth,
      helperH,
    );
    return StatsFastInfoLayout(
      topChart: Rect.fromLTWH(_chartLeft, 66, width, 82),
      pulseChart: Rect.fromLTWH(_chartLeft, 176, width, 38),
      bottomChart: Rect.fromLTWH(_chartLeft, 246, width, 56),
      categoryPanel: categoryPanel,
      categoryControlChart: categoryControlChart,
      categorySecondaryChart: categorySecondaryChart,
      categoryAxisLabelLeft: categoryAxisLabelLeft,
      categoryTitleOffset: Offset(categoryChartLeft, titleDrawY),
      categoryLegendY: legendY,
    );
  }
}

class StatsFastInfoSpec {
  const StatsFastInfoSpec({required this.charts});

  final List<StatsFastInfoChartMetadata> charts;

  static StatsFastInfoSpec forMode(StatsRenderMode mode) {
    return switch (mode) {
      StatsRenderMode.common => const StatsFastInfoSpec(
        charts: [
          StatsFastInfoChartMetadata(
            title: '1. Szűrés pontszám',
            yAxisLabel: 'pontszám',
            xAxisLabel: 'hónapok',
            legendItems: [
              StatsFastInfoLegendItem(label: 'rossz', color: Color(0xFFEF4444)),
              StatsFastInfoLegendItem(
                label: 'semleges 50',
                color: Color(0xFFFBBF24),
              ),
              StatsFastInfoLegendItem(label: 'jó', color: Color(0xFF22C55E)),
            ],
          ),
          StatsFastInfoChartMetadata(
            title: '2. Küszöb feletti többlet',
            yAxisLabel: 'többlet',
            xAxisLabel: 'hónapok',
            legendItems: [
              StatsFastInfoLegendItem(
                label: 'küszöb',
                color: Color(0xFFEF4444),
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
    legendFontSize: 12.4,
    legendMarkerWidth: 10.5,
    legendMarkerHeight: 5.2,
    secondaryLineSmoothingEnabled: true,
    secondaryLineDashed: false,
    controlVisualSensitivity: 1.0,
    categoryYAxisValueLabelCount: 3,
  );

  static StatsFastInfoLayout layoutForTesting(
    Size size, {
    TransactionType categoryActiveType = TransactionType.expense,
  }) {
    return StatsFastInfoLayout.resolve(
      size,
      categoryActiveType: categoryActiveType,
    );
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
    final layout = StatsFastInfoLayout.resolve(
      size,
      categoryActiveType: data.activeType,
    );
    final spec = StatsFastInfoSpec.forMode(data.mode);
    _drawCategoryScope(canvas, layout, spec);
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
  }

  void _drawCategoryScope(
    Canvas canvas,
    StatsFastInfoLayout layout,
    StatsFastInfoSpec spec,
  ) {
    final series = StatsCategoryScopeSeries.fromYearData(data);
    _drawCategoryPanel(canvas, layout.categoryPanel);
    final chart = layout.categoryControlChart;
    final primary = spec.charts[0].copyWith(
      title: data.activeType == TransactionType.income
          ? 'Bevétel vs kiadás'
          : spec.charts[0].title,
      legendItems: data.activeType == TransactionType.income
          ? const [
              StatsFastInfoLegendItem(
                label: 'Fedezi a kiadást',
                color: Color(0xFF22C55E),
              ),
              StatsFastInfoLegendItem(
                label: 'Kevés bevétel',
                color: Color(0xFFEF4444),
              ),
              StatsFastInfoLegendItem(
                label: 'Nullszaldó',
                color: Color(0xFFFBBF24),
              ),
            ]
          : spec.charts[0].legendItems,
    );
    _drawCategoryChartHeader(canvas, primary, layout);
    if (data.activeType == TransactionType.income) {
      _drawIncomeCenterlineBars(canvas, chart, series.incomeComparisonBars);
    } else {
      _drawSoftScoreZones(canvas, chart);
      _drawScoreGrid(canvas, chart);
      _drawSegmentedScorePath(canvas, chart, series.scoreLine);
      _drawScoreEndpoint(canvas, chart, series.scoreLine);
      _drawEndpointBadge(
        canvas,
        chart,
        series.scoreLine,
        '${series.kontrollScore.round()}/100',
        _scoreColor(series.kontrollScore),
      );
      _drawControlAxisValueLabels(canvas, chart);
    }
    _drawMonthTicks(canvas, chart, series.monthTicks);

    final helperChart = layout.categorySecondaryChart;
    final helperTitle = spec.charts[1].title;
    _drawText(
      canvas,
      helperTitle,
      Offset(helperChart.left, helperChart.top - 8),
      TextStyle(
        color: AppColors.gray700,
        fontSize: data.activeType == TransactionType.income ? 8.8 : 8.5,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: helperChart.width,
    );
    _drawThresholdExcessBars(canvas, helperChart, series.helperBars);
    _drawMonthTicks(canvas, helperChart, series.monthTicks);
  }

  void _drawIncomeCenterlineBars(
    Canvas canvas,
    Rect chart,
    List<StatsIncomeComparisonBar> bars,
  ) {
    final gridPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i += 1) {
      final y = chart.top + chart.height * i / 2;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final centerY = chart.center.dy;
    canvas.drawLine(
      Offset(chart.left, centerY),
      Offset(chart.right, centerY),
      Paint()
        ..color = AppColors.gray700.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    if (bars.isEmpty) return;
    final maxAbs = math.max(
      1,
      bars.fold<double>(0, (max, bar) => math.max(max, bar.signedValue.abs())),
    );
    final barWidth = (chart.width / (bars.length * 1.8)).clamp(3.0, 18.0);
    for (final bar in bars) {
      if (bar.signedValue == 0) continue;
      final height = math.max(
        1.0,
        chart.height * 0.44 * bar.signedValue.abs() / maxAbs,
      );
      final x = chart.left + chart.width * bar.position.clamp(0.0, 1.0);
      final rect = Rect.fromLTWH(
        x - barWidth / 2,
        bar.signedValue > 0 ? centerY - height : centerY,
        barWidth,
        height,
      );
      final intensity = (0.45 + bar.signedValue.abs() / maxAbs * 0.42)
          .clamp(0.45, 0.92)
          .toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = _color(bar.colorHex).withValues(alpha: intensity),
      );
    }
  }

  void _drawCategoryChartHeader(
    Canvas canvas,
    StatsFastInfoChartMetadata metadata,
    StatsFastInfoLayout layout,
  ) {
    _drawText(
      canvas,
      metadata.title,
      layout.categoryTitleOffset,
      const TextStyle(
        color: AppColors.gray700,
        fontSize: 10.2,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: layout.categoryControlChart.width,
    );
    _drawLegendAt(
      canvas,
      metadata.legendItems,
      layout.categoryControlChart,
      layout.categoryLegendY,
    );
  }

  void _drawLegendAt(
    Canvas canvas,
    List<StatsFastInfoLegendItem> items,
    Rect chart,
    double y,
  ) {
    var x = chart.left;
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

  void _drawSoftScoreZones(Canvas canvas, Rect chart) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x2122C55E),
          Color(0x0A22C55E),
          Color(0x14FBBF24),
          Color(0x0AEF4444),
          Color(0x21EF4444),
        ],
        stops: [0, 0.38, 0.50, 0.62, 1],
      ).createShader(chart);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chart, const Radius.circular(8)),
      paint,
    );
  }

  void _drawScoreGrid(Canvas canvas, Rect chart) {
    final gridPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i += 1) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final neutralY = chart.bottom - chart.height * 0.5;
    canvas.drawLine(
      Offset(chart.left, neutralY),
      Offset(chart.right, neutralY),
      Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.50)
        ..strokeWidth = 1,
    );
  }

  void _drawSegmentedScorePath(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final path = _smoothPathForPoints(chart, points, 100);
    final zones = const [
      _ScoreZone(from: 0, to: 45, color: Color(0xFFEF4444)),
      _ScoreZone(from: 45, to: 60, color: Color(0xFFFBBF24)),
      _ScoreZone(from: 60, to: 100, color: Color(0xFF22C55E)),
    ];
    for (final zone in zones) {
      final yTop = chart.bottom - chart.height * zone.to / 100;
      final yBottom = chart.bottom - chart.height * zone.from / 100;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(chart.left - 4, yTop, chart.right + 4, yBottom),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = zone.color.withValues(alpha: 0.96)
          ..strokeWidth = 3.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }
  }

  void _drawScoreEndpoint(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
  ) {
    if (points.isEmpty) return;
    final point = points.last;
    final offset = _offsetForPoint(
      chart,
      point,
      points.length - 1,
      points.length,
    );
    canvas.drawCircle(offset, 6.8, Paint()..color = Colors.white);
    canvas.drawCircle(offset, 4.3, Paint()..color = _scoreColor(point.value));
  }

  void _drawEndpointBadge(
    Canvas canvas,
    Rect chart,
    List<StatsSeriesPoint> points,
    String label,
    Color color,
  ) {
    if (points.isEmpty) return;
    final point = points.last;
    final offset = _offsetForPoint(
      chart,
      point,
      points.length - 1,
      points.length,
    );
    final painter = _textPainter(
      label,
      TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w800),
      maxWidth: 52,
    );
    final width = painter.width + 10;
    final left = offset.dx - width - 2;
    final top = (offset.dy - 8).clamp(chart.top + 2, chart.bottom - 14);
    final rect = Rect.fromLTWH(left, top, width, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    painter.paint(
      canvas,
      Offset(
        left + width / 2 - painter.width / 2,
        top + 7 - painter.height / 2,
      ),
    );
  }

  void _drawMonthTicks(Canvas canvas, Rect chart, List<StatsMonthTick> ticks) {
    if (ticks.isEmpty) return;
    const textStyle = TextStyle(
      color: AppColors.gray500,
      fontSize: 7.4,
      fontWeight: FontWeight.w700,
    );
    for (final tick in ticks) {
      final painter = _textPainter(tick.label, textStyle, maxWidth: 42);
      final x = chart.left + chart.width * tick.position.clamp(0.0, 1.0);
      final left = (x - painter.width / 2).clamp(
        chart.left,
        chart.right - painter.width,
      );
      painter.paint(canvas, Offset(left, chart.bottom + 11));
    }
  }

  void _drawThresholdExcessBars(
    Canvas canvas,
    Rect chart,
    List<StatsHelperBar> bars,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(chart, const Radius.circular(6)),
      Paint()..color = const Color(0xB8F8FAFC),
    );
    final baselineY = chart.bottom - 1;
    canvas.drawLine(
      Offset(chart.left, baselineY),
      Offset(chart.right, baselineY),
      Paint()
        ..color = AppColors.gray500.withValues(alpha: 0.40)
        ..strokeWidth = 1,
    );
    if (bars.isEmpty) return;
    final barWidth = bars.length <= 12
        ? (chart.width / math.max(bars.length * 7, 18)).clamp(5.0, 10.0)
        : (chart.width / (bars.length * 1.35)).clamp(1.1, 7.0);
    for (final bar in bars) {
      final delta = bar.value.clamp(0, 100).toDouble();
      final x = chart.left + chart.width * bar.position.clamp(0.0, 1.0);
      final height = math.max(1.0, delta / 100 * chart.height * 0.82);
      final rect = Rect.fromLTWH(
        x - barWidth / 2,
        baselineY - height,
        barWidth,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.min(2.4, barWidth / 2)),
        ),
        Paint()
          ..color = _color(
            bar.colorHex,
          ).withValues(alpha: (0.34 + delta / 100 * 0.5).clamp(0.34, 0.84)),
      );
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

  Path _smoothPathForPoints(
    Rect chart,
    List<StatsSeriesPoint> points,
    double maxValue,
  ) {
    final offsets = [
      for (var i = 0; i < points.length; i += 1)
        _offsetForPoint(chart, points[i], i, points.length, maxValue: maxValue),
    ];
    final path = Path();
    if (offsets.isEmpty) return path;
    path.moveTo(offsets.first.dx, offsets.first.dy);
    if (offsets.length < 3) {
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

  Offset _offsetForPoint(
    Rect chart,
    StatsSeriesPoint point,
    int index,
    int count, {
    double maxValue = 100,
  }) {
    final position = point.position ?? (count <= 1 ? 0.5 : index / (count - 1));
    return Offset(
      chart.left + chart.width * position.clamp(0.0, 1.0),
      chart.bottom - chart.height * (point.value / maxValue).clamp(0.0, 1.0),
    );
  }

  Color _scoreColor(double value) {
    if (value < 45) return const Color(0xFFEF4444);
    if (value < 60) return const Color(0xFFFBBF24);
    return const Color(0xFF22C55E);
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

class _ScoreZone {
  const _ScoreZone({required this.from, required this.to, required this.color});

  final double from;
  final double to;
  final Color color;
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      child: CustomPaint(painter: _StatsFastInfoGraphPainter(data)),
    );
  }
}

class _StatsFastInfoGraphPainter extends CustomPainter {
  const _StatsFastInfoGraphPainter(this.data);

  final StatsYearData data;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(
      34,
      44,
      (size.width - 68).clamp(1.0, double.infinity),
      172,
    );
    _drawGrid(canvas, chart);
    switch (data.mode) {
      case StatsRenderMode.categoryScope:
        _drawTrendLine(canvas, chart);
      case StatsRenderMode.closing:
        _drawClosingBars(canvas, chart);
      case StatsRenderMode.heatmap:
        _drawHeatDistribution(canvas, chart);
    }
  }

  void _drawGrid(Canvas canvas, Rect chart) {
    final gridPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i += 1) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    for (var i = 0; i <= 6; i += 1) {
      final x = chart.left + chart.width * i / 6;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
    }
  }

  void _drawTrendLine(Canvas canvas, Rect chart) {
    final months = data.graphMonths;
    final values = months
        .map((month) => month.thresholdHitDays.toDouble())
        .toList();
    final maxValue = _max(values).clamp(1.0, double.infinity);
    final path = Path();
    for (var i = 0; i < values.length; i += 1) {
      final x = _xForIndex(chart, i, values.length);
      final y = chart.bottom - chart.height * values[i] / maxValue;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(
          chart.center.dx,
          chart.bottom - chart.height * values.first / maxValue,
        ),
        5,
        Paint()..color = AppColors.expense,
      );
      return;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF97316)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.expense
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawClosingBars(Canvas canvas, Rect chart) {
    final months = data.graphMonths;
    final values = months.map((month) => month.closingAmount).toList();
    final maxValue = _max(values).clamp(1.0, double.infinity);
    final barWidth = (chart.width / (months.length * 1.5)).clamp(8.0, 22.0);
    for (var i = 0; i < months.length; i += 1) {
      final month = months[i];
      final centerX = _xForBarIndex(chart, i, months.length);
      final barHeight = chart.height * month.closingAmount / maxValue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          chart.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = month.thresholdHitDays > 0
              ? AppColors.primary
              : AppColors.gray300,
      );
      if (month.thresholdHitDays > 0) {
        canvas.drawCircle(
          Offset(centerX, chart.bottom - barHeight - 10),
          3,
          Paint()..color = AppColors.expense,
        );
      }
    }
  }

  void _drawHeatDistribution(Canvas canvas, Rect chart) {
    final months = data.graphMonths;
    final maxValue = _max(
      months.map((month) => month.scopeTotal).toList(),
    ).clamp(1.0, double.infinity);
    final tile = (chart.width / 16).clamp(12.0, 18.0).toDouble();
    for (var i = 0; i < months.length; i += 1) {
      final month = months[i];
      final intensity = (month.scopeTotal / maxValue).clamp(0.05, 1.0);
      final x = _xForIndex(chart, i, months.length) - tile / 2;
      final y = chart.bottom - chart.height * intensity;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, tile, tile),
          const Radius.circular(4),
        ),
        Paint()
          ..color = Color.lerp(
            const Color(0xFFDCFCE7),
            AppColors.expense,
            intensity,
          )!,
      );
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

  @override
  bool shouldRepaint(_StatsFastInfoGraphPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../models/fast_info_metric.dart';
import '../category_menu/category_icon_badge.dart';

class FastInfoVisual extends StatelessWidget {
  const FastInfoVisual({super.key, required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final value = metric;
    if (value == null || !_hasVisual(value)) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (value.avatar case final avatar?) ...[
            CategoryIconBadge(
              key: ValueKey('fastinfo-avatar-${slot.id}'),
              colorSlot: 0,
              iconSlot: avatar.iconSlot,
              size: 24,
              iconSize: 14,
              backgroundColor: AppColors.fromHex(avatar.colorHex),
              showShadow: false,
            ),
            if (_hasGraph(value) || value.trend != null)
              const SizedBox(width: 5),
          ],
          if (_hasGraph(value))
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value.progressKind != null && value.progress != null)
                    _ProgressVisual(slotId: slot.id, metric: value),
                  if (value.progressKind != null &&
                      value.progress != null &&
                      _hasChart(value))
                    const SizedBox(height: 3),
                  if (_hasChart(value))
                    Expanded(
                      child: _ChartVisual(slotId: slot.id, metric: value),
                    ),
                ],
              ),
            ),
          if (value.trend case final trend?) ...[
            if (_hasGraph(value)) const SizedBox(width: 5),
            _TrendVisual(slotId: slot.id, trend: trend),
          ],
        ],
      ),
    );
  }

  bool _hasVisual(FastInfoMetricResult value) {
    return value.avatar != null || _hasGraph(value) || value.trend != null;
  }

  bool _hasGraph(FastInfoMetricResult value) {
    return (value.progressKind != null && value.progress != null) ||
        _hasChart(value);
  }

  bool _hasChart(FastInfoMetricResult value) {
    return switch (value.chartKind) {
      FastInfoChartKind.sparkline => value.chartSeries.any(
        (series) => series.values.isNotEmpty,
      ),
      FastInfoChartKind.weeklyBars => value.weeklyBars.isNotEmpty,
      FastInfoChartKind.multiLine => value.chartSeries.any(
        (series) => series.values.isNotEmpty,
      ),
      null => false,
    };
  }
}

class FastInfoPillTrend extends StatelessWidget {
  const FastInfoPillTrend({
    super.key,
    required this.slotId,
    required this.trend,
  });

  final String slotId;
  final FastInfoTrend trend;

  @override
  Widget build(BuildContext context) {
    return _TrendVisual(
      key: ValueKey('fastinfo-pill-trend-$slotId'),
      slotId: slotId,
      trend: trend,
      compact: true,
      includeSemanticKey: false,
    );
  }
}

class _ProgressVisual extends StatelessWidget {
  const _ProgressVisual({required this.slotId, required this.metric});

  final String slotId;
  final FastInfoMetricResult metric;

  @override
  Widget build(BuildContext context) {
    final progress = metric.progress!.clamp(0.0, 1.0);
    final color = _semanticColor(metric.semantic);
    if (metric.progressKind == FastInfoProgressKind.ring) {
      return Align(
        key: ValueKey('fastinfo-progress-$slotId'),
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            value: progress,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }
    return ClipRRect(
      key: ValueKey('fastinfo-progress-$slotId'),
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: progress,
        backgroundColor: AppColors.gray200,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _ChartVisual extends StatelessWidget {
  const _ChartVisual({required this.slotId, required this.metric});

  final String slotId;
  final FastInfoMetricResult metric;

  @override
  Widget build(BuildContext context) {
    return switch (metric.chartKind) {
      FastInfoChartKind.sparkline => _LineChart(
        chartKey: ValueKey('fastinfo-sparkline-$slotId'),
        series: metric.chartSeries.take(1).toList(),
      ),
      FastInfoChartKind.weeklyBars => _WeeklyBars(
        key: ValueKey('fastinfo-weekly-bars-$slotId'),
        bars: metric.weeklyBars,
      ),
      FastInfoChartKind.multiLine => _MultiLineChart(
        chartKey: ValueKey('fastinfo-multiline-$slotId'),
        legendKey: ValueKey('fastinfo-multiline-legend-$slotId'),
        series: metric.chartSeries,
      ),
      null => const SizedBox.shrink(),
    };
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({super.key, required this.bars});

  final List<FastInfoWeeklyBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxValue = bars.fold<double>(
      0,
      (max, bar) => math.max(max, bar.value),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < bars.length; index += 1)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: bars[index].isFuture
                    ? .18
                    : maxValue <= 0
                    ? .18
                    : math.max(.18, bars[index].value / maxValue),
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == bars.length - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: bars[index].isFuture
                        ? AppColors.gray300
                        : _semanticColor(bars[index].semantic),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.chartKey, required this.series});

  final Key chartKey;
  final List<FastInfoChartSeries> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((item) => item.values.isEmpty)) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(
      key: chartKey,
      child: CustomPaint(painter: _LineChartPainter(series)),
    );
  }
}

class _MultiLineChart extends StatelessWidget {
  const _MultiLineChart({
    required this.chartKey,
    required this.legendKey,
    required this.series,
  });

  final Key chartKey;
  final Key legendKey;
  final List<FastInfoChartSeries> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((item) => item.values.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      key: chartKey,
      children: [
        SizedBox(
          key: legendKey,
          height: 3,
          child: Row(
            children: [
              for (
                var index = 0;
                index < math.min(3, series.length);
                index += 1
              )
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index == math.min(3, series.length) - 1 ? 0 : 3,
                    ),
                    color: _LineChartPainter._colors[index],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(child: CustomPaint(painter: _LineChartPainter(series))),
      ],
    );
  }
}

class _TrendVisual extends StatelessWidget {
  const _TrendVisual({
    super.key,
    required this.slotId,
    required this.trend,
    this.compact = false,
    this.includeSemanticKey = true,
  });

  final String slotId;
  final FastInfoTrend trend;
  final bool compact;
  final bool includeSemanticKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: includeSemanticKey ? ValueKey('fastinfo-trend-$slotId') : null,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          trend.direction == FastInfoTrendDirection.up
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          size: compact ? 12 : 14,
          color: _semanticColor(trend.semantic),
        ),
        const SizedBox(width: 1),
        Flexible(
          child: Text(
            trend.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _semanticColor(trend.semantic),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.series);

  final List<FastInfoChartSeries> series;

  static const _colors = <Color>[
    AppColors.primary,
    AppColors.gray500,
    AppColors.gray300,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.expand((item) => item.values).toList();
    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final spread = maxValue - minValue;

    for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex += 1) {
      final points = series[seriesIndex].values;
      if (points.isEmpty) continue;
      final paint = Paint()
        ..color = _colors[seriesIndex % _colors.length]
        ..strokeWidth = seriesIndex == 0 ? 2 : 1.25
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var index = 0; index < points.length; index += 1) {
        final x = points.length == 1
            ? 0.0
            : size.width * index / (points.length - 1);
        final normalized = spread <= 0
            ? .5
            : (points[index] - minValue) / spread;
        final y = size.height - normalized * size.height;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

Color _semanticColor(FastInfoSemantic semantic) {
  return switch (semantic) {
    FastInfoSemantic.neutral => AppColors.primary,
    FastInfoSemantic.good => AppColors.income,
    FastInfoSemantic.warning => const Color(0xFFF59E0B),
    FastInfoSemantic.bad => AppColors.expense,
  };
}

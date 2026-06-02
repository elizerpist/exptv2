import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_card_catalog.dart';
import '../../../settings/models/fast_info_config.dart';
import '../../state/fast_info_metrics_resolver.dart';

class FastInfoVisual extends StatelessWidget {
  const FastInfoVisual({super.key, required this.slot, this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return switch (slot.visualType) {
      FastInfoVisualType.progress => _ProgressVisual(
        slot: slot,
        metric: metric,
      ),
      FastInfoVisualType.sparkline => _SparklineVisual(
        slot: slot,
        metric: metric,
      ),
      FastInfoVisualType.bar => _BarVisual(slot: slot, metric: metric),
      FastInfoVisualType.ring => _RingVisual(slot: slot, metric: metric),
      FastInfoVisualType.status => _StatusVisual(slot: slot),
      FastInfoVisualType.trend => _TrendVisual(slot: slot),
      FastInfoVisualType.plain => const SizedBox.shrink(),
    };
  }
}

class _ProgressVisual extends StatelessWidget {
  const _ProgressVisual({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: ValueKey('fastinfo-visual-progress-${slot.id}'),
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: (metric?.progress ?? slot.progress ?? 0.45).clamp(0.0, 1.0),
        backgroundColor: AppColors.gray200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

class _SparklineVisual extends StatelessWidget {
  const _SparklineVisual({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('fastinfo-visual-sparkline-${slot.id}'),
      height: 10,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(metric?.series)),
    );
  }
}

class _BarVisual extends StatelessWidget {
  const _BarVisual({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final series = metric?.series;
    final value = (metric?.progress ?? slot.progress ?? 0.5).clamp(0.0, 1.0);
    final bars = series == null || series.isEmpty
        ? List<double>.generate(5, (index) => (index + 1) / 5)
        : series.length <= 5
        ? series
        : series.sublist(series.length - 5);
    final maxValue = bars.fold<double>(
      0,
      (max, item) => item > max ? item : max,
    );
    return Row(
      key: ValueKey('fastinfo-visual-bar-${slot.id}'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (index) {
        final normalized = maxValue <= 0 ? value : bars[index] / maxValue;
        return Expanded(
          child: Container(
            height: 3 + normalized.clamp(0.0, 1.0) * 6,
            margin: EdgeInsets.only(right: index == bars.length - 1 ? 0 : 2),
            decoration: BoxDecoration(
              color: normalized > 0 ? AppColors.primary : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _RingVisual extends StatelessWidget {
  const _RingVisual({required this.slot, required this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: ValueKey('fastinfo-visual-ring-${slot.id}'),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: (metric?.progress ?? slot.progress ?? 0.5).clamp(0.0, 1.0),
          backgroundColor: AppColors.gray200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _StatusVisual extends StatelessWidget {
  const _StatusVisual({required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: ValueKey('fastinfo-visual-status-${slot.id}'),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TrendVisual extends StatelessWidget {
  const _TrendVisual({required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('fastinfo-visual-trend-${slot.id}'),
      children: const [
        Icon(Icons.trending_up, size: 13, color: AppColors.primary),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.series);

  final List<double>? series;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final values = series == null || series!.isEmpty
        ? const <double>[4, 7, 5, 9, 8]
        : series!;
    final maxValue = values.fold<double>(
      0,
      (max, item) => item > max ? item : max,
    );
    final minValue = values.fold<double>(
      maxValue,
      (min, item) => item < min ? item : min,
    );
    final spread = maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index += 1) {
      final x = values.length == 1
          ? 0.0
          : size.width * index / (values.length - 1);
      final normalized = spread <= 0
          ? 0.5
          : (values[index] - minValue) / spread;
      final y = size.height - normalized * size.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

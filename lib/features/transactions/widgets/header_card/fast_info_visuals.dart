import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_card_catalog.dart';
import '../../../settings/models/fast_info_config.dart';

class FastInfoVisual extends StatelessWidget {
  const FastInfoVisual({super.key, required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return switch (slot.visualType) {
      FastInfoVisualType.progress => _ProgressVisual(slot: slot),
      FastInfoVisualType.sparkline => _SparklineVisual(slot: slot),
      FastInfoVisualType.bar => _BarVisual(slot: slot),
      FastInfoVisualType.ring => _RingVisual(slot: slot),
      FastInfoVisualType.status => _StatusVisual(slot: slot),
      FastInfoVisualType.trend => _TrendVisual(slot: slot),
      FastInfoVisualType.plain => const SizedBox.shrink(),
    };
  }
}

class _ProgressVisual extends StatelessWidget {
  const _ProgressVisual({required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: ValueKey('fastinfo-visual-progress-${slot.id}'),
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: (slot.progress ?? 0.45).clamp(0.0, 1.0),
        backgroundColor: AppColors.gray200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

class _SparklineVisual extends StatelessWidget {
  const _SparklineVisual({required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('fastinfo-visual-sparkline-${slot.id}'),
      height: 10,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter()),
    );
  }
}

class _BarVisual extends StatelessWidget {
  const _BarVisual({required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    final value = (slot.progress ?? 0.5).clamp(0.0, 1.0);
    return Row(
      key: ValueKey('fastinfo-visual-bar-${slot.id}'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            height: (3 + index).toDouble(),
            margin: EdgeInsets.only(right: index == 4 ? 0 : 2),
            decoration: BoxDecoration(
              color: index / 5 <= value ? AppColors.primary : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _RingVisual extends StatelessWidget {
  const _RingVisual({required this.slot});

  final FastInfoSlot slot;

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
          value: (slot.progress ?? 0.5).clamp(0.0, 1.0),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.50, size.height * 0.62)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

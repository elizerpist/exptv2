import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';

class MagnetStrip extends StatelessWidget {
  static const defaultHeight = 105.0;

  const MagnetStrip({
    super.key,
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    this.height = defaultHeight,
    this.accent = AppColors.primary,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return CustomPaint(
          key: ValueKey('magnet-strip-${type.nativeValue}'),
          size: Size(width, height),
          painter: MagnetStripPainter(
            type: type,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            accent: accent,
          ),
        );
      },
    );
  }
}

class MagnetStripPainter extends CustomPainter {
  const MagnetStripPainter({
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    required this.accent,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final total = totalIncome.abs() + totalExpense.abs();
    final ratio = total <= 0
        ? 0.5
        : (totalIncome.abs() / total).clamp(0.05, 0.95).toDouble();
    final centerY = size.height / 2;
    final trackHeight = math.max(2.0, size.height * 6 / 35);
    final rect = Rect.fromLTWH(
      0,
      centerY - trackHeight / 2,
      size.width,
      trackHeight,
    );

    if (type == MagnetType.magnetcard) {
      _paintMagnetCard(canvas, size, ratio);
      return;
    }

    if (type == MagnetType.adaptive) {
      final pillWidth = math.max(20.0, size.width * ratio);
      final pillHeight = math.max(4.0, size.height * 16 / 35);
      final pillRect = Rect.fromLTWH(
        0,
        centerY - pillHeight / 2,
        pillWidth,
        pillHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(3)),
        Paint()..color = accent.withValues(alpha: 0.85),
      );
      return;
    }

    if (type == MagnetType.budget) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
          ).createShader(rect),
      );
      return;
    }

    if (type == MagnetType.nofade) {
      final split = rect.left + rect.width * ratio;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rect.left, rect.top, split, rect.bottom),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0x4D2C2C2C),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(split, rect.top, rect.right, rect.bottom),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0x0D2C2C2C),
      );
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x4D2C2C2C), Color(0x0D2C2C2C)],
        ).createShader(rect),
    );
  }

  void _paintMagnetCard(Canvas canvas, Size size, double ratio) {
    final paint = Paint()
      ..color = AppColors.gray800.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.height / 35);
    final slabHeight = math.max(12.0, size.height * 16 / 35);
    final rect = Rect.fromLTWH(
      0,
      size.height / 2 - slabHeight / 2,
      size.width,
      slabHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, paint);
    final markerX = size.width * ratio;
    canvas.drawLine(
      Offset(markerX, rect.top),
      Offset(markerX, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MagnetStripPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.totalIncome != totalIncome ||
        oldDelegate.totalExpense != totalExpense ||
        oldDelegate.accent != accent;
  }
}

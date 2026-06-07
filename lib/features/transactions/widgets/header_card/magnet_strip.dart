import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';

class MagnetStrip extends StatelessWidget {
  static const defaultHeight = 157.5;

  const MagnetStrip({
    super.key,
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    this.height = defaultHeight,
    this.accent = AppColors.primary,
    this.budgetProgress,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final double height;
  final Color accent;
  final BudgetStripProgress? budgetProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final strip = CustomPaint(
          key: ValueKey('magnet-strip-${type.nativeValue}'),
          size: Size(width, height),
          painter: MagnetStripPainter(
            type: type,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            accent: accent,
          ),
        );
        final progress = budgetProgress;
        if (type != MagnetType.budget ||
            progress == null ||
            !progress.hasLimit) {
          return strip;
        }
        final trackHeight = math.max(2.0, height * 6 / 35);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              strip,
              SizedBox(
                key: const ValueKey('magnet-budget-progress-track'),
                width: width,
                height: trackHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.ratio,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        key: ValueKey('magnet-budget-progress-fill'),
                        decoration: BoxDecoration(
                          color: Color(0xffff8800),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BudgetStripProgress {
  const BudgetStripProgress({
    required this.hasLimit,
    required this.spent,
    required this.limitAmount,
  });

  final bool hasLimit;
  final double spent;
  final double limitAmount;

  double get ratio {
    if (!hasLimit || limitAmount <= 0) return 0;
    return (spent.abs() / limitAmount.abs()).clamp(0.0, 1.0).toDouble();
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

  static double incomeRatio(double totalIncome, double totalExpense) {
    final total = totalIncome.abs() + totalExpense.abs();
    if (total <= 0) return 0.5;
    return (totalIncome.abs() / total).clamp(0.05, 0.95).toDouble();
  }

  static List<Color> gradientColorsFor(MagnetType type) {
    return switch (type) {
      MagnetType.nofade => const [
        AppColors.income,
        AppColors.income,
        AppColors.expense,
        AppColors.expense,
      ],
      MagnetType.budget => const [AppColors.expense, AppColors.income],
      MagnetType.magnetcard => const [AppColors.gray500, AppColors.gray500],
      MagnetType.adaptive => const [AppColors.income, AppColors.income],
      MagnetType.fade => const [AppColors.income, AppColors.expense],
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ratio = incomeRatio(totalIncome, totalExpense);
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
        RRect.fromRectAndRadius(pillRect, const Radius.circular(2)),
        Paint()..color = AppColors.income.withValues(alpha: 0.85),
      );
      return;
    }

    if (type == MagnetType.budget) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: gradientColorsFor(type),
          ).createShader(rect),
      );
      return;
    }

    if (type == MagnetType.nofade) {
      final split = rect.left + rect.width * ratio;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rect.left, rect.top, split, rect.bottom),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.income,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(split, rect.top, rect.right, rect.bottom),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.expense,
      );
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: gradientColorsFor(type),
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
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
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

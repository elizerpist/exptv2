import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../data/limit_manager.dart';
import '../../models/limit_allocation_data.dart';

class BudgetStripProgress {
  const BudgetStripProgress({
    required this.hasLimit,
    required this.spent,
    required this.limitAmount,
  });

  final bool hasLimit;
  final double spent;
  final double limitAmount;

  bool get visible => hasLimit && limitAmount > 0;
  double get factor =>
      visible ? (spent / limitAmount).clamp(0.0, 1.0).toDouble() : 0.0;
  Color get fillColor => LimitManager.progressColor(spent, limitAmount);
}

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
    this.budgetAllocation,
    this.customGradientColors,
    this.customMarkerPosition,
    this.customKey,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final double height;
  final Color accent;
  final BudgetStripProgress? budgetProgress;
  final LimitAllocationData? budgetAllocation;
  final List<Color>? customGradientColors;
  final double? customMarkerPosition;
  final String? customKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final customGradient = customGradientColors;
        if (customGradient != null && customGradient.isNotEmpty) {
          return CustomPaint(
            key: ValueKey(customKey ?? 'magnet-strip-custom'),
            size: Size(width, height),
            painter: _CustomMagnetStripPainter(
              gradientColors: customGradient,
              markerPosition: customMarkerPosition,
              height: height,
            ),
          );
        }
        if (type == MagnetType.budget) {
          return _BudgetMagnetProgressStrip(
            width: width,
            height: height,
            progress: budgetProgress,
          );
        }
        if (type == MagnetType.partitionedBudget) {
          return _PartitionedBudgetMagnetStrip(
            width: width,
            height: height,
            allocation: budgetAllocation,
          );
        }
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

class _CustomMagnetStripPainter extends CustomPainter {
  const _CustomMagnetStripPainter({
    required this.gradientColors,
    required this.markerPosition,
    required this.height,
  });

  final List<Color> gradientColors;
  final double? markerPosition;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final trackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.fade,
      height,
    );
    final rect = Rect.fromLTWH(
      0,
      size.height / 2 - trackHeight / 2,
      size.width,
      trackHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(colors: gradientColors).createShader(rect),
    );
    final marker = markerPosition;
    if (marker == null) return;
    final markerX = rect.left + rect.width * marker.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(markerX, rect.center.dy),
      math.max(5, trackHeight * 1.05),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      Offset(markerX, rect.center.dy),
      math.max(4, trackHeight * 0.82),
      Paint()..color = AppColors.white,
    );
    canvas.drawCircle(
      Offset(markerX, rect.center.dy),
      math.max(4, trackHeight * 0.82),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gray500.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _CustomMagnetStripPainter oldDelegate) {
    return oldDelegate.gradientColors != gradientColors ||
        oldDelegate.markerPosition != markerPosition ||
        oldDelegate.height != height;
  }
}

class _PartitionedBudgetMagnetStrip extends StatelessWidget {
  const _PartitionedBudgetMagnetStrip({
    required this.width,
    required this.height,
    required this.allocation,
  });

  final double width;
  final double height;
  final LimitAllocationData? allocation;

  @override
  Widget build(BuildContext context) {
    final resolved = allocation;
    if (resolved == null || resolved.segments.isEmpty) {
      return SizedBox(
        key: const ValueKey('magnet-strip-partitionedBudget'),
        width: width,
        height: height,
      );
    }
    final trackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.partitionedBudget,
      height,
    );
    return SizedBox(
      key: const ValueKey('magnet-strip-partitionedBudget'),
      width: width,
      height: height,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: DecoratedBox(
            key: const ValueKey('magnet-partitioned-budget-track'),
            decoration: const BoxDecoration(color: AppColors.gray200),
            child: SizedBox(
              width: width,
              height: trackHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var left = 0.0;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      for (var i = 0; i < resolved.segments.length; i += 1)
                        () {
                          final segment = resolved.segments[i];
                          final segmentWidth =
                              (constraints.maxWidth * segment.fraction)
                                  .clamp(0.0, constraints.maxWidth - left)
                                  .toDouble();
                          final child = Positioned(
                            key: ValueKey(
                              'magnet-partitioned-budget-segment-$i',
                            ),
                            left: left,
                            top: 0,
                            width: segmentWidth,
                            bottom: 0,
                            child: ColoredBox(color: segment.color),
                          );
                          left += segmentWidth;
                          return child;
                        }(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetMagnetProgressStrip extends StatelessWidget {
  const _BudgetMagnetProgressStrip({
    required this.width,
    required this.height,
    required this.progress,
  });

  final double width;
  final double height;
  final BudgetStripProgress? progress;

  @override
  Widget build(BuildContext context) {
    final resolved = progress;
    if (resolved == null || !resolved.visible) {
      return SizedBox(
        key: const ValueKey('magnet-strip-budget'),
        width: width,
        height: height,
      );
    }
    return SizedBox(
      key: const ValueKey('magnet-strip-budget'),
      width: width,
      height: height,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            key: const ValueKey('magnet-budget-progress-track'),
            width: width,
            height: MagnetStripPainter.visualTrackHeight(
              MagnetType.budget,
              height,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: resolved.factor,
                  child: DecoratedBox(
                    key: const ValueKey('magnet-budget-progress-fill'),
                    decoration: BoxDecoration(
                      color: resolved.fillColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      MagnetType.partitionedBudget => const [
        AppColors.income,
        Color(0xFFF59E0B),
        AppColors.expense,
      ],
      MagnetType.fade => const [AppColors.income, AppColors.expense],
    };
  }

  static double visualTrackHeight(MagnetType type, double stripHeight) {
    return math.max(2.0, stripHeight * 6 / 35);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ratio = incomeRatio(totalIncome, totalExpense);
    final centerY = size.height / 2;
    final trackHeight = visualTrackHeight(type, size.height);
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
      final pillHeight = trackHeight;
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

    if (type == MagnetType.budget || type == MagnetType.partitionedBudget) {
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
      ..strokeWidth = math.max(1.0, visualTrackHeight(type, size.height) / 8);
    final slabHeight = visualTrackHeight(type, size.height);
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

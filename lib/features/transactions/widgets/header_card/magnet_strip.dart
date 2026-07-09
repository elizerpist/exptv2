import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/limit_allocation_data.dart';

enum MagnetMarkerStyle { circle, line }

class MagnetStrip extends StatelessWidget {
  static const defaultHeight = 157.5;

  const MagnetStrip({
    super.key,
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    this.height = defaultHeight,
    this.accent = AppColors.primary,
    this.budgetAllocation,
    this.customGradientColors,
    this.customMarkerPosition,
    this.customMarkerStyle = MagnetMarkerStyle.circle,
    this.customKey,
    this.ambulanceSkin = false,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final double height;
  final Color accent;
  final LimitAllocationData? budgetAllocation;
  final List<Color>? customGradientColors;
  final double? customMarkerPosition;
  final MagnetMarkerStyle customMarkerStyle;
  final String? customKey;
  final bool ambulanceSkin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final customGradient = customGradientColors;
        if (ambulanceSkin) {
          return _AmbulanceMagnetStrip(
            width: width,
            height: height,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
          );
        }
        if (customGradient != null && customGradient.isNotEmpty) {
          return CustomPaint(
            key: ValueKey(customKey ?? 'magnet-strip-custom'),
            size: Size(width, height),
            painter: _CustomMagnetStripPainter(
              gradientColors: customGradient,
              markerPosition: customMarkerPosition,
              markerStyle: customMarkerStyle,
              height: height,
            ),
          );
        }
        if (type == MagnetType.budget) {
          return _BudgetMagnetProgressStrip(
            width: width,
            height: height,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
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

class _AmbulanceMagnetStrip extends StatelessWidget {
  const _AmbulanceMagnetStrip({
    required this.width,
    required this.height,
    required this.totalIncome,
    required this.totalExpense,
  });

  static const orange = Color(0xFFE87522);
  static const yellow = Color(0xFFFFD84D);

  final double width;
  final double height;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final factor = MagnetStripPainter.balanceProgressFactor(
      totalIncome,
      totalExpense,
    );
    return SizedBox(
      key: const ValueKey('magnet-strip-ambulanceSkin'),
      width: width,
      height: height,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            key: const ValueKey('magnet-ambulance-progress-track'),
            width: width,
            height: MagnetStripPainter.visualTrackHeight(
              MagnetType.fade,
              height,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.22),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: factor,
                  child: CustomPaint(
                    key: const ValueKey('magnet-ambulance-progress-fill'),
                    painter: const _AmbulanceStripePainter(),
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

class _AmbulanceStripePainter extends CustomPainter {
  const _AmbulanceStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()..color = _AmbulanceMagnetStrip.orange;
    canvas.drawRect(Offset.zero & size, orangePaint);
    final yellowPaint = Paint()..color = _AmbulanceMagnetStrip.yellow;
    const stripeWidth = 14.0;
    const gap = 22.0;
    for (var left = -stripeWidth; left < size.width + gap; left += gap) {
      final path = Path()
        ..moveTo(left + 5, 0)
        ..lineTo(left + stripeWidth, 0)
        ..lineTo(left + stripeWidth - 5, size.height)
        ..lineTo(left, size.height)
        ..close();
      canvas.drawPath(path, yellowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbulanceStripePainter oldDelegate) => false;
}

class _CustomMagnetStripPainter extends CustomPainter {
  const _CustomMagnetStripPainter({
    required this.gradientColors,
    required this.markerPosition,
    required this.markerStyle,
    required this.height,
  });

  final List<Color> gradientColors;
  final double? markerPosition;
  final MagnetMarkerStyle markerStyle;
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
    if (markerStyle == MagnetMarkerStyle.line) {
      final center = Offset(markerX, rect.center.dy);
      final lineHeight = math.max(16, trackHeight + 10).toDouble();
      final shadowRect = Rect.fromCenter(
        center: center,
        width: 5,
        height: lineHeight + 2,
      );
      final markerRect = Rect.fromCenter(
        center: center,
        width: 3,
        height: lineHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(2.5)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(markerRect, const Radius.circular(1.5)),
        Paint()..color = AppColors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(markerRect, const Radius.circular(1.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.gray500.withValues(alpha: 0.55),
      );
      return;
    }
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
        oldDelegate.markerStyle != markerStyle ||
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
    required this.totalIncome,
    required this.totalExpense,
  });

  final double width;
  final double height;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final factor = MagnetStripPainter.balanceProgressFactor(
      totalIncome,
      totalExpense,
    );
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
                  widthFactor: factor,
                  child: DecoratedBox(
                    key: const ValueKey('magnet-budget-progress-fill'),
                    decoration: BoxDecoration(
                      color: MagnetStripPainter.referenceGray,
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

  static const referenceGray = AppColors.gray500;
  static const _softTransitionFraction = 0.16;

  static double incomeRatio(double totalIncome, double totalExpense) {
    final total = totalIncome.abs() + totalExpense.abs();
    if (total <= 0) return 0.5;
    return (totalIncome.abs() / total).clamp(0.0, 1.0).toDouble();
  }

  static double balanceProgressFactor(double totalIncome, double totalExpense) {
    return incomeRatio(totalIncome, totalExpense);
  }

  static List<double> softBalanceStops(double ratio) {
    final center = ratio.clamp(0.0, 1.0).toDouble();
    final halfTransition = _softTransitionFraction / 2;
    return <double>[
      0,
      (center - halfTransition).clamp(0.0, 1.0).toDouble(),
      (center + halfTransition).clamp(0.0, 1.0).toDouble(),
      1,
    ];
  }

  static List<double> grayFadeStops(double ratio) {
    final center = ratio.clamp(0.0, 1.0).toDouble();
    return <double>[0, center, 1];
  }

  static List<Color> gradientColorsFor(MagnetType type) {
    return switch (type) {
      MagnetType.nofade => const [
        AppColors.income,
        AppColors.income,
        AppColors.expense,
        AppColors.expense,
      ],
      MagnetType.budget => const [referenceGray, referenceGray],
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
      _paintGrayFade(canvas, rect, ratio);
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
          colors: const [
            AppColors.income,
            AppColors.income,
            AppColors.expense,
            AppColors.expense,
          ],
          stops: softBalanceStops(ratio),
        ).createShader(rect),
    );
  }

  void _paintGrayFade(Canvas canvas, Rect rect, double ratio) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: const [referenceGray, referenceGray, Color(0x0064748B)],
          stops: grayFadeStops(ratio),
        ).createShader(rect),
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

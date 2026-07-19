import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_color_manager.dart';
import '../models/transaction_category.dart';
import 'category_menu/category_icon_badge.dart';

class GlossyCategoryAvatar extends StatelessWidget {
  const GlossyCategoryAvatar({
    super.key,
    this.iconKey,
    required this.category,
    required this.size,
    required this.iconSize,
    required this.debugSource,
    this.iconStrokeWidth = 1.4,
    this.selected = false,
    this.opacity = 1,
    this.pulsing = false,
    this.showQuestionMark = false,
    this.showTopHighlight = true,
  });

  final TransactionCategory? category;
  final double size;
  final double iconSize;
  final String debugSource;
  final double iconStrokeWidth;
  final bool selected;
  final double opacity;
  final bool pulsing;
  final bool showQuestionMark;
  final bool showTopHighlight;

  final Key? iconKey;

  @override
  Widget build(BuildContext context) {
    final colorSlot = category?.colorSlot;
    final fallbackColor = category?.slotColor ?? AppColors.gray500;
    final gradient = colorSlot == null
        ? LinearGradient(colors: [fallbackColor, fallbackColor])
        : CategoryColorManager.gradient(colorSlot);
    final effectiveScale = selected ? (pulsing ? 1.18 : 1.1) : 1.0;
    return Opacity(
      opacity: opacity,
      child: AnimatedScale(
        scale: effectiveScale,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.28, -0.56),
              radius: 1.15,
              colors: [
                Colors.white.withValues(alpha: .26),
                Colors.white.withValues(alpha: .08),
                Colors.transparent,
              ],
              stops: const [0, .25, .50],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF0F172A,
                ).withValues(alpha: selected ? .20 : .16),
                offset: Offset(0, selected ? 18 : 13),
                blurRadius: selected ? 32 : 24,
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: .18),
                offset: const Offset(0, 10),
                blurRadius: 18,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: selected ? .16 : .09),
                offset: const Offset(0, -1),
                blurRadius: 4,
              ),
              if (selected)
                BoxShadow(
                  color: Colors.white.withValues(alpha: .16),
                  spreadRadius: 4,
                ),
            ],
          ),
          child: ClipOval(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: selected ? .54 : .50),
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.32, -0.60),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: .22),
                          Colors.white.withValues(alpha: .08),
                          Colors.transparent,
                        ],
                        stops: const [.0, .28, .52],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(.16, .56),
                        radius: .9,
                        colors: [
                          const Color(0xFF0F172A).withValues(alpha: .20),
                          Colors.transparent,
                        ],
                        stops: const [0, .43],
                      ),
                    ),
                  ),
                  if (showTopHighlight)
                    CustomPaint(
                      painter: _GlossyAvatarRingPainter(
                        opacity: selected ? .78 : .72,
                      ),
                    ),
                  Center(
                    child: CategoryIconBadge(
                      key: iconKey,
                      category: category,
                      backgroundColor: Colors.transparent,
                      size: size,
                      iconSize: iconSize,
                      iconStrokeWidth: iconStrokeWidth,
                      showShadow: false,
                      showQuestionMark: showQuestionMark,
                      debugSource: debugSource,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlossyAvatarRingPainter extends CustomPainter {
  const _GlossyAvatarRingPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: opacity);
    final inset = stroke.strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawArc(rect, math.pi * 1.08, math.pi * .84, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _GlossyAvatarRingPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

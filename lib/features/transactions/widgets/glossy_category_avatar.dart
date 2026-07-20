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
    this.colorSlot,
    this.avatarGradient,
    this.centerChild,
    this.iconStrokeWidth = 1.4,
    this.selected = false,
    this.opacity = 1,
    this.pulsing = false,
    this.showQuestionMark = false,
    this.showTopHighlight = true,
    this.showBodyHighlight = true,
    this.bodyHighlightStrength = 1,
    this.bodyHighlightKey,
    this.showBodyBorder = true,
    this.animateBodySize = true,
    this.showSelectedOuterGlow = true,
    this.scaleSelection = true,
  });

  final TransactionCategory? category;
  final double size;
  final double iconSize;
  final String debugSource;
  final int? colorSlot;
  final Gradient? avatarGradient;
  final Widget? centerChild;
  final double iconStrokeWidth;
  final bool selected;
  final double opacity;
  final bool pulsing;
  final bool showQuestionMark;
  final bool showTopHighlight;
  final bool showBodyHighlight;
  final double bodyHighlightStrength;
  final Key? bodyHighlightKey;
  final bool showBodyBorder;
  final bool animateBodySize;
  final bool showSelectedOuterGlow;
  final bool scaleSelection;

  final Key? iconKey;

  @override
  Widget build(BuildContext context) {
    final resolvedColorSlot = colorSlot ?? category?.colorSlot;
    final fallbackColor = category?.slotColor ?? AppColors.gray500;
    final gradient =
        avatarGradient ??
        (resolvedColorSlot == null
            ? LinearGradient(colors: [fallbackColor, fallbackColor])
            : CategoryColorManager.gradient(resolvedColorSlot));
    final highlightStrength = bodyHighlightStrength.clamp(0.0, 1.0).toDouble();
    final effectiveScale = scaleSelection && selected
        ? (pulsing ? 1.18 : 1.1)
        : 1.0;
    return Opacity(
      opacity: opacity,
      child: AnimatedScale(
        scale: effectiveScale,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: animateBodySize
              ? const Duration(milliseconds: 180)
              : Duration.zero,
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: showBodyHighlight && highlightStrength > 0
                ? RadialGradient(
                    center: const Alignment(-0.28, -0.56),
                    radius: 1.15,
                    colors: [
                      Colors.white.withValues(alpha: .26 * highlightStrength),
                      Colors.white.withValues(alpha: .08 * highlightStrength),
                      Colors.transparent,
                    ],
                    stops: const [0, .25, .50],
                  )
                : null,
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
              if (selected && showSelectedOuterGlow)
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
                border: showBodyBorder
                    ? Border.all(
                        color: Colors.white.withValues(
                          alpha: selected ? .54 : .50,
                        ),
                      )
                    : null,
                shape: BoxShape.circle,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (showBodyHighlight && highlightStrength > 0)
                    DecoratedBox(
                      key: bodyHighlightKey,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.32, -0.60),
                          radius: 1.1,
                          colors: [
                            Colors.white.withValues(
                              alpha: .22 * highlightStrength,
                            ),
                            Colors.white.withValues(
                              alpha: .08 * highlightStrength,
                            ),
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
                    child:
                        centerChild ??
                        CategoryIconBadge(
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';

class BackheaderStyleSurface extends StatelessWidget {
  const BackheaderStyleSurface({
    super.key,
    required this.style,
    required this.current,
    required this.items,
    required this.categoryBars,
    required this.frameProgress,
    required this.frameOverview,
    required this.activeIndex,
    this.backgroundColor = AppColors.gray100,
  });

  final BackheaderStyle style;
  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final List<CategoryBudgetBarData> categoryBars;
  final BudgetProgressData? frameProgress;
  final OverviewBudgetData? frameOverview;
  final int activeIndex;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final color = current.category?.color ?? _overviewColor;
    final amountText = current.amountText;
    final segments = _segmentColors;
    return DecoratedBox(
      key: ValueKey('backheader-style-${style.nativeValue}'),
      decoration: BoxDecoration(
        color: _background(color),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          switch (style) {
            BackheaderStyle.heroToken => _HeroToken(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.orbitBudget => _OrbitBudget(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.classic => const SizedBox.shrink(),
          },
          if (items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: _Dots(
                count: items.length,
                activeIndex: activeIndex,
                onDark: _usesLightDots,
              ),
            ),
        ],
      ),
    );
  }

  Color get _overviewColor => switch (current.overview?.kind) {
    BudgetGoalKind.incomeGoal => AppColors.income,
    BudgetGoalKind.savingGoal => const Color(0xFF3B82F6),
    _ => AppColors.primary,
  };

  bool get _usesLightDots => style == BackheaderStyle.orbitBudget;

  Color _background(Color color) => switch (style) {
    BackheaderStyle.orbitBudget => color,
    _ => backgroundColor,
  };

  List<Color> get _segmentColors {
    const fallback = [
      AppColors.primary,
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFFA855F7),
      Color(0xFF14B8A6),
    ];
    final colors = <Color>[for (final bar in categoryBars) bar.color];
    for (final color in fallback) {
      if (colors.length >= 6) break;
      if (!colors.contains(color)) colors.add(color);
    }
    return colors.take(6).toList();
  }
}

class _HeroToken extends StatelessWidget {
  const _HeroToken({
    required this.current,
    required this.amountText,
    required this.color,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-heroToken-content'),
      padding: const EdgeInsets.fromLTRB(30, 44, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Token(color: color, title: current.title),
              const SizedBox(width: 16),
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'CATEGORY TOKEN',
                ),
              ),
              const SizedBox(width: 12),
              _AmountBlock(amountText: amountText),
            ],
          ),
          const SizedBox(height: 14),
          _PartitionStrip(colors: segments, height: 14, activeColor: color),
        ],
      ),
    );
  }
}

class _OrbitBudget extends StatelessWidget {
  const _OrbitBudget({
    required this.current,
    required this.amountText,
    required this.color,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-orbitBudget-content'),
      padding: const EdgeInsets.fromLTRB(30, 38, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: amountText,
                  light: true,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(66),
                      painter: _OrbitPainter(segments),
                    ),
                    _Avatar(
                      color: AppColors.white.withValues(alpha: 0.18),
                      textColor: AppColors.white,
                      title: current.title,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PartitionStrip(
            colors: segments,
            height: 14,
            activeColor: AppColors.white,
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    this.light = false,
  });

  final String title;
  final String subtitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? AppColors.white : AppColors.gray800;
    final subColor = light
        ? AppColors.white.withValues(alpha: 0.72)
        : AppColors.gray600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
      ],
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.amountText});

  final String amountText;

  @override
  Widget build(BuildContext context) {
    return Text(
      amountText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: AppColors.gray800,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.color,
    required this.textColor,
    required this.title,
  });

  final Color color;
  final Color textColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        _initial(title),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Token extends StatelessWidget {
  const _Token({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            _initial(title),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartitionStrip extends StatelessWidget {
  const _PartitionStrip({
    required this.colors,
    required this.activeColor,
    this.height = 24,
  });

  final List<Color> colors;
  final Color activeColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('backheader-partition-strip'),
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < colors.length; i += 1)
              Expanded(
                flex: i == 0 ? 3 : 2,
                child: ColoredBox(color: i == 0 ? activeColor : colors[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.activeIndex,
    required this.onDark,
  });

  final int count;
  final int activeIndex;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i += 1)
          Container(
            key: ValueKey('category-budget-dot-$i'),
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == activeIndex
                  ? (onDark ? AppColors.white : AppColors.primary)
                  : (onDark
                        ? AppColors.white.withValues(alpha: 0.45)
                        : AppColors.white),
            ),
          ),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.22);
    canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    final sweep = (math.pi * 2) / colors.length;
    for (final color in colors) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color == colors.first ? AppColors.white : color;
      canvas.drawArc(rect.deflate(8), start, sweep * 0.78, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

String _initial(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

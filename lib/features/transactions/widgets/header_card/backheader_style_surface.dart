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
  });

  final BackheaderStyle style;
  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final List<CategoryBudgetBarData> categoryBars;
  final BudgetProgressData? frameProgress;
  final OverviewBudgetData? frameOverview;
  final int activeIndex;

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
            BackheaderStyle.colorFieldPartition => _ColorField(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.partitionDashboard => _PartitionDashboard(
              current: current,
              amountText: amountText,
              segments: segments,
            ),
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
            BackheaderStyle.mosaicBudget => _MosaicBudget(
              current: current,
              amountText: amountText,
              segments: segments,
            ),
            BackheaderStyle.ledgerStrip => _LedgerStrip(
              current: current,
              amountText: amountText,
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

  bool get _usesLightDots =>
      style == BackheaderStyle.partitionDashboard ||
      style == BackheaderStyle.colorFieldPartition ||
      style == BackheaderStyle.orbitBudget ||
      style == BackheaderStyle.ledgerStrip;

  Color _background(Color color) => switch (style) {
    BackheaderStyle.colorFieldPartition || BackheaderStyle.orbitBudget => color,
    BackheaderStyle.partitionDashboard => const Color(0xFF111827),
    BackheaderStyle.ledgerStrip => const Color(0xFF0F766E),
    _ => AppColors.gray100,
  };

  List<Color> get _segmentColors {
    final colors = <Color>[for (final bar in categoryBars) bar.color];
    if (colors.isEmpty) {
      return const [
        AppColors.primary,
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFF3B82F6),
      ];
    }
    return colors.take(6).toList();
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({
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
      key: const ValueKey('backheader-style-colorFieldPartition-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(
                color: AppColors.white.withValues(alpha: 0.18),
                textColor: AppColors.white,
                title: current.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'AKTÍV KATEGÓRIA',
                  light: true,
                ),
              ),
              _AmountBlock(amountText: amountText, light: true),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Közös budget partition',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _PartitionStrip(colors: segments, height: 28, activeColor: color),
        ],
      ),
    );
  }
}

class _PartitionDashboard extends StatelessWidget {
  const _PartitionDashboard({
    required this.current,
    required this.amountText,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-partitionDashboard-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'BUDGET MAP',
                  light: true,
                ),
              ),
              _AmountBlock(
                amountText: amountText,
                light: true,
                secondary: 'maradék fókusz',
              ),
            ],
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _PartitionStrip(
                colors: segments,
                height: 44,
                activeColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 0),
      child: Column(
        children: [
          Row(
            children: [
              _Token(color: color, title: current.title),
              const SizedBox(width: 18),
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'CATEGORY TOKEN',
                ),
              ),
              _AmountBlock(amountText: amountText),
            ],
          ),
          const SizedBox(height: 16),
          _PartitionStrip(colors: segments, height: 16, activeColor: color),
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
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Row(
        children: [
          Expanded(
            child: _TitleBlock(
              title: current.title,
              subtitle: amountText,
              light: true,
            ),
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(86),
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
    );
  }
}

class _MosaicBudget extends StatelessWidget {
  const _MosaicBudget({
    required this.current,
    required this.amountText,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-mosaicBudget-content'),
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'PARTITION MOSAIC',
                ),
              ),
              _AmountBlock(amountText: amountText),
            ],
          ),
          const SizedBox(height: 14),
          _MosaicTiles(colors: segments, title: current.title),
        ],
      ),
    );
  }
}

class _LedgerStrip extends StatelessWidget {
  const _LedgerStrip({
    required this.current,
    required this.amountText,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-ledgerStrip-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TitleBlock(
                  title: current.title,
                  subtitle: 'LEDGER STRIP',
                  light: true,
                ),
              ),
              _AmountBlock(amountText: amountText, light: true),
            ],
          ),
          const SizedBox(height: 26),
          _PartitionStrip(
            colors: segments,
            height: 22,
            activeColor: AppColors.white,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.44),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Text(
                  '${_initial(current.title)} active',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
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
      children: [
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
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
          ),
        ),
      ],
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.amountText,
    this.light = false,
    this.secondary,
  });

  final String amountText;
  final bool light;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.white : AppColors.gray800;
    final subColor = light
        ? AppColors.white.withValues(alpha: 0.70)
        : AppColors.gray600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          amountText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 3),
          Text(
            secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(color: subColor, fontSize: 10),
          ),
        ],
      ],
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
      radius: 20,
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
      width: 70,
      height: 70,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
          child: Text(
            _initial(title),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
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

class _MosaicTiles extends StatelessWidget {
  const _MosaicTiles({required this.colors, required this.title});

  final List<Color> colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              _tile(
                0,
                0,
                width * 0.42,
                48,
                colors[0],
                title: _initial(title),
                active: true,
              ),
              _tile(
                width * 0.45,
                0,
                width * 0.23,
                48,
                colors.length > 1 ? colors[1] : const Color(0xFFF59E0B),
              ),
              _tile(
                width * 0.71,
                0,
                width * 0.29,
                48,
                colors.length > 2 ? colors[2] : const Color(0xFFEF4444),
              ),
              _tile(
                0,
                56,
                width * 0.30,
                22,
                colors.length > 3 ? colors[3] : const Color(0xFF3B82F6),
              ),
              _tile(
                width * 0.34,
                56,
                width * 0.24,
                22,
                colors.length > 4 ? colors[4] : const Color(0xFFA855F7),
              ),
              _tile(width * 0.62, 56, width * 0.38, 22, AppColors.gray300),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    double x,
    double y,
    double width,
    double height,
    Color color, {
    String? title,
    bool active = false,
  }) {
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: active ? Border.all(color: AppColors.white, width: 3) : null,
        ),
        child: title == null
            ? const SizedBox.shrink()
            : Center(
                child: Text(
                  title,
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
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.22);
    canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    final sweep = (math.pi * 2) / colors.length;
    for (final color in colors) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
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

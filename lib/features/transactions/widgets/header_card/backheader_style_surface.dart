import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../category_slot_icon.dart';

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
    this.orbitPartitionBar,
    this.orbitProgress = 0,
    this.orbitHasLimit = false,
    this.orbitAmountText,
    this.orbitInlineEditor,
    this.onOrbitHandlePointerDown,
    this.onOrbitHandlePointerMove,
    this.onOrbitHandlePointerUp,
    this.onOrbitHandlePointerCancel,
  });

  final BackheaderStyle style;
  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final List<CategoryBudgetBarData> categoryBars;
  final BudgetProgressData? frameProgress;
  final OverviewBudgetData? frameOverview;
  final int activeIndex;
  final Color backgroundColor;
  final Widget? orbitPartitionBar;
  final double orbitProgress;
  final bool orbitHasLimit;
  final String? orbitAmountText;
  final Widget? orbitInlineEditor;
  final void Function(PointerDownEvent event)? onOrbitHandlePointerDown;
  final void Function(PointerMoveEvent event)? onOrbitHandlePointerMove;
  final void Function(PointerUpEvent event)? onOrbitHandlePointerUp;
  final void Function(PointerCancelEvent event)? onOrbitHandlePointerCancel;

  @override
  Widget build(BuildContext context) {
    final color = current.category?.color ?? _overviewColor;
    final amountText = orbitAmountText ?? current.amountText;
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
              partitionBar: orbitPartitionBar,
              progress: orbitProgress,
              hasLimit: orbitHasLimit,
              inlineEditor: orbitInlineEditor,
              onHandlePointerDown: onOrbitHandlePointerDown,
              onHandlePointerMove: onOrbitHandlePointerMove,
              onHandlePointerUp: onOrbitHandlePointerUp,
              onHandlePointerCancel: onOrbitHandlePointerCancel,
            ),
            BackheaderStyle.classic => const SizedBox.shrink(),
          },
          if (items.length > 1 && style != BackheaderStyle.orbitBudget)
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
    required this.partitionBar,
    required this.progress,
    required this.hasLimit,
    required this.inlineEditor,
    this.onHandlePointerDown,
    this.onHandlePointerMove,
    this.onHandlePointerUp,
    this.onHandlePointerCancel,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final Widget? partitionBar;
  final double progress;
  final bool hasLimit;
  final Widget? inlineEditor;
  final void Function(PointerDownEvent event)? onHandlePointerDown;
  final void Function(PointerMoveEvent event)? onHandlePointerMove;
  final void Function(PointerUpEvent event)? onHandlePointerUp;
  final void Function(PointerCancelEvent event)? onHandlePointerCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-orbitBudget-content'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _OrbitIcon(item: current, progress: progress, hasLimit: hasLimit),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  current.title,
                  key: const ValueKey('backheader-orbit-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  amountText,
                  key: const ValueKey('backheader-orbit-amount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          partitionBar ?? const SizedBox(height: 14),
          Expanded(
            child: inlineEditor == null
                ? const SizedBox.shrink()
                : Align(alignment: Alignment.bottomCenter, child: inlineEditor),
          ),
          Center(
            child: GestureDetector(
              key: const ValueKey('backheader-orbit-handle'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {},
              onPanUpdate: (_) {},
              onPanEnd: (_) {},
              onPanCancel: () {},
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: onHandlePointerDown,
                onPointerMove: onHandlePointerMove,
                onPointerUp: onHandlePointerUp,
                onPointerCancel: onHandlePointerCancel,
                child: SizedBox(
                  width: 78,
                  height: 22,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.item,
    required this.progress,
    required this.hasLimit,
  });

  final BackheaderBudgetItem item;
  final double progress;
  final bool hasLimit;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    return SizedBox(
      key: const ValueKey('backheader-orbit-icon'),
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasLimit)
            CustomPaint(
              key: const ValueKey('backheader-orbit-progress-ring'),
              size: const Size.square(58),
              painter: _OrbitProgressRingPainter(progress),
            ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.22),
              ),
            ),
            alignment: Alignment.center,
            child: category == null
                ? Icon(
                    _overviewIcon(item.overview?.kind),
                    color: AppColors.white,
                    size: 25,
                  )
                : CategorySlotIcon(
                    slot: category.iconSlot,
                    color: AppColors.white,
                    size: 27,
                    strokeWidth: 1.25,
                  ),
          ),
        ],
      ),
    );
  }

  IconData _overviewIcon(BudgetGoalKind? kind) {
    return switch (kind) {
      BudgetGoalKind.expenseBudget => Icons.account_balance_wallet_outlined,
      BudgetGoalKind.incomeGoal => Icons.trending_up,
      BudgetGoalKind.savingGoal => Icons.savings_outlined,
      null => Icons.account_balance_wallet_outlined,
    };
  }
}

class _OrbitProgressRingPainter extends CustomPainter {
  const _OrbitProgressRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.22);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white;
    final ringRect = rect.deflate(2.4);
    canvas.drawArc(ringRect, 0, 6.283185307179586, false, track);
    canvas.drawArc(
      ringRect,
      -1.5707963267948966,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.gray600,
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
          style: const TextStyle(
            color: AppColors.gray800,
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

String _initial(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

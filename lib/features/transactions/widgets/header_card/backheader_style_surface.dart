import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/limit_allocation_data.dart';
import '../../models/overview_budget_data.dart';
import '../category_slot_icon.dart';
import 'magnet_strip.dart';
import 'transaction_header_metrics.dart';

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
    this.centerDesign = BackheaderCenterDesign.neutral,
    this.orbitPartitionBar,
    this.orbitProgress = 0,
    this.orbitHasLimit = false,
    this.orbitAmountText,
    this.orbitAmountEditor,
    this.orbitActions,
    this.centerProgress = 0,
    this.centerHasLimit = false,
    this.centerProgressColor = AppColors.primary,
    this.centerPartitionRingEnabled = false,
    this.centerPartitionAllocation,
    this.centerDragOffset = 0,
    this.centerPeriodLabel,
    this.centerActions,
    this.centerPreviousEdge,
    this.centerPreviousFarthest,
    this.centerPreviousOuter,
    this.centerPreviousInner,
    this.centerNextInner,
    this.centerNextOuter,
    this.centerNextFarthest,
    this.centerNextEdge,
    this.centerExpandedExtent = 0,
    this.onCenterPreviousEdgeTap,
    this.onCenterPreviousFarthestTap,
    this.onCenterPreviousOuterTap,
    this.onCenterPreviousInnerTap,
    this.onCenterNextInnerTap,
    this.onCenterNextOuterTap,
    this.onCenterNextFarthestTap,
    this.onCenterNextEdgeTap,
    this.onCenterBadgeTap,
    this.onCenterBadgeLongPressStart,
    this.onCenterBadgeLongPressMoveUpdate,
    this.onCenterBadgeLongPressEnd,
    this.onCenterBadgeLongPressCancel,
    this.centerRemainingText,
    this.onCenterHandlePointerDown,
    this.onCenterHandlePointerMove,
    this.onCenterHandlePointerUp,
    this.onCenterHandlePointerCancel,
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
  final BackheaderCenterDesign centerDesign;
  final Widget? orbitPartitionBar;
  final double orbitProgress;
  final bool orbitHasLimit;
  final String? orbitAmountText;
  final Widget? orbitAmountEditor;
  final Widget? orbitActions;
  final double centerProgress;
  final bool centerHasLimit;
  final Color centerProgressColor;
  final bool centerPartitionRingEnabled;
  final LimitAllocationData? centerPartitionAllocation;
  final double centerDragOffset;
  final String? centerPeriodLabel;
  final Widget? centerActions;
  final BackheaderBudgetItem? centerPreviousEdge;
  final BackheaderBudgetItem? centerPreviousFarthest;
  final BackheaderBudgetItem? centerPreviousOuter;
  final BackheaderBudgetItem? centerPreviousInner;
  final BackheaderBudgetItem? centerNextInner;
  final BackheaderBudgetItem? centerNextOuter;
  final BackheaderBudgetItem? centerNextFarthest;
  final BackheaderBudgetItem? centerNextEdge;
  final double centerExpandedExtent;
  final VoidCallback? onCenterPreviousEdgeTap;
  final VoidCallback? onCenterPreviousFarthestTap;
  final VoidCallback? onCenterPreviousOuterTap;
  final VoidCallback? onCenterPreviousInnerTap;
  final VoidCallback? onCenterNextInnerTap;
  final VoidCallback? onCenterNextOuterTap;
  final VoidCallback? onCenterNextFarthestTap;
  final VoidCallback? onCenterNextEdgeTap;
  final VoidCallback? onCenterBadgeTap;
  final GestureLongPressStartCallback? onCenterBadgeLongPressStart;
  final GestureLongPressMoveUpdateCallback? onCenterBadgeLongPressMoveUpdate;
  final GestureLongPressEndCallback? onCenterBadgeLongPressEnd;
  final VoidCallback? onCenterBadgeLongPressCancel;
  final String? centerRemainingText;
  final void Function(PointerDownEvent event)? onCenterHandlePointerDown;
  final void Function(PointerMoveEvent event)? onCenterHandlePointerMove;
  final void Function(PointerUpEvent event)? onCenterHandlePointerUp;
  final void Function(PointerCancelEvent event)? onCenterHandlePointerCancel;
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
              amountEditor: orbitAmountEditor,
              actions: orbitActions,
              onHandlePointerDown: onOrbitHandlePointerDown,
              onHandlePointerMove: onOrbitHandlePointerMove,
              onHandlePointerUp: onOrbitHandlePointerUp,
              onHandlePointerCancel: onOrbitHandlePointerCancel,
            ),
            BackheaderStyle.centerBadgeBudget => _CenterBadgeBudget(
              current: current,
              items: items,
              activeIndex: activeIndex,
              amountText: amountText,
              color: color,
              coloredDesign: centerDesign == BackheaderCenterDesign.colored,
              progress: centerProgress,
              hasLimit: centerHasLimit,
              progressColor: centerProgressColor,
              partitionRingEnabled: centerPartitionRingEnabled,
              partitionAllocation: centerPartitionAllocation,
              periodLabel: centerPeriodLabel,
              actions: centerActions,
              previousEdge: centerPreviousEdge,
              previousFarthest: centerPreviousFarthest,
              previousOuter: centerPreviousOuter,
              previousInner: centerPreviousInner,
              nextInner: centerNextInner,
              nextOuter: centerNextOuter,
              nextFarthest: centerNextFarthest,
              nextEdge: centerNextEdge,
              dragOffset: centerDragOffset,
              expandedExtent: centerExpandedExtent,
              onPreviousEdgeTap: onCenterPreviousEdgeTap,
              onPreviousFarthestTap: onCenterPreviousFarthestTap,
              onPreviousOuterTap: onCenterPreviousOuterTap,
              onPreviousInnerTap: onCenterPreviousInnerTap,
              onNextInnerTap: onCenterNextInnerTap,
              onNextOuterTap: onCenterNextOuterTap,
              onNextFarthestTap: onCenterNextFarthestTap,
              onNextEdgeTap: onCenterNextEdgeTap,
              onBadgeTap: onCenterBadgeTap,
              onBadgeLongPressStart: onCenterBadgeLongPressStart,
              onBadgeLongPressMoveUpdate: onCenterBadgeLongPressMoveUpdate,
              onBadgeLongPressEnd: onCenterBadgeLongPressEnd,
              onBadgeLongPressCancel: onCenterBadgeLongPressCancel,
              remainingText: centerRemainingText,
              onHandlePointerDown: onCenterHandlePointerDown,
              onHandlePointerMove: onCenterHandlePointerMove,
              onHandlePointerUp: onCenterHandlePointerUp,
              onHandlePointerCancel: onCenterHandlePointerCancel,
            ),
            BackheaderStyle.classic => const SizedBox.shrink(),
          },
          if (items.length > 1 &&
              style != BackheaderStyle.orbitBudget &&
              style != BackheaderStyle.centerBadgeBudget)
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
    BackheaderStyle.centerBadgeBudget
        when centerDesign == BackheaderCenterDesign.colored =>
      Color.alphaBlend(color.withValues(alpha: 0.72), backgroundColor),
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
    required this.amountEditor,
    required this.actions,
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
  final Widget? amountEditor;
  final Widget? actions;
  final void Function(PointerDownEvent event)? onHandlePointerDown;
  final void Function(PointerMoveEvent event)? onHandlePointerMove;
  final void Function(PointerUpEvent event)? onHandlePointerUp;
  final void Function(PointerCancelEvent event)? onHandlePointerCancel;

  @override
  Widget build(BuildContext context) {
    final trackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.fade,
      TransactionHeaderMetrics.magnetHeight,
    );
    final partitionHeight = trackHeight * 0.63;
    final partitionTop =
        TransactionHeaderMetrics.magnetTop +
        TransactionHeaderMetrics.magnetHeight / 2 -
        trackHeight / 2;
    final topRowTop =
        TransactionHeaderMetrics.cardHeight -
        TransactionHeaderMetrics.expandedSlideDistance +
        10;
    return Stack(
      key: const ValueKey('backheader-style-orbitBudget-content'),
      children: [
        Positioned(
          top: topRowTop,
          left: 24,
          right: actions == null ? 24 : 120,
          child: Row(
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
            ],
          ),
        ),
        Positioned(
          top: partitionTop,
          left: 0,
          right: 0,
          child: SizedBox(
            height: partitionHeight,
            child: partitionBar ?? SizedBox(height: partitionHeight),
          ),
        ),
        Positioned(
          top: TransactionHeaderMetrics.balanceTop,
          left: 24,
          right: 24,
          child:
              amountEditor ??
              Text(
                amountText,
                key: const ValueKey('backheader-orbit-amount'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16.8,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
        ),
        if (actions != null)
          Positioned(top: topRowTop, right: 24, child: actions!),
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          child: Center(
            child: Listener(
              key: const ValueKey('backheader-orbit-handle'),
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
      ],
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.item,
    required this.progress,
    required this.hasLimit,
  });

  static const _outerSize = 40.6;
  static const _innerSize = 32.2;

  final BackheaderBudgetItem item;
  final double progress;
  final bool hasLimit;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    return SizedBox(
      key: const ValueKey('backheader-orbit-icon'),
      width: _outerSize,
      height: _outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasLimit)
            Positioned.fill(
              child: CustomPaint(
                key: const ValueKey('backheader-orbit-progress-ring'),
                painter: _OrbitProgressRingPainter(progress),
                child: const SizedBox.expand(),
              ),
            ),
          Container(
            width: _innerSize,
            height: _innerSize,
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
                    size: 18,
                  )
                : CategorySlotIcon(
                    slot: category.iconSlot,
                    color: AppColors.white,
                    size: 19,
                    strokeWidth: 1,
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

class _CenterBadgeBudget extends StatelessWidget {
  const _CenterBadgeBudget({
    required this.current,
    required this.items,
    required this.activeIndex,
    required this.amountText,
    required this.color,
    required this.coloredDesign,
    required this.progress,
    required this.hasLimit,
    required this.progressColor,
    required this.partitionRingEnabled,
    required this.partitionAllocation,
    required this.periodLabel,
    required this.actions,
    required this.previousEdge,
    required this.previousFarthest,
    required this.previousOuter,
    required this.previousInner,
    required this.nextInner,
    required this.nextOuter,
    required this.nextFarthest,
    required this.nextEdge,
    required this.dragOffset,
    required this.expandedExtent,
    required this.onPreviousEdgeTap,
    required this.onPreviousFarthestTap,
    required this.onPreviousOuterTap,
    required this.onPreviousInnerTap,
    required this.onNextInnerTap,
    required this.onNextOuterTap,
    required this.onNextFarthestTap,
    required this.onNextEdgeTap,
    required this.onBadgeTap,
    required this.onBadgeLongPressStart,
    required this.onBadgeLongPressMoveUpdate,
    required this.onBadgeLongPressEnd,
    required this.onBadgeLongPressCancel,
    required this.remainingText,
    required this.onHandlePointerDown,
    required this.onHandlePointerMove,
    required this.onHandlePointerUp,
    required this.onHandlePointerCancel,
  });

  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final int activeIndex;
  final String amountText;
  final Color color;
  final bool coloredDesign;
  final double progress;
  final bool hasLimit;
  final Color progressColor;
  final bool partitionRingEnabled;
  final LimitAllocationData? partitionAllocation;
  final String? periodLabel;
  final Widget? actions;
  final BackheaderBudgetItem? previousEdge;
  final BackheaderBudgetItem? previousFarthest;
  final BackheaderBudgetItem? previousOuter;
  final BackheaderBudgetItem? previousInner;
  final BackheaderBudgetItem? nextInner;
  final BackheaderBudgetItem? nextOuter;
  final BackheaderBudgetItem? nextFarthest;
  final BackheaderBudgetItem? nextEdge;
  final double dragOffset;
  final double expandedExtent;
  final VoidCallback? onPreviousEdgeTap;
  final VoidCallback? onPreviousFarthestTap;
  final VoidCallback? onPreviousOuterTap;
  final VoidCallback? onPreviousInnerTap;
  final VoidCallback? onNextInnerTap;
  final VoidCallback? onNextOuterTap;
  final VoidCallback? onNextFarthestTap;
  final VoidCallback? onNextEdgeTap;
  final VoidCallback? onBadgeTap;
  final GestureLongPressStartCallback? onBadgeLongPressStart;
  final GestureLongPressMoveUpdateCallback? onBadgeLongPressMoveUpdate;
  final GestureLongPressEndCallback? onBadgeLongPressEnd;
  final VoidCallback? onBadgeLongPressCancel;
  final String? remainingText;
  final void Function(PointerDownEvent event)? onHandlePointerDown;
  final void Function(PointerMoveEvent event)? onHandlePointerMove;
  final void Function(PointerUpEvent event)? onHandlePointerUp;
  final void Function(PointerCancelEvent event)? onHandlePointerCancel;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final amountTop = safeTop + 8;
    final railTop = safeTop + 21;
    final amountColor = coloredDesign ? AppColors.white : AppColors.gray800;
    final titleColor = coloredDesign ? AppColors.white : AppColors.gray700;
    final periodColor = coloredDesign
        ? AppColors.white.withValues(alpha: 0.9)
        : AppColors.gray700;
    final handleColor = coloredDesign
        ? AppColors.white.withValues(alpha: 0.78)
        : AppColors.gray500.withValues(alpha: 0.72);
    final ringColor = coloredDesign ? AppColors.white : progressColor;
    final ringTrackColor = coloredDesign
        ? AppColors.white.withValues(alpha: 0.34)
        : AppColors.gray300;
    return Stack(
      key: const ValueKey('backheader-style-centerBadgeBudget-content'),
      children: [
        Positioned(
          top: amountTop,
          left: 24,
          right: 132,
          child: Text(
            amountText,
            key: const ValueKey('backheader-center-badge-amount'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: amountColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        if (periodLabel != null && periodLabel!.trim().isNotEmpty)
          Positioned(
            top: amountTop,
            right: 24,
            width: 104,
            child: Text(
              periodLabel!,
              key: const ValueKey('backheader-center-period-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: periodColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
        Positioned(
          top: railTop,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: _CenterBadgeWheel.width,
              height: 112,
              child: _CenterBadgeWheel(
                current: current,
                items: items,
                activeIndex: activeIndex,
                currentColor: color,
                coloredDesign: coloredDesign,
                progress: progress,
                hasLimit: hasLimit,
                progressColor: ringColor,
                ringTrackColor: ringTrackColor,
                partitionRingEnabled: partitionRingEnabled,
                partitionAllocation: partitionAllocation,
                titleColor: titleColor,
                previousEdge: previousEdge,
                previousFarthest: previousFarthest,
                previousOuter: previousOuter,
                previousInner: previousInner,
                nextInner: nextInner,
                nextOuter: nextOuter,
                nextFarthest: nextFarthest,
                nextEdge: nextEdge,
                dragOffset: dragOffset,
                onPreviousEdgeTap: onPreviousEdgeTap,
                onPreviousFarthestTap: onPreviousFarthestTap,
                onPreviousOuterTap: onPreviousOuterTap,
                onPreviousInnerTap: onPreviousInnerTap,
                onNextInnerTap: onNextInnerTap,
                onNextOuterTap: onNextOuterTap,
                onNextFarthestTap: onNextFarthestTap,
                onNextEdgeTap: onNextEdgeTap,
                onBadgeTap: onBadgeTap,
                onBadgeLongPressStart: onBadgeLongPressStart,
                onBadgeLongPressMoveUpdate: onBadgeLongPressMoveUpdate,
                onBadgeLongPressEnd: onBadgeLongPressEnd,
                onBadgeLongPressCancel: onBadgeLongPressCancel,
              ),
            ),
          ),
        ),
        if (actions != null) Positioned(right: 24, bottom: 18, child: actions!),
        if (remainingText != null)
          Positioned(
            left: 24,
            right: 24,
            top:
                TransactionHeaderMetrics.cardHeight +
                math.max(0.0, expandedExtent - 18) / 2,
            child: Text(
              remainingText!,
              key: const ValueKey('backheader-center-remaining-amount'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: coloredDesign ? AppColors.white : AppColors.gray700,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 2,
          child: Center(
            child: Listener(
              key: const ValueKey('backheader-center-handle'),
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
                    key: const ValueKey('backheader-center-handle-line'),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterBadgeWheel extends StatelessWidget {
  const _CenterBadgeWheel({
    required this.current,
    required this.items,
    required this.activeIndex,
    required this.currentColor,
    required this.coloredDesign,
    required this.progress,
    required this.hasLimit,
    required this.progressColor,
    required this.ringTrackColor,
    required this.partitionRingEnabled,
    required this.partitionAllocation,
    required this.titleColor,
    required this.previousEdge,
    required this.previousFarthest,
    required this.previousOuter,
    required this.previousInner,
    required this.nextInner,
    required this.nextOuter,
    required this.nextFarthest,
    required this.nextEdge,
    required this.dragOffset,
    required this.onPreviousEdgeTap,
    required this.onPreviousFarthestTap,
    required this.onPreviousOuterTap,
    required this.onPreviousInnerTap,
    required this.onNextInnerTap,
    required this.onNextOuterTap,
    required this.onNextFarthestTap,
    required this.onNextEdgeTap,
    required this.onBadgeTap,
    required this.onBadgeLongPressStart,
    required this.onBadgeLongPressMoveUpdate,
    required this.onBadgeLongPressEnd,
    required this.onBadgeLongPressCancel,
  });

  static const width = 386.0;
  static const _activeSize = 78.0 * 1.15;
  static const _innerPreviewSize = 48.0 * 1.10 * 1.10;
  static const _outerPreviewSize = 40.0 * 1.10 * 1.10;
  static const _farthestPreviewSize = 34.0 * 1.10 * 1.10;
  static const _edgePreviewSize = 28.0 * 1.10 * 1.10;
  static const _slotSpacing = 66.0;
  static const _compressedOuterSpacing = 38.0;
  static const _titleTop = 82.0;

  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final int activeIndex;
  final Color currentColor;
  final bool coloredDesign;
  final double progress;
  final bool hasLimit;
  final Color progressColor;
  final Color ringTrackColor;
  final bool partitionRingEnabled;
  final LimitAllocationData? partitionAllocation;
  final Color titleColor;
  final BackheaderBudgetItem? previousEdge;
  final BackheaderBudgetItem? previousFarthest;
  final BackheaderBudgetItem? previousOuter;
  final BackheaderBudgetItem? previousInner;
  final BackheaderBudgetItem? nextInner;
  final BackheaderBudgetItem? nextOuter;
  final BackheaderBudgetItem? nextFarthest;
  final BackheaderBudgetItem? nextEdge;
  final double dragOffset;
  final VoidCallback? onPreviousEdgeTap;
  final VoidCallback? onPreviousFarthestTap;
  final VoidCallback? onPreviousOuterTap;
  final VoidCallback? onPreviousInnerTap;
  final VoidCallback? onNextInnerTap;
  final VoidCallback? onNextOuterTap;
  final VoidCallback? onNextFarthestTap;
  final VoidCallback? onNextEdgeTap;
  final VoidCallback? onBadgeTap;
  final GestureLongPressStartCallback? onBadgeLongPressStart;
  final GestureLongPressMoveUpdateCallback? onBadgeLongPressMoveUpdate;
  final GestureLongPressEndCallback? onBadgeLongPressEnd;
  final VoidCallback? onBadgeLongPressCancel;

  @override
  Widget build(BuildContext context) {
    final slots = _slots()
      ..sort((left, right) => right.distance.compareTo(left.distance));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final slot in slots) _buildSlot(slot),
        Positioned(
          top: _titleTop,
          left: (width - 142) / 2,
          child: SizedBox(
            width: 142,
            child: Text(
              current.title,
              key: const ValueKey('backheader-center-badge-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_CenterWheelSlotData> _slots() {
    final previousIncoming = dragOffset > 0 ? _extraNeighborAtOffset(-5) : null;
    final nextIncoming = dragOffset < 0 ? _extraNeighborAtOffset(5) : null;
    return [
      if (previousEdge != null) _slotData(-4, previousEdge!, onPreviousEdgeTap),
      if (previousIncoming != null) _slotData(-5, previousIncoming, null),
      if (previousFarthest != null)
        _slotData(-3, previousFarthest!, onPreviousFarthestTap),
      if (previousOuter != null)
        _slotData(-2, previousOuter!, onPreviousOuterTap),
      if (previousInner != null)
        _slotData(-1, previousInner!, onPreviousInnerTap),
      _slotData(0, current, null),
      if (nextInner != null) _slotData(1, nextInner!, onNextInnerTap),
      if (nextOuter != null) _slotData(2, nextOuter!, onNextOuterTap),
      if (nextFarthest != null) _slotData(3, nextFarthest!, onNextFarthestTap),
      if (nextEdge != null) _slotData(4, nextEdge!, onNextEdgeTap),
      if (nextIncoming != null) _slotData(5, nextIncoming, null),
    ];
  }

  BackheaderBudgetItem? _extraNeighborAtOffset(int offset) {
    if (offset == 0 || items.length < 2) return null;
    final rawIndex = (activeIndex + offset) % items.length;
    final index = rawIndex < 0 ? rawIndex + items.length : rawIndex;
    final item = items[index];
    final visibleKeys = <String>{
      current.key,
      if (previousEdge != null) previousEdge!.key,
      if (previousFarthest != null) previousFarthest!.key,
      if (previousOuter != null) previousOuter!.key,
      if (previousInner != null) previousInner!.key,
      if (nextInner != null) nextInner!.key,
      if (nextOuter != null) nextOuter!.key,
      if (nextFarthest != null) nextFarthest!.key,
      if (nextEdge != null) nextEdge!.key,
    };
    if (visibleKeys.contains(item.key)) return null;
    return item;
  }

  _CenterWheelSlotData _slotData(
    int offset,
    BackheaderBudgetItem item,
    VoidCallback? onTap,
  ) {
    final logicalOffset = offset + dragOffset / _slotSpacing;
    final distance = logicalOffset.abs().clamp(0.0, 4.0).toDouble();
    final centerX = width / 2 + _visualOffsetForLogical(logicalOffset);
    final size = _sizeForDistance(distance);
    return _CenterWheelSlotData(
      offset: offset,
      item: item,
      color: _colorForItem(item),
      centerX: centerX,
      distance: distance,
      size: size,
      opacity: _opacityForDistance(distance),
      progress: offset == 0 ? progress : _progressForItem(item),
      hasLimit: offset == 0 ? hasLimit : _hasLimitForItem(item),
      progressColor: offset == 0 ? progressColor : _progressColorForItem(item),
      onTap: onTap,
    );
  }

  Widget _buildSlot(_CenterWheelSlotData slot) {
    final left = slot.centerX - slot.size / 2;
    final top = (_activeSize - slot.size) / 2;
    final active = slot.offset == 0;
    final slotName = active ? null : _slotName(slot.offset);
    return Positioned(
      key: ValueKey(
        active
            ? 'backheader-center-active-slot-${slot.item.key}'
            : 'backheader-center-preview-$slotName-${slot.item.key}',
      ),
      left: left,
      top: top,
      child: _CenterBadgeVisual(
        key: ValueKey(
          active
              ? 'backheader-center-active-${slot.item.key}'
              : 'backheader-center-preview-$slotName',
        ),
        item: slot.item,
        previewSlotName: slotName,
        active: active,
        coloredDesign: coloredDesign,
        size: slot.size,
        opacity: slot.opacity,
        color: active ? currentColor : slot.color,
        progress: slot.progress,
        hasLimit: slot.hasLimit,
        progressColor: coloredDesign ? AppColors.white : slot.progressColor,
        ringTrackColor: ringTrackColor,
        partitionAllocation: active && partitionRingEnabled
            ? partitionAllocation
            : null,
        onTap: active ? onBadgeTap : slot.onTap,
        onBadgeLongPressStart: active ? onBadgeLongPressStart : null,
        onBadgeLongPressMoveUpdate: active ? onBadgeLongPressMoveUpdate : null,
        onBadgeLongPressEnd: active ? onBadgeLongPressEnd : null,
        onBadgeLongPressCancel: active ? onBadgeLongPressCancel : null,
      ),
    );
  }

  String _slotName(int offset) {
    return offset < 0 ? 'previous-${offset.abs()}' : 'next-$offset';
  }

  double _sizeForDistance(double distance) {
    if (distance <= 0) return _activeSize;
    if (distance <= 1) {
      return _lerp(_activeSize, _innerPreviewSize, distance);
    }
    if (distance <= 2) {
      return _lerp(_innerPreviewSize, _outerPreviewSize, distance - 1);
    }
    if (distance <= 3) {
      return _lerp(_outerPreviewSize, _farthestPreviewSize, distance - 2);
    }
    return _lerp(_farthestPreviewSize, _edgePreviewSize, distance - 3);
  }

  double _opacityForDistance(double distance) {
    if (distance <= 0) return 1;
    if (distance <= 1) return _lerp(1, 0.72, distance);
    if (distance <= 2) return _lerp(0.72, 0.58, distance - 1);
    if (distance <= 3) return _lerp(0.58, 0.48, distance - 2);
    return _lerp(0.48, 0.42, distance - 3);
  }

  double _visualOffsetForLogical(double logicalOffset) {
    final distance = logicalOffset.abs();
    if (distance <= 1) return logicalOffset * _slotSpacing;
    final sign = logicalOffset < 0 ? -1.0 : 1.0;
    return sign * (_slotSpacing + (distance - 1) * _compressedOuterSpacing);
  }

  Color _colorForItem(BackheaderBudgetItem item) {
    final category = item.category;
    if (category != null) return category.color;
    return switch (item.overview?.kind) {
      BudgetGoalKind.incomeGoal => AppColors.income,
      BudgetGoalKind.savingGoal => const Color(0xFF3B82F6),
      _ => AppColors.primary,
    };
  }

  bool _hasLimitForItem(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null) return overview.hasLimit && overview.limitAmount > 0;
    final category = item.category;
    return category != null && category.hasLimit && category.limitAmount > 0;
  }

  double _progressForItem(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null) {
      if (!overview.hasLimit || overview.limitAmount <= 0) return 0;
      return (overview.amount / overview.limitAmount)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    final category = item.category;
    if (category == null) return 0;
    return category.progress;
  }

  Color _progressColorForItem(BackheaderBudgetItem item) {
    final base = _colorForItem(item);
    final overview = item.overview;
    final ratio = overview != null
        ? (!overview.hasLimit || overview.limitAmount <= 0
              ? 0.0
              : overview.amount / overview.limitAmount)
        : item.category?.rawProgress ?? 0.0;
    if (ratio >= 0.90) return AppColors.expense;
    if (ratio >= 0.75) return const Color(0xFFEAB308);
    return base;
  }

  double _lerp(double begin, double end, double value) {
    return begin + (end - begin) * value;
  }
}

class _CenterWheelSlotData {
  const _CenterWheelSlotData({
    required this.offset,
    required this.item,
    required this.color,
    required this.centerX,
    required this.distance,
    required this.size,
    required this.opacity,
    required this.progress,
    required this.hasLimit,
    required this.progressColor,
    required this.onTap,
  });

  final int offset;
  final BackheaderBudgetItem item;
  final Color color;
  final double centerX;
  final double distance;
  final double size;
  final double opacity;
  final double progress;
  final bool hasLimit;
  final Color progressColor;
  final VoidCallback? onTap;
}

BoxDecoration _centerBadgeDecoration({
  required Color color,
  required bool coloredDesign,
}) {
  if (!coloredDesign) {
    return BoxDecoration(color: color, shape: BoxShape.circle);
  }
  return BoxDecoration(
    color: AppColors.white.withValues(alpha: 0.18),
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
  );
}

class _CenterBadgeVisual extends StatelessWidget {
  const _CenterBadgeVisual({
    super.key,
    required this.item,
    required this.previewSlotName,
    required this.active,
    required this.color,
    required this.coloredDesign,
    required this.size,
    required this.opacity,
    required this.progress,
    required this.hasLimit,
    required this.progressColor,
    required this.ringTrackColor,
    required this.partitionAllocation,
    required this.onTap,
    required this.onBadgeLongPressStart,
    required this.onBadgeLongPressMoveUpdate,
    required this.onBadgeLongPressEnd,
    required this.onBadgeLongPressCancel,
  });

  static const _baseSize = 78.0;
  static const _baseFillSize = 58.0;
  static const _baseIconSize = 27.0;
  static const _partitionPadding = 4.0;

  final BackheaderBudgetItem item;
  final String? previewSlotName;
  final bool active;
  final Color color;
  final bool coloredDesign;
  final double size;
  final double opacity;
  final double progress;
  final bool hasLimit;
  final Color progressColor;
  final Color ringTrackColor;
  final LimitAllocationData? partitionAllocation;
  final VoidCallback? onTap;
  final GestureLongPressStartCallback? onBadgeLongPressStart;
  final GestureLongPressMoveUpdateCallback? onBadgeLongPressMoveUpdate;
  final GestureLongPressEndCallback? onBadgeLongPressEnd;
  final VoidCallback? onBadgeLongPressCancel;

  @override
  Widget build(BuildContext context) {
    final scale = size / _baseSize;
    final fillSize = _baseFillSize * scale;
    final partitionSize = fillSize + _partitionPadding * scale * 2;
    final iconSize = (_baseIconSize * scale).clamp(14.0, 27.0).toDouble();
    final progressKey = active
        ? const ValueKey('backheader-center-progress-ring')
        : ValueKey('backheader-center-preview-progress-ring-$previewSlotName');
    final fillKey = active
        ? const ValueKey('backheader-center-budget-button')
        : ValueKey('backheader-center-preview-fill-$previewSlotName');

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (partitionAllocation != null)
              SizedBox(
                width: partitionSize,
                height: partitionSize,
                child: CustomPaint(
                  key: const ValueKey('backheader-center-partition-ring'),
                  painter: _CenterBadgePartitionRingPainter(
                    allocation: partitionAllocation!,
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPressStart: active ? onBadgeLongPressStart : null,
              onLongPressMoveUpdate: active ? onBadgeLongPressMoveUpdate : null,
              onLongPressEnd: active ? onBadgeLongPressEnd : null,
              onLongPressCancel: active ? onBadgeLongPressCancel : null,
              child: Container(
                key: fillKey,
                width: fillSize,
                height: fillSize,
                decoration: _centerBadgeDecoration(
                  color: color,
                  coloredDesign: coloredDesign,
                ),
                alignment: Alignment.center,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      key: progressKey,
                      painter: _CenterBadgeProgressRingPainter(
                        progress: hasLimit ? progress : 0,
                        color: progressColor,
                        trackColor: ringTrackColor,
                        showFill: hasLimit,
                      ),
                    ),
                    Center(
                      child: item.category == null
                          ? Icon(
                              _overviewIcon(item.overview?.kind),
                              color: AppColors.white,
                              size: iconSize,
                            )
                          : CategorySlotIcon(
                              slot: item.category!.iconSlot,
                              color: AppColors.white,
                              size: iconSize,
                              listenForSlotChanges: false,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

const _centerBadgeRingStrokeWidth = 2.4;

class _CenterBadgePartitionRingPainter extends CustomPainter {
  const _CenterBadgePartitionRingPainter({required this.allocation});

  final LimitAllocationData allocation;

  @override
  void paint(Canvas canvas, Size size) {
    if (allocation.segments.isEmpty) return;
    final rect = (Offset.zero & size).deflate(_centerBadgeRingStrokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _centerBadgeRingStrokeWidth
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (final segment in allocation.segments) {
      final sweep = math.pi * 2 * segment.fraction.clamp(0.0, 1.0);
      if (sweep <= 0) continue;
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CenterBadgePartitionRingPainter oldDelegate) {
    final oldSegments = oldDelegate.allocation.segments;
    final segments = allocation.segments;
    if (oldSegments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i += 1) {
      final old = oldSegments[i];
      final current = segments[i];
      if (old.fraction != current.fraction ||
          old.color != current.color ||
          old.kind != current.kind) {
        return true;
      }
    }
    return oldDelegate.allocation.overviewLimit != allocation.overviewLimit;
  }
}

class _CenterBadgeProgressRingPainter extends CustomPainter {
  const _CenterBadgeProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.showFill,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final bool showFill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_centerBadgeRingStrokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _centerBadgeRingStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, 0, 6.283185307179586, false, track);
    if (!showFill) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _centerBadgeRingStrokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -1.5707963267948966,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterBadgeProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.showFill != showFill;
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
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.22);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white;
    final ringRect = rect.deflate(1.8);
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

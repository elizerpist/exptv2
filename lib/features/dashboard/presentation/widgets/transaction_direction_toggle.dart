import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../../../../core/design/app_control_metrics.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../application/transaction_direction_controller.dart';
import '../../application/dashboard_performance_counters.dart';

/// Input-only renderer for the two transaction directions.
class TransactionDirectionToggle extends StatelessWidget {
  const TransactionDirectionToggle({
    super.key,
    required this.bounds,
    required this.palette,
    required this.selectedDirection,
    required this.incomeIconScale,
    required this.expenseIconScale,
    required this.onSelected,
    this.selectedIconScaleAnimation,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardModePalette palette;
  final TransactionDirection selectedDirection;
  final double incomeIconScale;
  final double expenseIconScale;
  final ValueChanged<TransactionDirection> onSelected;
  final Animation<double>? selectedIconScaleAnimation;
  final DashboardPerformanceCounters? performanceCounters;

  static const AssetBytesLoader _incomeIconLoader = AssetBytesLoader(
    'assets/fluvi/actions/income_wallet.svg.vec',
  );
  static const AssetBytesLoader _expenseIconLoader = AssetBytesLoader(
    'assets/fluvi/actions/expense_bag.svg.vec',
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Row(
        children: [
          Expanded(
            child: _DirectionButton(
              direction: TransactionDirection.income,
              label: 'Bevétel',
              bytesLoader: _incomeIconLoader,
              assetKey: const ValueKey('fluvi-income-wallet'),
              activeGradient: FluviVisualTokens.incomeButtonHighlightGradient,
              selected: selectedDirection == TransactionDirection.income,
              iconScale: incomeIconScale,
              iconScaleAnimation:
                  selectedDirection == TransactionDirection.income
                  ? selectedIconScaleAnimation
                  : null,
              onTap: onSelected,
              performanceCounters: performanceCounters,
            ),
          ),
          const SizedBox(width: FluviVisualTokens.controlInnerGap),
          Expanded(
            child: _DirectionButton(
              direction: TransactionDirection.expense,
              label: 'Kiadás',
              bytesLoader: _expenseIconLoader,
              assetKey: const ValueKey('fluvi-expense-bag'),
              activeGradient: palette.expenseGradient,
              selected: selectedDirection == TransactionDirection.expense,
              iconScale: expenseIconScale,
              iconScaleAnimation:
                  selectedDirection == TransactionDirection.expense
                  ? selectedIconScaleAnimation
                  : null,
              onTap: onSelected,
              performanceCounters: performanceCounters,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.label,
    required this.bytesLoader,
    required this.assetKey,
    required this.activeGradient,
    required this.selected,
    required this.iconScale,
    required this.iconScaleAnimation,
    required this.onTap,
    required this.performanceCounters,
  });

  final TransactionDirection direction;
  final String label;
  final AssetBytesLoader bytesLoader;
  final Key assetKey;
  final LinearGradient activeGradient;
  final bool selected;
  final double iconScale;
  final Animation<double>? iconScaleAnimation;
  final ValueChanged<TransactionDirection> onTap;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(direction),
      child: SizedBox(
        height: AppSelectorMetrics.directionControlHeight,
        child: FluviRoundedBox(
          key: assetKey == const ValueKey('fluvi-income-wallet')
              ? const ValueKey('fluvi-income-button')
              : const ValueKey('fluvi-expense-button'),
          color: selected ? null : FluviVisualTokens.surface,
          gradient: selected ? activeGradient : null,
          borderRadius: BorderRadius.circular(
            AppSelectorMetrics.compactTileRadius,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DirectionIcon(
                  bytesLoader: bytesLoader,
                  assetKey: assetKey,
                  iconScale: iconScale,
                  iconScaleAnimation: iconScaleAnimation,
                  performanceCounters: performanceCounters,
                ),
                const SizedBox(width: FluviVisualTokens.controlInnerGap),
                Text(
                  label,
                  style: selected
                      ? FluviVisualTokens.actionLabelOnActiveTextStyle
                      : FluviVisualTokens.actionLabelTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionIcon extends StatelessWidget {
  const _DirectionIcon({
    required this.bytesLoader,
    required this.assetKey,
    required this.iconScale,
    required this.iconScaleAnimation,
    required this.performanceCounters,
  });

  final AssetBytesLoader bytesLoader;
  final Key assetKey;
  final double iconScale;
  final Animation<double>? iconScaleAnimation;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(
      DashboardPerformanceMetric.svgPulseSubtreeBuild,
    );
    final icon = SvgPicture(
      bytesLoader,
      key: assetKey,
      width: FluviVisualTokens.actionIconSize,
      height: FluviVisualTokens.actionIconSize,
    );
    final animation = iconScaleAnimation;
    if (animation == null) return _scaledIcon(iconScale, icon);
    return AnimatedBuilder(
      animation: animation,
      child: icon,
      builder: (context, child) => _scaledIcon(animation.value, child!),
    );
  }

  Widget _scaledIcon(double scale, Widget child) => Transform.scale(
    scale: scale * FluviVisualTokens.directionIconScaleMultiplier,
    child: child,
  );
}

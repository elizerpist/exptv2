import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/app_control_metrics.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../application/transaction_direction_controller.dart';

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
  });

  final DashboardBounds bounds;
  final DashboardModePalette palette;
  final TransactionDirection selectedDirection;
  final double incomeIconScale;
  final double expenseIconScale;
  final ValueChanged<TransactionDirection> onSelected;

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
              assetPath: 'assets/fluvi/actions/income_wallet.svg',
              assetKey: const ValueKey('fluvi-income-wallet'),
              activeGradient: palette.incomeGradient,
              selected: selectedDirection == TransactionDirection.income,
              iconScale: incomeIconScale,
              onTap: onSelected,
            ),
          ),
          const SizedBox(width: FluviVisualTokens.controlInnerGap),
          Expanded(
            child: _DirectionButton(
              direction: TransactionDirection.expense,
              label: 'Kiadás',
              assetPath: 'assets/fluvi/actions/expense_bag.svg',
              assetKey: const ValueKey('fluvi-expense-bag'),
              activeGradient: palette.expenseGradient,
              selected: selectedDirection == TransactionDirection.expense,
              iconScale: expenseIconScale,
              onTap: onSelected,
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
    required this.assetPath,
    required this.assetKey,
    required this.activeGradient,
    required this.selected,
    required this.iconScale,
    required this.onTap,
  });

  final TransactionDirection direction;
  final String label;
  final String assetPath;
  final Key assetKey;
  final LinearGradient activeGradient;
  final bool selected;
  final double iconScale;
  final ValueChanged<TransactionDirection> onTap;

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
                Transform.scale(
                  scale: iconScale,
                  child: SvgPicture.asset(
                    assetPath,
                    key: assetKey,
                    width: FluviVisualTokens.actionIconSize,
                    height: FluviVisualTokens.actionIconSize,
                  ),
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

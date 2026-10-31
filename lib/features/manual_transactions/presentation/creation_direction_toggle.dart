import 'package:flutter/material.dart';

import '../../../core/design/fluvi_global_appearance.dart';
import '../../dashboard/query/domain/ledger_direction.dart';

/// Compact create-only direction control shared by the manual and recurring
/// editors. The editor owns the draft direction; this widget only renders and
/// reports an explicit user choice.
final class CreationDirectionToggle extends StatelessWidget {
  const CreationDirectionToggle({
    super.key,
    required this.direction,
    required this.colorProfile,
    required this.onChanged,
    this.enabled = true,
  });

  final LedgerDirection direction;
  final FluviDirectionColorProfile colorProfile;
  final ValueChanged<LedgerDirection> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isIncome = direction == LedgerDirection.income;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final gradient = isIncome
        ? FluviDirectionColorPaletteCatalog.income(colorProfile)
        : FluviDirectionColorPaletteCatalog.expense(colorProfile);
    return SizedBox(
      key: const ValueKey<String>('creation-direction-toggle'),
      width: 92,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .50)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AnimatedAlign(
                alignment: isIncome
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: 40,
                  height: 34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  _DirectionToggleSide(
                    key: const ValueKey<String>('creation-direction-income'),
                    label: 'Bevétel',
                    selected: isIncome,
                    enabled: enabled,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => onChanged(LedgerDirection.income),
                  ),
                  _DirectionToggleSide(
                    key: const ValueKey<String>('creation-direction-expense'),
                    label: 'Kiadás',
                    selected: !isIncome,
                    enabled: enabled,
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => onChanged(LedgerDirection.expense),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DirectionToggleSide extends StatelessWidget {
  const _DirectionToggleSide({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Center(
              child: Icon(
                icon,
                size: 21,
                color: selected ? Colors.white : const Color(0xff64748b),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

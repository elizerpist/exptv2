import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../models/transaction_category.dart';
import 'transaction_menu_metrics.dart';

class TransactionTypePills extends StatelessWidget {
  const TransactionTypePills({
    super.key,
    required this.activeType,
    required this.onChanged,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  });

  final TransactionType activeType;
  final ValueChanged<TransactionType> onChanged;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        TransactionMenuMetrics.typePillTopPadding,
        20,
        TransactionMenuMetrics.typePillBottomPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TransactionTypePill(
              type: TransactionType.income,
              active: activeType == TransactionType.income,
              surfaceColor: surfaceColor,
              surfaceStyle: surfaceStyle,
              accentColor: accentColor,
              onTap: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TransactionTypePill(
              type: TransactionType.expense,
              active: activeType == TransactionType.expense,
              surfaceColor: surfaceColor,
              surfaceStyle: surfaceStyle,
              accentColor: accentColor,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTypePill extends StatelessWidget {
  const _TransactionTypePill({
    required this.type,
    required this.active,
    required this.surfaceColor,
    required this.surfaceStyle,
    required this.accentColor,
    required this.onTap,
  });

  final TransactionType type;
  final bool active;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color accentColor;
  final ValueChanged<TransactionType> onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(25);
    final materialFeedback = ExpenseSurface.materialFeedbackEnabled(
      surfaceStyle,
    );
    return ExpensePressable(
      enabled: surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        return ExpenseSurfaceContainer(
          surfaceKey: ValueKey(
            'transaction-type-pill-${type.nativeValue}-surface',
          ),
          style: surfaceStyle,
          color: surfaceColor,
          borderRadius: radius,
          pressed: pressed,
          primary: active,
          primaryColor: accentColor,
          constraints: const BoxConstraints(
            minHeight: TransactionMenuMetrics.typePillMinHeight,
          ),
          neutralBorder: Border.all(
            color: active ? accentColor : AppColors.gray200,
          ),
          neutralShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.1 : 0.08),
              offset: const Offset(0, 2),
              blurRadius: active ? 3 : 4,
            ),
          ],
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              overlayColor: materialFeedback
                  ? null
                  : ExpenseSurface.transparentOverlayColor,
              splashColor: materialFeedback ? null : Colors.transparent,
              highlightColor: materialFeedback ? null : Colors.transparent,
              onTap: () => onTap(type),
              child: SizedBox(
                height: TransactionMenuMetrics.typePillMinHeight,
                child: Center(
                  child: Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.white : AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

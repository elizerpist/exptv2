import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../slots/category_color_resolver.dart';
import 'category_menu/category_icon_badge.dart';
import 'ghost_logbox_visuals.dart';

class RecurringGhostLogBox extends StatelessWidget {
  const RecurringGhostLogBox({
    super.key,
    required this.ghost,
    required this.category,
    this.surfaceColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.settings = const GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.dashed,
      backgroundOpacityEnabled: true,
      avatarOpacityEnabled: false,
      textOpacityEnabled: false,
      avatarBadgeEnabled: true,
      textTone: GhostLogboxTextTone.normal,
      expectedLabelEnabled: true,
    ),
  });

  static const _ghostBackgroundOpacity = 0.72;
  static const _ghostAvatarOpacity = 0.58;
  static const _ghostTextOpacity = 0.68;

  final RecurringGhostRecord ghost;
  final TransactionCategory? category;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final GhostLogboxSettings settings;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(25);
    final content = ExpenseSurfaceContainer(
      style: surfaceStyle,
      color: _surfaceColor,
      borderRadius: borderRadius,
      neutralBorder: Border.all(color: _solidBorderColor),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 12),
          Expanded(child: _textColumn()),
          const SizedBox(width: 12),
          _amountColumn(),
        ],
      ),
    );
    final styledContent = settings.borderStyle == GhostLogboxBorderStyle.dashed
        ? DashedRoundedBorder(
            key: ValueKey('recurring-ghost-dashed-border-${ghost.id}'),
            borderRadius: borderRadius,
            color: AppColors.gray400.withValues(alpha: 0.78),
            child: content,
          )
        : content;

    return Container(
      key: ValueKey('recurring-ghost-logbox-${ghost.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SizedBox(height: 72, child: styledContent),
    );
  }

  Color get _surfaceColor {
    if (!settings.backgroundOpacityEnabled) return surfaceColor;
    return surfaceColor.withValues(alpha: _ghostBackgroundOpacity);
  }

  Color get _solidBorderColor {
    if (settings.borderStyle == GhostLogboxBorderStyle.dashed) {
      return Colors.transparent;
    }
    return AppColors.gray300;
  }

  Color get _merchantColor {
    if (settings.textTone == GhostLogboxTextTone.gray) return AppColors.gray600;
    return AppColors.gray800;
  }

  Color get _amountColor {
    if (settings.textTone == GhostLogboxTextTone.gray) return AppColors.gray600;
    return ghost.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
  }

  Widget _avatar() {
    final avatar = CategoryIconBadge(
      category: category,
      backgroundColor: CategoryColorResolver.color(
        category: category,
        snapshotHex: ghost.categoryColor,
        fallback: AppColors.gray500,
      ),
      size: 46,
      iconSize: 28,
      showShadow: false,
    );
    return SizedBox.square(
      dimension: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          settings.avatarOpacityEnabled
              ? Opacity(opacity: _ghostAvatarOpacity, child: avatar)
              : avatar,
          if (settings.avatarBadgeEnabled)
            const Positioned(right: -1, bottom: -1, child: GhostBadge()),
        ],
      ),
    );
  }

  Widget _textColumn() {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ghost.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _merchantColor,
          ),
        ),
        if (settings.expectedLabelEnabled) ...[
          const SizedBox(height: 3),
          const Text(
            'Várható · ismétlődő',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
            ),
          ),
        ],
      ],
    );
    if (!settings.textOpacityEnabled) return column;
    return Opacity(opacity: _ghostTextOpacity, child: column);
  }

  Widget _amountColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          ghost.displayAmount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _amountColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ghost.displayTime,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

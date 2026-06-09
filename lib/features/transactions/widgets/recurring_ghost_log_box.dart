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
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
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
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final GhostLogboxSettings settings;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(25);
    final content = ExpenseSurfaceContainer(
      style: surfaceStyle,
      color: _surfaceColor,
      borderRadius: borderRadius,
      neutralBorder: _usesDashedBorder
          ? Border.all(color: Colors.transparent)
          : null,
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
    final styledContent = _usesDashedBorder
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

  bool get _usesDashedBorder => !surfaceStyle.hasPressEffect;

  Color get _surfaceColor =>
      surfaceColor.withValues(alpha: _ghostBackgroundOpacity);

  Color get _merchantColor => AppColors.gray600;

  Color get _amountColor => AppColors.gray600;

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
          Opacity(opacity: _ghostAvatarOpacity, child: avatar),
          Positioned(right: -1, bottom: -1, child: _ghostBadge()),
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
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ghost.isPushTriggered
                  ? Icons.notifications_outlined
                  : Icons.schedule_outlined,
              key: ValueKey('recurring-ghost-trigger-icon-${ghost.id}'),
              size: 12,
              color: AppColors.gray500,
            ),
            const SizedBox(width: 4),
            Text(
              ghost.isPushTriggered ? 'Várható · push' : 'Várható · idő',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
    return Opacity(opacity: _ghostTextOpacity, child: column);
  }

  Widget _amountColumn() {
    final column = Column(
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
    return Opacity(opacity: _ghostTextOpacity, child: column);
  }

  Widget _ghostBadge() {
    if (!avatarSurfaceStyle.hasPressEffect) return const GhostBadge();
    return ExpenseSurfaceContainer(
      style: avatarSurfaceStyle,
      color: AppColors.white,
      borderRadius: BorderRadius.circular(9),
      width: 18,
      height: 18,
      primaryColor: AppColors.gray500,
      child: const GhostBadge(
        backgroundColor: Colors.transparent,
        strokeColor: Colors.transparent,
      ),
    );
  }
}

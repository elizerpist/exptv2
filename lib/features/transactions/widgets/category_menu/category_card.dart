import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/transaction_category.dart';
import 'category_icon_badge.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    required this.onSelect,
    required this.onModify,
    required this.onDelete,
    this.active = false,
    this.surfaceColor = AppColors.gray50,
    this.cardSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  });

  final TransactionCategory category;
  final int transactionCount;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onDelete;
  final bool active;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final Color accentColor;

  bool get _hasTransactions => transactionCount > 0;

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    onModify(category);
  }

  @override
  Widget build(BuildContext context) {
    final activeUsesInset = active && cardSurfaceStyle.hasPressEffect;
    final avatarCardOffset = ExpenseSurface.pressOffset(
      style: cardSurfaceStyle,
      pressed: activeUsesInset,
    );
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: ValueKey('category-card-${category.transactionCategoryID}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(category),
              onLongPress: _handleLongPress,
              child: ExpensePressable(
                enabled: cardSurfaceStyle.hasPressEffect,
                forcePressed: activeUsesInset,
                builder: (context, pressed) {
                  final radius = BorderRadius.circular(18);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ExpenseSurfaceContainer(
                        surfaceKey: ValueKey(
                          'category-card-surface-${category.transactionCategoryID}',
                        ),
                        style: cardSurfaceStyle,
                        color: surfaceColor,
                        borderRadius: radius,
                        pressed: pressed,
                        padding: const EdgeInsets.fromLTRB(12, 82, 12, 14),
                        neutralBorder: Border.all(color: AppColors.gray200),
                        neutralShadow: categoryNeutralShadow(cardSurfaceStyle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              category.name,
                              key: ValueKey(
                                'category-card-title-${category.transactionCategoryID}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$transactionCount tranzakció',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (active && !cardSurfaceStyle.hasPressEffect)
                        CategoryActiveBorder(
                          key: ValueKey(
                            'category-card-active-border-${category.transactionCategoryID}',
                          ),
                          radius: radius,
                          color: accentColor,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset.zero, end: avatarCardOffset),
                duration: ExpenseSurface.pressDuration,
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(offset: value, child: child);
                },
                child: IgnorePointer(
                  child: ExpensePressable(
                    key: ValueKey(
                      'category-icon-${category.transactionCategoryID}',
                    ),
                    enabled: avatarSurfaceStyle.hasPressEffect,
                    forcePressed: active && avatarSurfaceStyle.hasPressEffect,
                    builder: (context, pressed) {
                      return ExpenseSurfaceContainer(
                        surfaceKey: ValueKey(
                          'category-icon-surface-${category.transactionCategoryID}',
                        ),
                        style: avatarSurfaceStyle,
                        color: category.slotColor,
                        primary: true,
                        primaryColor: category.slotColor,
                        borderRadius: BorderRadius.circular(32.5),
                        pressed: pressed,
                        width: 65,
                        height: 65,
                        child: CategoryIconBadge(
                          category: category,
                          backgroundColor: Colors.transparent,
                          size: 65,
                          iconSize: 44,
                          iconStrokeWidth: 1.35,
                          showShadow: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              key: ValueKey(
                'category-delete-${category.transactionCategoryID}',
              ),
              onTap: _hasTransactions ? null : () => onDelete(category),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hasTransactions
                      ? AppColors.gray500.withValues(alpha: 0.3)
                      : AppColors.expense.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<BoxShadow>? categoryNeutralShadow(ExpenseSurfaceInteraction style) {
  if (style != ExpenseSurfaceInteraction.neutralNeutral) return null;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];
}

class CategoryActiveBorder extends StatelessWidget {
  const CategoryActiveBorder({
    super.key,
    required this.radius,
    required this.color,
  });

  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/transaction_category.dart';
import 'category_icon_badge.dart';

class CategoryCard extends StatefulWidget {
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

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  Timer? _cardReleaseTimer;
  var _cardPressed = false;

  bool get _hasTransactions => widget.transactionCount > 0;

  @override
  void dispose() {
    _cardReleaseTimer?.cancel();
    super.dispose();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onModify(widget.category);
  }

  void _pressCard() {
    if (!widget.cardSurfaceStyle.hasPressEffect) return;
    _cardReleaseTimer?.cancel();
    _setCardPressed(true);
  }

  void _releaseCardSoon() {
    if (!widget.cardSurfaceStyle.hasPressEffect) return;
    _cardReleaseTimer?.cancel();
    _cardReleaseTimer = Timer(const Duration(milliseconds: 120), () {
      _setCardPressed(false);
    });
  }

  void _setCardPressed(bool value) {
    if (_cardPressed == value || !mounted) return;
    setState(() => _cardPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final activeUsesInset =
        widget.active && widget.cardSurfaceStyle.hasPressEffect;
    final cardPressed = activeUsesInset || _cardPressed;
    final avatarCardOffset = ExpenseSurface.pressOffset(
      style: widget.cardSurfaceStyle,
      pressed: cardPressed,
    );
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _pressCard(),
              onPointerUp: (_) => _releaseCardSoon(),
              onPointerCancel: (_) => _releaseCardSoon(),
              child: GestureDetector(
                key: ValueKey(
                  'category-card-${widget.category.transactionCategoryID}',
                ),
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onSelect(widget.category),
                onLongPress: _handleLongPress,
                child: ExpensePressable(
                  enabled: widget.cardSurfaceStyle.hasPressEffect,
                  forcePressed: cardPressed,
                  builder: (context, pressed) {
                    final radius = BorderRadius.circular(18);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ExpenseSurfaceContainer(
                          surfaceKey: ValueKey(
                            'category-card-surface-${widget.category.transactionCategoryID}',
                          ),
                          style: widget.cardSurfaceStyle,
                          color: widget.surfaceColor,
                          borderRadius: radius,
                          pressed: pressed,
                          padding: const EdgeInsets.fromLTRB(12, 82, 12, 14),
                          neutralBorder: Border.all(color: AppColors.gray200),
                          neutralShadow: categoryNeutralShadow(
                            widget.cardSurfaceStyle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.category.name,
                                key: ValueKey(
                                  'category-card-title-${widget.category.transactionCategoryID}',
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
                                '${widget.transactionCount} tranzakció',
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
                        if (widget.active &&
                            !widget.cardSurfaceStyle.hasPressEffect)
                          CategoryActiveBorder(
                            key: ValueKey(
                              'category-card-active-border-${widget.category.transactionCategoryID}',
                            ),
                            radius: radius,
                            color: widget.accentColor,
                          ),
                      ],
                    );
                  },
                ),
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
                      'category-icon-${widget.category.transactionCategoryID}',
                    ),
                    enabled: widget.avatarSurfaceStyle.hasPressEffect,
                    forcePressed:
                        cardPressed && widget.avatarSurfaceStyle.hasPressEffect,
                    builder: (context, pressed) {
                      return ExpenseSurfaceContainer(
                        surfaceKey: ValueKey(
                          'category-icon-surface-${widget.category.transactionCategoryID}',
                        ),
                        style: widget.avatarSurfaceStyle,
                        color: widget.category.slotColor,
                        primary: true,
                        primaryColor: widget.category.slotColor,
                        borderRadius: BorderRadius.circular(32.5),
                        pressed: pressed,
                        width: 65,
                        height: 65,
                        child: CategoryIconBadge(
                          category: widget.category,
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
                'category-delete-${widget.category.transactionCategoryID}',
              ),
              onTap: _hasTransactions
                  ? null
                  : () => widget.onDelete(widget.category),
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

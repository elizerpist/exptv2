import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/limit_allocation_data.dart';
import 'magnet_strip.dart';
import 'transaction_header_metrics.dart';

class TransactionHeaderCard extends StatelessWidget {
  const TransactionHeaderCard({
    super.key,
    required this.balanceText,
    required this.onCategoryPressed,
    required this.onExpandPressed,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.labelText = 'Egyenleg',
    this.expanded = false,
    this.magnetType = MagnetType.fade,
    this.accent = AppColors.primary,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.buttonSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.budgetAllocation,
    this.leadingChipText,
    this.leadingChipColor,
    this.magnetGradientColors,
    this.magnetMarkerPosition,
    this.magnetMarkerStyle = MagnetMarkerStyle.circle,
    this.magnetKey,
    this.fastInfoVisible = false,
    this.balanceHidden = false,
    this.showBalanceVisibilityButton = true,
    this.drawSurface = true,
    this.onBalanceVisibilityPressed,
    this.onNotificationPressed,
    this.notificationUnreadCount = 0,
    this.slideProgress,
    this.contentOpacity,
  });

  final String balanceText;
  final VoidCallback onCategoryPressed;
  final VoidCallback onExpandPressed;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final String labelText;
  final bool expanded;
  final MagnetType magnetType;
  final Color accent;
  final Color cardColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final double totalIncome;
  final double totalExpense;
  final LimitAllocationData? budgetAllocation;
  final String? leadingChipText;
  final Color? leadingChipColor;
  final List<Color>? magnetGradientColors;
  final double? magnetMarkerPosition;
  final MagnetMarkerStyle magnetMarkerStyle;
  final String? magnetKey;
  final bool fastInfoVisible;
  final bool balanceHidden;
  final bool showBalanceVisibilityButton;
  final bool drawSurface;
  final VoidCallback? onBalanceVisibilityPressed;
  final VoidCallback? onNotificationPressed;
  final int notificationUnreadCount;
  final double? slideProgress;
  final double? contentOpacity;

  static const height = TransactionHeaderMetrics.cardHeight;

  @override
  Widget build(BuildContext context) {
    final visibleBalanceText = balanceHidden ? '••••••• Ft' : balanceText;
    final resolvedContentOpacity = contentOpacity ?? (expanded ? 0.0 : 1.0);

    Widget headerContentOpacity(Widget child) {
      if (contentOpacity != null) {
        return Opacity(opacity: resolvedContentOpacity, child: child);
      }
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: resolvedContentOpacity,
        child: child,
      );
    }

    final headerBody = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: SizedBox(
        key: const ValueKey('transaction-header-card'),
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (drawSurface)
              Positioned.fill(
                child: ExpenseSurfaceContainer(
                  surfaceKey: const ValueKey('transaction-header-surface'),
                  style: surfaceStyle,
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  animatePress: false,
                  clipContent: false,
                  neutralShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                  profile: ExpenseSurfaceProfile.headerCard,
                  child: const SizedBox.expand(),
                ),
              ),
            const Positioned(
              top: TransactionHeaderMetrics.titleTop,
              left: 30,
              child: Text(
                'ExpenseTracker',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.magnetTop,
              left: 0,
              right: 0,
              child: SizedBox(
                height: TransactionHeaderMetrics.magnetHeight,
                child: MagnetStrip(
                  type: magnetType,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  accent: accent,
                  height: TransactionHeaderMetrics.magnetHeight,
                  budgetAllocation: budgetAllocation,
                  customGradientColors: magnetGradientColors,
                  customMarkerPosition: magnetMarkerPosition,
                  customMarkerStyle: magnetMarkerStyle,
                  customKey: magnetKey,
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.cameraTop,
              left: 30,
              child: _HeaderLeadingChip(
                text: leadingChipText,
                color: leadingChipColor ?? const Color(0xFFFBBF24),
                onPressed: onExpandPressed,
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.balanceLabelTop,
              left: 30,
              child: headerContentOpacity(
                Text(
                  labelText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.balanceTop,
              left: 30,
              right: 90,
              child: headerContentOpacity(
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        visibleBalanceText,
                        key: const ValueKey('header-balance-text'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    if (showBalanceVisibilityButton) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        key: const ValueKey('header-balance-visibility-button'),
                        onPressed: onBalanceVisibilityPressed,
                        icon: Icon(
                          balanceHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.gray800,
                          size: 20,
                        ),
                        tooltip: balanceHidden
                            ? 'Egyenleg megjelenítése'
                            : 'Egyenleg elrejtése',
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.categoryButtonTop,
              right: 25,
              child: headerContentOpacity(
                _HeaderCategoryButton(
                  surfaceStyle: buttonSurfaceStyle,
                  primaryColor: accent,
                  onPressed: onCategoryPressed,
                ),
              ),
            ),
            if (onNotificationPressed != null)
              Positioned(
                top: TransactionHeaderMetrics.titleTop - 4,
                right: 25,
                child: _HeaderNotificationButton(
                  unreadCount: notificationUnreadCount,
                  onPressed: onNotificationPressed!,
                ),
              ),
          ],
        ),
      ),
    );

    final headerSlide = slideProgress;
    final slidingHeader = headerSlide == null
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -TransactionHeaderMetrics.expandedSlideDistance * value,
                ),
                child: child,
              );
            },
            child: headerBody,
          )
        : Transform.translate(
            offset: Offset(
              0,
              -TransactionHeaderMetrics.expandedSlideDistance * headerSlide,
            ),
            child: headerBody,
          );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: slidingHeader,
    );
  }
}

class _HeaderNotificationButton extends StatelessWidget {
  const _HeaderNotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const ValueKey('header-notification-button'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gray200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.gray800,
                size: 19,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            key: const ValueKey('header-notification-unread-badge'),
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.expense,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderCategoryButton extends StatelessWidget {
  const _HeaderCategoryButton({
    required this.surfaceStyle,
    required this.primaryColor,
    required this.onPressed,
  });

  final ExpenseSurfaceInteraction surfaceStyle;
  final Color primaryColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final materialFeedback = ExpenseSurface.materialFeedbackEnabled(
      surfaceStyle,
    );
    return ExpensePressable(
      enabled: surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        return ExpenseSurfaceContainer(
          surfaceKey: const ValueKey('header-category-button-surface'),
          style: surfaceStyle,
          color: primaryColor,
          borderRadius: radius,
          pressed: pressed,
          primary: false,
          primaryColor: primaryColor,
          width: 48,
          height: 48,
          clipContent: false,
          neutralShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              key: const ValueKey('header-category-button'),
              onTap: onPressed,
              borderRadius: radius,
              overlayColor: materialFeedback
                  ? null
                  : ExpenseSurface.transparentOverlayColor,
              splashColor: materialFeedback ? null : Colors.transparent,
              highlightColor: materialFeedback ? null : Colors.transparent,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _MenuBar(),
                    SizedBox(height: 3),
                    _MenuBar(),
                    SizedBox(height: 3),
                    _MenuBar(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderLeadingChip extends StatelessWidget {
  const _HeaderLeadingChip({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  final String? text;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(7);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        key: const ValueKey('header-budget-trigger-chip'),
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          key: text == null ? null : const ValueKey('header-scope-chip'),
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: text == null
              ? const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.white,
                  size: 20,
                )
              : Text(
                  text!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

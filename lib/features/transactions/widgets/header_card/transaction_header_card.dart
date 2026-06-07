import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
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
    this.expanded = false,
    this.magnetType = MagnetType.fade,
    this.accent = AppColors.primary,
    this.cardColor = AppColors.gray100,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.buttonSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.fastInfoVisible = false,
    this.balanceHidden = false,
    this.drawSurface = true,
    this.onBalanceVisibilityPressed,
    this.slideProgress,
    this.contentOpacity,
  });

  final String balanceText;
  final VoidCallback onCategoryPressed;
  final VoidCallback onExpandPressed;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final bool expanded;
  final MagnetType magnetType;
  final Color accent;
  final Color cardColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final double totalIncome;
  final double totalExpense;
  final bool fastInfoVisible;
  final bool balanceHidden;
  final bool drawSurface;
  final VoidCallback? onBalanceVisibilityPressed;
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
              top: TransactionHeaderMetrics.cameraTop,
              left: 30,
              child: Container(
                key: const ValueKey('header-camera-chip'),
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.white,
                  size: 21,
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
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.balanceLabelTop,
              left: 30,
              child: headerContentOpacity(
                const Text(
                  'Egyenleg',
                  style: TextStyle(
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
                ),
              ),
            ),
            Positioned(
              top: TransactionHeaderMetrics.categoryButtonTop,
              right: 25,
              child: headerContentOpacity(
                _HeaderCategoryButton(
                  surfaceStyle: buttonSurfaceStyle,
                  onPressed: onCategoryPressed,
                ),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          slidingHeader,
          Positioned(
            top: TransactionHeaderMetrics.expandButtonTop - 13,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                key: const ValueKey('header-expand-button-hit-area'),
                width: 56,
                height: 56,
                child: Center(
                  child: ExpensePressable(
                    enabled: buttonSurfaceStyle.hasPressEffect,
                    builder: (context, pressed) {
                      final radius = BorderRadius.circular(15);
                      return ExpenseSurfaceContainer(
                        style: buttonSurfaceStyle,
                        color: AppColors.primary,
                        borderRadius: radius,
                        pressed: pressed,
                        primary: true,
                        width: 30,
                        height: 30,
                        clipContent: false,
                        neutralShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: radius,
                          child: InkWell(
                            key: const ValueKey('header-expand-button'),
                            onTap: onExpandPressed,
                            borderRadius: radius,
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                expanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCategoryButton extends StatelessWidget {
  const _HeaderCategoryButton({
    required this.surfaceStyle,
    required this.onPressed,
  });

  final ExpenseSurfaceInteraction surfaceStyle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return ExpensePressable(
      enabled: surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        return ExpenseSurfaceContainer(
          style: surfaceStyle,
          color: AppColors.primary,
          borderRadius: radius,
          pressed: pressed,
          primary: true,
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

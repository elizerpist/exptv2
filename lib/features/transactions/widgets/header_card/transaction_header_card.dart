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
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.fastInfoVisible = false,
    this.balanceHidden = false,
    this.onBalanceVisibilityPressed,
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
  final double totalIncome;
  final double totalExpense;
  final bool fastInfoVisible;
  final bool balanceHidden;
  final VoidCallback? onBalanceVisibilityPressed;

  static const height = TransactionHeaderMetrics.cardHeight;

  @override
  Widget build(BuildContext context) {
    final visibleBalanceText = balanceHidden ? '••••••• Ft' : balanceText;
    return SizedBox(
      key: const ValueKey('transaction-header-card'),
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: Offset(
                0,
                expanded
                    ? -TransactionHeaderMetrics.expandedSlideDistance / height
                    : 0,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.15,
                            ),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
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
                      width: 45,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.white,
                        size: 26,
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
                    top: TransactionHeaderMetrics.balanceTop,
                    left: 30,
                    right: 90,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: expanded ? 0 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Egyenleg',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  visibleBalanceText,
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
                                key: const ValueKey(
                                  'header-balance-visibility-button',
                                ),
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
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: TransactionHeaderMetrics.categoryButtonTop,
                    right: 25,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: expanded ? 0 : 1,
                      child: _HeaderCategoryButton(
                        onPressed: onCategoryPressed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  child: Material(
                    color: AppColors.primary,
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      key: const ValueKey('header-expand-button'),
                      onTap: onExpandPressed,
                      borderRadius: BorderRadius.circular(15),
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
  const _HeaderCategoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: const ValueKey('header-category-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
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

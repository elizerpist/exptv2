import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TransactionHeaderCard extends StatelessWidget {
  const TransactionHeaderCard({
    super.key,
    required this.balanceText,
    required this.onCategoryPressed,
    required this.onExpandPressed,
    this.expanded = false,
  });

  final String balanceText;
  final VoidCallback onCategoryPressed;
  final VoidCallback onExpandPressed;
  final bool expanded;

  static const height = 204.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('transaction-header-card'),
      height: height,
      width: double.infinity,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: Offset(0, expanded ? -160 / height : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 45,
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
              top: 37,
              right: 27,
              child: IconButton(
                key: const ValueKey('header-calendar-button'),
                onPressed: () {},
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppColors.gray600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                splashRadius: 20,
              ),
            ),
            Positioned(
              top: 75,
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
              top: 120,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 35,
                child: CustomPaint(painter: _HeaderMagnetPainter()),
              ),
            ),
            Positioned(
              top: 129,
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
                            balanceText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.visibility_outlined,
                          color: AppColors.gray800,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: 25,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: expanded ? 0 : 1,
                child: _HeaderCategoryButton(onPressed: onCategoryPressed),
              ),
            ),
            Positioned(
              top: 188,
              left: 0,
              right: 0,
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
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _HeaderMagnetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final incomePaint = Paint()
      ..color = const Color(0xFF2C2C2C).withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final expensePaint = Paint()
      ..color = const Color(0xFF2C2C2C).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final centerY = size.height / 2;
    final segmentWidth = size.width / 18;
    for (var i = 0; i < 18; i += 1) {
      final left = i * segmentWidth;
      final height = i.isEven ? 16.0 : 25.0;
      final paint = i < 6 ? incomePaint : expensePaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left + 2,
            centerY - height / 2,
            segmentWidth - 4,
            height,
          ),
          const Radius.circular(8),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

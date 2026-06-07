import 'package:flutter/material.dart';

import '../../data/limit_manager.dart';

class CategoryProgressBar extends StatelessWidget {
  const CategoryProgressBar({
    super.key,
    required this.spent,
    required this.limitAmount,
    this.fillColor,
    this.height = 2,
  });

  final double spent;
  final double limitAmount;
  final Color? fillColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = limitAmount <= 0
        ? 0.0
        : (spent / limitAmount).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                key: const ValueKey('category-progress-fill'),
                decoration: BoxDecoration(
                  color:
                      fillColor ??
                      LimitManager.progressColor(spent, limitAmount),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

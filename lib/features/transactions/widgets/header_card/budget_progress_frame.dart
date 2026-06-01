import 'package:flutter/material.dart';

import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';

class BudgetProgressFrame extends StatelessWidget {
  const BudgetProgressFrame({
    super.key,
    required this.progress,
    required this.kind,
    this.height = 62,
  });

  final BudgetProgressData progress;
  final BudgetGoalKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!progress.hasLimit) return const SizedBox.shrink();
    const borderWidth = 2.0;
    final borderColor = _borderColor();
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      key: const ValueKey('budget-progress-frame'),
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            key: const ValueKey('budget-progress-frame-background'),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: radius,
            ),
          ),
          ClipRRect(
            borderRadius: radius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                var left = 0.0;
                final children = <Widget>[];
                for (var i = 0; i < progress.segments.length; i += 1) {
                  final segment = progress.segments[i];
                  final width = constraints.maxWidth * segment.fraction;
                  children.add(
                    Positioned(
                      left: left,
                      top: 0,
                      width: width,
                      bottom: 0,
                      child: SizedBox.expand(
                        key: ValueKey('budget-progress-frame-segment-$i'),
                        child: ColoredBox(
                          color: segment.color.withValues(alpha: 1),
                        ),
                      ),
                    ),
                  );
                  left += width;
                }
                return Stack(fit: StackFit.expand, children: children);
              },
            ),
          ),
          if (borderColor != null)
            DecoratedBox(
              key: const ValueKey('budget-progress-frame-border'),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
            ),
        ],
      ),
    );
  }

  Color? _borderColor() {
    if (kind.warnsWhenHigh && progress.isDanger) {
      return const Color(0xffff4444);
    }
    if (kind.warnsWhenHigh && progress.isWarning) {
      return const Color(0xffff9800);
    }
    return null;
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    return Container(
      key: const ValueKey('budget-progress-frame'),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: _borderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var left = 0.0;
          final children = <Widget>[];
          for (var i = 0; i < progress.segments.length; i += 1) {
            final segment = progress.segments[i];
            final width = constraints.maxWidth * segment.fraction;
            children.add(
              Positioned(
                key: ValueKey('budget-progress-frame-segment-$i'),
                left: left,
                top: 0,
                width: width,
                bottom: 0,
                child: ColoredBox(color: segment.color),
              ),
            );
            left += width;
          }
          return Stack(fit: StackFit.expand, children: children);
        },
      ),
    );
  }

  Color _borderColor() {
    if (kind.warnsWhenHigh && progress.isDanger) {
      return const Color(0xffff4444);
    }
    if (kind.warnsWhenHigh && progress.isWarning) {
      return const Color(0xffff9800);
    }
    if (!kind.warnsWhenHigh && progress.isSuccess) {
      return const Color(0xff10b981);
    }
    return AppColors.white;
  }
}

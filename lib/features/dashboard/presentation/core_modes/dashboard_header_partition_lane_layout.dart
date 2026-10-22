import 'package:flutter/material.dart';
import '../dashboard_budget_header_presentation.dart';
import 'dashboard_partition_lane_geometry.dart';

/// Budget's physical profile owns both modes' lane geometry.
final class DashboardHeaderPartitionLaneLayout extends StatelessWidget {
  const DashboardHeaderPartitionLaneLayout({
    super.key,
    required this.child,
    required this.labels,
    this.expansionProgress = 1,
  });
  final Widget child;
  final Widget labels;
  final double expansionProgress;
  @override
  Widget build(BuildContext context) {
    final profile = DashboardBudgetHeaderPresentationScope.profileOf(context);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = profile.partitionThickness;
          final reveal = DashboardPartitionLaneGeometry.headerRevealFor(
            availableHeight:
                constraints.maxHeight -
                DashboardPartitionLaneGeometry.headerDetailTop -
                profile.partitionBottomInset,
            thickness: height,
            expansionProgress: expansionProgress,
          );
          return Stack(
            children: [
              Positioned(
                left: DashboardPartitionLaneGeometry.headerHorizontalInset,
                right: DashboardPartitionLaneGeometry.headerHorizontalInset,
                bottom: profile.partitionBottomInset,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: reveal,
                    child: Opacity(
                      opacity: reveal,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          labels,
                          const SizedBox(height: 4),
                          SizedBox(
                            key: const ValueKey(
                              'balance-header-income-expense-partition',
                            ),
                            width: double.infinity,
                            height: height,
                            child: child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

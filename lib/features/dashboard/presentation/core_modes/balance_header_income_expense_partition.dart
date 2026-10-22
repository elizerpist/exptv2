import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import 'dashboard_partition_lane_geometry.dart';
import 'dashboard_header_partition_lane_layout.dart';
import 'balance_header_partition_labels.dart';

/// Header-local, two-way Balance comparison. Its inputs are already-published
/// scope totals; it has no history, query, or transaction dependency.
final class BalanceHeaderIncomeExpensePartition extends StatelessWidget {
  const BalanceHeaderIncomeExpensePartition({
    super.key,
    required this.incomeMinor,
    required this.expenseMinor,
    this.heightPercent = 0,
    this.expansionProgress = 1,
    this.foreground = Colors.white,
    this.plotTop = 0,
    this.plotHeight = 0,
    this.valueTop = 0,
    this.verticalPosition = 0,
  });

  final double expansionProgress;
  final Color foreground;
  final int incomeMinor;
  final int expenseMinor;
  final double heightPercent;
  final double plotTop;
  final double plotHeight;
  final double valueTop;
  final double verticalPosition;

  /// Delegates to the single Balance partition geometry owner so the simple
  /// and glass renderers cannot drift apart as their shared sliders move.
  static double topFor({
    required double plotTop,
    required double plotHeight,
    required double valueTop,
    required double height,
    required double verticalPosition,
  }) => DashboardPartitionLaneGeometry.balanceHeaderTopFor(
    plotTop: plotTop,
    plotHeight: plotHeight,
    valueTop: valueTop,
    height: height,
    verticalPosition: verticalPosition,
  );

  @override
  Widget build(BuildContext context) {
    final total = math.max(0, incomeMinor) + math.max(0, expenseMinor);
    final incomeRatio = total == 0 ? 0.0 : math.max(0, incomeMinor) / total;
    return DashboardHeaderPartitionLaneLayout(
      labels: BalanceHeaderPartitionLabels(
        incomeRatio: incomeRatio,
        hasActivity: total > 0,
        foreground: foreground,
      ),
      expansionProgress: expansionProgress,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          DashboardPartitionLaneGeometry.cornerRadius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              key: const ValueKey('balance-header-income-expense-empty-track'),
              decoration: BoxDecoration(
                color: total > 0
                    ? const Color(0xffdc4e75)
                    : FluviVisualTokens.partitionEmptyTrack,
              ),
            ),
            if (incomeRatio > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: incomeRatio,
                child: const DecoratedBox(
                  key: ValueKey('balance-header-income-expense-income'),
                  decoration: BoxDecoration(color: Color(0xff1f9f70)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

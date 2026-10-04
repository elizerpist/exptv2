import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import 'dashboard_partition_lane_geometry.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';

/// Header-local, two-way Balance comparison. Its inputs are already-published
/// scope totals; it has no history, query, or transaction dependency.
final class BalanceHeaderIncomeExpensePartition extends StatelessWidget {
  const BalanceHeaderIncomeExpensePartition({
    super.key,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.heightPercent,
    required this.plotTop,
    required this.plotHeight,
    required this.valueTop,
    required this.verticalPosition,
  });

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
    final incomeBasisPoints = total == 0
        ? 5000
        : (math.max(0, incomeMinor) * 10000 / total).round();
    final expenseBasisPoints = 10000 - incomeBasisPoints;
    final height = DashboardPartitionLaneGeometry.balanceHeaderThicknessFor(
      heightPercent,
    );
    return Positioned(
      key: const ValueKey<String>('balance-header-income-expense-partition'),
      left: DashboardHeaderTrendChartStyle.plotLeft,
      right: DashboardHeaderTrendChartStyle.plotLeft,
      top: topFor(
        plotTop: plotTop,
        plotHeight: plotHeight,
        valueTop: valueTop,
        height: height,
        verticalPosition: verticalPosition,
      ),
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          DashboardPartitionLaneGeometry.cornerRadius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              key: ValueKey<String>(
                'balance-header-income-expense-empty-track',
              ),
              decoration: BoxDecoration(
                color: FluviVisualTokens.partitionEmptyTrack,
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: incomeBasisPoints / 10000,
              child: const DecoratedBox(
                key: ValueKey<String>(
                  'balance-header-income-expense-softened-fill',
                ),
                decoration: BoxDecoration(
                  color: FluviVisualTokens.balancePartitionSoftenedDark,
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: math.max(1, incomeBasisPoints),
                  child: const SizedBox.expand(
                    key: ValueKey<String>(
                      'balance-header-income-expense-income',
                    ),
                  ),
                ),
                Expanded(
                  flex: math.max(1, expenseBasisPoints),
                  child: const SizedBox.expand(
                    key: ValueKey<String>(
                      'balance-header-income-expense-expense',
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BalanceHeaderPartitionLabel(
                        label: '${(incomeBasisPoints / 100).round()}%',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _BalanceHeaderPartitionLabel(
                        label: '${(expenseBasisPoints / 100).round()}%',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BalanceHeaderPartitionLabel extends StatelessWidget {
  const _BalanceHeaderPartitionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

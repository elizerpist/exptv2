import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_partition_lane_geometry.dart';

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
  });

  final int incomeMinor;
  final int expenseMinor;
  final double heightPercent;
  final double plotTop;
  final double plotHeight;

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
      left: 16,
      right: 16,
      top: plotTop + (plotHeight - height) / 2,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          DashboardPartitionLaneGeometry.cornerRadius,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: math.max(1, incomeBasisPoints),
              child: _BalanceHeaderPartitionSide(
                key: const ValueKey<String>(
                  'balance-header-income-expense-income',
                ),
                color: const Color(0xff24ad73),
                label: '${(incomeBasisPoints / 100).round()}%',
                alignment: Alignment.centerLeft,
              ),
            ),
            Expanded(
              flex: math.max(1, expenseBasisPoints),
              child: _BalanceHeaderPartitionSide(
                key: const ValueKey<String>(
                  'balance-header-income-expense-expense',
                ),
                color: const Color(0xffe05672),
                label: '${(expenseBasisPoints / 100).round()}%',
                alignment: Alignment.centerRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BalanceHeaderPartitionSide extends StatelessWidget {
  const _BalanceHeaderPartitionSide({
    super.key,
    required this.color,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[color.withValues(alpha: .95), color],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(
        alignment: alignment,
        child: FittedBox(
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
        ),
      ),
    ),
  );
}

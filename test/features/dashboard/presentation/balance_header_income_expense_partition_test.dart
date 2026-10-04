import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_income_expense_partition.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_partition_lane_geometry.dart';

void main() {
  testWidgets(
    'BALANCE-HEADER-PARTITION: resident income and expense totals form one red-green Budget-shaped lane with in-lane percentages',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 140,
              child: Stack(
                children: <Widget>[
                  BalanceHeaderIncomeExpensePartition(
                    incomeMinor: 700000,
                    expenseMinor: 300000,
                    heightPercent: 50,
                    plotTop: 48,
                    plotHeight: 60,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final lane = find.byKey(
        const ValueKey<String>('balance-header-income-expense-partition'),
      );
      final income = find.byKey(
        const ValueKey<String>('balance-header-income-expense-income'),
      );
      final expense = find.byKey(
        const ValueKey<String>('balance-header-income-expense-expense'),
      );
      expect(lane, findsOneWidget);
      expect(income, findsOneWidget);
      expect(expense, findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(
        tester.getSize(lane).height,
        DashboardPartitionLaneGeometry.balanceHeaderThicknessFor(50),
      );
      expect(
        tester.getSize(income).width,
        greaterThan(tester.getSize(expense).width),
      );
    },
  );
}

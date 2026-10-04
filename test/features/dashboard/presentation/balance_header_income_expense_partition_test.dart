import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_income_expense_partition.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_partition_lane_geometry.dart';

void main() {
  testWidgets(
    'BALANCE-HEADER-PARTITION: resident income and expense totals form one neutral Budget-track lane with a softened-dark income fill',
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
                    valueTop: 16,
                    verticalPosition: 0,
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
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-income-expense-empty-track'),
        ),
        findsOneWidget,
        reason:
            'The entire lane must begin from the same neutral empty material '
            'as the Budget allocation partition.',
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-income-expense-softened-fill'),
        ),
        findsOneWidget,
        reason:
            'Income is one softened-dark overlay, not the old green/red pair.',
      );
      expect(
        tester
            .widget<DecoratedBox>(
              find.byKey(
                const ValueKey<String>(
                  'balance-header-income-expense-empty-track',
                ),
              ),
            )
            .decoration,
        const BoxDecoration(color: FluviVisualTokens.partitionEmptyTrack),
      );
      expect(
        tester
            .widget<DecoratedBox>(
              find.byKey(
                const ValueKey<String>(
                  'balance-header-income-expense-softened-fill',
                ),
              ),
            )
            .decoration,
        const BoxDecoration(
          color: FluviVisualTokens.balancePartitionSoftenedDark,
        ),
      );
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
      expect(
        tester.getRect(lane).bottom,
        108,
        reason:
            'At vertical position 0 the simple bar must share the exact '
            'expanded-header lower baseline used by the Budget partition and '
            'the material Balance bar.',
      );
    },
  );
}

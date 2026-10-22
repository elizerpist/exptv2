import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_income_expense_partition.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_bar.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_configuration.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_budget_header_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final percent in [0.0, 100.0]) {
      for (final glass in [false, true]) {
        testWidgets(
          'Budget and Balance physical lane match width=$width thickness=$percent glass=$glass',
          (tester) async {
            final controller = DashboardBudgetHeaderPresentationController()
              ..setPartitionHeightPercent(percent);
            addTearDown(controller.dispose);
            final profile = DashboardBudgetHeaderPresentationProfile(
              controller.value,
            );
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: DashboardBudgetHeaderPresentationScope(
                    controller: controller,
                    child: Column(
                      children: [
                        SizedBox(
                          width: width,
                          height: 140,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: profile.partitionBottomInset,
                                child: BudgetHeaderAllocationDetail(
                                  partition:
                                      const DashboardBudgetPartitionPresentation.unavailable(
                                        direction: LedgerDirection.expense,
                                      ),
                                  thickness: profile.partitionThickness,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: width,
                          height: 140,
                          child: Stack(
                            children: [
                              if (glass)
                                const BalanceHeaderGlassBar(
                                  incomeMinor: 700,
                                  expenseMinor: 300,
                                  configuration:
                                      BalanceHeaderGlassConfiguration(
                                        renderer:
                                            BalanceHeaderGlassRenderer.baseline,
                                      ),
                                )
                              else
                                const BalanceHeaderIncomeExpensePartition(
                                  incomeMinor: 700,
                                  expenseMinor: 300,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            final budget = tester.getRect(
              find.byKey(const ValueKey('budget-header-allocation-partition')),
            );
            final balance = tester.getRect(
              find.byKey(
                const ValueKey('balance-header-income-expense-partition'),
              ),
            );
            expect(balance.left, budget.left);
            expect(balance.right, budget.right);
            expect(balance.height, budget.height);
            expect(balance.bottom - 140, budget.bottom);
            expect(balance.left, 16);
            expect(find.text('Bevétel 70%'), findsOneWidget);
            expect(find.text('Kiadás 30%'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final values in [
    (700, 300, .7),
    (300, 700, .3),
    (100, 100, .5),
    (100, 0, 1.0),
    (0, 100, 0.0),
    (0, 0, 0.0),
  ]) {
    test('dual bar ratio ${values.$1}/${values.$2}', () {
      expect(
        BalanceHeaderGlassBar.incomeRatioFor(
          incomeMinor: values.$1,
          expenseMinor: values.$2,
        ),
        values.$3,
      );
    });
  }
  testWidgets('zero totals show neutral track and no income material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          height: 140,
          child: Stack(
            children: [
              BalanceHeaderGlassBar(
                incomeMinor: 0,
                expenseMinor: 0,
                configuration: BalanceHeaderGlassConfiguration(),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('balance-header-income-expense-empty-track')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('balance-header-glass-physical-body')),
      findsNothing,
    );
    expect(find.text('Bevétel 0%'), findsOneWidget);
    expect(find.text('Kiadás 0%'), findsOneWidget);
  });
}

import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_test_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  testWidgets('mounts only the selected mode-family host', (tester) async {
    final store = createBalanceProductionStore();
    addTearDown(store.dispose);
    await store.start();
    final dashboardMode = ValueNotifier(SpendeeDashboardMode.budget);
    addTearDown(dashboardMode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<SpendeeDashboardMode>(
            valueListenable: dashboardMode,
            builder: (context, mode, _) => SpendeeTestDashboard(
              store: store,
              expenseTheme: ExpenseTheme.fromSettings(
                AppThemeSettings.defaults(),
              ),
              dashboardMode: mode,
              onPickSummaryMonth: () {},
              onEditTransaction: (_) {},
              onDeleteTransactionRequested: (_) async => true,
              onVendorSheetRequested: () {},
              logBottomPadding: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('spendee-mode-host-budget')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-mode-host-balance')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('spendee-mode-host-mind')), findsNothing);

    dashboardMode.value = SpendeeDashboardMode.balance;
    await tester.pump();

    expect(
      find.byKey(const ValueKey('spendee-mode-host-balance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-mode-host-budget')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('spendee-mode-host-mind')), findsNothing);
  });

  testWidgets(
    'Balance host owns only Balance variants and is disposed on family switch',
    (tester) async {
      final store = createBalanceProductionStore();
      addTearDown(store.dispose);
      await store.start();
      final dashboardMode = ValueNotifier(SpendeeDashboardMode.balance);
      addTearDown(dashboardMode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<SpendeeDashboardMode>(
              valueListenable: dashboardMode,
              builder: (context, mode, _) => SpendeeTestDashboard(
                store: store,
                expenseTheme: ExpenseTheme.fromSettings(
                  AppThemeSettings.defaults(),
                ),
                dashboardMode: mode,
                onPickSummaryMonth: () {},
                onEditTransaction: (_) {},
                onDeleteTransactionRequested: (_) async => true,
                onVendorSheetRequested: () {},
                logBottomPadding: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final balanceHost = find.byType(SpendeeBalanceModeHost);
      expect(balanceHost, findsOneWidget);
      final balanceHostState = tester.state<State<StatefulWidget>>(balanceHost);
      expect(balanceHostState.mounted, isTrue);

      dashboardMode.value = SpendeeDashboardMode.budget;
      await tester.pump();

      expect(find.byType(SpendeeBalanceModeHost), findsNothing);
      expect(balanceHostState.mounted, isFalse);

      dashboardMode.value = SpendeeDashboardMode.balanceV2;
      await tester.pump();
      expect(find.byType(SpendeeBalanceModeHost), findsOneWidget);

      dashboardMode.value = SpendeeDashboardMode.budgetV2;
      await tester.pump();
      expect(find.byType(SpendeeBalanceModeHost), findsNothing);
      expect(
        find.byKey(const ValueKey('spendee-mode-host-budget')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Budget variants replace their local host runtime but preserve store filters',
    (tester) async {
      final store = createBalanceProductionStore();
      addTearDown(store.dispose);
      await store.start();
      final dashboardMode = ValueNotifier(SpendeeDashboardMode.budget);
      addTearDown(dashboardMode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<SpendeeDashboardMode>(
              valueListenable: dashboardMode,
              builder: (context, mode, _) => SpendeeTestDashboard(
                store: store,
                expenseTheme: ExpenseTheme.fromSettings(
                  AppThemeSettings.defaults(),
                ),
                dashboardMode: mode,
                onPickSummaryMonth: () {},
                onEditTransaction: (_) {},
                onDeleteTransactionRequested: (_) async => true,
                onVendorSheetRequested: () {},
                logBottomPadding: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final legacyBudgetHost = find.byType(SpendeeBudgetModeHost);
      expect(legacyBudgetHost, findsOneWidget);
      final legacyBudgetState = tester.state<State<StatefulWidget>>(
        legacyBudgetHost,
      );
      expect(legacyBudgetState.mounted, isTrue);

      final category = store.categoriesById.values.first;
      store.setCategoryFilter(category);
      expect(store.activeCategoryIds, <int>{category.transactionCategoryID});

      dashboardMode.value = SpendeeDashboardMode.budgetV2;
      await tester.pump();

      expect(find.byType(SpendeeBudgetModeHost), findsOneWidget);
      expect(legacyBudgetState.mounted, isFalse);
      expect(store.activeCategoryIds, <int>{category.transactionCategoryID});
      final budgetV2State = tester.state<State<StatefulWidget>>(
        find.byType(SpendeeBudgetModeHost),
      );
      expect(budgetV2State.mounted, isTrue);

      dashboardMode.value = SpendeeDashboardMode.balance;
      await tester.pump();

      expect(find.byType(SpendeeBudgetModeHost), findsNothing);
      expect(budgetV2State.mounted, isFalse);
      expect(store.activeCategoryIds, <int>{category.transactionCategoryID});
    },
  );
}

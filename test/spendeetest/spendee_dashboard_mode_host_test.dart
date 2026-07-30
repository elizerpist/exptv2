import 'package:exptv2/core/debug/debug_console.dart';
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

  testWidgets(
    'disposed Budget carousel motion cannot publish into the replacement host',
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

      final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      final headerGesture = await tester.startGesture(tester.getCenter(handle));
      await headerGesture.moveBy(const Offset(0, 134));
      await tester.pump();
      await headerGesture.up();
      await tester.pumpAndSettle();

      final oldHost = find.byType(SpendeeBudgetModeHost);
      final oldHostState = tester.state<State<StatefulWidget>>(oldHost);
      final carousel = find.byKey(
        const ValueKey('spendee-test-context-carousel-gesture'),
      );
      final carouselGesture = await tester.startGesture(
        tester.getCenter(carousel),
      );
      await carouselGesture.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await carouselGesture.up();
      await tester.pump();

      dashboardMode.value = SpendeeDashboardMode.budgetV2;
      await tester.pump();
      expect(oldHostState.mounted, isFalse);
      expect(find.byType(SpendeeBudgetModeHost), findsOneWidget);

      final replacementFilter = store.categoriesById.values.last;
      store.setCategoryFilter(replacementFilter);
      expect(store.activeCategoryIds, <int>{
        replacementFilter.transactionCategoryID,
      });

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(oldHostState.mounted, isFalse);
      expect(
        store.activeCategoryIds,
        <int>{replacementFilter.transactionCategoryID},
        reason:
            'An old release/filter continuation must not resolve the new '
            'Budget host runtime or overwrite its shared-store selection.',
      );
    },
  );

  testWidgets(
    'same Budget host invalidates carousel motion before replacing its store',
    (tester) async {
      final oldStore = createBalanceProductionStore();
      final replacementStore = createBalanceProductionStore();
      addTearDown(oldStore.dispose);
      addTearDown(replacementStore.dispose);
      await oldStore.start();
      await replacementStore.start();
      final activeStore = ValueNotifier(oldStore);
      addTearDown(activeStore.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: activeStore,
              builder: (context, store, _) => SpendeeTestDashboard(
                key: const ValueKey('same-budget-dashboard'),
                store: store,
                expenseTheme: ExpenseTheme.fromSettings(
                  AppThemeSettings.defaults(),
                ),
                dashboardMode: SpendeeDashboardMode.budget,
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

      final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      final headerGesture = await tester.startGesture(tester.getCenter(handle));
      await headerGesture.moveBy(const Offset(0, 134));
      await tester.pump();
      await headerGesture.up();
      await tester.pumpAndSettle();

      final host = find.byType(SpendeeBudgetModeHost);
      final hostState = tester.state<State<StatefulWidget>>(host);
      DebugConsole.clear();
      final carousel = find.byKey(
        const ValueKey('spendee-test-context-carousel-gesture'),
      );
      final carouselGesture = await tester.startGesture(
        tester.getCenter(carousel),
      );
      await carouselGesture.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await carouselGesture.up();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump();

      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (line) =>
                line.contains('[Perf] SpendeeTest carousel_filter_schedule') &&
                line.contains('category-2-'),
          ),
        ),
        reason:
            'The old-store filter timer must be pending when dependencies '
            'are replaced.',
      );

      activeStore.value = replacementStore;
      await tester.pump();

      expect(find.byType(SpendeeBudgetModeHost), findsOneWidget);
      expect(
        tester.state<State<StatefulWidget>>(find.byType(SpendeeBudgetModeHost)),
        same(hostState),
        reason: 'This exercises dependency replacement on the same host.',
      );
      expect(hostState.mounted, isTrue);

      final replacementFilter = replacementStore.categoriesById.values.first;
      replacementStore.setCategoryFilter(replacementFilter);
      expect(replacementStore.activeCategoryIds, <int>{
        replacementFilter.transactionCategoryID,
      });

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(oldStore.activeCategoryIds, isEmpty);
      expect(
        replacementStore.activeCategoryIds,
        <int>{replacementFilter.transactionCategoryID},
        reason:
            'The old carousel continuation must be invalidated before the '
            'replacement store becomes visible to the coordinator.',
      );
    },
  );

  testWidgets(
    'same BudgetV2 host invalidates rail motion before replacing its store',
    (tester) async {
      final oldStore = createBalanceProductionStore();
      final replacementStore = createBalanceProductionStore();
      addTearDown(oldStore.dispose);
      addTearDown(replacementStore.dispose);
      await oldStore.start();
      await replacementStore.start();
      final activeStore = ValueNotifier(oldStore);
      addTearDown(activeStore.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: activeStore,
              builder: (context, store, _) => SpendeeTestDashboard(
                key: const ValueKey('same-budget-v2-dashboard'),
                store: store,
                expenseTheme: ExpenseTheme.fromSettings(
                  AppThemeSettings.defaults(),
                ),
                dashboardMode: SpendeeDashboardMode.budgetV2,
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

      final host = find.byType(SpendeeBudgetModeHost);
      final hostState = tester.state<State<StatefulWidget>>(host);
      final rail = find.byKey(
        const ValueKey('spendee-budget-v2-avatar-ticker'),
      );
      DebugConsole.clear();
      await tester.timedDrag(
        rail,
        const Offset(-142, 0),
        const Duration(milliseconds: 260),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        DebugConsole.entries.where((line) => line.contains('[BudgetV2')),
        isEmpty,
        reason:
            'Standalone B2 must not expose an intermediate carousel trace '
            'while the replacement-store race is still pending.',
      );

      activeStore.value = replacementStore;
      await tester.pump();
      expect(
        tester.state<State<StatefulWidget>>(find.byType(SpendeeBudgetModeHost)),
        same(hostState),
      );
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-rail-runtime-0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-budget-v2-rail-runtime-1')),
        findsOneWidget,
      );

      final replacementFilter = replacementStore.categoriesById.values.first;
      replacementStore.setCategoryFilter(replacementFilter);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();

      expect(oldStore.activeCategoryIds, isEmpty);
      expect(replacementStore.activeCategoryIds, <int>{
        replacementFilter.transactionCategoryID,
      });
      expect(tester.takeException(), isNull);
    },
  );
}

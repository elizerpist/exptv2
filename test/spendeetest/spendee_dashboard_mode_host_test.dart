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
}

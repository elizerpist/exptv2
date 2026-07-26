import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Balance exposes a working debug panel button', (tester) async {
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendeeBalanceDashboard(
            input: _input(),
            brand: const SizedBox(width: 300, height: 60),
            onOpenDebugPanel: () => opened += 1,
            transactionLogBuilder: (_, _) => const SizedBox(),
          ),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('spendee-balance-debug-panel-button'),
    );
    expect(button, findsOneWidget);

    await tester.tap(button);
    expect(opened, 1);
  });
}

BalanceFrameInput _input() {
  const category = TransactionCategory(
    transactionCategoryID: 1,
    name: 'Food',
    type: 'expense',
    colorSlot: 1,
    iconSlot: 1,
    backgroundColor: '#FF4B78',
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
  return BalanceFrameInput(
    now: DateTime(2026, 7, 25),
    activeType: TransactionType.expense,
    summaryWindow: SummaryWindow.monthly,
    summaryReferenceDate: DateTime(2026, 7),
    transactions: const [
      TransactionRecord(
        id: 1,
        date: '2026-07-25',
        time: '11:42',
        latitude: null,
        longitude: null,
        address: null,
        merchant: 'Test merchant',
        amount: -100,
        userAssignedName: null,
        transactionCategoryID: 1,
      ),
    ],
    recurringGhosts: const [],
    categories: const [category],
    limits: const [],
  );
}

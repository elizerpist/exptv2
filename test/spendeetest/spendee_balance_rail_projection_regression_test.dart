import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  setUp(DebugConsole.clear);

  testWidgets(
    'a no-ghost monthly rail settle does not resolve the selected frame again after projection',
    (tester) async {
      final store = createBalanceProductionStore(
        transactions: <TransactionRecord>[
          balanceProductionRecord(1, categoryId: 1, date: '2026.04.17'),
          balanceProductionRecord(2, categoryId: 1, date: '2026.05.17'),
          balanceProductionRecord(3, categoryId: 1, date: '2026.06.17'),
          balanceProductionRecord(4, categoryId: 1, date: '2026.07.17'),
        ],
      );
      addTearDown(store.dispose);
      await store.start();
      store.commitStatsViewMutation(
        await store.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.monthly,
          year: 2026,
          month: 7,
        ),
      );
      await pumpBalanceProductionHost(tester, store: store, settle: false);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-summary-chevron')),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('spendee-balance-rail-ticking-viewport')),
        Offset(-SpendeeBalanceVisualSpec.timeRailSlotDistance * 2, 0),
      );
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      final completedFrameResolves = DebugConsole.entries.where(
        (entry) =>
            entry.contains('operation=balance-frame-resolve') &&
            entry.contains('phase=complete'),
      );
      expect(
        completedFrameResolves,
        hasLength(2),
        reason:
            'the initial monthly frame and the selected rail scope are the '
            'only two semantic frames when recurring projection returns no ghosts',
      );
      expect(
        DebugConsole.entries.where(
          (entry) =>
              entry.contains('operation=balance-rail-load') &&
              entry.contains('phase=complete'),
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

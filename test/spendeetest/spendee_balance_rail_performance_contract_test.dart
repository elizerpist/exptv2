import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  setUp(DebugConsole.clear);
  const recordCount = int.fromEnvironment(
    'BALANCE_RAIL_CONTRACT_RECORDS',
    defaultValue: 14000,
  );

  testWidgets(
    'V3-004 $recordCount-row rail drag coalesces previews into one settled load',
    (tester) async {
      final timing = Stopwatch()..start();
      final transactions = List.generate(recordCount, (index) {
        const months = <String>['04', '05', '06', '07'];
        return balanceProductionRecord(
          index + 1,
          categoryId: 1,
          merchant: 'T',
          date: '2026.${months[index % months.length]}.17',
        );
      });
      // ignore: avoid_print
      print(
        '[RailPerfDiag] fixture rows=$recordCount ms=${timing.elapsedMilliseconds}',
      );
      expect(transactions, hasLength(recordCount));
      final store = createBalanceProductionStore(transactions: transactions);
      await store.start();
      // ignore: avoid_print
      print(
        '[RailPerfDiag] test.store_started ms=${timing.elapsedMilliseconds}',
      );
      store.commitStatsViewMutation(
        await store.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.monthly,
          year: 2026,
          month: 7,
        ),
      );
      // ignore: avoid_print
      print(
        '[RailPerfDiag] test.monthly_committed ms=${timing.elapsedMilliseconds}',
      );
      await pumpBalanceProductionHost(tester, store: store, settle: false);
      // ignore: avoid_print
      print('[RailPerfDiag] test.host_pumped ms=${timing.elapsedMilliseconds}');
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-summary-chevron')),
      );
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print('[RailPerfDiag] test.rail_open ms=${timing.elapsedMilliseconds}');

      final viewport = find.byKey(
        const ValueKey('spendee-balance-rail-ticking-viewport'),
      );
      final rail = find.byKey(const ValueKey('spendee-balance-time-rail'));
      final collapseControl = find.byKey(
        const ValueKey('spendee-balance-collapse-control'),
      );
      expect(
        tester.getRect(collapseControl).top,
        greaterThanOrEqualTo(tester.getRect(rail).bottom),
      );
      await tester.drag(
        viewport,
        Offset(-SpendeeBalanceVisualSpec.timeRailSlotDistance * 2, 0),
      );
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print(
        '[RailPerfDiag] test.drag_settled ms=${timing.elapsedMilliseconds}',
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final railLoads = DebugConsole.entries.where(
        (entry) => entry.contains('operation=balance-rail-load'),
      );
      final completedLoads = railLoads.where(
        (entry) => entry.contains('phase=complete'),
      );
      expect(completedLoads, hasLength(1));
      final request = railLoads.singleWhere(
        (entry) => entry.contains('phase=request'),
      );
      expect(request, contains('superseded='));
      expect(request, isNot(contains('superseded=0')));
      expect(request, contains('duplicate_final_loads=0'));
      expect(request, contains('discarded_frame_resolves=0'));
      expect(request, contains('recurring_during_drag=0'));
      expect(request, contains('inactive_stats_during_drag=0'));
      final diagnosticEntries = DebugConsole.entries
          .where(
            (entry) =>
                entry.contains('[BalanceTrace]') &&
                (entry.contains('operation=balance-frame-resolve') ||
                    entry.contains('operation=balance-transaction-log-build') ||
                    entry.contains('operation=balance-rail-load')),
          )
          .toList(growable: false);
      // ignore: avoid_print
      print(
        '[RailPerfDiag] balance_trace_count=${diagnosticEntries.length} '
        'frame_resolves=${diagnosticEntries.where((entry) => entry.contains('operation=balance-frame-resolve') && entry.contains('phase=complete')).length} '
        'log_builds=${diagnosticEntries.where((entry) => entry.contains('operation=balance-transaction-log-build') && entry.contains('phase=complete')).length}',
      );
      for (final entry in diagnosticEntries) {
        // ignore: avoid_print
        print('[RailPerfDiag] $entry');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'V3 type return reuses the bounded transaction log for $recordCount rows',
    (tester) async {
      final transactions = List.generate(recordCount, (index) {
        // Mirrors the supplied device trace: a large expense history with a
        // small income side, rather than an artificial 50/50 data split.
        final income = index < 90;
        return balanceProductionRecord(
          index + 1,
          categoryId: 1,
          amount: (income ? 1000 + index : -1000 - index).toDouble(),
          merchant: income ? 'B' : 'K',
          date: '2026.07.${(17 - index % 3).toString().padLeft(2, '0')}',
          time: '10:${(index % 60).toString().padLeft(2, '0')}',
        );
      });
      final store = createBalanceProductionStore(transactions: transactions);
      addTearDown(store.dispose);
      await pumpBalanceProductionHost(tester, store: store, settle: false);
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-income-action')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-expense-action')),
      );
      await tester.pump();

      final typeSwitches = DebugConsole.entries
          .where(
            (entry) =>
                entry.contains('operation=balance-type-switch') &&
                entry.contains('phase=complete'),
          )
          .toList(growable: false);
      expect(typeSwitches, hasLength(2));
      expect(typeSwitches.last, contains('frame_cache=history'));
      expect(typeSwitches.last, contains('log_cache=reused'));
      expect(tester.takeException(), isNull);
    },
  );
}

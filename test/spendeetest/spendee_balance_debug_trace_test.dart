import 'dart:io';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_debug_trace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(DebugConsole.clear);

  test(
    'debug trace correlates duration and safe error kind without payload',
    () {
      final first = BalanceDebugTrace.begin('balance-frame-resolve');
      final second = BalanceDebugTrace.begin('balance-transaction-log-build');
      final railToggle = BalanceDebugTrace.begin('balance-rail-toggle');
      final switchTrace = BalanceDebugTrace.begin(
        'balance-type-switch',
        fields: const <String, Object?>{
          'from_type': 'expense',
          'to_type': 'income',
          'merchant': 'Lidl',
        },
      );
      final scrollTrace = BalanceDebugTrace.begin(
        'balance-log-scroll',
        fields: const <String, Object?>{'visible_rows': 96, 'build_bound': 21},
      );
      final boundedScrollTrace = BalanceDebugTrace.begin(
        'balance-log-scroll',
        fields: const <String, Object?>{
          'visible_rows': 8,
          'loaded_rows': 107,
          'build_bound': 21,
        },
      );

      BalanceDebugTrace.finish(
        first,
        error: StateError('merchant=Lidl amount=350000'),
      );
      BalanceDebugTrace.finish(second);
      BalanceDebugTrace.finish(railToggle);
      BalanceDebugTrace.mark(
        switchTrace,
        'cache',
        fields: const <String, Object?>{'frame_cache': 'history'},
      );
      BalanceDebugTrace.finish(switchTrace);
      BalanceDebugTrace.finish(scrollTrace);
      BalanceDebugTrace.finish(boundedScrollTrace);

      final trace = DebugConsole.allText;
      expect(trace, contains('operation=balance-frame-resolve'));
      expect(trace, contains('operation=balance-transaction-log-build'));
      expect(trace, contains('operation=balance-rail-toggle'));
      expect(trace, contains('correlation='));
      expect(trace, contains('duration_ms='));
      expect(trace, contains('error_kind=StateError'));
      expect(trace, contains('phase=request'));
      expect(trace, contains('phase=complete'));
      expect(trace, contains('operation=balance-type-switch'));
      expect(trace, contains('from_type=expense'));
      expect(trace, contains('to_type=income'));
      expect(trace, contains('operation=balance-log-scroll'));
      expect(trace, contains('visible_rows=96'));
      expect(trace, contains('build_bound=21'));
      expect(trace, contains('visible_rows=8'));
      expect(trace, contains('loaded_rows=107'));
      expect(trace, isNot(contains('Lidl')));
      expect(trace, isNot(contains('350000')));
    },
  );

  test('Balance entry closes its trace when host construction throws', () {
    final source = File(
      'lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart',
    ).readAsStringSync();
    final entryStart = source.indexOf('Widget _buildBalanceDashboard()');
    final entryEnd = source.indexOf('Widget _balanceDashboard(', entryStart);
    final entry = source.substring(entryStart, entryEnd);

    expect(entry, contains('catch (error)'));
    expect(entry, contains('BalanceDebugTrace.finish(trace, error: error)'));
    expect(entry, contains('rethrow'));
  });
}

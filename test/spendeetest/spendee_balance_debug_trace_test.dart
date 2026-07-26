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

      BalanceDebugTrace.finish(
        first,
        error: StateError('merchant=Lidl amount=350000'),
      );
      BalanceDebugTrace.finish(second);
      BalanceDebugTrace.finish(railToggle);

      final trace = DebugConsole.allText;
      expect(trace, contains('operation=balance-frame-resolve'));
      expect(trace, contains('operation=balance-transaction-log-build'));
      expect(trace, contains('operation=balance-rail-toggle'));
      expect(trace, contains('correlation='));
      expect(trace, contains('duration_ms='));
      expect(trace, contains('error_kind=StateError'));
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ALT-BOUNDARY: Havi 2 and Éves bind only the existing linked presentation', () {
    final adapter = File(
      'lib/features/dashboard/presentation/core_modes/'
      'balance_alternative_scope_presentation.dart',
    ).readAsStringSync();
    final renderer = File(
      'lib/features/dashboard/presentation/core_modes/'
      'balance_dashboard_core_surface.dart',
    ).readAsStringSync();

    expect(adapter, contains('DashboardBalanceLinkedPresentation linked'));
    expect(adapter, contains('BalanceAlternativeScopePresentation.fromLinked'));
    expect(adapter, isNot(contains('DashboardBalanceLinkedProjection.build')));
    expect(adapter, isNot(contains('DashboardLedgerEntry')));
    expect(renderer, contains('BalanceAlternativeScopePresentation.fromLinked(value)'));
    expect(renderer, isNot(contains('Repository')));
  });
}

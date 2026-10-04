import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionSources = <String>[
    'lib/app/shell/bnb03_bottom_navigation.dart',
    'lib/features/dashboard/presentation/core_modes/'
        'balance_header_income_expense_partition.dart',
    'lib/features/dashboard/presentation/core_modes/'
        'balance_alternative_extended_sheet_cards.dart',
    'lib/features/dashboard/presentation/dashboard_budget_header_presentation.dart',
  ];

  test(
    'ARC-01: Balance, Budget and FAB refinement remains presentation-only',
    () {
      for (final source in productionSources) {
        final contents = File(source).readAsStringSync();
        expect(
          contents,
          isNot(contains('Repository')),
          reason: '$source must consume published presentation data only.',
        );
        expect(
          contents,
          isNot(contains('QueryController')),
          reason: '$source must not construct a query owner.',
        );
      }
    },
  );

  test('ARC-01: FAB derives its direction visuals from existing owners', () {
    final fab = File(
      'lib/app/shell/bnb03_bottom_navigation.dart',
    ).readAsStringSync();
    final shell = File('lib/app/shell/fluvi_app_shell.dart').readAsStringSync();

    expect(fab, contains('FluviDirectionColorPaletteCatalog'));
    expect(fab, contains('TransactionDirection direction'));
    expect(shell, contains('animation: _controller.transactionDirection'));
    expect(shell, contains('tuning.globalAppearance.directionColorProfile'));
    expect(
      shell,
      contains(
        RegExp(
          r'transactionDirection:\s*_controller\.transactionDirection\.direction',
        ),
      ),
      reason:
          'The shell must only pass the already-owned direction to the FAB; '
          'it must not create a second direction controller.',
    );
  });
}

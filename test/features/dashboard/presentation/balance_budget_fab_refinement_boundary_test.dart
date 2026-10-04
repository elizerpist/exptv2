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

  test(
    'ARC-02: FAB choice and Balance partition geometry retain one owner',
    () {
      final appearance = File(
        'lib/core/design/fluvi_global_appearance.dart',
      ).readAsStringSync();
      final controller = File(
        'lib/features/dashboard/presentation/core_modes/'
        'dashboard_header_visual_engine.dart',
      ).readAsStringSync();
      final geometry = File(
        'lib/features/dashboard/presentation/core_modes/'
        'dashboard_partition_lane_geometry.dart',
      ).readAsStringSync();
      final simple = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_header_income_expense_partition.dart',
      ).readAsStringSync();
      final glass = File(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_header_glass_bar.dart',
      ).readAsStringSync();

      expect(appearance, contains('enum FluviFabIconPresentation'));
      expect(controller, contains('void setFabIconPresentation'));
      expect(controller, contains('_setGlobalAppearance('));
      expect(geometry, contains('static double balanceHeaderTopFor('));
      expect(
        simple,
        contains('DashboardPartitionLaneGeometry.balanceHeaderTopFor'),
      );
      expect(
        glass,
        contains('DashboardPartitionLaneGeometry.balanceHeaderTopFor'),
      );
      for (final source in <String>[simple, glass]) {
        expect(source, isNot(contains('Repository')));
        expect(source, isNot(contains('QueryController')));
      }
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Budget distribution stays RAM-only and independent from Query ownership',
    () {
      final source = _read(
        'lib/features/dashboard/application/dashboard_budget_category_distribution_controller.dart',
      );
      for (final forbidden in <String>[
        'FinancialLimitRepository',
        'CurrentQueryController',
        'QueryComposer',
        'MethodChannel',
        'EventChannel',
        'TransactionRepository',
        'DashboardLogBox',
        'sql',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
      expect(source, contains('PreparedBudgetLimitSnapshot'));
      expect(
        source,
        contains('DashboardBudgetCategoryDistributionBundleCache'),
      );
    },
  );

  test(
    'distribution card commands the existing rail and does not own selection or motion',
    () {
      final source = _read(
        'lib/features/dashboard/presentation/core_modes/budget_category_distribution_card.dart',
      );
      for (final forbidden in <String>[
        '.setTargetHandle(',
        'CenteredCarouselController',
        'ScrollController(',
        'Future.delayed',
        'CustomPainter',
        'fl_chart',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
      expect(source, contains('animateToTargetHandle'));
      expect(source, contains('ListView.builder'));
    },
  );

  test('production donut remains dynamic SVG plus mathematical hit testing', () {
    final source = _read(
      'lib/features/dashboard/presentation/core_modes/budget_category_distribution_svg.dart',
    );
    expect(source, contains("viewBox = '44 44 424 424'"));
    expect(source, contains('BudgetCategoryDistributionDonutHitTest'));
    expect(source, isNot(contains('CustomPainter')));
  });
}

String _read(String relativePath) =>
    File('${Directory.current.path}/$relativePath').readAsStringSync();

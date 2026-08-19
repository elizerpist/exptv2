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
        'fl_chart',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
      expect(source, contains('animateToTargetHandle'));
      expect(
        source,
        contains('BudgetDistributionPageSurface'),
        reason: 'the shared surface owns the local virtualized legend list',
      );
    },
  );

  test('production donut uses one Canvas scene with shared hit geometry', () {
    final card = _read(
      'lib/features/dashboard/presentation/core_modes/budget_category_distribution_card.dart',
    );
    final partnerCard = _read(
      'lib/features/dashboard/presentation/core_modes/budget_partner_distribution_card.dart',
    );
    final scene = _read(
      'lib/features/dashboard/presentation/core_modes/budget_clay_donut_scene.dart',
    );
    final legacySvg = _read(
      'lib/features/dashboard/presentation/core_modes/budget_category_distribution_svg.dart',
    );

    expect(card, contains('BudgetClayDonutView'));
    expect(partnerCard, contains('BudgetClayDonutView'));
    expect(card, isNot(contains('SvgPicture')));
    expect(partnerCard, isNot(contains('SvgPicture')));
    expect(scene, contains('CustomPainter'));
    expect(scene, contains("viewBox = '44 44 424 424'"));
    expect(scene, contains('resolveHit'));
    expect(scene, isNot(contains('TextPainter')));
    expect(legacySvg, contains('BudgetClayDonutGeometry.resolveHit'));
  });
}

String _read(String relativePath) =>
    File('${Directory.current.path}/$relativePath').readAsStringSync();

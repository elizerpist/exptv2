import 'dart:io';

import 'package:fluvi/core/design/dashboard_border_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BU-BORDER-RED-01: fresh Budget header and content are borderless', () {
    expect(DashboardBorderSettings.defaults.budgetHeader, isFalse);
    expect(DashboardBorderSettings.defaults.budgetContent, isFalse);
    final budgetSurface = _read(
      'lib/features/dashboard/presentation/core_modes/'
      'budget_dashboard_core_surface.dart',
    );
    expect(
      budgetSurface,
      contains('borderSurface: DashboardBorderSurface.budgetHeader'),
    );
  });

  test(
    'BWD-BOUNDARY: Balance appearance retains one state owner and write path',
    () {
      final settings = _read(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_presentation_settings.dart',
      );
      final tuner = _read(
        'lib/features/dashboard/presentation/core_modes/'
        'dashboard_header_visual_tuner.dart',
      );

      expect(
        RegExp(r'class\s+BalancePresentationSettings\b').allMatches(settings),
        hasLength(1),
      );
      expect(
        RegExp(r'class\s+BalancePresentationController\b').allMatches(settings),
        hasLength(1),
      );
      expect(
        settings,
        contains('void setBalanceCarouselWaveAnimationEnabled(bool next)'),
      );
      expect(
        settings,
        contains('void setBalanceContentCardColoredBorderEnabled(bool next)'),
      );
      expect(
        settings,
        contains('void setAlternativeMotherCardVisible(bool next)'),
      );
      expect(
        tuner,
        contains('controller.setBalanceCarouselWaveAnimationEnabled'),
      );
      expect(
        tuner,
        contains('controller.setBalanceContentCardColoredBorderEnabled'),
      );
      expect(tuner, contains('controller.setAlternativeMotherCardVisible'));
      expect(
        tuner,
        isNot(contains('BalancePresentationController(')),
        reason: 'The tuner forwards intent and never creates a second owner.',
      );
    },
  );

  test('BWD-BOUNDARY: content and mini cards share the one accent resolver', () {
    final surface = _read(
      'lib/features/dashboard/presentation/core_modes/'
      'balance_dashboard_core_surface.dart',
    );

    expect(
      RegExp(r'_BalanceCarouselReferenceAccent\.resolve\(').allMatches(surface),
      hasLength(2),
      reason:
          'The card painter and content border must share one color resolver.',
    );
    expect(surface, contains('_balanceCarouselCardForTopic('));
    expect(surface, contains('balanceContentCardColoredBorderEnabled'));
  });

  test(
    'BWD-BOUNDARY: the carousel owns one shared wave ticker and no card ticker',
    () {
      final surface = _read(
        'lib/features/dashboard/presentation/core_modes/'
        'balance_dashboard_core_surface.dart',
      );

      expect(
        RegExp(r'AnimationController\(').allMatches(surface),
        hasLength(1),
      );
      expect(surface, contains('final class _BalanceUpperCarouselState'));
      expect(
        surface,
        contains('_wavePhaseController.repeat(period: requestedPeriod)'),
      );
      expect(surface, contains('_wavePhaseController.stop()'));
      expect(surface, contains('final class _BalanceCarouselAmbientWave'));
    },
  );

  test(
    'BWD-BOUNDARY: category and partner retain the single ranked-layout owner',
    () {
      final ranked = _read(
        'lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart',
      );

      expect(
        RegExp(r'class\s+_RankedOverviewLayout\b').allMatches(ranked),
        hasLength(1),
      );
      expect(ranked, contains('rankedListExtraHeight'));
    },
  );
}

String _read(String relativePath) =>
    File('${Directory.current.path}/$relativePath').readAsStringSync();

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
      contains('borderSurface: DashboardBorderSurface.header'),
    );
  });

  test('Balance settings have one owner and no retired presentation APIs', () {
    final settings = _read(
      'lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart',
    );
    final tuner = _read(
      'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart',
    );
    expect(
      RegExp(r'class\s+BalancePresentationSettings\b').allMatches(settings),
      hasLength(1),
    );
    expect(
      RegExp(r'class\s+BalancePresentationController\b').allMatches(settings),
      hasLength(1),
    );
    for (final removed in <String>[
      'BalanceCarouselCardKind',
      'BalanceContentSurfaceStyle',
      'BalanceUnifiedBodyLayout',
      'BalanceHeaderChartTimeLabels',
      'BalanceLatestTransactionCardPresentation',
      'balanceCarousel',
      'balanceContentCardColoredBorderEnabled',
      'balanceContentCardBorderOpacity',
      'alternativeMotherCardVisible',
    ]) {
      expect(settings, isNot(contains(removed)));
      expect(tuner, isNot(contains(removed)));
    }
    expect(tuner, isNot(contains('BalancePresentationController(')));
    for (final retained in <String>[
      'setSumLayoutPresentation',
      'setYearLayoutPresentation',
      'setMonthLayoutPresentation',
      'setDayLayoutPresentation',
      'setDayFocusedPresentation',
      'setDayRatioPresentation',
      'setDayRatioViewPresentation',
      'setDayPerformanceVisualPresentation',
      'setUsesChildCards',
    ]) {
      expect(settings, contains(retained));
      expect(tuner, contains('controller.$retained'));
    }
  });

  test('Balance renderer has no legacy carousel or ambient animation owner', () {
    final surface = _read(
      'lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart',
    );
    for (final retired in <String>[
      '_BalanceUpperCarousel',
      '_BalancePrimaryCardHost',
      '_BalanceCarouselAmbientWave',
      'AnimationController(',
      'showsTetris',
      'isHeaderLinked',
    ]) {
      expect(surface, isNot(contains(retired)));
    }
    expect(surface, contains('showTimeLabels: false'));
    expect(surface, contains('_BalanceAlternativeScopeScaffold'));
  });
}

String _read(String relativePath) =>
    File('${Directory.current.path}/$relativePath').readAsStringSync();

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WR-28 bounded controls have one owner shared by Mind and Month', () {
    final chart = File(
      'lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart',
    ).readAsStringSync();
    final mind = File(
      'lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart',
    ).readAsStringSync();
    final core = File(
      'lib/core/design/fluvi_bounded_curve.dart',
    ).readAsStringSync();
    expect(chart, contains('fluviBoundedMonotoneSegments'));
    expect(mind, contains('fluviBoundedMonotoneSegments'));
    expect(mind, isNot(contains('final slopes = List<double>.filled')));
    expect(core, isNot(contains('features/')));
    expect(core, isNot(contains('package:flutter/material.dart')));
    for (final source in [chart, core]) {
      for (final forbidden in [
        'Repository',
        'dart:io',
        'dart:ffi',
        'package:http',
        'BackdropFilter',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
    }
  });
  test(
    'MTC-02 RED: the four-choice monthly chart catalog is owned by Balance presentation settings',
    () async {
      final settingsSource = await File(
        'lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart',
      ).readAsString();
      final cardSource = await File(
        'lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart',
      ).readAsString();

      expect(
        settingsSource,
        contains('enum BalanceMonthlySpendingChartPresentation'),
      );
      expect(
        settingsSource,
        isNot(contains('enum BalanceHeaderLineChartPresentation')),
        reason:
            'The original Header trend must not retain a dead terrain mode.',
      );
      for (final name in <String>[
        'current',
        'topographic',
        'reactiveSvg',
        'shaderAtmosphere',
      ]) {
        expect(settingsSource, contains(name));
      }
      expect(
        cardSource,
        contains('FluviTopographicWaveChart'),
        reason:
            'The monthly Költés child card—not the Header—must own the only '
            'production construction site for the terrain renderer.',
      );
    },
  );

  test(
    'BMR-06 boundary: the terrain uses one cached material painter with a vertex-lit fallback and registered FragmentProgram rather than contour widgets',
    () async {
      final chartSource = await File(
        'lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart',
      ).readAsString();
      final pubspec = await File('pubspec.yaml').readAsString();

      expect(chartSource, contains('FragmentProgram.fromAsset'));
      expect(chartSource, contains('drawVertices'));
      expect(chartSource, contains('surfaceFootSamples'));
      expect(pubspec, contains('shaders/fluvi_wave_surface.frag'));
    },
  );
}

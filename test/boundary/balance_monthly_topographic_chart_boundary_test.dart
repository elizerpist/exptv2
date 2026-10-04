import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

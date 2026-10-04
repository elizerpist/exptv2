import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'MTC-02 boundary: Android persists the four-choice monthly spending renderer independently from Header graph selection',
    () {
      final source = File(
        '${Directory.current.path}/android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt',
      ).readAsStringSync();

      expect(
        source,
        contains(
          'preferences.getInt("balanceMonthlySpendingChartPresentation", 0)',
        ),
      );
      expect(
        source,
        contains('require(balanceMonthlySpendingChartPresentation in 0..3)'),
      );
      expect(
        source,
        contains(
          '.putInt("balanceMonthlySpendingChartPresentation", balanceMonthlySpendingChartPresentation)',
        ),
      );
      expect(
        source,
        contains('require(balanceHeaderGraphPresentation in 0..2)'),
        reason: 'The established Header line/partition selector is unrelated.',
      );
    },
  );

  test(
    'MTC-06 boundary: the monthly terrain is presentation-only and does not acquire ledger/query or backdrop-filter ownership',
    () {
      final source = File(
        '${Directory.current.path}/lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart',
      ).readAsStringSync();

      expect(source, contains('final class FluviTopographicWaveChart'));
      expect(source, contains('MaskFilter.blur'));
      expect(source, isNot(contains('BackdropFilter')));
      expect(source, isNot(contains('Repository')));
      expect(source, isNot(contains('Query')));
      expect(source, isNot(contains('DashboardLedgerEntry')));
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TOPO-01 native boundary: Android persists the renderer choice independently from the three-way Header graph kind',
    () {
      final source = File(
        '${Directory.current.path}/android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt',
      ).readAsStringSync();

      expect(
        source,
        contains('preferences.getInt("balanceHeaderLineChartPresentation", 0)'),
        reason:
            'Fresh installs must keep the current flat line renderer until a '
            'user explicitly selects the topographic alternative.',
      );
      expect(
        source,
        contains('require(balanceHeaderLineChartPresentation in 0..1)'),
      );
      expect(
        source,
        contains(
          '.putInt("balanceHeaderLineChartPresentation", balanceHeaderLineChartPresentation)',
        ),
      );
      expect(
        source,
        contains('require(balanceHeaderGraphPresentation in 0..2)'),
        reason:
            'The existing graph-kind setting retains all three line/partition '
            'choices and is never repurposed for the new renderer selection.',
      );
    },
  );

  test(
    'TOPO-05 boundary: the terrain renderer is paint-only and has no financial or backdrop-filter path',
    () {
      final source = File(
        '${Directory.current.path}/lib/features/dashboard/presentation/core_modes/balance_header_topographic_chart.dart',
      ).readAsStringSync();

      expect(source, contains('final class BalanceHeaderTopographicPainter'));
      expect(source, contains('MaskFilter.blur'));
      expect(source, isNot(contains('BackdropFilter')));
      expect(source, isNot(contains('Repository')));
      expect(source, isNot(contains('Query')));
      expect(source, isNot(contains('DashboardLedgerEntry')));
    },
  );
}

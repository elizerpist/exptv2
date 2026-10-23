import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_day_cards.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('original vertical impact card baseline for all marker colors', (
    tester,
  ) async {
    for (final percent in [-12.0, 0.0, 12.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('legacy-impact'),
                child: SizedBox(
                  width: 210,
                  height: 500,
                  child: BalanceAlternativeDailyImpactCard(
                    presentation: DashboardBalanceDailyImpactPresentation(
                      available: true,
                      previousSevenExpenseMinor: 1000000,
                      currentSevenExpenseMinor: 1000000,
                      valuePercent: percent,
                      scaleExtentPercent: 20,
                      markerFraction: .5 + percent / 40,
                      overflow: false,
                      todayNetMinor: 20000,
                      referenceAverageNetMinor: 10000,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('legacy-impact')),
        matchesGoldenFile(
          '../../../goldens/balance_impact_vertical_${percent.toInt()}.png',
        ),
      );
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_visuals.dart';

final momentum = DashboardBalanceDailyMomentumPresentation(
  available: true,
  selected: const DashboardBalanceDailyMomentumPoint(
    epochDay: 1,
    currentIncomeMinor: 52000000,
    referenceIncomeMinor: 45000000,
    currentExpenseMinor: 35000000,
    referenceExpenseMinor: 39000000,
    isCurrentHalf: true,
    incomeAxis: .4,
    expenseAxis: -.3,
    magnitude: .5,
  ),
  rhythm: const [],
);
const impact = DashboardBalanceDailyImpactPresentation(
  available: true,
  previousSevenExpenseMinor: 28900000,
  currentSevenExpenseMinor: 27000000,
  valuePercent: 6.4,
  scaleExtentPercent: 50,
  markerFraction: .564,
  overflow: false,
  todayNetMinor: 1240000,
  referenceAverageNetMinor: 0,
);
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(410, 380),
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Inter'),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('capture'),
            child: SizedBox.fromSize(
              size: size,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  testWidgets(
    'three focused lower views and compact impact reference goldens',
    (tester) async {
      final views = <String, Widget>{
        'compass': BalanceDayFinancialCompass(momentum: momentum),
        'comparison': BalanceDayFinancialComparison(momentum: momentum),
        'impact': const BalanceDayImpactFocus(impact: impact),
        'compact': const BalanceDayCompactImpact(impact: impact),
      };
      for (final entry in views.entries) {
        await pump(
          tester,
          entry.value,
          size: entry.key == 'compact'
              ? const Size(410, 115)
              : const Size(410, 380),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            '../../../goldens/balance_day_focused_${entry.key}.png',
          ),
        );
      }
    },
  );
  testWidgets('responsive normal and narrow lower bounds do not overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(320, 190),
      const Size(320, 300),
      const Size(410, 440),
    ]) {
      for (final child in [
        BalanceDayFinancialCompass(momentum: momentum),
        BalanceDayFinancialComparison(momentum: momentum),
        const BalanceDayImpactFocus(impact: impact),
      ]) {
        await pump(tester, child, size: size);
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('compass and comparison physically grow with more space', (
    tester,
  ) async {
    final sizes = <String, List<double>>{};
    for (final height in [190.0, 330.0]) {
      for (final item in <String, Widget>{
        'balance-day-compass-circle': BalanceDayFinancialCompass(
          momentum: momentum,
        ),
        'balance-day-comparison-panels': BalanceDayFinancialComparison(
          momentum: momentum,
        ),
      }.entries) {
        await pump(tester, item.value, size: Size(410, height));
        expect(tester.takeException(), isNull);
        sizes
            .putIfAbsent(item.key, () => [])
            .add(tester.getSize(find.byKey(ValueKey(item.key))).height);
      }
    }
    for (final heights in sizes.values) {
      expect(heights.last, greaterThan(heights.first));
    }
    await pump(
      tester,
      const BalanceDayCompactImpact(impact: impact),
      size: const Size(410, 80),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'unavailable inputs retain neutral labels and never fake percentages',
    (tester) async {
      await pump(
        tester,
        BalanceDayFinancialCompass(
          momentum: DashboardBalanceDailyMomentumPresentation.unavailable(
            selectedEpochDay: 1,
          ),
        ),
      );
      expect(find.text('Még nincs összehasonlítható előzmény'), findsOneWidget);
      await pump(
        tester,
        BalanceDayImpactFocus(
          impact: DashboardBalanceDailyImpactPresentation.unavailable(
            todayNetMinor: 0,
            referenceAverageNetMinor: 0,
          ),
        ),
      );
      expect(
        find.text('Nincs elegendő összehasonlítható adat'),
        findsOneWidget,
      );
      expect(find.text('—'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

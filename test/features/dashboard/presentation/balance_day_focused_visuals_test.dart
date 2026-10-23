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
  testWidgets('V4 periods share actual capsule geometry', (tester) async {
    const point = DashboardBalanceDailyMomentumPoint(
      epochDay: 1,
      currentIncomeMinor: 70700000,
      referenceIncomeMinor: 72100000,
      currentExpenseMinor: 75699900,
      referenceExpenseMinor: 65104500,
      isCurrentHalf: true,
      incomeAxis: -.1,
      expenseAxis: .1,
      magnitude: .2,
    );
    await pump(
      tester,
      BalanceDayFinancialComparison(
        momentum: DashboardBalanceDailyMomentumPresentation(
          available: true,
          selected: point,
          rhythm: const [],
        ),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('balance-day-comparison-chart')),
    );
    final painter = paint.painter! as BalanceDayComparisonPainter;
    final colors = painter.scale.bars
        .map((bar) => BalanceDayComparisonPainter.colorFor(bar.flow))
        .toList();
    expect(colors[0], colors[2]);
    expect(colors[1], colors[3]);
    expect(colors[0], isNot(colors[1]));
    final rects = painter.barRects(
      tester.getSize(
        find.byKey(const ValueKey('balance-day-comparison-chart')),
      ),
    );
    expect(rects[3].height, greaterThan(rects[0].height));
    expect(rects[0].height, greaterThan(rects[2].height));
    expect(rects[2].height, greaterThan(rects[1].height));
    expect(
      rects[2].center.dx - rects[1].center.dx,
      greaterThan(rects[1].center.dx - rects[0].center.dx),
    );
    expect(find.text('Figyelem szükséges'), findsNothing);
    expect(find.text('-1,9%'), findsNothing);
    expect(find.text('+16,3%'), findsNothing);
    expect(find.text('Előző 30 nap'), findsOneWidget);
    expect(find.text('Utolsó 30 nap'), findsOneWidget);
    expect(find.text('Bevétel'), findsNWidgets(2));
    expect(find.text('Kiadás'), findsNWidgets(2));
    expect(find.text('+69955 Ft'), findsOneWidget);
    expect(find.text('-49999 Ft'), findsOneWidget);
    expect(find.text('-119954 Ft'), findsOneWidget);
    expect(find.text('Mérlegváltozás'), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile(
        '../../../goldens/balance_day_financial_comparison_v4.png',
      ),
    );
    const worsening = DashboardBalanceDailyImpactPresentation(
      available: true,
      previousSevenExpenseMinor: 4919500,
      currentSevenExpenseMinor: 6602400,
      valuePercent: -34.21079377985568,
      scaleExtentPercent: 100,
      markerFraction: .3289460311007216,
      overflow: false,
      todayNetMinor: 0,
      referenceAverageNetMinor: 0,
    );
    await pump(tester, const BalanceDayImpactFocus(impact: worsening));
    expect(find.text('Romlás'), findsOneWidget);
    expect(find.text('-34,2%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('balance-day-seven-day-comparison')),
      findsOneWidget,
    );
    expect(find.text('Napi hatás'), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('../../../goldens/balance_day_impact_focus_v3.png'),
    );
  });

  testWidgets(
    'V4 comparison shows period nets without quadrant or percentages',
    (tester) async {
      for (final values in [
        [200, 100, 100, 200],
        [200, 100, 200, 100],
        [100, 200, 100, 200],
        [100, 200, 200, 100],
        [0, 0, 0, 0],
        [100000000000, 200000000000, 80000000000, 250000000000],
      ]) {
        final point = DashboardBalanceDailyMomentumPoint(
          epochDay: 1,
          currentIncomeMinor: values[0],
          referenceIncomeMinor: values[1],
          currentExpenseMinor: values[2],
          referenceExpenseMinor: values[3],
          isCurrentHalf: true,
          incomeAxis: 0,
          expenseAxis: 0,
          magnitude: 0,
        );
        await pump(
          tester,
          BalanceDayFinancialComparison(
            momentum: DashboardBalanceDailyMomentumPresentation(
              available: true,
              selected: point,
              rhythm: const [],
            ),
          ),
          size: const Size(320, 190),
        );
        expect(find.text(point.quadrant.label), findsNothing);
        expect(find.text('Mérlegváltozás'), findsOneWidget);
        final paint = tester.widget<CustomPaint>(
          find.byKey(const ValueKey('balance-day-comparison-chart')),
        );
        final painter = paint.painter! as BalanceDayComparisonPainter;
        if (values.every((value) => value == 0)) {
          expect(find.text('0 Ft'), findsNWidgets(7));
          expect(
            painter
                .barRects(const Size(280, 60))
                .every((rect) => rect.height == 0),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('V3 impact keeps neutral, dynamic scale and overshoot states', (
    tester,
  ) async {
    for (final percent in [0.0, 8.0, -8.0, 400.0, -400.0]) {
      final source = DashboardBalanceDailyImpactPresentation(
        available: true,
        previousSevenExpenseMinor: 100000,
        currentSevenExpenseMinor: 100000,
        valuePercent: percent,
        scaleExtentPercent: 15,
        markerFraction: (.5 + percent / 30).clamp(0.0, 1.0),
        overflow: percent.abs() > 15,
        todayNetMinor: 0,
        referenceAverageNetMinor: 0,
      );
      await pump(
        tester,
        BalanceDayImpactFocus(impact: source),
        size: const Size(320, 190),
      );
      expect(
        find.text(
          percent == 0
              ? 'Nincs változás'
              : percent > 0
              ? 'Javulás'
              : 'Romlás',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('balance-day-seven-day-comparison')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

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
        'balance-day-comparison-chart': BalanceDayFinancialComparison(
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
        BalanceDayFinancialComparison(
          momentum: DashboardBalanceDailyMomentumPresentation.unavailable(
            selectedEpochDay: 1,
          ),
        ),
      );
      expect(find.text('Még nincs összehasonlítható előzmény'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('balance-day-comparison-chart')),
        findsNothing,
      );
      expect(find.text('Mérlegváltozás'), findsNothing);

      await pump(
        tester,
        BalanceDayImpactFocus(
          impact: DashboardBalanceDailyImpactPresentation.unavailable(
            todayNetMinor: 0,
            referenceAverageNetMinor: 0,
          ),
        ),
      );
      expect(find.text('Nincs elegendő adat'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_performance_index_view.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';

import 'balance_day_ratio_comparison_test.dart' show source;
import '../../../support/single_pixel_raster_comparator.dart';

const gaugeKey = ValueKey('balance-day-performance-index-gauge');
const capture = ValueKey('performance-capture');
Future<void> pumpPerformance(
  WidgetTester tester, {
  DashboardBalanceDailyInsightsPresentation? data,
  Size size = const Size(410, 350),
  BalanceDayRatioViewPresentation view =
      BalanceDayRatioViewPresentation.performanceIndex,
  BalanceDayRatioPresentation mode = BalanceDayRatioPresentation.coverage,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(fontFamily: 'Inter'),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: capture,
          child: SizedBox.fromSize(
            size: size,
            child: ColoredBox(
              color: Colors.white,
              child: BalanceDayFocusedLayout(
                presentation: data ?? source(),
                focusedPresentation:
                    BalanceDayFocusedPresentation.dailyImpactFocus,
                showFocusedDayImpact: true,
                ratioViewPresentation: view,
                ratioPresentation: mode,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  final originalComparator = goldenFileComparator;
  setUpAll(() {
    goldenFileComparator = SinglePixelRasterComparator(
      Uri.file(
        '${Directory.current.path}/test/features/dashboard/presentation/balance_day_performance_index_view_test.dart',
      ),
      goldenFilename: 'balance_day_performance_index_above_100.png',
    );
  });
  tearDownAll(() => goldenFileComparator = originalComparator);
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('single canonical gauge golden endpoints keep avatars and rail', (
    tester,
  ) async {
    for (final entry in [
      ('', source(), const Size(410, 350)),
      ('_compact', source(), const Size(320, 260)),
      ('_above_100', source(currentIncome: 100000000), const Size(410, 350)),
      ('_below_100', source(currentIncome: 40000000), const Size(410, 350)),
      ('_unavailable', source(noDenominator: true), const Size(410, 350)),
    ]) {
      await pumpPerformance(tester, data: entry.$2, size: entry.$3);
      await tester.pumpAndSettle();
      expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
      expect(find.text('30 napos teljesítmény'), findsOneWidget);
      expect(find.text('Előző 30 nap = 100%'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('balance-day-rhythm-bars')),
        findsOneWidget,
      );
      for (final item in BalanceDayFocusedPresentation.values) {
        expect(
          find.byKey(ValueKey('balance-day-perspective-${item.name}')),
          findsOneWidget,
        );
      }
      expect(
        tester.getCenter(find.byKey(gaugeKey)).dx,
        closeTo(
          tester
              .getCenter(find.byKey(const ValueKey('balance-day-rhythm-bars')))
              .dx,
          .001,
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/balance_day_performance_index${entry.$1}.png',
        ),
      );
    }
  });
  testWidgets(
    'single scene is larger and dual selection is preserved through routing',
    (tester) async {
      await pumpPerformance(
        tester,
        view: BalanceDayRatioViewPresentation.dualGauge,
        mode: BalanceDayRatioPresentation.netMargin,
      );
      await tester.pumpAndSettle();
      final small = tester.getSize(
        find.byKey(const ValueKey('balance-day-ratio-previous')),
      );
      final top = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-top-section')),
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-bottom-section')),
      );
      expect(find.text('+9,7%'), findsOneWidget);
      await pumpPerformance(
        tester,
        mode: BalanceDayRatioPresentation.netMargin,
      );
      await tester.pumpAndSettle();
      expect(find.text('84,3%'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(gaugeKey)).width,
        greaterThan(small.width * 1.4),
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('balance-day-focused-top-section')),
        ),
        top,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('balance-day-focused-bottom-section')),
        ),
        rail,
      );
      await pumpPerformance(
        tester,
        view: BalanceDayRatioViewPresentation.dualGauge,
        mode: BalanceDayRatioPresentation.netMargin,
      );
      await tester.pumpAndSettle();
      expect(find.text('+9,7%'), findsOneWidget);
      expect(find.text('−7,1%'), findsOneWidget);
      expect(find.byType(BudgetSemicircleGauge), findsNWidgets(2));
    },
  );
  testWidgets(
    'canonical animation retargets same state and ignores dual calculation mode',
    (tester) async {
      await pumpPerformance(tester);
      await tester.pumpAndSettle();
      final state = tester.state(find.byKey(gaugeKey));
      BudgetSemicircleMaterial material() => tester.widget(
        find.descendant(
          of: find.byKey(gaugeKey),
          matching: find.byType(BudgetSemicircleMaterial),
        ),
      );
      final old = material().progress;
      await pumpPerformance(
        tester,
        data: source(currentIncome: 100000000),
        mode: BalanceDayRatioPresentation.netMargin,
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.state(find.byKey(gaugeKey)), same(state));
      final target = tester
          .widget<BalanceDayPerformanceIndexView>(
            find.byType(BalanceDayPerformanceIndexView),
          )
          .presentation
          .scale
          .visualProgress;
      expect(material().progress, greaterThan(old));
      expect(material().progress, lessThan(target));
      await tester.pumpAndSettle();
      expect(material().progress, target);
      await pumpPerformance(tester, data: source(currentIncome: 100000000));
      await tester.pumpAndSettle();
      expect(material().progress, target);
    },
  );
  testWidgets('overflow preserves number and missing values suppress marker', (
    tester,
  ) async {
    await pumpPerformance(tester, data: source(currentIncome: 300000000));
    await tester.pumpAndSettle();
    final view = tester.widget<BalanceDayPerformanceIndexView>(
      find.byType(BalanceDayPerformanceIndexView),
    );
    expect(view.presentation.performanceIndex, greaterThan(200));
    expect(find.text(view.presentation.primaryLabel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('budget-semicircle-scale-overflow')),
      findsOneWidget,
    );
    await pumpPerformance(tester, data: source(available: false));
    await tester.pumpAndSettle();
    expect(find.text('Nincs elegendő adat'), findsOneWidget);
    expect(
      tester.widget<BudgetSemicircleGauge>(find.byKey(gaugeKey)).showMarker,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}

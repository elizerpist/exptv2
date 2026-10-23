import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_performance_horizontal_meter_view.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_performance_index_view.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_impact_meter.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'balance_day_ratio_comparison_test.dart' show source;

const trackKey = ValueKey('balance-day-horizontal-meter-track');
const markerKey = ValueKey('balance-impact-meter-marker');
const capture = ValueKey('meter-capture');
Future<void> pumpMeter(
  WidgetTester tester, {
  DashboardBalanceDailyInsightsPresentation? data,
  Size size = const Size(410, 350),
  BalanceDayRatioViewPresentation ratio =
      BalanceDayRatioViewPresentation.performanceIndex,
  BalanceDayPerformanceVisualPresentation visual =
      BalanceDayPerformanceVisualPresentation.horizontalMeter,
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
                ratioViewPresentation: ratio,
                performanceVisualPresentation: visual,
                ratioPresentation: BalanceDayRatioPresentation.netMargin,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
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
  for (final percent in [0.0, 50.0, 84.3, 100.0, 120.0, 150.0, 200.0, 250.0]) {
    test(
      'index $percent maps marker centre over the full usable horizontal axis',
      () {
        final geometry = BalanceImpactMeterGeometry(const Size(350, 56));
        final fraction = (percent / 200).clamp(0.0, 1.0);
        final rect = geometry.markerAt(percent / 200);
        expect(
          rect.center.dx,
          closeTo(
            geometry.start + (geometry.end - geometry.start) * fraction,
            1e-10,
          ),
        );
        expect(rect.left, greaterThanOrEqualTo(1));
        expect(rect.right, lessThanOrEqualTo(349));
        expect(rect.center.dy, closeTo(28, 1e-10));
        if (percent == 100) {
          expect(rect.center.dx, closeTo(175, 1e-10));
        }
      },
    );
  }
  testWidgets(
    'seven horizontal golden endpoints preserve source material and day frame',
    (tester) async {
      for (final entry in [
        ('', source(), const Size(410, 350)),
        ('_compact', source(), const Size(320, 260)),
        ('_below_100', source(currentIncome: 40000000), const Size(410, 350)),
        (
          '_equal_100',
          source(currentIncome: 72100000, currentExpense: 65104500),
          const Size(410, 350),
        ),
        ('_above_100', source(currentIncome: 100000000), const Size(410, 350)),
        ('_overflow', source(currentIncome: 300000000), const Size(410, 350)),
        ('_unavailable', source(noDenominator: true), const Size(410, 350)),
      ]) {
        await pumpMeter(tester, data: entry.$2, size: entry.$3);
        await tester.pumpAndSettle();
        expect(find.byType(BudgetSemicircleGauge), findsNothing);
        expect(
          find.byType(BalanceDayPerformanceHorizontalMeterView),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('balance-day-rhythm-bars')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(capture),
          matchesGoldenFile(
            '../../../goldens/balance_day_performance_horizontal_meter${entry.$1}.png',
          ),
        );
      }
    },
  );
  testWidgets(
    'meter is dominant, marker centred at reference, and unavailability is explicit',
    (tester) async {
      await pumpMeter(
        tester,
        data: source(currentIncome: 72100000, currentExpense: 65104500),
      );
      await tester.pumpAndSettle();
      final main = tester.getRect(
        find.byKey(const ValueKey('balance-day-main-visual')),
      );
      final track = tester.getRect(find.byKey(trackKey));
      expect(track.width / main.width, closeTo(.93, 1e-8));
      expect(track.height, inInclusiveRange(44.0, 64.0));
      expect(
        tester.getCenter(find.byKey(markerKey)).dx,
        closeTo(
          tester
              .getCenter(
                find.byKey(const ValueKey('balance-impact-meter-reference')),
              )
              .dx,
          1e-8,
        ),
      );
      final meter = tester.widget<BalanceImpactMeter>(find.byKey(trackKey));
      expect(
        meter.markerColor,
        BalanceAlternativeHtmlTokens.dailyMomentumPurple,
      );
      await pumpMeter(tester, data: source(available: false));
      await tester.pumpAndSettle();
      expect(find.byKey(markerKey), findsNothing);
      expect(find.text('Nincs elegendő adat'), findsOneWidget);
    },
  );
  testWidgets(
    'same financial model and fixed rail geometry across visual alternatives',
    (tester) async {
      await pumpMeter(
        tester,
        visual: BalanceDayPerformanceVisualPresentation.semicircle,
      );
      await tester.pumpAndSettle();
      final old = tester
          .widget<BalanceDayPerformanceIndexView>(
            find.byType(BalanceDayPerformanceIndexView),
          )
          .presentation;
      final top = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-top-section')),
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-bottom-section')),
      );
      await pumpMeter(tester);
      await tester.pumpAndSettle();
      final next = tester
          .widget<BalanceDayPerformanceHorizontalMeterView>(
            find.byType(BalanceDayPerformanceHorizontalMeterView),
          )
          .presentation;
      expect(next.performanceIndex, old.performanceIndex);
      expect(next.primaryLabel, '84,3%');
      expect(next.interpretation, old.interpretation);
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
      await pumpMeter(tester, ratio: BalanceDayRatioViewPresentation.dualGauge);
      await tester.pumpAndSettle();
      expect(find.byType(BudgetSemicircleGauge), findsNWidgets(2));
      expect(find.text('+9,7%'), findsOneWidget);
      await pumpMeter(
        tester,
        visual: BalanceDayPerformanceVisualPresentation.semicircle,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
      expect(find.text('84,3%'), findsOneWidget);
    },
  );
  testWidgets(
    'rapid retargeting starts at visible marker without animation backlog',
    (tester) async {
      await pumpMeter(tester);
      await tester.pumpAndSettle();
      final state = tester.state(
        find.byType(BalanceDayPerformanceHorizontalMeterView),
      );
      double position() => tester
          .widget<BalanceImpactMeter>(find.byKey(trackKey))
          .markerFraction;
      final initial = position();
      await pumpMeter(tester, data: source(currentIncome: 100000000));
      await tester.pump(const Duration(milliseconds: 60));
      final intermediate = position();
      expect(intermediate, greaterThan(initial));
      expect(intermediate, lessThan(.5965));
      await pumpMeter(tester, data: source(currentIncome: 40000000));
      expect(position(), closeTo(intermediate, 1e-10));
      await tester.pump(const Duration(milliseconds: 30));
      expect(position(), lessThan(intermediate));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(BalanceDayPerformanceHorizontalMeterView)),
        same(state),
      );
      final model = tester
          .widget<BalanceDayPerformanceHorizontalMeterView>(
            find.byType(BalanceDayPerformanceHorizontalMeterView),
          )
          .presentation;
      expect(position(), model.scale.visualProgress);
    },
  );
}

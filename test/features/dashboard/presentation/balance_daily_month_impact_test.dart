import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_daily_month_impact_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_daily_month_impact_ribbon.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_momentum_rail.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'balance_day_ratio_comparison_test.dart' show source;

DashboardBalanceDailyMonthImpactPresentation data(
  double? before,
  double? after,
) => DashboardBalanceDailyMonthImpactPresentation(
  selectedEpochDay: 20742,
  incomeBeforeMinor: before == null ? 0 : 10000000,
  expenseBeforeMinor: before == null ? 0 : ((100 - before) * 100000).round(),
  incomeAfterMinor: after == null ? 0 : 10000000,
  expenseAfterMinor: after == null ? 0 : ((100 - after) * 100000).round(),
  ratioBeforePercent: before,
  ratioAfterPercent: after,
  dailyImpactPp: before == null || after == null ? null : after - before,
  available: before != null && after != null,
);
DashboardBalanceDailyInsightsPresentation insights(
  double? before,
  double? after, {
  bool history = true,
}) {
  final old = source(available: history);
  return DashboardBalanceDailyInsightsPresentation(
    identity: old.identity,
    timeScope: old.timeScope,
    momentum: old.momentum,
    impact: old.impact,
    monthImpact: data(before, after),
  );
}

const capture = ValueKey('month-impact-evidence');
Future<void> pump(
  WidgetTester tester,
  double? before,
  double? after, {
  Size size = const Size(390, 400),
  bool history = true,
  BalanceDayFocusedPresentation selected =
      BalanceDayFocusedPresentation.monthlyNetMarginImpact,
  ValueChanged<BalanceDayFocusedPresentation>? onChanged,
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
                presentation: insights(before, after, history: history),
                focusedPresentation: selected,
                showFocusedDayImpact: false,
                onFocusedPresentationChanged: onChanged,
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
  for (final entry in [
    (
      30.0,
      26.0,
      '−4,0 pp',
      BalanceDailyMonthImpactState.decreasedStillPositive,
    ),
    (-12.0, 8.0, '+20,0 pp', BalanceDailyMonthImpactState.crossedToPositive),
    (5.0, -3.0, '−8,0 pp', BalanceDailyMonthImpactState.crossedToNegative),
    (
      -25.0,
      -15.0,
      '+10,0 pp',
      BalanceDailyMonthImpactState.increasedStillNegative,
    ),
    (
      10.0,
      20.0,
      '+10,0 pp',
      BalanceDailyMonthImpactState.increasedStillPositive,
    ),
    (
      -10.0,
      -20.0,
      '−10,0 pp',
      BalanceDailyMonthImpactState.decreasedStillNegative,
    ),
    (10.0, 0.0, '−10,0 pp', BalanceDailyMonthImpactState.reachedNeutral),
    (-10.0, 0.0, '+10,0 pp', BalanceDailyMonthImpactState.reachedNeutral),
    (0.0, 10.0, '+10,0 pp', BalanceDailyMonthImpactState.crossedToPositive),
    (0.0, -10.0, '−10,0 pp', BalanceDailyMonthImpactState.crossedToNegative),
    (20.0, 20.0, '0,0 pp', BalanceDailyMonthImpactState.unchanged),
  ]) {
    test('prepared visual state ${entry.$1} to ${entry.$2}', () {
      final p = BalanceDailyMonthImpactPresentation.fromData(
        data(entry.$1, entry.$2),
      );
      expect(p.state, entry.$4);
      expect(p.deltaLabel, entry.$3);
      expect(p.beforeLabel, contains('%'));
      expect(p.afterLabel, contains('%'));
      if (p.direction != 0) {
        expect(p.explanation, contains('százalékpont'));
      }
      if (p.state == BalanceDailyMonthImpactState.increasedStillNegative) {
        expect(p.rightColor, BalanceDailyMonthImpactColors.purple);
        expect(p.valueColor, BalanceDailyMonthImpactColors.positive);
      }
    });
  }
  test('undefined before never becomes a fictitious zero ratio or delta', () {
    final p = BalanceDailyMonthImpactPresentation.fromData(data(null, 20));
    expect(p.available, isFalse);
    expect(p.deltaLabel, '— pp');
    expect(p.beforeLabel, '—');
    expect(p.afterLabel, '+20%');
    expect(
      BalanceDailyMonthImpactPresentation.fromData(null).state,
      BalanceDailyMonthImpactState.unavailable,
    );
  });
  testWidgets(
    'reference four states, neutral, missing and compact golden endpoints',
    (tester) async {
      for (final entry in [
        ('positive_decrease', 30.0, 26.0, const Size(390, 400)),
        ('crossed_positive', -12.0, 8.0, const Size(390, 400)),
        ('crossed_negative', 5.0, -3.0, const Size(390, 400)),
        ('negative_improvement', -25.0, -15.0, const Size(390, 400)),
        ('neutral', 20.0, 20.0, const Size(390, 400)),
        ('unavailable', null, 20.0, const Size(390, 400)),
        ('compact', 30.0, 26.0, const Size(320, 260)),
      ]) {
        await pump(tester, entry.$2, entry.$3, size: entry.$4);
        await tester.pumpAndSettle();
        expect(find.byType(BalanceDailyMonthImpactView), findsOneWidget);
        expect(
          find.byKey(const ValueKey('balance-day-momentum-rail')),
          findsOneWidget,
        );
        for (final value in BalanceDayFocusedPresentation.values) {
          expect(
            find.byKey(ValueKey('balance-day-perspective-${value.name}')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(capture),
          matchesGoldenFile(
            '../../../goldens/balance_day_month_impact_${entry.$1}.png',
          ),
        );
      }
    },
  );
  testWidgets(
    'four avatars keep height and rail state; monthly impact works without rhythm history',
    (tester) async {
      BalanceDayFocusedPresentation? next;
      await pump(
        tester,
        30,
        26,
        history: false,
        onChanged: (value) => next = value,
      );
      final rail = tester.state(find.byType(BalanceDayMomentumRail));
      final top = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-top-section')),
      );
      final bottom = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-bottom-section')),
      );
      expect(find.text('−4,0 pp'), findsOneWidget);
      for (final selected in BalanceDayFocusedPresentation.values) {
        await tester.tap(
          find.byKey(ValueKey('balance-day-perspective-${selected.name}')),
        );
        expect(next, selected);
        await pump(
          tester,
          30,
          26,
          history: false,
          selected: selected,
          onChanged: (value) => next = value,
        );
        expect(tester.state(find.byType(BalanceDayMomentumRail)), same(rail));
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
          bottom,
        );
        expect(tester.takeException(), isNull);
      }
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/balance_day_four_avatar_selector.png',
        ),
      );
    },
  );
  testWidgets(
    'info opens existing rounded sheet pattern and ribbon retargets visible shape',
    (tester) async {
      await pump(tester, 30, 26);
      await tester.pumpAndSettle();
      final viewState = tester.state(find.byType(BalanceDailyMonthImpactView));
      BalanceDailyMonthImpactRibbonPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey('balance-day-month-impact-ribbon'),
                    ),
                  )
                  .painter!
              as BalanceDailyMonthImpactRibbonPainter;
      expect(painter().frame.direction, -1);
      await pump(tester, -12, 8);
      await tester.pump(const Duration(milliseconds: 60));
      final middle = painter().frame.direction;
      expect(middle, greaterThan(-1));
      expect(middle, lessThan(1));
      await pump(tester, 5, -3);
      expect(painter().frame.direction, closeTo(middle, 1e-10));
      await tester.pumpAndSettle();
      expect(painter().frame.direction, -1);
      expect(
        tester.state(find.byType(BalanceDailyMonthImpactView)),
        same(viewState),
      );
      await tester.tap(
        find.byKey(const ValueKey('balance-day-month-impact-info')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('A mutató megmutatja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

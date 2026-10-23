import 'dart:io';

import '../../../support/single_pixel_raster_comparator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

DashboardBalanceDailyInsightsPresentation source({
  bool noDenominator = false,
  bool available = true,
  int currentIncome = 70700000,
  int currentExpense = 75699900,
}) {
  const date = LocalDate(year: 2026, month: 7, day: 16);
  DashboardBalanceDailyMomentumPoint point(int epochDay) =>
      DashboardBalanceDailyMomentumPoint(
        epochDay: epochDay,
        referenceIncomeMinor: 72100000,
        referenceExpenseMinor: noDenominator ? 0 : 65104500,
        currentIncomeMinor: noDenominator ? 0 : currentIncome,
        currentExpenseMinor: noDenominator ? 0 : currentExpense,
        isCurrentHalf: epochDay >= date.epochDay - 29,
        incomeAxis: -.2,
        expenseAxis: .3,
        magnitude: .4,
      );
  return DashboardBalanceDailyInsightsPresentation(
    identity: const DashboardBalancePrimaryIdentity(
      upstreamScopeKey: 'ratio',
      indexGeneration: 1,
      coreRevision: 1,
    ),
    timeScope: const DayScope(date),
    momentum: available
        ? DashboardBalanceDailyMomentumPresentation(
            available: true,
            selected: point(date.epochDay),
            rhythm: [for (var i = 59; i >= 0; i--) point(date.epochDay - i)],
          )
        : DashboardBalanceDailyMomentumPresentation.unavailable(
            selectedEpochDay: date.epochDay,
          ),
    impact: DashboardBalanceDailyImpactPresentation.unavailable(
      todayNetMinor: 0,
      referenceAverageNetMinor: 0,
    ),
  );
}

const previous = ValueKey('balance-day-ratio-previous');
const current = ValueKey('balance-day-ratio-current');
void main() {
  final originalComparator = goldenFileComparator;
  setUpAll(() {
    goldenFileComparator = SinglePixelRasterComparator(
      Uri.file(
        '${Directory.current.path}/test/features/dashboard/presentation/balance_day_ratio_comparison_test.dart',
      ),
      goldenFilename: 'balance_day_ratio_net_margin.png',
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
  Future<void> pump(
    WidgetTester tester,
    DashboardBalanceDailyInsightsPresentation data,
    BalanceDayRatioPresentation mode, {
    Size size = const Size(410, 350),
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
                child: BalanceDayFocusedLayout(
                  presentation: data,
                  focusedPresentation:
                      BalanceDayFocusedPresentation.dailyImpactFocus,
                  ratioPresentation: mode,
                  showFocusedDayImpact: true,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  BudgetSemicircleMaterial material(WidgetTester tester, Key key) =>
      tester.widget<BudgetSemicircleMaterial>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(BudgetSemicircleMaterial),
        ),
      );
  testWidgets(
    'five ratio golden endpoints use two canonical gauges and stable geometry',
    (tester) async {
      for (final entry in [
        (
          'coverage',
          BalanceDayRatioPresentation.coverage,
          const Size(410, 350),
          false,
        ),
        (
          'net_margin',
          BalanceDayRatioPresentation.netMargin,
          const Size(410, 350),
          false,
        ),
        (
          'coverage_compact',
          BalanceDayRatioPresentation.coverage,
          const Size(320, 260),
          false,
        ),
        (
          'net_margin_compact',
          BalanceDayRatioPresentation.netMargin,
          const Size(320, 260),
          false,
        ),
        (
          'zero_denominator',
          BalanceDayRatioPresentation.coverage,
          const Size(410, 350),
          true,
        ),
      ]) {
        await pump(
          tester,
          source(noDenominator: entry.$4),
          entry.$2,
          size: entry.$3,
        );
        await tester.pumpAndSettle();
        expect(find.byType(BudgetSemicircleGauge), findsNWidgets(2));
        expect(find.text('Egyenlegarány'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('balance-day-compact-impact')),
          findsNothing,
        );
        final left = tester.getRect(find.byKey(previous));
        final right = tester.getRect(find.byKey(current));
        final rail = tester.getRect(
          find.byKey(const ValueKey('balance-day-rhythm-bars')),
        );
        expect(left.size, right.size);
        expect(
          (left.center.dx + right.center.dx) / 2,
          closeTo(rail.center.dx, .001),
        );
        expect(
          find.byKey(const ValueKey('budget-semicircle-neutral-reference')),
          findsNWidgets(2),
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            '../../../goldens/balance_day_ratio_${entry.$1}.png',
          ),
        );
      }
    },
  );
  testWidgets(
    'mode switch retains gauge states and geometry and retargets canonical motion',
    (tester) async {
      final data = source();
      await pump(tester, data, BalanceDayRatioPresentation.coverage);
      final leftState = tester.state(find.byKey(previous));
      final rightState = tester.state(find.byKey(current));
      final leftRect = tester.getRect(find.byKey(previous));
      final before = material(tester, previous).progress;
      await pump(tester, data, BalanceDayRatioPresentation.netMargin);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.state(find.byKey(previous)), same(leftState));
      expect(tester.state(find.byKey(current)), same(rightState));
      expect(tester.getRect(find.byKey(previous)), leftRect);
      expect(material(tester, previous).progress, lessThan(before));
      expect(
        material(tester, previous).progress,
        greaterThan((9.70249653259362 + 100) / 200),
      );
      await tester.pumpAndSettle();
      expect(find.text('+9,7%'), findsOneWidget);
      expect(find.text('−7,1%'), findsOneWidget);
      expect(find.text('−16,8 százalékpont'), findsOneWidget);
      expect(
        data.momentum.selected.epochDay,
        const LocalDate(year: 2026, month: 7, day: 16).epochDay,
      );
      expect(
        material(tester, previous).presentation.semanticScale!.neutralLabel,
        '0%',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('long net amounts cannot move or resize one period gauge', (
    tester,
  ) async {
    for (final size in [const Size(410, 350), const Size(320, 260)]) {
      await pump(
        tester,
        source(currentIncome: 9000000000000000000, currentExpense: 1),
        BalanceDayRatioPresentation.netMargin,
        size: size,
      );
      await tester.pumpAndSettle();
      final left = tester.getRect(find.byKey(previous));
      final right = tester.getRect(find.byKey(current));
      expect(left.size, right.size);
      expect(left.top, closeTo(right.top, .001));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'both overflow directions preserve actual percentage and canonical marker',
    (tester) async {
      await pump(
        tester,
        source(currentIncome: 25000000, currentExpense: 10000000),
        BalanceDayRatioPresentation.coverage,
      );
      await tester.pumpAndSettle();
      expect(find.text('250,0%'), findsOneWidget);
      expect(material(tester, current).progress, 1);
      expect(material(tester, current).showMarker, isTrue);
      expect(
        find.descendant(of: find.byKey(current), matching: find.text('›')),
        findsOneWidget,
      );
      await pump(
        tester,
        source(currentIncome: 10000000, currentExpense: 25000000),
        BalanceDayRatioPresentation.netMargin,
      );
      await tester.pumpAndSettle();
      expect(find.text('−150,0%'), findsOneWidget);
      expect(
        material(tester, current).presentation.semanticScale!.rawValue,
        -150,
      );
      expect(material(tester, current).progress, 0);
      expect(material(tester, current).showMarker, isTrue);
      expect(
        find.descendant(of: find.byKey(current), matching: find.text('‹')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'undefined denominators paint empty track and missing history paints no fictitious gauges',
    (tester) async {
      await pump(
        tester,
        source(noDenominator: true),
        BalanceDayRatioPresentation.coverage,
      );
      expect(find.text('Kiadás nélkül'), findsOneWidget);
      expect(find.text('Nincs pénzmozgás'), findsOneWidget);
      expect(find.text('Nem számítható'), findsOneWidget);
      expect(material(tester, previous).showMarker, isFalse);
      expect(material(tester, current).showMarker, isFalse);
      expect(material(tester, previous).progress, 0);
      await pump(
        tester,
        source(available: false),
        BalanceDayRatioPresentation.coverage,
      );
      expect(
        find.text('Nincs elegendő összehasonlítható adat'),
        findsOneWidget,
      );
      expect(find.byType(BudgetSemicircleGauge), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

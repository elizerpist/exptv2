import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_day_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_year_focused_layout.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'BalanceDayEvidence',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets(
    'day router preserves default old content, header and Mother Card through all variants',
    (tester) async {
      final settings = BalancePresentationController();
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(_day),
      );
      final header = ValueNotifier<DashboardBalancePresentation?>(
        _header(_day),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      addTearDown(header.dispose);
      await tester.pumpWidget(_host(_day, settings, linked, header));
      await tester.pump();
      expect(
        find.byType(BalanceAlternativeDailyMomentumCoordinateCard),
        findsOneWidget,
      );
      expect(find.byType(BalanceDayFocusedLayout), findsNothing);
      final mother = tester.getRect(
        find.byKey(const ValueKey('balance-unified-header-content-surface')),
      );
      final oldHeader = tester
          .widget<Text>(find.byKey(const ValueKey('balance-header-net-amount')))
          .data;
      final original = linked.value;
      settings.setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
      await tester.pump();
      final rail = tester.getRect(
        find.byKey(const ValueKey('balance-day-focused-top-section')),
      );
      for (final p in BalanceDayFocusedPresentation.values) {
        settings.setDayFocusedPresentation(p);
        await tester.pump();
        expect(find.byType(BalanceDayFocusedLayout), findsOneWidget);
        expect(
          find.byType(BalanceAlternativeDailyMomentumCoordinateCard),
          findsNothing,
        );
        expect(
          tester.getRect(
            find.byKey(
              const ValueKey('balance-unified-header-content-surface'),
            ),
          ),
          mother,
        );
        expect(
          tester.getRect(
            find.byKey(const ValueKey('balance-day-focused-top-section')),
          ),
          rail,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('balance-header-net-amount')),
              )
              .data,
          oldHeader,
        );
        expect(linked.value, same(original));
        expect(
          find.byKey(const ValueKey('balance-day-compact-impact')),
          p == BalanceDayFocusedPresentation.dailyImpactFocus
              ? findsNothing
              : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      settings.setDayLayoutPresentation(BalanceDayLayoutPresentation.current);
      await tester.pump();
      expect(
        find.byType(BalanceAlternativeDailyMomentumCoordinateCard),
        findsOneWidget,
      );
      expect(find.byType(BalanceDayFocusedLayout), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'impact toggle grows actual compass circle and comparison panels without moving rail',
    (tester) async {
      final settings = BalancePresentationController()
        ..setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(_day),
      );
      final header = ValueNotifier<DashboardBalancePresentation?>(
        _header(_day),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      addTearDown(header.dispose);
      await tester.pumpWidget(_host(_day, settings, linked, header));
      await tester.pump();
      for (final p in [
        BalanceDayFocusedPresentation.financialCompass,
        BalanceDayFocusedPresentation.financialComparison,
      ]) {
        settings.setDayFocusedPresentation(p);
        settings.setShowFocusedDayImpact(true);
        await tester.pump();
        final target = find.byKey(
          ValueKey(
            p == BalanceDayFocusedPresentation.financialCompass
                ? 'balance-day-compass-circle'
                : 'balance-day-comparison-panels',
          ),
        );
        final on = tester.getSize(target);
        final rail = tester.getRect(
          find.byKey(const ValueKey('balance-day-focused-top-section')),
        );
        settings.setShowFocusedDayImpact(false);
        await tester.pump();
        expect(tester.getSize(target).height, greaterThan(on.height));
        if (p == BalanceDayFocusedPresentation.financialCompass) {
          expect(tester.getSize(target).width, greaterThan(on.width));
        }
        expect(
          tester.getRect(
            find.byKey(const ValueKey('balance-day-focused-top-section')),
          ),
          rail,
        );
        expect(
          find.byKey(const ValueKey('balance-day-compact-impact')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final size in [const Size(320, 300), const Size(390, 360)]) {
    testWidgets(
      'rendered Day rail equals Year and Month selector allocations at $size',
      (tester) async {
        Future<void> pump(Widget child) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(fontFamily: 'BalanceDayEvidence'),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: child,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
        }

        final daySource =
            BalanceAlternativeScopePresentation.fromLinked(_linked(_day))
                as BalanceAlternativeDayPresentation;
        await pump(
          BalanceDayFocusedLayout(
            presentation: daySource.dailyInsights,
            focusedPresentation: BalanceDayFocusedPresentation.financialCompass,
            showFocusedDayImpact: true,
          ),
        );
        final dayRect = tester.getRect(
          find.byKey(const ValueKey('balance-day-focused-top-section')),
        );
        expect(dayRect.height, closeTo(size.height * .21, .001));
        final yearSource =
            BalanceAlternativeScopePresentation.fromLinked(
                  _linked(const YearScope(2025)),
                )
                as BalanceAlternativeYearPresentation;
        await pump(BalanceYearFocusedLayout(presentation: yearSource));
        final yearRect = tester.getRect(
          find.byKey(const ValueKey('balance-year-focused-selector-zone')),
        );
        expect(dayRect.top, yearRect.top);
        expect(dayRect.height, yearRect.height);
        final monthSource =
            BalanceAlternativeScopePresentation.fromLinked(
                  _linked(const MonthScope(YearMonth(year: 2025, month: 5))),
                )
                as BalanceAlternativeMonthPresentation;
        await pump(BalanceMonthFocusedLayout(presentation: monthSource));
        final option = find.byKey(
          const ValueKey('balance-month-perspective-balanceTrend'),
        );
        final zone = find.ancestor(
          of: option,
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == size.height * .21,
          ),
        );
        expect(zone, findsOneWidget);
        expect(tester.getRect(zone).top, dayRect.top);
        expect(tester.getRect(zone).height, dayRect.height);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final scope in <LedgerTimeScope>[
    const AllTimeScope(),
    const YearScope(2025),
    const MonthScope(YearMonth(year: 2025, month: 5)),
  ]) {
    testWidgets(
      'day settings leave ${scope.canonicalKey} content pixels unchanged',
      (tester) async {
        final settings = BalancePresentationController()
          ..setMonthCombinedCardPresentation(
            BalanceMonthCombinedCardPresentation.spendingRhythm,
          )
          ..setYearBarPresentation(BalanceYearBarPresentation.clay3d);
        final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
          _linked(scope),
        );
        final header = ValueNotifier<DashboardBalancePresentation?>(
          _header(scope),
        );
        addTearDown(settings.dispose);
        addTearDown(linked.dispose);
        addTearDown(header.dispose);
        await tester.pumpWidget(_host(scope, settings, linked, header));
        await tester.pump();
        final surface = find.byKey(const ValueKey('day-focused-evidence'));
        final boundary = tester.renderObject<RenderRepaintBoundary>(surface);
        final before = await tester.runAsync(() => boundary.toImage());
        settings.setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
        settings.setDayFocusedPresentation(
          BalanceDayFocusedPresentation.dailyImpactFocus,
        );
        settings.setShowFocusedDayImpact(false);
        await tester.pump();
        expect(find.byType(BalanceDayFocusedLayout), findsNothing);
        expect(
          settings.value.monthCombinedCardPresentation,
          BalanceMonthCombinedCardPresentation.spendingRhythm,
        );
        expect(
          settings.value.yearBarPresentation,
          BalanceYearBarPresentation.clay3d,
        );
        await expectLater(surface, matchesReferenceImage(before!));
        before.dispose();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('all focused variants fit small physical content bounds', (
    tester,
  ) async {
    final source = _linked(_day).dailyInsights;
    for (final p in BalanceDayFocusedPresentation.values) {
      for (final show in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 280,
                  height: 210,
                  child: BalanceDayFocusedLayout(
                    presentation: source,
                    focusedPresentation: p,
                    showFocusedDayImpact: show,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('balance-day-focused-top-section')),
              )
              .height,
          closeTo(210 * .21, .001),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${p.name} impact=$show',
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('five focused daily whole-content golden endpoints', (
    tester,
  ) async {
    final settings = BalancePresentationController()
      ..setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _linked(_day),
    );
    final header = ValueNotifier<DashboardBalancePresentation?>(_header(_day));
    addTearDown(settings.dispose);
    addTearDown(linked.dispose);
    addTearDown(header.dispose);
    await tester.pumpWidget(_host(_day, settings, linked, header));
    await tester.pump();
    for (final variant in [
      (BalanceDayFocusedPresentation.financialCompass, true, 'compass_on'),
      (BalanceDayFocusedPresentation.financialCompass, false, 'compass_off'),
      (
        BalanceDayFocusedPresentation.financialComparison,
        true,
        'comparison_on',
      ),
      (
        BalanceDayFocusedPresentation.financialComparison,
        false,
        'comparison_off',
      ),
      (BalanceDayFocusedPresentation.dailyImpactFocus, true, 'impact_focus'),
    ]) {
      settings.setDayFocusedPresentation(variant.$1);
      settings.setShowFocusedDayImpact(variant.$2);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('day-focused-evidence')),
        matchesGoldenFile(
          '../../../goldens/balance_day_focused_${variant.$3}.png',
        ),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _day = DayScope(LocalDate(year: 2025, month: 5, day: 12));
const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'day-fixture',
  indexGeneration: 1,
  coreRevision: 1,
);
List<DashboardLedgerEntry> _scopeEntries(
  LedgerTimeScope scope,
  bool income,
  int year,
) => [
  for (var month = 1; month <= 12; month++)
    for (final day in income ? [1, 12] : [3, 7, 12, 18, 24])
      DashboardLedgerEntry(
        id: '${income ? 'i' : 'e'}-$month-$day',
        categoryId: income ? 'income' : 'expense',
        partnerId: 'fixture',
        direction: income ? 'income' : 'expense',
        amountMinor:
            (income
                ? (day == 1 ? 150000 : 45000)
                : (day == 3
                      ? 25000
                      : day == 7
                      ? 30000
                      : day == 12
                      ? 1000
                      : day == 18
                      ? 20000
                      : 15000)) *
            100,
        bookedLocalEpochDay: LocalDate(
          year: year,
          month: month,
          day: day,
        ).epochDay,
        bookedLocalTimeMinutes: 600,
      ),
];
DashboardBalanceLinkedPresentation _linked(LedgerTimeScope scope) {
  final year = switch (scope) {
    YearScope(:final year) => year,
    MonthScope(:final value) => value.year,
    DayScope(:final date) => date.year,
    _ => 2025,
  };
  return DashboardBalanceLinkedProjection.build(
    identity: _identity,
    timeScope: scope,
    selectedDirection: LedgerDirection.expense,
    incomeEntries: scope is AllTimeScope
        ? const []
        : _scopeEntries(scope, true, year),
    expenseEntries: scope is AllTimeScope
        ? const []
        : _scopeEntries(scope, false, year),
    logicalAsOfDate: const LocalDate(year: 2026, month: 6, day: 15),
  );
}

DashboardBalancePresentation _header(LedgerTimeScope scope) {
  final year = scope is YearScope ? scope.year : 2025;
  final income = scope is AllTimeScope
      ? <DashboardLedgerEntry>[]
      : _scopeEntries(scope, true, year);
  final expense = scope is AllTimeScope
      ? <DashboardLedgerEntry>[]
      : _scopeEntries(scope, false, year);
  final i = income.fold<int>(0, (v, e) => v + e.amountMinor);
  final e = expense.fold<int>(0, (v, e) => v + e.amountMinor);
  return DashboardBalancePresentation(
    scopeKey: 'day-fixture',
    coreRevision: 1,
    incomeTotalMinor: i,
    expenseTotalMinor: e,
    netTotalMinor: i - e,
    formattedNetTotal: '${(i - e) ~/ 100} Ft',
    presentationId: 1,
    headerTimeScope: scope,
    history: DashboardBalanceHistoryProjection.build(
      incomeEntries: income,
      expenseEntries: expense,
    ),
  );
}

Widget _host(
  LedgerTimeScope scope,
  BalancePresentationController settings,
  ValueNotifier<DashboardBalanceLinkedPresentation?> linked,
  ValueNotifier<DashboardBalancePresentation?> header, {
  double collapseFraction = 0,
}) => MaterialApp(
  theme: ThemeData(
    fontFamily: scope is DayScope ? 'BalanceDayEvidence' : 'Ahem',
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: scope is DayScope ? 390 : 412,
        height: scope is DayScope ? 844 : 892,
        child: RepaintBoundary(
          key: const ValueKey('day-focused-evidence'),
          child: BalanceDashboardCoreSurface(
            presentation: DashboardCoreModePresentation(
              geometry: DashboardGeometryResolver.resolve(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  scope is DayScope
                      ? const Size(390, 844)
                      : const Size(412, 892),
                ),
                mode: DashboardModeSpec.balance,
                collapseProgress:
                    DashboardLayoutMetrics.reference
                        .fitToViewport(
                          scope is DayScope
                              ? const Size(390, 844)
                              : const Size(412, 892),
                        )
                        .collapseTravel *
                    collapseFraction,
                isRailExpanded: false,
              ),
              palette: DashboardModePaletteResolver.resolve(
                DashboardModeSpec.balance,
              ),
            ),
            balancePresentation: header,
            balanceLinkedPresentation: linked,
            presentationSettings: settings,
            adaptiveScope: scope,
          ),
        ),
      ),
    ),
  ),
);

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
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_sum_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_sum_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  testWidgets('SUM content identity survives collapse and immediate reverse', (
    tester,
  ) async {
    final scope = const AllTimeScope();
    final settings = BalancePresentationController()
      ..setSumLayoutPresentation(BalanceSumLayoutPresentation.focused)
      ..setSumFocusedPresentation(BalanceSumFocusedPresentation.stability);
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _linked(scope),
    );
    final header = ValueNotifier<DashboardBalancePresentation?>(_header(scope));
    addTearDown(settings.dispose);
    addTearDown(linked.dispose);
    addTearDown(header.dispose);
    await tester.pumpWidget(_host(scope, settings, linked, header));
    await tester.pump();
    final focused = find.byType(BalanceSumFocusedLayout);
    final element = tester.element(focused);
    final state = tester.state(focused);
    final prepared = linked.value;
    final mother = tester.element(
      find.byKey(const ValueKey('balance-unified-header-content-surface')),
    );
    for (final fraction in [0.0005, .05, .35, .1, .7, 1.0, 0.0]) {
      await tester.pumpWidget(
        _host(scope, settings, linked, header, collapseFraction: fraction),
      );
      await tester.pump();
      expect(focused, findsOneWidget);
      expect(tester.element(focused), same(element));
      expect(tester.state(focused), same(state));
      expect(linked.value, same(prepared));
      expect(
        tester.element(
          find.byKey(const ValueKey('balance-unified-header-content-surface')),
        ),
        same(mother),
      );
      expect(
        find.byKey(const ValueKey('balance-upper-carousel')),
        findsNothing,
      );
      expect(
        settings.value.sumFocusedPresentation,
        BalanceSumFocusedPresentation.stability,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final size in [
    const Size(280, 210),
    const Size(320, 230),
    const Size(390, 360),
  ]) {
    testWidgets('SUM perspectives and actual stats reallocation at $size', (
      tester,
    ) async {
      final source =
          BalanceAlternativeScopePresentation.fromLinked(
                _linked(const AllTimeScope()),
              )
              as BalanceAlternativeSumPresentation;
      final settings = BalancePresentationController()
        ..setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: ValueListenableBuilder<BalancePresentationSettings>(
                  valueListenable: settings,
                  builder: (context, value, _) => BalanceSumFocusedLayout(
                    presentation: source,
                    perspective: value.sumFocusedPresentation,
                    showSupplementaryStats:
                        value.showSumFocusedSupplementaryStats,
                    onPerspectiveChanged: settings.setSumFocusedPresentation,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final top = tester
          .getSize(
            find.byKey(const ValueKey('balance-sum-focused-selector-zone')),
          )
          .height;
      expect(top, closeTo(size.height * .21, .001));
      for (final p in BalanceSumFocusedPresentation.values) {
        settings.setShowSumFocusedSupplementaryStats(true);
        await tester.tap(
          find.byKey(ValueKey('balance-sum-perspective-${p.name}')),
        );
        await tester.pump();
        expect(settings.value.sumFocusedPresentation, p);
        final chart = find.byKey(ValueKey('balance-sum-chart-${p.name}'));
        expect(chart, findsOneWidget);
        final before = tester.getSize(chart);
        final paintFinder = find.descendant(
          of: chart,
          matching: find.byType(CustomPaint),
        );
        final prepared = p == BalanceSumFocusedPresentation.positiveRatio
            ? null
            : (tester.widget<CustomPaint>(paintFinder.first).painter!
                      as BalanceSumFocusedChartPainter)
                  .chart;
        settings.setShowSumFocusedSupplementaryStats(false);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('balance-sum-focused-stats')),
          findsNothing,
        );
        expect(tester.getSize(chart).height, greaterThan(before.height));
        if (prepared != null) {
          expect(
            (tester.widget<CustomPaint>(paintFinder.first).painter!
                    as BalanceSumFocusedChartPainter)
                .chart,
            same(prepared),
          );
        }
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('balance-sum-focused-selector-zone')),
              )
              .height,
          top,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'SUM starts focused and roundtrips through the explicit old renderer',
    (tester) async {
      const scope = AllTimeScope();
      final settings = BalancePresentationController();
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
      expect(find.byType(BalanceSumFocusedLayout), findsOneWidget);
      settings.setSumLayoutPresentation(BalanceSumLayoutPresentation.current);
      await tester.pump();
      expect(find.byType(BalanceAlternativeSumHistogramCard), findsOneWidget);
      final mother = tester.getRect(
        find.byKey(const ValueKey('balance-unified-header-content-surface')),
      );
      final amount = tester
          .widget<Text>(find.byKey(const ValueKey('balance-header-net-amount')))
          .data;
      final data = linked.value;
      for (var i = 0; i < 2; i++) {
        settings.setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
        await tester.pump();
        expect(find.byType(BalanceSumFocusedLayout), findsOneWidget);
        expect(find.byType(BalanceAlternativeSumHistogramCard), findsNothing);
        for (final p in BalanceSumFocusedPresentation.values) {
          await tester.tap(
            find.byKey(ValueKey('balance-sum-perspective-${p.name}')),
          );
          await tester.pump();
          expect(settings.value.sumFocusedPresentation, p);
          expect(
            tester.getRect(
              find.byKey(
                const ValueKey('balance-unified-header-content-surface'),
              ),
            ),
            mother,
          );
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('balance-header-net-amount')),
                )
                .data,
            amount,
          );
          expect(linked.value, same(data));
          expect(tester.takeException(), isNull);
        }
        settings.setSumLayoutPresentation(BalanceSumLayoutPresentation.current);
        await tester.pump();
        expect(find.byType(BalanceAlternativeSumHistogramCard), findsOneWidget);
        expect(find.byType(BalanceSumFocusedLayout), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final scope in <LedgerTimeScope>[
    const YearScope(2025),
    const MonthScope(YearMonth(year: 2025, month: 5)),
    const DayScope(LocalDate(year: 2025, month: 5, day: 15)),
  ]) {
    testWidgets('SUM preferences leave $scope pixels unchanged', (
      tester,
    ) async {
      final settings = BalancePresentationController();
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
      final finder = find.byKey(const ValueKey('month-focused-evidence'));
      final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
      final image = await tester.runAsync(() => boundary.toImage());
      settings.setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
      settings.setSumFocusedPresentation(
        BalanceSumFocusedPresentation.stability,
      );
      settings.setShowSumFocusedSupplementaryStats(false);
      await tester.pump();
      await expectLater(finder, matchesReferenceImage(image!));
      image.dispose();
      expect(find.byType(BalanceSumFocusedLayout), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('SUM focused visual evidence for each perspective and stats off', (
    tester,
  ) async {
    const scope = AllTimeScope();
    final settings = BalancePresentationController()
      ..setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _linked(scope),
    );
    final header = ValueNotifier<DashboardBalancePresentation?>(_header(scope));
    addTearDown(settings.dispose);
    addTearDown(linked.dispose);
    addTearDown(header.dispose);
    await tester.pumpWidget(_host(scope, settings, linked, header));
    await tester.pump();
    for (final p in BalanceSumFocusedPresentation.values) {
      settings.setSumFocusedPresentation(p);
      for (final show in [true, false]) {
        settings.setShowSumFocusedSupplementaryStats(show);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await expectLater(
          find.byKey(const ValueKey('month-focused-evidence')),
          matchesGoldenFile(
            '../../../goldens/balance_sum_focused_${p.name}_${show ? "stats" : "expanded"}.png',
          ),
        );
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'month-fixture',
  indexGeneration: 1,
  coreRevision: 1,
);
List<DashboardLedgerEntry> _entries(bool income, int year) => [
  for (var month = 1; month <= 12; month++)
    for (final day in income ? [1, 12, 20] : [3, 7, 12, 17, 24, 28])
      DashboardLedgerEntry(
        id: '${income ? 'i' : 'e'}-$year-$month-$day',
        categoryId: income ? 'income' : 'expense',
        partnerId: 'fixture',
        direction: income ? 'income' : 'expense',
        amountMinor:
            (income
                ? (day == 1 ? 90000 : 20000)
                : (day == 7
                      ? 110000
                      : day == 24
                      ? 26000
                      : 10000)) *
            100,
        bookedLocalEpochDay: LocalDate(
          year: year,
          month: month,
          day: day,
        ).epochDay,
        bookedLocalTimeMinutes: 600,
      ),
];
List<DashboardLedgerEntry> _scopeEntries(
  LedgerTimeScope scope,
  bool income,
  int year,
) {
  if (scope is MonthScope) return _entries(income, year);
  return [
    for (var month = 1; month <= 12; month++)
      DashboardLedgerEntry(
        id: '${income ? 'i' : 'e'}-$year-$month',
        categoryId: income ? 'income' : 'expense',
        partnerId: 'fixture',
        direction: income ? 'income' : 'expense',
        amountMinor: (income ? 300 + month * 20 : 470 - month * 10) * 100000,
        bookedLocalEpochDay: LocalDate(
          year: year,
          month: month,
          day: 12,
        ).epochDay,
        bookedLocalTimeMinutes: 600,
      ),
  ];
}

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
    incomeEntries: _scopeEntries(scope, true, year),
    expenseEntries: _scopeEntries(scope, false, year),
    logicalAsOfDate: const LocalDate(year: 2026, month: 6, day: 15),
  );
}

DashboardBalancePresentation _header(LedgerTimeScope scope) {
  final year = scope is YearScope ? scope.year : 2025;
  final income = _scopeEntries(scope, true, year);
  final expense = _scopeEntries(scope, false, year);
  final i = income.fold<int>(0, (v, e) => v + e.amountMinor);
  final e = expense.fold<int>(0, (v, e) => v + e.amountMinor);
  return DashboardBalancePresentation(
    scopeKey: 'month-fixture',
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
  theme: ThemeData(fontFamily: 'Inter'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: scope is MonthScope ? 390 : 412,
        height: scope is MonthScope ? 844 : 892,
        child: RepaintBoundary(
          key: const ValueKey('month-focused-evidence'),
          child: BalanceDashboardCoreSurface(
            presentation: DashboardCoreModePresentation(
              geometry: DashboardGeometryResolver.resolve(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  scope is MonthScope
                      ? const Size(390, 844)
                      : const Size(412, 892),
                ),
                mode: DashboardModeSpec.balance,
                collapseProgress:
                    DashboardLayoutMetrics.reference
                        .fitToViewport(
                          scope is MonthScope
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

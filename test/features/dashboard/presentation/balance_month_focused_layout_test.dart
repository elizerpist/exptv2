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
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_net_margin_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'BalanceMonthEvidence',
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

  for (final size in [
    const Size(280, 210),
    const Size(320, 230),
    const Size(390, 360),
  ]) {
    testWidgets('three monthly perspectives share bounded frame at $size', (
      tester,
    ) async {
      final source = _alternative();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'BalanceMonthEvidence'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: BalanceMonthFocusedLayout(presentation: source),
              ),
            ),
          ),
        ),
      );
      Rect? chartRect;
      for (final p in BalanceMonthPerspective.values) {
        await tester.tap(
          find.byKey(ValueKey('balance-month-perspective-${p.name}')),
        );
        await tester.pump();
        final chart = find.byKey(ValueKey('balance-month-chart-${p.name}'));
        expect(chart, findsOneWidget);
        chartRect ??= tester.getRect(chart);
        final rendered = tester.getRect(chart);
        // Text layout can change sub-ulp rounding while the physical frame is
        // identical; preserve a tolerance far below any display pixel.
        expect(rendered.left, closeTo(chartRect.left, 1e-9));
        expect(rendered.top, closeTo(chartRect.top, 1e-9));
        expect(rendered.right, closeTo(chartRect.right, 1e-9));
        expect(rendered.bottom, closeTo(chartRect.bottom, 1e-9));
        expect(find.text(p.subtitle), findsOneWidget);
        if (p == BalanceMonthPerspective.spendingLevel) {
          expect(find.byType(BalanceMonthNetMarginGauge), findsOneWidget);
        } else {
          final paint = tester.widget<CustomPaint>(
            find
                .descendant(of: chart, matching: find.byType(CustomPaint))
                .first,
          );
          final painter = paint.painter! as BalanceMonthFocusedChartPainter;
          expect(
            painter.presentation.sourcePresentationId,
            source.primary!.presentationId,
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'monthly layout starts focused and roundtrips through the explicit old renderer',
    (tester) async {
      const scope = MonthScope(YearMonth(year: 2025, month: 5));
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
      expect(find.byType(BalanceMonthFocusedLayout), findsOneWidget);
      settings.setMonthLayoutPresentation(
        BalanceMonthLayoutPresentation.current,
      );
      await tester.pump();
      expect(find.byType(BalanceAlternativeDailySpendCard), findsOneWidget);
      expect(find.byType(BalanceAlternativeSavingsRingCard), findsOneWidget);
      expect(
        find.byType(BalanceAlternativeIncomeExpenseStripCard),
        findsOneWidget,
      );
      final mother = tester.getRect(
        find.byKey(const ValueKey('balance-unified-header-content-surface')),
      );
      final oldBody = tester.getRect(
        find.byKey(const ValueKey('balance-alternative-month-layout')),
      );
      final oldHeader = tester
          .widget<Text>(find.byKey(const ValueKey('balance-header-net-amount')))
          .data;
      final originalData = linked.value;
      for (var cycle = 0; cycle < 2; cycle++) {
        settings.setMonthLayoutPresentation(
          BalanceMonthLayoutPresentation.focused,
        );
        await tester.pump();
        expect(find.byType(BalanceMonthFocusedLayout), findsOneWidget);
        expect(find.byType(BalanceAlternativeDailySpendCard), findsNothing);
        expect(find.byType(BalanceAlternativeSavingsRingCard), findsNothing);
        expect(
          find.byType(BalanceAlternativeIncomeExpenseStripCard),
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
        for (final p in BalanceMonthPerspective.values) {
          await tester.tap(
            find.byKey(ValueKey('balance-month-perspective-${p.name}')),
          );
          await tester.pump();
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('balance-header-net-amount')),
                )
                .data,
            oldHeader,
          );
          expect(linked.value, same(originalData));
          expect(tester.takeException(), isNull);
        }
        settings.setMonthLayoutPresentation(
          BalanceMonthLayoutPresentation.current,
        );
        await tester.pump();
        expect(find.byType(BalanceMonthFocusedLayout), findsNothing);
        expect(find.byType(BalanceAlternativeDailySpendCard), findsOneWidget);
        expect(
          tester.getRect(
            find.byKey(const ValueKey('balance-alternative-month-layout')),
          ),
          oldBody,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('monthly perspective survives header collapse lifecycle', (
    tester,
  ) async {
    const scope = MonthScope(YearMonth(year: 2025, month: 5));
    final settings = BalancePresentationController()
      ..setMonthLayoutPresentation(BalanceMonthLayoutPresentation.focused);
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _linked(scope),
    );
    final header = ValueNotifier<DashboardBalancePresentation?>(_header(scope));
    addTearDown(settings.dispose);
    addTearDown(linked.dispose);
    addTearDown(header.dispose);
    await tester.pumpWidget(_host(scope, settings, linked, header));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('balance-month-perspective-swings')),
    );
    await tester.pump();
    final focused = find.byType(BalanceMonthFocusedLayout);
    final element = tester.element(focused);
    final state = tester.state(focused);
    final prepared = linked.value;
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
        find.byKey(const ValueKey('balance-upper-carousel')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('balance-month-chart-swings')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final scope in <LedgerTimeScope>[
    const AllTimeScope(),
    const YearScope(2025),
    const DayScope(LocalDate(year: 2025, month: 5, day: 15)),
  ]) {
    testWidgets('month choice leaves ${scope.canonicalKey} pixels unchanged', (
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
      final surface = find.byKey(const ValueKey('month-focused-evidence'));
      final boundary = tester.renderObject<RenderRepaintBoundary>(surface);
      final before = await tester.runAsync(() => boundary.toImage());
      settings.setMonthLayoutPresentation(
        BalanceMonthLayoutPresentation.focused,
      );
      await tester.pump();
      expect(find.byType(BalanceMonthFocusedLayout), findsNothing);
      await expectLater(surface, matchesReferenceImage(before!));
      before.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('monthly trend and clay swings golden endpoints', (tester) async {
    const scope = MonthScope(YearMonth(year: 2025, month: 5));
    final settings = BalancePresentationController()
      ..setMonthLayoutPresentation(BalanceMonthLayoutPresentation.focused);
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _linked(scope),
    );
    final header = ValueNotifier<DashboardBalancePresentation?>(_header(scope));
    addTearDown(settings.dispose);
    addTearDown(linked.dispose);
    addTearDown(header.dispose);
    await tester.pumpWidget(_host(scope, settings, linked, header));
    await tester.pump();
    for (final p in [
      BalanceMonthPerspective.balanceTrend,
      BalanceMonthPerspective.swings,
    ]) {
      await tester.tap(
        find.byKey(ValueKey('balance-month-perspective-${p.name}')),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey('month-focused-evidence')),
        matchesGoldenFile(
          '../../../goldens/balance_month_focused_${p.name}.png',
        ),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

BalanceAlternativeMonthPresentation _alternative() =>
    BalanceAlternativeScopePresentation.fromLinked(
          _linked(const MonthScope(YearMonth(year: 2025, month: 5))),
        )
        as BalanceAlternativeMonthPresentation;
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
        amountMinor: (income ? 450 : 320) * 100000,
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
  theme: ThemeData(
    fontFamily: scope is MonthScope ? 'BalanceMonthEvidence' : 'Ahem',
  ),
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

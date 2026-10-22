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
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_bar.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_year_focused_chart_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_year_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'BalanceYearEvidence',
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

  test(
    'prepared geometry keeps net signs, neutral zero, twelve slots and a shared flow scale',
    () {
      final source = _alternative(const YearScope(2025));
      final data = _chart(source);
      final net = BalanceYearFocusedChartGeometry.resolve(
        const Size(340, 210),
        data,
        BalanceYearPerspective.monthlyNet,
      );
      expect(net.monthlyRects, hasLength(12));
      expect(net.monthlyRects[0]!.bottom, net.axis);
      expect(net.monthlyRects[1]!.top, net.axis);
      expect(net.monthlyRects[2]!.center.dy, net.axis);
      expect(net.monthlyRects[3], isNull);
      final flow = BalanceYearFocusedChartGeometry.resolve(
        const Size(340, 210),
        data,
        BalanceYearPerspective.incomeExpense,
      );
      expect(flow.incomeRects[2]!.height, flow.expenseRects[2]!.height);
      expect(
        flow.incomeRects[0]!.height / flow.expenseRects[0]!.height,
        closeTo(450 / 320, .0001),
      );
      expect(flow.barWidth * 2 + 2, lessThanOrEqualTo(flow.slot));
      final cumulative = BalanceYearFocusedChartGeometry.resolve(
        const Size(340, 210),
        data,
        BalanceYearPerspective.cumulativeNet,
      );
      expect(cumulative.cumulativePoints.first!.dy, cumulative.axis);
      expect(cumulative.cumulativePoints, hasLength(13));
      expect(data.months.last.cumulativeNetMinor, data.annualNetMinor);
      for (final point in cumulative.cumulativePoints.whereType<Offset>()) {
        expect(
          point.dy,
          inInclusiveRange(cumulative.plot.top, cumulative.plot.bottom),
        );
      }
    },
  );

  test(
    'future calendar slots do not create final cumulative closing points',
    () {
      final data = _chart(_alternative(const YearScope(2026)));
      final geometry = BalanceYearFocusedChartGeometry.resolve(
        const Size(290, 190),
        data,
        BalanceYearPerspective.cumulativeNet,
      );
      expect(data.months[6].isFuture, isTrue);
      expect(geometry.cumulativePoints[7], isNull);
      expect(data.closedMonthCount, 5);
    },
  );

  for (final size in [const Size(320, 230), const Size(390, 360)]) {
    testWidgets(
      'all three perspectives occupy one identical chart frame at $size',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'BalanceYearEvidence'),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: BalanceYearFocusedLayout(
                    presentation: _alternative(const YearScope(2025)),
                  ),
                ),
              ),
            ),
          ),
        );
        final initialRect = tester.getRect(
          find.byKey(const ValueKey('balance-year-focused-chart-boundary')),
        );
        for (final perspective in BalanceYearPerspective.values) {
          await tester.tap(
            find.byKey(
              ValueKey('balance-year-perspective-${perspective.name}'),
            ),
          );
          await tester.pump();
          expect(find.byType(BalanceYearFocusedLayout), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter is BalanceYearFocusedChartPainter,
            ),
            findsOneWidget,
          );
          expect(find.text(perspective.title), findsOneWidget);
          expect(
            tester.getRect(
              find.byKey(const ValueKey('balance-year-focused-chart-boundary')),
            ),
            initialRect,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byKey(const ValueKey('balance-year-month-2')));
        await tester.pump();
        if (size.height >= 240) {
          expect(
            find.byKey(const ValueKey('balance-year-focused-selected-month')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'year layout switches repeatedly without changing Mother Card or header snapshot',
    (tester) async {
      const scope = YearScope(2025);
      final settings = BalancePresentationController()
        ..setYearBarPresentation(BalanceYearBarPresentation.clay3d);
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(scope),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        _header(scope),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      addTearDown(balance.dispose);
      await tester.pumpWidget(_host(scope, settings, linked, balance));
      await tester.pump();
      expect(find.byType(BalanceAlternativeAnnualClosingsCard), findsOneWidget);
      expect(find.byType(BalanceAlternativeSavingsRingCard), findsOneWidget);
      expect(
        find.byType(BalanceAlternativeAnnualIncomeExpenseCard),
        findsOneWidget,
      );
      final header = tester
          .widget<Text>(find.byKey(const ValueKey('balance-header-net-amount')))
          .data;
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
      );
      final body = tester.getRect(
        find.byKey(const ValueKey('balance-alternative-year-layout')),
      );
      final beforeLinked = linked.value;
      final beforeHeader = balance.value;
      for (var cycle = 0; cycle < 2; cycle++) {
        settings.setYearLayoutPresentation(
          BalanceYearLayoutPresentation.focused,
        );
        await tester.pump();
        expect(find.byType(BalanceYearFocusedLayout), findsOneWidget);
        expect(find.byType(BalanceAlternativeAnnualClosingsCard), findsNothing);
        expect(find.byType(BalanceAlternativeSavingsRingCard), findsNothing);
        expect(
          find.byType(BalanceAlternativeAnnualIncomeExpenseCard),
          findsNothing,
        );
        final focusedBody = tester.getRect(
          find.byType(BalanceYearFocusedLayout),
        );
        expect(focusedBody.left, body.left);
        expect(focusedBody.right, body.right);
        expect(focusedBody.bottom, lessThanOrEqualTo(body.bottom));
        for (final perspective in BalanceYearPerspective.values) {
          await tester.tap(
            find.byKey(
              ValueKey('balance-year-perspective-${perspective.name}'),
            ),
          );
          await tester.pump();
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('balance-header-net-amount')),
                )
                .data,
            header,
          );
          expect(
            tester.getRect(
              find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
            ),
            headerRect,
          );
          expect(linked.value, same(beforeLinked));
          expect(balance.value, same(beforeHeader));
          expect(tester.takeException(), isNull);
        }
        settings.setYearLayoutPresentation(
          BalanceYearLayoutPresentation.current,
        );
        await tester.pump();
        expect(find.byType(BalanceYearFocusedLayout), findsNothing);
        expect(
          find.byType(BalanceAlternativeAnnualClosingsCard),
          findsOneWidget,
        );
        expect(
          settings.value.yearBarPresentation,
          BalanceYearBarPresentation.clay3d,
        );
        expect(
          tester.getRect(
            find.byKey(const ValueKey('balance-alternative-year-layout')),
          ),
          body,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final scope in <LedgerTimeScope>[
    const AllTimeScope(),
    const MonthScope(YearMonth(year: 2025, month: 5)),
    const DayScope(LocalDate(year: 2025, month: 5, day: 15)),
  ]) {
    testWidgets('year choice leaves ${scope.canonicalKey} content unchanged', (
      tester,
    ) async {
      final settings = BalancePresentationController();
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(scope),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        _header(scope),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      addTearDown(balance.dispose);
      await tester.pumpWidget(_host(scope, settings, linked, balance));
      await tester.pump();
      final surface = find.byKey(const ValueKey('year-focused-evidence'));
      final boundary = tester.renderObject<RenderRepaintBoundary>(surface);
      final before = await tester.runAsync(() => boundary.toImage());
      final data = linked.value;
      settings.setYearLayoutPresentation(BalanceYearLayoutPresentation.focused);
      await tester.pump();
      expect(find.byType(BalanceYearFocusedLayout), findsNothing);
      expect(linked.value, same(data));
      await expectLater(surface, matchesReferenceImage(before!));
      before.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'current year keeps future closes absent and current month selectable',
    (tester) async {
      const scope = YearScope(2026);
      final settings = BalancePresentationController()
        ..setYearLayoutPresentation(BalanceYearLayoutPresentation.focused);
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
      await tester.tap(
        find.byKey(const ValueKey('balance-year-perspective-cumulativeNet')),
      );
      await tester.pump();
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey(
                        'balance-year-focused-chart-cumulativeNet',
                      ),
                    ),
                  )
                  .painter!
              as BalanceYearFocusedChartPainter;
      expect(painter.geometry.cumulativePoints[7], isNull);
      expect(painter.presentation.closedMonthCount, 5);
      await tester.tap(find.byKey(const ValueKey('balance-year-month-6')));
      await tester.pump();
      expect(find.textContaining('Folyamatban'), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('year-focused-evidence')),
        matchesGoldenFile(
          '../../../goldens/balance_year_focused_current_cumulative.png',
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'focused annual surface golden endpoints and historical header remain aligned',
    (tester) async {
      const scope = YearScope(2025);
      final settings = BalancePresentationController()
        ..setYearLayoutPresentation(BalanceYearLayoutPresentation.focused);
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(scope),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        _header(scope),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      addTearDown(balance.dispose);
      await tester.pumpWidget(_host(scope, settings, linked, balance));
      await tester.pump();
      final headerBar = tester.widget<BalanceHeaderGlassBar>(
        find.byType(BalanceHeaderGlassBar),
      );
      final data = _chart(_alternative(scope));
      expect(headerBar.incomeMinor, data.annualIncomeMinor);
      expect(headerBar.expenseMinor, data.annualExpenseMinor);
      for (final perspective in BalanceYearPerspective.values) {
        await tester.tap(
          find.byKey(ValueKey('balance-year-perspective-${perspective.name}')),
        );
        await tester.pump();
        await expectLater(
          find.byKey(const ValueKey('year-focused-evidence')),
          matchesGoldenFile(
            '../../../goldens/balance_year_focused_${perspective.name}.png',
          ),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

BalanceYearFocusedChartPresentation _chart(
  BalanceAlternativeYearPresentation source,
) => BalanceYearFocusedChartPresentation.fromIncomeExpense(
  source.incomeExpense,
  year: (source.timeScope as YearScope).year,
  logicalAsOfDate: source.logicalAsOfDate,
  transactionCounts: source.transactionCounts,
);
BalanceAlternativeYearPresentation _alternative(YearScope scope) =>
    BalanceAlternativeScopePresentation.fromLinked(_linked(scope))
        as BalanceAlternativeYearPresentation;
const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'year-fixture',
  indexGeneration: 1,
  coreRevision: 1,
);
List<DashboardLedgerEntry> _entries(bool income, int year) => [
  for (var month = 1; month <= (year == 2026 ? 6 : 12); month++)
    if (month != 4)
      DashboardLedgerEntry(
        id: '${income ? 'i' : 'e'}-$year-$month',
        categoryId: income ? 'income' : 'expense',
        partnerId: 'fixture',
        direction: income ? 'income' : 'expense',
        amountMinor:
            (income
                ? (month == 3 ? 200 : 450)
                : (month == 2
                      ? 610
                      : month == 3
                      ? 200
                      : 320)) *
            100000,
        bookedLocalEpochDay: LocalDate(
          year: year,
          month: month,
          day: 12,
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
    incomeEntries: scope is AllTimeScope ? const [] : _entries(true, year),
    expenseEntries: scope is AllTimeScope ? const [] : _entries(false, year),
    logicalAsOfDate: const LocalDate(year: 2026, month: 6, day: 15),
  );
}

DashboardBalancePresentation _header(LedgerTimeScope scope) {
  final year = scope is YearScope ? scope.year : 2025;
  final income = scope is AllTimeScope
      ? <DashboardLedgerEntry>[]
      : _entries(true, year);
  final expense = scope is AllTimeScope
      ? <DashboardLedgerEntry>[]
      : _entries(false, year);
  final i = income.fold<int>(0, (v, e) => v + e.amountMinor);
  final e = expense.fold<int>(0, (v, e) => v + e.amountMinor);
  return DashboardBalancePresentation(
    scopeKey: 'year-fixture',
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
  ValueNotifier<DashboardBalancePresentation?> header,
) => MaterialApp(
  theme: ThemeData(
    fontFamily: scope is YearScope ? 'BalanceYearEvidence' : 'Ahem',
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: scope is YearScope ? 390 : 412,
        height: scope is YearScope ? 844 : 892,
        child: RepaintBoundary(
          key: const ValueKey('year-focused-evidence'),
          child: BalanceDashboardCoreSurface(
            presentation: DashboardCoreModePresentation(
              geometry: DashboardGeometryResolver.resolve(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  scope is YearScope
                      ? const Size(390, 844)
                      : const Size(412, 892),
                ),
                mode: DashboardModeSpec.balance,
                collapseProgress: 0,
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

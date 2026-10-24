import '../../../support/mother_card_raster_comparator.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/balance_daily_calculation_mode.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_bar.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_entity_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_configuration.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final originalComparator = goldenFileComparator;
  setUpAll(() {
    if (originalComparator is LocalFileComparator) {
      goldenFileComparator = MotherCardRasterComparator(
        originalComparator.basedir.resolve(
          'balance_dashboard_core_surface_test.dart',
        ),
      );
    }
  });
  tearDownAll(() => goldenFileComparator = originalComparator);

  // Keep retained financial/header assertions deterministic under reduced motion.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets(
    'Balance Header foreground frame changes text without balance data work',
    (tester) async {
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      final frame = ValueNotifier<DashboardHeaderVisualFrame>(
        const DashboardHeaderVisualFrame(
          colors: <Color>[Colors.red, Colors.red],
          stops: <double>[0, 1],
          opacity: 1,
          colorA: Colors.red,
          colorB: Colors.red,
          foregroundTextColor: Colors.black,
          chartColor: Colors.white,
        ),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'balance|all',
          coreRevision: 1,
          incomeTotalMinor: 120000,
          expenseTotalMinor: 20000,
          netTotalMinor: 100000,
          formattedNetTotal: '1 000 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'latest',
            title: 'Teszt',
            formattedAmount: '1 000 Ft',
            direction: LedgerDirection.income,
            occurredOrder: 1,
          ),
        ),
      );
      final mode = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: mode,
              balancePresentation: balance,
              headerVisualController: visual,
              headerVisualFrame: frame,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .color,
        Colors.black,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .fontFamily,
        'Roboto',
      );
      final before = balance.value;
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Colors.white,
        chartColor: Colors.black,
      );
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .color,
        Colors.white,
      );
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Color(0xD114213A),
        chartColor: Colors.black,
        typography: FluviTypographyProfile.colorLab,
      );
      await tester.pump();
      final colorLabAmount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(colorLabAmount.style!.color, const Color(0xD114213A));
      expect(colorLabAmount.style!.fontFamily, 'FluviColorLabInter');
      final headerBeforeModeLabel = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-header'),
        ),
      );
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Color(0xD114213A),
        chartColor: Colors.black,
        typography: FluviTypographyProfile.colorLab,
        showsHeaderModeLabelAboveValue: true,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-header-mode-label')),
        findsOneWidget,
      );
      final balanceAmountTop = tester.getTopLeft(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(
        balanceAmountTop.dy,
        closeTo(
          headerBeforeModeLabel.top +
              DashboardHeaderTrendChartStyle.detailTop +
              DashboardHeaderTrendChartLayout.modeLabelReserve,
          .01,
        ),
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('dashboard-core-mode-balance-header'),
          ),
        ),
        headerBeforeModeLabel,
      );
      expect(balance.value, same(before));
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
      frame.dispose();
      balance.dispose();
    },
  );

  testWidgets(
    'daily calculation changes amount and bar atomically without navigation or lower data changes',
    (tester) async {
      await (FontLoader('BalanceHeaderEvidence')
            ..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf')))
          .load();
      final selected = DayScope(const LocalDate(year: 2024, month: 2, day: 15));
      final earlier = const LocalDate(year: 2024, month: 1, day: 1).epochDay;
      final current = const LocalDate(year: 2024, month: 2, day: 12).epochDay;
      final source = DashboardBalancePresentation(
        scopeKey: 'q',
        coreRevision: 1,
        incomeTotalMinor: 50000,
        expenseTotalMinor: 10000,
        netTotalMinor: 40000,
        formattedNetTotal: '400 Ft',
        presentationId: 1,
        headerTimeScope: selected,
        history: DashboardBalanceHistorySeries(
          startInclusiveEpochMinute: earlier * 1440,
          endInclusiveEpochMinute: current * 1440,
          points: [
            DashboardBalanceHistoryPoint(
              entryId: 'a',
              epochDay: earlier,
              epochMinute: earlier * 1440,
              incomeTotalMinor: 20000,
              expenseTotalMinor: 5000,
              balanceMinor: 15000,
            ),
            DashboardBalanceHistoryPoint(
              entryId: 'b',
              epochDay: current,
              epochMinute: current * 1440,
              incomeTotalMinor: 50000,
              expenseTotalMinor: 10000,
              balanceMinor: 40000,
            ),
          ],
        ),
      );
      final data = ValueNotifier<DashboardBalancePresentation?>(source);
      final settings = BalancePresentationController();
      addTearDown(data.dispose);
      addTearDown(settings.dispose);
      final mode = _balanceModePresentation();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'BalanceHeaderEvidence'),
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: mode,
              balancePresentation: data,
              presentationSettings: settings,
              adaptiveScope: selected,
            ),
          ),
        ),
      );
      await tester.pump();
      Text amount() => tester.widget<Text>(
        find.byKey(const ValueKey('balance-header-net-amount')),
      );
      BalanceHeaderGlassBar bar() => tester.widget<BalanceHeaderGlassBar>(
        find.byType(BalanceHeaderGlassBar),
      );
      expect(amount().data, '+250 Ft');
      expect(bar().incomeMinor, 30000);
      expect(bar().expenseMinor, 5000);
      await expectLater(
        find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
        matchesGoldenFile(
          '../../../goldens/balance_header_context_month_to_date.png',
        ),
      );
      final rect = tester.getRect(
        find.byKey(const ValueKey('balance-header-net-amount')),
      );
      settings.setDailyCalculationMode(
        BalanceDailyCalculationMode.allTimeToDate,
      );
      await tester.pump();
      expect(amount().data, '+400 Ft');
      await expectLater(
        find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
        matchesGoldenFile(
          '../../../goldens/balance_header_context_all_time_to_date.png',
        ),
      );
      expect(bar().incomeMinor, 50000);
      expect(bar().expenseMinor, 10000);
      expect(data.value, same(source));
      expect(data.value!.headerTimeScope, selected);
      expect(
        tester.getRect(find.byKey(const ValueKey('balance-header-net-amount'))),
        rect,
      );
      settings.setDailyCalculationMode(BalanceDailyCalculationMode.monthToDate);
      await tester.pump();
      expect(amount().data, '+250 Ft');
      expect(bar().incomeMinor, 30000);
      settings.setHeaderGraphPresentation(
        BalanceHeaderGraphPresentation.lineChart,
      );
      await tester.pump();
      expect(amount().data, '+250 Ft');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'BGF-10: expanded partition mounts one glass body while line and collapsed endpoints mount none',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      final settings = ValueNotifier<BalancePresentationSettings>(
        const BalancePresentationSettings.defaults().copyWith(
          headerGraphPresentation:
              BalanceHeaderGraphPresentation.incomeExpensePartition,
          headerGlassConfiguration: BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
          ),
          revision: 1,
        ),
      );
      addTearDown(balance.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balancePresentation: balance,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
        findsOneWidget,
      );
      expect(find.byType(BackdropFilter), findsOneWidget);

      settings.value = settings.value.copyWith(
        headerGraphPresentation: BalanceHeaderGraphPresentation.lineChart,
        revision: 2,
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
        findsNothing,
      );
      expect(find.byType(BackdropFilter), findsNothing);

      settings.value = settings.value.copyWith(
        headerGraphPresentation:
            BalanceHeaderGraphPresentation.incomeExpensePartition,
        revision: 3,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(collapseFraction: 1),
              balancePresentation: balance,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
        findsNothing,
      );
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );

  testWidgets(
    'Balance simple income-expense header visual mounts the neutral one-fill lane without a glass tree',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      final settings = ValueNotifier<BalancePresentationSettings>(
        const BalancePresentationSettings.defaults().copyWith(
          headerGraphPresentation:
              BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
          revision: 1,
        ),
      );
      addTearDown(balance.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balancePresentation: balance,
              presentationSettings: settings,
            ),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('balance-header-income-expense-empty-track'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'BALDEFAULT-02: an unconfigured Balance surface mounts the continuous four-child composition',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-unified-header-content-surface'),
        ),
        findsOneWidget,
      );
      for (final key in <String>[
        'balance-tetris-card-3',
        'balance-tetris-card-4',
        'balance-tetris-card-5',
        'balance-tetris-card-combined',
      ]) {
        expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
      }
    },
  );

  testWidgets(
    'BAL-SAVINGS-UNIFIED-RED: Year and Month replace the two narrow right slots with one readable savings card',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(cashflow: _alternativeYearCashflow()),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-savings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-4')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-5')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-savings-percentage'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-savings-amount'),
        ),
        findsOneWidget,
      );

      linked.value = _linked(cashflow: _alternativeMonthCashflow());
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-savings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-4')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-5')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-savings-budget-3d'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ALT2-04/06: SUM, Year, Havi 2 and Napi 4 resolve their source-owned extended-sheet bodies',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(cashflow: _alternativeYearCashflow()),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('balance-alternative-year-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-savings')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-plot-scroll'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-closings-plot'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-alternative-year-income-expense-bars',
          ),
        ),
        findsOneWidget,
      );

      linked.value = _linked(cashflow: _alternativeMonthCashflow());
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-savings')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-month-daily-spend-plot'),
        ),
        findsOneWidget,
      );
      for (final chart in BalanceMonthlySpendingChartPresentation.values) {
        settings.setMonthlySpendingChartPresentation(chart);
        await tester.pump();
        expect(settings.value.monthlySpendingChartPresentation, chart);
        expect(
          tester
              .widget<BalanceAlternativeDailySpendCard>(
                find.byType(BalanceAlternativeDailySpendCard),
              )
              .chartPresentation,
          chart,
          reason:
              'The real month scaffold must receive the live settings value '
              'before its renderer is selected.',
        );
        final terrainStyleName = switch (chart) {
          BalanceMonthlySpendingChartPresentation.current => null,
          BalanceMonthlySpendingChartPresentation.topographic => 'terrain',
          BalanceMonthlySpendingChartPresentation.reactiveSvg => 'svgReference',
          BalanceMonthlySpendingChartPresentation.shaderAtmosphere =>
            'shaderAtmosphere',
        };
        expect(
          find.byKey(
            ValueKey<String>('balance-monthly-spending-wave-$terrainStyleName'),
          ),
          chart == BalanceMonthlySpendingChartPresentation.current
              ? findsNothing
              : findsOneWidget,
          reason:
              'Only the production Month → Költés child card may mount '
              'the selected additive terrain renderer.',
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'balance-alternative-month-daily-spend-plot',
            ),
          ),
          chart == BalanceMonthlySpendingChartPresentation.current
              ? findsOneWidget
              : findsNothing,
        );
      }

      linked.value = _linked(cashflow: _alternativeDayCashflow());
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-savings')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-alternative-day-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-daily-impact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-combined')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-monthly-spending-wave-shaderAtmosphere',
          ),
        ),
        findsNothing,
        reason: 'A persisted monthly chart choice cannot leak to the Day body.',
      );
    },
  );

  testWidgets(
    'BALANCE-CHILD-CARDS-02 RED: Napi4 retains its live four-card content when child shells are toggled off',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(cashflow: _alternativeDayCashflow()),
      );
      final settings = BalancePresentationController()
        ..setUsesChildCards(false);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('balance-tetris-card-daily-impact')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('balance-tetris-card-combined')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('balance-alternative-child-card-shell')),
        findsNothing,
      );

      settings.setUsesChildCards(true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('balance-alternative-child-card-shell')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SHEET-01/02: 412×892 Havi 2 and Éves cards use direct HTML-scale content instead of a card-wide fallback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _richAlternativeMonthLinked(),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      final metrics = DashboardLayoutMetrics.reference.fitToViewport(
        const Size(412, 892),
      );
      final mode = _balanceModePresentation(
        metrics: metrics,
        hasPhysicalRail: false,
      );

      Future<void> pumpSurface() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('balance-alternative-sheet-golden'),
              child: SizedBox.expand(
                child: BalanceDashboardCoreSurface(
                  presentation: mode,
                  balanceLinkedPresentation: linked,
                  presentationSettings: settings,
                ),
              ),
            ),
          ),
        ),
      );

      Finder cardWideFallback() => find.byWidgetPredicate((widget) {
        if (widget is! FittedBox || widget.fit != BoxFit.contain) {
          return false;
        }
        final child = widget.child;
        return child is SizedBox && child.width != null && child.height != null;
      });

      await pumpSurface();
      await tester.pump();
      final canonicalMother = DashboardHeaderContentMotherCardBounds.resolve(
        geometry: _balanceModePresentation(
          metrics: metrics,
          hasPhysicalRail: false,
        ).geometry,
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-unified-header-content-surface'),
          ),
        ),
        Rect.fromLTWH(
          canonicalMother.left,
          canonicalMother.top,
          canonicalMother.width,
          canonicalMother.height,
        ),
        reason: 'Havi 2 uses the Balance SUM Mother Card frame.',
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-month-daily-spend-plot'),
        ),
        findsOneWidget,
      );
      for (final element in cardWideFallback().evaluate()) {
        final fitted = element.widget as FittedBox;
        final authored = fitted.child! as SizedBox;
        final viewport = (element.renderObject! as RenderBox).size;
        expect(
          viewport,
          Size(authored.width!, authored.height!),
          reason:
              'At the reference viewport the stable responsive canvas is an identity mapping.',
        );
      }
      _expectHtmlCardSurfaceSizes(tester);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-alternative-sheet-golden')),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_havi2_surface.png',
        ),
      );

      linked.value = _richAlternativeYearLinked();
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-closings-plot'),
        ),
        findsOneWidget,
      );
      for (final element in cardWideFallback().evaluate()) {
        final authored = (element.widget as FittedBox).child! as SizedBox;
        expect(
          (element.renderObject! as RenderBox).size,
          Size(authored.width!, authored.height!),
          reason:
              'The yearly canvas retains authored type and plot dimensions.',
        );
      }
      _expectHtmlCardSurfaceSizes(tester);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-alternative-sheet-golden')),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_eves_surface.png',
        ),
      );
    },
  );

  test(
    'BX5 RED: Closings compact fraction uses strict-positive bucket DTOs',
    () {
      final summary = balanceClosingsCompactSummary(
        DashboardBalanceClosingsPresentation(
          identity: const DashboardBalancePrimaryIdentity(
            upstreamScopeKey: 'closings',
            indexGeneration: 1,
            coreRevision: 1,
          ),
          timeScope: const YearScope(2026),
          buckets: const <DashboardBalanceClosingBucket>[
            DashboardBalanceClosingBucket(
              id: 'one',
              label: 'JAN',
              incomeMinor: 100,
              expenseMinor: 0,
            ),
            DashboardBalanceClosingBucket(
              id: 'two',
              label: 'FEB',
              incomeMinor: 0,
              expenseMinor: 0,
            ),
            DashboardBalanceClosingBucket(
              id: 'three',
              label: 'MÁR',
              incomeMinor: 0,
              expenseMinor: 30,
            ),
            DashboardBalanceClosingBucket(
              id: 'four',
              label: 'ÁPR',
              incomeMinor: 80,
              expenseMinor: 0,
            ),
          ],
        ),
      );
      expect(summary, '2 / 12 hónap pluszos');

      final empty = DashboardBalanceClosingsPresentation(
        identity: const DashboardBalancePrimaryIdentity(
          upstreamScopeKey: 'empty-closings',
          indexGeneration: 1,
          coreRevision: 1,
        ),
        timeScope: const AllTimeScope(),
        buckets: const <DashboardBalanceClosingBucket>[],
      );
      expect(balanceClosingsCompactSummary(empty), 'Nincs adat');
    },
  );

  testWidgets(
    'BALANCE-HEADER-VISIBILITY RED: prepared net uses the canonical on-dark Header foreground',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all',
          coreRevision: 7,
          incomeTotalMinor: 150000,
          expenseTotalMinor: 210000,
          netTotalMinor: -60000,
          formattedNetTotal: '-600 Ft',
          presentationId: 1,
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(amount.data, '-600 Ft');
      expect(amount.style?.color, FluviVisualTokens.textOnAction);
      expect(
        amount.style?.color,
        isNot(modePresentation.palette.upcomingHeaderTone),
        reason: 'Widget presence alone is not evidence of visible contrast.',
      );

      balance.value = balance.value!.copyWith(
        netTotalMinor: 60000,
        formattedNetTotal: '600 Ft',
        presentationId: 2,
      );
      await tester.pump();
      expect(find.text('600 Ft'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style
            ?.color,
        FluviVisualTokens.textOnAction,
      );
    },
  );

  testWidgets(
    'BALANCE-HEADER-HISTORY RED: all-time amount shares Mind anchor and expanded trend geometry',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        DashboardBalancePresentation(
          scopeKey: 'income|all|expense|all',
          coreRevision: 7,
          incomeTotalMinor: 1000000,
          expenseTotalMinor: 400000,
          netTotalMinor: 600000,
          formattedNetTotal: '6 000 Ft',
          presentationId: 7,
          history: DashboardBalanceHistorySeries(
            startInclusiveEpochMinute: 20000 * 1440,
            endInclusiveEpochMinute: 20620 * 1440,
            points: const <DashboardBalanceHistoryPoint>[
              DashboardBalanceHistoryPoint(
                entryId: 'first',
                epochDay: 20000,
                epochMinute: 20000 * 1440,
                incomeTotalMinor: 1000000,
                expenseTotalMinor: 0,
                balanceMinor: 1000000,
              ),
              DashboardBalanceHistoryPoint(
                entryId: 'last',
                epochDay: 20620,
                epochMinute: 20620 * 1440,
                incomeTotalMinor: 1000000,
                expenseTotalMinor: 400000,
                balanceMinor: 600000,
              ),
            ],
          ),
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
              presentationSettings: ValueNotifier(
                const BalancePresentationSettings.defaults().copyWith(
                  headerGraphPresentation:
                      BalanceHeaderGraphPresentation.lineChart,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final header = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-header'),
        ),
      );
      final amount = tester.getTopLeft(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(
        amount.dx,
        closeTo(header.left + DashboardHeaderTrendChartStyle.detailLeft, .01),
      );
      expect(
        amount.dy,
        closeTo(header.top + DashboardHeaderTrendChartStyle.detailTop, .01),
      );
      final balanceAmount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(balanceAmount.style?.fontSize, 19);
      expect(balanceAmount.style?.height, .96);
      expect(balanceAmount.style?.letterSpacing, -.76);
      expect(balanceAmount.style?.fontWeight, FontWeight.w900);

      expect(
        tester
            .widget<BalanceHeaderHistoryChart>(
              find.byType(BalanceHeaderHistoryChart),
            )
            .showTimeLabels,
        isFalse,
      );

      final plot = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-paint'),
        ),
      );
      expect(
        tester
            .widget<CustomPaint>(
              find.byKey(
                const ValueKey<String>('balance-header-history-chart-paint'),
              ),
            )
            .painter,
        isA<DashboardHeaderTrendPainter>(),
        reason:
            'The rejected terrain experiment belongs only in the monthly '
            'Költés card; the Header keeps its established trend painter.',
      );
      expect(plot.left, closeTo(header.left + 16, .01));
      expect(plot.top, closeTo(header.top + 48, .01));
      expect(plot.width, 346);
      expect(plot.height, 60);
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('balance-header-history-chart-reveal'),
              ),
            )
            .height,
        60,
      );
    },
  );

  testWidgets(
    'per-scope content switches retain the one physical Mother Card',
    (tester) async {
      final settings = BalancePresentationController();
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _richAlternativeMonthLinked(),
      );
      addTearDown(settings.dispose);
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();
      final mother = find.byKey(
        const ValueKey('balance-unified-header-content-surface'),
      );
      final identity = tester.renderObject(mother);
      for (final layout in [
        BalanceMonthLayoutPresentation.focused,
        BalanceMonthLayoutPresentation.current,
        BalanceMonthLayoutPresentation.focused,
      ]) {
        settings.setMonthLayoutPresentation(layout);
        await tester.pump();
        expect(tester.renderObject(mother), same(identity));
        expect(
          find.byKey(
            ValueKey(
              layout == BalanceMonthLayoutPresentation.focused
                  ? 'balance-month-focused-layout'
                  : 'balance-alternative-month-layout',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('balance-carousel')), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Balance continuous detachment visual milestones', (
    tester,
  ) async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await tester.binding.setSurfaceSize(const Size(412, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      _richAlternativeMonthLinked(),
    );
    addTearDown(linked.dispose);
    final balance = ValueNotifier<DashboardBalancePresentation?>(
      const DashboardBalancePresentation(
        scopeKey: 'balance|2026-08',
        coreRevision: 7,
        incomeTotalMinor: 500000,
        expenseTotalMinor: 200000,
        netTotalMinor: 300000,
        formattedNetTotal: '3 000 Ft',
        presentationId: 7,
      ),
    );
    addTearDown(balance.dispose);
    Rect? initialPartition, initialAmount;
    double? partitionDelta, amountDelta;
    for (final state in [
      (0.0, 'expanded'),
      (.1, 'first_frame'),
      (9.0, 'early'),
      (90.0, 'half'),
      (171.0, 'near_collapsed'),
      (180.0, 'collapsed'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            backgroundColor: const Color(0xffe9edf6),
            body: RepaintBoundary(
              key: const ValueKey('balance-detachment-scene'),
              child: Container(
                color: const Color(0xffe9edf6),
                width: double.infinity,
                height: double.infinity,
                child: BalanceDashboardCoreSurface(
                  presentation: _balanceModePresentation(
                    hasPhysicalRail: false,
                    collapseFraction: state.$1 / 180,
                  ),
                  balancePresentation: balance,
                  balanceLinkedPresentation: linked,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final partition = state.$1 < 1
          ? tester.getRect(
              find.byKey(
                const ValueKey('balance-header-income-expense-partition'),
              ),
            )
          : initialPartition!;
      final amount = tester.getRect(
        find.byKey(const ValueKey('balance-header-net-amount')),
      );
      initialPartition ??= partition;
      initialAmount ??= amount;
      if (state.$1 == .1) {
        partitionDelta = (partition.top - initialPartition.top).abs();
        amountDelta = (amount.top - initialAmount.top).abs();
      }
      await expectLater(
        find.byKey(const ValueKey('balance-detachment-scene')),
        matchesGoldenFile(
          '../../../goldens/balance_unified_detachment_${state.$2}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }
    expect(
      partitionDelta,
      lessThan(1),
      reason:
          'Partition Header geometry is continuous at the first swipe frame.',
    );
    expect(
      amountDelta,
      lessThan(1),
      reason:
          'Header primary amount retains its position at the first swipe frame.',
    );
  });

  for (final viewport in [const Size(412, 892), const Size(280, 620)]) {
    for (final focused in [false, true]) {
      for (final scope in ['sum', 'year', 'month', 'day']) {
        testWidgets(
          'canonical $scope focused=$focused survives collapse and reversal at $viewport',
          (tester) async {
            await tester.binding.setSurfaceSize(viewport);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final settings = BalancePresentationController()
              ..setSumLayoutPresentation(
                focused
                    ? BalanceSumLayoutPresentation.focused
                    : BalanceSumLayoutPresentation.current,
              )
              ..setYearLayoutPresentation(
                focused
                    ? BalanceYearLayoutPresentation.focused
                    : BalanceYearLayoutPresentation.current,
              )
              ..setMonthLayoutPresentation(
                focused
                    ? BalanceMonthLayoutPresentation.focused
                    : BalanceMonthLayoutPresentation.current,
              )
              ..setDayLayoutPresentation(
                focused
                    ? BalanceDayLayoutPresentation.focused
                    : BalanceDayLayoutPresentation.current,
              );
            final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
              switch (scope) {
                'year' => _linked(cashflow: _alternativeYearCashflow()),
                'month' => _richAlternativeMonthLinked(),
                'day' => _linked(cashflow: _alternativeDayCashflow()),
                _ => _linked(),
              },
            );
            addTearDown(settings.dispose);
            addTearDown(linked.dispose);
            final metrics = DashboardLayoutMetrics.reference.fitToViewport(
              viewport,
            );
            Element? analyticalElement;
            RenderObject? motherRender;
            double? initialRelativeTop;
            for (final fraction in [
              0.0,
              .1 / 180,
              .5 / 180,
              1 / 180,
              3 / 180,
              .05,
              .1,
              .2,
              .35,
              .1,
              .7,
              .8,
              .95,
              1.0,
              .5,
              0.0,
            ]) {
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: BalanceDashboardCoreSurface(
                      presentation: _balanceModePresentation(
                        metrics: metrics,
                        hasPhysicalRail: false,
                        collapseFraction: fraction,
                      ),
                      balanceLinkedPresentation: linked,
                      presentationSettings: settings,
                    ),
                  ),
                ),
              );
              await tester.pump();
              final analytical = find.byKey(
                ValueKey<String>(
                  focused
                      ? 'balance-$scope-focused-layout'
                      : 'balance-alternative-$scope-layout',
                ),
                skipOffstage: false,
              );
              expect(
                analytical,
                findsOneWidget,
                reason:
                    'The accepted scope subtree must stay mounted at $fraction.',
              );
              analyticalElement ??= tester.element(analytical);
              expect(tester.element(analytical), same(analyticalElement));
              final mother = find.byKey(
                const ValueKey('balance-unified-header-content-surface'),
                skipOffstage: false,
              );
              motherRender ??= tester.renderObject(mother);
              expect(tester.renderObject(mother), same(motherRender));
              for (final retired in [
                'balance-carousel',
                'balance-carousel-viewport',
                'balance-primary-card',
              ]) {
                expect(
                  find.byKey(ValueKey(retired), skipOffstage: false),
                  findsNothing,
                );
              }
              final physicalBody = find.byKey(
                const ValueKey('balance-unified-moving-body'),
                skipOffstage: false,
              );
              final relativeTop =
                  tester.getRect(analytical).top -
                  tester.getRect(physicalBody).top;
              initialRelativeTop ??= relativeTop;
              if (fraction == .35) {
                expect(
                  (relativeTop - initialRelativeTop).abs(),
                  greaterThan(.5),
                  reason:
                      'The live chart slides relative to its physical Mother Card.',
                );
              }
              final header = tester.widget<DashboardCoreModeHeaderScaffold>(
                find.byType(DashboardCoreModeHeaderScaffold),
              );
              expect(header.depthProgress, closeTo(fraction, 1e-8));
              expect(header.borderProgress, closeTo(fraction, 1e-8));
              if (fraction > .02) {
                expect(
                  tester
                      .widgetList<IgnorePointer>(
                        find.ancestor(
                          of: analytical,
                          matching: find.byType(IgnorePointer),
                        ),
                      )
                      .any((widget) => widget.ignoring),
                  isTrue,
                  reason:
                      'Hidden transformed analytical content cannot intercept gestures.',
                );
              }
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
}

void _expectHtmlCardSurfaceSizes(WidgetTester tester) {
  final mother = tester.getRect(
    find.byKey(
      const ValueKey<String>('balance-unified-header-content-surface'),
    ),
  );
  for (final key in <String>[
    'balance-tetris-card-3',
    'balance-tetris-card-savings',
    'balance-tetris-card-combined',
  ]) {
    final actual = tester.getRect(find.byKey(ValueKey<String>(key)));
    expect(actual.width, greaterThan(0), reason: '$key has positive width');
    expect(actual.height, greaterThan(0), reason: '$key has positive height');
    expect(actual.left, greaterThanOrEqualTo(mother.left));
    expect(actual.top, greaterThanOrEqualTo(mother.top));
    expect(actual.right, lessThanOrEqualTo(mother.right));
    expect(actual.bottom, lessThanOrEqualTo(mother.bottom));
  }
}

DashboardCoreModePresentation _balanceModePresentation({
  DashboardLayoutMetrics? metrics,
  double principalModeContentExtraHeight = 0,
  bool hasPhysicalRail = true,
  double collapseFraction = 0,
}) {
  final resolvedMetrics =
      metrics ??
      DashboardLayoutMetrics.reference.fitToViewport(const Size(412, 892));
  return DashboardCoreModePresentation(
    geometry: DashboardGeometryResolver.resolve(
      metrics: resolvedMetrics,
      mode: DashboardModeSpec.balance,
      collapseProgress: resolvedMetrics.collapseTravel * collapseFraction,
      isRailExpanded: false,
      hasPhysicalRail: hasPhysicalRail,
      principalModeContentExtraHeight: principalModeContentExtraHeight,
    ),
    palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.balance),
  );
}

DashboardBalancePresentation _balance() => const DashboardBalancePresentation(
  scopeKey: 'income|all|expense|all',
  coreRevision: 7,
  incomeTotalMinor: 1000000,
  expenseTotalMinor: 400000,
  netTotalMinor: 600000,
  formattedNetTotal: '6 000 Ft',
  presentationId: 7,
  latestTransaction: DashboardBalanceLatestTransactionPresentation(
    entryId: 'latest',
    title: 'Latest',
    formattedAmount: '100 Ft',
    direction: LedgerDirection.income,
    occurredOrder: 1,
  ),
);

DashboardBalanceLinkedPresentation _linked({
  DashboardBalancePrimaryPresentation? cashflow,
  DashboardBalanceClosingsPresentation? closings,
  DashboardBalanceRetentionPresentation? retention,
  DashboardBalanceCategoryMoversPresentation? categoryMovers,
  List<DashboardBalanceRankedItem>? topCategories,
}) {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 3,
    coreRevision: 7,
  );
  return DashboardBalanceLinkedPresentation(
    identity: identity,
    timeScope: cashflow?.timeScope ?? const AllTimeScope(),
    selectedDirection: LedgerDirection.income,
    cashflow:
        cashflow ??
        DashboardBalancePrimaryPresentation(
          identity: identity,
          timeScope: const AllTimeScope(),
          mode: DashboardBalancePrimaryMode.sum,
          incomeTotalMinor: 700000,
          expenseTotalMinor: 400000,
          periodPairs: const <DashboardBalancePrimaryPeriodPair>[
            DashboardBalancePrimaryPeriodPair(
              value: 2025,
              incomeMinor: 300000,
              expenseMinor: 200000,
            ),
            DashboardBalancePrimaryPeriodPair(
              value: 2026,
              incomeMinor: 400000,
              expenseMinor: 200000,
            ),
          ],
          dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
        ),
    latestTransactions: const <DashboardBalanceScopedTransaction>[
      DashboardBalanceScopedTransaction(
        entryId: 'latest-in-scope',
        title: 'Piac',
        categoryTitle: 'Élelmiszer',
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
        amountMinor: 35000,
        direction: LedgerDirection.expense,
        occurredOrder: 20632 * 1440,
        epochDay: 20632,
        localTimeMinutes: 12 * 60,
      ),
    ],
    topCategories:
        topCategories ??
        const <DashboardBalanceRankedItem>[
          DashboardBalanceRankedItem(
            id: 'salary',
            label: 'Fizetés',
            direction: LedgerDirection.income,
            amountMinor: 700000,
            transactionCount: 2,
            categoryColorId: 'color_07',
            categoryIconId: 'icon_17',
          ),
        ],
    topPartners: const <DashboardBalanceRankedItem>[
      DashboardBalanceRankedItem(
        id: 'employer',
        label: 'Munkahely',
        direction: LedgerDirection.income,
        amountMinor: 700000,
        transactionCount: 2,
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
      ),
    ],
    categoryMovers: categoryMovers,
    closings: closings,
    retention: retention,
    categoryInsights: <String, DashboardBalanceCategoryInsight>{
      'salary': _salaryCategoryInsight(),
    },
    partnerInsights: <String, DashboardBalancePartnerInsight>{
      'employer': _employerPartnerInsight(),
    },
  );
}

const _alternativeBalanceIdentity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 3,
  coreRevision: 7,
);

DashboardBalanceLinkedPresentation _richAlternativeMonthLinked() => _linked(
  cashflow: DashboardBalancePrimaryPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
    mode: DashboardBalancePrimaryMode.month,
    incomeTotalMinor: 500000,
    expenseTotalMinor: 200000,
    periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
    dailyPoints: <DashboardBalancePrimaryDayPoint>[
      for (var day = 1; day <= 31; day += 1)
        DashboardBalancePrimaryDayPoint(
          day: day,
          incomeMinor: day == 1 ? 500000 : 0,
          expenseMinor: switch (day % 7) {
            0 => 36000,
            3 => 21000,
            5 => 12000,
            _ => 0,
          },
        ),
    ],
  ),
  retention: DashboardBalanceRetentionPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
    periods: const <DashboardBalanceRetentionPeriod>[
      DashboardBalanceRetentionPeriod(
        id: '2026-07',
        label: 'július',
        incomeMinor: 400000,
        expenseMinor: 250000,
        state: DashboardBalanceRetentionState.value,
        selected: false,
        retentionBasisPoints: 3750,
      ),
      DashboardBalanceRetentionPeriod(
        id: '2026-08',
        label: 'augusztus',
        incomeMinor: 500000,
        expenseMinor: 200000,
        state: DashboardBalanceRetentionState.value,
        selected: true,
        retentionBasisPoints: 6000,
      ),
    ],
  ),
);

DashboardBalanceLinkedPresentation _richAlternativeYearLinked() => _linked(
  cashflow: DashboardBalancePrimaryPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    mode: DashboardBalancePrimaryMode.year,
    incomeTotalMinor: 1326000,
    expenseTotalMinor: 858000,
    periodPairs: <DashboardBalancePrimaryPeriodPair>[
      for (var month = 1; month <= 12; month += 1)
        DashboardBalancePrimaryPeriodPair(
          value: month,
          incomeMinor: month * 17000,
          expenseMinor: month * 11000,
        ),
    ],
    dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
  ),
  closings: DashboardBalanceClosingsPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    buckets: <DashboardBalanceClosingBucket>[
      for (var month = 1; month <= 12; month += 1)
        DashboardBalanceClosingBucket(
          id: '2026-$month',
          label: 'M$month',
          incomeMinor: month.isEven ? 90000 : 25000,
          expenseMinor: month.isEven ? 30000 : 55000,
        ),
    ],
  ),
  retention: DashboardBalanceRetentionPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    periods: const <DashboardBalanceRetentionPeriod>[
      DashboardBalanceRetentionPeriod(
        id: '2025',
        label: '2025',
        incomeMinor: 1100000,
        expenseMinor: 760000,
        state: DashboardBalanceRetentionState.value,
        selected: false,
        retentionBasisPoints: 3090,
      ),
      DashboardBalanceRetentionPeriod(
        id: '2026',
        label: '2026',
        incomeMinor: 1326000,
        expenseMinor: 858000,
        state: DashboardBalanceRetentionState.value,
        selected: true,
        retentionBasisPoints: 3529,
      ),
    ],
  ),
);

DashboardBalancePrimaryPresentation _alternativeYearCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: const YearScope(2026),
      mode: DashboardBalancePrimaryMode.year,
      incomeTotalMinor: 780000,
      expenseTotalMinor: 330000,
      periodPairs: <DashboardBalancePrimaryPeriodPair>[
        for (var month = 1; month <= 12; month += 1)
          DashboardBalancePrimaryPeriodPair(
            value: month,
            incomeMinor: month == 12 ? 90000 : 0,
            expenseMinor: month == 1 ? 40000 : 0,
          ),
      ],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalancePrimaryPresentation _alternativeMonthCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
      mode: DashboardBalancePrimaryMode.month,
      incomeTotalMinor: 0,
      expenseTotalMinor: 0,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalancePrimaryPresentation _alternativeDayCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: DayScope(const LocalDate(year: 2026, month: 8, day: 7)),
      mode: DashboardBalancePrimaryMode.unsupportedDay,
      incomeTotalMinor: 0,
      expenseTotalMinor: 0,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalanceCategoryInsight _salaryCategoryInsight() =>
    DashboardBalanceCategoryInsight(
      id: 'salary',
      label: 'Fizetés',
      direction: LedgerDirection.income,
      amountMinor: 700000,
      activeDirectionScopeAmountMinor: 700000,
      transactionCount: 2,
      activeDayCount: 2,
      medianAmountTimesTwo: 700000,
      temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
        DashboardBalanceEntityTemporalBucket(
          id: '2026',
          label: '2026',
          value: 700000,
        ),
      ],
      distribution: const DashboardBalanceTransactionSizeDistribution(
        zeroToFiveKCount: 0,
        fiveToTenKCount: 0,
        tenToTwentyKCount: 0,
        twentyKPlusCount: 2,
      ),
      minimumAmountMinor: 350000,
      maximumAmountMinor: 350000,
      dayOccurrences: const <DashboardBalanceEntityOccurrence>[],
      hiddenDayOccurrenceCount: 0,
    );

DashboardBalancePartnerInsight _employerPartnerInsight() {
  const occurrence = DashboardBalanceEntityOccurrence(
    id: 'employer-1',
    epochDay: 20000,
    localTimeMinutes: 12 * 60,
    amountMinor: 350000,
    occurredOrder: 20000 * 1440 + 12 * 60,
  );
  return DashboardBalancePartnerInsight(
    id: 'employer',
    label: 'Munkahely',
    direction: LedgerDirection.income,
    amountMinor: 700000,
    transactionCount: 2,
    activeDayCount: 2,
    latestScopeOccurrence: occurrence,
    temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
      DashboardBalanceEntityTemporalBucket(id: '2026', label: '2026', value: 2),
    ],
    recentScopeOccurrences: const <DashboardBalanceEntityOccurrence>[
      occurrence,
    ],
    relationship: DashboardBalancePartnerRelationship(
      allHistoryTransactionCount: 3,
      firstOccurrence: occurrence,
      latestOccurrence: occurrence,
      medianAmountTimesTwo: 700000,
      firstQuartileAmountMinor: 350000,
      thirdQuartileAmountMinor: 350000,
      typicalCadenceMinutesTimesTwo: 1440,
      cadenceOccurrences: const <DashboardBalanceEntityOccurrence>[occurrence],
    ),
  );
}

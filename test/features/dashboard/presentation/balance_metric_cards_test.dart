import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_cashflow_stability_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_closings_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_category_movers_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_future_placeholder_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_momentum_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_retention_card.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'PC5: diverging bar geometry keeps the zero axis mathematically stable',
    () {
      const buckets = <DashboardBalanceClosingBucket>[
        DashboardBalanceClosingBucket(
          id: 'positive',
          label: 'P',
          incomeMinor: 10,
          expenseMinor: 0,
        ),
        DashboardBalanceClosingBucket(
          id: 'negative',
          label: 'N',
          incomeMinor: 0,
          expenseMinor: 5,
        ),
        DashboardBalanceClosingBucket(
          id: 'zero',
          label: 'Z',
          incomeMinor: 0,
          expenseMinor: 0,
        ),
      ];
      final bars = balanceClosingBarRectsFor(
        size: const Size(300, 200),
        buckets: buckets,
      );
      expect(bars[0]!.bottom, 100);
      expect(bars[0]!.top, lessThan(100));
      expect(bars[1]!.top, 100);
      expect(bars[1]!.bottom, greaterThan(100));
      expect(bars[2], isNull);
    },
  );

  test('BM4: map geometry places the current point in its true quadrant', () {
    final point = balanceMomentumMapPointFor(
      size: const Size(200, 200),
      currentPace: 10,
      previousPace: -20,
      momentum: 30,
    );
    expect(point.dx, greaterThan(100));
    expect(point.dy, lessThan(100));
    expect(
      balanceMomentumMapPointFor(
        size: const Size(200, 200),
        currentPace: 0,
        previousPace: 0,
        momentum: 0,
      ),
      const Offset(100, 100),
    );
  });

  test('BX3: Retention bars retain a fixed zero-percent axis', () {
    const periods = <DashboardBalanceRetentionPeriod>[
      DashboardBalanceRetentionPeriod(
        id: 'positive',
        label: 'P',
        incomeMinor: 100,
        expenseMinor: 75,
        retentionBasisPoints: 2500,
        state: DashboardBalanceRetentionState.value,
        selected: true,
      ),
      DashboardBalanceRetentionPeriod(
        id: 'negative',
        label: 'N',
        incomeMinor: 100,
        expenseMinor: 120,
        retentionBasisPoints: -2000,
        state: DashboardBalanceRetentionState.value,
        selected: false,
      ),
    ];
    final positive = balanceRetentionBarRectFor(
      size: const Size(80, 200),
      basisPoints: 2500,
      allPeriods: periods,
    );
    final negative = balanceRetentionBarRectFor(
      size: const Size(80, 200),
      basisPoints: -2000,
      allPeriods: periods,
    );
    expect(positive.bottom, 100);
    expect(positive.top, lessThan(100));
    expect(negative.top, 100);
    expect(negative.bottom, greaterThan(100));
  });

  test(
    'BX4: Stability distribution includes zero, median and complete marks',
    () {
      final presentation = _stability();
      final geometry = balanceStabilityDistributionGeometryFor(
        size: const Size(300, 120),
        presentation: presentation,
      );
      expect(geometry.zeroX, inInclusiveRange(0, 300));
      expect(geometry.medianX, inInclusiveRange(0, 300));
      expect(geometry.band.left, lessThanOrEqualTo(geometry.medianX));
      expect(geometry.band.right, greaterThanOrEqualTo(geometry.medianX));
      expect(geometry.observationMarks, hasLength(3));
    },
  );

  testWidgets(
    'PC5: Closings shows its zero-centred chart and a local bucket inspection',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceClosingsCard(
            presentation: (_metrics(
              closings: DashboardBalanceClosingsPresentation(
                identity: _identity,
                timeScope: const YearScope(2026),
                buckets: const <DashboardBalanceClosingBucket>[
                  DashboardBalanceClosingBucket(
                    id: 'jan',
                    label: 'JAN',
                    incomeMinor: 10000,
                    expenseMinor: 0,
                  ),
                  DashboardBalanceClosingBucket(
                    id: 'feb',
                    label: 'FEB',
                    incomeMinor: 0,
                    expenseMinor: 4000,
                  ),
                  DashboardBalanceClosingBucket(
                    id: 'mar',
                    label: 'MÁR',
                    incomeMinor: 0,
                    expenseMinor: 0,
                  ),
                ],
              ),
            )).closings,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('balance-closings-chart')),
        findsOneWidget,
      );
      expect(find.text('1 / 3 pozitív'), findsOneWidget);
      final chart = find.byKey(
        const ValueKey<String>('balance-closings-chart'),
      );
      await tester.tapAt(tester.getTopLeft(chart) + const Offset(8, 24));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-closing-inspection')),
        findsOneWidget,
      );
      expect(find.textContaining('JAN'), findsNWidgets(2));
    },
  );

  testWidgets(
    'PC5: Year closings shares the Balance clay setting while other scopes stay current',
    (tester) async {
      final yearClosings = DashboardBalanceClosingsPresentation(
        identity: _identity,
        timeScope: const YearScope(2026),
        buckets: const <DashboardBalanceClosingBucket>[
          DashboardBalanceClosingBucket(
            id: 'positive',
            label: 'P',
            incomeMinor: 10000,
            expenseMinor: 0,
          ),
          DashboardBalanceClosingBucket(
            id: 'negative',
            label: 'N',
            incomeMinor: 0,
            expenseMinor: 4000,
          ),
        ],
      );
      await tester.pumpWidget(
        _host(
          child: BalanceClosingsCard(
            presentation: (_metrics(closings: yearClosings)).closings,
            yearBarPresentation: BalanceYearBarPresentation.clay3d,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-closings-paint-clay3d')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          child: BalanceClosingsCard(
            presentation: (_metrics(
              closings: DashboardBalanceClosingsPresentation(
                identity: _identity,
                timeScope: const AllTimeScope(),
                buckets: yearClosings.buckets,
              ),
            )).closings,
            yearBarPresentation: BalanceYearBarPresentation.clay3d,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-closings-paint-current')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BM4: Momentum map exposes its true quadrant and calculated metrics',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceMomentumCard(
            presentation: (_metrics(
              momentum: _strengtheningMomentum(),
            )).momentum,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-momentum-map')),
        findsOneWidget,
      );
      expect(find.text('Erősödő többlet'), findsNWidgets(2));
      expect(find.text('Korábbi tempó'), findsOneWidget);
      expect(find.text('Mostani tempó'), findsOneWidget);
      expect(find.text('Momentum'), findsOneWidget);
    },
  );

  test(
    'BM4: Momentum rate formatting carries the currency unit exactly once',
    () {
      expect(
        formatBalanceMomentumRate(1450000, DashboardBalanceMomentumUnit.perDay),
        '+14500 Ft/nap',
      );
      expect(
        formatBalanceMomentumRate(
          -2900000,
          DashboardBalanceMomentumUnit.perHour,
        ),
        '−29000 Ft/óra',
      );
    },
  );

  testWidgets('BM4: Momentum unavailable state is clean', (tester) async {
    await tester.pumpWidget(
      _host(
        child: BalanceMomentumCard(
          presentation: (_metrics(
            momentum: DashboardBalanceMomentumPresentation.unavailable(
              identity: _identity,
              timeScope: const YearScope(2026),
            ),
          )).momentum,
        ),
      ),
    );
    expect(find.text('Nincs elég összehasonlítható adat'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('balance-momentum-map')),
      findsNothing,
    );
  });

  testWidgets(
    'STAB-RED: Cashflow stability keeps live data in two local reference views without changing card bounds',
    (tester) async {
      final retention = _retention();
      await tester.pumpWidget(
        _host(
          child: BalanceRetentionCard(
            presentation: (_metrics(retention: retention)).retention,
          ),
        ),
      );
      expect(find.text('Megtartási arány'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Bevétel'), findsOneWidget);
      expect(find.text('Megtartott'), findsOneWidget);
      expect(find.text('Kiadás'), findsOneWidget);
      final retentionBar = find.byKey(
        const ValueKey<String>('balance-retention-bar-selected'),
      );
      await tester.tap(retentionBar);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-retention-inspection')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          child: BalanceCashflowStabilityCard(
            presentation: (_metrics(stability: _stability())).stability,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil1')),
        findsOneWidget,
      );
      expect(find.text('Medián nettó'), findsOneWidget);
      expect(find.text('Tipikus sáv'), findsOneWidget);
      expect(find.text('Értelmezés fókuszban'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('balance-stability-inspection')),
        findsNothing,
        reason: 'The retired point inspection cannot compete with card tap.',
      );
      final card = find.byKey(
        const ValueKey<String>('balance-linked-detail-stability'),
      );
      final before = tester.getRect(card);
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-toggle-surface')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-stability-interpretation')),
        findsOneWidget,
      );
      expect(tester.getRect(card), before);

      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-stabil2-info')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil2')),
        findsOneWidget,
        reason:
            'An explicit child control must not bubble into the card toggle.',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-toggle-surface')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'STAB-RED: a presentation refresh keeps the active local Stability view',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCashflowStabilityCard(
            presentation: (_metrics(stability: _stability())).stability,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-toggle-surface')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil2')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          child: BalanceCashflowStabilityCard(
            presentation: (_metrics(
              stability: DashboardBalanceStabilityPresentation(
                identity: _identity,
                timeScope: const AllTimeScope(),
                observations: _stability().observations,
                medianNetTimesTwo: 600,
                typicalDeviationTimesTwo: 200,
              ),
            )).stability,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-stability-stabil2')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'STAB-REFERENCE-GOLDEN: stabil1 and stabil2 retain separate production-card compositions',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCashflowStabilityCard(
            presentation: (_metrics(stability: _stability())).stability,
          ),
          width: 378,
          height: 320,
        ),
      );
      await expectLater(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        matchesGoldenFile(
          '../../../goldens/balance_cashflow_stability_stabil1.png',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-toggle-surface')),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        matchesGoldenFile(
          '../../../goldens/balance_cashflow_stability_stabil2.png',
        ),
      );
    },
  );

  testWidgets(
    'BX6: analytic and future details use a bounded compact fallback',
    (tester) async {
      for (final card in <Widget>[
        BalanceRetentionCard(presentation: _metrics().retention),
        BalanceCashflowStabilityCard(presentation: _metrics().stability),
        const BalanceFuturePlaceholderCard.ghost(),
        const BalanceFuturePlaceholderCard.forecast(),
      ]) {
        await tester.pumpWidget(_host(child: card, width: 150, height: 110));
        expect(
          tester.takeException(),
          isNull,
          reason: '${card.runtimeType} compact layout',
        );
      }
    },
  );

  testWidgets(
    'Standalone metrics and future placeholders show truthful unavailable states',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceRetentionCard(presentation: (_metrics()).retention),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-retention')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          child: BalanceCashflowStabilityCard(
            presentation: (_metrics()).stability,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(child: const BalanceFuturePlaceholderCard.ghost()),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-ghost')),
        findsOneWidget,
      );
      expect(find.text('Hamarosan'), findsOneWidget);
      expect(
        find.textContaining('Ghost funkció még nincs bekötve'),
        findsOneWidget,
      );
      expect(find.text('0 Ft'), findsNothing);

      await tester.pumpWidget(
        _host(child: const BalanceFuturePlaceholderCard.forecast()),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-forecast')),
        findsOneWidget,
      );
      expect(
        find.textContaining('előrejelzési adatok bekötése'),
        findsOneWidget,
      );
      expect(find.text('0 Ft'), findsNothing);
    },
  );

  testWidgets(
    'Standalone Movers keeps card bounds and Back clears only local selection',
    (tester) async {
      final presentation = _movers();
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: presentation,
            )).categoryMovers,
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-housing')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: _movers(id: 'food'),
            )).categoryMovers,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-food')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-movers-back')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-list')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MOVERS-REFERENCE: the two local pages reserve their default hierarchy for ranking and chart content',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(categoryMovers: _movers())).categoryMovers,
          ),
          height: 520,
        ),
      );

      expect(find.text('Kategóriaváltozás'), findsOneWidget);
      expect(
        find.text(
          'A kiválasztott időszak költéseinek változása\na megelőző azonos időszakhoz képest.',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-info')),
        findsOneWidget,
      );
      expect(find.text('?'), findsNothing);
      expect(find.text('i'), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey<String>('balance-category-movers-info-visual'),
          ),
        ),
        const Size(21, 21),
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-direction-decrease'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-direction-increase'),
        ),
        findsOneWidget,
      );
      expect(find.text('csökkenés'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-footer')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-movers-direction-decrease'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Nincs ebbe az irányba változó kategória'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-movers-direction-increase'),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-housing')),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-kpi-current'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-kpi-percentage'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-kpi-delta')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-cumulative-chart'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-detail-info'),
        ),
        findsOneWidget,
      );
      expect(find.text('?'), findsNothing);
      expect(find.text('i'), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey<String>('balance-category-movers-info-visual'),
          ),
        ),
        const Size(21, 21),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('balance-category-movers-back')),
        ),
        const Size(44, 44),
      );
      expect(find.text('Előző'), findsNothing);
    },
  );

  testWidgets(
    'MOVERS-REFERENCE-GOLDEN: both reference-locked pages retain their visual hierarchy',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: _referenceMovers(),
            )).categoryMovers,
          ),
          width: 378,
          height: 540,
        ),
      );
      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_category_movers_page_one.png',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-housing')),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        matchesGoldenFile(
          '../../../goldens/balance_category_movers_page_two.png',
        ),
      );
    },
  );

  testWidgets(
    'MOVERS-DAY-CHART: one canonical bucket keeps the cumulative chart frame and horizontal comparison marks',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: _dayMovers(),
            )).categoryMovers,
          ),
          width: 378,
          height: 520,
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-mover-day-housing'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-cumulative-chart'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        matchesGoldenFile('../../../goldens/balance_category_movers_day.png'),
      );
    },
  );

  testWidgets(
    'MOVERS-STRETCH: the existing taller envelope distributes Page 1 ranking rows without a dead permanent footer',
    (tester) async {
      Future<({double rowHeight, Rect lastRow, Rect body})> measure({
        required double height,
      }) async {
        await tester.pumpWidget(
          _host(
            child: BalanceCategoryMoversCard(
              presentation: (_metrics(
                categoryMovers: _referenceMovers(),
              )).categoryMovers,
            ),
            width: 378,
            height: height,
          ),
        );
        final first = tester.getRect(
          find.byKey(const ValueKey<String>('balance-category-mover-housing')),
        );
        return (
          rowHeight: first.height,
          lastRow: tester.getRect(
            find.byKey(
              const ValueKey<String>('balance-category-mover-reference-4'),
            ),
          ),
          body: tester.getRect(
            find.byKey(
              const ValueKey<String>('balance-linked-detail-category-movers'),
            ),
          ),
        );
      }

      final baseline = await measure(height: 360);
      final stretched = await measure(height: 520);

      expect(baseline.rowHeight, inInclusiveRange(30, 42));
      expect(stretched.rowHeight, greaterThanOrEqualTo(baseline.rowHeight));
      expect(
        stretched.lastRow.bottom,
        lessThanOrEqualTo(stretched.body.bottom),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-footer')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-mover-reference-4'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MOVERS-COMPACTION RED: Page 1 uses one compact title-row info control and shows its bounded ranking without permanent explanatory surfaces',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: _referenceMovers(),
            )).categoryMovers,
          ),
          width: 378,
          height: 320,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-info')),
        findsOneWidget,
      );
      expect(
        find.text(
          'A kiválasztott időszak költéseinek változása\na megelőző azonos időszakhoz képest.',
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-footer')),
        findsNothing,
      );
      final decrease = tester.getSize(
        find.byKey(
          const ValueKey<String>('balance-category-movers-direction-decrease'),
        ),
      );
      expect(decrease.height, inInclusiveRange(30, 32));
      expect(decrease.width, inInclusiveRange(100, 112));
      final body = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers'),
        ),
      );
      final lastRow = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-category-mover-reference-4'),
        ),
      );
      expect(lastRow.bottom, lessThanOrEqualTo(body.bottom));
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-list-scroll'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-movers-info')),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-explanation-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-linked-detail-category-movers'),
          ),
        ),
        body,
        reason: 'The in-card explanation must not resize mode content.',
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-movers-overlay-close'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-explanation-overlay'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'MOVERS-COMPACTION RED: Page 2 gives reclaimed space to the chart and exposes exactly three metrics only on chart tap',
    (tester) async {
      await tester.pumpWidget(
        _host(
          child: BalanceCategoryMoversCard(
            presentation: (_metrics(
              categoryMovers: _referenceMovers(),
            )).categoryMovers,
          ),
          width: 378,
          height: 320,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-housing')),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-detail-info'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-kpi-current'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-overlay'),
        ),
        findsNothing,
      );
      final chart = find.byKey(
        const ValueKey<String>('balance-category-movers-cumulative-chart'),
      );
      expect(chart, findsOneWidget);
      expect(tester.getSize(chart).height, greaterThanOrEqualTo(150));
      final detailBounds = tester.getRect(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
      );

      final chartBounds = tester.getRect(chart);
      await tester.tapAt(Offset(chartBounds.center.dx, chartBounds.top + 6));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-current'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-percentage'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-delta'),
        ),
        findsOneWidget,
      );
      expect(find.text('Előző'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-movers-detail-info'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-overlay'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-explanation-overlay'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        ),
        detailBounds,
        reason: 'Neither in-card overlay may resize mode content.',
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-category-movers-overlay-close'),
        ),
      );
      await tester.pump();

      await tester.tap(chart);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-overlay'),
        ),
        findsOneWidget,
      );

      await tester.tapAt(Offset(chartBounds.center.dx, chartBounds.top + 6));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-metrics-overlay'),
        ),
        findsNothing,
      );
    },
  );
}

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 7,
  coreRevision: 11,
);

Widget _host({
  required Widget child,
  double width = 390,
  double height = 320,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: width, height: height, child: child),
  ),
);

({
  DashboardBalanceClosingsPresentation closings,
  DashboardBalanceMomentumPresentation momentum,
  DashboardBalanceRetentionPresentation retention,
  DashboardBalanceStabilityPresentation stability,
  DashboardBalanceCategoryMoversPresentation? categoryMovers,
})
_metrics({
  DashboardBalanceClosingsPresentation? closings,
  DashboardBalanceMomentumPresentation? momentum,
  DashboardBalanceRetentionPresentation? retention,
  DashboardBalanceStabilityPresentation? stability,
  DashboardBalanceCategoryMoversPresentation? categoryMovers,
}) => (
  closings:
      closings ??
      DashboardBalanceClosingsPresentation(
        identity: _identity,
        timeScope: const AllTimeScope(),
        buckets: const [],
      ),
  momentum:
      momentum ??
      DashboardBalanceMomentumPresentation.unavailable(
        identity: _identity,
        timeScope: const AllTimeScope(),
      ),
  retention:
      retention ??
      DashboardBalanceRetentionPresentation(
        identity: _identity,
        timeScope: const AllTimeScope(),
        periods: const [],
      ),
  stability:
      stability ??
      DashboardBalanceStabilityPresentation(
        identity: _identity,
        timeScope: const AllTimeScope(),
        observations: const [],
        medianNetTimesTwo: null,
        typicalDeviationTimesTwo: null,
      ),
  categoryMovers: categoryMovers,
);

DashboardBalanceCategoryMoversPresentation _movers({String id = 'housing'}) =>
    DashboardBalanceCategoryMoversPresentation(
      identity: _identity,
      timeScope: const AllTimeScope(),
      selectedDirection: LedgerDirection.income,
      logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 24),
      currentWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2026, month: 1, day: 1),
        endInclusive: LocalDate(year: 2026, month: 9, day: 24),
      ),
      referenceWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2025, month: 1, day: 1),
        endInclusive: LocalDate(year: 2025, month: 9, day: 24),
      ),
      movers: <DashboardBalanceCategoryMover>[
        DashboardBalanceCategoryMover(
          id: id,
          label: 'Lakhatás',
          categoryColorId: 'color_07',
          categoryIconId: 'icon_17',
          currentMinor: 260000,
          referenceMinor: 120000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 260000,
              referenceMinor: 120000,
            ),
          ],
        ),
      ],
    );

DashboardBalanceCategoryMoversPresentation _referenceMovers() {
  final decreases = List<DashboardBalanceCategoryMover>.generate(
    5,
    (index) => DashboardBalanceCategoryMover(
      id: index == 0 ? 'housing' : 'reference-$index',
      label: <String>[
        'Lakhatás',
        'Élelmiszer',
        'Vásárlás',
        'Előfizetések',
        'Szórakozás',
      ][index],
      categoryColorId: 'color_18',
      categoryIconId: 'icon_17',
      currentMinor: <int>[39000000, 8800000, 5100000, 3000000, 2700000][index],
      referenceMinor: <int>[
        42000000,
        10900000,
        7400000,
        4260000,
        3800000,
      ][index],
      trend: <DashboardBalanceCategoryMoverTrendPoint>[
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 1,
          currentMinor: 9000000 - index * 300000,
          referenceMinor: 11000000 - index * 300000,
        ),
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 2,
          currentMinor: 13000000 - index * 300000,
          referenceMinor: 14500000 - index * 300000,
        ),
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 3,
          currentMinor: 17000000 - index * 300000,
          referenceMinor: 20000000 - index * 300000,
        ),
      ],
    ),
    growable: false,
  );
  return DashboardBalanceCategoryMoversPresentation(
    identity: _identity,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    selectedDirection: LedgerDirection.expense,
    logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 1),
    currentWindow: const DashboardBalanceCategoryComparisonWindow(
      startInclusive: LocalDate(year: 2026, month: 7, day: 1),
      endInclusive: LocalDate(year: 2026, month: 7, day: 31),
    ),
    referenceWindow: const DashboardBalanceCategoryComparisonWindow(
      startInclusive: LocalDate(year: 2026, month: 6, day: 1),
      endInclusive: LocalDate(year: 2026, month: 6, day: 30),
    ),
    movers: decreases,
    topDecreases: decreases,
    topIncreases: const <DashboardBalanceCategoryMover>[],
  );
}

DashboardBalanceCategoryMoversPresentation _dayMovers() =>
    DashboardBalanceCategoryMoversPresentation(
      identity: _identity,
      timeScope: const DayScope(LocalDate(year: 2026, month: 9, day: 24)),
      selectedDirection: LedgerDirection.expense,
      logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 24),
      currentWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2026, month: 9, day: 24),
        endInclusive: LocalDate(year: 2026, month: 9, day: 24),
      ),
      referenceWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2026, month: 9, day: 23),
        endInclusive: LocalDate(year: 2026, month: 9, day: 23),
      ),
      movers: <DashboardBalanceCategoryMover>[
        DashboardBalanceCategoryMover(
          id: 'day-housing',
          label: 'Lakhatás',
          categoryColorId: 'color_18',
          categoryIconId: 'icon_17',
          currentMinor: 39000000,
          referenceMinor: 42000000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 24,
              currentMinor: 39000000,
              referenceMinor: 42000000,
            ),
          ],
        ),
      ],
    );

DashboardBalanceRetentionPresentation _retention() =>
    DashboardBalanceRetentionPresentation(
      identity: _identity,
      timeScope: const YearScope(2026),
      periods: const <DashboardBalanceRetentionPeriod>[
        DashboardBalanceRetentionPeriod(
          id: 'previous',
          label: '2025',
          incomeMinor: 100,
          expenseMinor: 80,
          retentionBasisPoints: 2000,
          state: DashboardBalanceRetentionState.value,
          selected: false,
        ),
        DashboardBalanceRetentionPeriod(
          id: 'selected',
          label: '2026',
          incomeMinor: 100,
          expenseMinor: 75,
          retentionBasisPoints: 2500,
          state: DashboardBalanceRetentionState.value,
          selected: true,
        ),
      ],
    );

DashboardBalanceStabilityPresentation _stability() =>
    DashboardBalanceStabilityPresentation(
      identity: _identity,
      timeScope: const AllTimeScope(),
      observations: const <DashboardBalanceMonthlyNetObservation>[
        DashboardBalanceMonthlyNetObservation(
          id: 'month:2026-1',
          label: '2026 JAN',
          month: YearMonth(year: 2026, month: 1),
          incomeMinor: 100,
          expenseMinor: 0,
        ),
        DashboardBalanceMonthlyNetObservation(
          id: 'month:2026-2',
          label: '2026 FEB',
          month: YearMonth(year: 2026, month: 2),
          incomeMinor: 200,
          expenseMinor: 0,
        ),
        DashboardBalanceMonthlyNetObservation(
          id: 'month:2026-3',
          label: '2026 MÁR',
          month: YearMonth(year: 2026, month: 3),
          incomeMinor: 300,
          expenseMinor: 0,
        ),
      ],
      medianNetTimesTwo: 400,
      typicalDeviationTimesTwo: 200,
    );

DashboardBalanceMomentumPresentation _strengtheningMomentum() =>
    DashboardBalanceMomentumProjection.build(
      identity: _identity,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 9)),
      logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 23),
      logicalAsOfLocalTimeMinutes: 14 * 60 + 37,
      incomeEntries: <DashboardLedgerEntry>[
        _entry('history', 1, 2026, 9, 9),
        _entry('current', 700, 2026, 9, 20),
      ],
      expenseEntries: <DashboardLedgerEntry>[
        _entry('previous', -140, 2026, 9, 12, direction: 'expense'),
      ],
    );

DashboardLedgerEntry _entry(
  String id,
  int amountMinor,
  int year,
  int month,
  int day, {
  String direction = 'income',
}) => DashboardLedgerEntry(
  id: id,
  partnerId: id,
  categoryId: id,
  direction: direction,
  amountMinor: amountMinor,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: 12 * 60,
);

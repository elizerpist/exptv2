import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_entity_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_cashflow_stability_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_closings_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_momentum_card.dart';
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

  testWidgets('PC5/BM4: new topics dispatch through the one lower card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(topic: BalanceLinkedDetailTopic.closings, presentation: _linked()),
    );
    expect(
      find.byKey(const ValueKey<String>('balance-linked-detail-closings')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _host(topic: BalanceLinkedDetailTopic.momentum, presentation: _linked()),
    );
    expect(
      find.byKey(const ValueKey<String>('balance-linked-detail-momentum')),
      findsOneWidget,
    );
    expect(find.text('Nincs elég összehasonlítható adat'), findsOneWidget);
  });

  testWidgets(
    'PC5: Closings shows its zero-centred chart and a local bucket inspection',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.closings,
          presentation: _linked(
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
    'BM4: Momentum map exposes its true quadrant and calculated metrics',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.momentum,
          presentation: _linked(momentum: _strengtheningMomentum()),
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
        topic: BalanceLinkedDetailTopic.momentum,
        presentation: _linked(
          momentum: DashboardBalanceMomentumPresentation.unavailable(
            identity: _identity,
            timeScope: const YearScope(2026),
          ),
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
    'BX3/BX4: Retention and Stability use immutable detail data and local inspection',
    (tester) async {
      final retention = _retention();
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.retention,
          presentation: _linked(retention: retention),
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
          topic: BalanceLinkedDetailTopic.stability,
          presentation: _linked(stability: _stability()),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-stability-distribution')),
        findsOneWidget,
      );
      expect(find.text('Medián nettó'), findsOneWidget);
      expect(find.text('Tipikus sáv'), findsOneWidget);
      expect(find.text('0 Ft'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-stability-distribution')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-stability-inspection')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BX6: analytic and future details use a bounded compact fallback',
    (tester) async {
      for (final topic in <BalanceLinkedDetailTopic>[
        BalanceLinkedDetailTopic.retention,
        BalanceLinkedDetailTopic.stability,
        BalanceLinkedDetailTopic.ghost,
        BalanceLinkedDetailTopic.forecast,
      ]) {
        await tester.pumpWidget(
          _host(topic: topic, presentation: _linked(), width: 150, height: 110),
        );
        expect(tester.takeException(), isNull, reason: '$topic compact layout');
      }
    },
  );

  testWidgets('L4: latest detail renders the five scoped transactions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        topic: BalanceLinkedDetailTopic.latestTransaction,
        presentation: _linked(),
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('balance-linked-detail-latest')),
      findsOneWidget,
    );
    for (var index = 0; index < 5; index += 1) {
      expect(
        find.byKey(ValueKey<String>('balance-linked-latest-entry-$index')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'LATEST-MAIN-RED: all bounded rows use canonical avatars in one fixed no-separator layout',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.latestTransaction,
          presentation: _linked(),
          height: 320,
        ),
      );

      expect(find.byType(Scrollable), findsNothing);
      expect(find.byType(Divider), findsNothing);
      for (var index = 0; index < 5; index += 1) {
        final entryId = 'entry-$index';
        expect(
          find.byKey(ValueKey<String>('balance-linked-latest-$entryId')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey<String>('balance-linked-latest-avatar-$entryId')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey<String>('balance-linked-latest-amount-$entryId')),
          findsOneWidget,
        );
      }
      expect(find.text('Tétel 0'), findsOneWidget);
      expect(find.textContaining('Kategória 0 ·'), findsOneWidget);
      expect(find.textContaining('12:00'), findsOneWidget);
      expect(find.textContaining('08:07'), findsNWidgets(4));
      expect(
        find.bySemanticsLabel(
          RegExp(r'Tétel 0, Kategória 0, 2024\. 10\. 04\., 12:00'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getRect(
              find.byKey(
                const ValueKey<String>('balance-linked-latest-avatar-entry-0'),
              ),
            )
            .left,
        lessThan(
          tester
              .getRect(
                find.byKey(
                  const ValueKey<String>(
                    'balance-linked-latest-amount-entry-0',
                  ),
                ),
              )
              .left,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CATEGORY-REFERENCE-RED: fixed category face promotes the existing median rather than total/share/profile',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topCategory,
          presentation: _linked(
            categoryInsights: <String, DashboardBalanceCategoryInsight>{
              'category-0': _categoryInsight(
                amountMinor: 9900,
                medianAmountMinor: 1200,
              ),
            },
          ),
          height: 320,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-linked-rank-category-0')),
      );
      await tester.pump();

      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('MEDIÁN'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('balance-category-insight-median')),
        findsOneWidget,
      );
      expect(find.text('12 Ft'), findsOneWidget);
      expect(find.text('99 Ft'), findsNothing);
      expect(find.text('Időbeli profil'), findsNothing);
      expect(find.textContaining('domináns sávban'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('balance-category-insight-avatar')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-insight-distribution'),
        ),
        findsOneWidget,
      );
      expect(find.text('0–5k'), findsOneWidget);
      expect(find.text('5–10k'), findsOneWidget);
      expect(find.text('10–20k'), findsOneWidget);
      expect(find.text('20k+'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-category-insight-detail')),
        matchesGoldenFile(
          '../../../goldens/balance_category_reference_detail.png',
        ),
      );
    },
  );

  testWidgets(
    'L5-L7: category and partner detail retain their rank composition',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topCategory,
          presentation: _linked(),
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-top-category'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('balance-linked-rank-category-0'),
              ),
            )
            .height,
        greaterThan(
          tester
              .getSize(
                find.byKey(
                  const ValueKey<String>('balance-linked-rank-category-1'),
                ),
              )
              .height,
        ),
      );

      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topPartner,
          presentation: _linked(),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-top-partner')),
        findsOneWidget,
      );
      expect(find.text('5 tranzakció'), findsOneWidget);
    },
  );

  testWidgets(
    'CAT/PART-RED: real rank rows open local detail, update from replacement and Back never leaves the lower card',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topCategory,
          presentation: _linked(
            categoryInsights: <String, DashboardBalanceCategoryInsight>{
              'category-0': _categoryInsight(amountMinor: 1200),
            },
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-linked-rank-category-0')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-insight-detail')),
        findsOneWidget,
      );
      expect(find.text('6 Ft'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topCategory,
          presentation: _linked(
            categoryInsights: <String, DashboardBalanceCategoryInsight>{
              'category-0': _categoryInsight(amountMinor: 3400),
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text('17 Ft'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-insight-back')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-list-category')),
        findsOneWidget,
      );

      // A replacement which no longer admits the locally selected entity
      // returns to the master list; stale detail data may never survive it.
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-linked-rank-category-0')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-insight-detail')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topCategory,
          presentation: _linked(),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-list-category')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.topPartner,
          presentation: _linked(
            partnerInsights: <String, DashboardBalancePartnerInsight>{
              'partner-0': _partnerInsight(),
            },
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-linked-rank-partner-0')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-partner-insight-detail')),
        findsOneWidget,
      );
      expect(find.textContaining('Kapcsolati előzmény'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-partner-insight-back')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-list-partner')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BX1/BX2 RED: new detail topics are data-free truthful surfaces',
    (tester) async {
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.retention,
          presentation: _linked(),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-retention')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.stability,
          presentation: _linked(),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(topic: BalanceLinkedDetailTopic.ghost, presentation: _linked()),
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
        _host(
          topic: BalanceLinkedDetailTopic.forecast,
          presentation: _linked(),
        ),
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

  test(
    'L1: linked detail rendering has no repository or prepared-index dependency',
    () {
      final source = File(
        'lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart',
      ).readAsStringSync();
      expect(source, contains('DashboardBalanceLinkedPresentation'));
      expect(source, isNot(contains('repository/')));
      expect(source, isNot(contains('runtime/data')));
      expect(source, isNot(contains('PreparedDashboardIndex')));
    },
  );

  testWidgets(
    'Movers stays inside the linked lower card and Back clears only local selection',
    (tester) async {
      final presentation = _movers();
      await tester.pumpWidget(
        _host(
          topic: BalanceLinkedDetailTopic.categoryMovers,
          presentation: _linked(categoryMovers: presentation),
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
          topic: BalanceLinkedDetailTopic.categoryMovers,
          presentation: _linked(categoryMovers: _movers(id: 'food')),
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
}

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 7,
  coreRevision: 11,
);

Widget _host({
  required BalanceLinkedDetailTopic topic,
  required DashboardBalanceLinkedPresentation presentation,
  double width = 390,
  double height = 320,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: width,
      height: height,
      child: BalanceLinkedDetailCard(presentation: presentation, topic: topic),
    ),
  ),
);

DashboardBalanceLinkedPresentation _linked({
  DashboardBalanceClosingsPresentation? closings,
  DashboardBalanceMomentumPresentation? momentum,
  DashboardBalanceRetentionPresentation? retention,
  DashboardBalanceStabilityPresentation? stability,
  DashboardBalanceCategoryMoversPresentation? categoryMovers,
  Map<String, DashboardBalanceCategoryInsight> categoryInsights =
      const <String, DashboardBalanceCategoryInsight>{},
  Map<String, DashboardBalancePartnerInsight> partnerInsights =
      const <String, DashboardBalancePartnerInsight>{},
}) => DashboardBalanceLinkedPresentation(
  identity: _identity,
  timeScope: const AllTimeScope(),
  selectedDirection: LedgerDirection.income,
  cashflow: DashboardBalancePrimaryPresentation(
    identity: _identity,
    timeScope: const AllTimeScope(),
    mode: DashboardBalancePrimaryMode.sum,
    incomeTotalMinor: 1,
    expenseTotalMinor: 0,
    periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
    dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
  ),
  closings: closings,
  momentum: momentum,
  retention: retention,
  stability: stability,
  categoryMovers: categoryMovers,
  latestTransactions: List<DashboardBalanceScopedTransaction>.generate(
    5,
    (index) => DashboardBalanceScopedTransaction(
      entryId: 'entry-$index',
      title: 'Tétel $index',
      categoryTitle: 'Kategória $index',
      categoryColorId: 'color_07',
      categoryIconId: 'icon_17',
      amountMinor: index + 1,
      direction: index.isEven
          ? LedgerDirection.income
          : LedgerDirection.expense,
      occurredOrder: 100 - index,
      epochDay: 20000 - index,
      localTimeMinutes: index == 0 ? 12 * 60 : 8 * 60 + 7,
    ),
    growable: false,
  ),
  topCategories: _ranks('category', amountBase: 50000),
  topPartners: _ranks('partner', amountBase: 1000),
  categoryInsights: categoryInsights,
  partnerInsights: partnerInsights,
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

DashboardBalanceCategoryInsight _categoryInsight({
  required int amountMinor,
  int? medianAmountMinor,
}) => DashboardBalanceCategoryInsight(
  id: 'category-0',
  label: 'category 0',
  direction: LedgerDirection.income,
  amountMinor: amountMinor,
  activeDirectionScopeAmountMinor: 10000,
  transactionCount: 4,
  activeDayCount: 2,
  medianAmountTimesTwo: medianAmountMinor == null
      ? amountMinor
      : medianAmountMinor * 2,
  temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
    DashboardBalanceEntityTemporalBucket(
      id: '2026',
      label: '2026',
      value: 1200,
    ),
  ],
  distribution: const DashboardBalanceTransactionSizeDistribution(
    zeroToFiveKCount: 1,
    fiveToTenKCount: 2,
    tenToTwentyKCount: 1,
    twentyKPlusCount: 0,
  ),
  minimumAmountMinor: 100,
  maximumAmountMinor: 1000,
  dayOccurrences: const <DashboardBalanceEntityOccurrence>[],
  hiddenDayOccurrenceCount: 0,
);

DashboardBalancePartnerInsight _partnerInsight() {
  const occurrence = DashboardBalanceEntityOccurrence(
    id: 'partner-occurrence',
    epochDay: 20000,
    localTimeMinutes: 12 * 60,
    amountMinor: 1200,
    occurredOrder: 1,
  );
  return DashboardBalancePartnerInsight(
    id: 'partner-0',
    label: 'partner 0',
    direction: LedgerDirection.income,
    amountMinor: 1200,
    transactionCount: 3,
    activeDayCount: 2,
    latestScopeOccurrence: occurrence,
    temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
      DashboardBalanceEntityTemporalBucket(id: '2026', label: '2026', value: 3),
    ],
    recentScopeOccurrences: const <DashboardBalanceEntityOccurrence>[
      occurrence,
    ],
    relationship: DashboardBalancePartnerRelationship(
      allHistoryTransactionCount: 3,
      firstOccurrence: occurrence,
      latestOccurrence: occurrence,
      medianAmountTimesTwo: 2400,
      firstQuartileAmountMinor: 1000,
      thirdQuartileAmountMinor: 1400,
      typicalCadenceMinutesTimesTwo: 60,
      cadenceOccurrences: const <DashboardBalanceEntityOccurrence>[occurrence],
    ),
  );
}

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

List<DashboardBalanceRankedItem> _ranks(
  String prefix, {
  required int amountBase,
}) => List<DashboardBalanceRankedItem>.generate(
  5,
  (index) => DashboardBalanceRankedItem(
    id: '$prefix-$index',
    label: '$prefix $index',
    direction: LedgerDirection.income,
    amountMinor: amountBase - index,
    transactionCount: 5 - index,
    categoryColorId: 'color_07',
    categoryIconId: 'icon_17',
  ),
  growable: false,
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

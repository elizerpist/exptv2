import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_closings_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_momentum_card.dart';
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
        '+14500,00 Ft/nap',
      );
      expect(
        formatBalanceMomentumRate(
          -2900000,
          DashboardBalanceMomentumUnit.perHour,
        ),
        '−29000,00 Ft/óra',
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
}

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 7,
  coreRevision: 11,
);

Widget _host({
  required BalanceLinkedDetailTopic topic,
  required DashboardBalanceLinkedPresentation presentation,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 390,
      height: 320,
      child: BalanceLinkedDetailCard(presentation: presentation, topic: topic),
    ),
  ),
);

DashboardBalanceLinkedPresentation _linked({
  DashboardBalanceClosingsPresentation? closings,
  DashboardBalanceMomentumPresentation? momentum,
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
  latestTransactions: List<DashboardBalanceScopedTransaction>.generate(
    5,
    (index) => DashboardBalanceScopedTransaction(
      entryId: 'entry-$index',
      title: 'Tétel $index',
      categoryTitle: 'Kategória $index',
      amountMinor: index + 1,
      direction: index.isEven
          ? LedgerDirection.income
          : LedgerDirection.expense,
      occurredOrder: 100 - index,
      epochDay: 20000 - index,
    ),
    growable: false,
  ),
  topCategories: _ranks('category', amountBase: 50000),
  topPartners: _ranks('partner', amountBase: 1000),
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

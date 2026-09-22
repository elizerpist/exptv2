import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  testWidgets('L4-RED: latest detail renders the five scoped transactions', (
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
    expect(find.text('Nincs tétel ebben az időszakban'), findsNothing);
  });

  testWidgets(
    'L5-L7-RED: category detail features rank one and the next ranks',
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
      for (var index = 0; index < 5; index += 1) {
        expect(
          find.byKey(ValueKey<String>('balance-linked-rank-category-$index')),
          findsOneWidget,
        );
      }
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
      expect(find.text('Havi'), findsNothing);
      expect(find.text('Éves'), findsNothing);
      expect(find.text('Össz.'), findsNothing);
    },
  );

  testWidgets(
    'L6-L7-RED: partner detail uses count values and rank composition',
    (tester) async {
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
      for (var index = 0; index < 5; index += 1) {
        expect(
          find.byKey(ValueKey<String>('balance-linked-rank-partner-$index')),
          findsOneWidget,
        );
      }
    },
  );

  test(
    'L1-RED: linked detail rendering has no repository or prepared-index dependency',
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

DashboardBalanceLinkedPresentation _linked() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 7,
    coreRevision: 11,
  );
  return DashboardBalanceLinkedPresentation(
    identity: identity,
    timeScope: const AllTimeScope(),
    selectedDirection: LedgerDirection.income,
    cashflow: DashboardBalancePrimaryPresentation(
      identity: identity,
      timeScope: const AllTimeScope(),
      mode: DashboardBalancePrimaryMode.sum,
      incomeTotalMinor: 1,
      expenseTotalMinor: 0,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    ),
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
}

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

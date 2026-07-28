import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/balance_production_host.dart';

void main() {
  test('Balance V2 is a first-class Balance-shell presentation', () {
    expect(
      SpendeeBalancePresentation.values.map((value) => value.name),
      contains('balanceV2'),
    );
    expect(
      SpendeeDashboardMode.values.map((value) => value.name),
      contains('balanceV2'),
    );
    expect(SpendeeDashboardMode.balanceV2.usesBalanceShell, isTrue);
  });

  testWidgets(
    'Balance V2 turns the FastInfo footprint into one taller detail carousel',
    (tester) async {
      await pumpBalanceProductionHost(
        tester,
        allTime: true,
        dashboardMode: SpendeeDashboardMode.balanceV2,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        find.byKey(const ValueKey('spendee-balance-fast-info-belt')),
        findsNothing,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('spendee-balance-detail-stage')),
        ),
        const Rect.fromLTWH(17, 241, 378, 301),
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-v2-detail-ticking-viewport')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-v2-detail-dot-8')),
        findsOneWidget,
      );
      final noSpendPage = find.byKey(
        const ValueKey('spendee-balance-v2-page-no-spend'),
      );
      expect(tester.getSize(noSpendPage), const Size(378, 291));
      expect(
        find.descendant(
          of: noSpendPage,
          matching: find.byKey(
            const ValueKey('spendee-balance-v2-no-spend-observed-days'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: noSpendPage,
          matching: find.byKey(
            const ValueKey('spendee-balance-fast-info-surface-noSpend'),
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('Balance V2 turns category and merchant rankings into Top 5', (
    tester,
  ) async {
    final categories = List<TransactionCategory>.generate(
      5,
      (index) => TransactionCategory.fromMap({
        'transactionCategoryID': index + 1,
        'name': 'Kategória ${index + 1}',
        'type': 'kiadás',
        'colorSlot': index,
        'iconSlot': index,
        'backgroundColor': null,
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': false,
      }),
    );
    final transactions = List<TransactionRecord>.generate(
      5,
      (index) => TransactionRecord.fromMap({
        'id': index + 1,
        'date': '2026.07.16',
        'time': '10:0$index',
        'merchant': 'Kereskedő ${index + 1}',
        'amount': -(50000 - index * 5000),
        'userAssignedName': null,
        'transactionCategoryID': index + 1,
      }),
    );
    final store = createBalanceProductionStore(
      transactions: transactions,
      categories: categories,
    );
    await pumpBalanceProductionHost(
      tester,
      store: store,
      allTime: true,
      dashboardMode: SpendeeDashboardMode.balanceV2,
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 80));

    final viewport = find.byKey(
      const ValueKey('spendee-balance-v2-detail-ticking-viewport'),
    );
    for (var index = 0; index < 6; index += 1) {
      await tester.timedDrag(
        viewport,
        const Offset(-250, 0),
        const Duration(milliseconds: 280),
      );
      await tester.pump(const Duration(milliseconds: 420));
    }

    expect(find.text('Top 5 kategória'), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('spendee-balance-detail-page-top-categories')),
      ),
      const Size(378, 291),
    );
  });

  testWidgets('Balance V2 category card shows leader plus four live rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            height: 291,
            child: SpendeeBalanceDetailPage(
              expandedContent: true,
              model: SpendeeBalanceTopCategoriesModel(
                id: 'top-categories',
                title: 'Top 5 kategória',
                featuredCategory: 'Első',
                featuredMeta: 'Havi · 1. hely',
                featuredAmount: '50 000 Ft',
                featuredIconAsset: 'assets/icons/lucide/handbag.svg',
                rankDimension: SpendeeBalanceRankDimension.month,
                includeGhostTransactions: true,
                rows: const <SpendeeBalanceTopCategoryRowModel>[
                  SpendeeBalanceTopCategoryRowModel(
                    scope: '2. hely',
                    category: 'Második',
                    amount: '40 000 Ft',
                    iconAsset: 'assets/icons/lucide/bus-front.svg',
                    color: Color(0xFF06B6D4),
                  ),
                  SpendeeBalanceTopCategoryRowModel(
                    scope: '3. hely',
                    category: 'Harmadik',
                    amount: '30 000 Ft',
                    iconAsset: 'assets/icons/lucide/house.svg',
                    color: Color(0xFFF24CAE),
                  ),
                  SpendeeBalanceTopCategoryRowModel(
                    scope: '4. hely',
                    category: 'Negyedik',
                    amount: '20 000 Ft',
                    iconAsset: 'assets/icons/lucide/car.svg',
                    color: Color(0xFF8B5CF6),
                  ),
                  SpendeeBalanceTopCategoryRowModel(
                    scope: '5. hely',
                    category: 'Ötödik',
                    amount: '10 000 Ft',
                    iconAsset: 'assets/icons/lucide/utensils.svg',
                    color: Color(0xFF16A36A),
                  ),
                ],
              ),
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
              onCategoryRankDimensionChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 4; index += 1) {
      expect(
        find.byKey(ValueKey('spendee-balance-top-category-row-$index')),
        findsOneWidget,
      );
    }
    expect(find.text('Ötödik'), findsOneWidget);
  });

  testWidgets('Balance V2 gives the daily average chart the reclaimed height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            height: 291,
            child: SpendeeBalanceDetailPage(
              expandedContent: true,
              model: SpendeeBalanceAverageDailyModel(
                id: 'average-daily',
                title: 'Átlagos napi költés',
                periodLabel: 'Napi',
                rollingTotalLabel: '30 000 Ft / 30 nap',
                averageLabel: '1 000 Ft / nap',
                dailyValues: List<double>.filled(30, 1000),
                facts: const <SpendeeBalanceDailyFactModel>[
                  SpendeeBalanceDailyFactModel(label: 'Puffer', value: '4 nap'),
                  SpendeeBalanceDailyFactModel(label: 'Maximum', value: '2 000 Ft'),
                  SpendeeBalanceDailyFactModel(label: 'Kiugrások', value: '1 db'),
                ],
                selectedDimension: SpendeeBalanceAverageDimension.month,
                iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
                includeGhostTransactions: true,
              ),
              onGhostChanged: (_, _) {},
              onBudgetDimensionChanged: (_) {},
              onMerchantDimensionChanged: (_) {},
              onAverageDimensionChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey('spendee-balance-average-daily-chart')),
      ),
      const Size(346, 104),
    );
  });

  testWidgets('header dropdown exposes the Balance V2 production route', (
    tester,
  ) async {
    await pumpBalanceProductionHost(tester, allTime: true, settle: false);
    await tester.pump(const Duration(milliseconds: 20));

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final balanceV2Item = find.byKey(
      const ValueKey('spendee-test-header-background-balance-v2'),
    );
    expect(balanceV2Item, findsOneWidget);
  });
}

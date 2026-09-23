import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'entity-insights',
    indexGeneration: 9,
    coreRevision: 4,
  );

  test(
    'CAT-RED: category detail stays active-direction/scope local with exact share, child years and count-weighted boundaries',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const AllTimeScope(),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: <DashboardLedgerEntry>[
          _entry('income', 'income', 9999999, 2025, 1, 1),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            'food-2024',
            'expense',
            -400000,
            2024,
            12,
            31,
            category: 'food',
            partner: 'food-partner',
          ),
          _entry(
            'food-5k',
            'expense',
            -500000,
            2025,
            1,
            2,
            category: 'food',
            partner: 'food-partner',
          ),
          _entry(
            'food-10k',
            'expense',
            -1000000,
            2025,
            1,
            3,
            category: 'food',
            partner: 'food-partner',
          ),
          _entry(
            'food-20k',
            'expense',
            -2000000,
            2025,
            2,
            3,
            category: 'food',
            partner: 'food-partner',
          ),
          _entry(
            'other',
            'expense',
            -10000,
            2025,
            3,
            1,
            category: 'other',
            partner: 'other-partner',
          ),
        ],
      );

      final category = linked.categoryInsights['food']!;
      expect(linked.topCategories.first.id, 'food');
      expect(category.amountMinor, 3900000);
      expect(category.activeDirectionScopeAmountMinor, 3910000);
      expect(category.shareBasisPoints, 9974);
      expect(category.transactionCount, 4);
      expect(category.activeDayCount, 4);
      expect(category.medianAmountTimesTwo, 1500000);
      expect(category.roundedMedianAmountMinor, 750000);
      expect(category.temporalBuckets.map((bucket) => bucket.id), <String>[
        '2024',
        '2025',
      ]);
      expect(category.temporalBuckets.map((bucket) => bucket.value), <int>[
        400000,
        3500000,
      ]);
      expect(category.distribution.counts, <int>[1, 1, 1, 1]);
      expect(category.distribution.dominantBucketIndex, 0);
    },
  );

  test(
    'CAT-RED: YEAR/MONTH child profiles include exact zero calendar buckets and leap February Day remains occurrence-only',
    () {
      final entries = <DashboardLedgerEntry>[
        _entry('food-feb-1', 'expense', -100, 2024, 2, 1, category: 'food'),
        _entry('food-feb-29', 'expense', -200, 2024, 2, 29, category: 'food'),
      ];
      final year = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const YearScope(2024),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: entries,
      ).categoryInsights['food']!;
      expect(year.temporalBuckets, hasLength(12));
      expect(year.temporalBuckets[1].value, 300);
      expect(year.temporalBuckets[2].value, 0);

      final month = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2024, month: 2)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: entries,
      ).categoryInsights['food']!;
      expect(month.temporalBuckets, hasLength(29));
      expect(month.temporalBuckets.first.value, 100);
      expect(month.temporalBuckets.last.value, 200);
    },
  );

  test(
    'PART-RED: partner detail keeps count rank while scope activity, all-history cadence, median and nearest-rank band are exact',
    () {
      final expenses = <DashboardLedgerEntry>[
        _entry(
          'p-old',
          'expense',
          -10000,
          2024,
          1,
          1,
          partner: 'shop',
          category: 'hidden-category',
        ),
        _entry(
          'p-1',
          'expense',
          -30000,
          2025,
          3,
          1,
          minutes: 0,
          partner: 'shop',
          category: 'hidden-category',
        ),
        _entry(
          'p-2',
          'expense',
          -10000,
          2025,
          3,
          5,
          minutes: 0,
          partner: 'shop',
          category: 'hidden-category',
        ),
        _entry(
          'p-3',
          'expense',
          -50000,
          2025,
          3,
          12,
          minutes: 0,
          partner: 'shop',
          category: 'hidden-category',
        ),
        _entry(
          'amount-not-count',
          'expense',
          -999999,
          2025,
          3,
          13,
          partner: 'amount-only',
          category: 'other',
        ),
      ];
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2025, month: 3)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: expenses,
      );

      expect(linked.topPartners.first.id, 'shop');
      final partner = linked.partnerInsights['shop']!;
      expect(partner.amountMinor, 90000);
      expect(partner.transactionCount, 3);
      expect(partner.activeDayCount, 3);
      expect(partner.temporalBuckets, hasLength(31));
      expect(partner.temporalBuckets[0].value, 1);
      expect(partner.temporalBuckets[4].value, 1);
      expect(partner.relationship.allHistoryTransactionCount, 4);
      expect(partner.relationship.medianAmountTimesTwo, 40000);
      expect(partner.relationship.firstQuartileAmountMinor, 10000);
      // nearest-rank Q3: ceil(.75 * 4) - 1 = 2 in [10k, 10k, 30k, 50k].
      expect(partner.relationship.thirdQuartileAmountMinor, 30000);
      expect(partner.relationship.typicalCadenceMinutesTimesTwo, 20160);
      expect(partner.relationship.cadenceOccurrences, hasLength(4));
      expect(
        partner.recentScopeOccurrences.map((occurrence) => occurrence.id),
        <String>['p-3', 'p-2', 'p-1'],
      );
    },
  );

  test(
    'PART-RED: fewer than three partner transactions has no invented cadence',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const AllTimeScope(),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('one', 'expense', -100, 2025, 1, 1, partner: 'shop'),
          _entry('two', 'expense', -100, 2025, 1, 2, partner: 'shop'),
        ],
      );

      expect(
        linked
            .partnerInsights['shop']!
            .relationship
            .typicalCadenceMinutesTimesTwo,
        isNull,
    );
  },
  );

  test(
    'CAT-RED: Day keeps all metrics but renders only the newest twelve chronological category occurrences',
    () {
      final entries = <DashboardLedgerEntry>[
        for (var index = 1; index <= 13; index += 1)
          _entry(
            'food-$index',
            'expense',
            -index,
            2026,
            9,
            23,
            minutes: index,
            category: 'food',
            partner: 'not-rendered',
          ),
      ];
      final category = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const DayScope(LocalDate(year: 2026, month: 9, day: 23)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: entries,
      ).categoryInsights['food']!;

      expect(category.transactionCount, 13);
      expect(category.amountMinor, 91);
      expect(category.temporalBuckets, isEmpty);
      expect(category.usesDayLowSampleFallback, isFalse);
      expect(category.hiddenDayOccurrenceCount, 1);
      expect(
        category.dayOccurrences.map((occurrence) => occurrence.id),
        <String>[for (var index = 2; index <= 13; index += 1) 'food-$index'],
      );
    },
  );

  test(
    'PART-RED: relationship metrics use every all-history occurrence while visual lists stay bounded',
    () {
      final entries = <DashboardLedgerEntry>[
        for (var index = 1; index <= 10; index += 1)
          _entry(
            'shop-$index',
            'expense',
            -index * 100,
            2026,
            9,
            index,
            minutes: index,
            partner: 'shop',
            category: 'not-rendered',
          ),
      ];
      final partner = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 9)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: entries,
      ).partnerInsights['shop']!;

      expect(partner.transactionCount, 10);
      expect(partner.relationship.allHistoryTransactionCount, 10);
      expect(partner.relationship.cadenceOccurrences, hasLength(8));
      expect(
        partner.relationship.cadenceOccurrences.map((occurrence) => occurrence.id),
        <String>[for (var index = 3; index <= 10; index += 1) 'shop-$index'],
      );
      expect(partner.recentScopeOccurrences, hasLength(5));
      expect(
        partner.recentScopeOccurrences.first.id,
        'shop-10',
      );
      expect(partner.relationship.typicalCadenceMinutesTimesTwo, 2882);
    },
  );
}

DashboardLedgerEntry _entry(
  String id,
  String direction,
  int amountMinor,
  int year,
  int month,
  int day, {
  int minutes = 12 * 60,
  String category = 'category',
  String partner = 'partner',
}) => DashboardLedgerEntry(
  id: id,
  partnerId: partner,
  categoryId: category,
  direction: direction,
  amountMinor: amountMinor,
  bookedLocalEpochDay: DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(1970)).inDays,
  bookedLocalTimeMinutes: minutes,
  partnerDisplayName: partner,
  categoryDisplayName: category,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
);

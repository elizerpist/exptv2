import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  DashboardLedgerEntry row(
    String id, {
    required String category,
    required String partner,
    String? partnerName,
    String? note,
    int amount = 100,
  }) => DashboardLedgerEntry(
    id: id,
    categoryId: category,
    partnerId: partner,
    direction: 'expense',
    amountMinor: amount,
    bookedLocalEpochDay: 20,
    bookedLocalTimeMinutes: 600,
    partnerDisplayName: partnerName,
    note: note,
  );

  test(
    'precomputes bounded category/partner membership without changing order',
    () {
      final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
        row('a', category: 'food', partner: 'market'),
        row('b', category: 'utilities', partner: 'mvm'),
        row('c', category: 'utilities', partner: 'market'),
        row('d', category: 'food', partner: 'mvm'),
      ]);

      expect(seed.entryCount, 4);
      expect(seed.select(categoryId: 'utilities').entryIds, <String>['b', 'c']);
      expect(seed.select(partnerId: 'mvm').entryIds, <String>['b', 'd']);
      expect(
        seed.select(categoryId: 'utilities', partnerId: 'market').entryIds,
        <String>['c'],
      );
    },
  );

  test('prepared live search matches partner display name or note in RAM', () {
    final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
      row('a', category: 'food', partner: 'spar', partnerName: 'SPAR'),
      row(
        'b',
        category: 'food',
        partner: 'other',
        partnerName: 'Valami',
        note: 'SPAR-blokk',
      ),
      row(
        'c',
        category: 'utilities',
        partner: 'tesco',
        partnerName: 'TESCO',
        note: 'tej',
      ),
      row(
        'd',
        category: 'food',
        partner: 'spar-note-boundary',
        partnerName: 'SPAR',
        note: 'blokk',
      ),
    ]);

    expect(seed.select(normalizedSearch: 'spar').entryIds, <String>[
      'a',
      'b',
      'd',
    ]);
    expect(seed.select(normalizedSearch: 'tej').entryIds, <String>['c']);
    expect(
      seed.select(categoryId: 'food', normalizedSearch: 'spar').entryIds,
      <String>['a', 'b', 'd'],
    );
    expect(seed.select(normalizedSearch: 'nincs').entryIds, isEmpty);
    expect(
      seed.select(normalizedSearch: 'ar b').entryIds,
      isEmpty,
      reason:
          'Partner name and memo match independently; a query cannot span '
          'their storage boundary.',
    );
  });

  test('search normalizer is case-insensitive and preserves accents', () {
    expect(
      DashboardLedgerSearchNormalizer.normalize('  ÁRVÍZ\tTŰRŐ '),
      'árvíz tűrő',
    );
    expect(DashboardLedgerSearchNormalizer.normalize(' \n '), isNull);
  });

  test('unknown focus is an exact empty projection, not a base fallback', () {
    final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
      row('a', category: 'food', partner: 'market'),
    ]);

    expect(seed.select(categoryId: 'utilities').entryIndices, isEmpty);
  });

  test('amount lookup is inclusive, ordered, and composes with facets', () {
    final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
      row('a', category: 'food', partner: 'market', amount: 900),
      row('b', category: 'utilities', partner: 'mvm', amount: 300),
      row('c', category: 'utilities', partner: 'market', amount: 700),
      row('d', category: 'food', partner: 'mvm', amount: 500),
    ]);

    expect(
      seed
          .select(minimumAmountScaled100: 400, maximumAmountScaled100: 800)
          .entryIds,
      <String>['c', 'd'],
    );
    expect(
      seed
          .select(
            categoryId: 'utilities',
            minimumAmountScaled100: 400,
            maximumAmountScaled100: 800,
          )
          .entryIds,
      <String>['c'],
    );
  });

  test(
    'AMD-02: derives a visible Year amount domain from prepared membership',
    () {
      final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
        DashboardLedgerEntry(
          id: 'all-time-rent',
          categoryId: 'housing',
          partnerId: 'landlord',
          direction: 'expense',
          amountMinor: 26000000,
          bookedLocalEpochDay: LocalDate(year: 2026, month: 1, day: 5).epochDay,
          bookedLocalTimeMinutes: 600,
        ),
        DashboardLedgerEntry(
          id: 'fastfood-small',
          categoryId: 'fastfood',
          partnerId: 'kfc',
          direction: 'expense',
          amountMinor: 180000,
          bookedLocalEpochDay: LocalDate(year: 2027, month: 1, day: 5).epochDay,
          bookedLocalTimeMinutes: 600,
        ),
        DashboardLedgerEntry(
          id: 'fastfood-max',
          categoryId: 'fastfood',
          partnerId: 'mcdonalds',
          direction: 'expense',
          amountMinor: 1350000,
          bookedLocalEpochDay: LocalDate(
            year: 2027,
            month: 12,
            day: 5,
          ).epochDay,
          bookedLocalTimeMinutes: 600,
        ),
      ]);

      final domain = seed.amountDomain(
        timeScope: const YearScope(2027),
        categoryId: 'fastfood',
      );

      expect(domain.entryCount, 2);
      expect(domain.minimumAmountScaled100, 180000);
      expect(domain.maximumAmountScaled100, 1350000);
    },
  );

  test(
    'RED: unchanged prepared membership is reused by identity when another focus dimension clears',
    () {
      final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
        row('a', category: 'food', partner: 'market'),
        row('b', category: 'utilities', partner: 'mvm'),
        row('c', category: 'utilities', partner: 'market'),
      ]);

      final categoryOnly = seed.select(categoryId: 'utilities');
      final afterPartnerClear = seed.select(categoryId: 'utilities');

      expect(
        identical(categoryOnly.entryIndices, afterPartnerClear.entryIndices),
        isTrue,
        reason:
            'Clearing partner focus must reuse the retained category ordinal '
            'membership rather than copy an equivalent list.',
      );
    },
  );
}

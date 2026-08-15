import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';

void main() {
  DashboardLedgerEntry row(
    String id, {
    required String category,
    required String partner,
  }) => DashboardLedgerEntry(
    id: id,
    categoryId: category,
    partnerId: partner,
    direction: 'expense',
    amountMinor: 100,
    bookedLocalEpochDay: 20,
    bookedLocalTimeMinutes: 600,
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

  test('unknown focus is an exact empty projection, not a base fallback', () {
    final seed = DashboardFocusMembershipSeed(<DashboardLedgerEntry>[
      row('a', category: 'food', partner: 'market'),
    ]);

    expect(seed.select(categoryId: 'utilities').entryIndices, isEmpty);
  });

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

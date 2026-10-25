import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';

void main() {
  test(
    'pending unknown-amount ghosts retain a visible, non-financial label',
    () {
      final row = DashboardLogRowViewModel.fromLedgerEntry(
        const DashboardLedgerEntry(
          id: 'ghost:occurrence-1',
          partnerId: 'partner-1',
          partnerDisplayName: 'Netflix',
          categoryId: 'category-1',
          categoryDisplayName: 'Előfizetések',
          categoryColorId: 'blue',
          categoryIconId: 'subscription',
          direction: 'expense',
          amountMinor: 0,
          amountIsUnknown: true,
          isPendingGhost: true,
          recurrenceOccurrenceId: 'occurrence-1',
          bookedLocalEpochDay: 20_500,
          bookedLocalTimeMinutes: 480,
        ),
      );

      expect(row.isPendingGhost, isTrue);
      expect(row.hasGhostOrigin, isTrue);
      expect(row.amountIsUnknown, isTrue);
      expect(row.formattedAmount, 'Változó összeg');
      expect(row.categoryDisplayName, 'Várható · Előfizetések');
      expect(row.semanticLabel, startsWith('Várható, Netflix'));
    },
  );

  test(
    'explicit category assignments retain their override identity for painter badges',
    () {
      final row = DashboardLogRowViewModel.fromLedgerEntry(
        const DashboardLedgerEntry(
          id: 'ghost:override-1',
          partnerId: 'partner-1',
          partnerDisplayName: 'Netflix',
          categoryId: 'category-entertainment',
          categoryDisplayName: 'Szórakozás',
          categoryColorId: 'orange',
          categoryIconId: 'gamepad',
          assignmentMode: 'entryOverride',
          direction: 'expense',
          amountMinor: 449000,
          isPendingGhost: true,
          recurrenceOccurrenceId: 'occurrence-override-1',
          bookedLocalEpochDay: 20_500,
          bookedLocalTimeMinutes: 480,
        ),
      );

      expect(row.hasGhostOrigin, isTrue);
      expect(row.hasCategoryOverride, isTrue);
      expect(row.categoryColorId, 'orange');
      expect(row.categoryIconId, 'gamepad');
    },
  );
}

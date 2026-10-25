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
}

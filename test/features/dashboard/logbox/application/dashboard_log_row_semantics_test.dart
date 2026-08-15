import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_view_models.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';

void main() {
  test(
    'RED: prepared LogBox rows retain category and partner focus semantics',
    () {
      final row = DashboardLogViewModelProjector.presentRow(
        const DashboardLedgerEntry(
          id: 'entry-1',
          partnerId: 'partner-1',
          categoryId: 'category-1',
          direction: 'expense',
          amountMinor: -12345,
          bookedLocalEpochDay: 20600,
          bookedLocalTimeMinutes: 600,
          partnerDisplayName: 'Partner',
          categoryDisplayName: 'Category',
          categoryColorId: 'color_02',
          categoryIconId: 'icon_02',
        ),
      );

      expect(row.categoryId, 'category-1');
      expect(row.partnerId, 'partner-1');
      expect(row.partnerDisplayName, 'Partner');
    },
  );
}

import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day group page preserves a complete day and its canonical identity', () {
    const scopeKey = 'expense|day:2026-03-13|categories:|partners:|refinements:';
    const date = LocalDate(year: 2026, month: 3, day: 13);
    const rows = <DashboardLedgerEntry>[
      DashboardLedgerEntry(
        id: 'entry-b',
        partnerId: 'partner-1',
        categoryId: 'category-1',
        direction: 'expense',
        amountMinor: 500000,
        bookedLocalEpochDay: 20525,
        bookedLocalTimeMinutes: 720,
      ),
      DashboardLedgerEntry(
        id: 'entry-a',
        partnerId: 'partner-1',
        categoryId: 'category-1',
        direction: 'expense',
        amountMinor: 401489,
        bookedLocalEpochDay: 20525,
        bookedLocalTimeMinutes: 540,
      ),
    ];

    const page = DashboardDayGroupPage(
      canonicalQueryKey: scopeKey,
      coreRevision: 12,
      groups: <DashboardDayLogGroup>[
        DashboardDayLogGroup(localDate: date, rows: rows),
      ],
      nextCursor: DashboardDayGroupPageCursor(
        beforeLocalDateExclusive: LocalDate(year: 2026, month: 3, day: 12),
      ),
    );

    expect(page.groups, hasLength(1));
    expect(page.groups.single.localDate, date);
    expect(page.groups.single.rows, hasLength(2));
    expect(
      page.groups.single.rows.fold<int>(
        0,
        (total, row) => total + row.amountMinor,
      ),
      901489,
    );
    expect(page.nextCursor!.beforeLocalDateExclusive.isoString, '2026-03-12');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

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
    'entry override keeps the partner avatar while exposing the effective category badge',
    () {
      final row = DashboardLogRowViewModel.fromLedgerEntry(
        const DashboardLedgerEntry(
          id: 'ghost:override-1',
          partnerId: 'partner-1',
          partnerDisplayName: 'Netflix',
          partnerAvatarCategoryId: 'category-subscription',
          partnerAvatarColorId: 'blue',
          partnerAvatarIconId: 'subscription',
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
      expect(row.partnerAvatarColorId, 'blue');
      expect(row.partnerAvatarIconId, 'subscription');
    },
  );

  test('saved category visual patch replaces one resident row only', () {
    const entry = DashboardLedgerEntry(
      id: 'entry-1',
      partnerId: 'partner-1',
      partnerDisplayName: 'Tesco',
      partnerAvatarCategoryId: 'food',
      partnerAvatarColorId: 'blue',
      partnerAvatarIconId: 'basket',
      categoryId: 'food',
      categoryDisplayName: 'Élelmiszer',
      categoryColorId: 'blue',
      categoryIconId: 'basket',
      assignmentMode: 'partnerDefault',
      direction: 'expense',
      amountMinor: 50000,
      bookedLocalEpochDay: 20500,
      bookedLocalTimeMinutes: 600,
    );
    final viewport = DashboardLogViewportState.deferredPreparedOrdered(
      scope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
      revision: 7,
      entries: const <DashboardLedgerEntry>[entry],
      entryCount: 1,
      nextCursor: null,
    );
    final originalViewportId = viewport.viewportId;
    final patched = viewport.withVisualPatch(
      const DashboardLedgerVisualPatch(
        entryId: 'entry-1',
        partnerId: 'partner-1',
        direction: 'expense',
        amountMinor: 50000,
        bookedLocalEpochDay: 20500,
        bookedLocalTimeMinutes: 600,
        partnerDisplayName: 'Tesco',
        partnerAvatarCategoryId: 'food',
        partnerAvatarColorId: 'blue',
        partnerAvatarIconId: 'basket',
        categoryId: 'clothes',
        categoryDisplayName: 'Ruházat',
        categoryColorId: 'orange',
        categoryIconId: 'hanger',
        assignmentMode: 'entryOverride',
        entryRevision: 8,
      ),
    );

    expect(patched, isNotNull);
    expect(patched!.viewportId, isNot(originalViewportId));
    final row = patched.flatItems.single.row;
    expect(row.categoryDisplayName, 'Ruházat');
    expect(row.hasCategoryOverride, isTrue);
    expect(row.partnerAvatarColorId, 'blue');
    expect(row.partnerAvatarIconId, 'basket');
  });

  test(
    'one accepted save patch is shared by resident ghost-mode projections',
    () {
      const entry = DashboardLedgerEntry(
        id: 'entry-1',
        partnerId: 'partner-1',
        partnerDisplayName: 'Tesco',
        partnerAvatarCategoryId: 'food',
        partnerAvatarColorId: 'blue',
        partnerAvatarIconId: 'basket',
        categoryId: 'food',
        categoryDisplayName: 'Élelmiszer',
        categoryColorId: 'blue',
        categoryIconId: 'basket',
        assignmentMode: 'partnerDefault',
        direction: 'expense',
        amountMinor: 50000,
        bookedLocalEpochDay: 20500,
        bookedLocalTimeMinutes: 600,
      );
      final cache = DashboardLogRowProjectionCache(const <DashboardLedgerEntry>[
        entry,
      ]);
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final first = DashboardLogViewportState.deferredPreparedReferences(
        scope: scope,
        revision: 7,
        rowTable: const <DashboardLedgerEntry>[entry],
        rowProjectionCache: cache,
        rowIndices: const <int>[0],
        entryCount: 1,
        nextCursor: null,
      );
      final second = DashboardLogViewportState.deferredPreparedReferences(
        scope: scope,
        revision: 7,
        rowTable: const <DashboardLedgerEntry>[entry],
        rowProjectionCache: cache,
        rowIndices: const <int>[0],
        entryCount: 1,
        nextCursor: null,
      );

      final patched = first.withVisualPatch(
        const DashboardLedgerVisualPatch(
          entryId: 'entry-1',
          partnerId: 'partner-1',
          direction: 'expense',
          amountMinor: 50000,
          bookedLocalEpochDay: 20500,
          bookedLocalTimeMinutes: 600,
          partnerDisplayName: 'Tesco',
          partnerAvatarCategoryId: 'food',
          partnerAvatarColorId: 'blue',
          partnerAvatarIconId: 'basket',
          categoryId: 'clothes',
          categoryDisplayName: 'Ruházat',
          categoryColorId: 'orange',
          categoryIconId: 'hanger',
          assignmentMode: 'entryOverride',
          entryRevision: 8,
        ),
      );

      expect(patched, isNotNull);
      expect(second.flatItems.single.row.categoryDisplayName, 'Ruházat');
      expect(second.flatItems.single.row.hasCategoryOverride, isTrue);
      expect(second.flatItems.single.row.partnerAvatarIconId, 'basket');
    },
  );
}

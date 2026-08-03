import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_view_models.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';

void main() {
  test(
    'projects one immutable snapshot into deterministic day groups and rows',
    () {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final snapshot = DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 4,
        scope: scope,
        coreRevision: 8,
        totalMinor: 123,
        entryCount: 2,
        nextCursor: const <String, Object?>{'before': 17},
        isPreview: true,
        entries: const [
          DashboardLedgerEntry(
            id: 'later',
            partnerId: 'p2',
            categoryId: 'c2',
            direction: 'expense',
            amountMinor: 77,
            bookedLocalEpochDay: 20600,
            bookedLocalTimeMinutes: 615,
            partnerDisplayName: 'Beta Market',
            categoryDisplayName: 'Egyéb',
            categoryColorId: 'color_01',
            categoryIconId: 'icon_01',
          ),
          DashboardLedgerEntry(
            id: 'earlier',
            partnerId: 'p1',
            categoryId: 'c1',
            direction: 'expense',
            amountMinor: 46,
            bookedLocalEpochDay: 20599,
            bookedLocalTimeMinutes: 75,
            partnerDisplayName: 'Alpha Market',
            categoryDisplayName: 'Élelmiszer',
            categoryColorId: 'color_02',
            categoryIconId: 'icon_02',
          ),
        ],
      );

      final state = DashboardLogViewModelProjector.presentSnapshot(snapshot);

      expect(state.queryKey, scope.key);
      expect(state.revision, 8);
      expect(state.entryCount, 2);
      expect(state.isPreview, isTrue);
      expect(state.isCommitted, isFalse);
      expect(state.nextCursor, const <String, Object?>{'before': 17});
      expect(state.groups, hasLength(2));
      expect(state.groups.first.rows.single.displayName, 'Beta Market');
      expect(state.groups.last.rows.single.formattedAmount, '-0,46 Ft');
      expect(state.groups.last.rows.single.categoryDisplayName, 'Élelmiszer');
    },
  );

  test(
    'preview promotion updates metadata without rebinding the projected list',
    () {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final preview = DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 1,
        scope: scope,
        coreRevision: 8,
        totalMinor: 123,
        entryCount: 1,
        isPreview: true,
        entries: const [
          DashboardLedgerEntry(
            id: 'entry',
            partnerId: 'p',
            categoryId: 'c',
            direction: 'expense',
            amountMinor: 123,
            bookedLocalEpochDay: 20600,
            bookedLocalTimeMinutes: 1,
          ),
        ],
      );
      final committed = preview.copyWith(generation: 2, isPreview: false);
      final store = DashboardPresentationStore();
      final adapter = DashboardLogPresentationAdapter(store: store);
      addTearDown(adapter.dispose);
      addTearDown(store.dispose);

      store.publish(preview);
      final groups = adapter.state!.groups;
      store.promote(committed);

      expect(adapter.state!.isCommitted, isTrue);
      expect(identical(adapter.state!.groups, groups), isTrue);
      expect(adapter.listRebindCount, 1);
    },
  );

  test('preview target swaps the complete LogBox state without I/O', () {
    final firstScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 1)),
    );
    final secondScope = firstScope.copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 2)),
    );
    final first = DashboardPresentationSnapshot(
      queryKey: firstScope.key,
      generation: 1,
      scope: firstScope,
      coreRevision: 1,
      totalMinor: 123,
      entryCount: 3,
      isPreview: true,
      entries: const [
        DashboardLedgerEntry(
          id: 'a',
          partnerId: 'p',
          categoryId: 'c',
          direction: 'expense',
          amountMinor: 123,
          bookedLocalEpochDay: 20600,
          bookedLocalTimeMinutes: 60,
          partnerDisplayName: 'A',
        ),
      ],
    );
    final second = DashboardPresentationSnapshot(
      queryKey: secondScope.key,
      generation: 2,
      scope: secondScope,
      coreRevision: 1,
      totalMinor: 456,
      entryCount: 4,
      isPreview: true,
      entries: const [
        DashboardLedgerEntry(
          id: 'd',
          partnerId: 'p',
          categoryId: 'c',
          direction: 'expense',
          amountMinor: 456,
          bookedLocalEpochDay: 20601,
          bookedLocalTimeMinutes: 120,
          partnerDisplayName: 'D',
        ),
      ],
    );
    final store = DashboardPresentationStore();
    final adapter = DashboardLogPresentationAdapter(store: store);
    addTearDown(adapter.dispose);
    addTearDown(store.dispose);
    store.publish(first, activate: false);
    store.publish(second, activate: false);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: firstScope.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );
    expect(adapter.state?.queryKey, firstScope.key);
    expect(adapter.state?.groups.single.rows.single.displayName, 'A');

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: secondScope.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );
    expect(adapter.state?.queryKey, secondScope.key);
    expect(adapter.state?.entryCount, 4);
    expect(adapter.state?.groups.single.rows.single.displayName, 'D');
    expect(store.repositoryReadCountDuringMotion, 0);
    expect(store.nativeCallCountDuringMotion, 0);
  });
}

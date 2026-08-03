import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_paging_coordinator.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _PagingRepository implements DashboardLedgerRepository {
  final Completer<DashboardLedgerResult> nextPage =
      Completer<DashboardLedgerResult>();
  int reads = 0;
  Map<String, Object?>? lastCursor;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    reads += 1;
    lastCursor = after;
    return nextPage.future;
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => const Stream<DashboardLedgerResult>.empty();
}

void main() {
  test(
    'paging is committed-only and deduplicates an in-flight cursor',
    () async {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final first = const DashboardLedgerEntry(
        id: 'first',
        partnerId: 'p1',
        categoryId: 'c1',
        direction: 'expense',
        amountMinor: 100,
        bookedLocalEpochDay: 20600,
        bookedLocalTimeMinutes: 60,
      );
      final second = const DashboardLedgerEntry(
        id: 'second',
        partnerId: 'p2',
        categoryId: 'c2',
        direction: 'expense',
        amountMinor: 200,
        bookedLocalEpochDay: 20600,
        bookedLocalTimeMinutes: 30,
      );
      final repository = _PagingRepository();
      final store = DashboardPresentationStore();
      final coordinator = DashboardLogPagingCoordinator(
        store: store,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(store.dispose);
      store.publish(
        DashboardPresentationSnapshot(
          queryKey: scope.key,
          generation: 1,
          scope: scope,
          coreRevision: 1,
          totalMinor: 100,
          entryCount: 1,
          entries: [first],
          nextCursor: const <String, Object?>{'entryId': 'first'},
        ),
      );
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.month,
          parentQueryKey: scope.key,
          childQueryKey: null,
          railOpen: false,
          direction: LedgerDirection.expense,
          presentationEpoch: 1,
        ),
      );

      final firstRequest = coordinator.loadNextPage();
      final duplicateRequest = coordinator.loadNextPage();
      await Future<void>.value();
      expect(repository.reads, 1);
      expect(repository.lastCursor, const <String, Object?>{
        'entryId': 'first',
      });

      repository.nextPage.complete(
        DashboardLedgerResult(
          totalMinor: 300,
          entryCount: 2,
          entries: [second],
          scopeKey: scope.key.value,
          coreRevision: 1,
        ),
      );
      await Future.wait([firstRequest, duplicateRequest]);

      expect(store.activeSnapshot?.entries.map((entry) => entry.id), [
        'first',
        'second',
      ]);
      expect(store.activeSnapshot?.nextCursor, isNull);
    },
  );

  test(
    'late committed page is rejected after the visible target changes',
    () async {
      final firstScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final secondScope = firstScope.copyWith(
        timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
      );
      final repository = _PagingRepository();
      final store = DashboardPresentationStore();
      final coordinator = DashboardLogPagingCoordinator(
        store: store,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(store.dispose);
      store.publish(
        DashboardPresentationSnapshot(
          queryKey: firstScope.key,
          generation: 1,
          scope: firstScope,
          coreRevision: 1,
          totalMinor: 100,
          entryCount: 1,
          nextCursor: const <String, Object?>{'entryId': 'first'},
        ),
      );
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

      final request = coordinator.loadNextPage();
      await Future<void>.value();
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
      repository.nextPage.complete(
        DashboardLedgerResult(
          totalMinor: 300,
          entryCount: 2,
          scopeKey: firstScope.key.value,
          coreRevision: 1,
          entries: const [
            DashboardLedgerEntry(
              id: 'late',
              partnerId: 'p',
              categoryId: 'c',
              direction: 'expense',
              amountMinor: 200,
              bookedLocalEpochDay: 20600,
              bookedLocalTimeMinutes: 30,
            ),
          ],
        ),
      );
      await request;

      expect(store.activeSnapshot?.queryKey, firstScope.key);
      expect(store.activeSnapshot?.entries, isEmpty);
    },
  );

  test('preview paging is never requested', () async {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final repository = _PagingRepository();
    final store = DashboardPresentationStore();
    final coordinator = DashboardLogPagingCoordinator(
      store: store,
      repository: repository,
    );
    addTearDown(coordinator.dispose);
    addTearDown(store.dispose);
    store.publish(
      DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 1,
        scope: scope,
        coreRevision: 1,
        totalMinor: 100,
        entryCount: 1,
        isPreview: true,
        nextCursor: const <String, Object?>{'entryId': 'first'},
      ),
    );
    await coordinator.loadNextPage();

    expect(repository.reads, 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _DirectionRepository implements DashboardLedgerRepository {
  int reads = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads += 1;
    final isIncome = scope.direction == LedgerDirection.income;
    return DashboardLedgerResult(
      totalMinor: isIncome ? 70700000 : 68900000,
      entryCount: isIncome ? 6 : 94,
      coreRevision: 7,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => Stream.fromFuture(read(scope, pageSize: pageSize, after: after));
}

void main() {
  test('direction is part of the presentation key and cannot cross-serve', () {
    final month = const MonthScope(YearMonth(year: 2026, month: 7));
    final expense = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: month,
    );
    final income = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: month,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);

    store.publish(
      DashboardPresentationSnapshot(
        queryKey: expense.key,
        generation: 1,
        coreRevision: 7,
        totalMinor: 68900000,
        entryCount: 94,
      ),
    );

    expect(store.snapshotFor(expense.key)?.totalMinor, 68900000);
    expect(store.snapshotFor(income.key), isNull);
    expect(store.cacheHitCount, 1);
    expect(store.cacheMissCount, 1);
  });

  test('one immutable snapshot supplies amount, count and rows atomically', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final snapshot = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 3,
      coreRevision: 9,
      totalMinor: 70700000,
      entryCount: 6,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);

    store.publish(snapshot);

    expect(identical(store.activeSnapshot, snapshot), isTrue);
    expect(store.activeSnapshot?.queryKey, scope.key);
    expect(store.activeSnapshot?.totalMinor, 70700000);
    expect(store.activeSnapshot?.entryCount, 6);
    expect(store.activeSnapshot?.entries, isEmpty);
  });

  test('publishing the same snapshot does not notify or rebind', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final snapshot = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 1,
      coreRevision: 1,
      totalMinor: 1,
      entryCount: 1,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications += 1);

    store.publish(snapshot);
    store.publish(snapshot);

    expect(notifications, 1);
    expect(store.previewPromotionCount, 0);
  });

  test('promoting an identical preview is a visual no-op', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final preview = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 11,
      scope: scope,
      coreRevision: 4,
      totalMinor: 68900000,
      entryCount: 94,
      isPreview: true,
    );
    final committed = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 12,
      scope: scope,
      coreRevision: 4,
      totalMinor: 68900000,
      entryCount: 94,
      isPreview: false,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications += 1);

    store.publish(preview);
    final rebound = store.promote(committed);

    expect(rebound, isFalse);
    expect(notifications, 1);
    expect(store.previewPromotionCount, 1);
    expect(identical(store.activeSnapshot, committed), isTrue);
  });

  test('parent emission cannot replace a centered child preview', () {
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final child = parent.copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 15)),
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);

    final childPreview = DashboardPresentationSnapshot(
      queryKey: child.key,
      generation: 2,
      scope: child,
      coreRevision: 4,
      totalMinor: 123,
      entryCount: 2,
      isPreview: true,
    );
    final parentFresh = DashboardPresentationSnapshot(
      queryKey: parent.key,
      generation: 3,
      scope: parent,
      coreRevision: 4,
      totalMinor: 999,
      entryCount: 20,
    );

    store.publish(childPreview);
    final activated = store.publish(parentFresh);

    expect(activated, isFalse);
    expect(identical(store.activeSnapshot, childPreview), isTrue);
    expect(store.snapshotFor(parent.key), same(parentFresh));
  });

  test('narrow metrics publish cannot discard detailed rows for its key', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final entry = const DashboardLedgerEntry(
      id: 'entry-1',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 100,
      bookedLocalEpochDay: 1,
      bookedLocalTimeMinutes: 60,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);

    store.publish(
      DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 1,
        scope: scope,
        coreRevision: 2,
        totalMinor: 100,
        entryCount: 1,
        entries: [entry],
      ),
    );
    store.publish(
      DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 2,
        scope: scope,
        coreRevision: 2,
        totalMinor: 100,
        entryCount: 1,
      ),
    );

    expect(store.activeSnapshot?.entries, [entry]);
  });

  test(
    'prewarming opposite direction makes the later toggle cache-only',
    () async {
      final repository = _DirectionRepository();
      final store = DashboardPresentationStore();
      final controller = CurrentQueryController(
        repository: repository,
        presentationStore: store,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(store.dispose);

      controller.refresh();
      await Future<void>.value();
      await controller.prewarm(
        controller.state.scope.copyWith(direction: LedgerDirection.income),
      );
      final readsAfterPrewarm = repository.reads;

      controller.setDirection(LedgerDirection.income);

      expect(repository.reads, readsAfterPrewarm);
      expect(controller.state.scope.direction, LedgerDirection.income);
      expect(store.activeSnapshot?.queryKey, controller.state.scope.key);
      expect(store.activeSnapshot?.totalMinor, 70700000);
      expect(store.activeSnapshot?.entryCount, 6);
    },
  );
}

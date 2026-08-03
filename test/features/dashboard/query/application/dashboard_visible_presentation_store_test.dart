import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('visible target resolves only its expected query key atomically', () {
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final child = parent.copyWith(
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final childSnapshot = DashboardPresentationSnapshot(
      queryKey: child.key,
      generation: 1,
      scope: child,
      coreRevision: 1,
      totalMinor: 68900000,
      entryCount: 94,
      isPreview: true,
    );
    final parentSnapshot = DashboardPresentationSnapshot(
      queryKey: parent.key,
      generation: 2,
      scope: parent,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(childSnapshot, activate: false);
    store.publish(parentSnapshot, activate: false);

    final target = DashboardVisiblePresentationTarget(
      plane: TimePlane.year,
      parentQueryKey: parent.key,
      childQueryKey: child.key,
      railOpen: false,
      direction: LedgerDirection.expense,
      presentationEpoch: 2,
    );
    var notifications = 0;
    store.addListener(() => notifications += 1);

    store.setVisibleTarget(target);

    expect(target.expectedVisibleQueryKey, parent.key);
    expect(identical(store.activeSnapshot, parentSnapshot), isTrue);
    expect(store.visiblePresentationPublishCount, 1);
    expect(store.crossKeyPublishAttemptCount, 0);
    expect(notifications, 1);
  });

  test(
    'rail close invalidates the child target before delayed child publish',
    () {
      final parent = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const YearScope(2026),
      );
      final child = parent.copyWith(
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
      );
      final parentSnapshot = DashboardPresentationSnapshot(
        queryKey: parent.key,
        generation: 3,
        scope: parent,
        coreRevision: 1,
        totalMinor: 492500000,
        entryCount: 658,
      );
      final childSnapshot = DashboardPresentationSnapshot(
        queryKey: child.key,
        generation: 4,
        scope: child,
        coreRevision: 1,
        totalMinor: 61200000,
        entryCount: 94,
        isPreview: true,
      );
      final store = DashboardPresentationStore();
      addTearDown(store.dispose);
      store.publish(parentSnapshot, activate: false);
      store.publish(childSnapshot, activate: false);

      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.year,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: true,
          direction: LedgerDirection.expense,
          presentationEpoch: 1,
        ),
      );
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.year,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: false,
          direction: LedgerDirection.expense,
          presentationEpoch: 2,
        ),
      );

      final delayedChildAccepted = store.publish(
        childSnapshot.copyWith(generation: 5),
      );

      expect(delayedChildAccepted, isFalse);
      expect(store.activeSnapshot?.queryKey, parent.key);
      expect(store.rejectedChildCallbackCount, greaterThanOrEqualTo(1));
    },
  );

  test('the same month snapshot is reused as year child and month mother', () {
    final month = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final year = month.copyWith(timeScope: const YearScope(2026));
    final monthSnapshot = DashboardPresentationSnapshot(
      queryKey: month.key,
      generation: 7,
      scope: month,
      coreRevision: 1,
      totalMinor: 68900000,
      entryCount: 94,
      isPreview: true,
    );
    final yearSnapshot = DashboardPresentationSnapshot(
      queryKey: year.key,
      generation: 8,
      scope: year,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(monthSnapshot, activate: false);
    store.publish(yearSnapshot, activate: false);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: year.key,
        childQueryKey: month.key,
        railOpen: true,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );
    expect(store.activeSnapshot?.queryKey, month.key);
    expect(store.activeSnapshot?.entryCount, 94);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: month.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );

    expect(store.activeSnapshot?.queryKey, month.key);
    expect(store.activeSnapshot?.totalMinor, 68900000);
    expect(store.activeSnapshot?.entryCount, 94);
    expect(store.activeSnapshot?.coreRevision, 1);
  });

  test('direction target changes amount, count and LogBox key together', () {
    final month = const MonthScope(YearMonth(year: 2026, month: 7));
    final expense = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: month,
    );
    final income = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: month,
    );
    final expenseSnapshot = DashboardPresentationSnapshot(
      queryKey: expense.key,
      generation: 1,
      scope: expense,
      coreRevision: 1,
      totalMinor: 68900000,
      entryCount: 94,
    );
    final incomeSnapshot = DashboardPresentationSnapshot(
      queryKey: income.key,
      generation: 2,
      scope: income,
      coreRevision: 1,
      totalMinor: 70700000,
      entryCount: 6,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(expenseSnapshot, activate: false);
    store.publish(incomeSnapshot, activate: false);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: expense.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: income.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.income,
        presentationEpoch: 2,
      ),
    );

    final visible = store.activeSnapshot;
    expect(visible?.queryKey, income.key);
    expect(visible?.scope?.direction, LedgerDirection.income);
    expect(visible?.totalMinor, 70700000);
    expect(visible?.entryCount, 6);
  });

  test('cached adjacent year target swaps without a loading placeholder', () {
    final year2026 = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final year2027 = year2026.copyWith(timeScope: const YearScope(2027));
    final first = DashboardPresentationSnapshot(
      queryKey: year2026.key,
      generation: 1,
      scope: year2026,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
    );
    final second = DashboardPresentationSnapshot(
      queryKey: year2027.key,
      generation: 2,
      scope: year2027,
      coreRevision: 1,
      totalMinor: 100,
      entryCount: 2,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(first, activate: false);
    store.publish(second, activate: false);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: year2026.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );
    final notificationsBeforeSwap = store.visiblePresentationPublishCount;
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: year2027.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );

    expect(store.activeSnapshot?.queryKey, year2027.key);
    expect(store.activeSnapshot?.totalMinor, 100);
    expect(store.activeSnapshot?.entryCount, 2);
    expect(store.visiblePresentationPublishCount, notificationsBeforeSwap + 1);
    expect(store.stalePlaceholderPublishCount, 0);
  });

  test('cold adjacent year retains the complete outgoing snapshot', () {
    final year2026 = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final year2027 = year2026.copyWith(timeScope: const YearScope(2027));
    final outgoing = DashboardPresentationSnapshot(
      queryKey: year2026.key,
      generation: 1,
      scope: year2026,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
      entries: const [],
    );
    final loadingIncoming = DashboardPresentationSnapshot(
      queryKey: year2027.key,
      generation: 2,
      scope: year2027,
      isLoading: true,
      isStale: true,
    );
    final incoming = DashboardPresentationSnapshot(
      queryKey: year2027.key,
      generation: 3,
      scope: year2027,
      coreRevision: 1,
      totalMinor: 510000000,
      entryCount: 701,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(outgoing, activate: false);
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: year2026.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );

    final publishesBeforeColdSwap = store.visiblePresentationPublishCount;
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: year2027.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );
    final acceptedLoading = store.publish(loadingIncoming);

    expect(acceptedLoading, isFalse);
    expect(store.activeSnapshot?.queryKey, year2026.key);
    expect(store.activeSnapshot?.totalMinor, 492500000);
    expect(store.activeSnapshot?.entryCount, 658);
    expect(store.visiblePresentationPublishCount, publishesBeforeColdSwap);
    expect(store.stalePlaceholderPublishCount, 1);

    final acceptedIncoming = store.publish(incoming);

    expect(acceptedIncoming, isTrue);
    expect(store.activeSnapshot?.queryKey, year2027.key);
    expect(store.activeSnapshot?.totalMinor, 510000000);
    expect(store.activeSnapshot?.entryCount, 701);
    expect(store.visiblePresentationPublishCount, publishesBeforeColdSwap + 1);
  });

  test('zero-result child close restores the complete parent snapshot', () {
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final child = parent.copyWith(
      timeScope: const MonthScope(YearMonth(year: 2026, month: 12)),
    );
    final parentSnapshot = DashboardPresentationSnapshot(
      queryKey: parent.key,
      generation: 1,
      scope: parent,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
    );
    final childSnapshot = DashboardPresentationSnapshot(
      queryKey: child.key,
      generation: 2,
      scope: child,
      coreRevision: 1,
      totalMinor: 0,
      entryCount: 0,
      isPreview: true,
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    store.publish(parentSnapshot, activate: false);
    store.publish(childSnapshot, activate: false);

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: parent.key,
        childQueryKey: child.key,
        railOpen: true,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );
    expect(store.activeSnapshot?.queryKey, child.key);
    expect(store.activeSnapshot?.totalMinor, 0);
    expect(store.activeSnapshot?.entryCount, 0);

    final publishesBeforeClose = store.visiblePresentationPublishCount;
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: parent.key,
        childQueryKey: child.key,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );

    expect(store.activeSnapshot?.queryKey, parent.key);
    expect(store.activeSnapshot?.totalMinor, 492500000);
    expect(store.activeSnapshot?.entryCount, 658);
    expect(store.visiblePresentationPublishCount, publishesBeforeClose + 1);
    expect(store.stalePlaceholderPublishCount, 0);
  });

  test('repeated rail open and close rejects every delayed child publish', () {
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    final parentSnapshot = DashboardPresentationSnapshot(
      queryKey: parent.key,
      generation: 1,
      scope: parent,
      coreRevision: 1,
      totalMinor: 492500000,
      entryCount: 658,
    );
    store.publish(parentSnapshot, activate: false);

    for (var cycle = 0; cycle < 100; cycle += 1) {
      final child = parent.copyWith(
        timeScope: MonthScope(YearMonth(year: 2026, month: cycle % 12 + 1)),
      );
      final childSnapshot = DashboardPresentationSnapshot(
        queryKey: child.key,
        generation: cycle + 2,
        scope: child,
        coreRevision: 1,
        totalMinor: cycle.isEven ? 61200000 : 0,
        entryCount: cycle.isEven ? 94 : 0,
        isPreview: true,
      );
      store.publish(childSnapshot, activate: false);
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.year,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: true,
          direction: LedgerDirection.expense,
          presentationEpoch: cycle * 2 + 1,
        ),
      );
      expect(store.activeSnapshot?.queryKey, child.key);
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.year,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: false,
          direction: LedgerDirection.expense,
          presentationEpoch: cycle * 2 + 2,
        ),
      );
      final accepted = store.publish(
        childSnapshot.copyWith(generation: cycle + 1002),
      );
      expect(accepted, isFalse);
      expect(store.activeSnapshot?.queryKey, parent.key);
      expect(store.activeSnapshot?.totalMinor, 492500000);
      expect(store.activeSnapshot?.entryCount, 658);
    }

    expect(store.rejectedChildCallbackCount, 100);
    expect(store.stalePlaceholderPublishCount, 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test('publishes one complete frame and rejects older epochs', () {
    final store = DashboardVisibleFrameStore();
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(store.publish(_frame(day: 2, epoch: 4, generation: 8)), isTrue);
    expect(store.publish(_frame(day: 1, epoch: 3, generation: 99)), isFalse);

    expect(store.value!.queryKey, _keyForDay(2));
    expect(store.visiblePublishCount, 1);
    expect(store.staleFrameRejectCount, 1);
    expect(notifications, 1);
  });

  test('same epoch rejects out-of-order generations', () {
    final store = DashboardVisibleFrameStore();
    store.publish(_frame(day: 3, epoch: 7, generation: 12));

    expect(store.publish(_frame(day: 2, epoch: 7, generation: 11)), isFalse);
    expect(store.value!.queryKey, _keyForDay(3));
    expect(store.staleFrameRejectCount, 1);
  });

  test('same visual frame is a notification no-op', () {
    final store = DashboardVisibleFrameStore();
    final frame = _frame(day: 5, epoch: 2, generation: 3);
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(store.publish(frame), isTrue);
    expect(store.publish(frame), isFalse);
    expect(store.visiblePublishCount, 1);
    expect(notifications, 1);
  });

  test('settle promotion changes no visual counters or lane identities', () {
    final store = DashboardVisibleFrameStore();
    final preview = _frame(day: 7, epoch: 9, generation: 14);
    store.publish(preview);
    final before = store.visiblePublishCount;
    var notifications = 0;
    store.addListener(() => notifications += 1);

    expect(
      store.promoteCommitted(expectedKey: preview.queryKey, epoch: 9),
      isTrue,
    );

    expect(store.value!.mode, DashboardVisibleMode.committed);
    expect(store.value!.amount, same(preview.amount));
    expect(store.value!.count, same(preview.count));
    expect(store.value!.logBox, same(preview.logBox));
    expect(store.visiblePublishCount, before);
    expect(store.logRebindCount + store.amountRestartCount, 0);
    expect(notifications, 0);
  });

  test('atomically stages narrow presentation lanes from one frame', () {
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    final first = _frame(day: 4, epoch: 1, generation: 1);
    final second = _frame(day: 5, epoch: 1, generation: 2);
    var navigationNotifications = 0;
    var amountNotifications = 0;
    var countNotifications = 0;
    var logNotifications = 0;
    store.navigationLane.addListener(() => navigationNotifications += 1);
    store.amountLane.addListener(() => amountNotifications += 1);
    store.countLane.addListener(() => countNotifications += 1);
    store.logBoxLane.addListener(() => logNotifications += 1);

    expect(store.publish(first), isTrue);
    expect(store.publish(second), isTrue);

    expect(store.navigationLane.value, same(second));
    expect(store.amountLane.value, same(second));
    expect(store.countLane.value, same(second));
    expect(store.logBoxLane.value, same(second));
    expect(
      second.amountPresentationId,
      second.preparedFrame.amountPresentationId,
    );
    expect(
      second.countPresentationId,
      second.preparedFrame.countPresentationId,
    );
    expect(second.logBoxPresentationId, second.preparedFrame.logViewportId);
    expect(store.logBoxLane.value!.logBox, same(second.preparedFrame.logBox));
    expect(
      <LedgerQueryKey>{
        store.amountLane.value!.amount.queryKey,
        store.countLane.value!.count.queryKey,
        store.logBoxLane.value!.logBox.queryKey,
      },
      <LedgerQueryKey>{second.queryKey},
    );
    expect(navigationNotifications, 2);
    expect(amountNotifications, 2);
    expect(countNotifications, 2);
    expect(logNotifications, 2);

    expect(
      store.promoteCommitted(expectedKey: second.queryKey, epoch: 1),
      isTrue,
    );
    expect(navigationNotifications, 2);
    expect(amountNotifications, 2);
    expect(countNotifications, 2);
    expect(logNotifications, 2);
  });

  test('settle promotion requires the exact visible key and epoch', () {
    final store = DashboardVisibleFrameStore();
    final preview = _frame(day: 8, epoch: 11, generation: 20);
    store.publish(preview);

    expect(
      store.promoteCommitted(expectedKey: _keyForDay(7), epoch: 11),
      isFalse,
    );
    expect(
      store.promoteCommitted(expectedKey: preview.queryKey, epoch: 10),
      isFalse,
    );
    expect(store.value!.mode, DashboardVisibleMode.preview);
  });
}

DashboardVisibleFrame _frame({
  required int day,
  required int epoch,
  required int generation,
}) {
  final parent = _parentScope();
  final scope = parent.copyWith(
    timeScope: DayScope(LocalDate(year: 2026, month: 6, day: day)),
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: parent.key,
    coreRevision: 3,
    totalMinor: day * 100,
    formattedAmount: '$day,00 Ft',
    entryCount: day,
    formattedEntryCount: '$day',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: const [],
      entryCount: day,
      nextCursor: null,
      direction: LedgerDirection.income,
    ),
    presentationDigest: day,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: parent.key,
    plane: TimePlane.month,
    railOpen: true,
    semanticIndex: day - 1,
    childLabel: '$day',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: generation,
    mode: DashboardVisibleMode.preview,
  );
}

LedgerQueryKey _keyForDay(int day) => _parentScope()
    .copyWith(timeScope: DayScope(LocalDate(year: 2026, month: 6, day: day)))
    .key;

CurrentLedgerQueryScope _parentScope() => CurrentLedgerQueryScope(
  direction: LedgerDirection.income,
  timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
);

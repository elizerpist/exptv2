import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test('same display frame publishes only its last target without backlog', () {
    final scheduler = _FakeScheduler();
    final published = <String>[];
    final coalescer = DashboardDisplayFrameCoalescer(
      scheduler: scheduler,
      publish: (frame) => published.add(frame.queryKey.value),
    );

    coalescer.request(_frame(day: 1, generation: 1));
    coalescer.request(_frame(day: 2, generation: 2));
    coalescer.request(_frame(day: 3, generation: 3));

    expect(scheduler.pendingCallbackCount, 1);
    scheduler.fireFrame();
    expect(published, [_keyForDay(3).value]);
    expect(coalescer.requestCount, 3);
    expect(coalescer.publishCount, 1);
    expect(coalescer.coalescedTargetCount, 2);

    scheduler.fireFrame();
    expect(published, [_keyForDay(3).value]);
  });

  test('crossings in separate display frames are all visible', () {
    final scheduler = _FakeScheduler();
    final published = <int>[];
    final coalescer = DashboardDisplayFrameCoalescer(
      scheduler: scheduler,
      publish: (frame) => published.add(frame.semanticChildIndex),
    );

    coalescer.request(_frame(day: 4, generation: 1));
    scheduler.fireFrame();
    coalescer.request(_frame(day: 5, generation: 2));
    scheduler.fireFrame();
    coalescer.request(_frame(day: 6, generation: 3));
    scheduler.fireFrame();

    expect(published, [3, 4, 5]);
    expect(coalescer.maximumPublishesInOneDisplayFrame, 1);
  });

  test('request during publication is scheduled for the next frame', () {
    final scheduler = _FakeScheduler();
    final published = <int>[];
    late DashboardDisplayFrameCoalescer coalescer;
    coalescer = DashboardDisplayFrameCoalescer(
      scheduler: scheduler,
      publish: (frame) {
        published.add(frame.semanticChildIndex);
        if (frame.semanticChildIndex == 0) {
          coalescer.request(_frame(day: 2, generation: 2));
        }
      },
    );

    coalescer.request(_frame(day: 1, generation: 1));
    scheduler.fireFrame();
    expect(published, [0]);
    expect(scheduler.pendingCallbackCount, 1);
    scheduler.fireFrame();
    expect(published, [0, 1]);
  });
}

final class _FakeScheduler implements DashboardDisplayFrameScheduler {
  final List<VoidCallback> _callbacks = <VoidCallback>[];
  int _frameNumber = 0;

  @override
  int get currentFrameNumber => _frameNumber;

  int get pendingCallbackCount => _callbacks.length;

  @override
  void scheduleFrame(VoidCallback callback) => _callbacks.add(callback);

  void fireFrame() {
    if (_callbacks.isEmpty) return;
    _frameNumber += 1;
    final callbacks = List<VoidCallback>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

DashboardVisibleFrame _frame({required int day, required int generation}) {
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
    navigationEpoch: 1,
    presentationEpoch: 1,
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

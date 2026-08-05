import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_diagnostics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('emits the canonical profile-safe event envelope', () {
    final events = <DashboardInteractionDiagnosticEvent>[];
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(
      counters: counters,
      sink: events.add,
      verboseSemanticCrossings: true,
    );
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final child = parent.copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 14)),
    );
    final context = DashboardDiagnosticContext(
      gestureId: 8,
      motionEpoch: 13,
      navigationEpoch: 21,
      presentationEpoch: 34,
      queryKey: child.key,
      parentQueryKey: parent.key,
      coreRevision: 5,
      semanticIndex: 13,
      frameNumber: 55,
    );

    diagnostics.record(
      DashboardInteractionEvent.visibleFramePublished,
      context: context,
      source: 'preparedDeck',
      duration: const Duration(microseconds: 610),
    );

    expect(events, hasLength(1));
    final event = events.single;
    expect(event.name, 'VISIBLE_FRAME_PUBLISHED');
    expect(event.gestureId, 8);
    expect(event.motionEpoch, 13);
    expect(event.navigationEpoch, 21);
    expect(event.presentationEpoch, 34);
    expect(event.queryKey, child.key);
    expect(event.parentQueryKey, parent.key);
    expect(event.coreRevision, 5);
    expect(event.semanticIndex, 13);
    expect(event.frameNumber, 55);
    expect(event.source, 'preparedDeck');
    expect(event.durationMicros, 610);
    expect(counters.value(DashboardPerformanceMetric.visibleFramePublish), 1);
  });

  test(
    'semantic diagnostics are disabled by default without losing counts',
    () {
      final events = <DashboardInteractionDiagnosticEvent>[];
      final diagnostics = DashboardInteractionDiagnostics(sink: events.add);
      final context = DashboardDiagnosticContext.empty.copyWith(
        semanticIndex: 4,
      );

      diagnostics.record(
        DashboardInteractionEvent.motionSemanticCrossed,
        context: context,
        source: 'rail',
      );
      diagnostics.record(
        DashboardInteractionEvent.motionFrameTargetSelected,
        context: context,
        source: 'catalog',
      );

      expect(events, isEmpty);
    },
  );

  test('motion hot-path data operations are counted in fixed slots', () {
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(counters: counters);

    diagnostics.runMotionHotPath(() {
      diagnostics.recordDataOperation(DashboardDataOperation.sql);
      diagnostics.recordDataOperation(DashboardDataOperation.platformChannel);
      diagnostics.recordDataOperation(DashboardDataOperation.repositoryRead);
      diagnostics.recordDataOperation(DashboardDataOperation.liveLeaseStart);
      diagnostics.recordDataOperation(DashboardDataOperation.logBoxProjection);
      diagnostics.recordDataOperation(DashboardDataOperation.formatting);
    });

    expect(counters.value(DashboardPerformanceMetric.sqlCallsDuringMotion), 1);
    expect(
      counters.value(DashboardPerformanceMetric.platformCallsDuringMotion),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.repositoryReadsDuringMotion),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.liveLeaseStartsDuringMotion),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logBoxProjectionsDuringMotion),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.formattingDuringMotion),
      1,
    );

    diagnostics.recordDataOperation(DashboardDataOperation.sql);
    expect(
      counters.value(DashboardPerformanceMetric.sqlCallsDuringMotion),
      1,
      reason: 'background/non-motion work is not a motion-path violation',
    );
  });

  test('data work is counted for the complete physical motion interval', () {
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(counters: counters);

    diagnostics.setMotionActive(true);
    diagnostics.recordDataOperation(DashboardDataOperation.repositoryRead);
    diagnostics.setMotionActive(false);
    diagnostics.recordDataOperation(DashboardDataOperation.repositoryRead);

    expect(
      counters.value(DashboardPerformanceMetric.repositoryReadsDuringMotion),
      1,
    );
  });

  test('defines every required diagnostic event wire name', () {
    expect(
      DashboardInteractionEvent.values.map((event) => event.wireName),
      containsAll(<String>{
        'MOTION_GESTURE_STARTED',
        'MOTION_BALLISTIC_STARTED',
        'MOTION_SEMANTIC_CROSSED',
        'MOTION_FRAME_TARGET_SELECTED',
        'VISIBLE_FRAME_PUBLISHED',
        'MOTION_SETTLED',
        'COMMITTED_FRAME_PROMOTED',
        'LIVE_LEASE_STARTED',
        'LIVE_FRAME_ACCEPTED',
        'PREPARED_DECK_CACHE_HIT',
        'PREPARED_DECK_CACHE_MISS',
        'PREPARED_DECK_STARTED',
        'PREPARED_DECK_READY',
        'PREPARED_DECK_DISCARDED',
        'STALE_CALLBACK_REJECTED',
      }),
    );
  });
}

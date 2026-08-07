import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_diagnostics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_anchor.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      presentationGeneration: 89,
      dataGeneration: 144,
      presentationMode: DashboardPresentationMode.preview,
      dataOrigin: DashboardDataOrigin.deterministicZero,
      motionState: DashboardMotionActivity.ballistic,
      acquisitionReason: DataAcquisitionReason.databaseRevision,
    );

    diagnostics.record(
      DashboardInteractionEvent.visibleFramePublished,
      context: context,
      source: 'preparedIndex',
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
    expect(event.presentationGeneration, 89);
    expect(event.dataGeneration, 144);
    expect(event.presentationMode, DashboardPresentationMode.preview);
    expect(event.dataOrigin, DashboardDataOrigin.deterministicZero);
    expect(event.motionState, DashboardMotionActivity.ballistic);
    expect(event.acquisitionReason, DataAcquisitionReason.databaseRevision);
    expect(event.source, 'preparedIndex');
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
        DashboardInteractionEvent.railChildCrossed,
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

  test('motion hot-path data operations fail hard and emit violations', () {
    final events = <DashboardInteractionDiagnosticEvent>[];
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(
      counters: counters,
      sink: events.add,
    );

    for (final operation in DashboardDataOperation.values) {
      expect(
        () => diagnostics.runMotionHotPath(
          () => diagnostics.recordDataOperation(operation),
        ),
        throwsA(isA<AssertionError>()),
      );
    }

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
    expect(
      events.map((event) => event.name),
      everyElement('MOTION_DATA_IO_VIOLATION'),
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
    expect(
      () => diagnostics.recordDataOperation(
        DashboardDataOperation.repositoryRead,
      ),
      throwsA(isA<AssertionError>()),
    );
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
        'GLOBAL_REVISION_WATCH_SUBSCRIBED',
        'GLOBAL_REVISION_CHANGED',
        'INDEX_BUILD_STARTED',
        'INDEX_BUILD_READY',
        'INDEX_PUBLISHED',
        'NAV_PRESENTATION_SELECTED',
        'RAIL_CHILD_CROSSED',
        'SETTLE_METADATA_COMMITTED',
        'VERTICAL_PAGE_REQUESTED',
        'MOTION_DATA_IO_VIOLATION',
        'STALE_CALLBACK_REJECTED',
      }),
    );
    expect(DataAcquisitionReason.values, <DataAcquisitionReason>[
      DataAcquisitionReason.bootstrap,
      DataAcquisitionReason.databaseRevision,
      DataAcquisitionReason.explicitCommittedVerticalPaging,
    ]);
  });

  test(
    'core emits the complete runtime and RAM-navigation lifecycle',
    () async {
      final events = <DashboardInteractionDiagnosticEvent>[];
      final scheduler = _DisplayFrameScheduler();
      final diagnostics = DashboardInteractionDiagnostics(
        sink: events.add,
        verboseSemanticCrossings: true,
      );
      final core = DashboardCoreController(
        dataRepository: const EmptyDashboardDataRuntimeRepository(),
        displayFrameScheduler: scheduler,
        interactionDiagnostics: diagnostics,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);

      await core.bootstrap();
      core.setRailOpen(true);
      scheduler.fireFrame();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(18);
      scheduler.fireFrame();
      core.settleRail(18);

      final names = events.map((event) => event.name).toList();
      expect(
        names,
        containsAll(<String>[
          'GLOBAL_REVISION_WATCH_SUBSCRIBED',
          'INDEX_BUILD_STARTED',
          'INDEX_BUILD_READY',
          'INDEX_PUBLISHED',
          'NAV_PRESENTATION_SELECTED',
          'MOTION_GESTURE_STARTED',
          'RAIL_CHILD_CROSSED',
          'MOTION_FRAME_TARGET_SELECTED',
          'VISIBLE_FRAME_PUBLISHED',
          'MOTION_SETTLED',
          'SETTLE_METADATA_COMMITTED',
        ]),
      );
      final buildEvents = events.where(
        (event) =>
            event.name == 'INDEX_BUILD_STARTED' ||
            event.name == 'INDEX_BUILD_READY',
      );
      expect(
        buildEvents.map((event) => event.acquisitionReason).toSet(),
        <DataAcquisitionReason>{DataAcquisitionReason.bootstrap},
      );
      expect(core.dataRuntime.globalRevisionSubscribeCount, 1);
    },
  );

  test(
    'core records canonical temporal derivation in the bounded ring',
    () async {
      final recorder = DashboardRailFlightRecorder(
        enabled: true,
        capacity: 32,
        collectFrameTimings: false,
      );
      final scheduler = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        dataRepository: const EmptyDashboardDataRuntimeRepository(),
        displayFrameScheduler: scheduler,
        railFlightRecorder: recorder,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      recorder.clear();

      core.navigatePlane(finer: false);

      final events = recorder.snapshot();
      final derivation = events.singleWhere(
        (event) =>
            event.type == DashboardRailFlightEventType.planeTargetDerived,
      );
      expect(derivation.sourcePlane, TimePlane.month);
      expect(derivation.targetPlane, TimePlane.year);
      expect(derivation.temporalAnchor?.visibleYear, 2026);
      expect(derivation.temporalAnchor?.visibleMonth, 7);
      expect(derivation.targetParentQueryKey?.value, contains('year:2026'));
      expect(derivation.derivationReason, 'broader');

      final changed = events.singleWhere(
        (event) =>
            event.type == DashboardRailFlightEventType.temporalAnchorChanged,
      );
      expect(changed.oldTemporalAnchor?.sourcePlane, TimePlane.month);
      expect(changed.newTemporalAnchor?.sourcePlane, TimePlane.year);
      expect(changed.newTemporalAnchor?.visibleYear, 2026);
      expect(
        changed.temporalAnchorReason,
        DashboardTemporalAnchorChangeReason.planeCommitted,
      );
    },
  );
}

final class _DisplayFrameScheduler implements DashboardDisplayFrameScheduler {
  final List<void Function()> _callbacks = <void Function()>[];

  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(void Function() callback) => _callbacks.add(callback);

  void fireFrame() {
    currentFrameNumber += 1;
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

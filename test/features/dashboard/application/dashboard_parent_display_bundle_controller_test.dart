import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle_controller.dart';
import 'package:fluvi/features/dashboard/performance/dashboard_performance_trace.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _DelayedBundleRepository
    implements DashboardParentDisplayBundleRepository {
  final requests = <DashboardParentDisplayBundleRequest>[];
  final pending = <Completer<DashboardParentDisplayBundlePayload>>[];

  @override
  Future<DashboardParentDisplayBundlePayload> readParentDisplayBundle(
    DashboardParentDisplayBundleRequest request,
  ) {
    requests.add(request);
    final completer = Completer<DashboardParentDisplayBundlePayload>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
  );
  final children = List<CurrentLedgerQueryScope>.generate(
    30,
    (index) => parent.copyWith(
      timeScope: DayScope(LocalDate(year: 2026, month: 6, day: index + 1)),
    ),
  );

  test(
    'publishes a finite deck only after its whole payload is complete',
    () async {
      final repository = _DelayedBundleRepository();
      final controller = DashboardParentDisplayBundleController(
        repository: repository,
        cacheCapacity: 2,
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      final loading = controller.ensureFiniteBundle(
        parentScope: parent,
        plane: TimePlane.month,
        expectedChildren: children,
      );
      expect(repository.requests, hasLength(1));
      expect(controller.currentBundle, isNull);
      expect(notifications, 0);

      repository.pending.single.complete(
        DashboardParentDisplayBundlePayload(
          parentScope: parent,
          plane: TimePlane.month,
          coreRevision: 12,
          snapshots: <DashboardLogPreviewSnapshot>[
            DashboardLogPreviewSnapshot.populated(
              scope: children.first,
              coreRevision: 12,
              totalMinor: 100,
              entryCount: 1,
              groups: const [],
            ),
          ],
        ),
      );
      final bundle = await loading;

      expect(bundle.isComplete, isTrue);
      expect(controller.currentBundle, same(bundle));
      expect(controller.previewFor(children[0])?.entryCount, 1);
      expect(controller.previewFor(children[20])?.isExplicitEmpty, isTrue);
      expect(controller.canServeFinitePreview(children[20]), isTrue);
      expect(notifications, 1);
    },
  );

  test(
    'a complete current finite deck suppresses motion target fallback',
    () async {
      final repository = _DelayedBundleRepository();
      final controller = DashboardParentDisplayBundleController(
        repository: repository,
        cacheCapacity: 2,
      );
      addTearDown(controller.dispose);

      final loading = controller.ensureFiniteBundle(
        parentScope: parent,
        plane: TimePlane.month,
        expectedChildren: children,
      );
      repository.pending.single.complete(
        DashboardParentDisplayBundlePayload(
          parentScope: parent,
          plane: TimePlane.month,
          coreRevision: 12,
          snapshots: const <DashboardLogPreviewSnapshot>[],
        ),
      );
      await loading;

      expect(
        controller.shouldFallbackToMotionTargetPrefetch(children[14]),
        isFalse,
      );
    },
  );

  test(
    'prewarms a next parent without replacing the visible current deck',
    () async {
      final repository = _DelayedBundleRepository();
      final controller = DashboardParentDisplayBundleController(
        repository: repository,
        cacheCapacity: 2,
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      final currentLoading = controller.ensureFiniteBundle(
        parentScope: parent,
        plane: TimePlane.month,
        expectedChildren: children,
      );
      repository.pending.single.complete(
        DashboardParentDisplayBundlePayload(
          parentScope: parent,
          plane: TimePlane.month,
          coreRevision: 12,
          snapshots: const <DashboardLogPreviewSnapshot>[],
        ),
      );
      final current = await currentLoading;
      expect(controller.currentBundle, same(current));
      expect(notifications, 1);

      final nextParent = parent.copyWith(
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final nextChildren = List<CurrentLedgerQueryScope>.generate(
        31,
        (index) => nextParent.copyWith(
          timeScope: DayScope(LocalDate(year: 2026, month: 7, day: index + 1)),
        ),
      );
      final nextLoading = controller.prewarmFiniteBundle(
        parentScope: nextParent,
        plane: TimePlane.month,
        expectedChildren: nextChildren,
      );
      repository.pending.last.complete(
        DashboardParentDisplayBundlePayload(
          parentScope: nextParent,
          plane: TimePlane.month,
          coreRevision: 12,
          snapshots: const <DashboardLogPreviewSnapshot>[],
        ),
      );
      final next = await nextLoading;

      expect(controller.currentBundle, same(current));
      expect(notifications, 1);
      controller.activatePreparedBundle(next, notify: false);
      expect(controller.currentBundle, same(next));
      expect(notifications, 1);
    },
  );

  test('records parent bundle readiness as a numeric profile event', () async {
    DashboardPerformanceTrace.resetForTest(enabled: true);
    addTearDown(DashboardPerformanceTrace.resetForTest);
    final repository = _DelayedBundleRepository();
    final controller = DashboardParentDisplayBundleController(
      repository: repository,
      cacheCapacity: 2,
    );
    addTearDown(controller.dispose);

    final loading = controller.prewarmFiniteBundle(
      parentScope: parent,
      plane: TimePlane.month,
      expectedChildren: children,
    );
    repository.pending.single.complete(
      DashboardParentDisplayBundlePayload(
        parentScope: parent,
        plane: TimePlane.month,
        coreRevision: 12,
        snapshots: const <DashboardLogPreviewSnapshot>[],
      ),
    );
    await loading;

    expect(
      DashboardPerformanceTrace.events.single,
      isA<DashboardPerformanceTraceEvent>()
          .having(
            (event) => event.kind,
            'kind',
            DashboardPerformanceTraceKind.parentBundleReady,
          )
          .having((event) => event.valueA, 'child count', 30)
          .having((event) => event.valueB, 'revision', 12),
    );
  });
}

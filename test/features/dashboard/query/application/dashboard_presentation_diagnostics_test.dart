import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_diagnostics.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _ManualFrameScheduler implements DashboardFrameScheduler {
  final callbacks = <void Function()>[];

  @override
  void schedule(void Function() callback) => callbacks.add(callback);

  void presentNextFrame() {
    final callback = callbacks.removeAt(0);
    callback();
  }
}

void main() {
  test('preview mode is independent from the snapshot data origin', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 1)),
    );
    final snapshot = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 3,
      scope: scope,
      totalMinor: 10,
      entryCount: 1,
      presentationMode: DashboardPresentationMode.preview,
      dataOrigin: DashboardDataOrigin.freshQuery,
    );

    expect(snapshot.isPreview, isTrue);
    expect(snapshot.presentationMode, DashboardPresentationMode.preview);
    expect(snapshot.dataOrigin, DashboardDataOrigin.freshQuery);
  });

  test(
    'preview diagnostics coalesce frame presentation to the latest publish',
    () {
      final scheduler = _ManualFrameScheduler();
      var frame = 10;
      final diagnostics = DashboardPresentationDiagnostics(
        frameScheduler: scheduler,
        frameNumber: () => frame,
      );
      final firstKey = const LedgerQueryKey('expense|day:2026-07-01');
      final secondKey = const LedgerQueryKey('expense|day:2026-07-02');

      diagnostics.recordRailChildCrossed(
        interactionEpoch: 4,
        semanticChild: 1,
        queryKey: firstKey,
        activity: DashboardPreviewActivity.ballistic,
        frameNumber: frame,
      );
      diagnostics.recordPreviewSnapshotSelected(
        interactionEpoch: 4,
        presentationGeneration: 1,
        queryKey: firstKey,
        amount: 100,
        entryCount: 1,
        logGroupCount: 1,
        logRowCount: 1,
        contentDigest: 11,
        dataOrigin: DashboardDataOrigin.childPreviewBundle,
        cacheHit: true,
      );
      diagnostics.recordPreviewPresentationPublished(
        interactionEpoch: 4,
        presentationGeneration: 1,
        queryKey: firstKey,
        amount: 100,
        entryCount: 1,
        logDigest: 11,
        presentationMode: DashboardPresentationMode.preview,
      );
      diagnostics.recordPreviewPresentationPublished(
        interactionEpoch: 4,
        presentationGeneration: 2,
        queryKey: secondKey,
        amount: 200,
        entryCount: 2,
        logDigest: 22,
        presentationMode: DashboardPresentationMode.preview,
      );

      expect(diagnostics.previewPresentationPublishedCount, 2);
      expect(diagnostics.previewFramePresentedCount, 0);
      expect(diagnostics.previewFrameCoalescedCount, 1);
      expect(scheduler.callbacks, hasLength(1));

      scheduler.presentNextFrame();

      expect(diagnostics.previewFramePresentedCount, 1);
      expect(
        diagnostics.events.last.kind,
        DashboardPresentationDiagnosticKind.previewFramePresented,
      );
      expect(diagnostics.events.last.queryKey, secondKey);
      expect(diagnostics.events.last.presentationGeneration, 2);

      frame = 11;
      diagnostics.recordPreviewPresentationPublished(
        interactionEpoch: 4,
        presentationGeneration: 3,
        queryKey: firstKey,
        amount: 100,
        entryCount: 1,
        logDigest: 11,
        presentationMode: DashboardPresentationMode.preview,
      );
      scheduler.presentNextFrame();
      expect(diagnostics.previewFramePresentedCount, 2);
    },
  );

  test(
    'late committed result is cached but cannot replace visible preview',
    () {
      final store = DashboardPresentationStore();
      addTearDown(store.dispose);
      final parent = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const YearScope(2026),
      );
      final child = parent.copyWith(
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.year,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: true,
          direction: parent.direction,
          presentationEpoch: 8,
        ),
      );
      store.publish(
        DashboardPresentationSnapshot(
          queryKey: child.key,
          generation: 8,
          scope: child,
          totalMinor: 200,
          entryCount: 2,
          presentationMode: DashboardPresentationMode.preview,
          dataOrigin: DashboardDataOrigin.childPreviewBundle,
        ),
      );

      final accepted = store.publishCommittedResult(
        DashboardPresentationSnapshot(
          queryKey: parent.key,
          generation: 7,
          scope: parent,
          totalMinor: 100,
          entryCount: 1,
          presentationMode: DashboardPresentationMode.committed,
          dataOrigin: DashboardDataOrigin.liveObserver,
        ),
        interactionEpoch: 7,
      );

      expect(accepted, isFalse);
      expect(store.activeSnapshot?.queryKey, child.key);
      expect(store.lateCommittedResultCachedCount, 1);
      expect(store.lateCommittedResultVisibleRejectedCount, 1);
    },
  );
}

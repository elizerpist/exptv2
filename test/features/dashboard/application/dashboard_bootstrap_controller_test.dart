import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_bootstrap_controller.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_diagnostics.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test('bootstrap waits for one complete parent display bundle', () async {
    final bundleCompleter = Completer<DashboardParentDisplayBundle>();
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final parentSnapshot = DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: 1,
      scope: scope,
      totalMinor: 492500000,
      entryCount: 658,
      dataOrigin: DashboardDataOrigin.freshQuery,
    );
    final childBundle = DashboardChildPreviewBundle(
      parentScope: scope,
      childPeriod: TimeChildPeriod.month,
      coreRevision: 1,
      childrenByQueryKey: const {},
    );
    final bootstrap = DashboardBootstrapController(
      store: store,
      readInitialBundle: () => bundleCompleter.future,
    );
    addTearDown(bootstrap.dispose);

    final start = bootstrap.start();
    await Future<void>.value();
    expect(bootstrap.isReady, isFalse);
    expect(store.activeSnapshot, isNull);

    bundleCompleter.complete(
      DashboardParentDisplayBundle(
        parentSnapshot: parentSnapshot,
        childPreviewBundle: childBundle,
      ),
    );
    await start;

    expect(bootstrap.isReady, isTrue);
    expect(bootstrap.snapshot?.queryKey, scope.key);
    expect(bootstrap.snapshot?.totalMinor, 492500000);
    expect(bootstrap.snapshot?.entryCount, 658);
    expect(store.activeSnapshot?.queryKey, scope.key);
    expect(store.visiblePresentationPublishCount, 1);
  });

  test('bootstrap publishes one valid snapshot before ready', () async {
    final critical = Completer<DashboardPresentationSnapshot>();
    final childPreview = Completer<void>();
    final store = DashboardPresentationStore();
    addTearDown(store.dispose);
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final bootstrap = DashboardBootstrapController(
      store: store,
      readCriticalSnapshot: () => critical.future,
      prepareChildPreview: () => childPreview.future,
    );
    addTearDown(bootstrap.dispose);

    final start = bootstrap.start();
    await Future<void>.value();
    expect(bootstrap.phase, DashboardBootstrapPhase.readingCriticalSnapshot);
    expect(store.activeSnapshot, isNull);

    critical.complete(
      DashboardPresentationSnapshot(
        queryKey: scope.key,
        generation: 1,
        scope: scope,
        totalMinor: 0,
        entryCount: 0,
        entries: const <DashboardLedgerEntry>[],
        dataOrigin: DashboardDataOrigin.freshQuery,
      ),
    );
    await Future<void>.value();
    expect(bootstrap.phase, DashboardBootstrapPhase.preparingChildPreview);
    expect(store.activeSnapshot, isNull);

    childPreview.complete();
    await start;

    expect(bootstrap.phase, DashboardBootstrapPhase.ready);
    expect(bootstrap.snapshot?.queryKey, scope.key);
    expect(bootstrap.snapshot?.totalMinor, 0);
    expect(bootstrap.snapshot?.entryCount, 0);
    expect(store.activeSnapshot?.queryKey, scope.key);
    expect(store.activeSnapshot?.isLoading, isFalse);
    expect(store.visiblePresentationPublishCount, 1);
  });

  test(
    'bootstrap rejects an invalid placeholder as the first dashboard state',
    () async {
      final store = DashboardPresentationStore();
      addTearDown(store.dispose);
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const YearScope(2026),
      );
      final bootstrap = DashboardBootstrapController(
        store: store,
        readCriticalSnapshot: () async => DashboardPresentationSnapshot(
          queryKey: scope.key,
          generation: 1,
          scope: scope,
          isLoading: true,
        ),
      );
      addTearDown(bootstrap.dispose);

      await bootstrap.start();

      expect(bootstrap.phase, DashboardBootstrapPhase.failed);
      expect(store.activeSnapshot, isNull);
      expect(bootstrap.error, isA<StateError>());
    },
  );
}

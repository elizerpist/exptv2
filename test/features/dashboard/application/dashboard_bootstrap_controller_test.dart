import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_bootstrap_controller.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_diagnostics.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
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

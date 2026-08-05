import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_bootstrap_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/data/empty_dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'core revision zero starts no preparation before revision one',
    () async {
      final repository = _RevisionRepository();
      final core = DashboardCoreController(
        preparedRepository: repository,
        revisionRepository: repository,
        initialDate: DateTime(2026, 8, 2),
        enableBackgroundPrewarm: false,
      );
      addTearDown(core.dispose);

      final bootstrap = core.bootstrap();
      await pumpEventQueue();
      repository.emitRevision(0);
      await pumpEventQueue();
      expect(repository.prepareCount, 0);

      repository.emitRevision(1);
      final frame = await bootstrap;
      expect(repository.prepareCount, 1);
      expect(frame.coreRevision, 1);
    },
  );

  test(
    'seed gate reads the structurally selected month after commit',
    () async {
      final repository = _RevisionRepository();
      final core = DashboardCoreController(
        preparedRepository: repository,
        revisionRepository: repository,
        initialDate: DateTime(2026, 8, 2),
        seedReady: false,
        enableBackgroundPrewarm: false,
      );
      addTearDown(core.dispose);
      core.navigation.navigateToMonth(const YearMonth(year: 2026, month: 7));

      final bootstrap = core.bootstrap();
      await pumpEventQueue();
      expect(repository.prepareCount, 0);

      core.markSeedCommitted();
      await pumpEventQueue();
      repository.emitRevision(1);
      final frame = await bootstrap;
      expect(frame.parentQueryKey.value, contains('month:2026-07'));
      expect(repository.lastRequest?.parentScope.key, frame.parentQueryKey);
    },
  );

  test(
    'bootstrap controller mounts only after one complete atomic frame',
    () async {
      final repository = _RevisionRepository();
      final core = DashboardCoreController(
        preparedRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        enableBackgroundPrewarm: false,
      );
      addTearDown(core.dispose);
      final bootstrap = DashboardBootstrapController(bootstrap: core.bootstrap);
      addTearDown(bootstrap.dispose);

      final first = bootstrap.start();
      final second = bootstrap.start();
      expect(identical(first, second), isTrue);
      await first;

      expect(bootstrap.phase, DashboardBootstrapPhase.ready);
      expect(bootstrap.frame, same(core.visibleFrames.value));
      expect(bootstrap.frame?.queryKey, bootstrap.frame?.amount.queryKey);
      expect(bootstrap.frame?.queryKey, bootstrap.frame?.count.queryKey);
      expect(bootstrap.frame?.queryKey, bootstrap.frame?.logBox.queryKey);
      expect(repository.prepareCount, 1);
    },
  );
}

final class _RevisionRepository
    implements
        DashboardPreparedDeckRepository,
        DashboardCoreRevisionRepository {
  final StreamController<int> _revisions = StreamController<int>.broadcast();
  final EmptyDashboardPreparedDeckRepository _empty =
      const EmptyDashboardPreparedDeckRepository();
  int prepareCount = 0;
  DashboardPreparedDeckRequest? lastRequest;

  void emitRevision(int revision) => _revisions.add(revision);

  @override
  Stream<int> watchCoreRevision() => _revisions.stream;

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) {
    prepareCount += 1;
    lastRequest = request;
    return _empty.prepareDeck(request, token);
  }
}

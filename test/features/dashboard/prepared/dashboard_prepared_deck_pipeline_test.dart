import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/application/dashboard_prepared_deck_cache.dart';
import 'package:fluvi/features/dashboard/prepared/application/dashboard_prepared_deck_pipeline.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';

import 'dashboard_prepared_test_fixtures.dart';

void main() {
  test(
    'closed seed gate rejects work before touching the repository',
    () async {
      final repository = _Repository();
      final pipeline = DashboardPreparedDeckPipeline(
        repository: repository,
        cache: DashboardPreparedDeckCache(capacity: 4),
      );
      final deck = preparedDeckFixture();

      await expectLater(
        pipeline.prepareRequired(DashboardPreparedDeckRequest.fromDeck(deck)),
        throwsStateError,
      );
      expect(repository.callCount, 0);
    },
  );

  test('revision zero can neither start nor enter the cache', () async {
    final repository = _Repository();
    final cache = DashboardPreparedDeckCache(capacity: 4);
    final pipeline = DashboardPreparedDeckPipeline(
      repository: repository,
      cache: cache,
    )..openSeedGate();
    final valid = preparedDeckFixture();
    final zeroKey = DashboardPreparedDeckKey(
      modelVersion: valid.key.modelVersion,
      direction: valid.key.direction,
      parentQueryKey: valid.key.parentQueryKey,
      categoryIdsKey: valid.key.categoryIdsKey,
      partnerIdsKey: valid.key.partnerIdsKey,
      refinementsKey: valid.key.refinementsKey,
      childKind: valid.key.childKind,
      coreRevision: 0,
      pageSize: valid.key.pageSize,
      semanticWindowIdentity: valid.key.semanticWindowIdentity,
    );

    await expectLater(
      pipeline.prepareRequired(
        DashboardPreparedDeckRequest(
          key: zeroKey,
          parentScope: valid.parentScope,
          semanticCatalog: valid.semanticCatalog,
        ),
      ),
      throwsStateError,
    );
    expect(repository.callCount, 0);
    expect(cache.length, 0);
  });

  test(
    'twenty concurrent requests share one exact Future and repository call',
    () async {
      final repository = _Repository();
      final pipeline = _openPipeline(repository);
      final deck = preparedDeckFixture();
      final request = DashboardPreparedDeckRequest.fromDeck(deck);

      final futures = List<Future<DashboardPreparedDeck>>.generate(
        20,
        (_) => pipeline.prepareRequired(request),
      );
      expect(
        futures.skip(1).every((future) => identical(future, futures.first)),
        isTrue,
      );
      expect(repository.callCount, 1);

      repository.complete(deck);
      final results = await Future.wait(futures);
      expect(results.every((result) => identical(result, deck)), isTrue);
      expect(pipeline.inFlightCount, 0);
      expect(pipeline.cache.peek(deck.key), same(deck));
    },
  );

  test('revision change cancels and discards a late completion', () async {
    final repository = _Repository();
    final pipeline = _openPipeline(repository);
    final oldDeck = preparedDeckFixture(revision: 1);
    final future = pipeline.prepareRequired(
      DashboardPreparedDeckRequest.fromDeck(oldDeck),
    );

    pipeline.acceptCoreRevision(2);
    repository.complete(oldDeck);

    await expectLater(future, throwsA(isA<DashboardPreparationDiscarded>()));
    expect(pipeline.cache.length, 0);
    expect(pipeline.discardedCompletionCount, 1);
  });

  test(
    'interaction prevents new prewarm but never blocks required work',
    () async {
      final repository = _Repository();
      final pipeline = _openPipeline(repository)..setInteractionActive(true);
      final deck = preparedDeckFixture();
      final request = DashboardPreparedDeckRequest.fromDeck(deck);

      await pipeline.prewarm(request);
      expect(repository.callCount, 0);
      expect(pipeline.suppressedPrewarmCount, 1);

      final required = pipeline.prepareRequired(request);
      expect(repository.callCount, 1);
      repository.complete(deck);
      expect(await required, same(deck));
    },
  );

  test(
    'required consumer promotes an existing prewarm instead of duplicating it',
    () async {
      final repository = _Repository();
      final pipeline = _openPipeline(repository);
      final deck = preparedDeckFixture();
      final request = DashboardPreparedDeckRequest.fromDeck(deck);

      final prewarm = pipeline.prewarm(request);
      final required = pipeline.prepareRequired(request);
      pipeline.setInteractionActive(true);
      expect(repository.callCount, 1);

      repository.complete(deck);
      await prewarm;
      expect(await required, same(deck));
      expect(pipeline.cache.peek(deck.key), same(deck));
    },
  );

  test(
    'interaction cancellation followed by the same target never overlaps work',
    () async {
      final repository = _Repository();
      final pipeline = _openPipeline(repository);
      final deck = preparedDeckFixture();
      final request = DashboardPreparedDeckRequest.fromDeck(deck);

      final prewarm = pipeline.prewarm(request);
      pipeline.setInteractionActive(true);
      final required = pipeline.prepareRequired(request);

      expect(repository.callCount, 1);
      repository.complete(deck);
      await prewarm;
      expect(await required, same(deck));
      expect(repository.callCount, 1);
    },
  );

  test(
    'navigation cancellation can promote the exact prewarm in place',
    () async {
      final repository = _Repository();
      final pipeline = _openPipeline(repository);
      final deck = preparedDeckFixture();
      final request = DashboardPreparedDeckRequest.fromDeck(deck);

      final prewarm = pipeline.prewarm(request);
      pipeline.cancelPrewarm();
      final required = pipeline.prepareRequired(request);

      expect(repository.callCount, 1);
      repository.complete(deck);
      await prewarm;
      expect(await required, same(deck));
      expect(repository.callCount, 1);
    },
  );
}

DashboardPreparedDeckPipeline _openPipeline(_Repository repository) {
  final pipeline = DashboardPreparedDeckPipeline(
    repository: repository,
    cache: DashboardPreparedDeckCache(capacity: 4),
  );
  pipeline
    ..acceptCoreRevision(1)
    ..openSeedGate();
  return pipeline;
}

final class _Repository implements DashboardPreparedDeckRepository {
  Completer<DashboardPreparedDeck>? _completer;
  int callCount = 0;

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) {
    callCount += 1;
    _completer = Completer<DashboardPreparedDeck>();
    return _completer!.future;
  }

  void complete(DashboardPreparedDeck deck) => _completer!.complete(deck);
}

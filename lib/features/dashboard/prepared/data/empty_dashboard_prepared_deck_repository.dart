import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../domain/dashboard_prepared_deck.dart';
import 'dashboard_prepared_deck_repository.dart';

/// Data-free host implementation used by Flutter web previews.
final class EmptyDashboardPreparedDeckRepository
    implements
        DashboardPreparedDeckRepository,
        DashboardCoreRevisionRepository {
  const EmptyDashboardPreparedDeckRepository();

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) async {
    if (token.isCancelled) {
      throw StateError('Prepared deck request was cancelled.');
    }
    DashboardPreparedFrame emptyFrame(scope) => DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: request.parentScope.key,
      coreRevision: request.key.coreRevision,
      totalMinor: 0,
      formattedAmount: '0,00 Ft',
      entryCount: 0,
      formattedEntryCount: '0',
      logBox: DashboardLogViewportState(
        queryKey: scope.key,
        revision: request.key.coreRevision,
        groups: const [],
        entryCount: 0,
        nextCursor: null,
        direction: scope.direction,
      ),
      presentationDigest: Object.hash(scope.key, request.key.coreRevision),
    );
    return DashboardPreparedDeck.complete(
      key: request.key,
      parentScope: request.parentScope,
      parentFrame: emptyFrame(request.parentScope),
      semanticCatalog: request.semanticCatalog,
      frames: {
        for (final entry in request.semanticCatalog.entries)
          entry.queryKey: emptyFrame(entry.scope),
      },
      contentDigest: Object.hash(request.key, 0),
      generation: token.generation,
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: const DashboardPreparedDeckBuildMetrics.synthetic(),
    );
  }
}

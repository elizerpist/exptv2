import '../../logbox/application/committed_log_viewport_cache.dart';
import '../domain/prepared_dashboard_index.dart';
import 'dashboard_data_runtime_repository.dart';

/// Deterministic no-I/O runtime used by web and isolated widget tests.
final class EmptyDashboardDataRuntimeRepository
    implements DashboardDataRuntimeRepository {
  const EmptyDashboardDataRuntimeRepository();

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    request.reason.requireIndexBuild();
    if (token.isCancelled) throw StateError('Index preparation was cancelled.');
    final assembly = PreparedDashboardIndexAssembly.zeroUniverse(
      key: request.key,
      directionalQueries: request.directionalQueries,
      initialYear: request.initialYear,
    );
    return PreparedDashboardIndex.complete(
      key: request.key,
      frames: assembly.frames,
      catalogs: assembly.catalogs,
      scopes: assembly.scopes,
      origins: assembly.origins,
      generation: token.generation,
      contentDigest: Object.hash(request.key, token.generation, 'empty'),
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: PreparedDashboardIndexBuildMetrics(
        sqlCallCount: 0,
        nativeSqlDurationMicros: 0,
        aggregateBucketCount: 0,
        scannedLedgerRowCount: 0,
        uniquePreviewRowCount: 0,
        frameCount: assembly.frames.length,
        nativeQueryDurationMicros: 0,
        nativeAggregationDurationMicros: 0,
        nativeMappingDurationMicros: 0,
        serializationDurationMicros: 0,
        bridgeTransferDurationMicros: 0,
        dartDecodeDurationMicros: 0,
        dartProjectionDurationMicros: 0,
        zeroUniverseCatalogDurationMicros:
            assembly.metrics.zeroUniverseCatalogDurationMicros,
        zeroUniverseScopeDurationMicros:
            assembly.metrics.zeroUniverseScopeDurationMicros,
        zeroFrameMaterializationDurationMicros:
            assembly.metrics.zeroFrameMaterializationDurationMicros,
        zeroScopeCount: assembly.metrics.zeroScopeCount,
        zeroFrameCount: assembly.metrics.zeroFrameCount,
        semanticCatalogCount: assembly.metrics.semanticCatalogCount,
        semanticEntryCount: assembly.metrics.semanticEntryCount,
        payloadBytes: 0,
        estimatedIndexBytes: assembly.metrics.zeroScopeCount * 48,
      ),
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    request.reason.requirePageRead();
    return Future<CommittedLogPage>.error(
      StateError('An empty dashboard has no committed page.'),
    );
  }

  @override
  Map<String, Object?> performanceReport() => const <String, Object?>{
    'index_build_calls': 0,
    'page_read_calls': 0,
    'platform_calls': 0,
  };
}

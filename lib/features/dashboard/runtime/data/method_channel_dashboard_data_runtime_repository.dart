import 'package:flutter/services.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/data/current_ledger_query_scope_wire_codec.dart';
import '../domain/prepared_dashboard_index.dart';
import 'dashboard_committed_page_binary_codec.dart';
import 'dashboard_data_runtime_repository.dart';
import 'prepared_dashboard_index_binary_codec.dart';

/// The sole dashboard data transport.
///
/// It exposes one global revision stream, whole-index builds caused only by
/// bootstrap/database revision, and explicit committed vertical paging. There
/// is deliberately no per-query EventChannel or navigation acquisition API.
final class MethodChannelDashboardDataRuntimeRepository
    implements
        DashboardDataRuntimeRepository,
        PreparedDashboardIndexPartitionRepository,
        PreparedDashboardIndexCancellationRepository {
  MethodChannelDashboardDataRuntimeRepository({
    MethodChannel? channel,
    EventChannel? revisionEventChannel,
    DashboardPreparedIndexDecodeWorker? indexDecodeWorker,
    DashboardCommittedPageDecodeWorker? pageDecodeWorker,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _revisionEventChannel =
           revisionEventChannel ?? const EventChannel(_revisionChannelName),
       _indexDecodeWorker =
           indexDecodeWorker ??
           const IsolateDashboardPreparedIndexDecodeWorker(),
       _pageDecodeWorker =
           pageDecodeWorker ??
           const IsolateDashboardCommittedPageDecodeWorker();

  static const String _channelName = 'com.fluvi/dashboard_query';
  static const String _revisionChannelName =
      'com.fluvi/dashboard_core_revision_stream';

  final MethodChannel _channel;
  final EventChannel _revisionEventChannel;
  final DashboardPreparedIndexDecodeWorker _indexDecodeWorker;
  final DashboardCommittedPageDecodeWorker _pageDecodeWorker;

  int _indexBuildCalls = 0;
  int _pageReadCalls = 0;
  int _platformCalls = 0;
  final List<int> _platformDurationMicros = <int>[];
  final List<int> _indexDecodeDurationMicros = <int>[];
  final List<int> _pageDecodeDurationMicros = <int>[];
  final List<int> _payloadBytes = <int>[];

  @override
  Future<void> cancelPreparedIndex(DashboardIndexPreparationToken token) async {
    if (token.reason != DataAcquisitionReason.query) return;
    try {
      await _channel.invokeMethod<void>(
        'cancelDashboardPreparedIndex',
        <String, Object?>{'requestGeneration': token.generation},
      );
    } on MissingPluginException {
      // Older native hosts simply cannot have started this request's owner.
    } on PlatformException {
      // Cancellation is best-effort transport work; the Dart token remains
      // the authoritative stale-result barrier.
    }
  }

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    request.reason.requireIndexBuild();
    if (token.isCancelled) {
      throw StateError('Prepared index was cancelled before dispatch.');
    }
    _indexBuildCalls += 1;
    _platformCalls += 1;
    final platformTimer = Stopwatch()..start();
    final raw = await _channel
        .invokeMethod<Object?>('readDashboardPreparedIndex', <String, Object?>{
          ...CurrentLedgerQueryScopeWireCodec.encodeDirectionalFilterSet(
            request.directionalQueries,
          ),
          'coreRevision': request.key.coreRevision,
          'pageSize': request.key.pageSize,
          'yearWindowStart': request.key.yearWindowStart,
          'yearWindowEndInclusive': request.key.yearWindowEndInclusive,
          'requestGeneration': token.generation,
          'acquisitionReason': request.reason.name,
        });
    platformTimer.stop();
    _platformDurationMicros.add(platformTimer.elapsedMicroseconds);
    if (token.isCancelled) {
      throw StateError('Prepared index was cancelled after native build.');
    }
    final bytes = _binary(raw);
    final decodeTimer = Stopwatch()..start();
    final decodedIndex = await _indexDecodeWorker.decode(
      bytes,
      request: request,
      expectedGeneration: token.generation,
    );
    decodeTimer.stop();
    _indexDecodeDurationMicros.add(decodeTimer.elapsedMicroseconds);
    _payloadBytes.add(bytes.lengthInBytes);
    final metrics = decodedIndex.buildMetrics;
    final nativeBuildAndSerializationMicros =
        metrics.nativeQueryDurationMicros +
        metrics.nativeMappingDurationMicros +
        metrics.serializationDurationMicros;
    final bridgeTransferMicros =
        (platformTimer.elapsedMicroseconds - nativeBuildAndSerializationMicros)
            .clamp(0, platformTimer.elapsedMicroseconds)
            .toInt();
    return decodedIndex.withBuildMetrics(
      decodedIndex.buildMetrics.copyWith(
        bridgeTransferDurationMicros: bridgeTransferMicros,
        decodeWorkerWallDurationMicros: decodeTimer.elapsedMicroseconds,
      ),
    );
  }

  @override
  Future<PreparedDashboardIndex> prepareIndexPartition(
    PreparedDashboardIndexPartitionRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    final indexRequest = request.request;
    indexRequest.reason.requireIndexBuild();
    if (token.isCancelled) {
      throw StateError('Prepared partition was cancelled before dispatch.');
    }
    _indexBuildCalls += 1;
    _platformCalls += 1;
    final platformTimer = Stopwatch()..start();
    final raw = await _channel.invokeMethod<Object?>(
      'readDashboardPreparedIndexPartition',
      <String, Object?>{
        ...CurrentLedgerQueryScopeWireCodec.encodeDirectionalFilterSet(
          indexRequest.directionalQueries,
        ),
        'direction': request.direction.name,
        'coreRevision': indexRequest.key.coreRevision,
        'pageSize': indexRequest.key.pageSize,
        'yearWindowStart': indexRequest.key.yearWindowStart,
        'yearWindowEndInclusive': indexRequest.key.yearWindowEndInclusive,
        'requestGeneration': token.generation,
        'acquisitionReason': indexRequest.reason.name,
      },
    );
    platformTimer.stop();
    _platformDurationMicros.add(platformTimer.elapsedMicroseconds);
    if (token.isCancelled) {
      throw StateError('Prepared partition was cancelled after native build.');
    }
    final bytes = _binary(raw);
    final decodeTimer = Stopwatch()..start();
    final decodedIndex = await _indexDecodeWorker.decode(
      bytes,
      request: indexRequest,
      expectedGeneration: token.generation,
      expectedPartitionDirection: request.direction,
    );
    decodeTimer.stop();
    _indexDecodeDurationMicros.add(decodeTimer.elapsedMicroseconds);
    _payloadBytes.add(bytes.lengthInBytes);
    final metrics = decodedIndex.buildMetrics;
    final nativeBuildAndSerializationMicros =
        metrics.nativeQueryDurationMicros +
        metrics.nativeMappingDurationMicros +
        metrics.serializationDurationMicros;
    final bridgeTransferMicros =
        (platformTimer.elapsedMicroseconds - nativeBuildAndSerializationMicros)
            .clamp(0, platformTimer.elapsedMicroseconds)
            .toInt();
    return decodedIndex.withBuildMetrics(
      decodedIndex.buildMetrics.copyWith(
        bridgeTransferDurationMicros: bridgeTransferMicros,
        decodeWorkerWallDurationMicros: decodeTimer.elapsedMicroseconds,
      ),
    );
  }

  @override
  Stream<int> watchCoreRevision() async* {
    int? previous;
    await for (final raw in _revisionEventChannel.receiveBroadcastStream()) {
      final map = _asMap(raw, 'Dashboard core revision event');
      final revision = _asInt(map['coreRevision'], 'coreRevision');
      if (revision <= 0 || revision == previous) continue;
      previous = revision;
      yield revision;
    }
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async {
    request.reason.requirePageRead();
    _pageReadCalls += 1;
    _platformCalls += 1;
    final platformTimer = Stopwatch()..start();
    final raw = await _channel.invokeMethod<Object?>(
      'readDashboardCommittedPage',
      <String, Object?>{
        ...CurrentLedgerQueryScopeWireCodec.encodeNavigatedScope(request.scope),
        'parentQueryKey': request.parentQueryKey.value,
        'coreRevision': request.coreRevision,
        'presentationEpoch': request.presentationEpoch,
        'commitGeneration': request.commitGeneration,
        'authoritativeTotalMinor': request.authoritativeTotalMinor,
        'authoritativeEntryCount': request.authoritativeEntryCount,
        'pageSize': request.pageSize,
        'pageOrdinal': request.pageOrdinal,
        'after': request.startCursor,
        'acquisitionReason': request.reason.name,
      },
    );
    platformTimer.stop();
    _platformDurationMicros.add(platformTimer.elapsedMicroseconds);
    final bytes = _binary(raw);
    final decodeTimer = Stopwatch()..start();
    final frame = await _pageDecodeWorker.decodePage(bytes, request: request);
    decodeTimer.stop();
    _pageDecodeDurationMicros.add(decodeTimer.elapsedMicroseconds);
    _payloadBytes.add(bytes.lengthInBytes);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_TRANSPORT_READY',
        queryKey: request.scope.key.value,
        coreRevision: request.coreRevision,
        entryCount: frame.rowCount,
        durationMs:
            platformTimer.elapsedMilliseconds + decodeTimer.elapsedMilliseconds,
        message:
            'pageOrdinal=${request.pageOrdinal} '
            'dartPlatformCallMicros=${platformTimer.elapsedMicroseconds} '
            'decodeWorkerMicros=${decodeTimer.elapsedMicroseconds} '
            'payloadBytes=${bytes.lengthInBytes}',
      ),
    );
    return frame;
  }

  @override
  Map<String, Object?> performanceReport() => <String, Object?>{
    'index_build_calls': _indexBuildCalls,
    'page_read_calls': _pageReadCalls,
    'platform_calls': _platformCalls,
    'platform_duration_micros': List<int>.unmodifiable(_platformDurationMicros),
    'index_decode_duration_micros': List<int>.unmodifiable(
      _indexDecodeDurationMicros,
    ),
    'page_decode_duration_micros': List<int>.unmodifiable(
      _pageDecodeDurationMicros,
    ),
    'payload_bytes': List<int>.unmodifiable(_payloadBytes),
  };

  static Uint8List _binary(Object? raw) => switch (raw) {
    Uint8List value => value,
    ByteData value => value.buffer.asUint8List(
      value.offsetInBytes,
      value.lengthInBytes,
    ),
    _ => throw const FormatException('Dashboard response must be binary.'),
  };

  static Map<String, Object?> _asMap(Object? raw, String label) {
    if (raw is! Map) throw FormatException('$label must be a map.');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static int _asInt(Object? raw, String label) {
    if (raw is! num) throw FormatException('$label must be numeric.');
    return raw.toInt();
  }
}

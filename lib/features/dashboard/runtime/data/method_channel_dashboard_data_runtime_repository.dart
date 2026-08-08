import 'package:flutter/services.dart';

import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
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
    implements DashboardDataRuntimeRepository {
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
          ..._filterArguments(request.filterScope),
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
    return decodedIndex.withBridgeTransferDurationMicros(bridgeTransferMicros);
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
    final raw = await _channel
        .invokeMethod<Object?>('readDashboardCommittedPage', <String, Object?>{
          ..._scopeArguments(request.scope),
          'parentQueryKey': request.parentQueryKey.value,
          'coreRevision': request.coreRevision,
          'presentationEpoch': request.presentationEpoch,
          'commitGeneration': request.commitGeneration,
          'pageSize': request.pageSize,
          'after': request.startCursor,
          'acquisitionReason': request.reason.name,
        });
    platformTimer.stop();
    _platformDurationMicros.add(platformTimer.elapsedMicroseconds);
    final bytes = _binary(raw);
    final decodeTimer = Stopwatch()..start();
    final frame = await _pageDecodeWorker.decodePage(bytes, request: request);
    decodeTimer.stop();
    _pageDecodeDurationMicros.add(decodeTimer.elapsedMicroseconds);
    _payloadBytes.add(bytes.lengthInBytes);
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

  static Map<String, Object?> _filterArguments(CurrentLedgerQueryScope scope) =>
      <String, Object?>{
        'direction': scope.direction.name,
        'periodGroups': const <Object?>[],
        'categoryIds': _sorted(scope.categoryIds),
        'partnerIds': _sorted(scope.partnerIds),
        'refinements': scope.refinements,
      };

  static Map<String, Object?> _scopeArguments(CurrentLedgerQueryScope scope) =>
      <String, Object?>{
        'scopeKey': scope.key.value,
        'direction': scope.direction.name,
        'periodGroups': _periodGroups(scope.timeScope),
        'categoryIds': _sorted(scope.categoryIds),
        'partnerIds': _sorted(scope.partnerIds),
        'refinements': scope.refinements,
      };

  static List<Object?> _periodGroups(LedgerTimeScope scope) {
    final selection = switch (scope) {
      AllTimeScope() => null,
      YearScope(:final year) => <String, Object?>{
        'kind': 'year',
        'value': year.toString().padLeft(4, '0'),
      },
      MonthScope(:final value) => <String, Object?>{
        'kind': 'month',
        'value': value.isoString,
      },
      DayScope(:final date) => <String, Object?>{
        'kind': 'day',
        'value': date.isoString,
      },
    };
    if (selection == null) return const <Object?>[];
    return <Object?>[
      <String, Object?>{
        'key': 'time',
        'selections': <Object?>[selection],
      },
    ];
  }

  static Uint8List _binary(Object? raw) => switch (raw) {
    Uint8List value => value,
    ByteData value => value.buffer.asUint8List(
      value.offsetInBytes,
      value.lengthInBytes,
    ),
    _ => throw const FormatException('Dashboard response must be binary.'),
  };

  static List<String> _sorted(Iterable<String> values) =>
      values.toList()..sort();

  static Map<String, Object?> _asMap(Object? raw, String label) {
    if (raw is! Map) throw FormatException('$label must be a map.');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static int _asInt(Object? raw, String label) {
    if (raw is! num) throw FormatException('$label must be numeric.');
    return raw.toInt();
  }
}

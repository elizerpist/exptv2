import 'package:flutter/services.dart';

import '../../motion/dashboard_semantic_catalog.dart';
import '../../prepared/data/dashboard_prepared_binary_codec.dart';
import '../../prepared/data/dashboard_prepared_deck_repository.dart';
import '../../prepared/domain/dashboard_prepared_deck.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../domain/current_ledger_query_scope.dart';

/// The single Android transport for immutable prepared dashboard data.
///
/// Deck, committed-live and paging payloads are bounded binary envelopes.
/// Their decoding and LogBox projection are delegated to a worker isolate;
/// the UI isolate only receives complete immutable objects.
final class MethodChannelDashboardPreparedRepository
    implements
        DashboardPreparedDeckRepository,
        DashboardPreparedLiveRepository,
        DashboardCoreRevisionRepository,
        DashboardPreparedRepositoryMetrics,
        DashboardNativePreparedRepository {
  MethodChannelDashboardPreparedRepository({
    MethodChannel? channel,
    EventChannel? eventChannel,
    EventChannel? revisionEventChannel,
    DashboardPreparedDeckDecodeWorker? preparedDecodeWorker,
    DashboardPreparedFrameDecodeWorker? preparedFrameDecodeWorker,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _eventChannel = eventChannel ?? const EventChannel(_streamChannelName),
       _revisionEventChannel =
           revisionEventChannel ??
           const EventChannel(_revisionStreamChannelName),
       _preparedDecodeWorker =
           preparedDecodeWorker ??
           const IsolateDashboardPreparedDeckDecodeWorker(),
       _preparedFrameDecodeWorker =
           preparedFrameDecodeWorker ??
           (preparedDecodeWorker is DashboardPreparedFrameDecodeWorker
               ? preparedDecodeWorker as DashboardPreparedFrameDecodeWorker
               : const IsolateDashboardPreparedDeckDecodeWorker());

  static const _channelName = 'com.fluvi/dashboard_query';
  static const _streamChannelName = 'com.fluvi/dashboard_query_stream';
  static const _revisionStreamChannelName =
      'com.fluvi/dashboard_core_revision_stream';

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  final EventChannel _revisionEventChannel;
  final DashboardPreparedDeckDecodeWorker _preparedDecodeWorker;
  final DashboardPreparedFrameDecodeWorker _preparedFrameDecodeWorker;
  static int _nextSubscriptionOrdinal = 0;
  int _preparedDeckCalls = 0;
  int _platformCalls = 0;
  int _committedFrameDecodes = 0;
  int _pageReads = 0;
  final List<int> _platformChannelDurationMicros = <int>[];
  final List<int> _sqlCallCounts = <int>[];
  final List<int> _sqlDurationMicros = <int>[];
  final List<int> _nativeMappingDurationMicros = <int>[];
  final List<int> _dartParsingDurationMicros = <int>[];
  final List<int> _payloadBytes = <int>[];
  final List<int> _liveFrameDecodeDurationMicros = <int>[];
  final List<int> _pageDecodeDurationMicros = <int>[];

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) async {
    if (token.isCancelled) {
      throw StateError('Prepared deck request was cancelled before dispatch.');
    }
    final yearArguments = request.key.childKind == DashboardChildKind.year
        ? <String, Object?>{
            'yearWindowStart': request.semanticCatalog.values.first,
            'yearWindowEndInclusive': request.semanticCatalog.values.last,
          }
        : const <String, Object?>{};
    _preparedDeckCalls += 1;
    _platformCalls += 1;
    final platformTimer = Stopwatch()..start();
    final raw = await _channel
        .invokeMethod<Object?>('readDashboardPreparedDeck', <String, Object?>{
          ..._arguments(request.parentScope, pageSize: request.key.pageSize),
          'childPeriod': request.key.childKind.name,
          'requestGeneration': token.generation,
          'requestId': '${request.key}|generation:${token.generation}',
          ...yearArguments,
        });
    platformTimer.stop();
    _platformChannelDurationMicros.add(platformTimer.elapsedMicroseconds);
    if (token.isCancelled) {
      throw StateError(
        'Prepared deck request was cancelled after native read.',
      );
    }
    final bytes = _binary(raw);
    final deck = await _preparedDecodeWorker.decode(
      bytes,
      request: request,
      expectedGeneration: token.generation,
    );
    final metrics = deck.buildMetrics;
    _sqlCallCounts.add(metrics.sqlCallCount);
    _sqlDurationMicros.add(metrics.nativeQueryDurationMicros);
    _nativeMappingDurationMicros.add(metrics.nativeMappingDurationMicros);
    _dartParsingDurationMicros.add(metrics.dartDecodeProjectionDurationMicros);
    _payloadBytes.add(bytes.lengthInBytes);
    return deck;
  }

  @override
  Stream<DashboardPreparedFrame> watchCommittedFrame(
    DashboardCommittedFrameRequest request,
  ) {
    final subscriptionId =
        '${request.scope.key.value}#committed:${++_nextSubscriptionOrdinal}';
    final arguments = <String, Object?>{
      ..._arguments(
        request.scope,
        pageSize: request.pageSize,
        subscriptionId: subscriptionId,
      ),
      'parentQueryKey': request.parentQueryKey.value,
      'coreRevision': request.coreRevision,
      'presentationEpoch': request.presentationEpoch,
      'leaseGeneration': request.leaseGeneration,
    };
    return _eventChannel.receiveBroadcastStream(arguments).asyncMap((
      raw,
    ) async {
      final timer = Stopwatch()..start();
      final frame = await _preparedFrameDecodeWorker.decodeFrame(
        _binary(raw),
        request: request,
      );
      timer.stop();
      _committedFrameDecodes += 1;
      _liveFrameDecodeDurationMicros.add(timer.elapsedMicroseconds);
      return frame;
    });
  }

  @override
  Future<DashboardPreparedFrame> readCommittedNextPage(
    DashboardCommittedFrameRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) async {
    _pageReads += 1;
    _platformCalls += 1;
    final platformTimer = Stopwatch()..start();
    final raw = await _channel.invokeMethod<Object?>(
      'readDashboardPreparedFrame',
      <String, Object?>{
        ..._arguments(request.scope, pageSize: request.pageSize, after: after),
        'parentQueryKey': request.parentQueryKey.value,
        'coreRevision': request.coreRevision,
        'presentationEpoch': request.presentationEpoch,
        'leaseGeneration': request.leaseGeneration,
      },
    );
    platformTimer.stop();
    _platformChannelDurationMicros.add(platformTimer.elapsedMicroseconds);
    final decodeTimer = Stopwatch()..start();
    final frame = await _preparedFrameDecodeWorker.decodePage(
      _binary(raw),
      request: request,
      currentFrame: currentFrame,
    );
    decodeTimer.stop();
    _pageDecodeDurationMicros.add(decodeTimer.elapsedMicroseconds);
    return frame;
  }

  @override
  Map<String, Object?> performanceReport() => <String, Object?>{
    'prepared_deck_calls': _preparedDeckCalls,
    'platform_calls': _platformCalls,
    'committed_frame_decodes': _committedFrameDecodes,
    'page_reads': _pageReads,
    'platform_channel_duration_micros': List<int>.unmodifiable(
      _platformChannelDurationMicros,
    ),
    'sql_call_counts': List<int>.unmodifiable(_sqlCallCounts),
    'sql_duration_micros': List<int>.unmodifiable(_sqlDurationMicros),
    'native_mapping_duration_micros': List<int>.unmodifiable(
      _nativeMappingDurationMicros,
    ),
    'dart_parsing_duration_micros': List<int>.unmodifiable(
      _dartParsingDurationMicros,
    ),
    'payload_bytes': List<int>.unmodifiable(_payloadBytes),
    'live_frame_decode_duration_micros': List<int>.unmodifiable(
      _liveFrameDecodeDurationMicros,
    ),
    'page_decode_duration_micros': List<int>.unmodifiable(
      _pageDecodeDurationMicros,
    ),
  };

  @override
  Stream<int> watchCoreRevision() async* {
    int? previous;
    await for (final raw in _revisionEventChannel.receiveBroadcastStream()) {
      final map = _asMap(raw, 'Dashboard core revision event');
      final revision = _asInt(map['coreRevision'], 'coreRevision');
      if (revision == previous) continue;
      previous = revision;
      yield revision;
    }
  }

  static Map<String, Object?> _arguments(
    CurrentLedgerQueryScope scope, {
    required int pageSize,
    Map<String, Object?>? after,
    String? subscriptionId,
  }) => <String, Object?>{
    'scopeKey': scope.key.value,
    'debugFlowId': 'Q-${scope.key.value}',
    'direction': scope.direction.name,
    'periodGroups': _periodGroups(scope.timeScope),
    'categoryIds': _sorted(scope.categoryIds),
    'partnerIds': _sorted(scope.partnerIds),
    'refinements': scope.refinements,
    'pageSize': pageSize,
    'subscriptionId': ?subscriptionId,
    ...?after == null ? null : <String, Object?>{'after': after},
  };

  static Uint8List _binary(Object? raw) => switch (raw) {
    Uint8List value => value,
    ByteData value => value.buffer.asUint8List(
      value.offsetInBytes,
      value.lengthInBytes,
    ),
    _ => throw const FormatException(
      'Prepared dashboard response must be binary.',
    ),
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

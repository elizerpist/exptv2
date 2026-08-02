import 'package:flutter/services.dart';

import '../domain/current_ledger_query_scope.dart';
import '../application/dashboard_query_debug.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'dashboard_ledger_repository.dart';

/// Android bridge for the shared dashboard query contract.
///
/// The core receives the same direction, canonical time scope and future
/// facets that the Flutter query controller owns. It performs both the
/// aggregate and the bounded timeline read from that one scope.
class MethodChannelDashboardLedgerRepository
    implements DashboardLedgerRepository {
  MethodChannelDashboardLedgerRepository({
    MethodChannel? channel,
    EventChannel? eventChannel,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _eventChannel = eventChannel ?? const EventChannel(_streamChannelName);

  static const _channelName = 'com.fluvi/dashboard_query';
  static const _streamChannelName = 'com.fluvi/dashboard_query_stream';

  final MethodChannel _channel;
  final EventChannel _eventChannel;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('readDashboard', {
      ..._arguments(scope, pageSize: pageSize, after: after),
    });

    return _decodeResult(raw, scope: scope);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    return _eventChannel
        .receiveBroadcastStream(
          _arguments(scope, pageSize: pageSize, after: after),
        )
        .map((raw) => _decodeResult(raw, scope: scope));
  }

  static Map<String, Object?> _arguments(
    CurrentLedgerQueryScope scope, {
    required int pageSize,
    Map<String, Object?>? after,
  }) {
    return <String, Object?>{
      'scopeKey': scope.key.value,
      'debugFlowId': DashboardQueryDebug.flowIdFor(scope),
      'direction': scope.direction.name,
      'periodGroups': _periodGroups(scope.timeScope),
      'categoryIds': _sorted(scope.categoryIds),
      'partnerIds': _sorted(scope.partnerIds),
      'refinements': scope.refinements,
      'pageSize': pageSize,
      ...?after == null ? null : <String, Object?>{'after': after},
    };
  }

  static DashboardLedgerResult _decodeResult(
    Object? raw, {
    CurrentLedgerQueryScope? scope,
  }) {
    final map = _asMap(raw, 'Dashboard query response');
    final result = DashboardLedgerResult(
      totalMinor: _asInt(map['totalMinor'], 'totalMinor'),
      entryCount: _asInt(map['entryCount'], 'entryCount'),
      entries: _entries(map['entries']),
      nextCursor: _optionalMap(map['nextCursor']),
      coreRevision: (map['coreRevision'] as num?)?.toInt(),
      scopeKey: map['scopeKey'] as String?,
      timeScopeKey: map['timeScopeKey'] as String?,
      direction: map['direction'] as String?,
      flowId: map['flowId'] as String?,
    );
    DashboardQueryDebug.mark(
      'D7 dartBridgeParsed',
      scope: scope,
      queryKey: result.scopeKey,
      flowId: result.flowId,
      result: result,
      detail: 'direction=${result.direction ?? '-'}',
    );
    return result;
  }

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

  static List<String> _sorted(Iterable<String> values) {
    return values.toList()..sort();
  }

  static List<DashboardLedgerEntry> _entries(Object? raw) {
    if (raw == null) return const <DashboardLedgerEntry>[];
    if (raw is! List<Object?>) {
      throw const FormatException('Dashboard query entries must be a list.');
    }
    return raw
        .map((entry) {
          final map = _asMap(entry, 'Dashboard query entry');
          return DashboardLedgerEntry(
            id: _asString(map['id'], 'id'),
            partnerId: _asString(map['partnerId'], 'partnerId'),
            categoryId: _asString(map['categoryId'], 'categoryId'),
            direction: _asString(map['direction'], 'direction'),
            amountMinor: _asInt(map['amountMinor'], 'amountMinor'),
            bookedLocalEpochDay: _asInt(
              map['bookedLocalEpochDay'],
              'bookedLocalEpochDay',
            ),
            bookedLocalTimeMinutes: _asInt(
              map['bookedLocalTimeMinutes'],
              'bookedLocalTimeMinutes',
            ),
            note: map['note'] as String?,
            occurredAtUtcMs: (map['occurredAtUtcMs'] as num?)?.toInt(),
            partnerDisplayName: map['partnerDisplayName'] as String?,
            categoryDisplayName: map['categoryDisplayName'] as String?,
            categoryColorId: map['categoryColorId'] as String?,
            categoryIconId: map['categoryIconId'] as String?,
            assignmentMode: map['assignmentMode'] as String?,
            originKind: map['originKind'] as String?,
          );
        })
        .toList(growable: false);
  }

  static Map<String, Object?>? _optionalMap(Object? raw) {
    if (raw == null) return null;
    return _asMap(raw, 'Dashboard query cursor');
  }

  static Map<String, Object?> _asMap(Object? raw, String label) {
    if (raw is! Map) throw FormatException('$label must be a map.');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _asString(Object? raw, String label) {
    if (raw is! String) throw FormatException('$label must be a string.');
    return raw;
  }

  static int _asInt(Object? raw, String label) {
    if (raw is! num) throw FormatException('$label must be numeric.');
    return raw.toInt();
  }
}

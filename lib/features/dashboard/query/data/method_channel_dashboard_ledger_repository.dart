import 'package:flutter/services.dart';

import '../domain/current_ledger_query_scope.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'dashboard_ledger_repository.dart';

/// Android bridge for the shared dashboard query contract.
///
/// The core receives the same direction, canonical time scope and future
/// facets that the Flutter query controller owns. It performs both the
/// aggregate and the bounded timeline read from that one scope.
class MethodChannelDashboardLedgerRepository
    implements DashboardLedgerRepository {
  MethodChannelDashboardLedgerRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.fluvi/dashboard_query';

  final MethodChannel _channel;

  @override
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope) async {
    final raw = await _channel.invokeMethod<Object?>('readDashboard', {
      'scopeKey': scope.key.value,
      'direction': scope.direction.name,
      'periodGroups': _periodGroups(scope.timeScope),
      'categoryIds': _sorted(scope.categoryIds),
      'partnerIds': _sorted(scope.partnerIds),
      'refinements': scope.refinements,
    });

    final map = _asMap(raw, 'Dashboard query response');
    return DashboardLedgerResult(
      totalMinor: _asInt(map['totalMinor'], 'totalMinor'),
      entryCount: _asInt(map['entryCount'], 'entryCount'),
      entries: _entries(map['entries']),
      nextCursor: _optionalMap(map['nextCursor']),
      coreRevision: (map['coreRevision'] as num?)?.toInt(),
    );
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

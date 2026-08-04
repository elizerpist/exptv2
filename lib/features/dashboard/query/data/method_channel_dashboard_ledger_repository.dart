import 'package:flutter/services.dart';

import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/time_child_summary.dart';
import '../application/dashboard_query_debug.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import 'dashboard_child_preview_bundle.dart';
import 'dashboard_child_preview_repository.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'dashboard_child_summary_repository.dart';
import 'dashboard_ledger_repository.dart';

/// Android bridge for the shared dashboard query contract.
///
/// The core receives the same direction, canonical time scope and future
/// facets that the Flutter query controller owns. It performs both the
/// aggregate and the bounded timeline read from that one scope.
class MethodChannelDashboardLedgerRepository
    implements
        DashboardLedgerRepository,
        DashboardCoreRevisionRepository,
        DashboardChildSummaryRepository,
        DashboardChildPreviewRepository {
  MethodChannelDashboardLedgerRepository({
    MethodChannel? channel,
    EventChannel? eventChannel,
    EventChannel? revisionEventChannel,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _eventChannel = eventChannel ?? const EventChannel(_streamChannelName),
       _revisionEventChannel =
           revisionEventChannel ??
           const EventChannel(_revisionStreamChannelName);

  static const _channelName = 'com.fluvi/dashboard_query';
  static const _streamChannelName = 'com.fluvi/dashboard_query_stream';
  static const _revisionStreamChannelName =
      'com.fluvi/dashboard_core_revision_stream';

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  final EventChannel _revisionEventChannel;
  static int _nextSubscriptionOrdinal = 0;

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

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) async {
    final raw = await _channel
        .invokeMethod<Object?>('readDashboardChildSummaries', <String, Object?>{
          ..._arguments(request.parentScope, pageSize: 1),
          'childPeriod': request.childPeriod.name,
        });
    return _decodeChildSummaryIndex(raw, request: request);
  }

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) async {
    final raw = await _channel.invokeMethod<Object?>(
      'readDashboardChildPreviewBundle',
      <String, Object?>{
        ..._arguments(request.parentScope, pageSize: request.previewPageSize),
        'childPeriod': request.childPeriod.name,
        'requestGeneration': request.requestGeneration,
        'requestId': request.requestId,
      },
    );
    return _decodeChildPreviewBundle(raw, request: request);
  }

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
    final flowId = DashboardQueryDebug.flowIdFor(scope);
    final subscriptionId = '$flowId#${++_nextSubscriptionOrdinal}';
    final arguments = _arguments(
      scope,
      pageSize: pageSize,
      after: after,
      subscriptionId: subscriptionId,
    );
    return Stream<DashboardLedgerResult>.multi((controller) {
      DashboardQueryDebug.mark(
        'D8A repositoryWatchRequested',
        scope: scope,
        flowId: flowId,
        detail: 'subscriptionId=$subscriptionId',
      );
      DashboardQueryDebug.mark(
        'D8B nativeWatchSubscribeRequested',
        scope: scope,
        flowId: flowId,
        detail: 'subscriptionId=$subscriptionId channel=$_streamChannelName',
      );
      var receivedSnapshot = false;
      final subscription = _eventChannel
          .receiveBroadcastStream(arguments)
          .listen(
            (raw) {
              try {
                final result = _decodeResult(raw, scope: scope);
                receivedSnapshot = true;
                controller.add(result);
              } on Object catch (error, stackTrace) {
                controller.addError(error, stackTrace);
              }
            },
            onError: controller.addError,
            onDone: () {
              if (!receivedSnapshot && !controller.isClosed) {
                controller.addError(
                  StateError(
                    'Native dashboard observer closed before its initial '
                    'snapshot for ${scope.key.value}.',
                  ),
                );
              }
              if (!controller.isClosed) controller.close();
            },
          );
      controller.onCancel = subscription.cancel;
    });
  }

  static Map<String, Object?> _arguments(
    CurrentLedgerQueryScope scope, {
    required int pageSize,
    Map<String, Object?>? after,
    String? subscriptionId,
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
      'subscriptionId': ?subscriptionId,
      ...?after == null ? null : <String, Object?>{'after': after},
    };
  }

  static DashboardLedgerResult _decodeResult(
    Object? raw, {
    CurrentLedgerQueryScope? scope,
    bool emitDebug = true,
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
    if (emitDebug) {
      DashboardQueryDebug.mark(
        'D7 dartBridgeParsed',
        scope: scope,
        queryKey: result.scopeKey,
        flowId: result.flowId,
        result: result,
        detail: 'direction=${result.direction ?? '-'}',
      );
    }
    return result;
  }

  static DashboardTimeChildSummaryIndex _decodeChildSummaryIndex(
    Object? raw, {
    required DashboardChildSummaryRequest request,
  }) {
    final map = _asMap(raw, 'Dashboard child summary response');
    final values = <String, DashboardTimeChildSummary>{};
    final rawValues = map['values'];
    if (rawValues is! List<Object?>) {
      throw const FormatException(
        'Dashboard child summary values must be a list.',
      );
    }
    for (final rawValue in rawValues) {
      final value = _asMap(rawValue, 'Dashboard child summary value');
      final summary = DashboardTimeChildSummary(
        childPeriodValue: _asString(
          value['childPeriodValue'],
          'childPeriodValue',
        ),
        childQueryKey: _asString(value['childQueryKey'], 'childQueryKey'),
        totalMinor: _asInt(value['totalMinor'], 'totalMinor'),
        entryCount: _asInt(value['entryCount'], 'entryCount'),
      );
      values[summary.childPeriodValue] = summary;
    }
    final childPeriod = TimeChildPeriod.values.byName(
      _asString(map['childPeriod'], 'childPeriod'),
    );
    if (childPeriod != request.childPeriod) {
      throw FormatException(
        'Dashboard child summary period mismatch: expected '
        '${request.childPeriod.name}, got ${childPeriod.name}.',
      );
    }
    final index = DashboardTimeChildSummaryIndex(
      parentQueryKey: _asString(map['parentQueryKey'], 'parentQueryKey'),
      direction: LedgerDirection.values.byName(
        _asString(map['direction'], 'direction'),
      ),
      childPeriod: childPeriod,
      coreRevision: _asInt(map['coreRevision'], 'coreRevision'),
      isComplete: _asBool(map['isComplete'], 'isComplete'),
      values: values,
    );
    if (index.parentQueryKey != request.parentScope.key.value ||
        index.direction != request.parentScope.direction) {
      throw const FormatException('Dashboard child summary scope mismatch.');
    }
    return index;
  }

  static DashboardChildPreviewBundle _decodeChildPreviewBundle(
    Object? raw, {
    required DashboardChildPreviewBundleRequest request,
  }) {
    final stopwatch = Stopwatch()..start();
    final map = _asMap(raw, 'Dashboard child preview response');
    final responseGeneration = _asInt(
      map['requestGeneration'],
      'requestGeneration',
    );
    final responseRequestId = _asString(map['requestId'], 'requestId');
    if (responseGeneration != request.requestGeneration ||
        responseRequestId != request.requestId) {
      throw const FormatException(
        'Dashboard child preview request identity mismatch.',
      );
    }
    final childPeriod = TimeChildPeriod.values.byName(
      _asString(map['childPeriod'], 'childPeriod'),
    );
    if (childPeriod != request.childPeriod) {
      throw FormatException(
        'Dashboard child preview period mismatch: expected '
        '${request.childPeriod.name}, got ${childPeriod.name}.',
      );
    }
    final parentQueryKey = _asString(map['parentQueryKey'], 'parentQueryKey');
    if (parentQueryKey != request.parentScope.key.value) {
      throw const FormatException('Dashboard child preview parent mismatch.');
    }
    final direction = LedgerDirection.values.byName(
      _asString(map['direction'], 'direction'),
    );
    if (direction != request.parentScope.direction) {
      throw const FormatException(
        'Dashboard child preview direction mismatch.',
      );
    }
    final revision = _asInt(map['coreRevision'], 'coreRevision');
    final rawChildren = map['children'];
    if (rawChildren is! List<Object?>) {
      throw const FormatException(
        'Dashboard child preview children must be a list.',
      );
    }
    final children = <LedgerQueryKey, DashboardChildPreview>{};
    var nonEmptyCount = 0;
    var totalEntryCount = 0;
    for (final rawChild in rawChildren) {
      final result = _decodeResult(rawChild, emitDebug: false);
      if (result.coreRevision != null && result.coreRevision != revision) {
        throw const FormatException(
          'Dashboard child preview revision mismatch.',
        );
      }
      final value = _childPeriodValue(result.timeScopeKey);
      final scope = request.parentScope.copyWith(
        timeScope: _childScope(value, childPeriod),
      );
      if (result.scopeKey != null && result.scopeKey != scope.key.value) {
        throw const FormatException(
          'Dashboard child preview child key mismatch.',
        );
      }
      children[scope.key] = DashboardChildPreview(
        childPeriodValue: value,
        scope: scope,
        result: result,
      );
      if (result.entryCount > 0) nonEmptyCount += 1;
      totalEntryCount += result.entryCount;
    }
    stopwatch.stop();
    DashboardQueryDebug.mark(
      'CHILD_PREVIEW_BUNDLE_PARSED',
      scope: request.parentScope,
      queryKey: request.parentScope.key.value,
      coreRevision: revision,
      entryCount: totalEntryCount,
      durationMs: stopwatch.elapsedMilliseconds,
      detail:
          'childCount=${children.length} '
          'nonEmptyCount=$nonEmptyCount '
          'zeroCount=${children.length - nonEmptyCount} '
          'totalEntryCount=$totalEntryCount '
          'parseDurationMicros=${stopwatch.elapsedMicroseconds} '
          'requestGeneration=${request.requestGeneration} '
          'source=childPreviewBundle',
    );
    return DashboardChildPreviewBundle(
      parentScope: request.parentScope,
      childPeriod: childPeriod,
      coreRevision: revision,
      previewPageSize: request.previewPageSize,
      childrenByQueryKey: children,
    );
  }

  static String _childPeriodValue(String? timeScopeKey) {
    if (timeScopeKey == null || !timeScopeKey.contains(':')) {
      throw const FormatException('Dashboard child preview has no time scope.');
    }
    return timeScopeKey.substring(timeScopeKey.indexOf(':') + 1);
  }

  static LedgerTimeScope _childScope(
    String value,
    TimeChildPeriod childPeriod,
  ) => switch (childPeriod) {
    TimeChildPeriod.year => YearScope(int.parse(value)),
    TimeChildPeriod.month => MonthScope(_parseMonth(value)),
    TimeChildPeriod.day => DayScope(_parseDay(value)),
  };

  static YearMonth _parseMonth(String value) {
    final parts = value.split('-');
    if (parts.length != 2) throw FormatException('Invalid month: $value');
    return YearMonth(year: int.parse(parts[0]), month: int.parse(parts[1]));
  }

  static LocalDate _parseDay(String value) {
    final parts = value.split('-');
    if (parts.length != 3) throw FormatException('Invalid day: $value');
    return LocalDate(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
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

  static bool _asBool(Object? raw, String label) {
    if (raw is! bool) throw FormatException('$label must be a boolean.');
    return raw;
  }
}

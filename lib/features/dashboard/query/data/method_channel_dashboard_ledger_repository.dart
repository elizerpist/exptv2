import 'package:flutter/services.dart';

import '../../application/dashboard_parent_display_bundle.dart';
import '../../application/dashboard_parent_display_bundle_controller.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/time_child_summary.dart';
import '../application/dashboard_query_debug.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../logbox/data/dashboard_log_repository.dart';
import '../../logbox/domain/dashboard_log_models.dart';
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
        DashboardLedgerFirstPagePrefetchRepository,
        DashboardChildSummaryRepository,
        DashboardLogPageRepository,
        DashboardParentDisplayBundleRepository {
  MethodChannelDashboardLedgerRepository({
    MethodChannel? channel,
    EventChannel? eventChannel,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _eventChannel = eventChannel ?? const EventChannel(_streamChannelName);

  static const _channelName = 'com.fluvi/dashboard_query';
  static const _streamChannelName = 'com.fluvi/dashboard_query_stream';

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  static int _nextSubscriptionOrdinal = 0;

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
  Future<DashboardParentDisplayBundlePayload> readParentDisplayBundle(
    DashboardParentDisplayBundleRequest request,
  ) async {
    final childPeriod = switch (request.plane) {
      TimePlane.month => 'day',
      TimePlane.year => 'month',
      TimePlane.sum => throw ArgumentError.value(
        request.plane,
        'request.plane',
        'SUM is an unbounded corridor, not a finite parent bundle.',
      ),
    };
    final expectedByKey = <String, CurrentLedgerQueryScope>{
      for (final child in request.expectedChildren) child.key.value: child,
    };
    final raw = await _channel.invokeMethod<Object?>(
      'readDashboardParentPreviewBundle',
      <String, Object?>{
        ..._arguments(request.parentScope, pageSize: 1, maxDayGroups: 7),
        'childPeriod': childPeriod,
        'expectedChildPeriodValues': request.expectedChildren
            .map(_childPeriodValue)
            .toList(growable: false),
      },
    );
    final map = _asMap(raw, 'Dashboard parent preview bundle response');
    if (_asString(map['parentQueryKey'], 'parentQueryKey') !=
            request.parentScope.key.value ||
        _asString(map['direction'], 'direction') !=
            request.parentScope.direction.name ||
        _asString(map['childPeriod'], 'childPeriod') != childPeriod) {
      throw const FormatException('Dashboard parent preview bundle mismatch.');
    }
    final coreRevision = _asInt(map['coreRevision'], 'coreRevision');
    final rawPreviews = map['previews'];
    if (rawPreviews is! List<Object?>) {
      throw const FormatException(
        'Dashboard parent preview entries must be a list.',
      );
    }
    final snapshots = <DashboardLogPreviewSnapshot>[];
    for (final rawPreview in rawPreviews) {
      final preview = _asMap(rawPreview, 'Dashboard parent preview entry');
      final queryKey = _asString(preview['scopeKey'], 'scopeKey');
      final scope = expectedByKey[queryKey];
      if (scope == null) {
        throw FormatException(
          'Parent preview contains an unexpected child $queryKey.',
        );
      }
      final groups = _dayGroups(preview['dayGroups'])
          .map(
            (group) => DashboardDayLogGroup(
              localDate: _localDateFromEpochDay(group.bookedLocalEpochDay),
              rows: group.entries,
            ),
          )
          .toList(growable: false);
      snapshots.add(
        DashboardLogPreviewSnapshot.populated(
          scope: scope,
          coreRevision: coreRevision,
          totalMinor: _asInt(preview['totalMinor'], 'totalMinor'),
          entryCount: _asInt(preview['entryCount'], 'entryCount'),
          groups: groups,
        ),
      );
    }
    return DashboardParentDisplayBundlePayload(
      parentScope: request.parentScope,
      plane: request.plane,
      coreRevision: coreRevision,
      snapshots: snapshots,
    );
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
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('readDashboardLogPage', {
      ..._arguments(scope, pageSize: 1),
      'maxDayGroups': maxDayGroups,
      if (before != null)
        'beforeLocalEpochDayExclusive': _epochDay(
          before.beforeLocalDateExclusive,
        ),
    });
    return _decodeLogPage(raw, scope: scope);
  }

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('readDashboardLogPage', {
      ..._arguments(scope, pageSize: 1, maxDayGroups: maxDayGroups),
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
      maxDayGroups: 7,
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
    int? maxDayGroups,
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
      ...?(maxDayGroups == null
          ? null
          : <String, Object?>{'maxDayGroups': maxDayGroups}),
      'subscriptionId': ?subscriptionId,
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
      dayGroups: _dayGroups(map['dayGroups']),
      nextCursor: _optionalMap(map['nextCursor']),
      nextDayCursor: _optionalMap(map['nextDayCursor']),
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

  static DashboardDayGroupPage _decodeLogPage(
    Object? raw, {
    required CurrentLedgerQueryScope scope,
  }) {
    final map = _asMap(raw, 'Dashboard LogBox page response');
    final queryKey = _asString(map['scopeKey'], 'scopeKey');
    if (queryKey != scope.key.value) {
      throw FormatException(
        'Dashboard LogBox page scope mismatch: expected ${scope.key.value}, '
        'got $queryKey.',
      );
    }
    final result = _decodeResult(map, scope: scope);
    return DashboardDayGroupPage(
      canonicalQueryKey: queryKey,
      coreRevision: _asInt(map['coreRevision'], 'coreRevision'),
      groups: result.dayGroups
          .map(
            (group) => DashboardDayLogGroup(
              localDate: _localDateFromEpochDay(group.bookedLocalEpochDay),
              rows: group.entries,
            ),
          )
          .toList(growable: false),
      nextCursor: result.nextDayCursor == null
          ? null
          : DashboardDayGroupPageCursor(
              beforeLocalDateExclusive: _localDateFromEpochDay(
                _asInt(
                  result.nextDayCursor!['beforeLocalEpochDayExclusive'],
                  'beforeLocalEpochDayExclusive',
                ),
              ),
            ),
    );
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

  static String _childPeriodValue(CurrentLedgerQueryScope scope) =>
      switch (scope.timeScope) {
        YearScope(:final year) => year.toString().padLeft(4, '0'),
        MonthScope(:final value) => value.isoString,
        DayScope(:final date) => date.isoString,
        AllTimeScope() => throw ArgumentError.value(
          scope,
          'scope',
          'A finite preview child needs a concrete time scope.',
        ),
      };

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

  static List<DashboardLedgerDayGroup> _dayGroups(Object? raw) {
    if (raw == null) return const <DashboardLedgerDayGroup>[];
    if (raw is! List<Object?>) {
      throw const FormatException('Dashboard query dayGroups must be a list.');
    }
    return raw
        .map((rawGroup) {
          final group = _asMap(rawGroup, 'Dashboard LogBox day group');
          return DashboardLedgerDayGroup(
            bookedLocalEpochDay: _asInt(
              group['bookedLocalEpochDay'],
              'bookedLocalEpochDay',
            ),
            entries: _entries(group['entries']),
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

  static LocalDate _localDateFromEpochDay(int epochDay) {
    final date = DateTime.utc(1970).add(Duration(days: epochDay));
    return LocalDate(year: date.year, month: date.month, day: date.day);
  }

  static int _epochDay(LocalDate date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;
}

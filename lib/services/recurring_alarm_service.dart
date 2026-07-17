import 'package:flutter/services.dart';

class RecurringAlarmDebugState {
  const RecurringAlarmDebugState({
    required this.effectiveMillis,
    required this.usingOverride,
    this.overrideMillis,
    this.logs = const <String>[],
  });

  final int? overrideMillis;
  final int? effectiveMillis;
  final bool usingOverride;
  final List<String> logs;

  DateTime? get overrideDate => _dateFromMillis(overrideMillis);
  DateTime? get effectiveDate => _dateFromMillis(effectiveMillis);

  static RecurringAlarmDebugState fromMap(Map<dynamic, dynamic> map) {
    return RecurringAlarmDebugState(
      overrideMillis: _intValue(map['overrideMillis']),
      effectiveMillis: _intValue(map['effectiveMillis']),
      usingOverride: map['usingOverride'] == true,
      logs: (map['logs'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  static DateTime? _dateFromMillis(int? value) {
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  static int? _intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class RecurringAlarmProcessResult {
  const RecurringAlarmProcessResult({
    required this.state,
    required this.processedCount,
    this.processed = const <Map<String, Object?>>[],
  });

  final RecurringAlarmDebugState state;
  final int processedCount;
  final List<Map<String, Object?>> processed;

  static RecurringAlarmProcessResult fromMap(Map<dynamic, dynamic> map) {
    final statePayload = map['state'];
    final processedRows = map['processed'] as List<dynamic>? ?? <dynamic>[];
    return RecurringAlarmProcessResult(
      state: statePayload is Map<dynamic, dynamic>
          ? RecurringAlarmDebugState.fromMap(statePayload)
          : RecurringAlarmDebugState.fromMap(map),
      processedCount:
          RecurringAlarmDebugState._intValue(map['processedCount']) ?? 0,
      processed: processedRows
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (row) => row.map(
              (key, value) => MapEntry(key.toString(), value as Object?),
            ),
          )
          .toList(),
    );
  }
}

class RecurringAlarmService {
  RecurringAlarmService({MethodChannel? methodChannel})
    : _enabled = true,
      _methodChannel =
          methodChannel ?? const MethodChannel('exptv2/recurring_alarm');

  RecurringAlarmService.disabled()
    : _enabled = false,
      _methodChannel = const MethodChannel('exptv2/recurring_alarm');

  final bool _enabled;
  final MethodChannel _methodChannel;

  Future<bool> syncRecurringAlarms() async {
    if (!_enabled) return false;
    final synced = await _methodChannel.invokeMethod<bool>(
      'syncRecurringAlarms',
    );
    return synced ?? false;
  }

  Future<RecurringAlarmProcessResult> processRecurringNow({
    DateTime? targetDate,
  }) async {
    if (!_enabled) return _emptyProcessResult();
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'processRecurringNow',
      {
        if (targetDate != null)
          'targetMillis': targetDate.millisecondsSinceEpoch,
      },
    );
    return RecurringAlarmProcessResult.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmProcessResult> setDebugDateOverride(
    DateTime targetDate,
  ) async {
    if (!_enabled) return _emptyProcessResult();
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'setDebugDateOverride',
      {'targetMillis': normalizedTarget.millisecondsSinceEpoch},
    );
    return RecurringAlarmProcessResult.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmDebugState> clearDebugDateOverride() async {
    if (!_enabled) return _emptyDebugState();
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'clearDebugDateOverride',
    );
    return RecurringAlarmDebugState.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmDebugState> scheduleDebugTestAlarm({
    Duration delay = const Duration(minutes: 2),
  }) async {
    if (!_enabled) return _emptyDebugState();
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'scheduleRecurringDebugTestAlarm',
      {'delayMillis': delay.inMilliseconds},
    );
    return RecurringAlarmDebugState.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<RecurringAlarmDebugState> loadDebugState() async {
    if (!_enabled) return _emptyDebugState();
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'loadRecurringAlarmDebugState',
    );
    return RecurringAlarmDebugState.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<bool> clearDebugLog() async {
    if (!_enabled) return false;
    final cleared = await _methodChannel.invokeMethod<bool>(
      'clearRecurringAlarmDebugLog',
    );
    return cleared ?? false;
  }

  RecurringAlarmDebugState _emptyDebugState() => const RecurringAlarmDebugState(
    effectiveMillis: null,
    usingOverride: false,
  );

  RecurringAlarmProcessResult _emptyProcessResult() =>
      RecurringAlarmProcessResult(state: _emptyDebugState(), processedCount: 0);
}

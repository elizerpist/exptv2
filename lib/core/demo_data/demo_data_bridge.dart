import 'package:flutter/services.dart';

import 'demo_seed_report.dart';

/// Narrow debug-only bridge to the core's deterministic demo seed command.
///
/// The Flutter layer sends only the command flag. Dataset generation, IDs,
/// amounts and dates remain owned by the native application layer.
class MethodChannelDemoDataBridge {
  const MethodChannelDemoDataBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.fluvi/demo_data';

  final MethodChannel _channel;

  Future<DemoSeedReport> seedDemoDataset({bool forceReset = false}) async {
    final raw = await _channel.invokeMethod<Object?>('seedDemoDataset', {
      'forceReset': forceReset,
    });
    return _decodeReport(raw);
  }

  static DemoSeedReport _decodeReport(Object? raw) {
    final map = _asMap(raw, 'Demo seed report');
    final reports = map['monthlyReports'];
    if (reports is! List) {
      throw const FormatException(
        'Demo seed report monthlyReports must be a list.',
      );
    }
    return DemoSeedReport(
      seedVersion: _asInt(map['seedVersion'], 'seedVersion'),
      prngSeed: _asInt(map['prngSeed'], 'prngSeed'),
      createdCategoryCount: _asInt(
        map['createdCategoryCount'],
        'createdCategoryCount',
      ),
      createdPartnerCount: _asInt(
        map['createdPartnerCount'],
        'createdPartnerCount',
      ),
      createdEntryCount: _asInt(map['createdEntryCount'], 'createdEntryCount'),
      monthlyReports: reports
          .map((value) => _decodeMonthReport(value))
          .toList(growable: false),
      earliestEntryAtUtcMs: _optionalInt(map['earliestEntryAtUtcMs']),
      latestEntryAtUtcMs: _optionalInt(map['latestEntryAtUtcMs']),
      alreadySeeded: _asBool(map['alreadySeeded'], 'alreadySeeded'),
      durationMs: _asInt(map['durationMs'], 'durationMs'),
    );
  }

  static DemoMonthReport _decodeMonthReport(Object? raw) {
    final map = _asMap(raw, 'Demo monthly report');
    return DemoMonthReport(
      year: _asInt(map['year'], 'year'),
      month: _asInt(map['month'], 'month'),
      entryCount: _asInt(map['entryCount'], 'entryCount'),
      incomeCount: _asInt(map['incomeCount'], 'incomeCount'),
      expenseCount: _asInt(map['expenseCount'], 'expenseCount'),
      incomeTargetMinor: _asInt(map['incomeTargetMinor'], 'incomeTargetMinor'),
      expenseTargetMinor: _asInt(
        map['expenseTargetMinor'],
        'expenseTargetMinor',
      ),
      incomeTotalMinor: _asInt(map['incomeTotalMinor'], 'incomeTotalMinor'),
      expenseTotalMinor: _asInt(map['expenseTotalMinor'], 'expenseTotalMinor'),
    );
  }

  static Map<String, Object?> _asMap(Object? raw, String label) {
    if (raw is! Map) throw FormatException('$label must be a map.');
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static int _asInt(Object? raw, String label) {
    if (raw is! num) throw FormatException('$label must be numeric.');
    return raw.toInt();
  }

  static int? _optionalInt(Object? raw) {
    if (raw == null) return null;
    return _asInt(raw, 'timestamp');
  }

  static bool _asBool(Object? raw, String label) {
    if (raw is! bool) throw FormatException('$label must be boolean.');
    return raw;
  }
}

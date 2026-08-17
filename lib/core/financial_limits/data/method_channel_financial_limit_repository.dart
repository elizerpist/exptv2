import 'package:flutter/services.dart';

import '../domain/financial_limit.dart';
import '../domain/financial_limit_repository.dart';

/// Typed CRUD bridge for future limit editors. It is intentionally never used
/// by the Budget rail/header hot path, which reads only an immutable snapshot.
final class MethodChannelFinancialLimitRepository
    implements FinancialLimitRepository {
  MethodChannelFinancialLimitRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.fluvi/financial_limits';
  final MethodChannel _channel;

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) async {
    final raw = await _channel.invokeMethod<Object?>(
      'getFinancialLimit',
      _key(key),
    );
    return raw == null ? null : _decode(_map(raw));
  }

  @override
  Future<List<FinancialLimit>> list() async {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'listFinancialLimits',
    );
    return List<FinancialLimit>.unmodifiable([
      for (final value in raw ?? const <Object?>[]) _decode(_map(value)),
    ]);
  }

  @override
  Future<FinancialLimit> upsert(
    FinancialLimitKey key,
    int amountScaled100,
  ) async {
    if (amountScaled100 < 0) throw ArgumentError.value(amountScaled100);
    final raw = await _channel.invokeMethod<Object?>('upsertFinancialLimit', {
      ..._key(key),
      'amountScaled100': amountScaled100,
    });
    return _decode(_map(raw));
  }

  @override
  Future<bool> delete(FinancialLimitKey key) async =>
      await _channel.invokeMethod<bool>('deleteFinancialLimit', _key(key)) ??
      false;

  static Map<String, Object?> _key(FinancialLimitKey key) {
    final result = <String, Object?>{'direction': key.direction.name};
    switch (key.target) {
      case FinancialLimitAggregateTarget():
        result['targetKind'] = 'aggregate';
      case FinancialLimitCategoryTarget(:final categoryId):
        result['targetKind'] = 'category';
        result['categoryId'] = categoryId;
    }
    switch (key.period) {
      case FinancialLimitSumPeriod():
        result['periodKind'] = 'sum';
      case FinancialLimitYearPeriod(:final year):
        result['periodKind'] = 'year';
        result['year'] = year;
      case FinancialLimitMonthPeriod(:final year, :final month):
        result['periodKind'] = 'month';
        result['year'] = year;
        result['month'] = month;
    }
    return result;
  }

  static FinancialLimit _decode(Map<Object?, Object?> raw) {
    final direction = FinancialLimitDirection.values.byName(
      _string(raw, 'direction'),
    );
    final target = switch (_string(raw, 'targetKind')) {
      'aggregate' => const FinancialLimitAggregateTarget(),
      'category' => FinancialLimitCategoryTarget(_string(raw, 'categoryId')),
      _ => throw const FormatException('Invalid financial limit target.'),
    };
    final period = switch (_string(raw, 'periodKind')) {
      'sum' => const FinancialLimitSumPeriod(),
      'year' => FinancialLimitYearPeriod(_int(raw, 'year')),
      'month' => FinancialLimitMonthPeriod(
        _int(raw, 'year'),
        _int(raw, 'month'),
      ),
      _ => throw const FormatException('Invalid financial limit period.'),
    };
    return FinancialLimit(
      key: FinancialLimitKey(
        direction: direction,
        target: target,
        period: period,
      ),
      amountScaled100: _int(raw, 'amountScaled100'),
      createdAtUtcMs: _int(raw, 'createdAtUtcMs'),
      updatedAtUtcMs: _int(raw, 'updatedAtUtcMs'),
    );
  }

  static Map<Object?, Object?> _map(Object? raw) {
    if (raw is Map<Object?, Object?>) return raw;
    if (raw is Map) return Map<Object?, Object?>.from(raw);
    throw const FormatException('Invalid financial limit bridge payload.');
  }

  static String _string(Map<Object?, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing financial limit $key.');
  }

  static int _int(Map<Object?, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Missing financial limit $key.');
  }
}

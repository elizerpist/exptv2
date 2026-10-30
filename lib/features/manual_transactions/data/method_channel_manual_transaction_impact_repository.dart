import 'package:flutter/services.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/manual_transaction_impact_repository.dart';

final class MethodChannelManualTransactionImpactRepository
    implements ManualTransactionImpactRepository {
  MethodChannelManualTransactionImpactRepository({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.fluvi/manual_transactions');

  final MethodChannel _channel;

  @override
  Future<ManualTransactionMonthImpact> loadMonthImpact({
    required LedgerDirection direction,
    required String? categoryId,
    required int year,
    required int month,
    String? excludedEntryId,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('getMonthImpact', {
      'direction': direction.name,
      'categoryId': categoryId,
      'year': year,
      'month': month,
      'excludedEntryId': excludedEntryId,
    });
    final map = _map(raw);
    return ManualTransactionMonthImpact(
      categoryActualScaled100: _int(map, 'categoryActualScaled100'),
      categoryLimitScaled100: _optionalInt(map['categoryLimitScaled100']),
      monthIncomeScaled100: _int(map, 'monthIncomeScaled100'),
      monthExpenseScaled100: _int(map, 'monthExpenseScaled100'),
    );
  }

  static Map<Object?, Object?> _map(Object? raw) {
    if (raw is Map<Object?, Object?>) return raw;
    if (raw is Map) return Map<Object?, Object?>.from(raw);
    throw const FormatException('Invalid manual transaction impact payload.');
  }

  static int _int(Map<Object?, Object?> raw, String key) {
    final value = raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('Missing $key in manual transaction impact payload.');
  }

  static int? _optionalInt(Object? value) => switch (value) {
    int value => value,
    num value => value.toInt(),
    _ => null,
  };
}

import 'package:flutter/services.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';

final class MethodChannelManualTransactionRepository
    implements ManualTransactionRepository {
  MethodChannelManualTransactionRepository({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.fluvi/manual_transactions');

  final MethodChannel _channel;

  @override
  Future<List<PartnerDirectoryEntry>> listPartners() async {
    final result = await _channel.invokeMethod<List<Object?>>('listPartners');
    return (result ?? const <Object?>[])
        .map((value) => PartnerDirectoryEntry.fromMap(_map(value)))
        .toList(growable: false);
  }

  @override
  Future<PartnerDirectoryEntry?> getPartnerById(String partnerId) async {
    final result = await _channel.invokeMethod<Object?>('getPartnerById', {
      'partnerId': partnerId,
    });
    return result == null ? null : PartnerDirectoryEntry.fromMap(_map(result));
  }

  @override
  Future<PartnerDirectoryEntry?> resolvePartner(String partnerId) async {
    final result = await _channel.invokeMethod<Object?>('resolvePartner', {
      'partnerId': partnerId,
    });
    return result == null ? null : PartnerDirectoryEntry.fromMap(_map(result));
  }

  @override
  Future<LedgerEntryDetail> getLedgerEntryById(String entryId) async =>
      LedgerEntryDetail.fromMap(
        _map(
          await _channel.invokeMethod<Object?>('getLedgerEntryById', {
            'entryId': entryId,
          }),
        ),
      );

  @override
  Future<LedgerEntryDetail> createManualTransaction({
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required LedgerDirection direction,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async {
    final result = await _channel
        .invokeMethod<Object?>('createManualTransaction', <String, Object?>{
          'partner': partner.toMap(),
          'categorySelection': categorySelection.toMap(),
          'direction': direction.name,
          'amountScaled100': amountScaled100,
          'bookedLocalEpochDay': bookedLocalEpochDay,
          'bookedLocalTimeMinutes': bookedLocalTimeMinutes,
          'occurredAtUtcMs': occurredAtUtcMs,
          'note': note,
        });
    return LedgerEntryDetail.fromMap(_map(result));
  }

  @override
  Future<LedgerEntryDetail> updateTransaction({
    required String entryId,
    required int expectedRevision,
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async {
    final result = await _channel
        .invokeMethod<Object?>('updateTransaction', <String, Object?>{
          'entryId': entryId,
          'expectedRevision': expectedRevision,
          'partner': partner.toMap(),
          'categorySelection': categorySelection.toMap(),
          'amountScaled100': amountScaled100,
          'bookedLocalEpochDay': bookedLocalEpochDay,
          'bookedLocalTimeMinutes': bookedLocalTimeMinutes,
          'occurredAtUtcMs': occurredAtUtcMs,
          'note': note,
        });
    return LedgerEntryDetail.fromMap(_map(result));
  }

  @override
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  }) async => PartnerDirectoryEntry.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updatePartner', <String, Object?>{
        'partnerId': partnerId,
        'displayNameOverride': displayNameOverride,
        'defaultCategoryId': defaultCategoryId,
      }),
    ),
  );

  static Map<Object?, Object?> _map(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    if (value is Map) return Map<Object?, Object?>.from(value);
    throw FormatException('Invalid manual transaction bridge response.');
  }
}

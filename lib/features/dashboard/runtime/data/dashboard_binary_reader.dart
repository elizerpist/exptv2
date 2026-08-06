import 'dart:convert';
import 'dart:typed_data';

import '../../query/data/dashboard_ledger_entry.dart';

/// Bounds-checked reader shared by the dashboard index and committed-page
/// binary envelopes. It never trusts payload-provided allocation sizes.
final class DashboardBinaryReader {
  DashboardBinaryReader(Uint8List bytes)
    : _bytes = bytes,
      _data = ByteData.sublistView(bytes);

  static const int maximumStringBytes = 1 << 20;

  final Uint8List _bytes;
  final ByteData _data;
  int _offset = 0;

  int get remaining => _bytes.lengthInBytes - _offset;

  int readInt32(String label) {
    _requireBytes(4, label);
    final value = _data.getInt32(_offset, Endian.big);
    _offset += 4;
    return value;
  }

  int readInt64(String label) {
    _requireBytes(8, label);
    final value = _data.getInt64(_offset, Endian.big);
    _offset += 8;
    return value;
  }

  bool readBool(String label) {
    _requireBytes(1, label);
    final value = _data.getUint8(_offset);
    _offset += 1;
    if (value > 1) throw FormatException('$label must be boolean.');
    return value == 1;
  }

  String readString(String label) {
    final length = readInt32('$label.length');
    if (length < 0 || length > maximumStringBytes || length > remaining) {
      throw FormatException('$label has an invalid length.');
    }
    final value = utf8.decode(
      Uint8List.sublistView(_bytes, _offset, _offset + length),
      allowMalformed: false,
    );
    _offset += length;
    return value;
  }

  String? readNullableString(String label) {
    final length = readInt32('$label.length');
    if (length == -1) return null;
    if (length < 0 || length > maximumStringBytes || length > remaining) {
      throw FormatException('$label has an invalid length.');
    }
    final value = utf8.decode(
      Uint8List.sublistView(_bytes, _offset, _offset + length),
      allowMalformed: false,
    );
    _offset += length;
    return value;
  }

  int readBoundedCount(String label, {required int maximum}) {
    final value = readInt32(label);
    if (value < 0 || value > maximum) {
      throw FormatException('$label exceeds its bound.');
    }
    return value;
  }

  DashboardLedgerEntry readRow() => DashboardLedgerEntry(
    id: readString('row.id'),
    partnerId: readString('row.partnerId'),
    partnerDisplayName: readString('row.partnerDisplayName'),
    categoryId: readString('row.categoryId'),
    categoryDisplayName: readString('row.categoryDisplayName'),
    categoryColorId: readString('row.categoryColorId'),
    categoryIconId: readString('row.categoryIconId'),
    assignmentMode: readString('row.assignmentMode'),
    originKind: readString('row.originKind'),
    direction: readString('row.direction'),
    amountMinor: readInt64('row.amountMinor'),
    bookedLocalEpochDay: readInt64('row.bookedLocalEpochDay'),
    bookedLocalTimeMinutes: readInt32('row.bookedLocalTimeMinutes'),
    note: readNullableString('row.note'),
    occurredAtUtcMs: readInt64('row.occurredAtUtcMs'),
  );

  Map<String, Object?>? readCursor(String label) => readBool('$label.present')
      ? <String, Object?>{
          'bookedLocalEpochDay': readInt64('$label.bookedLocalEpochDay'),
          'bookedLocalTimeMinutes': readInt32('$label.bookedLocalTimeMinutes'),
          'entryId': readString('$label.entryId'),
        }
      : null;

  void requireFullyConsumed({String envelope = 'Dashboard payload'}) {
    if (remaining != 0) {
      throw FormatException('$envelope has $remaining trailing bytes.');
    }
  }

  void _requireBytes(int count, String label) {
    if (count < 0 || remaining < count) {
      throw FormatException('Dashboard payload ended while reading $label.');
    }
  }
}

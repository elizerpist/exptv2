import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import '../domain/prepared_budget_limit_snapshot.dart';

typedef DashboardPreparedBudgetLimitSnapshotDecodeWorker =
    Future<PreparedBudgetLimitSnapshot> Function(Uint8List bytes);

final class IsolateDashboardPreparedBudgetLimitSnapshotDecodeWorker {
  const IsolateDashboardPreparedBudgetLimitSnapshotDecodeWorker();

  Future<PreparedBudgetLimitSnapshot> decode(Uint8List bytes) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () => DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
        payload.materialize().asUint8List(),
      ),
      debugName: 'fluvi-budget-limit-snapshot-decode',
    );
  }
}

/// Compact versioned transport for query-independent dense Budget values.
abstract final class DashboardPreparedBudgetLimitSnapshotBinaryCodec {
  static const int magic = 0x464c424c;
  static const int version = 1;
  static const int missingLimitSentinel = -1;
  static const int maximumPayloadBytes = 16 * 1024 * 1024;
  static const int maximumCategoryCount = 512;
  static const int maximumDenseCellCount =
      (1 + 32 + 32 * 12) * (maximumCategoryCount + 1) * 2;

  static PreparedBudgetLimitSnapshot decode(Uint8List bytes) {
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw FormatException('Budget limit payload is too large.');
    }
    final reader = _BudgetBinaryReader(bytes);
    if (reader.readInt32() != magic) throw FormatException('Bad Budget magic.');
    if (reader.readInt32() != version) {
      throw FormatException('Unsupported Budget payload version.');
    }
    final revision = reader.readInt64();
    final startYear = reader.readInt32();
    final endYear = reader.readInt32();
    final nativeSqlCallCount = reader.readInt32();
    final nativeSqlDurationNanos = reader.readInt64();
    if (nativeSqlCallCount < 0 || nativeSqlDurationNanos < 0) {
      throw FormatException('Invalid Budget native acquisition metrics.');
    }
    final categoryCount = reader.readInt32();
    if (categoryCount < 0 || categoryCount > maximumCategoryCount) {
      throw FormatException('Invalid Budget category count.');
    }
    final categories = List<String>.generate(
      categoryCount,
      (_) => reader.readUtf8(),
      growable: false,
    );
    final actualCount = reader.readInt32();
    if (actualCount < 0 || actualCount > maximumDenseCellCount) {
      throw FormatException('Invalid Budget dense cell count.');
    }
    final actuals = List<int>.generate(
      actualCount,
      (_) => reader.readInt64(),
      growable: false,
    );
    final limitCount = reader.readInt32();
    if (limitCount != actualCount) {
      throw FormatException('Budget actual/limit dense vector mismatch.');
    }
    final cells = List<PreparedBudgetLimitCell>.generate(limitCount, (index) {
      final value = reader.readInt64();
      if (value < missingLimitSentinel) {
        throw FormatException('Invalid persisted Budget limit sentinel.');
      }
      return PreparedBudgetLimitCell(
        actualScaled100: actuals[index],
        limitScaled100: value == missingLimitSentinel ? null : value,
      );
    }, growable: false);
    reader.requireExhausted();
    return PreparedBudgetLimitSnapshot(
      coreRevision: revision,
      yearWindowStart: startYear,
      yearWindowEndInclusive: endYear,
      orderedCategoryIds: categories,
      cells: cells,
      nativeSqlCallCount: nativeSqlCallCount,
      nativeSqlDurationMicros: nativeSqlDurationNanos ~/ 1000,
    );
  }
}

final class _BudgetBinaryReader {
  _BudgetBinaryReader(Uint8List bytes)
    : _bytes = bytes,
      _data = ByteData.sublistView(bytes);

  final Uint8List _bytes;
  final ByteData _data;
  var _offset = 0;

  int readInt32() {
    _require(4);
    final value = _data.getInt32(_offset, Endian.big);
    _offset += 4;
    return value;
  }

  int readInt64() {
    _require(8);
    final value = _data.getInt64(_offset, Endian.big);
    _offset += 8;
    return value;
  }

  String readUtf8() {
    final length = readInt32();
    if (length < 0 || length > 1024 || _offset + length > _bytes.length) {
      throw FormatException('Invalid Budget UTF-8 length.');
    }
    final value = utf8.decode(
      _bytes.sublist(_offset, _offset + length),
      allowMalformed: false,
    );
    _offset += length;
    return value;
  }

  void requireExhausted() {
    if (_offset != _bytes.length)
      throw FormatException('Trailing Budget bytes.');
  }

  void _require(int length) {
    if (_offset + length > _bytes.length) {
      throw FormatException('Truncated Budget payload.');
    }
  }
}

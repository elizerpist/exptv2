import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import '../domain/prepared_budget_limit_snapshot.dart';
import '../domain/prepared_spending_rhythm_snapshot.dart';

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
  static const int version = 5;
  static const int missingLimitSentinel = -1;
  static const int maximumPayloadBytes = 16 * 1024 * 1024;
  static const int maximumCategoryCount = 512;
  static const int maximumDenseCellCount =
      (1 + 32 + 32 * 12) * (maximumCategoryCount + 1) * 2;
  static const int spendingRhythmPartsPerPoint =
      SpendingRhythmDayPart.bucketCount;
  static const int spendingRhythmBytesPerPoint =
      8 + 8 + spendingRhythmPartsPerPoint * 8;
  static const int maximumSpendingRhythmPointCount =
      maximumPayloadBytes ~/ spendingRhythmBytesPerPoint;

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
    final incomeBank = _readDirectionBank(reader);
    final expenseBank = _readDirectionBank(reader);
    final rhythm = PreparedSpendingRhythmSnapshot(
      coreRevision: revision,
      incomeBank: _readRhythmBank(
        reader,
        expectedTargetCount: incomeBank.targetCount,
      ),
      expenseBank: _readRhythmBank(
        reader,
        expectedTargetCount: expenseBank.targetCount,
      ),
    );
    reader.requireExhausted();
    return PreparedBudgetLimitSnapshot(
      coreRevision: revision,
      yearWindowStart: startYear,
      yearWindowEndInclusive: endYear,
      incomeBank: incomeBank,
      expenseBank: expenseBank,
      spendingRhythmSnapshot: rhythm,
      nativeSqlCallCount: nativeSqlCallCount,
      nativeSqlDurationMicros: nativeSqlDurationNanos ~/ 1000,
    );
  }

  static PreparedSpendingRhythmDirectionBank _readRhythmBank(
    _BudgetBinaryReader reader, {
    required int expectedTargetCount,
  }) {
    final targetCount = reader.readInt32();
    if (targetCount != expectedTargetCount) {
      throw FormatException('Spending Rhythm target domain mismatch.');
    }
    final offsetCount = reader.readInt32();
    if (offsetCount != targetCount + 1) {
      throw FormatException('Invalid Spending Rhythm offset count.');
    }
    final offsets = List<int>.generate(
      offsetCount,
      (_) => reader.readInt32(),
      growable: false,
    );
    final pointCount = reader.readInt32();
    if (pointCount < 0 || pointCount > maximumSpendingRhythmPointCount) {
      throw FormatException('Invalid Spending Rhythm point count.');
    }
    final epochDays = List<int>.filled(pointCount, 0, growable: false);
    final actuals = List<int>.filled(pointCount, 0, growable: false);
    final parts = List<int>.filled(
      pointCount * spendingRhythmPartsPerPoint,
      0,
      growable: false,
    );
    for (var point = 0; point < pointCount; point += 1) {
      epochDays[point] = reader.readInt64();
      actuals[point] = reader.readInt64();
      for (var part = 0; part < spendingRhythmPartsPerPoint; part += 1) {
        parts[point * spendingRhythmPartsPerPoint + part] = reader.readInt64();
      }
    }
    return PreparedSpendingRhythmDirectionBank(
      targetCount: targetCount,
      targetOffsets: offsets,
      epochDays: epochDays,
      dailyActualScaled100: actuals,
      dayPartActualScaled100: parts,
    );
  }

  static PreparedBudgetLimitDirectionBank _readDirectionBank(
    _BudgetBinaryReader reader,
  ) {
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
    final limits = List<int>.generate(limitCount, (_) => reader.readInt64());
    final sourceCount = reader.readInt32();
    if (sourceCount != limitCount) {
      throw FormatException('Budget limit/source dense vector mismatch.');
    }
    final sources = List<PreparedBudgetLimitSource>.generate(sourceCount, (_) {
      return switch (reader.readUint8()) {
        0 => PreparedBudgetLimitSource.unavailable,
        1 => PreparedBudgetLimitSource.base,
        2 => PreparedBudgetLimitSource.override,
        _ => throw FormatException('Invalid Budget limit provenance.'),
      };
    }, growable: false);
    final cells = List<PreparedBudgetLimitCell>.generate(limitCount, (index) {
      final value = limits[index];
      if (value < missingLimitSentinel) {
        throw FormatException('Invalid persisted Budget limit sentinel.');
      }
      return PreparedBudgetLimitCell(
        actualScaled100: actuals[index],
        limitScaled100: value == missingLimitSentinel ? null : value,
        limitSource: sources[index],
      );
    }, growable: false);
    return PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: categories,
      cells: cells,
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

  int readUint8() {
    _require(1);
    return _data.getUint8(_offset++);
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
    if (_offset != _bytes.length) {
      throw FormatException('Trailing Budget bytes.');
    }
  }

  void _require(int length) {
    if (_offset + length > _bytes.length) {
      throw FormatException('Truncated Budget payload.');
    }
  }
}

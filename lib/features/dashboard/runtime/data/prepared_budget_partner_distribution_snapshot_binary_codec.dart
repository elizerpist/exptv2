import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import '../domain/prepared_budget_partner_distribution_snapshot.dart';

typedef DashboardPreparedBudgetPartnerDistributionSnapshotDecodeWorker =
    Future<PreparedBudgetPartnerDistributionSnapshot> Function(Uint8List bytes);

final class IsolateDashboardPreparedBudgetPartnerDistributionSnapshotDecodeWorker {
  const IsolateDashboardPreparedBudgetPartnerDistributionSnapshotDecodeWorker();

  Future<PreparedBudgetPartnerDistributionSnapshot> decode(Uint8List bytes) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () =>
          DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec.decode(
            payload.materialize().asUint8List(),
          ),
      debugName: 'fluvi-budget-partner-distribution-snapshot-decode',
    );
  }
}

/// Compact versioned transport for exact, query-independent partner amounts.
abstract final class DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec {
  static const int magic = 0x464c4250; // FLBP
  static const int version = 2;
  static const int maximumPayloadBytes = 16 * 1024 * 1024;
  static const int maximumPartnerCount = 2048;
  static const int maximumDenseCellCount =
      (1 + 32 + 32 * 12) * maximumPartnerCount;
  static const int maximumCategoryCount = 512;
  static const int maximumContributionCount = 4 * 1024 * 1024;

  static PreparedBudgetPartnerDistributionSnapshot decode(Uint8List bytes) {
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw FormatException('Budget partner payload is too large.');
    }
    final reader = _BudgetPartnerBinaryReader(bytes);
    if (reader.readInt32() != magic) {
      throw FormatException('Bad Budget partner magic.');
    }
    if (reader.readInt32() != version) {
      throw FormatException('Unsupported Budget partner payload version.');
    }
    final revision = reader.readInt64();
    final startYear = reader.readInt32();
    final endYear = reader.readInt32();
    final sqlCalls = reader.readInt32();
    final sqlNanos = reader.readInt64();
    if (revision <= 0 ||
        startYear <= 0 ||
        endYear < startYear ||
        sqlCalls < 0 ||
        sqlNanos < 0) {
      throw FormatException('Invalid Budget partner snapshot header.');
    }
    final incomeBank = _readDirectionBank(reader);
    final expenseBank = _readDirectionBank(reader);
    reader.requireExhausted();
    return PreparedBudgetPartnerDistributionSnapshot(
      coreRevision: revision,
      yearWindowStart: startYear,
      yearWindowEndInclusive: endYear,
      incomeBank: incomeBank,
      expenseBank: expenseBank,
      nativeSqlCallCount: sqlCalls,
      nativeSqlDurationMicros: sqlNanos ~/ 1000,
    );
  }

  static PreparedBudgetPartnerDistributionDirectionBank _readDirectionBank(
    _BudgetPartnerBinaryReader reader,
  ) {
    final partnerCount = reader.readInt32();
    if (partnerCount < 0 || partnerCount > maximumPartnerCount) {
      throw FormatException('Invalid Budget partner count.');
    }
    final ids = List<String>.generate(
      partnerCount,
      (_) => reader.readUtf8(),
      growable: false,
    );
    final titles = List<String>.generate(
      partnerCount,
      (_) => reader.readUtf8(),
      growable: false,
    );
    final amountCount = reader.readInt32();
    if (amountCount < 0 || amountCount > maximumDenseCellCount) {
      throw FormatException('Invalid Budget partner dense amount count.');
    }
    final amounts = List<int>.generate(
      amountCount,
      (_) => reader.readInt64(),
      growable: false,
    );
    if (amounts.any((amount) => amount < 0)) {
      throw FormatException('Negative Budget partner amount.');
    }
    final dominantCount = reader.readInt32();
    if (dominantCount != amountCount) {
      throw FormatException('Budget partner amount/category vector mismatch.');
    }
    final cells = List<PreparedBudgetPartnerDistributionCell>.generate(
      amountCount,
      (index) => PreparedBudgetPartnerDistributionCell(
        actualScaled100: amounts[index],
        dominantCategoryId: reader.readUtf8(),
      ),
      growable: false,
    );
    final categoryCount = reader.readInt32();
    if (categoryCount < 0 || categoryCount > maximumCategoryCount) {
      throw FormatException('Invalid Budget partner category count.');
    }
    final categories = List<String>.generate(
      categoryCount,
      (_) => reader.readUtf8(),
      growable: false,
    );
    final offsetCount = reader.readInt32();
    final expectedOffsetCount = (1 + 32 + 32 * 12) * categoryCount + 1;
    if (offsetCount < 1 || offsetCount > expectedOffsetCount) {
      throw FormatException('Invalid Budget partner contribution offsets.');
    }
    final offsets = List<int>.generate(
      offsetCount,
      (_) => reader.readInt32(),
      growable: false,
    );
    final contributionCount = reader.readInt32();
    if (contributionCount < 0 || contributionCount > maximumContributionCount) {
      throw FormatException('Invalid Budget partner contribution count.');
    }
    final contributions =
        List<PreparedBudgetPartnerCategoryContribution>.generate(
          contributionCount,
          (_) => PreparedBudgetPartnerCategoryContribution(
            partnerHandle: reader.readInt32(),
            actualScaled100: reader.readInt64(),
          ),
          growable: false,
        );
    return PreparedBudgetPartnerDistributionDirectionBank(
      orderedPartnerIds: ids,
      orderedPartnerTitles: titles,
      cells: cells,
      orderedCategoryIds: categories,
      categoryContributionOffsets: offsets,
      categoryContributions: contributions,
    );
  }
}

final class _BudgetPartnerBinaryReader {
  _BudgetPartnerBinaryReader(Uint8List bytes)
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
    if (length < 0 || length > 4096 || _offset + length > _bytes.length) {
      throw FormatException('Invalid Budget partner UTF-8 length.');
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
      throw FormatException('Trailing Budget partner bytes.');
    }
  }

  void _require(int length) {
    if (_offset + length > _bytes.length) {
      throw FormatException('Truncated Budget partner payload.');
    }
  }
}

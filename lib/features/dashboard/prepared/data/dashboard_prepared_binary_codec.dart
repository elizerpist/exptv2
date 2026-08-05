import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import '../../logbox/application/dashboard_log_view_models.dart';
import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/presentation/summary_metrics_presentation.dart';
import '../domain/dashboard_prepared_deck.dart';
import 'dashboard_prepared_deck_repository.dart';

abstract interface class DashboardPreparedDeckDecodeWorker {
  Future<DashboardPreparedDeck> decode(
    Uint8List bytes, {
    required DashboardPreparedDeckRequest request,
    required int expectedGeneration,
  });
}

final class IsolateDashboardPreparedDeckDecodeWorker
    implements DashboardPreparedDeckDecodeWorker {
  const IsolateDashboardPreparedDeckDecodeWorker();

  @override
  Future<DashboardPreparedDeck> decode(
    Uint8List bytes, {
    required DashboardPreparedDeckRequest request,
    required int expectedGeneration,
  }) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () => DashboardPreparedBinaryCodec.decode(
        payload.materialize().asUint8List(),
        request: request,
        expectedGeneration: expectedGeneration,
      ),
      debugName: 'fluvi-dashboard-prepared-decode',
    );
  }
}

abstract final class DashboardPreparedBinaryCodec {
  static const int magic = 0x464c444b;
  static const int version = 1;
  static const int maximumPayloadBytes = 32 * 1024 * 1024;

  static DashboardPreparedDeck decode(
    Uint8List bytes, {
    required DashboardPreparedDeckRequest request,
    required int expectedGeneration,
  }) {
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw const FormatException('Prepared deck payload is too large.');
    }
    final reader = _BinaryReader(bytes);
    if (reader.readInt32('magic') != magic) {
      throw const FormatException('Invalid prepared deck magic.');
    }
    if (reader.readInt32('version') != version) {
      throw const FormatException('Unsupported prepared deck version.');
    }
    final generation = reader.readInt64('generation');
    final revision = reader.readInt64('revision');
    final parentKey = LedgerQueryKey(reader.readString('parentQueryKey'));
    final direction = _direction(reader.readString('direction'));
    final childKind = reader.readString('childKind');
    final pageSize = reader.readInt32('pageSize');
    final sqlCallCount = reader.readInt32('sqlCallCount');
    final aggregateBucketCount = reader.readInt32('aggregateBucketCount');
    final scannedRowCount = reader.readInt32('scannedRowCount');
    final materializedRowCount = reader.readInt32('materializedRowCount');
    final queryDurationNanos = reader.readInt64('queryDurationNanos');
    final mappingDurationNanos = reader.readInt64('mappingDurationNanos');

    if (generation != expectedGeneration ||
        revision <= 0 ||
        revision != request.key.coreRevision ||
        parentKey != request.key.parentQueryKey ||
        parentKey != request.parentScope.key ||
        direction != request.key.direction ||
        direction != request.parentScope.direction ||
        childKind != request.key.childKind.name ||
        pageSize != request.key.pageSize ||
        sqlCallCount <= 0 ||
        aggregateBucketCount < 0 ||
        scannedRowCount < 0 ||
        materializedRowCount < 0 ||
        queryDurationNanos < 0 ||
        mappingDurationNanos < 0) {
      throw const FormatException('Prepared deck header identity mismatch.');
    }

    final parentSlice = reader.readSlice(pageSize: pageSize);
    final parentFrame = _projectFrame(
      parentSlice,
      scope: request.parentScope,
      parentQueryKey: parentKey,
      revision: revision,
    );
    final childCount = reader.readBoundedCount(
      'childCount',
      maximum: _BinaryReader.maximumChildCount,
    );
    if (childCount != request.semanticCatalog.length) {
      throw const FormatException('Prepared deck child count mismatch.');
    }

    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    final seenValues = <String>{};
    for (var index = 0; index < childCount; index += 1) {
      final childValue = reader.readString('childPeriodValue');
      if (!seenValues.add(childValue)) {
        throw const FormatException('Duplicate prepared child value.');
      }
      final slice = reader.readSlice(pageSize: pageSize);
      final queryKey = LedgerQueryKey(slice.queryKey);
      final semantic = request.semanticCatalog.entryForQueryKey(queryKey);
      if (semantic == null ||
          semantic.logicalIndex != index ||
          !_scopeValueMatches(semantic.scope, childValue)) {
        throw const FormatException(
          'Prepared child semantic identity mismatch.',
        );
      }
      frames[queryKey] = _projectFrame(
        slice,
        scope: semantic.scope,
        parentQueryKey: parentKey,
        revision: revision,
      );
    }
    reader.requireFullyConsumed();

    final maximumRows = (childCount + 1) * pageSize;
    if (materializedRowCount > (childCount + 1) * (pageSize + 1) ||
        parentSlice.entries.length +
                frames.values.fold<int>(
                  0,
                  (sum, frame) =>
                      sum +
                      frame.logBox.groups.fold<int>(
                        0,
                        (rows, group) => rows + group.rows.length,
                      ),
                ) >
            maximumRows) {
      throw const FormatException('Prepared deck row bound exceeded.');
    }

    return DashboardPreparedDeck.complete(
      key: request.key,
      parentScope: request.parentScope,
      parentFrame: parentFrame,
      semanticCatalog: request.semanticCatalog,
      frames: frames,
      contentDigest: Object.hash(
        parentFrame.presentationDigest,
        Object.hashAll(frames.values.map((frame) => frame.presentationDigest)),
        revision,
      ),
      generation: generation,
      preparedAt: DateTime.now().toUtc(),
    );
  }

  static DashboardPreparedFrame _projectFrame(
    _DecodedSlice slice, {
    required CurrentLedgerQueryScope scope,
    required LedgerQueryKey parentQueryKey,
    required int revision,
  }) {
    if (slice.queryKey != scope.key.value ||
        slice.timeScopeKey != scope.timeScope.canonicalKey ||
        slice.direction != scope.direction ||
        slice.entries.any((entry) => entry.direction != scope.direction.name)) {
      throw const FormatException('Prepared slice scope mismatch.');
    }
    final logBox = DashboardLogViewModelProjector.presentPreparedOrdered(
      scope: scope,
      revision: revision,
      entries: slice.entries,
      entryCount: slice.entryCount,
      nextCursor: slice.nextCursor,
      isPreview: true,
    );
    final digest = Object.hash(
      scope.key,
      revision,
      slice.totalMinor,
      slice.entryCount,
      Object.hashAll(
        slice.entries.map(
          (entry) => Object.hash(
            entry.id,
            entry.amountMinor,
            entry.bookedLocalEpochDay,
            entry.bookedLocalTimeMinutes,
            entry.partnerDisplayName,
            entry.categoryDisplayName,
            entry.categoryColorId,
            entry.categoryIconId,
          ),
        ),
      ),
      slice.nextCursor,
    );
    return DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: parentQueryKey,
      coreRevision: revision,
      totalMinor: slice.totalMinor,
      formattedAmount: SummaryMetricsPresentation.formatTotalMinor(
        slice.totalMinor,
      ),
      entryCount: slice.entryCount,
      formattedEntryCount: slice.entryCount.toString(),
      logBox: logBox,
      presentationDigest: digest,
    );
  }

  static LedgerDirection _direction(String value) {
    try {
      return LedgerDirection.values.byName(value);
    } on ArgumentError {
      throw FormatException('Invalid ledger direction: $value');
    }
  }

  static bool _scopeValueMatches(CurrentLedgerQueryScope scope, String value) =>
      scope.timeScope.canonicalKey.endsWith(':$value');
}

final class _DecodedSlice {
  const _DecodedSlice({
    required this.queryKey,
    required this.timeScopeKey,
    required this.direction,
    required this.totalMinor,
    required this.entryCount,
    required this.entries,
    required this.nextCursor,
  });

  final String queryKey;
  final String timeScopeKey;
  final LedgerDirection direction;
  final int totalMinor;
  final int entryCount;
  final List<DashboardLedgerEntry> entries;
  final Map<String, Object?>? nextCursor;
}

final class _BinaryReader {
  _BinaryReader(Uint8List bytes)
    : _bytes = bytes,
      _data = ByteData.sublistView(bytes);

  static const int maximumStringBytes = 1 << 20;
  static const int maximumChildCount = 101;

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

  _DecodedSlice readSlice({required int pageSize}) {
    final queryKey = readString('slice.queryKey');
    final timeScopeKey = readString('slice.timeScopeKey');
    final direction = DashboardPreparedBinaryCodec._direction(
      readString('slice.direction'),
    );
    final totalMinor = readInt64('slice.totalMinor');
    final entryCount = readInt64('slice.entryCount');
    if (entryCount < 0) {
      throw const FormatException('Slice entry count cannot be negative.');
    }
    final rowCount = readBoundedCount('slice.rowCount', maximum: pageSize);
    final entries = List<DashboardLedgerEntry>.generate(
      rowCount,
      (_) => readRow(),
      growable: false,
    );
    _requireStableOrder(entries);
    final nextCursor = readBool('slice.hasCursor')
        ? <String, Object?>{
            'bookedLocalEpochDay': readInt64('cursor.bookedLocalEpochDay'),
            'bookedLocalTimeMinutes': readInt32(
              'cursor.bookedLocalTimeMinutes',
            ),
            'entryId': readString('cursor.entryId'),
          }
        : null;
    return _DecodedSlice(
      queryKey: queryKey,
      timeScopeKey: timeScopeKey,
      direction: direction,
      totalMinor: totalMinor,
      entryCount: entryCount,
      entries: entries,
      nextCursor: nextCursor,
    );
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

  void requireFullyConsumed() {
    if (remaining != 0) {
      throw FormatException('Prepared deck has $remaining trailing bytes.');
    }
  }

  void _requireBytes(int count, String label) {
    if (count < 0 || remaining < count) {
      throw FormatException('Prepared deck ended while reading $label.');
    }
  }

  static void _requireStableOrder(List<DashboardLedgerEntry> entries) {
    final ids = <String>{};
    for (var index = 0; index < entries.length; index += 1) {
      final current = entries[index];
      if (!ids.add(current.id)) {
        throw const FormatException('Prepared slice has duplicate row IDs.');
      }
      if (index == 0) continue;
      final previous = entries[index - 1];
      final ordered =
          previous.bookedLocalEpochDay > current.bookedLocalEpochDay ||
          (previous.bookedLocalEpochDay == current.bookedLocalEpochDay &&
              (previous.bookedLocalTimeMinutes >
                      current.bookedLocalTimeMinutes ||
                  (previous.bookedLocalTimeMinutes ==
                          current.bookedLocalTimeMinutes &&
                      previous.id.compareTo(current.id) > 0)));
      if (!ordered) {
        throw const FormatException('Prepared rows are not in stable order.');
      }
    }
  }
}

import 'dart:isolate';
import 'dart:typed_data';

import '../../logbox/application/dashboard_log_view_models.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../domain/prepared_presentation_frame.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/prepared_dashboard_index.dart';
import 'dashboard_binary_reader.dart';
import 'dashboard_data_runtime_repository.dart';

abstract interface class DashboardPreparedIndexDecodeWorker {
  Future<PreparedDashboardIndex> decode(
    Uint8List bytes, {
    required PreparedDashboardIndexRequest request,
    required int expectedGeneration,
    LedgerDirection? expectedPartitionDirection,
  });
}

final class IsolateDashboardPreparedIndexDecodeWorker
    implements DashboardPreparedIndexDecodeWorker {
  const IsolateDashboardPreparedIndexDecodeWorker();

  @override
  Future<PreparedDashboardIndex> decode(
    Uint8List bytes, {
    required PreparedDashboardIndexRequest request,
    required int expectedGeneration,
    LedgerDirection? expectedPartitionDirection,
  }) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () => DashboardPreparedIndexBinaryCodec.decode(
        payload.materialize().asUint8List(),
        request: request,
        expectedGeneration: expectedGeneration,
        expectedPartitionDirection: expectedPartitionDirection,
      ),
      debugName: 'fluvi-dashboard-index-decode',
    );
  }
}

/// Decoder for the sole session-wide dashboard interaction index.
///
/// The native payload is sparse (only non-empty scopes) and contains one
/// deduplicated row table. This worker materializes deterministic zero scopes,
/// semantic catalogs and immutable presentation frames off the UI isolate.
abstract final class DashboardPreparedIndexBinaryCodec {
  static const int magic = 0x464c4449;
  static const int version = 3;
  static const int expectedSqlCallCount = 5;
  static const int maximumPayloadBytes = 128 * 1024 * 1024;
  static const int maximumRowCount = 200000;
  static const int maximumSparseFrameCount = 25000;

  static PreparedDashboardIndex decode(
    Uint8List bytes, {
    required PreparedDashboardIndexRequest request,
    required int expectedGeneration,
    LedgerDirection? expectedPartitionDirection,
  }) {
    final decodeTimer = Stopwatch()..start();
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw const FormatException('Prepared index payload is too large.');
    }
    final reader = DashboardBinaryReader(bytes);
    if (reader.readInt32('magic') != magic) {
      throw const FormatException('Invalid prepared index magic.');
    }
    if (reader.readInt32('version') != version) {
      throw const FormatException('Unsupported prepared index version.');
    }
    final generation = reader.readInt64('generation');
    final revision = reader.readInt64('revision');
    final pageSize = reader.readInt32('pageSize');
    final firstYear = reader.readInt32('firstYear');
    final lastYear = reader.readInt32('lastYear');
    final sqlCallCount = reader.readInt32('sqlCallCount');
    final aggregateBucketCount = reader.readInt32('aggregateBucketCount');
    final scannedRowCount = reader.readInt32('scannedRowCount');
    final uniquePreviewRowCount = reader.readInt32('uniquePreviewRowCount');
    final nativeFrameCount = reader.readInt32('frameCount');
    final sqlNanos = reader.readInt64('sqlDurationNanos');
    final queryNanos = reader.readInt64('queryDurationNanos');
    final aggregationNanos = reader.readInt64('aggregationDurationNanos');
    final mappingNanos = reader.readInt64('mappingDurationNanos');
    final serializationNanos = reader.readInt64('serializationDurationNanos');
    final key = request.key;
    if (generation != expectedGeneration ||
        revision <= 0 ||
        revision != key.coreRevision ||
        pageSize != key.pageSize ||
        firstYear != key.yearWindowStart ||
        lastYear != key.yearWindowEndInclusive ||
        firstYear > request.initialYear ||
        lastYear < request.initialYear ||
        request.initialYear - firstYear != lastYear - request.initialYear ||
        sqlCallCount != expectedSqlCallCount ||
        aggregateBucketCount < 0 ||
        scannedRowCount < 0 ||
        uniquePreviewRowCount < 0 ||
        nativeFrameCount < 0 ||
        sqlNanos < 0 ||
        queryNanos < 0 ||
        aggregationNanos < 0 ||
        mappingNanos < 0 ||
        serializationNanos < 0) {
      throw const FormatException('Prepared index header identity mismatch.');
    }

    final rowCount = reader.readBoundedCount(
      'rowCount',
      maximum: maximumRowCount,
    );
    if (rowCount != uniquePreviewRowCount) {
      throw const FormatException('Prepared index row count mismatch.');
    }
    final rowTable = List<DashboardLedgerEntry>.generate(
      rowCount,
      (_) => reader.readRow(),
      growable: false,
    );
    if (rowTable.map((row) => row.id).toSet().length != rowTable.length) {
      throw const FormatException('Prepared index row table is not unique.');
    }
    final sparseFrameCount = reader.readBoundedCount(
      'sparseFrameCount',
      maximum: maximumSparseFrameCount,
    );
    if (sparseFrameCount != nativeFrameCount) {
      throw const FormatException('Prepared index frame count mismatch.');
    }
    final sparseFrames = List<_RawIndexFrame>.generate(sparseFrameCount, (_) {
      final queryKey = LedgerQueryKey(reader.readString('frame.queryKey'));
      final timeScopeKey = reader.readString('frame.timeScopeKey');
      final direction = _direction(reader.readString('frame.direction'));
      final totalMinor = reader.readInt64('frame.totalMinor');
      final entryCount = reader.readInt64('frame.entryCount');
      if (entryCount <= 0) {
        throw const FormatException('Sparse prepared frame must be non-empty.');
      }
      final rowReferenceCount = reader.readBoundedCount(
        'frame.rowReferenceCount',
        maximum: pageSize,
      );
      if (rowReferenceCount > entryCount) {
        throw const FormatException(
          'Prepared frame row count is inconsistent.',
        );
      }
      final rowIndices = List<int>.generate(
        rowReferenceCount,
        (_) => reader.readInt32('frame.rowIndex'),
        growable: false,
      );
      if (rowIndices.any((index) => index < 0 || index >= rowTable.length)) {
        throw const FormatException(
          'Prepared frame row index is out of range.',
        );
      }
      final cursor = reader.readCursor('frame.cursor');
      return _RawIndexFrame(
        queryKey: queryKey,
        timeScopeKey: timeScopeKey,
        direction: direction,
        totalMinor: totalMinor,
        entryCount: entryCount,
        rowIndices: rowIndices,
        nextCursor: cursor,
      );
    }, growable: false);
    if (sparseFrames.map((frame) => frame.queryKey).toSet().length !=
        sparseFrames.length) {
      throw const FormatException('Prepared index has duplicate frames.');
    }
    reader.requireFullyConsumed(envelope: 'Prepared index');
    decodeTimer.stop();

    final projectionTimer = Stopwatch()..start();
    final projectedRows = List<DashboardLogRowViewModel>.generate(
      rowTable.length,
      (index) => DashboardLogViewModelProjector.presentRow(rowTable[index]),
      growable: false,
    );
    final universe = PreparedDashboardIndexAssembly.zeroUniverse(
      key: request.key,
      directionalQueries: request.directionalQueries,
      initialYear: request.initialYear,
    );
    for (final raw in sparseFrames) {
      final scope = universe.scopes[raw.queryKey];
      if (scope == null ||
          scope.direction != raw.direction ||
          scope.timeScope.canonicalKey != raw.timeScopeKey ||
          raw.rowIndices.any(
            (index) => rowTable[index].direction != raw.direction.name,
          )) {
        throw const FormatException('Prepared frame scope identity mismatch.');
      }
      universe.frames[raw.queryKey] = _projectFrame(
        raw,
        scope: scope,
        revision: revision,
        rowTable: rowTable,
        projectedRows: projectedRows,
      );
      universe.origins[raw.queryKey] = DashboardDataOrigin.preparedIndex;
    }
    // A directional partition payload deliberately omits the unchanged lane.
    // Retain deterministic zero scope metadata only for its exact sparse
    // direction so composition cannot accidentally treat the omitted lane as
    // newly-built data.
    if (expectedPartitionDirection != null &&
        sparseFrames.any(
          (frame) => frame.direction != expectedPartitionDirection,
        )) {
      throw const FormatException(
        'Prepared partition contains another direction.',
      );
    }
    if (expectedPartitionDirection != null) {
      universe.frames.removeWhere(
        (_, frame) => frame.scope.direction != expectedPartitionDirection,
      );
      universe.catalogs.removeWhere(
        (_, catalog) =>
            catalog.parentScope.direction != expectedPartitionDirection,
      );
      universe.origins.removeWhere(
        (queryKey, _) => universe.frames[queryKey] == null,
      );
    }
    projectionTimer.stop();

    final contentDigest = Object.hash(
      key,
      generation,
      Object.hashAll(
        sparseFrames.map(
          (frame) => Object.hash(
            frame.queryKey,
            frame.totalMinor,
            frame.entryCount,
            Object.hashAll(frame.rowIndices),
          ),
        ),
      ),
    );
    return PreparedDashboardIndex.complete(
      key: key,
      frames: universe.frames,
      catalogs: universe.catalogs,
      origins: universe.origins,
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: PreparedDashboardIndexBuildMetrics(
        sqlCallCount: sqlCallCount,
        nativeSqlDurationMicros: sqlNanos ~/ 1000,
        aggregateBucketCount: aggregateBucketCount,
        scannedLedgerRowCount: scannedRowCount,
        uniquePreviewRowCount: uniquePreviewRowCount,
        frameCount: universe.frames.length,
        nativeQueryDurationMicros: queryNanos ~/ 1000,
        nativeAggregationDurationMicros: aggregationNanos ~/ 1000,
        nativeMappingDurationMicros: mappingNanos ~/ 1000,
        serializationDurationMicros: serializationNanos ~/ 1000,
        bridgeTransferDurationMicros: 0,
        dartDecodeDurationMicros: decodeTimer.elapsedMicroseconds,
        dartProjectionDurationMicros: projectionTimer.elapsedMicroseconds,
        payloadBytes: bytes.lengthInBytes,
        estimatedIndexBytes: bytes.lengthInBytes + universe.frames.length * 256,
      ),
    );
  }

  static DashboardPreparedFrame _projectFrame(
    _RawIndexFrame raw, {
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> rowTable,
    required List<DashboardLogRowViewModel> projectedRows,
  }) {
    final logBox = DashboardLogViewModelProjector.presentPreparedReferences(
      scope: scope,
      revision: revision,
      rowTable: rowTable,
      projectedRowTable: projectedRows,
      rowIndices: raw.rowIndices,
      entryCount: raw.entryCount,
      nextCursor: raw.nextCursor,
    );
    return DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: dashboardPreparedParentQueryKey(scope),
      coreRevision: revision,
      totalMinor: raw.totalMinor,
      formattedAmount: DashboardPreparedFormatter.amountMinor(raw.totalMinor),
      entryCount: raw.entryCount,
      formattedEntryCount: raw.entryCount.toString(),
      logBox: logBox,
      presentationDigest: Object.hash(
        scope.key,
        revision,
        raw.totalMinor,
        raw.entryCount,
        Object.hashAll(raw.rowIndices),
        raw.nextCursor?['entryId'],
      ),
    );
  }

  static LedgerDirection _direction(String value) {
    try {
      return LedgerDirection.values.byName(value);
    } on ArgumentError {
      throw FormatException('Invalid ledger direction: $value');
    }
  }
}

final class _RawIndexFrame {
  const _RawIndexFrame({
    required this.queryKey,
    required this.timeScopeKey,
    required this.direction,
    required this.totalMinor,
    required this.entryCount,
    required this.rowIndices,
    required this.nextCursor,
  });

  final LedgerQueryKey queryKey;
  final String timeScopeKey;
  final LedgerDirection direction;
  final int totalMinor;
  final int entryCount;
  final List<int> rowIndices;
  final Map<String, Object?>? nextCursor;
}

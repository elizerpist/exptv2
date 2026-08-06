import 'dart:isolate';
import 'dart:typed_data';

import '../../logbox/application/dashboard_log_view_models.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../domain/prepared_presentation_frame.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/prepared_dashboard_index.dart';
import 'dashboard_binary_reader.dart';
import 'dashboard_data_runtime_repository.dart';

abstract interface class DashboardCommittedPageDecodeWorker {
  Future<DashboardPreparedFrame> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
    required DashboardPreparedFrame currentFrame,
  });
}

final class IsolateDashboardCommittedPageDecodeWorker
    implements DashboardCommittedPageDecodeWorker {
  const IsolateDashboardCommittedPageDecodeWorker();

  @override
  Future<DashboardPreparedFrame> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
    required DashboardPreparedFrame currentFrame,
  }) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () => DashboardCommittedPageBinaryCodec.decodePage(
        payload.materialize().asUint8List(),
        request: request,
        currentFrame: currentFrame,
      ),
      debugName: 'fluvi-dashboard-page-decode',
    );
  }
}

/// Binary decoder used only after an explicit committed vertical near-end
/// signal. Horizontal/rail navigation has no reference to this API.
abstract final class DashboardCommittedPageBinaryCodec {
  static const int magic = 0x464c534c;
  static const int version = 1;
  static const int maximumPayloadBytes = 16 * 1024 * 1024;

  static DashboardPreparedFrame decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
    required DashboardPreparedFrame currentFrame,
  }) {
    request.reason.requirePageRead();
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw const FormatException('Committed page payload is too large.');
    }
    if (currentFrame.queryKey != request.scope.key ||
        currentFrame.parentQueryKey != request.parentQueryKey ||
        currentFrame.coreRevision != request.coreRevision) {
      throw const FormatException('Committed page base identity mismatch.');
    }
    final reader = DashboardBinaryReader(bytes);
    if (reader.readInt32('magic') != magic ||
        reader.readInt32('version') != version) {
      throw const FormatException('Invalid committed page envelope.');
    }
    final commitGeneration = reader.readInt64('commitGeneration');
    final presentationEpoch = reader.readInt64('presentationEpoch');
    final revision = reader.readInt64('revision');
    final parentQueryKey = reader.readString('parentQueryKey');
    if (commitGeneration != request.commitGeneration ||
        presentationEpoch != request.presentationEpoch ||
        revision != request.coreRevision ||
        parentQueryKey != request.parentQueryKey.value) {
      throw const FormatException('Committed page header identity mismatch.');
    }
    final queryKey = reader.readString('slice.queryKey');
    final timeScopeKey = reader.readString('slice.timeScopeKey');
    final direction = _direction(reader.readString('slice.direction'));
    final totalMinor = reader.readInt64('slice.totalMinor');
    final entryCount = reader.readInt64('slice.entryCount');
    if (queryKey != request.scope.key.value ||
        timeScopeKey != request.scope.timeScope.canonicalKey ||
        direction != request.scope.direction ||
        entryCount < 0) {
      throw const FormatException('Committed page scope identity mismatch.');
    }
    final rowCount = reader.readBoundedCount(
      'slice.rowCount',
      maximum: request.pageSize,
    );
    final entries = List<DashboardLedgerEntry>.generate(
      rowCount,
      (_) => reader.readRow(),
      growable: false,
    );
    if (entries.any((entry) => entry.direction != direction.name)) {
      throw const FormatException('Committed page row direction mismatch.');
    }
    final nextCursor = reader.readCursor('slice.cursor');
    reader.requireFullyConsumed(envelope: 'Committed page');
    final page = DashboardLogViewModelProjector.presentPreparedOrdered(
      scope: request.scope,
      revision: revision,
      entries: entries,
      entryCount: entryCount,
      nextCursor: nextCursor,
    );
    final groups = <DashboardDayLogGroupViewModel>[
      ...currentFrame.logBox.groups,
    ];
    for (final incoming in page.groups) {
      if (groups.isNotEmpty && groups.last.dateKey == incoming.dateKey) {
        groups[groups.length - 1] = DashboardDayLogGroupViewModel(
          dateKey: groups.last.dateKey,
          dayLabel: groups.last.dayLabel,
          rows: <DashboardLogRowViewModel>[
            ...groups.last.rows,
            ...incoming.rows,
          ],
        );
      } else {
        groups.add(incoming);
      }
    }
    final rowIds = <String>{};
    for (final group in groups) {
      for (final row in group.rows) {
        if (!rowIds.add(row.entryId)) {
          throw const FormatException('Committed page repeats a row.');
        }
      }
    }
    final logBox = DashboardLogViewportState(
      queryKey: request.scope.key,
      revision: revision,
      groups: groups,
      entryCount: entryCount,
      nextCursor: nextCursor,
      direction: direction,
    );
    return DashboardPreparedFrame.complete(
      scope: request.scope,
      parentQueryKey: request.parentQueryKey,
      coreRevision: revision,
      totalMinor: totalMinor,
      formattedAmount: DashboardPreparedFormatter.amountMinor(totalMinor),
      entryCount: entryCount,
      formattedEntryCount: entryCount.toString(),
      logBox: logBox,
      presentationDigest: Object.hash(
        currentFrame.presentationDigest,
        Object.hashAll(rowIds),
        nextCursor?['entryId'],
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

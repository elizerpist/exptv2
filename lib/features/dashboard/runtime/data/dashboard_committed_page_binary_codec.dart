import 'dart:isolate';
import 'dart:typed_data';

import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/dashboard_log_view_models.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/prepared_dashboard_index.dart';
import 'dashboard_binary_reader.dart';
import 'dashboard_data_runtime_repository.dart';

abstract interface class DashboardCommittedPageDecodeWorker {
  Future<CommittedLogPage> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
  });
}

final class IsolateDashboardCommittedPageDecodeWorker
    implements DashboardCommittedPageDecodeWorker {
  const IsolateDashboardCommittedPageDecodeWorker();

  @override
  Future<CommittedLogPage> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
  }) {
    final payload = TransferableTypedData.fromList(<TypedData>[bytes]);
    return Isolate.run(
      () => DashboardCommittedPageBinaryCodec.decodePage(
        payload.materialize().asUint8List(),
        request: request,
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

  static CommittedLogPage decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
  }) {
    request.reason.requirePageRead();
    if (bytes.lengthInBytes > maximumPayloadBytes) {
      throw const FormatException('Committed page payload is too large.');
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
        entryCount < 0 ||
        totalMinor != request.authoritativeTotalMinor ||
        entryCount != request.authoritativeEntryCount) {
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
    final entryIds = <String>{};
    if (entries.any((entry) => !entryIds.add(entry.id))) {
      throw const FormatException('Committed page repeats a row identity.');
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
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: revision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: page,
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_committed_page_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('accepts ordinal one when the native scope identity is canonical', () {
    final request = _request();

    final page = DashboardCommittedPageBinaryCodec.decodePage(
      _payload(request),
      request: request,
    );

    expect(page.ordinal, 1);
    expect(page.queryKey, request.scope.key);
    expect(page.payload.entryCount, 156);
    expect(page.payload.nextCursor, isNotNull);
  });

  test('rejects a navigation transport key as a structural time identity', () {
    final request = _request();

    expect(
      () => DashboardCommittedPageBinaryCodec.decodePage(
        _payload(request, timeScopeKey: 'navigation=month:2025-04'),
        request: request,
      ),
      throwsFormatException,
    );
  });
}

DashboardCommittedPageRequest _request() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2025, month: 4)),
  );
  return DashboardCommittedPageRequest(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 9,
    presentationEpoch: 17,
    commitGeneration: 3,
    pageSize: 24,
    pageOrdinal: 1,
    startCursor: const <String, Object?>{
      'bookedLocalEpochDay': 20_000,
      'bookedLocalTimeMinutes': 600,
      'entryId': 'root-cursor',
    },
    previousStartCursor: null,
    reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
  );
}

Uint8List _payload(
  DashboardCommittedPageRequest request, {
  String? timeScopeKey,
}) {
  final writer = _Writer()
    ..int32(DashboardCommittedPageBinaryCodec.magic)
    ..int32(DashboardCommittedPageBinaryCodec.version)
    ..int64(request.commitGeneration)
    ..int64(request.presentationEpoch)
    ..int64(request.coreRevision)
    ..string(request.parentQueryKey.value)
    ..string(request.scope.key.value)
    ..string(timeScopeKey ?? request.scope.timeScope.canonicalKey)
    ..string(request.scope.direction.name)
    ..int64(1_560_000)
    ..int64(156)
    ..int32(1)
    ..row()
    ..boolean(true)
    ..int64(19_999)
    ..int32(600)
    ..string('ordinal-one-cursor');
  return writer.takeBytes();
}

final class _Writer {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  void int32(int value) {
    final data = ByteData(4)..setInt32(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void int64(int value) {
    final data = ByteData(8)..setInt64(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void boolean(bool value) => _bytes.addByte(value ? 1 : 0);

  void string(String value) {
    final encoded = utf8.encode(value);
    int32(encoded.length);
    _bytes.add(encoded);
  }

  void nullableString(String? value) {
    if (value == null) {
      int32(-1);
    } else {
      string(value);
    }
  }

  void row() {
    string('entry-1');
    string('partner-1');
    string('Tesco');
    string('category-1');
    string('Étel');
    string('color_02');
    string('icon_02');
    string('partnerDefault');
    string('manual');
    string('expense');
    int64(12_560);
    int64(20_000);
    int32(600);
    nullableString(null);
    int64(1_700_000_000_000);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

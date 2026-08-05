import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_binary_codec.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('decodes and fully projects one exact immutable prepared deck', () {
    final request = _request();
    final deck = DashboardPreparedBinaryCodec.decode(
      _payload(request),
      request: request,
      expectedGeneration: 7,
    );

    expect(deck.coreRevision, 3);
    expect(deck.generation, 7);
    expect(deck.buildMetrics.sqlCallCount, 6);
    expect(deck.buildMetrics.nativeQueryDurationMicros, 1);
    expect(deck.buildMetrics.nativeMappingDurationMicros, 2);
    expect(deck.buildMetrics.payloadBytes, greaterThan(0));
    expect(deck.frames.length, 30);
    expect(deck.parentFrame.amount.formattedAmount, '123,45 Ft');
    final day15 = deck.frameFor(request.semanticCatalog[14].queryKey);
    expect(day15.amount.formattedAmount, '123,45 Ft');
    expect(day15.count.formattedEntryCount, '1');
    expect(day15.logBox.groups, hasLength(1));
    expect(day15.logBox.groups.single.dayLabel, '2026. június 15.');
    expect(day15.logBox.groups.single.rows.single.entryId, 'entry-1');
    expect(day15.logBox.groups.single.rows.single.formattedAmount, '123,45 Ft');
    expect(
      day15.logBox.groups.single.rows.single.semanticLabel,
      contains('Árvíztűrő Partner'),
    );
    expect(day15.stableRowIdentities, ['entry-1']);
    expect(day15.stableAssetIdentities, ['color_02|icon_02']);
    expect(day15.nextCursor?['entryId'], 'entry-1');
  });

  test(
    'rejects wrong magic version generation revision and trailing bytes',
    () {
      final request = _request();
      final valid = _payload(request);

      expect(
        () => DashboardPreparedBinaryCodec.decode(
          _changedInt32(valid, 0, 0),
          request: request,
          expectedGeneration: 7,
        ),
        throwsFormatException,
      );
      expect(
        () => DashboardPreparedBinaryCodec.decode(
          _payload(request, sqlCallCount: 5),
          request: request,
          expectedGeneration: 7,
        ),
        throwsFormatException,
      );
      expect(
        () => DashboardPreparedBinaryCodec.decode(
          _changedInt32(valid, 4, 99),
          request: request,
          expectedGeneration: 7,
        ),
        throwsFormatException,
      );
      expect(
        () => DashboardPreparedBinaryCodec.decode(
          valid,
          request: request,
          expectedGeneration: 8,
        ),
        throwsFormatException,
      );
      expect(
        () => DashboardPreparedBinaryCodec.decode(
          _changedInt64(valid, 16, 4),
          request: request,
          expectedGeneration: 7,
        ),
        throwsFormatException,
      );
      expect(
        () => DashboardPreparedBinaryCodec.decode(
          Uint8List.fromList(<int>[...valid, 0]),
          request: request,
          expectedGeneration: 7,
        ),
        throwsFormatException,
      );
    },
  );

  test('rejects oversized string lengths before allocating', () {
    final request = _request();
    final payload = _changedInt32(_payload(request), 24, 0x7fffffff);

    expect(
      () => DashboardPreparedBinaryCodec.decode(
        payload,
        request: request,
        expectedGeneration: 7,
      ),
      throwsFormatException,
    );
  });

  test('decodes one exact committed frame envelope', () {
    final parent = _request().parentScope;
    final scope = parent.copyWith(
      timeScope: DayScope(const YearMonth(year: 2026, month: 6).clampDay(15)),
    );
    final request = DashboardCommittedFrameRequest(
      scope: scope,
      parentQueryKey: parent.key,
      coreRevision: 3,
      presentationEpoch: 9,
      leaseGeneration: 4,
      pageSize: 24,
    );
    final payload = _Writer()
      ..int32(DashboardPreparedBinaryCodec.frameMagic)
      ..int32(DashboardPreparedBinaryCodec.version)
      ..int64(4)
      ..int64(9)
      ..int64(3)
      ..string(parent.key.value)
      ..slice(
        queryKey: scope.key.value,
        timeScopeKey: scope.timeScope.canonicalKey,
        totalMinor: 12345,
        entryCount: 1,
        withRow: true,
      );

    final frame = DashboardPreparedBinaryCodec.decodeFrame(
      payload.takeBytes(),
      request: request,
    );

    expect(frame.queryKey, scope.key);
    expect(frame.parentQueryKey, parent.key);
    expect(frame.coreRevision, 3);
    expect(frame.amount.formattedAmount, '123,45 Ft');
    expect(frame.logBox.queryKey, scope.key);
  });

  test('committed page merge runs as one prepared immutable projection', () {
    final parent = _request().parentScope;
    final scope = parent.copyWith(
      timeScope: DayScope(const YearMonth(year: 2026, month: 6).clampDay(15)),
    );
    final request = DashboardCommittedFrameRequest(
      scope: scope,
      parentQueryKey: parent.key,
      coreRevision: 3,
      presentationEpoch: 9,
      leaseGeneration: 4,
      pageSize: 24,
    );
    Uint8List payload(String rowId, int epochDay) {
      final writer = _Writer()
        ..int32(DashboardPreparedBinaryCodec.frameMagic)
        ..int32(DashboardPreparedBinaryCodec.version)
        ..int64(4)
        ..int64(9)
        ..int64(3)
        ..string(parent.key.value)
        ..slice(
          queryKey: scope.key.value,
          timeScopeKey: scope.timeScope.canonicalKey,
          totalMinor: 24690,
          entryCount: 2,
          withRow: true,
          rowId: rowId,
          epochDay: epochDay,
        );
      return writer.takeBytes();
    }

    final current = DashboardPreparedBinaryCodec.decodeFrame(
      payload('entry-1', 20619),
      request: request,
    );

    final merged = DashboardPreparedBinaryCodec.decodePage(
      payload('entry-2', 20618),
      request: request,
      currentFrame: current,
    );

    expect(merged.logBox.groups, hasLength(2));
    expect(merged.stableRowIdentities, ['entry-1', 'entry-2']);
    expect(merged.entryCount, 2);
  });
}

DashboardPreparedDeckRequest _request() {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
  );
  final catalog = DashboardSemanticCatalog.forParent(
    parentScope: parent,
    childKind: DashboardChildKind.day,
  );
  return DashboardPreparedDeckRequest(
    key: DashboardPreparedDeckKey.fromScope(
      parentScope: parent,
      childKind: catalog.childKind,
      coreRevision: 3,
      pageSize: 24,
      semanticWindowIdentity: catalog.windowIdentity,
    ),
    parentScope: parent,
    semanticCatalog: catalog,
  );
}

Uint8List _payload(
  DashboardPreparedDeckRequest request, {
  int sqlCallCount =
      DashboardPreparedBinaryCodec.expectedPreparedDeckSqlCallCount,
}) {
  final writer = _Writer()
    ..int32(DashboardPreparedBinaryCodec.magic)
    ..int32(DashboardPreparedBinaryCodec.version)
    ..int64(7)
    ..int64(3)
    ..string(request.parentScope.key.value)
    ..string('income')
    ..string('day')
    ..int32(24)
    ..int32(sqlCallCount)
    ..int32(1)
    ..int32(1)
    ..int32(2)
    ..int64(1000)
    ..int64(2000);
  writer.slice(
    queryKey: request.parentScope.key.value,
    timeScopeKey: 'month:2026-06',
    totalMinor: 12345,
    entryCount: 1,
    withRow: true,
  );
  writer.int32(request.semanticCatalog.length);
  for (final entry in request.semanticCatalog.entries) {
    final value = entry.scope.timeScope.canonicalKey.split(':').last;
    writer.string(value);
    writer.slice(
      queryKey: entry.queryKey.value,
      timeScopeKey: entry.scope.timeScope.canonicalKey,
      totalMinor: entry.logicalIndex == 14 ? 12345 : 0,
      entryCount: entry.logicalIndex == 14 ? 1 : 0,
      withRow: entry.logicalIndex == 14,
    );
  }
  return writer.takeBytes();
}

Uint8List _changedInt32(Uint8List source, int offset, int value) {
  final result = Uint8List.fromList(source);
  ByteData.sublistView(result).setInt32(offset, value, Endian.big);
  return result;
}

Uint8List _changedInt64(Uint8List source, int offset, int value) {
  final result = Uint8List.fromList(source);
  ByteData.sublistView(result).setInt64(offset, value, Endian.big);
  return result;
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

  void slice({
    required String queryKey,
    required String timeScopeKey,
    required int totalMinor,
    required int entryCount,
    required bool withRow,
    String rowId = 'entry-1',
    int epochDay = 20619,
  }) {
    string(queryKey);
    string(timeScopeKey);
    string('income');
    int64(totalMinor);
    int64(entryCount);
    int32(withRow ? 1 : 0);
    if (withRow) row(rowId: rowId, epochDay: epochDay);
    boolean(withRow);
    if (withRow) {
      int64(epochDay);
      int32(600);
      string(rowId);
    }
  }

  void row({String rowId = 'entry-1', int epochDay = 20619}) {
    string(rowId);
    string('partner-1');
    string('Árvíztűrő Partner');
    string('category-1');
    string('Kategória');
    string('color_02');
    string('icon_02');
    string('partnerDefault');
    string('manual');
    string('income');
    int64(12345);
    int64(epochDay);
    int32(600);
    nullableString('tükörfúrógép');
    int64(1700000000000);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

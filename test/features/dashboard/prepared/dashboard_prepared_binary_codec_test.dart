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

Uint8List _payload(DashboardPreparedDeckRequest request) {
  final writer = _Writer()
    ..int32(DashboardPreparedBinaryCodec.magic)
    ..int32(DashboardPreparedBinaryCodec.version)
    ..int64(7)
    ..int64(3)
    ..string(request.parentScope.key.value)
    ..string('income')
    ..string('day')
    ..int32(24)
    ..int32(6)
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
  }) {
    string(queryKey);
    string(timeScopeKey);
    string('income');
    int64(totalMinor);
    int64(entryCount);
    int32(withRow ? 1 : 0);
    if (withRow) row();
    boolean(withRow);
    if (withRow) {
      int64(20619);
      int32(600);
      string('entry-1');
    }
  }

  void row() {
    string('entry-1');
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
    int64(20619);
    int32(600);
    nullableString('tükörfúrógép');
    int64(1700000000000);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

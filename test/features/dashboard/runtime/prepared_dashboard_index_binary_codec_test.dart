import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_dashboard_index_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('decodes one complete index with shared projected row identities', () {
    final request = _request();
    final index = DashboardPreparedIndexBinaryCodec.decode(
      _payload(request),
      request: request,
      expectedGeneration: 7,
    );

    final allIncome = request.filterScope.copyWith(
      direction: LedgerDirection.income,
      timeScope: const AllTimeScope(),
    );
    final incomeDay = allIncome.copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 15)),
    );
    final expenseDay = incomeDay.copyWith(direction: LedgerDirection.expense);
    final incomeMonth = incomeDay.copyWith(
      timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
    );
    final allFrame = index.frameFor(allIncome);
    final dayFrame = index.frameFor(incomeDay);
    final zeroFrame = index.frameFor(expenseDay);

    expect(index.generation, 7);
    expect(index.coreRevision, 3);
    expect(index.buildMetrics.sqlCallCount, 5);
    expect(index.buildMetrics.nativeSqlDurationMicros, 1);
    expect(index.buildMetrics.uniquePreviewRowCount, 1);
    expect(index.buildMetrics.serializationDurationMicros, 5);
    expect(index.catalogFor(allIncome).length, 3);
    expect(dayFrame.amount.formattedAmount, '123,45 Ft');
    expect(dayFrame.parentQueryKey, incomeMonth.key);
    expect(allFrame.parentQueryKey, allIncome.key);
    expect(dayFrame.logBox.groups.single.dayLabel, '2026. június 15.');
    expect(zeroFrame.amount.totalMinor, 0);
    expect(
      index.originFor(dayFrame.queryKey),
      DashboardDataOrigin.preparedIndex,
    );
    expect(
      index.originFor(zeroFrame.queryKey),
      DashboardDataOrigin.deterministicZero,
    );
    expect(
      identical(
        allFrame.logBox.groups.single.rows.single,
        dayFrame.logBox.groups.single.rows.single,
      ),
      isTrue,
      reason: 'the deduplicated native row must be projected exactly once',
    );
  });

  test('rejects stale generation, invalid row reference and trailing data', () {
    final request = _request();
    final valid = _payload(request);

    expect(
      () => DashboardPreparedIndexBinaryCodec.decode(
        valid,
        request: request,
        expectedGeneration: 8,
      ),
      throwsFormatException,
    );
    expect(
      () => DashboardPreparedIndexBinaryCodec.decode(
        _payload(request, dayRowIndex: 9),
        request: request,
        expectedGeneration: 7,
      ),
      throwsFormatException,
    );
    expect(
      () => DashboardPreparedIndexBinaryCodec.decode(
        Uint8List.fromList(<int>[...valid, 0]),
        request: request,
        expectedGeneration: 7,
      ),
      throwsFormatException,
    );
  });
}

PreparedDashboardIndexRequest _request() {
  final filterScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
  );
  return PreparedDashboardIndexRequest(
    key: PreparedDashboardIndexKey.fromScope(
      scope: filterScope,
      coreRevision: 3,
      pageSize: 24,
      yearWindowStart: 2025,
      yearWindowEndInclusive: 2027,
    ),
    filterScope: filterScope,
    initialYear: 2026,
    reason: DataAcquisitionReason.bootstrap,
  );
}

Uint8List _payload(
  PreparedDashboardIndexRequest request, {
  int dayRowIndex = 0,
}) {
  final incomeAll = request.filterScope.copyWith(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
  );
  final incomeDay = incomeAll.copyWith(
    timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 15)),
  );
  final writer = _Writer()
    ..int32(DashboardPreparedIndexBinaryCodec.magic)
    ..int32(DashboardPreparedIndexBinaryCodec.version)
    ..int64(7)
    ..int64(3)
    ..int32(24)
    ..int32(2025)
    ..int32(2027)
    ..int32(5)
    ..int32(1)
    ..int32(1)
    ..int32(1)
    ..int32(2)
    ..int64(1000)
    ..int64(2000)
    ..int64(3000)
    ..int64(4000)
    ..int64(5000)
    ..int32(1)
    ..row()
    ..int32(2)
    ..frame(queryKey: incomeAll.key.value, timeScopeKey: 'all', rowIndex: 0)
    ..frame(
      queryKey: incomeDay.key.value,
      timeScopeKey: 'day:2026-06-15',
      rowIndex: dayRowIndex,
    );
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

  void frame({
    required String queryKey,
    required String timeScopeKey,
    required int rowIndex,
  }) {
    string(queryKey);
    string(timeScopeKey);
    string('income');
    int64(12345);
    int64(1);
    int32(1);
    int32(rowIndex);
    boolean(false);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

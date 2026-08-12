import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_data_runtime.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_dashboard_index_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
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
    expect(
      index.compactZeroFrames.values.any(
        (frame) => frame.scope.direction == LedgerDirection.expense,
      ),
      isTrue,
      reason:
          'A complete payload with no matching expense rows must still retain '
          'the deterministic zero expense universe; only an explicitly '
          'requested directional partition may omit it.',
    );
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

  test(
    'decodes a sparse 2025 Query payload against a symmetric backing window',
    () {
      final request = _restrictiveRequest();
      final index = DashboardPreparedIndexBinaryCodec.decode(
        _payload(request, day: const LocalDate(year: 2025, month: 5, day: 15)),
        request: request,
        expectedGeneration: 7,
      );
      final allIncome = request.filterScope.copyWith(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
      );

      expect(request.key.yearWindowStart, 2013);
      expect(request.key.yearWindowEndInclusive, 2037);
      expect(index.catalogFor(allIncome).values, <int>[2025]);
      expect(
        index
            .frameFor(
              allIncome.copyWith(
                timeScope: const DayScope(
                  LocalDate(year: 2025, month: 5, day: 15),
                ),
              ),
            )
            .amount
            .totalMinor,
        12345,
      );
    },
  );

  test('a directional partition payload excludes the unchanged universe', () {
    final request = _request();
    final index = DashboardPreparedIndexBinaryCodec.decode(
      _payload(request),
      request: request,
      expectedGeneration: 7,
      expectedPartitionDirection: LedgerDirection.income,
    );

    expect(
      index.frames.values.every(
        (frame) => frame.scope.direction == LedgerDirection.income,
      ),
      isTrue,
    );
    expect(index.catalogs.values, everyElement(isA<Object>()));
    expect(
      index.catalogs.values.every(
        (catalog) => catalog.parentScope.direction == LedgerDirection.income,
      ),
      isTrue,
    );
  });

  test(
    'a directional partition keeps decoded rows compact until a LogBox window needs them',
    () async {
      final request = _request();
      final index = DashboardPreparedIndexBinaryCodec.decode(
        _payload(request),
        request: request,
        expectedGeneration: 7,
        expectedPartitionDirection: LedgerDirection.income,
      );

      expect(
        index.buildMetrics.dartProjectionDurationMicros,
        0,
        reason:
            'Partition decode must assemble compact hierarchy data only. '
            'Rich LogBox row/group projection belongs to the exact bounded '
            'scene window that will consume it.',
      );

      final allIncome = request.filterScope.copyWith(
        timeScope: const AllTimeScope(),
      );
      final incomeDay = allIncome.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 15)),
      );
      final allPayload = index.frameFor(allIncome).logBox;
      final dayPayload = index.frameFor(incomeDay).logBox;
      expect(allPayload.isRichProjected, isFalse);
      expect(dayPayload.isRichProjected, isFalse);

      expect(index.partitionFor(LedgerDirection.income).preparedRowCount, 1);
      expect(
        allPayload.isRichProjected,
        isFalse,
        reason:
            'Partition reuse/count metrics must consume compact row identity, '
            'not trigger rich all-frame projection.',
      );
      expect(dayPayload.isRichProjected, isFalse);

      final cache = DashboardLogBoxPreparedSceneCache();
      await cache.prepareWindow(
        window: DashboardLogBoxSceneWindow(
          identity: 'exact-day-window',
          payloads: <DashboardLogViewportState>[dayPayload],
        ),
        surfaceWidth: 360,
      );
      addTearDown(cache.dispose);

      expect(dayPayload.isRichProjected, isTrue);
      expect(allPayload.isRichProjected, isFalse);
    },
  );

  test(
    'a heavy compact partition projects only the requested interaction window',
    () async {
      final request = _wideRequest();
      final index = DashboardPreparedIndexBinaryCodec.decode(
        _heavyPayload(request, rowCount: 1801, extraFrameCount: 75),
        request: request,
        expectedGeneration: 7,
        expectedPartitionDirection: LedgerDirection.income,
      );
      final allIncome = request.filterScope.copyWith(
        timeScope: const AllTimeScope(),
      );
      final unselectedDay = allIncome.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 1, day: 1)),
      );
      final unselectedPayload = index.frameFor(unselectedDay).logBox;

      expect(index.buildMetrics.dartProjectionDurationMicros, 0);
      expect(index.buildMetrics.richRowProjectionDurationMicros, 0);
      expect(index.buildMetrics.richFrameProjectionDurationMicros, 0);
      expect(index.buildMetrics.projectedUniqueRowCount, 0);
      expect(index.buildMetrics.zeroFrameCount, 0);
      expect(index.buildMetrics.zeroScopeCount, greaterThan(3000));
      expect(
        index.buildMetrics.semanticCatalogCount,
        greaterThan(300),
        reason:
            'The 25-year fixture retains deterministic navigation semantics '
            'as compact catalogs rather than rich zero presentation frames.',
      );
      expect(unselectedPayload.isRichProjected, isFalse);

      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      await cache.prepareWindow(
        window: DashboardLogBoxSceneWindow(
          identity: 'one-row-interaction-window',
          payloads: <DashboardLogViewportState>[
            index
                .frameFor(
                  allIncome.copyWith(
                    timeScope: const DayScope(
                      LocalDate(year: 2026, month: 6, day: 15),
                    ),
                  ),
                )
                .logBox,
          ],
        ),
        surfaceWidth: 360,
      );

      expect(unselectedPayload.isRichProjected, isFalse);
      expect(
        index
            .frameFor(
              allIncome.copyWith(
                timeScope: const DayScope(
                  LocalDate(year: 2026, month: 6, day: 15),
                ),
              ),
            )
            .logBox
            .richProjectedRowCount,
        1,
        reason:
            'Only the exact requested day frame should allocate rich row/text '
            'presentation; the other 1,800 compact rows remain untouched.',
      );
    },
  );

  test(
    'compact decode keeps deterministic zero scopes out of the frame graph',
    () {
      final request = _request();
      final index = DashboardPreparedIndexBinaryCodec.decode(
        _payload(request),
        request: request,
        expectedGeneration: 7,
      );

      expect(
        index.frames.values.where(
          (frame) =>
              frame.entryCount == 0 &&
              index.originFor(frame.queryKey) ==
                  DashboardDataOrigin.deterministicZero,
        ),
        isEmpty,
        reason:
            'The compact index must retain zero-scope identity/catalog data '
            'without eagerly allocating a rich frame and empty LogBox '
            'viewport for every deterministic zero scope.',
      );
    },
  );
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

PreparedDashboardIndexRequest _restrictiveRequest() {
  final filterScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
    temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
      QueryPeriodSelection.year(2025),
    }),
  );
  return DashboardIndexRequestTemplate(
    filterScope: filterScope,
    pageSize: 24,
    initialYear: 2025,
    yearWindowRadius: 12,
  ).requestFor(coreRevision: 3, reason: DataAcquisitionReason.query);
}

PreparedDashboardIndexRequest _wideRequest() {
  final filterScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
  );
  return PreparedDashboardIndexRequest(
    key: PreparedDashboardIndexKey.fromScope(
      scope: filterScope,
      coreRevision: 3,
      pageSize: 24,
      yearWindowStart: 2014,
      yearWindowEndInclusive: 2038,
    ),
    filterScope: filterScope,
    initialYear: 2026,
    reason: DataAcquisitionReason.query,
  );
}

Uint8List _payload(
  PreparedDashboardIndexRequest request, {
  int dayRowIndex = 0,
  LocalDate day = const LocalDate(year: 2026, month: 6, day: 15),
}) {
  final incomeAll = request.filterScope.copyWith(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
  );
  final incomeDay = incomeAll.copyWith(timeScope: DayScope(day));
  final writer = _Writer()
    ..int32(DashboardPreparedIndexBinaryCodec.magic)
    ..int32(DashboardPreparedIndexBinaryCodec.version)
    ..int64(7)
    ..int64(3)
    ..int32(24)
    ..int32(request.key.yearWindowStart)
    ..int32(request.key.yearWindowEndInclusive)
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
      timeScopeKey: incomeDay.timeScope.canonicalKey,
      rowIndex: dayRowIndex,
    );
  return writer.takeBytes();
}

Uint8List _heavyPayload(
  PreparedDashboardIndexRequest request, {
  required int rowCount,
  required int extraFrameCount,
}) {
  if (extraFrameCount <= 0 || rowCount != 1 + extraFrameCount * 24) {
    throw ArgumentError('Heavy fixture needs equal bounded frame slices.');
  }
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
    ..int32(request.key.yearWindowStart)
    ..int32(request.key.yearWindowEndInclusive)
    ..int32(5)
    ..int32(1)
    ..int32(rowCount)
    ..int32(rowCount)
    ..int32(extraFrameCount + 1)
    ..int64(1000)
    ..int64(2000)
    ..int64(3000)
    ..int64(4000)
    ..int64(5000)
    ..int32(rowCount);
  for (var index = 0; index < rowCount; index += 1) {
    writer.row(index: index);
  }
  writer
    ..int32(extraFrameCount + 1)
    ..frame(
      queryKey: incomeDay.key.value,
      timeScopeKey: incomeDay.timeScope.canonicalKey,
      rowIndices: const <int>[0],
      entryCount: 1,
    );
  for (var frame = 0; frame < extraFrameCount; frame += 1) {
    final date = DateTime.utc(2026, 1, 1).add(Duration(days: frame));
    final dayScope = DayScope(
      LocalDate(year: date.year, month: date.month, day: date.day),
    );
    final day = incomeAll.copyWith(timeScope: dayScope);
    final offset = 1 + frame * 24;
    writer.frame(
      queryKey: day.key.value,
      timeScopeKey: dayScope.canonicalKey,
      rowIndices: List<int>.generate(24, (index) => offset + index),
      entryCount: 24,
    );
  }
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

  void row({int index = 1}) {
    string('entry-$index');
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
    int? rowIndex,
    List<int>? rowIndices,
    int? entryCount,
  }) {
    final indices = rowIndices ?? <int>[rowIndex!];
    string(queryKey);
    string(timeScopeKey);
    string('income');
    int64(12345);
    int64(entryCount ?? indices.length);
    int32(indices.length);
    for (final index in indices) {
      int32(index);
    }
    boolean(false);
  }

  Uint8List takeBytes() => _bytes.takeBytes();
}

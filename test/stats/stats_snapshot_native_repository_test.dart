import 'package:exptv2/features/stats/data/stats_snapshot.dart';
import 'package:exptv2/features/stats/data/stats_snapshot_repository.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/stats_snapshot_methods');
  late NativeStatsSnapshotRepository repository;
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    repository = NativeStatsSnapshotRepository(
      NativeBridge(
        methodChannel: channel,
        eventChannel: const EventChannel('test/stats_snapshot_events'),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'expenseListStatsSnapshots') {
            return <Map<String, Object?>>[
              snapshotRow(id: 'later', createdAt: 2000),
              snapshotRow(id: 'earlier', createdAt: 1000),
            ];
          }
          if (call.method == 'expenseUpsertStatsSnapshot') {
            return call.arguments;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('load maps structured native rows in deterministic order', () async {
    final snapshots = await repository.load();

    expect(calls.single.method, 'expenseListStatsSnapshots');
    expect(snapshots.map((snapshot) => snapshot.id), ['earlier', 'later']);
    expect(snapshots.first.categoryScopeIds, {1, 3});
    expect(snapshots.first.vendorScopeNames, {'Aldi', 'Tesco'});
    expect(snapshots.first.activeType, TransactionType.income);
    expect(snapshots.first.layoutMode, StatsLayoutMode.month);
  });

  test(
    'upsert sends every include and optional field as structured data',
    () async {
      final snapshot = StatsSnapshot(
        id: 'focus',
        name: 'Fokusz',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
        includeCategoryScope: true,
        includeVendorScope: true,
        includeActiveType: true,
        includeThreshold: true,
        includeLayoutMode: true,
        includePageIndex: true,
        categoryScopeIds: const {9, 2},
        vendorScopeNames: const {'Tesco', 'Aldi'},
        activeType: TransactionType.expense,
        threshold: 15000,
        layoutMode: StatsLayoutMode.year,
        activeYear: 2026,
        activeMonth: null,
        pageIndex: 1,
      );

      await repository.upsert(snapshot);

      expect(calls.single.method, 'expenseUpsertStatsSnapshot');
      expect(calls.single.arguments, <String, Object?>{
        'id': 'focus',
        'name': 'Fokusz',
        'createdAt': 1000,
        'updatedAt': 2000,
        'includeCategoryScope': true,
        'includeVendorScope': true,
        'includeActiveType': true,
        'includeThreshold': true,
        'includeLayoutMode': true,
        'includePageIndex': true,
        'categoryScopeIds': <int>[2, 9],
        'vendorScopeNames': <String>['Aldi', 'Tesco'],
        'activeType': 'expense',
        'threshold': 15000.0,
        'layoutMode': 'year',
        'activeYear': 2026,
        'activeMonth': null,
        'pageIndex': 1,
      });
    },
  );
}

Map<String, Object?> snapshotRow({required String id, required int createdAt}) {
  return <String, Object?>{
    'id': id,
    'name': 'Mentett nezet',
    'createdAt': createdAt,
    'updatedAt': createdAt + 1,
    'includeCategoryScope': true,
    'includeVendorScope': true,
    'includeActiveType': true,
    'includeThreshold': true,
    'includeLayoutMode': true,
    'includePageIndex': true,
    'categoryScopeIds': <int>[3, 1],
    'vendorScopeNames': <String>['Tesco', 'Aldi'],
    'activeType': 'income',
    'threshold': 5000.0,
    'layoutMode': 'month',
    'activeYear': 2025,
    'activeMonth': 3,
    'pageIndex': 1,
  };
}

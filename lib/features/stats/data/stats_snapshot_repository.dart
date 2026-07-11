import '../../../services/native_bridge.dart';
import 'stats_snapshot.dart';

class NativeStatsSnapshotRepository extends StatsSnapshotRepository {
  NativeStatsSnapshotRepository(this._nativeBridge);

  final NativeBridge _nativeBridge;

  @override
  Future<List<StatsSnapshot>> load() async {
    final rows = await _nativeBridge.expenseListStatsSnapshots();
    return [for (final row in rows) StatsSnapshot.fromJson(row)]
      ..sort(compareStatsSnapshots);
  }

  @override
  Future<void> upsert(StatsSnapshot snapshot) async {
    await _nativeBridge.expenseUpsertStatsSnapshot(snapshot.toJson());
  }
}

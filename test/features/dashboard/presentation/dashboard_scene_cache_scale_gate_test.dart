import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '700 to 100k ledger counts retain one complete bounded-preview rail bank',
    () async {
      final measurements = <int, Map<String, int>>{};
      for (final transactionCount in <int>[700, 10_000, 50_000, 100_000]) {
        final core = DashboardCoreController(
          initialDate: DateTime(2026, 7, 14),
          initialPlane: TimePlane.month,
          initialCoreRevision: 1,
          yearWindowRadius: 1,
        );
        final cache = DashboardLogBoxPreparedSceneCache();
        try {
          core.presentation.installIndex(
            buildRuntimeTestIndex(
              revision: 1,
              entryCountOverride: transactionCount,
              previewRowCountForScope: _boundedPreviewRows,
              previewGroupCountForScope: (scope) =>
                  _boundedPreviewRows(scope) == 0 ? 1 : 3,
            ),
            publishImmediately: true,
          );
          final window = core.renderCriticalLogBoxSceneWindow();

          await cache.prepareWindow(
            window: window,
            surfaceWidth: 378,
            yieldEveryRows: cache.maximumPinnedRows + 1,
          );
          cache.activateWindow(window);

          expect(
            window.payloads.every((payload) => payload.flatItems.length <= 24),
            isTrue,
          );
          expect(cache.preparedSceneCount, window.sceneCount);
          expect(cache.preparedRowCount, lessThanOrEqualTo(8192));
          expect(cache.estimatedBytes, greaterThan(0));
          expect(cache.textLayoutMissCount, 0);
          measurements[transactionCount] = <String, int>{
            'sceneCount': cache.preparedSceneCount,
            'textRows': cache.preparedRowCount,
            'sceneBytes': cache.estimatedBytes,
            'stagingRows': cache.peakStagingRowCount,
          };
        } finally {
          cache.dispose();
          core.dispose();
        }
      }

      final baseline = measurements[700]!;
      for (final transactionCount in <int>[10_000, 50_000, 100_000]) {
        expect(measurements[transactionCount], baseline);
      }
    },
  );
}

int _boundedPreviewRows(CurrentLedgerQueryScope scope) =>
    scope.direction == LedgerDirection.expense &&
        scope.timeScope == const MonthScope(YearMonth(year: 2026, month: 7))
    ? 24
    : 0;

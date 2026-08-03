import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps LogBox preview data-only and outside the rail physics lane', () {
    final root = Directory.current;
    final previewSource = _read(
      root,
      'lib/features/dashboard/application/dashboard_summary_metrics_source.dart',
    );
    final coordinator = _read(
      root,
      'lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart',
    );
    final queryController = _read(
      root,
      'lib/features/dashboard/query/application/current_query_controller.dart',
    );
    final logArea = _read(
      root,
      'lib/features/dashboard/logbox/presentation/dashboard_log_area.dart',
    );
    final dashboard = _read(
      root,
      'lib/features/dashboard/presentation/core_dashboard.dart',
    );

    expect(previewSource, contains('abstract interface class'));
    expect(previewSource, contains('ScopeSummaryMetrics? get metrics'));
    expect(
      previewSource,
      contains('DashboardTimeChildSummaryIndex? get readyIndex'),
    );

    expect(coordinator, contains('cachedFirstDayGroupPage(metrics.scope)'));
    expect(coordinator, contains('warmFirstDayGroupPages'));
    expect(coordinator, contains('DashboardLogPreviewLoading'));
    expect(coordinator, isNot(contains('_query.setTimeScope')));
    expect(coordinator, isNot(contains('onPreviewChanged')));

    expect(queryController, contains('warmFirstDayGroupPages'));
    expect(
      queryController,
      contains('Preview ticks must never call this method'),
    );

    for (final source in [logArea, dashboard]) {
      expect(source, isNot(contains('DashboardLedgerRepository')));
      expect(source, isNot(contains('DashboardSummaryMetricsController')));
    }
    expect(dashboard, contains('late Widget _logBoxRegion'));
  });
}

String _read(Directory root, String relativePath) =>
    File('${root.path}/$relativePath').readAsStringSync();

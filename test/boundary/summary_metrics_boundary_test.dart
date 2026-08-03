import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps summary amount and count on one presentation boundary', () {
    final root = Directory.current;
    final controller = _read(
      root,
      'lib/features/dashboard/application/dashboard_summary_amount_controller.dart',
    );
    final summaryPill = _read(
      root,
      'lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart',
    );
    final logBoxArea = _read(
      root,
      'lib/features/dashboard/logbox/presentation/dashboard_log_area.dart',
    );
    final logBoxState = _read(
      root,
      'lib/features/dashboard/logbox/application/dashboard_log_area_state.dart',
    );
    final metricsModel = File(
      '${root.path}/lib/features/dashboard/query/domain/scope_summary_metrics.dart',
    );
    final metricsPresentation = File(
      '${root.path}/lib/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart',
    );
    final legacyAmountPresentation = File(
      '${root.path}/lib/features/dashboard/time_navigation/presentation/summary_amount_presentation.dart',
    );

    expect(metricsModel.existsSync(), isTrue);
    expect(metricsPresentation.existsSync(), isTrue);
    expect(legacyAmountPresentation.existsSync(), isFalse);
    expect(controller, contains('class DashboardSummaryMetricsController'));
    expect(controller, contains('ScopeSummaryMetrics'));
    expect(controller, isNot(contains('childCount ?? parentCount')));
    expect(controller, isNot(contains('entryCount ??')));
    expect(summaryPill, contains('SummaryMetricsPresentation'));
    expect(logBoxArea, contains('snapshot.summaryMetrics.entryCount'));
    expect(logBoxState, contains('DashboardLogQuerySnapshot'));
    for (final source in [summaryPill, logBoxArea, logBoxState]) {
      expect(source, isNot(contains('DashboardLedgerRepository')));
      expect(source, isNot(contains('DashboardLedgerResult')));
      expect(source, isNot(contains('SummaryAmountPresentation')));
    }
  });
}

String _read(Directory root, String relativePath) =>
    File('${root.path}/$relativePath').readAsStringSync();

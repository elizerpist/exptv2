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
    final logBoxHeader = _read(
      root,
      'lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart',
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
    for (final source in [summaryPill, logBoxHeader]) {
      expect(source, contains('SummaryMetricsPresentation'));
      expect(source, isNot(contains('DashboardLedgerRepository')));
      expect(source, isNot(contains('DashboardLedgerResult')));
      expect(source, isNot(contains('SummaryAmountPresentation')));
    }
  });

  test('keeps diagnostics and bounded payloads out of widget ownership', () {
    final root = Directory.current;
    final diagnostics = _read(
      root,
      'lib/features/dashboard/query/application/dashboard_presentation_diagnostics.dart',
    );
    final cache = _read(
      root,
      'lib/features/dashboard/query/data/dashboard_bounded_cache.dart',
    );
    final fixture = _read(
      root,
      'lib/features/dashboard/query/data/dashboard_stress_fixture.dart',
    );
    for (final source in [diagnostics, cache, fixture]) {
      expect(source, isNot(contains('package:flutter/material.dart')));
      expect(source, isNot(contains('BuildContext')));
      expect(source, isNot(contains('ScrollController')));
    }
  });
}

String _read(Directory root, String relativePath) =>
    File('${root.path}/$relativePath').readAsStringSync();

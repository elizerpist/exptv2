import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'MHC-08/10 chart remains a paint-only semantic Header consumer with no ticker or financial authority',
    () {
      final chart = File(
        'lib/features/dashboard/mind/presentation/mind_header_score_chart.dart',
      ).readAsStringSync();
      final mindSurface = File(
        'lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart',
      ).readAsStringSync();

      expect(chart, contains('MindBehavioralScoreChartSeries'));
      expect(chart, contains('CustomPainter'));
      expect(chart, isNot(contains('AnimationController')));
      expect(chart, isNot(contains('Ticker')));
      expect(chart, isNot(contains('Timer(')));
      expect(chart, isNot(contains('QueryAmountRange')));
      expect(chart, isNot(contains('MindBehavioralScoreProjection.build')));
      expect(chart, isNot(contains('repository')));
      expect(mindSurface, contains('MindHeaderScoreChart('));
      expect(mindSurface, isNot(contains('.preview(')));
      expect(
        mindSurface,
        isNot(contains('MindBehavioralScoreProjection.build')),
      );
    },
  );
}

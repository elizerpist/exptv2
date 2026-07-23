import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/stats/widgets/stats_fast_info_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FastInfo metadata keeps user-facing copy Hungarian', () {
    final spec = StatsFastInfoGraph.specForTesting(StatsRenderMode.common);
    final visibleCopy = [
      for (final chart in spec.charts) ...[
        chart.title,
        chart.yAxisLabel,
        chart.xAxisLabel,
        ...chart.legendLabels,
      ],
    ].join(' ').toLowerCase();

    expect(spec.charts.first.yAxisLabel, 'pontszám');
    expect(visibleCopy, isNot(contains('score')));
    expect(visibleCopy, isNot(contains('threshold excess')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_monthly_overlay_series.dart';

void main() {
  test(
    'SUM3-BAR-01 RED: one neutral monthly overlay series keeps complete and scoped totals separate',
    () {
      final series = MindMonthlyOverlaySeries.fromTotals(
        fullAmounts: const <int>[1000, 0, 800],
        filteredAmounts: const <int>[250, 0, 0],
      );

      expect(series.values, hasLength(3));
      expect(series.values[0].fullAmount, 1000);
      expect(series.values[0].filteredAmount, 250);
      expect(series.values[1].filteredAmount, 0);
      expect(series.values[2].filteredAmount, 0);
      expect(series.scale.top, greaterThanOrEqualTo(1000));
    },
  );

  test(
    'SUM3-BAR-02 RED: overlay values clamp only impossible paint overflow',
    () {
      final series = MindMonthlyOverlaySeries.fromTotals(
        fullAmounts: const <int>[100],
        filteredAmounts: const <int>[150],
      );

      expect(series.values.single.fullAmount, 100);
      expect(series.values.single.filteredAmount, 100);
    },
  );
}

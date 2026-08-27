import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';

void main() {
  test(
    'formats the daily pace Header values in the presentation formatter',
    () {
      expect(
        DashboardPreparedFormatter.amountMinorPerDay(1200000),
        '12000,00 Ft/nap',
      );
      expect(
        DashboardPreparedFormatter.amountMinorPerDay(1000000),
        '10000,00 Ft/nap',
      );
    },
  );
}

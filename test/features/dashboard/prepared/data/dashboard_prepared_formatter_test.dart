import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';

void main() {
  test('formats exact scaled HUF values as whole forints', () {
    expect(DashboardPreparedFormatter.amountMinor(0), '0 Ft');
    expect(DashboardPreparedFormatter.amountMinor(550000), '5500 Ft');
    expect(DashboardPreparedFormatter.amountMinor(-550000), '-5500 Ft');
    expect(DashboardPreparedFormatter.amountMinor(1200000), '12000 Ft');
  });

  test('formats daily pace exact HUF values without a fractional suffix', () {
    expect(
      DashboardPreparedFormatter.amountMinorPerDay(1200000),
      '12000 Ft/nap',
    );
    expect(
      DashboardPreparedFormatter.amountMinorPerDay(1000000),
      '10000 Ft/nap',
    );
  });
}

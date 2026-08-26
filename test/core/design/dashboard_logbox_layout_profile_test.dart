import 'package:fluvi/core/design/dashboard_logbox_layout_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'LogBox height profile maps 0..100 percent to baseline..150 percent',
    () {
      const baseline = DashboardLogBoxLayoutProfile(DashboardLogBoxHeight.zero);
      final middle = DashboardLogBoxLayoutProfile(DashboardLogBoxHeight(.5));
      const maximum = DashboardLogBoxLayoutProfile(DashboardLogBoxHeight.one);

      expect(baseline.rowHeight, DashboardLogBoxTokens.rowHeight);
      expect(middle.rowHeight, DashboardLogBoxTokens.rowHeight * 1.25);
      expect(maximum.rowHeight, DashboardLogBoxTokens.rowHeight * 1.5);
    },
  );
}

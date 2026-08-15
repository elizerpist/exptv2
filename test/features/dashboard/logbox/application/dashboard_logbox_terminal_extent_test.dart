import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_terminal_extent.dart';

void main() {
  test(
    'RED: terminal navigation protection extends scroll content, never shortens the viewport',
    () {
      final long = DashboardLogBoxTerminalExtent.resolve(
        logBoxContentExtent: 900,
        viewportDimension: 400,
        terminalBottomInset: 120,
      );

      expect(long.viewportDimension, 400);
      expect(long.renderSurfaceExtent, 900);
      expect(long.terminalBottomInset, 120);
      expect(long.effectiveScrollContentExtent, 1020);
      expect(long.maxScrollExtent, 620);

      final short = DashboardLogBoxTerminalExtent.resolve(
        logBoxContentExtent: 300,
        viewportDimension: 400,
        terminalBottomInset: 80,
      );

      expect(short.viewportDimension, 400);
      expect(short.renderSurfaceExtent, 300);
      expect(short.terminalBottomInset, 0);
      expect(short.effectiveScrollContentExtent, 300);
      expect(short.maxScrollExtent, 0);

      final empty = DashboardLogBoxTerminalExtent.resolve(
        logBoxContentExtent: 0,
        viewportDimension: 400,
        terminalBottomInset: 80,
      );

      expect(empty.renderSurfaceExtent, 400);
      expect(empty.terminalBottomInset, 0);
      expect(empty.maxScrollExtent, 0);
    },
  );
}

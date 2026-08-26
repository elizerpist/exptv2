import 'package:fluvi/core/design/dashboard_logbox_layout_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter/material.dart';
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

  test('LogBox edit placeholder pins the reference vector treatment', () {
    expect(DashboardLogBoxTokens.editPlaceholderSize, 24);
    expect(
      DashboardLogBoxTokens.editPlaceholderBackground,
      const Color(0x1A7D8798),
    );
    expect(DashboardLogBoxTokens.editPlaceholderRadius, 8);
    expect(
      DashboardLogBoxTokens.editPlaceholderAssetPath,
      'assets/icons/lucide/pencil.svg',
    );
    expect(DashboardLogBoxTokens.editPlaceholderGlyphSize, 13);
    expect(
      DashboardLogBoxTokens.editPlaceholderGlyphColor,
      const Color(0xFF7D8798),
    );
  });

  test(
    'edit placeholder preserves the reference trailing slot at any height',
    () {
      final baseline = DashboardLogBoxTokens.editPlaceholderBounds(
        surfaceWidth: 378,
        rowTop: 20,
        rowHeight: DashboardLogBoxTokens.rowHeight,
      );
      final taller = DashboardLogBoxTokens.editPlaceholderBounds(
        surfaceWidth: 378,
        rowTop: 20,
        rowHeight: DashboardLogBoxTokens.rowHeight * 1.5,
      );

      expect(baseline, const Rect.fromLTWH(342, 35.5, 24, 24));
      expect(taller.left, baseline.left);
      expect(taller.size, baseline.size);
      expect(taller.center.dy, 20 + DashboardLogBoxTokens.rowHeight * .75);
      expect(
        DashboardLogBoxTokens.textTrailingEdge(surfaceWidth: 378),
        baseline.left - DashboardLogBoxTokens.rowGap,
      );
    },
  );
}

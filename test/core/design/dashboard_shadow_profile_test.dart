import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shadow catalog preserves Current as the exact Fluvi baseline', () {
    expect(DashboardShadowStyle.values, const <DashboardShadowStyle>[
      DashboardShadowStyle.none,
      DashboardShadowStyle.current,
      DashboardShadowStyle.soft,
    ]);
    expect(
      const DashboardShadowProfile(
        DashboardShadowStyle.current,
      ).shadowsFor(DashboardCornerSurfaceFamily.summaryPill),
      FluviVisualTokens.cardSurfaceShadows,
    );
  });

  test('none is flat and soft has blurred depth without a hard foot', () {
    const none = DashboardShadowProfile(DashboardShadowStyle.none);
    const soft = DashboardShadowProfile(DashboardShadowStyle.soft);
    for (final family in DashboardCornerSurfaceFamily.values) {
      expect(none.shadowsFor(family), isEmpty);
    }
    expect(soft.shadowsFor(DashboardCornerSurfaceFamily.header), const <
      BoxShadow
    >[
      BoxShadow(
        color: Color(0x3DC359B8),
        offset: Offset(0, 16),
        blurRadius: 34,
      ),
      BoxShadow(color: Color(0x1F50459C), offset: Offset(0, 6), blurRadius: 14),
    ]);
    final softShadows = soft.shadowsFor(
      DashboardCornerSurfaceFamily.contentCard,
    );
    expect(softShadows, const <BoxShadow>[
      BoxShadow(color: Color(0x14524B93), offset: Offset(0, 9), blurRadius: 19),
    ]);
    expect(softShadows, isNotEmpty);
    expect(softShadows.every((shadow) => shadow.blurRadius > 0), isTrue);
  });
}

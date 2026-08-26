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
      DashboardShadowStyle.reference3d,
    ]);
    expect(
      const DashboardShadowProfile(
        DashboardShadowStyle.current,
      ).shadowsFor(DashboardCornerSurfaceFamily.summaryPill),
      FluviVisualTokens.cardSurfaceShadows,
    );
  });

  test('the fourth depth profile pins the Balance reference material', () {
    const profile = DashboardShadowProfile(DashboardShadowStyle.reference3d);
    final summary = profile.depthFor(DashboardCornerSurfaceFamily.summaryPill);
    final search = profile.depthFor(DashboardCornerSurfaceFamily.searchPill);

    expect(
      summary.border,
      const Border.fromBorderSide(BorderSide(color: Color(0x1A666FAB))),
    );
    expect(summary.shadows, const <BoxShadow>[
      BoxShadow(color: Color(0x14524B93), offset: Offset(0, 8), blurRadius: 17),
      BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ]);
    expect(
      search.border,
      const Border.fromBorderSide(BorderSide(color: Color(0x17666FAB))),
    );
    expect(search.shadows, const <BoxShadow>[
      BoxShadow(color: Color(0x12524B93), offset: Offset(0, 7), blurRadius: 15),
      BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ]);
  });

  test('the fourth depth profile reaches every semantic surface family', () {
    const profile = DashboardShadowProfile(DashboardShadowStyle.reference3d);
    for (final family in DashboardCornerSurfaceFamily.values) {
      final depth = profile.depthFor(family);
      expect(depth.border, isNotNull, reason: family.name);
      expect(depth.outerShadows, isNotEmpty, reason: family.name);
      expect(depth.innerShadows, isNotEmpty, reason: family.name);
    }
    expect(
      profile.depthFor(DashboardCornerSurfaceFamily.summaryPill).surfaceColor,
      const Color(0xFFFEFEFF),
    );
    expect(
      profile.depthFor(DashboardCornerSurfaceFamily.searchPill).surfaceColor,
      const Color(0xF0FFFFFF),
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

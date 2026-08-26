import 'package:flutter/material.dart';

import 'dashboard_corner_profile.dart';
import 'dashboard_mode_palette.dart';

/// Global dashboard depth treatment. It changes only outer decoration, never
/// bounds, clipping, border or semantic surface ownership.
enum DashboardShadowStyle { none, current, soft }

/// One family-aware shadow resolver shared by dashboard outer surfaces.
///
/// The Current endpoint returns the authored Fluvi foot/elevation pair
/// verbatim. Soft uses the read-only visual reference's blurred families:
/// hero `(0x3DC359B8, y16, b34)` + `(0x1F50459C, y6, b14)`, cards
/// `(0x14524B93, y9, b19)`, and compact controls `(black 10%, y5, b12)`.
/// No Soft value has an unblurred lower foot.
final class DashboardShadowProfile {
  const DashboardShadowProfile(this.style);

  final DashboardShadowStyle style;

  List<BoxShadow> shadowsFor(DashboardCornerSurfaceFamily family) =>
      switch (style) {
        DashboardShadowStyle.none => const <BoxShadow>[],
        DashboardShadowStyle.current => switch (family) {
          DashboardCornerSurfaceFamily.logBoxGroup => const <BoxShadow>[
            FluviVisualTokens.cardFootShadow,
          ],
          _ => FluviVisualTokens.cardSurfaceShadows,
        },
        DashboardShadowStyle.soft => switch (family) {
          DashboardCornerSurfaceFamily.header => _softHeroShadows,
          DashboardCornerSurfaceFamily.directionControl ||
          DashboardCornerSurfaceFamily.summaryPill ||
          DashboardCornerSurfaceFamily.searchPill => _softControlShadows,
          DashboardCornerSurfaceFamily.contentCard ||
          DashboardCornerSurfaceFamily.logBoxGroup ||
          DashboardCornerSurfaceFamily.budgetDistributionCard =>
            _softCardShadows,
        },
      };

  static const _softHeroShadows = <BoxShadow>[
    BoxShadow(color: Color(0x3DC359B8), offset: Offset(0, 16), blurRadius: 34),
    BoxShadow(color: Color(0x1F50459C), offset: Offset(0, 6), blurRadius: 14),
  ];

  static const _softCardShadows = <BoxShadow>[
    BoxShadow(color: Color(0x14524B93), offset: Offset(0, 9), blurRadius: 19),
  ];

  static const _softControlShadows = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 5), blurRadius: 12),
  ];
}

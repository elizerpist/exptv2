import 'package:flutter/material.dart';

import 'dashboard_corner_profile.dart';
import 'dashboard_mode_palette.dart';

/// Global dashboard depth treatment. It changes only outer decoration, never
/// bounds, clipping or semantic surface ownership.
enum DashboardShadowStyle { none, current, soft, spendee3d }

/// Complete material-depth input for one dashboard surface family.
///
/// Most styles need only outer shadows. The reference-material endpoint also
/// owns an authored contour, an inner highlight, and (where source-defined)
/// an opaque surface colour. Callers retain their own fill unless that source
/// explicitly defines a material colour for the family.
@immutable
final class DashboardSurfaceDepth {
  const DashboardSurfaceDepth({
    this.border,
    this.surfaceColor,
    this.outerShadows = const <BoxShadow>[],
    this.innerShadows = const <BoxShadow>[],
  });

  final BoxBorder? border;
  final Color? surfaceColor;
  final List<BoxShadow> outerShadows;
  final List<BoxShadow> innerShadows;

  List<BoxShadow> get shadows => <BoxShadow>[...outerShadows, ...innerShadows];
}

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

  DashboardSurfaceDepth depthFor(DashboardCornerSurfaceFamily family) =>
      switch (style) {
        DashboardShadowStyle.none => _flatDepth,
        DashboardShadowStyle.current => switch (family) {
          DashboardCornerSurfaceFamily.logBoxGroup => _currentLogBoxDepth,
          _ => _currentSurfaceDepth,
        },
        DashboardShadowStyle.soft => switch (family) {
          DashboardCornerSurfaceFamily.header => _softHeroDepth,
          DashboardCornerSurfaceFamily.directionControl ||
          DashboardCornerSurfaceFamily.summaryPill ||
          DashboardCornerSurfaceFamily.searchPill => _softControlDepth,
          DashboardCornerSurfaceFamily.contentCard ||
          DashboardCornerSurfaceFamily.logBoxGroup ||
          DashboardCornerSurfaceFamily.budgetDistributionCard => _softCardDepth,
        },
        DashboardShadowStyle.spendee3d => switch (family) {
          DashboardCornerSurfaceFamily.searchPill => _referenceSearchDepth,
          DashboardCornerSurfaceFamily.summaryPill => _referenceSummaryDepth,
          _ => _referenceSurfaceDepth,
        },
      };

  List<BoxShadow> shadowsFor(DashboardCornerSurfaceFamily family) =>
      depthFor(family).shadows;

  BoxBorder? borderFor(
    DashboardCornerSurfaceFamily family, {
    BoxBorder? fallback,
  }) => depthFor(family).border ?? fallback;

  Color surfaceColorFor(
    DashboardCornerSurfaceFamily family, {
    required Color fallback,
  }) => depthFor(family).surfaceColor ?? fallback;

  static const _flatDepth = DashboardSurfaceDepth();

  static const _currentLogBoxDepth = DashboardSurfaceDepth(
    outerShadows: <BoxShadow>[FluviVisualTokens.cardFootShadow],
  );

  static const _currentSurfaceDepth = DashboardSurfaceDepth(
    outerShadows: FluviVisualTokens.cardSurfaceShadows,
  );

  static const _softHeroDepth = DashboardSurfaceDepth(
    outerShadows: _softHeroShadows,
  );

  static const _softCardDepth = DashboardSurfaceDepth(
    outerShadows: _softCardShadows,
  );

  static const _softControlDepth = DashboardSurfaceDepth(
    outerShadows: _softControlShadows,
  );

  // Balance reference Summary material, ported verbatim from the read-only
  // reference visual specification. The inner white layer is intentionally a
  // distinct highlight rather than an approximation of the Soft endpoint.
  static const _referenceSummaryDepth = DashboardSurfaceDepth(
    border: Border.fromBorderSide(BorderSide(color: Color(0x1A666FAB))),
    surfaceColor: Color(0xFFFEFEFF),
    outerShadows: <BoxShadow>[
      BoxShadow(color: Color(0x14524B93), offset: Offset(0, 8), blurRadius: 17),
    ],
    innerShadows: <BoxShadow>[
      BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  // Balance reference Search material. Its source has a deliberately lighter
  // contour and shallower outer depth than the Summary surface.
  static const _referenceSearchDepth = DashboardSurfaceDepth(
    border: Border.fromBorderSide(BorderSide(color: Color(0x17666FAB))),
    surfaceColor: Color(0xF0FFFFFF),
    outerShadows: <BoxShadow>[
      BoxShadow(color: Color(0x12524B93), offset: Offset(0, 7), blurRadius: 15),
    ],
    innerShadows: <BoxShadow>[
      BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  // Every non-Search outer dashboard family shares the complete Summary
  // contour/depth construction while retaining that component's own fill.
  static const _referenceSurfaceDepth = DashboardSurfaceDepth(
    border: Border.fromBorderSide(BorderSide(color: Color(0x1A666FAB))),
    outerShadows: <BoxShadow>[
      BoxShadow(color: Color(0x14524B93), offset: Offset(0, 8), blurRadius: 17),
    ],
    innerShadows: <BoxShadow>[
      BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

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

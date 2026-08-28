import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../financial_limits/presentation/budget_ring_presentation.dart';
import '../../assets/prepared_vector_asset_atlas.dart';
import '../../design/dashboard_mode_palette.dart';
import '../../financial_limits/domain/financial_limit.dart';
import '../domain/budget_progress_health.dart';
import 'category_icon_view.dart';

/// The sole visual-geometry contract for the Budget category avatar.
///
/// The shell may paint outside the fixed carousel slot, but it must never
/// change the sphere or glyph geometry. These source-space values deliberately
/// match [BudgetCategoryAvatarSvg]'s full artwork viewport.
abstract final class BudgetCategoryAvatarGeometry {
  static const avatarCanvasSize = 72.0;
  static const glyphSize = 30.0;

  static const selectionShellVisualDiameter = 112.0;
  static const selectionSourceViewport = 308.0;
  static const selectionTrackRadius = 96.0 * 1.12;
  static const selectionTrackWidth = 24.0;

  static const avatarVisibleRadius = 142.0 * avatarCanvasSize / 342.0;
  static const selectionTrackInnerRadius =
      (selectionTrackRadius - selectionTrackWidth / 2) *
      selectionShellVisualDiameter /
      selectionSourceViewport;
  static const selectionTrackClearance =
      selectionTrackInnerRadius - avatarVisibleRadius;

  static const selectionFaceColor = Color(0xffffffff);

  /// The source artwork's body centre. Normal artwork keeps its lower floor
  /// in a deliberately biased viewport; the selected core does not contain
  /// that floor and therefore recentres this point without changing scale.
  static const avatarSphereCenterX = 256.0;
  static const avatarSphereCenterY = 240.0;
  static const avatarArtworkViewportWidth = 324.0;
  static const avatarArtworkViewportHeight = 342.0;
  static const normalRailViewportTop = 78.0;
  static const centeredCoreViewportTop =
      avatarSphereCenterY - avatarArtworkViewportHeight / 2;
}

/// One hue/tone authority for every Budget target's projected shadow.
/// Geometry and opacity remain renderer-owned, but the target-derived colour
/// must never drift between the authored SVG floor and selection-shell cast.
abstract final class BudgetCategoryAvatarPalette {
  static Color shadowColor(Color categoryColor) =>
      Color.lerp(categoryColor, const Color(0xff24113f), .18)!;
}

/// Exact live-limit projection from the approved Budget reference. Monetary
/// values remain integer scaled-100 everywhere else; this tiny visual adapter
/// is the sole intentional ratio conversion for the painted arc.
@immutable
final class BudgetLimitProgressProjection {
  const BudgetLimitProgressProjection._({
    required this.rawProgress,
    required this.visualProgress,
  });

  factory BudgetLimitProgressProjection.fromAmounts({
    required int actualScaled100,
    required int? limitScaled100,
  }) {
    final hasPositiveLimit = limitScaled100 != null && limitScaled100 > 0;
    final raw = hasPositiveLimit ? actualScaled100 / limitScaled100 : 0.0;
    // This is the only intentional conversion from exact integer money to a
    // double: the painter consumes the bounded ratio directly. In particular,
    // 0 stays 0 and 99.9% must not be rounded into a full circle.
    final visual = BudgetLimitProgressProjection.boundedVisualProgress(raw);
    return BudgetLimitProgressProjection._(
      rawProgress: raw,
      visualProgress: visual,
    );
  }

  static double boundedVisualProgress(double rawProgress) =>
      !rawProgress.isFinite ? 0 : rawProgress.clamp(0.0, 1.0).toDouble();

  /// Arc coverage and semantic warning tone intentionally use different
  /// inputs: coverage is bounded, while the tone keeps the raw utilisation so
  /// an overspent target remains visibly dangerous rather than returning to
  /// its category accent at 100%.
  Color toneFor(Color targetAccent) => BudgetLimitProgressToneResolver.resolve(
    rawProgress: rawProgress,
    targetAccent: targetAccent,
  );

  final double rawProgress;
  final double visualProgress;
}

/// The one pure visual authority for selected Budget-target progress tones.
abstract final class BudgetLimitProgressToneResolver {
  static Color resolve({
    required double rawProgress,
    required Color targetAccent,
  }) => switch (BudgetProgressHealthResolver.resolve(
    isAvailable: rawProgress.isFinite,
    rawRatio: rawProgress,
  )) {
    BudgetProgressHealth.unavailable ||
    BudgetProgressHealth.targetAccent => targetAccent,
    BudgetProgressHealth.warning => FluviVisualTokens.budgetProgressWarning,
    BudgetProgressHealth.danger => FluviVisualTokens.budgetProgressDanger,
  };
}

/// One source/material authority for every Budget scope ring strategy.
///
/// These are the existing Fluvi selected-avatar source values;
/// no scope owns a second SVG, radius, stroke or active-cap language.
final class BudgetProgressRingGeometry {
  const BudgetProgressRingGeometry._({
    required this.id,
    required this.viewport,
    required this.center,
    required this.faceRadius,
    required this.trackRadius,
    required this.trackWidth,
    required this.trackShadowColor,
    required this.trackGradientColors,
    required this.trackGradientStops,
    required this.trackGlossColor,
    required this.trackGlossFraction,
    required this.faceShadowOffset,
    required this.groundShadowOffset,
    required this.groundShadowSize,
  });

  /// The single source consumed by the actual painter—not merely a test ID.
  static const source = BudgetProgressRingGeometry._(
    id: 'fluvi-selected-budget-ring-v1',
    viewport: Size.square(308),
    center: Offset(154, 154),
    faceRadius: 122,
    trackRadius: 107.52,
    trackWidth: 24,
    trackShadowColor: Color(0x73CFC7DF),
    trackGradientColors: <Color>[
      Color(0xFFF8F4FF),
      Color(0xFFECE8F8),
      Color(0xFFDCD6EC),
    ],
    trackGradientStops: <double>[0, .48, 1],
    trackGlossColor: Color(0x85FFFFFF),
    trackGlossFraction: .24,
    faceShadowOffset: Offset(0, 12),
    groundShadowOffset: Offset(0, 112),
    groundShadowSize: Size(252, 68),
  );

  static const sourceId = 'fluvi-selected-budget-ring-v1';
  static const sourceViewport = 308.0;
  static const sourceCenter = Offset(154, 154);
  static const sourceFaceRadius = 122.0;
  static const sourceTrackRadius = 107.52;
  static const sourceTrackWidth = 24.0;
  static const roundedCapRadius = 12.0;
  static const canonicalClockwiseStartAngle = -math.pi / 2;

  final String id;
  final Size viewport;
  final Offset center;
  final double faceRadius;
  final double trackRadius;
  final double trackWidth;
  final Color trackShadowColor;
  final List<Color> trackGradientColors;
  final List<double> trackGradientStops;
  final Color trackGlossColor;
  final double trackGlossFraction;
  final Offset faceShadowOffset;
  final Offset groundShadowOffset;
  final Size groundShadowSize;

  double get capRadius => trackWidth / 2;

  /// Canonical Canvas angle for the circular Budget scale. The seam is
  /// exactly twelve o'clock; positive Canvas angle advances clockwise.
  double angleForRatio(double ratio) =>
      canonicalClockwiseStartAngle + math.pi * 2 * ratio.clamp(0.0, 1.0);

  /// The one circular ratio coordinate for every scope renderer. Canvas Y
  /// increases downward, so the positive sweep is the authored clockwise
  /// Budget direction.
  Offset pointForRatio(double ratio) {
    final angle = angleForRatio(ratio);
    return center +
        Offset(math.cos(angle) * trackRadius, math.sin(angle) * trackRadius);
  }
}

/// Fill strategies over the one [BudgetProgressRingGeometry]. Every strategy
/// keeps the source ring's dimensions and 3D material; only its derived data
/// projection changes.
enum BudgetLimitProgressChromeGeometry {
  circular,
  verticalProjection,
  annualSegments,
  typicalMarker,
}

/// YEAR cells are complete, fixed angular capsules. A cell's colour conveys
/// the month's health; it is never a partial mini progress bar.
enum BudgetProgressRingAnnualSegmentHealth { neutral, healthy, warning, danger }

/// Resolves YEAR's fixed visual cell from the common raw-ratio health rule.
/// The normal Month category accent is intentionally translated to the fixed
/// annual health green here; all other scopes retain their own material rule.
abstract final class BudgetProgressRingAnnualSegmentHealthResolver {
  static BudgetProgressRingAnnualSegmentHealth resolve({
    required int actualScaled100,
    required int? resolvedMonthlyLimitScaled100,
    required bool isFuture,
  }) {
    if (isFuture ||
        resolvedMonthlyLimitScaled100 == null ||
        resolvedMonthlyLimitScaled100 <= 0) {
      return BudgetProgressRingAnnualSegmentHealth.neutral;
    }
    return switch (BudgetProgressHealthResolver.resolve(
      isAvailable: true,
      rawRatio: actualScaled100 / resolvedMonthlyLimitScaled100,
    )) {
      BudgetProgressHealth.targetAccent =>
        BudgetProgressRingAnnualSegmentHealth.healthy,
      BudgetProgressHealth.warning =>
        BudgetProgressRingAnnualSegmentHealth.warning,
      BudgetProgressHealth.danger =>
        BudgetProgressRingAnnualSegmentHealth.danger,
      BudgetProgressHealth.unavailable =>
        BudgetProgressRingAnnualSegmentHealth.neutral,
    };
  }
}

@immutable
final class BudgetProgressRingAnnualSegment {
  const BudgetProgressRingAnnualSegment({required this.health});

  /// Every calendar month owns one exact angular slot. This remains separate
  /// from the painted sweep so DEC→JAN is exactly the same as every other
  /// boundary instead of accumulating prior floating-point sweep lengths.
  static const slotSweepRadians = math.pi * 2 / 12;

  /// Positive empty distance between the two *painted* round caps in source
  /// space. At the selected 112px ring scale, eight source units remain a
  /// clearly visible, equal separator without making any month a progress bar.
  static const annualSegmentVisibleGap = 8.0;

  /// Two round caps consume one full stroke width along the arc tangent. The
  /// centreline gap therefore needs that width plus the desired visible void.
  static const centerlineGapLength =
      BudgetProgressRingGeometry.sourceTrackWidth + annualSegmentVisibleGap;
  static const centerlineGapRadians =
      centerlineGapLength / BudgetProgressRingGeometry.sourceTrackRadius;
  static const fixedSweepRadians = slotSweepRadians - centerlineGapRadians;
  static const paintedVisibleGapLength =
      centerlineGapLength - BudgetProgressRingGeometry.sourceTrackWidth;

  static double startAngleFor({
    required double canonicalStartAngle,
    required int monthIndex,
  }) {
    if (monthIndex < 0 || monthIndex >= 12) {
      throw ArgumentError.value(monthIndex, 'monthIndex', 'Expected 0..11.');
    }
    return canonicalStartAngle +
        monthIndex * slotSweepRadians +
        centerlineGapRadians / 2;
  }

  final BudgetProgressRingAnnualSegmentHealth health;

  @override
  bool operator ==(Object other) =>
      other is BudgetProgressRingAnnualSegment && other.health == health;

  @override
  int get hashCode => health.hashCode;
}

/// 3D YEAR material with a semantic health hue that cannot inherit the
/// category-arc hue rotation. Highlight and depth only adjust lightness.
@immutable
final class BudgetProgressRingAnnualHealthMaterial {
  const BudgetProgressRingAnnualHealthMaterial._({
    required this.base,
    required this.start,
    required this.middle,
    required this.end,
  });

  factory BudgetProgressRingAnnualHealthMaterial.forHealth(
    BudgetProgressRingAnnualSegmentHealth health, {
    Color healthyColor = FluviVisualTokens.budgetProgressHealthy,
  }) {
    final base = switch (health) {
      BudgetProgressRingAnnualSegmentHealth.healthy => healthyColor,
      BudgetProgressRingAnnualSegmentHealth.warning =>
        FluviVisualTokens.budgetProgressWarning,
      BudgetProgressRingAnnualSegmentHealth.danger =>
        FluviVisualTokens.budgetProgressDanger,
      BudgetProgressRingAnnualSegmentHealth.neutral => const Color(0xFFC5BDCF),
    };
    final hsl = HSLColor.fromColor(base);
    return BudgetProgressRingAnnualHealthMaterial._(
      base: base,
      start: hsl
          .withLightness((hsl.lightness + .18).clamp(0, 1).toDouble())
          .toColor(),
      middle: base,
      end: hsl
          .withLightness((hsl.lightness - .20).clamp(0, 1).toDouble())
          .toColor(),
    );
  }

  final Color base;
  final Color start;
  final Color middle;
  final Color end;

  /// Public source-contract assertion used by the regression suite.
  bool get usesCategoryHueShift => false;
}

/// One marker derives both sphere centres from the shared source ring. It is
/// deliberately a visual reference only: pace semantics remain in the
/// prepared DAY analysis.
@immutable
final class BudgetProgressRingDayPaceMarker {
  const BudgetProgressRingDayPaceMarker(this.center);

  final Offset center;
}

@immutable
final class BudgetProgressRingDayPaceMarkers {
  const BudgetProgressRingDayPaceMarkers._({
    required this.left,
    required this.right,
  });

  static const _breakEvenGaugeRatio = .75;
  static const markerRadius = 9.0;

  factory BudgetProgressRingDayPaceMarkers.resolve({
    required BudgetProgressRingGeometry geometry,
  }) {
    final trackRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.trackRadius,
    );
    final y = trackRect.bottom - trackRect.height * _breakEvenGaugeRatio;
    final dy = y - geometry.center.dy;
    final xOffset = math.sqrt(
      math.max(0, geometry.trackRadius * geometry.trackRadius - dy * dy),
    );
    return BudgetProgressRingDayPaceMarkers._(
      left: BudgetProgressRingDayPaceMarker(
        Offset(geometry.center.dx - xOffset, y),
      ),
      right: BudgetProgressRingDayPaceMarker(
        Offset(geometry.center.dx + xOffset, y),
      ),
    );
  }

  final BudgetProgressRingDayPaceMarker left;
  final BudgetProgressRingDayPaceMarker right;

  String get sourceGeometryId => BudgetProgressRingGeometry.sourceId;
  String get materialId => BudgetProgressRingSphereMaterial.sourceId;
  double get breakEvenGaugeRatio => _breakEvenGaugeRatio;
}

/// The one 3D sphere material language used by DAY and SUM reference marks.
///
/// DAY preserves its accepted neutral material. SUM changes only the semantic
/// base hue through [forHealthColor], keeping the same highlight/body/depth
/// construction and sphere geometry rather than introducing another marker
/// asset.
@immutable
final class BudgetProgressRingSphereMaterial {
  const BudgetProgressRingSphereMaterial._({
    required this.base,
    required this.highlight,
    required this.body,
    required this.depth,
  });

  static const sourceId = 'fluvi-selected-budget-sphere-marker-v1';
  static const defaultBody = Color(0xFFB3A8C4);
  static const defaultDepth = Color(0xFF655977);
  static const defaultHighlight = Color(0xD9FFFFFF);

  static const day = BudgetProgressRingSphereMaterial._(
    base: defaultBody,
    highlight: defaultHighlight,
    body: defaultBody,
    depth: defaultDepth,
  );

  static final white = BudgetProgressRingSphereMaterial.forHealthColor(
    const Color(0xfff8f6ff),
  );

  factory BudgetProgressRingSphereMaterial.forHealthColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    return BudgetProgressRingSphereMaterial._(
      base: base,
      highlight: hsl
          .withLightness((hsl.lightness + .26).clamp(0, 1).toDouble())
          .toColor()
          .withValues(alpha: .90),
      body: base,
      depth: hsl
          .withLightness((hsl.lightness - .24).clamp(0, 1).toDouble())
          .toColor(),
    );
  }

  final Color base;
  final Color highlight;
  final Color body;
  final Color depth;

  String get sourceGeometryId => BudgetProgressRingSphereMaterial.sourceId;
  bool get usesCategoryHueShift => false;
}

/// One semantic SUM reference point. Its ratio is measured from the shared
/// canonical top origin and advances clockwise in Canvas angle space.
@immutable
final class BudgetProgressRingSumScaleMarker {
  const BudgetProgressRingSumScaleMarker({
    required this.ratio,
    required this.center,
    required this.material,
  });

  final double ratio;
  final Offset center;
  final BudgetProgressRingSphereMaterial material;
}

/// Static SUM scale geometry. The short SUM arc remains the selected current
/// value marker; these three spheres are persistent reference points only.
abstract final class BudgetProgressRingSumScaleMarkers {
  static const ratios = <double>[.50, .75, .90];

  static List<BudgetProgressRingSumScaleMarker> resolve({
    required BudgetProgressRingGeometry geometry,
    Color healthyColor = FluviVisualTokens.budgetProgressHealthy,
  }) {
    const colors = <Color>[
      FluviVisualTokens.budgetProgressHealthy,
      FluviVisualTokens.budgetProgressWarning,
      FluviVisualTokens.budgetProgressDanger,
    ];
    return List<BudgetProgressRingSumScaleMarker>.unmodifiable(
      List<BudgetProgressRingSumScaleMarker>.generate(ratios.length, (index) {
        final ratio = ratios[index];
        return BudgetProgressRingSumScaleMarker(
          ratio: ratio,
          center: geometry.pointForRatio(ratio),
          material: BudgetProgressRingSphereMaterial.forHealthColor(
            index == 0 ? healthyColor : colors[index],
          ),
        );
      }),
    );
  }
}

/// Fixed white semantic boundaries for the two coloured SUM-scale styles.
/// They share the exact circle coordinate/material authority with the DAY and
/// current-SUM spheres; only the ratios and neutral material differ.
abstract final class BudgetProgressRingSumColoredScaleMarkers {
  static const List<double> boundaryRatios = <double>[.75, .90];

  static List<BudgetProgressRingSumScaleMarker> resolve({
    required BudgetProgressRingGeometry geometry,
  }) => List<BudgetProgressRingSumScaleMarker>.unmodifiable(
    <BudgetProgressRingSumScaleMarker>[
      for (final ratio in boundaryRatios)
        BudgetProgressRingSumScaleMarker(
          ratio: ratio,
          center: geometry.pointForRatio(ratio),
          material: BudgetProgressRingSphereMaterial.white,
        ),
    ],
  );
}

/// One visual blend policy for the circular SUM health scale. Business
/// thresholds remain exactly .75/.90; only this named half-window controls
/// the authored smooth hue transition around them.
abstract final class BudgetProgressRingSumHealthScale {
  static const healthyWarningBoundary = .75;
  static const warningDangerBoundary = .90;
  static const transitionHalfWidth = .035;

  static SweepGradient gradient({
    required Color healthy,
    required double startAngle,
  }) {
    final warning = FluviVisualTokens.budgetProgressWarning;
    final danger = FluviVisualTokens.budgetProgressDanger;
    return SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + math.pi * 2,
      colors: <Color>[
        healthy,
        Color.lerp(healthy, warning, .5)!,
        warning,
        Color.lerp(warning, danger, .5)!,
        danger,
        danger,
      ],
      stops: const <double>[
        0,
        healthyWarningBoundary - transitionHalfWidth,
        healthyWarningBoundary + transitionHalfWidth,
        warningDangerBoundary - transitionHalfWidth,
        warningDangerBoundary + transitionHalfWidth,
        1,
      ],
    );
  }

  /// Pure color oracle used by tests/diagnostics. This is not a painter hot
  /// path; Canvas uses [gradient] directly.
  static Color colorForRatio({required double ratio, required Color healthy}) {
    final value = ratio.clamp(0.0, 1.0).toDouble();
    final warning = FluviVisualTokens.budgetProgressWarning;
    final danger = FluviVisualTokens.budgetProgressDanger;
    final firstStart = healthyWarningBoundary - transitionHalfWidth;
    final firstEnd = healthyWarningBoundary + transitionHalfWidth;
    final secondStart = warningDangerBoundary - transitionHalfWidth;
    final secondEnd = warningDangerBoundary + transitionHalfWidth;
    if (value <= firstStart) return healthy;
    if (value < firstEnd) {
      return Color.lerp(
        healthy,
        warning,
        (value - firstStart) / (firstEnd - firstStart),
      )!;
    }
    if (value <= secondStart) return warning;
    if (value < secondEnd) {
      return Color.lerp(
        warning,
        danger,
        (value - secondStart) / (secondEnd - secondStart),
      )!;
    }
    return danger;
  }
}

/// One atomic Budget selection value. It carries both the exact semantic
/// target and the visual arc inputs, so an old target's scalar cannot become a
/// new centre target's ring during a carousel handoff.
@immutable
final class BudgetCategoryAvatarSelectedLimitVisualState {
  const BudgetCategoryAvatarSelectedLimitVisualState._({
    required this.targetHandle,
    required this.limitKey,
    required this.displayNumeratorScaled100,
    required this.displayDenominatorScaled100,
    required this.hasPositiveLimit,
    required this.rawProgress,
    required this.visualProgress,
    required this.chromeGeometry,
    required this.breakEvenGaugeRatio,
    required this.annualSegments,
    required this.typicalMarkerPosition,
  });

  factory BudgetCategoryAvatarSelectedLimitVisualState.unavailable({
    required int targetHandle,
  }) => BudgetCategoryAvatarSelectedLimitVisualState._(
    targetHandle: targetHandle,
    limitKey: null,
    displayNumeratorScaled100: null,
    displayDenominatorScaled100: null,
    hasPositiveLimit: false,
    rawProgress: 0,
    visualProgress: 0,
    chromeGeometry: BudgetLimitProgressChromeGeometry.circular,
    breakEvenGaugeRatio: null,
    annualSegments: const <BudgetProgressRingAnnualSegment>[],
    typicalMarkerPosition: null,
  );

  factory BudgetCategoryAvatarSelectedLimitVisualState.available({
    required int targetHandle,
    required FinancialLimitKey? limitKey,
    required int displayNumeratorScaled100,
    required int? displayDenominatorScaled100,
    double? rawProgressOverride,
    BudgetLimitProgressChromeGeometry chromeGeometry =
        BudgetLimitProgressChromeGeometry.circular,
    List<BudgetProgressRingAnnualSegment> annualSegments =
        const <BudgetProgressRingAnnualSegment>[],
    double? typicalMarkerPosition,
  }) {
    final hasPositiveLimit =
        displayDenominatorScaled100 != null && displayDenominatorScaled100 > 0;
    final projection = BudgetLimitProgressProjection.fromAmounts(
      actualScaled100: displayNumeratorScaled100,
      limitScaled100: displayDenominatorScaled100,
    );
    final rawProgress = rawProgressOverride ?? projection.rawProgress;
    final visualProgress =
        chromeGeometry == BudgetLimitProgressChromeGeometry.verticalProjection
        ? (rawProgress * .75).clamp(0.0, 1.0).toDouble()
        : BudgetLimitProgressProjection.boundedVisualProgress(rawProgress);
    return BudgetCategoryAvatarSelectedLimitVisualState._(
      targetHandle: targetHandle,
      limitKey: limitKey,
      displayNumeratorScaled100: displayNumeratorScaled100,
      displayDenominatorScaled100: displayDenominatorScaled100,
      hasPositiveLimit: hasPositiveLimit,
      rawProgress: rawProgress,
      visualProgress: visualProgress,
      chromeGeometry: chromeGeometry,
      breakEvenGaugeRatio:
          chromeGeometry == BudgetLimitProgressChromeGeometry.verticalProjection
          ? .75
          : null,
      annualSegments: List<BudgetProgressRingAnnualSegment>.unmodifiable(
        annualSegments,
      ),
      typicalMarkerPosition: typicalMarkerPosition,
    );
  }

  final int targetHandle;
  final FinancialLimitKey? limitKey;
  final int? displayNumeratorScaled100;
  final int? displayDenominatorScaled100;
  final bool hasPositiveLimit;
  final double rawProgress;
  final double visualProgress;
  final BudgetLimitProgressChromeGeometry chromeGeometry;
  final double? breakEvenGaugeRatio;
  final List<BudgetProgressRingAnnualSegment> annualSegments;
  final double? typicalMarkerPosition;

  bool get paintsProgressChrome => hasPositiveLimit;
  String get sourceGeometryId => BudgetProgressRingGeometry.sourceId;

  bool sameVisualAs(BudgetCategoryAvatarSelectedLimitVisualState other) =>
      targetHandle == other.targetHandle &&
      limitKey == other.limitKey &&
      displayNumeratorScaled100 == other.displayNumeratorScaled100 &&
      displayDenominatorScaled100 == other.displayDenominatorScaled100 &&
      hasPositiveLimit == other.hasPositiveLimit &&
      rawProgress == other.rawProgress &&
      visualProgress == other.visualProgress &&
      chromeGeometry == other.chromeGeometry &&
      breakEvenGaugeRatio == other.breakEvenGaugeRatio &&
      listEquals(annualSegments, other.annualSegments) &&
      typicalMarkerPosition == other.typicalMarkerPosition;
}

/// The approved avatar-artwork compositions in the Budget rail.
///
/// The semantic center is nested inside a selection shell that already owns a
/// projected cast shadow. Its core therefore deliberately omits the avatar's
/// own floor/blob. A selected target without a positive limit instead uses a
/// centred viewport with the exact authored floor shadow restored. Side
/// avatars retain the complete normal-rail artwork.
enum BudgetCategoryAvatarVariant { normalRail, centeredCore, centeredShadowed }

/// Optional hue-ramp authority for non-category Budget targets.
///
/// The ramp is deliberately projected into authored sphere light/main/body/
/// depth tones by [BudgetCategoryAvatarSvg]. Passing the brand ramp directly
/// to radial-gradient stops makes an aggregate look flat because a cyan or
/// purple neighbour is not intrinsically a highlight or a depth tone.
/// Ordinary categories retain their canonical category-colour rendering.
@immutable
final class BudgetCategoryAvatarFaceGradient {
  const BudgetCategoryAvatarFaceGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  final Color start;
  final Color middle;
  final Color end;
}

/// The source-authored Budget avatar body from the local visual reference's
/// `BudgetV2FluviSvg.avatarDisc` contract.
///
/// The body, its internal highlight/depth, and the lower coloured floor
/// shadow are one SVG artwork for side avatars. The centred core deliberately
/// omits only its floor/blob because the outer selection shell owns the one
/// selected-state cast shadow. [icon] is already decoded by
/// [PreparedVectorAssetAtlas].
final class BudgetCategoryAvatarArtwork extends StatelessWidget {
  const BudgetCategoryAvatarArtwork({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.svgSource,
    required this.selected,
    this.centeredCoreSvgSource,
    this.centeredShadowedSvgSource,
    this.selectedTargetHandle,
    this.selectedLimitVisualListenable,
    this.selectedLiveSelectionListenable,
    this.selectedLimitVisualForLiveSelection,
    this.onSelectionVisualIdentityMismatch,
    super.key,
  });

  final Color color;
  final PreparedVectorPicture icon;
  final String semanticsLabel;

  /// The side-avatar artwork, built when the immutable category presentation
  /// collection changes, never from a carousel tick. `flutter_svg` caches the
  /// parsed source by this value.
  final String svgSource;

  /// Prepared once alongside [svgSource]. It is selected only while the exact
  /// centre target has a positive limit and the outer chrome owns the sole
  /// selected-state projected shadow.
  final String? centeredCoreSvgSource;

  /// Prepared once alongside [svgSource]. It retains the same authored floor
  /// shadow as the normal rail artwork, but uses the centred source viewport
  /// so a no-limit centre target cannot jump vertically.
  final String? centeredShadowedSvgSource;
  final bool selected;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;

  /// The application-level live selection is authoritative. Keeping this
  /// listenable direct avoids a rail-local copied value during target handoff.
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return _BudgetCategoryAvatarSelectedComposition(
        color: color,
        icon: icon,
        semanticsLabel: semanticsLabel,
        centeredCoreSvgSource: centeredCoreSvgSource ?? svgSource,
        centeredShadowedSvgSource: centeredShadowedSvgSource ?? svgSource,
        selectedTargetHandle: selectedTargetHandle,
        selectedLimitVisualListenable: selectedLimitVisualListenable,
        selectedLiveSelectionListenable: selectedLiveSelectionListenable,
        selectedLimitVisualForLiveSelection:
            selectedLimitVisualForLiveSelection,
        onSelectionVisualIdentityMismatch: onSelectionVisualIdentityMismatch,
      );
    }
    return SizedBox.square(
      dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
      child: _BudgetCategoryAvatarDisc(
        source: svgSource,
        icon: icon,
        semanticLabel: semanticsLabel,
        canvasSize: BudgetCategoryAvatarGeometry.avatarCanvasSize,
        iconSize: BudgetCategoryAvatarGeometry.glyphSize,
      ),
    );
  }
}

/// The selected cell keeps its static avatar body separate from the live
/// chrome painter. The state listens to the existing selection publication
/// only to switch body ownership at a positive-limit boundary; ordinary
/// progress ticks rebuild the narrow chrome lane alone.
final class _BudgetCategoryAvatarSelectedComposition extends StatefulWidget {
  const _BudgetCategoryAvatarSelectedComposition({
    required this.color,
    required this.icon,
    required this.semanticsLabel,
    required this.centeredCoreSvgSource,
    required this.centeredShadowedSvgSource,
    required this.selectedTargetHandle,
    required this.selectedLimitVisualListenable,
    required this.selectedLiveSelectionListenable,
    required this.selectedLimitVisualForLiveSelection,
    required this.onSelectionVisualIdentityMismatch,
  });

  final Color color;
  final PreparedVectorPicture icon;
  final String semanticsLabel;
  final String centeredCoreSvgSource;
  final String centeredShadowedSvgSource;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  State<_BudgetCategoryAvatarSelectedComposition> createState() =>
      _BudgetCategoryAvatarSelectedCompositionState();
}

final class _BudgetCategoryAvatarSelectedCompositionState
    extends State<_BudgetCategoryAvatarSelectedComposition> {
  late bool _usesCenteredCore;

  @override
  void initState() {
    super.initState();
    _usesCenteredCore = _usesCenteredCoreFor(_currentVisual());
    _currentVisualListenable?.addListener(_onVisualChanged);
  }

  @override
  void didUpdateWidget(
    covariant _BudgetCategoryAvatarSelectedComposition oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final oldListenable = _visualListenableOf(oldWidget);
    final nextListenable = _currentVisualListenable;
    if (!identical(oldListenable, nextListenable)) {
      oldListenable?.removeListener(_onVisualChanged);
      nextListenable?.addListener(_onVisualChanged);
    }
    _usesCenteredCore = _usesCenteredCoreFor(_currentVisual());
  }

  @override
  void dispose() {
    _currentVisualListenable?.removeListener(_onVisualChanged);
    super.dispose();
  }

  Listenable? get _currentVisualListenable => _visualListenableOf(widget);

  static Listenable? _visualListenableOf(
    _BudgetCategoryAvatarSelectedComposition candidate,
  ) =>
      candidate.selectedLiveSelectionListenable ??
      candidate.selectedLimitVisualListenable;

  BudgetCategoryAvatarSelectedLimitVisualState? _currentVisual() {
    final liveVisual = widget.selectedLimitVisualForLiveSelection;
    final visual = liveVisual == null
        ? widget.selectedLimitVisualListenable?.value
        : liveVisual();
    final targetHandle = widget.selectedTargetHandle;
    if (visual == null ||
        targetHandle == null ||
        visual.targetHandle != targetHandle) {
      return null;
    }
    return visual;
  }

  bool _usesCenteredCoreFor(
    BudgetCategoryAvatarSelectedLimitVisualState? visual,
  ) => visual?.paintsProgressChrome ?? false;

  void _onVisualChanged() {
    final next = _usesCenteredCoreFor(_currentVisual());
    if (next == _usesCenteredCore || !mounted) return;
    setState(() => _usesCenteredCore = next);
  }

  @override
  Widget build(BuildContext context) {
    final source = _usesCenteredCore
        ? widget.centeredCoreSvgSource
        : widget.centeredShadowedSvgSource;
    return SizedBox.square(
      dimension: BudgetCategoryAvatarGeometry.avatarCanvasSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          _BudgetCategoryAvatarSelectionChromeLayer(
            color: widget.color,
            selectedTargetHandle: widget.selectedTargetHandle,
            selectedLimitVisualListenable: widget.selectedLimitVisualListenable,
            selectedLiveSelectionListenable:
                widget.selectedLiveSelectionListenable,
            selectedLimitVisualForLiveSelection:
                widget.selectedLimitVisualForLiveSelection,
            onSelectionVisualIdentityMismatch:
                widget.onSelectionVisualIdentityMismatch,
          ),
          _BudgetCategoryAvatarDisc(
            source: source,
            icon: widget.icon,
            semanticLabel: widget.semanticsLabel,
            canvasSize: BudgetCategoryAvatarGeometry.avatarCanvasSize,
            iconSize: BudgetCategoryAvatarGeometry.glyphSize,
          ),
        ],
      ),
    );
  }
}

final class _BudgetCategoryAvatarSelectionChromeLayer extends StatelessWidget {
  const _BudgetCategoryAvatarSelectionChromeLayer({
    required this.color,
    required this.selectedTargetHandle,
    required this.selectedLimitVisualListenable,
    required this.selectedLiveSelectionListenable,
    required this.selectedLimitVisualForLiveSelection,
    required this.onSelectionVisualIdentityMismatch,
  });

  final Color color;
  final int? selectedTargetHandle;
  final ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable;
  final Listenable? selectedLiveSelectionListenable;
  final BudgetCategoryAvatarSelectedLimitVisualState Function()?
  selectedLimitVisualForLiveSelection;
  final VoidCallback? onSelectionVisualIdentityMismatch;

  @override
  Widget build(BuildContext context) {
    final targetHandle = selectedTargetHandle;
    if (targetHandle == null) return const SizedBox();
    Widget chromeForVisual(
      BudgetCategoryAvatarSelectedLimitVisualState visual,
    ) {
      if (visual.targetHandle != targetHandle) {
        onSelectionVisualIdentityMismatch?.call();
        return const SizedBox();
      }
      if (!visual.paintsProgressChrome) return const SizedBox();
      return OverflowBox(
        alignment: Alignment.center,
        minWidth: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        maxWidth: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        minHeight: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        maxHeight: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        child: BudgetCategoryAvatarSelectionChrome(
          key: const ValueKey('budget-category-avatar-selection-chrome'),
          categoryColor: color,
          progressColor: BudgetLimitProgressToneResolver.resolve(
            rawProgress: visual.rawProgress,
            targetAccent: color,
          ),
          sourceProgress: visual.visualProgress,
          geometry: visual.chromeGeometry,
          breakEvenGaugeRatio: visual.breakEvenGaugeRatio,
          annualSegments: visual.annualSegments,
          typicalMarkerPosition: visual.typicalMarkerPosition,
        ),
      );
    }

    final liveListenable = selectedLiveSelectionListenable;
    final visualForLiveSelection = selectedLimitVisualForLiveSelection;
    if (liveListenable != null && visualForLiveSelection != null) {
      return AnimatedBuilder(
        animation: liveListenable,
        builder: (context, child) => chromeForVisual(visualForLiveSelection()),
      );
    }
    final visualListenable = selectedLimitVisualListenable;
    if (visualListenable == null) return const SizedBox();
    return ValueListenableBuilder<BudgetCategoryAvatarSelectedLimitVisualState>(
      valueListenable: visualListenable,
      builder: (context, visual, child) => chromeForVisual(visual),
    );
  }
}

final class _BudgetCategoryAvatarDisc extends StatelessWidget {
  const _BudgetCategoryAvatarDisc({
    required this.source,
    required this.icon,
    required this.semanticLabel,
    required this.canvasSize,
    required this.iconSize,
  });

  final String source;
  final PreparedVectorPicture icon;
  final String semanticLabel;
  final double canvasSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: canvasSize,
    child: Semantics(
      image: true,
      label: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                source,
                fit: BoxFit.contain,
                clipBehavior: Clip.hardEdge,
              ),
            ),
          ),
          CategoryIconView(picture: icon, size: iconSize, color: Colors.white),
        ],
      ),
    ),
  );
}

/// The exact reference selection chrome around the centre core. It is kept
/// separate from the SVG avatar body so no Flutter shadow/gradient can be
/// mistaken for intrinsic category artwork.
final class BudgetCategoryAvatarSelectionChrome extends StatelessWidget {
  const BudgetCategoryAvatarSelectionChrome({
    required this.categoryColor,
    this.progressColor,
    this.sourceProgress = 0,
    this.geometry = BudgetLimitProgressChromeGeometry.circular,
    this.breakEvenGaugeRatio,
    this.annualSegments = const <BudgetProgressRingAnnualSegment>[],
    this.typicalMarkerPosition,
    super.key,
  }) : faceColor = BudgetCategoryAvatarGeometry.selectionFaceColor;

  final Color categoryColor;
  final Color? progressColor;
  final double sourceProgress;
  final BudgetLimitProgressChromeGeometry geometry;
  final double? breakEvenGaugeRatio;
  final List<BudgetProgressRingAnnualSegment> annualSegments;
  final double? typicalMarkerPosition;
  final Color faceColor;

  /// Exposed as a small visual contract so the shell and authored SVG floor
  /// can be regression-tested against the same hue authority.
  Color get castShadowColor =>
      BudgetCategoryAvatarPalette.shadowColor(categoryColor);

  /// The live paint contract, shared with [_SelectionChromePainter]. It keeps
  /// the exact continuous visual ratio testable without quantising it into a
  /// display percentage.
  static double sweepRadiansForVisualProgress(double visualProgress) =>
      math.pi *
      2 *
      BudgetLimitProgressProjection.boundedVisualProgress(visualProgress);

  /// YEAR uses its own semantic green/yellow/red material. It deliberately
  /// must not enter the category-arc hue transform used by the continuous
  /// MONTH/DAY/SUM strategies.
  bool get usesCategoryHueShift =>
      geometry != BudgetLimitProgressChromeGeometry.annualSegments;

  @override
  Widget build(BuildContext context) {
    final ringPresentation = BudgetRingPresentationScope.settingsOf(context);
    final gradient = usesCategoryHueShift
        ? _SelectionArcGradient.fromCategoryColor(
            progressColor ?? categoryColor,
          )
        : null;
    final shadowColor = castShadowColor;
    return SizedBox.square(
      key: const ValueKey('budget-category-avatar-selection-shell'),
      dimension: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size.square(
            BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
          ),
          painter: _SelectionChromePainter(
            ringGeometry: BudgetProgressRingGeometry.source,
            targetAccent: categoryColor,
            // The annual strategy never reads these fallback values. Passing
            // opaque neutral values makes the no-category-gradient contract
            // structural instead of merely relying on painter branch order.
            startColor: gradient?.start ?? const Color(0xFF000000),
            middleColor: gradient?.middle ?? const Color(0xFF000000),
            endColor: gradient?.end ?? const Color(0xFF000000),
            faceColor: faceColor,
            shadowColor: shadowColor,
            sourceProgress: sourceProgress,
            geometry: geometry,
            breakEvenGaugeRatio: breakEvenGaugeRatio,
            annualSegments: annualSegments,
            typicalMarkerPosition: typicalMarkerPosition,
            sumRingStyle: ringPresentation.sumRingStyle,
            healthyColorMode: ringPresentation.healthyColorMode,
          ),
        ),
      ),
    );
  }
}

final class _SelectionArcGradient {
  const _SelectionArcGradient({
    required this.start,
    required this.middle,
    required this.end,
  });

  factory _SelectionArcGradient.fromCategoryColor(Color start) {
    final hsl = HSLColor.fromColor(start);
    final end = hsl
        .withHue((hsl.hue - 46 + 360) % 360)
        .withSaturation((hsl.saturation * .9).clamp(0, 1).toDouble())
        .withLightness((hsl.lightness * .92).clamp(0, 1).toDouble())
        .toColor();
    return _SelectionArcGradient(
      start: start,
      middle: Color.lerp(start, end, .45)!,
      end: end,
    );
  }

  final Color start;
  final Color middle;
  final Color end;
}

/// Ported exactly from the reference's `BudgetV2LimitProgressPainter` for the
/// no-data centre state. It is selection chrome only; the category body's
/// authored depth and floor blob stay inside [BudgetCategoryAvatarSvg].
final class _SelectionChromePainter extends CustomPainter {
  const _SelectionChromePainter({
    required this.ringGeometry,
    required this.targetAccent,
    required this.startColor,
    required this.middleColor,
    required this.endColor,
    required this.faceColor,
    required this.shadowColor,
    required this.sourceProgress,
    required this.geometry,
    required this.breakEvenGaugeRatio,
    required this.annualSegments,
    required this.typicalMarkerPosition,
    required this.sumRingStyle,
    required this.healthyColorMode,
  });

  final BudgetProgressRingGeometry ringGeometry;
  final Color targetAccent;
  final Color startColor;
  final Color middleColor;
  final Color endColor;
  final Color faceColor;
  final Color shadowColor;
  final double sourceProgress;
  final BudgetLimitProgressChromeGeometry geometry;
  final double? breakEvenGaugeRatio;
  final List<BudgetProgressRingAnnualSegment> annualSegments;
  final double? typicalMarkerPosition;
  final BudgetSumRingStyle sumRingStyle;
  final BudgetHealthyColorMode healthyColorMode;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / ringGeometry.viewport.width,
      size.height / ringGeometry.viewport.height,
    );
    final offset = Offset(
      (size.width - ringGeometry.viewport.width * scale) / 2,
      (size.height - ringGeometry.viewport.height * scale) / 2,
    );
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..scale(scale);

    final trackRect = Rect.fromCircle(
      center: ringGeometry.center,
      radius: ringGeometry.trackRadius,
    );
    const startAngle = BudgetProgressRingGeometry.canonicalClockwiseStartAngle;
    final sweep =
        BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(
          sourceProgress,
        );

    canvas.drawOval(
      Rect.fromCenter(
        center: ringGeometry.center + ringGeometry.groundShadowOffset,
        width: ringGeometry.groundShadowSize.width,
        height: ringGeometry.groundShadowSize.height,
      ),
      Paint()
        ..color = shadowColor.withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      ringGeometry.center + ringGeometry.faceShadowOffset,
      ringGeometry.faceRadius,
      Paint()
        ..color = shadowColor.withValues(alpha: .20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final faceRect = Rect.fromCircle(
      center: ringGeometry.center,
      radius: ringGeometry.faceRadius,
    );
    canvas.drawCircle(
      ringGeometry.center,
      ringGeometry.faceRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.32, -.44),
          radius: .78,
          colors: <Color>[
            faceColor,
            const Color(0xfffbf9ff),
            const Color(0xffefeaf8),
          ],
          stops: const <double>[0, .48, 1],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      ringGeometry.center,
      ringGeometry.faceRadius,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final shellHighlight = Path()
      ..moveTo(72, 86)
      ..cubicTo(114, 48, 189, 42, 236, 84);
    canvas.drawPath(
      shellHighlight,
      Paint()
        ..color = const Color(0x8CFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
    );

    _paintRingTrack(canvas, trackRect, startAngle);
    switch (geometry) {
      case BudgetLimitProgressChromeGeometry.circular:
        _paintActiveArc(canvas, trackRect, startAngle, sweep);
      case BudgetLimitProgressChromeGeometry.verticalProjection:
        _paintDayPaceRing(canvas, trackRect);
      case BudgetLimitProgressChromeGeometry.annualSegments:
        _paintAnnualSegments(canvas, trackRect, startAngle);
      case BudgetLimitProgressChromeGeometry.typicalMarker:
        _paintTypicalMarker(canvas, trackRect);
    }
    canvas.restore();
  }

  Color get _healthyColor => BudgetHealthyVisualColorResolver.resolve(
    mode: healthyColorMode,
    targetAccent: targetAccent,
    fixedGreen: FluviVisualTokens.budgetProgressHealthy,
  );

  void _paintRingTrack(Canvas canvas, Rect trackRect, double startAngle) {
    final usesColoredSumScale =
        geometry == BudgetLimitProgressChromeGeometry.typicalMarker &&
        sumRingStyle != BudgetSumRingStyle.current;
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..color = ringGeometry.trackShadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringGeometry.trackWidth + 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..shader =
            (usesColoredSumScale
                    ? _sumScaleGradient(startAngle)
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: ringGeometry.trackGradientColors,
                        stops: ringGeometry.trackGradientStops,
                      ))
                .createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringGeometry.trackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      math.pi * 2 * ringGeometry.trackGlossFraction,
      false,
      Paint()
        ..color = ringGeometry.trackGlossColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  Gradient _sumScaleGradient(double startAngle) {
    return BudgetProgressRingSumHealthScale.gradient(
      healthy: _healthyColor,
      startAngle: startAngle,
    );
  }

  void _paintActiveArc(
    Canvas canvas,
    Rect trackRect,
    double startAngle,
    double sweep,
  ) {
    _paintActiveArcWithColors(
      canvas,
      trackRect,
      startAngle,
      sweep,
      startColor,
      middleColor,
      endColor,
    );
  }

  void _paintActiveArcWithColors(
    Canvas canvas,
    Rect trackRect,
    double startAngle,
    double sweep,
    Color arcStart,
    Color arcMiddle,
    Color arcEnd,
  ) {
    if (sweep <= 0) return;
    canvas.drawArc(
      trackRect.shift(const Offset(0, 5)),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = arcEnd.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringGeometry.trackWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      sweep,
      false,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[arcStart, arcMiddle, arcEnd],
          stops: const <double>[0, .45, 1],
        ).createShader(trackRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringGeometry.trackWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      trackRect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = const Color(0x3DFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintDayPaceRing(Canvas canvas, Rect trackRect) {
    // Mapping a bottom-to-top gauge height to the lower circular arc preserves
    // the approved ring track, its gradient and rounded active endpoint. At
    // 50% the lower semicircle is filled; at 100% the identical ring is full.
    final fill = sourceProgress.clamp(0.0, 1.0).toDouble();
    final cutoff = 1 - fill * 2;
    final startAngle = math.asin(cutoff.clamp(-1.0, 1.0).toDouble());
    final sweep = math.pi - 2 * startAngle;
    _paintActiveArc(canvas, trackRect, startAngle, sweep);
    if (breakEvenGaugeRatio != null) {
      final markers = BudgetProgressRingDayPaceMarkers.resolve(
        geometry: ringGeometry,
      );
      _paintSphere(
        canvas,
        center: markers.left.center,
        material: BudgetProgressRingSphereMaterial.day,
      );
      _paintSphere(
        canvas,
        center: markers.right.center,
        material: BudgetProgressRingSphereMaterial.day,
      );
    }
  }

  void _paintSphere(
    Canvas canvas, {
    required Offset center,
    required BudgetProgressRingSphereMaterial material,
  }) {
    final bodyRect = Rect.fromCircle(
      center: center,
      radius: BudgetProgressRingDayPaceMarkers.markerRadius,
    );
    canvas.drawCircle(
      center + const Offset(0, 2),
      BudgetProgressRingDayPaceMarkers.markerRadius,
      Paint()
        ..color = material.depth.withValues(alpha: .28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(
      center,
      BudgetProgressRingDayPaceMarkers.markerRadius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-.35, -.4),
          radius: .9,
          colors: <Color>[material.highlight, material.body, material.depth],
          stops: <double>[0, .42, 1],
        ).createShader(bodyRect),
    );
    canvas.drawCircle(
      center + const Offset(-2.5, -3),
      2.2,
      Paint()..color = material.highlight,
    );
  }

  void _paintAnnualSegments(Canvas canvas, Rect trackRect, double startAngle) {
    if (annualSegments.length != 12) return;
    for (var index = 0; index < annualSegments.length; index += 1) {
      final segment = annualSegments[index];
      final sectionStart = BudgetProgressRingAnnualSegment.startAngleFor(
        canonicalStartAngle: startAngle,
        monthIndex: index,
      );
      final material = BudgetProgressRingAnnualHealthMaterial.forHealth(
        segment.health,
        healthyColor: _healthyColor,
      );
      _paintActiveArcWithColors(
        canvas,
        trackRect,
        sectionStart,
        BudgetProgressRingAnnualSegment.fixedSweepRadians,
        material.start,
        material.middle,
        material.end,
      );
    }
  }

  void _paintTypicalMarker(Canvas canvas, Rect trackRect) {
    if (sumRingStyle != BudgetSumRingStyle.current) {
      _paintColoredSumMarker(canvas, trackRect);
      return;
    }
    final rawPosition = typicalMarkerPosition;
    if (rawPosition != null) {
      const markerSweep = math.pi * 2 * .055;
      final position = rawPosition.clamp(0.0, 1.0).toDouble();
      // The short current marker is centred on its financial coordinate. In
      // particular ratio 1 wraps back to the twelve-o'clock seam instead of
      // stopping a marker-width early on the danger side.
      final markerStart =
          ringGeometry.angleForRatio(position) - markerSweep / 2;
      _paintActiveArc(canvas, trackRect, markerStart, markerSweep);
    }
    // The current short arc remains the selected typical value. Reference
    // scale points intentionally paint after it so their fixed thresholds stay
    // legible when the current marker reaches one of them.
    for (final marker in BudgetProgressRingSumScaleMarkers.resolve(
      geometry: ringGeometry,
      healthyColor: _healthyColor,
    )) {
      _paintSphere(canvas, center: marker.center, material: marker.material);
    }
  }

  void _paintColoredSumMarker(Canvas canvas, Rect trackRect) {
    const markerSweep = math.pi * 2 * .055;
    final boundaries = BudgetProgressRingSumColoredScaleMarkers.resolve(
      geometry: ringGeometry,
    );
    final rawPosition = typicalMarkerPosition;
    if (rawPosition != null) {
      final position = rawPosition.clamp(0.0, 1.0).toDouble();
      final center = _centerForRatio(position);
      switch (sumRingStyle) {
        case BudgetSumRingStyle.current:
          break;
        case BudgetSumRingStyle.coloredScaleWhiteArc:
          _paintActiveArcWithColors(
            canvas,
            trackRect,
            ringGeometry.angleForRatio(position) - markerSweep / 2,
            markerSweep,
            BudgetProgressRingSphereMaterial.white.highlight,
            BudgetProgressRingSphereMaterial.white.body,
            BudgetProgressRingSphereMaterial.white.depth,
          );
        case BudgetSumRingStyle.coloredScaleMovingSphere:
          _paintSphere(
            canvas,
            center: center,
            material: BudgetProgressRingSphereMaterial.white,
          );
      }
    }
    // Boundary spheres deliberately paint last, like DAY's fixed reference
    // markers, so the financial-coordinate boundaries stay legible when the
    // current white indicator happens to coincide with one of them.
    for (final boundary in boundaries) {
      _paintSphere(
        canvas,
        center: boundary.center,
        material: boundary.material,
      );
    }
  }

  Offset _centerForRatio(double ratio) => ringGeometry.pointForRatio(ratio);

  @override
  bool shouldRepaint(covariant _SelectionChromePainter oldDelegate) =>
      oldDelegate.ringGeometry != ringGeometry ||
      oldDelegate.targetAccent != targetAccent ||
      oldDelegate.startColor != startColor ||
      oldDelegate.middleColor != middleColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.faceColor != faceColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.sourceProgress != sourceProgress ||
      oldDelegate.geometry != geometry ||
      oldDelegate.breakEvenGaugeRatio != breakEvenGaugeRatio ||
      !listEquals(oldDelegate.annualSegments, annualSegments) ||
      oldDelegate.typicalMarkerPosition != typicalMarkerPosition ||
      oldDelegate.sumRingStyle != sumRingStyle ||
      oldDelegate.healthyColorMode != healthyColorMode;
}

/// Literal source vector contract from the local visual reference.
/// `flutter_svg` does not support SVG filters, so retain the exact reference
/// compatibility transform: filters are removed but the approved authored
/// geometry and face gradient remain in the artwork.
abstract final class BudgetCategoryAvatarSvg {
  static String flutterRenderable(String source) => source
      .replaceAll(RegExp(r'<filter\b[^>]*>.*?</filter>', dotAll: true), '')
      .replaceAll(RegExp(r'\sfilter="url\(#[^)]+\)"'), '');

  static String avatarDisc(
    Color color,
    int identity, {
    BudgetCategoryAvatarVariant variant =
        BudgetCategoryAvatarVariant.normalRail,
    BudgetCategoryAvatarFaceGradient? faceGradient,
  }) {
    final hex = _hex(color).toLowerCase();
    final id = 'budgetAvatarDisc$identity';
    final gradient = faceGradient;
    final light = gradient == null
        ? _mixColor(hex, '#ffffff', .78)
        : _mixColor(_hex(gradient.start), '#ffffff', .78);
    final main = gradient == null
        ? _mixColor(hex, '#ffffff', .18)
        : _mixColor(_hex(gradient.middle), '#ffffff', .18);
    final body = gradient == null ? hex : _hex(gradient.middle);
    final depth = gradient == null
        ? _mixColor(hex, '#24113f', .32)
        : _mixColor(_hex(gradient.end), '#24113f', .32);
    final shadow = _hex(BudgetCategoryAvatarPalette.shadowColor(color));
    final viewport = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail =>
        '94 ${BudgetCategoryAvatarGeometry.normalRailViewportTop.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportWidth.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportHeight.toStringAsFixed(0)}',
      BudgetCategoryAvatarVariant.centeredCore ||
      BudgetCategoryAvatarVariant.centeredShadowed =>
        '94 ${BudgetCategoryAvatarGeometry.centeredCoreViewportTop.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportWidth.toStringAsFixed(0)} '
            '${BudgetCategoryAvatarGeometry.avatarArtworkViewportHeight.toStringAsFixed(0)}',
    };
    final variantName = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail => 'normal-rail',
      BudgetCategoryAvatarVariant.centeredCore => 'centered-core',
      BudgetCategoryAvatarVariant.centeredShadowed => 'centered-shadowed',
    };
    final shadowFilter =
        '<filter id="${id}Shadow" x="-70%" y="-70%" width="240%" height="240%" color-interpolation-filters="sRGB"><feGaussianBlur in="SourceAlpha" stdDeviation="18" result="b"/><feOffset in="b" dx="0" dy="22" result="o"/><feFlood flood-color="$shadow" flood-opacity=".28" result="c"/><feComposite in="c" in2="o" operator="in" result="s"/><feMerge><feMergeNode in="s"/><feMergeNode in="SourceGraphic"/></feMerge></filter>';
    final bodyFilter = ' filter="url(#${id}Shadow)"';
    final floorShadow = switch (variant) {
      BudgetCategoryAvatarVariant.normalRail ||
      BudgetCategoryAvatarVariant.centeredShadowed =>
        '<ellipse cx="256" cy="382" rx="126" ry="34" fill="$shadow" opacity=".10" filter="url(#${id}SoftBlur)"/>',
      BudgetCategoryAvatarVariant.centeredCore => '',
    };
    return '''<svg class="budget-fluvi-avatar-disc" viewBox="$viewport" preserveAspectRatio="xMidYMid meet" aria-hidden="true" focusable="false" data-fluvi-avatar-disc="true" data-budget-avatar-disc-variant="$variantName" data-budget-avatar-disc-color="$hex"><defs><radialGradient id="${id}Face" cx="32%" cy="26%" r="82%"><stop offset="0" stop-color="$light"/><stop offset=".38" stop-color="$main"/><stop offset=".72" stop-color="$body"/><stop offset="1" stop-color="$depth"/></radialGradient><linearGradient id="${id}Rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff" stop-opacity=".92"/><stop offset=".42" stop-color="#ffffff" stop-opacity=".38"/><stop offset="1" stop-color="$depth" stop-opacity=".55"/></linearGradient>$shadowFilter<filter id="${id}SoftBlur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter></defs><g data-fluvi-avatar-disc-body="true"$bodyFilter>$floorShadow<circle cx="256" cy="240" r="142" fill="url(#${id}Face)" stroke="url(#${id}Rim)" stroke-width="8"/></g></svg>''';
  }
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

String _mixColor(String source, String target, double amount) {
  final ratio = amount.clamp(0.0, 1.0);
  final channels = List<int>.generate(3, (index) {
    final start = int.parse(
      source.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    final end = int.parse(
      target.substring(1 + index * 2, 3 + index * 2),
      radix: 16,
    );
    return (start + (end - start) * ratio).round();
  });
  return '#${channels.map((channel) => channel.toRadixString(16).padLeft(2, '0')).join()}';
}

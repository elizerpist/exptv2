import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_catalog_ids.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';

/// The explicit semantic mode for the current Budget Header colour source.
///
/// This makes the live diagnostics distinguish the full canonical avatar
/// gradient used by no-limit targets from a positive-limit palette window.
enum BudgetHeaderPaletteMode { canonicalGradient, paletteWindow }

/// Immutable ten-slot scale derived once from a canonical category gradient.
///
/// The category catalog remains the visual authority. This type never stores
/// another ARGB table: it records one perceptually-generated representation of
/// the source identity for Header-window sampling and tuner preview.
@immutable
final class BudgetHeaderPalette {
  const BudgetHeaderPalette({
    required this.id,
    required this.canonicalColor,
    required this.slots,
  }) : assert(slots.length == slotCount);

  static const int slotCount = 10;

  /// Visible slot seven is the exact category identity.  The surrounding
  /// slots deliberately form a local sister-hue corridor, not a denser
  /// white-to-one-hue ramp.
  static const int canonicalSlotIndex = 6;

  final String id;
  final Color canonicalColor;
  final List<Color> slots;

  /// Samples the visible ten-slot scale continuously. Positions are expressed
  /// in the same 0…100 geometry used by the Color Lab movable window.
  Color samplePercent(double percent) {
    final normalized = (percent.isFinite ? percent : 0)
        .clamp(0.0, 100.0)
        .toDouble();
    final position = normalized / 100 * (slotCount - 1);
    final left = position.floor().clamp(0, slotCount - 1);
    final right = math.min(slotCount - 1, left + 1);
    return BudgetHeaderPaletteColorMath.mixPerceptual(
      slots[left],
      slots[right],
      position - left,
    );
  }

  double slotPositionForPercent(double percent) =>
      (percent.isFinite ? percent : 0).clamp(0.0, 100.0).toDouble() /
      100 *
      (slotCount - 1);
}

/// Bounded output of one semantic Budget palette-window projection.
@immutable
final class BudgetHeaderPaletteWindow {
  const BudgetHeaderPaletteWindow({
    required this.palette,
    required this.widthPercent,
    required this.centerPercent,
    required this.leftPercent,
    required this.rightPercent,
    required this.colorA,
    required this.colorB,
  });

  final BudgetHeaderPalette palette;
  final double widthPercent;
  final double centerPercent;
  final double leftPercent;
  final double rightPercent;
  final Color colorA;
  final Color colorB;

  double get leftSlotPosition => palette.slotPositionForPercent(leftPercent);
  double get rightSlotPosition => palette.slotPositionForPercent(rightPercent);
}

/// Bounded semantic snapshot for the existing FLOW/on-screen diagnostics
/// surface. It is built when the Budget selection, palette window or tuning
/// changes — never for a Header phase tick or painter invocation.
@immutable
final class BudgetHeaderDebugSnapshot {
  const BudgetHeaderDebugSnapshot({
    required this.targetHandle,
    required this.targetKind,
    required this.colorId,
    required this.paletteMode,
    required this.palette,
    required this.windowWidthPercent,
    required this.windowLeftPercent,
    required this.windowRightPercent,
    required this.colorA,
    required this.colorB,
    required this.opacity,
    required this.effectId,
    required this.settingsGeneration,
  });

  final int targetHandle;
  final String targetKind;
  final String colorId;
  final BudgetHeaderPaletteMode paletteMode;
  final BudgetHeaderPalette palette;
  final double windowWidthPercent;
  final double? windowLeftPercent;
  final double? windowRightPercent;
  final Color colorA;
  final Color colorB;
  final double opacity;
  final String effectId;
  final int settingsGeneration;

  String get slotsArgbSummary => palette.slots
      .map((color) => color.toARGB32().toRadixString(16).padLeft(8, '0'))
      .join(',');

  String get diagnosticPayload =>
      'targetHandle=$targetHandle '
      'targetKind=$targetKind '
      'colorId=$colorId '
      'paletteId=${palette.id} '
      'paletteMode=${paletteMode.name} '
      'slotCount=${palette.slots.length} '
      'slotsArgb=$slotsArgbSummary '
      'windowWidthPct=$windowWidthPercent '
      'windowLeft=${windowLeftPercent ?? '-'} '
      'windowRight=${windowRightPercent ?? '-'} '
      'leftSlotPosition=${windowLeftPercent == null ? '-' : palette.slotPositionForPercent(windowLeftPercent!).toStringAsFixed(3)} '
      'rightSlotPosition=${windowRightPercent == null ? '-' : palette.slotPositionForPercent(windowRightPercent!).toStringAsFixed(3)} '
      'colorAArgb=${colorA.toARGB32()} '
      'colorBArgb=${colorB.toARGB32()} '
      'opacity=$opacity '
      'effectId=$effectId '
      'settingsGeneration=$settingsGeneration';

  bool sameAs(BudgetHeaderDebugSnapshot other) =>
      targetHandle == other.targetHandle &&
      targetKind == other.targetKind &&
      colorId == other.colorId &&
      paletteMode == other.paletteMode &&
      palette.id == other.palette.id &&
      listEquals(palette.slots, other.palette.slots) &&
      windowWidthPercent == other.windowWidthPercent &&
      windowLeftPercent == other.windowLeftPercent &&
      windowRightPercent == other.windowRightPercent &&
      colorA == other.colorA &&
      colorB == other.colorB &&
      opacity == other.opacity &&
      effectId == other.effectId &&
      settingsGeneration == other.settingsGeneration;

  @override
  bool operator ==(Object other) =>
      other is BudgetHeaderDebugSnapshot && sameAs(other);

  @override
  int get hashCode => Object.hash(
    targetHandle,
    targetKind,
    colorId,
    paletteMode,
    palette.id,
    Object.hashAll(palette.slots),
    windowWidthPercent,
    windowLeftPercent,
    windowRightPercent,
    colorA,
    colorB,
    opacity,
    effectId,
    settingsGeneration,
  );
}

/// Pure geometric sampler for the finite Header window. It deliberately does
/// not know Budget accounting, targets, animation time, widgets, or paint.
abstract final class BudgetHeaderColorWindowSampler {
  static BudgetHeaderPaletteWindow sample({
    required BudgetHeaderPalette palette,
    required double rawProgress,
    required double windowWidthPercent,
  }) {
    final width = windowWidthPercent.clamp(10.0, 100.0).toDouble();
    final half = width / 2;
    final requestedCenter = rawProgress.isFinite ? rawProgress * 100 : 0.0;
    final center = requestedCenter.clamp(half, 100 - half).toDouble();
    final left = center - half;
    final right = left + width;
    return BudgetHeaderPaletteWindow(
      palette: palette,
      widthPercent: width,
      centerPercent: center,
      leftPercent: left,
      rightPercent: right,
      colorA: palette.samplePercent(left),
      colorB: palette.samplePercent(right),
    );
  }
}

/// Canonical, cached palette catalog for the 21 category visual identities.
///
/// It only consumes the already centralised [CategoryColorCatalog]. Arbitrary
/// gradients (the aggregate Budget visual) use the same generator and cache by
/// stable gradient id, so there is no second Budget-only colour table.
abstract final class BudgetHeaderPaletteCatalog {
  static final Map<String, BudgetHeaderPalette> _cache =
      <String, BudgetHeaderPalette>{};

  static final List<BudgetHeaderPalette> _allCategoryPalettes =
      List<BudgetHeaderPalette>.unmodifiable(<BudgetHeaderPalette>[
        for (final colorId in CategoryCatalogIds.colorIds)
          paletteForColorId(colorId),
      ]);

  static List<BudgetHeaderPalette> get allCategoryPalettes =>
      _allCategoryPalettes;

  static BudgetHeaderPalette paletteForColorId(String colorId) =>
      paletteForGradient(CategoryColorCatalog.resolve(colorId));

  static BudgetHeaderPalette paletteForGradient(
    CategoryGradientToken gradient,
  ) => _cache.putIfAbsent(
    gradient.id,
    () => BudgetHeaderPaletteGenerator.generate(gradient),
  );
}

/// Deterministic category-local micro-spectrum.
///
/// The canonical category catalog is the only semantic colour authority. Its
/// two cyclic neighbours contribute *hue direction* only, giving a palette a
/// useful local colour corridor without copying another category's RGB value.
/// This is intentionally piecewise OKLCH: a straight pale-to-canonical line
/// made ten technically distinct swatches but supplied too little information
/// to a 28% Header window.
abstract final class BudgetHeaderPaletteGenerator {
  static BudgetHeaderPalette generate(CategoryGradientToken gradient) {
    final canonical = gradient.middleColor;
    final source = BudgetHeaderPaletteColorMath._toOklch(canonical);
    final slots = List<Color>.filled(BudgetHeaderPalette.slotCount, canonical);
    final corridor = _HueCorridor.forGradient(gradient, source.hue);
    // Dark canonical families (blue through purple) need an intentionally
    // luminous lead transition.  Otherwise a 28% window can land entirely in
    // two neighbouring dark blue samples even when hue does move.  Warm/light
    // identities take the inverse, deeper lead path so the same short window
    // stays informative without turning the row into an unrelated rainbow.
    final darkFamily = source.lightness < .70;
    final vividTransitionLightness = darkFamily
        ? math.min(.84, source.lightness + .22)
        : .62;
    final chromaticTransitionLightness = darkFamily
        ? math.min(.88, source.lightness + .27)
        : math.max(.66, math.min(.78, source.lightness - .06));

    // Slot 1: the only genuinely neutral origin.  Slots 2–6 travel through a
    // lead sister hue toward identity; slots 8–10 travel toward the deep
    // sister.  L/C values are independently shaped so this is not a linear
    // OKLab interpolation disguised as a ten-slot palette.
    slots[0] = const Color(0xffffffff);
    slots[1] = _color(
      source,
      lightness: .972,
      chroma: math.max(.024, source.chroma * .15),
      hue: corridor.lead,
    );
    slots[2] = _color(
      source,
      lightness: .89,
      chroma: math.max(.065, source.chroma * .54),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.lead,
        .95,
      ),
    );
    slots[3] = _color(
      source,
      lightness: vividTransitionLightness,
      chroma: math.max(.09, source.chroma * .78),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.lead,
        .98,
      ),
    );
    slots[4] = _color(
      source,
      lightness: chromaticTransitionLightness,
      chroma: math.max(.095, source.chroma * .93),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.lead,
        .92,
      ),
    );
    slots[5] = _color(
      source,
      lightness: math.min(.94, source.lightness + .055),
      chroma: math.max(.10, source.chroma * 1.02),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.lead,
        .04,
      ),
    );
    // Exact source identity at visible slot seven prevents cumulative drift
    // between category swatches, avatar colours, and the Header palette.
    slots[BudgetHeaderPalette.canonicalSlotIndex] = canonical;
    slots[7] = _color(
      source,
      lightness: math.max(.20, source.lightness - .13),
      chroma: math.max(.10, source.chroma * 1.08),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.tail,
        .35,
      ),
    );
    slots[8] = _color(
      source,
      lightness: math.max(.15, source.lightness - .23),
      chroma: math.max(.105, source.chroma * 1.13),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.tail,
        .90,
      ),
    );
    slots[9] = _color(
      source,
      lightness: math.max(.10, source.lightness - .32),
      chroma: math.max(.10, source.chroma * 1.08),
      hue: BudgetHeaderPaletteColorMath.interpolateHue(
        source.hue,
        corridor.tail,
        1,
      ),
    );

    return BudgetHeaderPalette(
      id: gradient.id,
      canonicalColor: canonical,
      slots: List<Color>.unmodifiable(slots),
    );
  }

  static Color _color(
    _Oklch source, {
    required double lightness,
    required double chroma,
    required double hue,
  }) => BudgetHeaderPaletteColorMath._fromOklchGamutSafe(
    _Oklch(
      lightness: lightness.clamp(.08, .98).toDouble(),
      chroma: chroma.clamp(.0, .38).toDouble(),
      hue: hue,
    ),
  );
}

/// Hue guidance calculated from the existing cyclic `color_01…color_21`
/// order.  Two neighbours provide enough related movement (roughly 18–28° in
/// a normal family) without turning a category palette into a rainbow.
@immutable
final class _HueCorridor {
  const _HueCorridor({required this.lead, required this.tail});

  factory _HueCorridor.forGradient(
    CategoryGradientToken gradient,
    double canonicalHue,
  ) {
    final index = CategoryCatalogIds.colorIds.indexOf(gradient.id);
    if (index < 0) {
      return _HueCorridor(lead: canonicalHue, tail: canonicalHue);
    }
    Color neighbor(int offset) {
      final ringIndex =
          (index + offset + CategoryCatalogIds.colorIds.length * 2) %
          CategoryCatalogIds.colorIds.length;
      return CategoryColorCatalog.resolve(
        CategoryCatalogIds.colorIds[ringIndex],
      ).middleColor;
    }

    double corridorHue(int primaryOffset, int secondaryOffset) {
      final primaryHue = BudgetHeaderPaletteColorMath._toOklch(
        neighbor(primaryOffset),
      ).hue;
      final secondaryHue = BudgetHeaderPaletteColorMath._toOklch(
        neighbor(secondaryOffset),
      ).hue;
      // Prefer the adjacent family direction.  Some catalogue neighbours are
      // nearly identical after sRGB gamut mapping (notably parts of the
      // green/teal corridor); use the next cyclic guide only when the first
      // one would provide too little actual hue travel.
      final primaryTravel = BudgetHeaderPaletteColorMath.angularDistance(
        canonicalHue,
        primaryHue,
      );
      final neighborHue = primaryTravel >= .20 ? primaryHue : secondaryHue;
      return BudgetHeaderPaletteColorMath.moveHueToward(
        canonicalHue,
        neighborHue,
        // One cyclic neighbour provides a genuinely local sister hue.  The
        // second neighbour remains available to the catalog as a direction
        // oracle, but taking it directly made yellow/gold families jump into
        // green and violated their category identity.  0.52 rad is an upper
        // safety rail: after the piecewise slot interpolation and gamut map it
        // yields the intended roughly 18–28° visible local travel.
        maxTravelRadians: .52,
      );
    }

    return _HueCorridor(lead: corridorHue(-1, -2), tail: corridorHue(1, 2));
  }

  final double lead;
  final double tail;
}

/// Local OKLab conversion/mixing keeps Header colour derivation deterministic
/// without bringing a package into the app. Values are converted through
/// linear sRGB and are clamped only at the final display boundary.
abstract final class BudgetHeaderPaletteColorMath {
  static _Oklab _toOklab(Color color) {
    final red = _linear(color.r);
    final green = _linear(color.g);
    final blue = _linear(color.b);
    final l = .4122214708 * red + .5363325363 * green + .0514459929 * blue;
    final m = .2119034982 * red + .6806995451 * green + .1073969566 * blue;
    final s = .0883024619 * red + .2817188376 * green + .6299787005 * blue;
    final lRoot = math.pow(l, 1 / 3).toDouble();
    final mRoot = math.pow(m, 1 / 3).toDouble();
    final sRoot = math.pow(s, 1 / 3).toDouble();
    return _Oklab(
      lightness:
          .2104542553 * lRoot + .7936177850 * mRoot - .0040720468 * sRoot,
      a: 1.9779984951 * lRoot - 2.4285922050 * mRoot + .4505937099 * sRoot,
      b: .0259040371 * lRoot + .7827717662 * mRoot - .8086757660 * sRoot,
    );
  }

  static Color _fromOklab(_Oklab value) {
    final lRoot =
        value.lightness + .3963377774 * value.a + .2158037573 * value.b;
    final mRoot =
        value.lightness - .1055613458 * value.a - .0638541728 * value.b;
    final sRoot =
        value.lightness - .0894841775 * value.a - 1.2914855480 * value.b;
    final l = lRoot * lRoot * lRoot;
    final m = mRoot * mRoot * mRoot;
    final s = sRoot * sRoot * sRoot;
    final red = 4.0767416621 * l - 3.3077115913 * m + .2309699292 * s;
    final green = -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s;
    final blue = -.0041960863 * l - .7034186147 * m + 1.7076147010 * s;
    return Color.fromARGB(
      255,
      (_srgb(red).clamp(0.0, 1.0) * 255).round(),
      (_srgb(green).clamp(0.0, 1.0) * 255).round(),
      (_srgb(blue).clamp(0.0, 1.0) * 255).round(),
    );
  }

  static _Oklch _toOklch(Color color) => _toOklab(color).toOklch();

  /// Maps only chroma when an OKLCH point falls outside display sRGB.  This
  /// keeps its perceptual lightness and hue direction instead of hard RGB
  /// clipping a sister hue at a gamut edge.
  static Color _fromOklchGamutSafe(_Oklch value) {
    var low = 0.0;
    var high = value.chroma;
    var chosen = value;
    for (var iteration = 0; iteration < 14; iteration += 1) {
      final chroma = (low + high) / 2;
      final candidate = _Oklch(
        lightness: value.lightness,
        chroma: chroma,
        hue: value.hue,
      );
      if (_isDisplayGamut(candidate.toOklab())) {
        chosen = candidate;
        low = chroma;
      } else {
        high = chroma;
      }
    }
    return _fromOklab(chosen.toOklab());
  }

  static bool _isDisplayGamut(_Oklab value) {
    final lRoot =
        value.lightness + .3963377774 * value.a + .2158037573 * value.b;
    final mRoot =
        value.lightness - .1055613458 * value.a - .0638541728 * value.b;
    final sRoot =
        value.lightness - .0894841775 * value.a - 1.2914855480 * value.b;
    final l = lRoot * lRoot * lRoot;
    final m = mRoot * mRoot * mRoot;
    final s = sRoot * sRoot * sRoot;
    final red = 4.0767416621 * l - 3.3077115913 * m + .2309699292 * s;
    final green = -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s;
    final blue = -.0041960863 * l - .7034186147 * m + 1.7076147010 * s;
    const epsilon = 1e-6;
    return red >= -epsilon &&
        red <= 1 + epsilon &&
        green >= -epsilon &&
        green <= 1 + epsilon &&
        blue >= -epsilon &&
        blue <= 1 + epsilon;
  }

  static double interpolateHue(double from, double to, double amount) {
    final delta = _signedHueDelta(from, to);
    return from + delta * amount.clamp(0.0, 1.0).toDouble();
  }

  static double moveHueToward(
    double from,
    double to, {
    required double maxTravelRadians,
  }) {
    final delta = _signedHueDelta(from, to);
    return from + delta.clamp(-maxTravelRadians, maxTravelRadians).toDouble();
  }

  static double _signedHueDelta(double from, double to) {
    var delta = (to - from) % (math.pi * 2);
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;
    return delta;
  }

  static double angularDistance(double from, double to) =>
      _signedHueDelta(from, to).abs();

  static Color mixPerceptual(Color a, Color b, double amount) => _fromOklab(
    _Oklab.lerp(_toOklab(a), _toOklab(b), amount.clamp(0.0, 1.0).toDouble()),
  );

  static BudgetHeaderPalettePerceptualDelta measure(Color a, Color b) {
    final left = _toOklab(a).toOklch();
    final right = _toOklab(b).toOklch();
    final lightnessDelta = (left.lightness - right.lightness).abs();
    final chromaDelta = (left.chroma - right.chroma).abs();
    final hueDelta = left.chroma > .045 && right.chroma > .045
        ? angularDistance(left.hue, right.hue)
        : 0.0;
    final leftLab = left.toOklab();
    final rightLab = right.toOklab();
    final distance = math.sqrt(
      math.pow(leftLab.lightness - rightLab.lightness, 2) +
          math.pow(leftLab.a - rightLab.a, 2) +
          math.pow(leftLab.b - rightLab.b, 2),
    );
    return BudgetHeaderPalettePerceptualDelta(
      oklabDistance: distance,
      lightnessDelta: lightnessDelta,
      chromaDelta: chromaDelta,
      hueDeltaRadians: hueDelta,
    );
  }

  static double _linear(double channel) => channel <= .04045
      ? channel / 12.92
      : math.pow((channel + .055) / 1.055, 2.4).toDouble();

  static double _srgb(double channel) => channel <= .0031308
      ? channel * 12.92
      : 1.055 * math.pow(math.max(0, channel), 1 / 2.4).toDouble() - .055;
}

@immutable
final class BudgetHeaderPalettePerceptualDelta {
  const BudgetHeaderPalettePerceptualDelta({
    required this.oklabDistance,
    required this.lightnessDelta,
    required this.chromaDelta,
    required this.hueDeltaRadians,
  });

  final double oklabDistance;
  final double lightnessDelta;
  final double chromaDelta;
  final double hueDeltaRadians;

  double get hueDeltaDegrees => hueDeltaRadians * 180 / math.pi;
}

@immutable
final class _Oklab {
  const _Oklab({required this.lightness, required this.a, required this.b});

  final double lightness;
  final double a;
  final double b;

  _Oklch toOklch() => _Oklch(
    lightness: lightness,
    chroma: math.sqrt(a * a + b * b),
    hue: math.atan2(b, a),
  );

  static _Oklab lerp(_Oklab left, _Oklab right, double amount) => _Oklab(
    lightness: left.lightness + (right.lightness - left.lightness) * amount,
    a: left.a + (right.a - left.a) * amount,
    b: left.b + (right.b - left.b) * amount,
  );
}

@immutable
final class _Oklch {
  const _Oklch({
    required this.lightness,
    required this.chroma,
    required this.hue,
  });

  final double lightness;
  final double chroma;
  final double hue;

  _Oklab toOklab() => _Oklab(
    lightness: lightness,
    a: chroma * math.cos(hue),
    b: chroma * math.sin(hue),
  );
}

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
  static const int canonicalSlotIndex = 5;

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

/// Deterministic ten-slot material ramp. It retains the category's canonical
/// middle colour exactly at the identity zone, uses a pale tinted lead-in and
/// only a narrow tail hue bend. The result stays recognisably in the source
/// category family instead of becoming a generic rainbow.
abstract final class BudgetHeaderPaletteGenerator {
  static BudgetHeaderPalette generate(CategoryGradientToken gradient) {
    final canonical = gradient.middleColor;
    final source = BudgetHeaderPaletteColorMath.toOklab(canonical);
    final slots = List<Color>.filled(BudgetHeaderPalette.slotCount, canonical);
    final pale = _Oklab(
      lightness: .985,
      a: source.a * .035,
      b: source.b * .035,
    );

    for (
      var index = 0;
      index < BudgetHeaderPalette.canonicalSlotIndex;
      index += 1
    ) {
      final amount = index / BudgetHeaderPalette.canonicalSlotIndex;
      slots[index] = BudgetHeaderPaletteColorMath.fromOklab(
        _Oklab.lerp(pale, source, amount),
      );
    }
    // The category source remains exact at the identity zone. This makes the
    // category/avatar authority inspectable and prevents cumulative drift.
    slots[BudgetHeaderPalette.canonicalSlotIndex] = canonical;

    final sourceLch = source.toOklch();
    for (
      var index = BudgetHeaderPalette.canonicalSlotIndex + 1;
      index < BudgetHeaderPalette.slotCount;
      index += 1
    ) {
      final amount =
          (index - BudgetHeaderPalette.canonicalSlotIndex) /
          (BudgetHeaderPalette.slotCount -
              1 -
              BudgetHeaderPalette.canonicalSlotIndex);
      final tail = _Oklch(
        lightness: math.max(.12, sourceLch.lightness - .085 * amount),
        chroma: math.min(
          .37,
          sourceLch.chroma * (1 + .15 * amount) + .006 * amount,
        ),
        hue: sourceLch.hue + .040 * amount,
      );
      slots[index] = BudgetHeaderPaletteColorMath.fromOklab(tail.toOklab());
    }

    return BudgetHeaderPalette(
      id: gradient.id,
      canonicalColor: canonical,
      slots: List<Color>.unmodifiable(slots),
    );
  }
}

/// Local OKLab conversion/mixing keeps Header colour derivation deterministic
/// without bringing a package into the app. Values are converted through
/// linear sRGB and are clamped only at the final display boundary.
abstract final class BudgetHeaderPaletteColorMath {
  static _Oklab toOklab(Color color) {
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

  static Color fromOklab(_Oklab value) {
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

  static Color mixPerceptual(Color a, Color b, double amount) => fromOklab(
    _Oklab.lerp(toOklab(a), toOklab(b), amount.clamp(0.0, 1.0).toDouble()),
  );

  static double _linear(double channel) => channel <= .04045
      ? channel / 12.92
      : math.pow((channel + .055) / 1.055, 2.4).toDouble();

  static double _srgb(double channel) => channel <= .0031308
      ? channel * 12.92
      : 1.055 * math.pow(math.max(0, channel), 1 / 2.4).toDouble() - .055;
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

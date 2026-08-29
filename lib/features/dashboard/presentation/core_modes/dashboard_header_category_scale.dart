import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';

/// The user chooses only the source and the window width. In Category mode
/// the center is never a second stored control: Budget utilization supplies it
/// from the committed Header numerator/denominator.
enum DashboardBudgetHeaderColorSource { cool, category }

@immutable
final class DashboardBudgetHeaderCategoryState {
  const DashboardBudgetHeaderCategoryState({
    required this.source,
    required this.windowWidthPercent,
  });

  const DashboardBudgetHeaderCategoryState.defaults()
    : source = DashboardBudgetHeaderColorSource.cool,
      windowWidthPercent = 28;

  final DashboardBudgetHeaderColorSource source;
  final double windowWidthPercent;

  DashboardBudgetHeaderCategoryState copyWith({
    DashboardBudgetHeaderColorSource? source,
    double? windowWidthPercent,
  }) => DashboardBudgetHeaderCategoryState(
    source: source ?? this.source,
    windowWidthPercent: (windowWidthPercent ?? this.windowWidthPercent)
        .clamp(10.0, 100.0)
        .roundToDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetHeaderCategoryState &&
      source == other.source &&
      windowWidthPercent == other.windowWidthPercent;

  @override
  int get hashCode => Object.hash(source, windowWidthPercent);
}

/// Exact app source for the approved `category_palette_variation_lab.html`
/// COMPRESSED card: V1 Spectrum 40° (`lead=24`, `tail=16`).
///
/// `CategoryColorCatalog.middleColor` is the exact slot-seven identity. The
/// other anchors are generated once per color id, cached, and never generated
/// from a Header animation tick or pointer pixel.
@immutable
final class DashboardHeaderCategoryCompressedV1Scale {
  const DashboardHeaderCategoryCompressedV1Scale._({
    required this.id,
    required this.canonicalColor,
    required this.slots,
  }) : assert(slots.length == 10);

  static final Map<String, DashboardHeaderCategoryCompressedV1Scale> _cache =
      <String, DashboardHeaderCategoryCompressedV1Scale>{};

  final String id;
  final Color canonicalColor;
  final List<Color> slots;

  static DashboardHeaderCategoryCompressedV1Scale forColorId(String colorId) =>
      _cache.putIfAbsent(
        colorId,
        () => _generate(CategoryColorCatalog.resolve(colorId)),
      );

  static DashboardHeaderCategoryCompressedV1Scale? forColorIdOrNull(
    String? colorId,
  ) => colorId == null ? null : forColorId(colorId);

  Color samplePercent(double percent) {
    final bounded = (percent.isFinite ? percent : 0)
        .clamp(0.0, 100.0)
        .toDouble();
    final position = bounded / 100 * (slots.length - 1);
    final left = position.floor().clamp(0, slots.length - 1);
    final right = math.min(slots.length - 1, left + 1);
    return _CategoryV1ColorMath.mix(slots[left], slots[right], position - left);
  }

  static DashboardHeaderCategoryCompressedV1Scale _generate(
    CategoryGradientToken token,
  ) {
    final canonical = _CategoryV1ColorMath.toOklch(token.middleColor);
    final familyRule = _familyRuleForHue(canonical.hue);
    final lightness = _spectralLightnesses(canonical.lightness, familyRule);
    final chroma = _spectralChroma(canonical.chroma);
    const leadDegrees = 24.0;
    const tailDegrees = 16.0;
    final lead =
        familyRule.direction * leadDegrees * _CategoryV1ColorMath.degree;
    final tail =
        -familyRule.direction * tailDegrees * _CategoryV1ColorMath.degree;
    final full = <Color>[const Color(0xffffffff)];
    const leadProgress = <double>[0, .18, .42, .66, .86];
    for (var index = 0; index < 5; index += 1) {
      full.add(
        _CategoryV1ColorMath.gamutMap(
          _CategoryV1Oklch(
            lightness: lightness.$1[index],
            chroma: chroma.$1[index],
            hue: _CategoryV1ColorMath.normalizeHue(
              canonical.hue + lead * (1 - leadProgress[index]),
            ),
          ),
        ),
      );
    }
    full.add(token.middleColor);
    const tailProgress = <double>[.38, .72, 1];
    for (var index = 0; index < 3; index += 1) {
      full.add(
        _CategoryV1ColorMath.gamutMap(
          _CategoryV1Oklch(
            lightness: lightness.$2[index],
            chroma: chroma.$2[index] * (index == 2 ? familyRule.tailChroma : 1),
            hue: _CategoryV1ColorMath.normalizeHue(
              canonical.hue + tail * tailProgress[index],
            ),
          ),
        ),
      );
    }
    // COMPRESSED: R1…R8, perceptual midpoint(R8,R9), R9. Original R10 is
    // intentionally omitted, exactly as the approved card describes.
    final compressed = List<Color>.unmodifiable(<Color>[
      ...full.take(8),
      _CategoryV1ColorMath.mix(full[7], full[8], .5),
      full[8],
    ]);
    return DashboardHeaderCategoryCompressedV1Scale._(
      id: token.id,
      canonicalColor: token.middleColor,
      slots: compressed,
    );
  }

  static _CategoryV1FamilyRule _familyRuleForHue(double hue) {
    final degrees =
        _CategoryV1ColorMath.normalizeHue(hue) / _CategoryV1ColorMath.degree;
    if (degrees < 25) {
      return const _CategoryV1FamilyRule(
        direction: 1,
        terminalFloor: .43,
        tailDrop: .15,
        tailChroma: .98,
      );
    }
    if (degrees < 53) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .59,
        tailDrop: .11,
        tailChroma: .94,
      );
    }
    if (degrees < 78) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .68,
        tailDrop: .09,
        tailChroma: .86,
      );
    }
    if (degrees < 112) {
      return const _CategoryV1FamilyRule(
        direction: 1,
        terminalFloor: .80,
        tailDrop: .07,
        tailChroma: .80,
      );
    }
    if (degrees < 135) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .48,
        tailDrop: .16,
        tailChroma: .90,
      );
    }
    if (degrees < 153) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .39,
        tailDrop: .18,
        tailChroma: .96,
      );
    }
    if (degrees < 173) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .33,
        tailDrop: .19,
        tailChroma: .96,
      );
    }
    if (degrees < 197) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .31,
        tailDrop: .19,
        tailChroma: .98,
      );
    }
    if (degrees < 219) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .30,
        tailDrop: .18,
        tailChroma: 1,
      );
    }
    if (degrees < 238) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .27,
        tailDrop: .19,
        tailChroma: 1,
      );
    }
    if (degrees < 258) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .25,
        tailDrop: .20,
        tailChroma: 1.02,
      );
    }
    if (degrees < 283) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .23,
        tailDrop: .21,
        tailChroma: 1.02,
      );
    }
    if (degrees < 294) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .25,
        tailDrop: .20,
        tailChroma: 1,
      );
    }
    if (degrees < 307) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .27,
        tailDrop: .19,
        tailChroma: 1,
      );
    }
    if (degrees < 328) {
      return const _CategoryV1FamilyRule(
        direction: -1,
        terminalFloor: .31,
        tailDrop: .17,
        tailChroma: .98,
      );
    }
    return const _CategoryV1FamilyRule(
      direction: -1,
      terminalFloor: .35,
      tailDrop: .16,
      tailChroma: .96,
    );
  }

  static (List<double>, List<double>) _spectralLightnesses(
    double canonical,
    _CategoryV1FamilyRule rule,
  ) {
    final headroom = math.max(.028, .982 - canonical);
    final leadEnd = canonical + (headroom * .32).clamp(.018, .064);
    final leadStart = canonical + (headroom * .88).clamp(.062, .23);
    const leadProgress = <double>[0, .21, .48, .72, 1];
    var terminal = math.max(rule.terminalFloor, canonical - rule.tailDrop);
    terminal = math.min(terminal, canonical - .022);
    const tailProgress = <double>[.30, .66, 1];
    return (
      <double>[
        for (final p in leadProgress) leadStart - (leadStart - leadEnd) * p,
      ],
      <double>[
        for (final p in tailProgress) canonical - (canonical - terminal) * p,
      ],
    );
  }

  static (List<double>, List<double>) _spectralChroma(double canonical) => (
    <double>[
      for (final ratio in <double>[.18, .52, .78, .92, .98])
        math.max(.016, canonical * ratio),
    ],
    <double>[
      for (final ratio in <double>[1.03, 1, .94])
        math.max(.018, canonical * ratio),
    ],
  );
}

@immutable
final class DashboardHeaderCategoryWindow {
  const DashboardHeaderCategoryWindow({
    required this.scale,
    required this.centerPercent,
    required this.windowWidthPercent,
    required this.leftSamplePercent,
    required this.rightSamplePercent,
    required this.colorA,
    required this.colorMid,
    required this.colorB,
  });

  final DashboardHeaderCategoryCompressedV1Scale scale;
  final double centerPercent;
  final double windowWidthPercent;
  final double leftSamplePercent;
  final double rightSamplePercent;
  final Color colorA;
  final Color colorMid;
  final Color colorB;

  List<Color> get colors =>
      List<Color>.unmodifiable(<Color>[colorA, colorMid, colorB]);
  List<double> get stops => const <double>[0, .5, 1];

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderCategoryWindow &&
      scale.id == other.scale.id &&
      centerPercent == other.centerPercent &&
      windowWidthPercent == other.windowWidthPercent &&
      leftSamplePercent == other.leftSamplePercent &&
      rightSamplePercent == other.rightSamplePercent &&
      colorA == other.colorA &&
      colorMid == other.colorMid &&
      colorB == other.colorB;

  @override
  int get hashCode => Object.hash(
    scale.id,
    centerPercent,
    windowWidthPercent,
    leftSamplePercent,
    rightSamplePercent,
    colorA,
    colorMid,
    colorB,
  );
}

abstract final class DashboardHeaderCategoryWindowSampler {
  static double? remainingPercent({
    required int? spentScaled100,
    required int? limitScaled100,
  }) {
    if (spentScaled100 == null ||
        limitScaled100 == null ||
        limitScaled100 <= 0) {
      return null;
    }
    return ((1 - spentScaled100 / limitScaled100).clamp(0.0, 1.0) * 100)
        .toDouble();
  }

  static DashboardHeaderCategoryWindow sample({
    required DashboardHeaderCategoryCompressedV1Scale scale,
    required double? remainingPercent,
    required double windowWidthPercent,
  }) {
    final center = (remainingPercent?.isFinite == true ? remainingPercent! : 50)
        .clamp(0.0, 100.0)
        .toDouble();
    final width = windowWidthPercent.clamp(10.0, 100.0).toDouble();
    final half = width / 2;
    final left = (center - half).clamp(0.0, 100.0).toDouble();
    final right = (center + half).clamp(0.0, 100.0).toDouble();
    return DashboardHeaderCategoryWindow(
      scale: scale,
      centerPercent: center,
      windowWidthPercent: width,
      leftSamplePercent: left,
      rightSamplePercent: right,
      colorA: scale.samplePercent(left),
      colorMid: scale.samplePercent(center),
      colorB: scale.samplePercent(right),
    );
  }
}

@immutable
final class _CategoryV1FamilyRule {
  const _CategoryV1FamilyRule({
    required this.direction,
    required this.terminalFloor,
    required this.tailDrop,
    required this.tailChroma,
  });
  final int direction;
  final double terminalFloor;
  final double tailDrop;
  final double tailChroma;
}

@immutable
final class _CategoryV1Oklch {
  const _CategoryV1Oklch({
    required this.lightness,
    required this.chroma,
    required this.hue,
  });
  final double lightness;
  final double chroma;
  final double hue;
}

@immutable
final class _CategoryV1Oklab {
  const _CategoryV1Oklab({
    required this.lightness,
    required this.a,
    required this.b,
  });
  final double lightness;
  final double a;
  final double b;
}

abstract final class _CategoryV1ColorMath {
  static const double degree = math.pi / 180;
  static const double _tau = math.pi * 2;

  static double normalizeHue(double hue) => ((hue % _tau) + _tau) % _tau;

  static _CategoryV1Oklch toOklch(Color color) {
    final argb = color.toARGB32();
    double channel(int shift) => ((argb >> shift) & 0xff) / 255;
    final red = _toLinear(channel(16));
    final green = _toLinear(channel(8));
    final blue = _toLinear(channel(0));
    final l = .4122214708 * red + .5363325363 * green + .0514459929 * blue;
    final m = .2119034982 * red + .6806995451 * green + .1073969566 * blue;
    final s = .0883024619 * red + .2817188376 * green + .6299787005 * blue;
    final lr = math.pow(l, 1 / 3).toDouble();
    final mr = math.pow(m, 1 / 3).toDouble();
    final sr = math.pow(s, 1 / 3).toDouble();
    final lab = _CategoryV1Oklab(
      lightness: .2104542553 * lr + .7936177850 * mr - .0040720468 * sr,
      a: 1.9779984951 * lr - 2.4285922050 * mr + .4505937099 * sr,
      b: .0259040371 * lr + .7827717662 * mr - .8086757660 * sr,
    );
    return _CategoryV1Oklch(
      lightness: lab.lightness,
      chroma: math.sqrt(lab.a * lab.a + lab.b * lab.b),
      hue: normalizeHue(math.atan2(lab.b, lab.a)),
    );
  }

  static Color mix(Color left, Color right, double amount) {
    final a = toOklch(left);
    final b = toOklch(right);
    final aLab = _toOklab(a);
    final bLab = _toOklab(b);
    final t = amount.clamp(0.0, 1.0).toDouble();
    return gamutMap(
      _CategoryV1Oklch(
        lightness: aLab.lightness + (bLab.lightness - aLab.lightness) * t,
        chroma: math.sqrt(
          math.pow(aLab.a + (bLab.a - aLab.a) * t, 2) +
              math.pow(aLab.b + (bLab.b - aLab.b) * t, 2),
        ),
        hue: normalizeHue(
          math.atan2(
            aLab.b + (bLab.b - aLab.b) * t,
            aLab.a + (bLab.a - aLab.a) * t,
          ),
        ),
      ),
    );
  }

  static Color gamutMap(_CategoryV1Oklch target) {
    if (_isInGamut(target)) return _colorFor(target);
    var low = 0.0;
    var high = target.chroma;
    var chosen = _CategoryV1Oklch(
      lightness: target.lightness,
      chroma: 0,
      hue: target.hue,
    );
    for (var iteration = 0; iteration < 20; iteration += 1) {
      final candidate = _CategoryV1Oklch(
        lightness: target.lightness,
        chroma: (low + high) / 2,
        hue: target.hue,
      );
      if (_isInGamut(candidate)) {
        chosen = candidate;
        low = candidate.chroma;
      } else {
        high = candidate.chroma;
      }
    }
    return _colorFor(chosen);
  }

  static bool _isInGamut(_CategoryV1Oklch color) {
    final rgb = _toLinearRgb(_toOklab(color));
    const tolerance = .000001;
    return rgb.$1 >= -tolerance &&
        rgb.$1 <= 1 + tolerance &&
        rgb.$2 >= -tolerance &&
        rgb.$2 <= 1 + tolerance &&
        rgb.$3 >= -tolerance &&
        rgb.$3 <= 1 + tolerance;
  }

  static Color _colorFor(_CategoryV1Oklch color) {
    final rgb = _toLinearRgb(_toOklab(color));
    int channel(double value) => (_toSrgb(value).clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(
      255,
      channel(rgb.$1),
      channel(rgb.$2),
      channel(rgb.$3),
    );
  }

  static _CategoryV1Oklab _toOklab(_CategoryV1Oklch color) => _CategoryV1Oklab(
    lightness: color.lightness,
    a: color.chroma * math.cos(color.hue),
    b: color.chroma * math.sin(color.hue),
  );

  static (double, double, double) _toLinearRgb(_CategoryV1Oklab lab) {
    final lr = lab.lightness + .3963377774 * lab.a + .2158037573 * lab.b;
    final mr = lab.lightness - .1055613458 * lab.a - .0638541728 * lab.b;
    final sr = lab.lightness - .0894841775 * lab.a - 1.2914855480 * lab.b;
    final l = lr * lr * lr;
    final m = mr * mr * mr;
    final s = sr * sr * sr;
    return (
      4.0767416621 * l - 3.3077115913 * m + .2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - .3413193965 * s,
      -.0041960863 * l - .7034186147 * m + 1.7076147010 * s,
    );
  }

  static double _toLinear(double channel) => channel <= .04045
      ? channel / 12.92
      : math.pow((channel + .055) / 1.055, 2.4).toDouble();

  static double _toSrgb(double channel) => channel <= .0031308
      ? channel * 12.92
      : 1.055 * math.pow(math.max(0, channel), 1 / 2.4).toDouble() - .055;
}

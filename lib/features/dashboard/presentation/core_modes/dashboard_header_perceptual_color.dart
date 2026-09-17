import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared, deterministic OKLab/OKLCH color math for Header palette policies.
///
/// Palette policies own their anchors and window semantics. This utility owns
/// only perceptual interpolation and stable sRGB gamut mapping, so sibling
/// Header modes cannot drift into feature-local encoded-RGB mixers.
@immutable
final class DashboardHeaderOklch {
  const DashboardHeaderOklch({
    required this.lightness,
    required this.chroma,
    required this.hue,
  });

  final double lightness;
  final double chroma;
  final double hue;
}

@immutable
final class DashboardHeaderOklab {
  const DashboardHeaderOklab({
    required this.lightness,
    required this.a,
    required this.b,
  });

  final double lightness;
  final double a;
  final double b;
}

abstract final class DashboardHeaderPerceptualColorMath {
  static const double degree = math.pi / 180;
  static const double _tau = math.pi * 2;

  static double normalizeHue(double hue) => ((hue % _tau) + _tau) % _tau;

  static DashboardHeaderOklch toOklch(Color color) {
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
    final lab = DashboardHeaderOklab(
      lightness: .2104542553 * lr + .7936177850 * mr - .0040720468 * sr,
      a: 1.9779984951 * lr - 2.4285922050 * mr + .4505937099 * sr,
      b: .0259040371 * lr + .7827717662 * mr - .8086757660 * sr,
    );
    return DashboardHeaderOklch(
      lightness: lab.lightness,
      chroma: math.sqrt(lab.a * lab.a + lab.b * lab.b),
      hue: normalizeHue(math.atan2(lab.b, lab.a)),
    );
  }

  static Color mix(Color left, Color right, double amount) {
    final first = _toOklab(toOklch(left));
    final second = _toOklab(toOklch(right));
    final t = amount.clamp(0.0, 1.0).toDouble();
    return gamutMap(
      DashboardHeaderOklch(
        lightness: first.lightness + (second.lightness - first.lightness) * t,
        chroma: math.sqrt(
          math.pow(first.a + (second.a - first.a) * t, 2) +
              math.pow(first.b + (second.b - first.b) * t, 2),
        ),
        hue: normalizeHue(
          math.atan2(
            first.b + (second.b - first.b) * t,
            first.a + (second.a - first.a) * t,
          ),
        ),
      ),
    );
  }

  static Color gamutMap(DashboardHeaderOklch target) {
    if (_isInGamut(target)) return _colorFor(target);
    var low = 0.0;
    var high = target.chroma;
    var chosen = DashboardHeaderOklch(
      lightness: target.lightness,
      chroma: 0,
      hue: target.hue,
    );
    for (var iteration = 0; iteration < 20; iteration += 1) {
      final candidate = DashboardHeaderOklch(
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

  static bool _isInGamut(DashboardHeaderOklch color) {
    final rgb = _toLinearRgb(_toOklab(color));
    const tolerance = .000001;
    return rgb.$1 >= -tolerance &&
        rgb.$1 <= 1 + tolerance &&
        rgb.$2 >= -tolerance &&
        rgb.$2 <= 1 + tolerance &&
        rgb.$3 >= -tolerance &&
        rgb.$3 <= 1 + tolerance;
  }

  static Color _colorFor(DashboardHeaderOklch color) {
    final rgb = _toLinearRgb(_toOklab(color));
    int channel(double value) => (_toSrgb(value).clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(
      255,
      channel(rgb.$1),
      channel(rgb.$2),
      channel(rgb.$3),
    );
  }

  static DashboardHeaderOklab _toOklab(DashboardHeaderOklch color) =>
      DashboardHeaderOklab(
        lightness: color.lightness,
        a: color.chroma * math.cos(color.hue),
        b: color.chroma * math.sin(color.hue),
      );

  static (double, double, double) _toLinearRgb(DashboardHeaderOklab lab) {
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

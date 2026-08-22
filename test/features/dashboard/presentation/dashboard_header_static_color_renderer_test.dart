import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_static_color_renderer.dart';

/// Independent historical oracle copied from the exact `spendeetest` source:
/// `spendee_balance_visual_spec.dart` blob
/// `bea3a36482686b1ef7a537046dcce0f2c443918a`.
///
/// Keeping this test-only implementation separate from the production owner
/// prevents a future shader or Alignment approximation from passing merely by
/// sharing the same helper implementation.
final class _HistoricalSpendeeCssLinearGradient extends Gradient {
  const _HistoricalSpendeeCssLinearGradient({
    required this.cssDegrees,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
  });

  final double cssDegrees;
  final TileMode tileMode;

  ({Offset start, Offset end}) endpointsFor(Rect rect) {
    final radians = cssDegrees * 3.141592653589793 / 180;
    final direction = Offset(_sin(radians), -_cos(radians));
    final lineLength =
        rect.width * direction.dx.abs() + rect.height * direction.dy.abs();
    final halfVector = direction * (lineLength / 2);
    return (start: rect.center - halfVector, end: rect.center + halfVector);
  }

  @override
  ui.Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final (:start, :end) = endpointsFor(rect);
    final resolvedStops =
        stops ??
        List<double>.generate(
          colors.length,
          (index) => index / (colors.length - 1),
          growable: false,
        );
    return ui.Gradient.linear(start, end, colors, resolvedStops, tileMode);
  }

  @override
  _HistoricalSpendeeCssLinearGradient scale(double factor) =>
      _HistoricalSpendeeCssLinearGradient(
        cssDegrees: cssDegrees,
        colors: colors
            .map((color) => Color.lerp(null, color, factor)!)
            .toList(growable: false),
        stops: stops,
        tileMode: tileMode,
      );

  @override
  _HistoricalSpendeeCssLinearGradient withOpacity(double opacity) =>
      _HistoricalSpendeeCssLinearGradient(
        cssDegrees: cssDegrees,
        colors: colors
            .map((color) => color.withValues(alpha: color.a * opacity))
            .toList(growable: false),
        stops: stops,
        tileMode: tileMode,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Spendee Budget2 native static Header renderer', () {
    const fixtureColors = <Color>[
      Color(0xffbdf5ff),
      Color(0xff06b6d4),
      Color(0xff0057d9),
    ];
    const fixtureStops = <double>[0, .5, 1];

    test(
      'matches historical 112 degree CSS endpoints on non-square Header rects',
      () {
        const historical = _HistoricalSpendeeCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );
        const production = DashboardHeaderCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );

        for (final rect in <Rect>[
          const Rect.fromLTWH(0, 0, 360, 84),
          const Rect.fromLTWH(0, 0, 379, 110),
          const Rect.fromLTWH(0, 0, 400, 180),
          const Rect.fromLTWH(0, 0, 412, 104),
        ]) {
          final expected = historical.endpointsFor(rect);
          final actual = production.endpointsFor(rect);
          expect(actual.start.dx, closeTo(expected.start.dx, 1e-12));
          expect(actual.start.dy, closeTo(expected.start.dy, 1e-12));
          expect(actual.end.dx, closeTo(expected.end.dx, 1e-12));
          expect(actual.end.dy, closeTo(expected.end.dy, 1e-12));
        }
      },
    );

    test(
      'matches the original three-stop Budget2 fixture at pixel level',
      () async {
        const historical = _HistoricalSpendeeCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );
        const production = DashboardHeaderCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );

        final expected = await _render(historical, const Size(412, 104));
        final actual = await _render(production, const Size(412, 104));
        expect(actual, orderedEquals(expected));
      },
    );

    test(
      'proves that a uniform resampling which drops a source knot is not an equivalent representation',
      () async {
        const source = _HistoricalSpendeeCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );
        final sampledAnchors = List<Color>.generate(
          10,
          (index) => _sampleHistoricalFixture(index / 9),
          growable: false,
        );
        final sampledStops = List<double>.generate(
          10,
          (index) => index / 9,
          growable: false,
        );
        final sampled = DashboardHeaderStaticColorRenderer.gradientFor(
          colors: sampledAnchors,
          stops: sampledStops,
        );

        final referencePixels = await _render(source, const Size(412, 104));
        final sampledPixels = await _render(sampled, const Size(412, 104));
        final delta = _pixelDelta(referencePixels, sampledPixels);

        expect(
          delta.maxChannel,
          greaterThan(1),
          reason:
              'The 0/9…9/9 sample positions omit the original source knot at '
              '0.5, so they cannot be used as a renderer-equivalence oracle.',
        );
        expect(
          delta.meanChannel,
          greaterThan(.1),
          reason:
              'The loss is material rather than only a one-channel rounding '
              'difference at the original colour-function kink.',
        );
      },
    );

    test(
      'keeps an original source knot in an adaptive ten-stop resampling',
      () async {
        const source = _HistoricalSpendeeCssLinearGradient(
          cssDegrees: 112,
          colors: fixtureColors,
          stops: fixtureStops,
        );
        const adaptivePositions = <double>[
          0,
          1 / 9,
          2 / 9,
          3 / 9,
          4 / 9,
          .5,
          6 / 9,
          7 / 9,
          8 / 9,
          1,
        ];
        final adaptive = DashboardHeaderStaticColorRenderer.gradientFor(
          colors: <Color>[
            for (final position in adaptivePositions)
              _sampleHistoricalFixture(position),
          ],
          stops: adaptivePositions,
        );

        final referencePixels = await _render(source, const Size(412, 104));
        final adaptivePixels = await _render(adaptive, const Size(412, 104));
        final delta = _pixelDelta(referencePixels, adaptivePixels);

        expect(delta.maxChannel, lessThanOrEqualTo(1));
        expect(delta.meanChannel, lessThanOrEqualTo(.11));
      },
    );

    test(
      'keeps interior window knots authoritative instead of compatibility A/B',
      () async {
        const first = <Color>[
          Color(0xffbdf5ff),
          Color(0xff06b6d4),
          Color(0xff0057d9),
        ];
        const second = <Color>[
          Color(0xffbdf5ff),
          Color(0xffff00aa),
          Color(0xff0057d9),
        ];
        const stops = <double>[0, .5, 1];

        final firstPixels = await _render(
          DashboardHeaderStaticColorRenderer.gradientFor(
            colors: first,
            stops: stops,
          ),
          const Size(412, 104),
        );
        final secondPixels = await _render(
          DashboardHeaderStaticColorRenderer.gradientFor(
            colors: second,
            stops: stops,
          ),
          const Size(412, 104),
        );

        expect(secondPixels, isNot(orderedEquals(firstPixels)));
        expect(
          DashboardHeaderStaticColorRenderer.fragmentBaseRequired,
          isFalse,
        );
      },
    );
  });
}

Color _sampleHistoricalFixture(double position) {
  final bounded = position.clamp(0.0, 1.0).toDouble();
  if (bounded <= .5) {
    return Color.lerp(
      const Color(0xffbdf5ff),
      const Color(0xff06b6d4),
      bounded / .5,
    )!;
  }
  return Color.lerp(
    const Color(0xff06b6d4),
    const Color(0xff0057d9),
    (bounded - .5) / .5,
  )!;
}

({int maxChannel, double meanChannel}) _pixelDelta(
  Uint8List left,
  Uint8List right,
) {
  var maximum = 0;
  var total = 0;
  for (var index = 0; index < left.length; index += 1) {
    final delta = (left[index] - right[index]).abs();
    if (delta > maximum) maximum = delta;
    total += delta;
  }
  return (maxChannel: maximum, meanChannel: total / left.length);
}

Future<Uint8List> _render(Gradient gradient, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & size;
  canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  final image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

double _sin(double radians) =>
    // `dart:math` is deliberately kept out of this tiny test oracle so its
    // source math is visibly independent from the production port.
    ui.Offset.fromDirection(radians).dy;

double _cos(double radians) => ui.Offset.fromDirection(radians).dx;

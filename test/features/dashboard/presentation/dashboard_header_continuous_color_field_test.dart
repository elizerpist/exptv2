import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_budget_palette.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_continuous_color_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_static_color_renderer.dart';

void main() {
  group('DashboardHeaderContinuousColorScale', () {
    const anchors = <Color>[
      Color(0xfff7fbff),
      Color(0xff4ec9ee),
      Color(0xff2451cf),
      Color(0xff8b31d6),
    ];
    const positions = <double>[0, .28, .63, 1];

    test('monotone cubic interpolation preserves every authored anchor', () {
      final scale = DashboardHeaderContinuousColorScale.monotoneCubic(
        anchors: anchors,
        anchorPositions: positions,
      );

      for (var index = 0; index < anchors.length; index += 1) {
        expect(scale.sample(positions[index]), anchors[index]);
      }
    });

    test('monotone cubic interpolation is C1 at interior anchor knots', () {
      final scale = DashboardHeaderContinuousColorScale.monotoneCubic(
        anchors: anchors,
        anchorPositions: positions,
      );

      for (final knot in positions.skip(1).take(positions.length - 2)) {
        final left = scale.linearDerivative(knot - 1e-6);
        final right = scale.linearDerivative(knot + 1e-6);
        expect(left.distanceTo(right), lessThanOrEqualTo(2e-3));
      }
    });

    test(
      'reduces the anchor-boundary derivative spikes of a non-collinear linear scale',
      () {
        final linear = DashboardHeaderContinuousColorScale.historicalLinear(
          anchors: anchors,
          anchorPositions: positions,
        );
        final cubic = DashboardHeaderContinuousColorScale.monotoneCubic(
          anchors: anchors,
          anchorPositions: positions,
        );
        var linearMaximum = 0.0;
        var cubicMaximum = 0.0;
        for (final knot in positions.skip(1).take(positions.length - 2)) {
          linearMaximum = math.max(
            linearMaximum,
            linear
                .linearDerivative(knot - 1e-6)
                .distanceTo(linear.linearDerivative(knot + 1e-6)),
          );
          cubicMaximum = math.max(
            cubicMaximum,
            cubic
                .linearDerivative(knot - 1e-6)
                .distanceTo(cubic.linearDerivative(knot + 1e-6)),
          );
        }

        expect(linearMaximum, greaterThan(.1));
        expect(cubicMaximum, lessThanOrEqualTo(2e-3));
      },
    );

    test(
      'keeps all real category anchors exact while removing their linear knot spikes',
      () {
        const positions = <double>[
          0,
          1 / 9,
          2 / 9,
          3 / 9,
          4 / 9,
          5 / 9,
          6 / 9,
          7 / 9,
          8 / 9,
          1,
        ];
        var greatestLinearSpike = 0.0;
        for (final palette in BudgetHeaderPaletteCatalog.allCategoryPalettes) {
          final linear = DashboardHeaderContinuousColorScale.historicalLinear(
            anchors: palette.slots,
            anchorPositions: positions,
          );
          final cubic = palette.staticColorScale;
          for (var index = 0; index < positions.length; index += 1) {
            expect(cubic.sample(positions[index]), palette.slots[index]);
          }
          for (final knot in positions.skip(1).take(positions.length - 2)) {
            greatestLinearSpike = math.max(
              greatestLinearSpike,
              linear
                  .linearDerivative(knot - 1e-6)
                  .distanceTo(linear.linearDerivative(knot + 1e-6)),
            );
            expect(
              cubic
                  .linearDerivative(knot - 1e-6)
                  .distanceTo(cubic.linearDerivative(knot + 1e-6)),
              lessThanOrEqualTo(2e-3),
              reason: '${palette.id} must not retain a static-field knot spike',
            );
          }
        }

        expect(greatestLinearSpike, greaterThan(.1));
      },
    );

    test(
      'uses the smallest tested dense C1 stop budget that is pixel-equivalent to the 256-stop oracle',
      () async {
        final palette = BudgetHeaderPaletteCatalog.paletteForColorId(
          'color_12',
        );
        const transform = DashboardHeaderColorWindowTransform(
          left: 0,
          right: 1,
        );
        final field128 = DashboardHeaderContinuousField(
          paletteId: palette.id,
          sourceScale: palette.staticColorScale,
          windowTransform: transform,
          rawProgress: .5,
          windowWidth: 1,
          opacity: 1,
          minimumRenderStopCount: 128,
        );
        final field256 = DashboardHeaderContinuousField(
          paletteId: palette.id,
          sourceScale: palette.staticColorScale,
          windowTransform: transform,
          rawProgress: .5,
          windowWidth: 1,
          opacity: 1,
          minimumRenderStopCount: 256,
        );

        final delta = _imageDelta(
          await _renderStaticField(field128),
          await _renderStaticField(field256),
        );
        expect(delta.maxChannel, lessThanOrEqualTo(1));
        expect(delta.meanChannel, lessThanOrEqualTo(.2));
      },
    );

    test(
      'monotone cubic interpolation stays inside each local gamut envelope',
      () {
        final scale = DashboardHeaderContinuousColorScale.monotoneCubic(
          anchors: anchors,
          anchorPositions: positions,
        );

        for (var segment = 0; segment < anchors.length - 1; segment += 1) {
          final start = positions[segment];
          final end = positions[segment + 1];
          final lower = DashboardHeaderLinearRgb.fromColor(anchors[segment])
              .componentwiseMin(
                DashboardHeaderLinearRgb.fromColor(anchors[segment + 1]),
              );
          final upper = DashboardHeaderLinearRgb.fromColor(anchors[segment])
              .componentwiseMax(
                DashboardHeaderLinearRgb.fromColor(anchors[segment + 1]),
              );
          for (var step = 0; step <= 64; step += 1) {
            final sample = scale.sampleLinear(
              start + (end - start) * step / 64,
            );
            expect(sample.isWithin(lower, upper), isTrue);
            expect(sample.isInDisplayGamut, isTrue);
          }
        }
      },
    );

    test('header coordinate transform is exactly source=L+x*(R-L)', () {
      const transform = DashboardHeaderColorWindowTransform(
        left: .36,
        right: .64,
      );

      expect(transform.sourceForHeaderX(0), .36);
      expect(transform.sourceForHeaderX(.1), closeTo(.388, 1e-12));
      expect(transform.sourceForHeaderX(.5), closeTo(.5, 1e-12));
      expect(transform.sourceForHeaderX(1), .64);
    });

    test(
      'a C1 field derives dense static render stops from the windowed source function',
      () {
        final scale = DashboardHeaderContinuousColorScale.monotoneCubic(
          anchors: anchors,
          anchorPositions: positions,
        );
        const transform = DashboardHeaderColorWindowTransform(
          left: .36,
          right: .64,
        );
        final field = DashboardHeaderContinuousField(
          paletteId: 'test-spectrum',
          sourceScale: scale,
          windowTransform: transform,
          rawProgress: .5,
          windowWidth: .28,
          opacity: 1,
        );

        expect(field.renderStops.length, greaterThanOrEqualTo(64));
        expect(field.renderStops.first.sourcePosition, .36);
        expect(field.renderStops.first.headerStop, 0);
        expect(field.renderStops.first.color, scale.sample(.36));
        expect(field.renderStops.last.sourcePosition, .64);
        expect(field.renderStops.last.headerStop, 1);
        expect(field.renderStops.last.color, scale.sample(.64));
      },
    );
  });
}

Future<Uint8List> _renderStaticField(
  DashboardHeaderContinuousField field,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(412, 104);
  DashboardHeaderStaticColorRenderer.paint(
    canvas: canvas,
    rect: Offset.zero & size,
    colors: field.colors,
    stops: field.stops,
    opacity: field.opacity,
  );
  final image = await recorder.endRecording().toImage(412, 104);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

({int maxChannel, double meanChannel}) _imageDelta(
  Uint8List left,
  Uint8List right,
) {
  var maximum = 0;
  var total = 0;
  for (var index = 0; index < left.length; index += 1) {
    final delta = (left[index] - right[index]).abs();
    maximum = math.max(maximum, delta);
    total += delta;
  }
  return (maxChannel: maximum, meanChannel: total / left.length);
}

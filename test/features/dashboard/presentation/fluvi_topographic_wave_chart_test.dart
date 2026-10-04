import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const values = <FluviTopographicWaveDatum>[
    FluviTopographicWaveDatum(key: 1, value: 1800, label: '1'),
    FluviTopographicWaveDatum(key: 2, value: 7200, label: '2'),
    FluviTopographicWaveDatum(key: 3, value: 2600, label: '3'),
    FluviTopographicWaveDatum(key: 4, value: 9000, label: '4'),
    FluviTopographicWaveDatum(key: 5, value: 4000, label: '5'),
    FluviTopographicWaveDatum(key: 6, value: 6800, label: '6'),
  ];

  test(
    'MTC-03: real daily values produce a cached Catmull–Rom ridge and thirty progressively flattened contours',
    () {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: values,
        size: const Size(346, 132),
      );

      expect(terrain.ridgeSamples.length, greaterThan(60));
      expect(terrain.depthLayers, hasLength(30));
      expect(terrain.atmospheres, hasLength(4));
      expect(terrain.depthLayers.first.depth, 0);
      expect(terrain.depthLayers.last.depth, closeTo(1, .001));
      expect(
        terrain.depthLayers.first.opacity,
        greaterThanOrEqualTo(.18),
        reason:
            'At the real monthly-card scale the source SVG has visibly '
            'merged terrain volume, not imperceptible contour bookkeeping.',
      );
      expect(
        terrain.depthLayers.first.opacity,
        greaterThan(terrain.depthLayers.last.opacity),
      );
      expect(terrain.ridgeSamples.first.dx, closeTo(2, .01));
      expect(terrain.ridgeSamples.last.dx, closeTo(344, .01));
      // 14 dense samples per source segment: the smooth spline never creates
      // a false financial peak outside the two real adjacent values.
      for (var segment = 0; segment < values.length - 1; segment += 1) {
        final firstY = terrain.dataOffsets[segment].dy;
        final secondY = terrain.dataOffsets[segment + 1].dy;
        final lower = firstY < secondY ? firstY : secondY;
        final upper = firstY > secondY ? firstY : secondY;
        for (var sample = 0; sample <= 14; sample += 1) {
          final y = terrain.ridgeSamples[segment * 14 + sample].dy;
          expect(y, inInclusiveRange(lower, upper));
        }
      }
    },
  );

  test(
    'MTC-03: cached terrain remains stable for value-equivalent values and invalidates only for changed geometry',
    () {
      final cache = _TestTerrainCache();
      final first = cache.resolve(values, const Size(346, 132));
      final repeated = cache.resolve(
        List<FluviTopographicWaveDatum>.of(values),
        const Size(346, 132),
      );
      final resized = cache.resolve(values, const Size(300, 132));

      expect(identical(first, repeated), isTrue);
      expect(identical(first, resized), isFalse);
    },
  );

  test(
    'MTC-03: an all-zero month keeps a calm atmospheric empty state without inventing a spend ridge or marker',
    () {
      const zeroValues = <FluviTopographicWaveDatum>[
        FluviTopographicWaveDatum(key: 1, value: 0, label: '1'),
        FluviTopographicWaveDatum(key: 2, value: 0, label: '2'),
        FluviTopographicWaveDatum(key: 3, value: 0, label: '3'),
      ];

      final terrain = FluviTopographicWaveTerrain.resolve(
        values: zeroValues,
        size: const Size(346, 132),
      );

      expect(terrain.ridgeSamples, isEmpty);
      expect(terrain.depthLayers, isEmpty);
      expect(terrain.dataOffsets, isEmpty);
      expect(terrain.highestIndex, isNull);
      expect(terrain.atmospheres, hasLength(4));
      expect(terrain.nearestIndexForX(173), isNull);
    },
  );

  testWidgets(
    'MTC-04/05: every terrain option mounts one clipped Canvas terrain while only the shader option mounts the atmospheric shader',
    (tester) async {
      for (final style in FluviTopographicWaveStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 346,
                height: 132,
                child: FluviTopographicWaveChart(
                  values: values,
                  style: style,
                  tooltipForValue: (value) => '$value Ft',
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(
            ValueKey<String>('balance-monthly-spending-wave-${style.name}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'balance-monthly-spending-wave-shader-atmosphere',
            ),
          ),
          style == FluviTopographicWaveStyle.shaderAtmosphere
              ? findsOneWidget
              : findsNothing,
        );
      }
    },
  );

  testWidgets(
    'MTC-03: a tap selects a real datum and keeps the marker inside the terrain bounds',
    (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 346,
              height: 132,
              child: FluviTopographicWaveChart(
                values: values,
                style: FluviTopographicWaveStyle.svgReference,
                tooltipForValue: (value) => '$value Ft',
                onSelectedIndexChanged: (index) => selected = index,
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(282, 72));
      await tester.pump();
      expect(selected, inInclusiveRange(0, values.length - 1));
    },
  );

  testWidgets(
    'MTC-07 visual: SVG-reference terrain is a clipped lavender landscape rather than a conventional line chart',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xfffdfdff),
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: const ValueKey<String>(
                  'balance-monthly-spending-svg-reference-golden',
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SizedBox(
                    width: 346,
                    height: 220,
                    child: FluviTopographicWaveChart(
                      values: values,
                      style: FluviTopographicWaveStyle.svgReference,
                      tooltipForValue: (value) => '$value Ft',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(
          const ValueKey<String>(
            'balance-monthly-spending-svg-reference-golden',
          ),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_monthly_spending_svg_reference.png',
        ),
      );
    },
  );
}

/// Mirrors the chart's structural cache contract without exposing its private
/// state as part of the component API.
final class _TestTerrainCache {
  List<FluviTopographicWaveDatum>? _values;
  Size? _size;
  FluviTopographicWaveTerrain? _terrain;

  FluviTopographicWaveTerrain resolve(
    List<FluviTopographicWaveDatum> values,
    Size size,
  ) {
    if (_terrain != null && _size == size && _sameValues(_values!, values)) {
      return _terrain!;
    }
    _values = List<FluviTopographicWaveDatum>.of(values);
    _size = size;
    return _terrain = FluviTopographicWaveTerrain.resolve(
      values: values,
      size: size,
    );
  }

  bool _sameValues(
    List<FluviTopographicWaveDatum> left,
    List<FluviTopographicWaveDatum> right,
  ) =>
      left.length == right.length &&
      List<bool>.generate(
        left.length,
        (index) => left[index] == right[index],
      ).every((same) => same);
}

import 'dart:ui' as ui;

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
  final sparseSpike = List.generate(
    31,
    (index) => FluviTopographicWaveDatum(
      key: index + 1,
      value: index == 2
          ? 26800000
          : index == 18
          ? 13000000
          : index % 4 == 0
          ? 100000
          : 0,
      label: '${index + 1}',
    ),
  );

  test(
    'MTC-03: real daily values retain bounded interpolation and size-adaptive contour detail',
    () {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: values,
        size: const Size(346, 132),
      );

      expect(terrain.ridgeSamples.length, greaterThan(60));
      expect(terrain.depthLayers.length, inInclusiveRange(8, 24));
      expect(terrain.depthLayers.first.depth, 0);
      expect(terrain.depthLayers.last.depth, closeTo(1, .001));
      expect(
        terrain.depthLayers.first.opacity,
        inInclusiveRange(.10, .12),
        reason:
            'The contour is a restrained surface-detail layer; the filled '
            'locally-lit body, rather than a high-alpha line stack, owns '
            'the visible terrain volume.',
      );
      expect(
        terrain.depthLayers.first.opacity,
        greaterThan(terrain.depthLayers.last.opacity),
      );
      expect(terrain.ridgeSamples.first.dx, closeTo(10, .01));
      expect(terrain.ridgeSamples.last.dx, closeTo(336, .01));
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
    'BMR-05: terrain resolves a continuous local-depth material body rather than a rectangle-global baseline fill',
    () {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: values,
        size: const Size(346, 132),
      );

      expect(
        terrain.surfaceFootSamples,
        hasLength(terrain.ridgeSamples.length),
      );
      expect(
        terrain.surfacePath.contains(
          Offset.lerp(
            terrain.ridgeSamples[20],
            terrain.surfaceFootSamples[20],
            .5,
          )!,
        ),
        isTrue,
      );
      expect(
        terrain.surfaceFootSamples.first.dy,
        greaterThan(terrain.ridgeSamples.first.dy),
      );
      expect(
        terrain.surfaceFootSamples.map((point) => point.dy).toSet().length,
        greaterThan(1),
        reason:
            'The material foot follows local terrain, not one global baseline.',
      );
    },
  );

  testWidgets(
    'MTC-03: real production cache reuses equal data and invalidates size/data',
    (tester) async {
      FluviWaveRenderMetrics? metrics;
      Widget host(List<FluviTopographicWaveDatum> data, double width) =>
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: width,
                height: 132,
                child: FluviWaveDebugScope(
                  onPaint: (value) => metrics = value,
                  child: FluviTopographicWaveChart(
                    values: data,
                    style: FluviTopographicWaveStyle.terrain,
                    tooltipForValue: (v) => '$v Ft',
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(host(values, 346));
      final first = metrics!.terrain;
      expect(metrics!.geometryBuilds, 1);
      await tester.pumpWidget(host(List.of(values), 346));
      expect(identical(metrics!.terrain, first), isTrue);
      expect(metrics!.geometryBuilds, 1);
      await tester.pumpWidget(host(values, 300));
      expect(identical(metrics!.terrain, first), isFalse);
      expect(metrics!.geometryBuilds, 2);
      await tester.pumpWidget(host(sparseSpike, 300));
      expect(metrics!.geometryBuilds, 3);
    },
  );

  test(
    'MTC-03: an all-zero month has an empty surface without inventing a spend ridge or marker',
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
      expect(terrain.surfaceMesh, isNull);
      expect(terrain.surfacePath.computeMetrics(), isEmpty);
      expect(terrain.nearestIndexForX(173), isNull);
    },
  );

  test(
    'BMR-05: a sparse real spike keeps its datum ridge exact while retaining a finite local material body',
    () {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: sparseSpike,
        size: const Size(312, 196),
      );

      expect(terrain.highestIndex, 2);
      expect(
        terrain.dataOffsets.every(
          (point) => terrain.dataOffsets[2].dy <= point.dy,
        ),
        isTrue,
      );
      for (var i = 0; i < terrain.ridgeSamples.length; i++) {
        expect(terrain.surfaceFootSamples[i].dx, terrain.ridgeSamples[i].dx);
        expect(
          terrain.surfaceFootSamples[i].dy,
          greaterThan(terrain.ridgeSamples[i].dy),
        );
      }
      expect(
        terrain.surfaceFootSamples.every(
          (point) => point.dy.isFinite && point.dy <= terrain.plot.bottom,
        ),
        isTrue,
      );
    },
  );

  test(
    'BMR-06: the registered local wave material compiles to a FragmentShader',
    () async {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/fluvi_wave_surface.frag',
      );
      final shader = program.fragmentShader();
      shader.dispose();
    },
  );

  testWidgets(
    'MTC-04/05: every terrain option mounts one clipped Canvas terrain without an atmospheric overlay',
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
          findsNothing,
        );
      }
    },
  );

  testWidgets('MTC-03: a tap callback selects the exact nearest real datum', (
    tester,
  ) async {
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
    expect(selected, 4);
  });

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

  testWidgets(
    'BMR-07 visual: a narrow monthly card keeps a true shaded surface for a sparse real spike',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xfffdfdff),
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: const ValueKey<String>(
                  'balance-monthly-spending-sparse-spike-golden',
                ),
                child: SizedBox(
                  width: 312,
                  height: 196,
                  child: FluviTopographicWaveChart(
                    values: sparseSpike,
                    style: FluviTopographicWaveStyle.svgReference,
                    tooltipForValue: (value) => '$value Ft',
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
            'balance-monthly-spending-sparse-spike-golden',
          ),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_monthly_spending_sparse_spike.png',
        ),
      );
    },
  );

  testWidgets(
    'BMR-07 visual: a zero month has no decorative landscape or financial marker',
    (tester) async {
      const zeroValues = <FluviTopographicWaveDatum>[
        FluviTopographicWaveDatum(key: 1, value: 0, label: '1'),
        FluviTopographicWaveDatum(key: 2, value: 0, label: '2'),
        FluviTopographicWaveDatum(key: 3, value: 0, label: '3'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xfffdfdff),
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: const ValueKey<String>(
                  'balance-monthly-spending-zero-golden',
                ),
                child: SizedBox(
                  width: 312,
                  height: 196,
                  child: FluviTopographicWaveChart(
                    values: zeroValues,
                    style: FluviTopographicWaveStyle.svgReference,
                    tooltipForValue: (value) => '$value Ft',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final paintFinder = find
          .descendant(
            of: find.byType(FluviTopographicWaveChart),
            matching: find.byType(CustomPaint),
          )
          .last;
      final dynamic painter = tester.widget<CustomPaint>(paintFinder).painter;
      expect((painter.metrics as FluviWaveRenderMetrics).markerBounds, isNull);
      expect((painter.metrics as FluviWaveRenderMetrics).tooltipBounds, isNull);
      expect((painter.metrics as FluviWaveRenderMetrics).route, 'empty');
      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-monthly-spending-zero-golden'),
        ),
        matchesGoldenFile('../../../goldens/balance_monthly_spending_zero.png'),
      );
    },
  );
}

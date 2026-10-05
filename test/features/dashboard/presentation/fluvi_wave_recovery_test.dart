import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fluvi_wave_fixture.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Ahem')
      ..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'));
    await font.load();
  });
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  for (final (year, month, days) in [
    (2026, 2, 28),
    (2024, 2, 29),
    (2026, 6, 30),
    (2026, 7, 31),
  ]) {
    test('WR-08/09 positive same-x body depth, $days calendar days', () {
      final amounts = waveSparseForints(days);
      final data = waveData(waveLinked(amounts, year: year, month: month));
      expect(data.map((v) => v.key), List.generate(days, (i) => i + 1));
      expect(data.map((v) => v.value), amounts.map((v) => v * 100));
      expect(
        DashboardPreparedFormatter.compactAmountMinor(data[1].value),
        '268 k Ft',
      );
      for (final size in [
        const Size(240, 128),
        const Size(194, 96),
        const Size(320, 200),
      ]) {
        final terrain = FluviTopographicWaveTerrain.resolve(
          values: data,
          size: size,
        );
        for (var i = 0; i < terrain.ridgeSamples.length; i++) {
          final ridge = terrain.ridgeSamples[i];
          final foot = terrain.surfaceFootSamples[i];
          expect(foot.dx, ridge.dx);
          expect(
            foot.dy - ridge.dy,
            greaterThan(0),
            reason:
                'size=$size sample=$i x=${ridge.dx}; zero/small days must have positive visible depth',
          );
          expect(foot.dy, lessThan(size.height));
        }
      }
    });
  }

  testWidgets('WR-12 isolated vertex-colour pixel probe', (tester) async {
    final mesh = ui.Vertices(
      ui.VertexMode.triangles,
      const [Offset(0, 0), Offset(32, 0), Offset(0, 32)],
      colors: const [Color(0xff9682f2), Color(0xff9682f2), Color(0xff9682f2)],
    );
    final observed = <String, List<int>>{};
    for (final blend in [BlendMode.srcOver, BlendMode.dst]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawVertices(mesh, blend, Paint()..isAntiAlias = true);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(32, 32);
      final bytes = (await tester.runAsync(() => image.toByteData()))!;
      final offset = (8 * 32 + 8) * 4;
      observed[blend.name] = List.generate(
        4,
        (i) => bytes.getUint8(offset + i),
      );
      await waveWriteEvidence(tester, image, 'vertex-${blend.name}', {
        'blend': blend.name,
        'pixel': observed[blend.name],
      });
      image.dispose();
      picture.dispose();
    }
    // A probe measures engine behavior independently from production material.
    expect(observed['dst'], [150, 130, 242, 255]);
    debugPrint('WR-12 vertex pixels $observed');
  });

  testWidgets(
    'WR-13 production async owner never paints another terrain lookup',
    (tester) async {
      final pending = <(FluviTopographicWaveTerrain, Completer<ui.Image>)>[];
      Future<ui.Image> load(FluviTopographicWaveTerrain terrain) {
        final result = Completer<ui.Image>();
        pending.add((terrain, result));
        return result.future;
      }

      FluviWaveRenderMetrics? metrics;
      final a = waveData(waveLinked(waveSparseForints(31)));
      final b = waveData(waveLinked(waveReferenceForints));
      final c = waveData(waveLinked(waveSparseForints(31, peak: 30)));
      Widget host(
        List<FluviTopographicWaveDatum> data, {
        FluviTopographicWaveStyle style =
            FluviTopographicWaveStyle.shaderAtmosphere,
      }) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            height: 128,
            child: FluviWaveDebugScope(
              textureLoader: load,
              atmosphere: false,
              onPaint: (value) => metrics = value,
              child: FluviTopographicWaveChart(
                values: data,
                style: style,
                tooltipForValue: DashboardPreparedFormatter.compactAmountMinor,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(a));
      for (var i = 0; i < 40 && metrics!.shaderState != 'ready'; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }
      expect(metrics!.shaderState, 'ready');
      expect(
        metrics!.route,
        'mesh',
        reason: 'cold same-data fallback while lookup pending',
      );
      Future<void> complete(int index) async {
        final image = (await tester.runAsync(
          () => FluviWaveDebugScope.createTexture(pending[index].$1),
        ))!;
        pending[index].$2.complete(image);
        await tester.pump();
        await tester.pump();
      }

      await complete(0);
      expect(
        metrics!.route,
        'shader',
        reason: 'actual shader paint, not compilation alone',
      );
      expect(identical(metrics!.terrain, metrics!.textureTerrain), isTrue);
      await tester.pumpWidget(host(b));
      expect(
        metrics!.route,
        'mesh',
        reason: 'B must not use already-loaded A lookup',
      );
      await tester.pumpWidget(host(c));
      await complete(2);
      expect(metrics!.route, 'shader');
      expect(identical(metrics!.terrain, pending[2].$1), isTrue);
      await complete(1); // B finishes after C; no stale publication.
      expect(identical(metrics!.textureTerrain, pending[2].$1), isTrue);
      final requests = metrics!.textureRequests;
      final geometryBuilds = metrics!.geometryBuilds;
      for (final x in [1.0, 238.0, 110.0]) {
        await tester.tapAt(
          tester.getTopLeft(find.byType(FluviTopographicWaveChart)) +
              Offset(x, 80),
        );
        await tester.pump();
      }
      expect(metrics!.textureRequests, requests);
      expect(metrics!.geometryBuilds, geometryBuilds);
      await tester.pumpWidget(host(a)); // pending A2
      await tester.pumpWidget(host(waveData(waveLinked(List.filled(31, 0)))));
      expect(metrics!.route, 'empty');
      final publications = metrics!.texturePublications;
      await complete(3);
      expect(
        metrics!.texturePublications,
        publications,
        reason: 'zero month cancels pending data',
      );
      await tester.pumpWidget(host(b));
      await tester.pumpWidget(
        host(b, style: FluviTopographicWaveStyle.terrain),
      );
      await complete(4);
      expect(metrics!.route, 'mesh');
      expect(metrics!.textureTerrain, isNull);
      await tester.pumpWidget(host(c));
      await tester.pumpWidget(const SizedBox());
      await complete(5);
      expect(metrics!.disposed, isTrue);
      expect(metrics!.textureDisposals, metrics!.textureRequests);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WR-06 production-parent baseline, complete sparse month', (
    tester,
  ) async {
    const viewport = Size(412, 892);
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      waveLinked(waveSparseForints(31)),
    );
    final settings = BalancePresentationController(
      initial: const BalancePresentationSettings.defaults().copyWith(
        monthlySpendingChartPresentation:
            BalanceMonthlySpendingChartPresentation.topographic,
        usesChildCards: false,
      ),
    );
    addTearDown(linked.dispose);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      waveProductionParent(linked: linked, settings: settings),
    );
    await tester.pump();
    expect(find.byType(BalanceAlternativeSavingsRingCard), findsOneWidget);
    final chartFinder = find.byType(FluviTopographicWaveChart);
    final chart = tester.widget<FluviTopographicWaveChart>(chartFinder);
    expect(chart.values, hasLength(31));
    expect(chart.values[1].value, 26800000);
    final paintFinder = find
        .descendant(of: chartFinder, matching: find.byType(CustomPaint))
        .last;
    final dynamic painter = tester.widget<CustomPaint>(paintFinder).painter;
    final terrain = painter.terrain as FluviTopographicWaveTerrain;
    final minDepth = List.generate(
      terrain.ridgeSamples.length,
      (i) => terrain.surfaceFootSamples[i].dy - terrain.ridgeSamples[i].dy,
    ).reduce(math.min);
    final bounds = tester.getRect(chartFinder);
    final transform = tester
        .renderObject(chartFinder)
        .getTransformTo(null)
        .storage
        .toList();
    final snapshot = <String, Object?>{
      'dataset': 'sparse-31-synthetic-268k',
      'selectedStyle': chart.style.name,
      'route': painter.surfaceShader == null ? 'mesh' : 'shader-requested',
      'chartLocalSize': '${terrain.size}',
      'chartGlobalBounds': '$bounds',
      'transformToRoot': transform,
      'financialPlot': '${terrain.plot}',
      'minSameXDepth': minDepth,
      'highestDay': chart.values[terrain.highestIndex!].key,
    };
    final image = await waveCapture(
      tester,
      find.byKey(const ValueKey('wave-production-parent')),
    );
    await waveWriteEvidence(tester, image, 'production-sparse', snapshot);
    image.dispose();
    debugPrint('WR-06 $snapshot');
    FluviWaveRenderMetrics? metrics;
    await tester.pumpWidget(
      waveProductionParent(
        linked: linked,
        settings: settings,
        wrap: (child) => FluviWaveDebugScope(
          opaqueBody: true,
          bounds: true,
          onPaint: (value) => metrics = value,
          child: child,
        ),
      ),
    );
    await tester.pump();
    final body = await waveCapture(
      tester,
      find.byKey(const ValueKey('wave-production-parent')),
    );
    await waveWriteEvidence(tester, body, 'production-opaque-bounds', {
      'dataset': 'sparse-31-synthetic-268k',
      ...metrics!.snapshot(),
    });
    body.dispose();
    expect(metrics!.route, 'opaque-diagnostic');
    expect(tester.takeException(), isNull);
  });
}

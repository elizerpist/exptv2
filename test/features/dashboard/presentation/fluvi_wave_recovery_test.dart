import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fluvi_wave_fixture.dart';
import '../../../support/dashboard_render_resources.dart';

void main() {
  test('WR-08 isolated peaks are rounded without clipped flat samples', () {
    final data = waveData(waveLinked(waveReferenceForints));
    final terrain = FluviTopographicWaveTerrain.resolve(
      values: data,
      size: const Size(240, 128),
    );
    for (var i = 1; i < data.length - 1; i++) {
      if (data[i].value > data[i - 1].value &&
          data[i].value > data[i + 1].value) {
        final y = terrain.dataOffsets[i].dy;
        expect(
          terrain.ridgeSamples[i * 14 - 1].dy,
          greaterThan(y),
          reason: 'left of isolated day ${i + 1} peak',
        );
        expect(
          terrain.ridgeSamples[i * 14 + 1].dy,
          greaterThan(y),
          reason: 'right of isolated day ${i + 1} peak',
        );
      }
    }
  });
  setUpAll(() async {
    await prepareDashboardTestRenderResources();
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

  testWidgets(
    'WR-15/19 real Dashboard host preserves tap/vertical ownership and warm cache',
    (tester) async {
      const viewport = Size(412, 892);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        waveLinked(waveReferenceForints),
      );
      final settings = BalancePresentationController(
        initial: const BalancePresentationSettings.defaults().copyWith(
          usesChildCards: true,
          monthlySpendingChartPresentation:
              BalanceMonthlySpendingChartPresentation.topographic,
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      var starts = 0;
      var ends = 0;
      var delta = 0.0;
      FluviWaveRenderMetrics? metrics;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluviWaveDebugScope(
              onPaint: (value) => metrics = value,
              child: DashboardCoreModeHost(
                controller: controller,
                presentationFor: (mode) => DashboardCoreModePresentation(
                  geometry: DashboardGeometryResolver.resolve(
                    metrics: DashboardLayoutMetrics.reference.fitToViewport(
                      viewport,
                    ),
                    mode: mode,
                    collapseProgress: 0,
                    isRailExpanded: false,
                    hasPhysicalRail: false,
                  ),
                  palette: DashboardModePaletteResolver.resolve(mode),
                ),
                balanceLinkedPresentation: linked,
                balancePresentationSettings: settings,
                onVerticalExpansionStart: () => starts++,
                onVerticalExpansionDragBy: (value) => delta += value,
                onVerticalExpansionEnd: () => ends++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final chart = find.byType(FluviTopographicWaveChart);
      final state = tester.state(chart);
      final terrain = metrics!.terrain;
      final builds = metrics!.geometryBuilds;
      final requests = metrics!.textureRequests;
      final bounds = tester.getRect(chart);
      final clock = Stopwatch()..start();
      for (var i = 0; i < 30; i++) {
        await tester.tapAt(
          Offset(
            bounds.left + 10 + (bounds.width - 20) * i / 29,
            bounds.center.dy,
          ),
        );
        await tester.pump();
      }
      clock.stop();
      expect(starts, 0);
      expect(metrics!.selectedKey, 31);
      expect(identical(tester.state(chart), state), isTrue);
      expect(identical(metrics!.terrain, terrain), isTrue);
      expect(metrics!.geometryBuilds, builds);
      expect(metrics!.textureRequests, requests);
      await tester.drag(chart, const Offset(0, -65));
      await tester.pump();
      expect(starts, 1);
      expect(ends, 1);
      expect(delta, lessThan(0));
      expect(
        metrics!.selectedKey,
        31,
        reason: 'a vertical drag is not a selection',
      );
      expect(controller.committedMode, DashboardModeSpec.balance);
      expect(identical(tester.state(chart), state), isTrue);
      expect(tester.takeException(), isNull);
      debugPrint(
        'WR-19 software/proot only: 30 warm selections ${clock.elapsedMicroseconds} us; ${metrics!.snapshot()}',
      );
      await tester.pumpWidget(const SizedBox());
      expect(metrics!.disposed, isTrue);
    },
  );

  for (final (year, month, days) in [
    (2026, 2, 28),
    (2024, 2, 29),
    (2026, 6, 30),
    (2026, 7, 31),
  ]) {
    test(
      'WR-08/09 exact calendar and oblique shell depth, $days calendar days',
      () {
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
          for (var day = 0; day < days; day++) {
            final point = terrain.dataOffsets[day];
            expect(
              point.dx,
              closeTo(
                terrain.plot.left + terrain.plot.width * day / (days - 1),
                1e-9,
              ),
            );
            expect(
              terrain.financialBaseline - point.dy,
              closeTo(
                (terrain.financialBaseline - terrain.plot.top) *
                    amounts[day] /
                    268000,
                1e-9,
              ),
              reason:
                  'every exact daily amount uses one linear scale, including genuine zero days',
            );
            expect(terrain.ridgeSamples[day * 14], point);
          }
          for (var i = 0; i < terrain.ridgeSamples.length; i++) {
            final ridge = terrain.ridgeSamples[i];
            final foot = terrain.surfaceFootSamples[i];
            expect(foot.dx, greaterThan(ridge.dx));
            expect(foot.dx, lessThan(size.width));
            expect(
              foot.dy - ridge.dy,
              greaterThan(0),
              reason:
                  'size=$size sample=$i x=${ridge.dx}; zero/small days must have positive visible depth',
            );
            expect(foot.dy, lessThan(size.height));
          }
        }
      },
    );
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
    'HS-07 lookup carries visible projected normals and section depth',
    (tester) async {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: const [
          FluviTopographicWaveDatum(key: 1, value: 100, label: '1'),
          FluviTopographicWaveDatum(key: 2, value: 100, label: '2'),
        ],
        size: const Size(240, 128),
      );
      final texture = (await tester.runAsync(
        () => FluviWaveDebugScope.createTexture(terrain),
      ))!;
      final bytes = (await tester.runAsync(() => texture.toByteData()))!;
      expect(texture.width, 480);
      expect(texture.height, 256);
      expect(bytes.getUint8(3), 0, reason: 'No geometry outside the shell');
      for (final depth in [.1, .25, .4]) {
        final sample = terrain.shell!.sample(7, depth);
        final x = (sample.position.dx * 2).floor();
        final y = (sample.position.dy * 2).floor();
        final offset = (y * texture.width + x) * 4;
        expect(bytes.getUint8(offset + 3), 255);
        final nx = bytes.getUint8(offset) / 255 * 2 - 1;
        final ny = bytes.getUint8(offset + 1) / 255 * 2 - 1;
        final encodedDepth = bytes.getUint8(offset + 2) / 255;
        expect(nx, closeTo(sample.normal.$1, .025));
        expect(ny, closeTo(sample.normal.$2, .05));
        expect(encodedDepth, closeTo(depth, .025));
      }
      texture.dispose();
    },
  );

  testWidgets(
    'HS-07 sloped normals and recessed overlap match the visible shell',
    (tester) async {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: waveData(waveLinked(waveReferenceForints)),
        size: const Size(240, 128),
      );
      final shell = terrain.shell!;
      final texture = (await tester.runAsync(
        () => FluviWaveDebugScope.createTexture(terrain),
      ))!;
      final bytes = (await tester.runAsync(() => texture.toByteData()))!;
      final vertices = [
        for (var column = 0; column < shell.ridge.length; column++)
          for (var row = 0; row < FluviWaveShell.rows; row++)
            shell.sample(column, row / (FluviWaveShell.rows - 1)),
      ];
      var outer = 0;
      var inner = 0;
      var overlap = 0;
      for (final column in [0, 35, 56, 112, 182, 196, 224, 280, 350, 420]) {
        for (final depth in [.2, .4, .75, .9]) {
          final target = shell.sample(column, depth).position;
          final x = (target.dx * 2).floor();
          final y = (target.dy * 2).floor();
          final offset = (y * texture.width + x) * 4;
          if (bytes.getUint8(offset + 3) != 255) continue;
          final expected = _visibleShellSample(
            vertices,
            Offset((x + .5) / 2, (y + .5) / 2),
          );
          if (expected == null || expected.margin < .05) continue;
          expect(
            bytes.getUint8(offset) / 255 * 2 - 1,
            closeTo(expected.nx, .055),
          );
          expect(
            bytes.getUint8(offset + 1) / 255 * 2 - 1,
            closeTo(expected.ny, .055),
          );
          expect(
            bytes.getUint8(offset + 2) / 255,
            closeTo(expected.depth, .035),
          );
          if (expected.depth < .5 && expected.nx.abs() > .08) outer++;
          if (expected.depth > .65) inner++;
          if (expected.farthest - expected.depth > .15) overlap++;
        }
      }
      texture.dispose();
      debugPrint(
        'HS-07 atlas sloped outer=$outer inner=$inner overlaps=$overlap',
      );
      expect(outer, greaterThan(0));
      expect(inner, greaterThan(0));
      expect(overlap, greaterThan(0));
    },
  );

  testWidgets(
    'WR-15 exact edge selection and painted marker/tooltip containment',
    (tester) async {
      const viewport = Size(320, 692);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        waveLinked(waveSparseForints(31, peak: 0)),
      );
      final settings = BalancePresentationController(
        initial: const BalancePresentationSettings.defaults().copyWith(
          monthlySpendingChartPresentation:
              BalanceMonthlySpendingChartPresentation.topographic,
        ),
      );
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      FluviWaveRenderMetrics? metrics;
      await tester.pumpWidget(
        waveProductionParent(
          linked: linked,
          settings: settings,
          viewport: viewport,
          wrap: (child) => FluviWaveDebugScope(
            onPaint: (value) => metrics = value,
            child: child,
          ),
        ),
      );
      final initial = metrics!.terrain;
      final initialState = tester.state(find.byType(FluviTopographicWaveChart));
      for (final (fraction, index) in [(0.0, 0), (1.0, 30)]) {
        final bounds = tester.getRect(find.byType(FluviTopographicWaveChart));
        await tester.tapAt(
          Offset(
            bounds.left + 1 + (bounds.width - 2) * fraction,
            bounds.center.dy,
          ),
        );
        await tester.pump();
        expect(metrics!.selectedIndex, index);
        expect(
          identical(
            initialState,
            tester.state(find.byType(FluviTopographicWaveChart)),
          ),
          isTrue,
        );
        expect(metrics!.terrain!.values[index].key, index + 1);
        expect(metrics!.selectedKey, index + 1);
        expect(
          metrics!.selectedValueMinor,
          metrics!.terrain!.values[index].value,
        );
        expect(
          metrics!.tooltipText,
          DashboardPreparedFormatter.compactAmountMinor(
            metrics!.selectedValueMinor!,
          ),
        );
        expect(identical(initial, metrics!.terrain), isTrue);
        for (final rect in [metrics!.markerBounds!, metrics!.tooltipBounds!]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(metrics!.terrain!.size.width));
          expect(rect.bottom, lessThanOrEqualTo(metrics!.terrain!.size.height));
        }
      }
    },
  );

  testWidgets('WR-12 failed shader load keeps the same-data painted fallback', (
    tester,
  ) async {
    FluviWaveRenderMetrics? metrics;
    final values = waveData(waveLinked(waveReferenceForints));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            height: 128,
            child: FluviWaveDebugScope(
              programLoader: () =>
                  Future.error(StateError('controlled shader load failure')),
              onPaint: (value) => metrics = value,
              child: FluviTopographicWaveChart(
                values: values,
                style: FluviTopographicWaveStyle.shaderAtmosphere,
                tooltipForValue: DashboardPreparedFormatter.compactAmountMinor,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(metrics!.shaderState, 'failed');
    expect(metrics!.shaderError, contains('controlled shader load failure'));
    expect(metrics!.route, 'mesh');
    expect(metrics!.terrain!.values, values);
    expect(metrics!.selectedIndex, 14);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    expect(tester.takeException(), isNull);
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
      expect(metrics!.lookupRequestToPaintMicros, greaterThan(0));
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
      debugPrint(
        'WR-19 retained production resource lifecycle ${metrics!.snapshot()}',
      );
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
        usesChildCards: true,
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
      'minCorrespondingDownDepth': minDepth,
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

// Independent visibility oracle: find all intersecting projected triangles
// and choose minimum physical depth, not the renderer's draw ordering.
({double nx, double ny, double depth, double farthest, double margin})?
_visibleShellSample(List<FluviWaveShellPoint> vertices, Offset target) {
  const rows = FluviWaveShell.rows;
  final columns = vertices.length ~/ rows;
  ({double nx, double ny, double depth, double farthest, double margin})?
  winner;
  var farthest = 0.0;
  for (var column = 0; column < columns - 1; column++) {
    for (var row = 0; row < rows - 1; row++) {
      final left = column * rows + row;
      final right = (column + 1) * rows + row;
      for (final triangle in [
        (left, right, left + 1),
        (right, right + 1, left + 1),
      ]) {
        final a = vertices[triangle.$1];
        final b = vertices[triangle.$2];
        final c = vertices[triangle.$3];
        final p = target - a.position;
        final ab = b.position - a.position;
        final ac = c.position - a.position;
        final determinant = ab.dx * ac.dy - ac.dx * ab.dy;
        if (determinant.abs() < 1e-10) continue;
        final wb = (p.dx * ac.dy - ac.dx * p.dy) / determinant;
        final wc = (ab.dx * p.dy - p.dx * ab.dy) / determinant;
        final wa = 1 - wb - wc;
        if (wa < 0 || wb < 0 || wc < 0) continue;
        final depth =
            (wa * (triangle.$1 % rows) +
                wb * (triangle.$2 % rows) +
                wc * (triangle.$3 % rows)) /
            (rows - 1);
        farthest = math.max(farthest, depth);
        if (winner != null && depth >= winner.depth) continue;
        winner = (
          nx: wa * a.normal.$1 + wb * b.normal.$1 + wc * c.normal.$1,
          ny: wa * a.normal.$2 + wb * b.normal.$2 + wc * c.normal.$2,
          depth: depth,
          farthest: 0,
          margin: math.min(wa, math.min(wb, wc)),
        );
      }
    }
  }
  return winner == null
      ? null
      : (
          nx: winner.nx,
          ny: winner.ny,
          depth: winner.depth,
          farthest: farthest,
          margin: winner.margin,
        );
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ORB-MATERIAL-01 filters the full static header field into a square launcher texture',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect)
        ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
        ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false);
      const frame = DashboardHeaderVisualFrame(
        colors: <Color>[
          Color(0xffffb37b),
          Color(0xffff79a8),
          Color(0xff8f5ee8),
        ],
        stops: <double>[0, .5, 1],
        opacity: 1,
        colorA: Color(0xffffb37b),
        colorB: Color(0xff8f5ee8),
      );
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: frame,
      );
      final renderer = DashboardHeaderMaterialFrameRenderer();
      final header = (await tester.runAsync(
        () => renderer.render(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          offset: Duration.zero,
        ),
      ))!;
      final orb = (await tester.runAsync(
        () => DashboardHeaderOrbFrameMapper.map(header: header, orbSizePx: 80),
      ))!;
      try {
        final headerPixels = (await tester.runAsync(() => _rgba(header)))!;
        final orbPixels = (await tester.runAsync(() => _rgba(orb)))!;
        // The circle's middle row maps from x=0..1 across the complete header
        // rectangle. This catches both a central-square crop and any extra
        // native travelling/radial bands.
        for (final x in <int>[1, 12, 24, 40, 56, 68, 78]) {
          final expectedX = (((x + .5) / 80) * (header.width - 1)).round();
          final expectedY = (((40 + .5) / 80) * (header.height - 1)).round();
          _expectFilteredSample(
            actual: _pixel(orbPixels, 80, x, 40),
            expected: _pixel(headerPixels, header.width, expectedX, expectedY),
            reason: 'orb x=$x must retain the source material without a crop',
          );
        }
        // Android 12+ owns the geometric clip outside this texture. Keeping
        // these pixels opaque proves that no binary circular raster cutout
        // can flicker during a ViewFlipper crossfade.
        expect(_pixel(orbPixels, 80, 0, 0).$4, 255);
        expect(_pixel(orbPixels, 80, 79, 0).$4, 255);
        await tester.runAsync(
          () => _writeEvidencePair(
            name: 'balance_static_header_orb_phase_0000ms',
            header: header,
            orb: orb,
            metadata: const <String, Object?>{
              'mode': 'balance',
              'effect': 'staticEffect',
              'phaseOffsetMs': 0,
              'headerSizePx': <int>[412, 188],
              'orbSizePx': 80,
              'renderer': 'DashboardHeaderStaticColorRenderer',
              'mapping': 'full-header-normalized-rectangle-to-filtered-square',
            },
          ),
        );
      } finally {
        header.dispose();
        orb.dispose();
        renderer.dispose();
        controller.dispose();
      }
    },
  );

  testWidgets(
    'ORB-MATERIAL-01b uses partially covered edge pixels only for the legacy alpha fallback',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      const frame = DashboardHeaderVisualFrame(
        colors: <Color>[Color(0xffffb37b), Color(0xff8f5ee8)],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Color(0xffffb37b),
        colorB: Color(0xff8f5ee8),
      );
      final renderer = DashboardHeaderMaterialFrameRenderer();
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: frame,
      );
      final header = (await tester.runAsync(
        () => renderer.render(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          offset: Duration.zero,
        ),
      ))!;
      final orb = (await tester.runAsync(
        () => DashboardHeaderOrbFrameMapper.map(
          header: header,
          orbSizePx: 80,
          applyCircularAlphaMask: true,
        ),
      ))!;
      try {
        final pixels = (await tester.runAsync(() => _rgba(orb)))!;
        final alpha = <int>[
          for (var index = 3; index < pixels.length; index += 4) pixels[index],
        ];
        expect(_pixel(pixels, 80, 0, 0).$4, 0);
        expect(_pixel(pixels, 80, 40, 40).$4, 255);
        expect(alpha.any((value) => value > 0 && value < 255), isTrue);
      } finally {
        header.dispose();
        orb.dispose();
        renderer.dispose();
        controller.dispose();
      }
    },
  );

  testWidgets(
    'ORB-MATERIAL-01c direct orb rendering keeps the full header coordinate field',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect)
        ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
        ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false);
      const frame = DashboardHeaderVisualFrame(
        colors: <Color>[
          Color(0xffffb37b),
          Color(0xffff79a8),
          Color(0xff8f5ee8),
        ],
        stops: <double>[0, .5, 1],
        opacity: 1,
        colorA: Color(0xffffb37b),
        colorB: Color(0xff8f5ee8),
      );
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: frame,
      );
      final renderer = DashboardHeaderMaterialFrameRenderer();
      final direct = (await tester.runAsync(
        () => renderer.renderOrbTexture(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          orbSizePx: 80,
          offset: Duration.zero,
        ),
      ))!;
      final header = (await tester.runAsync(
        () => renderer.render(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          offset: Duration.zero,
        ),
      ))!;
      final mapped = (await tester.runAsync(
        () => DashboardHeaderOrbFrameMapper.map(header: header, orbSizePx: 80),
      ))!;
      try {
        final directPixels = (await tester.runAsync(() => _rgba(direct)))!;
        final mappedPixels = (await tester.runAsync(() => _rgba(mapped)))!;
        for (final coordinate in <(int, int)>[
          (1, 1),
          (12, 24),
          (40, 40),
          (68, 56),
          (78, 78),
        ]) {
          _expectFilteredSample(
            actual: _pixel(directPixels, 80, coordinate.$1, coordinate.$2),
            expected: _pixel(mappedPixels, 80, coordinate.$1, coordinate.$2),
            reason: 'direct shader texture must retain complete header mapping',
          );
        }
      } finally {
        direct.dispose();
        header.dispose();
        mapped.dispose();
        renderer.dispose();
        controller.dispose();
      }
    },
  );

  testWidgets(
    'ORB-MATERIAL-01d direct shader texture keeps animated header aspect and phase',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.dualTide)
        ..setEffectControl('speed', .24)
        ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
        ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false);
      const frame = DashboardHeaderVisualFrame(
        colors: <Color>[
          Color(0xffffb37b),
          Color(0xffff79a8),
          Color(0xff8f5ee8),
        ],
        stops: <double>[0, .5, 1],
        opacity: 1,
        colorA: Color(0xffffb37b),
        colorB: Color(0xff8f5ee8),
      );
      final backend = DashboardHeaderFragmentBackend();
      final renderer = DashboardHeaderMaterialFrameRenderer(backend: backend);
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: frame,
      );
      const offset = Duration(milliseconds: 1250);
      final direct = (await tester.runAsync(
        () => renderer.renderOrbTexture(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          orbSizePx: 80,
          offset: offset,
        ),
      ))!;
      final header = (await tester.runAsync(
        () => renderer.render(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          offset: offset,
        ),
      ))!;
      final mapped = (await tester.runAsync(
        () => DashboardHeaderOrbFrameMapper.map(header: header, orbSizePx: 80),
      ))!;
      try {
        expect(backend.isReady, isTrue);
        final directPixels = (await tester.runAsync(() => _rgba(direct)))!;
        final mappedPixels = (await tester.runAsync(() => _rgba(mapped)))!;
        for (final coordinate in <(int, int)>[
          (8, 8),
          (24, 36),
          (40, 40),
          (64, 52),
          (72, 70),
        ]) {
          _expectFilteredSample(
            actual: _pixel(directPixels, 80, coordinate.$1, coordinate.$2),
            expected: _pixel(mappedPixels, 80, coordinate.$1, coordinate.$2),
            reason:
                'direct shader texture must preserve source aspect and phase',
          );
        }
      } finally {
        direct.dispose();
        header.dispose();
        mapped.dispose();
        renderer.dispose();
        backend.dispose();
        controller.dispose();
      }
    },
  );

  testWidgets(
    'ORB-MATERIAL-02 keeps two production effects distinct at one explicit phase',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
        ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false)
        // The exported offset is the complete clock input. Freezing the
        // visible controller makes this acceptance phase reproducible.
        ..setMotionEnabled(false);
      const frame = DashboardHeaderVisualFrame(
        colors: <Color>[
          Color(0xffffb37b),
          Color(0xffff79a8),
          Color(0xff8f5ee8),
        ],
        stops: <double>[0, .5, 1],
        opacity: 1,
        colorA: Color(0xffffb37b),
        colorB: Color(0xff8f5ee8),
      );
      final backend = DashboardHeaderFragmentBackend();
      final renderer = DashboardHeaderMaterialFrameRenderer(backend: backend);
      final fingerprints = <int>{};
      const headerSize = Size(412, 188);
      const samples = <int>[0, 1250, 2500, 3750];
      try {
        for (final effect in <DashboardHeaderEffectId>[
          DashboardHeaderEffectId.dualTide,
          DashboardHeaderEffectId.braidedCurrent,
        ]) {
          controller.selectEffect(effect);
          controller.setEffectControl('speed', .24);
          final snapshot = DashboardHeaderMaterialSnapshot.capture(
            controller: controller,
            frame: frame,
          );
          for (final offsetMs in samples) {
            final header = (await tester.runAsync(
              () => renderer.render(
                snapshot: snapshot,
                headerSize: headerSize,
                offset: Duration(milliseconds: offsetMs),
              ),
            ))!;
            final orb = (await tester.runAsync(
              () => DashboardHeaderOrbFrameMapper.map(
                header: header,
                orbSizePx: 80,
              ),
            ))!;
            try {
              final headerPixels = (await tester.runAsync(
                () => _rgba(header),
              ))!;
              final orbPixels = (await tester.runAsync(() => _rgba(orb)))!;
              _expectMappedCentreLine(
                headerPixels: headerPixels,
                headerWidth: header.width,
                headerHeight: header.height,
                orbPixels: orbPixels,
                orbSize: orb.width,
              );
              if (offsetMs == 1250) {
                fingerprints.add(_fingerprint(headerPixels));
              }
              await tester.runAsync(
                () => _writeEvidencePair(
                  name:
                      'balance_${effect.name}_header_orb_phase_${offsetMs.toString().padLeft(4, '0')}ms',
                  header: header,
                  orb: orb,
                  metadata: <String, Object?>{
                    'mode': 'balance',
                    'effect': effect.name,
                    'phaseOffsetMs': offsetMs,
                    'headerSizePx': <int>[412, 188],
                    'orbSizePx': 80,
                    'renderer':
                        'DashboardHeaderFragmentBackend/dashboard_header_field.frag',
                    'mapping':
                        'full-header-normalized-rectangle-to-filtered-square',
                    'launcherPlayback':
                        'sampled ViewFlipper package; not a live shader',
                  },
                ),
              );
            } finally {
              header.dispose();
              orb.dispose();
            }
          }
        }
        expect(
          backend.isReady,
          isTrue,
          reason: 'animated material evidence must use the production shader',
        );
        expect(
          fingerprints.length,
          2,
          reason:
              'different Header effects may share a palette but not a field',
        );
        await tester.runAsync(
          () => _writeEvidenceManifest(<String, Object?>{
            'comparison': 'balance-header-orb-two-effects',
            'effects': <String>['dualTide', 'braidedCurrent'],
            'sampleOffsetsMs': samples,
            'phaseClock': 'frozen-controller + explicit renderer offset',
            'framesFromOriginalRenderer': true,
            'launcherLimitation':
                'ViewFlipper repeats finite samples; non-periodic effects can show a seam.',
          }),
        );
      } finally {
        renderer.dispose();
        backend.dispose();
        controller.dispose();
      }
    },
  );
}

Future<Uint8List> _rgba(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) throw StateError('Pixels unavailable.');
  return data.buffer.asUint8List();
}

(int, int, int, int) _pixel(Uint8List pixels, int width, int x, int y) {
  final index = (y * width + x) * 4;
  return (
    pixels[index],
    pixels[index + 1],
    pixels[index + 2],
    pixels[index + 3],
  );
}

void _expectMappedCentreLine({
  required Uint8List headerPixels,
  required int headerWidth,
  required int headerHeight,
  required Uint8List orbPixels,
  required int orbSize,
}) {
  final y = orbSize ~/ 2;
  final expectedY = (((y + .5) / orbSize) * (headerHeight - 1)).round();
  for (final x in <int>[1, 12, 24, 40, 56, 68, 78]) {
    final expectedX = (((x + .5) / orbSize) * (headerWidth - 1)).round();
    _expectFilteredSample(
      actual: _pixel(orbPixels, orbSize, x, y),
      expected: _pixel(headerPixels, headerWidth, expectedX, expectedY),
      reason: 'the centre line may contain the source field only once',
    );
  }
}

void _expectFilteredSample({
  required (int, int, int, int) actual,
  required (int, int, int, int) expected,
  required String reason,
}) {
  // drawImageRect uses filtered sampling instead of the former round() lookup.
  // A one-source-pixel tolerance keeps the assertion about coordinate ownership
  // while explicitly permitting proper reconstruction filtering.
  for (final pair in <(int, int)>[
    (actual.$1, expected.$1),
    (actual.$2, expected.$2),
    (actual.$3, expected.$3),
    (actual.$4, expected.$4),
  ]) {
    expect((pair.$1 - pair.$2).abs(), lessThanOrEqualTo(8), reason: reason);
  }
}

int _fingerprint(Uint8List pixels) {
  var value = 0x811c9dc5;
  for (final byte in pixels) {
    value = ((value ^ byte) * 0x01000193) & 0x7fffffff;
  }
  return value;
}

const _evidenceDirectory = String.fromEnvironment('FLUVI_ORB_EVIDENCE');

Future<void> _writeEvidencePair({
  required String name,
  required ui.Image header,
  required ui.Image orb,
  required Map<String, Object?> metadata,
}) async {
  if (_evidenceDirectory.isEmpty) return;
  final directory = Directory(_evidenceDirectory)..createSync(recursive: true);
  final headerBytes = await header.toByteData(format: ui.ImageByteFormat.png);
  final orbBytes = await orb.toByteData(format: ui.ImageByteFormat.png);
  if (headerBytes == null || orbBytes == null) {
    throw StateError('Unable to encode Header/orb evidence.');
  }
  File(
    '${directory.path}/$name-header.png',
  ).writeAsBytesSync(headerBytes.buffer.asUint8List());
  File(
    '${directory.path}/$name-orb.png',
  ).writeAsBytesSync(orbBytes.buffer.asUint8List());
  File(
    '${directory.path}/$name.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metadata));
}

Future<void> _writeEvidenceManifest(Map<String, Object?> value) async {
  if (_evidenceDirectory.isEmpty) return;
  final directory = Directory(_evidenceDirectory)..createSync(recursive: true);
  File(
    '${directory.path}/manifest.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
}

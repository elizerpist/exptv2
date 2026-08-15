import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'RED: LogBox category glyphs stay self-contained vector display lists through row paint',
    () {
      final atlas = File(
        'lib/core/assets/prepared_vector_asset_atlas.dart',
      ).readAsStringSync();
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final logBoxGlyphPreparation = atlas.substring(
        atlas.indexOf('final class PreparedLogBoxVectorGlyph'),
        atlas.indexOf('  static Future<ui.Image> _rasterizeGroupSurface'),
      );

      expect(atlas, contains('PreparedLogBoxVectorGlyph'));
      expect(atlas, isNot(contains('_rasterizeWhiteIconAtlas')));
      expect(logBoxGlyphPreparation, isNot(contains('BlendMode.srcIn')));
      expect(logBoxGlyphPreparation, isNot(contains('drawColor(Colors.white')));
      expect(renderer, contains('_drawPreparedVectorGlyph('));
      expect(renderer, isNot(contains('rasters.icon(')));
      expect(renderer, isNot(contains('saveLayer(')));
      expect(renderer, isNot(contains('ColorFilter')));
      expect(renderer, isNot(contains('TextPainter(')));
      expect(renderer, isNot(contains('PreparedVectorAssetAtlas.instance')));
    },
  );

  test(
    'RED: LogBox avatar badges stay precompiled vector resources in both row painters',
    () {
      final atlas = File(
        'lib/core/assets/prepared_vector_asset_atlas.dart',
      ).readAsStringSync();
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();
      final committedItem = renderer.substring(
        renderer.indexOf('  void _paintCommittedItem('),
        renderer.indexOf('  void _recordVerticalCacheMiss('),
      );
      final previewItem = renderer.substring(
        renderer.indexOf('  bool _paintItem('),
        renderer.indexOf('  void _recordTextLayoutMiss('),
      );

      expect(atlas, contains('final class PreparedLogBoxVectorBadge'));
      expect(atlas, isNot(contains('_rasterizeBadgeAtlas')));
      for (final itemPainter in <String>[committedItem, previewItem]) {
        expect(itemPainter, contains('_drawPreparedVectorBadge('));
        expect(itemPainter, isNot(contains('_drawPreparedImage(')));
        expect(itemPainter, isNot(contains('drawImageRect(')));
      }
    },
  );

  testWidgets(
    'RED: a prepared LogBox glyph cannot modify sentinels outside its target',
    (tester) async {
      final atlas = PreparedVectorAssetAtlas();
      addTearDown(atlas.dispose);
      await atlas.prepare();
      await atlas.prepareLogBoxRasters(devicePixelRatio: 1);
      final rasters = atlas.logBoxRastersFor(1);

      final image = (await tester.runAsync(
        () => _paintGlyphSentinels(
          first: rasters.glyph(0),
          second: rasters.glyph(1),
        ),
      ))!;
      addTearDown(image.dispose);
      final pixels = (await tester.runAsync(() => _readPixels(image)))!;

      expect(
        pixels.colorAt(110, 110),
        _canvasSentinel,
        reason:
            'The reusable glyph display list may only affect its icon target, '
            'not the already painted outer LogBox canvas.',
      );
      expect(
        pixels.colorAt(80, 24),
        _firstRowSentinel,
        reason: 'Drawing glyph N+1 must not erase the first row.',
      );
      expect(
        pixels.colorAt(80, 76),
        _secondRowSentinel,
        reason: 'Drawing a glyph must not erase its own surrounding row.',
      );
      expect(
        pixels.countColorIn(_firstGlyphTarget, Colors.white),
        greaterThan(0),
        reason: 'The glyph target must still receive opaque white vector ink.',
      );
      expect(
        pixels.countColorIn(_secondGlyphTarget, Colors.white),
        greaterThan(0),
        reason: 'Each independently drawn glyph must render its own ink.',
      );
    },
  );

  testWidgets(
    'prepares every unique vector once and reuses pictures across remounts',
    (tester) async {
      final atlas = PreparedVectorAssetAtlas();

      await Future.wait(<Future<void>>[atlas.prepare(), atlas.prepare()]);

      expect(atlas.isReady, isTrue);
      expect(atlas.pictureCount, PreparedVectorAssetAtlas.assetCount);
      expect(
        atlas.logBoxGlyphCount,
        PreparedVectorAssetAtlas.logBoxGlyphAssetCount,
      );
      expect(
        atlas.pictureDecodeCount,
        PreparedVectorAssetAtlas.uniqueAssetCount,
      );
      expect(atlas.prepareDurationMicros, greaterThan(0));
      final decodeCount = atlas.pictureDecodeCount;
      await atlas.prepare();
      expect(atlas.pictureDecodeCount, decodeCount);

      final picture = atlas.categoryIcon(
        CategoryIconCatalog.handleOf('icon_02'),
      );
      for (var index = 0; index < 10; index += 1) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: PreparedVectorPictureView(
                picture: picture,
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            ),
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }

      expect(atlas.pictureDecodeCount, decodeCount);
      expect(
        atlas.categoryGradient(CategoryColorCatalog.handleOf('color_07')),
        same(atlas.categoryGradient(CategoryColorCatalog.handleOf('color_07'))),
      );
      atlas.dispose();
    },
  );

  test('rejects picture access before the bootstrap preparation completes', () {
    final atlas = PreparedVectorAssetAtlas();

    expect(
      () => atlas.categoryIcon(CategoryIconCatalog.handleOf('icon_01')),
      throwsStateError,
    );

    atlas.dispose();
  });

  testWidgets(
    'prepares bounded DPR-aware LogBox group raster and vector avatars without row cardinality',
    (tester) async {
      final atlas = PreparedVectorAssetAtlas();
      await atlas.prepare();
      final decodeCount = atlas.pictureDecodeCount;

      await Future.wait(<Future<void>>[
        atlas.prepareLogBoxRasters(devicePixelRatio: 1),
        atlas.prepareLogBoxRasters(devicePixelRatio: 1),
      ]);

      final rasters = atlas.logBoxRastersFor(1);
      expect(
        rasters.rasterSurfaceCount,
        1,
        reason:
            'The group nine-slice remains raster-backed; each visible avatar '
            'badge and glyph must remain an independent vector display list.',
      );
      expect(rasters.badgeCount, CategoryColorCatalog.allWithFallback.length);
      expect(rasters.glyphCount, CategoryIconCatalog.allWithFallback.length);
      final badge = rasters.badge(0);
      expect(badge.picture, isA<ui.Picture>());
      expect(badge.logicalSize, const Size.square(34));
      final glyph = rasters.glyph(0);
      expect(glyph.logicalSize, const Size.square(24));
      expect(glyph.picture, isA<ui.Picture>());
      expect(glyph.picture.debugDisposed, isFalse);
      expect(atlas.pictureDecodeCount, decodeCount);
      expect(atlas.logBoxBadgeBuildCount, 1);
      expect(atlas.logBoxGlyphBuildCount, 1);
      expect(atlas.logBoxRasterByteEstimate, greaterThan(0));
      expect(atlas.logBoxRasterByteEstimate, lessThan(4 * 1024 * 1024));
      expect(atlas.logBoxRasterSurfaceCount, 1);
      expect(rasters.groupSurface.width, 128);
      expect(rasters.groupSurface.height, 128);
      expect(rasters.groupSurfaceCenterSlice, isNot(Rect.zero));
      expect(atlas.logBoxRasterBuildCount, 1);

      await atlas.prepareLogBoxRasters(devicePixelRatio: 1);
      expect(atlas.logBoxRasterBuildCount, 1);
      expect(atlas.logBoxRastersFor(1), same(rasters));

      await atlas.prepareLogBoxRasters(devicePixelRatio: 2);
      expect(atlas.logBoxRasterBuildCount, 2);
      expect(atlas.logBoxBadgeBuildCount, 1);
      expect(atlas.logBoxGlyphBuildCount, 1);
      expect(atlas.pictureDecodeCount, decodeCount);
      expect(atlas.logBoxRastersFor(2).badge(0), same(badge));
      expect(atlas.logBoxRastersFor(2).glyph(0), same(glyph));
      atlas.dispose();
      expect(badge.picture.debugDisposed, isTrue);
      expect(glyph.picture.debugDisposed, isTrue);
    },
  );

  test('rejects LogBox raster access before DPR preparation', () async {
    final atlas = PreparedVectorAssetAtlas();
    await atlas.prepare();

    expect(() => atlas.logBoxRastersFor(3), throwsStateError);
    atlas.dispose();
  });
}

const _canvasSentinel = Color(0xff102030);
const _firstRowSentinel = Color(0xffd9485f);
const _secondRowSentinel = Color(0xff0ea5e9);
const _firstGlyphTarget = Rect.fromLTWH(14, 18, 18, 18);
const _secondGlyphTarget = Rect.fromLTWH(14, 70, 18, 18);

Future<ui.Image> _paintGlyphSentinels({
  required PreparedLogBoxVectorGlyph first,
  required PreparedLogBoxVectorGlyph second,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 120, 120));
  canvas.drawColor(_canvasSentinel, BlendMode.src);
  canvas.drawRect(
    const Rect.fromLTWH(40, 10, 68, 30),
    Paint()..color = _firstRowSentinel,
  );
  canvas.drawRect(
    const Rect.fromLTWH(40, 62, 68, 30),
    Paint()..color = _secondRowSentinel,
  );
  canvas.drawRect(
    _firstGlyphTarget.inflate(4),
    Paint()..color = const Color(0xff7c3aed),
  );
  canvas.drawRect(
    _secondGlyphTarget.inflate(4),
    Paint()..color = const Color(0xff22c55e),
  );
  _drawPreparedGlyph(canvas, first, _firstGlyphTarget);
  _drawPreparedGlyph(canvas, second, _secondGlyphTarget);
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(120, 120);
  } finally {
    picture.dispose();
  }
}

void _drawPreparedGlyph(
  Canvas canvas,
  PreparedLogBoxVectorGlyph glyph,
  Rect target,
) {
  canvas.save();
  canvas.translate(target.left, target.top);
  canvas.scale(
    target.width / glyph.logicalSize.width,
    target.height / glyph.logicalSize.height,
  );
  canvas.drawPicture(glyph.picture);
  canvas.restore();
}

Future<_RgbaPixels> _readPixels(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bytes == null) throw StateError('Could not read the test image pixels.');
  return _RgbaPixels(bytes, image.width, image.height);
}

final class _RgbaPixels {
  const _RgbaPixels(this._bytes, this.width, this.height);

  final ByteData _bytes;
  final int width;
  final int height;

  Color colorAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError('Pixel ($x, $y) is outside $width x $height.');
    }
    final offset = (y * width + x) * 4;
    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }

  int countColorIn(Rect rect, Color color) {
    var count = 0;
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y += 1) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x += 1) {
        if (colorAt(x, y) == color) count += 1;
      }
    }
    return count;
  }
}

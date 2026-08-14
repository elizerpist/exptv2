import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'RED: LogBox category glyphs stay prepared vector display lists through row paint',
    () {
      final atlas = File(
        'lib/core/assets/prepared_vector_asset_atlas.dart',
      ).readAsStringSync();
      final renderer = File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync();

      expect(atlas, contains('PreparedLogBoxVectorGlyph'));
      expect(atlas, isNot(contains('_rasterizeWhiteIconAtlas')));
      expect(renderer, contains('_drawPreparedVectorGlyph('));
      expect(renderer, isNot(contains('rasters.icon(')));
      expect(renderer, isNot(contains('saveLayer(')));
      expect(renderer, isNot(contains('TextPainter(')));
      expect(renderer, isNot(contains('PreparedVectorAssetAtlas.instance')));
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
    'prepares bounded DPR-aware LogBox rasters and vector glyphs without row cardinality',
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
        2,
        reason:
            'Only the badge atlas and group surface are raster-backed; category '
            'glyphs remain vector display lists.',
      );
      expect(rasters.badgeCount, CategoryColorCatalog.allWithFallback.length);
      expect(rasters.glyphCount, CategoryIconCatalog.allWithFallback.length);
      expect(rasters.badge(0).sourceRect.size, const Size.square(34));
      final glyph = rasters.glyph(0);
      expect(glyph.logicalSize, const Size.square(18));
      expect(glyph.picture, isA<ui.Picture>());
      expect(glyph.picture.debugDisposed, isFalse);
      expect(atlas.pictureDecodeCount, decodeCount);
      expect(atlas.logBoxGlyphBuildCount, 1);
      expect(atlas.logBoxRasterByteEstimate, greaterThan(0));
      expect(atlas.logBoxRasterByteEstimate, lessThan(4 * 1024 * 1024));
      expect(atlas.logBoxRasterSurfaceCount, 2);
      expect(rasters.groupSurface.width, 128);
      expect(rasters.groupSurface.height, 128);
      expect(rasters.groupSurfaceCenterSlice, isNot(Rect.zero));
      expect(atlas.logBoxRasterBuildCount, 1);

      await atlas.prepareLogBoxRasters(devicePixelRatio: 1);
      expect(atlas.logBoxRasterBuildCount, 1);
      expect(atlas.logBoxRastersFor(1), same(rasters));

      await atlas.prepareLogBoxRasters(devicePixelRatio: 2);
      expect(atlas.logBoxRasterBuildCount, 2);
      expect(atlas.logBoxGlyphBuildCount, 1);
      expect(atlas.pictureDecodeCount, decodeCount);
      expect(atlas.logBoxRastersFor(2).glyph(0), same(glyph));
      atlas.dispose();
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

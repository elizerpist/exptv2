import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';
import 'package:fluvi/core/categories/presentation/category_avatar_palette_scope.dart';
import 'package:fluvi/core/categories/presentation/category_visual_badge.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses the selected profile while retaining semantic handles', (
    tester,
  ) async {
    await PreparedVectorAssetAtlas.instance.prepare();
    const profile = CategoryAvatarColorProfile.pastel;
    final colorHandle = CategoryColorCatalog.handleOf('color_07');
    final iconHandle = CategoryIconCatalog.handleOf('icon_07');

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryAvatarColorProfileScope(
          profile: profile,
          child: CategoryVisualBadge(
            colorHandle: colorHandle,
            iconHandle: iconHandle,
          ),
        ),
      ),
    );

    final decorated = tester.widget<Container>(find.byType(Container).first);
    final decoration = decorated.decoration! as BoxDecoration;
    expect(
      decoration.gradient!.colors.map((color) => color.toARGB32()).toList(),
      const <int>[0xFF88C28A, 0xFF9AD29B, 0xFFAEE0AF],
    );
    expect(
      find.bySemanticsLabel(
        CategoryIconCatalog.tokenForHandle(iconHandle).semanticName,
      ),
      findsOneWidget,
    );
  });
}

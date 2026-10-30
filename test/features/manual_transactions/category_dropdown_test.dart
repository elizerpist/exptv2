import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/category_visual_badge.dart';
import 'package:fluvi/features/manual_transactions/presentation/category_dropdown.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets('category dropdown uses each category catalogue icon', (
    tester,
  ) async {
    final categories = <FluviCategory>[
      _category('food', 'Élelmiszer', 'color_02', 'icon_02'),
      _category('travel', 'Utazás', 'color_07', 'icon_07'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryDropdown(
            categories: categories,
            selectedCategoryId: 'food',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<CategoryVisualBadge>(find.byType(CategoryVisualBadge))
          .iconHandle,
      2,
    );

    await tester.tap(
      find.byKey(const ValueKey('manual-category-dropdown-anchor')),
    );
    await tester.pumpAndSettle();
    final badges = tester
        .widgetList<CategoryVisualBadge>(find.byType(CategoryVisualBadge))
        .toList(growable: false);
    expect(badges.map((badge) => badge.iconHandle), containsAll(<int>[2, 7]));
  });

  testWidgets(
    'category dropdown keeps new-category action fixed at its footer',
    (tester) async {
      var createRequested = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDropdown(
              categories: <FluviCategory>[
                _category('food', 'Élelmiszer', 'color_02', 'icon_02'),
              ],
              selectedCategoryId: 'food',
              onSelected: (_) {},
              onCreate: () async => createRequested = true,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('manual-category-dropdown-anchor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('manual-category-create-action')),
      );
      await tester.pump();
      expect(createRequested, isTrue);
    },
  );

  testWidgets('new category remains available when category search is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryDropdown(
            categories: <FluviCategory>[
              _category('food', 'Élelmiszer', 'color_02', 'icon_02'),
            ],
            selectedCategoryId: 'food',
            onSelected: (_) {},
            onCreate: () async {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('manual-category-dropdown-anchor')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-category-search')),
      'nincs ilyen kategória',
    );
    await tester.pumpAndSettle();

    expect(find.text('Nincs találat.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('manual-category-create-action')),
      findsOneWidget,
    );
  });
}

FluviCategory _category(
  String id,
  String name,
  String colorId,
  String iconId,
) => FluviCategory(
  id: id,
  name: name,
  colorId: colorId,
  iconId: iconId,
  isSystemUncategorized: false,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

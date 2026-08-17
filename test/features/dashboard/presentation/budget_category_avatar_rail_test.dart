import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_catalog.dart';
import 'package:fluvi/core/categories/presentation/category_icon_view.dart';
import 'package:fluvi/core/categories/presentation/glossy_category_avatar.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets(
    'renders complete spendeww SVG artwork instead of a composed glossy avatar',
    (tester) async {
      final categories =
          ValueNotifier<List<BudgetCategoryAvatarPresentationItem>>(const [
            BudgetCategoryAvatarPresentationItem(
              id: 'groceries',
              displayName: 'Groceries',
              colorId: 'color_08',
              iconId: 'icon_08',
            ),
            BudgetCategoryAvatarPresentationItem(
              id: 'travel',
              displayName: 'Travel',
              colorId: 'color_13',
              iconId: 'icon_11',
            ),
            BudgetCategoryAvatarPresentationItem(
              id: 'fuel',
              displayName: 'Fuel',
              colorId: 'color_03',
              iconId: 'icon_13',
            ),
            BudgetCategoryAvatarPresentationItem(
              id: 'coffee',
              displayName: 'Coffee',
              colorId: 'color_02',
              iconId: 'icon_34',
            ),
            BudgetCategoryAvatarPresentationItem(
              id: 'home',
              displayName: 'Home',
              colorId: 'color_15',
              iconId: 'icon_27',
            ),
            BudgetCategoryAvatarPresentationItem(
              id: 'books',
              displayName: 'Books',
              colorId: 'color_19',
              iconId: 'icon_42',
            ),
          ]);
      addTearDown(categories.dispose);

      await tester.pumpWidget(_host(categories));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('budget-category-avatar-rail')),
        findsOneWidget,
      );
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.clipBehavior, Clip.none);
      expect(find.byType(GlossyCategoryAvatar), findsNothing);
      expect(find.byType(BudgetCategoryAvatarArtwork), findsWidgets);
      expect(find.byType(CategoryIconView), findsWidgets);

      final center = tester.widget<BudgetCategoryAvatarArtwork>(
        find.byKey(const ValueKey('budget-category-avatar-center')),
      );
      expect(
        center.color,
        CategoryColorCatalog.resolve('color_08').middleColor,
      );
      expect(
        center.icon.assetPath,
        CategoryIconCatalog.resolve('icon_08').compiledAssetPath,
      );
      expect(center.selected, isTrue);
      expect(center.svgSource, contains('data-fluvi-avatar-disc="true"'));
      expect(center.svgSource, contains('data-budget-avatar-disc-core="true"'));
      final regular = tester
          .widgetList<BudgetCategoryAvatarArtwork>(
            find.byType(BudgetCategoryAvatarArtwork),
          )
          .firstWhere((avatar) => !avatar.selected);
      expect(regular.svgSource, contains('cx="256" cy="382"'));
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );
      expect(find.byType(Icon), findsNothing);
    },
  );

  testWidgets(
    'empty categories keep the rail host safe without a fake avatar',
    (tester) async {
      final categories =
          ValueNotifier<List<BudgetCategoryAvatarPresentationItem>>(const []);
      addTearDown(categories.dispose);

      await tester.pumpWidget(_host(categories));

      expect(
        find.byKey(const ValueKey('budget-category-avatar-rail')),
        findsOneWidget,
      );
      expect(find.byType(BudgetCategoryAvatarArtwork), findsNothing);
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'supports every finite category count and preserves the centered id across source replacement',
    (tester) async {
      for (final count in [0, 1, 2, 4, 5, 6]) {
        final categories =
            ValueNotifier<List<BudgetCategoryAvatarPresentationItem>>(
              _items(count),
            );
        addTearDown(categories.dispose);

        await tester.pumpWidget(_host(categories));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('budget-category-avatar-rail')),
          findsOneWidget,
          reason: '$count categories',
        );
        expect(tester.takeException(), isNull, reason: '$count categories');
        expect(
          find.byType(BudgetCategoryAvatarArtwork),
          count == 0 ? findsNothing : findsWidgets,
          reason: '$count categories',
        );
      }

      final categories =
          ValueNotifier<List<BudgetCategoryAvatarPresentationItem>>(_items(6));
      addTearDown(categories.dispose);
      await tester.pumpWidget(_host(categories));
      await tester.pump();

      await tester.fling(find.byType(ListView), const Offset(-420, 0), 2200);
      await tester.pumpAndSettle();
      final centeredBeforeReplacement = tester
          .widget<BudgetCategoryAvatarArtwork>(
            find.byKey(const ValueKey('budget-category-avatar-center')),
          )
          .semanticsLabel;

      categories.value = [
        const BudgetCategoryAvatarPresentationItem(
          id: 'new',
          displayName: 'New',
          colorId: 'color_01',
          iconId: 'icon_01',
        ),
        ..._items(6),
      ];
      await tester.pump();

      expect(
        tester
            .widget<BudgetCategoryAvatarArtwork>(
              find.byKey(const ValueKey('budget-category-avatar-center')),
            )
            .semanticsLabel,
        centeredBeforeReplacement,
      );
    },
  );
}

Widget _host(ValueNotifier<List<BudgetCategoryAvatarPresentationItem>> items) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 378,
            height: 72,
            child: BudgetCategoryAvatarRail(categories: items),
          ),
        ),
      ),
    );

List<BudgetCategoryAvatarPresentationItem> _items(int count) => [
  for (var index = 0; index < count; index += 1)
    BudgetCategoryAvatarPresentationItem(
      id: 'category-$index',
      displayName: 'Category $index',
      colorId: 'color_${((index % 21) + 1).toString().padLeft(2, '0')}',
      iconId: 'icon_${((index % 43) + 1).toString().padLeft(2, '0')}',
    ),
];

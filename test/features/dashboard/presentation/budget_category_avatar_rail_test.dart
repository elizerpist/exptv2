import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/categories/presentation/category_icon_view.dart';
import 'package:fluvi/core/categories/presentation/glossy_category_avatar.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  test('normal and centered artwork split projected-shadow ownership', () {
    const color = Color(0xffd834c9);
    final normal = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        color,
        17,
        variant: BudgetCategoryAvatarVariant.normalRail,
      ),
    );
    final centeredCore = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        color,
        17,
        variant: BudgetCategoryAvatarVariant.centeredCore,
      ),
    );

    expect(normal, contains('<ellipse cx="256" cy="382"'));
    expect(centeredCore, isNot(contains('<ellipse cx="256" cy="382"')));
    expect(normal, contains('radialGradient'));
    expect(centeredCore, contains('radialGradient'));
    expect(
      BudgetCategoryAvatarGeometry.centeredCoreViewportTop +
          BudgetCategoryAvatarGeometry.avatarArtworkViewportHeight / 2,
      BudgetCategoryAvatarGeometry.avatarSphereCenterY,
    );
  });

  test(
    'selection chrome and normal SVG floor share each target shadow hue',
    () {
      for (final color in <Color>[
        const Color(0xff2bc4f3),
        const Color(0xff8b45ed),
      ]) {
        final expected = BudgetCategoryAvatarPalette.shadowColor(color);
        final normal = BudgetCategoryAvatarSvg.flutterRenderable(
          BudgetCategoryAvatarSvg.avatarDisc(
            color,
            color.toARGB32(),
            variant: BudgetCategoryAvatarVariant.normalRail,
          ),
        );
        final chrome = BudgetCategoryAvatarSelectionChrome(
          categoryColor: color,
        );

        expect(chrome.castShadowColor, expected);
        expect(normal, contains(_hex(expected)));
      }
    },
  );

  testWidgets('selected avatar body and glyph keep unselected geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _artwork(key: const ValueKey('unselected-avatar')),
              _artwork(key: const ValueKey('selected-avatar'), selected: true),
            ],
          ),
        ),
      ),
    );
    final unselected = find.byKey(const ValueKey('unselected-avatar'));
    final selected = find.byKey(const ValueKey('selected-avatar'));
    expect(
      tester.getSize(
        find.descendant(of: selected, matching: find.byType(SvgPicture)),
      ),
      tester.getSize(
        find.descendant(of: unselected, matching: find.byType(SvgPicture)),
      ),
    );
    expect(
      tester.getSize(
        find.descendant(of: selected, matching: find.byType(CategoryIconView)),
      ),
      tester.getSize(
        find.descendant(
          of: unselected,
          matching: find.byType(CategoryIconView),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
      findsOneWidget,
    );
  });

  testWidgets('aggregate target is first and uses prepared source artwork', (
    tester,
  ) async {
    final harness = _Harness(_categories(6));
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('budget-target-avatar-rail')),
      findsOneWidget,
    );
    expect(find.byType(GlossyCategoryAvatar), findsNothing);
    expect(find.byType(Icon), findsNothing);
    final center = tester.widget<BudgetCategoryAvatarArtwork>(
      find.byKey(const ValueKey('budget-target-avatar-center')),
    );
    expect(center.semanticsLabel, 'Budget');
    expect(center.color, const Color(0xff2bc4f3));
    expect(center.icon.assetPath, contains('dollar-sign.svg.vec'));
    expect(find.byType(BudgetCategoryAvatarArtwork), findsWidgets);
  });

  testWidgets('zero real categories still leaves the aggregate target', (
    tester,
  ) async {
    final harness = _Harness(const <FluviCategory>[]);
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();
    expect(harness.presentation.value.items, hasLength(1));
    expect(
      tester
          .widget<BudgetCategoryAvatarArtwork>(
            find.byKey(const ValueKey('budget-target-avatar-center')),
          )
          .semanticsLabel,
      'Budget',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('income aggregate uses the exact prepared banknote artwork', (
    tester,
  ) async {
    final harness = _Harness(const <FluviCategory>[]);
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();

    harness.direction.select(TransactionDirection.income);
    await tester.pump();

    final center = tester.widget<BudgetCategoryAvatarArtwork>(
      find.byKey(const ValueKey('budget-target-avatar-center')),
    );
    expect(center.semanticsLabel, 'Összbevételi cél');
    expect(center.color, const Color(0xff8b45ed));
    expect(center.icon.assetPath, contains('banknote.svg.vec'));
  });

  testWidgets('tap centers a category through shared carousel motion', (
    tester,
  ) async {
    final harness = _Harness(_categories(6));
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();

    final side = find.byWidgetPredicate(
      (widget) =>
          widget is BudgetCategoryAvatarArtwork &&
          widget.semanticsLabel == 'Category 0',
    );
    expect(side, findsOneWidget);
    await tester.tap(side);
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester
          .widget<BudgetCategoryAvatarArtwork>(
            find.byKey(const ValueKey('budget-target-avatar-center')),
          )
          .semanticsLabel,
      'Budget',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BudgetCategoryAvatarArtwork>(
            find.byKey(const ValueKey('budget-target-avatar-center')),
          )
          .semanticsLabel,
      'Category 0',
    );
  });

  testWidgets('only the centered target owns one selection shell', (
    tester,
  ) async {
    final harness = _Harness(_categories(6));
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
      findsOneWidget,
    );
    await tester.fling(find.byType(ListView), const Offset(-420, 0), 2200);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
      findsOneWidget,
    );
  });

  test('semantic target tick retains the prepared item list', () {
    final harness = _Harness(_categories(3));
    addTearDown(harness.dispose);

    final before = harness.presentation.value.items;
    harness.presentation.setTargetHandle(1);

    expect(harness.presentation.value.selectedHandle, 1);
    expect(identical(harness.presentation.value.items, before), isTrue);
  });
}

Widget _artwork({Key? key, bool selected = false}) {
  const color = Color(0xffd834c9);
  final atlas = PreparedVectorAssetAtlas.instance;
  return BudgetCategoryAvatarArtwork(
    key: key,
    color: color,
    icon: atlas.categoryIcon(CategoryIconCatalog.handleOf('icon_08')),
    semanticsLabel: 'Groceries',
    svgSource: BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        color,
        17,
        variant: selected
            ? BudgetCategoryAvatarVariant.centeredCore
            : BudgetCategoryAvatarVariant.normalRail,
      ),
    ),
    selected: selected,
  );
}

Widget _host(DashboardBudgetPresentationController presentation) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 378,
        height: 72,
        child: BudgetTargetAvatarRail(presentation: presentation),
      ),
    ),
  ),
);

List<FluviCategory> _categories(int count) => List<FluviCategory>.generate(
  count,
  (index) => FluviCategory(
    id: 'category-$index',
    name: 'Category $index',
    colorId: 'color_${((index % 21) + 1).toString().padLeft(2, '0')}',
    iconId: 'icon_${((index % 43) + 1).toString().padLeft(2, '0')}',
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  ),
);

final class _Harness {
  _Harness(List<FluviCategory> categories)
    : categoryCollection = ValueNotifier<List<FluviCategory>>(categories),
      visibleFrame = ValueNotifier<DashboardVisibleFrame?>(null),
      direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      ) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categoryCollection,
      visibleFrame: visibleFrame,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => null,
    );
  }

  final ValueNotifier<List<FluviCategory>> categoryCollection;
  final ValueNotifier<DashboardVisibleFrame?> visibleFrame;
  final TransactionDirectionController direction;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    categoryCollection.dispose();
    visibleFrame.dispose();
    direction.dispose();
  }
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/catalog/category_icon_catalog.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/core/categories/presentation/category_icon_view.dart';
import 'package:fluvi/core/categories/presentation/glossy_category_avatar.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_limit_quick_edit_gesture.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_interaction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
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
    final centeredShadowed = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        color,
        17,
        variant: BudgetCategoryAvatarVariant.centeredShadowed,
      ),
    );

    expect(normal, contains('<ellipse cx="256" cy="382"'));
    expect(centeredCore, isNot(contains('<ellipse cx="256" cy="382"')));
    expect(centeredShadowed, contains('<ellipse cx="256" cy="382"'));
    expect(normal, contains('radialGradient'));
    expect(centeredCore, contains('radialGradient'));
    expect(centeredShadowed, contains('viewBox="94 69 324 342"'));
    expect(centeredCore, contains('viewBox="94 69 324 342"'));
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

  testWidgets('selected avatar without a positive limit keeps only its body', (
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
      findsNothing,
    );
  });

  testWidgets(
    'selected no-limit avatar restores the prepared centered SVG floor shadow',
    (tester) async {
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.unavailable(
          targetHandle: 7,
        ),
      );
      addTearDown(visual.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _artwork(
              key: const ValueKey('selected-no-limit-avatar'),
              selected: true,
              selectedTargetHandle: 7,
              selectedLimitVisualListenable: visual,
            ),
          ),
        ),
      );

      final picture = tester.widget<SvgPicture>(
        find.descendant(
          of: find.byKey(const ValueKey('selected-no-limit-avatar')),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        picture.bytesLoader,
        SvgStringLoader(_centeredShadowedArtworkSource()),
      );
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a selected avatar paints chrome only for its own positive limit',
    (tester) async {
      const key = FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: FinancialLimitCategoryTarget('groceries'),
        period: FinancialLimitMonthPeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          actualScaled100: 0,
          effectiveLimitScaled100: 100,
        ),
      );
      addTearDown(visual.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _artwork(
              key: const ValueKey('positive-limit-avatar'),
              selected: true,
              selectedTargetHandle: 7,
              selectedLimitVisualListenable: visual,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );
      expect(visual.value.visualProgress, 0);
    },
  );

  testWidgets(
    'zero crossing removes and restores chrome while the long-press pointer stays down',
    (tester) async {
      const key = FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: FinancialLimitCategoryTarget('groceries'),
        period: FinancialLimitMonthPeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          actualScaled100: 50,
          effectiveLimitScaled100: 100000,
        ),
      );
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoOpFinancialLimitRepository(),
        isKeyCurrent: (candidate) => candidate == key,
      );
      final quickEdit = BudgetLimitQuickEditGestureController(
        edits: edits,
        contextForCurrentSelection: () => const DashboardBudgetLimitEditContext(
          key: key,
          coreRevision: 1,
          targetHandle: 7,
          actualScaled100: 50,
          confirmedLimitScaled100: 100000,
        ),
        haptic: (_) {},
      );
      edits.addListener(() {
        final state = edits.value;
        if (state == null) return;
        visual.value = BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: state.targetHandle,
          limitKey: state.key,
          actualScaled100: state.actualScaled100,
          effectiveLimitScaled100: state.effectiveLimitScaled100,
        );
      });
      addTearDown(visual.dispose);
      addTearDown(quickEdit.dispose);
      addTearDown(edits.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BudgetTargetAvatarInteraction(
                onLongPressStart: (details) => quickEdit.longPressStarted(
                  globalY: details.globalPosition.dy,
                ),
                onLongPressMoveUpdate: (details) => quickEdit.longPressMoved(
                  globalY: details.globalPosition.dy,
                ),
                onLongPressEnd: (_) => quickEdit.longPressEnded(),
                child: _artwork(
                  key: const ValueKey('zero-crossing-avatar'),
                  selected: true,
                  selectedTargetHandle: 7,
                  selectedLimitVisualListenable: visual,
                ),
              ),
            ),
          ),
        ),
      );
      final avatar = find.byKey(const ValueKey('zero-crossing-avatar'));
      final initialSvgSize = tester.getSize(
        find.descendant(of: avatar, matching: find.byType(SvgPicture)),
      );
      final initialGlyphSize = tester.getSize(
        find.descendant(of: avatar, matching: find.byType(CategoryIconView)),
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(of: avatar, matching: find.byType(SvgPicture)),
            )
            .bytesLoader,
        SvgStringLoader(_centeredCoreArtworkSource()),
      );
      final pointer = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(kLongPressTimeout);
      expect(quickEdit.isEditing, isTrue);

      await pointer.moveBy(const Offset(0, 13));
      await tester.pump();
      expect(edits.value!.effectiveLimitScaled100, 0);
      expect(quickEdit.isEditing, isTrue);
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('budget-target-avatar-press-scale')),
            )
            .scale,
        .8,
      );
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsNothing,
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(of: avatar, matching: find.byType(SvgPicture)),
            )
            .bytesLoader,
        SvgStringLoader(_centeredShadowedArtworkSource()),
      );
      expect(
        tester.getSize(
          find.descendant(of: avatar, matching: find.byType(SvgPicture)),
        ),
        initialSvgSize,
      );
      expect(
        tester.getSize(
          find.descendant(of: avatar, matching: find.byType(CategoryIconView)),
        ),
        initialGlyphSize,
      );

      await pointer.moveBy(const Offset(0, -26));
      await tester.pump();
      expect(edits.value!.effectiveLimitScaled100, greaterThan(0));
      expect(quickEdit.isEditing, isTrue);
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(of: avatar, matching: find.byType(SvgPicture)),
            )
            .bytesLoader,
        SvgStringLoader(_centeredCoreArtworkSource()),
      );
      expect(
        tester.getSize(
          find.descendant(of: avatar, matching: find.byType(SvgPicture)),
        ),
        initialSvgSize,
      );
      expect(
        tester.getSize(
          find.descendant(of: avatar, matching: find.byType(CategoryIconView)),
        ),
        initialGlyphSize,
      );
      await pointer.up();
    },
  );

  testWidgets(
    'very-long clear changes the selected visual immediately and accepts an upward draft tick before pointer release',
    (tester) async {
      const key = FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: FinancialLimitCategoryTarget('groceries'),
        period: FinancialLimitMonthPeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          actualScaled100: 50,
          effectiveLimitScaled100: 100000,
        ),
      );
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoOpFinancialLimitRepository(),
        isKeyCurrent: (candidate) => candidate == key,
      );
      final quickEdit = BudgetLimitQuickEditGestureController(
        edits: edits,
        contextForCurrentSelection: () => const DashboardBudgetLimitEditContext(
          key: key,
          coreRevision: 1,
          targetHandle: 7,
          actualScaled100: 50,
          confirmedLimitScaled100: 100000,
        ),
        haptic: (_) {},
      );
      edits.addListener(() {
        final state = edits.value;
        if (state == null) return;
        visual.value = BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: state.targetHandle,
          limitKey: state.key,
          actualScaled100: state.actualScaled100,
          effectiveLimitScaled100: state.effectiveLimitScaled100,
        );
      });
      addTearDown(visual.dispose);
      addTearDown(quickEdit.dispose);
      addTearDown(edits.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BudgetTargetAvatarInteraction(
                onLongPressStart: (details) => quickEdit.longPressStarted(
                  globalY: details.globalPosition.dy,
                ),
                onLongPressMoveUpdate: (details) => quickEdit.longPressMoved(
                  globalY: details.globalPosition.dy,
                ),
                onLongPressEnd: (_) => quickEdit.longPressEnded(),
                child: _artwork(
                  key: const ValueKey('very-long-delete-avatar'),
                  selected: true,
                  selectedTargetHandle: 7,
                  selectedLimitVisualListenable: visual,
                ),
              ),
            ),
          ),
        ),
      );
      final avatar = find.byKey(const ValueKey('very-long-delete-avatar'));
      final pointer = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(kLongPressTimeout);
      await tester.pump(const Duration(milliseconds: 720));
      await tester.pump();

      expect(quickEdit.isEditing, isTrue);
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('budget-target-avatar-press-scale')),
            )
            .scale,
        .8,
      );
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsNothing,
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(of: avatar, matching: find.byType(SvgPicture)),
            )
            .bytesLoader,
        SvgStringLoader(_centeredShadowedArtworkSource()),
      );

      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();

      expect(edits.value!.effectiveLimitScaled100, 100000);
      expect(quickEdit.isEditing, isTrue);
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('budget-target-avatar-press-scale')),
            )
            .scale,
        .8,
      );
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(of: avatar, matching: find.byType(SvgPicture)),
            )
            .bytesLoader,
        SvgStringLoader(_centeredCoreArtworkSource()),
      );
      await pointer.up();
    },
  );

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

  testWidgets('an unavailable selected limit paints no selection shell', (
    tester,
  ) async {
    final harness = _Harness(_categories(6));
    addTearDown(harness.dispose);
    await tester.pumpWidget(_host(harness.presentation));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
      findsNothing,
    );
    await tester.fling(find.byType(ListView), const Offset(-420, 0), 2200);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
      findsNothing,
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

  test(
    'a positive limit paints the exact bounded utilisation without a minimum arc',
    () {
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 0,
          limitScaled100: 100,
        ).visualProgress,
        0,
      );
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 25,
          limitScaled100: 100,
        ).visualProgress,
        .25,
      );
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 75,
          limitScaled100: 100,
        ).visualProgress,
        .75,
      );
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 100,
          limitScaled100: 100,
        ).visualProgress,
        1,
      );
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 160,
          limitScaled100: 100,
        ).visualProgress,
        1,
      );
      expect(
        BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: 999,
          limitScaled100: 1000,
        ).visualProgress,
        .999,
      );
      expect(
        BudgetLimitProgressProjection.boundedVisualProgress(double.nan),
        0,
      );
    },
  );

  test('selection chrome keeps the Budget2 continuous sweep contract', () {
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(0),
      0,
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(.25),
      math.pi / 2,
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(.50),
      math.pi,
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(.75),
      math.pi * 1.5,
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(.99),
      closeTo(math.pi * 1.98, .0000001),
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(1),
      math.pi * 2,
    );
    expect(
      BudgetCategoryAvatarSelectionChrome.sweepRadiansForVisualProgress(1.66),
      math.pi * 2,
    );
  });
}

Widget _artwork({
  Key? key,
  bool selected = false,
  int? selectedTargetHandle,
  ValueListenable<BudgetCategoryAvatarSelectedLimitVisualState>?
  selectedLimitVisualListenable,
}) {
  const color = Color(0xffd834c9);
  final atlas = PreparedVectorAssetAtlas.instance;
  return BudgetCategoryAvatarArtwork(
    key: key,
    color: color,
    icon: atlas.categoryIcon(CategoryIconCatalog.handleOf('icon_08')),
    semanticsLabel: 'Groceries',
    svgSource: _normalArtworkSource(),
    centeredCoreSvgSource: _centeredCoreArtworkSource(),
    centeredShadowedSvgSource: _centeredShadowedArtworkSource(),
    selected: selected,
    selectedTargetHandle: selectedTargetHandle,
    selectedLimitVisualListenable: selectedLimitVisualListenable,
  );
}

String _normalArtworkSource() => BudgetCategoryAvatarSvg.flutterRenderable(
  BudgetCategoryAvatarSvg.avatarDisc(
    const Color(0xffd834c9),
    17,
    variant: BudgetCategoryAvatarVariant.normalRail,
  ),
);

String _centeredCoreArtworkSource() =>
    BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        const Color(0xffd834c9),
        17,
        variant: BudgetCategoryAvatarVariant.centeredCore,
      ),
    );

String _centeredShadowedArtworkSource() =>
    BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        const Color(0xffd834c9),
        17,
        variant: BudgetCategoryAvatarVariant.centeredShadowed,
      ),
    );

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
      ),
      snapshot = _snapshotForCategories(categories) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categoryCollection,
      visibleFrame: visibleFrame,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => snapshot,
    );
  }

  final ValueNotifier<List<FluviCategory>> categoryCollection;
  final ValueNotifier<DashboardVisibleFrame?> visibleFrame;
  final TransactionDirectionController direction;
  final PreparedBudgetLimitSnapshot snapshot;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    categoryCollection.dispose();
    visibleFrame.dispose();
    direction.dispose();
  }
}

PreparedBudgetLimitSnapshot _snapshotForCategories(
  List<FluviCategory> categories,
) {
  final targetCount = categories.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * targetCount,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: categories.map((category) => category.id).toList(),
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 1,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

final class _NoOpFinancialLimitRepository implements FinancialLimitRepository {
  const _NoOpFinancialLimitRepository();

  @override
  Future<bool> delete(FinancialLimitKey key) async => true;

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) async => null;

  @override
  Future<List<FinancialLimit>> list() async => const <FinancialLimit>[];

  @override
  Future<FinancialLimit> upsert(
    FinancialLimitKey key,
    int amountScaled100,
  ) async => FinancialLimit(
    key: key,
    amountScaled100: amountScaled100,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  );
}

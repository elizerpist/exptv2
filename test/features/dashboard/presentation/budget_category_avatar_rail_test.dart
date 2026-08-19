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
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_limit_quick_edit_gesture.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_rail_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_interaction.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets(
    'a distribution route uses the existing rail preview for every cyclic crossing',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(_categories(9));
      final visibleFrame = ValueNotifier<DashboardVisibleFrame?>(
        _interactiveFrame(),
      );
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final snapshot = _snapshotForCategories(categories.value);
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visibleFrame,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
      );
      final distributionRail = BudgetTargetAvatarRailController();
      final previewIntents = <int>[];
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);
      addTearDown(distributionRail.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                navigationController: distributionRail,
                onTargetPreview: (state) {
                  previewIntents.add(state.selectedHandle);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final firstRoute = distributionRail.animateToTargetHandle(
        7,
        source: BudgetTargetNavigationSource.pieSlice,
      );
      await tester.pumpAndSettle();
      await firstRoute;
      expect(presentation.value.selectedHandle, 7);

      final crossings = <int>[];
      presentation.addListener(
        () => crossings.add(presentation.value.selectedHandle),
      );
      final aggregateRoute = distributionRail.animateToTargetHandle(
        0,
        source: BudgetTargetNavigationSource.pieCenter,
      );
      // Programmatic scrolling owns normal frame-by-frame semantic previews;
      // sample real display cadence rather than jumping directly to settle.
      for (var frame = 0; frame < 20; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      await aggregateRoute;

      expect(crossings, containsAllInOrder(<int>[8, 9, 0]));
      expect(
        previewIntents,
        containsAllInOrder(<int>[8, 9, 0]),
        reason:
            'A semantic preview crossing emits the paired drill-down intent before motion settlement.',
      );
      expect(presentation.value.selectedHandle, 0);
    },
  );

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

  test('aggregate hue ramps are projected into intrinsic face lighting', () {
    final expense = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        const Color(0xff2bc4f3),
        41,
        faceGradient: const BudgetCategoryAvatarFaceGradient(
          start: Color(0xff22d3ee),
          middle: Color(0xff2bc4f3),
          end: Color(0xff39b8f4),
        ),
      ),
    );
    final income = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(
        const Color(0xff8b45ed),
        42,
        faceGradient: const BudgetCategoryAvatarFaceGradient(
          start: Color(0xff7c4dff),
          middle: Color(0xff8b45ed),
          end: Color(0xff9a3ddb),
        ),
      ),
    );
    final category = BudgetCategoryAvatarSvg.flutterRenderable(
      BudgetCategoryAvatarSvg.avatarDisc(const Color(0xffd834c9), 43),
    );

    expect(expense, contains('stop-color="#cef5fb"'));
    expect(expense, contains('stop-color="#51cff5"'));
    expect(expense, contains('stop-color="#3283ba"'));
    expect(income, contains('stop-color="#e2d8ff"'));
    expect(income, contains('stop-color="#a066f0"'));
    expect(income, contains('stop-color="#742fa9"'));
    expect(
      category,
      contains('stop-color="#f6d2f3"'),
      reason: 'Ordinary Category avatar lighting is a protected contract.',
    );
    expect(category, contains('stop-color="#df59d3"'));
    expect(category, contains('stop-color="#9e299d"'));
  });

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

  testWidgets(
    'a real very-long clear reaches the presentation rail before release or persistence',
    (tester) async {
      final harness = _InteractiveRailHarness();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        _host(
          harness.presentation,
          limitEditController: harness.edits,
          height: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        ),
      );
      await tester.pump();

      final avatar = find.byKey(const ValueKey('budget-target-avatar-center'));
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );

      final pointer = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(kLongPressTimeout);
      await tester.pump(const Duration(milliseconds: 720));
      await tester.pump();

      expect(harness.presentation.value.header.hasLimit, isFalse);
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsNothing,
      );
      expect(
        tester
            .widget<AnimatedScale>(
              find.ancestor(
                of: avatar,
                matching: find.byKey(
                  const ValueKey('budget-target-avatar-press-scale'),
                ),
              ),
            )
            .scale,
        .8,
      );
      expect(harness.repository.deleteCalls, 0);
      expect(harness.repository.upsertCalls, 0);

      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();

      expect(harness.presentation.value.header.hasLimit, isTrue);
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
      );
      expect(harness.repository.deleteCalls, 0);
      expect(harness.repository.upsertCalls, 0);
      await pointer.cancel();
    },
  );

  testWidgets(
    'the outer visible selected shell starts press feedback on the first pointer down',
    (tester) async {
      final harness = _InteractiveRailHarness();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        _host(
          harness.presentation,
          limitEditController: harness.edits,
          height: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        ),
      );
      await tester.pump();

      final avatar = find.byKey(const ValueKey('budget-target-avatar-center'));
      final shell = tester.getRect(
        find.byKey(const ValueKey('budget-category-avatar-selection-shell')),
      );
      final viewport = tester.getRect(
        find.byKey(const ValueKey('centered-carousel-viewport')),
      );
      final outerVisibleShellPoint = Offset(shell.center.dx, shell.top + 8);
      expect(shell.contains(outerVisibleShellPoint), isTrue);
      expect(viewport.contains(outerVisibleShellPoint), isTrue);
      expect(
        viewport.height,
        BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
      );
      expect(
        tester
            .widget<ListView>(
              find.byKey(const ValueKey('centered-carousel-viewport')),
            )
            .itemExtent,
        58,
      );

      final pointer = await tester.startGesture(outerVisibleShellPoint);
      await tester.pump();

      expect(
        tester
            .widget<AnimatedScale>(
              find.ancestor(
                of: avatar,
                matching: find.byKey(
                  const ValueKey('budget-target-avatar-press-scale'),
                ),
              ),
            )
            .scale,
        .8,
      );
      await pointer.cancel();
    },
  );

  testWidgets(
    'a horizontal drag from the expanded selected surface remains carousel-owned',
    (tester) async {
      final harness = _InteractiveRailHarness();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        _host(
          harness.presentation,
          limitEditController: harness.edits,
          height: BudgetCategoryAvatarGeometry.selectionShellVisualDiameter,
        ),
      );
      await tester.pump();

      final shell = tester.getRect(
        find.byKey(const ValueKey('budget-category-avatar-selection-shell')),
      );
      final viewport = find.byKey(const ValueKey('centered-carousel-viewport'));
      final controller = tester.widget<ListView>(viewport).controller!;
      final pixelsBefore = controller.position.pixels;
      await tester.flingFrom(
        Offset(shell.center.dx, shell.top + 8),
        const Offset(-420, 0),
        2200,
      );
      await tester.pumpAndSettle();

      expect(controller.position.pixels, isNot(pixelsBefore));
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

Widget _host(
  DashboardBudgetPresentationController presentation, {
  DashboardBudgetLimitEditController? limitEditController,
  double height = 72,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 378,
        height: height,
        child: BudgetTargetAvatarRail(
          presentation: presentation,
          limitEditController: limitEditController,
        ),
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

final class _InteractiveRailHarness {
  _InteractiveRailHarness()
    : categoryCollection = ValueNotifier<List<FluviCategory>>(_categories(1)),
      visibleFrame = ValueNotifier<DashboardVisibleFrame?>(_interactiveFrame()),
      direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      ),
      snapshot = _positiveSnapshotForCategories() {
    edits = DashboardBudgetLimitEditController(
      repository: repository,
      isKeyCurrent: (key) => presentation.value.header.limitKey == key,
    );
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categoryCollection,
      visibleFrame: visibleFrame,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => snapshot,
      limitEditController: edits,
    );
  }

  final ValueNotifier<List<FluviCategory>> categoryCollection;
  final ValueNotifier<DashboardVisibleFrame?> visibleFrame;
  final TransactionDirectionController direction;
  final PreparedBudgetLimitSnapshot snapshot;
  final _CountingFinancialLimitRepository repository =
      _CountingFinancialLimitRepository();
  late final DashboardBudgetLimitEditController edits;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    edits.dispose();
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

PreparedBudgetLimitSnapshot _positiveSnapshotForCategories() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    28,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Month/January is slice 2. Handle 0 is the selected aggregate target.
  cells[4] = const PreparedBudgetLimitCell(
    actualScaled100: 50000,
    limitScaled100: 100000,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['category-0'],
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

DashboardVisibleFrame _interactiveFrame() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 1)),
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 1,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 1,
      groups: const <DashboardDayLogGroupViewModel>[],
      entryCount: 0,
      nextCursor: null,
      direction: LedgerDirection.expense,
    ),
    presentationDigest: 1,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: 'January',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
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

final class _CountingFinancialLimitRepository
    implements FinancialLimitRepository {
  var deleteCalls = 0;
  var upsertCalls = 0;

  @override
  Future<bool> delete(FinancialLimitKey key) async {
    deleteCalls += 1;
    return true;
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) async => null;

  @override
  Future<List<FinancialLimit>> list() async => const <FinancialLimit>[];

  @override
  Future<FinancialLimit> upsert(
    FinancialLimitKey key,
    int amountScaled100,
  ) async {
    upsertCalls += 1;
    return FinancialLimit(
      key: key,
      amountScaled100: amountScaled100,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );
  }
}

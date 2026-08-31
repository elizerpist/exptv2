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
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
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
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_auto_reset_controller.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_experiments.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  test('all scope strategies retain the one Fluvi ring geometry authority', () {
    final states = <BudgetCategoryAvatarSelectedLimitVisualState>[
      BudgetCategoryAvatarSelectedLimitVisualState.available(
        targetHandle: 1,
        limitKey: null,
        displayNumeratorScaled100: 50,
        displayDenominatorScaled100: 100,
      ),
      BudgetCategoryAvatarSelectedLimitVisualState.available(
        targetHandle: 1,
        limitKey: null,
        displayNumeratorScaled100: 100,
        displayDenominatorScaled100: 100,
        chromeGeometry: BudgetLimitProgressChromeGeometry.verticalProjection,
      ),
      BudgetCategoryAvatarSelectedLimitVisualState.available(
        targetHandle: 1,
        limitKey: null,
        displayNumeratorScaled100: 100,
        displayDenominatorScaled100: 100,
        chromeGeometry: BudgetLimitProgressChromeGeometry.annualSegments,
        annualSegments: List<BudgetProgressRingAnnualSegment>.filled(
          12,
          const BudgetProgressRingAnnualSegment(
            health: BudgetProgressRingAnnualSegmentHealth.healthy,
          ),
        ),
      ),
      BudgetCategoryAvatarSelectedLimitVisualState.available(
        targetHandle: 1,
        limitKey: null,
        displayNumeratorScaled100: 50,
        displayDenominatorScaled100: 100,
        chromeGeometry: BudgetLimitProgressChromeGeometry.typicalMarker,
        typicalMarkerPosition: .5,
      ),
    ];

    expect(states.map((state) => state.sourceGeometryId).toSet(), <String>{
      BudgetProgressRingGeometry.sourceId,
    });
    expect(BudgetProgressRingGeometry.sourceTrackRadius, isNonZero);
    expect(BudgetProgressRingGeometry.sourceTrackWidth, isNonZero);
    expect(states[1].visualProgress, .75);
    expect(states[2].annualSegments, hasLength(12));
  });

  test('DAY break-even uses two mirrored sphere markers, not a line', () {
    final geometry = BudgetProgressRingGeometry.source;
    final markers = BudgetProgressRingDayPaceMarkers.resolve(
      geometry: geometry,
    );

    expect(markers.sourceGeometryId, BudgetProgressRingGeometry.sourceId);
    expect(markers.materialId, BudgetProgressRingSphereMaterial.sourceId);
    expect(markers.left.center.dy, markers.right.center.dy);
    expect(
      markers.left.center.dx + markers.right.center.dx,
      geometry.center.dx * 2,
    );
    expect(
      (markers.left.center - geometry.center).distance,
      closeTo(geometry.trackRadius, .000001),
      reason: 'left marker centre must lie on the shared track centreline',
    );
    expect(
      (markers.right.center - geometry.center).distance,
      closeTo(geometry.trackRadius, .000001),
      reason: 'right marker centre must lie on the shared track centreline',
    );
    expect(markers.left.center.dy, closeTo(100.24, .000001));
    expect(markers.breakEvenGaugeRatio, .75);
  });

  test('SUM scale exposes three clockwise shared-track health spheres', () {
    final geometry = BudgetProgressRingGeometry.source;
    final markers = BudgetProgressRingSumScaleMarkers.resolve(
      geometry: geometry,
    );

    expect(markers, hasLength(3));
    expect(markers.map((marker) => marker.ratio), <double>[.50, .75, .90]);
    expect(markers.map((marker) => marker.material.base), <Color>[
      FluviVisualTokens.budgetProgressHealthy,
      FluviVisualTokens.budgetProgressWarning,
      FluviVisualTokens.budgetProgressDanger,
    ]);
    for (final marker in markers) {
      expect(
        (marker.center - geometry.center).distance,
        closeTo(geometry.trackRadius, .000001),
        reason: 'SUM reference spheres must sit on the shared track centreline',
      );
      expect(
        marker.material.sourceGeometryId,
        BudgetProgressRingSphereMaterial.sourceId,
      );
      expect(marker.material.usesCategoryHueShift, isFalse);
    }
    // Canvas angles increase clockwise: .50 is bottom, .75 left and .90 is
    // then in the upper-left quadrant from the shared top origin.
    expect(markers[0].center.dx, closeTo(154, .000001));
    expect(markers[0].center.dy, closeTo(261.52, .000001));
    expect(markers[1].center.dx, closeTo(46.48, .000001));
    expect(markers[1].center.dy, closeTo(154, .000001));
    expect(markers[2].center.dx, lessThan(geometry.center.dx));
    expect(markers[2].center.dy, lessThan(geometry.center.dy));
  });

  test(
    'YEAR segments are twelve fixed health cells without partial progress',
    () {
      final cells = List<BudgetProgressRingAnnualSegment>.generate(
        12,
        (index) => BudgetProgressRingAnnualSegment(
          health: switch (index) {
            0 => BudgetProgressRingAnnualSegmentHealth.healthy,
            1 => BudgetProgressRingAnnualSegmentHealth.warning,
            2 => BudgetProgressRingAnnualSegmentHealth.danger,
            _ => BudgetProgressRingAnnualSegmentHealth.neutral,
          },
        ),
      );

      expect(cells, hasLength(12));
      expect(cells[0].health, BudgetProgressRingAnnualSegmentHealth.healthy);
      expect(cells[1].health, BudgetProgressRingAnnualSegmentHealth.warning);
      expect(cells[2].health, BudgetProgressRingAnnualSegmentHealth.danger);
      for (final cell in cells.skip(3)) {
        expect(cell.health, BudgetProgressRingAnnualSegmentHealth.neutral);
      }
      expect(
        BudgetProgressRingAnnualSegment.fixedSweepRadians,
        closeTo(
          BudgetProgressRingAnnualSegment.slotSweepRadians -
              BudgetProgressRingAnnualSegment.centerlineGapRadians,
          .000001,
        ),
      );
      expect(
        BudgetProgressRingAnnualSegment.paintedVisibleGapLength,
        BudgetProgressRingAnnualSegment.annualSegmentVisibleGap,
      );
      expect(
        BudgetProgressRingAnnualSegment.paintedVisibleGapLength,
        greaterThan(0),
        reason: 'round caps require a real positive painted gap',
      );
    },
  );

  test('YEAR cell health is green/yellow/red or explicit neutral', () {
    BudgetProgressRingAnnualSegmentHealth resolve({
      required int actual,
      required int? limit,
      bool future = false,
    }) => BudgetProgressRingAnnualSegmentHealthResolver.resolve(
      actualScaled100: actual,
      resolvedMonthlyLimitScaled100: limit,
      isFuture: future,
    );

    expect(
      resolve(actual: 74, limit: 100),
      BudgetProgressRingAnnualSegmentHealth.healthy,
    );
    expect(
      resolve(actual: 75, limit: 100),
      BudgetProgressRingAnnualSegmentHealth.warning,
    );
    expect(
      resolve(actual: 90, limit: 100),
      BudgetProgressRingAnnualSegmentHealth.warning,
    );
    expect(
      resolve(actual: 91, limit: 100),
      BudgetProgressRingAnnualSegmentHealth.danger,
    );
    expect(
      resolve(actual: 0, limit: 100, future: true),
      BudgetProgressRingAnnualSegmentHealth.neutral,
    );
    expect(
      resolve(actual: 0, limit: null),
      BudgetProgressRingAnnualSegmentHealth.neutral,
    );
  });

  test('YEAR health material preserves canonical health hue families', () {
    final annualChrome = BudgetCategoryAvatarSelectionChrome(
      categoryColor: const Color(0xFFD834C9),
      geometry: BudgetLimitProgressChromeGeometry.annualSegments,
      annualSegments: const <BudgetProgressRingAnnualSegment>[
        BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.danger,
        ),
      ],
    );
    final healthy = BudgetProgressRingAnnualHealthMaterial.forHealth(
      BudgetProgressRingAnnualSegmentHealth.healthy,
    );
    final warning = BudgetProgressRingAnnualHealthMaterial.forHealth(
      BudgetProgressRingAnnualSegmentHealth.warning,
    );
    final danger = BudgetProgressRingAnnualHealthMaterial.forHealth(
      BudgetProgressRingAnnualSegmentHealth.danger,
    );
    final neutral = BudgetProgressRingAnnualHealthMaterial.forHealth(
      BudgetProgressRingAnnualSegmentHealth.neutral,
    );

    expect(healthy.base, FluviVisualTokens.budgetProgressHealthy);
    expect(warning.base, FluviVisualTokens.budgetProgressWarning);
    expect(danger.base, FluviVisualTokens.budgetProgressDanger);
    expect(neutral.base, const Color(0xFFC5BDCF));
    expect(
      annualChrome.usesCategoryHueShift,
      isFalse,
      reason: 'YEAR must bypass the category arc hue transform entirely',
    );
    for (final material in <BudgetProgressRingAnnualHealthMaterial>[
      healthy,
      warning,
      danger,
      neutral,
    ]) {
      expect(material.usesCategoryHueShift, isFalse);
    }
    expect(
      HSLColor.fromColor(danger.end).hue,
      closeTo(HSLColor.fromColor(danger.base).hue, .001),
      reason: 'annual danger depth must remain red, never rotate magenta',
    );
  });

  testWidgets(
    'YEAR ring raster keeps twelve fixed health cells visibly separated',
    (tester) async {
      const key = ValueKey<String>('annual-health-ring-raster');
      final segments = <BudgetProgressRingAnnualSegment>[
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.healthy,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.warning,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.danger,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.healthy,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.danger,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.warning,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.healthy,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.neutral,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.neutral,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.neutral,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.neutral,
        ),
        const BudgetProgressRingAnnualSegment(
          health: BudgetProgressRingAnnualSegmentHealth.neutral,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF201D29),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: BudgetCategoryAvatarSelectionChrome(
                  categoryColor: const Color(0xFFD834C9),
                  geometry: BudgetLimitProgressChromeGeometry.annualSegments,
                  annualSegments: segments,
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          '../../../goldens/budget_annual_fixed_health_cells.png',
        ),
      );
    },
  );

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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
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
                onTargetPreview: (targetHandle) {
                  previewIntents.add(targetHandle);
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
      expect(
        presentation.value.selectedHandle,
        0,
        reason:
            'The rail is presentation-only. Its parent semantic commit owns '
            'when the Budget Header target may change with the Query frame.',
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

      expect(
        previewIntents,
        containsAllInOrder(<int>[8, 9, 0]),
        reason:
            'A semantic preview crossing emits the paired drill-down intent before motion settlement.',
      );
      expect(presentation.value.selectedHandle, 0);
    },
  );

  testWidgets(
    'RED REENTRANT-AVATAR: background hotset readiness never absorbs direct input',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(_categories(3));
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final readiness = ValueNotifier<bool>(false);
      var directPointerCount = 0;
      var semanticCrossingCount = 0;
      final motionStates = <bool>[];
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);
      addTearDown(readiness.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
            child: BudgetTargetAvatarRail(
              presentation: presentation,
              liveTargetReadiness: readiness,
              onDirectInputStarted: () => directPointerCount += 1,
              onTargetPreview: (_) => semanticCrossingCount += 1,
              onMotionActiveChanged: motionStates.add,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('budget-target-avatar-live-root-readiness')),
        findsNothing,
        reason:
            'Prepared-target readiness is a publication invariant, not the '
            'hit-test owner for a subsequent physical pointer.',
      );
      expect(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        findsOneWidget,
        reason: 'readiness churn must not replace the rail/controller subtree',
      );

      final carousel = find.byKey(
        const ValueKey('budget-target-avatar-carousel'),
      );
      for (var interaction = 0; interaction < 20; interaction += 1) {
        final crossingsBefore = semanticCrossingCount;
        await tester.drag(carousel, Offset(interaction.isEven ? -120 : 120, 0));
        await tester.pumpAndSettle();
        expect(
          semanticCrossingCount,
          greaterThan(crossingsBefore),
          reason:
              'Interaction ${interaction + 1} must retain semantic input even '
              'while background readiness is false.',
        );
        expect(motionStates.last, isFalse);
      }
      expect(directPointerCount, 20);
    },
  );

  testWidgets(
    'RED: real Avatar ballistic motion does not lock direct Summary input',
    (tester) async {
      final harness = _Harness(_categories(9));
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 1, 10),
      );
      final visibleFrames = DashboardVisibleFrameStore();
      final resetMotions = DashboardSummaryAutoResetMotionRegistry();
      var avatarBallisticActive = false;
      var directSummaryInputs = 0;
      final avatarPreviews = <int>[];
      final summaryCrossings = <TimePlane>[];
      addTearDown(harness.dispose);
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 378,
                  height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
                  child: BudgetTargetAvatarRail(
                    presentation: harness.presentation,
                    onTargetPreview: (targetHandle) {
                      avatarPreviews.add(targetHandle);
                    },
                    onMotionActiveChanged: (active) {
                      avatarBallisticActive = active;
                    },
                  ),
                ),
                SizedBox(
                  width: 378,
                  height: 59,
                  child: SummaryPillExperiment(
                    variant: SummaryPillVariant.segmented,
                    bounds: const DashboardBounds(
                      left: 0,
                      top: 0,
                      width: 378,
                      height: 59,
                    ),
                    navigation: navigation,
                    visibleFrames: visibleFrames,
                    onLevelCrossed: (plane, _) => summaryCrossings.add(plane),
                    onComponentCrossed: (_, _) {},
                    autoResetMotionRegistry: resetMotions,
                    onSelectorDirectInputStarted: () {
                      directSummaryInputs += 1;
                      resetMotions.cancelActiveResetMotion();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        const Offset(-520, 0),
        2600,
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(avatarBallisticActive, isTrue);

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-segmented-mode-selector')),
        const Offset(0, 160),
        2500,
      );
      await tester.pump();
      expect(
        directSummaryInputs,
        greaterThan(0),
        reason:
            'Summary pointer-down must be accepted while the real Avatar '
            'ballistic activity remains active.',
      );
      expect(avatarBallisticActive, isTrue);

      final previewsBeforeAvatarReentry = avatarPreviews.length;
      await tester.drag(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        const Offset(180, 0),
      );
      await tester.pump();
      expect(
        avatarPreviews.length,
        greaterThan(previewsBeforeAvatarReentry),
        reason:
            'The later Avatar pointer must immediately reclaim its own '
            'direct-input lane while Summary reset/ballistic work exists.',
      );

      await tester.pumpAndSettle();
      expect(summaryCrossings, isNotEmpty);
    },
  );

  testWidgets(
    'RG-G2: Avatar raw pointer preempts maintenance before the carousel starts a semantic crossing',
    (tester) async {
      final harness = _Harness(_categories(9));
      final order = <String>[];
      addTearDown(harness.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: harness.presentation,
                onDirectInputStarted: () => order.add('pointerDown'),
                onMotionActiveChanged: (active) {
                  if (active) order.add('motionStarted');
                },
                onTargetPreview: (_) => order.add('semanticCrossing'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('budget-target-avatar-carousel')),
        ),
      );
      await tester.pump();
      expect(order, <String>['pointerDown']);

      await gesture.moveBy(const Offset(-90, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(order.first, 'pointerDown');
      expect(order, contains('motionStarted'));
    },
  );

  testWidgets(
    'a user fling keeps preview live and still reports its final settled target',
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final previews = <int>[];
      final committed = <int>[];
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                onTargetPreview: (targetHandle) => previews.add(targetHandle),
                onTargetSettled: (targetHandle) => committed.add(targetHandle),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        const Offset(-220, 0),
        2200,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(previews, isNotEmpty);
      expect(
        committed,
        isEmpty,
        reason:
            'The rail reports each discrete preview separately; the composition '
            'bridge may publish the matching prepared frame without waiting for '
            'this final-settle callback.',
      );

      await tester.pumpAndSettle();
      expect(committed, <int>[previews.last]);
    },
  );

  testWidgets(
    'POST-DF1 DIAG: a ballistic Avatar crossing records typed accepted publication before settle',
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final acceptedTargets = <int>[];
      final settled = <int>[];
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);
      FluviDiagnosticLogger.clear();
      addTearDown(FluviDiagnosticLogger.clear);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                onTargetPreviewAccepted: (targetHandle) {
                  acceptedTargets.add(targetHandle);
                  return Future<bool>.value(true);
                },
                onTargetSettled: settled.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        const Offset(-420, 0),
        2600,
      );
      for (var frame = 0; frame < 12; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final hasBallisticRequest = FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'AV|PREVIEW_REQUESTED' &&
              (event.scope?.contains('phase=ballistic') ?? false),
        );
        if (hasBallisticRequest) break;
      }
      await tester.pump();

      expect(acceptedTargets, isNotEmpty);
      expect(settled, isEmpty);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|BALLISTIC_STARTED',
        ),
        isNotEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AV|PREVIEW_REQUESTED' &&
              (event.scope?.contains('phase=ballistic') ?? false),
        ),
        isNotEmpty,
        reason:
            'The rail must distinguish a ballistic crossing from a direct '
            'drag before the final settle callback.',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AV|PREVIEW_ACCEPTED' &&
              (event.scope?.contains('phase=ballistic') ?? false),
        ),
        isNotEmpty,
      );

      await tester.pumpAndSettle();
      expect(settled, hasLength(1));
      final summary = FluviDiagnosticLogger.entries.lastWhere(
        (event) => event.stage == 'BUDGET_AVATAR_MOTION_SUMMARY',
      );
      expect(summary.scope, contains('ballisticSemanticCrossings='));
      expect(summary.scope, contains('ballisticPreviewAccepted='));
    },
  );

  testWidgets(
    'POST-DF1 RED: twenty Avatar next-frame re-entries retain direct live publication',
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final acceptedTargets = <int>[];
      var directPointerStarts = 0;
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);
      FluviDiagnosticLogger.clear();
      addTearDown(FluviDiagnosticLogger.clear);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                onTargetPreviewAccepted: (targetHandle) {
                  acceptedTargets.add(targetHandle);
                  return Future<bool>.value(true);
                },
                onDirectInputStarted: () => directPointerStarts += 1,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rail = find.byKey(const ValueKey('budget-target-avatar-carousel'));
      for (var interaction = 0; interaction < 20; interaction += 1) {
        await tester.fling(
          rail,
          Offset(interaction.isEven ? -420 : 420, 0),
          2600,
        );
        // One ballistic display frame only. The replacement pointer must not
        // wait for an old simulation, resource warmup, or settlement.
        await tester.pump(const Duration(milliseconds: 16));
        final directRequestsBefore = FluviDiagnosticLogger.entries
            .where(
              (event) =>
                  event.stage == 'AV|PREVIEW_REQUESTED' &&
                  (event.scope?.contains('phase=directDrag') ?? false),
            )
            .length;
        final pointer = await tester.startGesture(tester.getCenter(rail));
        await tester.pump();

        await pointer.moveBy(const Offset(-20, 0));
        await tester.pump(const Duration(milliseconds: 16));
        await pointer.moveBy(const Offset(-200, 0));
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          FluviDiagnosticLogger.entries
              .where(
                (event) =>
                    event.stage == 'AV|PREVIEW_REQUESTED' &&
                    (event.scope?.contains('phase=directDrag') ?? false),
              )
              .length,
          greaterThan(directRequestsBefore),
          reason:
              'interaction=$interaction; the next Avatar pointer must enter '
              'the direct exact-publication lane before old ballistic settle.',
        );
        await pointer.up();
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(directPointerStarts, 40);
      expect(acceptedTargets, isNotEmpty);
    },
  );

  testWidgets(
    'a direct avatar tap commits only after its programmatic settle',
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final committed = <int>[];
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                onTargetSettled: (targetHandle) => committed.add(targetHandle),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final carousel = find.byKey(
        const ValueKey('budget-target-avatar-carousel'),
      );
      await tester.tapAt(tester.getCenter(carousel) + const Offset(58, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(committed, isEmpty);

      await tester.pumpAndSettle();
      expect(committed, hasLength(1));
    },
  );

  testWidgets(
    'an explicit pie command retains its one existing committed handoff',
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
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final settled = <int>[];
      final explicit = <int>[];
      final navigation = BudgetTargetAvatarRailController(
        onExplicitTargetIntent: (request) => explicit.add(request.targetHandle),
      );
      addTearDown(categories.dispose);
      addTearDown(visibleFrame.dispose);
      addTearDown(direction.dispose);
      addTearDown(presentation.dispose);
      addTearDown(navigation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
              child: BudgetTargetAvatarRail(
                presentation: presentation,
                navigationController: navigation,
                onTargetSettled: (targetHandle) => settled.add(targetHandle),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final route = navigation.animateToTargetHandle(
        1,
        source: BudgetTargetNavigationSource.pieSlice,
      );
      await tester.pumpAndSettle();
      await route;

      expect(settled, isEmpty);
      expect(explicit, <int>[1]);
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
        period: FinancialLimitMonthOverridePeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          displayNumeratorScaled100: 0,
          displayDenominatorScaled100: 100,
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
        period: FinancialLimitMonthOverridePeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          displayNumeratorScaled100: 50,
          displayDenominatorScaled100: 100000,
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
          displayNumeratorScaled100: state.actualScaled100,
          displayDenominatorScaled100: state.effectiveLimitScaled100,
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
    'stationary long press retains the selected visual and starts the first tick from its existing limit',
    (tester) async {
      const key = FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: FinancialLimitCategoryTarget('groceries'),
        period: FinancialLimitMonthOverridePeriod(2026, 1),
      );
      final visual = ValueNotifier(
        BudgetCategoryAvatarSelectedLimitVisualState.available(
          targetHandle: 7,
          limitKey: key,
          displayNumeratorScaled100: 50,
          displayDenominatorScaled100: 100000,
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
          displayNumeratorScaled100: state.actualScaled100,
          displayDenominatorScaled100: state.effectiveLimitScaled100,
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
                  key: const ValueKey('stationary-hold-avatar'),
                  selected: true,
                  selectedTargetHandle: 7,
                  selectedLimitVisualListenable: visual,
                ),
              ),
            ),
          ),
        ),
      );
      final avatar = find.byKey(const ValueKey('stationary-hold-avatar'));
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

      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();

      expect(edits.value!.effectiveLimitScaled100, 200000);
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
    'a stationary long press keeps the presentation rail bound before release or persistence',
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

      expect(harness.presentation.value.header.hasLimit, isTrue);
      expect(
        find.byKey(const ValueKey('budget-category-avatar-selection-chrome')),
        findsOneWidget,
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
      expect(harness.presentation.value.header.limitScaled100, 200000);
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

  testWidgets(
    'RG-G1: selected Avatar accepts the first long press through a transient Header projection gap',
    (tester) async {
      final harness = _InteractiveRailHarness();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        _host(
          harness.presentation,
          limitEditController: harness.edits,
          height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
        ),
      );
      await tester.pump();

      // The visible target/scope remains the same, but its next prepared
      // Header projection is not yet available. This is the physical r54
      // first-contact shape; it must not remove the direct input surface.
      harness.snapshot.value = null;
      harness.visibleFrame.value = _interactiveFrame();
      await tester.pump();
      expect(harness.presentation.value.header.editContext, isNull);

      final avatar = find.byKey(const ValueKey('budget-target-avatar-center'));
      final pointer = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(kLongPressTimeout);
      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();

      expect(
        harness.edits.value,
        isNotNull,
        reason:
            'a transient Header renderer gap must not remove the selected '
            'Avatar recognizer or its canonical edit context',
      );
      expect(harness.edits.value!.effectiveLimitScaled100, 200000);
      await pointer.up();
    },
  );

  testWidgets(
    'RG-G1: an active Avatar draft survives a same-target prepared-frame gap and releases its newest value',
    (tester) async {
      final harness = _InteractiveRailHarness();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        _host(
          harness.presentation,
          limitEditController: harness.edits,
          height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
        ),
      );
      await tester.pump();

      final avatar = find.byKey(const ValueKey('budget-target-avatar-center'));
      final pointer = await tester.startGesture(tester.getCenter(avatar));
      await tester.pump(kLongPressTimeout);
      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();
      expect(harness.edits.value!.effectiveLimitScaled100, 200000);

      // Same target/month, newer visible-frame identity, but no prepared
      // Header projection yet. The direct session—not that renderer gap—owns
      // the optimistic value under the still-held pointer.
      harness.snapshot.value = null;
      harness.visibleFrame.value = _interactiveFrame(coreRevision: 2);
      await tester.pump();
      expect(harness.presentation.value.header.editContext, isNotNull);
      expect(harness.edits.value!.effectiveLimitScaled100, 200000);

      await pointer.moveBy(const Offset(0, -13));
      await tester.pump();
      expect(harness.edits.value!.effectiveLimitScaled100, 300000);
      expect(
        harness.presentation.value.liveSelection.limitScaled100,
        300000,
        reason:
            'The live Header must retain the active compatible draft instead '
            'of reverting to the older confirmed 1,000 HUF value.',
      );

      await pointer.up();
      await tester.pump();
      expect(harness.repository.lastUpsertAmountScaled100, 300000);
    },
  );

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

  test(
    'Budget progress tone keeps raw utilisation independent from arc bounds',
    () {
      const accent = Color(0xff2374ab);

      Color toneFor(int actualScaled100, int limitScaled100) {
        final dynamic projection = BudgetLimitProgressProjection.fromAmounts(
          actualScaled100: actualScaled100,
          limitScaled100: limitScaled100,
        );
        return projection.toneFor(accent) as Color;
      }

      expect(toneFor(74999, 100000), accent);
      expect(toneFor(75000, 100000), FluviVisualTokens.budgetProgressWarning);
      expect(toneFor(90000, 100000), FluviVisualTokens.budgetProgressWarning);
      expect(toneFor(90001, 100000), FluviVisualTokens.budgetProgressDanger);
      expect(toneFor(125000, 100000), FluviVisualTokens.budgetProgressDanger);

      final overLimit = BudgetLimitProgressProjection.fromAmounts(
        actualScaled100: 125000,
        limitScaled100: 100000,
      );
      expect(overLimit.visualProgress, 1);
    },
  );
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
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
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
      snapshot = ValueNotifier<PreparedBudgetLimitSnapshot?>(
        _positiveSnapshotForCategories(),
      ) {
    edits = DashboardBudgetLimitEditController(
      repository: repository,
      isKeyCurrent: (key) => presentation.isLimitEditKeyCurrent(key),
    );
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categoryCollection,
      visibleFrame: visibleFrame,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => snapshot.value,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      limitEditController: edits,
    );
  }

  final ValueNotifier<List<FluviCategory>> categoryCollection;
  final ValueNotifier<DashboardVisibleFrame?> visibleFrame;
  final TransactionDirectionController direction;
  final ValueNotifier<PreparedBudgetLimitSnapshot?> snapshot;
  final _CountingFinancialLimitRepository repository =
      _CountingFinancialLimitRepository();
  late final DashboardBudgetLimitEditController edits;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    edits.dispose();
    categoryCollection.dispose();
    visibleFrame.dispose();
    snapshot.dispose();
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

DashboardVisibleFrame _interactiveFrame({int coreRevision = 1}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 1)),
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: coreRevision,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: coreRevision,
      groups: const <DashboardDayLogGroupViewModel>[],
      entryCount: 0,
      nextCursor: null,
      direction: LedgerDirection.expense,
    ),
    presentationDigest: coreRevision,
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
    frameGeneration: coreRevision,
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

  @override
  Future<List<FinancialLimit>> upsertBatch(
    List<FinancialLimitMutation> values,
  ) async => [
    for (final value in values) await upsert(value.key, value.amountScaled100),
  ];
}

final class _CountingFinancialLimitRepository
    implements FinancialLimitRepository {
  var deleteCalls = 0;
  var upsertCalls = 0;
  int? lastUpsertAmountScaled100;

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
    lastUpsertAmountScaled100 = amountScaled100;
    return FinancialLimit(
      key: key,
      amountScaled100: amountScaled100,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );
  }

  @override
  Future<List<FinancialLimit>> upsertBatch(
    List<FinancialLimitMutation> values,
  ) async => [
    for (final value in values) await upsert(value.key, value.amountScaled100),
  ];
}

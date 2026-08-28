import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_experiments.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

void main() {
  test('segmented visual and gesture centres are identical', () {
    final geometry = SummarySegmentedTrackGeometry.resolve(
      width: 218.8,
      preRegressionNavigationWidth: 210.8,
      activeTrackIndices: const <int>[0, 1, 2, 3],
    );

    for (final track in const <int>[0, 1, 2, 3]) {
      expect(
        geometry.visualCenterForTrack(track),
        closeTo(geometry.semanticCenterForTrack(track), .000001),
        reason:
            'The visible $track selector must use the same centre as its '
            'gesture owner.',
      );
    }
    final mode = geometry.semanticRectForTrack(0);
    final year = geometry.semanticRectForTrack(1);
    final month = geometry.semanticRectForTrack(2);
    final day = geometry.semanticRectForTrack(3);
    expect(mode.overlaps(year), isFalse);
    expect(year.overlaps(month), isFalse);
    expect(month.overlaps(day), isFalse);
    final modeVisual = geometry.visualContentRectForTrack(0);
    final yearVisual = geometry.visualContentRectForTrack(1);
    final monthVisual = geometry.visualContentRectForTrack(2);
    final dayVisual = geometry.visualContentRectForTrack(3);
    // A visual label may not live inside an independently padded interaction
    // lane. The exact same Rect owns its paint/clip/semantics/gesture.
    expect(modeVisual, mode);
    expect(yearVisual, year);
    expect(monthVisual, month);
    expect(dayVisual, day);
    expect(
      yearVisual.left - modeVisual.right,
      closeTo(geometry.segmentedSectionGap, .000001),
    );
    expect(
      monthVisual.left - yearVisual.right,
      closeTo(geometry.segmentedSectionGap, .000001),
    );
    expect(
      dayVisual.left - monthVisual.right,
      closeTo(geometry.segmentedSectionGap, .000001),
    );
    expect(
      geometry.segmentedSectionGap,
      geometry.preRegressionContentEdgeGap / 2,
    );
    expect(
      modeVisual.left,
      (geometry.height - geometry.contentMetrics.modeVisualSize) / 2,
      reason: 'large mode visual left inset must equal its top inset',
    );
    expect(
      geometry.preRegressionContentEdgeGap,
      SummarySegmentedTrackGeometry.preRegressionContentEdgeGapFor(
        preRegressionNavigationWidth: 210.8,
      ),
      reason: 'the half-gap must come from old width and old 25px badge',
    );
  });

  test('segmented mirror reverses only the owned component Rects', () {
    final normal = SummarySegmentedTrackGeometry.resolve(
      width: 218.8,
      preRegressionNavigationWidth: 210.8,
      activeTrackIndices: const <int>[0, 1, 2, 3],
      orientation: SummarySegmentedOrientation.normal,
    );
    final mirrored = SummarySegmentedTrackGeometry.resolve(
      width: 218.8,
      preRegressionNavigationWidth: 210.8,
      activeTrackIndices: const <int>[0, 1, 2, 3],
      orientation: SummarySegmentedOrientation.mirrored,
    );

    expect(
      mirrored.semanticRectForTrack(3).right,
      lessThan(mirrored.semanticRectForTrack(2).left),
    );
    expect(
      mirrored.semanticRectForTrack(2).right,
      lessThan(mirrored.semanticRectForTrack(1).left),
    );
    expect(
      mirrored.semanticRectForTrack(1).right,
      lessThan(mirrored.semanticRectForTrack(0).left),
    );
    for (final track in const <int>[0, 1, 2, 3]) {
      expect(
        mirrored.semanticRectForTrack(track),
        mirrored.visualContentRectForTrack(track),
      );
      expect(
        mirrored.semanticRectForTrack(track).width,
        closeTo(normal.semanticRectForTrack(track).width, .000001),
      );
    }
    expect(
      mirrored.semanticRectForTrack(2).left -
          mirrored.semanticRectForTrack(3).right,
      closeTo(normal.segmentedSectionGap, .000001),
    );
    expect(
      mirrored.width - mirrored.semanticRectForTrack(0).right,
      (mirrored.height - mirrored.contentMetrics.modeVisualSize) / 2,
      reason: 'mirrored mode right inset matches normal top inset',
    );
  });

  testWidgets('segmented Summary ports the selected reference material', (
    tester,
  ) async {
    final shadows = DashboardShadowStyleController()
      ..select(DashboardShadowStyle.reference3d);
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(shadows.dispose);
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardShadowStyleScope(
          controller: shadows,
          child: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      ),
    );

    final shell = tester.widget<FluviRoundedBox>(
      find.descendant(
        of: find.byType(SummaryPillExperiment),
        matching: find.byType(FluviRoundedBox),
      ),
    );
    expect(shell.decoration.color, const Color(0xFFFEFEFF));
    expect(shell.decoration.border, isNull);
  });

  testWidgets('segmented shell resolves the global SummaryPill family', (
    tester,
  ) async {
    final roundness = DashboardCornerRoundnessController()
      ..setPosition(DashboardCornerSurfaceFamily.summaryPill, 1);
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(roundness.dispose);
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardCornerRoundnessScope(
          controller: roundness,
          child: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<FluviRoundedBox>(
            find.descendant(
              of: find.byType(SummaryPillExperiment),
              matching: find.byType(FluviRoundedBox),
            ),
          )
          .decoration
          .borderRadius,
      DashboardCornerProfile(
        DashboardCornerSettings.defaults.withPosition(
          DashboardCornerSurfaceFamily.summaryPill,
          1,
        ),
      ).borderRadiusFor(
        DashboardCornerSurfaceFamily.summaryPill,
        size: const Size(378, 59),
      ),
    );
  });

  testWidgets('segmented tracks expose only the active hierarchy depth', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('summary-pill-segmented-mode-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('summary-pill-segmented-month-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard-summary-chevron')),
      findsNothing,
    );
    expect(tester.getSize(find.byType(SummaryPillExperiment)).height, 59);
    expect(
      find.bySemanticsLabel(
        RegExp('Időszint: Havi\\. Függőlegesen húzva válthat\\.'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Nap:')), findsNothing);

    navigation.commitTemporalCandidate(
      navigation.temporalCandidate(plane: TimePlane.month, isRailOpen: true),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('segmented hierarchy values defer visually to the amount', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      ),
    );

    final yearTexts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('summary-pill-segmented-year-selector'),
        ),
        matching: find.byType(Text),
      ),
    );
    final monthTexts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('summary-pill-segmented-month-selector'),
        ),
        matching: find.byType(Text),
      ),
    );
    expect(yearTexts, isNotEmpty);
    expect(monthTexts, isNotEmpty);
    expect(
      yearTexts.map((text) => text.style?.color),
      everyElement(FluviVisualTokens.textSecondary),
    );
    expect(
      monthTexts.map((text) => text.style?.color),
      everyElement(FluviVisualTokens.textSecondary),
    );

    final badge = find.byKey(
      const ValueKey<String>('summary-pill-segmented-mode-badge-month'),
    );
    expect(badge, findsOneWidget);
    expect(tester.getSize(badge), const Size(34, 34));
    final badgeWidget = tester.widget<Container>(badge);
    expect(badgeWidget.padding, const EdgeInsets.all(7));
    expect(
      badgeWidget.decoration,
      const BoxDecoration(
        color: Color(0xFFF1EFFF),
        borderRadius: BorderRadius.all(Radius.circular(9)),
      ),
    );
    final badgeIcon = tester.widget<Icon>(
      find.descendant(of: badge, matching: find.byType(Icon)),
    );
    expect(badgeIcon.color, const Color(0xFF7564F5));
  });

  testWidgets(
    'one hierarchy fling applies absolute carousel offsets to its original day',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      final crossedDays = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryPillExperiment(
              variant: SummaryPillVariant.segmented,
              bounds: _bounds,
              navigation: navigation,
              visibleFrames: visibleFrames,
              onLevelCrossed: (_, _) {},
              onComponentCrossed: (candidate, component) {
                if (component != DashboardTemporalAnchorComponent.day) return;
                crossedDays.add(candidate.dayCursor);
                navigation.commitTemporalCandidate(candidate);
              },
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
        const Offset(0, -240),
        1800,
      );
      await tester.pumpAndSettle();

      expect(crossedDays.length, greaterThan(1));
      // The 240px drag crosses four 59px rows and the capped ballistic tail
      // crosses four more. Both absolute offsets are measured from day 14.
      expect(crossedDays.last, 22);
    },
  );

  testWidgets(
    'physical Segmented field flings publish only their own coordinate',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 15),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      final yearTicks = <int>[];
      final monthTicks = <({int year, int day})>[];
      final dayTicks = <({int year, int month})>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryPillExperiment(
              variant: SummaryPillVariant.segmented,
              bounds: _bounds,
              navigation: navigation,
              visibleFrames: visibleFrames,
              onLevelCrossed: (_, _) {},
              onComponentCrossed: (candidate, component) {
                switch (component) {
                  case DashboardTemporalAnchorComponent.year:
                    yearTicks.add(candidate.yearCursor);
                    break;
                  case DashboardTemporalAnchorComponent.month:
                    monthTicks.add((
                      year: candidate.yearCursor,
                      day: candidate.dayCursor,
                    ));
                    break;
                  case DashboardTemporalAnchorComponent.day:
                    dayTicks.add((
                      year: candidate.yearCursor,
                      month: candidate.monthCursor.month,
                    ));
                    break;
                }
                navigation.commitTemporalCandidate(candidate);
              },
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-segmented-month-selector')),
        const Offset(0, -120),
        1500,
      );
      await tester.pumpAndSettle();
      expect(monthTicks, isNotEmpty);
      expect(monthTicks.map((tick) => tick.year), everyElement(2026));
      expect(monthTicks.map((tick) => tick.day), everyElement(15));
      expect(yearTicks, isEmpty);
      expect(dayTicks, isEmpty);

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
        const Offset(0, -120),
        1500,
      );
      await tester.pumpAndSettle();
      expect(dayTicks, isNotEmpty);
      expect(dayTicks.map((tick) => tick.year), everyElement(2026));
      expect(
        dayTicks.map((tick) => tick.month),
        everyElement(navigation.state.monthCursor.month),
      );
      expect(yearTicks, isEmpty);

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
        const Offset(0, -120),
        1500,
      );
      await tester.pumpAndSettle();
      expect(yearTicks, isNotEmpty);
      expect(
        navigation.state.monthCursor.month,
        dayTicks.last.month,
        reason: 'the YEAR spinner never carries into the MONTH selector',
      );
    },
  );

  testWidgets(
    'mirrored Segmented fields retain their own rendered hit Rects and flings',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 15),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      final componentTicks = <DashboardTemporalAnchorComponent>[];
      final levelTicks = <TimePlane>[];
      const presentation = DashboardSummaryPresentationSettings(
        showSeparators: true,
        temporalFlingPresentation: SummaryTemporalFlingPresentation.current,
        segmentedOrientation: SummarySegmentedOrientation.mirrored,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryPillExperiment(
              variant: SummaryPillVariant.segmented,
              bounds: _bounds,
              navigation: navigation,
              visibleFrames: visibleFrames,
              presentation: presentation,
              onLevelCrossed: (plane, _) => levelTicks.add(plane),
              onComponentCrossed: (candidate, component) {
                componentTicks.add(component);
                navigation.commitTemporalCandidate(candidate);
              },
            ),
          ),
        ),
      );

      final shell = tester.getRect(
        find.byKey(const ValueKey('summary-pill-experiment-segmented')),
      );
      final amount = tester.getRect(
        find.byKey(const ValueKey('summary-pill-experiment-amount-zone')),
      );
      final inset = shell.width <= 320
          ? 6.0
          : FluviVisualTokens.controlHorizontalInset;
      final geometry = SummarySegmentedTrackGeometry.resolve(
        width: shell.width - amount.width - inset,
        height: amount.height,
        activeTrackIndices: const <int>[0, 1, 2, 3],
        preRegressionNavigationWidth: shell.width - amount.width - inset * 2,
        orientation: SummarySegmentedOrientation.mirrored,
      );
      final selectors = <int, Finder>{
        0: find.byKey(const ValueKey('summary-pill-segmented-mode-selector')),
        1: find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
        2: find.byKey(const ValueKey('summary-pill-segmented-month-selector')),
        3: find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
      };
      for (final entry in selectors.entries) {
        expect(
          tester.getRect(entry.value),
          geometry
              .semanticRectForTrack(entry.key)
              .shift(Offset(amount.right, amount.top)),
          reason: 'mirrored visual, clip, semantics and hit owner must match',
        );
      }
      expect(amount.right, lessThan(tester.getRect(selectors[3]!).left));
      expect(
        tester.getRect(selectors[3]!).right,
        lessThan(tester.getRect(selectors[2]!).left),
      );
      expect(
        tester.getRect(selectors[2]!).right,
        lessThan(tester.getRect(selectors[1]!).left),
      );
      expect(
        tester.getRect(selectors[1]!).right,
        lessThan(tester.getRect(selectors[0]!).left),
      );

      await tester.fling(selectors[0]!, const Offset(0, 40), 600);
      await tester.pumpAndSettle();
      expect(levelTicks, isNotEmpty);

      for (final component in <DashboardTemporalAnchorComponent>[
        DashboardTemporalAnchorComponent.year,
        DashboardTemporalAnchorComponent.month,
        DashboardTemporalAnchorComponent.day,
      ]) {
        componentTicks.clear();
        final finder = switch (component) {
          DashboardTemporalAnchorComponent.year => selectors[1]!,
          DashboardTemporalAnchorComponent.month => selectors[2]!,
          DashboardTemporalAnchorComponent.day => selectors[3]!,
        };
        await tester.fling(finder, const Offset(0, -120), 1500);
        await tester.pumpAndSettle();
        expect(componentTicks, isNotEmpty);
        expect(componentTicks, everyElement(component));
      }
    },
  );

  testWidgets(
    'fixed experiment zones remain bounded on a narrow scaled surface',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 9, 30),
        initialPlane: TimePlane.month,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: SummaryPillExperiment(
                  variant: SummaryPillVariant.segmented,
                  bounds: const DashboardBounds(
                    left: 0,
                    top: 0,
                    width: 320,
                    height: 59,
                  ),
                  navigation: navigation,
                  visibleFrames: visibleFrames,
                  onLevelCrossed: (_, _) {},
                  onComponentCrossed: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );

      final year = find.byKey(
        const ValueKey('summary-pill-segmented-year-selector'),
      );
      final month = find.byKey(
        const ValueKey('summary-pill-segmented-month-selector'),
      );
      expect(tester.getTopLeft(year).dx, lessThan(tester.getTopLeft(month).dx));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('downward mode crossing means finer Summary hierarchy', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    final levels = <({TimePlane plane, bool railOpen})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPillExperiment(
          variant: SummaryPillVariant.segmented,
          bounds: _bounds,
          navigation: navigation,
          visibleFrames: visibleFrames,
          onLevelCrossed: (plane, railOpen) =>
              levels.add((plane: plane, railOpen: railOpen)),
          onComponentCrossed: (_, _) {},
        ),
      ),
    );

    await tester.fling(
      find.byKey(const ValueKey('summary-pill-segmented-mode-selector')),
      const Offset(0, 40),
      600,
    );
    await tester.pumpAndSettle();

    expect(levels, isNotEmpty);
    expect(levels.first, (plane: TimePlane.year, railOpen: false));
  });

  testWidgets('Summary separator visibility is paint-only', (tester) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    const presentation = DashboardSummaryPresentationSettings(
      showSeparators: false,
      temporalFlingPresentation: SummaryTemporalFlingPresentation.current,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPillExperiment(
          variant: SummaryPillVariant.segmented,
          bounds: _bounds,
          navigation: navigation,
          visibleFrames: visibleFrames,
          presentation: presentation,
          onLevelCrossed: (_, _) {},
          onComponentCrossed: (_, _) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('summary-pill-segmented-separator-1')),
      findsNothing,
    );
    final hiddenSeparatorYearX = tester
        .getTopLeft(
          find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
        )
        .dx;

    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPillExperiment(
          variant: SummaryPillVariant.segmented,
          bounds: _bounds,
          navigation: navigation,
          visibleFrames: visibleFrames,
          presentation: const DashboardSummaryPresentationSettings.defaults(),
          onLevelCrossed: (_, _) {},
          onComponentCrossed: (_, _) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('summary-pill-segmented-separator-1')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
          )
          .dx,
      hiddenSeparatorYearX,
    );
  });

  testWidgets('mode selector is always the current LogBox avatar metric', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    const presentation = DashboardSummaryPresentationSettings(
      showSeparators: true,
      temporalFlingPresentation: SummaryTemporalFlingPresentation.current,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPillExperiment(
          variant: SummaryPillVariant.segmented,
          bounds: _bounds,
          navigation: navigation,
          visibleFrames: visibleFrames,
          presentation: presentation,
          onLevelCrossed: (_, _) {},
          onComponentCrossed: (_, _) {},
        ),
      ),
    );
    final badge = find.byKey(
      const ValueKey('summary-pill-segmented-mode-badge-month'),
    );
    expect(tester.getSize(badge).width, greaterThanOrEqualTo(34));
    expect(find.text('HÓ'), findsNothing);
  });

  testWidgets('large mode visual left and top padding are equal', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      ),
    );
    // CenteredCarousel applies its initial physical recenter after the first
    // layout. Verify the settled visual owner rather than an off-center
    // bootstrap list child.
    await tester.pump();
    final shell = tester.getRect(
      find.byKey(const ValueKey('summary-pill-experiment-segmented')),
    );
    // A cyclic carousel can retain a non-clipped bootstrap copy above or
    // below its viewport. Choose the badge whose real visual rect is inside
    // the Summary shell, not the first matching offscreen child.
    final badgeFinder = find.byKey(
      const ValueKey('summary-pill-segmented-mode-badge-month'),
    );
    final badge = badgeFinder
        .evaluate()
        .map((element) {
          final box = element.renderObject! as RenderBox;
          return box.localToGlobal(Offset.zero) & box.size;
        })
        .singleWhere(
          (rect) =>
              rect.top >= shell.top &&
              rect.bottom <= shell.bottom &&
              rect.left >= shell.left &&
              rect.right <= shell.right,
        );
    expect(badge.left - shell.left, badge.top - shell.top);
  });

  testWidgets('rendered hierarchy and hit rects are the one layout geometry', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 22),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
    );
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(navigation.dispose);
    addTearDown(visibleFrames.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPillExperiment(
          variant: SummaryPillVariant.segmented,
          bounds: _bounds,
          navigation: navigation,
          visibleFrames: visibleFrames,
          onLevelCrossed: (_, _) {},
          onComponentCrossed: (_, _) {},
        ),
      ),
    );

    final shell = tester.getRect(
      find.byKey(const ValueKey('summary-pill-experiment-segmented')),
    );
    final amount = tester.getRect(
      find.byKey(const ValueKey('summary-pill-experiment-amount-zone')),
    );
    final finalInset = shell.width <= 320
        ? 6.0
        : FluviVisualTokens.controlHorizontalInset;
    final geometry = SummarySegmentedTrackGeometry.resolve(
      width: shell.width - amount.width - finalInset,
      height: amount.height,
      activeTrackIndices: const <int>[0, 1, 2, 3],
      preRegressionNavigationWidth: shell.width - amount.width - finalInset * 2,
    );
    final selectors = <int, Finder>{
      1: find.byKey(const ValueKey('summary-pill-segmented-year-selector')),
      2: find.byKey(const ValueKey('summary-pill-segmented-month-selector')),
      3: find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
    };
    for (final entry in selectors.entries) {
      final actual = tester.getRect(entry.value);
      final expected = geometry
          .semanticRectForTrack(entry.key)
          .shift(Offset(shell.left, amount.top));
      expect(actual, expected);
    }
  });

  testWidgets(
    'Dynamic Trio has one idle value and three continuous motion values',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 22),
        initialPlane: TimePlane.month,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      const presentation = DashboardSummaryPresentationSettings(
        showSeparators: true,
        temporalFlingPresentation: SummaryTemporalFlingPresentation.dynamicTrio,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            presentation: presentation,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      );

      final target = find.byKey(
        const ValueKey('summary-pill-segmented-month-selector'),
      );
      final trioValues = find.descendant(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith(
                'summary-pill-dynamic-trio-',
              ),
        ),
      );
      expect(trioValues, findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);

      await tester.fling(target, const Offset(0, -120), 1500);
      await tester.pump(const Duration(milliseconds: 120));

      expect(trioValues, findsNWidgets(3));

      // Stop at the first idle observation. Dynamic Trio belongs only to
      // physical drag/ballistic/snap movement and must not retain neighbors
      // through an arbitrary post-settle timer.
      for (
        var frame = 0;
        frame < 120 && tester.binding.hasScheduledFrame;
        frame += 1
      ) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        trioValues,
        findsOneWidget,
        reason:
            'The first idle frame after a real ballistic completion is '
            'center-only.',
      );
    },
  );

  testWidgets(
    'Dynamic Trio small non-ballistic release collapses immediately',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 22),
        initialPlane: TimePlane.month,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      const presentation = DashboardSummaryPresentationSettings(
        showSeparators: true,
        temporalFlingPresentation: SummaryTemporalFlingPresentation.dynamicTrio,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SummaryPillExperiment(
            variant: SummaryPillVariant.segmented,
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visibleFrames,
            presentation: presentation,
            onLevelCrossed: (_, _) {},
            onComponentCrossed: (_, _) {},
          ),
        ),
      );
      final target = find.byKey(
        const ValueKey('summary-pill-segmented-month-selector'),
      );
      final trioValues = find.descendant(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith(
                'summary-pill-dynamic-trio-',
              ),
        ),
      );

      await tester.drag(target, const Offset(0, -10));
      await tester.pumpAndSettle();
      expect(trioValues, findsOneWidget);
    },
  );
}

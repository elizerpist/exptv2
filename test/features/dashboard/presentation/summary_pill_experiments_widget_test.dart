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
    expect(tester.getSize(badge), const Size(25, 25));
    final badgeWidget = tester.widget<Container>(badge);
    expect(badgeWidget.padding, const EdgeInsets.all(5));
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
      modeSelectorLayout: SummaryModeSelectorLayout.current,
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

  testWidgets('large mode icon is at least the current LogBox avatar metric', (
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
      modeSelectorLayout: SummaryModeSelectorLayout.largeIcon,
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

  testWidgets('icon plus label preserves the current badge metric', (
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
      modeSelectorLayout: SummaryModeSelectorLayout.iconWithLabel,
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
    expect(tester.getSize(badge), const Size(25, 25));
    expect(find.text('HÓ'), findsOneWidget);
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
        modeSelectorLayout: SummaryModeSelectorLayout.current,
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
    },
  );
}

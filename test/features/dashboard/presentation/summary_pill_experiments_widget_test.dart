import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_experiments.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

void main() {
  testWidgets('segmented shell resolves the global SummaryPill family', (
    tester,
  ) async {
    final roundness = DashboardCornerRoundnessController()..setPosition(1);
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
      const DashboardCornerProfile(DashboardCornerRoundness(1)).borderRadiusFor(
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
}

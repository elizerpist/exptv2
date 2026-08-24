import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_experiments.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

void main() {
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
    'Swipe Mode has no visible mode column and owns horizontal mode intent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 22),
        initialPlane: TimePlane.year,
      );
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(navigation.dispose);
      addTearDown(visibleFrames.dispose);
      final crossed = <(TimePlane, bool)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryPillExperiment(
              variant: SummaryPillVariant.swipeMode,
              bounds: _bounds,
              navigation: navigation,
              visibleFrames: visibleFrames,
              onLevelCrossed: (plane, isRailOpen) =>
                  crossed.add((plane, isRailOpen)),
              onComponentCrossed: (_, _) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('summary-pill-swipe-mode-surface')),
        findsOneWidget,
      );
      final swipeSemantics = tester.getSemantics(
        find.byKey(const ValueKey('summary-pill-swipe-mode-semantics')),
      );
      final swipeData = swipeSemantics.getSemanticsData();
      expect(
        swipeData.label,
        contains('Időszint: Éves. Vízszintesen húzva válthat időszintet.'),
      );
      expect(swipeData.hasAction(SemanticsAction.increase), isTrue);
      expect(swipeData.hasAction(SemanticsAction.decrease), isTrue);
      swipeSemantics.owner!.performAction(
        swipeSemantics.id,
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(crossed.last, (TimePlane.month, false));
      expect(
        find.byKey(const ValueKey('summary-pill-swipe-year-selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-pill-swipe-month-selector')),
        findsNothing,
      );

      await tester.fling(
        find.byKey(const ValueKey('summary-pill-swipe-mode-surface')),
        const Offset(-160, 0),
        1800,
      );
      await tester.pumpAndSettle();
      expect(crossed, isNotEmpty);
      semantics.dispose();
    },
  );

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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

void main() {
  testWidgets('legacy shell resolves the same global SummaryPill family', (
    tester,
  ) async {
    final roundness = DashboardCornerRoundnessController()..setPosition(1);
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    addTearDown(roundness.dispose);
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardCornerRoundnessScope(
          controller: roundness,
          child: Scaffold(body: _pill(navigation, visible, motion)),
        ),
      ),
    );

    expect(
      tester
          .widget<FluviRoundedBox>(
            find.descendant(
              of: find.byType(DashboardSummaryPill),
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

  testWidgets('preview swaps prepared amount and child label directly', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    visible.publish(_frame(day: 14, amount: '123,45 Ft', generation: 1));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _pill(navigation, visible, motion))),
    );
    expect(find.text('2026 július 14'), findsOneWidget);
    expect(find.text('123,45 Ft'), findsOneWidget);

    visible.publish(_frame(day: 15, amount: '456,78 Ft', generation: 2));
    await tester.pump();

    expect(find.text('2026 július 15'), findsOneWidget);
    expect(find.text('456,78 Ft'), findsOneWidget);
    expect(find.text('123,45 Ft'), findsNothing);
  });

  testWidgets('settle promotion of the same value starts no amount animation', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    final frame = _frame(day: 14, amount: '123,45 Ft', generation: 1);
    visible.publish(frame);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _pill(navigation, visible, motion))),
    );
    final amountElement = tester.element(find.text('123,45 Ft'));

    expect(
      visible.promoteCommitted(
        expectedKey: frame.queryKey,
        epoch: frame.presentationEpoch,
      ),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 140));

    expect(
      identical(tester.element(find.text('123,45 Ft')), amountElement),
      isTrue,
    );
    expect(visible.visiblePublishCount, 1);
  });

  testWidgets('open year rail keeps the live visible month parent-aware', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 6, 16),
      initialPlane: TimePlane.year,
      initialRailOpen: true,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    visible.publish(_yearRailFrame(month: 6, generation: 1));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _pill(navigation, visible, motion))),
    );
    expect(find.text('Éves'), findsOneWidget);
    expect(find.text('2026 június'), findsOneWidget);
    expect(find.text('június'), findsNothing);

    visible.publish(_yearRailFrame(month: 7, generation: 2));
    await tester.pump();
    expect(find.text('2026 július'), findsOneWidget);
    expect(find.text('2026 június'), findsNothing);
  });

  testWidgets(
    'open month child labels remain complete at supported phone widths',
    (tester) async {
      for (final width in <double>[320, 378, 430]) {
        final navigation = DashboardNavigationController(
          initialDate: DateTime(2026, 9, 30),
          initialPlane: TimePlane.month,
          initialRailOpen: true,
        );
        final visible = DashboardVisibleFrameStore();
        final motion = SummaryNavigationMotionController();
        final frame = _frame(
          day: 30,
          month: 9,
          amount: '0 Ft',
          generation: width.toInt(),
        );
        visible.publish(frame);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: _pill(
                  navigation,
                  visible,
                  motion,
                  bounds: DashboardBounds(
                    left: 0,
                    top: 0,
                    width: width,
                    height: 59,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final subtitle = find.text('2026 szeptember 30');
        expect(subtitle, findsOneWidget, reason: 'width=$width');
        final paragraph = tester.renderObject<RenderParagraph>(subtitle);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: 'width=$width paragraphSize=${paragraph.size}',
        );
        expect(tester.takeException(), isNull, reason: 'width=$width');

        navigation.dispose();
        visible.dispose();
        motion.dispose();
      }
    },
  );

  testWidgets('shell gesture commits immediately and emits one haptic', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    var moves = 0;
    var haptics = 0;
    final motionStates = <bool>[];
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    visible.publish(_frame(day: 14, amount: '123,45 Ft', generation: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visible,
            navigationMotionController: motion,
            onMotionActiveChanged: motionStates.add,
            horizontalCandidateBuilder: (_) => null,
            onToggleRail: () {},
            onMoveFiner: () => moves += 1,
            onMoveBroader: () {},
            onMovePrevious: () {},
            onMoveNext: () {},
            onSelectionHaptic: () => haptics += 1,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(DashboardSummaryPill), const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(moves, 1);
    expect(haptics, 1);
    expect(motionStates, <bool>[true, false]);
  });

  testWidgets('each chevron tap emits exactly one rail-toggle intent', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    var railToggles = 0;
    addTearDown(navigation.dispose);
    addTearDown(visible.dispose);
    addTearDown(motion.dispose);
    visible.publish(_frame(day: 14, amount: '123,45 Ft', generation: 1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visible,
            navigationMotionController: motion,
            horizontalCandidateBuilder: (_) => null,
            onToggleRail: () => railToggles += 1,
            onMoveFiner: () {},
            onMoveBroader: () {},
            onMovePrevious: () {},
            onMoveNext: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
    await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));

    expect(railToggles, 2);
  });

  testWidgets(
    'vertical threshold swipes follow the canonical plane order when rail is closed or open',
    (tester) async {
      for (final railOpen in <bool>[false, true]) {
        for (final swipe
            in <
              ({
                Offset offset,
                List<TimePlane> expected,
                SummaryTransitionDirection visualDirection,
              })
            >[
              (
                offset: const Offset(0, 80),
                expected: <TimePlane>[
                  TimePlane.year,
                  TimePlane.month,
                  TimePlane.sum,
                ],
                visualDirection: SummaryTransitionDirection.backward,
              ),
              (
                offset: const Offset(0, -80),
                expected: <TimePlane>[
                  TimePlane.month,
                  TimePlane.year,
                  TimePlane.sum,
                ],
                visualDirection: SummaryTransitionDirection.forward,
              ),
            ]) {
          final navigation = DashboardNavigationController(
            initialDate: DateTime(2026, 7, 14),
            initialPlane: TimePlane.sum,
            initialRailOpen: railOpen,
          );
          final visible = DashboardVisibleFrameStore();
          final motion = SummaryNavigationMotionController();
          final planes = <TimePlane>[];
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DashboardSummaryPill(
                  bounds: _bounds,
                  navigation: navigation,
                  visibleFrames: visible,
                  navigationMotionController: motion,
                  horizontalCandidateBuilder: (_) => null,
                  onToggleRail: () {},
                  onMoveFiner: () {
                    planes.add(navigation.commitPlane(finer: true).plane);
                  },
                  onMoveBroader: () {
                    planes.add(navigation.commitPlane(finer: false).plane);
                  },
                  onMovePrevious: () {},
                  onMoveNext: () {},
                ),
              ),
            ),
          );

          for (var gesture = 0; gesture < 3; gesture += 1) {
            await tester.drag(find.byType(DashboardSummaryPill), swipe.offset);
            expect(motion.stagedText.direction, swipe.visualDirection);
            await tester.pumpAndSettle();
          }
          expect(planes, swipe.expected, reason: 'railOpen=$railOpen');
          navigation.dispose();
          visible.dispose();
          motion.dispose();
        }
      }
    },
  );

  testWidgets('vertical velocity commits use the same finer/broader mapping', (
    tester,
  ) async {
    Future<TimePlane> commitWithFling(Offset offset) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.sum,
      );
      final visible = DashboardVisibleFrameStore();
      final motion = SummaryNavigationMotionController();
      TimePlane? committed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigation: navigation,
              visibleFrames: visible,
              navigationMotionController: motion,
              horizontalCandidateBuilder: (_) => null,
              onToggleRail: () {},
              onMoveFiner: () {
                committed = navigation.commitPlane(finer: true).plane;
              },
              onMoveBroader: () {
                committed = navigation.commitPlane(finer: false).plane;
              },
              onMovePrevious: () {},
              onMoveNext: () {},
            ),
          ),
        ),
      );
      final initialOffset = Offset(0, offset.dy.isNegative ? 100 : -100);
      await tester.fling(
        find.byType(DashboardSummaryPill),
        offset,
        800,
        initialOffset: initialOffset,
        initialOffsetDelay: const Duration(milliseconds: 1),
      );
      await tester.pumpAndSettle();
      navigation.dispose();
      visible.dispose();
      motion.dispose();
      return committed!;
    }

    expect(await commitWithFling(const Offset(0, 127)), TimePlane.year);
    expect(await commitWithFling(const Offset(0, -127)), TimePlane.month);
  });
}

DashboardSummaryPill _pill(
  DashboardNavigationController navigation,
  DashboardVisibleFrameStore visible,
  SummaryNavigationMotionController motion, {
  DashboardBounds bounds = _bounds,
}) => DashboardSummaryPill(
  bounds: bounds,
  navigation: navigation,
  visibleFrames: visible,
  navigationMotionController: motion,
  horizontalCandidateBuilder: (_) => null,
  onToggleRail: () {},
  onMoveFiner: () {},
  onMoveBroader: () {},
  onMovePrevious: () {},
  onMoveNext: () {},
);

DashboardVisibleFrame _frame({
  required int day,
  int month = 7,
  required String amount,
  required int generation,
}) {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  final scope = parent.copyWith(
    timeScope: DayScope(YearMonth(year: 2026, month: month).clampDay(day)),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: const [],
    entryCount: 0,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: parent.key,
    coreRevision: 1,
    totalMinor: generation,
    formattedAmount: amount,
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: logBox,
    presentationDigest: generation,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: parent.key,
    plane: TimePlane.month,
    railOpen: true,
    semanticIndex: day - 1,
    childLabel: '$day',
    navigationEpoch: 0,
    presentationEpoch: 1,
    frameGeneration: generation,
    mode: DashboardVisibleMode.preview,
  );
}

DashboardVisibleFrame _yearRailFrame({
  required int month,
  required int generation,
}) {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const YearScope(2026),
  );
  final scope = parent.copyWith(
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: const [],
    entryCount: 0,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: parent.key,
    coreRevision: 1,
    totalMinor: generation,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: logBox,
    presentationDigest: generation,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: parent.key,
    plane: TimePlane.year,
    railOpen: true,
    semanticIndex: month - 1,
    childLabel: 'csak hónap',
    navigationEpoch: 0,
    presentationEpoch: generation,
    frameGeneration: generation,
    mode: DashboardVisibleMode.preview,
  );
}

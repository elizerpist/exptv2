import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/summary_text_content.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

void main() {
  testWidgets('open child rail keeps live child feedback inside mother zone', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
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
    expect(find.text('2026. július'), findsNWidgets(2));
    expect(find.text('2026 július 14'), findsOneWidget);
    expect(find.text('123,45 Ft'), findsOneWidget);
    final motherSemantics = tester
        .getSemantics(
          find.byKey(const ValueKey('dashboard-summary-open-mother-semantics')),
        )
        .getSemanticsData();
    expect(
      motherSemantics.label,
      'Időszak: 2026. július. '
      'Vízszintesen húzva testvér időszakot választhat.',
    );
    expect(motherSemantics.hasAction(SemanticsAction.increase), isTrue);
    expect(motherSemantics.hasAction(SemanticsAction.decrease), isTrue);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey('dashboard-summary-open-child-feedback-semantics'),
            ),
          )
          .getSemanticsData()
          .label,
      'Aktív finomítás: 2026 július 14',
    );

    motion.triggerRailTick(oldLogicalIndex: 14, newLogicalIndex: 15);
    visible.publish(_frame(day: 15, amount: '456,78 Ft', generation: 2));
    await tester.pump();

    expect(find.text('2026. július'), findsNWidgets(2));
    expect(find.text('2026 július 15'), findsOneWidget);
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('summary-navigation-tick-transform')),
    );
    expect(transform.transform.getTranslation().y, lessThan(0));
    expect(find.text('456,78 Ft'), findsOneWidget);
    expect(find.text('123,45 Ft'), findsNothing);
    semanticsHandle.dispose();
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

  testWidgets('open year rail keeps live child feedback inside mother zone', (
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
    expect(find.text('2026'), findsNWidgets(2));
    expect(find.text('2026 június'), findsOneWidget);

    motion.triggerRailTick(oldLogicalIndex: 6, newLogicalIndex: 7);
    visible.publish(_yearRailFrame(month: 7, generation: 2));
    await tester.pump();
    expect(find.text('2026'), findsNWidgets(2));
    expect(find.text('2026 július'), findsOneWidget);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('summary-navigation-tick-transform')),
          )
          .transform
          .getTranslation()
          .y,
      lessThan(0),
    );
  });

  testWidgets('open child rail keeps mother sibling carousel interactive', (
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
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigation: navigation,
            visibleFrames: visible,
            navigationMotionController: motion,
            horizontalCandidateBuilder: (_) => null,
            onToggleRail: () {},
            onMoveFiner: () {},
            onMoveBroader: () {},
            onMovePrevious: () {},
            onMoveNext: () {},
            onSelectPlaneTarget: (target, {required finer}) {},
            motherLabelForOffset: (offset) {
              final candidate = navigation.parentOffsetCandidate(offset);
              return candidate == null
                  ? null
                  : SummaryNavigationProjector.parentLabel(candidate);
            },
            onSelectMotherOffset: (offset) {
              final candidate = navigation.parentOffsetCandidate(offset);
              if (candidate == null) return;
              navigation.commitParentCandidate(
                candidate,
                offset.isNegative
                    ? DashboardTimeNavigationChangeDirection.backward
                    : DashboardTimeNavigationChangeDirection.forward,
              );
            },
          ),
        ),
      ),
    );

    await tester.fling(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-summary-mother-selector')),
        matching: find.byType(ListView),
      ),
      const Offset(-180, 0),
      1800,
    );
    await tester.pumpAndSettle();

    expect(navigation.state.yearCursor, 2029);
    expect(navigation.state.isRailOpen, isTrue);
  });

  testWidgets('mother labels remain complete at supported phone widths', (
    tester,
  ) async {
    for (final width in <double>[320, 378, 430]) {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 9, 30),
        initialPlane: TimePlane.month,
        initialRailOpen: false,
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

      final subtitle = find.text('2026. szeptember');
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
    'bounded primary axis and mother zones keep orthogonal gesture ownership',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
      );
      final visible = DashboardVisibleFrameStore();
      final motion = SummaryNavigationMotionController();
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
              horizontalCandidateBuilder: (_) => const SummaryTextContent(
                title: 'Havi',
                subtitle: '2026 augusztus',
              ),
              onToggleRail: () {},
              onMoveFiner: () {},
              onMoveBroader: () {},
              onMovePrevious: () {},
              onMoveNext: () {},
              onSelectPlaneTarget: (target, {required finer}) {
                navigation.commitPlaneTargetCandidate(
                  navigation.planeTargetCandidate(target),
                  finer: finer,
                );
              },
              motherLabelForOffset: (offset) {
                final candidate = navigation.parentOffsetCandidate(offset);
                return candidate == null
                    ? null
                    : SummaryNavigationProjector.parentLabel(candidate);
              },
              onSelectMotherOffset: (offset) {
                final candidate = navigation.parentOffsetCandidate(offset);
                if (candidate == null) return;
                navigation.commitParentCandidate(
                  candidate,
                  offset.isNegative
                      ? DashboardTimeNavigationChangeDirection.backward
                      : DashboardTimeNavigationChangeDirection.forward,
                );
              },
            ),
          ),
        ),
      );

      final axis = find.byKey(
        const ValueKey('dashboard-summary-axis-selector'),
      );
      final mother = find.byKey(
        const ValueKey('dashboard-summary-mother-selector'),
      );
      expect(axis, findsOneWidget);
      expect(mother, findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-summary-axis-separator')),
        findsOneWidget,
      );

      await tester.fling(
        find.descendant(of: axis, matching: find.byType(ListView)),
        const Offset(0, 90),
        300,
      );
      await tester.pumpAndSettle();
      expect(navigation.state.plane, TimePlane.year);

      await tester.fling(
        find.descendant(of: mother, matching: find.byType(ListView)),
        const Offset(-180, 0),
        1800,
      );
      await tester.pumpAndSettle();
      expect(navigation.state.yearCursor, 2029);
    },
  );

  testWidgets('SUM exposes no synthetic horizontal mother siblings', (
    tester,
  ) async {
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.sum,
    );
    final visible = DashboardVisibleFrameStore();
    final motion = SummaryNavigationMotionController();
    var motherCommits = 0;
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
            onToggleRail: () {},
            onMoveFiner: () {},
            onMoveBroader: () {},
            onMovePrevious: () {},
            onMoveNext: () {},
            onSelectPlaneTarget: (_, {required finer}) {},
            motherLabelForOffset: (_) => null,
            onSelectMotherOffset: (_) => motherCommits += 1,
          ),
        ),
      ),
    );

    final mother = find.byKey(
      const ValueKey('dashboard-summary-mother-selector'),
    );
    expect(mother, findsOneWidget);
    expect(
      find.descendant(of: mother, matching: find.byType(ListView)),
      findsNothing,
    );
    expect(find.text('Minden időszak'), findsOneWidget);

    await tester.drag(mother, const Offset(-180, 0));
    await tester.pump();
    expect(motherCommits, 0);
    expect(navigation.state.plane, TimePlane.sum);
  });

  testWidgets(
    'a vertical drag rejected by the mother zone remains dashboard-scrollable',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
      );
      final visible = DashboardVisibleFrameStore();
      final motion = SummaryNavigationMotionController();
      final dashboardScroll = ScrollController();
      addTearDown(navigation.dispose);
      addTearDown(visible.dispose);
      addTearDown(motion.dispose);
      addTearDown(dashboardScroll.dispose);
      visible.publish(_frame(day: 14, amount: '123,45 Ft', generation: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: dashboardScroll,
              child: SizedBox(
                width: _bounds.width,
                height: 900,
                child: Column(
                  children: [
                    _pill(navigation, visible, motion),
                    const SizedBox(height: 840),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final mother = find.descendant(
        of: find.byKey(const ValueKey('dashboard-summary-mother-selector')),
        matching: find.byType(ListView),
      );
      await tester.drag(mother, const Offset(0, -160));
      await tester.pumpAndSettle();

      expect(dashboardScroll.offset, greaterThan(0));
      expect(navigation.state.plane, TimePlane.month);
      expect(
        navigation.state.monthCursor,
        const YearMonth(year: 2026, month: 7),
      );
    },
  );
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
  onSelectPlaneTarget: (target, {required finer}) {
    navigation.commitPlaneTargetCandidate(
      navigation.planeTargetCandidate(target),
      finer: finer,
    );
  },
  motherLabelForOffset: (offset) {
    final candidate = navigation.parentOffsetCandidate(offset);
    return candidate == null
        ? null
        : SummaryNavigationProjector.parentLabel(candidate);
  },
  onSelectMotherOffset: (offset) {
    final candidate = navigation.parentOffsetCandidate(offset);
    if (candidate == null) return;
    navigation.commitParentCandidate(
      candidate,
      offset.isNegative
          ? DashboardTimeNavigationChangeDirection.backward
          : DashboardTimeNavigationChangeDirection.forward,
    );
  },
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

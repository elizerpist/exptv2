import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

SummaryNavigationPresentation _navigation({
  required String subtitle,
  required bool railOpen,
  SummaryContentChangeReason reason = SummaryContentChangeReason.initial,
  bool preview = false,
}) {
  return SummaryNavigationPresentation(
    plane: TimePlane.year,
    planeTitle: 'Éves',
    subtitle: subtitle,
    isRailOpen: railOpen,
    revision: subtitle.contains('május') ? 2 : 1,
    changeReason: reason,
    direction: SummaryTransitionDirection.forward,
    isPreview: preview,
  );
}

SummaryMetricsPresentation _amount({
  String text = '123,45 Ft',
  String? scopeKey,
  bool loading = false,
  bool stale = false,
  bool preview = false,
}) {
  final scope = _scopeFor(scopeKey);
  return SummaryMetricsPresentation.fromMetrics(
    ScopeSummaryMetrics(
      scope: scope,
      canonicalQueryKey: scope.key.value,
      coreRevision: 1,
      totalMinor: _minorFor(text),
      entryCount: 0,
      source: preview
          ? SummaryMetricsSource.childPreviewIndex
          : SummaryMetricsSource.freshQuery,
      isLoading: loading,
      isStale: stale,
      hasError: false,
    ),
    amountFormatter: (_) => text,
  );
}

CurrentLedgerQueryScope _scopeFor(String? raw) {
  final timeScope = switch (raw) {
    final value? when value.startsWith('day:') => () {
      final parts = value.substring(4).split('-').map(int.parse).toList();
      return DayScope(
        LocalDate(year: parts[0], month: parts[1], day: parts[2]),
      );
    }(),
    final value? when value.startsWith('month:') => () {
      final parts = value.substring(6).split('-').map(int.parse).toList();
      return MonthScope(YearMonth(year: parts[0], month: parts[1]));
    }(),
    final value? when value.startsWith('year:') => YearScope(
      int.parse(value.substring(5)),
    ),
    _ => const AllTimeScope(),
  };
  return CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: timeScope,
  );
}

int _minorFor(String text) {
  final normalized = text
      .replaceAll(' Ft', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  return (double.parse(normalized) * 100).round();
}

Offset _translation(WidgetTester tester, Key key) {
  final translation = tester
      .widget<Transform>(find.byKey(key))
      .transform
      .getTranslation();
  return Offset(translation.x, translation.y);
}

class _DelayedSummaryHost extends StatefulWidget {
  const _DelayedSummaryHost({this.initialRailOpen = false});

  final bool initialRailOpen;

  @override
  State<_DelayedSummaryHost> createState() => _DelayedSummaryHostState();
}

class _DelayedSummaryHostState extends State<_DelayedSummaryHost> {
  final amountRelease = Completer<void>();
  late bool railOpen;
  bool childSettled = false;

  @override
  void initState() {
    super.initState();
    railOpen = widget.initialRailOpen;
  }

  void settleChild() {
    setState(() => childSettled = true);
    amountRelease.future.then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void toggleRail() => setState(() => railOpen = !railOpen);

  @override
  Widget build(BuildContext context) {
    final isChildSettled = childSettled;
    return DashboardSummaryPill(
      bounds: _bounds,
      navigationPresentation: _navigation(
        subtitle: railOpen ? '2026. május' : (isChildSettled ? '2026' : '2026'),
        railOpen: railOpen,
        reason: isChildSettled
            ? SummaryContentChangeReason.childSettled
            : railOpen
            ? SummaryContentChangeReason.railOpened
            : SummaryContentChangeReason.railClosed,
      ),
      amountPresentation: _amount(
        loading: isChildSettled && !amountRelease.isCompleted,
        stale: isChildSettled && !amountRelease.isCompleted,
        text: amountRelease.isCompleted ? '456,78 Ft' : '123,45 Ft',
      ),
      onToggleRail: toggleRail,
    );
  }
}

void main() {
  for (final railOpen in [false, true]) {
    testWidgets(
      'left SummaryPill swipe dispatches the next YEAR parent when railOpen=$railOpen',
      (tester) async {
        var nextParentRequests = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardSummaryPill(
                bounds: _bounds,
                navigationPresentation: _navigation(
                  subtitle: '2026',
                  railOpen: railOpen,
                ),
                amountPresentation: _amount(),
                horizontalCandidateBuilder: (direction) =>
                    direction == SummaryTransitionDirection.forward
                    ? const SummaryTextContent(title: 'Éves', subtitle: '2027')
                    : const SummaryTextContent(title: 'Éves', subtitle: '2025'),
                onMoveNext: () => nextParentRequests += 1,
              ),
            ),
          ),
        );

        await tester.drag(
          find.byType(DashboardSummaryPill),
          const Offset(-80, 0),
        );
        await tester.pump();

        expect(nextParentRequests, 1);
      },
    );
  }

  testWidgets(
    'rail preview updates navigation without replacing the amount region',
    (tester) async {
      final navigation = ValueNotifier(
        _navigation(
          subtitle: '2026. július',
          railOpen: true,
          reason: SummaryContentChangeReason.railOpened,
        ),
      );
      addTearDown(navigation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigationPresentation: navigation.value,
              navigationListenable: navigation,
              navigationPresentationBuilder: () => navigation.value,
              amountPresentation: _amount(text: '707 000 Ft'),
            ),
          ),
        ),
      );

      final amountElement = tester.element(find.text('707 000 Ft'));
      navigation.value = _navigation(
        subtitle: '2026. december',
        railOpen: true,
        reason: SummaryContentChangeReason.childSettled,
      );
      await tester.pump();

      expect(find.text('2026. december'), findsOneWidget);
      expect(find.text('707 000 Ft'), findsOneWidget);
      expect(
        identical(tester.element(find.text('707 000 Ft')), amountElement),
        isTrue,
      );
    },
  );

  testWidgets(
    'child settle updates subtitle on next frame before delayed amount',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _DelayedSummaryHost(initialRailOpen: true)),
      );
      final state = tester.state<_DelayedSummaryHostState>(
        find.byType(_DelayedSummaryHost),
      );

      state.settleChild();
      await tester.pump();

      expect(find.text('2026. május'), findsOneWidget);
      expect(find.text('123,45 Ft'), findsOneWidget);
      expect(find.text('456,78 Ft'), findsNothing);

      state.amountRelease.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));

      expect(find.text('456,78 Ft'), findsOneWidget);
    },
  );

  testWidgets('rail toggle keeps title stable and changes only subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _DelayedSummaryHost()));

    expect(find.text('Éves'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
    await tester.pump();

    expect(find.text('Éves'), findsOneWidget);
    expect(find.text('2026. május'), findsOneWidget);
  });

  testWidgets(
    'committed gesture emits one haptic and cancelled gesture emits none',
    (tester) async {
      var haptics = 0;
      var moves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigationPresentation: _navigation(
                subtitle: '2026',
                railOpen: false,
              ),
              amountPresentation: _amount(),
              onMoveFiner: () => moves += 1,
              onSelectionHaptic: () => haptics += 1,
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(DashboardSummaryPill),
        const Offset(0, -80),
      );
      expect(moves, 1);
      expect(haptics, 1);

      await tester.drag(
        find.byType(DashboardSummaryPill),
        const Offset(0, -12),
      );
      expect(haptics, 1);
    },
  );

  testWidgets('shell return repaints only the transform', (tester) async {
    final motion = SummaryNavigationMotionController();
    final navigation = ValueNotifier(
      _navigation(subtitle: '2026', railOpen: false),
    );
    final amount = ValueNotifier(_amount(text: '707 000 Ft'));
    addTearDown(motion.dispose);
    addTearDown(navigation.dispose);
    addTearDown(amount.dispose);
    var navigationBuilderCalls = 0;
    var amountBuilderCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: navigation.value,
            navigationListenable: navigation,
            navigationPresentationBuilder: () {
              navigationBuilderCalls += 1;
              return navigation.value;
            },
            navigationMotionController: motion,
            amountPresentation: amount.value,
            amountListenable: amount,
            amountPresentationBuilder: () {
              amountBuilderCalls += 1;
              return amount.value;
            },
            onMoveFiner: () {
              navigation.value = SummaryNavigationPresentation(
                plane: TimePlane.month,
                planeTitle: 'Havi',
                subtitle: '2026. július',
                isRailOpen: false,
                revision: 2,
                changeReason: SummaryContentChangeReason.verticalPlaneForward,
                direction: SummaryTransitionDirection.forward,
              );
            },
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DashboardSummaryPill)),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final navigationCallsBeforeReturnFrame = navigationBuilderCalls;
    final amountCallsBeforeReturnFrame = amountBuilderCalls;

    await tester.pump(const Duration(milliseconds: 50));

    expect(navigationBuilderCalls, navigationCallsBeforeReturnFrame);
    expect(amountBuilderCalls, amountCallsBeforeReturnFrame);
    expect(
      _translation(
        tester,
        const ValueKey('dashboard-summary-shell-transform'),
      ).dx,
      0,
    );
    expect(
      _translation(
        tester,
        const ValueKey('dashboard-summary-shell-transform'),
      ).dy,
      lessThan(0),
    );
    expect(
      find.byKey(const ValueKey('dashboard-summary-shell-repaint-boundary')),
      findsOneWidget,
    );
    expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);
  });

  testWidgets('latest text transition wins over an interrupted transition', (
    tester,
  ) async {
    var content = const SummaryTextContent(title: 'Éves', subtitle: '2026');
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                SummaryPillTextTransition(
                  content: content,
                  axis: SummaryTransitionAxis.horizontal,
                  direction: SummaryTransitionDirection.forward,
                ),
                TextButton(
                  onPressed: () => setState(() {
                    content = const SummaryTextContent(
                      title: 'Éves',
                      subtitle: '2027',
                    );
                  }),
                  child: const Text('change'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('change'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('change'));
    await tester.pumpAndSettle();

    expect(find.text('2027'), findsOneWidget);
    expect(find.text('2026'), findsNothing);
  });

  testWidgets(
    'rail preview cancels an in-flight subtitle transition instead of stacking rows',
    (tester) async {
      final navigation = ValueNotifier(
        _navigation(
          subtitle: '2026. június',
          railOpen: true,
          reason: SummaryContentChangeReason.childSettled,
        ),
      );
      addTearDown(navigation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigationPresentation: navigation.value,
              navigationListenable: navigation,
              navigationPresentationBuilder: () => navigation.value,
              amountPresentation: _amount(text: '707 000 Ft'),
            ),
          ),
        ),
      );

      navigation.value = _navigation(
        subtitle: '2026. július',
        railOpen: true,
        reason: SummaryContentChangeReason.childSettled,
      );
      await tester.pump(const Duration(milliseconds: 40));

      navigation.value = _navigation(
        subtitle: '2026. augusztus',
        railOpen: true,
        reason: SummaryContentChangeReason.childSettled,
        preview: true,
      );
      await tester.pump();

      expect(find.text('2026. augusztus'), findsOneWidget);
      expect(find.text('2026. július'), findsNothing);
      expect(find.text('2026. június'), findsNothing);
    },
  );

  testWidgets('horizontal parent change crossfades both text blocks in X', (
    tester,
  ) async {
    final navigation = ValueNotifier(
      _navigation(subtitle: '2026. július', railOpen: false),
    );
    addTearDown(navigation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: navigation.value,
            navigationListenable: navigation,
            navigationPresentationBuilder: () => navigation.value,
            amountPresentation: _amount(text: '707 000 Ft'),
          ),
        ),
      ),
    );

    navigation.value = _navigation(
      subtitle: '2026. június',
      railOpen: false,
      reason: SummaryContentChangeReason.horizontalParentBackward,
    );
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.text('2026. június'), findsOneWidget);
    expect(find.text('2026. július'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('2026. június'), findsOneWidget);
    expect(find.text('2026. július'), findsNothing);
  });

  testWidgets(
    'horizontal commit moves the full shell before staging text and query work',
    (tester) async {
      final motion = SummaryNavigationMotionController();
      final navigation = ValueNotifier(
        _navigation(subtitle: '2026', railOpen: false),
      );
      final queryScopeGeneration = ValueNotifier(0);
      addTearDown(motion.dispose);
      addTearDown(navigation.dispose);
      addTearDown(queryScopeGeneration.dispose);
      var parentCommits = 0;
      var haptics = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigationPresentation: navigation.value,
              navigationListenable: navigation,
              navigationPresentationBuilder: () => navigation.value,
              navigationMotionController: motion,
              horizontalCandidateBuilder: (_) =>
                  const SummaryTextContent(title: 'Éves', subtitle: '2027'),
              amountPresentation: _amount(text: '707 000 Ft'),
              onMoveNext: () {
                parentCommits += 1;
                navigation.value = _navigation(
                  subtitle: '2027',
                  railOpen: false,
                  reason: SummaryContentChangeReason.horizontalParentForward,
                );
                queryScopeGeneration.value += 1;
              },
              onSelectionHaptic: () => haptics += 1,
            ),
          ),
        ),
      );

      final amountElement = tester.element(find.text('707 000 Ft'));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DashboardSummaryPill)),
      );
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2027'), findsNothing);
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ).dx,
        lessThan(0),
      );
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ).dy,
        0,
      );
      expect(
        find.ancestor(
          of: find.text('707 000 Ft'),
          matching: find.byKey(
            const ValueKey('dashboard-summary-shell-transform'),
          ),
        ),
        findsOneWidget,
      );
      expect(tester.element(find.text('707 000 Ft')), same(amountElement));
      expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
      expect(parentCommits, 0);

      await gesture.up();
      expect(parentCommits, 1);
      expect(haptics, 1);
      expect(queryScopeGeneration.value, 1);

      await tester.pump();
      expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2027'), findsNothing);
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ).dx,
        lessThan(0),
      );
      expect(
        find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 101));
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ),
        Offset.zero,
      );
      expect(motion.stagedText.phase, SummaryStagedTextPhase.transitioning);
      expect(
        find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('summary-navigation-axis-incoming')),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('707 000 Ft'),
          matching: find.byKey(
            const ValueKey('summary-navigation-axis-outgoing'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('707 000 Ft'),
          matching: find.byKey(
            const ValueKey('summary-navigation-axis-incoming'),
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('a new gesture cancels a stale shell/text completion', (
    tester,
  ) async {
    final motion = SummaryNavigationMotionController();
    final navigation = ValueNotifier(
      _navigation(subtitle: '2026', railOpen: false),
    );
    addTearDown(motion.dispose);
    addTearDown(navigation.dispose);
    var committedParents = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: navigation.value,
            navigationListenable: navigation,
            navigationPresentationBuilder: () => navigation.value,
            navigationMotionController: motion,
            horizontalCandidateBuilder: (_) =>
                const SummaryTextContent(title: 'Éves', subtitle: 'következő'),
            amountPresentation: _amount(text: '707 000 Ft'),
            onMoveNext: () {
              committedParents += 1;
              navigation.value = _navigation(
                subtitle: '202${6 + committedParents}',
                railOpen: false,
                reason: SummaryContentChangeReason.horizontalParentForward,
              );
            },
          ),
        ),
      ),
    );

    final first = await tester.startGesture(
      tester.getCenter(find.byType(DashboardSummaryPill)),
    );
    await first.moveBy(const Offset(-30, 0));
    await first.up();
    await tester.pump();
    expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);

    final second = await tester.startGesture(
      tester.getCenter(find.byType(DashboardSummaryPill)),
    );
    await second.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsNothing,
    );

    await second.up();
    await tester.pump();
    expect(committedParents, 2);
    expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);
    await tester.pump(const Duration(milliseconds: 101));
    expect(motion.stagedText.phase, SummaryStagedTextPhase.transitioning);
    expect(find.text('2028'), findsOneWidget);

    final third = await tester.startGesture(
      tester.getCenter(find.byType(DashboardSummaryPill)),
    );
    await third.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsNothing,
    );
  });

  testWidgets('SUM horizontal drag only resists without committing or haptic', (
    tester,
  ) async {
    final motion = SummaryNavigationMotionController();
    addTearDown(motion.dispose);
    var parentCommits = 0;
    var haptics = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: SummaryNavigationPresentation(
              plane: TimePlane.sum,
              planeTitle: 'Összesen',
              subtitle: 'Minden időszak',
              isRailOpen: false,
              revision: 1,
              changeReason: SummaryContentChangeReason.initial,
              direction: SummaryTransitionDirection.forward,
            ),
            navigationMotionController: motion,
            horizontalCandidateBuilder: (_) => null,
            amountPresentation: _amount(text: '707 000 Ft'),
            onMoveNext: () => parentCommits += 1,
            onSelectionHaptic: () => haptics += 1,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DashboardSummaryPill)),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(find.text('Minden időszak'), findsOneWidget);
    expect(find.text('2027'), findsNothing);
    final resistance = _translation(
      tester,
      const ValueKey('dashboard-summary-shell-transform'),
    );
    expect(resistance.dx, inInclusiveRange(-5.0, 0));
    expect(resistance.dy, 0);

    await gesture.up();
    await tester.pump();
    expect(parentCommits, 0);
    expect(haptics, 0);
    expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
    expect(
      _translation(
        tester,
        const ValueKey('dashboard-summary-shell-transform'),
      ).dx,
      lessThan(0),
    );

    await tester.pump(const Duration(milliseconds: 101));
    expect(
      _translation(tester, const ValueKey('dashboard-summary-shell-transform')),
      Offset.zero,
    );
  });

  testWidgets(
    'vertical commit returns the shell before beginning Y-only text',
    (tester) async {
      final motion = SummaryNavigationMotionController();
      final queryScopeGeneration = ValueNotifier(0);
      final navigation = ValueNotifier(
        _navigation(subtitle: '2026', railOpen: false),
      );
      addTearDown(motion.dispose);
      addTearDown(queryScopeGeneration.dispose);
      addTearDown(navigation.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSummaryPill(
              bounds: _bounds,
              navigationPresentation: navigation.value,
              navigationListenable: navigation,
              navigationPresentationBuilder: () => navigation.value,
              navigationMotionController: motion,
              amountPresentation: _amount(text: '707 000 Ft'),
              onMoveFiner: () {
                navigation.value = SummaryNavigationPresentation(
                  plane: TimePlane.month,
                  planeTitle: 'Havi',
                  subtitle: '2026. július',
                  isRailOpen: false,
                  revision: 2,
                  changeReason: SummaryContentChangeReason.verticalPlaneForward,
                  direction: SummaryTransitionDirection.forward,
                );
                queryScopeGeneration.value += 1;
              },
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DashboardSummaryPill)),
      );
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ).dx,
        0,
      );
      expect(
        _translation(
          tester,
          const ValueKey('dashboard-summary-shell-transform'),
        ).dy,
        lessThan(0),
      );

      await gesture.up();
      expect(queryScopeGeneration.value, 1);
      await tester.pump();
      expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);
      expect(
        find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 101));
      final outgoing = _translation(
        tester,
        const ValueKey('summary-navigation-axis-outgoing'),
      );
      final incoming = _translation(
        tester,
        const ValueKey('summary-navigation-axis-incoming'),
      );
      expect(outgoing.dx, 0);
      expect(incoming.dx, 0);
      expect(incoming.dy, greaterThan(0));
    },
  );

  testWidgets('amount transition is latest-wins and completes within 120 ms', (
    tester,
  ) async {
    final amount = ValueNotifier(
      _amount(text: '100,00 Ft', scopeKey: 'month:2026-03'),
    );
    addTearDown(amount.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardSummaryPill(
          bounds: _bounds,
          navigationPresentation: _navigation(
            subtitle: '2026. március',
            railOpen: true,
          ),
          amountListenable: amount,
          amountPresentationBuilder: () => amount.value,
          onMoveNext: () {},
        ),
      ),
    );

    amount.value = _amount(text: '200,00 Ft', scopeKey: 'month:2026-03');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    amount.value = _amount(text: '300,00 Ft', scopeKey: 'month:2026-03');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 121));

    expect(find.text('300,00 Ft'), findsOneWidget);
    expect(find.text('100,00 Ft'), findsNothing);
    expect(find.text('200,00 Ft'), findsNothing);
    expect(amount.value.formattedAmount, '300,00 Ft');
  });

  testWidgets(
    'rail preview replaces the amount directly while fresh results crossfade',
    (tester) async {
      final amount = ValueNotifier(
        _amount(text: '100,00 Ft', scopeKey: 'month:2026-03'),
      );
      addTearDown(amount.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: _navigation(
              subtitle: '2026. március',
              railOpen: true,
            ),
            amountListenable: amount,
            amountPresentationBuilder: () => amount.value,
          ),
        ),
      );

      amount.value = _amount(
        text: '200,00 Ft',
        scopeKey: 'day:2026-03-14',
        preview: true,
      );
      await tester.pump();

      expect(find.text('200,00 Ft'), findsOneWidget);
      expect(find.text('100,00 Ft'), findsNothing);

      amount.value = _amount(text: '300,00 Ft', scopeKey: 'day:2026-03-14');
      await tester.pump();

      expect(find.text('200,00 Ft'), findsOneWidget);
      expect(find.text('300,00 Ft'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 121));
      expect(find.text('300,00 Ft'), findsOneWidget);
      expect(find.text('200,00 Ft'), findsNothing);
    },
  );

  testWidgets('scope change replaces the amount without a stale crossfade', (
    tester,
  ) async {
    final amount = ValueNotifier(
      _amount(text: '707 000 Ft', scopeKey: 'month:2026-07'),
    );
    addTearDown(amount.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: _navigation(
              subtitle: '2026. július',
              railOpen: false,
            ),
            amountPresentation: amount.value,
            amountListenable: amount,
            amountPresentationBuilder: () => amount.value,
          ),
        ),
      ),
    );

    amount.value = _amount(text: '721 000 Ft', scopeKey: 'month:2026-06');
    await tester.pump();

    expect(find.text('721 000 Ft'), findsOneWidget);
    expect(find.text('707 000 Ft'), findsNothing);
  });

  testWidgets(
    'settling the identical amount and count starts no presentation work',
    (tester) async {
      final amount = ValueNotifier(
        _amount(text: '333,80 Ft', scopeKey: 'day:2026-06-19', preview: true),
      );
      addTearDown(amount.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardSummaryPill(
            bounds: _bounds,
            navigationPresentation: _navigation(
              subtitle: '2026. június',
              railOpen: true,
            ),
            amountListenable: amount,
            amountPresentationBuilder: () => amount.value,
          ),
        ),
      );
      // Same query/revision/value after preview -> settled. The listenable
      // still emits, but the mounted amount must remain visually unchanged.
      amount.value = _amount(text: '333,80 Ft', scopeKey: 'day:2026-06-19');
      await tester.pump();

      expect(find.text('333,80 Ft'), findsOneWidget);
    },
  );
}

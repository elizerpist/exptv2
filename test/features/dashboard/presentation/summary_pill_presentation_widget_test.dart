import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_amount_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

SummaryNavigationPresentation _navigation({
  required String subtitle,
  required bool railOpen,
  SummaryContentChangeReason reason = SummaryContentChangeReason.initial,
}) {
  return SummaryNavigationPresentation(
    plane: TimePlane.year,
    planeTitle: 'Éves',
    subtitle: subtitle,
    isRailOpen: railOpen,
    revision: subtitle.contains('május') ? 2 : 1,
    changeReason: reason,
    direction: SummaryTransitionDirection.forward,
  );
}

SummaryAmountPresentation _amount({
  String text = '123,45 Ft',
  bool loading = false,
  bool stale = false,
}) {
  return SummaryAmountPresentation(
    formattedAmount: text,
    scopeKey: text,
    isLoading: loading,
    isStale: stale,
    hasError: false,
  );
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

  testWidgets('amount transition is latest-wins and completes within 120 ms', (
    tester,
  ) async {
    final amount = ValueNotifier(_amount(text: '100,00 Ft'));
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

    amount.value = _amount(text: '200,00 Ft');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    amount.value = _amount(text: '300,00 Ft');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 121));

    expect(find.text('300,00 Ft'), findsOneWidget);
    expect(find.text('100,00 Ft'), findsNothing);
    expect(find.text('200,00 Ft'), findsNothing);
    expect(amount.value.formattedAmount, '300,00 Ft');
  });
}

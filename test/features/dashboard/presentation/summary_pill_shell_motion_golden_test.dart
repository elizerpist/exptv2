import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/summary_text_content.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_amount_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 59);

SummaryNavigationPresentation _navigation(String subtitle) =>
    SummaryNavigationPresentation(
      plane: TimePlane.year,
      planeTitle: 'Éves',
      subtitle: subtitle,
      isRailOpen: false,
      revision: subtitle == '2026' ? 1 : 2,
      changeReason: SummaryContentChangeReason.initial,
      direction: SummaryTransitionDirection.forward,
    );

const _amount = SummaryAmountPresentation(
  formattedAmount: '707 000 Ft',
  scopeKey: 'year:2026',
  isLoading: false,
  isStale: false,
  hasError: false,
);

Widget _shellGoldenHost({
  required ValueNotifier<SummaryNavigationPresentation> navigation,
  required SummaryNavigationMotionController motion,
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xfffafafa),
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey('summary-pill-shell-motion-golden'),
          child: SizedBox(
            width: 402,
            height: 83,
            child: Center(
              child: DashboardSummaryPill(
                bounds: _bounds,
                navigationPresentation: navigation.value,
                navigationListenable: navigation,
                navigationPresentationBuilder: () => navigation.value,
                navigationMotionController: motion,
                horizontalCandidateBuilder: (direction) => SummaryTextContent(
                  title: 'Éves',
                  subtitle: direction == SummaryTransitionDirection.forward
                      ? '2027'
                      : '2025',
                ),
                amountPresentation: _amount,
                onMoveNext: () => navigation.value = _navigation('2027'),
                onMovePrevious: () => navigation.value = _navigation('2025'),
                onSelectionHaptic: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpGoldenSurface(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(430, 120));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(child);
}

Future<TestGesture> _startCommittedHorizontalDrag(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(DashboardSummaryPill)),
  );
  await gesture.moveBy(const Offset(-40, 0));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('golden: full summary pill follows horizontal drag', (
    tester,
  ) async {
    final motion = SummaryNavigationMotionController();
    final navigation = ValueNotifier(_navigation('2026'));
    addTearDown(motion.dispose);
    addTearDown(navigation.dispose);
    await _pumpGoldenSurface(
      tester,
      _shellGoldenHost(navigation: navigation, motion: motion),
    );

    await _startCommittedHorizontalDrag(tester);

    await expectLater(
      find.byKey(const ValueKey('summary-pill-shell-motion-golden')),
      matchesGoldenFile('../../../goldens/summary_pill_shell_drag.png'),
    );
  });

  testWidgets('golden: shell returns while outgoing text stays frozen', (
    tester,
  ) async {
    final motion = SummaryNavigationMotionController();
    final navigation = ValueNotifier(_navigation('2026'));
    addTearDown(motion.dispose);
    addTearDown(navigation.dispose);
    await _pumpGoldenSurface(
      tester,
      _shellGoldenHost(navigation: navigation, motion: motion),
    );

    final gesture = await _startCommittedHorizontalDrag(tester);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(motion.stagedText.phase, SummaryStagedTextPhase.holding);
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsNothing,
    );
    await expectLater(
      find.byKey(const ValueKey('summary-pill-shell-motion-golden')),
      matchesGoldenFile('../../../goldens/summary_pill_shell_return.png'),
    );
  });

  testWidgets('golden: post-return text crossfades while shell is settled', (
    tester,
  ) async {
    final motion = SummaryNavigationMotionController();
    final navigation = ValueNotifier(_navigation('2026'));
    addTearDown(motion.dispose);
    addTearDown(navigation.dispose);
    await _pumpGoldenSurface(
      tester,
      _shellGoldenHost(navigation: navigation, motion: motion),
    );

    final gesture = await _startCommittedHorizontalDrag(tester);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump(const Duration(milliseconds: 95));

    expect(motion.stagedText.phase, SummaryStagedTextPhase.transitioning);
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('summary-navigation-axis-incoming')),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey('summary-pill-shell-motion-golden')),
      matchesGoldenFile(
        '../../../goldens/summary_pill_shell_text_transition.png',
      ),
    );
  });
}

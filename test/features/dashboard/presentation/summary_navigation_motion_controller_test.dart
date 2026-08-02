import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

void main() {
  test('rail tick intent accepts only an actual logical-index change', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 8, newLogicalIndex: 8),
      isFalse,
    );
    expect(controller.railTick, isNull);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 8, newLogicalIndex: 9),
      isTrue,
    );
    expect(controller.railTick, const SummaryRailTick(8, 9));

    expect(
      controller.triggerRailTick(oldLogicalIndex: 9, newLogicalIndex: 9),
      isFalse,
    );
    expect(controller.railTick, const SummaryRailTick(8, 9));
  });

  test(
    'staged text holds outgoing content until its matching shell return completes',
    () {
      final controller = SummaryNavigationMotionController();
      addTearDown(controller.dispose);
      const outgoing = SummaryTextContent(
        title: 'Havi',
        subtitle: '2026. július',
      );
      const incoming = SummaryTextContent(
        title: 'Havi',
        subtitle: '2026. augusztus',
      );

      final generation = controller.holdTextForShellReturn(
        outgoing: outgoing,
        direction: SummaryTransitionDirection.forward,
        axis: SummaryTransitionAxis.horizontal,
      );
      controller.bindShellReturnIncoming(
        generation: generation,
        incoming: incoming,
      );

      expect(controller.stagedText.phase, SummaryStagedTextPhase.holding);
      expect(controller.stagedText.outgoing, outgoing);
      expect(controller.stagedText.incoming, incoming);

      controller.completeShellReturn(generation: generation);
      expect(controller.stagedText.phase, SummaryStagedTextPhase.transitioning);
    },
  );

  test('rapid rail ticks replace the last intent without a queue', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 11, newLogicalIndex: 12),
      isTrue,
    );
    expect(
      controller.triggerRailTick(oldLogicalIndex: 12, newLogicalIndex: 13),
      isTrue,
    );
    expect(controller.railTick, const SummaryRailTick(12, 13));
    expect(notifications, 2);

    controller.resetRailTickBaseline(13);
    expect(
      controller.triggerRailTick(oldLogicalIndex: 13, newLogicalIndex: 13),
      isFalse,
    );
    expect(notifications, 2);
  });

  test('stale shell completion cannot activate a newer staged request', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);

    final oldGeneration = controller.holdTextForShellReturn(
      outgoing: const SummaryTextContent(title: 'Éves', subtitle: '2026'),
      direction: SummaryTransitionDirection.forward,
      axis: SummaryTransitionAxis.horizontal,
    );
    final newGeneration = controller.holdTextForShellReturn(
      outgoing: const SummaryTextContent(
        title: 'Havi',
        subtitle: '2026. július',
      ),
      direction: SummaryTransitionDirection.backward,
      axis: SummaryTransitionAxis.vertical,
    );

    controller.completeShellReturn(generation: oldGeneration);
    controller.bindShellReturnIncoming(
      generation: oldGeneration,
      incoming: const SummaryTextContent(title: 'Éves', subtitle: '2027'),
    );

    expect(controller.stagedText.generation, newGeneration);
    expect(controller.stagedText.phase, SummaryStagedTextPhase.holding);
    expect(controller.stagedText.incoming, isNull);
  });

  test(
    'staged text returns to idle only after its matching transition completes',
    () {
      final controller = SummaryNavigationMotionController();
      addTearDown(controller.dispose);

      final generation = controller.holdTextForShellReturn(
        outgoing: const SummaryTextContent(title: 'Éves', subtitle: '2026'),
        direction: SummaryTransitionDirection.forward,
        axis: SummaryTransitionAxis.horizontal,
      );
      controller.bindShellReturnIncoming(
        generation: generation,
        incoming: const SummaryTextContent(title: 'Éves', subtitle: '2027'),
      );
      controller.completeShellReturn(generation: generation);
      controller.completeTextTransition(generation: generation);

      expect(controller.stagedText.phase, SummaryStagedTextPhase.idle);
    },
  );
}

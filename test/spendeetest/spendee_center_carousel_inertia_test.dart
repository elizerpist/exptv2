import 'package:exptv2/features/transactions/widgets/experimental/spendee_center_carousel_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spendee center carousel legacy belt inertia', () {
    test('a slow sub-threshold drag springs its residual back', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);
      controller.applyDragDelta(-20);

      final motion = controller.releaseMotion(velocityDx: 0, liveTicked: false);

      expect(motion.inertial, isFalse);
      expect(motion.initialTravel, 20);
      expect(motion.preferredDxDirection, -1);
      expect(motion.directionalSnapAllowed, isFalse);
      expect(motion.initialDuration, const Duration(milliseconds: 120));
    });

    test(
      'a fast flick uses the original velocity travel and residual snap',
      () {
        final controller = SpendeeCenterCarouselController(itemCount: 6);
        controller.applyDragDelta(-10);

        final motion = controller.releaseMotion(
          velocityDx: -2600,
          liveTicked: false,
        );

        expect(motion.inertial, isTrue);
        expect(motion.initialTravel, -143);
        expect(motion.preferredDxDirection, -1);
        expect(motion.directionalSnapAllowed, isTrue);
        expect(motion.initialDuration, const Duration(milliseconds: 297));

        final update = controller.applyDragDelta(motion.initialTravel);
        expect(update.index, 2);
        expect(update.residualDx, -25);

        final settleTravel = controller.settleTravel(
          preferredDxDirection: motion.preferredDxDirection,
          allowDirectionalSnap: motion.directionalSnapAllowed,
        );
        expect(settleTravel, -39);

        final settled = controller.applyDragDelta(settleTravel);
        expect(settled.index, 3);
        expect(settled.residualDx, 0);
      },
    );

    test('a live boundary tick is not counted twice on release', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);
      final live = controller.applyDragDelta(-70);
      expect(live.index, 1);
      expect(live.residualDx, -6);

      final motion = controller.releaseMotion(velocityDx: 0, liveTicked: true);

      expect(motion.directionalSnapAllowed, isTrue);
      expect(motion.initialTravel, 6);
      final settled = controller.applyDragDelta(motion.initialTravel);
      expect(settled.index, 1);
      expect(settled.residualDx, 0);
    });

    test('programmatic selection travels the shortest ticking wheel path', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);

      final travel = controller.travelToIndex(4);

      expect(travel, 128);
      final settled = controller.applyDragDelta(travel);
      expect(settled.tickedIndexes, [5, 4]);
      expect(settled.index, 4);
      expect(settled.residualDx, 0);
    });

    test('programmatic selection compensates any live residual offset', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);
      controller.applyDragDelta(-10);

      final travel = controller.travelToIndex(2);

      expect(travel, -118);
      final settled = controller.applyDragDelta(travel);
      expect(settled.tickedIndexes, [1, 2]);
      expect(settled.index, 2);
      expect(settled.residualDx, 0);
    });

    test('a cancelled gesture settles without adding a directional tick', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);
      final dragged = controller.applyDragDelta(-26);
      expect(dragged.index, 0);
      expect(dragged.residualDx, -26);

      final settled = controller.applyDragDelta(controller.cancelTravel());

      expect(settled.tickedIndexes, isEmpty);
      expect(settled.index, 0);
      expect(settled.residualDx, 0);
    });

    test('a resumed drag keeps live residual but resets gesture distance', () {
      final controller = SpendeeCenterCarouselController(itemCount: 6);
      controller.applyDragDelta(-30);
      controller.applyDragDelta(21);

      expect(controller.residualDx, -9);
      expect(controller.totalDx, -9);

      controller.beginDragFromCurrentMotion();

      expect(controller.residualDx, -9);
      expect(controller.totalDx, 0);
    });
  });
}

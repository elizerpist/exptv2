import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_prepared_revision_bundle.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rail-critical window covers every prepared query exactly once',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final window = core.railCriticalSceneWindowForIndex(index);

      expect(window.sceneCount, index.frames.length);
      expect(
        window.payloads.map((payload) => payload.queryKey.value).toSet(),
        hasLength(index.frames.length),
      );
    },
  );

  test(
    'query publication window contains the visible parent and its immediate rail domain only',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final publicationBundle = DashboardPreparedRevisionBundle.forIndex(
        core.preparedIndex!,
        publicationState: core.navigation.state,
      );

      expect(
        publicationBundle.railCriticalSceneWindow.sceneCount,
        lessThan(core.preparedIndex!.frames.length),
      );
      expect(
        publicationBundle.railCriticalSceneWindow.payloads.map(
          (payload) => payload.queryKey,
        ),
        contains(core.navigation.state.parentQueryKey),
      );
    },
  );

  test(
    'input cancels speculative preparation without rejecting navigation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final preparation = Completer<void>();
      var cancellations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => preparation.future,
        activate: (_) {},
        cancel: () {
          cancellations += 1;
          if (!preparation.isCompleted) preparation.complete();
        },
      );

      final parentMove = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      await pumpEventQueue();
      expect(core.sceneWindowPreparing.value, isTrue);

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.navigatePlane(finer: false);
      core.setRailOpen(true);

      await parentMove;
      expect(cancellations, 1);
      expect(core.navigation.state.plane, TimePlane.year);
      expect(core.navigation.state.isRailOpen, isTrue);
    },
  );

  test(
    'a revision publishes its index and complete rail bank together',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initialWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      final allowNextBank = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          await allowNextBank.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final publication = core.installPreparedIndex(
        buildRuntimeTestIndex(revision: 2, generation: 2),
      );
      await Future<void>.microtask(() {});
      expect(core.activePreparedRevisionBundle!.coreRevision, 1);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:1|'));

      allowNextBank.complete();
      await publication;
      expect(core.activePreparedRevisionBundle!.coreRevision, 2);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:2|'));
      expect(cache.activeWindowManifest!.isComplete, isTrue);
    },
  );

  test('a complete active rail bank eliminates sibling rebase work', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    addTearDown(core.dispose);
    addTearDown(cache.dispose);
    await core.bootstrap();
    final window = core.railCriticalSceneWindow();
    await cache.prepareWindow(window: window, surfaceWidth: 378);
    cache.activateWindow(window);
    core.recordInitialSceneWindowActivation(window);
    var prepares = 0;
    core.attachLogBoxSceneWindowCoordinator(
      prepare: (_, {required retainViewportId}) async => prepares += 1,
      activate: (_) {},
      report: cache.report,
    );

    core.setRailOpen(true);
    final sibling = core.motion.catalog.logicalIndexForValue(6);
    core.semanticCrossed(sibling);
    core.settleRail(sibling);
    await pumpEventQueue();

    expect(prepares, 0);
    expect(cache.railCriticalLookupMissCount, 0);
  });
}

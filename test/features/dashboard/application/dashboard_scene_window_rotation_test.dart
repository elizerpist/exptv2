import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'parent commit waits for the complete target scene window and gates input',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final events = <String>[];
      final prepared = Completer<void>();
      DashboardLogBoxSceneWindow? target;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          events.add('prepare:${window.identity}');
          target = window;
          expect(retainViewportId, core.visibleFrames.value!.logBox.viewportId);
          await prepared.future;
        },
        activate: (window) => events.add('activate:${window.identity}'),
      );

      final rotation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(core.sceneWindowPreparing.value, isTrue);
      expect(core.navigation.state.monthCursor.month, 7);
      core.setRailOpen(true);
      expect(core.navigation.state.isRailOpen, isFalse);

      prepared.complete();
      await rotation;

      expect(core.navigation.state.monthCursor.month, 6);
      expect(core.sceneWindowPreparing.value, isFalse);
      expect(target, isNotNull);
      expect(target!.payloads, isNotEmpty);
      expect(events, <String>[
        'prepare:${target!.identity}',
        'activate:${target!.identity}',
      ]);
    },
  );

  test('the active bank already covers plane and direction targets', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    addTearDown(core.dispose);
    addTearDown(cache.dispose);
    await core.bootstrap();
    final initial = core.renderCriticalLogBoxSceneWindow();
    await cache.prepareWindow(window: initial, surfaceWidth: 378);
    cache.activateWindow(initial);

    core.navigatePlane(finer: false);
    final yearWindow = core.renderCriticalLogBoxSceneWindow();
    expect(yearWindow.payloads, isNotEmpty);
    expect(
      yearWindow.payloads.every((payload) => cache.sceneFor(payload) != null),
      isTrue,
    );

    core.selectDirection(TransactionDirection.expense);
    final expenseWindow = core.renderCriticalLogBoxSceneWindow();
    expect(
      expenseWindow.payloads.every(
        (payload) => cache.sceneFor(payload) != null,
      ),
      isTrue,
    );
    expect(cache.textLayoutMissCount, 0);
  });

  test('an index publication queues behind a structural scene rotation', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    final firstPrepare = Completer<void>();
    final indexActivated = Completer<void>();
    var prepareCount = 0;
    core.attachLogBoxSceneWindowCoordinator(
      prepare: (window, {required retainViewportId}) async {
        prepareCount += 1;
        if (prepareCount == 1) await firstPrepare.future;
      },
      activate: (window) {
        if (window.identity.startsWith('rev:2|')) indexActivated.complete();
      },
    );

    final rotation = core.navigateParent(
      DashboardTimeNavigationChangeDirection.backward,
    );
    await Future<void>.microtask(() {});
    expect(core.sceneWindowPreparing.value, isTrue);

    await core.installPreparedIndex(buildRuntimeTestIndex(revision: 2));
    expect(core.preparedIndex!.coreRevision, 1);

    firstPrepare.complete();
    await rotation;
    await indexActivated.future;

    expect(core.presentation.index!.coreRevision, 2);
    expect(prepareCount, 2);
    expect(core.sceneWindowPreparing.value, isFalse);
  });
}

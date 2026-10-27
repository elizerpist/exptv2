import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a saved category patch installs renderer resources before a blocked full revision can publish',
    () async {
      final repository = _BlockedRevisionRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        yearWindowRadius: 1,
      );
      final scenes = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(scenes.dispose);
      addTearDown(() {
        if (!repository.releaseRevision.isCompleted) {
          repository.releaseRevision.complete();
        }
      });
      await core.bootstrap();
      final initialRailWindow = core.railCriticalSceneWindowForIndex(
        core.preparedIndex!,
      );
      final initialWindow = DashboardLogBoxSceneWindow(
        identity: initialRailWindow.identity,
        coverageIdentity: initialRailWindow.coverageIdentity,
        payloads: [core.visibleFrames.value!.logBox],
      );
      await scenes.prepareWindow(window: initialWindow, surfaceWidth: 378);
      scenes.activateWindow(initialWindow);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => scenes.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
          surfaceWidth: 378,
        ),
        activate: scenes.activateWindow,
      );
      core.recordInitialSceneWindowActivation(initialWindow);

      final before = core.visibleFrames.value!;
      final entry = before.logBox.semanticPreviewLedgerEntryAt(0)!;
      final outcome = await core.acceptKnownCoreRevision(
        2,
        visualPatch: DashboardLedgerVisualPatch(
          entryId: entry.id,
          partnerId: entry.partnerId,
          direction: entry.direction,
          amountMinor: entry.amountMinor,
          bookedLocalEpochDay: entry.bookedLocalEpochDay,
          bookedLocalTimeMinutes: entry.bookedLocalTimeMinutes,
          partnerDisplayName: entry.partnerDisplayName!,
          partnerAvatarCategoryId: entry.partnerAvatarCategoryId ?? 'fallback',
          partnerAvatarColorId: entry.partnerAvatarColorId ?? 'fallback',
          partnerAvatarIconId: entry.partnerAvatarIconId ?? 'fallback',
          categoryId: 'clothes',
          categoryDisplayName: 'Ruházat',
          categoryColorId: 'orange',
          categoryIconId: 'hanger',
          assignmentMode: 'entryOverride',
          entryRevision: entry.visualRevision + 1,
        ),
      );

      expect(outcome, DashboardSaveVisualPatchOutcome.installed);
      final visible = core.visibleFrames.value!;
      expect(
        visible.logBox.flatItems.single.row.categoryDisplayName,
        'Ruházat',
      );
      expect(visible.logBox.flatItems.single.row.hasCategoryOverride, isTrue);
      expect(
        scenes.sceneFor(visible.logBox),
        isNotNull,
        reason:
            'The same scene-cache path used by the renderer is ready before '
            'the save callback returns.',
      );

      // The normal Core refresh is deliberately not awaited by the editor
      // readiness path. Give its asynchronous request one event turn, then
      // prove it is still blocked while the patched renderer is already ready.
      await Future<void>.delayed(Duration.zero);
      expect(repository.rebuildStarted.isCompleted, isTrue);
      expect(repository.releaseRevision.isCompleted, isFalse);
      expect(
        core
            .visibleFrames
            .value!
            .logBox
            .flatItems
            .single
            .row
            .categoryDisplayName,
        'Ruházat',
        reason:
            'The editor-ready patch remains visible while the full revision '
            'is deliberately held in the repository.',
      );
    },
  );
}

final class _BlockedRevisionRepository
    implements DashboardDataRuntimeRepository {
  var _prepareCount = 0;
  final Completer<void> rebuildStarted = Completer<void>();
  final Completer<void> releaseRevision = Completer<void>();

  @override
  Stream<int> watchCoreRevision() => const Stream<int>.empty();

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    _prepareCount += 1;
    if (_prepareCount > 1) {
      if (!rebuildStarted.isCompleted) rebuildStarted.complete();
      await releaseRevision.future;
    }
    return buildRuntimeTestIndex(
      revision: request.key.coreRevision,
      generation: token.generation,
      directionalQueries: request.directionalQueries,
      initialYear: request.initialYear,
      yearWindowRadius:
          request.key.yearWindowEndInclusive - request.initialYear,
      entryCountForScope: (_) => 1,
      previewRowCountForScope: (scope) =>
          scope.direction == LedgerDirection.income &&
              scope.timeScope ==
                  const MonthScope(YearMonth(year: 2026, month: 7))
          ? 1
          : 0,
      deferredLogBoxes: true,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => Future<CommittedLogPage>.error(
    StateError('The visual-patch test never requests another page.'),
  );

  @override
  Map<String, Object?> performanceReport() => const <String, Object?>{};
}

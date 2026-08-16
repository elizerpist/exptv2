import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'direction selection reads the independent applied Query before opening a draft',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      core.selectDirection(TransactionDirection.expense);
      core.queryComposer.open(LedgerDirection.expense);

      expect(
        core.presentation.navigation.state.parentQueryScope.direction,
        LedgerDirection.expense,
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.income).direction,
        LedgerDirection.income,
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).direction,
        LedgerDirection.expense,
      );
      expect(core.queryComposer.draft.direction, LedgerDirection.expense);
    },
  );

  test('direction selection is ignored while a Query draft is open', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2025, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    core.queryComposer.open();
    final draft = core.queryComposer.draft.copyWith(
      categoryIds: const <String>{'food'},
    );
    core.queryComposer.updateDraft(scope: draft);

    core.selectDirection(TransactionDirection.income);

    expect(
      core.presentation.navigation.state.parentQueryScope.direction,
      LedgerDirection.expense,
    );
    expect(core.currentQuery.scope.direction, LedgerDirection.expense);
    expect(core.queryComposer.draft, draft);
  });

  test(
    'Apply publishes one prepared restricted query scope atomically',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2024, 2),
          QueryPeriodSelection.month(2026, 8),
        }),
        categoryIds: const <String>{'food'},
      );
      var appliedNotifications = 0;
      core.currentQuery.addListener(() => appliedNotifications += 1);

      final published = await core.applyQuery(draft);

      expect(published, isTrue);
      expect(appliedNotifications, 1);
      expect(core.currentQuery.scope, draft);
      expect(
        core.navigation.state.parentQueryScope.temporalFilter,
        draft.temporalFilter,
      );
      expect(core.navigation.temporalAvailability.allowedYears, <int>[
        2024,
        2026,
      ]);
      expect(
        core.preparedIndex?.key.expenseFilterKey,
        contains(draft.temporalFilter.canonicalKey),
      );
    },
  );

  test(
    'same applied composer draft closes without building another index',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.queryComposer.open();

      final published = await core.applyQuery(
        core.queryComposer.draft,
        composerApplyIdentity: core.queryComposer.applyIdentity,
      );

      expect(published, isTrue);
      expect(repository.queryPreparationCount, 0);
      expect(core.queryComposer.isOpen, isFalse);
    },
  );

  test(
    'closing and reopening the composer cancels an older Apply before it can publish',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 8, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldPreparation = Completer<void>();
      var cancellationCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => oldPreparation.future,
        activate: (_) {},
        cancel: () => cancellationCount += 1,
      );
      core.queryComposer.open();
      final oldDraft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2025),
        }),
      );
      core.queryComposer.updateDraft(scope: oldDraft);
      final originallyAppliedIndex = core.preparedIndex!;
      final oldApply = core.applyQuery(
        oldDraft,
        composerApplyIdentity: core.queryComposer.applyIdentity,
      );
      await pumpEventQueue();

      core.queryComposer.closeWithoutApply();
      core.queryComposer.open();
      final newerDraft = core.queryComposer.draft.copyWith(
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2026, 6),
          QueryPeriodSelection.month(2026, 7),
          QueryPeriodSelection.month(2026, 8),
        }),
      );
      core.queryComposer.updateDraft(scope: newerDraft);

      expect(cancellationCount, 1);
      oldPreparation.complete();

      expect(await oldApply, isFalse);
      expect(core.currentQuery.scope.temporalFilter.isRestrictive, isFalse);
      expect(
        identical(core.preparedIndex, originallyAppliedIndex),
        isTrue,
        reason:
            'A cancelled Apply must not rotate the prepared dashboard index.',
      );
      expect(core.queryComposer.isOpen, isTrue);
      expect(core.queryComposer.draft, newerDraft);
    },
  );

  test(
    'Query Apply publishes after its local critical window without waiting for full-bank warmup',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 8, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final fullBankWarmup = Completer<void>();
      var preparations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) {
          preparations += 1;
          return preparations == 1
              ? Future<void>.value()
              : fullBankWarmup.future;
        },
        activate: (_) {},
        cancel: () {
          if (!fullBankWarmup.isCompleted) fullBankWarmup.complete();
        },
      );
      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2025),
        }),
      );

      expect(await core.applyQuery(draft), isTrue);
      await pumpEventQueue();

      expect(core.currentQuery.scope, draft);
      expect(preparations, 2);
      expect(fullBankWarmup.isCompleted, isFalse);
    },
  );

  test(
    'Query Apply invalidates a blocked old-index structural scene transition',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final oldIndexGeneration = core.preparedIndex!.generation;
      final oldPreparationStarted = Completer<void>();
      final oldPreparation = Completer<void>();
      addTearDown(() {
        if (!oldPreparation.isCompleted) oldPreparation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (window.coverageIdentity?.indexGeneration == oldIndexGeneration) {
            if (!oldPreparationStarted.isCompleted) {
              oldPreparationStarted.complete();
            }
            await oldPreparation.future;
          }
        },
        activate: (_) {},
        cancel: () {
          if (!oldPreparation.isCompleted) {
            oldPreparation.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
      );

      core.navigatePlane(finer: true);
      await oldPreparationStarted.future.timeout(const Duration(seconds: 1));

      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2025),
        }),
      );

      expect(
        await core
            .applyQuery(draft)
            .timeout(const Duration(milliseconds: 250), onTimeout: () => false),
        isTrue,
      );
      expect(core.currentQuery.scope, draft);
      expect(core.preparedIndex!.generation, isNot(oldIndexGeneration));
    },
  );

  test(
    'a 2025 category Query publishes through the symmetric backing window',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.queryComposer.open();
      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2025),
        }),
        categoryIds: const <String>{'entertainment'},
      );
      core.queryComposer.updateDraft(scope: draft);

      expect(await core.applyQuery(draft), isTrue);
      expect(core.currentQuery.scope, draft);
      expect(core.queryComposer.isOpen, isFalse);
      expect(core.preparedIndex?.key.yearWindowStart, 2013);
      expect(core.preparedIndex?.key.yearWindowEndInclusive, 2037);
      expect(core.navigation.temporalAvailability.allowedYears, <int>[2025]);
      expect(
        core.preparedIndex!
            .catalogFor(draft.copyWith(timeScope: const AllTimeScope()))
            .values,
        <int>[2025],
      );
    },
  );

  test('a zero-result restrictive Query is a valid publication', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 8, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    core.queryComposer.open();
    final draft = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 8),
      }),
      categoryIds: const <String>{'no-matching-category'},
    );
    core.queryComposer.updateDraft(scope: draft);

    expect(await core.applyQuery(draft), isTrue);
    expect(core.currentQuery.scope, draft);
    expect(core.queryComposer.isOpen, isFalse);
  });

  test(
    'a failed Query index preparation returns false and can be retried',
    () async {
      final repository = _FailOnceQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2024),
          QueryPeriodSelection.year(2026),
        }),
      );

      expect(await core.applyQuery(draft), isFalse);
      expect(core.currentQuery.scope.temporalFilter.isRestrictive, isFalse);

      expect(await core.applyQuery(draft), isTrue);
      expect(repository.queryPreparationCount, 2);
      expect(core.currentQuery.scope, draft);
    },
  );

  test('concurrent Apply intents share one Query index preparation', () async {
    final repository = _BlockingQueryIndexRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
      initialDate: DateTime(2025, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    final draft = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.year(2024),
        QueryPeriodSelection.year(2026),
      }),
    );

    final first = core.applyQuery(draft);
    final second = core.applyQuery(draft);

    expect(identical(first, second), isTrue);
    expect(repository.queryPreparationCount, 1);

    await repository.completeQueryPreparation();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(repository.queryPreparationCount, 1);
  });

  test(
    'draft preparation stays invisible and Apply consumes that exact index',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldIndex = core.preparedIndex;
      var candidateScenePreparations = 0;
      var candidateSceneActivations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {},
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) async {
              candidateScenePreparations += 1;
            },
        discardCandidate: (_) {},
        activate: (_) => candidateSceneActivations += 1,
      );
      core.queryComposer.open(LedgerDirection.expense);
      final draft = core.queryComposer.draft.copyWith(
        categoryIds: const <String>{'food'},
      );
      core.queryComposer.updateDraft(scope: draft);

      final candidate = await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      expect(candidate, isNotNull);
      expect(candidate!.sceneStaged, isTrue);
      expect(repository.queryPreparationCount, 1);
      expect(candidateScenePreparations, 1);
      expect(candidateSceneActivations, 0);
      expect(identical(core.preparedIndex, oldIndex), isTrue);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        isEmpty,
      );

      expect(
        await core.applyQuery(
          draft,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      expect(repository.queryPreparationCount, 1);
      expect(candidateScenePreparations, 1);
      expect(candidateSceneActivations, 1);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'food'},
      );
    },
  );

  test(
    'a staged Query candidate includes the current parent interaction domain before Apply',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
          surfaceWidth: 378,
        ),
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) =>
                cache.prepareCandidateWindow(
                  candidateKey: candidateKey,
                  window: window,
                  retainViewportId: retainViewportId,
                  surfaceWidth: 378,
                ),
        discardCandidate: cache.discardCandidateWindow,
        hasCandidate: cache.hasCandidateWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      core.queryComposer.open(LedgerDirection.expense);
      final draft = core.queryComposer.draft.copyWith(
        categoryIds: const <String>{'food'},
      );
      core.queryComposer.updateDraft(scope: draft);
      final candidate = await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      expect(candidate, isNotNull);
      expect(
        candidate!.currentParentInteractionWindow.sceneCount,
        greaterThan(candidate.structuralWindow.sceneCount),
        reason:
            'The Query sheet hides preparation long enough to stage the '
            'reachable sibling domain, not only the first parent frame.',
      );
      expect(
        candidate.currentParentInteractionWindow.payloads.every(
          (payload) => cache.railCriticalSceneFor(payload) == null,
        ),
        isTrue,
        reason: 'A draft bank remains invisible until the accepted Apply.',
      );

      expect(
        await core.applyQuery(
          draft,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      expect(
        candidate.currentParentInteractionWindow.payloads.every(
          (payload) => cache.railCriticalSceneFor(payload) != null,
        ),
        isTrue,
        reason:
            'The first rail sibling fling after Apply must not depend on a '
            'cancellable background warmup.',
      );
    },
  );

  test(
    'Apply re-stages a ready candidate whose bounded retained bank was evicted',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      var candidatePreparations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
          surfaceWidth: 378,
        ),
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) {
              candidatePreparations += 1;
              return cache.prepareCandidateWindow(
                candidateKey: candidateKey,
                window: window,
                retainViewportId: retainViewportId,
                surfaceWidth: 378,
              );
            },
        discardCandidate: cache.discardCandidateWindow,
        hasCandidate: cache.hasCandidateWindow,
        activate: cache.activateWindow,
      );

      core.queryComposer.open(LedgerDirection.expense);
      final draft = core.queryComposer.draft.copyWith(
        categoryIds: const <String>{'food'},
      );
      core.queryComposer.updateDraft(scope: draft);
      final candidate = await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      expect(candidate, isNotNull);
      expect(candidatePreparations, 1);
      cache.discardCandidateWindow(candidate!.cacheKey);
      expect(
        cache.hasCandidateWindow(
          candidate.currentParentInteractionWindow,
          candidateKey: candidate.cacheKey,
        ),
        isFalse,
      );

      expect(
        await core.applyQuery(
          draft,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      expect(candidatePreparations, 2);
      expect(
        candidate.currentParentInteractionWindow.payloads.every(
          (payload) => cache.railCriticalSceneFor(payload) != null,
        ),
        isTrue,
      );
    },
  );

  test(
    'discarding a ready draft candidate has no rollback publication',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldIndex = core.preparedIndex;
      core.queryComposer.open(LedgerDirection.expense);
      final draft = core.queryComposer.draft.copyWith(
        categoryIds: const <String>{'food'},
      );
      core.queryComposer.updateDraft(scope: draft);
      await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      core.discardQueryDraftCandidate(reason: 'testCancel');
      core.queryComposer.closeWithoutApply();

      expect(repository.queryPreparationCount, 1);
      expect(identical(core.preparedIndex, oldIndex), isTrue);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        isEmpty,
      );
    },
  );

  test(
    'closing and reopening an exact ready draft reuses its immutable index',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      core.queryComposer.open(LedgerDirection.expense);
      final draft = core.queryComposer.draft.copyWith(
        categoryIds: const <String>{'food'},
      );
      core.queryComposer.updateDraft(scope: draft);
      await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );
      expect(repository.queryPreparationCount, 1);

      core.discardQueryDraftCandidate(reason: 'sheetClosed');
      core.queryComposer.closeWithoutApply();
      core.queryComposer.open(LedgerDirection.expense);
      core.queryComposer.updateDraft(scope: draft);
      await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      expect(
        repository.queryPreparationCount,
        1,
        reason:
            'A closed editor may discard its invisible scene bank, but an '
            'exact complete immutable index remains reusable across sessions.',
      );
    },
  );

  test(
    'an Expense draft keeps the active prepared year window after parent navigation',
    () async {
      final repository = _DirectionalWindowReuseRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      expect(core.preparedIndex!.key.yearWindowStart, 2014);
      expect(core.preparedIndex!.key.yearWindowEndInclusive, 2038);

      final draft = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      final initialCandidate = await core.prepareQueryDraft(draft);
      expect(initialCandidate, isNotNull);
      expect(repository.partitionRequests, hasLength(1));
      expect(repository.queryWholeIndexRequests, isEmpty);

      await core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(core.navigation.temporalAnchor.visibleYear, 2025);

      final afterNavigation = await core.prepareQueryDraft(draft);

      expect(afterNavigation, isNotNull);
      expect(
        afterNavigation!.requestTemplate
            .requestFor(
              coreRevision: core.preparedIndex!.coreRevision,
              reason: DataAcquisitionReason.query,
            )
            .key
            .yearWindowStart,
        2014,
        reason:
            'Visible temporal movement within an active immutable index must '
            'not physically shift Query candidate backing coverage.',
      );
      expect(
        afterNavigation.requestTemplate
            .requestFor(
              coreRevision: core.preparedIndex!.coreRevision,
              reason: DataAcquisitionReason.query,
            )
            .key
            .yearWindowEndInclusive,
        2038,
      );
      expect(repository.partitionRequests, hasLength(1));
      expect(repository.queryWholeIndexRequests, isEmpty);
      expect(afterNavigation.index.builtDirection, LedgerDirection.expense);
      expect(afterNavigation.index.reusedDirection, LedgerDirection.income);
    },
  );

  test(
    'a prewarmed category chip removes its Query without a tap-time build',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var candidateScenePreparations = 0;
      final stagedCandidateKeys = <String>{};
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {},
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) async {
              candidateScenePreparations += 1;
              stagedCandidateKeys.add(candidateKey);
            },
        discardCandidate: stagedCandidateKeys.remove,
        hasCandidate: (window, {required candidateKey}) =>
            stagedCandidateKeys.contains(candidateKey),
        activate: (_) {},
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
        partnerIds: const <String>{'merchant-a', 'merchant-b'},
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);

      // Complete the two exact one-chip neighbours deterministically. This
      // mirrors the bounded background hotset without making this cache-hit
      // assertion wait for every unrelated speculative neighbour.
      final categoryTarget = applied.copyWith(
        categoryIds: const <String>{'travel'},
      );
      await core.prepareQueryDraft(categoryTarget);
      final preparedBeforeTap = repository.queryPreparationCount;
      final scenesBeforeTap = candidateScenePreparations;
      expect(preparedBeforeTap, greaterThanOrEqualTo(2));

      core.removeAppliedQueryCategory('food');

      // The neighbour was staged while the chip was stable, so the query
      // mutation publishes in the same interaction turn, without a cold
      // index or scene build caused by the tap.
      expect(repository.queryPreparationCount, preparedBeforeTap);
      expect(candidateScenePreparations, scenesBeforeTap);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'travel'},
      );
    },
  );

  test(
    'RED: a seven-target chip hotset defers clear-all before its Query index build',
    () async {
      final repository = _RecordingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 2048,
      );
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      _attachRealCandidateSceneCache(core, cache);
      FluviDiagnosticLogger.clear();

      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 6, amountScaled100: 600),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 600,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e', 'f'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);

      await pumpEventQueue(times: 160);

      expect(cache.retainedCandidateBankCount, 6);
      expect(
        core.appliedQueryChipHotsetCount,
        6,
        reason:
            'The six one-chip removals fit the bounded scene-bank policy; '
            'clear-all is the lower-priority seventh logical neighbour.',
      );
      expect(cache.protectedCandidateBankCount, 6);

      expect(repository.unfilteredExpenseQueryBuildCount, 0);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) => event.stage == 'QUERY_CHIP_HOTSET_DEFERRED',
        ),
        isTrue,
      );
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) => event.stage == 'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED',
        ),
        isFalse,
      );
    },
  );

  test(
    'a deferred clear-all candidate is foreground-admitted once and then reused',
    () async {
      final repository = _RecordingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 2048,
      );
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      _attachRealCandidateSceneCache(core, cache);
      FluviDiagnosticLogger.clear();
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 6, amountScaled100: 600),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 600,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e', 'f'},
      );
      final clearAll = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      expect(core.appliedQueryChipHotsetCount, 6);
      expect(core.deferredQueryChipHotsetCount, 1);
      expect(repository.unfilteredExpenseQueryBuildCount, 0);

      final first = await core.prepareQueryDraft(clearAll);

      expect(first, isNotNull);
      expect(repository.unfilteredExpenseQueryBuildCount, 1);
      expect(core.appliedQueryChipHotsetCount, 6);
      expect(core.deferredQueryChipHotsetCount, 1);
      expect(
        FluviDiagnosticLogger.entries
            .where(
              (event) => event.stage == 'QUERY_CHIP_HOTSET_FOREGROUND_ADMITTED',
            )
            .length,
        1,
      );

      final second = await core.prepareQueryDraft(clearAll);

      expect(second, isNotNull);
      expect(repository.unfilteredExpenseQueryBuildCount, 1);
    },
  );

  test(
    'five applied category chips retain every removal target plus clear-all',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      // Keep speculative scheduler work outside this cache-capacity test. The
      // six candidates below are staged explicitly so their identity and LRU
      // ownership can be asserted without a concurrent microtask racing the
      // count.
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      final candidateKeys = <String>{};
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {},
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) async {
              candidateKeys.add(candidateKey);
            },
        discardCandidate: candidateKeys.remove,
        hasCandidate: (window, {required candidateKey}) =>
            candidateKeys.contains(candidateKey),
        activate: (_) {},
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 5, amountScaled100: 500),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 500,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      expect(core.retainedPreparedQueryCandidateCount, 0);
      expect(core.appliedQueryChipHotsetCount, 6);

      // Prepare the complete current-X hotset directly. The controller's
      // production scheduler performs the same work incrementally after the
      // explicit sheet-removal boundary; this keeps the cache invariant test
      // deterministic and independent of idle/motion timing.
      for (final category in applied.categoryIds) {
        await core.prepareQueryDraft(
          applied.copyWith(
            categoryIds: <String>{...applied.categoryIds}..remove(category),
          ),
        );
      }
      await core.prepareQueryDraft(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
      );

      expect(repository.queryPreparationCount, 7);
      expect(core.retainedPreparedQueryCandidateCount, 6);
      final preparedBeforeTap = repository.queryPreparationCount;
      core.removeAppliedQueryCategory('a');
      expect(
        repository.queryPreparationCount,
        preparedBeforeTap,
        reason:
            'Every currently rendered chip X has a protected exact neighbour '
            'rather than losing one slot to the active query.',
      );
      expect(candidateKeys.length, greaterThanOrEqualTo(6));
    },
  );

  test(
    'an editor foreground candidate displaces a full applied chip hotset and activates',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      _attachRealCandidateSceneCache(core, cache);
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 5, amountScaled100: 500),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 500,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e'},
      );
      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      for (final category in applied.categoryIds) {
        await core.prepareQueryDraft(
          applied.copyWith(
            categoryIds: <String>{...applied.categoryIds}..remove(category),
          ),
        );
      }
      await core.prepareQueryDraft(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
      );
      expect(core.appliedQueryChipHotsetCount, 6);
      expect(cache.protectedCandidateBankCount, 6);
      expect(cache.retainedCandidateBankCount, 6);

      core.queryComposer.open(LedgerDirection.expense);

      expect(core.appliedQueryChipHotsetCount, 0);
      expect(cache.protectedCandidateBankCount, 0);
      final draft = applied.copyWith(
        categoryIds: const <String>{'a', 'b', 'c', 'd'},
      );
      core.queryComposer.updateDraft(scope: draft);
      final candidate = await core.prepareQueryDraft(
        draft,
        composerIdentity: core.queryComposer.applyIdentity,
      );

      expect(candidate, isNotNull);
      expect(
        cache.hasCandidateWindow(
          candidate!.currentParentInteractionWindow,
          candidateKey: candidate.cacheKey,
        ),
        isTrue,
      );
      expect(
        await core.applyQuery(
          draft,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      expect(
        cache.activeWindowIdentity,
        candidate.currentParentInteractionWindow.identity,
        reason:
            'A prepared-hit foreground candidate must activate its exact '
            'complete retained bank without another scene preparation.',
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'a', 'b', 'c', 'd'},
      );
    },
  );

  test(
    'direction commit replaces the protected chip hotset before an Income editor stages',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      _attachRealCandidateSceneCache(core, cache);
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 5, amountScaled100: 500),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 500,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final expense = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e'},
      );
      expect(await core.applyQuery(expense, facetPresentation: facets), isTrue);
      for (final category in expense.categoryIds) {
        await core.prepareQueryDraft(
          expense.copyWith(
            categoryIds: <String>{...expense.categoryIds}..remove(category),
          ),
        );
      }
      await core.prepareQueryDraft(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
      );
      expect(cache.protectedCandidateBankCount, 6);
      expect(repository.queryPreparationCount, 7);

      core.selectDirection(TransactionDirection.income);
      await pumpEventQueue(times: 20);

      expect(
        core.presentation.navigation.state.parentQueryScope.direction,
        LedgerDirection.income,
      );
      expect(core.appliedQueryChipHotsetCount, 0);
      expect(cache.protectedCandidateBankCount, 0);
      core.queryComposer.open(LedgerDirection.income);
      final incomeDraft = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'salary'},
      );
      core.queryComposer.updateDraft(scope: incomeDraft);
      final candidate = await core.prepareQueryDraft(
        incomeDraft,
        composerIdentity: core.queryComposer.applyIdentity,
      );
      expect(candidate, isNotNull);
      final preparedBeforeApply = repository.queryPreparationCount;
      expect(
        cache.hasCandidateWindow(
          candidate!.currentParentInteractionWindow,
          candidateKey: candidate.cacheKey,
        ),
        isTrue,
      );

      expect(
        await core.applyQuery(
          incomeDraft,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      expect(
        cache.activeWindowIdentity,
        candidate.currentParentInteractionWindow.identity,
        reason:
            'QUERY_APPLY_PREPARED_HIT must mean the exact Income candidate '
            'bank is already activation-ready.',
      );
      expect(
        repository.queryPreparationCount,
        preparedBeforeApply,
        reason:
            'Apply must activate the exact foreground candidate rather than '
            'dispatching a duplicate native index build.',
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.income).categoryIds,
        <String>{'salary'},
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        expense.categoryIds,
      );
    },
  );

  test(
    'Cancel restores the active direction chip-hotset protection without publication',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      _attachRealCandidateSceneCache(core, cache);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 5, amountScaled100: 500),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 500,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final expense = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'a', 'b', 'c', 'd', 'e'},
      );
      expect(await core.applyQuery(expense, facetPresentation: facets), isTrue);
      expect(cache.protectedCandidateBankCount, 6);
      final activeIndex = core.preparedIndex;

      // Keep the speculative post-publication scheduler out of this lifecycle
      // test; only editor suspension and restoration are under test here.
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);

      core.queryComposer.open(LedgerDirection.expense);
      expect(cache.protectedCandidateBankCount, 0);
      core.queryComposer.closeWithoutApply();

      expect(cache.protectedCandidateBankCount, 6);
      expect(core.appliedQueryChipHotsetCount, 6);
      expect(identical(core.preparedIndex, activeIndex), isTrue);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        expense.categoryIds,
      );
    },
  );

  test(
    'a prewarmed partner chip removes its Query without a tap-time build',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final stagedCandidateKeys = <String>{};
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {},
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) async {
              stagedCandidateKeys.add(candidateKey);
            },
        discardCandidate: stagedCandidateKeys.remove,
        hasCandidate: (window, {required candidateKey}) =>
            stagedCandidateKeys.contains(candidateKey),
        activate: (_) {},
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        partnerIds: const <String>{'merchant-a', 'merchant-b'},
      );
      core.queryComposer.open(LedgerDirection.expense);
      core.queryComposer.updateDraft(scope: applied);
      expect(
        await core.applyQuery(
          applied,
          facetPresentation: facets,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      final target = applied.copyWith(partnerIds: const <String>{'merchant-b'});
      await core.prepareQueryDraft(target);
      final preparedBeforeTap = repository.queryPreparationCount;

      core.removeAppliedQueryPartner('merchant-a');
      await pumpEventQueue(times: 1);

      expect(repository.queryPreparationCount, preparedBeforeTap);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).partnerIds,
        <String>{'merchant-b'},
      );
    },
  );

  test(
    'Query chip speculation waits for the explicit sheet-removal boundary',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );

      core.queryComposer.open(LedgerDirection.expense);
      core.queryComposer.updateDraft(scope: applied);
      expect(
        await core.applyQuery(
          applied,
          facetPresentation: facets,
          composerApplyIdentity: core.queryComposer.applyIdentity,
        ),
        isTrue,
      );
      await pumpEventQueue(times: 80);
      expect(
        repository.queryPreparationCount,
        1,
        reason:
            'A successful publication must not dispatch speculative chip work '
            'until the shell has removed the foreground Query sheet.',
      );
      expect(core.querySheetDismissalTransitionActive, isTrue);

      FluviDiagnosticLogger.clear();
      core.notifyQuerySheetDismissed();
      await pumpEventQueue(times: 80);
      expect(core.querySheetDismissalTransitionActive, isFalse);
      expect(repository.queryPreparationCount, greaterThan(1));
      final stages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      final readyAheadResumed = stages.indexOf(
        'COMMITTED_READY_AHEAD_RESUMED_AFTER_ROUTE',
      );
      final readyAheadSatisfied = stages.indexOf(
        'COMMITTED_READY_AHEAD_SATISFIED_AFTER_ROUTE',
      );
      final speculationResumed = stages.indexOf(
        'SPECULATIVE_WORK_RESUMED_AFTER_ROUTE',
      );
      final chipPrewarmStarted = stages.indexOf(
        'QUERY_CHIP_HOTSET_PREPARE_STARTED',
      );
      expect(readyAheadResumed, greaterThanOrEqualTo(0));
      expect(readyAheadSatisfied, greaterThan(readyAheadResumed));
      expect(speculationResumed, greaterThan(readyAheadSatisfied));
      expect(
        chipPrewarmStarted,
        greaterThan(speculationResumed),
        reason:
            'The route-completion readiness pass must settle before chip '
            'speculation gets its first preparation opportunity.',
      );
    },
  );
  test(
    'direct prepared chip publication settles committed ready-ahead before speculation',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final target = applied.copyWith(categoryIds: const <String>{'travel'});
      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await core.prepareQueryDraft(target);
      FluviDiagnosticLogger.clear();

      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 80);

      final stages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      final publication = stages.indexOf('QUERY_APPLY_PUBLICATION_COMPLETED');
      final readyAheadResumed = stages.indexOf(
        'COMMITTED_READY_AHEAD_RESUMED_AFTER_DIRECT_QUERY_PUBLICATION',
      );
      final readyAheadSatisfied = stages.indexOf(
        'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION',
      );
      final speculationResumed = stages.indexOf(
        'SPECULATIVE_WORK_RESUMED_AFTER_DIRECT_QUERY_PUBLICATION',
      );
      final chipPrewarmStarted = stages.indexOf(
        'QUERY_CHIP_HOTSET_PREPARE_STARTED',
      );
      expect(publication, greaterThanOrEqualTo(0));
      expect(readyAheadResumed, greaterThan(publication));
      expect(readyAheadSatisfied, greaterThan(readyAheadResumed));
      expect(speculationResumed, greaterThan(readyAheadSatisfied));
      expect(chipPrewarmStarted, greaterThan(speculationResumed));
    },
  );

  test(
    'direct prepared chip publication rejects a scene-owner warmup callback before ready-ahead settles',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final stagedCandidateKeys = <String>{};
      var invokeWarmupCallbackDuringActivation = false;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) async {
              stagedCandidateKeys.add(candidateKey);
            },
        discardCandidate: stagedCandidateKeys.remove,
        hasCandidate: (_, {required candidateKey}) =>
            stagedCandidateKeys.contains(candidateKey),
        prepareRetained:
            (_, {required retainedKey, required retainViewportId}) async {},
        hasRetained: (_) => false,
        activate: (_) {
          if (!invokeWarmupCallbackDuringActivation) return;
          core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
          core.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
        },
        scheduleRebase: (callback) => callback(),
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final target = applied.copyWith(categoryIds: const <String>{'travel'});

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);
      await core.prepareQueryDraft(target);
      FluviDiagnosticLogger.clear();
      invokeWarmupCallbackDuringActivation = true;

      expect(await core.applyQuery(target, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);

      _expectNoDirectPublicationSpeculationBeforeReadyAhead(
        FluviDiagnosticLogger.entries,
      );
    },
  );

  test(
    'a queued rail warmup callback fails closed after direct publication reservation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      core.recordInitialSceneWindowActivation(initial);
      final queuedRailCallbacks = <void Function()>[];
      var executeQueuedCallbackDuringActivation = false;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {
          if (!executeQueuedCallbackDuringActivation) return;
          for (final callback in List<void Function()>.of(
            queuedRailCallbacks,
          )) {
            callback();
          }
          queuedRailCallbacks.clear();
        },
        scheduleRebase: queuedRailCallbacks.add,
      );
      // This is an actual render-scheduled rail-maintenance callback from the
      // old visible index. It is intentionally held until the target Query
      // publication has installed its reservation.
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
      expect(queuedRailCallbacks, isNotEmpty);

      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      await core.prepareQueryDraft(target);
      FluviDiagnosticLogger.clear();
      executeQueuedCallbackDuringActivation = true;

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 80);

      _expectNoDirectPublicationSpeculationBeforeReadyAhead(
        FluviDiagnosticLogger.entries,
      );
    },
  );

  test(
    'a direct prepared miss holds scene-owner speculation behind exact ready-ahead',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var invokeWarmupCallbackDuringActivation = false;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {
          if (!invokeWarmupCallbackDuringActivation) return;
          core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
          core.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
        },
        scheduleRebase: (callback) => callback(),
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      FluviDiagnosticLogger.clear();
      invokeWarmupCallbackDuringActivation = true;
      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 120);

      expect(repository.queryPreparationCount, greaterThanOrEqualTo(2));
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('QUERY_CHIP_PREPARED_MISS'),
      );
      _expectNoDirectPublicationSpeculationBeforeReadyAhead(
        FluviDiagnosticLogger.entries,
      );
    },
  );

  test(
    'a zero-page direct publication binds and releases readiness without a page read',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'no-matching-category'},
      );
      FluviDiagnosticLogger.clear();

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 80);

      final stages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      expect(
        stages,
        contains('COMMITTED_READY_AHEAD_BOUND_TO_QUERY_PUBLICATION'),
      );
      expect(
        stages,
        contains(
          'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION',
        ),
      );
      expect(core.paging.pageReadCount, 0);
      expect(core.paging.hasOutstandingReadyWork, isFalse);
    },
  );

  test(
    'a multi-page direct publication settles exact ready-ahead before speculation',
    () async {
      final repository = _ReadyAheadQueryRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.committedLogViewport.configureSurfaceWidth(378);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'multi-page'},
      );
      FluviDiagnosticLogger.clear();

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 220);

      expect(repository.pageRequests, hasLength(5));
      expect(
        repository.pageRequests.map((request) => request.pageOrdinal),
        <int>[1, 2, 3, 4, 5],
      );
      expect(core.paging.pageReadCount, 5);
      expect(core.paging.hasOutstandingReadyWork, isFalse);
      _expectNoDirectPublicationSpeculationBeforeReadyAhead(
        FluviDiagnosticLogger.entries,
      );
    },
  );

  test(
    'a one-page direct publication settles its reservation without a repository read',
    () async {
      final repository = _ReadyAheadQueryRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.committedLogViewport.configureSurfaceWidth(378);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'one-page'},
      );
      FluviDiagnosticLogger.clear();

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 120);

      expect(repository.pageRequests, isEmpty);
      expect(core.paging.pageReadCount, 0);
      expect(core.paging.hasOutstandingReadyWork, isFalse);
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains(
          'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION',
        ),
      );
    },
  );

  test(
    'a structurally superseded publication cannot release newer readiness reservation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final olderTarget = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      final newerTarget = olderTarget.copyWith(
        categoryIds: const <String>{'travel'},
      );
      await core.prepareQueryDraft(olderTarget);
      await core.prepareQueryDraft(newerTarget);
      Future<bool>? newerApply;
      var triggerStructuralSupersede = false;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {
          if (!triggerStructuralSupersede || newerApply != null) return;
          core.queryComposer.open(LedgerDirection.expense);
          core.queryComposer.updateDraft(scope: newerTarget);
          newerApply = core.applyQuery(
            newerTarget,
            composerApplyIdentity: core.queryComposer.applyIdentity,
          );
        },
      );
      FluviDiagnosticLogger.clear();
      triggerStructuralSupersede = true;

      expect(await core.applyQuery(olderTarget), isFalse);
      expect(await newerApply, isTrue);
      core.notifyQuerySheetDismissed();
      await pumpEventQueue(times: 80);

      final publicationStarts = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'QUERY_APPLY_PUBLICATION_STARTED')
          .toList(growable: false);
      expect(publicationStarts, hasLength(2));
      final supersededFlow = publicationStarts.first.flowId;
      final currentFlow = publicationStarts.last.flowId;
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage ==
                  'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION' &&
              event.flowId == supersededFlow,
        ),
        isEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'COMMITTED_READY_AHEAD_SATISFIED_AFTER_ROUTE' &&
              event.flowId == currentFlow,
        ),
        isNotEmpty,
      );
      expect(core.currentQuery.scopeFor(LedgerDirection.expense), newerTarget);
    },
  );

  test(
    'a publication activation failure releases only its own reservation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldVisibleQueryKey = core.visibleFrames.value!.queryKey;
      final oldScope = core.currentQuery.scopeFor(LedgerDirection.expense);
      final target = oldScope.copyWith(categoryIds: const <String>{'food'});
      var failActivation = true;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {
          if (failActivation) throw StateError('synthetic scene activation');
        },
      );
      await core.prepareQueryDraft(target);
      FluviDiagnosticLogger.clear();

      expect(await core.applyQuery(target), isFalse);
      expect(core.currentQuery.scopeFor(LedgerDirection.expense), oldScope);
      expect(core.visibleFrames.value!.queryKey, oldVisibleQueryKey);
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('QUERY_APPLY_PUBLICATION_FAILED'),
      );

      failActivation = false;
      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 80);
      expect(core.currentQuery.scopeFor(LedgerDirection.expense), target);
    },
  );

  test(
    'foreground chip Apply promotes a matching in-flight hotset acquisition',
    () async {
      final repository = _ControllableHotsetQueryRepository(
        autoCompleteQueryBuilds: 1,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final stagedCandidateKeys = <String>{};
      var candidateScenePreparations = 0;
      addTearDown(() async {
        await repository.completeAllPendingQueryBuilds();
        core.dispose();
      });
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) async {
              candidateScenePreparations += 1;
              stagedCandidateKeys.add(candidateKey);
            },
        discardCandidate: stagedCandidateKeys.remove,
        hasCandidate: (_, {required candidateKey}) =>
            stagedCandidateKeys.contains(candidateKey),
        activate: (_) {},
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final target = applied.copyWith(categoryIds: const <String>{'travel'});

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      final scenePreparationsBeforeHotset = candidateScenePreparations;
      await pumpEventQueue(times: 80);
      expect(repository.queryRequestCountFor(target), 1);
      expect(repository.pendingQueryBuildCount, 1);

      FluviDiagnosticLogger.clear();
      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 16);

      expect(
        repository.queryRequestCountFor(target),
        1,
        reason:
            'Foreground intent for exact hotset X must adopt its one native '
            'acquisition instead of starting X again.',
      );
      expect(
        repository.cancelledQueryRequestCountFor(target),
        0,
        reason: 'Foreground promotion must not cancel the exact candidate X.',
      );

      await repository.completeNextPendingQueryBuild();
      await pumpEventQueue(times: 160);

      expect(core.currentQuery.scopeFor(LedgerDirection.expense), target);
      expect(candidateScenePreparations, scenePreparationsBeforeHotset + 1);
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('QUERY_CHIP_PREWARM_PROMOTED_TO_FOREGROUND'),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'QUERY_APPLY_PUBLICATION_COMPLETED',
        ),
        hasLength(1),
      );
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        isNot(contains('QUERY_CHIP_HOTSET_READY')),
        reason:
            'The invalidated speculative continuation must not independently '
            'complete/cache the candidate after foreground ownership transfer.',
      );
    },
  );

  test(
    'foreground chip Apply adopts an exact hotset candidate already scene-preparing',
    () async {
      final repository = _ControllableHotsetQueryRepository(
        autoCompleteQueryBuilds: 2,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final retainedCandidateKeys = <String>{};
      final hotsetSceneStarted = Completer<void>();
      final releaseHotsetScene = Completer<void>();
      var candidateScenePreparations = 0;
      var sceneCancellationRequests = 0;
      addTearDown(() async {
        if (!releaseHotsetScene.isCompleted) releaseHotsetScene.complete();
        await repository.completeAllPendingQueryBuilds();
        core.dispose();
      });
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) async {
              candidateScenePreparations += 1;
              if (candidateScenePreparations == 2) {
                if (!hotsetSceneStarted.isCompleted) {
                  hotsetSceneStarted.complete();
                }
                await releaseHotsetScene.future;
              }
              retainedCandidateKeys.add(candidateKey);
            },
        discardCandidate: retainedCandidateKeys.remove,
        hasCandidate: (_, {required candidateKey}) =>
            retainedCandidateKeys.contains(candidateKey),
        activate: (_) {},
        cancel: () => sceneCancellationRequests += 1,
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final target = applied.copyWith(categoryIds: const <String>{'travel'});

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);
      await hotsetSceneStarted.future;
      expect(repository.queryRequestCountFor(target), 1);
      expect(candidateScenePreparations, 2);

      FluviDiagnosticLogger.clear();
      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 16);

      expect(repository.queryRequestCountFor(target), 1);
      expect(repository.cancelledQueryRequestCountFor(target), 0);
      expect(candidateScenePreparations, 2);

      core.noteVerticalPointerIntentStarted(41);
      expect(
        sceneCancellationRequests,
        0,
        reason:
            'A promoted exact candidate is accepted foreground work, not a '
            'disposable speculative scene when raw vertical input arrives.',
      );
      core.noteVerticalPointerIntentEnded(41, cancelled: true);

      releaseHotsetScene.complete();
      await pumpEventQueue(times: 160);

      expect(core.currentQuery.scopeFor(LedgerDirection.expense), target);
      expect(
        candidateScenePreparations,
        2,
        reason:
            'Foreground should retain/adopt the in-flight exact scene rather '
            'than re-stage an already-owned candidate bank.',
      );
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('QUERY_CHIP_PREWARM_PROMOTED_TO_FOREGROUND'),
      );
    },
  );

  test(
    'a different foreground chip target still supersedes hotset work',
    () async {
      final repository = _ControllableHotsetQueryRepository(
        autoCompleteQueryBuilds: 1,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(() async {
        await repository.completeAllPendingQueryBuilds();
        core.dispose();
      });
      await core.bootstrap();
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final hotsetTarget = applied.copyWith(
        categoryIds: const <String>{'travel'},
      );
      final foregroundTarget = applied.copyWith(
        categoryIds: const <String>{'food'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);
      expect(repository.queryRequestCountFor(hotsetTarget), 1);
      expect(repository.pendingQueryBuildCount, 1);

      core.removeAppliedQueryCategory('travel');
      await pumpEventQueue(times: 16);

      expect(repository.queryRequestCountFor(hotsetTarget), 1);
      expect(
        repository.cancelledQueryRequestCountFor(hotsetTarget),
        greaterThanOrEqualTo(1),
        reason: 'Only the genuinely obsolete speculative target is cancelled.',
      );
      expect(repository.queryRequestCountFor(foregroundTarget), 1);

      await repository.completeAllPendingQueryBuilds();
      await pumpEventQueue(times: 160);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense),
        foregroundTarget,
      );
    },
  );

  test(
    'a promoted hotset continuation cannot publish after a newer chip target',
    () async {
      final repository = _ControllableHotsetQueryRepository(
        autoCompleteQueryBuilds: 1,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final activatedParentKeys = <String?>[];
      addTearDown(() async {
        await repository.completeAllPendingQueryBuilds();
        core.dispose();
      });
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) async {},
        activate: (window) =>
            activatedParentKeys.add(window.coverageIdentity?.parentQueryKey),
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final promotedTarget = applied.copyWith(
        categoryIds: const <String>{'travel'},
      );
      final newestTarget = applied.copyWith(
        categoryIds: const <String>{'food'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);
      expect(repository.queryRequestCountFor(promotedTarget), 1);

      FluviDiagnosticLogger.clear();
      activatedParentKeys.clear();
      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 8);
      core.removeAppliedQueryCategory('travel');
      await pumpEventQueue(times: 16);

      expect(repository.queryRequestCountFor(promotedTarget), 1);
      expect(repository.queryRequestCountFor(newestTarget), 1);

      await repository.completeAllPendingQueryBuilds();
      await pumpEventQueue(times: 160);

      expect(core.currentQuery.scopeFor(LedgerDirection.expense), newestTarget);
      expect(
        core.retainedPreparedQueryCandidateCount,
        0,
        reason:
            'The superseded promoted target must not insert a stale LRU '
            'candidate after the newer target becomes authoritative.',
      );
      final publishedParent = core.navigation.state.parentQueryScope;
      final stalePromotedParentKey = promotedTarget
          .copyWith(timeScope: publishedParent.timeScope)
          .key
          .value;
      expect(activatedParentKeys, contains(publishedParent.key.value));
      expect(activatedParentKeys, isNot(contains(stalePromotedParentKey)));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'QUERY_APPLY_PUBLICATION_COMPLETED',
        ),
        hasLength(1),
      );
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        isNot(contains('QUERY_CHIP_HOTSET_READY')),
        reason:
            'The old hotset loop was invalidated at promotion, so it cannot '
            'independently retain/cache the later stale result.',
      );
    },
  );

  test(
    'rapid distinct chip removals acquire each exact target at most once',
    () async {
      final repository = _ControllableHotsetQueryRepository(
        autoCompleteQueryBuilds: 1,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(() async {
        await repository.completeAllPendingQueryBuilds();
        core.dispose();
      });
      await core.bootstrap();
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 3, amountScaled100: 300),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 300,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'rent', 'travel'},
      );
      final hotsetTarget = applied.copyWith(
        categoryIds: const <String>{'rent', 'travel'},
      );
      final firstForegroundTarget = applied.copyWith(
        categoryIds: const <String>{'food', 'rent'},
      );
      final finalForegroundTarget = applied.copyWith(
        categoryIds: const <String>{'food', 'travel'},
      );

      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await pumpEventQueue(times: 80);
      expect(repository.queryRequestCountFor(hotsetTarget), 1);

      core.removeAppliedQueryCategory('travel');
      await pumpEventQueue(times: 8);
      core.removeAppliedQueryCategory('rent');
      await pumpEventQueue(times: 16);

      expect(repository.queryRequestCountFor(hotsetTarget), 1);
      expect(repository.queryRequestCountFor(firstForegroundTarget), 1);
      expect(repository.queryRequestCountFor(finalForegroundTarget), 1);
      expect(
        repository.cancelledQueryRequestCountFor(hotsetTarget),
        greaterThanOrEqualTo(1),
      );
      expect(
        repository.cancelledQueryRequestCountFor(firstForegroundTarget),
        greaterThanOrEqualTo(1),
        reason:
            'A newer direct target may cancel only the prior direct target.',
      );

      await repository.completeAllPendingQueryBuilds();
      await pumpEventQueue(times: 200);

      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense),
        finalForegroundTarget,
      );
    },
  );

  test(
    'raw pointer intent pauses direct-chip speculation before formal vertical drag',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 2, amountScaled100: 200),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 200,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'travel'},
      );
      final target = applied.copyWith(categoryIds: const <String>{'travel'});
      expect(await core.applyQuery(applied, facetPresentation: facets), isTrue);
      await core.prepareQueryDraft(target);
      core.noteVerticalPointerIntentStarted(17);
      expect(core.verticalPointerIntentActive, isTrue);
      FluviDiagnosticLogger.clear();

      core.removeAppliedQueryCategory('food');
      await pumpEventQueue(times: 80);

      final pausedStages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      expect(pausedStages, contains('QUERY_APPLY_PUBLICATION_COMPLETED'));
      expect(
        pausedStages,
        isNot(contains('QUERY_CHIP_HOTSET_PREPARE_STARTED')),
        reason:
            'Raw pointer intent must preempt speculative chip acquisition before '
            'Flutter has classified the gesture as a vertical drag.',
      );

      FluviDiagnosticLogger.clear();
      core.noteVerticalPointerIntentEnded(17, cancelled: false);
      await pumpEventQueue(times: 80);

      final resumedStages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      final readyAheadSatisfied = resumedStages.indexOf(
        'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION',
      );
      final chipPrewarmStarted = resumedStages.indexOf(
        'QUERY_CHIP_HOTSET_PREPARE_STARTED',
      );
      expect(core.verticalPointerIntentActive, isFalse);
      expect(readyAheadSatisfied, greaterThanOrEqualTo(0));
      expect(chipPrewarmStarted, greaterThan(readyAheadSatisfied));
    },
  );

  test(
    'pointer release resumes an exact deferred page while vertical interaction remains active',
    () async {
      final repository = _ReadyAheadQueryRepository(
        holdCommittedPageReads: true,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.committedLogViewport.configureSurfaceWidth(378);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'deferred-page'},
      );

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 80);
      expect(repository.pageRequests, hasLength(1));
      expect(repository.pageRequests.single.pageOrdinal, 1);

      core.noteVerticalPointerIntentStarted(71);
      core.beginVerticalInteraction();
      repository.completeNextCommittedPage();
      await pumpEventQueue(times: 24);
      expect(core.paging.committedPageDataPendingPresentation, isTrue);
      expect(core.committedLogViewport.pageForOrdinal(1), isNull);

      FluviDiagnosticLogger.clear();
      core.noteVerticalPointerIntentEnded(71, cancelled: false);
      await pumpEventQueue(times: 80);

      expect(core.verticalInteractionActive, isTrue);
      expect(core.committedLogViewport.pageForOrdinal(1), isNotNull);
      expect(core.paging.committedPageDataPendingPresentation, isFalse);
      expect(repository.pageRequests, hasLength(1));
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('VERTICAL_DEFERRED_PAGE_PRESENTATION_RESUMED'),
      );
    },
  );

  test(
    'motion idle resumes deferred presentation while vertical interaction remains active',
    () async {
      final repository = _ReadyAheadQueryRepository(
        holdCommittedPageReads: true,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.committedLogViewport.configureSurfaceWidth(378);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'deferred-page'},
      );

      expect(await core.applyQuery(target), isTrue);
      await pumpEventQueue(times: 80);
      core.noteVerticalPointerIntentStarted(72);
      core.beginVerticalInteraction();
      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      repository.completeNextCommittedPage();
      await pumpEventQueue(times: 24);
      expect(core.paging.committedPageDataPendingPresentation, isTrue);

      core.noteVerticalPointerIntentEnded(72, cancelled: false);
      await pumpEventQueue(times: 24);
      expect(core.committedLogViewport.pageForOrdinal(1), isNull);
      expect(repository.pageRequests, hasLength(1));

      core.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
      await pumpEventQueue(times: 80);

      expect(core.verticalInteractionActive, isTrue);
      expect(core.committedLogViewport.pageForOrdinal(1), isNotNull);
      expect(core.paging.committedPageDataPendingPresentation, isFalse);
      expect(repository.pageRequests, hasLength(1));
    },
  );

  test(
    'an aborted accepted Apply releases the route-sensitive speculative boundary',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      core.notifyQuerySheetDismissalRequested();
      expect(core.querySheetDismissalTransitionActive, isTrue);

      core.notifyQuerySheetDismissalAborted();

      expect(
        core.querySheetDismissalTransitionActive,
        isFalse,
        reason:
            'A failed Apply keeps the sheet open, so its route-sensitive '
            'background-work gate must not remain latched.',
      );
    },
  );

  test(
    'income and expense applied queries remain independent across selection',
    () async {
      final repository = _CountingQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final expense = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      expect(await core.applyQuery(expense), isTrue);
      expect(repository.queryPreparationCount, 1);

      core.selectDirection(TransactionDirection.income);
      await pumpEventQueue();
      expect(repository.queryPreparationCount, 1);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.income).categoryIds,
        isEmpty,
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'food'},
      );

      final income = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2026, 7),
        }),
      );
      expect(await core.applyQuery(income), isTrue);
      expect(repository.queryPreparationCount, 2);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.income).temporalFilter,
        income.temporalFilter,
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'food'},
      );
      core.selectDirection(TransactionDirection.expense);
      await pumpEventQueue();
      expect(repository.queryPreparationCount, 2);
    },
  );
}

void _attachRealCandidateSceneCache(
  DashboardCoreController core,
  DashboardLogBoxPreparedSceneCache cache,
) {
  core.attachLogBoxSceneWindowCoordinator(
    prepare: (window, {required retainViewportId}) => cache.prepareWindow(
      window: window,
      retainViewportId: retainViewportId,
      surfaceWidth: 378,
    ),
    prepareCandidate:
        (window, {required candidateKey, required retainViewportId}) =>
            cache.prepareCandidateWindow(
              candidateKey: candidateKey,
              window: window,
              retainViewportId: retainViewportId,
              surfaceWidth: 378,
            ),
    discardCandidate: cache.discardCandidateWindow,
    hasCandidate: cache.hasCandidateWindow,
    setCandidateHotset: cache.setProtectedCandidateKeys,
    planCandidateHotset: cache.admitCandidateHotset,
    activate: cache.activateWindow,
    cancel: cache.cancelInFlightPreparation,
    report: cache.report,
  );
}

void _expectNoDirectPublicationSpeculationBeforeReadyAhead(
  List<FluviDiagnosticEvent> entries,
) {
  final stages = entries.map((event) => event.stage).toList(growable: false);
  final publicationStarted = stages.lastIndexOf(
    'QUERY_APPLY_PUBLICATION_STARTED',
  );
  final readyAheadSatisfied = stages.indexWhere(
    (stage) =>
        stage ==
        'COMMITTED_READY_AHEAD_SATISFIED_AFTER_DIRECT_QUERY_PUBLICATION',
    publicationStarted + 1,
  );
  expect(publicationStarted, greaterThanOrEqualTo(0));
  expect(readyAheadSatisfied, greaterThan(publicationStarted));
  final lowerPriorityStarts = stages
      .sublist(publicationStarted, readyAheadSatisfied + 1)
      .where(
        <String>{
          'QUERY_CHIP_HOTSET_PREPARE_STARTED',
          'RAIL_INTERACTION_WARMUP_STARTED',
          'SUMMARY_PARENT_HOTSET_PREPARE_STARTED',
        }.contains,
      );
  expect(
    lowerPriorityStarts,
    isEmpty,
    reason:
        'The publication reservation must reject Summary, rail and Query-chip '
        'speculation before exact ready-ahead settles.',
  );
}

final class _ReadyAheadQueryRepository
    implements DashboardDataRuntimeRepository {
  _ReadyAheadQueryRepository({this.holdCommittedPageReads = false});

  final bool holdCommittedPageReads;
  final List<DashboardCommittedPageRequest> pageRequests =
      <DashboardCommittedPageRequest>[];
  final List<_PendingReadyAheadPage> _pendingCommittedPages =
      <_PendingReadyAheadPage>[];

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    final base = buildRuntimeTestIndex(
      revision: request.key.coreRevision,
      generation: token.generation,
      directionalQueries: request.directionalQueries,
      initialYear: request.initialYear,
      yearWindowRadius:
          request.key.yearWindowEndInclusive - request.initialYear,
      entryCountForScope: _entryCountFor,
      previewRowCountForScope: (scope) =>
          _entryCountFor(scope).clamp(0, request.key.pageSize).toInt(),
    );
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{
      for (final entry in base.frames.entries)
        entry.key: _frameWithPagingCursor(
          entry.value,
          pageSize: request.key.pageSize,
        ),
    };
    return PreparedDashboardIndex.complete(
      key: base.key,
      frames: frames,
      catalogs: base.catalogs,
      origins: base.origins,
      generation: token.generation,
      contentDigest: Object.hash(base.contentDigest, token.generation),
      preparedAt: DateTime.utc(2026, 8, 16),
      buildMetrics: base.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    request.reason.requirePageRead();
    pageRequests.add(request);
    final page = _pageFor(request);
    if (!holdCommittedPageReads) return Future<CommittedLogPage>.value(page);
    final completion = Completer<CommittedLogPage>();
    _pendingCommittedPages.add(_PendingReadyAheadPage(request, completion));
    return completion.future;
  }

  void completeNextCommittedPage() {
    if (_pendingCommittedPages.isEmpty) {
      throw StateError('No committed page read is pending.');
    }
    final pending = _pendingCommittedPages.removeAt(0);
    pending.completion.complete(_pageFor(pending.request));
  }

  CommittedLogPage _pageFor(DashboardCommittedPageRequest request) {
    final totalRows = _entryCountFor(request.scope);
    final start = request.pageOrdinal * request.pageSize;
    final count = (totalRows - start).clamp(0, request.pageSize).toInt();
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: request.coreRevision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: DashboardLogViewportState(
        queryKey: request.scope.key,
        revision: request.coreRevision,
        groups: count == 0
            ? const <DashboardDayLogGroupViewModel>[]
            : <DashboardDayLogGroupViewModel>[
                DashboardDayLogGroupViewModel(
                  dateKey: 'fixture-day-${request.pageOrdinal}',
                  dayLabel: 'Fixture day ${request.pageOrdinal}',
                  rows: List<DashboardLogRowViewModel>.generate(
                    count,
                    (index) => _pagingRow(
                      scope: request.scope,
                      ordinal: request.pageOrdinal,
                      index: index,
                    ),
                    growable: false,
                  ),
                ),
              ],
        entryCount: totalRows,
        nextCursor: start + count < totalRows
            ? _pagingCursor(request.scope, request.pageOrdinal)
            : null,
        direction: request.scope.direction,
      ),
    );
  }

  @override
  Map<String, Object?> performanceReport() => const <String, Object?>{};

  static int _entryCountFor(CurrentLedgerQueryScope scope) {
    if (scope.categoryIds.contains('multi-page')) return 144;
    if (scope.categoryIds.contains('one-page')) return 24;
    if (scope.categoryIds.contains('deferred-page')) return 67;
    return 0;
  }

  static DashboardPreparedFrame _frameWithPagingCursor(
    DashboardPreparedFrame frame, {
    required int pageSize,
  }) {
    final count = _entryCountFor(frame.scope);
    final rootRows = List<DashboardLogRowViewModel>.generate(
      count.clamp(0, pageSize).toInt(),
      (index) => _pagingRow(scope: frame.scope, ordinal: 0, index: index),
      growable: false,
    );
    return DashboardPreparedFrame.complete(
      scope: frame.scope,
      parentQueryKey: frame.parentQueryKey,
      coreRevision: frame.coreRevision,
      totalMinor: frame.totalMinor,
      formattedAmount: frame.amount.formattedAmount,
      entryCount: count,
      formattedEntryCount: '$count',
      logBox: DashboardLogViewportState(
        queryKey: frame.queryKey,
        revision: frame.coreRevision,
        groups: rootRows.isEmpty
            ? const <DashboardDayLogGroupViewModel>[]
            : <DashboardDayLogGroupViewModel>[
                DashboardDayLogGroupViewModel(
                  dateKey: 'fixture-day-root',
                  dayLabel: 'Fixture day root',
                  rows: rootRows,
                ),
              ],
        entryCount: count,
        nextCursor: count > pageSize ? _pagingCursor(frame.scope, 0) : null,
        direction: frame.scope.direction,
      ),
      presentationDigest: Object.hash(frame.presentationDigest, count),
    );
  }

  static Map<String, Object?> _pagingCursor(
    CurrentLedgerQueryScope scope,
    int ordinal,
  ) => <String, Object?>{'scope': scope.key.value, 'ordinal': ordinal};

  static DashboardLogRowViewModel _pagingRow({
    required CurrentLedgerQueryScope scope,
    required int ordinal,
    required int index,
  }) => DashboardLogRowViewModel(
    entryId: '${scope.key.value}:page:$ordinal:row:$index',
    displayName: 'Fixture row $index',
    categoryDisplayName: 'Fixture category',
    formattedAmount: '-1 Ft',
    displayTime: '12:00',
    amountStyle: scope.direction == LedgerDirection.income
        ? LogAmountStyle.income
        : LogAmountStyle.expense,
    categoryColorId: 'fallback',
    categoryIconId: 'fallback',
    semanticLabel: 'Fixture row $index',
  );
}

final class _PendingReadyAheadPage {
  const _PendingReadyAheadPage(this.request, this.completion);

  final DashboardCommittedPageRequest request;
  final Completer<CommittedLogPage> completion;
}

final class _ControllableHotsetQueryRepository
    implements
        DashboardDataRuntimeRepository,
        PreparedDashboardIndexCancellationRepository {
  _ControllableHotsetQueryRepository({required this.autoCompleteQueryBuilds});

  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final int autoCompleteQueryBuilds;
  final List<PreparedDashboardIndexRequest> queryRequests =
      <PreparedDashboardIndexRequest>[];
  final List<DashboardIndexPreparationToken> cancelledQueryTokens =
      <DashboardIndexPreparationToken>[];
  final List<_PendingHotsetQueryBuild> _pending = <_PendingHotsetQueryBuild>[];
  final Map<int, PreparedDashboardIndexRequest> _requestsByGeneration =
      <int, PreparedDashboardIndexRequest>{};

  int get pendingQueryBuildCount => _pending.length;

  int queryRequestCountFor(CurrentLedgerQueryScope target) => queryRequests
      .where((request) => request.directionalQueries.expense == target)
      .length;

  int cancelledQueryRequestCountFor(CurrentLedgerQueryScope target) =>
      cancelledQueryTokens
          .where(
            (token) =>
                _requestsByGeneration[token.generation]
                    ?.directionalQueries
                    .expense ==
                target,
          )
          .length;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason != DataAcquisitionReason.query) {
      return _empty.prepareIndex(request, token);
    }
    queryRequests.add(request);
    _requestsByGeneration[token.generation] = request;
    if (queryRequests.length <= autoCompleteQueryBuilds) {
      return _empty.prepareIndex(request, token);
    }
    final completion = Completer<PreparedDashboardIndex>();
    _pending.add(_PendingHotsetQueryBuild(request, token, completion));
    return completion.future;
  }

  @override
  Future<void> cancelPreparedIndex(DashboardIndexPreparationToken token) async {
    cancelledQueryTokens.add(token);
  }

  Future<void> completeNextPendingQueryBuild() async {
    if (_pending.isEmpty) {
      throw StateError('No Query index build is pending.');
    }
    final pending = _pending.removeAt(0);
    try {
      pending.completion.complete(
        await _empty.prepareIndex(pending.request, pending.token),
      );
    } on Object catch (error, stackTrace) {
      pending.completion.completeError(error, stackTrace);
    }
  }

  Future<void> completeAllPendingQueryBuilds() async {
    while (_pending.isNotEmpty) {
      await completeNextPendingQueryBuild();
    }
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _PendingHotsetQueryBuild {
  const _PendingHotsetQueryBuild(this.request, this.token, this.completion);

  final PreparedDashboardIndexRequest request;
  final DashboardIndexPreparationToken token;
  final Completer<PreparedDashboardIndex> completion;
}

final class _FailOnceQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPreparationCount = 0;
  var _failNextQuery = true;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryPreparationCount += 1;
      if (_failNextQuery) {
        _failNextQuery = false;
        return Future<PreparedDashboardIndex>.error(
          StateError('synthetic query prepare failure'),
        );
      }
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _BlockingQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPreparationCount = 0;
  PreparedDashboardIndexRequest? _pendingRequest;
  DashboardIndexPreparationToken? _pendingToken;
  Completer<PreparedDashboardIndex>? _pendingCompletion;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason != DataAcquisitionReason.query) {
      return _empty.prepareIndex(request, token);
    }
    queryPreparationCount += 1;
    _pendingRequest = request;
    _pendingToken = token;
    final completion = Completer<PreparedDashboardIndex>();
    _pendingCompletion = completion;
    return completion.future;
  }

  Future<void> completeQueryPreparation() async {
    final request = _pendingRequest;
    final token = _pendingToken;
    final completion = _pendingCompletion;
    if (request == null || token == null || completion == null) {
      throw StateError('No Query preparation is pending.');
    }
    completion.complete(await _empty.prepareIndex(request, token));
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _CountingQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPreparationCount = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryPreparationCount += 1;
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _RecordingQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final List<PreparedDashboardIndexRequest> queryRequests =
      <PreparedDashboardIndexRequest>[];

  int get unfilteredExpenseQueryBuildCount => queryRequests.where((request) {
    final scope = request.directionalQueries.expense;
    return scope.categoryIds.isEmpty &&
        scope.partnerIds.isEmpty &&
        scope.refinements.isEmpty &&
        !scope.temporalFilter.isRestrictive;
  }).length;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryRequests.add(request);
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _DirectionalWindowReuseRepository
    implements
        DashboardDataRuntimeRepository,
        PreparedDashboardIndexPartitionRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final List<PreparedDashboardIndexRequest> queryWholeIndexRequests =
      <PreparedDashboardIndexRequest>[];
  final List<PreparedDashboardIndexPartitionRequest> partitionRequests =
      <PreparedDashboardIndexPartitionRequest>[];

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryWholeIndexRequests.add(request);
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<PreparedDashboardIndex> prepareIndexPartition(
    PreparedDashboardIndexPartitionRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    partitionRequests.add(request);
    final complete = await _empty.prepareIndex(request.request, token);
    final direction = request.direction;
    return PreparedDashboardIndex.complete(
      key: complete.key,
      frames: <LedgerQueryKey, DashboardPreparedFrame>{
        for (final entry in complete.frames.entries)
          if (entry.value.scope.direction == direction) entry.key: entry.value,
      },
      catalogs: <LedgerQueryKey, DashboardSemanticCatalog>{
        for (final entry in complete.catalogs.entries)
          if (entry.value.parentScope.direction == direction)
            entry.key: entry.value,
      },
      origins: <LedgerQueryKey, DashboardDataOrigin>{
        for (final entry in complete.origins.entries)
          if (complete.frames[entry.key]?.scope.direction == direction)
            entry.key: entry.value,
      },
      generation: token.generation,
      contentDigest: Object.hash(complete.contentDigest, direction),
      preparedAt: complete.preparedAt,
      buildMetrics: complete.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

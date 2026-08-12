import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
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

      core.notifyQuerySheetDismissed();
      await pumpEventQueue(times: 80);
      expect(repository.queryPreparationCount, greaterThan(1));
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
    activate: cache.activateWindow,
    cancel: cache.cancelInFlightPreparation,
    report: cache.report,
  );
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

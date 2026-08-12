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
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

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
    'prewarmed category and partner chips remove their queries without tap-time builds',
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
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {},
        prepareCandidate:
            (window, {required candidateKey, required retainViewportId}) async {
              candidateScenePreparations += 1;
            },
        discardCandidate: (_) {},
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
      await pumpEventQueue(times: 80);
      final preparedBeforeTap = repository.queryPreparationCount;
      final scenesBeforeTap = candidateScenePreparations;
      expect(preparedBeforeTap, greaterThanOrEqualTo(6));

      core.removeAppliedQueryCategory('food');

      // The neighbour was staged while the chip was stable, so the query
      // mutation is published in this same interaction turn.  A later event
      // queue drain must only observe background work, never make the chip
      // removal visible for the first time.
      expect(repository.queryPreparationCount, preparedBeforeTap);
      expect(candidateScenePreparations, scenesBeforeTap);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'travel'},
      );

      await pumpEventQueue(times: 80);
      expect(repository.queryPreparationCount, greaterThan(preparedBeforeTap));
      expect(candidateScenePreparations, greaterThan(scenesBeforeTap));

      // The category publication starts a new bounded neighbour prewarm for
      // its resulting scope. A subsequent partner removal must consume that
      // prepared directional candidate in the same interaction turn too.
      final preparedBeforePartnerTap = repository.queryPreparationCount;
      final scenesBeforePartnerTap = candidateScenePreparations;
      core.removeAppliedQueryPartner('merchant-a');

      expect(repository.queryPreparationCount, preparedBeforePartnerTap);
      expect(candidateScenePreparations, scenesBeforePartnerTap);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).categoryIds,
        <String>{'travel'},
      );
      expect(
        core.currentQuery.scopeFor(LedgerDirection.expense).partnerIds,
        <String>{'merchant-b'},
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

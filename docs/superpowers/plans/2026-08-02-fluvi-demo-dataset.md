# Fluvi Demo Dataset Implementation Plan

> **For agentic workers:** Execute this plan inline in small TDD checkpoints. The user has not authorized a commit, push, or build.

**Goal:** Seed 700 deterministic records into the real Room database and expose the same scope-based read path to SummaryPill and the future LogBox.

**Architecture:** A pure Kotlin generator creates an immutable dataset plan. A core use case writes that plan atomically through the existing category, partner, ledger, revision, projection, and metadata boundaries. A debug-only Flutter bridge triggers the command, while a Room revision observer feeds the existing latest-wins query controller; SummaryPill consumes only the resulting query state.

**Tech Stack:** Kotlin, Room, SQLite/Flow invalidation, Flutter MethodChannel/EventChannel, existing `CurrentQueryController`, existing category catalog, Kotlin/JUnit/Robolectric tests, Dart unit/widget tests.

## Global Constraints

- Do not write demo records from a Flutter widget or directly from a DAO in presentation code.
- Do not create a second query or summary system.
- Do not hardcode a demo amount in SummaryPill.
- Keep the production current-month default unchanged.
- Use `2026-01-01 <= local date < 2026-08-01` in `Europe/Budapest`.
- Use integer money values from the existing `amountScaled100` contract; verify its display scale before generating targets.
- Do not use Flutter `Color`, asset paths, `IconData`, or widgets in core/read models.
- Do not commit, push, or build until explicitly requested.

## File map

- Create `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetGenerator.kt`: pure deterministic dataset plan and monthly allocation.
- Create `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetModels.kt`: immutable plans, manifest IDs, reports, and row drafts.
- Create `android/fluvi-core/src/main/kotlin/com/fluvi/core/usecase/SeedFluviDemoDatasetUseCase.kt`: atomic seed, idempotence, reset, metadata and revision.
- Create `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetVersion.kt`: version, PRNG seed and deterministic ID namespace.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/entity/FluviCurrentEntities.kt`: nullable demo metadata fields on app settings if confirmed as the least invasive metadata owner.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabase.kt`: schema version/migration or fresh metadata column defaults.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviCoreDaos.kt`: metadata, deterministic cleanup and invalidation observation queries.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/FluviCore.kt`: expose the seed use case and observer read contract.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`: canonical slice/read-row projection and revision-driven observation.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviQueryModels.kt`: immutable slice/row contracts if needed.
- Modify `android/fluvi-core/src/main/kotlin/com/fluvi/core/sync/LedgerChangePublisher.kt` or add a batch publisher helper only if the existing outbox API cannot publish the atomic seed without duplicated logic.
- Modify `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`: debug-only seed MethodChannel and dashboard EventChannel wiring.
- Create `lib/core/demo_data/demo_data_bridge.dart`: typed seed report bridge.
- Modify `lib/features/dashboard/query/data/dashboard_ledger_repository.dart`: add an optional/required watch contract without breaking test fakes.
- Modify `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`: observe the native scope stream and map the shared slice.
- Modify `lib/features/dashboard/query/application/current_query_controller.dart`: cancel/restart scope subscriptions, latest-wins, revision-aware cache invalidation.
- Modify `lib/features/dashboard/application/dashboard_core_controller.dart`: debug-only July 2026 navigation after successful seed.
- Create `test/core/demo_data/demo_seed_report_test.dart`: bridge report decoding and payload validation.
- Create or extend `test/features/dashboard/query/current_query_controller_test.dart`: observer and latest-wins behavior.
- Create `android/fluvi-core/src/test/kotlin/com/fluvi/core/demo/DemoDatasetGeneratorTest.kt`: RED/green generator tests.
- Create `android/fluvi-core/src/test/kotlin/com/fluvi/core/demo/SeedFluviDemoDatasetUseCaseTest.kt`: Room seed, reset and query tests.
- Create `android/fluvi-core/src/test/kotlin/com/fluvi/core/query/FluviDashboardObservationTest.kt`: invalidation and canonical read tests.
- Create `docs/demo-data/fluvi-demo-dataset.md`: final seed version, mapping, totals, trigger and read contract.

### Task 1: Establish failing generator tests

**Files:**
- Create: `android/fluvi-core/src/test/kotlin/com/fluvi/core/demo/DemoDatasetGeneratorTest.kt`
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetModels.kt`
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetVersion.kt`

**Interfaces:**
- Produce `DemoDatasetPlan(version: Int, prngSeed: Long, categories, partners, entries, monthlyReports)`.
- Each entry draft exposes deterministic `id`, `partnerId`, `categoryId`, direction, integer amount, local epoch day, local minutes, UTC timestamp, note, and assignment mode.

- [ ] Write tests for exact 7×100 counts, 6/94 direction mix, target totals, valid date range, category/icon/color IDs, deterministic equality, and low/high expense bounds.
- [ ] Run the focused Android test and confirm it fails because the generator/model is absent.

### Task 2: Implement the pure deterministic generator

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetModels.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetVersion.kt`
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetGenerator.kt`

**Interfaces:**
- `DemoDatasetGenerator.generate(): DemoDatasetPlan` is side-effect free.
- It uses fixed category/partner semantic definitions and catalog IDs, not visual literals.

- [ ] Implement deterministic ULID generation using the existing Crockford alphabet/ULID constraints, with fixed timestamps/PRNG output per ordinal.
- [ ] Allocate mandatory recurring and variable expenses first, then distribute the remaining target across normal transactions; reject any plan that violates monthly bounds.
- [ ] Convert `Europe/Budapest` local date/time to UTC using the existing core time representation.
- [ ] Run generator tests and confirm all pass.

### Task 3: Add the atomic core seed use case

**Files:**
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/usecase/SeedFluviDemoDatasetUseCase.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/FluviCore.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/entity/FluviCurrentEntities.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabase.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviCoreDaos.kt`

**Interfaces:**
- `suspend fun seed(forceReset: Boolean = false): DemoSeedReport`.
- The public core exposes `val demoSeed: SeedFluviDemoDatasetUseCase`.

- [ ] First add failing Room tests for fresh seed, second no-op, force reset preserving unrelated rows, rollback, metadata, revision, and exactly one Uncategorized row.
- [ ] Decide from the existing app-settings contract whether nullable seed metadata columns require Room v2 migration; do not add a new table unless app settings cannot safely own it.
- [ ] Implement deterministic manifest detection, foreign-key-safe cleanup, entity validation, one Room transaction, one revision advance, and explicit outbox/projection behavior.
- [ ] Run focused Room tests; fix implementation until green.

### Task 4: Expose the native canonical dashboard slice

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviQueryModels.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviCoreDaos.kt`

**Interfaces:**
- `FluviLedgerReadService.readSlice(scope, pageSize, cursor): FluviDashboardLedgerSlice`.
- `FluviLedgerReadService.observeSlice(scope, pageSize): Flow<FluviDashboardLedgerSlice>`.

- [ ] Add failing tests proving total, count, page, stable cursor, query key, direction, and revision are derived from the same scope.
- [ ] Add a revision-observation query that emits after the seed transaction commits.
- [ ] Add joined/batched row resolution for partner/category presentation fields without per-row N+1 queries.
- [ ] Run Room query and observation tests.

### Task 5: Add the debug seed and observation bridges

**Files:**
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Create: `lib/core/demo_data/demo_data_bridge.dart`
- Modify: `lib/features/dashboard/query/data/dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`

**Interfaces:**
- Dart `DemoDataBridge.seedDemoDataset({bool forceReset = false})`.
- Repository `watch(CurrentLedgerQueryScope scope)` emits `DashboardLedgerResult`.

- [ ] Add failing Dart bridge tests for report fields and malformed native payloads.
- [ ] Add a native debug-only `seedDemoDataset` method and an EventChannel-backed observation stream; do not expose DAOs or entry payloads.
- [ ] Map core rows to stable Flutter read-model fields only.
- [ ] Run bridge tests and Android compile/unit tests.

### Task 6: Integrate latest-wins query observation and debug navigation

**Files:**
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Create or modify: existing debug configuration/bootstrap owner identified during implementation.

**Interfaces:**
- Existing `CurrentQueryController` remains the sole query state owner.
- Debug seed success invokes a separate navigation intent to `MonthScope(2026-07)` with rail closed.

- [ ] Add failing controller tests for automatic observer emission, scope cancellation, stale result rejection, and demo navigation without changing production defaults.
- [ ] Implement subscription lifecycle and revision-aware cache invalidation.
- [ ] Keep SummaryPill bound to query result amount only; do not pass seed reports into presentation.
- [ ] Run focused Flutter tests.

### Task 7: Verify end-to-end contracts and document the dataset

**Files:**
- Create: `docs/demo-data/fluvi-demo-dataset.md`
- Modify: `docs/superpowers/checklists/2026-08-02-fluvi-demo-dataset.md`
- Add/modify: architecture boundary tests under the existing project test location.

- [ ] Run generator, Room, query, bridge, invalidation, idempotency, force-reset, and Flutter controller tests.
- [ ] Measure seed duration and representative year/month/page read durations in debug tests/logs.
- [ ] Update every DEMO checklist item with truthful status and evidence.
- [ ] Do not commit, push, or build; report any remaining blocked item explicitly.

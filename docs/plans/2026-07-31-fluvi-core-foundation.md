# Fluvi Core Foundation — implementation plan

**Goal:** replace the inherited application scaffold with a deliberately minimal
Kotlin/Room library project. Deliver only a clean database-management core.

**Non-goal boundary:** do not create Flutter, Android application, UI, APK,
Google Sheets API, restore runtime, recurring ghost runtime, Inbox parser, or a
bridge to the old application.

## Task 1 — Establish the clean core-only project boundary

Files to replace/remove:

- Remove inherited Flutter/UI/app source, assets, app module, legacy tests, old
  APK workflow, and old product documentation.
- Retain only generic Gradle wrapper tooling under android/gradle and
  android/gradlew*. It contains no app behaviour.
- Create android/settings.gradle.kts, android/build.gradle.kts,
  android/fluvi-core/build.gradle.kts,
  android/fluvi-core/src/main/AndroidManifest.xml, core-only README,
  .gitignore, scripts/verify-clean-core-boundary.sh, and a core-test GitHub
  workflow.

RED:

Write an isolation audit test/script expectation first: the Gradle settings
exposes only :fluvi-core, and no tracked production file declares a Flutter or
Android application plugin.

GREEN:

Create an Android library module, namespace com.fluvi.core, with
Room/KSP/JUnit/Robolectric dependencies. Do not add a Flutter plugin,
applicationId, or APK task.

Verify:

- Run ./scripts/verify-clean-core-boundary.sh.
- rg finds no dev.flutter, com.android.application, or include(":app") in
  android.
- git ls-files contains no lib/, test/, assets/, web/, pubspec.yaml, or
  android/app/ path.
- ./gradlew :fluvi-core:tasks --all exposes a library test task and no :app
  task.

## Task 2 — Write and run the first core RED tests

Files:

- android/fluvi-core/src/test/kotlin/com/fluvi/core/database/FluviDatabaseSchemaTest.kt
- android/fluvi-core/src/test/kotlin/com/fluvi/core/model/FluviIdGeneratorTest.kt
- android/fluvi-core/src/test/kotlin/com/fluvi/core/catalog/FluviCategoryCatalogTest.kt

RED:

Specify fresh-database tables/seed, ULID length/order, and the central 21/50
catalog. Run targeted core tests and record the expected missing-core failure.

GREEN:

Only after the observed RED result, add schema/model/catalog code sufficient for
these tests.

## Task 3 — Build the v1 clean Room schema

Files:

- model/FluviIds.kt, model/FluviLedgerModels.kt, model/FluviEnums.kt
- catalog/FluviCategoryCatalog.kt
- database/entity/*.kt, database/dao/*.kt
- database/FluviDatabase.kt, database/FluviDatabaseFactory.kt, FluviCore.kt

Requirements:

- Create all current and schema-only future tables stated in the architecture
  document, with ULID text keys, foreign keys, indexes, and lower-case enum
  persistence.
- Seed exactly one non-deletable Uncategorized category.
- Configure fluvi_core.db, Room v1, export schema.
- Expose a typed `FluviCoreFactory` facade; keep Room/DAOs/repositories
  module-internal and enforce ledger scalar invariants at the SQLite boundary.
- No migration path from any existing database.

Verify:

Run focused Room schema tests. Inspect generated schema and the absence of
legacy imports/table names.

## Task 4 — Partner and category transactional ownership

RED then GREEN files:

- Tests: usecase/FluviPartnerUseCaseTest.kt,
  usecase/FluviCategoryUseCaseTest.kt
- Production: repository/FluviPartnerRepository.kt,
  repository/FluviCategoryRepository.kt,
  usecase/FluviPartnerUseCase.kt,
  usecase/FluviCategoryUseCase.kt

Rules:

Implement creation, exact normalized alias lookup, rename override, reversible
merge, default category change, and category deletion/reassignment in one Room
transaction. Prove override rows remain untouched by default changes and retain
override mode after category deletion.

## Task 5 — Ledger write, archive, projection, and outbox core

RED then GREEN files:

- Tests: usecase/FluviLedgerWriteUseCaseTest.kt,
  sync/LedgerSheetProjectionTest.kt,
  sync/LedgerSyncOutboxRepositoryTest.kt
- Production: repository/FluviLedgerRepository.kt,
  usecase/FluviLedgerWriteUseCase.kt,
  sync/LedgerSheetRow.kt, sync/LedgerSheetProjection.kt,
  sync/LedgerSyncOutboxRepository.kt

Rules:

Validate commands, materialize the effective category, increment revisions,
project exactly one flat row, coalesce outbox upserts, and archive only on
deletion. No Google client is introduced.

## Task 6 — SQL reads, saved Query, and checkpoint metadata

RED then GREEN files:

- Tests: query/FluviLedgerReadServiceTest.kt,
  usecase/FluviQuerySnapshotUseCaseTest.kt,
  sync/LedgerCheckpointCoordinatorTest.kt,
  query/FluviLedgerLargeDatasetTest.kt
- Production: query/*.kt, repository/FluviQuerySnapshotRepository.kt,
  usecase/FluviQuerySnapshotUseCase.kt,
  sync/LedgerCheckpointCoordinator.kt,
  sync/LedgerRestoreContract.kt

Rules:

Implement keyset-only timeline, SQL summaries, normalized direction-affine
snapshots, and metadata/preparation only for checkpoint policy. The 50,000-row
test proves bounded page and aggregate correctness, not a device-specific
speed number.

## Task 7 — Verification, final commit, and push

1. Re-read docs/architecture/fluvi-core-foundation.md and update every FCORE
   row honestly.
2. Run :fluvi-core:testDebugUnitTest in Ubuntu/proot. If the known local ARM64
   AAPT2 limitation blocks Android unit execution, record the exact environment
   result and use the core-only GitHub workflow for authoritative x86_64
   verification.
3. Run scripts/verify-clean-core-boundary.sh, source import audits, and
   git diff --check.
4. Commit the implementation with:

       feat(fluvi): establish clean Room data core

5. Push refactor/fluvi-production, dispatch/wait for the core-only CI workflow.
   If it passes, commit the evidence-only acceptance-checklist update and push
   it too; report only evidence that actually passed.

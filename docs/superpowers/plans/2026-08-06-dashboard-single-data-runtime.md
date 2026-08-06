# Dashboard single data runtime implementation plan

Date: 2026-08-06

Execution mode: one agent, inline. The work is tightly coupled across one
runtime/domain/codec migration, so delegation would increase merge and
source-of-truth risk and is prohibited by the user.

Design:
`docs/superpowers/specs/2026-08-06-dashboard-single-data-runtime-design.md`

Acceptance gate:
`docs/superpowers/checklists/2026-08-06-dashboard-single-data-runtime.md`

## 1. Freeze baseline and expose the failed contract

- Preserve branch/tag, hashes, tests and logcat counts.
- Replace old tests that require `liveStarts + 1` with RED assertions that
  settle and every structural navigation perform zero acquisition.
- Add a RED static boundary asserting the live EventChannel, live repository
  interface and navigation PreparedDeck imports do not exist.
- Run the focused tests in Ubuntu proot and capture the expected failures.

## 2. Introduce typed acquisition and the global index model

- Add `DataAcquisitionReason`, `DashboardDataOrigin` and
  `DashboardPresentationMode`.
- Add parent-neutral `DashboardPreparedFrame` and immutable
  `PreparedDashboardIndex` with exact maps, catalogs, zero-frame behavior,
  digest and metrics.
- Add model tests for both directions, SUM/year/month/day lookup, zero periods,
  atomic amount/count/LogBox and revision mismatch.
- Migrate test fixtures to construct one complete index.

## 3. Build the single data runtime test-first

- Add RED tests for one global subscription, bootstrap barrier, generation
  latest-wins, revision-during-motion pending behavior and idle-frame swap.
- Implement `GlobalCoreRevisionObserver` and
  `PreparedDashboardIndexBuilder`.
- Implement `DashboardDataRuntime` current/pending lifecycle and diagnostics.
- Verify no navigation API is present on the runtime.

## 4. Replace presentation ownership test-first

- Add RED tests for synchronous parent/plane/direction/open-close/cross/settle
  selection from one index and zero fake repository/native/SQL/build/payload
  deltas.
- Implement `DashboardPresentationController` around the existing navigation,
  Motion Kernel, coalescer and visible store.
- Make `DashboardCoreController` a thin runtime/presentation façade.
- Make navigation methods synchronous and settle metadata-only.
- Preserve controller, physics, scroll-position and catalog semantics.

## 5. Isolate explicit paging

- Add RED tests that only committed vertical near-end can read, settle cannot,
  and stale page callbacks reject.
- Split the repository contract into index build, global revision and paging.
- Implement `ExplicitCommittedPagingController` with exact metadata guards.
- Keep the stable LogBox viewport and lazy slivers.

## 6. Replace the native parent-deck transport

- Add native RED tests for both directions in one index, constant SQL counts,
  sparse/zero periods, deduplicated rows and 10k/50k/100k bounds.
- Add aggregate row/preview index models and one global builder in
  `FluviLedgerReadService`.
- Implement one day aggregate query plus one ordered cursor scan, then fold
  month/year/all summaries in Kotlin.
- Implement the versioned deduplicated index binary codec and Dart worker
  decoder/projector.
- Add QueryKey parity and malformed/bounds tests.
- Record `EXPLAIN QUERY PLAN`; change Room indexes only if the plan requires it.

## 7. Delete the dual architecture

- Remove deck cache/pipeline/prewarm/domain/repository code and tests.
- Remove committed live query controller/interface/tests.
- Remove dashboard exact-scope EventChannel, observation session and tests.
- Remove `readDashboardPreparedDeck`, deck native models/codec branches and
  production imports.
- Tighten architecture tests so reintroduction cannot compile/test green.

## 8. Complete interaction, widget and invariant tests

- Cover all 20 required behavioral cases.
- Run the specified 50/50/30/20/20 interaction sequence with complete fake
  transport counters and exactly one revision subscription.
- Add revision/property/stale-callback tests.
- Verify stable rail/physics/LogBox/pulse identities and localized rebuilds.
- Confirm no golden files changed.

## 9. Verify and profile

- Run focused tests after each RED/GREEN slice in Ubuntu proot.
- Run full non-golden Flutter suite and `flutter analyze` in Ubuntu proot.
- Run native core/app Gradle tests and boundary script.
- Run 10k/50k/100k stress metrics.
- Update the profile harness to measure the full interaction interval,
  startup/index phases, p95/p99/worst frames, GC/allocation, memory and all
  transport counts.
- Run the scripted emulator profile and report threshold PASS/FAIL honestly.
- Document the reproducible physical-device command and interaction script.

## 10. Release gate and delivery

- Re-read every checklist row and approved design.
- Recompute rail/physics hashes and review the complete diff.
- Remove dead imports, TODOs, temporary/fallback paths and stale docs.
- Commit the final coherent migration and push the branch.
- Let GitHub Actions build/test/profile the APK.
- Download the successful APK to `/storage/emulated/0/Download/fluvi`, record
  SHA-256, Actions run/artifact and final commit.
- Produce the factual 20-item report and PASS/FAIL invariant table. Do not call
  the branch merge-ready if any acceptance row fails.

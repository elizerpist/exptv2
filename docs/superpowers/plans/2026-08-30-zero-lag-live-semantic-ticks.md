# Zero-lag live semantic ticks implementation plan

> Execute inline because the time, Avatar and Mind paths converge on the same
> visible-frame and LogBox resource owners; parallel edits would create
> conflicting ownership decisions. Review each checkpoint before continuing.

## Goal

Restore complete, exact, renderable live data on every Segmented time/level,
Budget Avatar and Mind semantic tick without restoring repository, index,
scene-preparation or text-layout work to the motion hot path.

## Baseline

- Branch: `separated-core-modes`
- Physical-failure source: `0fe4d8e2f75ecb59f50530e05f2e98101a84f459`
- Contract/checklist:
  `docs/superpowers/checklists/2026-08-30-zero-lag-live-semantic-ticks.md`
- Physical validation: pending user only.

## Tasks

### 1. Lock red product contracts

- [x] Replace the settle-only temporal assertions in
  `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
  and
  `test/features/dashboard/application/dashboard_scene_window_rotation_test.dart`
  with one-frame complete live-publication assertions.
- [x] Add production-parent `DashboardLogBoxViewport` assertions for a Mind
  range change before release in
  `test/features/dashboard/presentation/dashboard_logbox_query_preview_paint_test.dart`.
- [x] Add a real-handle Avatar crossing test proving the current partial
  `partitionRetained=true` path fails the complete identity contract.
- [x] Add Segmented level-selector one-frame data tests without
  `pumpAndSettle` as the live proof.
- [x] Run the exact focused tests through Ubuntu/proot and record the expected
  failures in the checklist.

### 2. Introduce one typed complete live identity and atomic barrier

- [x] Extend
  `lib/features/dashboard/application/dashboard_live_interaction_coordinator.dart`
  with tick sequence, effective Query/target/range, revision/epoch and prepared
  index identity required by visible consumers.
- [x] Extend
  `lib/features/dashboard/visible/domain/dashboard_visible_frame.dart` and
  `lib/features/dashboard/visible/application/dashboard_visible_frame_store.dart`
  so one staged live generation owns navigation, amount, count and LogBox
  publication.
- [x] Add a mixed-projection detector and bounded numeric metrics; avoid
  per-frame formatted logging.
- [x] Green the identity/store unit tests.

### 3. Make LogBox roots selectable before publication

- [x] Add a bounded row-resource reuse/first-root assembly capability to the
  existing `DashboardLogBoxPreparedSceneCache`; do not add a second renderer.
- [x] Key reusable row layouts by immutable row content identity, revision and
  layout profile rather than an arbitrary amount-refined Query key.
- [x] Expose complete-only synchronous activation for a staged live root.
- [x] Keep active/retained scene ownership lease-safe and within row/byte/bank
  limits.
- [x] Add cache reuse, exact order, empty, eviction and no-layout-on-activation
  tests.

### 4. Restore Segmented time and level live publication

- [x] Arm the finite active DAY/MONTH/YEAR component domains and adjacent level
  publication roots before selector input becomes ready.
- [x] Change
  `navigateExperimentalTemporalComponentCandidate` to resolve a retained exact
  root, accept one live identity and publish the complete frame in the current
  crossing turn.
- [x] Change the Segmented level path to the same complete prepared publication
  contract rather than the asynchronous full navigation path.
- [x] Make settle promote the current live target without first data publish or
  visual digest change.
- [x] Green DAY/MONTH/YEAR/level, reverse/interruption, stale-generation,
  Classic-control and protected-carousel tests.

### 5. Restore complete Avatar publications

- [x] Extend Avatar hotset priming to retain complete focused first roots and
  prepared Budget projection inputs for its bounded semantic target catalog.
- [x] Remove the real-handle `previewTargetHandle` early return in
  `DashboardBudgetLogboxDrilldownCoordinator`.
- [x] Stage/activate the prepared focus root and publish selected target,
  Header, limit, partition, distribution, Rhythm, amount/count and LogBox under
  one live identity.
- [x] Ensure aggregate restoration is equally prepared and settle only promotes
  canonical ownership.
- [x] Green eight-crossing, reverse, empty/populated, both-direction,
  same-target, stale-result and no-heavy-operation tests.

### 6. Make Mind preview physically drawable

- [x] Assemble the exact first visible range root from the resident amount
  membership plus reusable row resources before calling the atomic preview
  publisher.
- [x] Preserve frame-coalesced latest-value-wins callbacks, stable slider
  identity/domain and one canonical release commit.
- [x] Keep the live root visible while the matching canonical result promotes;
  reject stale completion without rollback.
- [x] Green real-viewport one-frame row/semantics/extent assertions, both
  thumbs, empty/one/multi-page ranges and no-heavy-operation counters.

### 7. Verify protected boundaries and record evidence

- [x] Run formatting checks, focused analysis, full `flutter analyze`, all
  affected tests, Classic controls, centered-carousel tests, Dashboard/LogBox/
  Budget/Mind suites and the broader `test/homev2` suite via Ubuntu/proot.
- [x] Reproduce and classify inherited failures against starting SHA when
  needed; never label a failing broad suite PASS.
- [x] Inspect the final diff and update every checklist status honestly.
- [x] Add the remaining D06–D10 decision records with exact evidence and
  validation results. Do not edit `MILESTONE_COMMITS.md`.

### 8. Commit, push and deliver exact APK

- [ ] Create coherent evidence-backed commits with the required Why/Evidence/
  Changed/Validation/Known limitations/Physical validation body.
- [ ] Push `separated-core-modes` without staging unrelated files.
- [ ] Monitor the GitHub Actions human diagnostic profile build for the exact
  final SHA.
- [ ] Download the normal `lib/main.dart` APK to
  `/storage/emulated/0/Download/fluvi`, verify SHA-256 and provide the user-only
  physical test script.

## Completion rule

Do not build or hand off while any non-user-only acceptance item is PARTIAL,
BLOCKED or NOT DONE. The maximum handoff status is
`TEST-CLEAN / DEVICE-PENDING`.

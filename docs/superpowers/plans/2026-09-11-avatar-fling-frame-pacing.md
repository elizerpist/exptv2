# Avatar fling frame-pacing forensic and minimal repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove the first Avatar live-resource preparation work unit that
breaks the existing 1 ms UI-slice contract, then repair only that unit while
preserving exact Avatar semantics and motion ownership.

**Architecture:** `DashboardLogBoxPreparedSceneCache.prepareWindow` remains
the sole staged-scene and yielding owner. `DashboardCoreController` keeps the
existing `budgetAvatarPreview` resource-lane choice and correlation identity;
`BudgetTargetAvatarRail` keeps the existing controller, `ScrollPosition`, and
physics. The implementation adds no cache, controller, visibility authority,
or UI-side workflow.

**Tech Stack:** Dart, Flutter widget/integration tests, existing diagnostic
ring, Android GitHub Actions profile, SCIP (`scip_dart 1.6.2`).

## Global Constraints

- Evaluate runtime behaviour from `92222edddeee5bb13792f62f939eedf81c867a52`;
  retain `5b1fe5067c8c3f2b14f7eb6398811566b25dbaef` only as a docs-only
  journal descendant.
- Do not edit `docs/FLUVI_ENGINEERING_JOURNAL.md`.
- Scope is Avatar fling smoothness/frame pacing only; do not change direction,
  Time, Mind, filtering, layout, geometry, design, persistence, or physics
  without direct causal proof.
- Never reduce semantic crossings, exact target publication, paint correctness
  or latest-wins/stale-rejection behaviour to improve timing.
- Run Flutter commands through Ubuntu proot; build the human APK online only.

## Evidence fixed before execution

- The matching graph is tooling commit
  `3f1a2bda6b529302ba59a04e226dc935f8fa446d`, source head `92222edd…`, raw
  index SHA-256 `22898ae4bd1aa4bb9d5af51c3f68034adddbd0e5112c01fd8986d44e77e46c12`.
- The fresh Avatar log export is unchanged: modified
  `2026-09-11T04:29:32.195Z`, 723,485 bytes, SHA-256
  `84ce186d3d7a92a843ce1fb9147e0c8a11d30cfd0447f85e9796e9d8d7787164`,
  session `fluvi-1789100927146293`, build `profile/92222edddeee`.
- Deduplicated retained sequences are `8463..9466`, 1,004 unique records,
  996 identical duplicate copies, no differing duplicates or internal gaps.
- Physical candidate boundary is only a hypothesis: sequence 9006 reports
  `rowDiscovery=10,561µs` followed by 9009
  `uiIsolateMicros=20,771`, `largestContiguousUiSliceMicros=10,561` for an
  active `avatar-live-root` target-1 preparation. It is not yet proven to be
  the perceived hitch or its inner cause.

### Task 1: Production-parent forensic workload and correlation

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart:1450-1650`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart:3785-3925,8393-8560`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart`
- Modify: `integration_test/dashboard_interaction_profile_test.dart`
- Modify: `integration_test/support/dashboard_profile_report.dart`

**Interfaces:**
- Consumes existing `DashboardLogBoxSceneWindow`,
  `DashboardLiveInteractionResourceLane.budgetAvatarPreview`, candidate
  target/generation/epoch and cache `checkpoint` API.
- Produces bounded diagnostic records keyed by the existing resource key and
  current target; the records contain no callback that can schedule work.

- [ ] **Step 1: Write a real-component failing regression.**
  Extend the existing persistent Avatar test/profile rather than adding a
  test-only shell. Its fixture must create nine distinct non-empty targets and
  invoke the existing rail/Core/cache/visible-store path through 20
  forward/reverse cold/warm/mixed flings, including drag-to-ballistic and
  target supersession. Assert that an exact target resource preparation emits
  a row-discovery record with target handle, focus generation, interaction
  epoch, resource-key digest, owner, active/current state and work-unit
  duration; assert FrameTiming/correlation linkage, final paint equality,
  no pending candidate, stable identities and zero tick repository/index/
  scene/canonical work.

- [ ] **Step 2: Verify RED.**
  Run the focused test through Ubuntu proot. The pre-change source must fail
  because the required row-discovery work-unit record/correlation is absent,
  not because the real components were bypassed.

- [ ] **Step 3: Add only bounded diagnostic points.**
  Around the actual row-discovery operations (`_RowLayoutKey.fromRow`,
  duplicate lookup/map insertion, and day-label extraction), record each
  individual elapsed duration and close/checkpoint the existing cache slice
  at the first proven over-budget inner boundary. Carry existing target/owner
  identity from the resource-lane request; do not add a state owner,
  unbounded sink, task, debounce, or timer. Extend the profile report to
  serialize the correlation and raw FrameTiming interval only when the
  existing diagnostics are enabled.

- [ ] **Step 4: Verify GREEN for instrumentation only.**
  Re-run the focused tests. Confirm that semantic sequence, publications and
  identity values are unchanged; record the strongest inner unit and frame
  association. If no unit is reproducibly over budget, stop implementation
  work and improve workload fidelity/correlation rather than optimise.

### Task 2: Causal RED performance gate

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart`
- Modify: `integration_test/dashboard_interaction_profile_test.dart`
- Modify: `integration_test/support/dashboard_profile_report.dart`

**Interfaces:**
- Consumes the exact diagnostic record added in Task 1 and the source-defined
  `DashboardLogBoxPreparedSceneCache.defaultMaxContiguousUiSliceMicros`.
- Produces one deterministic production-parent assertion for the proven
  inner operation, not a device-raster threshold.

- [ ] **Step 1: State one falsifiable hypothesis.**
  Name the first inner unit and source span that exceeds 1 ms under the
  representative cold/mixed workload, and identify the target/frame record
  which makes it causal. Reject rail rebuild, per-tick data/index/canonical
  work, and physics unless new evidence disproves their existing zero/stable
  counters.

- [ ] **Step 2: Write the focused failing assertion.**
  Feed the real exact-local Avatar window that reproduces the unit into the
  production cache through its normal resource lane. Assert every measured
  contiguous unit is `<= 1000µs` and retain the full Avatar end-state
  assertions. On the baseline it must fail specifically at the named unit.

- [ ] **Step 3: Verify RED and capture baseline distribution.**
  Run the test and the strengthened profile. Preserve samples, missed-frame
  count/rate, build/raster/total-span, target latency stages, yields, layout
  reuse/new counts and slice maxima for the same cold/warm/mixed sequence.

### Task 3: Minimal proven cache-owner repair

**Files:**
- Modify only the exact source file/lines proven by Task 2 (expected owner:
  `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart`).
- Modify the Task 1/2 tests only for permanent assertions.

**Interfaces:**
- Retains `prepareWindow` API, immutable staged-bank handoff,
  `DashboardLiveInteractionResourceLane.budgetAvatarPreview`, cache
  cancellation/retention and existing checkpoint semantics.

- [ ] **Step 1: Implement one repair selected by the RED evidence.**
  If the source measurement shows a compound row-discovery tranche, split it
  into resumable bounded steps and call the existing `checkpoint` before the
  next unit only at the proven boundary. Do not alter input velocity, target
  sequence, publication timing, cache ownership, or TextPainter/scene
  correctness. If the evidence selects a different unit, change only that
  unit and revise this task's exact source span before editing.

- [ ] **Step 2: Verify focused GREEN.**
  Re-run the exact RED command. It must become green with all units at or
  below 1,000µs and with unchanged full target/publication/paint/settle and
  identity assertions.

- [ ] **Step 3: Verify repeated workload.**
  Re-run cold, warm and mixed production-parent stress. Require no missing
  final target, no pending candidate, no tick data/canonical work, no new
  owner, and at least a 30% missed-frame reduction for representative
  cold/mixed runs with no causal P95 regression. Treat emulator raster and
  physical-device raster as separate environments.

### Task 4: Regression, delivery and provenance

**Files:**
- Modify: `integration_test/dashboard_interaction_profile_test.dart`
- Modify: `integration_test/support/dashboard_profile_report.dart`
- Regenerate on tooling branch: `docs/codegraph/`

- [ ] **Step 1: Run focused cache, Avatar-Core, rail, correctness, direction
  no-regression, Time no-regression, budget presentation, fast suite,
  formatter and modified-file analyzer through Ubuntu proot.** Record every
  command as PASS, FAIL or NOT RUN with its exact result.

- [ ] **Step 2: Commit the atomic application repair.** Include the required
  physical source/APK evidence, frozen Drive sequence, proven owner, matching
  graph, rejected hypotheses, exact changed files and honest validation body.
  Do not modify the engineering journal.

- [ ] **Step 3: Push and deliver.** Verify remote SHA; monitor exact GitHub
  `test-flutter`, `test-core`, human diagnostic APK and strengthened A–K
  profile. Download the resulting normal `lib/main.dart` APK to
  `/storage/emulated/0/Download/fluvi`, verify file size/hash and embedded
  application SHA.

- [ ] **Step 4: Regenerate exact final SCIP.** On
  `tooling/scip-codegraph-v1`, generate the graph against the final app SHA,
  inspect manifest/source-parent/raw hash, commit and push only tooling/docs.

## Plan self-review

- **Spec coverage:** AFP-01 through AFP-11 map the runtime baseline, Drive
  evidence, graph impact, deterministic workload, causal correlation, RED,
  minimal repair, correctness, performance distribution, delivery and
  user-only validation to Tasks 1–4.
- **No-placeholders check:** Task 3 deliberately contains an evidence gate,
  not an unspecified repair: it forbids editing until Task 2 names the actual
  unit, then constrains the only permissible mechanism to the existing
  checkpoint owner.
- **Type/ownership consistency:** every task retains `prepareWindow`, the
  existing Avatar resource lane, Core candidate identity and cache checkpoint;
  no new API or state authority is introduced.

## Execution mode

The work is tightly coupled: the trace chooses the RED assertion and the RED
assertion chooses the repair. It will run inline with review checkpoints;
parallel implementation would create conflicting edits to the same cache,
Core and profile owners.

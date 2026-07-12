# Lifecycle Retention And Startup Stats Prewarm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the complete app state mounted across background/resume and finish Home plus Stats initialization under the single cold-start loading gate.

**Architecture:** After the first unlock, `SecurityGate` becomes a persistent overlay host instead of conditionally replacing its child, and `SecurityController` reserves blocking loading for first startup only. `ExptShell` owns a shared stats render cache/worker, prewarms the default expense and income frames after transaction bootstrap, mounts Home and Stats in an offstage retained stack, waits one render frame, and only then dismisses its cold-start overlay. An inactive retained `StatsPage` reacts to changed store data by prewarming its exact local targets without publishing visible loading state.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing `TransactionStore`, `StatsRenderFrameCache`, `StatsRenderFrameWorker`, Ubuntu proot Flutter commands.

## Global Constraints

- Do not run local Flutter APK builds in Termux; APK builds belong on GitHub Actions.
- Run local Flutter tests and analyze through Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Preserve all unrelated dirty worktree files.
- Every production behavior change requires a failing regression test first.
- Do not report the full retained-render package complete while checklist rows remain `PARTIAL` or `NOT DONE`.

---

## Files

- Modify: `lib/features/security/security_controller.dart`
  - Own first-load versus resume-refresh loading semantics.
- Modify: `lib/features/security/security_gate.dart`
  - Keep the child mounted and place loading/lock surfaces above it.
- Modify: `lib/features/settings/settings_page.dart`
  - Publish confirmed PIN/biometric setting changes to the long-lived security gate.
- Modify: `lib/exptv2_app.dart`
  - Own the security gate controller and forward the optional stats worker dependency for deterministic app-level tests.
- Modify: `test/security/security_gate_test.dart`
  - Prove delayed resume does not show a spinner, dispose child state, or override a successful unlock.
- Modify: `test/settings/settings_page_test.dart`
  - Prove a successful PIN change is published to the security gate callback.
- Create: `lib/features/stats/data/stats_render_prewarmer.dart`
  - Build/cache startup and retained inactive stats targets with in-flight deduplication.
- Modify: `lib/features/stats/data/stats_render_frame.dart`
  - Provide threshold-copy support for canonical cache publication.
- Modify: `lib/features/stats/data/stats_render_frame_worker.dart`
  - Produce cache keys from the same request object used by page and shell.
- Modify: `lib/features/stats/stats_page.dart`
  - Use request-derived keys and prewarm exact retained targets on inactive store updates.
- Modify: `lib/features/shell/expt_shell.dart`
  - Own shared stats dependencies, cold-start coordination, and retained offstage host.
- Modify: `test/shell/navigation_performance_test.dart`
  - Prove startup prewarm and first stats navigation issue no extra worker request.
- Modify: `test/widget_test.dart`
  - Inject the immediate stats worker through the app root instead of a production test-only static access.
- Modify: `test/stats/stats_page_test.dart`
  - Prove external data changes prewarm while Stats is inactive.
- Modify: `docs/superpowers/checklists/2026-07-12-retained-render-cache-checklist.md`
  - Record verified requirement statuses only after tests pass.

## Task 1: Retain SecurityGate Child Across Resume

**Interfaces:**

- Consumes: `SecurityController.start()`, `SecurityController.lockForResume()`.
- Produces: cold-only `loading`; persistent child element after first unlock; loading or lock overlay above retained content.

- [x] Add a widget test with PIN disabled and a delayed second `expenseLoadSettings` result. After pause/resume, assert no `CircularProgressIndicator`, the child remains visible, and its `dispose` callback has not run.
- [x] Run the test through Ubuntu proot and verify RED because current resume sets `loading=true` and replaces the child.
- [x] Add a non-blocking `_load(..., blocking: false)` path for resume. Build `SecurityGate` as a stable `Stack` that mounts the app after first unlock, retains it thereafter, and places the cold spinner or lock screen above it.
- [x] Re-run the focused security test and full `security_gate_test.dart`; expect PASS.

## Task 2: Shared Stats Target And Prewarmer

**Interfaces:**

- Consumes: `StatsRenderFrameRequest`, `StatsRenderFrameCache`, `StatsRenderFrameWorker`, transaction/category list identity.
- Produces: `StatsRenderFrameRequest.cacheKey({required Object dataRevision})`, `StatsRenderFrameKey.withThreshold(double)`, and `StatsRenderPrewarmer.prewarm(...)` with duplicate in-flight suppression.

- [x] Add shell test setup using a controlled worker and injected shared cache. Assert two default requests exist before Stats is tapped.
- [x] Run the focused shell test and verify RED because `ExptShell` has no injected worker/cache and Stats is lazy.
- [x] Add request-derived key construction and the prewarmer. Cache the requested key and canonical threshold key returned by the worker.
- [x] Add the shell-owned shared cache/worker and pass both into `StatsPage`.

## Task 3: One Cold Gate And Retained Home/Stats Host

**Interfaces:**

- Consumes: `TransactionStore.start()`, `StatsRenderPrewarmer.prewarm`, `_retainedTabPages`.
- Produces: `_initializeApp()`, `shell-cold-start-loading`, retained offstage Home/Stats pages, lazy retained Settings/Notifications pages.

- [x] Extend the shell test: keep the cold gate visible while worker futures are pending; complete both; assert Home and Stats are mounted with `skipOffstage: false`; tap Stats and assert request count does not increase and no stats pending surface appears.
- [x] Replace the page-controller host with a stable stack of retained tabs. `_RetainedShellTab` uses `Offstage`, `IgnorePointer`, `ExcludeSemantics`, and `TickerMode` while preserving its child state.
- [x] Await transaction bootstrap and both primary stats frames, mount Home plus Stats, await one frame, then remove the cold gate. On prewarm error, log and release the gate rather than deadlocking startup.
- [x] Re-run the focused shell test and navigation suite; expect PASS.

## Task 4: Invisible Recompute While Stats Is Inactive

**Interfaces:**

- Consumes: retained `StatsPage` store listener and local type/scope/threshold/filter state.
- Produces: inactive store updates prewarm current and opposite targets without `setState` or visible loading.

- [x] Add a controlled-worker stats test: warm both frames, disable `TickerMode`, merge a new external transaction, assert background requests for the new data revision, complete them, reactivate Stats, and assert no extra request or spinner.
- [x] Run the focused test and verify RED because `_handleStoreChanged()` currently returns immediately while inactive.
- [x] Generalize stats prewarm to accept current/opposite targets. Seed cache while inactive; publish only if the page becomes active and the target is still current.
- [x] Re-run the focused test and full stats page suite; expect PASS.

## Task 5: Verification, Checklist, Commit, And Build

### Race hardening added after independent review

- [x] Push confirmed security settings from `SettingsPage` through `ExptShell` to a long-lived `SecurityGateController`; prove the next delayed resume locks synchronously.
- [x] Add settings-load/authentication generations and disposal guards; prove a late refresh cannot override a successful unlock or notify after disposal.
- [x] Revalidate transaction/category/scope/date/filter inputs after startup prewarm and retry before releasing the cold gate when the data revision changed.
- [x] Retry the current visible Stats frame when an inactive prewarm fails after reactivation.
- [x] Run focused race tests, full security/settings suites, full shell suite, and full stats page suite through Ubuntu proot.

- [x] Run focused security, shell, stats frame, and stats page tests through Ubuntu proot.
- [x] Re-run the full Flutter test suite through Ubuntu proot after the final race-hardening changes (859/859 passed).
- [x] Run Flutter analyze through Ubuntu proot.
- [x] Re-read the acceptance checklist after final audit and change only proven rows to `DONE` or `PARTIAL`.
- [x] Inspect `git diff --check` and stage only files from this fix.
- [ ] Commit the staged fix and push the feature branch.
- [ ] Trigger the GitHub Android workflow, verify the run succeeds for the new commit, and download its APK to `/storage/emulated/0/Download/exptv2`.

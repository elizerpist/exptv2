# Mind Year realtime frame contract implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` task by task. Steps use checkbox syntax for tracking.

**Goal:** Make the existing accepted renderer-acknowledged Mind Year path demonstrably correct for every actually painted Summary Year without a settle-only fallback or hot-path work.

**Architecture:** Core remains the only temporal and Mind-frame authority. The segmented selector reports real Summary paint, Core validates the active interaction generation and installs a frame from bounded immutable prepared membership, and the existing viewport paints that frame. The terminal-settle lifecycle only retires obsolete authority; it must not bypass active transient publication.

**Tech Stack:** Flutter widget tests, existing `FluviDiagnosticLogger`, existing CoreDashboard/segmented Summary/Mind viewport, Ubuntu-proot Flutter, GitHub Actions and SCIP tooling.

## Global constraints

- No Time carousel/controller/ScrollPosition/physics modification without new evidence.
- No debounce, cooldown, target dropping, wait-for-settle, remount, key, cache flush, second Year authority, repository/Room/index build, source scan or scene/text work per transient Year.
- Every Summary Year actually painted must have the same Mind identity in that transition and annual paint in the next frame at latest.
- Coalesced-before-paint targets do not require a Mind publication.
- Existing held-slider identity and stale rejection remain intact.

### Task 1: Establish the frame-by-frame production-parent contract

**Files:**

- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify: `docs/superpowers/checklists/2026-09-16-mind-year-retained-target-lifecycle-repair.md`

- [x] Write `MYRT-01` with four distinct annual fixtures, real CoreDashboard, segmented selector and annual viewport. Record each Summary-painted Year/G from `SUMMARY_TARGET_PAINTED`, assert the same Mind identity immediately, pump exactly one frame, then assert `MIND_HEATMAP|PAINTED` with the same Year/G.
- [x] Run only `MYRT-01` before any production mutation. The existing active publication was already green, so no artificial RED or speculative runtime mutation was made.
- [x] Extend the test with coalesced and terminal-refresh checks: `MYRT-02` rejects any transient Mind paint whose Year was not actually Summary-painted; `MYRT-01` proves terminal 2023 remains canonical through a real refresh.
- [x] Run the focused test again and mark MYRT-01/MYRT-02 factually.

### Task 2: Preserve adjacent lifecycle and work bounds

**Files:**

- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

- [x] Write a held-slider assertion against the last actual visible transient Year/G, then end/settle and verify canonical ownership.
- [x] In the same mounted interaction assert repository prepare count, index-build/canonical-apply diagnostics, source-row touches and scene/text preparation counters remain zero for each transient Year.
- [x] Run the new cases with `MYTP-01` and `MYRL-01` as part of the 77-test full Core ephemeral-focus matrix; no failure occurred.

### Task 3: Make only a source-proven repair if a new RED exposes one

**Files:**

- Potentially modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Potentially modify: the direct mounted regression test from Tasks 1–2

- [x] Use graph/source/log evidence to name the retained-target lifecycle owner of the earlier stale-resurrection defect.
- [x] `MYRL-01` was RED on the unpatched production parent (`Expected: 2025`, `Actual: 2027`) and GREEN after the narrow existing Core repair.
- [x] Preserve UI render-only boundaries, existing Time mechanism and bounded prepared membership; the realtime tests found no additional failing publication owner, so no speculative runtime change was made.
- [x] Re-run the exact RED/GREEN and focused Mind/Time/slider matrices.

### Task 4: Performance, delivery and provenance

**Files:**

- Modify only if new factual evidence requires it: `docs/FLUVI_ENGINEERING_JOURNAL.md`
- Tooling graph worktree: `/data/data/com.termux/files/usr/tmp/fluvi-scip-codegraph-v1`

- [x] Inspect the exact Actions run for the application SHA, including dashboard-profile body; it fails because `frame_timing_headroom` is null, and no threshold was weakened.
- [x] The existing verified application change is pushed; its normal human APK is downloaded to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_31f2f14.apk` with SHA-256 `40b0517da28f48f6faf185ced264d12ccd7b3537ee5a624b03bcb0b44fc5edff`.
- [ ] Regenerate SCIP for the final application SHA, record manifest source head/hash/counts, and append factual journal evidence in a separate `[skip ci]` commit after every application commit.
- [ ] Leave physical acceptance as `PENDING — USER ONLY`.

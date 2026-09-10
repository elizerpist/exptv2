# Direction-switch Hitch and Month Limit-Circle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the physically accepted `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` performance floor while proving and repairing the localized direction-switch hitch and the selected-target month limit-circle paint failure.

**Architecture:** The existing `TransactionDirectionController` remains the one direction authority; `DashboardCoreController` remains the workflow and visible-publication owner. `DashboardBudgetPresentationController` remains the sole financial limit-model authority, and the existing selected-avatar `AnimatedBuilder → CustomPaint` chain remains the only circle renderer. Diagnostics must observe those boundaries without adding state, cache, controller, delay, or an Avatar/Time behavior path.

**Tech Stack:** Flutter/Dart, `flutter_test`, production diagnostic logger, `FrameTiming`, GitHub Actions Android diagnostic APK.

## Global Constraints

- Physically accepted application source: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`; journal-only descendant: `6b838866ef5f6170de292489a7fe59fd2263228f`.
- Do not modify `docs/FLUVI_ENGINEERING_JOURNAL.md`.
- No Avatar or Time controller/position/physics/geometry/z-order/cache alteration unless a surviving-final-target defect is independently proven.
- Do not add a controller, store, cache, financial authority, synthetic Avatar movement, debounce, cooldown, delayed repaint, placeholder, or broad rebuild.
- Graph provenance begins `GRAPH STALE/UNAVAILABLE FOR TESTED HEAD`; graph is never runtime causality evidence.
- Production application changes require a red test first, exact validation evidence, push, GitHub human APK, and physical validation remains user-only.

## Acceptance Checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| P-01 | User task §3–4 | `MILESTONE_COMMITS.md` | `6e962…` is the preferred, physically accepted floor; two defects are open issues, not accepted behaviour | review diff | NOT DONE |
| D-01 | User task §10, §13 | Core direction path | Input through paint boundaries have ordered, bounded diagnostics in cold/warm, both directions | targeted profile trace + tests | NOT DONE |
| D-02 | User task §13–15 | Existing direction owner | Correct final direction/query/Header/Summary/LogBox/Budget without stale final candidate and with the proven hitch boundary removed | production-parent tests + profile | NOT DONE |
| M-01 | User task §10, §13 | Budget model → selected chrome | Month A → B retains target X and produces B's exact model/key | controller test | NOT DONE |
| M-02 | User task §13–14 | selected-avatar renderer | B's selected circle is built and painted without an Avatar event | widget/render acknowledgement test | NOT DONE |
| G-01 | User task §11, §15 | Avatar/Time | Existing Avatar/Time motion invariants remain unchanged | protected tests + diff + profile trace | NOT DONE |
| G-02 | User task §19 | tooling | Final matching SCIP graph, or explicit unavailable status | manifest/source-head check | NOT DONE |

## Architecture Card

- **Direction state owner/write path:** `DashboardCoreController.selectDirection` → `TransactionDirectionController.select` → `DashboardLiveInteractionCoordinator.accept` → existing scene-covered navigation commit.
- **Month state owner/write path:** `DashboardNavigationController._publish` (via Core temporal intent) → `DashboardLiveInteractionCoordinator.accept` → `DashboardBudgetPresentationController._publishHeaderOnly`.
- **Limit model owner:** `DashboardBudgetPresentationController._liveSelectionFor`, using the prepared limit snapshot and `DashboardBudgetPeriodResolver`; no repository read occurs on the hot path.
- **Circle renderer:** `BudgetTargetAvatarRail` passes the existing presentation listenable to `BudgetCategoryAvatarArtwork`; its selected chrome uses `AnimatedBuilder`, `RepaintBoundary`, and `_SelectionChromePainter`.
- **Reuse decision:** Extend the existing diagnostic logger and owner callbacks only. No second measurement or state machine is permitted.
- **Evidence:** controller and production-parent tests; selected chrome widget/paint test; protected Avatar/Time tests; profile diagnostics and Android screenshot/physical APK check.

### Task 1: Preserve the milestone and frozen evidence

**Files:**
- Modify: `MILESTONE_COMMITS.md:1`
- Add: `docs/superpowers/evidence/2026-09-10-direction-month-repair/*`
- Test: Git ancestry/hash inspection only

- [ ] Add the `6e962…` milestone above e8, identify its parent, APK marker, accepted motion, rollback policy, and the two explicitly open defects.
- [ ] Keep the two Drive snapshots immutable and record their current export metadata, session ranges, deduplication result, retention, and hash in the forensics commit.
- [ ] Verify only expected documentation/evidence paths changed.
- [ ] Commit documentation/forensics independently; do not include application code.

### Task 2: Direction reproducer and bounded trace

**Files:**
- Modify: `test/features/dashboard/application/dashboard_scene_window_rotation_test.dart`
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart` only if the existing production-parent harness is required
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart` only after a failing diagnostic-order assertion identifies a missing boundary

**Consumes:** Existing `DashboardCoreController.selectDirection`, visible-frame store and presentation controller.

**Produces:** One existing-owner diagnostic sequence from input request through semantic acceptance, visible publication, Budget bind, build/paint/raster acknowledgement.

- [ ] Write a production-parent test that drives expense → income and asserts final direction, query, visible frame, Header, Summary, LogBox, and Budget state with no pending final candidate.
- [ ] Run the focused test in Ubuntu/proot and record its expected failing assertion if the required transition evidence is absent.
- [ ] Add only the missing diagnostics at the existing boundary; include identity, generation and monotonic timestamps, but no mutation or asynchronous work.
- [ ] Add cold/warm, aggregate/category, and 20 alternating-cycle coverage using the same production harness.
- [ ] Run focused tests and capture profile diagnostics to identify the first delayed boundary before any behavioral change.

### Task 3: Month-circle production-parent red test and trace

**Files:**
- Modify: `test/features/dashboard/application/dashboard_budget_presentation_controller_test.dart`
- Modify: `test/features/dashboard/presentation/budget_category_avatar_rail_test.dart`
- Modify: `lib/features/dashboard/application/dashboard_budget_presentation_controller.dart` only if source-of-truth evidence is missing
- Modify: `lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart` only if existing paint acknowledgement lacks period/model identity

**Consumes:** existing live temporal interaction, Budget presentation, selected-avatar listenable, and paint callback.

**Produces:** A testable `month B + target X + FinancialLimitKey B` model/build/paint identity chain.

- [ ] Write a controller test: select target X with nonzero January visual; accept February only; assert target unchanged and February numerator, denominator, period/key, and visual differ as expected.
- [ ] Write a selected-chrome widget test with the production presentation listenable: change only month; assert painter callback receives exactly B's visual and no Avatar selection callback occurred.
- [ ] Run both tests on the unmodified application baseline and confirm the real failure is the reported contract, rather than an invalid fixture.
- [ ] Add bounded existing-owner diagnostics only where the test proves an opaque identity boundary.
- [ ] Identify the first divergence among accepted month, selected target, limit key, presentation notification, widget build, and paint acknowledgement.

### Task 4: Minimal root-cause repairs

**Files:** Exactly the owner file identified by Tasks 2–3 and the corresponding focused tests.

- [ ] State one root-cause hypothesis per defect, with the failing boundary and rejected alternatives.
- [ ] For each defect, write/retain its failing test first and run it red.
- [ ] Implement the smallest state-preserving repair at the proven owner; do not alter protected motion or create a new owner.
- [ ] Re-run that focused test green before changing anything else.
- [ ] Make atomic commits: direction repair and month-circle repair are separate unless the trace proves one shared owner and one atomic invariant.

### Task 5: Regression, delivery, and graph provenance

**Files:** tests and CI metadata only as needed; no journal edit.

- [ ] Run formatting, focused defects, Avatar protected tests, Time protected tests, presentation tests, boundary checks, and analyzer in Ubuntu/proot.
- [ ] Compare before/after profile diagnostics for direction and month boundaries; confirm no new Avatar/Time per-tick work and no changed controller/physics identity.
- [ ] Push application commits; monitor the exact SHA's GitHub human diagnostic APK; download it to `/storage/emulated/0/Download/fluvi`; report size and SHA-256.
- [ ] Generate matching SCIP in its separate tooling workflow or report `GRAPH STALE/UNAVAILABLE FOR FINAL HEAD`.
- [ ] Report physical validation as `PENDING — USER ONLY`.

## Plan Self-Review

- The two defects are deliberately separate until tracing proves a shared upstream authority.
- The plan maps every behavioral change to an existing owner and a red test.
- No task permits a physics, cache, visual-layout, or journal workaround.
- No task contains a placeholder implementation or a broad optimization pass.

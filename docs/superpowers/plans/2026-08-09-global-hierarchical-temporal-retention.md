# Global Hierarchical Temporal Retention Implementation Plan

> **For agentic workers:** execute inline with TDD checkpoints.

**Goal:** Retain the exact current rail preview into the one global temporal
anchor only when an open rail is structurally exited.

**Architecture:** `DashboardTemporalAnchor` remains the single Y-M-D source of
truth. `DashboardPresentationController` validates the current immutable
preview frame, calls the existing `DashboardNavigationController.retainChild`
primitive with an explicit structural-exit reason, then performs the existing
structural action. Semantic crossings remain presentation-only.

**Constraints:** no RailCriticalSceneBank, physics, paging, seed, scene-window,
threshold, cooldown, async, or golden-test changes.

### Task 1: Establish executable structural-exit regressions

- [ ] Extend `test/features/dashboard/runtime/dashboard_presentation_controller_test.dart`
  with SUM→YEAR, YEAR→MONTH, MONTH→DAY, stale-preview, no-fake-settle and
  identity assertions. Run them on `983ca2a` and record the expected old-anchor
  failure.

### Task 2: Capture valid previews at structural-exit boundaries

- [ ] Add `structuralRailExit` retention reasons in the temporal-navigation
  controller/domain.
- [ ] Add a synchronous, validated structural-exit capture operation in the
  presentation controller and invoke it before `setRailOpen(false)` and plane
  transitions that leave an open rail. Emit one bounded diagnostic only.
- [ ] Run the focused controller/time-navigation tests until green.

### Task 3: Verify regression boundaries and commit

- [ ] Run carousel/kernel, first-gesture takeover, stale-session, rebuild,
  analyze, and `scripts/test-fluvi-fast.sh`.
- [ ] Update I16 ownership in `docs/dashboard-test-coverage-audit.md` and
  commit only the focused correctness change as
  `fix: retain visible temporal child across structural navigation`.

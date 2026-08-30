# Performance Milestone + Final Two-Blocker Forensic Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the accepted dashboard interaction baseline, then prove and
repair only the intermediate-collapse gray slab and the Mind amount-range
lifecycle.

**Architecture:** `DashboardAppliedQueryFacetLoader` and
`CurrentQueryController` remain the one Query/domain authority; Mind may only
render their immutable binding. Budget composition keeps physical card surface
ownership separate from viewport clipping. Diagnostics remain debug-only and
are coalesced by semantic boundary, not physical frame.

**Tech Stack:** Flutter/Dart, current Dashboard controllers, widget/raster
tests, `FluviDiagnosticLogger`, Android physical diagnostics.

## Global Constraints

- Checkpoint `dfa90b6741108f824244dbc11a3d73a6c5174472` is immutable and the
  user-accepted performance baseline.
- Do not change fling physics, global cache/warmup policy, Header visual
  material, or a shared Query state without a proven dependency from CS or MR.
- No Android APK build/push before every active acceptance row is `DONE`.
- Use a failing production-owner regression before production code; retain
  exact physical/device evidence separately from automated proof.

---

### Task 1: Coalesce diagnostic traffic without losing capture authority

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify: `lib/core/diagnostics/fluvi_diagnostic_logger.dart` only if a neutral
  reusable coalescer is needed
- Test: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Test: `test/core/diagnostics/fluvi_diagnostic_logger_test.dart`

**Interfaces:**
- Consumes the retained Header backend/session state and current collapse
  geometry.
- Produces sparse `COLLAPSE|...`, Header session, and unchanged 2,000-entry
  diagnostic retention behavior.

- [x] Write a red test that changes only Header size within one collapse bucket
  and asserts that fidelity/touch records are not repeated; change bucket or
  render backend and assert one new record.
- [x] Run the isolated test and observe its expected pre-change failure.
- [x] Add the smallest session/bucket signature owner; do not format an event
  string on an unchanged vsync.
- [x] Re-run the test and existing FIFO logger tests.
- [ ] Commit this diagnostic-only change separately after `flutter analyze`
  and `git diff --check`.

### Task 2: Prove the intermediate collapse pixel owner

**Files:**
- Inspect/modify only after evidence: `core_dashboard.dart`,
  `budget_dashboard_core_surface.dart`, `budget_distribution_pager.dart`,
  `budget_distribution_page_surface.dart`,
  `budget_partner_distribution_card.dart`, `spending_rhythm_bar_chart.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Test: `test/features/dashboard/presentation/budget_distribution_pager_test.dart`

**Interfaces:**
- Consumes authoritative `DashboardCoreModePresentation` collapse geometry and
  one existing Budget surface owner.
- Produces bounded `COLLAPSE|...` / `CHART|...` owner facts and, only after
  proof, one correctly clipped/transformed physical composition.

- [x] Extend a production-parent intermediate-progress test (0.20, 0.50,
  0.75 and reversal) to assert the suspected owner’s exact geometry once the
  probe identifies it; do not write a color-mask test.
- [x] Run it against the current checkpoint and record whether it exposes a
  structural failure; if no deterministic pixel reproduction exists, retain a
  debug-only owner probe rather than guessing.
- [ ] Capture slow/fast/reverse Android evidence, identify one owner, then add
  the narrow failing regression matching that owner.
- [ ] Implement one structural owner fix, re-run intermediate and full Budget
  composition tests, then repeat the device matrix.

### Task 3: Trace Mind request-to-visible lifecycle

**Files:**
- Modify: `lib/features/dashboard/query/application/dashboard_applied_query_facet_loader.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Test: `test/features/dashboard/query/application/dashboard_applied_query_facet_loader_test.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`

**Interfaces:**
- Consumes one exact `CurrentLedgerQueryScope`, active direction, Query
  generation and repository result.
- Produces a diagnostic lifecycle with request/cache/result/reject/publish,
  then render gate/mount/layout/visible facts; it does not introduce a Mind
  domain cache or a copied slider.

- [ ] Write a red lifecycle test for every completed request terminal state
  (ready, stale rejection, failure) and assert a visible canonical state or
  explicit error—not eternal loading.
- [ ] Run the test and observe the pre-change failure.
- [ ] Add bounded `MIND|RANGE_*` and `MIND|SLIDER_*` events at component
  boundaries, with exact generation/scope/rejection reasons and layout data.
- [ ] Re-run cold, warm, direction/scope replacement and rapid re-entry tests.
- [ ] Use a device dump to classify the broken pipeline edge before any
  functional repair.

### Task 4: Repair only proven owner and close evidence

**Files:** exact source/test files established by Tasks 2–3.

- [ ] Create the failing regression for the proven gray-pixel owner or Mind
  lifecycle edge.
- [ ] Make one minimal source repair with no timeout, opacity mask, stale
  fallback, controller recreation, or physics retune.
- [ ] Run exact regression, affected suite, analyzer in Ubuntu proot, and
  `git diff --check`.
- [ ] Compare current bounded counters and user physical interaction baseline.
- [ ] Re-read the acceptance checklist. Only after every row is `DONE` may a
  normal GitHub Actions Android build be pushed, monitored, and downloaded.

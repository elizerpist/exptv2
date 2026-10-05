# Budget Secondary Analysis Implementation Plan

> **For agentic workers:** Execute inline because the pure frame contract,
> drawable-bank integration, pager transition and production surface have one
> coupled publication identity. Delegating them would create conflicting edits
> around the same controller and cache boundary.

**Goal:** Add the reference-faithful SUM/YEAR/MONTH/DAY Budget Analysis page to
the existing infinite Budget content pager and complete the interrupted cyan
FAB repair in one application delivery.

**Architecture:** A pure, typed projector turns the existing exact-revision
`PreparedBudgetLimitSnapshot` into a category/aggregate-specific immutable
analysis payload. The existing drawable controller caches and publishes that
payload beside Category and Partner visuals. The persistent pager changes only
its semantic modulo domain from two to three pages; a leaf card renders the
prepared payload without data access or financial calculations.

**Tech Stack:** Flutter, `package:flutter_test`, existing native prepared
Budget snapshot, existing `ValueListenable` publication and PageView stack.

## Global constraints

- Read and use `/storage/emulated/0/spendee/source of truth/budgetall.png` as
  the visual source of truth.
- Preserve the current worktree and its uncommitted FVP-08 repair.
- Use the Ubuntu-proot Flutter tool for tests and analyzer; do not build an APK
  locally on Termux.
- Do not add repository/database access, a route, a modal, a second selector,
  nested pager, a PageController, a ScrollPosition, or financial aggregation to
  a widget build/paint/gesture path.
- Use project formatters/tokens and existing bounded preparation facilities.

### Task 1: Close the interrupted FAB correction

**Files:**
- Modify: `lib/core/design/fluvi_global_appearance.dart`
- Modify: `lib/app/shell/bnb03_bottom_navigation.dart`
- Modify: `test/app/bnb03_bottom_navigation_test.dart`
- Modify: `docs/superpowers/plans/2026-10-05-fab-vector-presentations.md`

- [ ] Add a failing test that resolves the full-vector cyan from one semantic
  visual source and keeps the shell/ring/core contract.
- [ ] Observe RED against the pre-correction palette.
- [ ] Move the sampled `#06B6D4` / highlight pair to the global semantic
  appearance/token source and have the FAB consume it.
- [ ] Regenerate and open the one full-vector golden, then run the complete
  BNB test file and focused appearance/tuner tests.
- [ ] Mark FVP-08 only after all its evidence is green.

### Task 2: Define and prove the pure secondary-analysis contract

**Files:**
- Create: `lib/features/dashboard/application/dashboard_budget_secondary_analysis.dart`
- Create: `test/features/dashboard/application/dashboard_budget_secondary_analysis_test.dart`
- Modify: boundary-contract test location discovered from current Budget tests.

**Interfaces:**
- Consumes: `PreparedBudgetLimitSnapshot`, `LedgerDirection`,
  `LedgerTimeScope`, `DashboardBudgetTarget`, `LocalDate`.
- Produces: immutable `DashboardBudgetSecondaryAnalysisFrame` with one sealed
  SUM/YEAR/MONTH/DAY payload and canonical identity fields.

- [ ] Write RED tests for target isolation, completed-month eligibility,
  equal-weight utilization, signed delta, year bars, 28–31-day forecast,
  before/after room, historical/future/unavailable states, and last-day
  division safety.
- [ ] Run the isolated test file and confirm absence-of-projector failures.
- [ ] Implement integer-only money arithmetic and explicit calendar-policy
  helpers in the new application file; do not import Flutter.
- [ ] Re-run until GREEN, then add a structural test that presentation files
  cannot import repositories or the projector cannot import Flutter.

### Task 3: Extend the one prepared drawable bank and hotset

**Files:**
- Modify: `budget_category_distribution_visual_bank.dart`
- Modify: Budget scope publication wiring in
  `dashboard_header_visual_engine.dart` / `dashboard_core_controller.dart`
  only where the existing drawable preparation contract requires it.
- Test: existing Budget drawable/controller tests plus a focused analysis-bank
  cache test.

- [ ] Write RED tests proving a drawable frame retains an analysis bank whose
  selected payload has the same revision/direction/target/scope identity.
- [ ] Add the prepared analysis bank to
  `DashboardBudgetDistributionDrawableFrame`, built only during existing
  foreground/maintenance preparation.
- [ ] Extend the existing bounded current/previous/next target prewarm path;
  assert cache hits do not rebuild analysis during paint, avatar crossing or
  scope selection.
- [ ] Run focused controller tests GREEN and retain diagnostics/counters for
  source builds, cache hits and hotset promotions.

### Task 4: Turn the existing two-page domain into the three-page domain

**Files:**
- Modify: `budget_distribution_pager.dart`
- Modify: `budget_dashboard_core_surface.dart`
- Create: `budget_secondary_analysis_card.dart`
- Create: `test/features/dashboard/presentation/core_modes/budget_secondary_analysis_card_test.dart`
- Modify: existing pager/core-surface widget tests.

- [ ] Write RED pager tests for Category → Partner → Analysis → Category,
  reverse traversal, modulo-three idle rebase, and stable PageController and
  ScrollPosition identities.
- [ ] Change the semantic resolver and rebase remainder to three while keeping
  the one existing `PageView.builder` and controller instance.
- [ ] Write RED production-surface tests for all four scopes and their
  required hero structures.
- [ ] Implement a leaf card that receives only the immutable prepared payload:
  one SUM semicircle; YEAR zero-axis bars; two MONTH semicircles; two DAY
  before/after blocks plus arrow; one equal-weight three-KPI row in every
  mode.
- [ ] Add a single short card-local transition authority only after prepared
  data is available; do not create per-bar controllers or a loading placeholder.
- [ ] Run widget tests GREEN, including target-switch atomicity and no overflow
  / Flutter exceptions.

### Task 5: Verify reference fidelity, regression, performance and delivery

**Files:**
- Modify: acceptance checklist and engineering journal with factual outcomes.
- Test: targeted Budget, pager, FAB, analyzer, relevant repository suite.

- [ ] Capture production-card screenshots for SUM/YEAR/MONTH/DAY at the
  reference card dimensions, open them with `budgetall.png`, and record actual
  geometry differences before any golden update.
- [ ] Run the focused hot-path counter test for horizontal pager, avatar
  crossing and scope switching; verify zero repository/query/index/controller
  work during gesture/render paths.
- [ ] Run formatter, targeted tests, static analysis and relevant non-golden
  regression suites inside Ubuntu proot.
- [ ] Re-read every checklist row and source reference, record only verified
  DONE states, make one application commit, push `3d-linechart`, monitor the
  exact SHA’s Human Diagnostic APK, download it to
  `/storage/emulated/0/Download/fluvi`, and record SHA-256.

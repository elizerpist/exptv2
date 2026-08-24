# SummaryPill ballistic-primary-controls implementation plan

> **Historical plan.** This plan delivered `92b73600`; its primary-control
> experiment is no longer the reference implementation. Do not use its
> settle-only publication lifecycle as an architectural template. The current
> runtime comparison and acceptance checklist live in
> `../specs/2026-08-24-selectable-summary-pill-experiments-design.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the temporary Ledger amount and prototype vertical-axis plus horizontal-mother ballistic controls without changing the current temporal model or dashboard shell geometry.

**Architecture:** `DashboardLayoutMetrics` remains the Ledger fixed-header source. The shared `CenteredCarousel` gains orientation support, while `DashboardNavigationController` remains the one canonical selection owner and `DashboardCoreController` retains readiness-gated commits.

**Tech Stack:** Flutter, existing `CenteredCarouselController` / `CenterSnapScrollPhysics`, Flutter widget tests.

## Global Constraints

- Keep `SUM`, `YEAR`, and `MONTH` only; keep current mother--child and child rail.
- Do not create a second time/query state, fling engine, Ledger scroll owner, or fixed SummaryPill height state.
- Use Ubuntu-proot Flutter for tests/analyze; build the human APK only in GitHub Actions after push.
- Preserve the protected prepared-query, immutable-virtual-geometry, and first-fling boundaries in `MILESTONE_COMMITS.md`.

---

### Task 1: Red tests for reduced Ledger chrome and orientation-capable carousel

**Files:**
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`

- [x] Assert the header token sum is `top inset + count + gap + SearchPill + list gap`, the reference header is 96 px, and the resulting first scroll lane starts from that extent.
- [x] Assert the standalone amount key is absent while the SummaryPill amount, count, and SearchPill remain.
- [x] Add a vertical `CenteredCarousel` fling test that settles a valid multi-item target without affecting the existing horizontal test host.
- [x] Run the four focused tests and observe failure because production still has the amount lane and carousel is horizontal-only.

### Task 2: Implement the real Ledger header reduction

**Files:**
- Modify: `lib/core/design/dashboard_layout_metrics.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`

- [x] Remove only the amount slot/token/style; retain the source-bound count and independently surfaced SearchPill.
- [x] Set the central header metric to the real sum of its remaining tokenized rows and retain the existing resolver origin and LogBox viewport derivation.
- [x] Run the Task 1 Ledger-focused tests green.

### Task 3: Generalize the accepted carousel and expose canonical settled targets

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Modify: `lib/features/dashboard/runtime/application/dashboard_presentation_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`
- Test: `test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart`

- [x] Add axis-aware centered layout/hit calculations with horizontal as the unchanged default.
- [x] Add canonical direct plane and relative parent target candidates, then route a settled target through the existing core readiness-gated publication path.
- [x] Assert a high-velocity valid target is one canonical commit and SUM produces no parent target.
- [x] Run shared-carousel and time-navigation tests green.

### Task 4: Compose the two bounded SummaryPill zones

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/summary_pill_primary_controls.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_mode_navigation_test.dart`

- [x] Add tests first for distinct axis/mother keys, separator, axis-only vertical fling, mother-only horizontal fling, SUM no-op, semantics, and an unchanged chevron/child-rail path including live rail-tick feedback.
- [x] Replace the old whole-pill primary navigation detector with the two bounded centered-carousel adapters; retain the outer bounds, prepared amount, and chevron.
- [x] Ensure one settle invokes only its own semantic callback and no preview writes canonical state.
- [x] Run SummaryPill/navigation tests green.

### Task 5: Boundary/regression verification and documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-08-24-logbox-ledger-result-search-design.md`
- Modify: `docs/superpowers/specs/2026-08-24-summary-ballistic-prototype-design.md`
- Modify: `docs/superpowers/plans/2026-08-24-summary-ballistic-prototype.md`
- Test: `test/boundary/centered_carousel_boundary_test.dart` if its source contract needs the new shared orientation field

- [x] Run focused and protected dashboard/LogBox/rail/query suites plus `flutter analyze` inside Ubuntu proot.
- [x] Inspect changed endpoint widgets at expanded/collapsed and narrow/text-scaled test surfaces; do not claim physical feel from automation.
- [x] Update the Ledger record to say the result amount is withdrawn, and record this as a retained-mother-child experimental primary-control iteration.
- [x] Re-read the acceptance table and mark only verified items `DONE` before the production commit.

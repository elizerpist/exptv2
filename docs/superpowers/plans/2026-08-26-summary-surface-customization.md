# Summary Surface Customization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Narrow the SummaryPill comparison to Legacy and Segmented, make Segmented hierarchy fields independently cyclic, and add live presentation-only Card2 and roundness controls.

**Architecture:** Preserve canonical temporal/query and protected LogBox ownership. Extend the existing dashboard-lifetime presentation boundary with two small `ValueNotifier` controllers; resolve all roundness in one central profile before passing the result to existing shape leaves. The Segmented adapter requests a component-local candidate from the existing navigation controller, while Legacy retains its general parent-navigation behavior.

**Tech Stack:** Flutter/Dart, `ValueNotifier`, existing `CenteredCarousel`, custom-painted LogBox, repository-native widget/controller tests.

## Global Constraints

- No Swipe Mode runtime enum/member, renderer, tuner option, or test path remains.
- Default roundness must be pixel-identical to current `70589bf3` output.
- No database, nested vertical scroll owner, per-frame query/formatting, or TextPainter creation in LogBox paint.
- Do not alter Legacy rail, previous Budget preview amount bridge, body-order geometry, reclaimed segmented geometry, or SearchPill.
- Run Flutter tools inside Ubuntu proot; normal APK verification is GitHub Actions only.

---

### Task 1: Lock the two-variant catalog and independent temporal policy

**Files:**
- Modify: `lib/features/dashboard/presentation/summary_pill_variant.dart`
- Modify: `lib/features/dashboard/presentation/widgets/summary_pill_experiments.dart`
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Test: `test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart`
- Test: `test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart`

**Interfaces:**
- Produces `segmentedTemporalComponentOffsetCandidate(...)`, which returns an availability-aware canonical `DashboardNavigationState?` with no cross-field carry.
- The existing general `temporalComponentOffsetCandidate(...)` remains available for any non-Segmented client.

- [x] Write controller/widget tests for exactly two variants, month/day wrap, availability restrictions, validity normalization and single-field callbacks.
- [x] Run the focused tests and observe expected failures for missing two-variant catalog and independent policy.
- [x] Implement the minimal enum/host/widget removal and segmented candidate policy.
- [x] Re-run focused tests and protected rail/experimental prepared-selection suites.

### Task 2: Add presentation-only Card2 surface ownership

**Files:**
- Create: `lib/features/dashboard/presentation/budget_content_card_style.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_pager.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart`
- Test: `test/features/dashboard/presentation/budget_distribution_pager_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

**Interfaces:**
- `BudgetContentCardStyleController` owns only `bool showCardSurface`, default `true`.
- `BudgetDistributionPageCard(showCardSurface: ...)` preserves its child constraint/padding envelope in both styles.

- [x] Write failing ON/OFF and controller-identity tests for both category and partner pages.
- [x] Run focused tests and confirm current Card2 cannot represent OFF.
- [x] Thread the one controller from CoreDashboard through tuner/host/pager and make the shell decoration conditional without duplicating children.
- [x] Re-run tests plus Budget selection/focus/pager regressions.

### Task 3: Centralize global roundness and propagate it safely

**Files:**
- Create: `lib/core/design/dashboard_corner_profile.dart`
- Create: `lib/features/dashboard/presentation/dashboard_corner_roundness.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Modify: `lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: `lib/features/dashboard/presentation/widgets/summary_pill_experiments.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`
- Modify: LogBox render/painter style input discovered during source audit
- Test: `test/core/design/dashboard_corner_profile_test.dart`
- Test: affected header, direction, summary, LogBox and viewport-boundary suites

**Interfaces:**
- `DashboardCornerRoundnessController` owns only a normalized stepped scalar, default `0`.
- `DashboardCornerProfile` maps semantic surface family plus actual bounds to a safe `BorderRadius`/paint radius.

- [x] Write failing profile baseline/monotonic/safety tests and header-clip/shared-radius, shell/card/search/LogBox propagation tests.
- [x] Run them and confirm the profile/controller does not exist.
- [x] Implement the central resolver and the smallest leaf listeners/paint-style input; preserve exact baseline radii.
- [x] Re-run focused presentation, LogBox scene/viewport and body-order geometry suites.

### Task 4: Documentation, review and delivery

**Files:**
- Modify: `docs/superpowers/specs/2026-08-24-selectable-summary-pill-experiments-design.md`
- Modify: `docs/superpowers/checklists/2026-08-26-summary-surface-customization.md`
- Modify only if convention supports it: `MILESTONE_COMMITS.md`

- [x] Reconcile documentation with active two-variant status and presentation-only controls.
- [x] Run the required targeted suite and analyzer inside Ubuntu proot.
- [ ] Inspect screenshot/reference evidence and final diff; request a final code review.
- [ ] Commit once, push, monitor the exact GitHub Actions human APK workflow, download the normal diagnostic APK and record SHA-256.

## Plan self-review

Coverage: CAT, SEG, CARD, RND, PRS, REG, DOC and DEL requirements from the
acceptance checklist map to Tasks 1–4. The plan does not change protected
business/query/scroll ownership, and each production task starts with a failing
test. No open placeholders or undefined interfaces remain.

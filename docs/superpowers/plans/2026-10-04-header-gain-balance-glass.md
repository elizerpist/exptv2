# Header gain and Balance glass presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to execute this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Preserve the current dashboard while making the Header selector exactly half as sensitive and delivering one configurable, expandable-only Balance glass bar system.

**Architecture:** `DashboardHeaderModeSelector` remains the only physical owner of Header mode selection and receives a local transformed-drag adapter; the shared carousel motor remains unchanged. `BalancePresentationSettings` remains the only Balance presentation source of truth, with `DashboardPresentationPreferences`/the MethodChannel as its existing persistence path. A renderer-neutral bar owns ratio and geometry; isolated renderer adapters own material only.

**Tech Stack:** Flutter, existing `CenteredCarousel`, SharedPreferences MethodChannel, `BackdropFilter`, `glass_kit`, `glassmorphism`, `flutter_glass_ui_kit`, and `liquid_glass_widgets`.

## Global Constraints

- Development parent is `9035189a2f037b22b5bb92c344d890dcf96c9f50`; runtime parent is `271445da17345576ba56a5b1590ece9bee554c22`.
- Never use `67c2b484...` or `766710ea...` as a new work base.
- Do not modify shared centered-carousel source or `timeRefinementRail`.
- No repository, Query, prepared-index, amount-range or financial-membership work may enter any changed direct-manipulation/render path.
- Only expanded Balance headers may mount a chart/bar/renderer; collapsed headers mount none.
- Preserve user-provided untracked `test/**/failures/` material.
- Final Android APK delivery is an online GitHub Action artifact downloaded to `/storage/emulated/0/Download/fluvi`.

## Architecture card

| Concern | Single owner | Change | Verification |
| --- | --- | --- | --- |
| Header input gain | `DashboardHeaderModeSelector` + its existing carousel position | Scale drag delta and release velocity by a local `0.5` adapter only. | In-progress first/second boundary and immediate-publication tests. |
| Header motion | Shared `CenteredCarousel`/`timeRefinementRail` | No source/configuration change. | Protected carousel, Summary and Avatar tests plus diff check. |
| Balance visual state | `BalancePresentationSettings` / controller | Add serializable bar/common/renderer configuration and revisioned setters. | Equality/default/persistence tests. |
| Preference persistence | `DashboardPresentationPreferences` → MethodChannel → Android SharedPreferences | Persist primitive/json configuration without a second store. | Dart channel and Android contract inspection/tests. |
| Bar ratio/geometry | new renderer-neutral Balance bar host | Use resident income/expense totals, one capsule bounds and existing Budget lane height token. | 25/75, 50/50, 0/0 and bound tests. |
| Renderer materials | one isolated adapter per technology | Current, native, `glass_kit`, `glassmorphism`, `flutter_glass_ui_kit`, `liquid_glass_widgets`; only selected renderer is mounted. | Widget-tree renderer switching tests. |
| Mind Month header | `MindSumScopeTotalHeader` | Give Month the actual SUM-A year-total typography without a pill. | Header typography/decoration widget test. |
| Balance content border | `BalancePresentationSettings.defaults` | Default colored content outline off, preserving customization. | default setting test. |

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HSG-01 | prompt 1 | Header selector | Header-only finger displacement is 0.5×; first and second crossings need ~V and ~3V global travel in both directions. | In-progress pointer widget tests | DONE |
| HSG-02 | prompt 1 | Header selector | Release velocity is also 0.5×; current visual lane, immediate `onSelectedChanged`, interruption, owner identity, expansion isolation and inert tap remain intact. | Header host/controller/protected carousel tests | DONE |
| BDL-01 | prompt 2 | Balance defaults | Fresh Balance content card has no colored outline; existing setting still works. | Settings unit/widget test | DONE |
| MMD-02 | prompt 3 | Mind Month header | Month amount uses SUM-A year-total font metrics and no colored pill/backplate. | Mind Month header widget test | DONE |
| BGV-01 | prompt 4 | Balance state/prefs/tuner | Line chart versus Balance bar, bar size, vertical position, fill intensity, independent fill and renderer selection are live, revisioned and persisted. | controller/channel/tuner tests | DONE |
| BGV-02 | prompt 4 | Header surface | Collapsed/line modes build no bar or glass; expanded bar uses one shared ratio/bounds and resident data with safe 0/0 behavior. | surface widget geometry tests | DONE |
| BGV-03 | prompt 4 | renderer adapters | Baseline plus five actual native/package adapters use the same geometry; only selected adapter mounts; per-renderer configs retain/reset independently. | renderer widget/persistence tests and source inspection | DONE |
| BGV-04 | prompt 4 | settings UI | Progressive controls expose requested common and renderer-specific material parameters, including track/fill overrides. | tuner widget test | DONE |
| ARC-02 | all prompts | boundary | One settings owner, no new financial/query/repository ownership, no shared physics modification. | boundary/focused source tests and diff inspection | DONE |
| REL-02 | user delivery | branch/release | All local gates, one app commit/push, CI and exact normal Human APK download/hash. | command/action/APK evidence | NOT DONE |

## Execution tasks

### Task 1: Header-only 0.5 input gain

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_mode_selector.dart`
- Test: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`

- [x] Add HSG RED tests using a live `TestGesture`: before/after the ~V and ~3V cumulative global-distance crossings, then run the focused file and record the expected old 16/48px failure.
- [x] Implement a local drag bridge that feeds 0.5-scaled drag offsets and end velocity through the existing `ScrollPosition` lifecycle; retain the existing controller, physics, clip and item extent.
- [x] Run focused Header, controller, Summary/Avatar and centered-carousel tests; inspect the diff to prove shared motion source is untouched.

### Task 2: Balance state, persistence and default/Mind correction

**Files:**
- Modify: `balance_presentation_settings.dart`, `dashboard_presentation_preferences.dart`, preference store, `MainActivity.kt`, `core_dashboard.dart`, `mind_sum_year_band_header.dart`
- Test: Balance settings/preferences and Mind temporal-header suites

- [x] Write RED default/equality/persistence tests for border-off and the complete Balance visual config, plus the Mind no-pill/SUM-A typography assertion.
- [x] Add immutable serializable settings models and one revisioned controller write path; thread only that model through the existing preference transport and restore/persist glue.
- [x] Implement default border-off and shared Mind Month total text metrics without changing resident totals.

### Task 3: Renderer-neutral geometry and isolated actual renderers

**Files:**
- Create: focused Balance header bar host and renderer adapter files in `lib/features/dashboard/presentation/core_modes/`
- Modify: `balance_header_income_expense_partition.dart`, `balance_dashboard_core_surface.dart`, `pubspec.yaml`
- Test: `balance_header_income_expense_partition_test.dart` plus new renderer/surface tests

- [x] Write RED tests for expanded-only mount, line-only absence, 25/75/50/50/0/0 ratio, vertical bounds, and live renderer switch.
- [x] Add dependencies, run `flutter pub get`, inspect the installed APIs, then implement each package adapter against its actual public API.
- [x] Build common capsule geometry/labels once; add baseline/native/package material adapters with a clipped base track and separately materialized income fill.
- [x] Mount the host only in the expanded Balance header, use computed safe top/bottom bounds based on actual value layout, and retain current line chart unmodified.

### Task 4: Settings progressive disclosure and full regression coverage

**Files:**
- Modify: `dashboard_header_visual_tuner.dart` and the focused test suites

- [x] Write RED tuner tests for the Balance header visual section, line/bar control gating, per-renderer controls, independent fill controls, and reset scope.
- [x] Implement the section using current tuner primitives, moving (not duplicating) the existing bar-size setting and exposing renderer-local controls only when selected.
- [x] Run focused tests and update this checklist after direct evidence.

### Task 5: Verification, delivery, and evidence

- [x] Format every changed Dart/Kotlin file; run focused tests, shared carousel/Avatar/Summary protection, fast suite, static analysis and `git diff --check`.
- [x] Re-read this checklist and inspect screenshots for changed visual states; record any unmet item honestly.
- [ ] Commit one focused application commit descending from `9035189a`, push, monitor CI, download and hash the normal Human APK.
- [ ] Regenerate final-source SCIP using the repository tooling workflow, then add journal-only factual delivery evidence in a separate `[skip ci]` commit.

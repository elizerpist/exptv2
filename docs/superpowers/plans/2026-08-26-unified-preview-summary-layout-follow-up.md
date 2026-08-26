# Unified preview and Summary-layout follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every accepted temporal or BudgetAvatar crossing immediately
present one coherent chart and LogBox preview, while adding the requested
presentation-only Summary and Budget layout controls.

**Architecture:** Reuse the existing visible-frame/prepared-scene lane rather
than adding a second data model. The accepted avatar-crossing owner updates the
existing chart target and requests the matching focused LogBox projection in
the same synchronous callback; an active-resource scene hit rotates the normal
stale-guarded visible frame immediately, while a miss remains bounded async
work. Central immutable Summary and Budget layout settings feed only
render/layout adapters, leaving temporal, query and budget semantics unchanged.

**Tech Stack:** Flutter/Dart, `ValueNotifier` dashboard controllers,
custom-painted LogBox, existing CenteredCarousel and prepared scene cache.

## Global constraints

- Work only on `separated-core-modes`; the `spendeetest` worktree is read-only.
- Keep one stable vertical LogBox Scrollable/ScrollController/ScrollPosition
  and the custom-paint/prepared-text/scene-window architecture.
- Do not tune animation duration, debounce crossings, reverse the temporal
  hierarchy, create a second selector/navigation system, or make cache bounds
  unbounded.
- SearchPill owns its existing fill/border/depth/radius; only its outer parent
  composition may change.
- New settings default exactly to the current presentation and are independent
  of shadow, border, corner, height, palette and Split/Unified settings.
- Run Flutter test/analyze only from the Ubuntu proot. Push app code and
  deliver the matching GitHub-built human APK before final handoff.

## File map

- `lib/features/dashboard/application/dashboard_core_controller.dart` and
  `runtime/application/dashboard_presentation_controller.dart`: canonical
  preview publication and epoch/stale ownership.
- `lib/features/dashboard/presentation/core_modes/*budget*` and
  `dashboard_logbox_*`: Budget-avatar crossing and immediate focused LogBox
  projection.
- `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`
  and `dashboard_logbox_viewport.dart`: Search outer composition only.
- `lib/features/dashboard/presentation/widgets/summary_pill_experiments.dart`
  and Summary settings/tuner files: gesture mapping, separator/layout/trio.
- `lib/features/dashboard/presentation/*budget*surface.dart`: order projection
  over existing Split/Unified surfaces.
- matching `test/features/dashboard/**` and `test/core/design/**`: RED-first
  regressions; `docs/superpowers/checklists/...`: evidence/status.

### Task 1: Capture regression contracts and add central presentation models

**Files:** dashboard summary/budget settings/controller and tuner files;
corresponding controller/tuner tests.

- [x] Add RED tests that assert current defaults, independent mutation/reset,
  Summary separator/layout/fling values, and Budget section-order values.
- [ ] Run the focused tests and record their RED failure.
- [x] Implement immutable settings, controller and scope/wiring using the
  existing dashboard visual-controller conventions; add controls to the tuner.
- [x] Run focused settings/tuner tests green.

### Task 2: Unify crossing preview state before asynchronous focus installation

**Files:** `dashboard_core_controller.dart`,
`dashboard_presentation_controller.dart`, visible-frame/cache owner,
Budget avatar drilldown coordinator and their tests.

- [x] Add RED tests for cached category crossings and foreground focused-scene
  installation; existing prepared temporal visual-bank tests cover cache hits.
  interaction epoch reaches chart/LogBox before settle and repository delta is
  zero; include multi-crossing stale ordering and aggregate restoration.
- [ ] Run focused preview tests and capture the current avatar-only delayed
  failure.
- [x] Extend the existing focused visible-frame route with an active-resource
  scene staging capability. It reuses active prepared rows/text layouts and
  retains normal stale/coalescing ownership instead of adding a second data
  model.
- [x] Adapt BudgetAvatar foreground preview to install its matching focused
  scene during physical motion; permit the prepared temporal chart cache hit
  during foreground motion.
- [ ] Run full device multi-crossing/slow-backend trace matrix and document
  before/after event ordering. Automated core/cache/rail coverage is green;
  physical Android evidence remains required.

### Task 3: Correct Search outer composition and Summary interaction visuals

**Files:** Search viewport/header, `summary_pill_experiments.dart`, Summary
tests.

- [ ] Write RED tests for the Search outer-background pixels/structure and
  unchanged pill geometry, mode down/up direction, separator paint-only
  geometry, mode layouts and Dynamic Trio fractional values/clip.
- [ ] Run focused tests to demonstrate current failures.
- [x] Remove only the header parent clip/decorated envelope that clips or
  darkens SearchPill outer pixels, leaving its `FluviRoundedBox` intact.
- [x] Verify the existing physical carousel direction already maps downward
  to the required finer semantic order; preserve the enum/list/query order.
- [x] Render settings-driven separator visibility, a current-size icon/label
  column, and an icon-only visual at least the pinned LogBox avatar size.
- [x] Add Dynamic Trio as a clipped overlay driven by the existing carousel
  fractional controller: exactly one idle item, and previous/current/next with
  continuous distance-derived scale during motion. Keep the underlying
  carousel crossing owner unchanged.
- [x] Run all focused Search/Summary/CenteredCarousel tests green.

### Task 4: Project Budget section order over current composition geometry

**Files:** Budget core surface/layout helper and Budget surface/avatar tests.

- [ ] Add RED matrix tests for Split/Unified × avatars/chart order, physical
  surface ownership, maximum Unified avatar envelope clearance, no chart
  collision, and unchanged target/query/preview state.
- [ ] Run focused geometry tests and capture RED behavior.
- [x] Resolve avatar/chart bounds through one order-aware presentation helper;
  retain current order as default, keep Split background-hosted, and retain a
  single Unified outer shell. Carry the avatar rail shell/hit geometry as a
  unit, including the existing Unified clearance offset.
- [x] Run focused Budget surface, avatar, preview and composition suites
  green; the full dashboard suite carries one separately reproduced baseline
  failure.

### Task 5: Regression verification, documentation and delivery

**Files:** checklist/plan and only factual milestone updates if convention
requires them.

- [x] Run dashboard navigation/cache/scene, Summary, Budget, LogBox/Search,
  visual tuner, body-order and boundary suites in Ubuntu proot; reproduce any
  inherited failure at baseline before excluding it.
- [x] Run `flutter analyze` in Ubuntu proot: final fresh run reports `No issues
  found!` (100.3s).
- [x] Review `git diff` and status, update checklist statuses and documentation
  with exact trace/root-cause/defaults/manual Android checks.
- [ ] Commit one focused production change, push it, monitor the matching
  GitHub Actions human diagnostic job, download its normal APK to
  `/storage/emulated/0/Download/fluvi`, and record SHA-256.

## Coverage review

Tasks 1–5 cover every acceptance group UPV, SRCH, SUM, BORD, SET, regression,
documentation and delivery in the companion checklist. The cross-consumer
preview change is intentionally executed before visual adaptation because all
three Summary presentation variants must retain one existing data path.

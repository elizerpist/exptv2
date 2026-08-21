# Portal Header Visual Channels Implementation Plan

> **For agentic workers:** Execute inline in this worktree.  The user explicitly
> prohibits subagents for this task.  Steps use checkbox syntax for tracking.

**Goal:** Port the source-audited Portal inner-motion and background-morph
visual channels into the existing shared Header engine without semantic Portal
transformation or additional tickers.

**Architecture:** Extract source-derived five-mode material-field math into a
neutral pure catalog, retain independent channel state in the existing Header
controller, and render both through the existing clipped Header paint lane.
Budget remains a palette provider only.

**Tech Stack:** Flutter `CustomPainter`, `Ticker`, `ValueNotifier`, project
diagnostics, `flutter_test`.

## Global Constraints

- One dashboard-lifetime Header ticker; no I/O or semantic Dashboard rebuild
  on animation/tuner paths.
- Header A/B/opacity remain the single palette authority.
- Preserve `DashboardExpansionController`, motion, rail and cache ownership.
- Use RED → GREEN → REFACTOR; run Flutter tooling in Ubuntu proot.
- Portal semantic replacement/navigation/message workflow remains absent.

---

### Task 1: Freeze the audited source contract

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Modify: `docs/superpowers/checklists/2026-08-21-shared-header-visual-engine.md`

- [x] Write failing tests for exact five ids/labels/defaults, same shared field
  schema/time math, separate state/reset semantics, and absent semantic Portal
  transform.
- [x] Run the focused test and record expected missing catalog/channel API.
- [x] Keep production code out of this source-contract RED step.

### Task 2: Extract the shared Portal material field

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`

- [x] Implement exact source controls/defaults, field sampling and phase math.
- [x] Run deterministic t=0/25/50/75/100% tests and prove GREEN.
- [x] Refactor engine file to consume the neutral catalog rather than copy its
  algorithms.

### Task 3: Add two independent controller channels

**Files:**
- Modify: `dashboard_header_visual_engine.dart`
- Test: `dashboard_header_visual_engine_test.dart`

- [x] Add immutable inner/background configurations, independent selected mode,
  settings and active-mode reset, and optional inner rotation.
- [x] Make the existing ticker advance both deterministic phase projections;
  stop it when every continuous recipe is idle.
- [x] Test selection/reset/channel isolation and stable ticker identity.

### Task 4: Compose narrow visual render adapters

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_header_portal_painter.dart`
- Modify: `dashboard_header_visual_engine.dart`
- Test: `dashboard_header_visual_engine_test.dart`

- [x] Paint source background material first and source interior alpha overlay
  last in the existing Header painter; preserve the common effect between them.
- [x] Use current immutable Header palette, including canonical-gradient
  sampling where source center/window logic applies.
- [x] Test deterministic field inputs and static Header child identity through
  phase ticks.

### Task 5: Add source-owned tuner controls and diagnostics

**Files:**
- Modify: `dashboard_header_visual_tuner.dart`
- Modify: `dashboard_header_visual_engine.dart`
- Test: `dashboard_header_visual_tuner_test.dart`

- [x] Add distinct `PORTÁL BELSŐ MOZGÁS` and `Portal háttér-morph` sections in
  source order with selected-mode controls, toggles, reset and source labels.
- [x] Emit deduplicated semantic selection/setting/reset diagnostics only.
- [x] Test live slider update, reset isolation, and bounded internal scrolling.

### Task 6: Verify, commit, push and deliver

**Files:** all changed production/test/docs files.

- [x] Run focused tests, protected dashboard tests, boundary script and analyzer
  in Ubuntu proot; inspect checklist/reference statuses.
- [ ] Commit a focused Portal visual feature commit and push
  `separated-core-modes` without force.
- [ ] Wait for required Actions, download the matching normal `lib/main.dart`
  human APK to `/storage/emulated/0/Download/fluvi`, verify SHA-256, and report
  manual physical acceptance as pending.

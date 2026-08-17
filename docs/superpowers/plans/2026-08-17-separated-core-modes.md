# Separated Core Modes Implementation Plan

> **For agentic workers:** Execute inline in this worktree. The user explicitly
> prohibits subagents for this task. Track each checkbox while preserving all
> pre-existing local changes.

**Goal:** Establish presentation-only, runtime dashboard core-mode switching
with bounded two-surface rendering and header-only horizontal navigation.

**Architecture:** A shell-owned `DashboardCoreModeController` uses the existing
`DashboardModeSpec.values` ring for semantic state only. `DashboardMotionHost`
retains ticker and geometry ownership, exposes a local mode-motion listenable,
and `DashboardCoreModeHost` translates only isolated Balance/Budget/Mind roots.
The shared LogBox/Query/runtime stack remains outside this host.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`, Flutter gesture recognizers,
existing `GestureDirectionArbiter`, `DashboardGeometryResolver`, and
`flutter_test`.

## Global constraints

- Start from `09fc5e0e5c29ef6668c860ec1c4e9708b7c05323`; preserve protected
  `8d559cf` runtime/Query/LogBox/scroll contracts.
- Reuse `DashboardModeSpec.values`, geometry resolver, palette tokens and axis
  arbiter; introduce no fake page index, PageView, TabBarView or IndexedStack.
- Mode navigation is header-only presentation state: no repository, Query,
  paging, cache, scene or timing work and no new `TextPainter` hot path.
- Use strict RED → GREEN → REFACTOR. Run Flutter commands inside Ubuntu/proot.
- Do not modify the existing uncommitted query/profile files or generated
  helper material; do not update `MILESTONE_COMMITS.md`.

---

### Task 1: Specify and test semantic mode navigation

**Files:**
- Create: `test/features/dashboard/application/dashboard_core_mode_controller_test.dart`
- Create: `lib/features/dashboard/application/dashboard_core_mode_controller.dart`

**Interfaces:**
- Produces `DashboardCoreModeController(initialMode:)`,
  `DashboardCoreModeDirection`, `DashboardCoreModeTransitionPhase`, and
  `DashboardCoreModeTransition`.

- [ ] **Step 1: Write failing controller tests** for every initial mode,
  forward/backward ring order, one target, start-not-commit, commit once,
  cancel, completion, immutable target direction, thirty cycles and semantic
  observer events.
- [ ] **Step 2: Run RED**

  `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/application/dashboard_core_mode_controller_test.dart'`

  Expected: compile failure because the controller does not exist.
- [ ] **Step 3: Add the minimal headless controller.** Resolve neighbours from
  `DashboardModeSpec.values`; store no `page`, `index`, database type,
  `BuildContext`, animation ticker or pointer API. Notify only semantic state
  changes and call the injected, pure transition observer for started,
  committed and cancelled events.
- [ ] **Step 4: Run GREEN** with the same command.
- [ ] **Step 5: Refactor** immutable snapshot/event construction without
  changing observable lifecycle, then re-run the test.

### Task 2: Add isolated mode roots and locally bounded motion host

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart`
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_transition_motion.dart`
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Create: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Create: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Create: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/core/motion/dashboard_motion_host.dart`
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Create: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`

**Interfaces:**
- Consumes `DashboardCoreModeController`, one immutable mode presentation per
  `DashboardModeSpec`, `DashboardGeometryResolver`, shared palette tokens and
  `GestureDirectionArbiter`.
- Produces `DashboardCoreModeHost` with exactly one settled and at most two
  transitioning mode roots, and a local animation listening boundary.

- [ ] **Step 1: Write failing tests** for each root's keys/label/body shape,
  direct Mind envelope endpoints, bounded mode-root count during drag and
  after settlement, drag-following translation, and shared LogBox exclusion.
- [ ] **Step 2: Run RED** for the host and geometry tests; expected failure is
  absent roots/host/motion API rather than an unrelated test harness error.
- [ ] **Step 3: Implement minimal presentation inputs and roots.** Each root
  receives only immutable geometry/palette input. Balance/Budget render a
  header/card1/card2 and Mind a header/unified envelope. Reuse only low-level
  placeholder, positioning and token primitives; never pass `DashboardCoreController`.
- [ ] **Step 4: Extend `DashboardMotionHost`.** It remains the creator and
  disposer of the mode settle ticker, resolves every current/target frame via
  the central resolver, and exposes the mode-motion `Listenable` only to the
  child host. Do not merge it into the root structural listener.
- [ ] **Step 5: Implement host translation.** Translate source and one fixed
  neighbour across `LayoutBuilder` viewport width; use one normalized-distance
  settlement threshold in the motion policy. On completion, collapse to one
  root.
- [ ] **Step 6: Run GREEN**, then refactor shared low-level layout helpers only
  after all host/geometry tests remain green.

### Task 3: Connect one header axis boundary without touching protected owners

**Files:**
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart`
- Modify: `test/regression/dashboard_scroll_milestone_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_rail_density_trace_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`
- Create: `test/boundary/dashboard_core_mode_boundary_test.dart`

**Interfaces:**
- Shell creates exactly one `DashboardCoreModeController` beside its existing
  `DashboardCoreController` and adapts typed semantic events to existing
  diagnostics.
- `CoreDashboard` consumes that controller, leaves LogBox/rail/summary/action
  mounted once, and supplies expansion callbacks to the host.

- [ ] **Step 1: Write failing widget/boundary tests** for real header left/right
  cycles, vertical-only expansion, slop/diagonal/axis lock, card/merged-body
  isolation, expansion continuity, 30 transitions, no mode-triggered data
  acquisition, stable dashboard controller, one LogBox and localized rebuilds.
- [ ] **Step 2: Run RED** focused host and boundary tests.
- [ ] **Step 3: Wire production code.** Replace the old broad vertical header
  detector with a single actual-header `onPan*` boundary. Use cumulative
  Flutter gesture displacement and `GestureDirectionArbiter`; once chosen,
  vertical invokes the existing expansion callbacks and horizontal fixes one
  target. Use no raw-event replay, synthetic velocity, debounce, timer or
  microtask scheduling.
- [ ] **Step 4: Keep singleton shared content outside the host.** Move only
  header/cards/dots into mode roots, retain one LogBox viewport and all current
  cache/paging/query callbacks untouched.
- [ ] **Step 5: Run GREEN** focused tests, then refactor only duplicated
  presentation plumbing while preserving boundary assertions.

### Task 4: Verify, review scope and deliver

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-17-separated-core-modes.md`

- [ ] **Step 1: Run targeted new controller, host, geometry, core-dashboard,
  rebuild-isolation, relevant LogBox and boundary suites in Ubuntu/proot.**
- [ ] **Step 2: Run the repository's normal analyzer and broader fast/full
  validation in Ubuntu/proot; inspect all failures before changing code.**
- [ ] **Step 3: Re-read the protected milestone and checklist; inspect final
  diff for Query/Room/LogBox/physics/milestone/generated-junk changes.**
- [ ] **Step 4: Mark only verified checklist rows DONE; leave human physical
  acceptance PENDING. Run `git diff --check` and commit exactly scoped files
  as `feat: establish separated dashboard core mode foundation`.**
- [ ] **Step 5: Push the production Flutter commit, monitor the exact SHA's
  normal human `lib/main.dart` APK workflow, download its human APK to
  `/storage/emulated/0/Download/fluvi`, verify existence and SHA-256.**

## Plan self-review

- Coverage: Tasks 1–3 cover controller ownership, mode roots, host bounds,
  geometry, header arbitration, no-I/O, diagnostics and protected singleton
  state; Task 4 covers all validation/delivery obligations.
- No broad Query/LogBox performance work is planned.
- The only mode-specific content is a label and existing neutral placeholders.

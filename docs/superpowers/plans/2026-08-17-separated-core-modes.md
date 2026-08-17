# Atomic Core Modes Correction Implementation Plan

> **For agentic workers:** Execute inline in this worktree. The user explicitly
> prohibits subagents for this task. Track each checkbox while preserving all
> pre-existing local changes.

**Goal:** Replace the prior drag-following core-mode transition with one
stationary, immediate, header-only semantic mode switch.

**Architecture:** A shell-owned `DashboardCoreModeController` keeps only the
committed mode from `DashboardModeSpec.values`. `DashboardCoreModeHost` owns
the pointer-sequence latch and selects exactly one isolated
Balance/Budget/Mind root. `DashboardMotionHost` continues its existing
expansion/rail structural role and contains no core-mode motion lane.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`, Flutter gesture recognizers,
existing `GestureDirectionArbiter`, `DashboardGeometryResolver`, and
`flutter_test`.

## Global constraints

- Start from `09fc5e0e5c29ef6668c860ec1c4e9708b7c05323`; preserve protected
  `8d559cf` runtime/Query/LogBox/scroll contracts.
- Reuse `DashboardModeSpec.values`, geometry resolver, palette tokens and axis
  arbiter; introduce no fake page index, PageView, TabBarView, IndexedStack,
  PageController, transition animation or core-mode ticker.
- Mode navigation is header-only presentation state: no repository, Query,
  paging, cache, scene or timing work and no new `TextPainter` hot path.
- Use strict RED → GREEN → REFACTOR. Run Flutter commands inside Ubuntu/proot.
- Do not modify the existing uncommitted query/profile files or generated
  helper material; do not update `MILESTONE_COMMITS.md`.

---

### Task 1: Replace transition state with one-shot semantic navigation

**Files:**
- Modify: `test/features/dashboard/application/dashboard_core_mode_controller_test.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_mode_controller.dart`

**Interfaces:**
- Produces `DashboardCoreModeController(initialMode:)`,
  `DashboardCoreModeDirection`, `DashboardCoreModeSwitchEvent`, and one atomic
  `switchMode(direction)` write.

- [ ] **Step 1: Write failing controller tests** for every initial mode,
  immediate forward/backward ring order, exactly one observer event per
  one-shot switch, and thirty atomic cycles. Assert the source has no target,
  phase, progress, ticker or page-index API.
- [ ] **Step 2: Run RED**

  `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/application/dashboard_core_mode_controller_test.dart'`

  Expected: failure because the existing controller still exposes transition
  state and lacks the atomic switch-only contract.
- [ ] **Step 3: Simplify the headless controller.** Resolve neighbours from
  `DashboardModeSpec.values`; store no target, phase, progress, `page`,
  `index`, database type, `BuildContext`, animation ticker or pointer API.
  Notify once per atomic semantic switch and call the injected pure observer
  with from-mode, to-mode and direction.
- [ ] **Step 4: Run GREEN** with the same command.
- [ ] **Step 5: Refactor** the event construction and ring helper names without
  adding any transitional state, then re-run the test.

### Task 2: Make the mode host one-root and stationary

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Preserve: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Preserve: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Preserve: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Delete: `lib/core/motion/dashboard_core_mode_transition_motion.dart`
- Delete: compatibility re-export
  `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_transition_motion.dart`
- Modify: `lib/core/motion/dashboard_motion_host.dart`
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`

**Interfaces:**
- Consumes `DashboardCoreModeController`, one immutable mode presentation per
  `DashboardModeSpec`, `DashboardGeometryResolver`, shared palette tokens and
  `GestureDirectionArbiter`.
- Produces `DashboardCoreModeHost` with exactly one mode root at all times.

- [ ] **Step 1: Write failing tests** for each root's keys/label/body shape,
  direct Mind envelope endpoints, exactly-one-root state before/during/after
  input, stationary Balance bounds before acceptance, no neighbour root, and
  shared LogBox exclusion.
- [ ] **Step 2: Run RED** for the host and geometry tests; expected failure is
  the existing target/translation/settlement behavior rather than an unrelated
  test harness error.
- [ ] **Step 3: Preserve the isolated roots and immutable inputs.** Verify
  Balance/Budget retain header/card1/card2 and Mind retains its unified envelope;
  only the host selection policy changes. Never pass `DashboardCoreController`
  into a root.
- [ ] **Step 4: Remove the core-mode motion lane from `DashboardMotionHost`.**
  It resolves presentation only for the committed mode and retains its
  existing expansion/rail responsibilities.
- [ ] **Step 5: Implement host selection.** A `switch (committedMode)` creates
  exactly the matching root. The host contains no target/source Stack,
  `AnimatedBuilder`, `Transform.translate`, transition policy, ticker or
  async settlement.
- [ ] **Step 6: Run GREEN**, then refactor shared low-level layout helpers only
  after all host/geometry tests remain green.

### Task 3: Commit at horizontal axis acceptance, once per pointer sequence

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
  `DashboardCoreController` and adapts one-shot semantic switch events to
  existing diagnostics.
- `CoreDashboard` consumes that controller, leaves LogBox/rail/summary/action
  mounted once, and supplies expansion callbacks to the host.

- [ ] **Step 1: Write failing widget/boundary tests** for real header left/right
  one-shot cycles, stationary bounds/no neighbour before acceptance,
  vertical-only expansion, slop/diagonal/axis lock, card/merged-body isolation,
  expansion continuity, 30 independent swipes, no mode-triggered data
  acquisition, stable dashboard controller and one LogBox.
- [ ] **Step 2: Run RED** focused host and boundary tests.
- [ ] **Step 3: Wire production code.** The actual-header `onPan*` boundary
  uses cumulative Flutter gesture displacement and
  `GestureDirectionArbiter`; once chosen, vertical invokes the existing
  expansion callbacks and horizontal immediately calls the one-shot mode
  switch, then latches until up/cancel. Use no raw-event replay, synthetic
  velocity, debounce, timer, microtask or end-of-drag dependency.
- [ ] **Step 4: Keep singleton shared content outside the host.** Retain one
  LogBox viewport and all current cache/paging/query callbacks untouched; do
  not introduce a core-mode motion listener or per-pointer render work.
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
  as `fix: make core mode switching immediate and stationary`.**
- [ ] **Step 5: Push the production Flutter commit, monitor the exact SHA's
  normal human `lib/main.dart` APK workflow, download its human APK to
  `/storage/emulated/0/Download/fluvi`, verify existence and SHA-256.**

## Plan self-review

- Coverage: Tasks 1–3 cover controller ownership, mode roots, host bounds,
  geometry, header arbitration, no-I/O, diagnostics and protected singleton
  state; Task 4 covers all validation/delivery obligations.
- No broad Query/LogBox performance work is planned.
- The only mode-specific content is a label and existing neutral placeholders.

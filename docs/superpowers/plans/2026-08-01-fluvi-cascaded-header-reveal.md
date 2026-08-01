# Fluvi Cascaded Header Reveal Implementation Plan

> **For agentic workers:** Inline execution in the current session. Golden tests are intentionally omitted by user request.

**Goal:** Replace the split dashboard's lower-card opacity-only collapse treatment with a shared, delayed, behind-the-upper-card reveal motion.

**Architecture:** Add one pure `HeaderCascadeMotion` calculator and immutable motion result types. Feed it from `DashboardGeometryResolver` using `1 - normalizedCollapseProgress`; render the returned lower, upper, and header layers in one Stack with the required paint order.

**Tech Stack:** Flutter/Dart, immutable design-layer geometry, Flutter unit/widget tests, Ubuntu proot Flutter test runner, GitHub Actions debug APK build.

## Global Constraints

- Preserve the current upper-card profile and all expanded endpoints.
- Use exactly one normalized master reveal progress.
- Keep unified dashboard mode on its existing single-card path.
- Do not add an independent lower-card animation controller.
- Golden tests are skipped by explicit user request.
- Do not change downstream action, summary, search, rail, or bottom-navigation geometry.

### Task 1: Define the cascade calculator and prove its motion math

**Files:**
- Create: `lib/core/design/header_cascade_motion.dart`
- Create: `test/core/design/header_cascade_motion_test.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart` only if a shared motion token needs a named owner.

**Interfaces:**
- `CascadedCardMotion` exposes `top`, `left`, `right`, `opacity`, `scale`, and `progress`.
- `HeaderCascadeGeometry` contains the current upper/lower endpoint geometry plus `lowerHiddenOverlap` and `lowerNestedInset`.
- `HeaderCascadeMotion.calculate({required double masterProgress, required HeaderCascadeGeometry geometry})` returns `HeaderCascadeResult`.

- [ ] Write failing tests for progress 0, 0.20, 0.40, 0.65, and 1.0.
- [ ] Verify the lower interval starts after the upper, lower top/inset move monotonically, opacity is coupled to motion, and final geometry is exact.
- [ ] Implement `intervalProgress`, the two eased intervals, the upper motion, and the lower anchor formula.
- [ ] Run the focused unit test and confirm all cascade cases pass.

### Task 2: Integrate the calculator into centralized dashboard geometry

**Files:**
- Modify: `lib/core/design/dashboard_layout_frame.dart`
- Modify: `lib/core/design/dashboard_geometry_resolver.dart`
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`

**Interfaces:**
- `DashboardLayoutFrame` publishes `upperCardMotion` and `lowerCardMotion` for split mode.
- `DashboardGeometryResolver.resolve` computes `revealProgress = 1 - collapseProgress / collapseTravel` and never duplicates card progress equations.

- [ ] Add failing resolver assertions for split-mode lower motion at collapsed and intermediate progress.
- [ ] Populate motions from the calculator while retaining the existing expanded action/summary/search/rail bounds.
- [ ] Keep legacy scalar fields synchronized from the calculated motions for source compatibility.
- [ ] Run resolver and cascade unit tests.

### Task 3: Paint one correctly ordered split-mode Stack

**Files:**
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`

**Interfaces:**
- A small presentation-only motion-position widget consumes `DashboardBounds` and `CascadedCardMotion`; it owns no progress or animation state.

- [ ] Add a widget regression test that finds both split cards at an intermediate reveal and verifies the lower card's rect changes between collapsed and expanded states.
- [ ] Paint split layers as `lower`, `upper`, `header`; leave unified mode unchanged.
- [ ] Apply opacity and top-anchored scale from the supplied motion; keep pointer interaction disabled until the layer is effectively settled.
- [ ] Ensure placeholder cards fill the positioned width so inset animation cannot overflow.
- [ ] Run dashboard widget tests.

### Task 4: Audit, document, and prepare delivery

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-01-fluvi-cascaded-header-reveal.md`
- Modify: `docs/superpowers/specs/2026-08-01-fluvi-cascaded-header-reveal-design.md` if verification evidence changes.

- [ ] Run `git diff --check`, focused tests, the full non-golden Flutter suite, and `flutter analyze` through Ubuntu proot.
- [ ] Confirm no new golden test was added and no APK build runs locally.
- [ ] Update checklist statuses with exact test and CI evidence.
- [ ] Commit and push the completed change.
- [ ] Trigger and wait for GitHub Actions debug APK build, then download the named APK directly to `/storage/emulated/0/Download/fluvi`.


# Filtered LogBox first paint and viewport bounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to execute this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore immediate, input-free rendering of prepared Query previews and
place the single LogBox scroll viewport structurally between filters and the
shell bottom navigation without altering the approved scroll architecture.

**Architecture:** The first commit changes only the painter's rail-preview
visibility ownership: preview content is top-anchored and shared by paint and
semantics, while committed vertical rendering continues to use raw
content-local scroll pixels. The second commit makes the existing header a
structural sibling above the one scroll viewport, removes the historical
header-coordinate offset, and has the shell provide the body bound above the
bottom navigation.

**Tech Stack:** Flutter/Dart widget tests, CustomPaint, CustomScrollView,
existing prepared Query scene cache and virtual committed geometry.

## Global Constraints

- Branch: `query`; preserve all existing user files and do not reset/stash.
- No golden tests, no subagents, no integration-test harness or automated input.
- Preserve `155f18b62da6fd894f2992567a6d8dd25042f3a9` interaction contracts.
- Do not change physics, controller/position identity, page size, cache bounds,
  virtual geometry, paging policy, Query ownership, or vector-sharp avatars.
- Use RED → GREEN → REFACTOR and Ubuntu-proot Flutter commands.
- Push final production commits and deliver the normal human APK through GitHub
  Actions to `/storage/emulated/0/Download/fluvi`.

---

### Task 1: Lock rail-preview first-paint ownership

**Files:**

- Modify: `test/features/dashboard/presentation/dashboard_logbox_query_preview_paint_test.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart` if the existing painter harness is the smallest valid probe

**Consumes:** existing exact Query candidate publication, prepared scene cache,
stable `DashboardVerticalScrollController`, and `DashboardLogBoxPaintIdentity`.

**Produces:** one private `_DashboardLogBoxVisibleWindow` or equivalent owned by
the surface painter, with a top-anchored preview policy shared by paint and
semantics.

- [x] **Step 1: Write failing first-frame regressions.**

  Add tests that scroll Query A non-zero in committed vertical mode, publish
  exact prepared Query B, and inspect the first B `railPreview` publication
  before any B pointer/scroll event. Assert B scene/payload are non-empty and
  the pre-fix expected state is zero painted rows or the aggregate diagnostic.
  Add the same assertion to one and two successive prepared chip removals.

- [x] **Step 2: Verify RED.**

  Run the focused test in Ubuntu proot and confirm it fails because rail preview
  culls with old `ScrollController.offset`, not because scene/text resources are
  absent.

- [x] **Step 3: Implement the smallest correct ownership change.**

  In `_DashboardLogBoxSurfacePainter`, calculate preview visibility from origin
  zero and current viewport/surface height plus existing overscan. Keep its row
  count bounded. Reuse the exact helper in preview semantics. Leave committed
  virtual page culling untouched for this commit.

- [x] **Step 4: Verify GREEN and refactor.**

  Run the new tests, the historical no-input test, LogBox surface tests and
  scroll milestone suite. Remove duplication only after tests pass.

- [x] **Step 5: Commit only the correctness change.**

  Commit message: `fix: top-anchor filtered logbox preview paint`.

### Task 2: Bound header, scroll viewport, and navigation in their owning layouts

**Files:**

- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart` only if it owns a required parent constraint
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify/create: focused viewport/core-dashboard/app-shell layout tests in the existing dashboard presentation test layout

**Consumes:** the single existing header, scroll controller, virtual geometry
manifest, shell bottom navigation, and current visual token owner.

**Produces:** a Column/Flex-equivalent structural header + one constrained
scroll viewport, content-local scroll coordinates, shell-owned bottom
exclusion and a small canonical LogBox clearance.

- [ ] **Step 1: Write failing layout/coordinate tests.**

  Use real RenderBox rects to assert the scroll viewport begins at/after the
  header bottom without facets and after chips with facets; in an app-shell
  harness assert it ends above the actual navigation top with clearance. Assert
  resource commits leave virtual geometry stable and content offset zero maps to
  page zero.

- [ ] **Step 2: Verify RED.**

  Run the focused test and confirm the current overlay/spacer and `extendBody`
  layout violates the measured bounds.

- [ ] **Step 3: Implement the owning layout change.**

  Make `DashboardLogBoxHeader` a structural sibling above `_DashboardLogScrollArea`,
  remove `SliverToBoxAdapter(SizedBox(height: headerHeight))`, use supplied
  constraints rather than `MediaQuery.height - bounds.top`, convert all vertical
  offset conversions to content-local raw pixels, and update extent diagnostics.
  Change the shell—not LogBox—to exclude body content from the BNB. Add a small
  centralized clearance token only if no existing token fits.

- [ ] **Step 4: Verify GREEN and refactor.**

  Run focused layout, Query, viewport/paging, avatar, and all milestone tests.
  Confirm no new controller/position/physics or nested scrollable exists.

- [ ] **Step 5: Commit only the layout change.**

  Commit message: `fix: bound logbox viewport between filters and navigation`.

### Task 3: Full verification and delivery

**Files:**

- Modify: this checklist only if a delivery record is needed; never stage pre-existing untracked files.

- [ ] **Step 1: Run the required repository verification.**

  Run focused first-paint/layout/Query/milestone/avatar suites; then
  `./scripts/test-fluvi-fast.sh`, `./scripts/verify-fluvi-boundaries.sh`, and
  `flutter analyze --no-pub` via Ubuntu proot.

- [ ] **Step 2: Re-read checklist and mark evidence-backed statuses.**

  Mark only automated requirements that have fresh command output as `DONE`;
  leave `HV-01` pending until human Android verification.

- [ ] **Step 3: Push and deliver the exact normal APK.**

  Push the final `query` SHA without force-push, monitor the exact GitHub
  Actions human APK job, download the normal `lib/main.dart` APK to
  `/storage/emulated/0/Download/fluvi`, hash it, and report the physical
  checklist without claiming human acceptance.

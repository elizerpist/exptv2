# Spendee Test Header Parity Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Spendee test dashboard match the approved C1/C2/C3 HTML paint graph and make all three header stages reachable, stable and exception-free with real pointer gestures.

**Architecture:** Split computed HTML visual state and custom painting out of the large dashboard widget, keep the stage state machine pure, and integrate both through one header host whose animated height is also the single source of the home-content offset. Use TDD for pure style/state behavior, then widget/golden tests for paint order and real gestures.

**Tech Stack:** Flutter/Dart, `CustomPainter`, `FragmentProgram`-free Canvas shaders, `BackdropFilter`, widget tests/goldens, Ubuntu-proot Flutter test/analyze, GitHub Actions Android build.

## Global Constraints

- `docs/prototypes/color_lab.html` C1/C2/C3 Budget mode and screenshots `Screenshot_20260713-192134.png` / `Screenshot_20260713-192139.png` are mandatory references.
- Default computed Budget gradient is `#61E1FB` → `#14C5E1` → `#0390CA` at CSS `112deg`; graphic opacity is `0.57`.
- Header top is `104`, Stage 0 height `104`, Stage 1 height `284`; Stage 2 follows the HTML safety-zone formula.
- The one-pixel white card border is a foreground layer and must remain visible.
- The outer glow uses the HTML blur, opacity, vertical fade and radial falloff.
- Header expansion moves all content below it by the exact same height delta.
- No database, repository or native-bridge data-flow changes.
- No visual checklist row may be `DONE` without screenshot/golden evidence.
- Flutter tests and analyze run inside Ubuntu proot; APK build runs through GitHub Actions.

---

### Task 1: Computed HTML visual specification

**Files:**
- Create: `lib/features/transactions/widgets/experimental/spendee_header_visual_spec.dart`
- Test: `test/spendeetest/spendee_header_visual_spec_test.dart`

**Interfaces:**
- Produces: immutable `SpendeeHeaderVisualSpec.budgetDefault()`, scale sampler and reactive accent consumed by painters/dashboard.

- [ ] **Step 1: Write failing exact-value tests**

Test that the cool scale sampled at `36/50/64` returns `Color(0xFF61E1FB)`, `Color(0xFF14C5E1)`, `Color(0xFF0390CA)`; opacity center `50` returns `0.57`; and the accent mixes the sampled right stop `42%` toward white.

- [ ] **Step 2: Run RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_header_visual_spec_test.dart'
```

Expected: fail because `SpendeeHeaderVisualSpec` does not exist.

- [ ] **Step 3: Implement the pure visual spec**

Implement scale interpolation, immutable colors/stops, layer opacity, exact dimensions, glow mask stops, menu dimensions and HTML shadow tokens. Keep all values centralized and documented with HTML line references.

- [ ] **Step 4: Run GREEN and commit**

Run the same test; expected all pass. Commit visual-spec files.

### Task 2: Stable stage controller and real gesture regression

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_header_stage_controller.dart`
- Modify: `test/spendeetest/spendee_dashboard_foundation_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: controller that preserves settled stage across geometry replacement and deterministic signed drag/release output.

- [ ] **Step 1: Write failing controller tests**

Add tests for Stage 0→1, Stage 1 popout→0, Stage 1 manual return→1, Stage 1→2, Stage 2 overshoot→1, Stage 2 manual return→2, and replacing geometry while settled/dragging without resetting to Stage 0.

- [ ] **Step 2: Write failing real-pointer widget test**

At 412×892, use `startGesture`, multiple `moveBy` calls and `up`. After every phase assert `tester.takeException()` is null. Assert Stage 1 and Stage 2 remain after settle and assert the header/content rectangle deltas are equal.

- [ ] **Step 3: Run RED**

Run the two targeted test names in Ubuntu proot. Expected: current controller/host fails at least geometry preservation or real-data pointer/exception assertions.

- [ ] **Step 4: Implement minimal controller/host correction**

Use explicit settled stage, signed drag offset and armed target. Preserve state when geometry changes. Keep threshold tick bookkeeping scoped to one pointer sequence. Do not change store filtering.

- [ ] **Step 5: Run GREEN and commit**

Run controller and widget interaction tests; expected all pass with no captured exceptions. Commit controller/test changes.

### Task 3: Exact glass painters and foreground border/menu

**Files:**
- Create: `lib/features/transactions/widgets/experimental/spendee_header_glass.dart`
- Create: `lib/features/transactions/widgets/experimental/spendee_header_glass_painters.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Test: `test/spendeetest/spendee_header_glass_test.dart`

**Interfaces:**
- Consumes: `SpendeeHeaderVisualSpec`.
- Produces: `SpendeeHeaderOuterGlow`, `SpendeeHeaderGlassSurface`, `SpendeeHeaderGlassMenuButton`.

- [ ] **Step 1: Write failing structure/paint-order tests**

Assert the glass surface exposes separately keyed graphic, semantic-content and foreground-border layers; border is last; menu geometry/bars equal the HTML values; glow bounds grow by the header-height delta.

- [ ] **Step 2: Run RED**

Run the new test; expected missing classes/layers.

- [ ] **Step 3: Implement exact painters**

Use Canvas shaders in logical coordinates for the sampled base gradient and three gloss layers. Apply graphic opacity only to the graphics save-layer. Render the border and menu inset highlights in foreground painters. Apply the glow's intersected vertical/radial alpha mask with `BlendMode.dstIn`, then blur at sigma `34`.

- [ ] **Step 4: Integrate with the dashboard**

Replace `_HeaderOuterGlow`, `_HeaderGlassBackground`, `_HeaderGlassMenuButton` and `_GlassMenuBar`; remove hardcoded full-scale colors, cyan/blue card shadows and the hidden background `DecoratedBox` border.

- [ ] **Step 5: Run GREEN and commit**

Run visual-spec, glass and interaction tests. Expected all pass. Commit painters/integration.

### Task 4: Brand and C1 home-content parity

**Files:**
- Create: `assets/brand/final_spendeevector.svg` from the approved source asset.
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: packaged live brand lockup and exact C1 geometry below the header.

- [ ] **Step 1: Write failing widget geometry tests**

Assert brand lockup exists; Stage 0 title is `BUDGET`; unapproved Stage 0 subvalue is absent; type/summary/search/logbox rectangles use the spec margins, radii and heights.

- [ ] **Step 2: Run RED**

Expected failure for missing brand, wrong title/subvalue and current 20/18 geometry.

- [ ] **Step 3: Package the approved SVG and implement the lockup**

Copy the exact SVG path data into the packaged asset and render it with `flutter_svg`; use the HTML lockup position, logo size, title/tagline metrics and drop shadow.

- [ ] **Step 4: Correct dashboard component geometry and shadows**

Apply 28-pixel type/summary/search sides, radii `21/20/20`, HTML type-pill shadows including the expense glow, and logbox radius `18`. Remove Material default padding wherever it conflicts with the HTML.

- [ ] **Step 5: Run GREEN and commit**

Run widget tests; expected all geometry/content assertions pass.

### Task 5: Golden/device verification and delivery

**Files:**
- Add or update focused goldens under `test/goldens/spendeetest/` if supported by the repository test harness.
- Modify: `docs/superpowers/checklists/2026-07-13-spendeetest-dashboard-implementation-checklist.md`

**Interfaces:**
- Produces: honest acceptance evidence, pushed branch and downloadable APK.

- [ ] **Step 1: Generate and inspect Stage 0/1/2 golden renders**

Render at 412×892 DPR 1. Compare the Stage 0 header/menu/full dashboard with the HTML reference; inspect Stage 1/2 for clipping and paint continuity. Do not update expected goldens blindly.

- [ ] **Step 2: Run all affected tests and analyze**

Run in Ubuntu proot:

```bash
/home/flutteruser/flutter/bin/flutter test test/spendeetest test/widget_test.dart
/home/flutteruser/flutter/bin/flutter analyze
```

Expected: all tests pass, no exceptions/warnings, analyze reports no issues.

- [ ] **Step 3: Re-read references and update checklist honestly**

Only set rows to `DONE` where the acceptance condition has direct evidence. Leave device-only visual items `PARTIAL` until a fresh installed-APK screenshot exists.

- [ ] **Step 4: Commit and push `spendeetest`**

Verify `git diff --check`, commit, and push `origin/spendeetest`.

- [ ] **Step 5: Build through GitHub Actions and download APK**

Trigger the Android APK workflow for `spendeetest`, verify the run SHA equals branch HEAD, and download the release APK to `/storage/emulated/0/Download/exptv2/`.

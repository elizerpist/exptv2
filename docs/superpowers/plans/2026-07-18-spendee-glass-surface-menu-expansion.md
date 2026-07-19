# Spendee Glass Surface Menu Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add header, avatar, and chart glass design choices for normal/C2/liquid/acrylic surfaces while preserving the existing Spendee dashboard interactions.

**Architecture:** Introduce separate header and content-surface enums so the header can choose between normal, C2, liquid, and acrylic while avatar/chart can choose none, old glass, C2, liquid, and acrylic. Extract reusable C2, liquid, and acrylic wrapper widgets so header/avatar/chart share the same surface implementation and key structure, with no bottom fade for the new C2 path.

**Tech Stack:** Flutter 3.41.4/Dart 3.11.1, `liquid_glass_renderer` 0.2.0-dev.4, `fluent_ui` 4.13.0 Acrylic, existing widget tests through Ubuntu proot.

## Global Constraints

- Approved source: `docs/prototypes/color_lab.html:2183-2206` for C2 glass values.
- `liquid_glass_renderer` README says the package is experimental and Web is unsupported; keep Flutter web running by using a fallback path on web.
- `fluent_ui` is the selected acrylic plugin because it provides an inline `Acrylic` widget; do not use `flutter_acrylic` for header/avatar/chart surfaces because that package targets whole-window effects. Pin `fluent_ui` to 4.13.0 because 4.16.0 references Flutter APIs missing from this SDK and 4.12.0 has a `math_expressions` parser mismatch.
- Do not run local Flutter APK builds on Termux/Android; use proot for Flutter tests and analyzer.
- Keep existing unrelated dirty worktree changes intact.
- Update `docs/superpowers/checklists/2026-07-18-spendee-glass-surface-menu-expansion.md` honestly before final status.

---

### Task 1: RED Tests For Expanded Menu

**Files:**
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Consumes: existing `SpendeeTestDashboard`, `_pumpDashboard`, `_dragHeaderBy`.
- Produces: failing assertions for header, avatar, and chart menu choices.

- [x] **Step 1: Write failing widget test**

Add expectations that the design menu exposes:

```dart
expect(find.byKey(const ValueKey('spendee-test-header-surface-normal')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-header-surface-c2-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-surface-html-c2-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')), findsOneWidget);
```

- [x] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "header menu exposes header avatar and chart glass choices"'
```

Expected: FAIL because the new menu keys do not exist.

### Task 2: Surface State Model And Menu Actions

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`

**Interfaces:**
- Produces: `_HeaderSurface`, `_PanelSurface`, expanded `_HeaderDesignMenuAction`.

- [x] **Step 1: Implement enums and menu items**

Add header state:

```dart
enum _HeaderSurface { normal, htmlC2Glass, liquidGlass }
enum _PanelSurface { background, glass, htmlC2Glass, liquidGlass }
```

Replace avatar/chart use of `_HeaderContentSurface` with `_PanelSurface`.

- [x] **Step 2: Run menu test**

Run the Task 1 test; expected: PASS for menu presence after implementation.

### Task 3: C2 Shared No-Fade Surface

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Produces: `_C2GlassSurface({key, clipKey, paintKey, useBottomFade, borderRadius, child})`.

- [x] **Step 1: RED test for no-fade C2 avatar/header**

Assert the selected C2 avatar no longer has the old fade mask key and that header C2 has its own full-size glass key:

```dart
expect(find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-mask')), findsNothing);
expect(find.byKey(const ValueKey('spendee-test-header-c2-glass')), findsOneWidget);
```

- [x] **Step 2: Implement shared C2 wrapper**

Move the existing painter path into a reusable widget. Use `useBottomFade: false` for header/avatar/chart surfaces in this feature.

- [x] **Step 3: Run C2 tests**

Run the expanded interaction test target and ensure the C2 pixel sample remains cyan-biased.

### Task 4: Liquid Glass Dependency And Fallback Wrapper

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Produces: `_LiquidGlassSurface({key, fallbackKey, borderRadius, child})`.

- [x] **Step 1: Add dependency**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter pub add liquid_glass_renderer:^0.2.0-dev.4'
```

- [x] **Step 2: RED test for liquid keys**

Assert selecting liquid header/avatar/chart produces stable keys:

```dart
expect(find.byKey(const ValueKey('spendee-test-header-liquid-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-budget-stage1-liquid-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-budget-pie-liquid-glass')), findsOneWidget);
```

- [x] **Step 3: Implement wrapper**

Use `kIsWeb` to avoid real liquid renderer on Flutter web. Use the package-backed path on non-web, and a visually similar fallback on web so the local webserver remains usable.

### Task 5: Header Composition

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`

**Interfaces:**
- Consumes: `_HeaderSurface`, `_C2GlassSurface`, `_LiquidGlassSurface`.
- Produces: `_HeaderSurfaceFrame`.

- [x] **Step 1: Wrap current header content**

Keep normal header as current `SpendeeHeaderGlassSurface`. For C2/liquid, paint the existing colored header base below the selected glass overlay and put the semantic content above the overlay.

- [x] **Step 2: Verify header stage interactions**

Run `spendee_dashboard_interaction_test.dart` and confirm stage drag/menu tests pass.

### Task 6: Chart C2 And Liquid Surfaces

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Consumes: `_PanelSurface`.
- Produces: chart C2/liquid wrapper paths around `_BudgetPieContent`.

- [x] **Step 1: Add chart selection tests**

Select chart C2 and liquid menu options in stage2 and assert category/vendor content remains visible.

- [x] **Step 2: Implement chart wrappers**

Use background for no surface, existing `_budgetPieGlassDecoration()` for old glass, `_C2GlassSurface` for C2, `_LiquidGlassSurface` for liquid.

### Task 7: Verification And Server Restart

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-18-spendee-glass-surface-menu-expansion.md`
- Modify: `docs/superpowers/checklists/2026-07-18-spendeetest-resume-glass-work.md`

**Interfaces:**
- Produces: final verified checklist statuses and running local server.

- [x] **Step 1: Run verification**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_center_carousel_inertia_test.dart test/spendeetest/spendee_dashboard_foundation_test.dart test/transactions/transaction_widgets_test.dart'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze'
```

- [x] **Step 2: Restart webserver**

Restart `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8766`, record PID, and verify:

```bash
curl -s -o /dev/null -w "%{http_code}\n" --max-time 10 http://127.0.0.1:8766/
```

Expected: `200`.

### Task 8: Fluent UI Acrylic Surface Option

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Create: `lib/features/transactions/widgets/experimental/spendee_acrylic_surface.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Consumes: `_HeaderSurface`, `_PanelSurface`, `_HeaderDesignMenuAction`.
- Produces: `SpendeeAcrylicSurface({key, fluentKey, borderRadius, child})`, `_HeaderSurface.acrylic`, `_PanelSurface.acrylic`.

- [x] **Step 1: Write failing widget tests**

Add expectations for the new menu keys:

```dart
expect(find.byKey(const ValueKey('spendee-test-header-surface-acrylic')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-avatar-surface-acrylic')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-surface-acrylic')), findsOneWidget);
```

Add selection assertions:

```dart
expect(find.byKey(const ValueKey('spendee-test-header-acrylic')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-budget-stage1-acrylic')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-budget-pie-acrylic')), findsOneWidget);
```

- [x] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "header menu exposes header avatar and chart glass choices" --reporter expanded'
```

Expected: FAIL because the acrylic menu keys do not exist.

- [x] **Step 3: Add dependency**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter pub add fluent_ui:4.13.0'
```

- [x] **Step 4: Implement Acrylic wrapper and menu state**

Add `SpendeeAcrylicSurface` using `package:fluent_ui/fluent_ui.dart` as an alias and its `Acrylic` widget with explicit tint, blur, luminosity, and rounded shape. Add header/avatar/chart acrylic menu items and switch cases.

- [x] **Step 5: Verify GREEN**

Run the two targeted interaction tests and then the full dashboard interaction file.

### Task 9: Strengthen Liquid Fallback Material

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_liquid_glass_surface_stub.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_liquid_glass_surface_native.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Consumes: `SpendeeLiquidGlassSurface`.
- Produces: stronger fallback material layers and stable glare keys for header/avatar/chart liquid surfaces.

- [x] **Step 1: Write failing layer-key tests**

Assert that selected avatar/chart liquid surfaces contain their glare material keys:

```dart
expect(find.byKey(const ValueKey('spendee-test-budget-stage1-liquid-glare')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-budget-pie-liquid-glare')), findsOneWidget);
```

- [x] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "header avatar and chart select c2 liquid and acrylic surfaces" --reporter expanded'
```

Expected: FAIL because the liquid glare layer keys do not exist.

- [x] **Step 3: Add stronger material layers**

Increase fallback blur/tint and add top-left radial glare, bottom-right depth tint, two-sided border cue, and deeper shadow while preserving existing child geometry.

- [x] **Step 4: Verify GREEN**

Run the targeted test, full interaction file, analyzer, web bootstrap check, and restart the webserver.

### Task 10: Stage2 Swipe Navigation And Chart Row Surface Modes

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`
- Modify: `docs/superpowers/checklists/2026-07-18-spendee-glass-surface-menu-expansion.md`

**Interfaces:**
- Consumes: `_Stage2BudgetPage`, `_PanelSurface`, `_C2GlassSurface`, `SpendeeLiquidGlassSurface`, `SpendeeAcrylicSurface`.
- Produces: `_ChartListSurface`, header menu chart-list actions, swipe-only `_BudgetPieStage2Layer`, row wrappers keyed from each `_BudgetShareEntry.rowKey`.

- [x] **Step 1: Write failing widget tests**

Add tests that assert:

```dart
expect(find.byKey(const ValueKey('spendee-test-stage2-prev-page-button')), findsNothing);
expect(find.byKey(const ValueKey('spendee-test-stage2-next-page-button')), findsNothing);
await tester.drag(find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')), const Offset(-140, 0));
expect(find.byKey(const ValueKey('spendee-test-stage2-page-vendors')), findsOneWidget);
await tester.drag(find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')), const Offset(-140, 0));
expect(find.byKey(const ValueKey('spendee-test-stage2-page-categories')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-list-surface-none')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-list-surface-original')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-list-surface-html-c2-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-list-surface-liquid-glass')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-chart-list-surface-acrylic')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-test-header-outer-glow')), findsNothing);
```

- [x] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "stage 2 uses swipe loop navigation without chevrons" --reporter expanded'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "header menu controls chart list row surface mode" --reporter expanded'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "dashboard omits hardcoded header background glow" --reporter expanded'
```

Expected: FAIL because chevrons still render, chart-list surface actions do not exist, and the header glow still renders.

- [x] **Step 3: Implement swipe-only stage2 navigation**

Remove `_Stage2PageChevron` rendering. Wrap the stage2 layer in a horizontal `GestureDetector` with a drag threshold around 48px. Negative drag calls next page, positive drag calls previous page. Keep existing two-page looping behavior.

- [x] **Step 4: Implement chart list row surface modes**

Add:

```dart
enum _ChartListSurface { none, original, htmlC2Glass, liquidGlass, acrylic }
```

Add five header menu actions and pass the selected mode through `_SpendeeBudgetHeaderCard`, `_BudgetPieStage2Layer`, `_BudgetPiePanel`, `_BudgetPieContent`, and `_BudgetPieRow`.

- [x] **Step 5: Remove background glow**

Remove the `AnimatedPositioned` keyed `spendee-test-header-outer-glow`. Do not edit expense type pill gradients or donut entry colors.

- [x] **Step 6: Verify GREEN**

Run the targeted tests, full `spendee_dashboard_interaction_test.dart`, the existing regression bundle, `flutter analyze`, `git diff --check`, web bootstrap guard, and restart the webserver.

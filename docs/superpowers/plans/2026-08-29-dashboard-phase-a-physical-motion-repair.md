# Dashboard Phase A Physical Motion Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore correct Card2 collapse ownership, independent Summary direct input, and measured Avatar fling presentation while retaining deterministic live interaction.

**Architecture:** Keep the existing master expansion progress and the existing `BudgetDistributionPageController`/`PageController`. After a real raster provenance test, move Card2's one physical shell outside its PageView children and clip only the interior. Fix cross-control input only at the proven direct-input owner; Header remains on its one controller/ticker.

**Tech Stack:** Flutter/Dart WidgetTester, render-object image sampling, existing Fluvi diagnostics, Ubuntu-proot Flutter, GitHub Actions APK delivery.

## Global Constraints

- Remain on `separated-core-modes`; never switch/reset/stash/discard unrelated files.
- Preserve latest-wins live interaction, cache-independent foreground semantics, prepared frames, SearchPill, Query identity, Summary crossings, and stable LogBox ownership.
- Vertical motion never navigates/rebases/recreates Card2 paging. No cover, snapshot, second animator, global motion mutex, velocity reduction, or crossing debounce.
- Run Flutter only through Ubuntu proot. Keep Phase B palette production files untouched until A-PHYSICAL-25 is done.

---

### Task 1: Prove Card2 page and slab provenance

**Files:**
- Modify: `test/features/dashboard/presentation/budget_distribution_pager_test.dart`
- Modify: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`
- Modify only if necessary for a test seam: `lib/features/dashboard/presentation/core_modes/budget_distribution_pager.dart`

**Interfaces:**
- Consumes `BudgetDistributionPageController.pageController`, `virtualIndex`, `value`, `DashboardGeometryResolver`, and `BudgetDashboardCoreSurface`.
- Produces a controlled Card2 harness, image capture helper, and diagnostic-event collector.

- [ ] **Step 1: Write the failing Partner and Category progress tests.**

```dart
for (final page in BudgetDistributionPage.values) {
  final controller = BudgetDistributionPageController(
    initialVirtualIndex: page == BudgetDistributionPage.partner ? 1000001 : 1000000,
  );
  final retainedController = controller.pageController;
  ScrollPosition? retainedPosition;
  for (final expansion in <double>[1, .90, .75, .50, .25, .10, 0, .10, .25, .50, .75, .90, 1]) {
    await pumpComposition(tester, controller: controller, expansion: expansion);
    retainedPosition ??= retainedController.position;
    expect(identical(controller.pageController, retainedController), isTrue);
    expect(identical(retainedController.position, retainedPosition), isTrue);
    expect(controller.value, page);
    expect(controller.virtualIndex.isOdd, page == BudgetDistributionPage.partner);
    expect(pageChangedEvents, isEmpty);
    expect(visibleCard2Page(tester), page);
  }
}
```

- [ ] **Step 2: Run the test on the starting composition.**

Run: `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/presentation/budget_distribution_pager_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart'`

Expected: Partner visual ownership fails or the test proves a non-semantic sibling exposure. Record the result before production code changes.

- [ ] **Step 3: Add a test-only diagnostic color seam only if the actual raster cannot distinguish all owners.**

```dart
@visibleForTesting
final class BudgetDistributionCardDiagnosticColors {
  const BudgetDistributionCardDiagnosticColors({
    required this.partner,
    required this.category,
    required this.surface,
    required this.background,
    required this.revealAncestor,
  });
  final Color partner;
  final Color category;
  final Color surface;
  final Color background;
  final Color revealAncestor;
}
```

The default is `null`; production has no debug color setting or changed visual.

- [ ] **Step 4: Write the failing actual-composition raster test.**

```dart
final image = await captureCard2Image(tester);
expect(sample(image, slabPoint), diagnostic.surface);
expect(sample(image, activeInteriorPoint), diagnostic.partner);
expect(sample(image, activeInteriorPoint), isNot(diagnostic.category));
```

Sample reported slab, active interior, rounded edge, and neighbouring page area
for every intermediate progress. The result identifies the physical owner;
it does not merely assert a neutral color.

- [ ] **Step 5: Re-run Task 1 tests and document the proven cause.**

Expected: the test distinguishes semantic page mutation from visual sibling
exposure and names the exact slab owner.

### Task 2: Build one moving Card2 shell

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_pager.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Test: Task 1 test files

**Interfaces:**
- Consumes `BudgetDistributionPageController`, `BudgetContentLayout`, and existing corner/border/shadow scopes.
- Produces a `BudgetDistributionCardShell` owning Card2 surface/border/shadow once; PageView children become content-only.

- [ ] **Step 1: Write failing topology tests.**

```dart
expect(find.byKey(const ValueKey('budget-distribution-card-shell')), findsOneWidget);
expect(find.byKey(const ValueKey('budget-distribution-page-card-surface')), findsNothing);
expect(tester.widget<PageView>(find.byKey(const ValueKey('budget-distribution-pager'))).clipBehavior,
    isNot(Clip.none));
```

- [ ] **Step 2: Run these tests and confirm they fail on the per-page physical-shell model.**

Run: Task 1 command. Expected: the current PageView child owns the shell and allows overflow.

- [ ] **Step 3: Implement the one-shell composition.**

```dart
class BudgetDistributionCardShell extends StatelessWidget {
  const BudgetDistributionCardShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final radius = resolvedCard2Radius(context, constraints.biggest);
      return FluviRoundedBox(
        key: const ValueKey('budget-distribution-card-shell'),
        color: resolvedCard2Color(context),
        border: resolvedCard2Border(context),
        borderRadius: radius,
        boxShadow: resolvedCard2Shadows(context),
        child: ClipRRect(borderRadius: radius, child: child),
      );
    },
  );
}
```

Wrap the existing keyed `PageView.builder` once. Preserve its controller,
`onPageChanged`, and position listener. Page children retain keys and Category/
Partner content but never construct a separate physical shell.

- [ ] **Step 4: Repair the cascade clip only as Task 1 proves necessary.**

The final transformed child must contain the complete shell, not only page
content. A retained envelope clip must share geometry with that shell. Do not
keep the opacity override merely to conceal the previous slab.

- [ ] **Step 5: Run Task 1 tests plus horizontal paging and Partner scroll tests.**

Expected: both page identities, controller/position identity, no page-change
event, correct raster provenance, normal horizontal swipe and Partner list handoff.

- [ ] **Step 6: Commit the independently verifiable layer repair.**

Run: `git add lib/features/dashboard/presentation/core_modes/budget_distribution_pager.dart lib/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart test/features/dashboard/presentation/budget_distribution_pager_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart && git commit -m "fix(dashboard): preserve active card during collapse"`

### Task 3: Prove Header and card edge stability

**Files:**
- Modify if proven: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify if proven: `lib/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_fragment_backend_test.dart`
- Test: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes the one Header controller/frame and master collapse geometry.
- Produces stable controller/backend/program/shell identities while size/uniforms vary.

- [ ] **Step 1: Write the failing dense-progress identity test.**

```dart
final controllerId = identityHashCode(harness.headerVisualController);
final programId = backendProgramIdentity(tester);
for (final progress in denseProgress) {
  await pump(progress);
  expect(identityHashCode(harness.headerVisualController), controllerId);
  expect(backendProgramIdentity(tester), programId);
  expect(edgeSignature(await captureHeaderAndCardImage(tester)), isStableFor(progress));
}
```

- [ ] **Step 2: Run focused Header tests before code changes.**

Run: `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart test/features/dashboard/presentation/dashboard_header_fragment_backend_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart'`

Expected: either resource churn/topology change is proved, or no Header source edit is made and the regression test remains.

- [ ] **Step 3: Fix only the proven resource owner and re-run Task 3.**

Immutable backend/program resources stay in their current owner; per-frame
inputs are size/progress uniforms only. Never add a ticker, shader, key churn,
mask, or fallback material to the progress path.

### Task 4: Repair Avatar-ballistic to Summary input ownership

**Files:**
- Modify if proven: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify if proven: `lib/features/dashboard/presentation/dashboard_summary_auto_reset_controller.dart`
- Modify if proven: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Test: `test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart`
- Test: `test/features/dashboard/presentation/budget_category_avatar_rail_test.dart`

**Interfaces:**
- Consumes real `CenteredCarousel` pointer-down/`ScrollActivity`, Avatar motion lane, Summary reset controller/registry.
- Produces a Summary direct-input path independent from Avatar ballistics.

- [ ] **Step 1: Write the failing real ballistic cross-control test.**

```dart
await tester.fling(find.byKey(const ValueKey('budget-target-avatar-carousel')), const Offset(-720, 0), 2600);
await tester.pump(const Duration(milliseconds: 80));
expect(avatarController.hasActiveScrollActivity, isTrue);
final before = summarySelection.value;
await tester.drag(find.byKey(const ValueKey('dashboard-summary-pill')), const Offset(0, -140));
await tester.pump();
expect(summarySelection.value, isNot(before));
expect(avatarController.hasActiveScrollActivity, isTrue);
```

Continue with Summary fling followed by an Avatar direct drag and assert that
the latest direct input works while previous activity is unresolved.

- [ ] **Step 2: Run the test and identify the exact rejecting condition.**

Run: `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart test/features/dashboard/presentation/budget_category_avatar_rail_test.dart'`

Expected: source tracing names a real busy check, input gate, reset path or
lease. A synthetic `motionActive` fixture is not sufficient.

- [ ] **Step 3: Implement only Summary-specific direct ownership.**

```dart
void onSummaryDirectPointerDown() {
  summaryAutoResetController.cancel();
  summaryAutoResetMotionRegistry.cancelActiveResetMotion();
  controller.beginSummaryDirectInput();
}
```

Reuse an existing Summary lane where available. This path cannot test global
foreground activity or cancel/shorten Avatar ballistics.

- [ ] **Step 4: Re-run Task 4 tests and commit the repair.**

Run: `git add lib/features/dashboard/presentation/core_dashboard.dart lib/features/dashboard/presentation/dashboard_summary_auto_reset_controller.dart lib/features/dashboard/application/dashboard_core_controller.dart test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart test/features/dashboard/presentation/budget_category_avatar_rail_test.dart && git commit -m "fix(dashboard): decouple summary input from avatar ballistic motion"`

### Task 5: Measure Avatar pixel work without losing crossings

**Files:**
- Modify if counters are absent: `lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart`
- Modify only at the proven subscriber: matching presentation/controller owner
- Test: `test/features/dashboard/presentation/budget_category_avatar_rail_test.dart`
- Test: `test/features/dashboard/application/dashboard_rail_flight_recorder_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

**Interfaces:**
- Consumes raw pixel updates, `onPreviewChanged` crossings, prepared target publication, live generations.
- Produces a bounded per-fling summary and structural no-heavy-pixel-work assertions.

- [ ] **Step 1: Write the failing metric test around a real fling.**

```dart
expect(metrics.rawScrollUpdateCount, greaterThan(metrics.semanticCrossingCount));
expect(metrics.scenePreparationCount, lessThanOrEqualTo(metrics.semanticCrossingCount));
expect(metrics.repositoryIoCount, 0);
expect(metrics.presentationPublicationCount, metrics.semanticCrossingCount);
```

- [ ] **Step 2: Run the metrics test before code changes.**

Run: `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter test test/features/dashboard/presentation/budget_category_avatar_rail_test.dart test/features/dashboard/application/dashboard_rail_flight_recorder_test.dart test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart'`

Expected: a failing counter names the pixel-rate subscriber; passing evidence
means no physics redesign is performed.

- [ ] **Step 3: Move only proven pixel-rate nonvisual work to semantic crossings.**

Keep carousel transforms at pixel rate and every semantic crossing on the
prepared latest-wins path. Extend withheld-scene assertions to Category facet,
count and first visible row/viewport identity.

- [ ] **Step 4: Re-run Task 5 tests and commit only if source behavior changed.**

Run: `git add lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart test/features/dashboard/presentation/budget_category_avatar_rail_test.dart test/features/dashboard/application/dashboard_rail_flight_recorder_test.dart test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart && git commit -m "perf(budget): isolate avatar fling presentation work"`

### Task 6: Verify, document, deliver, and gate Phase B

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-29-dashboard-phase-a-physical-motion-repair.md`
- Modify: `docs/superpowers/specs/2026-08-29-dashboard-phase-a-physical-motion-repair-design.md`
- Modify only if the established record requires it: `MILESTONE_COMMITS.md`

**Interfaces:**
- Consumes focused evidence and exact pushed commit SHA.
- Produces honest checklist statuses, root-cause documentation, normal human APK and physical gate result.

- [ ] **Step 1: Run comprehensive validation.**

Run: `proot-distro login ubuntu -- bash -lc 'export PATH=/home/flutteruser/flutter/bin:$PATH; cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && flutter analyze && scripts/test-fluvi-fast.sh'`

Run: `git diff --check`

Expected: focused/protected suites pass, analysis has no new diagnostics and
whitespace is clean. Any inherited failure is reproduced at the starting SHA.

- [ ] **Step 2: Update docs with the exact slab owner, semantic result, old/new layer tree, controller identities, Header identity evidence, lock owner, and fling counters.**

- [ ] **Step 3: Commit implementation and corresponding docs, then push.**

Run: `git status --short && git push origin separated-core-modes && git rev-parse HEAD`

Never add the pre-existing `.tmp-*.png` files.

- [ ] **Step 4: Deliver the Android artifact and perform the physical matrix.**

Monitor the exact-SHA normal human APK Action. On success download its normal
`lib/main.dart` APK to `/storage/emulated/0/Download/fluvi`, verify it exists,
run `sha256sum`, install it, and physically test all A-COLL through A-PROTECT
items. If the device/build service is unavailable, mark A-PHYSICAL-25
`BLOCKED` and stop before Phase B.

## Plan self-review

- Tasks 1–6 cover every Phase A checklist ID.
- No Phase B implementation task exists; `B-GATE-01` remains blocked.
- The plan preserves one expansion owner, one pager controller, one Header
ticker, independent direct controls, and deterministic prepared presentation.

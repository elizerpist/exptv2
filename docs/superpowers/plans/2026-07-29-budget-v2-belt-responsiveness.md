# Budget V2 Avatar Belt Responsiveness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Budget V2 avatar rail a continuously moving, responsive belt whose incoming avatars are retained before entering and whose next pointer contact preempts any pending expensive filter publication.

**Architecture:** The dedicated V2 carousel remains the only drag/snap state owner. It uses seven index-stable belt slots, of which five are visible and two are transparent retained edge entries. The dashboard receives the direct-drag flag on settle so it can keep charts frozen until the final idle filter publish; a raw pointer-down cancels that pending publish before gesture-arena recognition.

**Tech Stack:** Flutter/Dart widget tests, `SpendeeCenterCarouselController`, `Timer`, `Listener`, existing Budget V2 dashboard and production-host contracts.

## Global Constraints

- Preserve the standard Budget 360ms final-filter debounce; it is a batching boundary, never an input lock.
- Do not change the shared TransactionStore category filter path.
- Direct avatar drag must not rebuild category/vendor/mother-card chart data before the final idle publish.
- Remote chart/legend/tap step previews remain immediate and stepped.
- Keep only interaction-scoped diagnostics; do not add frame/tick logging.
- Run Flutter tests/analyze only inside the Ubuntu proot environment.
- Stage and commit only task-owned files; preserve unrelated dirty worktree changes.

---

### Task 1: Encode the belt-entry and pointer-preemption regressions

**Files:**

- Modify: `test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`

**Interfaces:**

- Consumes: current `SpendeeBudgetV2AvatarCarousel` public constructor and the V2 production dashboard test host.
- Produces: failing behavior specifications for retained edge slots, raw pointer cancellation, and chart deferral.

- [x] **Step 1: Write the retained-entry failing widget test**

Extend the local `host` helper with an optional `VoidCallback? onPointerDown` and pass it to the desired carousel constructor. Add a test that builds seven items and asserts both edge-entry items are mounted at rest, the incoming `+3` item is transparent, and its `Element` stays the same after a controller tick:

```dart
testWidgets('retains both entering belt avatars before they become visible', (
  tester,
) async {
  await tester.pumpWidget(host(width: 328, itemCount: 7, onSettled: (_) {}));
  await tester.pump();
  final entering = find.byKey(
    const ValueKey('budget-v2-avatar-carousel-test-item-3-idle'),
  );
  final opposite = find.byKey(
    const ValueKey('budget-v2-avatar-carousel-test-item-4-idle'),
  );
  expect(entering, findsOneWidget);
  expect(opposite, findsOneWidget);
  final priorElement = tester.element(entering);
  expect(
    tester.widget<Opacity>(
      find.ancestor(of: entering, matching: find.byType(Opacity)).first,
    ).opacity,
    0,
  );
  final rail = find.byKey(
    const ValueKey('budget-v2-avatar-carousel-test-rail'),
  );
  final gesture = await tester.startGesture(tester.getCenter(rail));
  await gesture.moveBy(const Offset(-20, 0));
  await gesture.moveBy(const Offset(-40, 0));
  await tester.pump();
  expect(
    tester.widget<Opacity>(
      find.ancestor(of: entering, matching: find.byType(Opacity)).first,
    ).opacity,
    greaterThan(0),
  );
  await gesture.moveBy(const Offset(-58, 0));
  await tester.pump();
  expect(tester.element(entering), same(priorElement));
  await gesture.cancel();
});
```

- [x] **Step 2: Run it and confirm RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart --plain-name "retains both entering belt avatars before they become visible" --reporter expanded --timeout 60s'
```

Expected: FAIL because the five-slot rail does not mount the two entry items.

- [x] **Step 3: Write the raw-pointer and direct-chart failing host regressions**

Add a production-host test that settles an initial direct drag, starts a second pointer before the 360ms timer expires but sends no horizontal delta, pumps beyond the timer, and asserts no callback. Release that pointer, perform one more drag, then assert exactly one final callback. Change the existing direct-drag chart test to require zero chart diagnostics before the idle deadline and one after it.

```dart
final hold = await tester.startGesture(tester.getCenter(rail));
await tester.pump(const Duration(milliseconds: 180));
expect(settled, isEmpty);
await hold.up();
```

- [x] **Step 4: Run the raw-pointer test and confirm RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 pointer down preempts the pending filter before drag recognition" --reporter expanded --timeout 60s'
```

Expected: FAIL because the existing timer can commit before `onHorizontalDragStart`.

- [x] **Step 5: Retain the RED tests for the final atomic commit**

```bash
git add test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart
git commit -m "test(budget): expose v2 belt responsiveness regressions"
```

### Task 2: Implement the retained seven-slot V2 belt

**Files:**

- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart`
- Test: `test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart`

**Interfaces:**

- Consumes: `SpendeeCenterCarouselController` index/residual state and the item/size/scale builders.
- Produces: `onPointerDown`, a settled callback carrying `directDrag`, and seven retained belt entries keyed by category index.

- [x] **Step 1: Replace the five-slot mapping**

Use `[-3, -2, -1, 0, 1, 2, 3]`; retain the nearest unique logical position for every small-belt category. Implement opacity from fully visible through `±2` to zero at `±3`:

```dart
static const _slotOffsets = <int>[-3, -2, -1, 0, 1, 2, 3];

double _entryOpacity(double visualLogicalOffset) {
  final distance = visualLogicalOffset.abs();
  if (distance <= 2) return 1;
  if (distance >= 3) return 0;
  return 3 - distance;
}
```

- [x] **Step 2: Preserve category element identity across a tick**

Key each outer positioned item by `index`, not the mutable logical offset. Wrap it in `IgnorePointer` when zero-opacity and an `Opacity` around its existing `RepaintBoundary`/scale/item builder.

```dart
key: ValueKey('spendee-budget-v2-avatar-carousel-item-$index'),
child: IgnorePointer(
  ignoring: opacity <= 0,
  child: Opacity(opacity: opacity, child: RepaintBoundary(/* existing child */)),
),
```

- [x] **Step 3: Add raw pointer and direct-settle source contracts**

Add `VoidCallback? onPointerDown` and a named settle callback accepting `directDrag`. Wrap the `GestureDetector` in a translucent `Listener`; its only pointer-down work is `widget.onPointerDown?.call()`.

- [x] **Step 4: Run focused carousel suite to verify GREEN**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart --reporter expanded --timeout 60s'
```

Expected: all focused tests pass.

- [x] **Step 5: Retain the implementation for the final atomic commit**

```bash
git add lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart
git commit -m "fix(budget): retain incoming v2 avatar belt slots"
```

### Task 3: Keep direct settlements local and cancel on raw contact

**Files:**

- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`

**Interfaces:**

- Consumes: carousel `onPointerDown`, `onSettled(index, directDrag: ...)`, `_budgetV2FilterPublishTimer`, and the chart preview notifier.
- Produces: immediate timer cancellation and direct-drag chart deferral until the final publish.

- [x] **Step 1: Forward both new contracts through `SpendeeBudgetV2AvatarBelt`**

Add `onPointerDown` to the belt adapter, forward it to the carousel, and forward the actual `directDrag` value at settlement.

- [x] **Step 2: Split dashboard settlement by source**

For a direct drag, schedule the final bar only. Do not set `_budgetV2RequestedBarKey` or `_budgetV2PreviewBarKey`. For remote chart/legend/tap steps retain the existing request and preview path. Pass the raw-pointer callback to `_beginBudgetV2AvatarInteraction`.

```dart
if (directDrag) {
  if (selectionChanged) _scheduleBudgetV2FilterPublish(bar);
  return;
}
// Existing remote request + preview path.
```

- [x] **Step 3: Run both dashboard regressions to verify GREEN**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 pointer down preempts the pending filter before drag recognition" --reporter expanded --timeout 60s'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 avatar rail keeps direct tick previews local without chart delivery" --reporter expanded --timeout 60s'
```

Expected: both pass; chart diagnostics appear only after the final idle publish.

- [x] **Step 4: Run remote stepped-chart regression**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 category chart controls step the avatar and centre returns to overview" --reporter expanded --timeout 60s'
```

Expected: PASS.

- [x] **Step 5: Retain the implementation for the final atomic commit**

```bash
git add lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart test/spendeetest/spendee_budget_v2_contract_test.dart
git commit -m "fix(budget): preempt v2 filter on avatar contact"
```

### Task 4: Verify, record evidence, and publish a device APK

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-29-budget-v2-income-distribution.md`
- Modify: `docs/superpowers/specs/2026-07-29-budget-v2-belt-responsiveness-design.md`
- Modify: `docs/superpowers/plans/2026-07-29-budget-v2-belt-responsiveness.md`

- [x] **Step 1: Run full focused evidence**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart --reporter expanded --timeout 120s'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "budget carousel threshold release ticks before publishing filter" --reporter expanded --timeout 60s'
```

- [x] **Step 2: Run scoped analysis**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze --no-pub lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart'
```

Expected: `No issues found!`.

- [x] **Step 3: Update the checklist/evidence honestly**

Mark every verified requirement `DONE` only after the preceding evidence passes. Keep BUDGETV2-042 `PARTIAL` until a fresh device trace/screenshot verifies its visual entry behavior.

Post-review follow-up: the nullable default overview is now compared by its
resolved logical belt index, and the integration regression verifies a
remote-preview-to-overview direct return leaves the overview avatar selected,
does not redraw the chart, and does not publish or even schedule an
unnecessary filter. The reciprocal remote correction is also prevented from
manufacturing a null-to-overview timer.

- [ ] **Step 4: Commit, push, and build online**

```bash
git add docs/superpowers/checklists/2026-07-29-budget-v2-income-distribution.md docs/superpowers/specs/2026-07-29-budget-v2-belt-responsiveness-design.md docs/superpowers/plans/2026-07-29-budget-v2-belt-responsiveness.md
git commit -m "docs(budget): record v2 belt responsiveness evidence"
git push origin spendeetest
gh workflow run "Exptv2 Android APK Build" --ref spendeetest
gh run watch --exit-status
```

- [ ] **Step 5: Download the fresh debug APK**

```bash
gh release download debug-latest --pattern 'exptv2-debug-<new-sha>.apk' --dir /storage/emulated/0/Download --clobber
sha256sum /storage/emulated/0/Download/exptv2-debug-<new-sha>.apk
```

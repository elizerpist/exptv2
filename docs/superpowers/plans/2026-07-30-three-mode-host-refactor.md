# Three-mode host refactor implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Balance, Budget, and Mind independent runtime hosts while preserving all five selectable UI variants and every existing menu unchanged.

**Architecture:** Keep `SpendeeTestDashboard` as the menu-facing facade and route its selected variant directly to one keyed mode host.  The host implementation files are Dart `part` files of the dashboard library initially, so the refactor can move private visual/configuration types without changing UI-facing APIs.  Each host owns its local controllers, timers, frame caches, and callbacks; shared selection/filter state remains in `TransactionStore`.

**Tech Stack:** Flutter/Dart, existing `TransactionStore`, `flutter_test`, Ubuntu/proot Flutter toolchain.

## Global Constraints

- Do not change any menu label, order, key, position, visual appearance, or A/B selector.
- Retain all five `SpendeeDashboardMode` values: `balance`, `balanceV2`, `budget`, `budgetV2`, and `mind`.
- Map the five variants to exactly three data-flow families: Balance, Budget, Mind.
- Mount exactly one selected host; do not retain inactive mode trees with `IndexedStack`, `Offstage`, or disabled `TickerMode`.
- Preserve shared TransactionStore filter state on a switch; reset host-local visual motion and interaction state.
- Do not stage or modify pre-existing unrelated dirty files.
- Run Flutter test/analyze only through Ubuntu/proot; do not attempt a local Termux APK build.

---

### Task 1: Establish the mode-family and router contract

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_dashboard_mode.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Create: `lib/features/transactions/widgets/experimental/modes/spendee_balance_mode_host.dart`
- Create: `lib/features/transactions/widgets/experimental/modes/spendee_budget_mode_host.dart`
- Create: `lib/features/transactions/widgets/experimental/modes/spendee_mind_mode_host.dart`
- Modify: `test/spendeetest/spendee_dashboard_mode_test.dart`
- Create: `test/spendeetest/spendee_dashboard_mode_host_test.dart`

**Interfaces:**
- Consumes: existing `SpendeeDashboardMode`, `SpendeeTestDashboard` constructor and dashboard-menu callbacks.
- Produces: `SpendeeDashboardModeFamily`, `SpendeeDashboardMode.family`, and one keyed host selection point in the facade.

- [ ] **Step 1: Write the failing family mapping tests**

```dart
expect(SpendeeDashboardMode.balance.family, SpendeeDashboardModeFamily.balance);
expect(SpendeeDashboardMode.balanceV2.family, SpendeeDashboardModeFamily.balance);
expect(SpendeeDashboardMode.budget.family, SpendeeDashboardModeFamily.budget);
expect(SpendeeDashboardMode.budgetV2.family, SpendeeDashboardModeFamily.budget);
expect(SpendeeDashboardMode.mind.family, SpendeeDashboardModeFamily.mind);
```

- [ ] **Step 2: Run the mapping test and verify RED**

Run:

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_dashboard_mode_test.dart --reporter compact'
```

Expected: compile failure because `SpendeeDashboardModeFamily` and `family` do not exist.

- [ ] **Step 3: Add the minimal family mapping and part declarations**

```dart
enum SpendeeDashboardModeFamily { balance, budget, mind }

extension SpendeeDashboardModeFamilyX on SpendeeDashboardMode {
  SpendeeDashboardModeFamily get family => switch (this) {
    SpendeeDashboardMode.balance || SpendeeDashboardMode.balanceV2 =>
      SpendeeDashboardModeFamily.balance,
    SpendeeDashboardMode.budget || SpendeeDashboardMode.budgetV2 =>
      SpendeeDashboardModeFamily.budget,
    SpendeeDashboardMode.mind => SpendeeDashboardModeFamily.mind,
  };
}
```

Add the three `part` declarations after the dashboard imports and create the
three host files with `part of '../spendee_test_dashboard.dart';` and stable
host keys.  The initial host wrappers may delegate to existing render methods
only until their extraction task; they must not create a second mounted tree.

- [ ] **Step 4: Write the failing single-host widget test**

```dart
expect(find.byKey(const ValueKey('spendee-mode-host-budget')), findsOneWidget);
expect(find.byKey(const ValueKey('spendee-mode-host-balance')), findsNothing);
expect(find.byKey(const ValueKey('spendee-mode-host-mind')), findsNothing);
```

After changing `dashboardMode`, assert the new host exists and the previous
host is absent.

- [ ] **Step 5: Replace the retained mode stack with a direct keyed switch**

Route by `widget.dashboardMode.family`, key the selected host by the complete
variant value, and remove the mode-level `IndexedStack` retention path.  Keep
the existing menu action and `onDashboardModeChanged` callback unchanged.

- [ ] **Step 6: Run focused tests and commit**

Run the two mode tests.  Commit only the files listed in this task with:

```sh
git commit -m "refactor(dashboard): route variants through mode hosts"
```

### Task 2: Extract the Balance data-flow host

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/modes/spendee_balance_mode_host.dart`
- Modify: `test/spendeetest/spendee_balance_dashboard_test.dart`
- Modify: `test/spendeetest/spendee_dashboard_mode_host_test.dart`

**Interfaces:**
- Consumes: `SpendeeDashboardModeFamily.balance`, existing Balance callbacks, menu-created header/brand widgets, and `TransactionStore`.
- Produces: `SpendeeBalanceModeHost`, owning `BalanceFrameInput`/Balance-dashboard cache lifecycle for `balance` and `balanceV2`.

- [ ] **Step 1: Write the failing host-disposal test**

```dart
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.balance));
expect(find.byKey(const ValueKey('spendee-mode-host-balance')), findsOneWidget);
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.budget));
expect(find.byKey(const ValueKey('spendee-mode-host-balance')), findsNothing);
expect(disposedBalanceHostCount, 1);
```

Use a test-only callback supplied by the host constructor; do not add a
production-only debug API.

- [ ] **Step 2: Run the lifecycle test and verify RED**

Run:

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_dashboard_mode_host_test.dart --reporter compact'
```

Expected: the current balance lifecycle still belongs to the facade and the
test cannot observe host disposal.

- [ ] **Step 3: Move Balance-only runtime ownership into the host**

Move construction of `BalanceFrameInput`, the ordinary Balance and Balance V2
dashboard caches, frame callbacks, and their disposal into
`SpendeeBalanceModeHost`.  Pass unchanged menu-produced presentation values
and application callbacks from the facade.  Do not move or rewrite the menu
widgets themselves.

- [ ] **Step 4: Verify the Balance host has no Budget V2 branch**

Make `SpendeeBalanceModeHost` accept only `balance` and `balanceV2`; assert
this in its constructor.  Budget V2 is owned by the Budget host in Task 3.

- [ ] **Step 5: Run focused regression tests and commit**

Run `spendee_balance_dashboard_test.dart`,
`spendee_balance_v2_contract_test.dart`, and
`spendee_dashboard_mode_host_test.dart`.  Commit only task files with:

```sh
git commit -m "refactor(balance): extract balance mode host"
```

### Task 3: Extract the Budget data-flow host

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/modes/spendee_budget_mode_host.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify: `test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart`
- Modify: `test/spendeetest/spendee_dashboard_mode_host_test.dart`

**Interfaces:**
- Consumes: `SpendeeDashboardModeFamily.budget`, shared menu presentation values, `TransactionStore`, and the existing Balance visual components used by Budget V2.
- Produces: `SpendeeBudgetModeHost`, owner of legacy Budget and Budget V2 selection, long-press limit editing, filter publication, and budget-local animation lifecycle.

- [ ] **Step 1: Write the failing Budget-host lifecycle and filter-persistence tests**

```dart
store.setCategoryFilter(category);
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.budget));
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.budgetV2));
expect(store.activeCategoryIds, contains(category.transactionCategoryID));
expect(find.byKey(const ValueKey('spendee-mode-host-budget')), findsOneWidget);
expect(disposedBudgetHostCount, 1);
```

- [ ] **Step 2: Run the test and verify RED**

Run the host test plus `spendee_budget_v2_avatar_carousel_test.dart` in
Ubuntu/proot.  Expected: no standalone Budget host owns the old controller
and timer lifecycle yet.

- [ ] **Step 3: Move the legacy Budget runtime state into the host**

Move the header-stage controller, Budget carousel controller/release
controller, filter publication timer, selected Budget item, limit-edit state,
and legacy Budget render assembly into `SpendeeBudgetModeHost`.  Keep the
existing UI widgets and menu callbacks intact.

- [ ] **Step 4: Move Budget V2 runtime state into the same host**

Move Budget V2 frame construction, avatar selection/filter callbacks, limit
preview revision, and V2 dashboard assembly to `SpendeeBudgetModeHost`.
Do not let Budget V2 route through `SpendeeBalanceModeHost`.

- [ ] **Step 5: Preserve the existing interactive contracts**

Keep existing carousel settling, delayed filter publication, avatar long
press, category filtering, and menu keys.  The tests must prove a variant
switch preserves the store filter while the old host is disposed.

- [ ] **Step 6: Run Budget regressions and commit**

Run the three tests listed above plus
`spendee_dashboard_mode_host_test.dart`.  Commit only task files with:

```sh
git commit -m "refactor(budget): extract budget mode host"
```

### Task 4: Extract the Mind data-flow host

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/modes/spendee_mind_mode_host.dart`
- Modify: `test/spendeetest/spendee_mind_stats_adapter_test.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`
- Modify: `test/spendeetest/spendee_dashboard_mode_host_test.dart`

**Interfaces:**
- Consumes: `SpendeeDashboardModeFamily.mind`, shared menu presentation values, and `TransactionStore`.
- Produces: `SpendeeMindModeHost`, owner of Mind frames, caches, time rail, and Mind-only animation state.

- [ ] **Step 1: Write the failing Mind-host disposal test**

```dart
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.mind));
await tester.pumpWidget(buildDashboard(mode: SpendeeDashboardMode.balance));
expect(find.byKey(const ValueKey('spendee-mode-host-mind')), findsNothing);
expect(disposedMindHostCount, 1);
```

- [ ] **Step 2: Run the test and verify RED**

Run `spendee_dashboard_mode_host_test.dart` in Ubuntu/proot.  Expected: Mind
cache/controller ownership remains in the facade.

- [ ] **Step 3: Move Mind-only state and render assembly into the host**

Move Mind statistics frame caches, sum-year cache, selected/published year,
time-rail presentation notifier, year carousel controller, and Mind render
assembly into `SpendeeMindModeHost`.  Pass the unchanged menu callbacks and
presentation configuration in.

- [ ] **Step 4: Ensure host disposal clears Mind lifecycle resources**

Cancel/dispose every Mind timer, notifier, and animation controller in the
host's `dispose`.  Do not leave a Mind widget cache in the facade.

- [ ] **Step 5: Run Mind regressions and commit**

Run `spendee_mind_stats_adapter_test.dart`,
`spendee_dashboard_interaction_test.dart`, and
`spendee_dashboard_mode_host_test.dart`.  Commit only task files with:

```sh
git commit -m "refactor(mind): extract mind mode host"
```

### Task 5: Finalize the single-active-host lifecycle and verification

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_mode_host_test.dart`
- Modify: `docs/superpowers/checklists/2026-07-30-three-mode-host-refactor.md`

**Interfaces:**
- Consumes: all three extracted hosts and the complete mode mapping.
- Produces: a facade with no mode-specific runtime cache/controller and a
  fully verified three-host lifecycle.

- [ ] **Step 1: Write the final five-variant switch test**

```dart
for (final mode in SpendeeDashboardMode.values) {
  await tester.pumpWidget(buildDashboard(mode: mode));
  expect(find.byKey(ValueKey('spendee-mode-host-${mode.family.name}')), findsOneWidget);
  expect(find.byType(IndexedStack), findsNothing);
}
```

- [ ] **Step 2: Run the test and verify RED**

Run the host test before removing residual facade caches.  Expected: at least
one old retained mode-stack/cache path remains.

- [ ] **Step 3: Remove residual inactive-host retention**

Delete obsolete facade caches and mode-level `IndexedStack` branches.  Keep
all menu action values, widget keys, and callbacks unchanged.

- [ ] **Step 4: Run final local verification**

Run in Ubuntu/proot:

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_dashboard_mode_test.dart test/spendeetest/spendee_dashboard_mode_host_test.dart test/spendeetest/spendee_dashboard_foundation_test.dart test/spendeetest/spendee_dashboard_interaction_test.dart test/spendeetest/spendee_balance_dashboard_test.dart test/spendeetest/spendee_balance_v2_contract_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_mind_stats_adapter_test.dart --reporter compact --timeout 180s'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze --no-pub lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart lib/features/transactions/widgets/experimental/spendee_dashboard_mode.dart lib/features/transactions/widgets/experimental/modes test/spendeetest/spendee_dashboard_mode_test.dart test/spendeetest/spendee_dashboard_mode_host_test.dart'
```

- [ ] **Step 5: Update the checklist and commit**

Set each MODE item to `DONE` only when its listed verification evidence has
passed.  Run `git diff --check`, stage only the refactor files, tests, and the
new checklist, then commit with:

```sh
git commit -m "refactor(dashboard): isolate three mode data flows"
```

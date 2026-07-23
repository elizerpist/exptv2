# Spendee Mind D1-D5 Header Stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Color Lab Mind D1-D5 header/background flow to the Flutter Spendee test dashboard with live Stats data and configurable glass softness.

**Architecture:** Keep `SpendeeTestDashboard` as the integration point, but put live Stats frame creation in a focused adapter. Add D widgets in the experimental dashboard area and use the existing C2, liquid, Acrylic, and old glass wrappers with scoped softness values.

**Tech Stack:** Flutter widgets, existing `TransactionStore`, `StatsRenderFrame`, `StatsCategoryScopeSeries`, `StatsYearData`, `liquid_glass_renderer` native fallback wrapper, `fluent_ui` Acrylic wrapper.

## Global Constraints

- The source of truth is `docs/prototypes/color_lab.html`, not an approximate memory of the screenshots.
- No local Flutter APK build on Termux/Android.
- Run Flutter tests and analyze inside Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Do not revert unrelated dirty files.
- Completion requires the acceptance checklist to show `DONE` or an explicit deferral for every requested item.

---

### Task 1: Live Mind Stats Adapter

**Files:**
- Create: `lib/features/transactions/widgets/experimental/spendee_mind_stats_adapter.dart`
- Test: `test/spendeetest/spendee_mind_stats_adapter_test.dart`

**Interfaces:**
- Produces: `SpendeeMindStatsFrame.fromStore(TransactionStore store)` with `activeFrame`, `expenseFrame`, `incomeFrame`, `summaryScope`, `periodLabel`, and `modeKey`.
- Consumes: `StatsRenderFrame.build`, `defaultStatsThreshold`, `TransactionStore`.

- [ ] **Step 1: Write failing adapter tests**

```dart
test('mind stats frame maps summary windows to stats scopes', () async {
  final store = TransactionStore(_MindStatsRepository(), clock: () => DateTime(2026, 7, 18));
  await store.start();
  expect(SpendeeMindStatsFrame.fromStore(store).summaryScope, StatsSummaryScope.allTime);
  await store.setSummaryYear(2026);
  expect(SpendeeMindStatsFrame.fromStore(store).summaryScope, StatsSummaryScope.yearly);
  await store.setSummaryMonth(2026, 7);
  expect(SpendeeMindStatsFrame.fromStore(store).summaryScope, StatsSummaryScope.monthly);
});

test('mind stats frame exposes live expense and income chart series', () async {
  final store = TransactionStore(_MindStatsRepository(), clock: () => DateTime(2026, 7, 18));
  await store.start();
  await store.setSummaryYear(2026);
  final frame = SpendeeMindStatsFrame.fromStore(store);
  expect(frame.expenseFrame.categoryScopeSeries.scoreLine, isNotEmpty);
  expect(frame.expenseFrame.categoryScopeSeries.helperBars, isNotEmpty);
  expect(frame.incomeFrame.categoryScopeSeries.scoreLine, isNotEmpty);
  expect(frame.incomeFrame.categoryScopeSeries.incomeComparisonBars, isNotEmpty);
});
```

- [ ] **Step 2: Run RED**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_mind_stats_adapter_test.dart --reporter expanded'`

Expected: fails because `spendee_mind_stats_adapter.dart` does not exist.

- [ ] **Step 3: Implement adapter**

Build expense and income frames with `StatsRenderFrame.build`, mapping `SummaryWindow.allTime/yearly/monthly` to `StatsSummaryScope.allTime/yearly/monthly`, passing store transactions, categories, active merchant filters, active query, reference year/month, and `defaultStatsThreshold`.

- [ ] **Step 4: Run GREEN**

Run the same test command and expect PASS.

### Task 2: D Header State And Swipe Loop

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Test: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Produces: `_MindHeaderPage { d1, d2, d3g, d4, d5 }`, `_HeaderBackgroundMode { budget, mind }`, horizontal swipe handlers, and stable keys `spendee-test-mind-page-d1` through `spendee-test-mind-page-d5`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('header background menu enables mind d pages and swipes in a loop', (tester) async {
  await _pumpDashboard(tester);
  await _openHeaderDesignMenu(tester);
  await tester.tap(find.byKey(const ValueKey('spendee-test-header-background-mind')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('spendee-test-mind-page-d1')), findsOneWidget);
  await tester.drag(find.byKey(const ValueKey('spendee-test-header-background-swipe')), const Offset(-180, 0));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('spendee-test-mind-page-d2')), findsOneWidget);
  for (var i = 0; i < 4; i += 1) {
    await tester.drag(find.byKey(const ValueKey('spendee-test-header-background-swipe')), const Offset(-180, 0));
    await tester.pumpAndSettle();
  }
  expect(find.byKey(const ValueKey('spendee-test-mind-page-d1')), findsOneWidget);
});
```

- [ ] **Step 2: Run RED**

Run the named test and expect missing-key failure.

- [ ] **Step 3: Implement state and menu action**

Add the enum state, menu section, action switch, `GestureDetector` around the header background, and infinite page stepping.

- [ ] **Step 4: Run GREEN**

Run the named test and expect PASS.

### Task 3: Mind D Stage Layouts

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Test: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Consumes: `SpendeeMindStatsFrame`.
- Produces: D1 score ribbon, D2 boxed graphs, D3G yearly heatmap, D4 monthly heatmap, D5 sum heatmap.

- [ ] **Step 1: Write failing tests**

Assert that stage0 contains `spendee-test-mind-score-ribbon`, stage1 contains `spendee-test-mind-stage1-boxed-graphs`, and stage2 chooses `spendee-test-mind-stage2-monthly`, `spendee-test-mind-stage2-yearly`, or `spendee-test-mind-stage2-sum` when the summary pill/store window changes.

- [ ] **Step 2: Run RED**

Run the named widget tests and expect missing-key failures.

- [ ] **Step 3: Implement D widgets**

Translate the Color Lab layout constants into Flutter: orange/yellow/green header background, score ribbon at bottom, two boxed graph cards in stage1, and heatmap cards/cells in stage2. Use real frame data for values and graph samples.

- [ ] **Step 4: Run GREEN**

Run the named widget tests and expect PASS.

### Task 4: Surface Choices And Softness Sliders

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_liquid_glass_surface_stub.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_liquid_glass_surface_native.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_acrylic_surface.dart`
- Test: `test/spendeetest/spendee_dashboard_interaction_test.dart`

**Interfaces:**
- Produces scoped softness values for Budget avatar/chart/list and Mind stage1/stage2/list containers.

- [ ] **Step 1: Write failing tests**

Assert sliders with keys such as `spendee-test-budget-stage1-softness-slider`, `spendee-test-budget-stage2-softness-slider`, `spendee-test-mind-stage1-softness-slider`, and `spendee-test-mind-stage2-softness-slider` are visible for matching sections and only update their own rendered surface keys/values.

- [ ] **Step 2: Run RED**

Run the named widget tests and expect missing-key failures.

- [ ] **Step 3: Implement scoped sliders**

Replace the header-only slider entry with a reusable popup slider entry. Pass softness into C2, liquid, Acrylic, and old glass wrappers through scoped state.

- [ ] **Step 4: Run GREEN**

Run the named widget tests and expect PASS.

### Task 5: Full Verification And Server Restart

**Files:**
- Update: `docs/superpowers/checklists/2026-07-18-spendee-mind-d1-d5-header-stats.md`

- [ ] **Step 1: Format**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/dart format lib/features/transactions/widgets/experimental test/spendeetest docs/superpowers/checklists docs/superpowers/specs docs/superpowers/plans'`

- [ ] **Step 2: Run tests**

Run targeted adapter and dashboard tests, then the existing Spendee regression bundle if targeted tests pass.

- [ ] **Step 3: Analyze**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze'`

- [ ] **Step 4: Restart web server**

Stop the old Flutter web process and start `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8766` in the background. Verify `curl http://127.0.0.1:8766/` returns `200`.

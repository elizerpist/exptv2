# Stage2 Vendor Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a second stage2 page that shows vendor shares for the selected category using the existing chart/list design.

**Architecture:** Keep the current category chart as the first stage2 page. Add a dashboard state enum for the active stage2 page, aggregate vendor rows from `TransactionStore.windowedTransactions`, and reuse the same glass/background panel wrapper for both pages. Stage2 side chevrons switch pages.

**Tech Stack:** Flutter widgets, existing `TransactionStore`, existing `flutter_test` widget tests.

## Global Constraints

- No APK build in Termux.
- Run Flutter tests/analyze through Ubuntu proot.
- Use TDD: failing widget tests before production code.
- Do not change the current chart/list visual design except the requested page switching controls and vendor data.

---

### Task 1: Stage2 Vendor Page

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_dashboard_interaction_test.dart`
- Modify: `docs/superpowers/checklists/2026-07-18-spendee-stage1-header-controls.md`

**Interfaces:**
- Consumes: `TransactionStore.windowedTransactions`, `TransactionRecord.displayMerchant`, current `CategoryBudgetBarData` chart data.
- Produces: `_Stage2BudgetPage`, vendor share entries, stage2 chevron controls, vendor chart/list page.

- [ ] **Step 1: Write failing tests**

Add widget tests that drag to stage2, tap a chevron, and expect vendor rows for the selected category. Add assertions that chart background mode also wraps the vendor page.

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_dashboard_interaction_test.dart --plain-name "stage 2 chevrons switch to live vendor share for selected category"'
```

Expected: FAIL because chevron/vendor page keys do not exist yet.

- [ ] **Step 3: Implement minimal production code**

Add stage2 page state, pass `windowedTransactions` to the header, build vendor share rows from the selected category, and reuse the existing panel wrapper and chart/list layout.

- [ ] **Step 4: Run targeted and regression verification**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_center_carousel_inertia_test.dart test/spendeetest/spendee_dashboard_foundation_test.dart test/spendeetest/spendee_dashboard_interaction_test.dart && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: all targeted tests pass and analyzer reports no issues.

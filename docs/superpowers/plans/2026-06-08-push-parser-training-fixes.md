# Push Parser Training Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make push-log training create reusable app-bound parser profiles, automatically create uncategorized transactions from learned push formats, remove June 2026 seed transactions from the next build, and fix settings menu restore semantics.

**Architecture:** Keep push capture eligibility separate from transaction creation. `NotificationEventRepository` captures eligible notifications, then calls recurring push matching and a new normal parser-profile transaction creation path. Flutter training remains responsible for choosing amount/merchant from a message and saving an enabled app-bound profile before creating the currently selected log.

**Tech Stack:** Flutter/Dart widgets and stores, Android Kotlin Room repositories, GitHub Actions APK build.

---

### Task 1: Seed Data Excludes June 2026 Transactions

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt`
- Modify: `test/android_seed_data_test.dart`

- [ ] **Step 1: Write failing seed text test**

Add assertions that the seed version is `2026060801` and that the generator contains `if (year == 2026 && month == 6)`.

- [ ] **Step 2: Implement seed skip**

Bump `ExpenseSeedData.version` to `2026060801`. Inside `buildTransactions()`, after `year/month` calculation and before `expenseCount`, add:

```kotlin
if (year == 2026 && month == 6) {
    monthOffset += 1
    continue
}
```

- [ ] **Step 3: Verify through CI**

Local Flutter test is blocked on Termux Dart TLS alignment, so run `git diff --check` locally and rely on GitHub Actions for `flutter test` and APK build.

### Task 2: Position-Aware Training Tokens and Preview

**Files:**
- Modify: `lib/features/settings/models/notification_parser_rule.dart`
- Modify: `test/settings/notification_parser_rule_test.dart`

- [ ] **Step 1: Write failing parser model tests**

Add tests for the exact user sample:

```dart
const sample =
    "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n"
    "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.";
```

Expected behavior:
- tokens include `3 085 Ft`, `71 795,87 Ft`, `itt`, and `nyírő`
- selecting `3 085 Ft` and `nyírő` produces preview amount `3085` and merchant `nyírő`
- selecting the second amount produces preview amount `71795.87`

- [ ] **Step 2: Implement position-aware amount learning**

Update `learnAmountFromSelection()` so it finds all amount-like matches in normalized sample text, matches the selected normalized text, and builds a regex anchored by the selected occurrence's left/right context where possible. Keep the generic fallback when no sample occurrence is found.

- [ ] **Step 3: Include colon words in tokens**

Update `NotificationTrainingToken.fromSample()` so normal words are cleaned from punctuation instead of dropping words that contain `:`, allowing `itt` to appear.

### Task 3: Push Log Training Creates a New App-Bound Profile

**Files:**
- Modify: `lib/features/settings/state/push_notification_log_store.dart`
- Modify: `test/settings/push_notification_log_store_test.dart`

- [ ] **Step 1: Write failing store test**

Assert that `trainAndCreateTransaction()` saves a new enabled profile whose `packageName` and `appLabel` come from the event, while the original profile remains present.

- [ ] **Step 2: Implement profile creation**

Create a new profile before saving:
- id: `push-log-${event.id}`
- name: `${event.appLabel} minta`
- enabled: true
- appFilterText: event app label
- packageName: event package
- appLabel: event label
- rule: trained rule from selected tokens

Use this profile for the manual transaction preview and save.

### Task 4: Normal Parser Profiles Auto-Create Uncategorized Transactions

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt`

- [ ] **Step 1: Write native parser regression test**

Add a `PushRecurringParserTest` case proving the user sample parses amount `3085.0` and merchant `nyírő` with the learned patterns.

- [ ] **Step 2: Expose active parser profile rows**

Add `activeParserProfiles()` in `NotificationParserRuleStore`, returning enabled rows with rule and app fields.

- [ ] **Step 3: Add normal parser processing**

After capture insert, call normal parser processing before/after recurring matching. It should:
- skip duplicates
- skip if a transaction already exists for `sourceNotificationEventId`
- check profile package/app eligibility
- parse notification text with profile rule
- create an uncategorized transaction with `sourceNotificationEventId`
- log `[PushParser] auto transaction ...` success/skip reasons

### Task 5: Settings Menu Name and Restore Semantics

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Write failing settings behavior tests**

Assert the settings root option label is `Push import`. Assert bottom-nav away and back opens settings root, while recreating settings with the same store restores the last submenu.

- [ ] **Step 2: Rename labels**

Replace `Megfigyelni kívánt alkalmazás` submenu labels with `Push import`.

- [ ] **Step 3: Reset settings submenu on active bottom-nav leave**

When bottom nav switches away from settings, clear the settings active menu key to root. Do not clear it from lifecycle resume/recreate.

### Task 6: CI and APK

**Files:**
- No production files.

- [ ] **Step 1: Local cheap verification**

Run:

```bash
git diff --check
```

- [ ] **Step 2: Commit and push**

Commit focused changes and push `feature/push-log-parser-training-fixes`.

- [ ] **Step 3: Build online**

Run GitHub workflow `Exptv2 Android APK Build` on `feature/push-log-parser-training-fixes`.

- [ ] **Step 4: Report APK link**

After success, verify the `debug-latest` release asset and report:

```text
https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk
```

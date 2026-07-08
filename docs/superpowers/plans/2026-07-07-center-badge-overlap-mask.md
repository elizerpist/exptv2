# Center Badge Overlap Mask Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional colored Center Badge overlap mask so translucent badges do not reveal badges rendered underneath them.

**Architecture:** Store a new boolean in `AppThemeSettings` and native settings persistence. Expose it as a Backheader settings switch. Pass it through `TransactionHomePage -> CategoryBudgetStage -> BackheaderStyleSurface -> _CenterBadgeVisual`, where colored mode draws an opaque background-matching circular matte behind each badge before painting translucent white layers.

**Tech Stack:** Flutter/Dart widget tests, Android Kotlin settings store test, Ubuntu proot for local Flutter test/analyze, GitHub Actions for APK build when delivery is requested.

## Global Constraints

- Run Flutter tests/analyze through Ubuntu proot.
- Do not run local APK builds on Termux/Android.
- Default visual behavior must remain unchanged until the user enables the switch.
- The overlap mask must affect only `BackheaderCenterDesign.colored`; neutral Center Badge rendering must remain unchanged.
- Use TDD: write and run failing tests before implementation code.

---

### Task 1: Settings And Persistence

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`
- Test: `test/settings/backheader_style_options_panel_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

**Interfaces:**
- Produces: `AppThemeSettings.centerBadgeOverlapMaskEnabled`.
- Consumes: existing center badge settings serialization and native theme update flow.

- [x] Add failing Flutter model/bridge tests for default `false`, map round-trip, and platform payload.
- [x] Add failing Android store round-trip test source for `centerBadgeOverlapMaskEnabled`.
- [x] Implement the new setting field, `fromMap`, `toMap`, `copyWith`, and native load/save.
- [x] Re-run targeted settings tests through Ubuntu proot.

### Task 2: Settings Switch

**Files:**
- Modify: `lib/features/settings/widgets/options/backheader_style_options_panel.dart`
- Test: `test/settings/backheader_style_options_panel_test.dart`

**Interfaces:**
- Consumes: `AppThemeSettings.centerBadgeOverlapMaskEnabled`.
- Produces: switch key `center-badge-overlap-mask-toggle`.

- [x] Add failing widget test that finds and toggles the new switch.
- [x] Add a Center Badge settings switch labelled for overlap masking with copy explaining colored-mode-only behavior.
- [x] Re-run the settings panel test through Ubuntu proot.

### Task 3: Colored Render Mask

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

**Interfaces:**
- Consumes: `centerBadgeOverlapMaskEnabled`.
- Produces: background-colored circular matte key `backheader-center-overlap-mask` for active and preview badge visuals when colored mode and the switch are enabled.

- [x] Add failing colored render test that expects the matte only when enabled.
- [x] Add failing neutral render test that proves the switch has no effect in neutral mode.
- [x] Pass the setting through the transaction header widgets.
- [x] Paint an opaque matte circle behind each badge footprint before the translucent disc/icon/progress layers in colored mode only.
- [x] Re-run targeted Center Badge tests through Ubuntu proot.

### Task 4: Verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-06-center-badge-backheader-partition-checklist.md`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: honest checklist statuses and final verification evidence.

- [x] Run targeted Flutter tests in Ubuntu proot.
- [x] Run `flutter analyze` in Ubuntu proot.
- [x] Run full Flutter test suite in Ubuntu proot if targeted tests and analyze pass.
- [x] Update checklist statuses with evidence.

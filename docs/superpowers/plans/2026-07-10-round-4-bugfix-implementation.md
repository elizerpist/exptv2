# Round 4 Bugfix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement BUG4-001 through BUG4-008 from `docs/superpowers/checklists/2026-07-10-design-bugfix-round-4-checklist.md`, commit each completed checklist item separately, push once, run one GitHub Actions Android build, and download the final APK.

**Architecture:** Keep fixes inside the existing transaction store, transaction home page, shared slide-up sheet, logbox, icon, and category/vendor widget boundaries. Prefer targeted state/cache helpers and widget behavior fixes over broad refactors. Preserve existing UI patterns, especially category-card neumorph behavior as the reference for vendor/logbox press states.

**Tech Stack:** Flutter/Dart, existing widget tests, existing `DebugConsole`, Ubuntu proot Flutter commands for local tests/analyze, GitHub Actions for APK build.

## Global Constraints

- Do not run local Flutter APK builds in Termux/Android.
- Run Flutter tests/analyze through Ubuntu proot: `proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test ...'`.
- Update the checklist honestly; completion requires every item `DONE` or user-approved deferral.
- Commit each completed checklist item separately after verification passes.
- Push only once after all checklist items are implemented, verified, and committed.
- Download the final APK to `/storage/emulated/0/Download/exptv2`.

---

### Task 1: BUG4-001 Lag Measurement And Filter Responsiveness

**Files:**
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/transaction_store_test.dart`
- Update: `docs/superpowers/checklists/2026-07-10-design-bugfix-round-4-checklist.md`

- [ ] Add/adjust focused tests proving visible log/filter caches are reused and invalidated correctly on type, merchant, category, search, and summary changes.
- [ ] Verify the test fails if cache/prewarm behavior is missing.
- [ ] Add bounded `[Perf]` logs around type-switch and fastfilter tap/state/frame phases.
- [ ] Reduce duplicate recomputation by reusing store-visible values within the home page build and prewarming active views after filter changes.
- [ ] Run targeted store/home tests through Ubuntu proot.
- [ ] Mark BUG4-001 `DONE` and commit.

### Task 2: BUG4-002 Category Editor Keyboard-Stable Layout

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_sheet.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`
- Modify as needed: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Test: `test/transactions/slide_up_menu_card_test.dart`
- Test: `test/transactions/category_editor_test.dart`
- Update checklist.

- [ ] Add a widget test with keyboard insets proving the category editor inner panel metrics stay stable.
- [ ] Verify red against the current regression if present.
- [ ] Keep keyboard movement at the sheet level only and prevent inset-driven inner layout changes.
- [ ] Run targeted tests.
- [ ] Mark BUG4-002 `DONE` and commit.

### Task 3: BUG4-003 Vendor Neumorph Card/Avatar Sync

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/category_menu_test.dart`
- Update checklist.

- [ ] Add/adjust a vendor row test that asserts card and avatar surfaces share the same pressed/selected phase in press-effect mode.
- [ ] Verify red when avatar/card states are independent.
- [ ] Mirror the category card effective-pressed pattern for vendor cards.
- [ ] Run targeted vendor/category menu tests.
- [ ] Mark BUG4-003 `DONE` and commit.

### Task 4: BUG4-004 Vendor Avatar Category Icon Fallback

**Files:**
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/transaction_store_test.dart`
- Test: `test/transactions/category_menu_test.dart`
- Update checklist.

- [ ] Add store tests proving deterministic dominant category icon/color projection and unknown fallback.
- [ ] Add widget tests proving vendor avatars render category icons or gray question fallback.
- [ ] Implement category/icon projection on `VendorFilterSummary` and render it in vendor rows.
- [ ] Run targeted tests.
- [ ] Mark BUG4-004 `DONE` and commit.

### Task 5: BUG4-005 SummaryPill-Scoped Vendor/Category Counts

**Files:**
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_card.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Test: `test/transactions/transaction_store_test.dart`
- Test: `test/transactions/category_menu_test.dart`
- Update checklist.

- [ ] Add store tests for all-time/year/month summary windows proving vendor summaries and category counts use the active window.
- [ ] Add widget tests proving vendor cards show counts and category cards remain visible with `0`.
- [ ] Implement window-scoped count derivation without hiding category cards.
- [ ] Run targeted tests.
- [ ] Mark BUG4-005 `DONE` and commit.

### Task 6: BUG4-006 Logbox Icon Startup Timing And Debug Logs

**Files:**
- Modify: `lib/features/transactions/slots/category_icon_manager.dart`
- Modify: `lib/features/transactions/widgets/category_slot_icon.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify as needed: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Update checklist.

- [ ] Add tests proving icon assets/preferences are warmed before visible logbox icon rendering.
- [ ] Add bounded `[IconLoad]` and `[LogBoxIcon]` logs for preference load, warmup, first list build, and first icon ready/render.
- [ ] Implement icon warmup/cache path that removes visible delayed blank icon pop-in.
- [ ] Run targeted tests.
- [ ] Mark BUG4-006 `DONE` and commit.

### Task 7: BUG4-007 Logbox Neumorph Body/Avatar Press

**Files:**
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Update checklist with root-cause note and DONE status.

- [ ] Document root cause: why current passing tests did not catch the manual failure.
- [ ] Add failing pointer-coordinate tests for avatar-only tap and body-only tap.
- [ ] Implement one press-state model where body press forces avatar press, while avatar tap does not force body press.
- [ ] Verify callback counts and visual release timing.
- [ ] Run targeted tests.
- [ ] Mark BUG4-007 `DONE` and commit.

### Task 8: BUG4-008 Vendor Keyboard Footer-Only Lift

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify as needed: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Test: `test/transactions/category_menu_test.dart`
- Update checklist with root-cause note and DONE status.

- [ ] Document root cause: current vendor TDD expected whole-sheet `-keyboardInset` movement.
- [ ] Replace the wrong assertion with tests comparing no-keyboard and keyboard rectangles for header/search/list stability plus footer lift.
- [ ] Disable whole-sheet keyboard transform for vendor sheets and lift/pad only the vendor footer/list area.
- [ ] Run targeted tests.
- [ ] Mark BUG4-008 `DONE` and commit.

### Task 9: Final Verification, Push, Build, Download

**Files:**
- Verify all touched files.
- Update checklist only if any verification status changes.

- [ ] Run focused tests for all modified transaction widgets/store paths.
- [ ] Run `flutter analyze` through Ubuntu proot.
- [ ] Run broader Flutter tests if feasible through Ubuntu proot.
- [ ] Ensure every checklist item is `DONE`.
- [ ] Push branch once to origin.
- [ ] Watch GitHub Actions Android build for the pushed commit.
- [ ] Download the final debug APK from GitHub release/artifact into `/storage/emulated/0/Download/exptv2`.

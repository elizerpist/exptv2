# Transaction Export Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add transaction export options for local CSV file save, CSV share, clipboard copy, and a disabled Google Sheets placeholder.

**Architecture:** Keep CSV generation in a focused Dart service, expose export actions from the existing Settings export submenu, and use the existing native bridge pattern for Android file save/share operations. Google API is intentionally not implemented in this slice.

**Tech Stack:** Flutter/Dart, Android Kotlin MethodChannel, existing transaction repository/native bridge, Flutter widget/unit tests.

---

### Task 1: CSV Export Model And Formatter

**Files:**
- Create: `lib/features/transactions/export/transaction_csv_exporter.dart`
- Test: `test/transactions/transaction_csv_exporter_test.dart`

- [ ] Write failing unit tests for header order, transaction rows, CSV escaping, category labels, and recurring flag.
- [ ] Implement a small `TransactionCsvExporter` with `buildCsv(transactions, categories)`.
- [ ] Verify with `flutter test test/transactions/transaction_csv_exporter_test.dart`.

### Task 2: Flutter Export Service And Bridge Contract

**Files:**
- Create: `lib/features/transactions/export/transaction_export_service.dart`
- Modify: `lib/services/native_bridge.dart`
- Test: `test/transactions/transaction_export_service_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] Write failing tests for exporting all paged transactions, clipboard text generation, native save payload, and native share payload.
- [ ] Implement paged transaction loading using existing `TransactionPageQuery`.
- [ ] Add bridge methods for saving and sharing text files.
- [ ] Verify targeted tests.

### Task 3: Android File Save And Share

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Create or modify Kotlin helper near existing expense bridge code.
- Test: existing Android unit tests if local Gradle is available.

- [ ] Add method channel handlers for local CSV save and share.
- [ ] Save CSV into public Downloads through MediaStore on Android Q+ and legacy external Downloads where needed.
- [ ] Share CSV via `ACTION_SEND` and FileProvider/content URI.

### Task 4: Settings Export UI

**Files:**
- Create: `lib/features/settings/widgets/options/export_options_panel.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] Replace placeholder export submenu with actions: save file, share CSV, copy clipboard, Google Sheets later.
- [ ] Show concise success/error snackbars.
- [ ] Keep Google Sheets disabled/placeholder only.

### Task 5: Verification, Push, Build

**Files:**
- No source changes expected.

- [ ] Run Dart format.
- [ ] Run targeted Flutter tests.
- [ ] Run `flutter analyze`.
- [ ] Run full `flutter test` if practical.
- [ ] Commit all changes on `feature/transaction-export-options`.
- [ ] Push branch.
- [ ] Trigger GitHub Actions `android-build.yml` with `workflow_dispatch`.
- [ ] Report direct APK link from the `debug-latest` release.

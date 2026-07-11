# FAB Keyboard Sheet Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the normal AddTransaction FAB sheet off the native AddTransaction overlay and onto a Flutter sheet driven by `flutter_keyboard_controller`, with one coherent panel movement model.

**Architecture:** The main Flutter tree provides keyboard state through `KeyboardProvider`. AddTransaction opts into a controller-driven `SlideUpMenuCard` mode. The native IME host remains diagnostic-only for the normal app flow.

**Tech Stack:** Flutter, Dart, `flutter_keyboard_controller`, Android `WindowInsetsAnimationCompat` debug host retained for probe only.

## Global Constraints

- Run Flutter tests and analysis through Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Do not run local APK builds in Termux.
- Use targeted TDD for behavior changes.
- Keep unrelated untracked docs/prototypes untouched.
- Do not refactor unrelated sheets in this pass.

---

### Task 1: FAB Route Test

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/features/shell/expt_shell.dart`

**Interfaces:**
- Consumes: `_ShellSheetHostState.openTransaction({DateTime? requestedAt, String source, TransactionRecord? transaction})`
- Produces: FAB tap opens `AddTransactionSheet` through Flutter sheet host.

- [x] **Step 1: Write the failing test**

Update the existing FAB native-host test so a FAB tap asserts `openAddTransaction` is not called and `transaction-editor-card` appears.

- [x] **Step 2: Run RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart --plain-name "FAB opens Flutter add transaction sheet directly"'
```

Expected: fails because the current code calls `openAddTransaction`.

- [x] **Step 3: Implement shell route**

Change `_handleFabPressed` to call `_sheetHostKey.currentState?.openTransaction(...)` directly and stop suspending store/keyboard for native AddTransaction.

- [x] **Step 4: Run GREEN**

Run the same test and confirm it passes.

### Task 2: Keyboard Controller Sheet Mode

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/exptv2_app.dart`
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: relevant tests

**Interfaces:**
- Consumes: `flutter_keyboard_controller` `KeyboardProvider` and keyboard height notifier.
- Produces: `SlideUpMenuCard(useKeyboardController: true)` for AddTransaction.

- [x] **Step 1: Add dependency**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter pub add flutter_keyboard_controller:^1.0.4'
```

- [x] **Step 2: Write failing test**

Add a widget test that finds the AddTransaction `SlideUpMenuCard` and expects the controller-driven mode to be enabled.

- [x] **Step 3: Run RED**

Run the targeted test and confirm it fails before code changes.

- [x] **Step 4: Implement controller mode**

Wrap `Exptv2App` in `KeyboardProvider`, add opt-in controller keyboard mode to `SlideUpMenuCard`, and pass it from `AddTransactionSheet`.

- [x] **Step 5: Run GREEN**

Run the targeted test and confirm it passes.

### Task 3: Footer and Native Prewarm Cleanup

**Files:**
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NativeImeSheetHost.kt`
- Modify: tests as needed

**Interfaces:**
- Consumes: AddTransaction panel layout.
- Produces: scrollable form body with stable footer bottom padding; no normal-flow native AddTransaction prewarm.

- [x] **Step 1: Write failing test**

Add or update a widget test that asserts the AddTransaction body is scrollable and the save footer remains inside the sheet.

- [x] **Step 2: Run RED**

Run the targeted test and confirm it fails under the current conditional non-scrollable body/footer behavior.

- [x] **Step 3: Implement layout cleanup**

Make the AddTransaction body scrollable in Flutter sheet mode, remove keyboard-visible special footer padding, and remove automatic native AddTransaction prewarm.

- [x] **Step 4: Run GREEN**

Run targeted tests and confirm they pass.

### Task 4: Verification and Checklist

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-fab-keyboard-sheet-refactor-checklist.md`

- [x] **Step 1: Run targeted widget tests**

Run the FAB route and sheet layout tests through Ubuntu proot.

- [x] **Step 2: Run Flutter analysis**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

- [x] **Step 3: Update checklist**

Set each requirement to `DONE`, `PARTIAL`, or `BLOCKED` based on verified evidence.

- [x] **Step 4: Commit and push**

Commit only the relevant implementation, tests, dependency lockfile, and docs.

# Native IME Sheet Host Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a measurable Android-native IME-follow sheet host proof of concept with Flutter-only diagnostic content.

**Architecture:** Android owns the moving container and applies IME translation from `WindowInsetsAnimationCompat.Callback.onProgress`. Flutter owns a small probe UI hosted inside the native container and communicates only semantic open/close events.

**Tech Stack:** Kotlin Android embedding, Flutter `MethodChannel`, dedicated Dart entrypoint, existing Debug Console, Flutter widget tests, Android unit tests.

## Global Constraints

- Do not replace production AddTransaction behavior in this pass.
- Do not stream per-frame IME motion through Dart for the probe.
- Keep the native host lifecycle scoped to explicit Debug Console open/close.
- Run Flutter tests/analyze inside Ubuntu proot.
- Do not run local Flutter APK builds on Termux/Android.

---

### Task 1: Native Motion Model

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/NativeImeSheetMotion.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/NativeImeSheetMotionTest.kt`

**Interfaces:**
- Produces: `object NativeImeSheetMotion { fun translationYForIme(imeBottomPx: Int): Float }`

- [ ] **Step 1: Write the failing Android unit test**

```kotlin
assertEquals(-252f, NativeImeSheetMotion.translationYForIme(252))
assertEquals(0f, NativeImeSheetMotion.translationYForIme(-4))
```

- [ ] **Step 2: Run the Android unit test and verify it fails**

Run:
```bash
./gradlew testDebugUnitTest --tests com.exptv2.app.NativeImeSheetMotionTest
```

- [ ] **Step 3: Implement `NativeImeSheetMotion`**

```kotlin
object NativeImeSheetMotion {
    fun translationYForIme(imeBottomPx: Int): Float = -imeBottomPx.coerceAtLeast(0).toFloat()
}
```

- [ ] **Step 4: Re-run the Android unit test and verify it passes**

### Task 2: Flutter Debug Entry Point and Bridge

**Files:**
- Create: `lib/services/native_ime_sheet_bridge.dart`
- Create: `lib/features/diagnostics/native_ime_sheet_probe.dart`
- Modify: `lib/main.dart`
- Modify: `lib/core/debug/debug_console.dart`
- Modify: `lib/core/debug/debug_floating_button.dart`
- Test: `test/core/debug_floating_button_test.dart`

**Interfaces:**
- Produces: `NativeImeSheetBridge.openProbe()`
- Produces: `@pragma('vm:entry-point') Future<void> nativeImeSheetMain()`

- [ ] **Step 1: Write a failing widget test**

Tap the Debug Console native IME probe button and expect a method-channel call named `openProbe`.

- [ ] **Step 2: Run the widget test and verify it fails**

Run:
```bash
/home/flutteruser/flutter/bin/flutter test test/core/debug_floating_button_test.dart --plain-name "debug console can open native IME sheet probe"
```

- [ ] **Step 3: Implement the bridge, button, and probe entrypoint**

Use `MethodChannel('exptv2/native_ime_sheet')`, method names `openProbe` and `closeProbe`, and a simple probe app with two `TextField`s.

- [ ] **Step 4: Re-run the widget test and verify it passes**

### Task 3: Native Host and MainActivity Wiring

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/NativeImeSheetHost.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`

**Interfaces:**
- Consumes: `NativeImeSheetMotion.translationYForIme`
- Produces: `NativeImeSheetHost.attachMainChannel(MethodChannel)`
- Produces: `openProbe()` and `closeProbe()` native method handlers

- [ ] **Step 1: Add native host implementation**

Create a full-screen native overlay with a bottom-aligned moving container. Attach `WindowInsetsAnimationCompat.Callback` to the host and apply `sheetContainer.translationY = NativeImeSheetMotion.translationYForIme(ime.bottom)`.

- [ ] **Step 2: Embed FlutterView**

Start a dedicated cached `FlutterEngine` with the Dart entrypoint `nativeImeSheetMain`, attach a `FlutterView`, and add it to the moving container.

- [ ] **Step 3: Wire `MainActivity`**

Attach `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exptv2/native_ime_sheet")` to the native host.

- [ ] **Step 4: Run Kotlin unit tests and Flutter analyze**

Run Android unit test and Flutter analyze in proot.

### Task 4: Verification and Checklist

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-10-native-ime-sheet-host-checklist.md`

**Interfaces:**
- Consumes: all previous task outputs.

- [ ] **Step 1: Run targeted Flutter tests**
- [ ] **Step 2: Run targeted Android unit tests**
- [ ] **Step 3: Run Flutter analyze**
- [ ] **Step 4: Update checklist statuses honestly**

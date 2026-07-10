# Keyboard Slide Lag Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the visual keyboard-motion path with a local Flutter animation session so the AddTransaction sheet does not wait on sparse async native samples.

**Architecture:** Android reports IME animation session metadata instead of being the direct per-frame visual source. Flutter parses those session events, drives a local controller/ticker for active transitions, and snaps to `viewInsets.bottom` outside active sessions. The slide-up card reads a single effective inset and applies it only to the transform.

**Tech Stack:** Flutter, Dart widget/unit tests, Android Kotlin, `WindowInsetsAnimationCompat`, GitHub Actions APK workflow.

## Global Constraints

- Focus only on keyboard slide lag; do not change sheet gap/layout behavior.
- Keep AddTransaction `saveGap` and stable panel behavior untouched.
- Run Flutter tests/analyze through Ubuntu proot; APK builds run on GitHub Actions.
- Keep the final branch as a single bugfix commit by amending the existing squashed commit.

---

### Task 1: Dart IME Session Model

**Files:**
- Modify: `lib/core/keyboard/native_keyboard_insets.dart`
- Test: `test/core/keyboard/native_keyboard_insets_test.dart`

**Interfaces:**
- Produces: `NativeKeyboardAnimationSession.fromEvent(Object? event)`, `KeyboardAnimationPhase`, and `KeyboardInsetMotionCoordinator`.
- Consumes: existing `NativeKeyboardInsetSample` and fallback inset values.

- [ ] Write RED tests proving a fresh-but-lagging native sample does not directly drive visual inset when a session/fallback is ahead.
- [ ] Implement the session model and local interpolation coordinator.
- [ ] Keep stale fallback behavior for idle periods.

### Task 2: Flutter Follower Visual Path

**Files:**
- Modify: `lib/core/keyboard/keyboard_inset_follower.dart`
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Test: `test/transactions/slide_up_menu_card_test.dart`

**Interfaces:**
- Consumes: `KeyboardInsetMotionCoordinator.resolve(...)`.
- Produces: stable `KeyboardInsetMetrics.animatedInset` based on local animation value.

- [ ] Write RED widget test with a counted child showing keyboard animation ticks do not rebuild the sheet child subtree.
- [ ] Wire the follower to own a local animation controller/ticker.
- [ ] Keep `SlideUpMenuCard` transform-only keyboard movement.

### Task 3: Android Session Events

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NativeKeyboardInsetChannel.kt`

**Interfaces:**
- Produces EventChannel maps with `kind=session`, `phase=start|progress|end`, `startImeDp`, `endImeDp`, `imeDp`, `durationMs`, `fraction`, `eventNanos`.
- Consumes Android `WindowInsetsAnimationCompat`.

- [ ] Emit compact session events rather than treating every native progress sample as the visual source.
- [ ] Preserve diagnostic fields needed to compare native callback time, Dart receive time, and Flutter frame time.

### Task 4: Verification and Delivery

**Files:**
- Modify: checklist statuses.

**Interfaces:**
- Consumes all previous tasks.
- Produces final single commit, pushed branch, and APK.

- [ ] Run targeted Flutter tests through Ubuntu proot.
- [ ] Run `flutter analyze` through Ubuntu proot.
- [ ] Amend existing squashed bugfix commit and force-with-lease push.
- [ ] Run GitHub Actions APK workflow and download the resulting APK.

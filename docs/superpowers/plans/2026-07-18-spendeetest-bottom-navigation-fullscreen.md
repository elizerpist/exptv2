# Spendee Test Bottom Navigation and Chrome Fullscreen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved Dashboard / center FAB / Settings bottom navigation to `spendeeTest` mode and replace its top-right Settings shortcut with a Chrome-only fullscreen toggle.

**Architecture:** `ExptShell` remains the navigation and transaction-action owner and selects a focused `SpendeeTestBottomNav` only for the approved design mode. A shared `BrowserFullscreenController` coordinates request serialization and state notifications over a conditionally selected native stub or web DOM driver, then the controller is injected through the shell into the experimental dashboard.

**Tech Stack:** Flutter/Dart 3.11, Material widgets, `package:web` 1.1.1, Dart JS interop, Flutter widget tests, Ubuntu proot Flutter tooling.

## Global Constraints

- `docs/prototypes/color_lab.html` lines 4377-4412 and 10952-10956 are mandatory read-only visual references.
- The specialized bar contains exactly Dashboard, center add FAB, and Settings; it contains no Stats or Notifications destination.
- Fullscreen is web/Chrome-only; the Android APK renders no fullscreen button and imports no browser APIs.
- The normal Home / Stats / Settings navigation and right-positioned FAB remain unchanged.
- Existing uncommitted Color Lab, checklist, plan, and `test/failures/` work must remain untouched.
- Flutter tests and analyze run through Ubuntu proot; no local APK build runs on the phone.

---

### Task 1: Browser fullscreen state controller

**Files:**
- Create: `lib/core/platform/browser_fullscreen_controller.dart`
- Create: `lib/core/platform/browser_fullscreen_controller_factory.dart`
- Create: `lib/core/platform/browser_fullscreen_driver_stub.dart`
- Create: `lib/core/platform/browser_fullscreen_driver_web.dart`
- Modify: `pubspec.yaml`
- Test: `test/core/platform/browser_fullscreen_controller_test.dart`

**Interfaces:**
- Produces: `BrowserFullscreenDriver`, `BrowserFullscreenController`, and `createBrowserFullscreenController()`.
- `BrowserFullscreenController` exposes `isAvailable`, `isFullscreen`, `requestPending`, and `Future<void> toggle()` and owns its driver lifecycle.

- [ ] **Step 1: Write failing controller tests**

Create a fake driver whose `enter`, `exit`, availability, fullscreen state, external state event, pending completer, and thrown failure are controllable. Assert unavailable toggles are ignored, enter and exit select the correct driver call, external state events notify listeners, concurrent toggles collapse to one request, and rejection is swallowed without a false fullscreen state.

- [ ] **Step 2: Run the controller test and confirm RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/core/platform/browser_fullscreen_controller_test.dart'
```

Expected: FAIL because `BrowserFullscreenController` does not exist.

- [ ] **Step 3: Implement the controller and platform drivers**

Define the shared contract:

```dart
abstract class BrowserFullscreenDriver {
  bool get isAvailable;
  bool get isFullscreen;
  void addStateListener(VoidCallback listener);
  void removeStateListener(VoidCallback listener);
  Future<void> enter();
  Future<void> exit();
  void dispose();
}

class BrowserFullscreenController extends ChangeNotifier {
  BrowserFullscreenController(this._driver);
  bool get isAvailable => _driver.isAvailable;
  bool get isFullscreen => _driver.isFullscreen;
  bool get requestPending => _requestPending;
  Future<void> toggle();
}
```

The controller ignores unavailable/pending requests, catches browser policy rejection, and always resynchronizes listeners after completion. The web driver uses `web.document.fullscreenEnabled`, `documentElement.requestFullscreen()`, `document.exitFullscreen()`, and one retained `fullscreenchange` JS listener. The native stub always reports unavailable. Add `web: ^1.1.1` as a direct dependency.

- [ ] **Step 4: Run the controller test and confirm GREEN**

Run the Task 1 command again. Expected: all controller tests PASS.

- [ ] **Step 5: Commit Task 1**

```bash
git add pubspec.yaml pubspec.lock lib/core/platform/browser_fullscreen_controller*.dart lib/core/platform/browser_fullscreen_driver_*.dart test/core/platform/browser_fullscreen_controller_test.dart
git commit -m "feat: add browser fullscreen controller"
```

### Task 2: Specialized bottom navigation widget

**Files:**
- Create: `lib/features/shell/widgets/spendee_test_bottom_nav.dart`
- Modify: `lib/features/shell/widgets/bottom_nav_item.dart`
- Test: `test/features/shell/widgets/spendee_test_bottom_nav_test.dart`

**Interfaces:**
- Consumes: existing `BottomNavItem`, `ExptFab`, `AppTab`, theme surface values, and FAB callbacks.
- Produces: `SpendeeTestBottomNav(activeTab, onTabSelected, onFabPressed, onFabLongPress, ...)` with keys `spendee-test-bottom-nav`, `expt-bottom-nav`, existing destination keys, and `expt-fab`.

- [ ] **Step 1: Write failing navigation widget tests**

Pump the widget at `412x915`. Assert visible labels are `Dashboard` and `Beállítások`, Stats is absent, item centers are left/FAB/right in order, FAB center equals viewport center, home and settings taps dispatch the matching `AppTab`, and FAB tap/long press dispatch their callbacks.

- [ ] **Step 2: Run the navigation widget test and confirm RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/features/shell/widgets/spendee_test_bottom_nav_test.dart'
```

Expected: FAIL because `SpendeeTestBottomNav` does not exist.

- [ ] **Step 3: Implement the specialized bar**

Add optional `label` and `icon` presentation overrides to `BottomNavItem` while preserving tab IDs and callbacks. Build an 80-pixel edge-to-edge surface with a full-size stack: equal destination regions separated by a fixed center slot and an aligned existing `ExptFab`. Use `Dashboard` only as the specialized Home label and preserve theme accent/surface inputs.

- [ ] **Step 4: Run the navigation widget test and confirm GREEN**

Run the Task 2 command again. Expected: all specialized navigation tests PASS.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/shell/widgets/bottom_nav_item.dart lib/features/shell/widgets/spendee_test_bottom_nav.dart test/features/shell/widgets/spendee_test_bottom_nav_test.dart
git commit -m "feat: add spendee bottom navigation"
```

### Task 3: Shell integration and hidden-tab normalization

**Files:**
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `SpendeeTestBottomNav` and `BrowserFullscreenController`.
- Produces: mode-specific shell navigation, controller injection into the dashboard, and Dashboard normalization for persisted Stats/Notifications state.

- [ ] **Step 1: Change the existing Spendee shell test to the requested behavior**

Replace the old expectation that shell navigation and FAB are hidden. Assert specialized navigation and center FAB exist, Stats is absent, Settings opens through `bottom-nav-settings`, the specialized bar remains on Settings, Dashboard returns through `bottom-nav-home`, and native mode has no fullscreen button. Add a fixture with `shellActiveTabKey = 'stats'` and assert startup normalizes it to Home.

- [ ] **Step 2: Run focused shell tests and confirm RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart --plain-name "spendee test dashboard uses specialized shell navigation"'
```

Expected: FAIL because the current shell suppresses navigation in `spendeeTest` Home.

- [ ] **Step 3: Integrate mode-specific navigation**

Create and own one fullscreen controller in `ExptShell`, with an optional injected controller for tests. Pass it through `TransactionHomePage`. Select `SpendeeTestBottomNav` when the loaded theme mode is `spendeeTest`, keep it visible for Home and Settings, retain existing overlay suppression, and preserve `_handleFabPressed`/`_handleFabLongPressed`. Normalize disallowed persisted tabs to Home after the loaded theme becomes authoritative and update `EventStore.shellActiveTabKey`.

- [ ] **Step 4: Run focused shell tests and confirm GREEN**

Run the focused test plus the existing normal shell navigation tests. Expected: specialized and normal mode tests PASS.

- [ ] **Step 5: Commit Task 3**

```bash
git add lib/features/shell/expt_shell.dart lib/features/transactions/transaction_home_page.dart test/widget_test.dart
git commit -m "feat: activate spendee shell navigation"
```

### Task 4: Chrome-only dashboard fullscreen button

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: injected `BrowserFullscreenController`.
- Produces: `spendee-test-app-fullscreen-button`; removes `spendee-test-app-settings-button` from the experimental dashboard.

- [ ] **Step 1: Write failing fullscreen presentation tests**

Inject an available fake controller through `ExptShell`. Assert the fullscreen button replaces the old Settings shortcut, uses `Icons.fullscreen` initially, calls `toggle()` on tap, changes to `Icons.fullscreen_exit` after an external fullscreen event, and disables duplicate taps while pending. Retain the native/unavailable assertion that no fullscreen button is rendered.

- [ ] **Step 2: Run fullscreen presentation tests and confirm RED**

Run the focused `test/widget_test.dart` fullscreen test. Expected: FAIL because the current dashboard still renders `spendee-test-app-settings-button`.

- [ ] **Step 3: Implement the reactive icon button**

Replace `_AppCornerSettingsButton` with `_AppCornerFullscreenButton`. Render it only when the injected controller reports available; drive enter/exit icon, tooltip, disabled pending state, and unawaited `toggle()` from an `AnimatedBuilder`. Keep the existing category menu untouched.

- [ ] **Step 4: Run fullscreen presentation tests and confirm GREEN**

Run the focused fullscreen and complete specialized shell tests. Expected: PASS with no asynchronous Flutter exception.

- [ ] **Step 5: Commit Task 4**

```bash
git add lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart test/widget_test.dart
git commit -m "feat: add chrome fullscreen dashboard control"
```

### Task 5: Verification, evidence, checklist, and live preview

**Files:**
- Modify: `docs/superpowers/specs/2026-07-18-spendeetest-bottom-navigation-fullscreen-design.md`
- Test output: `test/failures/` remains user-owned and is not staged.

**Interfaces:**
- Consumes: all implementation tasks.
- Produces: fresh automated and visual evidence, updated acceptance statuses, pushed branch, and restarted live preview.

- [ ] **Step 1: Run targeted and relevant regression tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/core/platform/browser_fullscreen_controller_test.dart test/features/shell/widgets/spendee_test_bottom_nav_test.dart test/widget_test.dart test/web_preview/exptv2_web_preview_test.dart'
```

Expected: all tests PASS with zero failures.

- [ ] **Step 2: Run static analysis and web compilation**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze && /home/flutteruser/flutter/bin/flutter build web --debug'
```

Expected: analyze reports no issues and web debug build exits 0.

- [ ] **Step 3: Capture and inspect mobile and desktop screenshots**

Use the live `127.0.0.1:8766` preview at `412x915` and a desktop viewport. Verify the three-position order, centered FAB, active Dashboard/Settings state, absence of Stats, content clearance, no overflow, and the web fullscreen icon. Manually tap enter/exit fullscreen in Android Chrome.

- [ ] **Step 4: Update every acceptance status with evidence**

Re-read the spec and update each row to `DONE`, `PARTIAL`, `BLOCKED`, or `NOT DONE`. Record exact tests, analyze/build results, screenshot paths, and any browser-policy limitation. Do not claim completion while any unapproved item is not `DONE`.

- [ ] **Step 5: Commit, push, and hot restart**

```bash
git add docs/superpowers/specs/2026-07-18-spendeetest-bottom-navigation-fullscreen-design.md
git commit -m "docs: verify spendee bottom navigation"
git push origin spendeetest
```

Send uppercase `R` to the existing Flutter web-server session on port `8766`, wait for `Restarted application`, and leave the server running.

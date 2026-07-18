# Spendee Test Bottom Navigation and Chrome Fullscreen Design

## Status and approval

Approved on 2026-07-18. The user requested an active bottom navigation in the new `spendeeTest` dashboard design with exactly three positions: Dashboard on the left, the add FAB in the center, and Settings on the right. The existing top-right Settings button must be replaced by a fullscreen control in Chrome only; no fullscreen control is shown in the Android APK.

## Mandatory references

- Navigation markup source of truth: `docs/prototypes/color_lab.html`, common-header bottom navigation at lines 10952-10956.
- Navigation layout source of truth: `docs/prototypes/color_lab.html`, common-header navigation and inline FAB CSS at lines 4377-4412.
- Current shell integration: `lib/features/shell/expt_shell.dart`, especially `_buildShellNavigation` and the `spendeeTestHome` navigation suppression.
- Current reusable navigation widgets: `lib/features/shell/widgets/expt_bottom_nav.dart`, `bottom_nav_item.dart`, and `expt_fab.dart`.
- Current experimental dashboard integration: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`.
- Existing behavior test to replace: `test/widget_test.dart`, `spendee test dashboard hides shell nav and uses HTML header controls`.

The Color Lab files already have uncommitted user changes. They are read-only implementation references for this package and must not be edited or reverted by this work.

## Goal

Make the new dashboard design use its approved navigation model throughout the Dashboard and Settings destinations while preserving the existing transaction actions and leaving the normal design unchanged. On Flutter web, replace the duplicate top-right Settings shortcut with a Chrome fullscreen toggle that tracks the actual browser fullscreen state.

## Considered approaches

### 1. Shell-owned, design-specific bottom navigation

Add a focused bottom-navigation presentation for `DashboardDesignMode.spendeeTest`, owned by `ExptShell`. Compose it from the existing navigation item behavior and `ExptFab`, while matching the Color Lab's left item, inline center action, and right item. The shell remains the owner of tab selection, retained pages, transaction sheets, and FAB callbacks.

Chosen because it preserves one navigation owner, reuses the real transaction workflow, isolates the visual difference to the approved design mode, and avoids changing the normal navigation contract.

### 2. Generalize `ExptBottomNav` for arbitrary destinations and center actions

This would reduce one small amount of layout duplication but broaden a stable shared widget's API and state synchronization. Rejected because the two navigation models have materially different geometry and labels, and the normal design does not need this flexibility.

### 3. Embed navigation inside `SpendeeTestDashboard`

This would put the visual structure close to the dashboard, but the dashboard would then need shell tab, retained-page, sheet-host, and FAB responsibilities. Rejected because it creates competing navigation ownership and duplicates transaction-opening behavior.

## Navigation contract

### Visibility and destinations

When `dashboardDesignMode == DashboardDesignMode.spendeeTest`:

- the specialized bottom navigation is shown on both `AppTab.home` and `AppTab.settings`;
- the left item is labeled `Dashboard`, uses the home/dashboard icon, and selects `AppTab.home`;
- the center control is the existing add FAB, visually centered inline with the navigation bar;
- the right item is labeled `Beállítások`, uses the Settings icon, and selects `AppTab.settings`;
- no Stats item is rendered;
- no notification item is added to this bottom navigation;
- the active destination has the same theme-driven accent and active treatment as the app's navigation system.

The Settings destination uses the existing full Settings page, not the current header Settings overlay. Dashboard returns to the retained new-design home page without rebuilding its state unnecessarily.

If the persisted shell destination is Stats or Notifications when the `spendeeTest` setting becomes authoritative, the shell normalizes the active destination to Dashboard. This prevents a hidden destination from remaining active with no corresponding navigation item.

When the dashboard design is not `spendeeTest`, the existing Home / Stats / Settings bottom navigation and right-positioned FAB remain unchanged.

### FAB behavior

The center FAB is the existing `ExptFab` interaction surface, not a decorative replacement:

- tap opens the existing add-transaction workflow;
- long press opens the existing recurring manager workflow;
- the configured accent, surface interaction, and FAB size remain effective;
- the FAB remains available from both Dashboard and Settings while the specialized bar is visible;
- sheets and blocking overlays continue to suppress shell navigation according to existing shell rules;
- transaction content receives sufficient bottom padding so the bar cannot cover the final rows or controls.

The specialized bar follows the Color Lab geometry: equal left and right destination regions with a fixed center FAB, an edge-to-edge bottom surface, existing safe-area handling, and stable dimensions that do not shift when the active destination changes.

## Chrome fullscreen contract

### Presentation

The existing `spendee-test-app-settings-button` is removed from the new dashboard. Its top-right position is used by a fullscreen icon button only when all of the following are true:

- Flutter is running on web;
- the browser exposes the standard Fullscreen API;
- the new dashboard is visible.

The Android APK does not render this button. The dashboard's existing category/menu control remains unchanged.

### Behavior and state

The fullscreen control is a toggle initiated directly by its click gesture:

- when `document.fullscreenElement` is absent, request fullscreen on the document root;
- when `document.fullscreenElement` is present, exit fullscreen;
- show an enter-fullscreen icon outside fullscreen and an exit-fullscreen icon while fullscreen;
- subscribe to `fullscreenchange` so browser Back, Escape, or other browser-driven exits update the icon;
- preserve fullscreen while navigating between Dashboard and Settings because fullscreen belongs to the browser document;
- when Dashboard becomes visible again, display the actual current browser state.

Unsupported API access, a rejected fullscreen request, or browser policy denial must not crash the Flutter app. The control remains usable for a later user gesture and reports no false active state.

The browser integration is isolated behind a conditional platform adapter. Shared and Android compilation units must not import browser-only libraries.

## State and ownership

- `ExptShell` owns which navigation model is active, destination selection, retained pages, and FAB actions.
- The specialized navigation widget owns only layout and optimistic destination feedback.
- A browser fullscreen adapter owns Fullscreen API calls and `fullscreenchange` observation.
- The dashboard receives fullscreen availability/state/action through an injectable boundary so widget behavior can be tested without a real browser.
- No fullscreen state is persisted to app settings or the preview memory backend.

## Error and edge handling

- Rapid repeated fullscreen taps must not issue overlapping enter/exit requests.
- Disposing the dashboard removes browser event listeners.
- A design-mode change while Settings is active immediately selects the correct navigation model without showing stale items.
- Opening a shell sheet or blocking overlay hides the specialized navigation and FAB using the existing rules.
- Narrow mobile and desktop browser viewports must not overflow, overlap content, or move the center FAB away from the bar center.
- Browser fullscreen is verified in Chrome; no user-agent-specific Chrome branch is required when the standard API is available.

## Verification contract

- Start with failing widget tests for the requested navigation and fullscreen presentation.
- Widget tests cover Dashboard / FAB / Settings order, absence of Stats, active-state switching, Settings-to-Dashboard return, existing FAB tap and long-press actions, overlay suppression, and normal-design regression.
- Adapter tests cover enter, exit, external fullscreen-state change, unavailable API, rejected requests, and duplicate-request suppression.
- Shared widget tests use an injected fake fullscreen adapter to prove the web-only button state and action without importing browser APIs into VM tests.
- Run targeted Flutter tests and `flutter analyze` inside the Ubuntu proot environment.
- Run the relevant existing shell and web-preview tests.
- Compile Flutter web to prove conditional browser imports are valid.
- Inspect fresh screenshots at the primary `412x915` mobile viewport and a desktop viewport. Verify exact three-position layout, centered FAB, active states, no overlap, and no Stats item.
- In Android/native-mode widget verification, assert that the fullscreen button is absent.
- Manually exercise enter and exit fullscreen in Android Chrome from the live preview URL because headless test environments may deny fullscreen requests by policy.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| `NAV-001` | User: only Dashboard, center FAB, Settings in the new design | `expt_shell.dart`, design-specific bottom-nav widget | The `spendeeTest` bar has exactly those three ordered positions and matches the Color Lab structure | Widget structure/geometry tests and mobile screenshot | NOT DONE |
| `NAV-002` | User excluded other menu items | Shell navigation selection | Stats and Notifications are absent from the specialized bar, including after startup from a persisted hidden destination | Widget tests with persisted active-tab fixtures | NOT DONE |
| `NAV-003` | User requested an active bottom nav | Shell tab handling and retained pages | Dashboard and Settings switch correctly, show the correct active state, and the specialized bar remains present on both pages | Interaction tests | NOT DONE |
| `FAB-001` | User requested the FAB in the center | Specialized bar and existing `ExptFab` callbacks | FAB is centered and tap/long press retain add-transaction/recurring-manager behavior | Geometry and interaction tests | NOT DONE |
| `LAYOUT-001` | Approved Color Lab reference | Specialized bar and dashboard content padding | The bar and FAB do not overlap content at mobile or desktop sizes | Widget geometry tests and screenshots | NOT DONE |
| `FULL-001` | User replaced the upper Settings shortcut | `spendee_test_dashboard.dart` | The old top-right Settings button is removed; Settings is reachable from the bottom bar | Widget tests | NOT DONE |
| `FULL-002` | User requested fullscreen in Chrome only | Browser fullscreen adapter and dashboard button | Chrome button enters/exits document fullscreen and reflects browser-driven state changes | Adapter tests plus manual Chrome verification | NOT DONE |
| `FULL-003` | User excluded APK behavior | Conditional platform adapter and dashboard presentation | Android/native mode renders no top-right fullscreen button and imports no browser API | VM widget test and analyze | NOT DONE |
| `REG-001` | Existing app behavior outside new design | Existing `ExptBottomNav`, right FAB, shell tests | Normal design retains Home / Stats / Settings and its right-positioned FAB | Existing and focused regression tests | NOT DONE |
| `VER-001` | Global completion rules | Tests, analyze, web compile, screenshots | All targeted/full relevant checks pass and screenshots are inspected before completion is claimed | Recorded command output and image inspection | NOT DONE |

Completion requires every checklist item to be `DONE` or an explicit user-approved deferral. Compilation or a successful web build alone is not completion.

## Scope boundaries

- No Color Lab HTML/CSS edits are included.
- No Stats redesign or alternate route to Stats is added to the new design.
- No production web deployment or PWA display-mode change is included.
- No Android system-UI fullscreen behavior is added.
- No unrelated dashboard header, category carousel, transaction CRUD, or Settings redesign is included.

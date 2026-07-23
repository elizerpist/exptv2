# Exptv2 Web Preview Design

## Status and approval

Approved direction: the user selected a UI-development web preview for the complete Exptv2 application. The preview must run the same `lib/main.dart` application and widget tree as Android, with deterministic in-memory data and session-scoped CRUD. The Color Lab HTML remains a design reference only and is not the runtime target.

## Goal

Provide a browser-hosted Flutter development target at `127.0.0.1` that supports rapid UI iteration, hot reload, mobile-viewport screenshots, navigation through every main screen, and realistic CRUD interactions without requiring an Android APK build.

The preview is a development surface, not a production web application. Browser refresh may reset all preview data to its seed state.

## Considered approaches

### 1. Platform-specific transport behind `NativeBridge`

Keep the existing `NativeBridge` domain mapping and all current app consumers. Introduce a transport boundary beneath it: Android uses `MethodChannel` and `EventChannel`; web uses a deterministic in-memory transport implementing the same method protocol. The composition root selects the transport by platform.

Chosen because it runs the real application assembly, preserves the Android contract, centralizes preview behavior, and avoids duplicating screen or repository composition.

### 2. `WebNativeBridge` subclass

Subclass `NativeBridge` and override every method needed by the web preview. This is initially smaller, but inherited methods can silently fall through to missing web platform channels when a new capability is added. Rejected because completeness is not enforced at the transport boundary.

### 3. Separate preview application with fake repositories

Create a preview-only entry point that builds screens with fake repositories. This offers focused fixture control but duplicates production composition and can drift from the actual app. Rejected because the user needs the complete Exptv2 application, not a screen gallery.

## Architecture

### Composition root

`lib/main.dart` remains the canonical application entry point. A conditional platform factory creates the app bridge:

- Android and other native targets: `NativeBridge` with method/event channel transport.
- Web: `NativeBridge` with preview memory transport.

`Exptv2App`, `ExptShell`, stores, repositories, navigation, pages, dialogs, sheets, painters, and gestures remain the same widgets used by Android.

### Transport contract

The transport exposes the generic operations already used by `NativeBridge`:

- scalar method invocation;
- list method invocation;
- map method invocation;
- event stream subscription.

The Android implementation delegates to the current Flutter channels. The web implementation dispatches the same method names to an in-memory state object and returns payloads matching the existing Kotlin/MethodChannel map contracts. Domain decoding remains in `NativeBridge`, so Android and web exercise the same serialization boundary.

Unknown web method names fail loudly in development with the method name included. They must not silently return `null`, because that would hide incomplete preview coverage.

## Preview state

The memory backend starts with deterministic, realistic data covering the visible UI states:

- expense and income categories with packaged icons;
- transactions in the current month, adjacent months, and a prior year;
- merchants, renamed merchants, notes, and mixed transaction types;
- category limits and budget progress states;
- recurring rules and generated recurring records;
- notification cards and parser log examples;
- default theme, fast-info, notification, parser, and security settings;
- statistics snapshots where required by existing screens.

CRUD mutations update the shared in-memory state so changes are visible across Home, Stats, Notifications, Settings, recurring views, filters, and editors during the same browser session. IDs are generated monotonically. Hot reload preserves the running state when Flutter preserves the app isolate; full page refresh resets the fixture.

No IndexedDB, local-storage persistence, server API, authentication token, or production migration is included.

## Platform capability behavior

Android-only capabilities stay visible only where the existing UI requires their controls, but web execution must never call an unavailable platform channel or crash.

- Notification listener, accessibility capture, installed-app discovery, post-notification permission, app settings deep links, test notifications, and native alarm scheduling return stable unavailable/no-op results.
- Security settings load with PIN and biometric authentication disabled. Biometric actions are unavailable in preview.
- Native IME sheet opening returns `false`, allowing the existing Flutter sheet fallback to open.
- Native keyboard inset streams are disabled on web; Flutter browser view insets remain the fallback source.
- The Android-only keyboard controller package is reached through a conditional adapter with a web-compatible scope/fallback.
- Stats frame generation uses a synchronous or same-isolate worker on web instead of `Isolate.run`.
- Google Sheets initialization and authentication are disabled in preview. Existing settings UI receives a disconnected/unavailable state.
- File export generates preview content in memory. Native file sharing reports unavailable and never invokes Android file-sharing channels.
- Network error classification must not import `dart:io` into the web compilation unit.

These changes are platform-selected. They must not alter the existing Android runtime path.

## Web target and viewport

Add the standard Flutter `web/` platform files without changing Android identifiers or build configuration. The app fills the browser viewport and uses the same responsive constraints and safe-area behavior as the Flutter widget tree.

Primary verification viewport: `412x915` logical pixels, matching a modern Android phone layout closely enough for UI iteration. Additional checks cover a narrow mobile viewport and a desktop browser viewport to catch overflow, but the preview is optimized for mobile UI design rather than desktop information density.

The development server command is:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8766'
```

The browser URL is `http://127.0.0.1:8766`.

## Error handling

- Unknown preview bridge calls throw a descriptive `UnsupportedError` during development.
- Malformed CRUD payloads fail with the method name and invalid field rather than corrupting preview state.
- Unsupported native actions resolve to explicit unavailable/no-op results expected by the existing UI.
- Startup futures must complete; no page may remain behind an infinite loading or security gate.
- Asynchronous platform failures are captured by tests and may not surface as red Flutter error screens.

## Verification

- Unit tests for fixture initialization, ID generation, transaction/category/limit/recurring CRUD, filtering, settings updates, and reset behavior.
- Contract tests that pass preview payloads through the real `NativeBridge` domain decoding.
- Widget smoke test that pumps the production `Exptv2App` with the preview backend and reaches the unlocked shell.
- Interaction tests for all main tabs and every create, update, delete, toggle, filter, and settings mutation exposed by the preview UI.
- Existing Flutter tests and `flutter analyze` run inside the Ubuntu proot environment.
- A Flutter web compilation proves that no unavailable `dart:io`, isolate, or Android-only plugin import reaches the web target.
- Start the web server on `127.0.0.1:8766`, verify an HTTP response, and inspect mobile and desktop screenshots for blank output, overflow, overlap, and missing assets.
- Android channel transport tests remain passing to guard against native behavior regressions.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| `WEB-RUN-001` | User requested the complete Exptv2 app in a browser | `web/`, `lib/main.dart`, platform factory | `lib/main.dart` app loads at `127.0.0.1:8766` without an APK | Web compile, server HTTP smoke test, screenshot | DONE |
| `WEB-UI-001` | User is developing UI design | Existing app widget tree and platform adapters | All main screens, dialogs, and Flutter fallback sheets can be opened in a mobile browser viewport | Navigation interaction tests and screenshots | DONE |
| `WEB-DATA-001` | User selected in-memory sample data | Preview memory state and fixtures | Realistic data populates Home, Stats, Notifications, Settings, filters, limits, and recurring views | Fixture and widget assertions | DONE |
| `WEB-CRUD-001` | User required every screen and CRUD to work | Preview transport method handlers | Every transaction, category, limit, recurring, notification, parser, and settings mutation exposed by the preview UI updates all consumers during the session | Method inventory plus unit and interaction tests | DONE |
| `WEB-NATIVE-001` | Android notification, biometric, and accessibility features must be disabled | Capability adapters and startup services | Android-only actions never invoke missing web channels or block startup | Platform capability tests and async exception capture | DONE |
| `WEB-HOT-001` | Preview is for rapid UI iteration | Flutter web-server workflow | Dart/UI edits can be hot reloaded without a GitHub APK build | Live web-server reload check | PARTIAL |
| `WEB-ANDROID-001` | Web preview must not regress the app | Native channel transport and existing tests | Android continues to select the current channel-backed behavior | Existing bridge tests, full targeted test suite, analyze | DONE |

Completion requires every checklist item to be `DONE` or an explicit user-approved deferral. A successful web compile alone is not completion.

### Verification evidence (2026-07-18)

- `WEB-RUN-001`: `flutter build web --debug` completed in 159.4 seconds with a successful Wasm dry run. The foreground web-server reported `lib/main.dart is being served at http://127.0.0.1:8766`; HTTP GET returned 200 for `/`, `flutter_bootstrap.js`, and `main.dart.js`. The phone browser URL was opened with `termux-open-url`.
- `WEB-UI-001`: `test/web_preview/exptv2_web_preview_test.dart` navigates Home, Stats, Settings, Notifications, transaction/category/recurring sheets at `412x915`, and the primary surfaces plus Flutter transaction fallback at `1280x900` inside the 480-pixel web frame. All three golden PNGs were opened and inspected for blank output, clipping, overlap, stretching, and overflow markers.
- `WEB-DATA-001`: `test/services/preview/preview_native_state_test.dart` verifies deterministic current, adjacent, and prior-year data plus reset/deep-copy behavior; production-tree assertions verify data on Home, Stats, Notifications, Settings, recurring, and limit surfaces.
- `WEB-CRUD-001`: preview handler and real `NativeBridge` decoder tests cover transaction, category, limit, recurring transaction/rule, notification, parser, settings, export, stats, and reset methods. Production UI tests cover transaction/category CRUD, limit save, recurring toggle/delete, notification read/delete, and theme/notification/parser mutations.
- `WEB-NATIVE-001`: web adapter tests, disabled capability handler tests, production-tree async exception checks, and the successful web compile prove unavailable Android channels do not block startup.
- `WEB-HOT-001`: the foreground `flutter run -d web-server` session remains active and `r` recompiles in 4.6 seconds, but reports `Recompile complete. No client connected.` Android Chrome cannot install the Dart Debug Chrome extension required by Flutter's web-server device. The supported phone workflow is `r` followed by a browser refresh; true state-preserving hot reload remains unverified and is not claimed.
- `WEB-ANDROID-001`: the full Flutter suite passed 956 tests in 7 minutes 49 seconds, the targeted preview/bridge suite passed 39 tests, and `flutter analyze` reported no issues. Native MethodChannel constructors and method names remain covered by existing contract tests.

## Scope boundaries

- No production web deployment, service worker strategy, hosting configuration, or browser persistence.
- No replacement for the Android notification/accessibility capture engine.
- No attempt to reproduce Android biometric or permission dialogs in HTML.
- No unrelated visual redesign; the preview renders the current Flutter UI.
- Existing uncommitted Color Lab and query-time-picker work remains untouched.

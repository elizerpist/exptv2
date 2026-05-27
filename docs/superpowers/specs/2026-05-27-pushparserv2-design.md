# PushParserV2 Design

## Goal

Build a lightweight Android Flutter app named `pushparserv2` at:

`/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/pushparserv2`

Development must be done from Termux, without entering Ubuntu. The app captures Android notification-related events in realtime, stores every captured event in a local database, and lets the user inspect whether capture still works while the Flutter UI is closed or the app is in the background.

## Core Requirements

- Use Flutter for the user interface.
- Use Kotlin for Android notification and accessibility integration.
- Capture events with both supported methods:
  - `NotificationListenerService`
  - `AccessibilityService`
- Let the user choose the capture method in Settings:
  - `Notification Listener`
  - `Accessibility Service`
  - `Both`
- Request or guide the user through required permissions on first launch.
- Store all captured events locally with no automatic retention limit.
- Show stored and incoming events on the main screen in a chat-like list.
- Filter by app identity, not message text.
- The filter input is a regex matched against app label and package name.
- The default state shows all captured events.
- Capture should continue through native Android services while the Flutter UI is closed, as far as Android service lifecycle and granted permissions allow.

## Architecture

The app has two layers:

1. Flutter UI
2. Kotlin Android integration layer

The Kotlin layer is responsible for reliable capture and persistence. `NotificationListenerService` and `AccessibilityService` write directly into a native Room/SQLite database when the selected capture mode allows that source. This avoids depending on an active Flutter engine for background capture.

The Flutter layer is responsible for display, settings, filtering, and test controls. It communicates with Kotlin through platform channels:

- `MethodChannel` for loading stored rows, reading service status, opening Android settings screens, changing capture mode, clearing the database, and triggering test notifications.
- `EventChannel` for realtime updates while the Flutter UI is active.

## Data Storage

Use a native Room database backed by SQLite. The main table is `notification_events`.

Fields:

- `id`: autoincrement primary key
- `timestamp`: event timestamp in milliseconds
- `source`: `notification_listener` or `accessibility`
- `packageName`: source app package name
- `appLabel`: resolved app label when available
- `title`: notification title or accessibility-derived title
- `text`: notification text or accessibility-derived text
- `bigText`: expanded notification text when available
- `subText`: notification subtext when available
- `category`: Android notification category when available
- `notificationKey`: Android notification key when available
- `accessibilityEventType`: accessibility event type when relevant
- `hash`: stable hash for dedupe inspection
- `isDuplicate`: true when a similar event was already seen

All events are preserved until the user manually clears the database from Settings. Automatic deletion, rolling limits, and time-based expiry are out of scope.

## Duplicate Handling

When both capture methods see the same notification, the app must not silently discard either event. It stores both rows and marks likely duplicates with `isDuplicate`.

This is important for testing because the user wants to compare which method saw which event. The UI should show the source clearly with compact labels such as `NL`, `ACC`, and duplicate status.

## Main Screen

The main screen is the primary working surface.

Layout:

- A top app bar with title and Settings access.
- A scrollable chat-style list of captured events.
- A fixed bottom filter bar with:
  - regex text input for app label or package name
  - filter on/off control

Each event bubble shows:

- app label
- package name
- source indicator
- timestamp
- title
- text/body
- duplicate marker when relevant

Default behavior:

- filter off
- all stored events visible
- realtime events appear as they are captured
- newest events should behave like a chat log, with newest near the bottom and automatic scroll when appropriate

Filter behavior:

- The filter applies to app label and package name.
- The filter does not search notification title or body text.
- Invalid regex must not crash the app.
- The UI should keep using the previous valid regex and show an inline error for the current invalid input.

## Settings Screen

Settings contains testing and operational controls.

Controls:

- Capture mode selector:
  - `Notification Listener`
  - `Accessibility Service`
  - `Both`
- Permission status for Notification Access.
- Permission status for Accessibility Service.
- Button to open Notification Access settings.
- Button to open Accessibility settings.
- Button to send a local test notification.
- Button to clear the database.

Status fields:

- selected capture mode
- whether each service is active under the selected mode
- whether Notification Listener is enabled
- whether Accessibility Service is enabled
- last Notification Listener event time
- last Accessibility event time
- total stored event count

If a method is selected but its permission is not granted, the mode remains selected but the UI shows that the method is inactive until permission is granted. The selected mode is persisted in native preferences so the Kotlin services can enforce it even when Flutter is not running.

## First Launch And Permissions

On first launch, the app shows a permission setup surface. Android does not allow these permissions to be granted silently from inside the app, so the app guides the user to the correct system screens.

Required flows:

- Open Notification Access settings for `NotificationListenerService`.
- Open Accessibility settings for `AccessibilityService`.
- Recheck permission status when the app resumes.

The app should be usable even if only one permission is granted. Missing permissions are shown as inactive services, not fatal errors.

## Background Behavior

Native Android services should capture and store events even when:

- the Flutter UI is not open
- the app is in the background
- the user later reopens the app

On reopen, Flutter loads events from the Room database. If the UI is active during capture, it also receives realtime updates through `EventChannel`.

The design depends on Android granting and keeping the relevant services active. The app should expose enough status data for the user to test whether a service is running and when it last captured an event.

## Testing Scope

Implementation should verify:

- app starts successfully
- permission status is displayed correctly
- Notification Listener captures and persists events
- Accessibility Service captures and persists supported events
- `Both` mode records both sources
- events captured while the UI is closed are visible after reopening
- realtime updates appear while the UI is open
- regex filter matches app label and package name only
- invalid regex is handled without crashing
- local test notification can be generated
- database clear removes stored events

## Non-Goals

- No server sync.
- No cloud storage.
- No export feature in the first version.
- No automatic retention limit.
- No parsing of private FCM payloads that are not surfaced through Android notifications or accessibility events.
- No attempt to bypass Android permission screens.

## Implementation Direction

Use the recommended architecture:

- Flutter UI for screens, state, and controls.
- Kotlin services for capture.
- Room/SQLite for persistent storage.
- Platform channels for Flutter-native communication.

This direction prioritizes reliable background persistence and testability over keeping all logic in Dart.

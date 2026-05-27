# PushParserV2

Lightweight Android Flutter app for testing notification capture paths.

## What It Does

- Captures Android notification events through a Kotlin `NotificationListenerService`.
- Captures notification-related accessibility events through a Kotlin `AccessibilityService`.
- Lets the user select capture mode in-app: Notification Listener, Accessibility, or Both.
- Persists every captured event in a native Room/SQLite database with no automatic retention limit.
- Shows stored and realtime events in a Flutter chat-style UI.
- Filters by source app label/package using a regex; it does not filter notification body text.
- Provides Settings controls for permissions, status, test notifications, and database clearing.

## Repository

GitHub remote: <https://github.com/elizerpist/pushparserv2>

Local path used for development:

```text
/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/pushparserv2
```

## Environment Notes

This project was created from Termux as requested, without entering Ubuntu. In this Termux environment, full Flutter/Gradle verification is blocked by host tooling, not by project code:

- `/data/data/com.termux/files/home/flutter/bin/flutter test` aborts while building Flutter tooling because the bundled Dart binary reports an ARM64 Bionic TLS alignment error.
- `android/gradlew :app:compileDebugKotlin` stops because `JAVA_HOME` is not set and no `java` binary is available in Termux PATH.

Run tests/builds in an environment where Flutter's Dart binary and Java are available.

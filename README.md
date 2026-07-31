# Fluvi

Fluvi is a clean rewrite with two deliberately separate production consumers:

- `android:fluvi-core` — Kotlin/Room data-management library;
- the Flutter `com.fluvi.app` host — the current data-free Core Dashboard UI.

The dashboard does not call Room, repositories, queries, Sheets, sync,
logboxes, recurring rules, or Inbox code. When a future adapter is added, it
will consume the typed `FluviCoreFactory` facade; Room, DAOs, and repositories
remain internal to `android:fluvi-core`.

Run local verification from an Android/x86_64-capable environment:

    ./scripts/verify-fluvi-boundaries.sh
    cd android && ./gradlew :fluvi-core:testDebugUnitTest --no-daemon

Flutter tests and analysis run in the Ubuntu `flutteruser` environment on this
device. Debug APKs are built only by GitHub Actions and uploaded as the
`fluvi-debug-apk` artifact.

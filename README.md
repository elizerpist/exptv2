# Fluvi Core

Fluvi Core is a clean-room Kotlin/Room data-management library for a future
finance application.

This repository intentionally contains no Flutter UI, Android application
module, APK target, Sheets client, recurring runtime, or Inbox parser. Those
consumers will be designed and added one at a time after the core contract is
proven.

The only production module is android:fluvi-core.

Its supported integration entry point is `FluviCoreFactory`. Room, DAOs, and
repositories are module-internal implementation details; consumers receive
typed use cases and read services through `FluviCore`.

Run its unit tests in a standard Android/x86_64 environment:

    cd android
    ./gradlew :fluvi-core:testDebugUnitTest --no-daemon

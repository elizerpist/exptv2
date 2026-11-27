# Fluvi Android product

`scripts/build-r50-android.sh` builds the root Dart payload as an AAR with
Flutter and JDK 17, then publishes the Fluvi Kotlin, Room and focused WA
libraries. JDK 21 and the stock API 37 SDK assemble the Fluvi application.
The standard `android/app` Gradle entry point remains the test harness.
The Human profile entry point is `scripts/build-human-diagnostic-apk.sh`.

The merged manifests, resolved runtime dependencies and APK class
definitions are inspected separately. No private SDK or upstream
application checkout is required. The Android widget picker and bind
grant come from the system.

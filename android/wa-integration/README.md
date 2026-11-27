# Fluvi Android packaging with Widgets Anywhere

The vendor directory is the 577-file tree `d00525e0c97815cbdf1c46ef806fffbd2100b10e` from the released Widgets Anywhere 4.7.5 commit `9c7fed25ec833197656dec57427be4c26fc66138`. The build stages a fresh copy. Both MIT notices are included in the APK assets.

| Staged file | Integration |
| --- | --- |
| `settings.gradle.kts` | Consumes the local Fluvi payload/native Maven repositories. Leaves the wallpaper application outside the product. |
| `app/build.gradle.kts` | Preserves the WA namespace, build tooling and compiled host. Sets the Fluvi package and version, wires the native dependency and adds a profile build. |
| Main, debug and profile manifests | Keep the upstream Application and real accessibility service, remove the second launcher, rebase dynamic/companion permission identities and expose VM-service networking in diagnostic variants. |
| `App.kt` and `FluviHostDefaults.kt` | Use the original Application lifecycle with the optional crash reporting startup replaced by product preferences. The main frame is initially off, the tutorial is intact and PIN and shade hiding are enabled. |
| `WallpaperClient.kt` and `:lswinterconnect` manifest | Use a separate integrated companion namespace so the installed standalone package does not collide. No integrated companion ships. |

The staged Flutter module uses the original root Dart sources, assets, shader and dependency lock. Java 17 builds the Flutter AAR and the Fluvi native libraries, including the original Room/KSP core. Java 21 and the WA wrapper build the single application. The legacy Android root is only the isolated automated native and dashboard test harness. Product builds use `scripts/build-r49-android.sh`. Human profile builds use `scripts/build-human-diagnostic-apk.sh`. The test provider is a separate APK compiled only for the fixture and never merged into the product.

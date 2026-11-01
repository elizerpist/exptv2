# Fluvi · Élő orb — platform capability boundary

The `Fluvi · Élő orb` provider intentionally does **not** present a static
bitmap, GIF, Flutter engine, foreground service, or repeated
`updateAppWidget()` calls as an animated dashboard-header material.

## Verified boundary — 2026-11-01

- The available project toolchain is Flutter 3.41.4 with Android API 35.
- `adb devices` reports no attached device, so no launcher-host test ran in
  this environment.
- The known target is Android 15 / Nothing Launcher. On this API level the
  standard AppWidget transport is `RemoteViews`; it cannot host the Flutter
  `FragmentProgram` / AGSL header renderer or an arbitrary `CustomView`.
- Remote Compose can provide host-local animation only where the launcher has
  a compatible Remote Compose player. Its official architecture requires a
  host player to render the recorded document and run animations locally;
  checking an SDK integer is not proof that a particular launcher accepts the
  material operations Fluvi needs.

Reference: [Android Remote Compose concepts and architecture](https://developer.android.com/develop/ui/compose/system/remote-compose).

No real launcher prototype has been run for the target Android 15 / Nothing
pair, and the current build cannot compile or prove an Android 16+ Remote
Compose document/player contract. Therefore `OrbRendererCapabilities` remains
false on every branch. Configuration is deliberately blocked instead of
successfully adding a fake or static "live" orb; existing per-widget targets
remain stored and untouched.

The implementation therefore supplies the durable, non-deceptive parts now:

- one reconfigurable 1×1 provider (`Fluvi · Élő orb`), with one independent
  `appWidgetId` configuration per instance;
- durable mode, time axis, direction, ghost mode, current-period binding and
  Budget `categoryId` data, including restore-ID remapping;
- a light native configuration Activity that does not start Flutter or mount a
  dashboard; and
- an event-driven update boundary for Core revisions, manual ledger writes,
  limit/category mutations, push booking and scheduled recurrence booking.

On an unsupported host the widget is a non-text capability marker with an
accessible explanation rather than a claimed live orb. The remaining renderer
gate is intentional: a true result requires a real launcher-host prototype
that proves the complete header recipe (multi-stop palettes,
classic/full-field/space-fabric families, Deep Drift and both Portal channels)
animates locally without frame IPC.

Before enabling a future supported path, record all of the following against
the actual launcher: a continuous circle animation after the Activity closes,
palette and semantic-scene updates, separate widget-instance targets, and the
accepted operation profile for every Fluvi effect/Portal channel. A preview
Activity, an APK build, or `updateAppWidget()` returning successfully is not
that proof.

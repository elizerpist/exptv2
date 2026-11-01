# Fluvi · Élő orb — platform capability boundary

The `Fluvi · Élő orb` provider intentionally does **not** present a static
bitmap, GIF, Flutter engine, foreground service, or repeated
`updateAppWidget()` calls as an animated dashboard-header material.

The checked device is Android 15 / Nothing Launcher. The required
host-local Remote Compose widget path is not available there, while the
project's Flutter `FragmentProgram` / AGSL header programs cannot be embedded
in `RemoteViews`. AndroidX Remote Compose remains an alpha API and its actual
launcher Widgets operation profile must be verified on an Android 16+ host
before it can be accepted as a renderer for every Fluvi header effect and both
Portal channels.

The implementation therefore supplies the durable, non-deceptive parts now:

- one reconfigurable 1×1 provider (`Fluvi · Élő orb`), with one independent
  `appWidgetId` configuration per instance;
- durable mode, time axis, direction, ghost mode, current-period binding and
  Budget `categoryId` data, including restore-ID remapping;
- a light native configuration Activity that does not start Flutter or mount a
  dashboard; and
- an event-driven update boundary for Core revisions, manual ledger writes,
  limit/category mutations, push booking and scheduled recurrence booking.

On an unsupported host the widget is an explicit capability state rather than
a claimed live orb. The remaining renderer gate is intentional: a true result
requires a real launcher-host prototype that proves the complete header recipe
(multi-stop palettes, classic/full-field/space-fabric families, Deep Drift and
both Portal channels) animates locally without frame IPC.

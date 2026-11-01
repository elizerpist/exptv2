# Fluvi · Élő orb — renderer capability boundary

## Implemented compatibility backend — 2026-11-01

`Fluvi · Élő orb` now uses a normal Android AppWidget with `RemoteViews` and a
`ViewFlipper`. On every render the provider prepares a **finite** ARGB frame
bundle, creates all `ImageView` children, and sends one complete
`updateAppWidget()` payload. The launcher loops that local child sequence at
80 ms intervals. There is no per-frame provider update, Flutter engine,
foreground service, wakelock, GIF, overlay, or wallpaper integration.

The requested 32 × 96 × 96 ARGB profile is 1,179,648 raw bytes, beyond the
conservative one-update transport budget. The renderer takes the real
launcher-reported short cell side in dp, converts it with the actual display
density, and clamps the frame side to 64–96 physical pixels. It then reduces
the frame count to stay under a 700 KiB raw-image budget (the default
24 × 80 × 80 profile is 614,400 raw bytes and a 1.92 s loop). The first and
last frames sample `t ∈ [0, 1)` so the periodic material function does not
duplicate the first frame at the loop boundary.

The transparent frame corners are part of each bitmap. The home-screen
wallpaper remains visible outside the orb.

The renderer is a **compatibility-wave-v1** material. It reads the durable
Balance header palette, variant, position and window from
`dashboard_presentation`, samples its three window stops, and carries the
orb's own mode, time-axis, direction, ghost filter and category ID into a
deterministic material seed. Updating the dashboard palette publishes a new
bundle; Core/recurrent/push/limit events already enter the same event-driven
widget refresh boundary.

This is a real locally animated AppWidget backend, but it is not a claim of
pixel-for-pixel Flutter header parity. The persisted native preferences do not
yet contain the complete effect/settings banks, Mind-score projection,
Budget-limit colour projection, Deep Drift, or both Portal channels. Those
effects cannot honestly be reconstructed after the Flutter UI closes. Their
future implementation must extend the shared immutable scene-profile contract
rather than silently substitute this wave renderer.

| Dashboard visual input | Current orb route | Status |
| --- | --- | --- |
| Persisted Balance palette / variant / position / window | Three sampled stops in `compatibility-wave-v1` | Implemented; sRGB compatibility sampling, not Dashboard's perceptual sampler |
| Static header selection | Same finite material bundle, with no frame-IPC loop | Implemented compatibility behaviour |
| `classicReference`, `fullFieldFlow`, `spaceFabricWarp` effects | `compatibility-wave-v1` fallback | Not shader-equivalent |
| Deep Drift and both Portal channels | Not present in the native persisted profile | Not yet renderable after Flutter closes |
| Mind score and Budget category/limit colour projections | Orb configuration is retained as a deterministic seed only | Financial visual projection not yet shared |

## What remains to verify on a target phone

No `adb` device was attached in this environment. Therefore the required
Android 15 / Nothing Launcher evidence remains open: install the produced APK,
add a 1×1 orb, record multiple points in the loop after closing Fluvi, and
verify palette/configuration refreshes do not result in continuous provider
IPC. A build, an activity preview, or a successful `updateAppWidget()` call is
not proof of launcher playback.

The implementation uses standard platform `RemoteViews` operations and
`ViewFlipper`, not Remote Compose. See [RemoteViews](https://developer.android.com/reference/android/widget/RemoteViews)
and [ViewFlipper](https://developer.android.com/reference/android/widget/ViewFlipper).

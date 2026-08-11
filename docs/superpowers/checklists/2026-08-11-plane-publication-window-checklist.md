# Plane publication scene-window checklist

## Architecture card

- **Scope/source:** physical-device timing log and the 2026-08-11 Summary
  Pill performance specification. This changes scene-window sizing and
  foreground/background scheduling only; it preserves the recently fixed
  scene-demand ownership model.
- **Single owner/write path:** `DashboardCoreController` remains the sole
  owner of scene-demand, preparation generations, pending structural
  navigation, and scene activation. `DashboardPreparedRevisionBundle` remains
  the pure, immutable projection owner for scene payload windows.
- **Shared mechanism:** extend the existing scene-window projection and
  coordinator. Do not add a second cache, rail scheduler, or motion system.
- **State boundary:** structural publication windows are foreground and exact;
  rail-interaction and next-plane windows are cancellable background work.
  UI remains a consumer of the existing coordinator.
- **Verification:** RED/GREEN controller tests, existing scene/summary/rail
  regressions, Proot analysis, GitHub Flutter/core/profile gates, and a
  SHA-verified human APK in `/storage/emulated/0/Download/fluvi`.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PSP-01 | User §§2, 4–7, 16 | scene-window projection | A plane transition's foreground window contains only the exact visible parent plus direction twin, not the full sibling rail domain. | Dense SUM/YEAR/MONTH projection RED/GREEN tests | DONE |
| PSP-02 | User §§3, 8–9, 17 | `DashboardCoreController` coordinator | Pending structural foreground preparation starts immediately even while summary motion is active; maintenance remains deferred. | Motion-active controller regression | DONE |
| PSP-03 | User §§10, 13, 19 | background scene coordinator | The current plane's rail-interaction domain warms only after structural commit and never blocks it; rail open remains covered before publishing a child. | Blocked interaction-warmup controller regression | DONE |
| PSP-04 | User §11, 20 | idle background warmup | The next deterministic Summary Pill target's O(1) publication window is warmed at idle without whole-index preparation. | Next-plane prewarm/cache-hit regression | DONE |
| PSP-05 | User §§14–15, 21, 25 | protected scene/navigation systems | Direction twins remain synchronous; pending-intent coalescing and first-frame renderability remain correct; physics, paging, SQL and painter stay unchanged. | Existing direction/race/continuity/paging tests and focused diff | DONE |
| PSP-06 | User §§22–24 | diagnostics/performance evidence | Diagnostics distinguish structural publication from rail interaction, with scene/row counts and input-to-commit timing. | GitHub profile run 31510562359 passed A–J; every recorded scene-miss/drawability counter is zero. | DONE |
| PSP-07 | Global delivery rule | branch/CI/APK | Change is committed/pushed; exact GitHub human APK is monitored, downloaded and SHA verified. | `73ca3d66`, GitHub run 31510562359, and SHA-verified `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_73ca3d6.apk`. | DONE |

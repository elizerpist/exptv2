# Scene-window input decoupling design

## Goal

Keep the 2025 high-density fixture unchanged while ensuring scene-window text
preparation is never a prerequisite for rail motion, rail settle, or a new
vertical gesture.

## Evidence and root cause

Baseline: `e575e6ea3ed270528f007bcab9a3d0ee51748e64`.

`DashboardCoreController._drainSceneRebase` sets `sceneWindowPreparing` before
awaiting `DashboardLogBoxPreparedSceneCache.prepareWindow`. That method creates
`TextPainter` layouts on the Flutter UI isolate and only yields with a
microtask. `FluviAppShell` consumes the same notifier in an `AbsorbPointer`,
and controller navigation methods reject work while that flag is true.
Therefore a 133–226 ms dense-window preparation both occupies UI-isolate time
and explicitly denies pointer input. The former rotation test currently
encodes that gate as expected behaviour.

## Ownership and flow

`DashboardCoreController` remains the single owner of temporal metadata and
the latest-wins maintenance request. `DashboardLogBoxPreparedSceneCache`
remains the sole owner of `TextPainter` creation, prepared scene reuse,
staging, activation and eviction. `CoreDashboard` only binds the two existing
capabilities; `FluviAppShell` only applies startup readiness, never cache
maintenance readiness.

```text
rail pointer / ballistic
  -> prepared preview lookup and temporal metadata commit (synchronous)
  -> input immediately remains accepted
  -> controller records latest desired scene coverage
  -> cache performs bounded, cancelable background maintenance
  -> only a non-stale completed bank becomes active
```

`VisibleHotScene` is the already-available selected preview page. It is an
O(1) immutable lookup and must perform no scene preparation or layout.
`BackgroundSceneWindow` owns adjacent coverage, row text layouts and cache
rotation. Its work has no input gate and is latest-wins: a newer settled target
makes remaining chunks of an older target stale without discarding reusable
immutable entries.

## Scene-window input decoupling architecture card

### Scope and sources

- User requirement: FLUVI DASHBOARD — REMOVE INTERACTION COOLDOWN.
- Accepted reference paths: this design, the accompanying acceptance checklist,
  and `docs/dashboard/dashboard-rail-presentation-isolation-root-cause.md`.
- Existing implementation paths:
  `dashboard_core_controller.dart`, `dashboard_logbox_prepared_scene_cache.dart`,
  `core_dashboard.dart`, and `fluvi_app_shell.dart`.

### Single source and write path

- Source of truth: immutable `PreparedDashboardIndex` plus the controller's
  `DashboardNavigationState`.
- Read model: existing `DashboardVisibleFrameStore` hot preview and the cache's
  active immutable scene bank.
- Only write path: controller metadata commits followed by a generation-tagged
  cache-maintenance request; only the cache activates an immutable bank.
- Error/retry owner: the controller reports a cache maintenance error; no
  cache error may revoke interaction availability.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Rail preview and ballistic identity | existing motion kernel | gesture | untouched by cache maintenance |
| Settled temporal metadata | `DashboardCoreController` / presentation controller | screen | synchronous at settle |
| Vertical session generation | `DashboardLogBoxViewport` | pointer interaction | only a real vertical start creates one |
| Desired background coverage | `DashboardCoreController` | latest settle | overwritten by newer generation |
| Prepared/staged scene bank and layouts | `DashboardLogBoxPreparedSceneCache` | dashboard | activate only complete non-stale bank |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Rail physics and gestures | centered-carousel engine | velocity, inertia, snap and identity | do not duplicate or modify | frozen SHA-256 + trace tests |
| Scene text/layout cache | prepared-scene cache | width/content reuse, staging, eviction | extend this single owner | A→B→A cache test |
| Lifecycle coordination | core controller | latest target and metadata commit | extend controller | stale/latest-wins controller test |

### Layer flow

`TimeRefinementRail` / `DashboardLogBoxViewport` → `DashboardCoreController`
→ existing presentation and cache capability → immutable scene cache. Neither
presentation widget has repository, database, network or background workflow
ownership.

### Verification

- Domain/unit: controller ordering, cache reuse and stale cancellation.
- Widget/integration: next-frame vertical and repeated horizontal input.
- Screenshot/reference: no visual-reference change; no golden tests requested.
- Performance/cancellation: dense/light trace parity, preparation slice metrics
  and normal-entrypoint profile APK.

## Non-negotiable constraints

- Do not alter the 2025 seed volume, rail physics, rail controller identity,
  scroll-position identity, paging protocol, or stale vertical-session
  protection.
- No delay, debounce, cooldown, input block, golden test, hidden eager render,
  SQL, projection, formatting or `TextPainter.layout` on the rail hot path.
- The normal `lib/main.dart` HUMAN_DIAGNOSTIC profile APK is the delivery
  artifact; it must be downloaded, hashed and ZIP-verified after green CI.

## Verification design

Tests replace the old gate contract with immediate metadata/input acceptance,
latest-wins stale cancellation, cache reuse and dense-vs-light motion parity.
Diagnostics record preparation slices, yield count, layout/reuse/new counts,
notifier activity, pointer-to-session and release-to-ballistic latency, and
whether a genuine input was rejected. The frozen rail files are hash-checked
before and after the change.

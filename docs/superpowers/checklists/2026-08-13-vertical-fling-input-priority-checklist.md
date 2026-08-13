# Vertical fling input-priority checklist

Source: user task request of 2026-08-13 for `query` at `610925a`.

| ID | Requirement / source | Intended owner / area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VFI-01 | Observe, without changing, drag release, `goBallistic`, content-dimension changes and ballistic completion | Stable `DashboardLogBoxViewport` scroll-position observer | Each vertical interaction distinguishes no-ballistic release from ballistic start/end; the observer preserves controller/position/physics behavior | Widget/unit test + physical diagnostics | DONE — physical trace still pending. |
| VFI-02 | Keep vertical drag/ballistic input above speculative dashboard work | `DashboardCoreController` orchestration | Vertical interaction cancels/defers only speculative scene/query work; committed paging remains independently eligible | Controller lifecycle tests + source inspection | DONE — broader dashboard regression pending. |
| VFI-03 | Page TextPainter preparation must yield through scheduler priority, not zero-delay timers, with no yield log spam | `CommittedLogViewportCache` | Essential pages publish atomically after short `Priority.animation` slices; only real external preemption emits pause/resume | Cache tests + diagnostics | DONE — device slice timing pending. |
| VFI-04 | Remove committed-page query handling/reply dependence on Android main thread | `MainActivity` query dispatch | Bounded committed page calls use the background query queue; reply/phase diagnostics identify queue/submission and Dart platform duration | Kotlin tests/build + physical diagnostics | NOT DONE |
| VFI-05 | Retain committed vertical pages around bidirectional motion by bytes, not a fixed page count | `CommittedLogViewportCache` | Small scopes stay hot when within a hard byte cap; large scopes retain visible/history/forward safety pages and evict non-hot LRU pages | Cache/paging tests | NOT DONE |
| VFI-06 | Preserve exact identity and fail-closed rendering | Existing paging, cache, render owners | No stale/partial page, no changed physics/controller identities, no render-time layout, sequential cursors remain sequential | Regression suite + code inspection | NOT DONE |
| VFI-07 | Physical Android acceptance and downloadable normal APK | GitHub Actions + manual device run | Manual profile trace shows handoff state and no cache misses; online normal APK is downloaded to `/storage/emulated/0/Download` | Online build + manual test | NOT DONE |

Architecture card:

- The stable viewport owns observation and input intent only; it does not modify the framework simulation.
- `DashboardCoreController` arbitrates vertical-input priority versus speculation; `ExplicitCommittedPagingController` retains sequential keyset ownership.
- `CommittedLogViewportCache` alone owns private page text preparation, atomic drawable publication and byte-bounded retention.
- Android keeps Room/query work in the existing dashboard query path, moved to a dedicated background platform queue; no renderer or navigation path gains I/O.

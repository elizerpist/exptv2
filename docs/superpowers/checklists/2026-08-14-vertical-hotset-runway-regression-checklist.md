# Vertical hotset/runway regression — acceptance checklist

## Architecture card

| Concern | Existing owner | Required change | Only write path |
| --- | --- | --- | --- |
| Initial ready-hotset lifecycle and cursor requests | `ExplicitCommittedPagingController` | One immutable per-scope initial target with `pending → active → satisfied` state | Controller state transition methods |
| Committed page resources, retention and exposed runway | `CommittedLogViewportCache` | Keep prepared/exposed split; never claim an evicted page is drawable | Complete page commit plus explicit runway publication |
| Lifecycle signals | `DashboardCoreController` | Retry an existing pending intent only; never recreate it | Existing post-layout/idle callbacks |
| Scroll surface | `DashboardLogBoxViewport` / render surface | Render cache-exposed complete resources only | Existing stable controller/position |

No new cache, cursor owner, controller, position, physics, timer, or render-time
TextPainter path is permitted. UI continues to render supplied cache state only.

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VHR-01 | Root cause A | Paging controller | A new exact scope has exactly one fixed initial hotset target; later retries cannot move it | RED/GREEN controller test | DONE |
| VHR-02 | Root cause A | Core lifecycle | Post-layout and idle callbacks retry pending work only; `satisfied` is a no-op | RED/GREEN controller/core test | DONE |
| VHR-03 | Root cause A | Cache/runway | Runway publication does not create paging work and cannot walk the cursor while idle | Cache/controller test | DONE |
| VHR-04 | Root cause A | Cache retention | Exposed visible pages always retain both immutable page and prepared resources under the five-page cap | Cache/widget regression test | DONE |
| VHR-05 | Root cause B | Paging controller | An exact decoded page interrupted only by vertical input is retained and resumed/promoted without a second native read | RED/GREEN controller test | DONE |
| VHR-06 | Root cause B | Paging controller/cache | Scope/revision/generation supersession still drops stale deferred pages safely | Existing and extended stale tests | DONE |
| VHR-07 | Protected architecture | Query/scroll boundaries | Directional Query, staged Apply, stable scroll identity and fail-closed rendering stay unchanged | Focused query/viewport/boundary suites | DONE |
| VHR-08 | Delivery | Git/CI/APK | Two focused commits, pushed; physical Android verification explicitly pending | Verification evidence | PARTIAL |

## Frame-budgeted frontier and pre-ballistic runway follow-up

### Architecture card

| Concern | Existing owner | Required change | Only write path |
| --- | --- | --- | --- |
| Private page text/layout preparation | `CommittedLogViewportCache` | Keep both urgency lanes time-budgeted; urgency changes preemption eligibility, not atomicity or scheduler ownership | `_CommittedPagePreparationTask.prepare()` |
| Prepared versus Flutter-exposed exact geometry | `CommittedLogViewportCache` | Continue private commits; expose an already-complete contiguous prefix only through the cache-owned runway primitive | `publishPreparedRunway()` |
| Drag/ballistic phase selection | `DashboardLogBoxViewport` / existing `_VerticalInteractionSessionOwner` | Flush private exact runway at interaction start/drag; retain low-watermark publication only as ballistic emergency continuation | Existing scroll-notification lifecycle |
| Keyset reads and retained decoded page | `ExplicitCommittedPagingController` | Preserve serial cursor ownership and d4a396 retained-page/resume behavior | Existing controller request lifecycle |

No new cache, controller, `ScrollPosition`, physics, cursor owner, timer, or
render-time text-layout path is permitted.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VFR-01 | Commit 1 root cause | `CommittedLogViewportCache` | `frontierCritical` yields after genuine slice-budget exhaustion when private work remains | RED/GREEN cache test with injected scheduler handoff | DONE |
| VFR-02 | Commit 1 atomicity | Cache task | Frontier promotion retains progress and remains private until full exact page commit | Cache promotion/atomicity tests | DONE |
| VFR-03 | Commit 1 preemption | Cache task | Structural/stale preemption still supersedes at a scheduler boundary; vertical input is not foreground preemption | Cache regressions | DONE |
| VFR-04 | Commit 2 phase policy | Viewport/session owner | Already complete exact private runway is exposed on interaction start and drag before ballistic when possible | RED/GREEN viewport regression | DONE |
| VFR-05 | Commit 2 emergency correctness | Cache + viewport | Ballistic low-watermark can still atomically extend only complete exact runway | Existing/extended ballistic regression | DONE |
| VFR-06 | Protected ownership | Paging/cache/viewport | Serial keyset ownership, d4a396 decoded-page retention, controller/position/physics identity, five-page cap and fail-closed rendering remain unchanged | Focused/boundary suites | DONE |
| VFR-07 | Delivery | Git/CI/APK | Two scoped commits pushed; automated and physical evidence reported separately | Verification evidence | PARTIAL — local/focused and core/Flutter CI checks pass; the emulator profile gate is blocked by an unrelated rail scene-preparation slice, and normal-device acceptance remains manual |

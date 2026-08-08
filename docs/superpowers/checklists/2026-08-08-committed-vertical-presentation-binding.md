# Committed vertical presentation-binding acceptance checklist

## Architecture card

### Scope and sources

- **User requirement:** a visual no-op `preview -> committed` settle must still
  publish the authoritative LogBox presentation mode so the virtual committed
  surface exposes the cache's exact drawable extent to Flutter layout.
- **Root-cause evidence:** `DashboardVisibleFrameStore.promoteCommitted()`
  changes only `_value`; `logBoxLane` deliberately stays on the old preview
  frame. `DashboardLogBoxRenderSurface` currently derives both render domain
  and `SizedBox` height only from that stale payload-lane frame.
- **Existing paths:**
  `visible/application/dashboard_visible_frame_store.dart`,
  `logbox/application/dashboard_logbox_render_domain.dart`,
  `presentation/widgets/dashboard_logbox_render_surface.dart`, and
  `presentation/widgets/dashboard_logbox_viewport.dart`.

### Single source and write path

- **Payload source:** `logBoxLane`; it publishes only a changed visual payload.
- **Presentation source:** a new immutable `logBoxPresentationLane` published
  only by `DashboardVisibleFrameStore`; it owns mode, exact query/revision,
  epoch and payload viewport identity.
- **Only mode write path:** `publish()` / `promoteCommitted()` in
  `DashboardVisibleFrameStore` stage the presentation binding before its
  listeners are notified.
- **Read model:** the render surface builds one immutable binding from payload
  lane + presentation lane + committed cache. Paint, semantics, hit testing
  and `SizedBox` height use that same render-domain decision.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Visual LogBox payload | `logBoxLane` | Changed visual payload only |
| Mode and exact committed identity | `logBoxPresentationLane` | Every authoritative presentation change, including visual no-op settle |
| Ready pages / exact geometry | `CommittedLogViewportCache` | Atomic page commit / width preparation |
| Scroll extent | Flutter Sliver layout | Derived from the render binding's actual surface height |

### Frozen boundaries

No changes to `DashboardMotionKernel`, rail/carousel/physics,
`PreparedDashboardIndex`, `ExplicitCommittedPagingController` cursor/request
flow, `CommittedVerticalDemandPlanner`, root-page pinning, the keyset
repository, prepared rail scene cache, or human-vs-test APK product boundary.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CPB-01 | §§5–13 | visible-frame store + binding | Payload and presentation metadata have distinct canonical lanes | store unit test with notifier counters | DONE |
| CPB-02 | §§8, 20–22 | settle path | Same-payload preview→committed promotion has payload notifications = 0 and presentation notifications = 1 | red/green store test | DONE |
| CPB-03 | §§11–13 | domain resolver/render surface | A committed presentation binding selects `committedVertical` only for its exact cached root; rail preview remains independent | resolver + widget test | DONE |
| CPB-04 | §§12–16, 31–32 | render surface/sliver | RenderBox height and Flutter `maxScrollExtent` grow with actual 24→48→72→94 drawable geometry | drag-based widget regression | DONE |
| CPB-05 | §§20–27 | sibling child flow | A no-op June sibling settle reaches the final row through real drags; July/May/April and SUM/year behavior stay valid | 94-row July/June/May/April drag matrix + existing full suite | DONE |
| CPB-06 | §§15–16, 36 | diagnostics/report | Extent publication and mismatch diagnostics contain the authoritative and payload identities; normal flow has zero mismatch | focused diagnostic tests | DONE |
| CPB-07 | §§1, 18–19, 29–30 | frozen sources | No demand/paging/rail/physics/controller recreation or full-dashboard rebind regression | frozen-path diff + identity tests | DONE |
| CPB-08 | §§33–37 | delivery | Full non-golden suite, analysis and normal-entrypoint HUMAN_DIAGNOSTIC APK with hash/integrity | proot + Actions + artifact checks | PARTIAL — local checks PASS; Actions artifact pending |
| CPB-09 | §34 | physical device | June/May/April final rows are physically reachable with committed-domain geometry | user capture report | BLOCKED |

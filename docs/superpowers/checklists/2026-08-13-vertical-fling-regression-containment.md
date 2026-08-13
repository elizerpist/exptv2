# Vertical fling regression containment checklist

Source: user physical Android trace for `query` at `cac85a97` (2026-08-13).

Architecture card:

- Single source/write path: `ExplicitCommittedPagingController` owns one
  sequential cursor request and one private decoded page; `CommittedLogViewportCache`
  owns all rich/text presentation resources and atomic page publication.
- Input state: `DashboardCoreController` is the sole vertical-input lifecycle
  owner. The viewport only reports pointer/scroll observations and forwards
  intent; it never owns paging or cache state.
- Reuse decision: extend the existing cache preparation task and retention
  policy. No new paging, scene, or vertical cache owner is introduced.
- Layer flow: viewport input -> core vertical lifecycle -> paging coordinator
  -> committed viewport cache -> renderer. Native page data remains behind the
  existing repository adapter.

| ID | Requirement | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VFR-01 | Pause committed TextPainter preparation during drag/ballistic | paging controller + committed viewport cache | One decoded page stays private and resumes without a native reread; no partial page publishes | Cache/controller lifecycle tests | DONE |
| VFR-02 | Diagnose exact vertical background work | core contract + viewport diagnostics | Drag release reports scene/query speculation and committed request/pending/presentation state separately | Focused controller/widget test | DONE |
| VFR-03 | Restore hard movable prepared-page cap | committed viewport cache | Root remains pinned; at most five movable prepared pages survive a long traversal | Cache regression test | DONE |
| VFR-04 | Attribute zero-velocity input observations | stable viewport observer + transport adapter | One bounded raw input summary per session; platform response timing separates native work from Dart delivery/decode | Widget/adapter tests | DONE |
| VFR-05 | Preserve boundaries | existing owners | No physics/controller/position replacement, no render-time TextPainter, no stale or partial page | Boundary + relevant regression suites | DONE |
| VFR-06 | Physical Android acceptance | normal `lib/main.dart` profile APK | Repeated full-scope flings show no page layout during vertical input and no unbounded retained bank | CI build + manual device trace | NOT DONE |

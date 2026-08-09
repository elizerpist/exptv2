# Rail-Critical Visible Continuity Design

## Goal

Make a non-empty dashboard rail preview drawable on every published visible
frame, independently of cancellable background scene-window work.

## Scope and constraints

- Base: `245ab81dee09f09d5d627f6f5a27a8559cb748dd`.
- Preserve rail physics, carousel mechanics, input semantics, scroll reset,
  committed vertical paging, page size, keyset cursors, and latest-wins data
  revision semantics.
- No golden tests, hot-path scene builds, synchronous text layout, waiting,
  input cooldown, or renderer fallback.
- The first checkpoint contains runtime ownership, diagnostics, and one
  authoritative continuity test only. Test/CI consolidation is a later commit.

## Architecture card

### Existing implementation and root cause

`DashboardLogBoxPreparedSceneCache` already guarantees an immutable complete
active scene bank and hermetic staged replacement. Its active bank is selected
by `DashboardLogBoxRenderSurface` for rail preview painting. The old
`renderCriticalLogBoxSceneWindowFor` builds coverage around one temporal
anchor, so a cancelled replacement can leave an intact active bank that does
not contain a newly visible sibling payload.

### Sources of truth and write paths

| State | Owner | Publication rule |
| --- | --- | --- |
| Prepared data | `PreparedDashboardIndex` | Data runtime builds immutable candidate; dashboard core publishes only an accepted bundle. |
| Rail preview visuals | `RailCriticalSceneBank` | Renderer-visible bank contains only complete, exact-width/DPR scenes; one atomic active-bank replacement. |
| Revision bundle | `DashboardPreparedRevisionBundle` | Dashboard core publishes the data index and its rail-bank identity together after complete preparation. |
| Background locality work | Scene-window coordinator | May stage/cancel/restart; never supplies renderer correctness. |
| Committed vertical pages | `CommittedLogViewportCache` | Existing committed cache remains the sole vertical render authority. |

### RailCriticalSceneBank

The existing complete renderer-visible bank becomes the explicit
`RailCriticalSceneBank`. For one `PreparedDashboardIndex` revision and one
surface width/DPR it contains every bounded rail-reachable preview payload:

- SUM-to-year children;
- year-to-month children;
- month-to-day children;
- income and expense directions.

Rows are deduplicated by the existing immutable row-layout identity. The bank
never contains committed vertical pages or uncapped transaction lists.

### Publication flow

1. Build immutable `PreparedDashboardIndex` candidate.
2. Derive the full rail-critical preview window from that candidate.
3. Prepare a private complete rail bank with exact surface width and DPR.
4. In one synchronous publication transaction, activate that complete bank,
   publish `DashboardPreparedRevisionBundle`, and install its index into the
   presentation controller.
5. The renderer performs an O(1) exact lookup from `RailCriticalSceneBank`.

The old bundle remains active while a width/DPR or data-revision replacement is
prepared. User rail input never starts or waits for preparation.

### Error contract

A rail-bank lookup miss is an invariant violation. It is never repaired on the
paint or navigation hot path. For every frame with `payloadRowCount > 0`, the
surface records `visiblePayloadWithoutDrawable` if `drawableRowCount == 0`
and `visiblePayloadWithoutPaint` if `paintedRowCount == 0`, regardless of
background preparation state.

## Acceptance checklist

| ID | Source | Code area | Acceptance | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RCV-01 | User sections 2-5 | rail scene cache/core | Complete, immutable revision-scoped rail bank | focused cache and continuity tests | NOT DONE |
| RCV-02 | User sections 5-6 | core publication | Index and rail-bank identity publish transactionally | controller test and direct state inspection | NOT DONE |
| RCV-03 | User sections 8-11 | render surface | Rail preview has no background-window correctness dependency or fallback | continuity test | NOT DONE |
| RCV-04 | User sections 12-13 | render diagnostics | Non-empty visible payload cannot silently produce zero drawable/painted rows | widget continuity test | NOT DONE |
| RCV-05 | User sections 14-16 | dashboard continuity test | 2025 July cancel then June 24-row preview paints | targeted widget test | NOT DONE |
| RCV-06 | User section 17 | report/diagnostics | Bank count, unique layouts, headers, bytes, build duration are reported | focused test/report inspection | NOT DONE |
| RCV-07 | User section 1 | frozen paths | No rail physics, paging, scroll-reset, or input behavior changes | diff review and focused existing tests | NOT DONE |


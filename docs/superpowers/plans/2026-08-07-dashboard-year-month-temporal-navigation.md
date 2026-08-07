# Dashboard year/month isolation and temporal navigation implementation plan

Date: 2026-08-07

Execution mode: one agent, inline. Navigation ownership and presentation/render
measurements share state and are sequential; delegation would add conflict and
the user explicitly prohibited it.

Design:
`docs/superpowers/specs/2026-08-07-dashboard-year-month-temporal-navigation-design.md`

Acceptance gate:
`docs/superpowers/checklists/2026-08-07-dashboard-year-month-temporal-navigation.md`

## 1. Freeze and audit the milestone

- Preserve the branch/commit/tag and source hashes.
- Run the full non-golden 249-test suite and analyze in Ubuntu proot.
- Compare the month/day and year/month call graphs through render completion.
- Record every temporal state owner and transition read/write site.

## 2. Close the reproduction gap

- Extend the deterministic fixture from 9 to the production maximum 24 preview
  rows under a 94-entry month/658-entry year.
- Capture first/tenth and empty/populated build/layout/paint deltas in addition
  to already-equal velocity, ballistic input and endpoint.
- Preserve the pre-fix failure as the causal evidence.

## 3. Add RED architecture and temporal tests

- Fail closed if plane target derivation can bypass `DashboardTemporalAnchor`.
- Add 2024 → 2026 → Month, May retention, Month→Year→Month, rapid epoch,
  stale callback, direction and rail-open/closed cases.
- Add a notification/publish assertion proving one derivation and one commit.

## 4. Implement the canonical anchor

- Add the immutable anchor domain model.
- Replace independently stored cursor/retained temporal values with derived
  anchor accessors.
- Derive parent/child QueryKeys once per semantic transition and commit them
  atomically with navigation epoch.
- Reject stale settle/transition callbacks before they can write the anchor.

## 5. Add RED year/month presentation tests

- Assert constant-time summary/log payload identity selection and no collection
  equality/copy/projection.
- Assert bounded lazy row construction for the 24-row monthly payload.
- Assert zero root/Summary/rail/SVG rebuild, zero rail metric correction and
  stable controller/position/physics.

## 6. Apply the targeted post-lookup isolation

- Expose `PreparedSummaryFrame` and `PreparedLogViewportPayload` identities from
  the existing prepared frame without changing acquisition.
- Publish scalar summary lanes and a single immutable LogBox payload reference.
- Remove only the measured eager/offscreen/group traversal from the LogBox
  rail-frame render path.
- Keep visuals, paging, frame coalescing and month/day semantics intact.

## 7. Diagnostics and verification

- Add bounded typed temporal/year-month events and violation counters.
- Run focused RED/GREEN tests, then the full non-golden suite, analyze and
  architecture boundaries in Ubuntu proot.
- Recompute frozen hashes and scan the diff for prohibited behavior/goldens.

## 8. Profile and deliver

- Run the exact-commit online profile workflow with verbose FLOW disabled.
- Report empty/populated, first/tenth, month/day regression, temporal scenarios,
  UI/raster percentiles, allocation/GC and every acceptance status.
- Commit and push the coherent branch only after the checklist is re-read.

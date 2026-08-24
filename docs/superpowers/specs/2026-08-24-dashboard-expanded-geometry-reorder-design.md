# Dashboard Expanded Geometry Reorder Design

## Goal

Reorder only the expanded dashboard geometry to put the transaction action row
and Summary Pill between the header and mode-specific content. The collapsed
layout and downstream rail, handle, and LogBox anchors remain unchanged.

## Accepted inputs

- User task: Header → action → summary → mode content → rail → handle → LogBox
  when expanded; current collapsed layout when fully collapsed.
- Reference canvas: 412 × 892.
- Starting implementation: `DashboardLayoutMetrics` owns the expanded graph,
  `DashboardGeometryResolver` creates frames, and `CoreDashboard` renders them
  through a Stack.
- Starting branch: `separated-core-modes` at
  `5fe45e3e972de95d1a105937d90396ffca8a08bd`.
- Protected milestones: preserve controller, input, cache, and scroll
  ownership recorded in `MILESTONE_COMMITS.md`.

## Architecture card

### Single source and write path

- Source of truth: `lib/core/design/dashboard_layout_metrics.dart`.
- Read model: `DashboardLayoutFrame` from
  `DashboardGeometryResolver.resolve`.
- Production write path: only expanded metric getter dependencies.
- Persistent state, controller state, I/O, and gesture arbitration do not
  change.

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Expanded vertical anchors | `DashboardLayoutMetrics` | Rewire its one shared chain. |
| Collapsed anchors/interpolation | `DashboardGeometryResolver` | Preserve the existing owner and anchors. |
| Split-card endpoint motion | `HeaderCascadeMotion` | Preserve the timeline; supply relocated endpoints. |
| Balance, Budget, Mind layout | `DashboardLayoutFrame` | Reuse one shared frame; retain semantic composition. |
| Header pan input | `DashboardCoreModeHost` | Keep its actual `headerBounds` surface. |

### Layer flow

`DashboardLayoutMetrics → DashboardGeometryResolver → DashboardLayoutFrame →
CoreDashboard / mode surfaces`.

## Geometry

The metrics graph changes from:

`header → subheaderOne → zone2 → action → summary → rail`

to:

`header → action → summary → subheaderOne → zone2 → indicator → rail`.

No production pixel anchors are added. The formulas are:

```dart
actionTop = headerTop + headerExpandedHeight + standardGap;
summaryTop = actionTop + actionHeight + standardGap;
subheaderOneTop = summaryTop + summaryHeight + standardGap;
zone2Top = subheaderOneTop + subheaderOneHeight + standardGap;
railTop = zone2Top + zone2CardHeight + dotGap + dotHeight + standardGap;
```

The existing centered indicator relationship remains unchanged. At reference
size it yields action `241`, summary `304`, subheaderOne `374`, zone2 `457`,
indicator `681.5`, and rail `695`.

Collapsed action `219`, summary `282`, and rail `352` remain resolver-owned.
The existing rail-to-handle and LogBox derivation remains intact.
`headerGestureBounds` becomes exactly `headerBounds`; the actual mode-host pan
detector already uses that surface, avoiding a stale apparent overlay above
action and summary.

## Rendering and motion

`CoreDashboard` already inserts the mode host below action and summary in the
Stack. No renderer reorder is expected unless the new widget interaction test
demonstrates a necessary minimal change.

`HeaderCascadeMotion` keeps its master curve, intervals, scales, and
controller. Only its resolver-provided expanded endpoints move.

## Verification

- Resolver tests prove reference anchors, gaps, indicator symmetry, collapsed
  anchors, responsive derivation, mode parity, and the reversed Zone2-height
  dependency.
- Cascade tests prove existing motion ends at the shared relocated endpoints.
- Core dashboard widget tests prove expanded control positions and hit targets.
- Boundary, dashboard regression, and analyzer checks run in Ubuntu proot.
- The dedicated 412 × 892 expanded endpoint golden harness covers Balance,
  Budget, and Mind. It updates only those reordered expanded fixtures; the
  collapsed fixtures are protected by resolver/widget endpoint contracts and
  a direct before/after visual comparison, not regenerated.

## Out of scope

- No new curves, controllers, timing, springs, animation state, or motion
  tuning.
- No component resizing, styling/palette changes, per-mode coordinates,
  transaction/query/domain changes, or LogBox compensation.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| GEO-01 | Collapsed invariant | Metrics/resolver | Anchors stay 219/282/352; dimensions unchanged | Resolver/widget test and before/after endpoint comparison | DONE |
| GEO-02 | Expanded order | Metrics/resolver | Anchors are 241/304/374/457/695 from formulas | Resolver test and endpoint goldens | DONE |
| GEO-03 | Downstream invariant | Resolver | Rail/handle/LogBox relationships remain | Resolver test | DONE |
| GEO-04 | Indicator invariant | Metrics/resolver | Symmetric Zone2 → indicator → rail | Resolver test | DONE |
| GEO-05 | Mode parity | Frame/mode surfaces | Split and unified compositions share geometry | Resolver/mode test and endpoint goldens | DONE |
| GEO-06 | Dependency direction | Metrics/resolver | Zone2 height moves only downstream anchors | Resolver test | DONE |
| GEO-07 | Responsive invariant | Metrics | Web/scaled geometry remains derived | Resolver test | DONE |
| GEO-08 | Input/z-order | Core dashboard/host | Action and Summary remain interactive | Widget test, Stack inspection, and endpoint goldens | DONE |
| GEO-09 | Motion scope | Resolver/cascade | Existing owner and timing remain unchanged | Cascade test and source inspection | DONE |
| GEO-10 | Regression/delivery | Tests/CI | Required verification and normal APK delivery | Commands/Actions | PARTIAL — targeted checks are green; commit, Actions APK, and download remain. |

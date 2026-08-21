# Header raster + Avatar motion repair implementation plan

> Execute inline. The user prohibits subagents and requested implementation
> without a confirmation pause.

## 1. Freeze evidence and RED regressions

- Keep the missing current log explicitly BLOCKED; do not invent its CRITICAL
  rows.
- Add source-derived tests for continuous field interpolation, DPR/quality
  identity and retained field geometry on palette-only changes.
- Add avatar hot-path tests showing preview does not execute the drilldown
  publication and preserves the established centered-carousel target.

## 2. Refactor the narrow Header visual lane

- Retain reusable scalar/mesh field state in the paint-layer state rather than
  in each replacement `CustomPainter` delegate.
- Replace direct per-cell rectangle output with an interpolated mesh/direct
  continuous paint projection.
- Make sampling quality DPR-aware and expose bounded surface diagnostics.

## 3. Restore the motion/data boundary

- Keep `setTargetHandle` as the lightweight live crossing action.
- Coalesce only the transient preview state to the next display frame, latest
  value wins.
- Transfer committed Budget LogBox focus to the carousel settlement/explicit
  intent path; do not delay Header target feedback.

## 4. Verify and deliver

- Run focussed and protected tests in Ubuntu proot, inspect the checklist and
  confirm the shared physics source is unchanged.
- Commit/push focused repair changes, wait for CI and download the normal APK.
- Keep HRA-01/HRA-09 physical assertions truthful if the unavailable log or a
  human device profile remains outstanding.

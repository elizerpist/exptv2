# Mind cross-band pinch, pan-stable LOD, and Year 4×3 cell-floor repair

## Evidence and scope

- Starting application source: `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301`.
- Starting journal evidence: `aa2c0185cc7277509e4e9c60cc066feea13cf9be`.
- Visual evidence: latest Android screenshots in
  `/storage/emulated/0/Pictures/Screenshots` inspected before implementation.
- Frozen diagnostic evidence: journal entry **Fresh Sum physical log:
  cross-band pinch, pan morphology drift, Year 4x3 shrink regression**.
- Baseline Year source: `bda65eb9bedcb3cba5793208f059178a299a037e`.

## Architecture / reuse gate

- `MindDetailedSumNormalizedViewport` remains the sole Sum temporal state.
- Parent `MindDetailedSumChart` becomes the sole multi-pointer owner. Individual
  annual bands keep rendering, local one-pointer pan, and nearest-point tap
  selection only.
- `MindDetailedSumLod` is the one reusable source-only LOD mechanism. It must
  receive a stable calendar grid origin/resolution and crop a stable sampled
  representation; no second detail sampler is introduced.
- Stable annual Y domains are derived from the existing immutable current
  frame/range detail source. No Query, repository, Room, index or raw-ledger
  path may run on pointer updates.
- The Year direct-grid continues to use the existing `MindYearHeatmapMonthGroup`
  and `_MindYearHeatmapFourColumnFit`; reclaiming existing chrome/gaps replaces
  header-height subtraction as the source of selector space.

## Execution order

1. Add and run RED tests for cross-band parent pinch, fixed-zoom pan
   morphology/LOD overlap, and mounted 4×3 cell-floor/bounds behavior.
2. Move two-pointer scale lifecycle to the detailed-chart parent while keeping
   one-pointer vertical scroll, zoomed horizontal pan, boundary handoff, and
   tap owners distinct. Validate the fresh diagnostic fields.
3. Make per-year Y domains and same-resolution LOD buckets independent of
   horizontal viewport position, then validate overlap invariance.
4. Establish the pre-selector mounted 4×3 baseline and reclaim Year whitespace
   so the selector/header does not reduce actual painted day-cell size.
5. Run focused/host regression, format, analyzer, fast/boundary checks; commit
   each validated application unit with a separate journal-only commit. Push
   and deliver the online human APK and exact-source SCIP for the final SHA.

## Explicit non-goals

- No Sum PageView or exact yearly aggregate page is restored.
- No changes to Year secondary bar/line, Month, Day, BottomNav, Query,
  RangeSlider, Room/Kotlin/schema, Time/Avatar, Header, Budget, or LogBox.
- The exact screenshot APK identity remains missing; physical acceptance is
  user-only.

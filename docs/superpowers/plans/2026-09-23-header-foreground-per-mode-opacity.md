# Header foreground, palette and per-mode opacity implementation plan

Base: `616e87cb25ef08f6dbfb72fd4b1629418a4782e5`; later prompt-writer commits
through `39c6ca96773bb1e399c4a7361f04056909863883` are journal-only.

## Architecture card

`DashboardHeaderVisualController` remains the sole settings and ticker owner.
`DashboardHeaderVisualTuning` owns three bounded mode setting values:

```
Balance: palette/window + text foreground + chart foreground + opacity
Mind:    palette/window + text foreground + chart foreground + opacity
Budget:  existing colour source/window + opacity
    ↓
per-mode color policy emits DashboardHeaderVisualFrame
    ↓
same Header shell paints white base + one opacity-applied material layer
    ↓
mode detail reads foreground tokens for text and chart paint only
```

The palette sampling algorithm remains centralized: both new Balance lists use
`DashboardBalanceHeaderPaletteCatalog`; Mind uses its existing score-window
sampler with a palette enum rather than a second colour engine. Foreground is
an immutable frame token, so widgets render it and never own user state.

## Steps

1. [x] Audit journal, milestone, current source, matching graph provenance,
   current palette/color-policy/tuner/renderer consumers and Color Lab source.
2. [x] Create requirement checklist and this implementation plan.
3. [x] Add RED tests for authored palette orders/stops, independent foreground,
   independent per-mode opacity, tuner controls and presentation invariants.
4. [x] Extend bounded Header settings and controller setters without adding a
   controller or ticker.
5. [x] Extend palette samplers and per-mode frames/policies.
6. [x] Thread immutable foreground colour through Balance/Mind text and
   trend-chart renderers; preserve chart data and pointer ownership.
7. [x] Replace the old shared tuner opacity section with dedicated per-mode
   controls, then make RED tests green.
8. [x] Run focused Header, Balance, Mind and Budget regression tests, then
   analyze/format/diff and the established fast gate.
9. [ ] Re-read this checklist, commit one focused application change, push it,
   run one final online workflow/APK delivery, regenerate exact-SHA SCIP, then
   append a journal-only delivery entry and push it without a new build.

# Header typography and softened foreground implementation plan

## Goal

Add a bounded App/Color Lab Header typography comparison and a third,
source-derived softened-dark foreground option for independently selected
Balance/Mind text and trend-chart channels. This is Header presentation state
only.

## Source/evidence decisions

- Current application base: `65f33a4e388f6f796b77f31a5360e8f2f82a6f01`.
- Color Lab Portal content uses `color: rgba(20,33,58,.82)` in
  `docs/prototypes/color_lab.html`; this is the exact softened foreground.
- The compared Portal inherits the body’s authored `Inter, ui-sans-serif,
  system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`
  stack. Its nearby `SchedeeOutfit` selector is not the Portal selector and
  will not be used.
- Inter v4.1 is obtained from the official `rsms/inter` release and locally
  bundled with its SIL OFL 1.1 license. This makes the profile
  deterministic on Android while not claiming the user’s browser chose Inter
  rather than a fallback.

## Ownership/data flow

```text
DashboardHeaderVisualController (existing ticker + settings authority)
  -> DashboardHeaderVisualTuning (one typography profile; existing mode states)
  -> DashboardHeaderVisualFrame (foreground tokens + typography profile)
  -> Balance/Mind Header text and existing trend-chart renderers
```

No data model or chart geometry enters this flow. `DashboardHeaderTrendPainter`
continues receiving exactly the existing series, bounds, line width and hit
geometry; only its already-injected line color may differ.

## Implementation sequence

1. Add failing focused catalog/controller/tuner/style tests.
2. Run the focused RED command and retain its missing-API failure.
3. Add the `softenedDark` foreground token and an immutable typography profile
   to the existing visual tuning/frame/controller path.
4. Bundle official Inter and its OFL notice; register only a Header-local font
   family in `pubspec.yaml`.
5. Add the existing tuner’s typography control and thread the profile only to
   Balance/Mind amount/score and visual mode-label text.
6. Make the focused tests green, then run protected Header/Balance/Mind and
   fast/analyze/format/diff gates.
7. Re-read this checklist; commit one application change, push once and carry
   out the required final online APK delivery.
8. Generate SCIP twice from the fixed app SHA in the tooling worktree, commit
   those artifacts separately, and append a separate journal-only delivery
   commit.

## Explicit no-touch boundaries

No global `ThemeData` change, palette/opacity change, chart path/series/bounds
change, ticker/controller/store addition, persistence, Query/Summary/data work,
or Avatar/Time/carousel/gesture change.

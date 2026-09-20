# Mind Sum diagnostics and Year direct-grid acceptance checklist

## Architecture card

- **Financial authority:** the existing immutable `MindSumHeatmapFrame` and
  `MindYearHeatmapFrame` remain the sole current-filter/current-range inputs.
  Diagnostics, toggles, synchronized windows, and the Year layout must not
  create a Query, repository, Room, or range owner.
- **Sum presentation authority:** one local Sum state owns visualization mode
  and one shared normalized temporal viewport owns every visible detailed-year
  band. The top-right control remains the only visualization writer.
- **Diagnostics authority:** the existing bounded `FluviOnscreenDiagnostics`
  / debug-dropdown path receives scoped, copyable `MIND_SUM` events; no
  parallel debug surface or unbounded raw-event dump is introduced.
- **Year presentation authority:** `MindYearHeatmapViewport` owns the local
  in-card `3x4` / `4x3` selection. It is not persisted and it does not use the
  obsolete global month-card surface/layout settings.
- **Shared primitives:** existing palette resolver, anchored popup primitive,
  compact range control, monthly-overlay model/painter, and day-cell painter
  remain shared rather than copied.

| ID | Source / reference | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUMD-01 | 2026-09-20 physical feedback | Sum debug/onscreen diagnostics | Scoped Sum gesture/zoom/tap lifecycle events appear under the existing heatmap debug dropdown and can be copied; no unrelated dump | mounted debug-panel clipboard and lifecycle-event tests | DONE — Android physical use remains pending |
| SUMD-02 | 2026-09-20 physical feedback | detailed Sum chart state/model | A single shared normalized temporal window drives all visible yearly bands; multi-year pinch changes every band identically | RED/GREEN mounted multi-band noisy pinch test | DONE — device recognizer cadence remains physical-only |
| SUMD-03 | 2026-09-20 physical feedback | detailed Sum chart model | Home extent reaches <= about 184 visible days through accepted cumulative pinch; each zoom/tap event reports truthful window/LOD metrics | pure + mounted zoom-depth and diagnostic-event tests | DONE — device feel remains physical-only |
| SUMD-04 | 2026-09-20 physical feedback | Sum topology/modes | Exactly heatmap, detailed line, and monthly overlay are selectable only via the top toggle; no Sum PageView or exact aggregate page | existing `SUM3-TOPO` regression + source review | DONE |
| SUMD-05 | 2026-09-20 physical feedback | detailed Sum chart | Nearest truthful point inspection, faint monthly dashes, and 1/2/3+ band rules remain intact | Sum chart widget regressions + synchronized-window coverage | DONE — physical zoom acceptance remains pending |
| YEAR-DIRECT-01 | 2026-09-20 physical feedback + latest screenshots | Year primary viewport | Direct day-cell month groups render on the card, with no MonthCard surface/container setting or `2x6` path | RED/GREEN mounted Year viewport topology test | DONE |
| YEAR-DIRECT-02 | 2026-09-20 physical feedback | Year primary viewport | Header has title left and exactly local `3x4` / `4x3` selector right; settings/tuner no longer expose old Year layout/surface choices | mounted UI + settings/tuner tests | DONE |
| YEAR-DIRECT-03 | 2026-09-20 physical feedback + screenshot | Year primary geometry | Reduced month gaps and lower grid placement remove bottom dead space; `4x3` stays non-scrolling | mounted bounds/scroll tests, representative screenshot | PARTIAL — mounted geometry is green; a candidate-APK screenshot is still required |
| YEAR-DIRECT-04 | 2026-09-20 physical feedback | Year 3x4 renderer | Each month has scope amount and monthly closing balance below its direct day grid; `4x3` omits these rows | mounted content/semantics tests | DONE |
| YEAR-DIRECT-05 | protected Mind contract | Year primary interactions | Colored day taps/popup, palette/range behavior and Year bar/line secondary pages retain their current semantics | Year smoke and interaction regressions | DONE — exact Android validation remains pending |
| ARC-05 | `structuring-apps`, milestone 6e96218 | all changed paths | No duplicate state/query/gesture/cache/palette authority and no Avatar/Time/RangeSlider physics change | source review + boundary tests | DONE — `verify-fluvi-boundaries.sh` and the 431-assertion fast suite pass; device behavior remains physical-only |
| DELIV-04 | user workflow | GitHub/SCIP/journal | App commit is followed by a file-only `[skip ci]` journal commit; exact final app SHA has Actions human APK and exact matching SCIP | Git/Actions/artifact/graph audit | PARTIAL — app `f6d6da72` has exact APK and deterministic SCIP; Actions profile is inherited-red, and Android validation is user-only |
| PHYS-04 | user workflow | Android | User validates exact produced APK | user only | BLOCKED |

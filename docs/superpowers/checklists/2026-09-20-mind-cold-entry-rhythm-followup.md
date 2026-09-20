# Mind cold-entry, sparse-Sum, and temporal-card follow-up checklist

This checklist is the acceptance authority for the 2026-09-20 mixed repair
and presentation request. It supplements the immutable engineering journal;
it never reclassifies physical evidence as automated acceptance.

| ID | Requirement source | Code owner / area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AUD-01 | User prompt / journal | `FLUVI_ENGINEERING_JOURNAL.md`, `MILESTONE_COMMITS.md`, current source | Mandatory shared context, remote movement, and the supplied Budget screenshot are inspected before mutation. | Git/source audit; screenshot review. | DONE |
| AUD-02 | User prompt | `FLUVI_PROMPT_WRITER_RULES(1).md` | The named prompt-writer rules asset is read if present. | Repository/home + connected Drive search. | BLOCKED — asset was not found; user prompt and checked-in journal are the governing substitute. |
| BUG-SUM-01 | Exact 19c physical log / user prompt | `mind_detailed_sum_chart.dart` + detail model | A sparse year with a real nearest anchor beyond one LOD-padding bucket preserves a real paint-only continuation neighbour, while inspection remains restricted to in-window anchors. | New controlled RED→GREEN domain/widget test; bounded `BAND_SNAPSHOT` fields. | NOT DONE |
| BUG-SUM-02 | User prompt | Sum detailed chart | No fabricated boundary amount, Query mutation, repository/Room/index work, or changed zoom/tap semantics. | Source/boundary tests and targeted regressions. | NOT DONE |
| BUG-COLD-01 | User prompt / journal | Core Mind admission + Mind body host | Cold and warm Budget/Balance→Mind transitions emit stage-correlated timing for accepted request, prepared base, projection reuse/build, frame publish, first layout, and first paint. | Production-parent timing test plus bounded diagnostics. | NOT DONE |
| BUG-COLD-02 | User prompt | Proven cold-path owner only | The first entry presents the real admitted Mind frame as promptly as the warm path, without fake placeholders, Query mutation, or Budget/Balance regression. | RED→GREEN only after BUG-COLD-01 identifies the owner; Android diagnostic capture. | BLOCKED — causal timing boundary not yet proven. |
| SUM-AXIS-01 | User prompt / journal | `_MindDetailedSumMonthAxis` | Overview uses initials; zoomed ranges with sufficient slot width use full Hungarian month names without overlap/clipping. | Widget/layout tests for overview and zoomed domains. | NOT DONE |
| SUM-HEADER-01 | User prompt | `MindSumYearBandHeader` | Detailed line year/compact total match Sum overlay band placement, typography and formatting, from one immutable frame authority. | Existing header parity tests. | DONE — delivered in `f8edad8`/`19c1d69`. |
| SUM-CURVE-01 | User prompt | Mind presentation settings + detailed painter | Linear, monotone cubic, Catmull–Rom/tension, weighted 3/5/7 temporal smoothing, and independent adaptive smoothing remain separately configurable, raw inspection stays truthful, and controls cannot overshoot endpoints. | Existing domain/settings/widget tests. | DONE — delivered in `f8edad8`/`19c1d69`; retain in regression suite. |
| YEAR-LAYOUT-01 | User prompt | `mind_year_heatmap_viewport.dart` | 4×3 direct-cell, 3×4 MonthCard, and 2×6 MonthCard layouts exist; 2×6 carries month name, cells, Scope, Zárás and top-left date numbers. | Existing Year widget + 2×6 golden tests. | DONE — delivered in `f8edad8`/`19c1d69`; retain in regression suite. |
| YEAR-CARD-01 | User prompt | Year presentation settings + MonthCard renderer | Border and profitability tint/opacity apply only to 3×4/2×6 cards, never 4×3 cells or financial semantics. | Existing settings/Year viewport tests. | DONE — delivered in `f8edad8`/`19c1d69`; retain in regression suite. |
| YEAR-BAR-01 | User prompt | `MindYearHeatmapPartialBarPainter` | Year foreground bars derive their colour from the active heatmap palette/intensity authority, not a fixed unrelated colour. | Palette-reactivity widget/painter test. | PARTIAL — source uses the shared resolver; explicit current-context test is required. |
| MONTH-COMP-01 | User prompt + 19:51 Budget screenshot | Month temporal secondary cards + shared rhythm geometry | A new comparison card is additive to the existing rhythm card; it uses narrow rounded baseline-up filled bars, omits zero-day bars, tracks/outlines/remainders, and uses heatmap-reactive current-range colour. | RED→GREEN widget/painter tests and representative screenshot/golden. | NOT DONE |
| MONTH-COMP-02 | User prompt | Shared Month/Day temporal stats primitive | Month stat cards are larger/readable and preserve values/semantics. | Widget bounds + existing-stat regression. | NOT DONE |
| DAY-PRESENT-01 | User prompt | Shared temporal stats + Day timeline projection/painter | Day stat cards match enlarged Month stat-card geometry. | Widget bounds test. | NOT DONE |
| DAY-PRESENT-02 | User prompt | Prepared timeline event/read model + painter | Timeline primary marker label is `partner · amount`; real time stays available as secondary information and no UI-side ledger lookup occurs. | Projection + widget/painter tests. | NOT DONE |
| REG-01 | User prompt / milestones | Protected owners | Query/filter/range meaning, heatmap intensity, Scope/Zárás, Budget/Balance behavior, Avatar/Time controllers and the 6e962 interaction floor are unchanged. | Focused + fast + boundary suites; source diff review. | NOT DONE |
| VIS-01 | User prompt / AGENTS | Changed Month/Day visual surfaces | Changed visual states have screenshot/golden evidence; physical Android validation is not self-approved. | Golden/screenshot inspection plus normal human APK. | NOT DONE |

## Architecture card

- **Financial source of truth:** existing immutable prepared Mind membership and
  `Mind*HeatmapProjection` frames. The amount range remains the existing
  `QueryAmountRange` preview/commit owner.
- **Presentation source of truth:** `MindYearHeatmapPresentationSettings` and
  its controller. It already owns curve choices and Year MonthCard styling;
  this work does not add a second preference or query owner.
- **Shared visual primitives:** `MindYearHeatmapPaletteResolver` remains the
  only dynamic colour authority; `MindSumYearBandHeader` remains the single
  Sum annual-header primitive; `_MindTemporalStats` is the shared Month/Day
  info-card primitive to scale once.
- **Data boundary:** a Day timeline partner label, if the prepared contribution
  lacks it, must be retained in the immutable prepared contribution/event at
  projection admission. Widgets must not look up ledger rows or repositories.
- **Bug boundaries:** sparse Sum repair may extend only *paint context* with a
  nearest real source neighbour. Cold-entry repair is prohibited until bounded
  stage diagnostics identify the first slow component.

## Physical status

`PHYSICAL VALIDATION — PENDING, USER ONLY`

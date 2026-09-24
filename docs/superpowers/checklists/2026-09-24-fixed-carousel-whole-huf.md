# Fixed Balance carousel and whole-HUF presentation — Acceptance Checklist

## Architecture card

### Scope and sources

- User requirements: 2026-09-24 fixed Balance geometry/Latest-card prompt and
  palette cleanup/whole-HUF/Header parity prompt.
- Existing implementation: `BalancePresentationSettings` and
  `_BalanceUpperCarousel`; `DashboardPreparedFormatter`; Balance/Mind Header
  trend surfaces and `DashboardHeaderTrendChartStyle`; the existing Balance
  Header palette catalog/tuner.
- Protected physical baseline: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- Current behavioral source audited beneath journal commits:
  `22fb148a72383c3e39196b13f84a8f76c63bf159`.

### Single sources and write paths

| State / decision | Owner | Write path | UI boundary |
| --- | --- | --- | --- |
| Fixed Balance rail geometry | Balance-local geometry resolver in `_BalanceUpperCarousel` | None: immutable calculation from production constraints | Existing `CenteredCarousel` receives spec only; it remains gesture/physics owner. |
| Balance chart/time preferences | `BalancePresentationController` | Existing chart/time setters | Tuner forwards only these settings. |
| Exact HUF text | `DashboardPreparedFormatter.amountMinor` | Pure format function | Consumers render prepared exact-money text; compact formatters remain separate. |
| Header primary-value metrics | `DashboardHeaderTrendChartStyle` | Immutable Header-local visual token | Balance and Mind apply their own frame color/typography to shared metrics. |
| Palette family × variant | `DashboardHeaderVisualTuning` / catalog | Existing Header visual controller | Existing Balance color section presents the reduced catalog. |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Evidence |
| --- | --- | --- | --- |
| Carousel controller, position and physics | `CenteredCarousel` | Reuse unchanged; Balance only supplies a fixed local spec. | Source/graph audit and controller regression tests. |
| Exact HUF major-unit conversion | `DashboardPreparedFormatter`, with existing Query whole-HUF precedent | Change the central exact formatter; audit non-central presentation paths instead of replacing strings. | Formatter and presentation tests. |
| Primary header text lane | `DashboardHeaderTrendChartStyle` | Add one neutral metric token; do not fork Balance/Mind magic values. | Mounted header metric-parity test. |
| Balance palette sampling | `DashboardBalanceHeaderPaletteCatalog` + existing sampler | Delete inactive family data only; retain literal survivor anchors and current variant state. | Full-array catalog/tuner tests. |

### Layer flow

`Balance UI → existing presentation controller/settings → immutable local geometry spec → CenteredCarousel`.

`Prepared amount → DashboardPreparedFormatter → immutable presentation text → UI`.

No UI path may add repository, Query, index, scene, timer, ticker, or a second
carousel/controller owner.

## Acceptance inventory

| ID | Source/reference | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| GEO-01 | User geometry contract | `balance_presentation_settings.dart`, tuner | Width/gap session state, setters and controls are retired; chart/time controls remain. | Settings/tuner tests and source search. | DONE |
| GEO-02 | User screenshot relation | Balance-local carousel resolver | Settled center remains centered; side outer edges equal pre-change `.30/0` baseline; horizontal gaps equal Summary→card vertical gap symmetrically. | Production-parent rect tests at reference/narrow/wide widths. | DONE |
| GEO-03 | User interaction boundary | Balance surface | Widened visible card regions have coherent paint/hit/semantics bounds; no overlap or paint-only edge; controller/position/profile remain. | Hit-test/semantics and motion-identity regressions. | DONE |
| LATEST-01 | User compact-card contract | `_LatestCarouselPreview` | Exact `Utolsó tranzakció`, white receipt icon in existing-accent circle, two rows, no small-card date/time/amount. | Mounted widget/bounds test. | DONE |
| LATEST-02 | Existing Latest delivery | Large linked detail | Five fixed large rows retain avatar/title/category/date/HH:mm/right signed amount and no scroll/dividers. | Existing mounted detail regression. | DONE |
| PAL-01 | Palette cleanup prompt | palette enum/catalog/tuner | Only Soft Rainbow, Levander Rose Embrace, Limit (Color Lab), Custom Balance remain; 3 variants each = 12, exact survivors unchanged. | Full-array catalog/controller/tuner tests. | DONE |
| PAL-02 | Palette safety prompt | Header tuning | Removed selection is session-only or receives proven fallback; no persistence invented. | Source-wide serialization/persistence audit. | DONE — no serialization/persistence consumer exists. |
| HUF-01 | Whole-HUF contract | prepared formatter | Exact minor values use existing domain-consistent major-unit conversion with no fraction: zero/positive/negative/large/per-day covered. | Formatter RED→GREEN tests. | DONE |
| HUF-02 | Global presentation requirement | all `lib` money paths | Every user-visible exact HUF path is whole HUF; compact k/M decimal and non-money decimal remain. | Full `rg` audit plus representative Balance/Budget/Mind/Summary/LogBox/Query tests. | DONE |
| HDR-01 | Header parity prompt | Header trend kernel, Balance/Mind surfaces | Balance total uses Mind's 19/.96/-.76/w900 metric lane at same left/top while retaining its own value/color/profile. | Mounted production widget test. | DONE |
| REG-01 | Prompt no-touch/milestone | all changed surfaces | Financial/score data, Query/Summary, Movers/topic order, shared carousel motion, global geometry, Mind/Budget semantics unchanged. | Focused protected suites, diff and source review. | DONE |
| DEL-01 | User delivery instruction | GitHub/SCIP/docs | Atomic application commit pushed; exact normal human APK downloaded/hashed/identity-checked; exact-source SCIP separate; journal separate `[skip ci]`. | Actions/artifact/manifest/Git evidence. | NOT DONE |
| PHYS-01 | Evidence boundary | Android device | Physical design acceptance is only the user’s decision. | User validation. | BLOCKED — USER ONLY |

## Witnessed RED evidence

- `DashboardPreparedFormatter.amountMinor(550000)` rendered `5500,00 Ft` and
  `amountMinorPerDay(1200000)` rendered `12000,00 Ft/nap` before the formatter
  change.
- The catalog originally exposed eleven family values; the four-family catalog
  test failed at the extra third entry.
- The tuner originally mounted `balance-carousel-width-boost`; the retirement
  test therefore failed before the control/state removal.
- The selected Latest card originally mounted
  `balance-carousel-latest-inline-date`, which failed the final compact-card
  contract.
- The original Balance Header value used `titleMedium`/w700 rather than the
  Mind 19/.96/-.76/w900 lane.

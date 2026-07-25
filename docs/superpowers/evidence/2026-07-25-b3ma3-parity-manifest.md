# B3M-A3 parity manifest

## Frozen identity

| Item | Frozen value | Verification |
| --- | --- | --- |
| Main reference | `balance_latest_layout.html` | Direct source inspection |
| Exclusive screen | `[data-stage2-alternative="today-time-rail-permanent"]` | `renderExactB3M` clone branch |
| Main SHA-256 | `7940542ec918633de295b252c1c333e8f9a9df65f3a96680d269ca5335310d8f` | `sha256sum balance_latest_layout.html` |
| Runtime shell | `docs/prototypes/color_lab.html` → `strict-mother-child` | iframe and `cloneNode(true)` inspection |
| Runtime shell SHA-256 at inventory | `2637007d400e8fe63ef33170b27b00e96f5b0dbb6fc2a75cef9203511b9bf11b` | `sha256sum docs/prototypes/color_lab.html` |
| Design viewport | `412×892` logical px | `--screen-w`, `--screen-h` |
| Checklist | `B3MA3-PARITY-R5` | frozen parity checklist |

The main hash is mandatory. If it changes, implementation and visual comparison
must stop until the checklist records a new revision/hash. `color_lab.html` is
also recorded because the frozen main document loads and clones its current
brand, frame, and bottom-navigation DOM at runtime.

## Source and state cascade

The exact screen is created with all of the following states:

```text
data-stage2-alternative=today-time-rail-permanent
data-today-budget-pill-behavior=exit
data-today-redesign-density=time-rail-compact
data-today-time-scope-default=expanded
data-today-time-scope-mode=permanent
```

Computed properties must be read in this order:

1. `installTodayRedesignStyles` (`balance_latest_layout.html:1557-3384`)
2. `installTodayRedesignInteractionStyles`
   (`balance_latest_layout.html:3393-4564`)
3. base interaction selectors
4. `[data-today-redesign-density="time-rail-compact"]` overrides
5. `[data-today-time-scope-mode="permanent"]` overrides
6. action SVG/install factories, then exclusive action-toggle installer

No A, A2, other gallery alternative, old Flutter card, or Material default is a
visual source.

## DOM → Flutter inventory

| HTML selector/factory | Exact content/state | Flutter target | Behavior source | Checklist |
| --- | --- | --- | --- | --- |
| `.stage2-redesign-layout` | Full 412×892 Balance stack | `SpendeeBalanceMode` | Balance controller | GLOBAL, SHELL |
| `.stage2-redesign-topbar`, cloned `.spendee-brand-lockup` | Fluvi live logo/copy | shared brand lockup hosted by Balance | existing logo editor/fill map | SHELL-002/003 |
| `.stage2-redesign-balance-hero` | Balance, reserve, ratio, specks | `SpendeeBalanceHeader` | Balance collapse only | HEADER, MOTION |
| `.stage2-redesign-insight-grid` | 5 distinct infinite cards | `SpendeeBalanceInsightCarousel` | center carousel controller | FAST, DATA |
| `[data-today-insight-id=no-spend]` | No-spend days + lunar art | no-spend card branch | live frame resolver | FAST-002 |
| `[data-today-insight-id=category-change]` | category delta | category-change card branch | live frame resolver | FAST-002 |
| `[data-today-insight-id=latest-transaction]` | latest record | latest card branch | live frame resolver | FAST-002 |
| `[data-today-insight-id=trend-comparison]` | prior/current 30-day trend | trend card branch | live frame resolver | FAST-002 |
| `[data-today-insight-id=upcoming-recurring]` | pending recurring row | recurring card branch | live ghost resolver | FAST-002, CARD-003 |
| `.stage2-redesign-detail-stage` | 176px page + 6px dots | `SpendeeBalanceDetailCarousel` | center carousel controller | CARD-001 |
| `.stage2-redesign-today-detail` | Variable Napi/Heti/Havi budget | variable-budget page/painter | live filtered records/limits | CARD-002/004 |
| `.stage2-redesign-top-categories-detail` | 3 scope rows | top-category page | live ranked data | CARD-006 |
| `.stage2-redesign-top-merchants-detail` | Éves/Havi/Összesen Top 5 | top-merchant page | live ranked data | CARD-002/006 |
| `.stage2-redesign-average-daily-detail` | 30-day average/chart/facts | average-daily page/painter | live 30-day series | CARD-005/006 |
| `[data-today-ghost-toggle]` | local on/off per page/card | semantic ghost toggle | local flag + recompute | CARD-003 |
| `.stage2-redesign-action-grid` | exclusive income/expense | `SpendeeBalanceActionToggle` | active store type | ACTION |
| `createB3MA3AdaptiveIncomeWallet` | layered 1024 SVG | exact income SVG/painter | action pulse | ACTION-001/002 |
| `createB3MA3AdaptiveExpenseBag` | layered 1024 SVG | exact expense SVG/painter | action pulse | ACTION-001/002 |
| `.stage2-redesign-month-summary` | icon/title/value/chevron | `SpendeeBalanceSummary` | old summary gestures only | MONTH |
| `.stage2-redesign-search-row` | search/capsules + filter | `SpendeeBalanceSearchFilter` | old focus/query/capsules only | SEARCH |
| `createTodayTimeScopeDrawer` | permanent control/rail/dots | `SpendeeBalanceTimeScopeRail` | dynamic option resolver + carousel | RAIL |
| `.stage2-redesign-collapse-handle` | bar + changing label | collapse handle | exact 180px/50% controller | RAIL-001/002 |
| `.stage2-redesign-transaction-section` | heading + viewport | `SpendeeBalanceTransactionLog` | lazy builder | TXN |
| `.stage2-redesign-transaction-day-card` | one card/date | `SpendeeBalanceDayCard` | grouped canonical rows | TXN-001 |
| `.stage2-redesign-transaction-row` | avatar/copy/value/edit | `SpendeeBalanceTransactionRow` | filter/edit/swipe/delete/rename | TXN-002…004 |
| cloned `.common-header-bottom-nav` | shared 80px nav | `SpendeeTestBottomNav` | existing shell navigation | NAV |
| `.common-header-inline-fab` | 58px add FAB | `ExptFab` optional gradient | existing tap/long press | NAV-001 |

## Authored layout grid and effective geometry

All coordinates below are logical pixels in the 412×892 authored design grid.
The HTML phone frame itself has a 1px border with `border-box`, so browser
content measurements may appear inset by one pixel. Flutter comparison uses
the authored grid and crops equivalent content.

| Component | Effective geometry |
| --- | --- |
| page | `412×892`, background `#F8FAFC`, clipped frame radius `34` |
| topbar/brand | top `48`, left/right `16`, height `49`, z `8`; logo `56` |
| hero expanded | x `16…396`, y `104…230`, height `126`, radius `24`, padding `16 20 12`, z `5` |
| hero collapsed | height `104` |
| scroll content | top padding `241`, horizontal `16`, bottom `88`, vertical gap `11` |
| FastInfo belt | y `241…345`, height `104`, 3 equal boxes, outer flex gap `9` |
| detail stage | y `356…542`, height `186`, rows `176 + 4 + 6` |
| action row | y `553…595`, height `42`, side margin `4`, gap `10`, radii `16` |
| month summary | y `606…665`, height `59`, radius `20` |
| search row | y `676…715`, height `39`, columns `1fr 40`, gap `9` |
| permanent time scope | y `726…805`, height `79` |
| bottom navigation | inner/reference-local y `810`; outer 412×892 phone coordinate y `811` after the 1px frame inset; height `80`, padding `12 20` |
| transaction viewport | `calc(892 - 485) = 407` high behind/above nav clipping |

### Selector → computed-style → Flutter mapping

This table records the final `time-rail-compact` + `permanent` cascade, not
completion evidence. The linked checklist requirements remain `NOT DONE`
until their specified tests and screenshot overlays exist.

| Frozen selector/factory | Final computed style/geometry | Flutter property/target |
| --- | --- | --- |
| `.stage2-redesign-layout`, cloned `.phone-screen` | outer `412×892`; 1px frame inset yields `410×890` inner canvas; `#F8FAFC`; radius `34`; hard clipping | `SpendeeBalanceVisualSpec.viewport`, `canvas`, `screenBorderWidth`, `screenRadius`, `pageBackground`; `SpendeeBalanceDashboard` root |
| `.stage2-redesign-topbar`, `.stage2-redesign-balance-hero` | brand y `48`, h `49`, logo `56`; hero y `104`, h `126→104`, radius `24`, padding `16 20 12`; `118deg` four-stop gradient | `SpendeeBalanceVisualSpec.brand*`, `hero*`, `heroGradient`; `SpendeeBalanceHeader` |
| `.stage2-redesign-insight-grid`, `.stage2-redesign-insight-card` | y `241`, h `104`; three equal visible boxes; outer flex `gap: 9px`; compact card-internal overrides do not change that outer gap | `SpendeeBalanceVisualSpec.insightTop`, `insightHeight`, `insightGap`; `SpendeeBalanceFastInfoBelt` |
| `.stage2-redesign-detail-stage`, `.stage2-redesign-detail-carousel`, `.stage2-redesign-detail-page-dot` | y `356`, h `186`; page `176`; pagination gap `4`; inactive/active dots `4/6`, active `#E84CAE` | `SpendeeBalanceVisualSpec.detail*`; `SpendeeBalanceDetailCarousel` |
| `.stage2-redesign-threshold*` after the permanent override | rows `15px 13px 1fr`, right padding `23`; track `6`; marker `16`, white border `4`; fill `#FF4D79→#E94FCB`, shadow `0 2px 5px rgba(234,79,186,.20)`; marker shadows `0 3px 9px rgba(244,61,122,.30)` and `0 0 0 1px rgba(255,95,145,.22)` | `SpendeeBalanceBudgetProgressPainter` constants and geometry in `spendee_balance_card_painters.dart` |
| `.stage2-redesign-average-daily-detail .fastinfo-sparkline`, `buildTrendSparklineClipPath` | 30 values → six consecutive bucket averages; x `0…100%`, y `22…78%`; closed polygon to the bottom; fill `linear-gradient(180deg, rgba(139,125,250,.15), rgba(139,125,250,.03))`; `stroke: none` | `SpendeeBalanceDailyChartPainter.bucketAverages`, `pointsForSize`, and fill-only `drawPath`; no stroke paint |
| `.stage2-redesign-action-grid`, `.stage2-redesign-month-summary`, `.stage2-redesign-search-row` | action y/h `553/42`, margin `4`, gap `10`; summary y/h `606/59`; search y/h `676/39`, columns `1fr 40px`, gap `9` | `SpendeeBalanceVisualSpec.action*`, `summary*`, `search*`; `SpendeeBalanceActionToggle`, `SpendeeBalanceSummary`, `SpendeeBalanceSearchFilter` |
| `createTodayTimeScopeDrawer`, `.stage2-redesign-collapse-handle` | scope y/h `726/79`; control `21`, rail `37`; passive/selected pill `49×30` / `68×37`; dots `5`; handle `92×21` | `SpendeeBalanceVisualSpec.timeRail*`, `handleSize`, pill/dot sizes; `SpendeeBalanceTimeScopeRail` |
| `.stage2-redesign-transaction-day-card`, `.stage2-redesign-transaction-row` | card radius `18`; row min-h `50`; grid `31px minmax(0,1fr) auto 22px`; padding `7px 12px` | `SpendeeBalanceVisualSpec.dayCardRadius`, transaction row/avatar/edit/padding constants; Balance transaction-log widgets |
| cloned `.common-header-bottom-nav`, `.common-header-inline-fab` | nav inner/reference-local y `810`, outer phone y `811`, h `80`; FAB `58`; FAB gradient `140deg`, `#6065F5 0%`, `#8C5CEF 52%`, `#F25CBF 100%` | `SpendeeBalanceVisualSpec.bottomNavTop` is the inner `810`; the 1px shell inset yields outer y `811`; `SpendeeTestBottomNav`, Balance FAB gradient |
| `.stage2-redesign-scroll-content`, `.stage2-redesign-post-budget-content`, `attachTodayRedesignScrollInteraction` | native scroll contributes `-180p`, hero padding-flow shrink contributes `-22p`; effective shared flow `-(180p + 22p)`, with element-specific transforms applied separately | `SpendeeBalanceCollapseVisuals.scrollContentTranslateY`; `SpendeeBalanceDashboard` nested transforms |

### Hero drawing

- Gradient direction: `118deg`
- Stops: `#8079e9 0%`, `#a879ee 38%`, `#e985d9 69%`,
  `#ff8cad 100%`
- Radius: `24`
- Expanded/collapsed height: `126→104`
- Full layered border, gloss, shadow, specks, typography, meter, and divider
  declarations remain traceable to the selector/property table added during
  implementation review.

### FastInfo and detail surfaces

- FastInfo height `104`; exactly 3 equal visible boxes; no pagination dots.
- Detail page `176`; pagination inactive dot `4`, active `6`,
  active `#E84CAE`.
- The average-daily chart is a filled six-bucket clipped polygon. It has no
  separately painted line: final `stroke: none`.
- Compact detail tiles are `36` (average daily `32`);
  category/merchant mini avatars `17`.
- Each of the five belt cards and four detail pages retains its distinct DOM
  hierarchy/content.

### Post-header controls

- Actions: `42` high, side margin `4`, gap `10`, radius `16`; SVG art
  `50/48`; pulse duration `420ms`.
- Summary: `59` high; grid `25px 1fr auto 16px`; gap `9`; horizontal padding
  `15`; radius `20`.
- Search: `39` high; grid `1fr 40px`; gap `9`; field radius `21`; filter
  radius `17`.
- Rail control `21`; rail `37`; passive year `49×30`; selected `68×37`,
  radius `16`, font `15`; selected gradient
  `#715EFB→#B484F3→#E478C3`; dots `5`.
- Collapse handle `92×21`; internal grid `22px auto`; gap `5`;
  translated `-11px` from 50% so the bar, not the whole hit area, is centered.
- Transaction day-card radius `18`; row grid
  `31px minmax(0,1fr) auto 22px`; min-height `50`; padding `7px 12px`;
  edit button `22`, radius `7`.
- Balance-only FAB gradient: `140deg`, `#6065F5 0%`, `#8C5CEF 52%`,
  `#F25CBF 100%`.

## Collapse and animation manifest

`attachTodayRedesignScrollInteraction` defines a 180px virtual collapse
distance:

```text
p = clamp(offset / 180, 0, 1)
scrollTop = 180p
heroHeight = 126 - 22p
heroFlowDelta = 126 - heroHeight = 22p
effectiveSharedFlowY = -(180p + 22p)
insightProgress = clamp((p - .03) / .62)
insightOpacity = 1 - insightProgress
insightScale = 1 - .10 * insightProgress
insightTranslateY = -18 * insightProgress
detailProgress = clamp((p - .16) / .62)
detailOpacity = 1 - detailProgress
detailScale = 1 - .04 * detailProgress
detailTranslateY = -24 * detailProgress
heroStatOpacity = 1 - clamp((p - .08) / .52)
heroStatTranslateY = 10 * (1 - heroStatOpacity)
exitPostBaseShift = -((104 + 2*11 + 186) - 180p)
postTranslateY = exitPostBaseShift * detailProgress
```

- Stable endpoints: expanded `p=0`, collapsed `p=1`.
- The shared effective flow endpoint is `-(180 + 22) = -202px`: native
  viewport scroll and the `126→104` hero-flow shrink are cumulative. The
  post-content-specific endpoint is another `-132px`, so its total endpoint
  movement is `-334px`.
- `collapsing` is a transient render state, never a third snap point.
- Release snap threshold: `90px` / 50%.
- Click and keyboard toggle between endpoints.
- Handle uses direct finger follow after the 3px movement threshold.
- Insight pointer events turn off near `112.5px`; detail pointer events near
  `135.9px`.
- Action pulse samples: `.9 → 1.12 → .98 → 1` over `420ms`.
- Reduced motion removes decorative transition while retaining the resulting
  semantic state.

## Visual-source / behavior-source separation

| Component | Visual source | Permitted behavior source |
| --- | --- | --- |
| hero/boxes/cards/actions | frozen HTML/CSS/SVG only | B3M-A3 JS + live store |
| summary | frozen HTML only | existing `SummaryPill` gesture/ticker |
| search/capsules/filter | frozen HTML only | existing query/focus/capsule APIs; filter callback only |
| rail/handle | frozen HTML only | B3M-A3 rail JS + Budget center-carousel physics |
| transaction log | frozen HTML only | existing filter/edit/delete/rename/reset/lazy behavior |
| navigation/FAB | frozen HTML only | existing shell callbacks |

## HTML field → typed domain metric mapping

The typed source for the five FastInfo insights and four detail-page data
shapes is
`lib/features/transactions/state/balance_metrics_resolver.dart`.
`BalanceMetricsResolver.resolve(snapshot, includedGhosts:)` returns one
immutable `BalanceMetricBundle`; `BalanceFrameResolver` adapts these fields
into the `BalanceRenderFrame` consumed by widgets rather than recomputing
periods, ranking, ghost inclusion, budgets, or chart series in the UI.

| Frozen HTML field | Canonical metric/calculation input | Typed resolver output |
| --- | --- | --- |
| `[data-today-insight-id=no-spend]` value and meta | `metric('no_spend_napok_szama')` and its seven-day visual values | `insights[BalanceMetricInsightKind.noSpend]`: `primaryText`, `secondaryText`, `numericValue`, `sourceMetric` |
| `[data-today-insight-id=category-change]` amount, category, direction copy | `metric('legnagyobb_novekedo_kategoria')` plus current/previous rolling-30 category aggregates | `insights[BalanceMetricInsightKind.categoryChange]`: `primaryText`, `secondaryText`, `numericValue`, `category`, `sourceMetric` |
| `[data-today-insight-id=latest-transaction]` amount, merchant/time, avatar | `metric('legutobbi_tranzakcio')` plus the newest real or included ghost row | `insights[BalanceMetricInsightKind.latestTransaction]`: `primaryText`, `secondaryText`, `numericValue`, `category`, `record`/`ghost`, `sourceMetric` |
| `[data-today-insight-id=trend-comparison]` percentage, direction, comparison copy | `metric('koltesi_trend')` plus current/previous rolling-30 variable expense totals | `insights[BalanceMetricInsightKind.trendComparison]`: `primaryText`, `numericValue`, `comparisonValue`, `direction`, `sourceMetric` |
| `[data-today-insight-id=upcoming-recurring]` amount and next date | `metric('kovetkezo_ismetlo_kiadas')` plus the next in-scope included ghost | `insights[BalanceMetricInsightKind.upcomingRecurring]`: `primaryText`, `secondaryText`, `numericValue`, `category`, `ghost`, `sourceMetric` |
| `.stage2-redesign-today-detail` Napi/Heti/Havi labels, amount, remainder, count, progress and reference | canonical period aggregates and monthly overview limit; existing `mai_koltes`, `heti_koltes`, `havi_koltes` remain comparison metrics | `variableBudgets[BalanceMetricBudgetPeriod.day/week/month]`: `label`, `spent`, `budget`, `remaining`, `transactionCount`, `progress`, `referenceAmount` |
| `.stage2-redesign-top-categories-detail` period rows | variable-expense category groups for day/week/month/year; `top_kategoria_heten` is the existing comparison metric | `topCategories[BalanceMetricCategoryPeriod.*]`: nullable `BalanceMetricCategoryRank(category, amount, transactionCount)` |
| `.stage2-redesign-top-merchants-detail` Éves/Havi/Összesen Top 5 rows | ranked variable-expense merchant groups; `leggyakoribb_kereskedo` is the existing comparison metric | `topMerchants[BalanceMetricMerchantPeriod.year/month/allTime]`: ordered `BalanceMetricMerchantRank(rank, name, amount, transactionCount, category)` lists |
| `.stage2-redesign-average-daily-detail` amount, chart and three facts | `metric('atlagos_napi_koltes').series`, exactly 30 values | `averageDaily`: `dailySeries`, `rollingTotal`, `average`, `bufferDays`, `highestDay`, `spikeThreshold`, `spikeDays` |

Ghost-off uses an empty `includedGhosts` list; ghost-on supplies the selected
pending recurring rows through the same resolver. This mapping documents the
contract only; live invalidation and rendered parity still require the tests
and screenshots named in `A3-DATA-*`.

## Evidence status

The implementation and its automated unit/widget/interaction coverage now
exist, including bounded 10k store paging, a 600-row lazy widget path,
same-revision frame reuse, two-way two-option rail wrapping, date-boundary
recurring projection, keyboard/semantics states, and explicit merchant
rename/revert actions. The final local verification produced a clean full
`flutter analyze`, 128/128 passing Balance feature tests, eight passing
frozen-prototype static contracts, and a non-updating pass for both B3M-A3
production goldens. The repository-wide test run produced 1213 passes, one
skip, and the single pre-existing failure in the untouched
`test/settings/fast_info_options_panel_test.dart` (`expected 11`, `actual
10`). These automated results are not treated as visual completion.

Expanded and collapsed reference captures, app goldens, side-by-side images,
and 50% overlays are present under
`docs/superpowers/evidence/screenshots/` and `test/goldens/`. Their current
metrics and SHA-256 identities are recorded in
`2026-07-25-b3ma3-visual-comparison.md`. Both comparisons remain visibly
nonzero, so the corresponding checklist states remain `NOT DONE`.

Nineteen required visual state rows still have no normalized reference/app
pair. The required target-device profile-mode `FrameTiming`/DevTools trace,
memory capture, list/rail fling trace, and ten animated collapse cycles are
also absent. The existing 600-row widget instrumentation proves bounded
construction and rebuild isolation, but it is not a substitute for that
profile evidence.

The frozen full-screen reference itself combines mutually inconsistent
production states (Income action with expense data, monthly summary with an
annual rail, stale latest transaction) and omits the mandatory header menu.
Consequently a normalized, approved reference revision/state matrix is needed
before the zero-tolerance whole-screen visual gate can be completed.

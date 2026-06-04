# FastInfo Catalog Redesign Design

## Status and Goal

Approved in the June 4, 2026 FastInfo card review.

Replace the current 78-card FastInfo catalog with 18 useful, non-duplicated
cards. Every retained card uses live app data and the agreed calculation. Old
saved configurations migrate deterministically; removed cards do not remain
selectable and do not render saved placeholder values.

## Non-Goals

- Keep three pill slots and three box slots; do not add more slots.
- Do not add a separate FastInfo balance card because balance remains in the
  header.
- Do not retain debug, parser, database-health, notification, backup, sync, or
  import/export cards.
- Do not auto-fill slots made empty by migration.
- Do not draw filler visuals without meaningful data or a denominator.

## Shared Rules

### Time Periods

- Day means the local calendar day.
- Week means Monday through Sunday in the local timezone.
- Month means the local calendar month.
- Rolling 30 days means today plus the preceding 29 calendar days.
- Previous rolling 30 days means the 30 calendar days immediately before that.
- Same-day monthly comparison means current month day 1 through today versus
  previous month day 1 through `min(today.day, previous month length)`.
- Expenses are absolute values of negative amounts; income is positive amounts.

### Trends and Limits

Expense increase is a red upward arrow; expense decrease is a green downward
arrow. Income increase is a green upward arrow; income decrease is a red
downward arrow. When the previous value is zero, show `Nincs összehasonlítás`
instead of an infinite or fabricated percentage.

Expense-limit progress colors are green below 75%, yellow from 75% through 100%,
and red above 100%. The metric ratio may exceed `1.0`; the painter may clamp its
width but must retain the red overspending state. Without a required limit or
goal, hide the related progress visual and dependent values.

Any FastInfo calculation needing account balance uses the same numeric all-time
balance as the header: `all-time income - all-time expense`. The resolver
receives this value from `TransactionStore` rather than defining separate math.

## Retained Catalog

### 1. Mai költés (`mai_koltes`)

Primary is today's expense, emphasized as `elköltve`. Secondary information is
today's remaining recommended ceiling and transaction count. An arrow and
percentage compare today with trailing 30-day average daily expense, including
zero-spend days. Show colored progress only with a current monthly limit.

`daily ceiling = max(0, monthly limit - current-month expense before today) / remaining days including today`

`daily remaining = max(0, daily ceiling - today's expense)`

`progress = today's expense / daily ceiling`

The ceiling excludes today's spending from its numerator, so it remains stable
throughout the day. This card absorbs `mai_maradek_keret`,
`napi_ajanlott_maximum`, `mai_koltes_ajanlotthoz`,
`mai_nap_atlaghoz_kepest`, and `ma_rogzitett_tranzakciok_szama`.

### 2. Heti költés (`heti_koltes`)

Primary is current Monday-through-today expense. Secondary information is the
remaining derived weekly allowance. The trend compares the current week through
today with the previous week through the same weekday. The visual is seven
Monday-Sunday bars; future current-week days are empty, not zero-spend bars.

`weekly allowance = monthly expense limit / 4.345`

`weekly remaining = max(0, weekly allowance - current-week expense)`

Only show allowance information when a monthly limit exists. This card absorbs
`heti_maradek_keret` and `ez_a_het_elozo_hethez`.

### 3. Havi költés (`havi_koltes`)

Primary is current calendar-month expense. Secondary information is limit usage
and remaining amount when a monthly limit exists. Trend compares current
month-to-date with the previous month through the same calendar day.

The compact chart contains non-cumulative daily expense lines for current month
ending today, previous full month, and the full month before that. Outlier days
therefore create spikes. The chart has no axes or labels and has a tiny
three-color legend. This card absorbs `havi_limit_allapot` and
`ez_a_honap_elozo_honaphoz`.

### 4. Megtakarítás (`megtakaritas`)

Primary is current-month actual savings. Secondary is savings rate. Show a goal
ring only when a configured monthly saving goal exists.

`actual savings = max(0, current-month income - current-month expense)`

`goal progress = actual savings / configured monthly saving goal`

`savings rate = actual savings / current-month income`

Without a goal show `Nincs cél`; without income omit savings rate. This card
absorbs `megtakaritasi_cel_haladas` and `havi_megtakaritasi_rata`.

### 5. 30 napos költési trend (`koltesi_trend`)

Compare the rolling last 30 days with the immediately preceding 30 days. Show
the arrow and percentage beside the value, with current and previous totals as
secondary context. Do not draw a graph or progress bar. When a monthly limit
exists, the card includes a compact pace status derived from
`havi_keret_egesi_sebesseg`.

### 6. Utolsó tranzakció (`legutobbi_tranzakcio`)

Show amount as primary, then merchant/name, category, and time. Use the
transaction category's existing color and icon as an avatar.

### 7. Várható hó végi költés (`varhato_ho_vegi_koltes`)

Show projected current-month expense, projected month-end remaining, and a
forecast sparkline.

`projected expense = current-month expense / elapsed month days * days in month`

When a monthly limit exists, color the risk using projected expense versus that
limit. Without a limit, show forecast only. Projected remaining is current-month
income minus projected expense. This absorbs `tulkoltes_kockazat` and
`ho_vegi_becsult_maradek`.

### 8. Kategórialimit állapot (`leggyorsabban_fogyo_kategorialimit`)

Show the category with the highest current-month limit usage, its avatar and
progress, plus counts near and over limit. Near-limit is 75% through 100%; over
limit is above 100%. This absorbs `limit_feletti_kategoriak_szama`,
`kategoria_limit_kozeleben`, and `kategoria_limit_tullepve`.

### 9. Leggyakoribb kereskedő (`leggyakoribb_kereskedo`)

Rank all-history expense merchants by transaction count, then larger total
expense, then merchant name. Show transaction count first and total amount
second. The avatar comes from the merchant's most frequent expense category.

### 10. Átlagos napi költés (`atlagos_napi_koltes`)

Show trailing 30-day average and a trailing 30-day daily-spend sparkline. Include
full-balance runway days as secondary information.

`average = rolling 30-day expense / 30`

`balance runway days = max(0, shared header balance) / average`

Zero-spend days count as zero. If average is zero, omit runway instead of showing
infinity. This absorbs the full-balance meaning of `puffer_napok_szama`.

### 11. No-spend napok (`no_spend_napok_szama`)

Count zero-expense days in the elapsed current month, including today and
excluding future days. The ring shows `no-spend days / elapsed month days`.

### 12. Top kategória ma (`top_kategoria_ma`)

Rank today's categories by total expense amount, then transaction count, then
category name. Show avatar, name, amount, and share of today's expense.

### 13. Top kategória héten/hónapban (`top_kategoria_heten`)

Weekly top category is primary and monthly top category is secondary. Both rank
by expense transaction count, then larger total expense, then category name. Use
the weekly primary avatar. This absorbs `top_kategoria_honapban`.

### 14. Legnagyobb kategóriaváltozás (`legnagyobb_novekedo_kategoria`)

Compare rolling last 30 days with previous rolling 30 days and choose the
category with the largest absolute percentage change. Show avatar and red-up or
green-down trend. A category absent previously but positive now displays `Új`,
not infinity. This absorbs `legjobban_csokkeno_kategoria`.

### 15. Közelgő ismétlődő kiadások (`kovetkezo_ismetlo_kiadas`)

Show next recurring expense name, amount, due date, and category avatar. Include
next-seven-calendar-day total and count. Use recurring ghost data from
`TransactionStore`, not new merchant-history inference. This absorbs
`kovetkezo_7_nap_fix_kiadasai`.

### 16. Havi fix költségek (`havi_fix_koltseg_osszesen`)

Show current-month expected recurring expense as primary. Secondary information
is already deducted fixed expense, remaining fixed expense, largest fixed
expense, and budget remaining after fixed expense. Use recurring ghosts plus
matching realized transactions. Show the fixed-expense/monthly-limit ring and
budget-after-fixed only when a monthly limit exists.

This absorbs `fix_koltseg_aranya_havi_keretbol`, `mar_levont_fix_kiadasok`,
`meg_varhato_fix_kiadasok`, `legnagyobb_fix_kiadas`, and
`fix_koltsegek_utan_marado_keret`.

### 17. Havi bevétel (`bevetel_ebben_a_honapban`)

Show current calendar-month income and compare month-to-date with the previous
month through the same calendar day. Secondary information is income coverage:

`income coverage days = current-month income / trailing 30-day average daily expense`

Thirty or more days is positive; below 30 is a warning. Omit infinity when
average expense is zero. This absorbs the monthly-income meaning of
`puffer_napok_szama`.

### 18. Kiadás/bevétel arány (`kiadas_bevetel_arany`)

Show current-month expense divided by current-month income, with net monthly
cashflow as secondary information. Use the shared green/yellow/red progress
thresholds. When income is zero, omit percentage and progress. This absorbs
`netto_havi_cashflow`.

## Migration Map

Only these legacy IDs map to retained canonical cards:

| Canonical ID | Legacy IDs mapped to it |
| --- | --- |
| `mai_koltes` | `mai_maradek_keret`, `napi_ajanlott_maximum`, `mai_koltes_ajanlotthoz`, `mai_nap_atlaghoz_kepest`, `ma_rogzitett_tranzakciok_szama` |
| `heti_koltes` | `heti_maradek_keret`, `ez_a_het_elozo_hethez` |
| `havi_koltes` | `havi_limit_allapot`, `ez_a_honap_elozo_honaphoz` |
| `megtakaritas` | `megtakaritasi_cel_haladas`, `havi_megtakaritasi_rata` |
| `koltesi_trend` | `havi_keret_egesi_sebesseg` |
| `varhato_ho_vegi_koltes` | `tulkoltes_kockazat`, `ho_vegi_becsult_maradek` |
| `leggyorsabban_fogyo_kategorialimit` | `limit_feletti_kategoriak_szama`, `kategoria_limit_kozeleben`, `kategoria_limit_tullepve` |
| `atlagos_napi_koltes` | `puffer_napok_szama` |
| `top_kategoria_heten` | `top_kategoria_honapban` |
| `legnagyobb_novekedo_kategoria` | `legjobban_csokkeno_kategoria` |
| `kovetkezo_ismetlo_kiadas` | `kovetkezo_7_nap_fix_kiadasai` |
| `havi_fix_koltseg_osszesen` | `fix_koltseg_aranya_havi_keretbol`, `mar_levont_fix_kiadasok`, `meg_varhato_fix_kiadasok`, `legnagyobb_fix_kiadas`, `fix_koltsegek_utan_marado_keret` |
| `kiadas_bevetel_arany` | `netto_havi_cashflow` |

All other original IDs not among the 18 canonical cards migrate to an empty
slot and are removed from the selectable catalog.

Migration runs while loading `FastInfoConfig`:

1. Scan pill slots 0-2, then box slots 0-2.
2. Keep canonical IDs; replace mapped legacy IDs with their canonical ID and
   rebuild from the canonical catalog while preserving slot type.
3. Replace all other removed or unknown IDs with `null`.
4. Globally deduplicate across pills and boxes. First occurrence in scan order
   wins; later occurrences become `null`.
5. Preserve every resulting position. Do not move or auto-fill cards.

New installations use defaults chosen only from the retained catalog.

## Architecture and Data Flow

Replace the current mostly preformatted `FastInfoMetricResult` with a structured
render model capable of representing compact pill value, primary box value,
ordered secondary rows, trend direction/text/semantic color, category avatar,
progress ratio and semantic state, single-series sparkline, multi-series line
chart with legend, seven-day bars with future-day state, and explicit missing
data status.

The renderer owns layout and formatting. The resolver owns calculations, period
semantics, availability, and semantic meaning. Use shared visual components
rather than 18 unrelated bespoke box widgets.

`TransactionStore` assembles one immutable FastInfo snapshot containing
transactions, categories, limits, recurring ghost transactions, numeric header
balance, current local date, and configured monthly saving goal. The resolver
builds reusable period aggregates once per snapshot. Settings preview uses the
same result contract with deterministic preview inputs.

Invalidate the FastInfo cache when transactions, categories, limits, recurring
ghosts, or relevant goals change, and when the local date changes. Do not resolve
metrics per animation frame.

## Layout and Rendering

- Keep three pills and three side-by-side boxes.
- Increase box height from 84 px to 112 px.
- Increase live panel and settings preview height to avoid clipping.
- Simple cards show only real content, with no filler graphics.
- Avatar cards use existing category color and icon.
- The monthly chart uses three distinct readable colors and a tiny legend.
- Primary values remain emphasized; secondary content truncates cleanly and
  never overlaps or overflows.

## Missing Data Behavior

- No limit: hide limit progress and limit-dependent values.
- No saving goal: show `Nincs cél`; hide goal ring.
- No comparison denominator: show `Nincs összehasonlítás`; hide percentage.
- No applicable transaction or recurring data: show `Nincs adat`.
- Zero average daily expense: omit runway/coverage rather than showing infinity.
- A failure to resolve one metric must not prevent other cards from rendering.
- Never fall back to catalog demo values in the live panel.

## Testing and Verification

Resolver tests cover local date boundaries, Monday-Sunday weeks, rolling 30/60
days, leap years, short previous months, same-day comparisons, stable daily
ceiling, future weekly bars, 75%/100% thresholds, trend semantics, zero or absent
denominators, ranking tie-breakers, recurring-ghost calculations, shared balance,
and migration/deduplication.

Widget tests cover hidden visuals without limits/goals, semantic colors, arrows,
avatars, rings, seven-day bars, forecast sparkline, three-line monthly chart,
compact pills, lack of filler visuals, and no overflow at narrow and wide widths.
They also verify that settings and live panels use the structured result and only
18 cards appear in the pool.

Before completion run formatter, analyzer, targeted FastInfo and migration tests,
then the full Flutter test suite.

## Acceptance Criteria

- Exactly 18 approved canonical cards are selectable.
- Every retained card uses the calculations and periods in this document.
- Merged information exists only on its canonical card.
- Old configurations migrate without crashes, slot movement, or automatic
  replacement of removed cards.
- Limit- and goal-dependent visuals appear only with a real denominator.
- The monthly chart shows current, previous, and two-months-ago daily expense,
  with the current line ending today and visible outlier spikes.
- The three-column panel uses taller boxes without overlap or overflow.
- Analyzer and the full test suite pass.

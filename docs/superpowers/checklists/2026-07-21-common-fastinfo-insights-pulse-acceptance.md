# Common FastInfo Insights Pulse Acceptance List

Working artifact: `balance_latest_layout.html`.

This is the canonical review list for the shared FastInfo Insight Card and
Pulse relationship. The gallery-specific checklist covers B3M delivery and
visual fidelity; this file covers whether a card, its calculation, and its
future Pulse rule tell one consistent story.

## Product Rule

- Every financial state that can later produce a Pulse message must have one
  visible Insight Card with the same canonical calculation.
- A Pulse is a delivery decision over a visible insight, not a separate or
  hidden financial insight.
- An insight can explicitly have no Pulse trigger. That is different from a
  hidden, unmapped trigger.
- Pulse infrastructure such as priority, lifecycle, fingerprint, and header
  morph may remain engine-only because it is not a financial insight.
- A proposed Pulse detector without a visible owning card is disabled until a
  visible card is accepted.

## Source Register

| Source | Role |
| --- | --- |
| `balance_latest_layout.html` | Reviewable B3M card artifact and future card-backed trigger declarations. |
| `lib/features/settings/models/fast_info_card_catalog.dart` | Current 16-card Flutter FastInfo inventory; the generic monthly-income card is removed and the gallery additionally excludes the header-owned ratio card. |
| `lib/features/transactions/state/fast_info_metrics_resolver.dart` | Existing live FastInfo calculations and visual descriptors. |
| `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/docs/superpowers/specs/2026-07-13-hidden-forecast-pulse-design.md` | Accepted Pulse calculation and delivery design. |
| `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/docs/superpowers/checklists/2026-07-13-hidden-forecast-pulse-checklist.md` | Pulse implementation backlog; it is not yet implemented. |

## Program Status

| ID | Acceptance condition | Status | Evidence / gap |
| --- | --- | --- | --- |
| CFIP-001 | A shared FastInfo/Pulse acceptance list exists and is updated during card review. | DONE | This file. |
| CFIP-002 | All 15 selected insights are present in the B3M gallery. | DONE | Gallery catalog and static test exclude the header-owned ratio and generic monthly-income cards. |
| CFIP-003 | Every financial Pulse detector has one visible owning Insight Card, or is explicitly disabled. | NOT DONE | Pulse-only candidates still need disposition. |
| CFIP-004 | Each reviewed card has one typed canonical metric definition, rather than separate FastInfo and Pulse formulas. | NOT DONE | Existing resolver mixes presentation strings and calculation; gallery has no canonical metric schema yet. |
| CFIP-005 | Each reviewed card stores its visible Stage1/Stage2 data and Pulse trigger rule together in the gallery catalog. | NOT DONE | The gallery currently stores visible prototype data only. |
| CFIP-006 | FastInfo visuals and Pulse trigger zones use the same thresholds and scope. | NOT DONE | The 30-day trend visual is not yet bound to the Pulse thresholds. |
| CFIP-007 | Pulse messages do not repeat unchanged state and may compose related visible insights into one story. | PARTIAL | Accepted Pulse design exists; engine/reducer is not implemented. |
| CFIP-008 | Every no-trigger card explicitly records `pulse: none`; no card is silently omitted. | NOT DONE | Mapping review has not been completed. |
| CFIP-009 | Engine-only mechanics are separated from financial insight definitions. | PARTIAL | Policy is defined; implementation and ownership review remain. |
| CFIP-010 | The Flutter Pulse engine consumes the same typed metric data as FastInfo. | NOT DONE | Pulse implementation backlog remains entirely open. |
| CFIP-011 | `kiadas_bevetel_arany` and its `HF-009_EXPENSE_INCOME_RATIO` candidate are retired from the B3M insight plan rather than duplicated beside the static Balance header. | PARTIAL | Gallery entry is removed; this prototype task does not modify the current Flutter catalog/resolver/surfaces. |
| CFIP-012 | `bevetel_ebben_a_honapban` is absent from B3M and the FastInfo catalog while its raw income and pending-income-ghost aggregates remain available to other calculations. | DONE | Catalog/config/resolver tests prove card removal and retain the `megtakaritas` expected-income projection. `MonthlyIncomeSummary` retains the card-independent input set for the Pulse backlog. |
| CFIP-012R | User instruction: revert the unapproved removal of the monthly-income calculation without restoring the FastInfo card. | `FastInfoPeriodAggregates`; `HF-007_GHOST_INCOME_MISSING` plan source | A reusable monthly-income summary exposes received, pending, expected, variable, previous-period variable income, and coverage inputs; the catalog still omits `bevetel_ebben_a_honapban`. | `fast_info_period_aggregates_test.dart` proves the summary; catalog test proves no card is restored; the Pulse plan now references the summary rather than deleted `_monthlyIncome`. | DONE |

## Card Review Queue

`PARTIAL` means the visible card is drafted or the calculation exists, but its
canonical card-backed Pulse contract has not yet been accepted and encoded.

| Order | Insight card | Existing FastInfo relation | Proposed Pulse relation | Status | Next required decision |
| --- | --- | --- | --- | --- | --- |
| 1 | `koltesi_trend` - 30 napos trend | Existing rolling 30-day variable-spend metric. | `HF-013_SPEND_TREND_30D` | PARTIAL | Review the two-window Stage2 alternative, then encode one canonical metric and exact trigger zones in the gallery. |
| 2 | `mai_koltes` - Mai költés | Daily all-expense card plus variable daily ceiling. | `HF-003_DAILY_SAFE_SPEND` | NOT DONE | Separate displayed actual spend from safe-spend trigger evidence. |
| 3 | `heti_koltes` - Heti költés | Weekly spend, bars, and weekly pace. | `HF-004_WEEKLY_PACE` | NOT DONE | Align pace math to actual month length for Pulse. |
| 4 | `havi_koltes` - Havi költés | Month-to-date actual spend. | Evidence for `HF-001_MONTH_END_EXPENSE` | NOT DONE | Keep actual state distinct from the end-of-month forecast. |
| 5 | `megtakaritas` - Megtakarítás | Actual current-month savings and goal position. | `HF-010_SAVINGS_GOAL_FORECAST` | NOT DONE | Require the shared HF-001 forecast input. |
| 6 | `legutobbi_tranzakcio` - Utolsó tranzakció | Latest real transaction event. | `none` | NOT DONE | Confirm explicit no-trigger policy. |
| 7 | `varhato_ho_vegi_koltes` - Várható hó végi költés | Existing variable pace plus fixed/ghost forecast. | `HF-001_MONTH_END_EXPENSE` | NOT DONE | Make it the canonical month-end forecast card. |
| 8 | `leggyorsabban_fogyo_kategorialimit` - Kategórialimit állapot | Projected monthly category limit state. | `HF-002_MONTHLY_CATEGORY_LIMIT_BURN` | NOT DONE | Align visible zones and Pulse supersede behavior. |
| 9 | `leggyakoribb_kereskedo` - Leggyakoribb kereskedő | Merchant activity snapshot. | `none` | NOT DONE | Confirm explicit no-trigger policy. |
| 10 | `atlagos_napi_koltes` - Átlagos napi költés | Rolling average and spike history. | Input for `HF-011_BALANCE_BUFFER_DAYS` | NOT DONE | Keep average card distinct from balance-buffer card evidence. |
| 11 | `no_spend_napok_szama` - No-spend napok | Variable-spend-free day pattern. | `none` in accepted V1 | NOT DONE | Confirm no trigger or define a visible behavior card later. |
| 12 | `top_kategoria_heten` - Top kategóriák | Day/week/month ranking snapshot. | `none` | NOT DONE | Confirm explicit no-trigger policy. |
| 13 | `legnagyobb_novekedo_kategoria` - Legnagyobb kategóriaváltozás | Largest variable category delta. | `HF-012_TOP_CATEGORY_SPIKE` | PARTIAL | Review the fourth B3M-row Stage2 alternatives, then accept one canonical presentation with the `+10 000 Ft` / `+30%` materiality and recovery behavior. |
| 14 | `kovetkezo_ismetlo_kiadas` - Közelgő ismétlődő kiadások | Pending recurring load for the next seven days. | `HF-006_NEXT_7D_RECURRING` | NOT DONE | Define materiality and standalone/composed delivery. |
| 15 | `havi_fix_koltseg_osszesen` - Havi fix költségek | Activated and pending monthly fixed load. | `HF-005_FIXED_COST_LOAD` | NOT DONE | Define composition with budget and cashflow stories. |

## Retired Insight Decisions

| Former card / detector | Decision | Rationale | Status |
| --- | --- | --- | --- |
| `kiadas_bevetel_arany` / `HF-009_EXPENSE_INCOME_RATIO` | Excluded from the B3M insight plan; do not make it a Pulse candidate. | The static Balance header already owns the same expense/income and remaining-balance overview. A second gallery insight would repeat it without adding a distinct user action. | PARTIAL |
| `bevetel_ebben_a_honapban` / `HF-007_GHOST_INCOME_MISSING` | Exclude the generic monthly-income FastInfo card; retain its raw aggregates. | `currentMonthIncome`, expected income, and pending income ghosts remain inputs to `megtakaritas` and future forecasts. `MonthlyIncomeSummary` preserves the card-independent calculation for the future plan source. A specific late-income insight must be accepted before `HF-007` may pulse. | DONE |

## 30-Day Trend Review

### Canonical Card

| Field | Current accepted meaning |
| --- | --- |
| Card ID | `koltesi_trend` |
| Scope | Latest rolling 30 days versus the preceding rolling 30 days. |
| Included money | Variable expenses only. |
| Excluded money | Fixed, recurring, and scheduled expenses. |
| Inputs | `current`, `previous`. |
| Derived values | `deltaAmount = current - previous`; `deltaRatio = current / previous - 1`. |
| No baseline | When `previous <= 0`, show `Nincs összehasonlítás`; no Pulse trend trigger. |
| Stage1 | Compact direction and percentage: for the prototype, `+18%`, `fixek nélkül`. |
| Stage2 | Standard B3M: current amount, previous amount, fixed exclusion, and comparison-zone visual. Alternative B3M: two rolling-window values, absolute and relative delta, scope, and the relevant Pulse threshold. |

### Pulse Rule

| Rule | Condition | Result |
| --- | --- | --- |
| Worsening | `deltaRatio >= +15%` and `deltaAmount >= +10 000 Ft` | Candidate `HF-013`, `behavior_shift`, bad direction. |
| Improving | `deltaRatio <= -15%` and `deltaAmount <= -10 000 Ft` | Candidate `HF-013`, `behavior_shift`, good direction. |
| Noise / neutral | Either materiality condition is missing. | No Pulse message. |
| Composition | Budget or cashflow pressure is also active. | Trend explains that stronger visible story; it does not automatically become a second header message. |
| Recovery | A previously meaningful worsening condition resolves into the improving/neutral state. | May produce a recovery Pulse according to lifecycle rules. |

### Current Prototype State

| Item | Status | Detail |
| --- | --- | --- |
| Focused B3M cards | PARTIAL | `koltesi_trend` is rendered in the first lower editing row and `top_kategoria_heten` is removed from the primary row and rendered once in the new third B3M row. This remains active prototype editing, not visual approval. |
| Alternative Stage2 compositions | PARTIAL | The lower lane exposes six B3M siblings: rolling-window comparison, Pulse decision map, additive spend equation, rolling-window time tape, a Stage1-to-Stage2 daily filled-sparkline expansion, and B3M-F's two-period composition stripe. B3M-F uses the B3M-A delta container, all B3M secondary facts, a gray previous-period segment, and a current-period segment that turns green when lower or red when higher; visual acceptance is pending review. |
| FastInfo scope and facts | DONE | Gallery and resolver agree on rolling variable spend and fixed exclusion. |
| Prototype values | DONE | `191 200 Ft`, `162 000 Ft`, `+29 200 Ft`, `+18%`; these are prototype values, not live app data. |
| Pulse thresholds documented | DONE | The accepted HF-013 thresholds are recorded above. |
| Canonical metric object in gallery catalog | NOT DONE | The card has display fields only; it needs typed inputs and derived values. |
| Stage2 zone visual bound to exact `-15% / +15%` trigger thresholds | NOT DONE | It is currently a contextual visual, not the trigger source. |
| Flutter Pulse detector using the same metric | NOT DONE | No Pulse engine implementation exists yet. |

## Pulse Candidates Without a Settled Visible Owner

| Pulse candidate | Required disposition under the product rule |
| --- | --- |
| `HF-020_YEARLY_CATEGORY_LIMIT_BURN` | Create a visible yearly-limit Insight Card, or keep the detector disabled. |
| `HF-014_SCORE_DIRECTION` | Create a visible score-direction Insight Card on its owning surface, or keep the detector disabled. |
| `HF-021_UNCATEGORIZED_STATUS` | Create a visible data-quality status card, or keep the delayed detector disabled. |
| `HF-008_INCOME_GOAL_RISK` | Already deferred because it overlaps with `HF-010`; do not activate separately. |

## Engine-Only Rules

These remain allowed without an Insight Card because they do not describe an
additional financial fact: `HF-015_LIMIT_ZONE_SUPERSEDE`,
`HF-016_PULSE_PRIORITY`, `HF-017_PULSE_LIFECYCLE`,
`HF-018_HEADER_MORPH_PULSE`, and `HF-019_PULSE_ENGINE_PANEL`.

## Completion Rule Per Card

A card can become `DONE` only when all of the following are accepted and
recorded here and in the gallery catalog:

1. One visible Stage1 fact and non-redundant Stage2 evidence.
2. Exact scope, included and excluded money, inputs, formula, and no-data rule.
3. Explicit Pulse rule: thresholds, direction, materiality, composition, and
   recovery; or an explicit `pulse: none` decision.
4. Visual zones that match the rule rather than a separate illustrative scale.
5. A regression test that proves the visible card and Pulse candidate use the
   same typed calculation.

# SUM styles and Budget distribution delivery checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

This is the single completion checklist for the two user-approved feature
prompts. No application build or delivery claim is valid while any product
requirement below is not `DONE` (unless the user explicitly defers it).

## Mandatory references

- SUM-A source of truth: `/storage/emulated/0/spendee/source of truth/suma.png`
  (941 x 1672; inspected before implementation).
- SUM-B source of truth: `/storage/emulated/0/spendee/source of truth/sumb.png`
  (941 x 1672; inspected before implementation).
- Budget behavior source: user prompt received 2026-10-01, “FLUVI — BUDGET
  DAY HEADER + DISTRIBUTION CARD CLEANUP + RANKING SELECTOR”.
- Protected interaction floor:
  `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- Required journal and milestone policy:
  `MILESTONE_COMMITS.md`, `docs/FLUVI_ENGINEERING_JOURNAL.md`.

## Architecture card

| Concern | Single owner / write path | Consumers | Boundary proof |
| --- | --- | --- | --- |
| Persisted dashboard display choices | display-preferences controller and store | hamburger settings, Mind SUM/Year/Month/Day, Balance | controller/domain/store and presentation boundary tests |
| SUM visual variant | one `Current/SUM-A/SUM-B` preference resolver | Mind SUM renderer | source-of-truth screenshot and widget tests |
| Header geometry policy | shared temporal content-header primitive/spec | Mind SUM/Year/Month/Day | geometry tests across scopes |
| Balance child-shell switch | persisted display preference consumed by Balance composition | alternate balance content | widget tests for both shells without data/interaction ownership change |
| Budget daily allowance | pure budget scope/domain analysis from prepared exact money | Budget header presentation | unit tests using scaled integers and historical/current/future fixtures |
| Distribution ranking | Card2/dashboard-lifetime presentation owner, immutable entry projections | category and partner list headers/rows | controller/widget performance tests; no repository/query work on tap |
| Exact transaction counts | existing bounded prepared Budget acquisition and snapshot/bridge contract, if no exact authority exists | category/partner distribution projectors | native/codec/projector tests, same SQL acquisition count |
| Distribution geometry | one shared category/partner page-surface contract | Category and Partner Card2 | RenderBox parity tests |

UI only renders immutable view data and forwards intents. Persistence,
financial calculation, prepared acquisition and ranking state do not live in
leaf widgets. The existing carousel/PageView controller, ScrollPosition,
physics, Query and selected-target owners remain unchanged.

## SUM and dashboard settings

| ID | Requirement and source | Intended code area | Acceptance condition / verification | Status |
| --- | --- | --- | --- | --- |
| SUM-01 | Hamburger-menu setting: Current / SUM-A / SUM-B (previous prompt) | display preferences + existing header hamburger menu | persisted selection changes actual SUM renderer; controller/store/widget test | DONE |
| SUM-02 | Current preserves legacy SUM | Mind SUM resolver | no visual/semantic change under Current; regression test | DONE |
| SUM-03 | SUM-A matches `suma.png` | Mind SUM composition/tokens | geometry, typography, month cards, totals, slider/legend, chooser match reference; screenshot evidence | DONE |
| SUM-04 | SUM-B: SUM-A month cards; SUM-B mother-card tone and 3D year card with year/icon/annual total | Mind SUM composition/tokens | screenshots compared to `sumb.png`; no flattened year card | DONE |
| SUM-05 | SUM top-right layout chooser visibility | persisted display preference + SUM header | On/Off removes control and reclaims space; persistence/widget test | DONE |
| SUM-06 | Unified content-card header spec in SUM/Year/Month/Day | shared temporal header primitive/spec | same height, type hierarchy, baseline and vertical rhythm; cross-scope geometry test | DONE |
| SUM-07 | Year fits one page with no scroll after header expansion, including 4-column non-stretched layout | Mind Year viewport/layout solver | no overflow/scroll; reclaim empty gap above slider; widget layout test | DONE |
| SUM-08 | Year mother-card top-right actions visibility | persisted display preference + Year header | On/Off clean reflow/persistence/widget test | DONE |
| SUM-09 | Balance child-card shell toggle | persisted display preference + Balance alternate composition | On preserves existing shells; Off renders content directly and preserves behavior/padding; widget test | DONE |
| SUM-10 | Settings live in the existing hamburger menu | dashboard header visual tuner/settings host | all new controls are discoverable there; widget test | DONE |
| SUM-11 | No raster/source PNG rendered in production | Mind SUM rendering | code inspection and screenshot test use real Flutter widgets only | DONE |

## Budget DAY header

| ID | Requirement and source | Intended code area | Acceptance condition / verification | Status |
| --- | --- | --- | --- | --- |
| DAY-01 | Replace DAY-only “Napi tempó” daily average semantic | budget scope analysis + header presentation | primary metric is selected-day actual / daily available budget, not renamed old pace; unit test | DONE |
| DAY-02 | Dynamic day allowance formula | pure scaled-integer budget analysis | `max(0, round((monthlyLimit - spendBeforeSelectedDay)/remainingDaysInclusive))`; tests prove prior underspend/overspend carries forward | DONE |
| DAY-03 | Do not double count selected-day spending | same | denominator uses spend through prior day only; red/green fixture | DONE |
| DAY-04 | Truthful labels and unavailable future state | header presentation | current `Mai mozgástér`, historical `Napi mozgástér`, future explicit unavailable; formatter test | DONE |
| DAY-05 | Keep Month/Year/SUM headers and secondary projection consumers intact | presentation/controller | regression tests/code audit | DONE |
| DAY-06 | Exact HUF/scaled-money rules; no double arithmetic | domain analysis/formatter | no decimal HUF and existing rounding used; unit test | DONE |

## Budget Partner cleanup and shared geometry

| ID | Requirement and source | Intended code area | Acceptance condition / verification | Status |
| --- | --- | --- | --- | --- |
| DIST-01 | Remove Partner Spending Rhythm UI in SUM/Year/Month/Day | partner distribution card/layout | no renderer, footer, reserved lane, divider gap or placeholder; scope matrix widget test | DONE |
| DIST-02 | Preserve remaining Rhythm data consumers | rhythm ownership audit | only Partner Card2 presentation dependency removed; code/test evidence | DONE |
| DIST-03 | Partner pie equals Category pie geometry | shared distribution page surface | equal RenderBox left/top/width/height under identical Card2 constraints | DONE |
| DIST-04 | No partner-specific geometry magic numbers | shared geometry contract | Partner uses same surface calculation; code/boundary inspection | DONE |
| DIST-05 | One common title row | shared distribution page surface | left pie heading and right list heading/selector share body column split and same Y row | DONE |
| DIST-06 | No overflow across compact/normal, unified/split, SUM/Year/Month/Day | shared layout tests | all configurations mount without overflow and no blank Partner lower lane | DONE |

## Budget ranking and transaction-count data

| ID | Requirement and source | Intended code area | Acceptance condition / verification | Status |
| --- | --- | --- | --- | --- |
| RANK-01 | Small selector in Category and Partner list title | shared title-row + stable presentation owner | `Részesedés` default and `Tranzakciószám`, within title-row bounds; rebuild/rebase survival test | DONE |
| RANK-02 | Ranking switch is presentation-only and immediate | distribution ranking owner | no Query/filter/avatar/focus/LogBox/page/time mutation, debounce, async or controller replacement; counter/identity test | DONE |
| RANK-03 | Share behavior remains amount-descending and `%` | immutable list projection | exact amount desc then stable handle/id; rounded percent only as trailing metric | DONE |
| RANK-04 | Count behavior uses exact scope transaction count | prepared data/projector/list projection | category/partner aggregate and selected-category target work in SUM/YEAR/MONTH/DAY, including exact day | DONE |
| RANK-05 | Count tie-break and visual metric | shared trailing metric presentation | count desc, amount desc, stable id; trailing integer has no `%`; row visual parity test | DONE |
| RANK-06 | Pie remains monetary share under both ranking modes | visual bank/interaction mapping | slice values and stable slice/row identity unchanged on selector tap | DONE |
| COUNT-01 | Audit existing count authority before extension | prepared Budget graph | provenance documented; no fabricated UI count source | DONE |
| COUNT-02 | If absent, carry count in existing bounded acquisition | Kotlin snapshots/codec/bridge/Dart models/projectors | same grouped ledger scan includes `COUNT(*)`, no per-selector or extra acquisition | DONE |
| COUNT-03 | Count survives every snapshot boundary | native + binary codec + Dart prepared models | aggregate, category, partner, partner-in-category and Day round-trip tests | DONE |
| COUNT-04 | SQL-call count does not increase because ranking exists | native acquisition/performance test | exact before/after bound evidence | DONE |
| RANK-07 | Shared legend trailing metric has semantic type | `BudgetDistributionLegendRow` model/renderer | share percent vs transaction count cannot be confused in API; row tests | DONE |
| RANK-08 | Selector tap has zero acquisition work after resident revision | ranking owner/performance diagnostics | no repo/index/scene/SQL/query mutation; tests | DONE |

## Protected invariants and completion

| ID | Requirement and source | Intended code area | Acceptance condition / verification | Status |
| --- | --- | --- | --- | --- |
| SAFE-01 | Preserve `6e962…` physical interaction floor | all touched code | avatar/time/PageView controllers, positions and physics identities unchanged; protected tests | DONE |
| SAFE-02 | No Balance/Mind regression from Budget work; no unrelated surface mutation | all touched code | scope diff review + protected tests | DONE |
| TEST-01 | RED tests before each production behavior family | tests | DAY, DIST, RANK, COUNT old behavior shown failing before implementation | DONE |
| TEST-02 | Focused/local/protected test, format, analysis and diff gates | project tests | commands/results recorded honestly | DONE |
| VIS-01 | Visual verification for SUM-A/SUM-B and changed Budget cards | golden/screenshot evidence | reference inspection + production screenshots/RenderBox proofs | DONE |
| REL-01 | Commit discipline | git | `d40df643...` prepared-data contract followed by `c52f7a68...` presentation/settings; no unrelated dirty files included | DONE |
| REL-02 | Push, exact GitHub Actions audit and human APK download | CI/release | `c52f7a68...` pushed; Actions `36794717003` audited; normal human APK downloaded, SHA-256 and embedded identity verified | DONE |
| REL-03 | Separate factual journal update | engineering journal | `[skip ci]` journal-only commit after evidence, physical validation marked user-only | DONE |
| REL-04 | Final report | completion | preflight/provenance/formula/geometry/ranking/tests/CI/APK/final-state report supplied; inherited profile gate explicitly classified | DONE |

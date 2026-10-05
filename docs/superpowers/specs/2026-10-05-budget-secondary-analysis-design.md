# Budget Secondary Analysis — Accepted Design and Acceptance Checklist

## Sources and fixed scope

- User request: 2026-10-05, “FLUVI — BUDGET SECONDARY ANALYSIS CARD”.
- Visual source of truth: `/storage/emulated/0/spendee/source of truth/budgetall.png`, opened and inspected at its native 1312 × 1199 resolution.
- Existing implementation: `BudgetDistributionPager`,
  `DashboardBudgetDistributionDrawableController`,
  `DashboardBudgetPresentationController`, and the prepared
  `PreparedBudgetLimitSnapshot` runtime input.
- Related unfinished repair: FVP-08 in
  `docs/superpowers/plans/2026-10-05-fab-vector-presentations.md`.

The four reference panels are one Budget secondary-analysis card in the
existing content-card pager. They are not routes, sheets, modal views, or four
independent page systems. Its input identity is exactly:

`coreRevision + direction + selectedBudgetTarget + timeScope`.

The immutable analysis frame is produced before paint. Widgets render that
frame and forward the existing pager and avatar intents only.

## Budget Secondary Analysis architecture card

### Single source and write path

| Concern | Owner | Rule |
| --- | --- | --- |
| Time scope | Existing dashboard Summary/time navigation | Analysis reads its committed prepared scope; it owns no selector. |
| Selected Budget target | `DashboardBudgetPresentationController` plus `BudgetTargetAvatarRailController` | Analysis never writes target selection. |
| Ledger/limit facts | `PreparedBudgetLimitSnapshot` | No repository, database, query, file, or JSON access is permitted in analysis widgets. |
| Derived analysis | new pure `DashboardBudgetSecondaryAnalysisProjector` | Integer-safe formulas run only while a prepared drawable frame is built. |
| Drawable/cache publication | existing `DashboardBudgetDistributionDrawableController` | Extend its immutable frame/cache and existing hotset path; do not add a competing cache. |
| Swipe physics | existing `BudgetDistributionPageController` / `PageView` | Expand its modulo domain from two to three semantic pages while retaining its controller and position. |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Infinite pager, rebasing, physics, ScrollPosition | `BudgetDistributionPageController` | Extend from parity to modulo-three; no nested PageView. |
| Prepared revision data | `PreparedBudgetLimitSnapshot` | Reuse dense month/year/SUM cells; no new repository query or ledger scan. |
| Budget target semantics | `DashboardBudgetTarget` and presentation controller | Reuse target handles including aggregate handle `0`; no local category state. |
| Limit fallback | `DashboardBudgetResolvedMonthlyLimitResolver` / prepared snapshot | Use existing resolved limits; never invent denominators. |
| Health colors | existing Budget health/design tokens | Render semantic health from one token source; no copied feature palette. |
| Target hotset | existing avatar/Distribution prewarm mechanism | Include analysis subframes in the same bounded drawable publication. |
| Currency and time labels | existing project formatters | Do not introduce a second HUF or scope formatter. |

### Layer flow

`PreparedBudgetLimitSnapshot → pure secondary-analysis projector → immutable
secondary-analysis bank inside DashboardBudgetDistributionDrawableFrame →
BudgetSecondaryAnalysisCard → existing PageView`.

The presentation files have no concrete repository imports. The projector has
no Flutter widget dependency. The pager owns no business calculations.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FVP-08 | Previous interrupted FAB repair | global visual token + BNB FAB | Full vector resolves the photographed `#06B6D4`/`#DDF9FC` material through `FluviFabReferenceMaterial`, retains no shell/ring/core, and has an inspected golden. | Focused BNB color/widget/golden test. | DONE |
| BSA-01 | `budgetall.png`, §0 | design/checklist + visual tests | Reference remains the sole visual geometry source for SUM/YEAR/MONTH/DAY. | Reference and four 390×220 production-card golden screenshots opened and compared. | DONE |
| BSA-02 | §§1, 14, 26 | `budget_distribution_pager.dart` | Existing controller, ScrollPosition, PageView physics, idle rebasing and infinite bidirectional behavior survive while domain becomes Category → Partner → Analysis. | Pager widget tests verify forward/reverse cycle, semantic-modulo rebase and controller/position identity. | DONE |
| BSA-03 | §§2, 9, 11 | projector/frame/cache | Every visible title, hero and KPI set derives from one immutable revision/direction/target/scope frame; aggregate and category targets remain distinct. | Frame identity checks and two-target SUM/DAY unit test. | DONE |
| BSA-04 | §§10–13, 25 | drawable controller + core hotset | Widgets perform no aggregation or I/O; scope switches select prepared payloads and the bounded drawable frame cache retains target frames. | Cache-hit counter test; renderer accepts only immutable frame payloads. | DONE |
| BSA-05 | §4 | SUM payload + card | Valid closed months use equal-weight monthly utilization; zero-spend valid-limit months count, no-limit months do not; hero is one overspend-capable semicircle with delta/compliance/stability KPI row. | Unit test plus SUM golden. | DONE |
| BSA-06 | §5 | YEAR payload + card | Twelve month slots retain unavailable future months; `limit - actual < 0` paints red upward and positive reserve paints green downward from a centered zero axis; three required KPIs are correct. | Unit test plus YEAR zero-axis golden. | DONE |
| BSA-07 | §6 | MONTH payload + card | Hero contains exactly two side-by-side semicircles, integer-safe elapsed/used ratios, percentage-point pace insight and truthful current versus completed-period KPI labels. | 28/29/30/31-day unit test plus MONTH golden. | DONE |
| BSA-08 | §7 | DAY payload + card | Hero contains two Before → After blocks and arrow; the selected-day formulas, terminal-day safety, signed daily-room impact and truthful historical state are exact. | Unit test plus DAY golden. | DONE |
| BSA-09 | §§18–20 | projector + render states | Missing limit/data, zero spend, historical periods and future periods have distinct truthful presentations with no NaN, infinity or fabricated forecast/zero. | Focused unavailable/future/terminal unit tests. | DONE |
| BSA-10 | §§3, 16, 17, 20 | analysis card/painters | Each mode preserves the reference hierarchy, compact scope label, hero dominance, three equal KPI blocks, global typography, HUF formatting and restrained one-authority animation. | Renderer structure tests and inspected four golden screenshots. | DONE |
| BSA-11 | §§21, 23 | production Budget surface tests | Actual Budget surface mounts Analysis, cycles forward/backward through all three semantic pages without overflow, exception, reset or stale target. | Pager production-surface test mounts Analysis under the original PageView and checks same ScrollPosition. | DONE |
| BSA-12 | §§22, 24 | projector tests | Mandatory SUM/YEAR/MONTH/DAY formulas and two-target category isolation are deterministic and test-first. | Focused unit tests observed RED then GREEN. | DONE |
| BSA-13 | §25 | diagnostics/performance tests | Swipe, avatar fling and scope switch do not cause repository acquisition, query, prepared-index rebuild, full ledger scan, SVG parse, controller/position creation or synchronous frame-path aggregation. | Drawable cache hit test verifies no new analysis-frame build, zero native SQL and zero picture decode; pager identity tests cover controller/position reuse. | DONE |
| BSA-14 | §26 | regression suites | Existing Category/Partner pages, rankings, avatar physics, Header, other modes and bottom navigation retain behavior. | Focused Category/Partner pager, visual-bank and BNB regression tests. | DONE |
| BSA-15 | Delivery rules | branch/CI/APK | All checklist rows are DONE; app changes are committed, pushed to `3d-linechart`, exact GitHub Human Diagnostic APK succeeds, downloads to `/storage/emulated/0/Download/fluvi`, and SHA-256 is recorded. | Application SHA `829588c972a7064cf1c15048e9249958ea5a6d59`; Actions run `37300271099` passed Flutter, core and Human APK jobs; local `fluvi_HUMAN_DIAGNOSTIC_829588c.apk` SHA-256 `762bf9533a6689f0d8d6040e28a0d5ac42c0d365b5e3e41fdd3ebbfaf661d517`. | DONE |

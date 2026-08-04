# Acceptance checklist: open-rail parent transition

Baseline: `104c22f` (`feature/dashboard-open-rail-parent-transition`), based on
the preserved milestone `3dd650c225c24bc4382ceddd208ec35fae2a0e4f`.

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| ORP-01 | User prompt: open rail parent navigation | `DashboardCoreController` | SummaryPill month navigation uses one explicit open-rail parent transition | `dashboard_parent_navigation_performance_test.dart` | DONE |
| ORP-02 | User prompt: atomic ownership | time-navigation state + presentation store | Parent key, deck parent key, child ordinal, child key and epoch change coherently | controller transition tests | DONE |
| ORP-03 | User prompt: cached July → June | dashboard core/summary metrics | One pump shows target parent and retained/clamped target child | cached open-rail application test | DONE |
| ORP-04 | User prompt: atomic amount/count/LogBox | presentation store + summary metrics | Amount, count and content share target child query key and revision | visible-target/active-snapshot assertions | DONE |
| ORP-05 | User prompt: cached navigation has no fallback | current query + bundle path | No repository/native read controls visible cached navigation | repository counter assertions | DONE |
| ORP-06 | User prompt: retained child ordinal | time navigation controller | July 31 → June 30 and March 31 → February 28/29 | controller tests | DONE |
| ORP-07 | User prompt: latest wins | core transition guard | July → June → May leaves only May visible | sequential cached transition test + generation guard | DONE |
| ORP-08 | User prompt: stale callback rejection | rail widget/controller | Delayed settle after close or parent change mutates nothing | delayed settle tests | DONE |
| ORP-09 | User prompt: no live fallback for complete bundle | core + query controller | Cached target is published before any live query transition | event trace + cached counters | DONE |
| ORP-10 | User prompt: cold target consistency | core async transition | Old complete snapshot remains intact until one complete target publish | cold target async test | DONE |
| ORP-11 | User prompt: direction parity | query key and bundle validation | Income and expense have identical open-rail transition semantics | direction/query-key regression suite | DONE |
| ORP-12 | User prompt: seed gate | startup/prewarm paths | Pre-seed bundle requests/publications are blocked and revision-0 data is invalidated | explicit pre-seed preparation test | DONE |
| ORP-13 | User prompt: stable rail identity | time rail/controller | Rail State, ScrollController/Position and physics identity remain stable | existing rail identity suite + unchanged motion owner | DONE |
| ORP-14 | User prompt: required diagnostics | dashboard query diagnostics | Target parent bundle publication is logged with parent/deck/expected keys and acceptance | targeted event trace | DONE |
| ORP-15 | User prompt: no golden tests | test suite | No golden test is added or required | `rg` + targeted suite | DONE |
| ORP-16 | User instruction: one final build/push | git/CI handoff | Only after all checks pass: one final commit, push, online build, download | git/CI verification | NOT DONE |

# Combined Balance expansion implementation plan

> **Execution:** inline and test-first. The user approved the complete product
> contracts and explicitly requested one final build containing the whole
> bundle, so this plan is executed without an intermediate APK build.

**Goal:** add truthful Ghost/Forecast placeholder topics and Core-owned
Retention/Stability insights to the existing linked Balance carousel. Enrich
the existing Closings preview with its already-owned strict-positive fraction.

**Current source truth:** application base `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`
already has real Closings and Momentum, unlike the stale portions of the
incoming prompts. The final finite order is therefore:

`cashflow, closings, momentum, retention, stability, ghost, forecast, latestTransaction, topCategory, topPartner`.

## Architecture and no-touch boundaries

- `DashboardBalanceLinkedProjection` remains the only data owner. It creates
  immutable Retention and Stability DTOs once from its resident Income and
  Expense memberships; widgets never regroup or calculate financial data.
- Ghost and Forecast have no Core fields or data authority in this delivery.
  They are deterministic presentation-only topic/detail placeholders.
- `DashboardBalanceClosingsPresentation` remains the sole source of the
  strict-positive compact fraction. No parallel Break-even aggregation exists.
- The existing `CenteredCarousel`, controller, `ScrollPosition`, physics,
  one lower-card envelope, Query/repository/cache owners and dashboard
  geometry remain untouched.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BX-01 | Ghost/Forecast §§14–17 | Balance topic/domain and lower dispatch | Ten real topics include Ghost and Forecast; their compact/lower copy is truthful and contains no fabricated money, counts, rows, data authority or nested pager. | mounted surface/detail tests and copy assertions | DONE |
| BX-02 | Retention §§4,13–14 | immutable linked projection + renderer | Both-direction Retention has finite no-income/no-data states; SUM aggregate, YEAR siblings, continuous MONTH/DAY month siblings and selected identity are exact. | RED/GREEN pure and widget tests | DONE |
| BX-03 | Stability §§4,13–15 | immutable linked projection + renderer | Complete-month net sample, deterministic median/MAD-style deviation/band and 3-observation unavailable state are exact; distribution is not a line chart. | RED/GREEN pure and widget tests | DONE |
| BX-04 | Break-even §§1,13–14 | existing Closings compact card | Strict-positive `N / M` copy and dimensional wording read the exact immutable Closings bucket DTO; no new topic or aggregation. | DTO identity/copy tests | DONE |
| BX-05 | both prompts §§12,15,24–26 | existing surface/controller/Core hot path | One carousel/position/physics/lower shell remains; new selections are presentation-only and compact-safe. | controller/position, bounds, no-source-work tests | DONE |
| BX-06 | user delivery instruction | commits/CI/APK/SCIP/journal | One final app-code build after all five features, human APK, exact final-source SCIP and journal-only evidence commit. | Actions, hash, manifest and git checks | PARTIAL — application commit, one final remote build/APK, exact-source SCIP and journal evidence are pending. |

## Task sequence

1. **Audit/precondition:** preserve known untracked work; re-audit the
   matching pre-change graph and source consumers. Confirm Closings DTO exists
   before Break-even work.
2. **Retention RED → GREEN:** first introduce pure fixtures for formula,
   zero-state and sibling-domain contracts, then add a bounded immutable
   Balance-specific DTO/projection.
3. **Stability RED → GREEN:** test complete-month selection, deterministic
   doubled-minor median/MAD math and unavailable state before adding its pure
   DTO/projection.
4. **Single linked payload:** wire both DTOs into the existing linked
   projection and retain current presentation/cache identity semantics.
5. **Presentation domain RED → GREEN:** extend current topic mapping with
   Retention, Stability, Ghost and Forecast; reuse the existing lower dispatch
   shell and indicators; add the Closings compact fraction.
6. **Renderers/bounds:** add Balance-local Retention divergent bars, Stability
   distribution band and inert truthful future placeholders. Test compact and
   selected presentation states through the mounted production parent.
7. **Integration and delivery:** run protected/current suites, formatter,
   analyzer and diff checks; create one app-code commit, push it and only then
   run/monitor the one final remote human APK build. Regenerate SCIP for that
   exact app SHA, then append factual journal evidence in a separate
   `[skip ci]` journal-only commit.

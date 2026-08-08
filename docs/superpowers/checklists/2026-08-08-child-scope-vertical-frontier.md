# Child-scope vertical lazy-paging frontier acceptance checklist

## Architecture card

- **User requirement:** forward committed-vertical demand must follow the
  viewport's lower edge and must never stall at a drawable frontier merely
  because the first visible page remains ordinal zero.
- **Existing owners:** `DashboardLogBoxViewport` converts scroll metrics to a
  demand; `ExplicitCommittedPagingController` is the only cursor/I/O owner;
  `CommittedLogViewportCache` owns bounded drawable-page retention;
  `CommittedVerticalDemandPlanner` is the one pure O(1) policy shared by
  scroll-start and scroll-update.
- **Write path:** scroll notification -> pure demand plan -> cache's monotonic
  desired ordinal -> existing sequential paging controller -> atomic cache
  commit. The painter remains read-only.
- **Frozen boundaries:** rail motion, carousel/physics, prepared rail scenes,
  PreparedDashboardIndex, pinned page-zero, render-domain selection, and the
  human-vs-harness APK boundary are unchanged.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CSVF-01 | §§4–8, 10–13, 38 | viewport + pure planner | Scroll-start/update use one O(1) lower-edge planner, never `firstPage + constant` | planner unit tests + source inspection | DONE |
| CSVF-02 | §§2–5, 15–17 | planner | 94-row June geometry where first=0, last=2, ready=2 demands ordinal 3 | deterministic planner regression | DONE |
| CSVF-03 | §§7–8, 24–26 | cache retention | Visible pages plus the bounded two-page forward bank remain drawable without exceeding the existing five local-page budget | cache regression + viewport paint test | DONE |
| CSVF-04 | §§19–23 | planner/cache | Boundary counts and different page/group geometries reach their terminal page lazily; no full-list preload | deterministic planner/cache matrix | PARTIAL — device-level July/June/May capture remains pending |
| CSVF-05 | §§27–28, 36, 38 | frozen sources | No rail, physics, query ownership, root-page or render-domain source diff | `git diff` frozen-path audit | DONE |
| CSVF-06 | §§29–31 | diagnostics | Physical diagnostic summaries expose frontier inputs and can report a genuine frontier stall | focused diagnostics test + source inspection | DONE |
| CSVF-07 | §§32–34 | build product | Final APK is normal `lib/main.dart` HUMAN_DIAGNOSTIC, never integration-test harness | workflow/source check + Actions artifact | NOT DONE |
| CSVF-08 | §§36–37 | verification/delivery | Focused/full non-golden suite, analysis, remote human APK, SHA-256 and ZIP integrity are recorded | proot + Actions + artifact checks | PARTIAL — local 344/344 PASS and analysis clean; remote HUMAN APK pending |
| CSVF-09 | §35 | physical device | July/June/May sibling physical scroll reaches last row with no cache/stall miss | user capture report | BLOCKED |

## Local verification evidence

- The pure planner uses `lastVisibleOrdinal + 2`, constrained to the last
  possible ordinal, and additionally demands the next page at the drawable
  frontier when a cursor remains.
- The deterministic June regression has `first=0`, `last=2`,
  `highestReady=2`, `lastPossible=3`; it now demands page ordinal `3`.
- The page/viewport boundary matrix covers 24, 25, 48, 49, 72, 73, 94 and
  1000 rows with compact, reference-phone and tall viewport dimensions.
- The cache preserves the bounded forward-ready bank and reports a frontier
  stall only for a genuine no-demand invariant violation.

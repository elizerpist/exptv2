# b166 interaction-authority repair — acceptance checklist

Source of truth: user request **FLUVI — REPAIR INTERACTION AUTHORITY** dated
2026-09-03, physical source `b1662045c15c2940e263ff191ca6314c9fc2d72f`, and
the three latest b166 Drive captures.  This is an execution checklist, not a
device-pass claim.  `MILESTONE_COMMITS.md` is intentionally not modified.

| ID | Source / evidence | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| IA-01 | User §§4–5, 9–10; b166 `LIVE_ROOT_MISS` traces | Core live-interaction / visible-frame seam | Exact Phase-A semantic/list frames are accepted independently from rich-scene readiness; stale Phase-B cannot overwrite Phase-A | Core/visible-frame unit tests | DONE (automated) |
| AV-01 | Avatar log `AV|LIVE_ROOT_MISS` and `BUDGET_PROGRESS_IDENTITY_MISMATCH` | Budget focus coordinator + Avatar rail adapter | Every valid crossing updates avatar, exact rows/count and Budget identity before rich paint/settle | Production-parent rail test with unavailable/delayed/stale rich scene | DONE (automated) |
| AV-02 | User §6; accepted physical fling feel | Centered carousel / Avatar rail | No changes to velocity, friction, ballistic duration, tick spacing, snap or gesture thresholds | Existing centered-carousel and rail regressions + diff review | DONE (automated; physical feel pending user) |
| TIME-01 | Time log `SUMMARY_*_LIVE_ROOT_MISS`, settle rejection; user month jump | Segmented acceptance + Core temporal publication | User release target becomes Phase-A authoritative; selector, Query and list agree after settle | Production-parent month/reversal/interruption tests | DONE (automated) |
| TIME-02 | User §7.2 | Segmented selector controller adapter | Recenter never restores an old origin while the current Phase-A target is pending rich paint | Controller + production-parent regression | DONE (automated) |
| MIND-01 | Slider log `MIND|LIVE_ROOT_MISS` and `latestExactPreviewUnavailable` | Mind preview + Core visible-frame seam | Pointer-down updates count and exact rows repeatedly before pointer-up even if rich stager is absent/delayed | Production Dashboard/LogBox pointer-down tests | DONE (automated) |
| MIND-02 | User §§8.3–8.4 | Mind amount-domain / canonical reconciliation | Stable domain, mounted slider and preview remain through one final canonical commit; no rollback/loading/unmount | Delayed canonical and stale-generation tests | DONE (automated) |
| ID-01 | User §10 | Shared typed interaction identity | Avatar/list, month/query/list, direction and amount/list identities remain coherent; stale rich result is discarded | Identity and stale-completion tests | DONE (automated) |
| DIAG-01 | User §11 | Bounded logger / interaction summaries | Phase-A and rich outcomes are distinct; 1000-entry rolling tail is retained; no per-frame string spam | Logger and focused summary tests | DONE (automated) |
| DEBUG-01 | Explicit user addition | On-screen debug panel marker popup | Flag-marker dropdown has a light background and legible dark text; the requested marker categories are available | Debug-console widget test | DONE |
| VALID-01 | User §§15–18 and global AGENTS | Validation / delivery | Tests and analysis are honestly recorded; exact committed SHA is pushed and GitHub human APK is downloaded and hashed | Commands, GitHub run and local artifact | PARTIAL — commit/push/online human APK pending |

## Architecture / ownership card

- **Intent/rendering adapters:** `BudgetTargetAvatarRail`, segmented SummaryPill
  and `QueryAmountRangeControl` collect physical input only.
- **Shared authority:** `DashboardCoreController`,
  `DashboardLiveInteractionCoordinator`, `DashboardVisibleFrameStore` and the
  presentation controller own interaction generation, exact frames and stale
  rejection.
- **Phase A:** resident/prepared exact semantic/list data is publishable as the
  current visible authority without rich layout/scene/paint acknowledgement.
- **Phase B:** LogBox/chart/text-rich preparation is asynchronous, identity
  checked and latest-wins.  It may enhance but may not reject, roll back or
  choose the Phase-A target.
- **Protected implementation:** one centered-carousel engine, existing Query
  and prepared-index authority, Avatar fling physics, and the 1000-entry logger.

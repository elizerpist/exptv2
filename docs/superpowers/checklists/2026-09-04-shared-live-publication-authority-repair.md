# shared live-publication authority repair — acceptance checklist

Source of truth: user request **FLUVI — REPAIR SHARED LIVE-PUBLICATION
AUTHORITY, MIND CANONICAL APPLY, READABLE PHASE-A LOGBOX, AND ATOMIC
AVATAR/TIME DATA CONSISTENCY**, the physical 7cfc capture set, and source
verification at `7cfc75de2e9d387b661678459ae237aff44b4c11`. This checklist
does not claim a device result. `MILESTONE_COMMITS.md` remains unchanged.

| ID | Source / evidence | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SLA-01 | Fresh session `fluvi-1788482472212507`; Mind generation 63 then Avatar 2–34; `visibleFrameStoreRejected` | `DashboardVisibleFrameStore` + Core/Persistence seam | Cross-producer previews use typed producer identity plus globally ordered, store-issued intent/publication ownership; unrelated local counters are never compared as one clock | `dashboard_visible_frame_store_test.dart`; Core production-parent Mind → Avatar → Time test; foreign-store token rejection | DONE |
| SLA-02 | Same physical session; older Mind completion must not replace Avatar | Live interaction/Core reconciliation | Same-producer and older-global-owner stale completion rejection remains fail-closed | Delayed Mind completion, reverse order, and alternating-producer regressions | DONE |
| MIND-03 | Avatar-log seq 1388–1389 and 1921–1922 | Query candidate preparation/application | Optional candidate rich-scene retention failure cannot abort an exact canonical amount Query | Real protected-bank retention-failure regression through `prepareQueryDraft` and `applyQuery` | DONE |
| MIND-04 | Avatar-log seq 1682 `Prepared frame scope identity mismatch` | Binary codec/request construction | Exact identity tuple is logged and a deterministic physical-path reproducer proves and repairs only the faulty construction; incompatible identity remains rejected | Native canonical refinement-order codec regression and negative incompatible-scope test | DONE |
| MIND-05 | 7cfc Mind preview evidence | Mind preview/canonical bridge | Each live amount preview and final canonical Query preserve exact amount refinements, mounted control, latest-wins reconciliation, and one commit per completed drag | Production-parent held-pointer/repeated-drag/reentrant release tests | DONE |
| PHASEA-01 | Physical screenshot and fallback renderer source | Prepared scene cache + stable LogBox render surface | Every non-empty exact Phase-A frame shows prepared, readable transaction content instead of abstract gray bars; empty remains exact-empty | Resource and painter regressions across Time, Mind, Avatar, empty and populated reversal | DONE |
| PHASEA-02 | Hot-path invariants | Prepared resource/cache owner | Readable Phase-A uses bounded prebuilt row resources; paint creates no `TextPainter`, no repository/index/rich projection work occurs per tick | Painter counters, `readablePhaseARow` resource tests, source review | DONE |
| TIME-03 | Time log seq 296/300/301/379/380/594 | Summary acknowledgement/promotion seam | Preview → committed promotion retains acknowledgement identity for the already visible current target; old reports remain stale; no target jump or first-time settle content | Physical-order promotion regression with full-scope drawable acknowledgement | DONE |
| AV-03 | 31 Avatar rejections and `BUDGET_PROGRESS_IDENTITY_MISMATCH` | Budget focus publication + Avatar rail | Every accepted Avatar target atomically binds selected target, Budget header/distribution, count, focus and LogBox identity; one final canonical focus commit | Production Budget parent ballistic/settle/atomicity tests | DONE |
| PERF-03 | User: Summary fling now good | Existing time and carousel owners | No change to Summary/Avatar physics or tick cost; no Query/index/scene work per semantic tick | Protected motion tests, direct publication counters and source review | DONE |
| DIAG-02 | User §10 | Diagnostic logger | Add only bounded owner/order, scope-mismatch, readable-row, and promotion-ack events; retain rolling logger behavior | Bounded digest/sample source review and focused diagnostic assertions | DONE |
| VALID-02 | User §§12–16 and global delivery rules | Validation/delivery | Analyzer, focused and broader tests honestly recorded; app commit pushed; GitHub human APK built/downloaded/hashed; matching graph regenerated separately or truthfully stale | Exact commands, Actions run, artifact, tooling validation | PARTIAL — code validation complete; commit/push/APK/graph work remains |

## Architecture card

- **Input adapters:** `QueryAmountRangeControl`, `BudgetTargetAvatarRail`, and
  SummaryPill only collect user intent and preserve their existing physics.
- **Interaction authority:** `DashboardCoreController`,
  `DashboardLiveInteractionCoordinator`, `DashboardPresentationController`,
  and `DashboardVisibleFrameStore` own typed producer identity, ordered intent,
  exact visible frames, and stale-result rejection.
- **Phase A:** one exact, resident/prepared semantic/list frame. It includes
  readable immutable row layout resources and becomes authoritative without a
  rich scene/paint acknowledgement.
- **Phase B:** optional rich scene/cache augmentation. It is identity-checked,
  bounded, latest-wins, and never selects, rejects, rolls back, or overwrites
  Phase A.
- **Protected:** centered-carousel/Summary physics, Avatar physics, database
  and query authority, controller ownership, bounded cache policy, existing
  row/card visual language, and the rolling diagnostics tail.

## Validation ledger before delivery

- PASS — `flutter analyze` (Ubuntu proot): no issues.
- PASS — focused visible-store, Core, query application, renderer/cache,
  Mind, Avatar/Budget and Summary suites listed in the repair journal.
- PASS — `flutter test test/features/dashboard/application --reporter
  failures-only`: 274 tests.
- FAIL (inherited) — `flutter test test/features/dashboard/presentation
  --reporter failures-only`: 565 passed, 19 failures. The exact same
  normalized failure list occurs on the untouched `7cfc75de...` worktree
  (same SHA-256
  `a46adf030b93ff95af13343a9bea086f70626beab4d9d6d7dbb5ba1bb4ee3a38`).
  They are six core geometry goldens, one classic-header parity assertion,
  three Deep Drift source-contract errors, eight Space Fabric temporal
  golden/ticker errors, and the pre-existing stable LogBox surface test.

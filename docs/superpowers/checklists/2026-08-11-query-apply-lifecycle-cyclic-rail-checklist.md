# Query Apply Lifecycle and Cyclic Restricted Rail Checklist

Source: user report, 2026-08-11, against `query` at
`7a661eeb7e7a5adfe2e4c4ae5530f26aaf837916`.

| ID | Requirement / source | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QAL-01 | Same exact applied query is a no-op | `DashboardCoreController.applyQuery`, app shell | No native index build or scene prepare; initiating sheet closes next frame | controller + widget test | DONE |
| QAL-02 | Apply is bound to edit session, generation and canonical draft | `QueryComposerController`, `DashboardCoreController`, app shell | Draft edit, close, reopen, newer apply, direction change or dispose invalidate old Apply | race/controller tests | DONE |
| QAL-03 | Stale work is cancelled and cannot publish | scene-preparation coordinator and core controller | Old Apply never replaces index/query/navigation, rotates bank, completes composer or closes a newer sheet | controllable preparer test + diagnostics | DONE |
| QAL-04 | Publication waits only for required critical presentation | prepared revision bundle / scene-window coordination | Correct initial visible frame and immediate rail state are complete; noncritical warmup happens after publication and is cancellable | scene-window fake scheduler tests + duration diagnostics | DONE |
| QAL-05 | Result count does not determine Apply success | core query application | Zero-result query publishes and closes; nonzero scopes follow the same lifecycle | core + shell tests | DONE |
| QAL-06 | Presets keep their exact canonical temporal filter | Query composer/data controller | Aug 2026 last-3-months is June/July/August and cannot be overwritten by old Apply | deterministic preset + stale race test | DONE |
| QAL-07 | Restricted temporal domains cycle semantically | `DashboardSemanticCatalog` / time navigation | Multi-value restricted years/months/days map cyclically only through allowed values; a single value is bounded | catalog + navigation tests | DONE |
| QAL-08 | Unrestricted time navigation stays milestone-compatible | semantic catalog/time navigation | No Query/all-time retains existing finite/infinite mode behavior; no physics changes | existing + focused catalog tests | DONE |
| QAL-09 | Protected dashboard systems remain untouched | diff/architecture boundary | No rail physics, scroll ownership, paging, scene correctness bypass or visual Query changes | boundary/targeted tests + diff inspection | DONE |
| QAL-10 | Diagnostics distinguish no-op, cancellation, critical prep, publication and background warmup | core/application diagnostics | Canonical identities and cancellation reasons are emitted without frame spam | focused diagnostics test/code inspection | DONE |
| SCN-01 | Minimal publication scene bank remains renderable after any committed navigation | `DashboardCoreController` scene-window coordinator | New non-empty visible scope is covered or an exact demand rebase is requested before it renders | production-minimal-bank direction/plane renderability tests | DONE |
| SCN-02 | Direction and canonical Query identity participate in render coverage | scene-window payload/coverage identity | Same time coordinate with another direction/query cannot skip required rebase | minimal-bank income→expense regression | DONE |
| SCN-03 | Cancelling speculative full-bank warmup cannot disable demanded rebases | scene-window coordinator | Direction/plane demand rebase still prepares and activates after background cancellation | cancellable-preparer plus direction/plane rebase tests | DONE |
| SCN-04 | Minimal-bank navigation preserves performance architecture | revision bundle / background warmup | No restoration of publication-blocking full bank; rail/paging physics unchanged | code inspection + focused suite | DONE |

## Architecture card

- **Applied Query write path:** `DashboardCoreController` is the sole atomic
  publisher of prepared index, temporal availability, `CurrentQueryController`
  and composer completion.
- **Draft/session owner:** `QueryComposerController` owns discardable draft plus
  one monotonically increasing edit-session token; it never writes applied Query.
- **Apply/workflow owner:** `DashboardCoreController` owns one `QueryApplyIdentity`
  and cancels the existing scene-preparation capability when that identity loses
  authority.
- **Scene ownership:** the existing scene-window cache remains the only scene
  scheduler/cache. The core asks it for a minimal publication-critical window,
  then schedules the broader same-revision bank as existing cancellable maintenance.
- **Temporal mapping owner:** `DashboardSemanticCatalog` remains the only
  logical-index-to-semantic mapping; the existing `cyclic` data mode is selected
  for multi-value restricted domains instead of adding widget modulo arithmetic.
- **Evidence:** focused TDD RED/GREEN, controller/widget/scene/catalog tests,
  boundary suite, targeted analysis, fast suite, GitHub Action and normal human APK.

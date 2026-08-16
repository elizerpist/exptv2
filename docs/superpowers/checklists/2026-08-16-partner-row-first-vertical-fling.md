# Partner-row first vertical fling acceptance checklist

## Architecture card

- User requirement: preserve a one-move vertical fling beginning on an eligible
  partner row, without replacing the existing `Scrollable`, position, physics,
  partner-swipe arbitration, or prior committed-readiness work.
- Existing owners: `CustomScrollView` / Flutter `Scrollable` owns vertical
  drag and ballistic behavior; `DashboardLogBoxPartnerSwipeGestureRecognizer`
  owns only row-axis arbitration; `DashboardVerticalScrollController` observes
  framework handoff without modifying it.
- Source of truth / only write path: the framework vertical recognizer updates
  the one existing `ScrollPosition`; Listener samples remain diagnostic only.
- Reuse decision: extend the already-existing `CustomScrollView` drag-start
  contract. No second vertical recognizer, delta replay, velocity synthesizer,
  paging owner, or cache path is introduced.
- Layer flow: pointer UI -> framework gesture arena -> existing Scrollable /
  ScrollPosition -> existing viewport diagnostic observer. No repository,
  controller, cache, or query data path participates.
- Focused structural evidence: Flutter 3.41.4 (`ff37bef603`) documents and
  implements `start` as arena-win origin with zero pending update; `down`
  emits that pending update. The current partner recognizer resolves vertical
  on the first direction-bearing pointer move.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| GAF-01 | Single-move partner-row fling | viewport + widget test | One large vertical move followed by up advances the same ScrollPosition without a second gesture. | New real viewport widget RED/GREEN test. | DONE |
| GAF-02 | Framework-native ownership | existing `CustomScrollView` | Existing Flutter vertical recognizer retains pre-arena delta via `DragStartBehavior.down`; no event replay or second recognizer. | Pinned SDK inspection + widget test. | DONE |
| GAF-03 | Ballistic contract | observer + widget test | `goBallistic` receives framework output; application does not manufacture velocity. | Existing observer contract plus focused lifecycle test. | DONE |
| GAF-04 | Partner swipe regressions | partner recognizer tests | Intentional left swipe still acquires once; vertical, diagonal, rightward, tap, and cancel retain their existing outcomes. | Partner-swipe focused suite. | DONE |
| GAF-05 | Query / first-gesture regression | viewport + query tests | Fully drawable committed scope after Query publication accepts the first partner-row vertical gesture. | New focused viewport state test plus query suite. | DONE |
| GAF-06 | Protected readiness and geometry | paging/cache/viewport tests | No paging workaround, no read after pointer contact, no cache/virtual miss masking, and stable geometry/controller/position/physics identities. | Existing relevant suites and direct diff inspection. | DONE |
| GAF-07 | Diagnostics | existing bounded interaction diagnostics | Raw pointer and formal framework scroll evidence remain bounded; no per-move payload or synthetic input state. | Test/source inspection. | DONE |
| GAF-08 | Delivery | git/GitHub Actions | Exactly one production commit, one push, and one normal `lib/main.dart` human APK for the final SHA. | Git history, workflow, downloaded APK SHA-256. | NOT DONE |

## Inline execution plan

1. Add the real-widget single-move partner-row vertical gesture test before any
   production change and observe the failure on `464255c`.
2. Set the existing `CustomScrollView` to Flutter's supported down-origin drag
   behavior, then run the RED test and the partner-arena regressions.
3. Add only any missing focused regressions required to prove first-gesture,
   ballistic, and no-focus behavior; refactor only if tests reveal duplicated
   ownership.
4. Re-read this checklist, run the required suites/analyze/boundary verifier,
   then make one commit and obtain one online normal human APK.

# Fluvi reentrant live-interaction acceptance checklist

Date: 2026-08-31
Starting source: `b0b6828fbbd042d6fb2f6e1c85a74404b4c61a1c`
Physical status: FAIL — user-only Android evidence
Task status: implementation complete within automated scope; validation and
delivery in progress; no milestone authorized

This record supersedes only the A1/T1/M3 completion claims in the
2026-08-30 zero-lag checklist. It does not rewrite the historical milestone.

| ID | Requirement source | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PRE-01 | User §5–6 | Git history, three fresh Drive docs | Local/remote identity and exact fresh sessions/revisions are recorded; copied sessions are not conflated | Pre-flight transcript and log audit | DONE |
| AV-01 | User §4.1, §9.1, §11 | `BudgetTargetAvatarRail`, core Avatar hotset/readiness | Background live-root preparation never disables the rail hit-test; readiness is checked at semantic publication, not pointer admission | Production-parent widget test: second and twentieth next-frame gesture accepted | DONE — the rail no longer has a readiness-owned `IgnorePointer`; 20 sequential production-parent drags are accepted while readiness is false |
| AV-02 | User §11 | Avatar motion state/diagnostics | Every direct/ballistic/cancel/supersede terminal path releases its own generation idempotently; stale release cannot affect a newer gesture | Lifecycle unit/widget matrix | DONE — the Avatar owns no second lease; the shared centered-controller terminal/interruption suite plus repeated production-parent gestures passes |
| AV-03 | User §3, §14 | Budget focus coordinator, visible-frame store | Every accepted Avatar tick retains complete exact focus/LogBox/Budget publication; no visual-only or settle-only regression | Existing live-paint regression plus repeated-interaction assertions | DONE — complete prepared focus/LogBox publication tests remain green; only pointer admission changed |
| TM-01 | User §4.2, §10 | `_HierarchyValueSelectorState` | A 2025→2024→2025 gesture emits both crossings; returning to the origin is not suppressed | One-frame widget test without `pumpAndSettle` | DONE — both crossings are emitted before release and the next gesture is accepted one frame later |
| TM-02 | User §10 | Segmented gesture state | Latest desired/live/published/settle target is 2025 after reversal; release causes zero first visible change | Widget + controller test with exact empty 2024 and populated 2025 | DONE — production `DashboardLogBoxViewport` paints populated→exact-empty→populated before settle; settle retains 2025 |
| TM-03 | User §4.3, §12 | Segmented input lifecycle and core live publication | Next gesture is accepted on the next frame; scene warming/canonical promotion never gates recognition | Terminal/cancel/supersede re-entry tests | DONE — next-frame widget regression and shared controller interruption/identity suite pass without a timer |
| TM-04 | User §3, §15 | Segmented prepared temporal path | A prepared hit remains repository/native/index/scene/text-layout free and atomically updates Summary/Budget/LogBox | Existing production-parent live-paint tests and counters | DONE — complete finite hotset production test paints both empty and populated roots with no foreground preparation |
| MIND-01 | User §4.4, §9.4, §13 | `QueryAmountRangeControl` | Twenty next-frame drags reach start/change/end with stable element/state and no loading/unmount | Production-parent repeated-drag widget test | DONE — one Element handles 20 consecutive start/change/end cycles; release flushes only a pending preview |
| MIND-02 | User §13 | Mind preview + prepared scene cache | Non-empty live ranges stage a drawable production LogBox root from reusable row resources; exact empty ranges are explicitly empty, not misses | Real `DashboardLogBoxViewport` one-frame paint test | DONE — non-empty rows paint, exact-empty is deliberate, and populated rows repaint before release |
| MIND-03 | User §13 | Mind release reconciliation/query apply | Drag makes no repository/native/index request; release commits once; live list remains visible while canonical work completes and next drag is not blocked | Operation counters + delayed completion test | DONE — canonical borrowing shares the bounded live bank; stale release is rejected by Mind interaction generation and cannot clear the newer preview |
| ATOM-01 | User §14, §19.5 | Typed live interaction identity / visible frame | Summary/count/LogBox/Budget/partition/distribution/rhythm share one live identity; `mixedProjectionCount=0` | Deterministic identity assertions with diagnostic mismatch output | DONE — existing visible-frame identity barrier remains authoritative; affected identity and `mixedProjectionCount=0` regressions pass |
| PERF-01 | User §20 | All three hot paths | Per tick/update: repository/native/index/foreground-scene/text-layout work is zero; cooldown frames zero; settle visual delta zero | Counter-based deterministic tests | DONE — prepared-path and production-paint tests assert zero hot-path repository/index/scene work and no release-only first paint |
| REG-01 | User §17 | Shared carousel, Classic SummaryPill, diagnostics | Physics/controller/ScrollPosition, Classic immediate behavior, rolling 1000-log console and unrelated gray/budget diagnostics remain unchanged | Existing focused suites + diff review | DONE — protected 142-test suite passes and the unrelated owners are untouched; the broad Dashboard command is still not globally green because of 23 documented inherited/parallel-only failures |
| VAL-01 | User §22–24 | Changed sources/tests | Format, analyze, focused tests, affected dashboard regression and exact committed-source validation are honestly recorded | Exact command output | NOT DONE |
| BUILD-01 | User §24–25 + AGENTS.md | GitHub Actions | Pushed exact SHA produces profile HUMAN_DIAGNOSTIC APK; downloaded file and SHA-256 recorded | GitHub run + local artifact hash | NOT DONE |

## Evidence decisions

### D01 — Segmented reverse crossing

Question: Why can 2025 fail to republish after a same-pointer 2024 reversal?

Evidence inspected:
- Fresh `Fluvi logs time fling` b0b session, seq 14103–14215.
- `_HierarchyValueSelectorState.onSelectedChanged` returns when `offset == 0`.
- `_latestCandidate` therefore remains the prior 2024 candidate and owns settle.

Conclusion: Confirmed root cause.

Decision: Replace origin-only suppression with explicit per-gesture current live
target ownership; origin return is emitted when it differs from the current
live target.

### D02 — Avatar post-first-interaction lockout

Question: Which owner can suppress every later horizontal pointer?

Evidence inspected:
- Fresh `Fluvi logs avatar fling`: current b0b session seq 3543–4542; two
  `avatar_fling` marks but no Avatar pointer/motion events in the retained
  late interval.
- `BudgetTargetAvatarRail` wraps the complete carousel in
  `IgnorePointer(ignoring: !liveTargetReadiness)`.
- `_primeRequestedBudgetAvatarFocusHotset` and
  `_primeBudgetAvatarLiveRowResources` set that readiness false during
  background re-arming after semantic state changes.

Conclusion: Source-level causal gate identified; terminal lifecycle still
needs a red production-parent test to distinguish it from any recognizer bug.

Decision: Pointer admission must not be owned by background hotset readiness.
Keep exact readiness as a publication invariant and make misses explicit.

### D03 — Mind live range renderability

Question: Why can preview membership publish without visible rows?

Evidence inspected:
- Fresh `Fluvi logs slider`, current b0b session seq 2070–3069.
- 69 preview frames; most active-resource hits/visible extents had zero rows.
- The retained live-resource bank is exact row/layout ownership, while the
  arbitrary range window is staged synchronously by immutable row identity.
- Release candidate preparation repeatedly failed retention after 370–457 ms
  with 2295 retained rows versus the two-bank 2048 row bound.

Conclusion: Live membership and release publication are distinct. Row
renderability/reconciliation is not proven correct by lane publication.

Decision: Add a real production-viewport red test, repair resource selection
at the prepared-scene owner, and preserve the live preview across canonical
release work. Do not use fake rows or a second list renderer.

### D04 — Architecture ownership

Question: Should any feature receive a second gesture, query, or cache engine?

Evidence inspected:
- Existing centered carousel, `DashboardLiveInteractionCoordinator`,
  `DashboardVisibleFrameStore`, prepared-index and prepared-scene owners.

Conclusion: Reuse/extend existing shared owners.

Decision: UI remains intent collection/rendering; lifecycle tokens live with
the interaction owner and row resources remain in the prepared scene cache.

### D05 — Avatar terminal ownership

Question: Did an Avatar-specific gesture lease fail to release after settle?

Evidence inspected:
- The fresh trace contains no second-gesture Avatar callback at all.
- The production rail had no separate lease state; the shared centered
  controller already owns direct/ballistic/cancel/supersede termination.
- The whole rail was hit-test-disabled solely by `liveTargetReadiness=false`.

Conclusion: The stuck owner was the background-readiness `IgnorePointer`, not
an unreleased recognizer or ballistic token.

Decision: Remove readiness from pointer admission, keep the shared controller
lifecycle, and record accepted pointers with readiness/controller identities.

### D06 — Segmented settle ownership

Question: Which value incorrectly owned release after a reverse crossing?

Evidence inspected:
- `offset == 0` suppressed the return-to-origin semantic event.
- `_latestCandidate` therefore remained the outbound 2024 target.

Conclusion: The stale last outbound candidate incorrectly owned settlement.

Decision: Current semantic target, last emitted target, and settle target move
together on every real boundary crossing in either direction.

### D07 — Prepared temporal reversal

Question: Is reverse publication itself incoherent once both roots are armed?

Evidence inspected:
- A first production-parent test armed only the origin root; 2024 entered the
  foreground fallback and raced the reverse publication.
- The complete finite 2024/2025 hotset publishes exact-empty 2024 and paints
  populated 2025 in one controlled frame before settle.

Conclusion: Core reversal is coherent on the prepared path; an incomplete
interaction hotset is a readiness miss, not evidence that return-to-origin is
semantically stale.

Decision: Preserve the zero-work prepared path and test reversal with the
complete reachable hotset. The widget fix restores the missing reverse tick.

### D08 — Mind canonical release retention

Question: Why did the delayed canonical result fail after a drawable drag?

Evidence inspected:
- The exact live resource bank retained 2,295 rows under its independent
  8,192-row bound.
- A second canonical bank borrowing the same immutable row layouts was rejected
  against the generic two-bank 2,048-row cap even though it added zero unique
  row resources.

Conclusion: Bank count was conflated with unique retained resource growth.

Decision: Use the already-admitted live bank as the candidate-bound baseline;
shared borrowing is accepted, genuinely new unique resources beyond the
baseline remain rejected and tested.

### D09 — Mind stale completion ownership

Question: Can an older release completion overwrite a newer drag?

Evidence inspected:
- Query apply latest-wins used Query/composer identity but not the Mind
  interaction generation.
- A delayed completion can therefore remain logically current after the next
  slider interaction begins.

Conclusion: Canonical promotion lacked interaction-generation ownership.

Decision: Capture the release interaction generation, include it in in-flight
dedup/cancellation and every publication-currentness check, and retain the
exact live preview when a stale/rejected promotion returns false.

### D10 — Slider callback readiness

Question: Why could release duplicate preview work or delay the next gesture?

Evidence inspected:
- `onChangeEnd` always called the preview callback, even when the same value had
  already published in the prior frame.
- Slider local state otherwise had no cooldown or busy gate.

Conclusion: There was no timer-based input lock; the avoidable duplicate
release preview added work to the terminal edge.

Decision: Flush only an actually pending same-frame value. Canonical commit
still occurs once and remains independent of the next `onChangeStart`.

## Validation record (pre-commit)

- Initial red command: three focused regressions failed for the expected
  reasons: Avatar `IgnorePointer`, missing origin-return tick, and canonical
  borrowing rejected by the candidate-row cap.
- Affected six-file command: **149 tests passed**.
- Protected carousel/time/Budget/visible-frame command: **142 tests passed**.
- Full `flutter analyze`: **No issues found** in 123.3 seconds.
- Full `test/features/dashboard`: **1,074 passed, 23 failed**. This command is
  not labelled PASS. The unchanged LogBox line-87 failure reproduces at the
  starting SHA `b0b6828f`; the four paging failures pass **25/25** when run
  independently and are broad-run interference. The remaining Header/golden
  failures are the already recorded inherited baseline set; no goldens were
  updated.

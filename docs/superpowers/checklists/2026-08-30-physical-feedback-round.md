# Fluvi physical-feedback round acceptance checklist

This record supersedes the pre-build status in
`2026-08-30-performance-milestone-final-two-blockers.md` for this agent pass.
The newer user device evidence reopens Avatar cadence, time cadence, the random
settled Rhythm slab, and the Mind interaction lifecycle. It does not rewrite or
promote the historical milestone in `MILESTONE_COMMITS.md`.

Authoritative inputs:

- user prompt `FLUVI — PHYSICAL FEEDBACK ROUND` (2026-08-30);
- Google Docs `Fluvi logs`, `Fluvi logs 2`, and `Fluvi logs 3`;
- `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260830-103859.png`;
- current local `separated-core-modes` worktree at pre-flight SHA
  `0810f0ca61f429c23f2cd6486f053e3970092ea4`.

Status meanings are `DONE`, `PARTIAL`, `BLOCKED`, and `NOT DONE`. Device
validation is a post-build user-only activity. It is deliberately not used as
an agent-side pre-build PASS condition; the strongest handoff is
`TEST-CLEAN / DEVICE-PENDING`.

| ID | Source requirement | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| R1 | Exact rolling 1000-entry live diagnostics | `fluvi_diagnostic_logger.dart`, `debug_console.dart` | Newest 1000 retained forever; FIFO, monotonic session count/sequence, virtualized live projection, bounded refresh | unit + widget tests, source inspection | DONE |
| R2 | Follow/review UX | debug console | At-bottom follows; manual review is not pulled; unseen count and jump-to-live work | widget tests | DONE |
| R3 | Quick bug marker and bounded copy/capture | logger + console | Marker captures compact context; live/frozen copy is ordered and explicitly latest-1000 | unit + widget tests | DONE |
| R4 | Low-noise diagnostics | Header/rail/Mind/Rhythm instrumentation | Stable config logs are change/bucket/summary driven; no whole-buffer formatting while closed | counter tests + source audit | DONE |
| M1 | Stable amount-domain identity | Query amount-domain binding/loader/current query | Amount-only edits do not invalidate the same non-amount domain; non-amount changes do | unit/controller tests | DONE |
| M2 | Stable Mind control during warm edit | Mind surface + range control | No unmount/loading replacement/reset after a valid domain exists | widget/controller tests | DONE |
| M3 | Live transient Mind preview | shared prepared index/focus/presentation path | Thumb and visible rows/count follow the newest frame-coalesced preview while pointer remains down; no repository/full-index work per raw update | operation-count + widget/integration tests | DONE |
| M4 | One canonical commit | Query application | One final exact commit per completed changed gesture; no commit for no-op/cancel; preview reconciles without rollback | interaction tests | DONE |
| A1 | Avatar hot-path cause | Avatar rail/coordinator/core focus | Full focus/index/publication storm is removed from transient crossings while visual preview and final semantic target remain correct | 1/8-crossing/reverse tests + counters | DONE |
| A2 | Avatar flight evidence | bounded flight recorder | One summary reports raw/tick cadence and expensive-work counts without per-frame string logging | unit/widget tests | DONE |
| T1 | Time hot-path cause | Summary/time selector and prepared temporal navigation | Cache/scene misses cannot synchronously turn a visual transient crossing into a heavy navigation transaction; settle commits latest target | multi-crossing/reverse/interruption tests + counters | DONE |
| T2 | Time flight evidence | bounded flight recorder | Independent summary reports cadence/work counts | unit/widget tests | DONE |
| G1 | Random gray Rhythm slab forensics | Rhythm slot/card/scene lifecycle | Exact current owner is fixed only if proven; otherwise durable low-frequency owner/state diagnostics and marker snapshot are present without a cosmetic patch | source audit + widget/state tests | DONE |
| G2 | Preserve collapse repair | full Budget composition | Existing intermediate-collapse regression remains green | targeted regression | DONE |
| B1 | Budget/limit audit | Query/index/Budget lifecycle | Three logs are deduplicated and anomalies classified; no behavior change without causal proof | forensic record + targeted invariant tests if justified | DONE |
| P1 | Protected Header/category behavior | Header palette/render engine | Existing dynamic category colors, ticker/backend identity, and palette behavior unchanged | existing regression tests | DONE |
| V1 | Static and targeted validation | all affected paths | Diff clean; affected analyze/tests green; any inherited suite failure reproduced at starting SHA and reported | exact commands/results | NOT DONE |
| V2 | Evidence-backed commits | Git history | Only coherent, tested changes committed; required commit-body evidence and `PENDING — USER ONLY` present | `git show`, status | NOT DONE |
| V3 | One exact-SHA Android artifact | GitHub Actions | Build only after R1–V2 agent-authority gates are DONE; exact committed SHA pushed once, human APK downloaded and SHA-256 verified | Actions run + local hash | NOT DONE |

Post-build user-only matrix (not an agent PASS claim): log live/review/marker/copy,
Mind cold/warm/live drag, independent Avatar and time fling stress, gray-state
mixed-interaction reproduction, collapse regression, and budget/limit stress.

## Forensic intake status

- `Fluvi logs`: read; four apparent retained windows, including the proven
  time and Avatar workload intervals. No event sequence identity is available,
  so identical copied/runtime lines cannot always be distinguished.
- `Fluvi logs 2`: read; seq 14971–15138 is duplicated as a copied block and
  deduplicated by sequence. It lacks a chart-layer owner lifecycle.
- `Fluvi logs 3`: read; seq 16065–16781 is continuous and proves nine
  Query/index/domain-unmount/remount cycles during amount adjustment.
- screenshot: inspected at original resolution; the slab is a sharp-edged
  approximately sRGB `(196,196,196)` region below a valid donut, but source and
  current logs do not yet prove its painter.

## Engineering journal

### [STEP 01] Mind amount-domain invalidation

- Question: why did an amount adjustment repeatedly unmount the ready slider?
- Evidence: `Fluvi logs 3` seq 16065–16781 showed the applied Query entering
  loading and republishing the same 50,000–26,000,000 domain after every
  amount-only change; CURRENT HEAD keyed the canonical domain by the complete
  amount-refined scope.
- Conclusion: the control's own refinement recursively invalidated its source
  domain.
- Decision: key and request the domain by the exact Query with only the two
  amount refinements removed, while retaining every independent filter.
- Validation: domain/controller/loader tests pass; amount-only changes perform
  no refetch/loading transition and non-amount changes still invalidate.
- Status: confirmed.

### [STEP 02] Mind live list preview

- Question: can the list follow the thumb without a repository/index apply per
  pointer sample?
- Evidence: the prepared directional index already retains immutable ledger
  membership rows; no amount-sorted membership projection existed.
- Conclusion: a compact amount-sorted ordinal index can derive an exact preview
  over resident rows without mutating the committed Query or navigation.
- Decision: add binary-bound amount membership, frame-coalesce raw slider
  updates, and publish amount/count/LogBox presentation lanes together. Keep
  the full Query apply as the one release commit.
- Validation: 64 focused tests pass; the Core operation-count test asserts one
  resident preview row, unchanged committed navigation/Query, zero additional
  repository calls, and zero index builds during drag.
- Status: confirmed; physical perception remains user-only pending.

### [STEP 03] Avatar transient publication storm

- Question: which Avatar work is required at each crossed target and which
  work can wait for the selected target to settle?
- Evidence: the device log recorded 22 target changes/index publications and
  19 focus publication cycles in one short flight; CURRENT HEAD routed every
  `onTargetPreview` through the complete ephemeral-focus install path.
- Conclusion: a discrete crossing was being treated as a mini canonical focus
  transaction even though the retained rail presentation can bind its target,
  Header palette, progress, and prepared consumers without replacing the
  canonical focus/index.
- Decision: publish the prepared visual target during crossings and perform
  exactly one canonical focus/index/LogBox transaction for the latest settled
  target. Keep carousel physics, velocity, crossing count, controller, and
  `ScrollPosition` unchanged.
- Validation: the 8-crossing controller test records zero focus/index/visible
  frame/repository work before settle and exactly one final focus publication;
  the complete affected rail group passes 114 tests.
- Status: confirmed by source and automated counters; physical cadence remains
  user-only pending.

### [STEP 04] Time component crossing transaction storm

- Question: why did a year/month/day carousel crossing start scene rebase,
  cache/text-layout, Query, and presentation work before the flight settled?
- Evidence: the time log showed 10–15 navigation transactions and 13 critical
  cache/text-layout misses in sub-second flights; CURRENT HEAD called the full
  temporal navigation path from every `onSelectedChanged` callback.
- Conclusion: the visual selector tick and canonical temporal transaction had
  the same callback owner.
- Decision: keep crossed candidates local to the stable carousel, emit the
  latest candidate once on idle, and run the existing canonical temporal
  transaction exactly once. Reuse the common typed raw-motion recorder and a
  bounded shared semantic-cadence accumulator for settle summaries.
- Validation: the multi-crossing test observes unchanged navigation, visible
  frame, repository calls, scene starts, and Query applies throughout eight
  crossings, followed by one exact latest-target commit. Shared cadence tests
  prove bounded retention, percentiles, long gaps, duplicates, and skips.
- Status: confirmed by source and automated counters; physical cadence remains
  user-only pending.

### [STEP 05] Random settled Rhythm slab ownership

- Question: which current child paints the screenshot's uniform `(196,196,196)`
  lower-card slab after mixed interaction?
- Evidence: the screenshot proves the slab while the upper Partner donut stays
  valid, but `Fluvi logs 2` has no chart-owner lifecycle. CURRENT source gives
  the donut and Rhythm separate data/layout owners; the null-Rhythm branch is
  transparent and the real chart has transparent zero tracks. No production
  or diagnostic source literal matching the screenshot fill was found.
- Conclusion: the exact painter is not proven. The strongest source-level lead
  is a separately invalidated Rhythm slot below an independently ready donut,
  but recoloring or masking that slot would be speculative.
- Decision: preserve the visual hierarchy and add a diagnostic-only,
  state-change-driven Rhythm observer. It reports semantic state, actual
  renderer, query/revision/generation identity, bounds, paint bounds, clip,
  background, opacity, and z-order without adding paint. An explicit
  `gray_rectangle` user marker samples the then-current geometry from every
  mounted retained page so the visible owner can be identified after random
  reproduction.
- Validation: logger and Partner-card tests prove ready/unavailable owner
  transitions, no unchanged-frame event flood, exact marker context, and
  provider disposal. The visual defect remains unresolved pending the next
  user capture; no cosmetic behavior change was made.
- Status: owner unresolved; durable forensic gate confirmed.

### [STEP 06] Budget/index anomaly classification

- Question: do the retained errors prove the disappearing-limit defect or a
  causal link to the gray Rhythm slab?
- Evidence: two logs contain `Prepared index has no catalog` during incoming
  scene preparation. CURRENT `installPreparedIndex` catches that failure before
  `_publishIndex`, returns false, and retains the prior complete publication.
  CURRENT regression coverage prevents a new revision from requesting the
  retired ephemeral-focus catalog. `LIVE_FACET_SCENE_AUGMENT_FAILED` occurs
  after the prepared frame is already authoritative. Stale Query/page rejects
  carry explicit latest-wins generation guards. The observed allocation ratio
  `2.471` is supported over-allocation semantics: raw ratio stays truthful while
  visual coverage deliberately clamps to `1.0`.
- Conclusion: the no-catalog event is a real scene-preparation invariant
  failure/performance concern in the tested older runtime, but the supplied
  evidence does not show it clearing a limit, publishing an invalid budget, or
  painting the slab. The cancellation/rejection events are not independently
  harmful without a mismatched accepted publication.
- Decision: make no Budget math, persistence, or last-known-value change. Keep
  the existing generation/availability diagnostics and verify the current
  no-retired-catalog and over-allocation invariants.
- Validation: current targeted regression commands are recorded in the final
  verification section; physical non-reproduction is not called a fix.
- Status: audit complete; Budget disappearance remains not reproduced and not
  root-caused.

### [STEP 07] Broad-suite failure classification

- Question: did the task introduce the 21 failures reported by the broad
  1,182-test dashboard/performance/regression command?
- Evidence: the unchanged LogBox and scroll-milestone tests fail on both the
  task head and detached starting SHA `0810f0ca` because an unscoped
  `find.byType(Scrollable)` matches multiple elements. The three Deep Drift
  source-parser failures, classic catalog `14` versus `18` expectation,
  Space Fabric threshold/ticker-cleanup failures, and all six geometry-golden
  differences also reproduce on that exact detached starting SHA.
- Conclusion: those 20 failures are inherited baseline failures under the
  current Flutter/test environment. One failure was task-related: the scene
  rotation test still asserted the superseded per-crossing temporal commit.
- Decision: do not update goldens or unrelated baseline tests. Strengthen the
  temporal test to assert no navigation/scene transaction at crossing and one
  exact retained-hotset publication at settle.
- Validation: detached starting-SHA commands reproduce every classified
  baseline failure; the strengthened temporal contract test passes on the task
  head. The full affected scene test remains part of final validation.
- Status: confirmed.

### [STEP 08] Protected visual and collapse boundaries

- Question: did the Mind/rail/forensic work alter the accepted category Header
  renderer or regress the prior collapse-slab repair?
- Evidence: no Header/palette/shader production file changed from the starting
  SHA. Six focused Header fragment-backend, palette-transport, renderer,
  static-color, visual-engine, and tuner files pass 102 tests. The full
  production G4 collapse proxy drives real Partner Rhythm through dense
  intermediate states and passes.
- Conclusion: the protected Header identity/palette contract and the previous
  collapse-path repair remain intact under automated coverage.
- Decision: mark G2 and P1 complete without changing Header or collapse code.
- Validation: 102 protected Header tests pass; the exact G4 full-composition
  proxy passes.
- Status: confirmed; random settled slab ownership remains user-capture
  dependent and is not called fixed.

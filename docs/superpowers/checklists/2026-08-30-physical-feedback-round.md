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
| G1 | Random gray Rhythm slab forensics | Rhythm slot/card/scene lifecycle | Exact current owner is fixed only if proven; otherwise durable low-frequency owner/state diagnostics and marker snapshot are present without a cosmetic patch | source audit + widget/state tests | NOT DONE |
| G2 | Preserve collapse repair | full Budget composition | Existing intermediate-collapse regression remains green | targeted regression | NOT DONE |
| B1 | Budget/limit audit | Query/index/Budget lifecycle | Three logs are deduplicated and anomalies classified; no behavior change without causal proof | forensic record + targeted invariant tests if justified | PARTIAL |
| P1 | Protected Header/category behavior | Header palette/render engine | Existing dynamic category colors, ticker/backend identity, and palette behavior unchanged | existing regression tests | NOT DONE |
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

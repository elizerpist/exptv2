# Fluvi Engineering Journal

Shared evidence journal for the Fluvi prompt-writer and coding agents. Read this file in full before every implementation attempt. Entries record physically tested application SHAs, observed behavior, evidence boundaries, failed loops, commit/source audits, and the next allowed investigation scope. `USER_MARK` log entries are annotations and are never runtime proof by themselves.

> 2026-09-13 journal maintenance note: earlier long-form entries are compacted below without changing their evidence classification or no-regression meaning. The detailed commit/log artifacts remain in repository/Git history and connected evidence sources. Future entries remain append-style.

## 2026-09-10 — Physical feedback on `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`

- Exact physically tested application: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`, branch `fix/avatar-fling-pacing-codex-20260910`, APK marker `fluvi_HUMAN_DIAGNOSTIC_6e96218.apk`.
- User result: Avatar fling and overall performance good. Remaining symptoms at that time: income/expense switch hitch and limit-circle not visibly populated after month change until Avatar movement.
- Fresh Avatar and Time traces sampled healthy semantic/final-target correctness. Generic Budget pipeline emitted accepted/bound/built/painted progress events around the month symptom, so “no publication at all” was not proven.
- Protected loop guards: `aa61242c...` was smooth but lost correctness; `33ee878b...` restored correctness but choppy; `e8b73e3...` earlier motion floor; `6e962187...` became the protected physical performance floor.
- `MILESTONE_COMMITS.md` intent: preserve `6e962187...` performance/correctness while repairing later issues. Physical validation of later repairs remains user-only.

## 2026-09-10 — Direction-circle forensic audit on `0b108b73e8e13b7a3bbd397dd9c98e8bb0db79aa`

- Exact physically tested diagnostic APK: `fluvi_HUMAN_DIAGNOSTIC_0b108b7.apk`, SHA-256 `ffdaca3aeba8deee546baf55f7066cd9334e5a03117667e0e8849b0331103a28`.
- Physical result: direction-switch hitch no longer perceived; remaining reproducible failure was missing Avatar selection/progress circle immediately after direction switch until Avatar movement. Time fling did not show the analogous failure in that run.
- Fresh Avatar and Time snapshots sampled healthy semantic/final-target correctness around this direction-specific failure. Same-session retained windows contain a hard missing sequence range `10121–11662`; never infer continuity across it.
- Proven failure chain: new direction presentation published selected target 4, then `BUDGET_PROGRESS_IDENTITY_MISMATCH` showed physical Avatar target 0 vs visual target 4.
- Proven source cause class: `DIRECTION-DOMAIN SELECTED-TARGET REBASE ATOMICITY FAILURE`. `DashboardBudgetPresentationController` restores per-direction selected identity, while `BudgetTargetAvatarRail._replaceItems(...)` could preserve the previous physical center by stable ID instead of rebasing to the new direction presentation. Preserve controller/ScrollPosition/physics identity while converging one target authority.
- CI/profile for `0b108b73...` was green but false-green for this physical symptom because the automated direction case did not assert physical center == semantic target == presentation target == selected-circle paint target.
- Matching graph was stale for this diagnostic SHA. User physical evidence overrides automated green.

## 2026-09-11 — Physical Avatar frame-pacing feedback on `92222edddeee5bb13792f62f939eedf81c867a52`

- Exact physically tested application: `92222edddeee5bb13792f62f939eedf81c867a52`, APK `fluvi_HUMAN_DIAGNOSTIC_92222ed.apk`, SHA-256 `604f5e81de1265a8776af5b986288429b58c317fa3da63a8d97d607accbc1637`.
- User result: Avatar fling usable but intermittently slightly choppy; user explicitly allowed that it may predate this build, so no new-regression claim was justified.
- Fresh Avatar snapshot SHA-256 `84ce186d3d7a92a843ce1fb9147e0c8a11d30cfd0447f85e9796e9d8d7787164`, build marker `profile/92222edddeee`.
- Retained flights showed variable missed frames while sampled final-target correctness remained healthy. No rail rebuild storm and no per-tick repository/index/canonical persistence path was observed.
- Proven performance-contract anomaly: active `avatar-live-root` preparation hit `rowDiscovery=10561 µs` against a source-declared 1000 µs contiguous-UI budget; one preparation reached ~20.771 ms UI-isolate work. Exact inner `rowDiscovery` operation and direct correlation to the user's rough frame remained unproven.
- Matching SCIP existed at tooling `3f1a2bda6b529302ba59a04e226dc935f8fa446d`, source_head `92222edd...`, raw index SHA-256 `22898ae4bd1aa4bb9d5af51c3f68034adddbd0e5112c01fd8986d44e77e46c12`.
- CI/profile was green but automated K profile did not reproduce the physical long slice. Protected performance floor remains `6e962187...`; do not trade correctness for fake smoothness.

## 2026-09-12 — Mind annual heatmap feature contract on application source `0d1a6ad2efcfe84465f46184888f93cf24d245e4`

- New feature contract, not an implemented-defect diagnosis. Exact last physical application at that time remained `92222edd...`; `0d1a6ad2...` was not physically accepted.
- Mind + Year only; exactly twelve MonthCards visually arranged 3 columns × 4 rows; each month uses square day cells.
- Heatmap must represent the same current filter identity: income/expense direction, annual time/year scope, category OR partner focus, then amount-range slider refinement; no independent filter authority.
- Live amount slider must recolor during drag. Existing `previewMindAmountRange()` is the live authority; canonical Query commit remains `onChangeEnd` only.
- Annual normalization is global across non-empty filtered days. Empty days are neutral; no-data/min==max semantics require explicit tests/tokens.
- MonthCards scroll; slider footer is fixed outside the scroll viewport and compact. Shared Query Menu presentation must not regress.
- Current prepared ledger rows retain `bookedLocalEpochDay`; resident membership data means drag need not parse dates or hit Room/repository.
- Parent `DashboardCoreModeHost` owns a vertical drag recognizer; child annual scrolling required production-parent gesture-arena tests.
- Per-slider-tick prohibition: no full annual row scan, repository/Room work, index rebuild, date regrouping, canonical commit, or unbounded cache.

## 2026-09-13 — Mind annual heatmap design approval and realtime-performance hardening

- Prompt-writer design approval branch lineage: journal-only `4d24b3722aae6e0c4f5229e490112dd5c6a2e773`; underlying application source then `0d1a6ad2...`.
- Approved architecture: one Mind annual projection from prepared ledger data, one upstream identity, existing live amount-preview authority, scrollable 3×4 MonthCard region plus fixed compact footer, RED tests before implementation.
- Projection invariant: rebuild only when upstream non-amount identity changes (year/time, direction, category/partner, other source-verified refinements, data revision). After build, slider work must be independent of annual transaction count; per-day sorted contributions + prefix sums/binary bounds or source-proven equivalent are acceptable.
- Identity/liveness: generation/epoch safety; stale scheduled frame callbacks may never recolor a newer identity; replacement is atomic from the consumer's perspective.
- Slider terminal invariant: final finger value must not be lost when `onChangeEnd` races a pending coalesced frame; thumb, compact labels, heatmap and canonical range must converge exactly.
- Normalization: global annual min/max from non-empty filtered days; real empty days neutral; non-empty minimum remains visibly non-empty; no-data year all neutral; deterministic explicit token for `min == max`; amount sign semantics must follow current source.
- Layout/paint: structural `Column + Expanded(scroll) + fixed footer`, one vertical scroll owner, one slider hit-test owner, scoped rebuilds/repaints; no broad Stack reorder.
- Calendar correctness: exactly 12 MonthCards, correct month lengths, 365/366 years, Feb 29, local calendar identity, no fake interactive nonexistent dates, narrow-width month-label coverage.
- Mandatory performance gate: production-parent profile with large synthetic annual data, preview compute p50/p95/max, FrameTiming, rebuild/paint scope, allocation/GC if available; 16.67 ms frame interval requires meaningful headroom. Automated profile cannot declare physical acceptance.
- Forbidden: debounce/cooldown, release-only recolor, stale placeholders, dropped latest value, duplicate filter authority, per-tick persistence/source scans, or hiding jank by reducing correctness.

## 2026-09-13 — Mind Year heatmap physical repair feedback: canonical Fluvi worktree, calendar geometry, direction atomicity, diagnostics

- Feedback time: 2026-09-13 19:26 Europe/Budapest.
- This is a REPAIR cycle based on the user's current physical observation and supplied screenshot. The screenshot proves visible symptoms but does NOT expose an APK/source SHA or build marker. Therefore no current Git SHA, including `c4dc80dba00a09b08900f649cd8366edd9f93d9b`, may be called the exact physically tested source until build/runtime identity proves it.
- Current remote feature-line application HEAD before this journal-only entry: `c4dc80dba00a09b08900f649cd8366edd9f93d9b` on `feature/mind-year-heatmap-codex-20260913`.
- Audited feature lineage after `4d24b372...`: `9898fcedc767f4682bfa95053dacdb56c8e5d3c8` docs/spec; `2ed662d209ecaa7b00f653be6d0ef42446be09e1` bounded live Year heatmap; `bef289b6d2c6471409677d0c5fdf993a6c088f42` profile-summary retention; `28440a5f07151d6fc508f3817c48d2b0498d4205` profile-evidence retention; `2355953cafb322d8f917ac1f756e4a7738d4b5d9` bounded-field painter refactor; `c4dc80dba00a09b08900f649cd8366edd9f93d9b` held-preview profile isolation.
- Process defect: those coding-agent implementation/profile commits did not append implementation/completion evidence to this shared journal. The next agent must backfill concise factual evidence from actual diffs/tests/profile artifacts, then update this journal after every new application commit. Do not fabricate historical runtime proof.
- Worktree correction: application development belongs to the canonical Fluvi worktree. The extra application worktree is rejected. User reports canonical Fluvi worktree currently carries `separated-core-modes`; exact LOCAL worktree/dirty/HEAD state is MISSING EVIDENCE and must be proven before mutation. Remote `separated-core-modes` is `df1d4a3ca9ca83565260a6f7618ab3786ca5650e`; remote topology audit shows it is an ancestor of the current feature line, so fast-forward integration is possible remotely, but this does not prove the local worktree is clean or non-diverged.
- Required migration: in the canonical Fluvi worktree only, fetch and inventory worktrees/status/current branch/local HEAD/remote refs. If clean, create a new repair branch from the ACTUAL local `separated-core-modes` HEAD, recommended `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`; verify ancestry; fast-forward-only integrate the current feature line including this journal commit. If dirty/untracked or local ancestry blocks FF, STOP and report exact evidence; do not stash/reset/rebase/cherry-pick/destructively overwrite user state.
- Obsolete extra-worktree/branch cleanup is POST-INTEGRATION only: push the new canonical repair branch; prove every old feature/application/journal commit is reachable from that remote branch; then remove the obsolete extra worktree, delete the old local/remote feature branch and prune worktree metadata. No forced deletion merely to satisfy Git. Stay inside the Fluvi repository/project for application work.
- Screenshot symptoms: MonthCards are too tall with large unused gap below day cells; every month begins at visual column zero instead of its real weekday; too many real-day cells are colored for the selected income/expense direction; direction switching lags and the heatmap can disappear momentarily. Compact fixed slider footer is present.
- PROVEN calendar/layout source cause at `c4dc...`: `mind_year_heatmap_viewport.dart` uses a 3-column GridView with fixed `childAspectRatio: .64`; MonthCards give the painter an `Expanded`/`SizedBox.expand()` region; painter maps sequential day index by `index ~/ 7` and `index % 7` with no weekday offset. Therefore day 1 always paints in column 0 and card height is disconnected from true calendar row count. Replacing `.64` with another magic ratio is rejected.
- Required calendar geometry: seven columns are Monday→Sunday. Compute leading slots from the first local calendar day; map real day `d` through `slotIndex = leadingSlots + (d - 1)`; derive row/column from that slot; derive `rowCount` from leading slots + month length. A Wednesday-start month has two leading SPACE-ONLY slots before day 1. Nonexistent leading/trailing slots render no square. A REAL day with zero matching rows is a visible gray/no-data square. A REAL day with matching rows is colored.
- Robust height contract: preserve the 3-column × 4-row annual composition while making height calendar/content-driven, not fixed-tall. A candidate is four visual annual rows of three cards whose height follows the maximum calendar rowCount among those three months plus title/padding, or an equivalent source-proven constraint solution. Avoid expensive intrinsic layout on the live path and avoid another magic aspect ratio.
- Direction symptom is PHYSICALLY PROVEN; exact source cause is UNPROVEN. Current source already resolves the heatmap seed through `base.partitionFor(direction).focusMembershipSeed`; `DashboardFocusMembershipSeed.select()` assumes its supplied seed is already direction-partition-specific. Therefore “direction filtering was omitted” is NOT proven. Trace: direction input → selected/canonical direction → heatmap identity → `partitionFor(direction)` seed identity → projection build/ready → frame schedule/publication/stale rejection → consumer → actual paint, and repair the first proven failing boundary.
- Required day-color semantic: a REAL local-calendar day is colored iff a contribution survives the complete active intersection: selected income OR expense direction ∩ selected annual year/time scope ∩ category OR partner focus ∩ every other source-defined non-amount refinement such as search where applicable ∩ transient amount-range slider secondary refinement. No surviving contribution => gray real-day square. Slider must never make opposite-direction rows eligible.
- Direction atomicity/performance contract: when Bevétel/Kiadás becomes visibly selected, the heatmap must not blank and must not display stale old-direction paint under the new selected chrome. Correct new-direction paint must arrive from resident prepared data in the same visible transition or next render frame, with latest-wins stale rejection. Profile request→identity→projection-ready→publish→paint latency before choosing optimization. A bounded max-two-direction prewarm/cache is allowed only if measurements prove projection readiness is causal; it must share the same authority/identity and be atomically invalidated, never unbounded.
- Preserve existing bounded slider architecture: `MindYearHeatmapProjection` stores per-day sorted contributions/prefix sums and slider preview visits fixed 365/366 day buckets. Do not regress to per-tick Room/repository/index/canonical/source-row work.
- Mandatory anti-false-green tests: exact COLORED DAY SETS for deliberately disjoint income vs expense fixtures; real mounted production-parent Bevétel/Kiadás toggle using one controller; no blank/stale frame after new direction becomes visibly selected; rapid back/forth latest-wins; slider secondary-intersection; Monday-, Wednesday-, Sunday-start months; real no-match day gray vs nonexistent slot unpainted; leap year/Feb 29; compact calendar-derived height/no excess gap; 7 Monday→Sunday columns; preserved 12-card 3×4 composition; existing work-bound/performance tests. Merely asserting “colors differ” is insufficient.
- Diagnostics requirement: add a dedicated `Mind Heatmap` option in the EXISTING onscreen debug panel/dropdown. Source-locate and graph-verify the panel/filter owner before modification; do not create a parallel debug UI. Reuse bounded `FluviOnscreenDiagnostics`. Add bounded lifecycle events covering direction request, identity resolution, projection build start/end, frame scheduled/published/stale-rejected, direction-visible, actual paint, coalesced slider-preview summary, and one calendar-geometry summary per projection/year. Record safe generation/direction/year/revision/count/timing fields including request→ready→paint latency and source rows touched. No per-cell flood and no raw transaction/partner/category names or sensitive transaction payloads.
- Runtime-log boundary: no fresh current Mind heatmap runtime trace was found in connected Fluvi logs. Historical `Fluvi logs slider` belongs to build `9e8a7b3a0a1f17bbd9433927e1d8a0afcd8413e9`, session `fluvi-1788686737010611`, modified 2026-09-06; it is stale for current heatmap correctness and only historical preview context.
- GRAPH STATUS: tooling remote `5036775f68198c314ea23047181cb3a4f1e9ae33` has manifest `source_head=bef289b6d2c6471409677d0c5fdf993a6c088f42`, `scip_dart=1.6.2`, raw index SHA-256 `de22a7a3b924ddce1952a56c16a29dd259ed5337b2c719903efd7950757ea297`. It predates `28440a5...`, `2355953...`, and `c4dc80d...`, so it is STALE/current-navigation-only. Regenerate matching SCIP after canonical-worktree integration before shared-symbol impact conclusions; source-verify refs; regenerate again for final application SHA.
- No-regression floor: `MILESTONE_COMMITS.md` protects `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. Preserve Avatar/Time controller/ScrollPosition/physics identity and canonical query ownership. Do not broaden into shared direction mechanics unless instrumentation proves that boundary causal.
- PROVEN: current user-observed calendar misalignment, excess card height, wrong direction day-set behavior and direction-switch lag/transient disappearance; source missing weekday offset and fixed-tall card geometry; existing direction partition call; bounded daily projection architecture; feature commit topology; stale graph; no fresh current heatmap trace; missing coding-agent journal evidence after feature commits.
- UNPROVEN: first causal boundary for wrong income/expense membership; owner of lag/blanking; need for prewarm; exact screenshot APK/source SHA; exact local canonical Fluvi worktree cleanliness/divergence.
- MISSING EVIDENCE: canonical local-worktree preflight; screenshot build identity; fresh `Mind Heatmap` trace; production-parent exact-day-set RED→GREEN evidence; direction request→correct-paint latency/FrameTiming profile; matching SCIP for integrated and final source; final APK/hash; user physical revalidation.
- Prompt-writer change for this feedback: journal only, `[skip ci]`; no application source, test, workflow, graph, milestone file, build configuration or runtime behavior is changed by the prompt writer.
- Physical validation of the eventual repaired APK: `PENDING — USER ONLY`.

## 2026-09-13 — Backfill: Mind heatmap implementation and profile evidence

- Backfill author: repair agent on canonical Fluvi branch
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.  This entry is
  based on the actual Git diffs, checked-in tests and available GitHub Actions
  summaries/logs; it adds no retrospective device-runtime claim.
- `9898fcedc767f4682bfa95053dacdb56c8e5d3c8` changed only the original
  feature plan/spec/checklist.  It did not change production code or provide
  physical evidence.
- `2ed662d209ecaa7b00f653be6d0ef42446be09e1` added the annual projection,
  live projection lane, core-controller integration, Mind surface/host/range
  bridge, profile harness/report support and associated tests.  The actual
  projection builds from resident ledger entries, stores day-local sorted
  contributions/prefix sums, and its preview iterates the fixed annual day
  domain.  The tests cover valid 365/366 dates, normalization, held slider
  recolor, stale identity and basic direction/focus/range cases; they did not
  assert true Monday–Sunday slots, disjoint direction day sets through the
  mounted production parent, or per-frame chrome/heatmap atomicity.
- `bef289b6d2c6471409677d0c5fdf993a6c088f42` changed profile-summary
  retention/race handling and explicitly did not alter Mind query or heatmap
  authority.  It is context for profile evidence only.
- `28440a5f07151d6fc508f3817c48d2b0498d4205` changed the profile harness and
  checklist to retain Mind preview evidence across bounded diagnostic-tail
  eviction.  It did not change production heatmap ownership.
- `2355953cafb322d8f917ac1f756e4a7738d4b5d9` replaced each MonthCard's
  per-day widget grid with one dynamic `CustomPainter` field and added
  structural tests.  The painter still used sequential `index ~/ 7` /
  `index % 7`; this is the verified source of the calendar-column defect.
  GitHub Actions run `34761546881` reported core, Flutter and human-APK jobs
  successful but the dashboard profile failed its Mind FrameTiming evidence
  validation, so it is not a green physical-performance result.
- `c4dc80dba00a09b08900f649cd8366edd9f93d9b` changed the integration profile
  sampler to isolate held previews and updated its checklist.  It did not
  change production heatmap direction/calendar code.  GitHub Actions run
  `34763720161` likewise had core, Flutter and human-APK jobs successful while
  `run-dashboard-profile` failed: the retained frame-timing report included
  average build `14.898 ms`, p90 build `24.461 ms`, p99 build `62.496 ms`, six
  missed build-budget frames, and average raster `752.771 ms` (p90 `1416.142
  ms`, p99 `1505.187 ms`).  This is a failing automation artifact, not a
  statement that the physical screenshot came from this SHA.
- Current repair audit additionally verified: the screenshot SHA/build marker
  is unknown; no fresh current Mind heatmap runtime trace exists; the old
  graph at `bef289b6...` was stale; pre-repair SCIP has now been regenerated
  for `d27950c...`; and the prior tests' “colors changed”/single-direction
  assertions leave the new exact-set and atomic-frame false-green gaps open.
- Still unproven: the first direction causal boundary, any need for a
  direction cache/prewarm, final request-to-paint timing, and device
  acceptance.  `PENDING — USER ONLY` remains the physical-validation state.

## 2026-09-13 — Mind heatmap calendar/direction repair application evidence

- Application commit: `9fb4a9e1` (`fix(mind): repair year heatmap calendar
  and direction atomicity`).  This is application/test/profile source, not
  physical acceptance.
- First direction boundary proved by the RED mounted-parent reproducer:
  `transactionDirection.select(...)` changed the visible Income/Expense
  chrome while the old heatmap refresh still derived direction from the
  navigation-owned scope, whose LogBox scene acknowledgement could be held.
  Thus the already-present `base.partitionFor(direction).focusMembershipSeed`
  was not omitted; it was supplied too late for visible atomicity.  The repair
  installs the target immutable Mind frame from the same resident partition
  before changing the chrome.  A bounded, one-operation inactive canonical
  amount-domain prewarm was added because the actual loader otherwise owned
  only the active direction's domain; it retains no second Query controller
  and only the two canonical directional slots.
- Calendar source repair: new immutable
  `MindYearHeatmapCalendarGeometry` maps local Monday–Sunday slots, derives
  leading/trailing empty space and row count from each month, and the viewport
  groups three MonthCards per annual row using the maximum required calendar
  height.  It removes the fixed global aspect ratio; real zero-data days stay
  gray and nonexistent slots are not painted.
- Diagnostic repair: the existing bounded DebugConsole gained a `Mind
  Heatmap` filter.  The event family is correlated by safe flow/direction/
  digest/revision/timing/count fields and covers request, identity, projection
  build, schedule/publication/stale rejection, visible paint, coalesced slider
  summary and calendar geometry.  No raw descriptions, partner/category names
  or per-cell logging were introduced.
- RED→GREEN automated evidence: `MYHR-05` local geometry fixtures cover
  Monday/Wednesday/Sunday starts, January–June 2025 offsets, 28/29/30/31 day
  months and four/five/six rows. `MYHR-06` asserts disjoint exact Income and
  Expense local-day sets and range-as-secondary-intersection. `MYHR-07/08`
  exercise real production direction controls frame-by-frame and rapid
  toggles, rejecting blank, chrome/identity mismatch and stale paints. The
  panel test verifies All plus the dedicated filter; loader tests prove the
  bounded prewarm; report tests require direction timing/critical-path fields.
- Validation actually run in Ubuntu proot: `flutter analyze` — PASS (`No
  issues found`); focused calendar/viewport/loader/profile-report suite —
  PASS (116 tests); full `dashboard_core_ephemeral_focus_test.dart` — PASS
  (106 tests); query/rebuild/zero-I/O regression suite — PASS (57 tests).
  Device integration profile, final Actions profile values, human APK hash and
  physical visual acceptance remain unproven at this point.
- Untracked preservation baseline before this commit: 80 pre-existing user
  paths, content-manifest SHA-256
  `d64543c3bde9e6599e01278b0944e4c045dce252f4595ac058cdba5de2d0350f`;
  path/size/mtime-manifest SHA-256
  `849c3088844bb383f46f701e35c789a17049ab40662fc664185e6ad20036fcd4`.
  None was staged, modified, stashed, cleaned or deleted.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-14 — Prepared-base repair delivery and final graph provenance

- Final application source remains
  `288cc35584ec5cb6e41eb237523104922a2c7393`; journal commits do not alter
  application source. Final SCIP was generated from a temporarily detached
  canonical checkout at that exact SHA and then the worktree was returned to
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` at
  `67ee2a955b6f420a13868f49f515c1f203632ad6`.
- Final SCIP provenance: `scip_dart=1.6.2`, raw index SHA-256
  `075b9e35e8f132456cda35c63535e26a93ddba7f158a312855600a585232b86a`,
  448 documents, 290,228 occurrences, 10,233 repository-defined symbols and
  74,608 references. Tooling graph commit
  `a031f804a692345e24759d3631ed134cbca02e0f` on
  `tooling/scip-codegraph-v1` records that provenance; its tooling tests pass.
- Exact source Actions delivery run: `34859925658`, workflow `Fluvi
  Verification`, head SHA `288cc35584ec5cb6e41eb237523104922a2c7393`.
  `test-core`, `test-flutter`, path gate and `build-human-diagnostic-apk`
  succeeded. The human release target is that same full SHA.
- Downloaded normal human diagnostic APK:
  `/storage/emulated.com/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_288cc35.apk`;
  byte size `82,482,481`; SHA-256
  `8bc1d1fa915c8617258c7cdcc0e853c9a58e4619583bc53be03c892230947f97`.
  The full `FLUVI_BUILD_COMMIT=288cc35584ec5cb6e41eb237523104922a2c7393`
  string was verified in the APK `lib/arm64-v8a/libapp.so`; build purpose is
  the workflow’s `human_diagnostic` profile target.
- At this journal time, the separate Actions dashboard-profile job remains
  running. It is not substituted for user physical acceptance and its result
  must be reported factually when observed.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-14 — Physical Mind direction/LogBox regression on `2fc02e143197996eee2218fe3830a1349e0f1f5d`

- Feedback time: 2026-09-14 08:31 Europe/Budapest.
- Exact physically tested application SHA from the refreshed runtime marker: `2fc02e143197996eee2218fe3830a1349e0f1f5d` on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`. Commit `2fc02e...` is profile/test-only on top of production repair `9fb4a9e1e2e2468255d53e2dfbe174ac3d9b17b9`. Current remote branch before this journal entry is `3d4e75a7a9a2694461b09a8851643fd8c2ba141b`, another profile/test-only commit, and is NOT physically tested.
- Fresh Drive snapshot: Google Doc `Fluvi logs other`, ID `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified `2026-09-14T06:26:30.430Z`; plain-text export SHA-256 `07e64e2eeb84c65c25e27deeea64026a314981978a022c47d0fb3edf996f3c96`, 334,926 bytes, 1,001 lines. Session `fluvi-1789367123468683`; retained sequence `6151–7150`, 1,000 unique contiguous events, no observed internal gaps. Build marker `profile/2fc02e143197`; `USER_MARK issue=other` is the user's observation anchor, not mechanism proof.
- Onscreen-debug distinction proved from exact tested source: the LOG FILTER dropdown contains `All` and `Mind Heatmap`, but the separate `MARK BUG NOW` popup does NOT contain a Mind Heatmap issue choice; it contains `mind_slider`, Avatar/Time/Budget choices and `other`. Therefore the user's choice of `Other` for this feedback is correct. The next repair must add a dedicated Mind Heatmap BUG-MARK option without duplicating the existing log filter or diagnostic ring.
- Physical regressions: (1) Bevétel/Kiadás switching visibly lags at the annual heatmap; (2) after selecting Kiadás, the visible transaction LogBoxes can remain Income rows; leaving Year and returning restores the list. The LogBox symptom is a regression and cross-surface consistency failure, not an accepted eventual-consistency behavior.
- PROVEN heatmap timing boundary: four retained direction switches show generic direction-visible latency around `3.9–11.9 ms`. Expense heatmap transitions reach correct paint in roughly `29–35 ms`. Two Income transitions first emit `MIND_HEATMAP|FRAME_REJECTED_STALE reason=preparedBaseUnavailable`, then do not resolve identity/projection until roughly `0.86–0.95 s`, with correct paint roughly `0.90–0.98 s` after request. Once the compatible base exists, projection work is bounded/fast; final ready projections are direction-separated (Income: 1,846 source rows / 42 colored days; Expense: 2,458 source rows / 193 colored days).
- CURRENT source matches the heatmap failure class: `_installMindYearHeatmapForDirectionIntent(...)` depends on a target-direction compatible amount domain/binding and `_compatibleMindAmountPreviewBase(...)`; if unavailable it clears `mindYearHeatmap` and logs `preparedBaseUnavailable`. Thus the first proven heatmap failure boundary is TARGET-DIRECTION PREPARED-BASE READINESS before heatmap identity/projection, not the generic direction controller and not a ready-state direction-partition omission. WHY the inactive-direction compatible base is absent despite the bounded prewarm is still UNPROVEN and must be traced before production repair.
- LogBox physical stale-row failure is PROVEN by user testing, but the first causal boundary is UNPROVEN in the retained trace. At the currently instrumented boundaries, each switch publishes the requested target direction: `DIRECTION_SWITCH_VISIBLE_PUBLISHED`, `VERTICAL_PAGE_COMMITTED` and `LOGBOX_SCENE_SELECTED` all agree with the requested income/expense direction; no retained direction mismatch was observed among `LOGBOX_SCENE_SELECTED`, `VERTICAL_PAGE_COMMITTED`, or `VERTICAL_EXTENT_PUBLISHED`. Existing telemetry therefore stops above the ACTUAL rendered card/row identity and cannot clear the physical rejection.
- Recovery by leaving Year and returning is evidence that a lifecycle/reconciliation/remount transition can heal the stale visible rows; it is a diagnostic clue only, NOT proof that remounting is the correct fix. Mode-toggle/remount/key/cache-flush workarounds are forbidden.
- Current `DashboardCoreController.selectDirection(...)` deliberately stages heatmap intent installation, then visible `transactionDirection.select(direction)`, while LogBox/navigation/query publication completes through later asynchronous orchestration. This split is an architectural hazard for cross-surface atomicity, but the exact LogBox root owner remains UNPROVEN. Do not broadly rewrite shared direction mechanics without actual rendered-row evidence.
- False-green gap in `9fb4a9e1...` tests: direction tests preinstall/wait for the opposite amount domain before interaction and then assert heatmap/chrome identity. That removes the physical cold/inactive-direction `preparedBaseUnavailable` path. Existing tests also do not assert the actual visible LogBox card/row direction on every frame. Therefore the previous “direction atomicity” automated acceptance is physically rejected and insufficient.
- Commit audit: `9fb4a9e1...` is the production repair and crosses debug, dashboard controller, Mind calendar/presentation, query facet-loader and test/profile layers; `2fc02e...` and `3d4e75a...` are profile/test-only follow-ups. The next agent must inspect actual diffs rather than trust subjects and must keep the repair at the first proven owner(s).
- Exact-tested-SHA CI audit: GitHub Actions run `34782074754` for `2fc02e...` concluded FAILURE; `test-core` succeeded, `test-flutter` failed, and the human diagnostic APK/profile jobs in that run were skipped. The connector audit did not recover the exact failing Flutter-test body; classify the exact failure cause as MISSING EVIDENCE and re-run/inspect locally before using this baseline as a validation gate.
- GRAPH STATUS: tooling `tooling/scip-codegraph-v1` is `2ea314e5193d390f055c2bdb9c015187b759389f`; manifest `source_head=9fb4a9e1e2e2468255d53e2dfbe174ac3d9b17b9`, `scip_dart=1.6.2`, raw index SHA-256 `5965eef98fac62a893c8cabc48ab0ec1305dbb13010a53b5e925d1d1e0532d69`. This graph matches the production source parent but is STALE FOR EXACT TESTED HEAD `2fc02e...`; regenerate before relying on graph impact for shared-symbol edits and again for final application SHA.
- Structuring requirement: the user reports a dedicated `Structuring Apps` / `structuring-apps` skill is available to the coding agent and requires it for this architecture-sensitive repair. It was not found as a repository file during the prompt-writer audit. The coding agent must load the actual available skill before architecture changes and report its exact identifier/path/version and applied boundary/layer invariants. If unavailable in the coding-agent environment, STOP as `MISSING CAPABILITY` rather than substituting guessed architecture rules.
- Required next forensic scope: reproduce a COLD inactive-direction switch without target-domain preinstallation/wait loops; trace amount-domain/binding/prepared-base lifecycle to the first owner of `preparedBaseUnavailable`; add bounded diagnostics that correlate actual visible LogBox row/card identity with selected direction/query generation; mount a production-parent frame-by-frame test where heatmap, direction chrome and actual transaction cards must share one visible direction generation. Rapid toggles must be latest-wins; Year leave/re-enter must not be needed to become correct.
- Dedicated debug UX requirement: preserve the existing `Mind Heatmap` log filter and add a separate `Mind Heatmap` bug-mark choice producing a distinct USER_MARK issue (for example `mind_heatmap`) so future physical feedback can select it instead of `other`.
- No-regression gate: `MILESTONE_COMMITS.md` protects physical performance floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. Preserve Avatar/Time controller, ScrollPosition and physics identity; preserve bounded slider hot-path semantics; do not introduce repository/Room/index/canonical work per slider tick; do not fix one direction surface by breaking another.
- PROVEN: exact tested SHA/build marker; contiguous fresh Other log snapshot; physical heatmap lag; physical stale LogBox after direction switch; fast generic direction controller; income heatmap `preparedBaseUnavailable` as first proven heatmap boundary; ready-state direction-separated projection; missing Mind Heatmap bug-marker menu item; existing test false-green shape; failed exact-SHA CI run; stale exact-head graph.
- UNPROVEN: why inactive-direction prepared base disappears/remains unavailable despite prewarm; first actual-render LogBox divergence owner; whether the same shared orchestration defect causes both symptoms; whether a bounded dual-direction resident base change is necessary; final physical smoothness/correctness.
- MISSING EVIDENCE: exact `test-flutter` failure body for run `34782074754`; matching SCIP for exact tested/current/final source as required; actual rendered LogBox row/card direction trace; production-parent cold-target RED→GREEN evidence; final performance profile/APK/hash; user physical revalidation.
- Prompt-writer source change for this feedback: this journal entry only, committed with `[skip ci]`; no application source, tests, workflow, graph, milestone file, build configuration or runtime behavior is changed by the prompt writer.
- Physical validation of the next application repair: `PENDING — USER ONLY`.

## 2026-09-14 — Prepared-base liveness and rendered-LogBox boundary application evidence

- Application commit: `288cc35584ec5cb6e41eb237523104922a2c7393`
  (`fix(mind): release prepared bases before optional scenes`). This is an
  evidence-led repair commit, not a device-acceptance claim.
- Source root cause for the verified heatmap delay: a Mind base was previously
  obtained only from the complete `PreparedQueryCandidate` future. Its exact
  immutable `PreparedDashboardIndex` is ready before optional budget/
  partner/LogBox candidate scene work. The refreshed Drive snapshot records
  exactly that gap: Income receives `preparedBaseUnavailable` early and only
  reaches the later candidate completion about 0.86–0.95 s afterward.
- Repair: `PreparedQueryCandidatePreparation.indexFuture` exposes the exact,
  revision/scope-validated immutable index without applying a Query or leasing
  a scene. `DashboardCoreController` remains the only orchestration owner; it
  retains at most one non-amount Mind base per ledger direction, serializes
  cold sibling admission through the one native index lane, and uses
  direction-keyed supersession generations. A matching chip-hotset promotion
  uses the same early readiness boundary. No retry, timer, remount, key change,
  cache flush, renderer query mutation, second direction controller, or
  unbounded cache was introduced.
- Direction publication contract: if a Year heatmap target lacks its compatible
  prepared base, Core retains the complete current direction rather than
  publish new chrome with a blank/stale heatmap. Once the exact target base is
  admitted, existing Core/presentation direction flow owns the target switch.
- Actual LogBox forensic boundary: the stable painter now emits
  `LOGBOX|VISIBLE_ROWS_BOUND` from the matching canvas paint. It carries only
  safe selected/canonical/payload identities, generation/revision/viewport
  fields, counts, direction totals and hashed row/query edge identities. The
  Core provenance is captured with the immutable composition, not fetched from
  a later post-frame controller read. It does not repair the user’s stale-row
  symptom; it establishes the first trustworthy physical trace boundary.
- Debug UX: the existing `All`/`Mind Heatmap` log filter is unchanged. The
  separate `MARK BUG NOW` popup now has `Mind Heatmap` with
  `USER_MARK issue=mind_heatmap`.
- RED→GREEN evidence in Ubuntu proot: `DRR-03` proves an immutable index is
  released before a held optional candidate scene; `DRR-03b` covers hotset
  promotion; `DRR-03c` holds one cold native build and proves no sibling enters
  before it settles; `DRR-05` verifies actual painted-row safe provenance and
  an intentional selected/payload mismatch; `DRR-09` verifies the bug-marker
  option. Full `dashboard_core_ephemeral_focus_test.dart` passed 71 tests;
  full `dashboard_core_query_application_test.dart` passed 52 tests;
  full debug and vector-asset suites passed; targeted production analysis
  passed with `No issues found`.
- Known unrelated test baseline: the full
  `dashboard_logbox_stable_render_surface_test.dart` fails before/independent
  of this repair at unchanged line 89 because `tester.state(find.byType(
  Scrollable))` finds multiple elements. Its new focused DRR-05 test passes;
  this failure is not represented as a green regression result.
- CI baseline correction after direct GitHub job-log audit: run `34782074754`
  had `test-core`, `test-flutter`, and human APK success; the overall failure
  was `run-dashboard-profile` at integration profile line 1629, missing the
  post-quiescence engine timing marker and later
  `B_year_month_rail_populated`. This is profile-instrumentation evidence,
  unrelated to the two physical direction symptoms; the earlier journal text
  that called `test-flutter` failed is superseded by this factual audit.
- Still unproven/not complete: a post-repair physical trace, first production
  stale-LogBox owner and repair, exact no-preinstalled-domain cold parent pair,
  actual-row cross-surface/re-entry/rapid-toggle matrix, final performance
  profile, final matching SCIP, human APK hash, and device validation.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-15 — Physical Summary Time target-jump recurrence and Mind Year heatmap publication lag on `288cc35584ec5cb6e41eb237523104922a2c7393`

- Feedback time: 2026-09-15 08:10 Europe/Budapest. Exact physically tested application is `288cc35584ec5cb6e41eb237523104922a2c7393`, runtime marker `profile/288cc35584ec`, on the canonical repair lineage. Remote branch HEAD immediately before this prompt-writer journal entry was docs-only `e508cbe2cc8faf3ee1ed0043bb0b78223ec8ed67`; application source therefore remains `288cc355...`.
- Fresh `Fluvi logs time fling`: Google Doc `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, revision `51`, modified `2026-09-15T06:07:56.959Z`; plain-text export `808,629` bytes, SHA-256 `08c630714ed985a7d646a368ac70b7b0b7f4e80a5e9593d62e6e12aeabd1b594`. It contains two 1,001-line LIVE_TAIL snapshots from session `fluvi-1789452354097594`: retained `2105–3104` and `2115–3114`; the 990-event overlap is byte-identical, giving a deduplicated contiguous union `2105–3114` with 1,010 unique events. USER_MARKs include `time_fling` and `time_target_jump` and remain observation anchors only.
- Fresh `Fluvi mind heatmap`: Google Doc `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, revision `3`, modified `2026-09-15T06:06:19.421Z`; plain-text export `405,440` bytes, SHA-256 `2c4ab4c366e0ba884dd8a48d0597f82eabf3f81e1408bb6d6289e362fadd1605`, 1,001 lines, same session/build, contiguous retained `2075–3074`. Combined same-session deduplicated coverage is contiguous `2075–3114` (1,040 unique events).
- Physical Time symptom: the user reports the old Summary Pill target-finding failure has returned, e.g. after 2024 a value as far away as 2000 can appear and the year selector jumps. The retained fresh trace independently proves the same defect class with an exact `2024 -> 2020` jump; literal year 2000 is not retained in this window and must not be substituted for the user's device observation.
- PROVEN Time trace boundary: the preceding year flight reaches/paints 2028→2027→2026→2025→2024 and `flight:8` ends canonically on 2024. A new direct pointer is accepted while Summary Time is still in a held/prior-motion transition; Core reconciles/promotes the semantic 2024 target and invalidates the segmented settle target. The very next new Time candidate is `year:2020`, is accepted and exact-painted, and `flight:9` contains one semantic tick ending on 2020. Neighboring later flights demonstrate 2020→2021 and 2021→2020 normally, while stale settle attempts are rejected as superseded.
- Matching source/graph audit proves the relevant ownership split: `_HierarchyValueSelectorState` snapshots `_motionOrigin` from semantic navigation state, projects candidates from carousel logical offset, and performs `_controller.jumpToIndexSilently(0)` only after its own successful `onMotionIdle()` settle. `CenteredCarousel` direct-pointer interruption can suppress the normal settled callback, while Core `noteSummaryDirectPointerDown(...)` can promote/canonicalize the latest completed semantic target and invalidate the segmented settle target independently. This establishes the failure class `SUMMARY TIME SEMANTIC-ORIGIN / PHYSICAL-LOGICAL OFFSET REBASE ATOMICITY FAILURE ON BACK-TO-BACK DIRECT-POINTER PREEMPTION`. Exact raw-index arithmetic and the smallest production owner still require a mounted RED reproducer before mutation.
- False-green gap for Time: existing controller/core direct-pointer tests can exercise semantic promotion without mounting the real `_HierarchyValueSelector` + `CenteredCarouselController` logical index. They therefore do not prove that semantic origin and physical/logical offset are atomically rebased before the next gesture. Preserve controller, ScrollPosition and physics identities; do not fix by recreation, hard year clamps, delays/debounce, remounts/keys, disabling direct-pointer interruption, or snapping to current year.
- Physical Mind symptom: while already in Mind + Year, changing the year updates the Summary year but the annual heatmap follows perceptibly later rather than immediately.
- PROVEN Mind timing boundary on the same build/session: accepted/painted Summary year targets precede matching heatmap identity by about `1.60 s` for 2024, `1.52 s` for 2020, `0.80 s` for 2021, and `1.20 s` for the later 2020 transition. Once `MIND_HEATMAP|IDENTITY_RESOLVED` finally occurs, projection builds are only roughly `84–123 µs` in the retained samples and paint follows shortly afterward. The lag is therefore before heatmap identity/publication, not a heatmap projection-compute bottleneck.
- Matching source + SCIP explain the Mind failure class: `ensureMindYearHeatmapProjection()` derives year from canonical `navigation.state` / `yearCursor` and is referenced by focus/category/partner and presentation amount-range paths. The accepted transient Summary Time Year path publishes through `_publishPreparedSegmentedTemporalTarget(...)` / live-interaction state and has no matching heatmap projection trigger. During fast year flings there are no corresponding intermediate heatmap publications; heatmap catches up later through canonical/navigation or presentation refresh. PROVEN cause class: `MIND YEAR HEATMAP TEMPORAL IDENTITY PUBLICATION IS TIED TO CANONICAL NAVIGATION / PRESENTATION REFRESH RATHER THAN THE ALREADY-ACCEPTED TRANSIENT SUMMARY TIME YEAR TARGET`.
- Required Mind contract: for a Summary Time Year candidate that is both accepted and actually visible/painted, Mind heatmap year identity must use that same accepted generation and publish in the same visible transition or next render frame. Coalesced candidates that never paint need not force heatmap publication. Rapid flings are latest-wins with stale generation rejection. This must not create per-tick canonical Query commits, Room/repository work, index rebuilds, duplicate Time/year authority, or rich-scene/text preparation solely for heatmap; use the existing bounded resident prepared index/focus membership path.
- Commit audit: since the prior prompt-writer journal commit `101ac1a4...`, application commit `288cc355...` changed shared prepared-resource/Core orchestration to release Mind bases before optional scenes, retain bounded per-direction bases, add actual LogBox paint provenance and dedicated Mind Heatmap bug marking. Follow-up `67ee2a9...` and `e508cbe...` are journal/delivery-only. Commit `288cc355...` explicitly did not intend to change Time/Summary mechanics, but it crosses shared Core/resource orchestration; whether it introduced the returned Time target-jump is UNPROVEN and must be established by RED/bisect evidence rather than inferred from chronology.
- Exact-tested-SHA CI: GitHub Actions run `34859925658` for `288cc355...` has `test-core`, `test-flutter`, path governance and human diagnostic APK jobs successful, while `run-dashboard-profile` failed and overall workflow concluded failure. The exact current profile failure body was not recovered in this prompt-writer pass; classify it as MISSING EVIDENCE and inspect/re-run before using the baseline as a performance gate.
- GRAPH STATUS: matching tooling branch `tooling/scip-codegraph-v1` is `a031f804a692345e24759d3631ed134cbca02e0f`, manifest `source_head=288cc35584ec5cb6e41eb237523104922a2c7393`, `scip_dart=1.6.2`, raw index SHA-256 `075b9e35e8f132456cda35c63535e26a93ddba7f158a312855600a585232b86a`, 448 documents / 290,228 occurrences / 10,233 repository symbols / 74,608 refs. It matches this physical build and must be regenerated for the final application SHA.
- Structuring requirement remains mandatory. Prior coding-agent evidence located `Structuring Apps` at `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`; the next agent must open/read the actual skill itself and report exact identifier/path/version plus applied ownership/layer rules before touching shared Time/Mind orchestration. If unavailable, STOP as `MISSING CAPABILITY`.
- No-regression floor: `MILESTONE_COMMITS.md` protects `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. Historical `e8b73e3...` demonstrates that apparent smoothness can coexist with out-of-prepared-window target split/jump; never trade exact-target correctness for smoothness or fake bounds. Preserve Avatar/Time controller/ScrollPosition/physics identity, canonical query ownership, the 288 prepared-base/direction repair, LogBox provenance, bounded slider semantics and calendar geometry.
- PROVEN: exact tested source/session/build; fresh contiguous two-log coverage; physical Time target-jump recurrence; retained exact 2024→2020 one-gesture jump; Time semantic-origin/physical-logical rebase atomicity failure class; physical Mind Year lag; 0.8–1.6 s pre-identity delay; fast 84–123 µs heatmap projection compute; missing transient accepted-Year→heatmap publication coupling; matching exact-source SCIP; 288 commit topology and failing dashboard-profile job.
- UNPROVEN: literal 2024→2000 mechanics in the retained trace; the exact smallest line-level Time rebase owner/raw index arithmetic; whether 288 introduced the Time recurrence; whether Time and Mind defects share one causal owner; exact profile-job failure body; final repair performance/physical acceptance.
- MISSING EVIDENCE: mounted production Summary UI RED that captures semantic origin + carousel logical/physical offset through back-to-back pointer preemption; production-parent Mind Year RED asserting Summary-painted generation == heatmap-painted generation frame-by-frame; exact dashboard-profile failure body for run `34859925658`; final matching SCIP/APK/hash; user physical revalidation.
- Prompt-writer change for this feedback: journal only, `[skip ci]`; no application source, tests, workflow, graph, milestone file, build configuration or runtime behavior is changed by the prompt writer.
- Physical validation of the next application repair: `PENDING — USER ONLY`.

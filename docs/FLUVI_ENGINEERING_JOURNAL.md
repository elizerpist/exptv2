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
- Fresh evidence snapshots: Avatar log SHA-256 `de24763fd6570f7353bf148b9fe8868e83f3459c598bc663723384df2c00cc77`; Time `3e4f07bf8a8ef9c6fb0f419f30a9fc4cc9d5f2ce94e071b876afac80674876a2`; Budget `f73c15b94a0f0ac90001cff97e9287fbfc2b79e55b04a75319fc40aea35e538b`. Same-session retained windows contain a hard missing sequence range `10121–11662`; never infer continuity across it.
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
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_288cc35.apk`;
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

## 2026-09-15 — Profile timing-boundary correction (`7ae82c56`)

- Test-only commit: `7ae82c565de3c808237dea32a541bbb5fda36e9e`
  (`test(profile): permit an idle Mind timing boundary`). No Flutter runtime,
  Core, Time, Mind, query, LogBox, cache, controller, ScrollPosition, physics
  or presentation source changed.
- Exact online RED evidence: Actions run `34992842232`, profile job
  `104463696499`, built from application SHA
  `e62a817232121aa7023f4946aeacf6cc4111c82d`, failed at
  `drainPrePreviewFrameTimings` before either RangeSlider gesture. The
  quiescence gate had passed, then the engine delivered no new callback during
  the four-second idle drain (`Expected: non-empty; Actual: []`). The job did
  not reach a frame-time threshold; its subsequent missing scenario map is a
  consequence, not a second cause.
- Comparative source/log evidence: the earlier exact `7645789...` profile
  run reached the same Mind interaction and failed later on actual
  `FrameTiming` headroom, after a non-empty idle callback happened to arrive.
  Thus an idle callback is not a semantic property of the pointer interaction
  being measured. The existing per-held-pointer and per-direction-tap
  `_awaitFrameTimingAfter(...)` assertions remain unchanged and continue to
  require newly delivered engine samples during real user input.
- Repair: retain the four-second delayed-batch drain and clear any batch it
  receives, but permit zero callbacks in an otherwise quiescent engine. This
  removes only the false precondition; it does not relax production behavior,
  slider publication, FrameTiming requirements for actual gestures, direction
  atomicity, or any performance threshold.
- Local validation in Ubuntu proot: `flutter analyze
  integration_test/dashboard_interaction_profile_test.dart
  integration_test/support/dashboard_profile_report.dart` — PASS (`No issues
  found`); `flutter test test/performance/dashboard_profile_report_test.dart`
  — PASS (98 tests).
- Pending: a reasoned exact online profile rerun must establish the actual
  post-pointer frame metrics. The distinct `7645789...` metric failure and
  `e62a8172` dual-lane resource cost remain unproven as a common cause and
  must not be silently classified green.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-15 — Mind profile p95 schema correction (`5aff50ea`)

- Test/profile evidence commit: `5aff50ea` (`test(profile): normalize Mind
  FrameTiming p95`). No production Flutter, Core, Time, Mind, query, LogBox,
  cache, controller, ScrollPosition, physics, or widget source changed.
- Exact online evidence before this correction: Actions run `34997263756`,
  profile job `104478420467`, on source head `e1a2c05...`, passed dashboard
  paths, core tests, Flutter tests and human APK. The idle timing precondition
  no longer failed: the run reached real held RangeSlider and direction-tap
  interactions. It then failed at
  `DashboardProfileReport.validateMindYearHeatmapEvidence` line 195 with
  `frame_timing` invalid, before the p95 headroom comparison.
- First proven owner: Flutter's `FrameTimingSummarizer.summary` provides p50,
  p90 and p99 aggregates but no p95 fields, while Fluvi's Mind evidence
  contract requires p95. The rejected SDK map reported, for context only,
  average/p90/p99 build `15.869`/`24.297`/`35.264 ms`, 21 build misses, and
  average/p90/p99 raster `2198.060`/`2946.552`/`4348.980 ms`; it did not
  contain the required p95 values. Therefore these numbers are NOT a valid
  completed p95 performance classification.
- RED→GREEN: `PRF-02` initially failed to compile because the normalizing
  boundary did not exist. The new shared profile adapter receives the exact
  bounded captured build/raster duration lists for both the complete Mind
  interaction and its direction-tap subset, computes p95 through the existing
  percentile routine, and removes the raw duration lists before report
  publication. Thus no threshold is relaxed and no unbounded frame trace is
  retained. Local Ubuntu-proot validation: targeted profile report suite PASS
  (99 tests); targeted analysis PASS (`No issues found`).
- Required next evidence: rerun the exact profile with the p95 schema now
  present; only then classify actual p95/headroom. Existing baseline
  `288cc355...` profile failure remains inherited comparative evidence, not a
  green result. Physical validation remains `PENDING — USER ONLY`.

## 2026-09-15 — Actual Mind profile headroom result on `a0ccd9c` (FAILED)

- Exact run: Actions `35002536665`, profile job `104496048857`, source head
  `a0ccd9c9909e8613caaf702a64bc0842c122d87a`. Dashboard paths, `test-core`,
  `test-flutter` and the human diagnostic APK job PASS. The profile job ran
  its A–K gate from `17:44:03Z` through `18:05:00Z` and FAILED.
- The p95 schema correction is proven effective: the failure is now
  `Mind Year heatmap profile evidence frame_timing_headroom is invalid` at
  `validateMindYearHeatmapEvidence` line 208. The prior missing-p95 failure
  occurred at line 195. No FrameTiming threshold or interaction assertion was
  relaxed.
- The retained failed B response does not contain its report map because the
  validator throws before the harness stores B; therefore exact B p50/p95/max
  values remain MISSING EVIDENCE rather than invented. The available log and
  artifact do prove that at least one actual B p95 or missed-frame threshold
  failed. The same run's emulator reports repeated `EGL_emulation`
  app-time samples around `1.2–1.6 s`; host diagnostics show `-gpu swangle`.
  This is strong host/renderer correlation, not proof that all application
  contribution is zero.
- No further runtime change was made from this result: the trace also contains
  unrelated LogBox scene preparation outside the bounded Mind preview
  counters, so a production performance patch would be speculative without a
  source-correlated B frame report. Profile status remains FAILED, and final
  physical performance acceptance is not claimed.
- Delivery artifact from the successful human job:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_a0ccd9c.apk`,
  `82,498,865` bytes, SHA-256
  `79752a1a983cf3c595a60780577fe0f93c07dc459727f792cc04e5b9efb675d4`.
  APK integrity passed and arm64 `libapp.so` contains the full
  `a0ccd9c9909e8613caaf702a64bc0842c122d87a` marker. Physical validation:
  `PENDING — USER ONLY`.

## 2026-09-15 — Bounded dual Mind direction row-resource readiness (`e62a8172`)

- Application commit: `e62a8172` (`fix(mind): prewarm both direction row
  resources`). This follows the Summary Time / transient Mind Year repair and
  addresses the still-failing delivery profile boundary; it is not a physical
  device-acceptance claim.
- RED `MIND-LIVE-RESOURCE-01` proved the first owner mismatch: Core had two
  bounded direction-specific Mind prepared bases, but its one
  `mindAmountPreview` live-resource slot/lane warmed only Income. Expense
  therefore had an admitted base but no Phase-A paragraph bank, allowing the
  first measured direction tap to begin the source-membership rich LogBox
  preparation. This agrees with the failed profile's 1,846/2,458-row resource
  preparation evidence; it does not attribute the observed 126.620 ms slice
  to an unmeasured individual lease instruction.
- Repair: `DashboardCoreController` now asks the existing bounded
  `DashboardLogBoxPreparedSceneCache` for one distinct Mind resource lane per
  ledger direction (`mindIncomeAmountPreview` /
  `mindExpenseAmountPreview`) after each compatible base is admitted. Core
  remains the only request coordinator; the cache remains the only paragraph
  owner. Canonical Query, direction authority, viewport/renderer ownership,
  Time motion, controller/ScrollPosition/physics identity and heatmap
  ownership are unchanged. The cache's existing hard bank/row/byte admission
  limits remain in force; no unbounded cache, remount, key, cache flush,
  retry, delay, repository access or index build is added to a direction tap.
- GREEN evidence in Ubuntu proot: the Core RED now sees both direction lanes;
  cache test `MIND-LIVE-RESOURCE-01` retains both complete immutable banks
  simultaneously. Targeted `flutter analyze` returned `No issues found`; the
  Core/cache/Mind/LogBox/Summary regression matrix passed 212 tests.
- Still pending: online `run-dashboard-profile` on this exact application
  SHA, its FrameTiming/resource counters, final matching SCIP, human APK and
  physical validation. The previous profile failure is not reclassified as
  green by this commit.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-15 — Summary Time rebase and Mind Year transient-publication repair

- Application commit: `9945d6e9d4cfc3b948f85e724d18c2925fd975e2`
  (`fix(summary,mind): align pointer rebase and heatmap year`). This entry is
  evidence-led local repair evidence, not device acceptance.
- Frozen evidence remains the same physical session
  `fluvi-1789452354097594`, build `profile/288cc35584ec`: Drive Time document
  `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, revision 51,
  SHA-256 `08c630714ed985a7d646a368ac70b7b0b7f4e80a5e9593d62e6e12aeabd1b594`;
  and Mind document `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, revision 3,
  SHA-256 `2c4ab4c366e0ba884dd8a48d0597f82eabf3f81e1408bb6d6289e362fadd1605`.
- Structuring Apps gate: `structuring-apps` at
  `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
  (local skill; no version metadata) was read and applied. The repair keeps
  one semantic Time/Query authority in Core/navigation, UI as renderer/intent
  forwarder, and the existing carousel controller as sole physical motion
  owner. It adds no duplicate Year/query authority, remount/key workaround,
  controller/ScrollPosition/physics replacement, timer or cache flush.
- Time RED→GREEN: mounted `TIME-01` reproduced semantic origin 2024 with raw
  carousel logical offset `-4.0678` and first replacement candidate 2019.
  The first proven owner is the missing physical/logical rebase after Core
  accepts a direct-pointer preemption. The selector now invokes the existing
  `interruptAndJumpToIndexSilently(0)` immediately after Core preemption;
  this retains controller, ScrollPosition and physics identity and makes the
  first replacement candidate the local 2023 target. The mounted
  CoreDashboard identity test covers the same transaction.
- Mind RED→GREEN: mounted `MYTP-01` previously painted Summary Year 2025
  while the heatmap identity was 2026. A post-frame renderer acknowledgement
  now reaches `DashboardCoreController`, which publishes only the latest
  accepted painted Year with its existing interaction generation from the
  existing bounded prepared base. Canonical callers retain epoch zero after
  settle; held range previews preserve only their exact active identity. A
  coalesced 2025→2023 sequence produces no stale 2024 heatmap paint.
- Mind hot path: annual ordinal/day/amount contribution membership is created
  and evicted with the existing two-direction prepared-base slots. Transient
  Year publication uses that immutable membership; `MYTP-01` records
  `sourceRows=0` and one prepared contribution. `MYHP-15` proves an unprimed
  slider rejects fail-closed rather than lazily admitting a base or scanning
  source entries. A previously failing Phase-A preview test was corrected to
  explicitly prewarm the base it calls resident.
- Local validation in Ubuntu proot: `flutter analyze` over all ten changed
  source/test files — PASS, no issues; focused Summary/Core/Mind/debug suite
  — PASS, 152 tests; complete
  `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
  — PASS, 73 tests. A prior full-repository local run had unrelated Header
  golden/ticker and scroll-milestone failures and is not represented as green.
- Baseline classification remains factual: Actions run `34859925658` at
  `288cc355...` has successful core/flutter/path/human-APK jobs but failed
  dashboard profile due Mind FrameTiming rejection (average 40.341 ms,
  p90 102.517 ms, p99/worst 301.913 ms, 15 missed frames). It is not called a
  green baseline.
- Still pending after this application commit: online CI/profile evidence,
  final matching SCIP provenance, human diagnostic APK/hash and physical
  device acceptance. A historical bisect has not established whether
  `288cc355...` introduced the Time recurrence.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-15 — Delivery and profile classification for `9945d6e9...`

- Application repair commit: `9945d6e9d4cfc3b948f85e724d18c2925fd975e2`
  (`fix(summary,mind): align pointer rebase and heatmap year`). Its separate
  local-evidence journal commit is `6174cee7d7b6cc3c5af3ea1c4edf5296d77eb180`.
  The CI-only follow-up `7645789ec9c01da627d6c41b0cabeb3d3b30c7df` supplies
  `platform-tools` to `android-actions/setup-android@v3`: the original new
  run `34985737430` stopped before tests because its removed default `tools`
  SDK package could not be found. This changes no Flutter/Android runtime
  source.
- Final matching SCIP for the application repair was generated with
  `scip_dart 1.6.2`: source head `9945d6e9d4cfc3b948f85e724d18c2925fd975e2`,
  raw SHA-256 `556b3c5a214ddeb935dbb64e5f17daa8a52f78d92f97dc63a8b6fdf2fd2d102d`,
  445 documents, 291,643 occurrences, 10,251 repository symbols and 74,980
  references. Generated tooling commit: `b15f37bf0eb023cae82481a1ad39b1c6f589bb6c`
  on `tooling/scip-codegraph-v1`.
- Corrected Actions run `34986214585` reached the application checks:
  `dashboard paths`, `test-core`, `test-flutter`, and `human diagnostic APK`
  succeeded. The normal APK was downloaded to
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_7645789.apk`;
  size `82,498,865` bytes, SHA-256
  `98c6a5f7b99bb042f667fd389b7f222c8a01e1053854baaa038ff932385f492e`.
  Its arm64 `libapp.so` contains the complete build SHA
  `7645789ec9c01da627d6c41b0cabeb3d3b30c7df`.
- `run-dashboard-profile` in that same run FAILED at
  `DashboardProfileReport.validateMindYearHeatmapEvidence`, not because of
  the annual projection compute: its rejected FrameTiming sample reports
  average build `58.534 ms`, p90 build `152.947 ms`, p99/worst build
  `341.451 ms`, 30 missed build frames, average raster `1023.047 ms`, p90
  raster `1141.376 ms`, p99/worst raster `1326.925 ms`. The profile gate
  requires p95 below `12 ms` and at most one miss, so this is an explicit
  failed performance gate and is not called green.
- Artifact comparison is factual but non-causal: baseline run `34859925658`
  on `288cc355...` also failed the same gate (average build `40.341 ms`, p90
  `102.517 ms`, p99/worst `301.913 ms`, 15 misses). Both B-scenario logs
  contain pre-existing direction/live-resource LogBox scene preparation for
  1,846 and 2,458 rows. In the new run such preparations include UI slices up
  to `126.620 ms`; the repair's renderer-acknowledged transient-Year method
  only installs the already-admitted Mind projection and has no scene-preparer
  call. This excludes treating the profile failure as evidence that the
  transient Year hand-off directly starts rich LogBox work, but does NOT prove
  that the repair is performance-neutral: emulator variance and the worse
  aggregate sample leave that question unproven.
- Local repair evidence remains PASS: targeted analysis had no issues;
  focused Summary/Core/Mind/debug tests passed 152 tests; full
  `dashboard_core_ephemeral_focus_test.dart` passed 73 tests. The separate
  profile performance gate remains FAILED and needs a source-proven,
  scope-approved LogBox/resource performance repair or stronger reproducible
  causality evidence before overall delivery can be called complete.
- Physical validation remains: `PENDING — USER ONLY`.

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

## 2026-09-16 — Physical Mind Year blank heatmap after settling on 2025: stale retained transient year resurrection

- Feedback time: 2026-09-16 05:37 Europe/Budapest. User reports Summary Time now looks good and only the Mind heatmap log was refreshed. Current repair scope is Mind Year heatmap lifecycle only; Time remains a protected no-regression surface unless new evidence proves otherwise.
- Screenshot evidence: Mind + Year + Income visibly shows Summary year `2025` and `7,833,000.00 Ft`, while the annual heatmap day cells remain neutral/gray at the full visible amount range (`Min. 1,000 Ft`, `Max. 626,000 Ft`). This is a cross-surface identity failure, not accepted eventual consistency.
- Fresh Drive source: `Fluvi mind heatmap`, document ID `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`. Frozen plain-text export is 298,415 bytes, 1,001 lines, SHA-256 `a75f08ee38783a27fe6ea7364de8d7b42d252c7e4ed6f15a554dabe52297259d`; session `fluvi-1789529602106929`; retained sequence `750–1749`, exactly 1,000 unique contiguous events with no gaps or duplicates. Startup/build-marker events were evicted before sequence 750, so the exact physical APK/source SHA is MISSING EVIDENCE and no current Git SHA may be called exact-tested from this snapshot.
- The screenshot amount is independently present in the fresh trace. At seq `995–1001`, Income Year 2025 binds 12 nonzero rhythm bars, numerator/actual `783300000` scaled100, and accepts `income|year:2025`. Seq `1011` then records `SUMMARY_TARGET_PAINTED` for Year 2025 with nonempty payload. `TM|FLIGHT_SUMMARY` seq `1019` ends with `canonicalSettleCommits=1` and zero settle visual deltas. This supports the user's statement that the visible Time target is behaving correctly in this reproduction.
- PROVEN: this is not an empty-data year and not a projection-compute inability. A correct Income 2025 heatmap projection is built at seq `1223–1227` with `preparedContributions=1804`, `matchingRows=1846`; a later correct Income 2025 build at seq `1597–1601` again has `preparedContributions=1804`. Expense 2025 also has resident nonzero projection data. Therefore the gray screenshot cannot be explained by "2025 has no matching data".
- PROVEN stale overwrite: after the correct/current 2025 surfaces are present, seq `1266–1275` resolves, builds, publishes and paints **year 2027** with `cause=summaryVisualTransientYearRetained`, `temporalGeneration=4`, `preparedContributions=0`, `coloredDays=0`, while concurrent `LOGBOX_SCENE_SELECTED` remains `income|year:2025`. The same stale resurrection repeats at seq `1636–1644`: a correct 2025 projection was just published at seq `1597–1601`, then retained transient 2027 is reinstalled and painted empty. This directly matches the screenshot symptom: Summary/LogBox own 2025 while heatmap has been overwritten by stale retained 2027.
- The prior 2026-09-15 pre-identity-lag defect is NOT the current bottleneck. Fresh transient-year samples for 2024/2023/2027 resolve identity and build/publish immediately in microseconds when the renderer-acknowledged path fires. The failure now is lifecycle/ownership after final settle, not slow projection calculation.
- Matching current source explains the resurrection boundary. `DashboardCoreController.ensureMindYearHeatmapProjection()` gives `_currentMindYearHeatmapVisualTemporalTarget(...)` precedence over canonical `state.yearCursor`, and classifies that path as `summaryVisualTransientYearRetained`. The retained target validity check is direction/Year-component/plane based; it does not by itself require that the retained year/generation still agrees with a later canonical final settle. `noteSegmentedSummaryComponentVisualTargetPainted(...)` retains the accepted painted target after publication, while the settle path only clears the retained pointer when it is the identical target object. Fresh runtime evidence proves a stale 2027 target can therefore survive a final 2025 settle and be consumed by later non-amount/direction/refresh callers. Exact smallest invalidation boundary still requires RED proof before production mutation.
- PROVEN cause class: `STALE RENDERER-ACKNOWLEDGED TRANSIENT SUMMARY YEAR RETENTION OUTLIVES FINAL CANONICAL SETTLE AND IS LATER RE-APPLIED BY MIND HEATMAP REFRESH, OVERRIDING CORRECT 2025 WITH EMPTY 2027`.
- False-green gap: `9945d6e9...` fixed immediate transient Summary-year following and tested coalesced stale paint, but the physical loop shows the suite did not prove that a retained painted transient Z cannot survive a different final canonical Year Y and later be resurrected by `ensureMindYearHeatmapProjection()` / direction/focus/presentation refresh. A mounted production-parent RED must reproduce transient 2027 -> final canonical/painted 2025 -> later refresh -> stale 2027 reinstall.
- Commit/source audit: application commit `9945d6e9d4cfc3b948f85e724d18c2925fd975e2` introduced the renderer-acknowledged transient Mind Year retention mechanism. `e62a817232121aa7023f4946aeacf6cc4111c82d` later changed bounded dual-direction row-resource readiness, not retained-Year ownership. Follow-ups `7ae82c56...`, `5aff50ea...`, `a0ccd9c9909e8613caaf702a64bc0842c122d87a`, and current `16fc92dd5d56a6c9a26b3dd848c4c97b3ce755b1` are test/profile/docs lineage; `16fc92d...` is journal-only over `a0ccd9c...`. Do not infer the exact physical APK from branch chronology because the fresh startup marker is absent.
- Matching graph: tooling branch `tooling/scip-codegraph-v1` at `baadaa49ac1b835e95f6b27f699c91bbd9c56a3f` indexes source head `a0ccd9c9909e8613caaf702a64bc0842c122d87a` with `scip_dart=1.6.2`, raw index SHA-256 `0cd32af38f771fc79f09764920d00643160499c3b3d2bb201a6427f9e0e58a4`, 448 documents, 290,834 occurrences, 10,247 repository symbols and 74,695 references. Because the current application branch differs from `a0ccd9c...` only by the docs-only `16fc92d...`, this graph matches the current application source for shared-symbol impact; regenerate again for the final repair SHA.
- Current CI/profile status remains factual: `a0ccd9c...` core/flutter/human-APK paths pass, but Actions `35002536665` profile job `104496048857` fails `Mind Year heatmap profile evidence frame_timing_headroom is invalid`. Do not weaken that gate or conflate host/renderer performance evidence with this correctness failure.
- Required repair contract: renderer-acknowledged transient Year may override canonical Year only while that visual target belongs to the still-current/unsettled interaction generation. Once final canonical Year Y settles/owns the presentation, any retained transient Z != Y must be invalidated/demoted at the authoritative lifecycle boundary and the heatmap reconciled to Y in the same visible transition or next frame. A later direction/focus/query/amount/presentation refresh must never resurrect Z. Preserve active held-slider identity, latest-wins stale rejection, bounded resident data, and the fast transient-year following behavior added by `9945d6e9...`.
- Forbidden workaround loop: no delay/debounce/cooldown, no remount/key/cache flush, no Room/repository/index rebuild per Year/slider event, no second Year authority, no blanket "always use canonical year" regression that removes legitimate renderer-acknowledged transient following, and no broad Time/carousel rewrite. User reports Time currently looks good; preserve its controller/ScrollPosition/physics identities and existing direct-pointer rebase repair.
- PROVEN: physical 2025/nonzero-summary vs gray heatmap mismatch; fresh contiguous Mind log; correct 2025 resident projection data; stale `summaryVisualTransientYearRetained` 2027 with zero contributions overwriting 2025 twice; current source precedence that allows retained visual target over canonical year; application commit introducing that mechanism; matching current-source SCIP.
- UNPROVEN: exact physical APK/source SHA; why the final 2025 renderer acknowledgement did not replace the old retained 2027 in this precise interaction (callback absence, generation rejection, or another lifecycle condition); smallest correct invalidation/demotion line(s); final performance and device acceptance.
- MISSING EVIDENCE: mounted production-parent stale-retention RED with visual target/canonical generation/object identity; final matching SCIP/APK/hash; user physical revalidation.
- Prompt-writer change for this feedback: this journal entry only, committed with `[skip ci]`; no application source, test, workflow, graph, milestone file, build configuration or runtime behavior is changed by the prompt writer.
- Physical validation of the next application repair: `PENDING — USER ONLY`.

## 2026-09-16 — Retained Mind Year lifecycle repair (`31f2f146`)

- Application commit: `31f2f146249cf247284697bb3c193010eaccd00a`
  (`fix(mind): retire stale retained Year on settle`). It changes only the
  terminal Mind-Year target-authority lifecycle, its mounted regression test,
  and the required architecture/checklist evidence; it does not alter Time
  carousel motion, controller/ScrollPosition/physics, canonical Query,
  prepared bases, projection computation, LogBox, slider or renderer owners.
- RED `MYRL-01` mounts the real CoreDashboard and segmented Year selector,
  publishes/renderer-acknowledges transient 2027, settles a distinct canonical
  2025 target through the production settle path, then calls the shared Core
  heatmap refresh entry point. On the unmodified parent it failed with
  expected `2025`, actual `2027`.
- First proven owner: `_settleAcceptedExperimentalTemporalComponentCandidate`
  cleared `_mindYearHeatmapVisualTemporalTarget` only under `identical(...)`.
  A distinct final 2025 target consequently could not demote the retained 2027
  object, which remained eligible for
  `summaryVisualTransientYearRetained` selection on a later refresh.
- Repair: a terminal Year/Year-plane settle now demotes that retained visual
  target regardless of object identity. A currently held amount-range identity
  remains separately owned; current painted transient following remains before
  settlement. No cache/remount/delay/repository/index workaround was added.
- GREEN evidence in Ubuntu proot: `MYRL-01` plus `MYTP-01` PASS; complete
  `dashboard_core_ephemeral_focus_test.dart` PASS (75 tests); direct Mind
  projection/live and CoreDashboard matrix PASS (41 tests); changed Dart
  analysis PASS (`No issues found`).
- Matching pre-repair SCIP source audit used tooling
  `baadaa49ac1b835e95f6b27f699c91bbd9c56a3f`; its manifest source head is
  `a0ccd9c9909e8613caaf702a64bc0842c122d87a`, which still matches the
  application source prior to this commit. The manifest's actual recorded raw
  index SHA-256 is `9b375a9f012f5d51a984935b5b163ebcb061e02f4a058fbcb662d359ce789b8f`;
  this differs from the handoff's quoted hash and is reported rather than
  silently treated as identical. Final matching SCIP is still required.
- Known limits: startup marker eviction still leaves the exact physical APK
  SHA unknown. Online CI/profile/human APK/final graph and user device
  validation remain pending; the prior profile headroom failure is not called
  green.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-16 — Mind Year realtime correctness and liveness contract (`c2e35c8f`)

- Validation-only commit: `c2e35c8f` (`test(mind): enforce realtime Year
  heatmap contract`) changes tests and acceptance/architecture/plan evidence;
  it makes **no production runtime change**. The application repair remains
  `31f2f146`.
- Product boundary clarified: stale retained `2027 -> 2025` lifecycle GREEN is
  not completion by itself. Every Year that Summary actually paints must have
  the same Mind identity in that transition and an actual annual heatmap paint
  in the same or immediately following render frame. A coalesced never-painted
  target is not owed a heatmap publication, but it may never later paint.
- New mounted `MYRT-01` uses the actual CoreDashboard, segmented Year selector
  and annual viewport with distinct 2026→2025→2024→2023 Income data. It checks
  actual Summary paint, exact Mind identity/G1, and actual
  `MIND_HEATMAP|PAINTED` with at most one additional frame; it also proves the
  held slider retains exact 2023/G1, the terminal canonical 2023/G0 paints,
  and a later Core refresh cannot restore retained transient authority.
- New mounted `MYRT-02` drives a real 1,500 px/s ballistic Year fling with the
  input sequence deliberately frame-free. On subsequent visible ballistic
  frames it requires each Summary-painted Year to obtain actual Mind paint in
  the same or next frame, rejects a transient Mind paint for any unpainted or
  coalesced Summary Year, and retains zero source-row/repository work bounds.
  This is a frame contract, not a pump-until-idle eventual-consistency test.
- Hot-path proof: for every direct transient target,
  `SUMMARY_COMPONENT_PREPARED_PUBLICATION` reports `repositoryCalls=0`,
  `indexBuilds=0`, `scenePrepares=0`; the Mind frame reports `sourceRows=0` and
  prepared contribution use. The mounted direct and ballistic paths retain one
  repository prepare and zero raw source-row touches. The direct test also
  proves canonical year/query authority stays at 2026 until terminal settle.
- Ubuntu-proot GREEN evidence: full
  `dashboard_core_ephemeral_focus_test.dart` passes 77 tests; changed-file
  `flutter analyze` reports `No issues found`; Mind domain/viewport suite
  passes 19 tests; centered-carousel identity suite passes 15 tests; Summary
  direct-pointer-preemption suite passes 12 tests; Mind mode host passes 2
  tests. The protected Time carousel/controller/ScrollPosition/physics source
  remains untouched.
- Exact application CI audit: Actions run `35059233562` for `31f2f146` has
  `test-flutter`, `test-core`, dashboard-paths and human diagnostic APK jobs
  successful. `run-dashboard-profile` fails at
  `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`,
  then cannot complete the A–K report because
  `B_year_month_rail_populated` is absent. This existing profile evidence
  failure is **not green** and no threshold/gate was weakened. Final automated
  FrameTiming acceptance remains blocked pending a causal profile/instrument
  repair outside this proven runtime lifecycle boundary.
- The existing successful human APK for `31f2f146` is present at
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_31f2f14.apk`,
  size 82,498,865 bytes, SHA-256
  `40b0517da28f48f6faf185ced264d12ccd7b3537ee5a624b03bcb0b44fc5edff`.
  Its `libapp.so` contains the full `31f2f146249cf247284697bb3c193010eaccd00a`
  source marker.
- Still pending: final matching SCIP provenance after the final validation
  commit, honest resolution/classification of the null profile FrameTiming
  evidence, and user physical Android acceptance. The fresh physical log still
  cannot identify its previous APK SHA because startup markers were evicted.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-16 — Final Mind Year realtime SCIP provenance

- Final graph generation used the clean canonical application/validation source
  head `2645114242ceda04326a88073e27dc5bcd4b7a8c`; later branch commits in this
  cycle are documentation-only and do not change application runtime source.
  The graph's source parent is `c2e35c8fb42452b60386316f15cc3571ef473dae` and
  source ref is `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.
- A separate temporary index was generated with `scip_dart 1.6.2` using
  `--output` outside the repository, so the pre-existing untracked
  application `index.scip` remained untouched. Final index SHA-256:
  `1b46fee4310f996bd9d88efb6567c718e00c3c8c9eab5b23de137414f6fc34f6`.
- Generated manifest: 448 documents, 292,834 occurrences, 40,591 defined
  symbols, 10,258 repository-defined symbols and 75,293 references. The
  tooling artifact commit is `74ba06ee5b0e04b415c8ca11f213a0e1faa0b48a` on
  `tooling/scip-codegraph-v1`, pushed separately from application history.
- Tooling `dart test` passes 15 tests. Source-verified graph queries resolve
  `ensureMindYearHeatmapProjection` (19 references: 4 production, 15 tests),
  `noteSegmentedSummaryComponentVisualTargetPainted` (2: 1 production, 1
  test), and `endSegmentedSummaryMotion` (3: 1 production, 2 tests). The
  result remains graph navigation/impact evidence, not runtime causality.
- The final application-side checklist delivery entries are recorded in
  docs-only `0e31072f`, followed by this journal-only `[skip ci]` entry. The
  null `frame_timing_headroom` profile failure remains an honest automated
  performance blocker; no runtime source, timing threshold or profile gate is
  changed here.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-16 — Populated Mind Year prepared-payload admission (`f5e483c2`)

- Application commit: `f5e483c2` (`fix(mind): publish populated Year heatmap
  with list paint`), parent `fa6b1640322a4a6131e3531a3aa2f2824987f297`.
  This is the first repair for the physical **populated payload** liveness
  gap; it does not change Time carousel/controller/ScrollPosition/physics,
  canonical Query ownership, rich LogBox rendering, slider, calendar or Mind
  direction-base architecture.
- Fresh physical evidence was frozen from Google Doc `Fluvi mind heatmap`, ID
  `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified
  `2026-09-16T13:46:32.002Z`: 323,737 bytes, SHA-256
  `58b10f7256864db39055dfd3eeca2669e40f6423de6adc14eed437d47ba663ee`,
  session `fluvi-1789566368119437`, retained sequences `1200–2199`, 1,000
  unique contiguous events with no gap. The startup build marker had already
  been evicted, so the exact prior physical APK source SHA remains unknown.
- The trace and screenshot prove Income 2026 Summary/list payload is ready
  while MonthCards are gray: Summary/list paint around `42,165,415` /
  `42,165,432` microseconds, while the first 42-contribution heatmap frame
  publishes at `43,497,426` and paints at `43,509,978`; a second sample has
  the same roughly 1.3-second gap. Projection work itself is only 93–180 µs.
- New mounted current-parent RED `MYPL-01` seeds a real prepared Income 2026
  list package (visible count 42) with exact colored dates Jan 4, Feb 18 and
  Dec 29, plus empty 2027. Before this repair, the populated target reached
  `LIVE_INTERACTION_ACCEPTED`, `SUMMARY_TARGET_PAINTED` and nonzero
  `LOGBOX|VISIBLE_ROWS_BOUND`, but the previous empty heatmap remained after
  its only allowed next frame. No
  `MIND_HEATMAP|SUMMARY_VISUAL_TARGET_ADMISSION` was emitted for that target.
- First proven owner: a populated Year can start
  `TIME_PHASE_A_CANDIDATE_PENDING` and only later be promoted exact by
  `_promotePendingSegmentedTimePhaseACandidate`. That late Phase-A acceptance
  does not re-enter the selector's renderer callback, even though the same
  accepted Year/G has already painted Summary and the lightweight list. The
  renderer callback alone therefore created an empty-vs-populated false green.
- Repair: `DashboardCoreController._recordSegmentedTargetPaint` now admits
  the compact annual frame through the same existing Core helper only when
  the normal renderer acknowledgement has not already admitted the identical
  accepted target. The helper uses the existing bounded prepared base/annual
  membership, Year/G and stale guards; it reads no LogBox rich scene, text
  layout, repository, Room, index build or raw ledger row. It does not create
  a second Year/data authority. A bounded safe admission diagnostic records
  only Year/generation/result.
- GREEN evidence in Ubuntu proot: current-parent RED-to-GREEN MYPL-01 PASS;
  full `dashboard_core_ephemeral_focus_test.dart` PASS (78 tests); the Mind
  projection/live/viewport, Mind host, Summary and LogBox focused suite PASS
  (75 tests); profile-report/seed-contract suite PASS (102 tests); changed
  Dart file analysis PASS (`No issues found`). MYPL-01 repeats populated →
  empty → populated three times before release assertions and requires actual
  `MIND_HEATMAP|PAINTED year=2026 coloredDays=3`. Existing ballistic MYRT-02
  now asserts each painted Year’s exact populated/empty colored-day payload,
  not merely its identity. One attempted two-name `--plain-name` command
  selected no tests (exit 79); it was a CLI selection error and was replaced
  by individual and full actual runs.
- Work bounds: the mounted direct/repeated path retains one repository
  prepare and zero Mind source-row touches. It exercises only resident
  immutable prepared membership; no settle-only wait, target dropping,
  debounce, remount/key or cache-flush workaround exists.
- Structuring Apps skill read: `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
  (no version metadata). The repair preserves one Core write path, UI
  render/intent-only boundaries, shared prepared-data reuse and fail-closed
  cross-surface tests. Architecture/checklist/plan evidence is included in
  the application commit.
- Still pending: final matching SCIP for `f5e483c2`, exact Actions status and
  human APK/hash, and physical Android validation. The historical
  software-rendered `frame_timing_headroom` profile evidence failure remains
  separate and is not called green or weakened here.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-16 — Populated Mind Year repair delivery evidence

- Canonical branch application repair `f5e483c2c97e55fb4675c27191ff5d337cd78975`
  and its prior journal-only evidence commit `ae9678941ff044b693f7aa6fc39acd80bae05ce0`
  are pushed to `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.
- Explicit GitHub Actions dispatch was required because no automatic push run
  appeared during the observed wait. `Fluvi Verification` run `35114517631`
  ran the branch tip `ae967894...` (which contains the `f5e483c2` runtime
  repair plus journal only). `dashboard-paths`, `test-core`, `test-flutter`
  and `build-human-diagnostic-apk` are PASS; nightly/baseline lanes are
  skipped as configured.
- The normal human diagnostic APK is released and downloaded locally at
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_ae96789.apk`.
  It is 82,498,865 bytes with SHA-256
  `08d91fcb9d34678297f12c9c947e1960f762203827bcd269b8440923d2242229`.
  The APK's `lib/arm64-v8a/libapp.so` contains full source marker
  `ae9678941ff044b693f7aa6fc39acd80bae05ce0`; the immediately preceding
  application-code commit is `f5e483c2...`.
- Final matching SCIP was generated from the clean canonical source head
  `ae967894...` with `scip_dart 1.6.2`, without changing the pre-existing
  untracked application `index.scip`. Raw final index SHA-256 is
  `f565ef23fb7b23c45eca156e434ac70736dfe4b9e6c834ba7ee648ff8b00d821`;
  manifest counts are 448 documents, 293,393 occurrences, 40,625 defined
  symbols, 10,260 repository symbols and 75,441 refs. Tooling graph commit
  `4e6c5f4e29363e200601cf913e80c7dcde73d07c` is pushed separately on
  `tooling/scip-codegraph-v1`; its 15 tooling tests pass. Source-verified
  queries resolve `ensureMindYearHeatmapProjection` (20 refs: 4 production,
  16 tests) and `noteSegmentedSummaryComponentVisualTargetPainted` (2 refs:
  1 production, 1 test). Graph is navigation evidence, not runtime causality.
- The automated profile job is NOT green: job `104858666696` in run
  `35114517631` fails at `DashboardProfileReport.validateMindYearHeatmapEvidence`
  (`integration_test/support/dashboard_profile_report.dart:151`) because
  `frame_timing_headroom` is `null`; downstream complete-suite validation then
  reports `B_year_month_rail_populated` missing. This is the same established
  failure class recorded for the pre-repair `31f2f146` run, and this repair
  changed neither profile instrumentation nor Time/renderer pacing policy.
  It remains an honest automated performance blocker, not a passing result
  and not grounds for a speculative unrelated performance patch.
- Final checklist is therefore delivery PARTIAL: source, focused regressions,
  human APK and final graph are delivered; profile FrameTiming evidence and
  physical Android acceptance remain unresolved.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-17 — Mind behavioral score and live Header palette delivery (`06fe576a`)

- Application commit: `06fe576ae6e916116f94fdbb3fe27a75b3c1a005`
  (`feat(mind): add behavioral score header palette`) on
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`; its application
  parent is the approved HTML-prototype commit
  `91777be7de7f3138e9aef2146747007a4f75b9aa`. The feature adds a prepared,
  immutable daily score projection and generation-checked live publication;
  it retains the canonical inclusive two-ended `QueryAmountRange` as the
  membership authority.
- Expense is causal: sparse `<=12` active days use the approved amount-only
  score; dense activity uses trailing 31-day occurrence/amount signals,
  dynamic EMA and a causal running-maximum normalization. Income uses the
  approved daily trend comparison with the last one-to-three meaningful prior
  samples, median baseline, capped adjustment and explicit `noSignal` state.
  The architecture exposes one daily series for Day/Month/Year/Sum; no hourly
  Day path and no second query/filter state were introduced.
- Header delivery: `x/100` is semantic header content, while an independent
  Mind policy feeds the pre-existing shared Header visual controller with a
  score-centred seven-anchor traffic-light window. The existing controller is
  still the only Header ticker. The existing tuner has a separate 10–100%
  Mind `Ablakszélesség` state (default 28%); it does not alias Budget state or
  alter score mathematics.
- Local Ubuntu-proot evidence: score domain/live/header/profile tests pass
  (125 tests); production Core range/direction/focus and visible-rail score
  tests pass; Mind tuner/host tests pass; protected Mind heatmap and canonical
  amount-range tests pass (21 tests). Two changed-file `flutter analyze`
  groups report `No issues found`; `dart format --output=none
  --set-exit-if-changed` changed zero files; `git diff --check` passed.
- Exact GitHub Actions evidence: run `35155897610` for `06fe576a` has
  `dashboard-paths`, `test-core`, `test-flutter` and
  `build-human-diagnostic-apk` PASS. The normal human diagnostic APK release
  targets exactly `06fe576a` and is downloaded at
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_06fe576.apk`;
  size 82,777,393 bytes, SHA-256
  `488341f7afd687f33f8a2730d7bae7c338208db5e99282a834a441909e4f0f7f`.
- The same run's `run-dashboard-profile` job `104996781694` is FAIL, before
  score-specific evidence is evaluated: `Mind Year heatmap profile evidence
  frame_timing_headroom is invalid: null`, followed by the expected missing
  `B_year_month_rail_populated` report. This is the established inherited
  null-FrameTiming failure recorded for the preceding source lineage. No
  threshold/profile weakening or speculative unrelated performance change was
  made; it remains an automated performance blocker.
- Final matching SCIP was generated in an isolated clean worktree from
  `06fe576a` using `scip_dart 1.6.2`; the pre-existing untracked application
  `index.scip` was preserved. Raw index SHA-256 is
  `7b1ef7b6b494b3613822178edd58f0b44e541046c5d300237269db70b970b3d8`.
  The manifest records source parent `91777be7...`, 451 documents, 297,994
  occurrences, 10,407 repository symbols and 76,771 references. Tooling
  commit `6c113674` on `tooling/scip-codegraph-v1` is pushed separately;
  tooling `dart test` passes 15 tests and the source-verified
  `MindBehavioralScoreProjection` query resolves 11 production and 16 test
  references. The graph is navigation evidence, not runtime causality.
- Delivery status is PARTIAL solely for the inherited Android profile gate and
  physical acceptance. Physical validation: `PENDING — USER ONLY`.

## 2026-09-17 — Expanded Mind Header score-history chart delivery (`505e6873`)

- Application commit: `505e6873b5c10e0bdfa64c1a00a4d75fdeb584da`
  (`feat(mind): add expanded score history header chart`) on
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`. The strict
  visual authority was inspected directly at
  `/storage/emulated/0/spendee/mind score Reference .png` (941×1663). The
  implementation retains its 378×126 logical header composition: the semantic
  score is at `(16,16)`, and the chart plot is `(16,48,346×60)`.
- The chart is a Mind-only expanded-header layer. It is clipped directly by
  the existing expansion progress, receives no independent entrance motion,
  ticker, animation controller, query authority, or financial calculation,
  and is `IgnorePointer`/repaint-boundary isolated. Its painter supplies the
  reference's thin white smoothed line, outlined endpoint, subtle dashed guide
  and transparent white area fade. The score value remains semantic content;
  the existing shared Header visual controller remains the sole ticker owner.
- A resident immutable score chart series is published atomically with the
  selected score frame. Expense points reuse the causal daily score path.
  Income series construction has one chronological resident index pass with a
  running median and prior-three-sample state, avoiding repeated historical
  scans. Sum begins at the first eligible day; Day/Month/Year use their
  canonical scoped start, so the graph preserves the same daily point
  semantics without creating a graph-specific score model.
- A build-side notification was source-isolated during validation:
  `_MindQueryAmountRangeBinding.build` previously synchronously called score
  projection publication through `_mindQueryAmountRange`, which could mark
  the Header dirty while its ancestor was building. That build-side call was
  removed; the already-existing semantic scope routes and post-build initial
  prime remain the sole publishers. No timer, debounce or deferred score
  semantics were introduced.
- Visual evidence: the focused golden test renders the 378×126 chart card,
  and the generated image was inspected against the device reference for
  top-left score placement, plot bounds, thin line/endpoint, guide, soft
  white under-line fade and continuous expansion clipping. Human device
  visual acceptance remains separate below.
- PASS — Ubuntu/proot focused Core regression suite:
  `flutter test --no-pub test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
  (80 passing). PASS — focused domain/presentation/protected suite covering
  score series, chart component/boundary/golden, host, Header visual engine,
  tuner, heatmap and canonical range:
  `flutter test --no-pub <listed focused test files>` (109 passing). PASS —
  targeted changed-file analysis:
  `flutter analyze --no-pub <11 changed production/test targets>` — `No
  issues found!` (41.0s). PASS — `git diff --check` before commit.
- GitHub Actions run `35178660924` for exactly `505e6873` has `test-core`,
  `test-flutter`, `dashboard-paths`, and `build-human-diagnostic-apk` PASS.
  The normal human diagnostic APK was downloaded to
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_505e687.apk`;
  SHA-256 is
  `eeecca600e636de2583b3f4e15684510e69e69e092c6acc2622ca1a0a4dc1292`.
- FAIL — the same run's `run-dashboard-profile` job fails at the established
  inherited FrameTiming gate: `Mind Year heatmap profile evidence
  frame_timing_headroom is invalid: null` in
  `DashboardProfileReport.validateMindYearHeatmapEvidence`. The chart work did
  not modify that profile instrumentation or weaken its threshold; this is an
  honest automated-profile blocker, not a green performance result.
- Final matching SCIP was generated from the exact application SHA with
  `scip_dart 1.6.2`; raw index SHA-256 is
  `5b68ad2eae74206b3cbee795313b0cc47b2f0367f14f30f706b70e00f19db375`.
  Tooling graph commit
  `34b4a8578e1457d42a0c723936dc2238de4494b2`
  (`tooling/scip-codegraph-v1`) is pushed separately and its `dart test`
  passes all 15 tests. The graph is source-verified navigation evidence, not
  runtime causality.
- Delivery status: PARTIAL solely for the inherited automated profile gate
  and physical Android acceptance. Physical validation: `PENDING — USER ONLY`.

## 2026-09-17 — Mind adaptive range, exact 2027 Fastfood mirror and perceptual palette delivery (`9c8ac0c1`)

- Application feature commit: `9c8ac0c1adb37ac1fec3aac062b9f790159b350d`
  (`feat(mind): refine score scale and adaptive amount domain`) on
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`. Follow-up
  profile-fixture-only commits end at application/test source
  `e31f10edefe154139db78951642628f71ec6c1cf`; they do not change production
  Dashboard, Query, Budget, carousel, renderer, ticker, chart, score, or
  database runtime code.
- Adaptive range ownership remains canonical: `QueryAmountRange.domainScope`
  removes only its amount endpoints, and the native authoritative facet/domain
  aggregate publishes the non-amount-filtered maximum through the existing
  `CurrentQueryController` cache. A drag reuses that maximum; it cannot
  recursively contract its own physical domain or issue Room/repository/index
  work. The shared deterministic 1/2/5 monetary snap helper yields 2,000 Ft
  at 260,000 Ft, 1,000 Ft at 100,000 Ft, 200 Ft at 20,000 Ft and 50 Ft at
  5,000 Ft. The compact shared range control now puts the slider above its
  single `Összeg`/Min./Max. caption row while retaining preview/final parity.
- `FastfoodPrototype2025Rows` stores the exact executed f332b712 prototype
  output: 100 normalized 2025 rows, total 645,560 Ft, SHA-256
  `cd8ec0a6bb2e5558a11e3dddd7aa6a087d9edde897b13fceea1da4eb82e5a65e`.
  The deterministic real demo seed maps them to `Gyorsétterem` and its six
  real partners, changes only the year to 2027, increments the versioned seed
  manifest, and preserves idempotent normal Room/query behavior. The original
  2025 list is not regenerated or modified.
- Mind Header color is now the approved continuous eight-anchor scale:
  `#991B1B`/0, `#DC2626`/18, `#F04A24`/35, `#F97316`/48,
  `#FBBF24`/58, `#86D957`/70, `#4ADE80`/82 and `#15803D`/100. The prior
  encoded-sRGB interpolation was replaced by shared OKLab perceptual sampling;
  alpha remains owned by the Header. The existing independent Mind 10–100%
  window/tuner and Budget policy remain unchanged.
- The user-accepted expanded Mind Header chart source and reference geometry
  were not changed: it retains the upper-left semantic score, expanded-only
  clipping/reveal, thin white line, endpoint and white under-line fade, with
  the one shared Header controller/ticker.
- PASS — local Ubuntu/proot:
  `flutter test test/performance/dashboard_profile_report_test.dart` (99
  tests); focused range, palette, chart, score, heatmap, Core and demo suites
  passed during the feature increments; changed-target `flutter analyze`
  passed; `git diff --check` passed before commits. The local broad Flutter
  run still has its inherited 30-second scene-window timeout and is not
  represented as green.
- PASS — GitHub Actions run `35196364731` for exact `e31f10ed`:
  `test-flutter` (analysis + curated Flutter suite), `test-core` (clean Room
  core plus native dashboard bridge), `dashboard-paths` and
  `build-human-diagnostic-apk` all pass. The normal human diagnostic APK is
  downloaded at
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_e31f10e.apk`;
  size 82,859,313 bytes, SHA-256
  `e2f72729e46b5ab3482b73a4377555ce5dbd24c951780068dd71375b52181871`,
  with embedded source marker `e31f10edefe154139db78951642628f71ec6c1cf`.
- FAIL — the same run's 20:58 `run-dashboard-profile` reaches the established
  `DashboardProfileReport.validateMindYearHeatmapEvidence` rejection:
  `frame_timing_headroom is invalid: null`, then lacks the B report as a
  consequence. The Fastfood Avatar fixture recovery passed its prior failure
  point; this source does not change Mind heatmap FrameTiming instrumentation,
  thresholds, Time/Avatar physics, or renderer pacing. This inherited profile
  limitation remains an honest automated performance blocker.
- Final matching SCIP was generated from the clean exact application/test
  source `e31f10ed` using `scip_dart 1.6.2`. Raw index SHA-256 is
  `ab524e61ab8f6a215cffaeae6ffffa17f3ab47073c79708db129fd67f6c5688c`;
  the manifest records 457 documents, 300,334 occurrences, 41,525 defined
  symbols, 10,474 repository symbols and 77,226 refs. Tooling graph commit
  `e09fd00e036f485aeb0e9388f867fe65d3bd374b` is pushed separately on
  `tooling/scip-codegraph-v1`; its 15 tooling tests pass. The raw index stays
  ignored/uncommitted and graph output is source-navigation evidence only.
- Pre-existing unrelated untracked files, including the local `index.scip`,
  were preserved. Delivery is PARTIAL only for the inherited automated profile
  FrameTiming gate and physical device acceptance. Physical validation:
  `PENDING — USER ONLY`.

## 2026-09-17 — Mind visible-domain, four-column heatmap and chart-label delivery (`9a8a7575`)

- Application feature commit: `9a8a7575` (`feat(mind): fit annual heatmap and
  label score chart`) on
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`. It keeps the
  compact Mind range binding exact: a missing visible-scope domain no longer
  falls back to the broader canonical direction domain. Inactive-direction
  prewarming may still use resident canonical availability only to schedule
  work; it cannot supply a rendered slider maximum. This prevents an old
  all-time 260,000 Ft domain from being displayed for a narrower visible
  2027 scope.
- The mounted AMD regression covers an intentionally withheld exact domain,
  slider preview/commit, repeated Year and Sum transitions, and stale-domain
  rejection. Its expected 2027 Fastfood maximum is derived from the fixture
  (13,500 Ft), not hard-coded into production code.
- Mind Year presentation now includes a footer-aware 4 x 3 fit-to-viewport
  layout. It solves one shared square day-cell extent from available width and
  height, real calendar row counts, chrome and enabled footers; its annual
  layout is non-scrolling without nested/card scroll owners. Existing 2 x 6
  and 3 x 4 retain their original scroll path and controller.
- The accepted Header plot geometry (`16,48,346,60`), line, fade, endpoint,
  guide, expansion clipping and shared ticker remain unchanged. A separate
  chart-presentation owner defaults to hidden and can show exactly five quiet
  labels at the actual immutable series dates 0/25/50/75/100%; it makes no
  query or score calculation.
- Sum observation status is deliberately forensic, not a speculative renderer
  change. A new native test pages the real deterministic demo seed through
  the committed all-time query: its first 100 date-descending rows are
  expected 2027 Fastfood, then it must enter older years under the same
  all-time query identity. Local ARM64/proot could compile/start this lane
  only until the unavailable `conscrypt_openjdk_jni-linux-aarch_64` library;
  the clean GitHub `test-core` run is the pending evidence boundary.
- PASS — local Ubuntu/proot: focused range/heatmap/chart/tuner suites, the
  protected 149-test Flutter selection, all 84
  `dashboard_core_ephemeral_focus_test.dart` cases, changed-target
  `flutter analyze`, and `git diff --check`. NOT RUN locally: final native
  Sum execution (Termux/proot AAPT2/Conscrypt host limitation). Online
  verification was explicitly authorized before push. The inherited
  `frame_timing_headroom is invalid: null` profile evidence remains separate
  and is not declared green. Physical validation: `PENDING — USER ONLY`.

## 2026-09-17 — Mind online forensic / APK / graph evidence (`9a8a7575`)

- PASS — GitHub Actions run `35243573729` for the pushed branch head
  `d3b32d388623aac09ea2125e2d35b8dec627cc66`: `test-flutter` passed analysis
  plus the curated Flutter suite (2m35s), and `test-core` passed clean Room
  core plus native dashboard bridge tests (5m26s). This clean runner executes
  the Sum forensic that ARM64/proot could not host.
- The production-faithful deterministic Sum test proves **NO DEFECT**: an
  All-time expense query has one query identity; its first 100 newest
  date-descending rows are correctly the 2027 Fastfood mirror, and pagination
  then reaches earlier years. No LogBox list/query/paging production code was
  changed for the screenshot observation.
- PASS — human diagnostic release
  `fluvi_HUMAN_DIAGNOSTIC_d3b32d3.apk` was downloaded to
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_d3b32d3.apk`.
  It is 83,088,689 bytes and SHA-256
  `e40ecb26705c8a8a3a064ef65e1bd5fc5c69288e2b9fc1a02b84df81e8247da8`.
  Its source marker is the journal head `d3b32d38`; its application runtime
  source is the preceding `9a8a7575` commit.
- PASS — matching SCIP was generated from the clean exact application source
  `9a8a7575902288eebf8b95ae60c698be035531c4` with `scip_dart 1.6.2`. Raw
  index SHA-256 is
  `3159a7ce7bf41403360f8e2ff1a8f59e9553bbdf2f08ffa62370f484e85c008a`.
  The manifest records 467 documents and 307,195 occurrences. Tooling graph
  commit `0a67cb2e` is pushed separately on `tooling/scip-codegraph-v1`, and
  its 15 tooling tests pass. The graph is navigation evidence, not runtime
  causality.
- The workflow's unrelated `run-dashboard-profile` job is still in progress
  at this journal point; its established `frame_timing_headroom is invalid:
  null` lineage must remain an honest separate status. Physical validation:
  `PENDING — USER ONLY`.

## 2026-09-17 — Profile exact-visible-domain assertion evidence (`c67e7139`)

- `c67e713925150a058d1c9a3c85ce55a97af65693` changes only the dashboard
  integration profile assertion and its acceptance checklist; it makes no
  production runtime, Query, Mind, Heatmap, Header, seed, renderer or Android
  build-input change. The test now waits for
  `amountDomainForScope(mindAmountDomainScopeFor(opposite))`: the exact
  visible structural domain that `mindAmountRangeBindingFor` uses. The prior
  assertion waited for `amountDomainFor(opposite)`, an all-time canonical
  template that need not be admitted for the inactive visible scope.
- PASS — Ubuntu/proot
  `flutter analyze integration_test/dashboard_interaction_profile_test.dart`
  reports no issues, and `git diff --check` is clean.
- PASS — GitHub Actions run `35246447435`: `dashboard-paths` (11s),
  `test-flutter` (2m32s), `test-core` (5m47s), and the human diagnostic APK
  job (6m46s) succeed. The clean Core lane preserves the Sum **NO DEFECT**
  proof. The new exact-visible-domain assertion no longer stops the profile.
- FAIL — the same run's `run-dashboard-profile` job fails after 27m31s at the
  pre-existing `DashboardProfileReport.validateMindYearHeatmapEvidence` gate:
  `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`.
  The subsequent absent B report is a consequence of that validator failure.
  No threshold, profile instrumentation, Time/Avatar physics, or Mind
  production code was changed to mask it; this remains an honest inherited
  automated-performance blocker.
- PASS — SCIP was regenerated from exact `c67e7139` with `scip_dart 1.6.2`.
  Raw index SHA-256:
  `128070323a4a86bb72cd86148df7d7b8ff9b83d8c35cfc69dfb9de3051bd8434`.
  Tooling commit `1d9f1178` on `tooling/scip-codegraph-v1` is pushed; its
  manifest pins this source head and all 15 tooling tests pass. The raw index
  is ignored and the graph is navigation evidence, not runtime causality.
- The normal human artifact for the actual runtime application feature remains
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_d3b32d3.apk`
  (83,088,689 bytes; SHA-256
  `e40ecb26705c8a8a3a064ef65e1bd5fc5c69288e2b9fc1a02b84df81e8247da8`).
  `c67e7139` is test/checklist-only and does not change that runtime source.
- PASS — the exact `c67e7139` human diagnostic release was also downloaded
  to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_c67e713.apk`.
  It is 83,088,689 bytes and SHA-256
  `fbd1105599a013e3d2fc6061c513552cab70bc224374ce5c272151e2ac3c36c0`.
  Physical validation: `PENDING — USER ONLY`.

## 2026-09-18 — Mind temporal heatmaps and atomic score publication (`463222fa`)

- Application feature commit: `463222fa` (`feat(mind): unify temporal
  heatmaps and score publication`) on
  `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.
- Mind now has one Core-owned temporal heatmap coordinator over the existing
  immutable prepared membership: Sum publishes real filtered monthly buckets
  across all represented years; Year retains the mature daily calendar; Month
  publishes real daily buckets. Every range preview uses bounded bucket-local
  amount-prefix lookup rather than repository, Room, raw ledger rows or
  rendered LogBox data.
- Sum/Year/Month share one fixed Mind body footer: five resolver-owned palette
  swatches, then the one existing compact `Összeg` / Min. / Max. range control.
  The footer remains outside the temporal scroll owner. Year MonthCards now
  reserve six visual calendar rows; 4×3 gets the selected 50px Mind-body
  extension required to fit its three six-row groups and both optional footer
  rows without annual scrolling.
- The source-proven transient Summary Year score lag is fixed at the Core
  renderer-acknowledged admission boundary: heatmap and score/chart publish
  together. A mounted held-slider regression then exposed a separate
  Month→Sum→Year issue: the heatmap accepted the new range while the score
  preview rejected an obsolete drag identity. The repaired guard rebases only
  to an already-published current score target, preserving stale safety.
- PASS — Ubuntu/proot:
  `flutter test test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
  reports 91 tests green; focused Mind projection/viewport/palette/host/live
  tests report 44 green; Header chart/tuner/color/boundary tests report 26
  green; and `mind_header_score_chart_golden_test.dart` is green. A bounded
  diagnostic-profile run of the mounted held-slider test measured six score
  previews at p50=270µs, p95=max=4710µs, while source-row, repository and
  index-build preview counters remained zero.
- PASS — Ubuntu/proot: `flutter analyze` has no issues (135.2s) and
  `git diff --check` is clean before the application commit.
- NOT RUN locally —
  `./gradlew :fluvi-core:testDebugUnitTest --tests
  com.fluvi.core.query.FluviPreparedDashboardIndexTest.boundedYearWindowKeepsAllTimeTotalsButOmitsOutsidePeriodFrames --offline`
  reaches `:fluvi-core:processDebugUnitTestResources` but AAPT2 daemon startup
  fails before the test executes. The native all-time focus-membership
  regression must run on the clean online runner; it is not represented as
  locally green.
- The previously accepted Header line, fade, endpoint, plot bounds,
  expansion clip and single visual ticker are unchanged; the chart golden is
  green. No Time/Avatar physics, canonical Query owner, Budget state, LogBox
  paging/render owner, score mathematics or Fastfood fixture changed.
- Final online CI/APK/SCIP evidence remains pending after this journal-only
  commit. Physical validation: `PENDING — USER ONLY`.

## 2026-09-18 — Mind temporal gesture ownership repair (`434276ac`)

- The first final online workflow for the preceding delivery, run
  `35282348049` at source head `f5d74e04`, passed `test-flutter`, clean Room
  core tests, native dashboard bridge tests and the human diagnostic APK job.
  Its profile B integration lane failed at
  `_profileMindYearHeatmapSlider` because it found one
  `dashboard-core-mode-content-gesture-region` where temporal Mind content
  requires none. This is a real topology regression, not the inherited null
  FrameTiming profile issue.
- Root cause: the shared-footer refactor retained a passive outer
  `GestureDetector` around every Mind TimePlane to preserve the held slider.
  It preserved the slider but changed the mounted Year/Sum/Month hit-test
  topology.
- Repair: `DashboardCoreModeHost` now leaves Mind's surface invariant and
  hands the existing expansion callbacks to `MindDashboardCoreSurface` only
  for its non-temporal (Day) content slot. Sum/Year/Month contain no outer
  content gesture region, while the compact footer remains under the same
  `_MindTemporalBody` parent across every TimePlane.
- PASS — Ubuntu/proot focused host regression:
  `flutter test test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart --plain-name "FTR-03: one active compact range element keeps its held thumb values across Mind TimePlane changes"`
  reports one passing test. The direct Year-host topology test was also
  exercised locally; exact final online profile B and APK evidence remain
  pending.
- Protected systems remain unchanged: Time/Avatar physics, Query ownership,
  one compact range owner, score mathematics, Header chart/ticker, Budget and
  LogBox. Physical validation: `PENDING — USER ONLY`.

## 2026-09-18 — Final online validation and delivery (`434276ac`)

- Final workflow: `35285472445`, dispatched from journal head
  `1da3809320457f6cddcc6328c5b2e6646e826466`; its runtime application source
  is the immediately preceding repair commit `434276acd234f2ad04217365f30659204fe2159e`.
- PASS — online `test-flutter`, clean Room `test-core`, native dashboard bridge
  tests and `build-human-diagnostic-apk`. The first profile failure's temporal
  hit-test assertion is absent after the repair: profile B proceeds past the
  Mind Year slider topology check.
- FAIL — online `run-dashboard-profile`, only at the inherited profile harness
  check `Mind Year heatmap profile evidence frame_timing_headroom is invalid:
  null`. This known runner/harness condition is not altered or called green;
  it occurs after the repaired topology path.
- Human artifact downloaded and digest-verified:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_1da3809.apk`
  (83,252,529 bytes, SHA-256
  `ff79a7e388fe78b82ca4aaf78a2d687836846d84e003498641ce807fa52c46a5`).
  The compiled `FLUVI_BUILD_COMMIT` marker is `1da38093…`.
- Final matching SCIP is tooling commit `53c1f6da9535c75c42ec425de3ae7bd708f5ee3a`
  on `tooling/scip-codegraph-v1`: `manifest.source_head=434276ac…`,
  SCIP Dart 1.6.2, raw index SHA-256
  `0c7c77f79fb2990f4bbd92c0b62ef13c6b93169b7b461b19d2418ebaf9482462`,
  and tooling tests pass 15/15.
- Physical acceptance remains `PENDING — USER ONLY`.

## 2026-09-18 — Physical Mind Sum/layout/gesture feedback and palette-extension audit

- Feedback time: 2026-09-18 01:31 Europe/Budapest. User supplied a current Android screenshot of Mind + Sum and new physical observations, but the screenshot exposes no APK/source/build marker. Therefore the exact physically tested source SHA remains **MISSING EVIDENCE**; do not relabel the current remote application source as the exact tested APK without runtime identity.
- Remote branch state audited before this journal-only entry: branch `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD `1da3809320457f6cddcc6328c5b2e6646e826466` is journal-only; its runtime application parent lineage is `434276acd234f2ad04217365f30659204fe2159e` (`fix(mind): restore temporal gesture ownership`) after `463222fa45fcc0efd85d036af61a2697609a6e21` (`feat(mind): unify temporal heatmaps and score publication`). The intervening `f5d74e04...` and `1da38093...` commits are documentation only.
- Current matching SCIP is tooling commit `53c1f6da9535c75c42ec425de3ae7bd708f5ee3a`, manifest `source_head=434276acd234f2ad04217365f30659204fe2159e`, `scip_dart=1.6.2`, raw index SHA-256 `0c7c77f79fb2990f4bbd92c0b62ef13c6b93169b7b461b19d2418ebaf9482462`, 473 documents / 312,615 occurrences / 10,791 repository symbols. Graph definitions were source-verified for the Mind presentation settings, Sum/Month viewports, palette resolver, MonthCard, Mind surface, CoreModeHost and upper-vertical gesture coordinator.
- Latest relevant connected Drive logs are stale for this feedback: `Fluvi logs time fling` was last modified 2026-09-15, and `Fluvi mind heatmap` was last modified 2026-09-16 13:46:32Z (session `fluvi-1789566368119437`). There is no post-feedback 2026-09-18 runtime trace, so the new screenshot/gesture report is physical evidence but not a causal log.
- **PHYSICALLY PROVEN / screenshot:** Mind + Sum renders the title, `3 év · 36 hónap`, month-axis letters, year labels/totals, the five-swatch purple legend and the amount slider, while no colored monthly heatmap rectangles are visible. The screenshot also shows the legend occupying a dedicated lane above the slider. User reports the 4×3 Year layout is over-compressed when this legend is present.
- **PROVEN source cause for invisible Sum cells at 434276ac:** `MindSumHeatmapViewport` creates each month as an `Expanded -> Padding -> DecoratedBox` inside a 29px-high `Row`, but the childless `DecoratedBox` is given no explicit cross-axis height and the Row does not stretch it. The existing Sum tests only find the keyed DecoratedBox/read its decoration color; they do not assert a non-zero painted rectangle, so this is a false-green rendering gap matching the screenshot.
- **PROVEN legend/layout source behavior:** `_MindTemporalBody` always reserves a fixed 28px legend lane plus a 74px compact range lane for every Mind TimePlane. `MindYearHeatmapPresentationSettings` has no legend-visibility field. User now requires legend visibility to be user-selectable; when OFF it must reserve zero height and return that space to the temporal content, especially the 4×3 Year layout.
- **PROVEN Month reference mismatch:** current Flutter Month uses almost the full available width, centers day numbers, uses 8px labels and 3px radius. The authoritative Stage2 `B3M-MYM · Havi month layout` uses a centered `min(100%, 282px)` seven-column grid, 4px gaps, square cells, 3px internal padding, 6px radius and 7px/900 day numbers at the cell's top-left. The prototype's fake March values remain presentation-only and must never become production financial data.
- **PROVEN current gesture topology:** `434276ac` intentionally removed the host-level Mind content gesture wrapper and gives Sum/Year/Month exclusive temporal viewport ownership; only non-temporal Day content receives the Mind content vertical GestureDetector. Existing host regression explicitly expects scrolling Year content not to call expansion and only the Header drag to trigger it. This conflicts with the user's current requirement that up/down swipes on the Mind card itself trigger collapse/expand. The repository already has `DashboardUpperVerticalGestureCoordinator.consumeBoundaryOverscroll(...)` and Budget uses it to hand boundary overscroll from a child Scrollable to the single `DashboardExpansionController`; this must be source/graph-audited before inventing a second recognizer.
- **NEW presentation requirements:** add a tuner toggle for the palette legend; add a tuner-selectable Year rendering style where day cells sit directly on the white Mind surface instead of nested MonthCard material shells while retaining month grouping/titles and the same immutable financial projection; keep current MonthCard shell style as the other selectable presentation.
- **NEW palette presets:** retain Fluvi and B3M-MY3 and add Ocean Sunset (`#001219,#005f73,#0a9396,#94d2bd,#e9d8a6,#ee9b00,#ca6702,#bb3e03,#ae2012,#9b2226`), Bold Berry (`#f9dbbd,#ffa5ab,#da627d,#a53860,#450920`), Meadow Green (`#d9ed92,#b5e48c,#99d98c,#76c893,#52b69a,#34a0a4,#168aad,#1a759f,#1e6091,#184e77`), Peachy Delight (`#d8e2dc,#ffe5d9,#ffcad4,#f4acb7,#9d8189`), Soft Rainbow (`#fbf8cc,#fde4cf,#ffcfd2,#f1c0e8,#cfbaf0,#a3c4f3,#90dbf4,#8eecf5,#98f5e1,#b9fbc0`), Cherry Blossom (`#ebd4cb,#da9f93,#b6465f,#890620,#2c0703`), Soft Pastels (`#faf3dd,#c8d5b9,#8fc0a9,#68b0ab,#4a7c59`) and the user-labelled fixed `Custom colour` preset (`#ce84ad,#ce96a6,#d1a7a0,#d4cbb3,#d2e0bf`). The duplicate HSL/SCSS/RGB representations are equivalent encodings, not separate palettes; no arbitrary color-picker feature is implied by this feedback.
- Palette state remains presentation-only and must be one authority for Year/Month/Sum and the optional legend. New presets with authored ordered stops should sample the complete stop sequence across normalized intensity; B3M's existing exact stepped semantics and Fluvi's existing semantic palette must not be silently changed.
- **UNPROVEN:** exact tested APK/source SHA; whether the current screenshot was produced by `434276ac` or its preceding application source; any additional causal owner beyond the source-proven Sum zero-height box and current temporal gesture topology; whether another runtime performance issue accompanies the requested palette/layout changes.
- **MISSING EVIDENCE:** post-2026-09-18 runtime logs, exact screenshot build identity, mounted RED→GREEN for Sum painted-cell bounds/golden, production-parent Mind card collapse/scroll arbitration, optional-legend 4×3 geometry, direct-on-card Year style, exact B3M-MYM geometry, all new palette resolver/tuner tests, final CI/APK/final matching SCIP and user physical revalidation.
- Prompt-writer change for this feedback: this journal entry only, in a build-trigger-free `[skip ci]` commit. No application source, test, workflow, graph, milestone or runtime behavior is changed by the prompt writer.
- Physical validation of the eventual candidate APK: `PENDING — USER ONLY`.

## 2026-09-18 — Mind heatmap presentation and boundary-swipe delivery (`43b5fc10`)

- Application commit `43b5fc1090cfd35562df84d8d65838a297c0b689`
  (`feat(mind): repair heatmap presentation and card swipes`) repairs the
  source-proven Sum zero-height tile failure by materializing each bounded
  month tile extent. `SUM-PAINT-01` was RED at the audited parent with a
  `RenderBox` height of `0.0`; it is GREEN with positive in-viewport bounds
  and resolver-owned colour.
- Mind presentation now has one existing-settings-controller path for a
  default-ON optional legend and an independent annual MonthCard/direct-cell
  surface choice. Hiding the legend removes its 28px lane structurally, gives
  the space back to temporal content, and leaves the fixed compact slider
  bounds unchanged. Direct Year cells keep the same immutable frame, calendar
  geometry, titles, totals and 2×6/3×4/4×3 arrangements without the muted
  nested shell.
- Month now follows the audited B3M-MYM geometry only: centered
  `min(available, 282px)` seven-column grid, 4px gaps, square cells, 3px
  inset, 6px radius, and top-left 7px/900 day labels. Prototype fixture data
  did not enter the production projection.
- Fluvi and B3M-MY3 are byte-value regression-protected. One existing palette
  resolver now additionally owns the eight exact fixed user presets (Ocean
  Sunset, Bold Berry, Meadow Green, Peachy Delight, Soft Rainbow, Cherry
  Blossom, Soft Pastels, and fixed `Custom colour`), including every authored
  stop and five bounded resolver-derived legend samples.
- Mind Sum/Year keep their child-scroll owner and hand only boundary
  overscroll to the existing `DashboardUpperVerticalGestureCoordinator`.
  Zero-extent Sum/Month content can use that same owner; the compact range is
  a sibling and both physical thumbs are regression-tested to produce zero
  expansion. Budget was refactored to the same extracted boundary-handoff
  primitive without a behavior change. No second expansion controller, broad
  Mind recognizer, timer, Query owner, or financial projection was added.
- PASS — Ubuntu/proot formatter reports 15 changed Dart files already
  formatted. Focused Mind/settings/resolver/viewport/host/tuner/coordinator
  and Budget-boundary suite: 68 tests passed. `./scripts/test-fluvi-fast.sh`
  passed 431 tests. `flutter analyze --no-pub` reports no issues (132.3s).
  `git diff --check` passed before the application commit.
- PASS — online workflow `35318487076` for exact application SHA `43b5fc10`
  passed `test-flutter`, `test-core`, and `build-human-diagnostic-apk`.
  The normal app-entrypoint artifact is
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_43b5fc1.apk`,
  83,285,297 bytes, SHA-256
  `48248c8f1be0c20eefdc659b7f00b3cf8d1e8a12e925866d28437b1a821240d7`.
  Its release target and embedded `FLUVI_BUILD_COMMIT` marker are exact
  `43b5fc1090cfd35562df84d8d65838a297c0b689`.
- FAIL — the same workflow's automatic `run-dashboard-profile` lane reaches
  the established harness failure:
  `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`
  in `DashboardProfileReport.validateMindYearHeatmapEvidence`. The subsequent
  missing B report is consequential. No profile threshold, instrumentation,
  Time/Avatar physics, or application behavior was changed to mask it; it is
  not called green and is not physical validation.
- PASS — exact-source SCIP regenerated from `43b5fc10` with `scip_dart 1.6.2`.
  Manifest: 474 documents, 314,460 occurrences, 10,825 repository-defined
  symbols; raw index SHA-256
  `f3b8b75fbe2f197a3fcb57dbe8e7c0ff1e36f6117cf0ba6583825b9d8a394662`.
  Tooling commit `b96bbfe5` on `tooling/scip-codegraph-v1` is pushed and its
  15 Dart tests pass. The raw index remains untracked; graph evidence is
  navigation/provenance evidence, not runtime causality.
- The earlier screenshot's exact source identity remains unavailable; this
  delivery does not retroactively claim it was `434276ac` or `43b5fc10`.
  Physical validation: `PENDING — USER ONLY`.


## 2026-09-18 — Physical Mind Month B3M-MYM scale/header mismatch after 43b5fc10 delivery

- User supplied a new Android screenshot at 11:39 showing Mind + Havi for 2026 július and reports that the monthly activity view is still materially too small and does not match the authoritative reference HTML in either cell scale or the upper labels. The screenshot itself contains no embedded application SHA, so the exact physically tested APK identity remains **MISSING EVIDENCE**; do not infer it from delivery chronology alone.
- Remote branch audit for this feedback: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` is currently at documentation HEAD `d6a0e71a6f4b61a8f451918bf0613e30fa8a31f2`; its delivered application commit is `43b5fc1090cfd35562df84d8d65838a297c0b689` (`feat(mind): repair heatmap presentation and card swipes`). No newer application source was found on this branch before this journal-only entry.
- **PHYSICALLY PROVEN / screenshot:** the Month screen renders `Napi aktivitás`, then `31 nap` on a separate line, then `július 2026`, then `6 aktív nap` on another separate line. The day grid is visibly much narrower/smaller than the available Mind card area. This does not visually match the Stage2 B3M-MYM composition requested by the user.
- **PROVEN reference mismatch:** `origin/spendeetest:balance_latest_layout.html` defines `.mind-monthly-activity-head` as one horizontal flex row with the title on the left and day count on the right. Inside the calendar, `.mind-monthly-activity-summary` is another horizontal row with month/year on the left and active-day count on the right. The reference grid is centered at `width: min(100%, 282px)`, with 7 columns and 4px gaps.
- **PROVEN source cause for undersized cells at application commit 43b5fc10:** `_MindMonthHeatmapContent` still solves cell size against a hard-coded six-row envelope: `cellByHeight = (constraints.maxHeight - staticChrome - gap * 5) / 6`, then `cellExtent = min(cellByWidth, cellByHeight)`, and `gridHeight = cellExtent * 6 + gap * 5`. The current July 2026 calendar requires only five displayed calendar rows, so the sixth reserved row unnecessarily caps `cellExtent` and leaves the visible grid materially smaller than the available 282px-width reference target.
- **PROVEN source cause for header mismatch at 43b5fc10:** Flutter currently emits four sequential `Text` widgets for title, day count, month/year and active-day count. It therefore cannot reproduce the two side-by-side B3M-MYM header/summary rows despite matching some individual font/cell tokens.
- Existing Month tests are insufficient for this physical mismatch: one test explicitly preserves a `fixed six-row envelope`; `MONTH-B3M-01` proves a 282px grid only in its wide test harness but does not prove production-card height allows the same cell extent for the actual month's row count; no current test proves the two reference header rows as left/right pairs in production composition.
- Required product behavior from this feedback: Month must use the available Mind card space instead of shrinking a five-row month to a six-row envelope; its cell scale should reach the B3M-MYM reference geometry whenever the real card bounds permit it. The top information must follow the reference grouping: `Napi aktivitás` + day count on one row, and month/year + active-day count on one row. Do not copy prototype fixture values; only the production data and selected month remain authoritative.
- **UNPROVEN:** exact tested APK/source SHA; whether any additional outer-card constraint beyond the source-proven six-row cap contributes to the physical size; final pixel-perfect production geometry until mounted RED→GREEN bounds are captured.
- **MISSING EVIDENCE:** exact screenshot build marker, production-card RED→GREEN cell bounds for a five-row 31-day month, mounted left/right header-row geometry, final APK and user physical revalidation.
- Prompt-writer change for this feedback: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, workflow, tooling graph or milestone file is modified.
- Physical validation of the eventual correction: `PENDING — USER ONLY`.


## 2026-09-18 — Mind compact amount slider left-label removal feedback

- User follow-up on the current Mind Month screenshot: remove the visible `Összeg` text at the left side of the compact amount-slider metadata row.
- Remote branch audit before this journal-only entry: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD `00d96125251b0e3d3e8ef353e1d2945f57b8175f`; effective delivered application source remains `43b5fc1090cfd35562df84d8d65838a297c0b689`. The commits above the application SHA are documentation-only.
- **PROVEN source owner at 43b5fc10:** `lib/features/dashboard/query/presentation/query_amount_range_control.dart` renders an explicit `Text('Összeg')` in the compact Mind amount control immediately before the `Min.` / `Max.` values. This is the label visible in the supplied screenshot and is the requested removal target.
- Scope clarification: this feedback targets the compact Mind slider row only. The separate standard Query amount-range control also contains an `Összeg` heading, but removing that standard-control heading is **not requested** by this feedback and must not be changed without separate evidence.
- Required resulting composition: compact Mind slider retains the RangeSlider plus `Min.` and `Max.` values, but the standalone left-side `Összeg` label is absent; the reclaimed horizontal space should remain available to the Min/Max row rather than being replaced by an empty spacer.
- **MISSING EVIDENCE:** mounted RED→GREEN compact-control geometry test and user physical validation of the eventual application change.
- Prompt-writer change for this feedback: journal only, build-trigger-free `[skip ci]` commit. No application source, test, workflow, tooling graph or milestone file is modified.
- Physical validation of the eventual correction: `PENDING — USER ONLY`.


## 2026-09-18 — Mind compact amount slider: remove left `Összeg` caption

- User feedback: in the Mind compact amount-range footer, remove the standalone `Összeg` label shown to the left of the minimum/maximum values. Keep the slider itself and the `Min.` / `Max.` amount readouts.
- Remote branch audit before this journal-only entry: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD was `00d96125251b0e3d3e8ef353e1d2945f57b8175f`, a journal-only commit. The latest delivered application source remains `43b5fc1090cfd35562df84d8d65838a297c0b689`.
- **PROVEN source owner at 43b5fc10:** `lib/features/dashboard/query/presentation/query_amount_range_control.dart` renders the Mind-specific footer through `_CompactMindAmountRangeSurface`. Its lower Row begins with a standalone `Text('Összeg')`, followed by an 8px gap, then the `Min.` and `Max.` compact amount values. This is the exact label visible at the left side of the slider footer.
- Scope clarification: remove this standalone caption from the **compact Mind presentation only**. Do not remove the `Összeg` heading from the standard Query amount-range surface unless separately requested; do not change range semantics, slider geometry, snapping, min/max values, diagnostics, commit behavior or gesture ownership.
- **MISSING EVIDENCE:** mounted RED→GREEN geometry for the compact footer after caption removal, final application commit/APK and user physical revalidation.
- Prompt-writer change for this feedback: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, workflow, tooling graph or milestone file is modified.
- Physical validation of the eventual correction: `PENDING — USER ONLY`.

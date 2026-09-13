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

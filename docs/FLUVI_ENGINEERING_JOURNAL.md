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

## 2026-09-19 — Segmented startup narrow-layout and Legacy rail-profile compatibility repair

- Application commit `5893b4568f7061c6e643e7ce767ac76716c7c8d1` follows the first exact delivery candidate `98eaba5e...` and addresses two newly observed verification failures without changing the requested product default: production startup remains `Segmented` + `Mirrored`.
- **RED external evidence:** workflow `35433511022` reached `I_first_fling` then failed at `ScrollController.position` with `Bad state: No element`, before the inherited `frame_timing_headroom` profile gate. Current source explains this: the protected physical profile drives the Legacy-only `dashboard-time-rail`, while a Segmented Summary intentionally replaces that legacy rail surface. The c1b12 reference workflow `35392071533` instead reached the older `frame_timing_headroom is invalid: null` failure.
- **RED mounted evidence:** the product default caused the app-shell test harness to throw `Segmented Summary cannot fit its authored content` with a 146.56px navigation lane. The initial 40% amount envelope left insufficient width for the immutable selector visuals at that narrow host.
- **Repair:** `FluviApp` / `FluviAppShell` expose an optional embedding/test initial Summary variant; normal app construction still resolves to Segmented. The A–K profile now explicitly requests Legacy, so it measures the same protected Time-carousel fixture rather than relying on an obsolete product default. `SummarySegmentedTrackGeometry.minimumWidthFor` computes the exact lower bound for active authored tracks and existing half-gap invariant; only when needed, the Summary gives the amount slot just enough width back to satisfy that bound. No selector glyph/semantic cell is scaled or clipped; normal-width amount allocation remains 40%.
- **GREEN evidence:** `test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart` passes 30 tests, including the exact narrow-host no-clip geometry proof. `test/app/fluvi_app_test.dart` passes 18 tests, including explicit Legacy Time-rail mounting and the default Segmented startup path. Existing normal-orientation geometry tests now request Normal explicitly; the separate startup/default coverage continues to assert Mirrored. `flutter analyze --no-pub` reports no issues; `git diff --check` passes.
- **No-touch:** no Time physics/controller/position behavior, Avatar behavior, Query semantics, score calculation, Header colour policy, LogBox, Budget, Room/Kotlin/schema, or `MILESTONE_COMMITS.md` change is included.
- **Still required:** rerun exact-SHA CI/profile, obtain the normal human diagnostic APK, regenerate exact-SHA SCIP, and user device validation. Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Final delivery evidence: Day→Month Mind repair and presentation controls

- Final application source is `5893b4568f7061c6e643e7ce767ac76716c7c8d1` (`fix(summary): preserve startup layout and rail profile`), pushed first without a documentation child to trigger workflow `35436924400`. It contains the Day→Month exact visible-frame publication repair, selectable 10/20-colour Mind scale, legend placement/body-space controls, temporal-X score-chart inspection, and segmented/mirrored startup defaults; the later startup repair preserves those defaults while making the protected profile fixture explicitly Legacy and keeping narrow Segmented layout unclipped.
- Frozen causal runtime evidence remains the fully audited Drive document `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, revision 6, modified `2026-09-19T05:41:59.038Z`: 373,368 bytes, SHA-256 `46682010d3a002a7b2eafc9414cc55c5d2bc71e355aef198c8e10990cb8daa95`, session `fluvi-1789796494332681`, retained seq `60,439..61,438`, zero gaps/conflicts/exact duplicates, 60,438 evicted rows, and no `USER_MARK` or build identity. The Day→Month missing Month publication is still exactly seq 60,623/60,632 versus component positive controls 61,346/61,348 and 61,398/61,400. The supplied screenshot still has no build marker; it is not attributed to this APK.
- Final local validation on exact application source: the 15 targeted files pass `285/285`; `flutter analyze --no-pub` reports no issues; `./scripts/test-fluvi-fast.sh` passes `431/431`; `./scripts/verify-fluvi-boundaries.sh` and `git diff --check` pass. The final targeted additions prove latest-wins Day↔Month level publication, 10↔20 actual-Core presentation isolation, and chart-tap zero Core/Query/Time/source work. The Termux `dart format --set-exit-if-changed` wrapper remains non-idempotently noisy despite stable file hashes; formatting was checked by unchanged hashes plus compiling/test/analyzer evidence, not misreported as a clean wrapper PASS.
- Workflow `35436924400` job audit: `dashboard-paths`, `test-core`, `test-flutter`, and `build-human-diagnostic-apk` are PASS; `test-flutter-nightly`, `run-dashboard-profile-baseline`, and `test-native-nightly` are explicit skipped branches. `run-dashboard-profile` is FAIL, so the workflow is **not globally green**. Exact 5893 log search finds zero `Bad state: No element` occurrences; it reaches only `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`, byte-for-byte the same final profile gate observed in c1b12 workflow `35392071533`. The driver’s later missing B report is consequential to that prior gate, not a second feature failure. No profile threshold/instrumentation or protected motion behavior was weakened.
- The exact normal human release is `fluvi_HUMAN_DIAGNOSTIC_5893b45.apk`, release target `5893b4568f7061c6e643e7ce767ac76716c7c8d1`; it is downloaded to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_5893b45.apk`, 83,580,209 bytes, SHA-256 `3741ebb3e021363b4e58db0d3603a588adce34b65ef7110c5adbc989454d8d05`. Archive integrity passes and the complete application SHA occurs three times in the APK.
- Exact-source SCIP was regenerated from detached clean source `5893b456`: `scip_dart 1.6.2`, raw index SHA-256 `49eb5689a8f29a9047ae9031ea92863e53fdf75412c4d1d4a6ffb2093480bba5`, 474 documents, 268,973 occurrences, and 10,982 repository-defined symbols. Tooling commit `2433548f311fd23711da28ec957b90f39b34560a` is pushed on `tooling/scip-codegraph-v1`; its 15 Dart tests pass. The graph is provenance/navigation evidence only, not replacement runtime causality.
- Diff/no-touch audit for `c1b12..5893` confirms no production change in Time or Avatar physics/controller/position, Query semantics, score algorithm, Header colour algorithm, Room/Kotlin/schema, LogBox, Budget, Day financial aggregation, Year inspection, or `MILESTONE_COMMITS.md`. Standard Query range rendering stays independent of Mind palette state. The tracked worktree is clean apart from the separately retained user untracked diagnostics/index paths.
- Device visual/touch/smoothness acceptance remains outside automation and has not been claimed. Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Selectable 10/20-colour Mind heatmap resolution

- Application commit `a7561cba942918b90d766ebc379d5d8c49471bbb` adds `MindHeatmapScaleResolution` to the existing `MindYearHeatmapPresentationSettings` owner. The product default remains `ten`; a real 10↔20 change advances presentation revision once, while a no-op does not. It is not persisted and does not alter Query, financial membership, normalized intensity, score, range, or navigation.
- **RED evidence:** SCALE-01 initially failed because the enum, settings field and controller setter were absent. SCALE-03 initially failed because the central resolver had no resolution parameter or twenty-stop path.
- **Resolver evidence:** `MindYearHeatmapPaletteResolver` remains the sole colour authority. Its exact existing ten-stop lists and adjacent `Color.lerp` behavior stay default-compatible at every anchor and representative off-anchor test. It now contains the user-approved fixed twenty-stop lists for exactly Fluvi, B3M-MY3, Meadow Green, Fluvi stretched and B3M-MY3 stretched. SCALE-03 verifies all 100 twenty anchors; SCALE-04 proves twenty affects actual tile resolution rather than only the legend.
- **Surface ownership:** the selected resolution is passed through the existing Year MonthCard painter, Sum viewport, Month viewport, Day viewport and the one Mind legend. The tuner exposes `10 szín` and `20 szín`. Tests retain the same admitted frame identity while changing resolution, and the shared legend is exactly 10 or 20 samples from the resolver.
- Focused validation: settings/resolver/temporal viewport/Year viewport/Header tuner/Mind mode-host suite passed (53 tests); Dart format check passed. No palette enum was added, so Soft Rainbow and Peachy Delight remain absent.
- **Still pending:** the separate compact-legend placement/body-height work, physical colour assessment, final CI, human diagnostic APK, final-source SCIP and user device validation. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Compact Mind legend placement and reclaimed body space

- Application commit `7f8e91ee` introduces the presentation-only `MindHeatmapLegendPlacement` in the existing `MindYearHeatmapPresentationSettings` owner: `aboveSlider` remains the default; `inlineBetweenRangeValues` is independently selectable from visibility and scale resolution. The header tuner exposes `Slider felett` and `Slider alatt — Min/Max között`.
- **RED/GREEN evidence:** the new setting test was initially red because placement state/controller API did not exist. Mounted `LEGEND-POS-01/BODY-SPACE-01` now measures the default above composition: temporal viewport followed by a `16.0px` external legend lane and a `68.0px` fixed compact footer, for `84.0px` total reservation. Against the audited former source contract `28 + 74 = 102px`, this is a measured `18.0px` return to the temporal body. Slider, Min. and Max. have positive bounds and no widget exception/overflow is recorded.
- **Inline evidence:** `LEGEND-POS-02/03` proves that inline placement mounts no external lane, positions the read-only Mind legend between Min. and Max., and reserves no legend space when visibility is off. Ten mode swatches are `6×6px` with `1px` gaps; twenty mode is `4×4px`, with the full 20-swatch block measuring `99px` (≤100px). The exact same resolver supplies tiles and both legend modes.
- **Range ownership:** `QueryAmountRangeControl` remains the sole slider/range authority. It accepts only an inert `compactMindCenterAccessory`, and its standard Query presentation deliberately ignores it. `RANGE-ACCESSORY-01` verifies that standard rendering does not mount the accessory; `RANGE-GEOM-01` verifies the compact variant inside a real 68px parent. Range preview/commit/snap values and touch geometry are unmodified.
- **No remount/data work evidence:** switching above→inline retains the actual `mind-query-amount-range` element identity, and changing 10→20 inline also retains it. Existing presentation-only frame identity coverage remains green. No repository/index/Query/time/score owner was introduced or mutated for either legend choice.
- Focused validation in Ubuntu proot: `query_amount_range_control_test.dart` PASS (12); `mind_year_heatmap_mode_host_test.dart` PASS (17); `mind_presentation_settings_test.dart` plus `dashboard_header_visual_tuner_test.dart` PASS (22); Dart formatting and `git diff --check` PASS.
- **Still pending:** physical readability across device/text-scale combinations, final CI/human diagnostic APK/final exact-source SCIP, and user device validation. The inherited profile `frame_timing_headroom` gate is not claimed green. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Mind Header temporal score-chart inspection

- Application commit `8845e748` replaces the former split chart X authorities with `MindHeaderScoreChartTemporalProjection`. c1b12 painted score anchors by list index while its time labels derived positions from the epoch-day domain; sparse `CHART-X-01/02` now proves anchors at 0/10/90/100% for a 0..100 series, and proves line, static labels, nearest-point hit testing and crosshair share the same clamped epoch-day mapping.
- The selected value is always the existing immutable `MindBehavioralScorePoint`: a clean tap snaps to the nearest temporal point, white vertical crosshair and white marker paint at that exact X, the top label is the point's existing rounded `NN/100`, another point moves selection, and the same selected point clears it. Selection is local chart State and synchronously clears when the immutable series/domain changes; no Core, Query, Time, repository, index or score calculation owner is called.
- Explicit presentation context reaches the chart from existing Sum/Year/Month/Day body state. Selected labels use the existing Hungarian short-month formatter: Year/Day `aug 26`, Sum `2027. aug`, Month `26`. Static time-label visibility remains its independent existing setting and crosshair works with it hidden or shown.
- **Header coexistence:** the chart cannot sit above the physical Header pan layer. Instead the existing Header gesture layer passively relays raw pointer events to the chart while retaining its existing pan recognizer. The relay owns no selection state and enters no competing gesture arena. `CHART-TAP-08/09` proves an in-plot vertical drag starts/ends Header expansion and creates no crosshair; a clean production Header tap still selects.
- Golden evidence: new selected crosshair golden `test/goldens/mind_header_score_chart_selected_crosshair.png`, SHA-256 `d037f455327a4ddf220579535a05b90710ca3620e66b8c365ad46bd8c71fd974`, was generated and directly inspected. The existing unselected reference golden remains green.
- Focused validation in Ubuntu proot: `mind_header_score_chart_test.dart` PASS (10); `mind_header_score_chart_golden_test.dart` PASS (2); `mind_year_heatmap_mode_host_test.dart` PASS (18); Dart formatting and `git diff --check` PASS.
- **Still pending:** user device perception/animation validation, final CI/human diagnostic APK/final exact-source SCIP. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Segmented and mirrored Summary startup defaults

- Application commit `b124698e` changes the product startup/default presentation only: `SummaryPillVariantController()` now starts `segmented`, and `DashboardSummaryPresentationSettings.defaults()` (including reset) starts `mirrored`. No persistence was added; the Header tuner still selects both Klasszikus/Szekciós and Normál/Tükrözött options.
- **RED/GREEN evidence:** SUMMARY-DEFAULT-01 initially observed the old Legacy controller default and then passes with segmented plus `transitionEpoch == 0`; SUMMARY-DEFAULT-02 initially observed normal orientation and now proves mirrored default/reset. The controller accepts an explicit initial variant so transition-specific tests can begin legacy by intent instead of inheriting an obsolete global default.
- **First-frame owner repair:** CoreDashboard formerly hard-coded `_lastSummaryPillVariant = legacy`. It now constructs the variant controller from its explicit/product initial value and immediately initializes bookkeeping from that actual value before registering the listener. This prevents a fabricated outgoing Legacy state or a synthetic transition.
- `SUMMARY-DEFAULT-03/04` mounts a fresh real CoreDashboard and proves the segmented selector is physical, the legacy shell is absent, mode selector lies on the mirrored side of the amount zone, orientation is mirrored, transition epoch is zero, and no `SUMMARY_VARIANT_TRANSITION_STARTED` is emitted during startup. A legacy→segmented Budget footprint fixture now declares `initialSummaryPillVariant: legacy` and remains green.
- Focused validation in Ubuntu proot: SUMMARY-DEFAULT-03/04 CoreDashboard test PASS; legacy→segmented footprint fixture PASS; summary controller/presentation and Header tuner focused tests PASS; Dart formatting and `git diff --check` PASS.
- **Still pending:** final full suite/analyzer/Actions/human diagnostic APK/final exact-source SCIP and user device validation. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Summary-default fixture and structural-range test alignment

- Application/test commit `beb24681` keeps the new product default (`segmented` + `mirrored`) intact while making existing CoreDashboard fixtures declare their intended Legacy source whenever they specifically exercise the Legacy Summary shell, chevron/rail, narrow geometry, or Legacy→Segmented transition. The production default remains covered separately by the unparameterized first-frame test.
- The updated full `core_dashboard_test.dart` passes 34 tests in Ubuntu proot. The former 14 aggregate failures were audited rather than labelled inherited: they were implicit Legacy fixture starts. The 206px collapse fixture now explicitly starts Legacy, and the mirrored Segmented background probe uses its actual left-side unassigned inset.
- A pre-existing range test asserted that a ready all-time Query facet would mount the Mind compact slider even while its matching Year/Month structural amount domain was absent. The Core owner deliberately rejects that false fallback. The corrected test passes the lifecycle loader into production composition and proves the control stays unavailable rather than rendering an incorrect all-time range; range-mount/hit-geometry coverage remains in the dedicated mounted Mind range tests.
- No production behavior, Query semantics, score calculation, Time/Avatar motion owners, or dashboard layout algorithm changed in this commit. Physical validation remains: `PENDING — USER ONLY`.

## 2026-09-19 — Repeated Day→Month level-return guard

- Test commit `e1fc59cb` adds `LEVEL-MONTH-05` to the already repaired Core semantic admission boundary. A real mounted Mind Day body performs exactly `Month → Day → Month → Day → Month` level navigation with no month-component change and no settling workaround.
- The guard proves every rail-closed return immediately has `MonthScope`, a `MindMonthHeatmapFrame` for June 2027, a mounted Month grid, and no Day grid; every reopened rail has the converse Day frame/grid. Resident-data invariants remain `repository.prepareCalls` unchanged and identical prepared-index object identity. The focused test passes in Ubuntu proot.
- No production source, Time/Avatar behavior, Query semantics, score algorithm, or additional notifier changed. Physical validation remains: `PENDING — USER ONLY`.

## 2026-09-19 — Avatar fixture startup-state audit

- Test commit `641fd6d5` resolves the fast-suite Avatar liveness failures without changing Avatar/Core production code. Ten physical Avatar cases had implicitly inherited the former Legacy Summary geometry; under the new Segmented/Mirrored product startup they could prepare/canonicalize the target yet miss the fixture's old painted-handle condition.
- Both shared `CoreDashboard` mount factories in `dashboard_avatar_target_liveness_test.dart` now explicitly request `SummaryPillVariant.legacy`. The dedicated file passes all 10 cases, including cold, persistent, sparse, Month/Day startup sequences, final-target replacement and exact resource preparation. First-frame product-default coverage remains unparameterized elsewhere.
- No Time/Avatar controller, physics, cache, scene preparation, Query, score, production layout, or semantic owner changed. Physical validation remains: `PENDING — USER ONLY`.

## 2026-09-19 — Rail identity fixture startup-state audit

- Test commit `98eaba5e` makes the structural controller/position/physics identity fixture explicitly start the Legacy Summary variant. Its stated object of observation is the physical `dashboard-time-rail`, which intentionally is not mounted by the new Segmented startup mode.
- The direct rebuild-isolation test passes with the actual rail controller, ScrollPosition and physics identities unchanged throughout all structural changes. No production Time/Avatar/Query or Summary behavior changed; the fresh Segmented/Mirrored first-frame test remains the product-default proof.
- Physical validation remains: `PENDING — USER ONLY`.

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

## 2026-09-20 — Detailed Sum chart zoom and anchored-cell delivery

- Application commit `15bae5ac712eec4683ce808e06a4d6106a2818db` (`feat(mind): add zoomable detailed Sum chart`) advances the approved Mind feature delivery from the current three-card baseline. This is feature work; the user explicitly excluded fresh Drive/runtime-log audit, none was performed, and this entry makes no runtime-causality claim.
- Sum preserves its ordered presentation contract: page 0 is the multi-year month heatmap, page 1 is the exact one-point-per-year aggregate trend, and page 2 remains the distinct detailed per-year multi-line visualization. The exact chart was not conflated with the detailed chart and its annual aggregate semantics were not changed.
- The detailed chart now uses `MindDetailedSumTimeWindow` and `MindDetailedSumLod`: its minimum extent is the actual Jan–Dec epoch-day domain, pinch zoom changes that semantic temporal interval around the gesture focal point, and panning applies only while zoomed. Its bounded LOD emits only selected real immutable daily aggregate points from the already-admitted Sum frame; it never fabricates financial samples and does not enter Query, Core, Time, repository, Room or a raw-ledger scan.
- One year expands into the chart viewport, two years share it, and three or more retain a 118px minimum band in an inner vertical scroll surface. Every band has Hungarian month-initial X labels and readable compact monetary Y labels. The compact line/heatmap switch uses the existing Sum pager and leaves the current financial frame identity untouched.
- `MindAnchoredInfoCard` was corrected to calculate local placement from the actual card stack bounds. Sum month and Year day info cards now derive their anchor from the tapped cell’s global geometry, clamp only at card edges, pass through pointer hit testing so a subsequent cell can be selected, and dismiss by tapping the currently selected cell again. No static top-left popup origin remains in these paths.
- **RED/GREEN evidence:** the new detailed-model and mounted Sum-page contracts were written before their model/widget wiring; they initially failed for the missing time-window/LOD/chart surface, third-page keys and transition path. Popup geometry tests exposed the former card-origin anchor and are green with actual Stack bounds. Independent review then exposed a same-year identity zoom-reset gap, Y-gutter focal-X mismatch and inaccessible Year-popup dismissal; each was first RED and is GREEN. The final focused model + Sum/Year viewport command is PASS (**43 tests**); Ubuntu/proot `flutter analyze --no-pub` is PASS (`No issues found!`, 179.3 seconds); `./scripts/test-fluvi-fast.sh` is PASS (**431 tests**); and `./scripts/verify-fluvi-boundaries.sh` plus `git diff --check` are PASS. The unzoomed detailed-page swipe and zoomed local-pan boundary were both mounted-tested.
- Intentionally unchanged: Avatar/Time/Summary physics and controllers, canonical Query and range-slider ownership, repository/Room/Kotlin/schema, financial scoring/Header colour, Budget, LogBox, palette authority, BottomNav, and `MILESTONE_COMMITS.md`. The current app still retains the earlier Year heatmap/partial-bars/monthly-line, Month rhythm, Day timeline and permanent inline legend features.
- Still unproven: final Actions results, normal human APK for exact `15bae5ac`, exact-source SCIP, reference-image raster parity and real-device nested pinch/pan/page/slider interaction. Physical validation: `PENDING — USER ONLY`.

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


## 2026-09-18 — 33facc5 Mind Year inspection and presentation convergence delivery

- Application commit `33facc5f1bfcee5d02abd07dd16448aa0173604b` delivers the Year MonthCard inspection feature and the pending Mind presentation corrections requested in the preceding journal entry. It is the effective runtime source; the surrounding application branch may subsequently receive this journal-only evidence commit.
- **Feature/data proof:** Year inspection remains presentation-local to `MindYearHeatmapViewport`: one inspected `(year, month)` identity and one 220 ms viewport-local animation controller, never a persisted/global selection or one controller per card. The frame continues to use `MindYearHeatmapMonthlyAggregates` as the full-ledger twelve-month authority (`Zárás`/net, income, expense), which stays independent of direction, focus and the Mind range. A separate bounded `MindYearHeatmapScopedMonthlyAggregates` is built once from admitted resident selected prepared contributions for the active category/partner/search scope before amount-range preview; it is not computed on tap, paint, or slider ticks. The scope label/tint follows `DashboardQueryFacetChips` precedence and `CategoryVisualResolver`; partner uses its category color. No repository, index, Query, Time or LogBox operation is introduced by inspection taps.
- **Interaction proof:** a MonthCard clean-tap `Listener` is local to the card and rejects pointer travel above the tested slop. It intentionally replaced a competing tap-recognizer approach after the production host RED showed that a normal `GestureDetector` suppressed the already-approved Year `DashboardVerticalScrollBoundaryHandoff`. The final listener preserves real Year scrolling and the boundary transfer to the single existing upper expansion coordinator; it does not surround the compact slider. The selected card morphs in its fixed annual slot; direction/palette/legend/surface/range changes retain same-Year inspection, and a new Year frame invalidates the old identity before paint.
- **Presentation proof:** palette choices are exactly seven, each with ten authored anchors: Fluvi, B3M-MY3, Meadow Green, Soft Rainbow, Peachy Delight, Fluvi stretched and B3M-MY3 stretched. The centralized resolver interpolates adjacent anchors continuously, preserves neutral empty tiles and exposes ten resolver-owned legend swatches. The standalone Month view now uses its real five/six calendar rows, the two B3M-MYM left/right header rows and the centered 282px-or-available grid. The compact Mind range footer no longer contains the standalone `Összeg` caption; its Min./Max. row and the standard Query amount heading remain. Legend-off structurally returns its lane to 4x3 temporal content; the zero-scroll tests record whether square cells are width- or height-limited instead of retaining a legend-present envelope.
- **RED → GREEN evidence:** initial scoped-month model and Year-card inspection contracts were absent; the focused Core and production-parent tests now prove full-vs-scoped aggregates, category/partner intersection, no fake search scope, open/close/transfer morph, stable card Rect/scroll extent, stale-Year invalidation, direction independence, direct/MonthCard styles, 4x3 widths 360/390/412/430, real five/six Month rows, ten palette anchors/legend, compact-caption isolation, and real boundary-scroll behavior. The prior gesture implementation was rejected by the host `RED GESTURE-02`; the final local pointer observer made that exact boundary handoff contract GREEN without changing coordinator ownership.
- **PASS — local Ubuntu/proot validation:** eight focused Mind/domain/presentation/host/tuner/query files: 80 tests passed; Core/focus suite: 102 tests passed. `dart format --output=none --set-exit-if-changed` over 17 changed Dart files reported 0 changes. `flutter analyze --no-pub` reported no issues (193.3s). `PATH=/home/flutteruser/flutter/bin:$PATH ./scripts/test-fluvi-fast.sh` passed 431 tests (05:47). `./scripts/verify-fluvi-boundaries.sh && git diff --check` passed. An initial direct fast-suite invocation failed only because the Ubuntu shell PATH omitted `flutter` (`exit 127`); the identical suite was then rerun with the Flutter SDK path and passed.
- **PASS — CI/build:** workflow `35342061591` for exact SHA `33facc5f1bfcee5d02abd07dd16448aa0173604b` passed `test-flutter`, `test-core`, and `build-human-diagnostic-apk`. The normal `lib/main.dart` human artifact is `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_33facc5.apk`, 83,318,065 bytes, SHA-256 `b709ebf07b890b2b76256c2b729682630fd445f74711e4bddef9418a928c2476`. Its release target and embedded `FLUVI_BUILD_COMMIT` marker both equal the full application SHA.
- **FAIL — inherited profile gate remains honest:** the same workflow's `run-dashboard-profile` job failed after 27 minutes at `DashboardProfileReport.validateMindYearHeatmapEvidence`: `Bad state: Mind Year heatmap profile evidence frame_timing_headroom is invalid: null.` The later `B_year_month_rail_populated must be a report map` is consequential. No threshold, profile evidence, Time/Avatar physics or runtime behavior was altered to mask this existing gate failure; it is neither green CI nor physical acceptance.
- **PASS — final SCIP:** regenerated from an isolated exact-`33facc5` source worktree with `scip_dart 1.6.2`; manifest has source_head `33facc5f1bfcee5d02abd07dd16448aa0173604b`, 474 documents, 316,161 occurrences and 10,869 repository-defined symbols; raw index SHA-256 `4c2cad6557be62ef4498e9815c8d9f8013896690265f314a174b64af693e6888`. Tooling commit `0f81d535c8e8ee2778b50cf46e6733fc23bceb30` on `tooling/scip-codegraph-v1` is pushed; its 15 Dart tests pass.
- The screenshots and both frozen Drive logs still have no exact build marker for this physical feedback. The delivery does not claim they were produced by `33facc5`; actual animation smoothness and visual acceptance remain device-only. Physical validation: `PENDING — USER ONLY`.

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


## 2026-09-18 — Year month tap-to-morph information card + consolidated pending Mind presentation refinements

- New user feature request: in Mind Year mode every month must be tappable. Tapping a month morphs that month presentation into an information card. The information view must show the month-end remainder/close, total income and total expense **independently of the currently active Bevétel/Kiadás pill**. If a special category or vendor/partner scope is active, the card must also present that scope using its category colour. This is a new presentation/read-model feature, not a request to navigate the TimePlane from Year to Month.
- Remote branch audit before this journal-only entry: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD `369a61f3ffef4f35f19bef9665266479599ca5c6`; commits above the delivered application source are documentation-only. Effective application source remains `43b5fc1090cfd35562df84d8d65838a297c0b689` (`feat(mind): repair heatmap presentation and card swipes`), parent `75b50e1469609df298b450af5618b6f9ea1867cf`.
- Matching SCIP tooling remains `b96bbfe5`: manifest `source_head=43b5fc1090cfd35562df84d8d65838a297c0b689`, `scip_dart=1.6.2`, raw index SHA-256 `f3b8b75fbe2f197a3fcb57dbe8e7c0ff1e36f6117cf0ba6583825b9d8a394662`, 474 documents / 314,460 occurrences / 10,825 repository-defined symbols. Graph definitions/references were audited for the Year viewport/MonthCard/frame/monthly aggregates, focus controller/facet metadata, current Query scope, QueryMenu facet data, prepared focus membership, and category visual resolver; source remains the causal authority.
- Relevant Drive evidence is historical for this feature. Frozen `Fluvi mind heatmap` revision 5 (modified 2026-09-16T13:46:31.735Z, session `fluvi-1789566368119437`) is a complete retained 1200..2199 LIVE_TAIL with no sequence gaps/conflicts and no build marker; text snapshot SHA-256 `58b10f7256864db39055dfd3eeca2669e40f6423de6adc14eed437d47ba663ee`. Frozen `Fluvi logs time fling` revision 51 (modified 2026-09-15T06:07:56.959Z, session `fluvi-1789452354097594`) deduplicates overlapping LIVE_TAIL blocks to unique sequences 2105..3114 with zero conflicts/gaps; snapshot SHA-256 `08c630714ed985a7d646a368ac70b7b0b7f4e80a5e9593d62e6e12aeabd1b594`; USER_MARKs identify historical profile build `288cc35584ec5cb6e41eb237523104922a2c7393`. Neither log contains this new tap/morph interaction and neither is causal evidence for it.
- **PROVEN existing financial owner:** `MindYearHeatmapFrame.monthlyAggregates` already carries twelve immutable full-calendar monthly aggregates with `incomeForMonth`, `expenseForMonth`, and `netForMonth = income - expense`. The Core deliberately sources them from prepared Budget handle zero and tests explicitly protect them from active direction, category/partner focus, and Mind amount-range narrowing. The existing Year UI calls this monthly net `Zárás`. No separate cumulative account-balance/month-end-balance authority was found in the audited Mind Year pipeline; therefore a coding agent must not invent a cumulative balance interpretation for the requested `hó végi maradék` without a separate proven owner.
- **PROVEN current interaction gap:** `MindYearHeatmapMonthCard` is a `StatelessWidget` with no tap callback/selection state. Its heatmap semantics are read-only. Current tests contain no month-card tap or heatmap→information-card morph scenario.
- **PROVEN scope metadata/color path:** active ephemeral category/partner facets are represented by `DashboardFocusFacet(id, displayName, colorId, iconId)`; applied Query facets are represented by `QueryMenuCategoryFacet` and `QueryMenuPartnerFacet`. Existing `DashboardQueryFacetChips` establishes the visible-dimension precedence: an active ephemeral focus replaces the displayed applied facet for that same dimension; partner tint comes from `categoryColorId`. Canonical category colour resolves through `CategoryVisualResolver.resolve(...).gradient.middleColor`. This is reusable presentation metadata, not permission to add another color authority.
- **PROVEN scoped-data gap:** the existing `monthlyAggregates` must remain whole-ledger totals and cannot be repurposed for category/vendor values. The Core already has resident `DashboardFocusMembershipSeed.select(...)` membership and uses it to build the focus-filtered Year heatmap with zero repository reads. A category/vendor monthly information value therefore needs a new bounded immutable read-model derived at the prepared/projection boundary, not repository/index work on card tap and not mutation of the full-month aggregate bank. Existing tests explicitly require category/partner focus to leave `monthlyAggregates` unchanged.
- Product interaction requirement recorded for implementation: one inspected month at a time; tap morphs heatmap content into info content without changing Year TimePlane or Query. The selected month must be identity-safe against a Year/frame change and must not allow stale data from a prior year. Exact animation implementation/duration remains **UNPROVEN** and must use/audit existing Fluvi motion conventions rather than invent a second global animation owner.
- Consolidated outstanding prior requirements to carry into the next implementation prompt: (1) Month B3M-MYM must use the actual 5/6 calendar-row count and the two reference left/right header rows; (2) compact Mind slider removes only the standalone `Összeg` caption, preserving Min/Max and standard Query control; (3) when legend is OFF, 4×3 Year must consume the reclaimed vertical space and enlarge/fill the available Mind card rather than staying sized for a legend-present envelope.
- Consolidated palette requirement: expose **exactly seven 10-colour product scales** and remove the other current product choices. First approved palette reference: Fluvi-A `#EDF7F6,#D6F1EF,#B7E9EA,#8FDADF,#67C7DD,#56B0E1,#668FE3,#816FE1,#A05FDD,#C05CD7`; B3M-A `#F4F7FB,#FFEEDA,#FFD5AF,#FFB15C,#FF8D64,#FF6B6B,#F536BD,#D03CB0,#A237BF,#821AC2`; Meadow Green `#D9ED92,#B5E48C,#99D98C,#76C893,#52B69A,#34A0A4,#168AAD,#1A759F,#1E6091,#184E77`; Soft Rainbow `#FBF8CC,#FDE4CF,#FFCFD2,#F1C0E8,#CFBAF0,#A3C4F3,#90DBF4,#8EECF5,#98F5E1,#B9FBC0`; Peachy Delight `#D8E2DC,#ECE4DA,#FFE5D9,#FFD7D7,#FFCAD4,#F9BBC6,#F4ACB7,#C89AA0,#B28D94,#9D8189`. Second approved stretched visual reference is sampled from the generated asset centres: Fluvi-B `#E9E0FC,#DCCCFD,#CAB0FB,#BFA1FA,#B18EF8,#9570ED,#8B65E5,#7657C5,#684EB1,#493590`; B3M-B `#FCF0E4,#FED2A6,#FCB476,#F5956A,#F97184,#F96B8B,#EE46A1,#BF3CB6,#843BC3,#47188C`. Every scale remains ten authored stops; do not downsample them to five. The second reference encodes the user's stated rule that intermediate tones are inserted between neighbouring anchors. Palette names may be disambiguated in the tuner, but no eighth product palette is implied.
- **UNPROVEN:** exact final morph visual choreography; whether `hó végi maradék` should ever mean a cumulative account balance beyond the existing proven `Zárás/net` semantic; multi-category/multi-partner info-card compression semantics; exact physical APK identity for the most recent screenshots because no build marker is visible.
- **MISSING EVIDENCE:** production-parent RED→GREEN month tap/morph test, one-selection/stale-year lifecycle proof, direction-independent three-metric proof, prepared category/partner monthly scoped-value model and tests, actual-paint/morph bounds, long-name/multiple-facet overflow behavior, palette migration tests for exactly seven ten-stop scales, no-legend 4×3 adaptive fill test, five-row Month production geometry fix, compact-slider caption removal test, final CI/APK/final-SHA SCIP, and user physical validation.
- Prompt-writer change for this feedback: journal only, build-trigger-free `[skip ci]` commit. No application source, test, workflow, graph, milestone or runtime behavior is changed by the prompt writer.
- Physical validation of the eventual candidate APK: `PENDING — USER ONLY`.


## 2026-09-18 — Palette reduction + Mind Month temporal-response regression; Day presentation discussion reopened

- New user product feedback: remove `Soft Rainbow` and `Peachy Delight` from the Mind heatmap palette selector. The delivered seven-palette set therefore becomes **five** retained product scales: Fluvi, B3M-MY3, Meadow Green, Fluvi — stretched, B3M-MY3 — stretched. No replacement palettes were requested.
- New physical performance feedback: Mind Year (the annual surface with 12 MonthCards) has the desired behavior — year changes immediately update the heatmap and immediately trigger the matching Header score / Header colour / line-chart change. Mind Month (one selected-month day layout) does not match that behavior: both the heatmap and Header score/colour/line chart visibly lag. Product requirement: while Month is active, **both parent-year changes and selected-month changes must publish the matching Month heatmap and Header semantic frame immediately**, using the already-successful Year flow as the architectural reference rather than inventing a separate delayed pipeline.
- Exact tested APK/source identity for this new physical report is **MISSING EVIDENCE** because the feedback contains no embedded build marker. Do not infer physical source identity from chronology alone.
- Remote branch audit before this journal-only entry: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD is `c36a3e4bba3dd7507e98277846bd0bb4baf27cd5`, a journal-only child of application commit `33facc5f1bfcee5d02abd07dd16448aa0173604b` (`feat(mind): add MonthCard inspection and converge presentation`). The journal commit modifies only `docs/FLUVI_ENGINEERING_JOURNAL.md`; the latest application source is therefore `33facc5f...`.
- **PROVEN current palette owner at 33facc5:** `MindYearHeatmapPaletteStyle` has exactly seven enum cases and still includes `softRainbow` and `peachyDelight`; their tuner labels and resolver/test consumers must be graph/source audited before removal. The requested product state is now five cases, not seven.
- **PROVEN Year fast-path architecture at 33facc5:** Year has a renderer-acknowledged transient temporal admission path. `noteSegmentedSummaryComponentVisualTargetPainted(...)` accepts only the Year component/Year plane and routes to `_admitMindYearHeatmapForSegmentedTarget(...)`; that method synchronously publishes the Year heatmap and the matching behavioral score from already-resident prepared data before canonical navigation catch-up. Its source comments explicitly require heatmap + Header score to advance together and it performs no repository/index read on that publication path.
- **PROVEN Month architectural asymmetry at 33facc5:** Month currently publishes through the ordinary canonical-state path `ensureMindTemporalVisualProjection() -> _installMindMonthHeatmapProjection(navigation.state) + ensureMindBehavioralScoreProjection()`. `_installMindMonthHeatmapProjection` builds/selects the selected `state.monthCursor` frame from resident prepared membership, but there is no Month equivalent of the renderer-accepted transient Year admission transaction. The visual-target acknowledgement path is hard-gated to `DashboardTemporalAnchorComponent.year` and `TimePlane.year`. This asymmetry is consistent with the user's physical Year-fast / Month-lag report, but without a fresh current-build trace the exact runtime stall owner remains **UNPROVEN**.
- Required future forensic direction: compare accepted target -> heatmap publish -> score publish -> Header paint for Year versus Month, including both Month-plane parent-year changes and retained-child month changes. The target design is not a timer/debounce/cache workaround; it is the same prepared, synchronous, identity-safe publication principle that already works in Year. Preserve Time controller/ScrollPosition/physics ownership and latest-wins semantics.
- Current Drive documents remain historical for this new feedback: `Fluvi mind heatmap` last modified 2026-09-16 and `Fluvi logs time fling` last modified 2026-09-15. No post-feedback runtime capture is available yet.
- Day-mode product discussion is deliberately **OPEN — DO NOT IMPLEMENT YET**. Prior user decisions recovered from project history: the Day visual should remain one card, not multiple cards; the previously preferred activity concept was 24 hour cells in one card (no grouped subcards), while the behavioral Header score must **not** be derived from hourly subdivisions. Later product clarification requires the Header to use the selected calendar day's point from the same canonical daily behavioral series used by broader Mind views, so the same date + direction + filters cannot receive a different score merely because Day is active.
- **PROVEN current structural topology at 33facc5:** `TimePlane` has only `sum/year/month`. A selected day already exists as `DayScope` via Month-plane `retainedChildScope` when the rail is open, and `effectiveScope` becomes that DayScope. The Mind body, however, still renders `MindMonthHeatmapViewport` for every `TimePlane.month` state; there is no Day-specific Mind body renderer yet. Therefore a future Day UI can potentially remain a Month-plane child presentation rather than introducing a fourth global TimePlane, but that product/architecture choice is pending the current discussion.
- Candidate Day direction for discussion, not implementation authority: one Day card with a 24-cell hourly activity fingerprint, while Header score/colour/line-chart uses the selected daily behavioral point and a daily-context series (not an hourly score series). Hour cells would visualize transaction activity only; they must never redefine the score. Exact cell semantics, summary rows, tap behavior and Header chart window remain user-decision items.
- **MISSING EVIDENCE / pending decisions:** fresh Month performance trace tied to exact app SHA; RED→GREEN Month accepted-target latency/paint tests; whether Day should activate when Month rail opens on a DayScope; exact 24-cell arrangement/labels; whether hour cells encode amount, transaction count, or another activity metric; whether hour cells are tappable; Day summary metrics; exact daily-context Header chart window.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, workflow, graph or milestone file is modified. No coding-agent prompt is produced yet because the user explicitly requested Day-mode design discussion first.


## 2026-09-18 — Day presentation approved; include Month fast-path + five-palette reduction in next delivery

- User approved the previously discussed Day product concept and requested one implementation prompt that includes this Day feature plus the immediately preceding corrections: remove Soft Rainbow/Peachy Delight and repair Month year/month temporal-response latency using the already-fast Year publication pattern.
- **Approved Day product contract:** Day remains a child of the existing Month plane rather than adding a fourth global TimePlane. It activates when Month is open to a concrete `DayScope`/selected day. The Mind body is one card, not multiple cards and not six grouped dayparts.
- Day body uses one **4 × 6 grid of exactly 24 hour cells**, ordered 00–23 with no grouped subcards. Cell intensity represents the **sum of admitted transaction amounts in that local hour**, after the existing direction/category/partner/search/amount-range semantics. Cell colours come from the same active Mind heatmap palette authority as Sum/Year/Month. The hour cells are an activity fingerprint only and must not define or recalculate behavioral score.
- Approved Day information composition from the discussion: first horizontal row `Óránkénti aktivitás` on the left and `N aktív óra` on the right; second horizontal row selected calendar date on the left and the selected day's total amount on the right; then the 24-cell grid; then one compact `Összesen` total row. No initial per-hour tap/morph inspector is requested.
- **Approved Day Header contract:** Header score and Header colour use the selected calendar day's canonical daily behavioral point from the existing `MindBehavioralScoreProjection`; there is no hourly score algorithm. The same date + direction + filters must not receive a different score merely because Day presentation is active. Header line chart shows a **31-day rolling daily context ending at the selected day**. This is a daily series, not a 24-hour series. The selected-day point remains the endpoint/current Header score.
- **PROVEN existing Day score foundation at application source 33facc5:** production test `MBS-01` already proves that a visible Month-plane rail child publishes `DayScope` and retargets `mindBehavioralScore` to that exact selected day before settle. Current Core `_publishMindBehavioralScoreForVisibleFrame` derives target and chart request from the visible frame's exact `timeScope`. Current `_mindScoreSeriesRequest` gives DayScope a one-day chart window, so the approved 31-day chart context is a presentation/request gap, not a requirement for a new score owner.
- **PROVEN Day body gap/data availability:** CoreDashboard currently hides `mindTemporalHeatmapVisible` specifically when `TimePlane.month && isRailOpen`, so the selected DayScope has no Mind body renderer. `DashboardLedgerEntry` already contains `bookedLocalTimeMinutes`, sufficient to identify local hour. However `MindYearHeatmapPreparedContribution`, the resident Mind projection transport reused by Sum/Month/Year, currently carries only ordinal, local epoch day and amount; it drops local time minutes. A Day hourly projection therefore needs a bounded prepared-time field/read-model addition or source-equivalent prepared owner — never a repository read or raw-row scan on each day tick.
- **Month latency requirement remains:** while Month body is active, both parent-year and month target changes must update Month heatmap + Header score/colour/chart together on the accepted target, with Year's existing synchronous renderer-acknowledged prepared publication as the architectural reference. Exact runtime stall remains **UNPROVEN** without a current-build trace; implementation must first add target→heatmap→score→paint instrumentation/RED coverage for Month rather than simply copying private Year methods.
- **Palette product state is final for this delivery:** exactly five ten-stop scales remain: Fluvi, B3M-MY3, Meadow Green, Fluvi — stretched, B3M-MY3 — stretched. Soft Rainbow and Peachy Delight must be removed from enum/tuner/resolver/tests; no replacements.
- Matching SCIP is available for exact application source `33facc5f1bfcee5d02abd07dd16448aa0173604b`: tooling commit `0f81d535c8e8ee2778b50cf46e6733fc23bceb30`, `scip_dart 1.6.2`, raw index SHA-256 `4c2cad6557be62ef4498e9815c8d9f8013896690265f314a174b64af693e6888`, 474 documents / 316,161 occurrences / 10,869 repository symbols. Graph/source audit identifies direct consumers for the Month projection, temporal visual coordinator, Year accepted-target callback, DayScope/TimePlane and palette enum.
- Latest relevant Drive revisions are unchanged and historical: `Fluvi mind heatmap` rev 5, session `fluvi-1789566368119437`, retained 1200..2199 with no gaps/conflicts/no build marker; `Fluvi logs time fling` rev 51, session `fluvi-1789452354097594`, deduplicated 2105..3114 with no gaps/conflicts and only historical USER_MARK build `288cc35584ec5cb6e41eb237523104922a2c7393`. Neither contains the current Month physical regression or approved Day body.
- **MISSING EVIDENCE:** exact physical APK identity for the Month lag report; fresh target-correlated Month trace; Day 24-hour RED→GREEN projection/render tests; Day selected-day score parity vs broader-view canonical point; 31-day chart-context proof; final CI/APK/final-source SCIP; user physical validation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source/test/workflow/graph/milestone code is modified by this record. Physical validation of the eventual candidate remains `PENDING — USER ONLY`.


## 2026-09-19 — Day→Month blank-body regression + 10/20 heatmap scale, interactive score crosshair, compact legend placement, larger Mind body, segmented/mirrored startup defaults

- New physical feedback with Android screenshot: after navigating from the new Day view back to Month, the Summary shows the Month target and the compact range/legend render, but the Mind heatmap body is blank. The Month day-cell card appears only after changing month. The supplied screenshot shows Expense, June 2027, a blank white Mind body, the Meadow-style ten-swatch legend and the compact range; the screenshot itself contains no embedded source/build SHA, so exact APK identity remains **MISSING EVIDENCE**.
- Remote branch audit before this journal-only entry: fix/mind-year-heatmap-calendar-direction-fluvi-20260913 HEAD is application commit c1b12ade9745ce96143ce3c6a275c2c12ac4d349 (feat(mind): publish Month and Day temporal activity), parent 40c0080bf2ada3ecafcc71f12257838090c725bf. CI run 35392071533 for exact c1b12 passed test-flutter, test-core, dashboard-paths and build-human-diagnostic-apk; run-dashboard-profile remains red at the inherited frame_timing_headroom is invalid: null gate. Human release fluvi_HUMAN_DIAGNOSTIC_c1b12ad.apk is 83,399,985 bytes, SHA-256 4ff7c69fc680e0c6936037b91cd23568c2642b2a361d818de756010a523fa070, release target c1b12.
- Matching SCIP is exact for c1b12: tooling commit bcdeebb25ab2d4a74a15a8e525e4320b40f62844, scip_dart 1.6.2, raw index SHA-256 01da7f1ea85cc3d655a0d82ef15f53861651ab9efad97bdbfbea22409fa821eb, 474 documents / 318,426 occurrences / 10,908 repository symbols. Impact review includes Core temporal admission, Mind Header chart + presentation settings, Mind heatmap settings/resolver/body, compact Query range, Summary variant/presentation controllers and their direct tests.
- **Fresh log evidence:** connected Fluvi mind heatmap is now revision 6, modified 2026-09-19T05:41:59.038Z. Full exported text snapshot is 373,368 bytes, SHA-256 46682010d3a002a7b2eafc9414cc55c5d2bc71e355aef198c8e10990cb8daa95. Session fluvi-1789796494332681, sessionEventCount 61,438, retained seq 60,439..61,438, zero duplicate/conflicting sequence and zero retained-window gaps; 60,438 earlier events were evicted by the rolling tail. No USER_MARK/build SHA is embedded.
- **PROVEN Day→Month failing boundary from revision 6:** seq 60,623 publishes an exact prepared source=level Month target for expense|month:2027-06 with resourcesReady=true phaseAReady=true repositoryRequests=0 indexBuilds=0; seq 60,632 accepts temporalScope=MonthScope; range/slider and Month LogBox then bind/paint (seq 60,633..60,657). In that entire Day→Month level transition there is **no** MIND_TEMPORAL_HEATMAP|FRAME_PUBLISHED kind=month and no Mind accepted-target Month admission. Later, an actual month-component change produces the missing Mind publications: May at seq 61,346/61,348 and June at seq 61,398/61,400. This directly matches the physical report that Month appears only after changing month.
- **PROVEN source cause at c1b12:** the new Month renderer-acknowledged fast path covers component targets via noteSegmentedSummaryComponentVisualTargetPainted(...), but Day→Month is a **level** transition through navigateExperimentalTemporalSelection(... source='level'). On a published level target Core calls _recordNavigationSelection(...), which republishes Mind from canonical navigation.state; the currently visible MonthScope candidate is not passed as the Mind semantic target. ensureMindTemporalHeatmapProjection() explicitly preserves a renderer-visible open-rail DayScope and otherwise dispatches from canonical state.effectiveScope. _onVisibleFramePublished has an explicit DayScope body install but no symmetric MonthScope level install. CoreDashboard can therefore switch its Month body presentation while mindTemporalHeatmap still carries the preceding Day frame; MindMonthHeatmapViewport rejects that frame type and the body is blank. Existing MONTH-LIVE-01 is a false-green for this path because it tests Month-plane **component** acknowledgement from a rail-closed Month origin, not DayScope→MonthScope level closure.
- New heatmap product setting: user wants selectable current **10-colour** scale resolution or a new **20-colour** resolution for every retained palette. Current ten-stop behavior remains the default and must be byte-value compatible. Mathematical note: preserving all ten anchors and inserting exactly one midpoint between each adjacent pair yields 19 colours, not 20. To satisfy the requested true 20-step option without arbitrarily over-refining one interval, the proposed 20-colour lists are 20 equally spaced samples of the existing ten-anchor piecewise sRGB/Flutter Color.lerp curve (t = 0/19 ... 19/19), preserving both endpoints and the same hue path.
- Proposed exact 20-colour Fluvi: #EDF7F6,#E2F4F3,#D7F1EF,#C9EEED,#BAEAEB,#A8E3E6,#95DCE1,#82D4DE,#6FCBDD,#63C1DE,#5AB6E0,#59A9E1,#6199E2,#6A8AE3,#777BE2,#846DE1,#9366DF,#A25FDD,#B15DDA,#C05CD7.
- Proposed exact 20-colour B3M-MY3: #F4F7FB,#F9F3EB,#FEEEDC,#FFE3C8,#FFD8B4,#FFC890,#FFB769,#FFA65F,#FF9562,#FF8466,#FF7469,#FD607C,#F847A3,#EF37BB,#DE3AB5,#CB3BB2,#B539B9,#A035BF,#9128C1,#821AC2.
- Proposed exact 20-colour Meadow Green: #D9ED92,#C8E98F,#B7E48C,#A9DF8C,#9CDA8C,#8CD38F,#7CCB92,#6BC295,#5ABA99,#4AB09D,#3CA6A1,#2E9BA6,#1F91AA,#1787AB,#197DA4,#1A739E,#1C6997,#1E5F90,#1B5783,#184E77.
- Proposed exact 20-colour Fluvi — stretched: #E9E0FC,#E3D7FC,#DDCDFD,#D4C0FC,#CCB3FB,#C6AAFB,#C1A3FA,#BB9BF9,#B492F8,#AA86F5,#9C78F0,#936EEB,#8E68E8,#8863E0,#7E5CD1,#7556C3,#6E52B9,#664DAF,#5841A0,#493590.
- Proposed exact 20-colour B3M-MY3 — stretched: #FCF0E4,#FDE2C7,#FED4A9,#FDC592,#FCB77B,#F9A972,#F69A6C,#F68A72,#F8797F,#F96F86,#F96D89,#F76390,#F1529A,#E744A4,#D040AE,#B93CB7,#9D3BBE,#8139C0,#6429A6,#47188C.
- New Mind Header chart feature: keep the existing static X-label visible/hidden setting, but make the expanded line chart inspectable by tap. A clean tap selects the nearest real immutable MindBehavioralScorePoint in temporal X space and renders a vertical white crosshair at that point; tapping another point moves it; tapping the already-selected point/line toggles it off. The top label is that canonical point's rounded score (NN/100), not interpolated financial math. Bottom label formatting is mode-aware: Year = short month + day (e.g. aug 26), Sum = year + short month, Month = day only; Day uses short month + day because its approved rolling 31-day chart can cross a month boundary. Crosshair state is presentation-local and clears on a new series/domain, not persisted.
- **PROVEN chart architecture gap:** MindHeaderScoreChart is currently Stateless and wrapped in IgnorePointer; its painter places score points by list index while static time labels map the actual epoch-day domain. A tappable exact-time crosshair therefore needs one shared temporal-X mapping for line points, labels, hit testing and crosshair; it must select existing immutable score points, never synthesize/interpolate a new score.
- Mind body-space request: reclaim useful heatmap height above the range control. Proposed target geometry is to shrink the fixed compact footer lane from 74px to 68px (moving the slider/footer stack 6px closer to the card bottom) and the separate above-slider legend lane from 28px to 16px, subject to mounted no-clip/hit-target proof. This returns 18px to the heatmap body in the default above-slider legend layout. Do not shrink RangeSlider interaction/touch semantics or Min/Max text to achieve this.
- New legend placement setting: retain legend visibility independently, and add above slider (current concept, compact 16px lane) versus below slider — between Min/Max. In the inline/below layout the separate legend lane is structurally zero; a compact center accessory is rendered inside the compact range's Min/Max row below the slider. Proposed inline swatches: 10-colour mode uses 6×6px squares; 20-colour mode uses 4×4px squares; 1px gaps are acceptable to keep the center block ≤100px. QueryAmountRangeControl must remain the one range owner; the generic Query control must not gain Mind palette authority — at most it accepts a presentation-only center accessory from Mind.
- Startup product default: SummaryPill must start in SummaryPillVariant.segmented and segmented orientation must start SummarySegmentedOrientation.mirrored. Current source defaults are legacy + normal. Existing tuner choices remain selectable; this is a session startup/default change, not new persistence. CoreDashboard's _lastSummaryPillVariant bookkeeping must initialize from the actual controller default so startup does not fabricate a Legacy→Segmented transition epoch/event.
- **MISSING EVIDENCE / future gates:** RED→GREEN Day→Month level transition test and actual Month paint; exact build marker for the physical screenshot/log; 10/20 setting/tile/legend parity tests; below-slider legend bounds at 10/20 resolutions; reclaimed body/footer RenderRects and slider hit target; crosshair temporal-X/nearest-point/toggle/series-reset/mode-label tests plus Header-drag non-regression; segmented+mirrored first-frame default without synthetic transition; final CI/APK/final-source SCIP and user physical validation.
- Prompt-writer action: journal only, build-trigger-free [skip ci] commit. No application source, tests, workflow, tooling graph or milestone file is modified. Physical validation of the eventual candidate remains PENDING — USER ONLY.


## 2026-09-19 — Day→Month exact visible-frame admission repair

- Application commit `e83197d4fbcc3b5f3483e5d2a2b12e7f9888d24c` repairs the exact c1b12 DayScope→MonthScope level-close boundary. This follows the frozen `Fluvi mind heatmap` revision 6 evidence (373,368 bytes; SHA-256 `46682010d3a002a7b2eafc9414cc55c5d2bc71e355aef198c8e10990cb8daa95`): seq 60,623 publishes the prepared source=level `expense|month:2027-06` target, seq 60,632 accepts MonthScope, and no Month frame/admission exists until later component crossings 61,346/61,348 and 61,398/61,400.
- **RED evidence:** new mounted `LEVEL-MONTH-01/02/03/04` starts from a real `CoreDashboard` Mind Day body (June 6, 2027), executes only `navigateExperimentalTemporalSelection(plane: TimePlane.month, isRailOpen: false)`, pumps the first accepted frame, and failed against c1b12 because `mindTemporalHeatmap.value` was `MindDayHeatmapFrame`, not `MindMonthHeatmapFrame`.
- **Repair owner:** `DashboardCoreController._onVisibleFramePublished` now recognizes the exact renderer-visible closed MonthScope frame. It delegates to the same Core-owned `_publishMindMonthBodyAndScoreForExactTarget` transaction used by Month component admission. The target must equal the visible Month scope and current navigation target; the operation uses the existing resident prepared Mind base (`allowBaseAdmission: false`) and has an identity-current guard. It publishes body and Header score together or fails closed. No widget retry, timer, delay, Query mutation, repository read, or index build was added.
- **GREEN evidence:** `LEVEL-MONTH-01/02/03/04` now proves a `MindMonthHeatmapFrame` for 2027-06, a positive-bound `mind-month-heatmap-grid`, absent Day/unavailable body, and Header series request tied to the Month domain. It observes a `MIND_TEMPORAL_HEATMAP|ACCEPTED_TARGET_ADMISSION` record with `source=visibleFrameLevelAcceptance`, `published=true`, `repositoryRequests=0`, and `indexBuilds=0`. The prior `MONTH-LIVE-01` component positive control and `DAY-HOST-01` Day fast path also pass.
- Formatting evidence: Dart format check passes for the two changed Dart files. No Time physics/controller/position, Avatar, Query range semantics, score algorithm, Header colour mapping, LogBox, Budget, Room/Kotlin/schema, Year inspection, or `MILESTONE_COMMITS.md` change is in this commit.
- **Still unproven:** exact source identity of the user’s physical screenshot; broader latest-wins and repeated level-round-trip coverage; device animation quality; final CI, normal human APK, exact final-source SCIP, and user physical validation. The inherited profile failure `frame_timing_headroom is invalid: null` is not reclassified as green.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Mind card paging/charts, fixed legend, annual height parity, and contained BottomNav feature contract

- This feedback is primarily a **new presentation/feature contract**, not a runtime bugfix cycle. The user explicitly said fresh runtime log review is not required for this feature prompt; no new runtime causality is claimed from Drive logs in this entry. Current branch HEAD before this journal-only record is `128c72992fbb571dd3cac9e89ac38b226f0897f5`, itself documentation-only. The current authoritative application source remains `5893b4568f7061c6e643e7ce767ac76716c7c8d1` (`fix(summary): preserve startup layout and rail profile`).
- Matching SCIP remains tooling commit `2433548f311fd23711da28ec957b90f39b34560a`, with `manifest.source_head=5893b4568f7061c6e643e7ce767ac76716c7c8d1`, `scip_dart=1.6.2`, raw index SHA-256 `49eb5689a8f29a9047ae9031ea92863e53fdf75412c4d1d4a6ffb2093480bba5`, 474 documents / 268,973 occurrences / 10,982 repository-defined symbols. Graph definitions were source-verified for `MindYearHeatmapPresentationSettings`, `MindSumHeatmapViewport`, `MindYearHeatmapViewport`, `DashboardShellPresentationSettings`, and `Bnb03BottomNavigation`.
- `MILESTONE_COMMITS.md` still protects `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` as the preferred physical overall-performance / Avatar-motion floor. This feature must not retune Time/Avatar physics, duplicate canonical Query ownership, or trade interaction correctness for presentation work. Physical validation of the current 5893 application remains `PENDING — USER ONLY`.
- **Legend contract is now final:** remove the Mind heatmap legend visibility and placement settings from the user-facing presentation controls. The palette legend is always visible in the current compact **under-slider / between Min–Max** location. Keep one palette authority and one `QueryAmountRangeControl`; no second slider/range owner and no above-slider legend lane. Current source still has independent `showHeatmapLegend` plus `MindHeatmapLegendPlacement { aboveSlider, inlineBetweenRangeValues }` and corresponding tuner controls, so this is a concrete presentation simplification.
- **Year-card height parity:** 4×3 and 3×4 annual layouts must use the same outer Mind-card/body height. The 4×3 screenshot shows avoidable white space between the final month row and the slider; reclaim that space rather than shrinking MonthCards/day cells. Current source gives only `fourColumns` a `requiredMindModeContentExtraHeight => 50`, while the 4-column viewport already has its own non-scrolling three-row fit solver. The implementation must prove the correct geometry with mounted bounds tests before changing this source knob; MonthCard/day-cell extents are protected by this product requirement.
- **Mind Sum becomes a two-page horizontal card:** page 1 is the multi-year heatmap, page 2 is a line-chart view. Horizontal paging is presentation-only and must not create a second Query/data authority or steal the compact amount-slider's horizontal drag. Sum page 1 title becomes `Többéves aktivitás`; below it is a gray explicit period + month count (for example `2025–2027 · 36 hónap`). Remove the current tertiary `Éves aktivitás` line. Each year becomes one two-row unit: top row has year left and a compact rounded annual amount right (for example `7,1 M Ft`, `646 k Ft`); second row is the full-width 12-month heatmap for that year. Current 5893 source instead uses `Többéves hőtérkép`, `N év · N hónap`, a tertiary `Éves aktivitás`, one global month-axis row, and one 29px row containing year + cells + exact total.
- **Sum page 2 line-chart visual contract:** keep the same year-by-year information hierarchy, but replace the heatmap row with a continuous financial trend chart. Use thin vertical dashed month separators, real month-center markers, a line capable of showing real intra-month movement rather than only twelve straight monthly values, and a light colored area/veil under the line that fades downward. The screenshot's extra statistic cards/lists are explicitly out of scope. Do not copy screenshot-only titles or invent tooltip/stat products. The series must be derived from real immutable prepared financial time samples under the same active Mind filter identity; do not fabricate intermediate financial values merely to make the curve wavy.
- **Mind Year also becomes a two-page horizontal card:** page 1 remains the annual heatmap; page 2 is exactly one 12-bar monthly chart. For each month, the light-gray background bar is that month's complete total for the selected direction (total expense in Expense, total income in Income); the colored foreground bar is the currently filtered scope for that same month. Treat it as a partial bar: foreground height / background height equals filtered amount / complete directional monthly amount. With no secondary filter, the whole bar is colored. Required chart chrome is limited to the chart itself: X-axis month initials, a readable Y-axis value scale, and thin horizontal scale/grid lines. Do **not** add the reference image's stat cards or Top-3 list.
- The exact denominator/numerator implementation for the new Year comparison must reuse the existing prepared immutable financial authority: denominator = selected year/month + selected direction before secondary filtering; numerator = the same month under the current complete active secondary filter identity. Source/graph-verify category/partner/search/amount-range semantics and zero-total handling; do not introduce an independent query engine or per-paint repository read.
- **BottomNav gets an additional selectable style, not a replacement.** Preserve the current BNB-03 raised/protruding centre FAB and contour as a selectable existing option. Add a new contained/flat option in the existing shell presentation settings/tuner: the centre FAB is somewhat smaller, fully inside the BottomNav height, the entire top edge is horizontal/flat, and there is no central circular arc/notch/protrusion. Current source has only outer edge-shape and top-border settings; `Bnb03BottomNavigation` hardcodes a 75px bar + 24px top overflow + 96px outer FAB shell and generates a central circular contour. The new variant must preserve safe-area behavior, item semantics and existing style geometry byte-for-byte/contract-for-contract.
- **PROVEN from current source:** current legend visibility/placement are independently configurable; inline legend already exists as a read-only center accessory in the one compact range owner; only 4×3 requests +50 Mind content height; current Sum hierarchy differs from the approved redesign; BottomNav has no overall layout-style selector and its current centre FAB/arc is hard-wired into one contour coordinate system.
- **UNPROVEN / implementation-discovery boundary:** the smallest existing prepared-data owner to feed the new Sum intra-month trend series and Year full-vs-filtered monthly comparison must be source/graph audited before adding projection code; exact pager ownership should reuse or extend an existing presentation pager pattern where appropriate rather than creating duplicate state. Graph relationships are navigation evidence only.
- **MISSING EVIDENCE:** final mounted geometry for equal 3×4/4×3 outer height without changing MonthCard/day-cell extents; RED→GREEN horizontal pager/slider gesture-arena coverage; exact Sum trend projection tests; exact Year denominator/numerator comparison tests for Income/Expense/filter/no-filter/zero-total; new contained BottomNav bounds/hit/semantics/golden evidence; final CI/APK/final-source SCIP; user physical validation.
- Prompt-writer action for this feedback: this journal-only update is the only repository mutation, committed build-trigger-free with `[skip ci]`. No application source, test, workflow, tooling graph or milestone file is modified by the prompt writer. The coding agent must read this journal **in full before implementation and after every application commit append factual commit/evidence history without rewriting prior entries**.


## 2026-09-19 — Permanent inline Mind legend and shared Year height parity guard

- Application commit `1bf1fa1e6ae4218e8abc8c351b0e7dae3dc3b9da` starts the approved Mind paging/BottomNav delivery with its first presentation unit. It is based on application source `5893b4568f7061c6e643e7ce767ac76716c7c8d1` and pre-change matching SCIP tooling `2433548f311fd23711da28ec957b90f39b34560a`. This is feature/presentation work; the user explicitly excluded a fresh Drive runtime-log audit, so no new runtime causality is claimed.
- Changed owners: `MindYearHeatmapPresentationSettings` no longer has `showHeatmapLegend`, `MindHeatmapLegendPlacement`, or their setters. The Mind surface now always supplies the existing resolver-owned inert inline accessory to the sole `QueryAmountRangeControl`; the tuner no longer offers visibility or placement controls, and `_MindTemporalBody` has no above-slider legend lane. The 10/20 palette resolution setting and the standard Query presentation remain intact.
- **RED evidence:** the first focused tuner/mounted host run found the obsolete legend switch and no inline legend. After removing the old four-column-only `+50px` envelope, `YEAR-6R-09/10` reproducibly measured 15px of vertical deficit: the compact viewport was 232px, while the three two-footer MonthCard rows plus padding required 247px. This was fixed at the presentation-boundary owner, not in card/day-cell sizing.
- **Repair:** the former 4×3-only `+50px` request is gone. A measured 15px annual fit guard is active only when both optional MonthCard footer rows are visible, and applies equally to 2×6, 3×4 and 4×3 Year layouts. It preserves one outer annual envelope, default 3×4/4×3 parity, and the dense two-footer 4×3 zero-scroll case. It does not alter financial data, Query semantics, range gestures, Time/Avatar physics, MonthCard width authority, day-cell algorithm, score, LogBox, Room/Kotlin/schema, or `MILESTONE_COMMITS.md`.
- **GREEN evidence:** Ubuntu/proot focused settings, temporal viewport, Year viewport, mode host, tuner and range-control suite passed with 79 tests. The tests prove one inline 10/20 legend in Sum/Year/Month/Day, no external lane or user legend controls, RangeSlider element stability, 68px footer bounds, shared 3×4/4×3 body bounds, reference four-column card width 83.5px / width-derived cell authority 8.5px, 12 cards and zero-scroll two-footer 4×3. `dart format --output=none --set-exit-if-changed` reported 0 changes for the ten changed Dart files; `git diff --check` passed.
- **Still unproven:** device screenshot/rect acceptance, full analyzer/fast/boundary suite, final CI/human APK/final-source SCIP, and the remaining Sum pager/line chart, Year bar page and BottomNav contained-flat units. The known profile condition `frame_timing_headroom is invalid: null` is not reclassified. Physical validation: `PENDING — USER ONLY`.

### CI correction for `1bf1fa1e`

- GitHub Actions run `35441317120` for exact application SHA `1bf1fa1e6ae4218e8abc8c351b0e7dae3dc3b9da` is **FAIL**, not globally green: `dashboard-paths` and `test-core` passed, but `test-flutter` failed in `flutter analyze --no-fatal-infos` on one new `unused_import` warning in `test/core/design/dashboard_geometry_resolver_test.dart`. The curated Flutter suite, profile and `build-human-diagnostic-apk` were skipped, so there is no APK for this SHA.
- The unused import was a mechanical leftover from retiring the four-column-only setting owner. The current worktree removes it; local Ubuntu/proot `flutter analyze --no-pub` then passed with no issues. That correction will be included in the next application SHA and must receive a fresh CI/APK attempt. This does not change the inherited profile classification or constitute physical validation.


## 2026-09-19 — Pageable multi-year Mind Sum and real daily trend anchors

- Application commit `1635f46c9a6815e8775ba008a086adc4dade5012` delivers the second approved presentation unit. It follows `1bf1fa1e` and remains rooted in the original authoritative application source `5893b4568f7061c6e643e7ce767ac76716c7c8d1`; the initial matching SCIP was tooling commit `2433548f311fd23711da28ec957b90f39b34560a`. It is feature work only: the user explicitly excluded a fresh Drive runtime-log audit, so none was performed or used for causality claims.
- `MindSumHeatmapProjection` now makes one bounded prepared-contribution pass at build time to bucket exact local epoch days alongside its existing monthly buckets. A preview reads the same `MindHeatmapAmountRangeBucket` data and exposes only non-empty immutable `MindSumHeatmapDailyPoint`s. `SUM-LINE-01` was first RED because the frame type/API did not exist; it is now GREEN for nonuniform dates, range refinement, no fabricated day, and four build-time contribution touches. No Room/repository/raw-ledger scan is introduced on slider preview.
- `MindSumHeatmapViewport` now keeps page selection and each visual page's scroll controller locally. Page 0 uses the approved `Többéves aktivitás` title, exact period/month subtitle, and two-row year units with existing resolver-owned 12-cell heatmap and narrow compact amounts (`7,73 M Ft`, `646 k Ft`). Page 1 uses the same yearly identity with a CustomPainter whose anchors are real daily points, eleven dashed month separators, twelve month-centre markers, and a clipped color-to-transparent under-line fill. It adds no statistic cards, Top-3 list, score calculation, data store or Query owner.
- `SUM-PAGER-01/02/03` was RED before the new PageView/chart APIs. It is GREEN for page 0→1→0, real chart anchors, slider horizontal-drag isolation, one stable `QueryAmountRangeControl` element, unchanged admitted temporal-frame identity and both vertical handoff cases. Discovery during the RED/GREEN cycle: a `PageView` suppresses the nested ListView's usual boundary overscroll notification. The repair is a passive `Listener`, not a competing recognizer: it forwards only slop-clearing vertical movement at the active page's actual outgoing boundary to the existing `DashboardUpperVerticalGestureCoordinator`. The inner list remains the owner for in-bounds vertical scroll, and the footer/RangeSlider is outside the pager.
- Validation: Ubuntu/proot focused Unit 1+2 command passed **90 tests**; `flutter analyze --no-pub` passed with `No issues found!` in 144.9s; `git diff --check` passed. The Termux/proot formatter reports a false `Changed` status for five Dart files even with identical before/after SHA-256 values; no byte-level formatting difference existed. The 1bf CI analyzer failure's unused test import is removed in this application SHA, so a fresh exact-SHA workflow is required.
- No Time/Avatar physics/controller/position, Core publication, canonical Query semantics, score algorithm, Header colour, Budget, LogBox, Room/Kotlin/schema, global cache ownership or `MILESTONE_COMMITS.md` diff is in this unit. Still unproven: focused painter golden/raster, direct Core Query/Time counters, later Year bar and BottomNav units, final full suite/CI/human APK/exact-source SCIP, and Android physical acceptance.
- Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Mind Year partial bars and shared pager-boundary handoff

- Application commit `9877c77aea24326f2816a52d6951a6f0151f8854` delivers the approved Mind Year page-two comparison. This continues presentation work after `1635f46c`; no fresh Drive runtime audit was required or performed. The initial exact graph remains the 5893 tooling graph `2433548f311fd23711da28ec957b90f39b34560a`; final-source SCIP regeneration remains required.
- `MindYearHeatmapPartialBarSeries` reads each full gray background from the admitted frame's selected-direction `monthlyAggregates` and its colored foreground from the current `frame.month(month)` day totals. It creates exactly 12 month values, clamps only an impossible filtered-over-full paint condition while issuing a debug diagnostic, and derives a zero-based deterministic nice scale from full values. There is no Query, repository, Room, prepared-cache or raw-row access in this renderer/preview path.
- `MindYearHeatmapViewport` is now page-local: existing annual heatmap is page 0 with its existing external scroll-controller identity, and page 1 is a constrained bar painter with grid lines, Y ticks and Hungarian initials `J F M Á M J J A S O N D`. Range preview is observed from the same immutable frame directly on page 1; it updates the foreground without changing the full authority or creating a second Query.
- The earlier Sum-specific passive PageView boundary listener became the neutral `DashboardPagedVerticalBoundaryHandoff` because Year is a second consumer. It observes pointer motion only after slop and only at the active page's outgoing scroll boundary; it forwards to the existing expansion coordinator without owning a gesture recognizer. The old duplicate Year inner handoff path is removed, preserving a single handoff route. The updated two-move test simulates a real multi-event drag after PageView's arena decision rather than treating a lone 80px synthetic move as in-bounds scroll evidence.
- **RED/GREEN evidence:** `YEAR-BAR-01/02/03` first failed because the partial-bar series did not exist, then passed for Expense/Income overlays, zero background and nice full-value scale. `YEAR-BAR-04/05` passes for Year pager movement, unchanged admitted frame and range-preview foreground update. Combined Year/Sum/host suite passed 52 tests; Ubuntu/proot `flutter analyze --no-pub` passed with `No issues found!` in 155.0s; `git diff --check` passed.
- **Still unproven:** focused raster/golden review, final Core/repository counter proof, BottomNav contained-flat delivery, full final suites/CI/final APK/final-source SCIP and Android acceptance. No Time/Avatar physics/controller/position, Core publication, Query semantics, score, Header colour, Budget, LogBox, Room/Kotlin/schema or `MILESTONE_COMMITS.md` change is in this application commit.
- Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Additive contained-flat BNB-03 presentation

- Application commit `28188f9a615f252d14501ebeaccf72c9bfa392d0` delivers the approved additive BottomNav layout choice. It follows the 5893 application lineage and the initial matching SCIP tooling `2433548f311fd23711da28ec957b90f39b34560a`; final-source graph regeneration remains required. This is presentation feature work. The user explicitly excluded fresh Drive runtime-log audit for this delivery, so none was performed and no runtime causality is claimed.
- The single shell presentation owner now exposes `DashboardBottomNavLayoutStyle { raisedFab, containedFlat }`, defaults to `raisedFab`, and is selectable through the existing BottomNav tuner. `FluviAppShell` only forwards that presentation value to its existing `Bnb03BottomNavigation`; no navigation destination, Query, Core, Time or prepared-data write path is involved.
- Raised BNB-03 keeps the pre-existing 75px physical bar, 24px top overflow, 99px authored envelope, 96px shell, 84px visible purple ring and canonical centre contour. `containedFlat` uses the same physical-path owner with its centre protrusion disabled: the top edge is horizontal, the 60px visible purple ring and 72px Semantics/InkWell hit shell both sit wholly inside the 75px bar, and the hit shell remains above Flutter's 48px accessibility floor. The existing corner-shape and optional top-border choices remain separate presentation inputs.
- **RED evidence:** the initial Unit-4 tests failed to compile because `DashboardBottomNavLayoutStyle`, the BNB input and the flat-contour capability did not exist. The tests therefore established the required missing public presentation/geometry boundary before production code was added.
- **GREEN evidence:** Ubuntu/proot `flutter test test/app/bnb03_bottom_navigation_test.dart --reporter expanded` passed 13 tests, including the old raised raster/contour positive control plus contained bounds, horizontal-centre raster, hit/semantic rect, Shop/Home callbacks, outer edge, top-border and SafeArea cases. The combined BNB/app/tuner run passed 45 tests. `flutter analyze --no-pub` passed with `No issues found!` in 214.4s; proot Dart formatter check and `git diff --check` passed.
- No Time/Avatar physics/controller/position, Summary/Time navigation semantics, canonical Query, score/Header-colour, Budget, LogBox, Room/Kotlin/schema, repository/cache owner or `MILESTONE_COMMITS.md` file changed. Still unproven: final package validation, exact final-source SCIP, final Unit-4 CI/human APK and Android physical acceptance.
- Application SHA `28188f9a615f252d14501ebeaccf72c9bfa392d0` was pushed as the branch tip for its build-triggering workflow `35447287389`; at this entry it is queued, so no lane is pre-classified as green.
- The preceding Year-bar application SHA `9877c77aea24326f2816a52d6951a6f0151f8854` has workflow `35446376580`: dashboard-paths, test-flutter and test-core are PASS; build-human-diagnostic-apk is PASS; `run-dashboard-profile` is still running at this entry and therefore no global-green claim is made. Its normal human APK `fluvi_HUMAN_DIAGNOSTIC_9877c77.apk` was downloaded to `/storage/emulated/0/Download/fluvi/`; size `83,678,513` bytes; SHA-256 `9265776b99162f0cfc0263ca814a30922acedd3e76f5bb20bb9c87f002f1f6c6`.
- Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Canonical formatting follow-up for Mind paging

- Application commit `0e97ce1c66bbd8fcce543eb8508c88feb690733e` applies the mandatory `dart format` output to four already-delivered Mind paging files: `mind_temporal_heatmap_projection.dart` and its direct projection/viewport/host tests. This is a formatter-only delivery follow-up; no feature behavior, data owner, Query/Time/Avatar physics, score, Room/Kotlin/schema, BottomNav geometry or `MILESTONE_COMMITS.md` owner changed.
- Evidence: the final format gate identified those four files as noncanonical. After `dart format`, the required Ubuntu/proot eight-file focused suite passed **118 tests**, `flutter analyze --no-pub` passed with `No issues found!` in 148.5s, and `git diff --check` passed. The changed lines are canonical Dart wrapping in generic and test expressions; the original feature RED→GREEN evidence remains the respective Unit 2/3 evidence above.
- The application SHA was pushed as branch tip for a new exact-SHA CI/APK run. The previous `28188f9` profile rerun reached the same inherited `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null` gate as baseline `5893` and Unit 3; it did **not** reproduce the first run's earlier `Missing Mind painted event for expense`. That earlier event is therefore not sufficient evidence of a new product regression. Neither profile run is globally green.
- Still pending for `0e97ce1`: exact-SHA Actions lane audit, normal human APK download/hash, regenerated exact-source SCIP, and user Android validation.
- Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Final Mind paging delivery evidence

- Final application source is `0e97ce1c66bbd8fcce543eb8508c88feb690733e` (`style(mind): format paging implementation`), pushed as the build-triggering branch tip before any later documentation-only commit. There is no post-build application-source mutation. This formatter follow-up is limited to canonical Dart wrapping of four already-delivered Mind paging files; the feature owners and behavior remain those recorded for application commits `1bf1fa1`, `1635f46`, `9877c77`, and `28188f9`.
- Exact Actions run `35449748738` for `0e97ce1` is **FAIL overall**, not globally green: `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; `run-dashboard-profile` reaches `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`. That is the same inherited profile gate observed for baseline `5893` and the 281 rerun. The final run does not fail earlier on `Missing Mind painted event for expense`; the first 281 occurrence remains non-reproducible and is not classified as a product regression.
- The normal human diagnostic release `fluvi-human-diagnostic-0e97ce1` targets exact commit `0e97ce1c66bbd8fcce543eb8508c88feb690733e`. The downloaded `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_0e97ce1.apk` is `83,678,513` bytes with SHA-256 `1be9548e41e154552872a239351fd1a1fa6221c7cf2862727f60a49bdaae810e`. The workflow build command supplies `FLUVI_BUILD_COMMIT=0e97ce1c66bbd8fcce543eb8508c88feb690733e` and the release target is that same commit.
- Local final verification for the final application source: Ubuntu/proot required eight-file focused suite PASS (**118 tests**); `flutter analyze --no-pub` PASS (`No issues found!`, 148.5s); `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh` PASS; `git diff --check` PASS. The shared checklist preserves `PARTIAL` delivery status because the inherited profile lane is not green, and `NOT DONE` physical status because no user device acceptance exists.
- Exact-source SCIP is regenerated and pushed on tooling commit `62ece5cc2a0d0be9dfd64118c3f3ecfebba75699`: `manifest.source_head=0e97ce1c66bbd8fcce543eb8508c88feb690733e`, `source_parent=61a5b66e8f17fd6818eafa541432ac7824092ce4`, `scip_dart=1.6.2`, raw index SHA-256 `e997b2d0ab11ce4801d98413f15c3d3defa4ee642f83f5a0610122900bb952d6`, 475 documents, 325,550 occurrences, and 11,054 repository-defined symbols. A second independent generation produced an identical full SHA/manifest comparison.
- This feature cycle deliberately did not require a new Drive runtime-log audit; no Drive trace is used here for causality. No Time/Avatar physics/controller/position, canonical Query semantics, score/Header-colour algorithm, Budget, LogBox, Room/Kotlin/schema, repository API, or `MILESTONE_COMMITS.md` change is introduced. Physical validation: `PENDING — USER ONLY`.


## 2026-09-19 — Mind three-card aggregate data and Sum presentation settings

- Application commit `93b462eb` begins the approved three-card Mind feature cycle. It is new presentation work; the user explicitly excluded fresh Drive/runtime-log causality review, so none was used.
- `MindSumHeatmapFrame.yearlyPoints` now exposes one immutable exact current-preview aggregate per continuous represented year, including a zero-valued internal year. It derives solely from the existing Sum month bucket totals and does not rescan prepared contributions during preview. `MindAggregateLinePoint` is the neutral immutable chart-anchor model for later Sum and Year renderers.
- `MindYearHeatmapPresentationSettings` and its existing controller now own revisioned Sum-only row layout (`twoRowExpanded` / `oneRowCompact`) and month-label placement (`none` / `belowEachRow` / `insideMonthCells`). The existing tuner exposes them; no Query, Time or persistence state is added.
- RED evidence: `SUM-YEAR-01` and `SUM-PRESENT-01` first failed to compile because the annual-point and setting APIs were absent. GREEN: focused domain/settings suite passes 17 tests; changed-file analyzer reports no issues; `git diff --check` passes. No Time/Avatar motion, canonical Query, score, repository, Room/Kotlin/schema, LogBox or `MILESTONE_COMMITS.md` owner changes.
- Still pending: shared aggregate chart primitive, Sum three-page composition/month popup, Year third card/day popup, gesture tests, final CI/APK/SCIP and user physical validation. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Mind three-card aggregate charts and cell inspection

- Application commit `a5c0ddf3148b9e379e3d7963b1a94d59feaa3b73` completes the next feature unit on top of `93b462eb`. This remains new presentation work; the user explicitly excluded fresh Drive/runtime forensic review, and no Drive trace was read or used for a causal claim.
- **Sum card contract:** `MindSumHeatmapViewport` now has page 0 multi-year heatmap, page 1 the new purple annual aggregate chart, and page 2 the preserved existing real daily multi-line chart. `MindSumHeatmapFrame.yearlyPoints` remains the sole data source for page 1: exactly one current direction/filter/range-preview total per continuous calendar year, including internal zero years. The shared `MindAggregateLineChart` has local selected-point state, bounded tooltip, labels, guide grid, purple transparent-downward fill and a minimum per-year slot width that becomes a horizontal scroll extent for wide year domains. No raw transaction plot, Query mutation, repository read or score calculation is added.
- **Sum heatmap presentation/inspection:** the existing settings now drive two-row versus compact year units and none/below/inside Hungarian month labels. Only non-empty month cells receive a local tap target. Their infocard is a bounded presentation overlay whose clamped position is calculated from the tapped cell's global centre; it shows calendar month and current preview total. Slider and fixed footer remain outside the pager.
- **Year card contract:** `MindYearHeatmapViewport` now has page 0 annual heatmap, retained page 1 full-gray/current-filtered-color bars, and page 2 a twelve-point current-preview monthly aggregate chart. It uses the same shared line primitive but builds only 12 immutable month totals from the already admitted frame. The former full MonthCard tap region is removed from the mounted Year tree; only represented colored day cells are Semantics button/tap targets. Their popup is locally selected, clamped within page bounds and cleared when the selected calendar year changes.
- **RED/GREEN evidence:** the initial changed viewport test expected the old Sum page-1 daily chart and the old MonthCard inspection; it failed at those now-obsolete boundaries. Updated mounted tests now prove the three-page Sum order and preserved tertiary chart, exact `2024=100` / `2025=1500` annual anchors, selection tooltip, Sum compact/inside-label setting, Sum month infocard, Year third page's 12 monthly aggregates, Year line tooltip, absent MonthCard tap key and active colored-day key/info overlay. The `mind_year_heatmap_mode_host_test` first exposed an 11px finite-height aggregate-chart overflow. The shared chart now derives its plot height from the actual card constraint; the host and compact range regression suite is GREEN.
- **Validation:** Ubuntu/proot focused Sum/Year viewport command passed **32 tests**. Ubuntu/proot Mind host plus compact-range command passed **33 tests**, including `SUM-PAGER-02` RangeSlider identity/isolation. Targeted analyzer for changed production/test files passed with `No issues found!`; `git diff --check` passed before the application commit. The direct production changes are only the two Mind viewports and the shared chart primitive; the direct tests are the two matching viewport test files.
- **Intentionally unchanged:** canonical Query ownership and persistence, Room/repository APIs, prepared-cache ownership, financial score and Header colour algorithms, Time/Avatar physics/controllers, fixed compact range owner, LogBox/Budget, Kotlin/schema and `MILESTONE_COMMITS.md`.
- **Still unproven:** broad nested chart-scroll versus outer-page gesture behavior at a real device's long time domain, final full analyzer/fast/boundary suite, exact-SHA CI/human APK/final-source SCIP and Android physical validation. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Aggregate-chart popup context correction

- Application commit `c68216cd757d69beb6e4742f2a923e2c891d6506` corrects the selected-point presentation contract without changing a financial datum. The shared aggregate chart now accepts a presentation-only selected label and comparison-period label. Sum supplies `az előző évhez képest`; Year supplies the selected `YYYY. month` label and `az előző hónaphoz képest`.
- The correction follows mounted Year page-three selection evidence: the common x-axis label was correctly a month initial but was insufficient as an infocard identity. No Query, range, frame, repository, prepared-data, chart point or navigation owner changed.
- Validation: Ubuntu/proot targeted analyzer passed with `No issues found!`; Sum/Year viewport suite passed **32 tests**. Full CI/APK/final SCIP and Android validation remain pending. Physical validation: `PENDING — USER ONLY`.

### Gesture evidence follow-up

- Test commit `c7db9cb897a10476303e3d982d060345a7866b62` adds `SUM-GESTURE-01`: fifteen annual anchors exceed the shared chart's minimum slot-width domain, a deliberate drag on `mind-aggregate-line-scroll` advances only the inner horizontal Scrollable, and the Sum PageView remains on page 1. The Ubuntu/proot focused test is GREEN. This is test-only; no application data, gesture implementation, Query or navigation code changed.
- Test commit `7afd52b00edec3b358fc7a85aa60f14837cbd4d3` adds `YEAR-LINE-01`: the page-three January aggregate changes from `600000` to `500000` when the existing range-preview frame excludes the lower entry. It is GREEN in Ubuntu/proot and confirms that the Year line is neither raw-event data nor a second Query projection. This is test-only; no production owner changed.
- Test commit `4b2bc12f` extends the Sum presentation test through `belowEachRow` before `insideMonthCells`; it proves the exact Hungarian initials row and then the compact in-cell alternative. The focused Ubuntu/proot test is GREEN. The acceptance checklist is updated honestly: visual golden and broad real-device nested gesture evidence remain `PARTIAL`; delivery evidence remains `PARTIAL`; physical validation is not done.

## 2026-09-19 — Preserve tertiary Sum heading

- Application commit `299196d4ceb07cd6a98dd5704cbb00df5516a436` is a one-line presentation correction: only the newly added annual aggregate page uses `Többéves alakulás`; the retained tertiary daily multi-line page keeps the pre-existing `Többéves aktivitás` heading. This protects the explicit instruction to preserve rather than silently redefine that card.
- Ubuntu/proot `SUM-CARDS-01/02/03` is GREEN. No model, Query, frame, chart point, scroll, range, Core, Time/Avatar or data-store owner changed. Final exact-SHA CI/APK/SCIP and Android physical validation remain pending. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Analyzer-clean aggregate chart test follow-up

- Test-only commit `649a5c04863a24cdf865384b59220e0c38f0f332` removes one unnecessary cascade in the Sum month-label test. It does not modify production sources; the final application source remains `299196d4ceb07cd6a98dd5704cbb00df5516a436`.
- Evidence: the full Ubuntu/proot analyzer initially reported exactly one `avoid_single_cascade_in_expression_statements` finding at this test line. After the mechanical test-only correction, the combined Sum/Year Mind viewport command passes **34 tests** and full `flutter analyze --no-pub` reports `No issues found!` in 123.7 seconds. `dart format --output=none --set-exit-if-changed` and `git diff --check` pass.
- This does not affect the already pushed exact-application CI/APK/SCIP inputs. Final Actions lane audit, final human APK download/hash and Android physical validation remain pending. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Final three-card Mind delivery evidence

- The final production application source is `299196d4ceb07cd6a98dd5704cbb00df5516a436` (`fix(mind): retain tertiary Sum chart heading`). No later commit changes production application code: `649a5c04` is test-only, `9afafd28` is a journal-only record, and `21ce6530` is a checklist-only record.
- Exact Actions workflow `35460432390` for `299196d4` is **FAIL overall**, never globally green: `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly and baseline lanes are skipped; `run-dashboard-profile` is FAIL at `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`. The same gate appears in the preceding comparable run `35459799922`; it is an inherited profile-evidence limitation, not evidence that this feature passed device performance.
- The normal human diagnostic release `fluvi-human-diagnostic-299196d` targets exact commit `299196d4ceb07cd6a98dd5704cbb00df5516a436`. The downloaded APK is `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_299196d.apk`, `83,793,201` bytes, SHA-256 `033759d8500bf6ff263a46879c89b21f340c83d17b14fadb3ba55d879de54545`. Its binary contains that exact build SHA; the workflow supplied `FLUVI_BUILD_COMMIT=${{ github.sha }}`.
- Final local evidence: combined Sum/Year viewport suite PASS (**34 tests**); full Ubuntu/proot `flutter analyze --no-pub` PASS (`No issues found!`, 123.7 seconds); `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh` PASS; `dart format --output=none --set-exit-if-changed` for the final changed test and `git diff --check` PASS. Tooling `dart test` PASS (**15 tests**).
- Exact-source SCIP was generated from detached clean source `299196d4` and pushed as tooling commit `96124386a7e6e9b424ece8f2b3c31012706c26de`. `manifest.source_head=299196d4ceb07cd6a98dd5704cbb00df5516a436`, `source_parent=5da4c6d359048c372844d0a19eb26fb6359b1913`, `scip_dart=1.6.2`, raw index SHA-256 `af541117c85c3f8a75339471c90138a7a526f1c59f8d91f1de7fd8ae7b27211b`, 476 documents, 327,273 occurrences and 11,139 repository-defined symbols. A second direct generation was byte-identical (`git diff --quiet`).
- The new feature intentionally did not need a fresh Drive audit; no runtime root-cause claim is made. The remaining acceptance gaps are exactly the checklist's visual/reference raster evidence and broad real-device nested-gesture proof (`PARTIAL`), inherited profile-gate completion (`PARTIAL`), and user Android testing (`NOT DONE`). Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Expanded Mind temporal cards

- Application commit `81ee844d225aa3660f8a42bbd2b1c9e74f06802f` implements the approved feature expansion on top of the three-card Mind presentation lineage. This is feature work; the user expressly excluded fresh Drive/runtime-log audit, so no Drive trace was read and no runtime causality is claimed.
- Sum retains its ordered card set: page 0 multi-year heatmap, page 1 exact one-aggregate-per-year purple chart, and page 2 the preserved daily multi-line chart. The Sum compact setting is now structurally real (`year | narrower aligned 12-cell strip | compact total`), and `belowEachRow` uses twelve individual cell-aligned Hungarian labels rather than a centred text string.
- Month gains the secondary `Napi költési ritmus` page. It consumes the current immutable month frame's continuous 28–31 daily range-preview aggregates, paints daily bars plus a dashed `napi átlag` guide, and supplies compact total/active-day/average/strongest-day tiles. No repository or raw-ledger path is entered by the page.
- Day gains the secondary `Napi tranzakciók idővonala` page. Its event markers contain only the resident selected-day prepared ordinal, local time and current-range amount; they are exact marker inputs, never manufactured hourly or raw-query records. The page paints a 00–24 axis, marker stems, legend, and summary tiles.
- Year retains annual heatmap plus partial-bar page and its twelve-month line page. The shared aggregate chart now explicitly supports a width-fit domain: Year's 12 month points have zero horizontal scroll extent and use the available card height, while Sum's long annual domain retains its readable minimum slot width and inner horizontal scroll.
- Sum month and Year day selection state remains feature-local. Their duplicate anchored-popup placement code was replaced by data-free `MindAnchoredInfoCard`, which derives local placement from the actual tapped global cell anchor and clamps only at card edges. Query, repository, Room, score, Time and persistent state do not participate.
- **RED/GREEN evidence:** `MONTH-RHYTHM-01` and `DAY-TIMELINE-01` initially failed because the bounded rhythm/event frame APIs did not exist. Mounted Month/Day secondary-card tests first failed because their pagers/cards did not exist. The Year monthly-line test first failed with a 270px horizontal scroll extent. All are GREEN after implementation. The combined domain + Sum/Month/Day viewport command passed **24 tests**; the Year viewport suite passed **22 tests**; focused Sum/Year popup, compact-layout and line-width tests passed.
- Intentionally unchanged: Avatar/Time/Summary physics and controllers, canonical Query ownership and persistence, repository/Room/Kotlin/schema, score/Header colour algorithms, Budget, LogBox, range owner, palettes, BottomNav behavior and `MILESTONE_COMMITS.md`. The pre-existing partial-bar diagnostic still clamps an inconsistent test fixture where filtered exceeds supplied full total; it is not introduced by this commit.
- Still unproven: reference-image pixel/golden comparison, same-device nested gesture behavior, final full suite/CI/human APK/exact-source SCIP, and user Android acceptance. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Resident comparison layers for Month and Day secondary cards

- Application commit `154c80d0277f0d1f62a5af9b6bef1a8f9f504e89` refines the already delivered Month `Napi költési ritmus` and Day `Napi tranzakciók idővonala` cards against their approved references. This remains presentation feature work; the user excluded Drive/runtime-log audit and none was performed.
- The immutable Month frame now retains a second continuous daily aggregate series for the same already admitted direction/filter membership before only the live amount-range preview. The rhythm painter first draws that series in muted gray, then overlays the current range-preview bars in the Mind palette colour. Its `Teljes hónap` statistic likewise describes the comparison layer, while the active-day/average/current bars still use the preview frame.
- The immutable Day frame equivalently retains exact local-time selected-day markers before the live amount-range preview. The timeline paints gray all-in-membership stems first, then the current preview stems/labels in the Mind palette; `Teljes nap` reports the comparison total/event count and `Aktuális sáv` remains the range-preview total. Both paths stay entirely in bounded resident prepared data: no Query mutation, repository/Room access, raw-ledger scan, score work or new authority is introduced.
- **RED/GREEN evidence:** `MONTH-RHYTHM-02` first failed because the Month frame had no slider-before daily series; `DAY-TIMELINE-02` first failed because the Day frame had no slider-before exact-marker series. Ubuntu/proot `flutter test --no-pub test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart --reporter expanded` is GREEN (**26 tests**). Proot formatter check and `git diff --check` are GREEN.
- Intentionally unchanged: existing Sum/Year page contracts, Time/Avatar/Summary physics/controllers, canonical Query, range-slider owner, repository/Room/Kotlin/schema, financial score/Header colour, Budget, LogBox, palettes, BottomNav and `MILESTONE_COMMITS.md`. Still unproven: reference pixel/golden comparison, device nested-gesture behavior, complete final-suite/CI/APK/exact-source SCIP evidence and user Android acceptance. Physical validation: `PENDING — USER ONLY`.

## 2026-09-19 — Expanded Mind temporal-card final delivery evidence

- Final application source is `154c80d0277f0d1f62a5af9b6bef1a8f9f504e89` (`feat(mind): add resident comparison layers to temporal cards`). It was pushed as the branch tip for build-triggering workflow `35468024801` before later docs-only commits. Application commits in this feature delivery are `81ee844d225aa3660f8a42bbd2b1c9e74f06802f` (three-card expansion and Month/Day secondary cards) and `154c80d0277f0d1f62a5af9b6bef1a8f9f504e89` (resident comparison layers); their required journal-only commits are `21aca9b55eadfcddf68305f0237ddf3242489de2` and `fa671d6da9ae1b538c8e67977bfb7e93940c4b97`, each changing only this journal file.
- **Local evidence:** Ubuntu/proot focused domain + temporal viewport command is PASS (**26 tests**); Mind settings/Year viewport/host/range regression command completed with the covered cases green; full Ubuntu/proot `flutter analyze --no-pub` is PASS (`No issues found!`, 143.5s); `./scripts/test-fluvi-fast.sh` is PASS (**431 tests**, 5m52s); `./scripts/verify-fluvi-boundaries.sh` and `git diff --check` are PASS. The clean comparison-frame tests `MONTH-RHYTHM-02` and `DAY-TIMELINE-02` were established RED before their frame APIs existed and green after implementation.
- **Actions `35468024801`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly/baseline lanes are skipped. The workflow is **FAIL overall**, not globally green, because `run-dashboard-profile` again reaches `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`. The exact same known profile-evidence gate follows the route's failure; no earlier application failure is present in this run, and this entry does not represent that inherited gate as a new Mind-card regression.
- **Human APK:** release `fluvi-human-diagnostic-154c80d` targets exact source `154c80d0277f0d1f62a5af9b6bef1a8f9f504e89`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_154c80d.apk` exists, is `83,907,889` bytes, and has SHA-256 `b9ee5d69b50e354099191806e4f15f21d0a96a8466ca8fb82b4a9a99aaf9590e`; an exact-SHA binary scan finds that application commit in the APK.
- **Exact-source SCIP:** tooling commit `d61ee019be03a624b5e21d301d39dba13058a441` is pushed on `tooling/scip-codegraph-v1`. Its manifest has `source_head=154c80d0277f0d1f62a5af9b6bef1a8f9f504e89`, `source_parent=21aca9b55eadfcddf68305f0237ddf3242489de2`, `scip_dart=1.6.2`, raw index SHA-256 `9a24575371f42f06611a70d3339740468f0121b867db2734b99ec4578d3b645b`, 478 documents, 329,685 occurrences and 11,236 repository-defined symbols. `dart test` in `tools/codegraph` is PASS (**15 tests**); a second full graph generation was byte-identical.
- The accepted feature semantics are code/test complete: Sum page order is heatmap/exact annual/multi-line; Year retains heatmap/partial-bars plus the 12-month line; Month/Day second pages consume resident data, and their current-range marks overlay the same-admission muted comparison layers. The checklist remains intentionally `PARTIAL` only for reference-pixel/golden proof, real-device nested gesture evidence, inherited profile gate and user physical validation. No Drive log was read in this feature cycle by user instruction. No Time/Avatar physics, canonical Query semantics, Room/Kotlin/schema, score/Header-colour, Budget, LogBox or `MILESTONE_COMMITS.md` change is present.
- Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Zoomable detailed Sum chart final delivery evidence

- Final application source is `15bae5ac712eec4683ce808e06a4d6106a2818db` (`feat(mind): add zoomable detailed Sum chart`). It was pushed before its documentation children, so Actions workflow `35476787935` and the human APK target that exact application SHA. The initial delivery journal child is `55f6e64bcd922d1f71b9f8cd3aa9d9199a3d2819`; it changes only this journal file. No fresh Drive log was read, per the explicit feature-work boundary.
- The application adds a single reusable immutable detailed-Sum time-window/LOD model and renderer: the Sum pager retains page 0 multi-year heatmap, page 1 exact annual aggregate line, and page 2 detailed multi-line chart. The detailed card has Jan–Dec home zoom, focal semantic pinch zoom/pan, source-only LOD anchors, one/two/three-plus-year adaptive band behavior, Hungarian month/monetary axes, and the local top-right heatmap/line switch. The shared anchored-info-card path now keeps Sum month and Year colored-day inspection tied to the tapped cell, clamped inside its card; Year has an explicit accessible dismiss affordance.
- Review-derived RED/GREEN follow-ups prove that a same-year replacement frame resets a stale detail zoom window, pinch focal math excludes the Y-axis gutter, every LOD anchor comes from the immutable source, and the Year info card remains dismissible. No new Query, Room, repository, Time, score or persistent owner was added.
- **Local validation:** focused detailed model/Sum/Year viewport suite PASS (**43 tests**); Ubuntu/proot `flutter analyze --no-pub` PASS (`No issues found!`); Ubuntu/proot `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); Ubuntu/proot `./scripts/verify-fluvi-boundaries.sh` PASS; changed-file format check and `git diff --check` PASS. Exact-source tooling `dart test` PASS (**15 tests**).
- **Actions `35476787935`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly and baseline jobs are skipped. The workflow is **FAIL overall**, not globally green, solely because `run-dashboard-profile` fails after 17m41s at the inherited gate `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`; its follow-on missing report map is consequent. No earlier new application failure occurs in that lane.
- **Human APK:** release `fluvi-human-diagnostic-15bae5a` targets exact source `15bae5ac712eec4683ce808e06a4d6106a2818db`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_15bae5a.apk` exists, is `84,219,337` bytes, has SHA-256 `e19bfe7a71a039826eee3c1669bdffd7624e1b6cca71b9f1ef5eae3b82d0ffec`, and contains the exact full application SHA.
- **Exact-source SCIP:** tooling commit `945c6244e5308a82d2d89d8ee8c148cec491655b` is pushed on `tooling/scip-codegraph-v1`. Its manifest has `source_head=15bae5ac712eec4683ce808e06a4d6106a2818db`, `source_parent=3db86473a08a885bd0130b7dec3288db5594afa3`, `scip_dart=1.6.2`, raw index SHA-256 `526bb6411157304b9ae67a21b3831e3343ffa3adf79bd91ff46c2c8020b0f152`, 481 documents, 331,450 occurrences and 11,280 repository-defined symbols. A second generation has the identical graph-tree digest `28a68a0fcb93642668345e4425a6e63abdbc90804f18996378ffcd6aee5bfbb2`.
- Physical validation remains `PENDING — USER ONLY`.

## 2026-09-20 — Physical detailed-Sum zoom failure and Sum card simplification

- New Android physical feedback with screenshot: the detailed Sum chart renders adaptive year bands, X/Y axes and the top-right line/heatmap control, but the user does **not** perceive the intended refinement/LOD behavior and reports that pinch zoom does not work physically. Pinch interaction interferes with Dashboard collapse/expand and with horizontal Sum page switching. The screenshot itself exposes no build/source marker, so the exact physically tested APK SHA remains **MISSING EVIDENCE**; do not infer it solely from chronology. The latest delivered matching feature APK is `fluvi_HUMAN_DIAGNOSTIC_15bae5a.apk`, source `15bae5ac712eec4683ce808e06a4d6106a2818db`, but this screenshot is not independently identity-proven.
- Product decision now supersedes the prior three-page Sum presentation: **remove the exact annual aggregate secondary page from Sum**. Sum should expose only two visualization surfaces: the multi-year heatmap and the currently edited detailed per-year chart. They are selected exclusively by the existing small top-right heatmap/line buttons. **Horizontal PageView swipe navigation between Sum visualizations must be removed/disabled**; the toggle becomes the only visualization-switch interaction. The detailed chart remains the feature under active refinement.
- **PROVEN current source topology at application source 15bae5ac:** `_MindSumHeatmapContentState` still owns a `PageController` and a three-child `PageView`: page 0 heatmap, page 1 exact annual aggregate chart, page 2 detailed chart. The mini toggle does not switch local renderer state; it calls `_selectDetailMode`, which animates that same PageView directly between pages 0 and 2. Thus horizontal page-swipe recognition remains live even though the product now wants button-only switching.
- **PROVEN current multi-touch/collapse interaction surface:** the entire Sum `PageView` is wrapped by `DashboardPagedVerticalBoundaryHandoff`. That wrapper is a raw `Listener` that tracks one pointer and may begin the existing upper vertical collapse/expand coordinator once that pointer's travel clears slop and is vertically dominant at a page boundary. It has no multi-pointer/pinch exclusion. The detailed year band simultaneously owns `GestureDetector.onScaleStart/onScaleUpdate/onScaleEnd` and only applies zoom when `pointerCount >= 2`. Therefore the production composition has overlapping active interaction paths for the same physical pinch sequence: detailed scale, horizontal PageView, and passive vertical boundary/collapse observation.
- **PROVEN false-green gap in current zoom test:** `DSUM-02/03` mounts `MindSumHeatmapViewport` directly without supplying `upperVerticalGestures`, so the production collapse/expand handoff cannot activate in that test. Its synthetic pinch moves two pointers symmetrically on the exact same Y coordinate, so it also does not model realistic diagonal/vertical finger noise. The same test reaches the detailed page by horizontal PageView swipes and therefore cannot prove the newly requested button-only topology. Existing `DSUM-04/05/06` explicitly treats an unzoomed one-finger chart drag as a page gesture, which is now an obsolete acceptance condition.
- **PROVEN LOD implementation fact:** `MindDetailedSumLod.sample` is a pure source-only downsampler over current immutable daily points and the painter uses its returned anchors. The physical observation that refinement is not visibly apparent does not prove that this function never changes its returned set; it proves the current physical visual result/gesture path does not satisfy the intended experience. Any next repair must add observable mounted evidence for actual rendered anchor-count/detail change across zoom levels, not only time-window semantics.
- Matching SCIP for exact application source `15bae5ac712eec4683ce808e06a4d6106a2818db` is tooling commit `945c6244e5308a82d2d89d8ee8c148cec491655b`, `scip_dart=1.6.2`, raw index SHA-256 `526bb6411157304b9ae67a21b3831e3343ffa3adf79bd91ff46c2c8020b0f152`, 481 documents / 331,450 occurrences / 11,280 repository-defined symbols. Graph/source verification identifies `MindDetailedSumChart` as constructed only from the Sum temporal viewport in production, and `DashboardPagedVerticalBoundaryHandoff` as directly consumed by the Sum and Year Mind viewports. The graph is impact/navigation evidence; the source above proves the actual gesture topology.
- Relevant Drive logs are stale for this physical report: `Fluvi mind heatmap` was last modified 2026-09-19T05:41:59Z and `Fluvi logs time fling` on 2026-09-15, both predating application source 15bae5ac and its physical APK. They are therefore HISTORICAL only and are not used to claim current pinch causality.
- **PROVEN:** current source still has three Sum pages and active PageView horizontal swipe; current production parent supplies `upperVerticalGestures`; the paged boundary listener lacks a multi-touch exclusion; the detailed chart scale path requires two pointers; the existing physical user report says pinch fails/interferes; the current production-parent omission makes the pinch test false-green for collapse interaction.
- **UNPROVEN:** which recognizer wins first on every real-device pinch sequence; whether PageView, collapse handoff, or their combination is the first runtime loser/winner on the user's exact gesture; exact physical APK/source identity; the precise amount by which the current LOD anchor set changes during the failed physical gesture.
- **MISSING EVIDENCE:** exact APK build marker from the physical test; production-parent two-pointer RED test with real `DashboardUpperVerticalGestureCoordinator`; noisy/diagonal pinch test; proof that collapse progress remains unchanged throughout pinch; proof that no Sum page index changes during pinch; proof that the toggle alone switches heatmap/detail; proof that page 1 exact annual aggregate view is absent; mounted rendered-point-count/detail-density evidence before/after zoom; final CI/APK/final-source SCIP; user Android revalidation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, test, workflow, tooling graph or milestone file is modified by the prompt writer. Physical validation of the next candidate remains `PENDING — USER ONLY`.

## 2026-09-20 — Sum toggle-only topology repair

- Application commit `54427e35` applies the first physical-zoom repair unit on top of the user-audited `15bae5ac` source: Sum now has exactly two locally selected presentation surfaces, the existing multi-year heatmap and the detailed Sum chart. The obsolete exact annual aggregate Sum page, its `PageView`, its `PageController`, its swipe contract, and its Sum-only `yearlyPoints` API are removed. The existing top-right line/heatmap control writes the local two-state selection synchronously; it is the only visualization switch.
- **RED/GREEN:** `SUM-TOPO-01` initially failed because `mind-sum-heatmap-pager` was mounted. It is GREEN after the direct two-state composition: no Sum `PageView`, no page-one exact surface, and a one-finger horizontal drag cannot change the selected visualization. The revised adaptive-chart test confirms that the preserved detailed chart is selected through the button and returns to heatmap through the matching button without mutating the admitted frame.
- **Validation:** Ubuntu/proot Sum temporal viewport suite PASS (**18 tests**); Ubuntu/proot Sum projection suite PASS (**11 tests**); `git diff --check` PASS before commit. The deliberately noisy production-parent pinch test was RED against the old topology: `DashboardExpansionController.isDragging` became true during the two-pointer sequence. It is not yet accepted as final pinch proof; the next unit adds explicit local multi-touch isolation and retains the positive one-pointer boundary handoff contract.
- **Intentionally unchanged:** Year paging/card structure, Month rhythm, Day timeline, anchored info cards, permanent inline legend, RangeSlider/Query ownership, Time/Avatar physics, Header score/colour, repository/Room/schema/Kotlin, Budget, LogBox and `MILESTONE_COMMITS.md`.
- **Still unproven:** true transaction-time deep zoom, observable coarse-to-fine LOD, final production-parent pinch isolation, final CI/APK/exact-source SCIP and Android validation. The physical screenshot's exact source SHA remains missing evidence. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Detailed Sum local multi-touch isolation

- Application commit `7b41fe53` introduces the bounded gesture repair following the toggle-only topology. `MindDetailedSumChart` now tracks its own active pointer set. Once two pointers are down, it marks the local pinch session active, freezes only its detailed-year `ListView`, and suppresses only that surface's vertical boundary handoff. The chart remains the ScaleGestureRecognizer owner; no global collapse setting or unrelated mode is disabled.
- The existing shared `DashboardVerticalScrollBoundaryHandoff` now accepts an optional `ValueListenable<bool>` suppression source. Its default behavior is unchanged; a suppressed owner cancels only a currently active handoff and ignores scroll/direct handoff until the local multi-pointer session ends. This centralizes the reusable boundary policy instead of copying a second collapse workaround into the chart.
- **RED/GREEN:** the noisy, diagonal production-parent test had previously driven `DashboardExpansionController.isDragging` true in the obsolete Sum tree. It now verifies active local pinch ownership, unchanged expansion progress/drag state, a return to idle on release, unchanged admitted frame, and the retained detailed surface. The real host regression suite additionally proves a non-scroll one-pointer Sum drag still reaches the existing upper expansion coordinator, and a scrollable Sum grid still hands off only at its true boundary.
- **Validation:** Ubuntu/proot combined Sum viewport plus production Mind-host suites PASS (**39 tests**); isolated noisy production-parent pinch plus detailed pinch test PASS (**2 tests**); `git diff --check` PASS. The changes intentionally do not touch Year card paging, Month/Day secondary cards, Query, RangeSlider, Time/Avatar, repository/Room/schema, Header score/colour, Budget, LogBox or milestones.
- **Still unproven:** device recognizer cadence, true transaction-time deep zoom and visibly progressive LOD, final CI/APK/exact-source SCIP and Android validation. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Transaction-preserving detailed Sum resolution

- Application commit `b6c330de` removes the detailed Sum chart's daily-aggregate ceiling without creating another Query, projection or repository owner. The existing one-pass Sum projection now retains a bounded immutable time-sorted prepared-detail list per represented year: ordinal, local epoch-minute and amount. It remains resident beside the existing month and daily amount-range buckets.
- `MindSumHeatmapFrame.detailPointsForYear` is range-bound and window-aware. Broad views use existing current-preview daily aggregates; a window of seven days or less binary-searches only the visible resident time span and emits each amount-range eligible prepared transaction. Same-minute entries retain ordinal order rather than being collapsed. Slider previews still use the existing prefix-sum monthly/daily bucket path; deep rendering never requests Room/repository or scans the complete ledger.
- Detailed Sum time-window geometry now uses epoch minutes. Pinch focal position and one-finger pan preserve minute-domain location. The old `binCount == logical pixel width` overview policy is replaced with a 28px minimum-anchor-spacing budget which starts intentionally calmer and expands continuously with zoom. At one day or below the LOD returns every supplied transaction anchor; extrema remain real source anchors only.
- **RED/GREEN:** `SUM-DETAIL-01` initially did not compile because no transaction detail read model/API existed. It is GREEN with separately timed 00:20 and two 12:00 entries, including slider-range exclusion. `DSUM-LOD-01` proves 1,095 yearly source transactions reduce materially at home while retaining the 9,000 spike; a deep day emits all three exact source ordinals. The renderer consumes this API directly and exposes its anchor count for mounted inspection.
- **Validation:** Ubuntu/proot Sum projection, detail-model, temporal viewport and production Mind-host suites PASS (**54 tests**); changed-Dart formatter check and `git diff --check` PASS. No Year, Month, Day, inline legend, range owner, Query semantics, Time/Avatar, Header, repository/Room/schema, Budget, LogBox or milestone code changes.
- **Still unproven:** Android perceived refinement and recognizer cadence, full analyzer/fast/boundary suites, exact final CI/APK/SCIP and user validation. Physical validation: `PENDING — USER ONLY`.

### Production-parent pinch assertion follow-up

- Test-only commit `4221870f` strengthens `SUM-GEST-01`: the realistic noisy two-pointer sequence now proves the detail time-window changes as well as proving active local pinch ownership, unchanged expansion state, unchanged Sum surface and unchanged admitted frame. The source is unchanged by this test follow-up; Android recognizer cadence remains user-only evidence.

## 2026-09-20 — Sum detail API boundary cleanup

- Application commit `f311241b` completes the narrow static-analysis cleanup after the toggle-only, multi-touch and transaction-detail repair units. `MindSumHeatmapFrame` construction is now projection-internal, so the private prepared-detail representation cannot leak through a public constructor; the Sum viewport also removes the obsolete paged-boundary import after PageView removal. This does not change product behavior or introduce another data/gesture owner.
- **Validation:** Ubuntu/proot focused Sum projection, detail-model, temporal viewport and production Mind-host command is PASS (**54 tests**); changed-Dart formatter and `git diff --check` are PASS; full Ubuntu/proot `flutter analyze --no-pub` is PASS (`No issues found!`, 129.5s).
- The remaining work is final fast/boundary regression, CI/human APK, exact-source SCIP and Android revalidation. The screenshot still lacks a build marker, so its exact source identity remains missing evidence. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Detailed Sum zoom repair final automated delivery evidence

- Final application source is `f311241b8aacd5a60219533f1257d576eda7da11` (`fix(mind): keep Sum detail construction internal`), pushed as the application branch tip before this final documentation evidence. The repair application commits are `54427e35` (two-surface toggle-only Sum), `7b41fe53` (local multi-touch isolation), `b6c330de` (resident transaction-time detail), and `f311241b` (internal projection API boundary); their required journal-only children are `cf4fa0f3`, `47e056f5`, `42379579`, and `28b7587b`, each changing only this journal file.
- **Automated validation:** Ubuntu/proot focused Sum projection/detail-model/viewport/production-host suite PASS (**54 tests**); `flutter analyze --no-pub` PASS (`No issues found!`, 129.5s); `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh`, changed-Dart format check and `git diff --check` PASS. Production-parent noisy-pinch coverage proves time-window change while the expansion coordinator, presentation surface and admitted frame remain unchanged; dense LOD coverage proves a materially coarser overview and transaction-level deep detail from resident prepared contributions.
- **Actions `35491099076`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly and baseline lanes are skipped. The workflow is **FAIL overall**, never globally green, solely because `run-dashboard-profile` fails at the inherited `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`, followed by the consequent missing `B_year_month_rail_populated` report map. The failure occurs in the same established profile-evidence boundary; no earlier new application failure is present.
- **Human APK:** release `fluvi-human-diagnostic-f311241` targets exact source `f311241b8aacd5a60219533f1257d576eda7da11`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_f311241.apk` exists, is `84,235,721` bytes, SHA-256 `6f44a91f3942e9ae17586fa836983f19e05d03c53916f5c44e641e77281e8358`, and contains the full exact application SHA.
- **Exact-source SCIP:** tooling commit `7b6e3857a09f6641c194c377f305680721a0084e` is pushed on `tooling/scip-codegraph-v1`. Its manifest has `source_head=f311241b8aacd5a60219533f1257d576eda7da11`, `source_parent=3eb9156d201d14112708bf715be76e3698b14ea8`, `scip_dart=1.6.2`, raw index SHA-256 `70e2039b653938fd7682957f1b9e3c28dac3933af0f7be151c905707f29a55ba`, 481 documents, 332,041 occurrences and 11,302 repository-defined symbols. Two complete generations produced identical graph-tree SHA-256 `2dba435d9c538d421a8f5ca701d5dc825a4c0824ed44e022bfab67e7d7e61104`; tooling `dart test` PASS (**15 tests**).
- No fresh Drive log was read, by explicit feature-work instruction. The new Android screenshot contains no build marker, so its exact input APK remains unproven. The remaining acceptance boundary is real-device pinch/visual validation only. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Detailed Sum zoom range too shallow + tap inspection requirement

- New Android physical feedback after the repaired Sum delivery: pinch is now recognized sufficiently to change the visible domain, but the effective zoom range/sensitivity is far too shallow in practice. The user reports that the maximum physically reachable result changes the full-year view from roughly 12 visible months to only about 11. Product requirement: the detailed Sum chart must support **substantially deeper zoom**, with at least a half-year-scale visible window (about 6 months) reachable from the 12-month home view, and further inward zoom may continue toward the already-supported finer detail levels.
- Additional product requirement: tapping anywhere on a detailed Sum year plot must inspect the nearest real represented temporal point and show a compact popup/infocard identifying **which calendar day** and **what amount** that point represents. The interaction must not require hitting the tiny painted marker exactly. The inspected value must come from the real current filtered/range-preview chart source; do not interpolate a fake financial value from the line between anchors.
- Current authoritative application source is `f311241b8aacd5a60219533f1257d576eda7da11` (`fix(mind): keep Sum detail construction internal`). Final automated delivery evidence, APK and exact-source SCIP for that source are already recorded immediately above. Current remote branch HEAD before this journal-only feedback record is `70f8842132caef951b36a02d01e47ded05daa19f`, a journal-only child; no newer application source exists at this audit point.
- **PROVEN current zoom model:** `MindDetailedSumTimeWindow.zoomAtMinute` mathematically permits a visible interval all the way down to one minute; there is no source-level six-month floor or hard 11-month clamp. Therefore the physical 12→11-month limit is not proven to be a model-range ceiling. The current chart applies `ScaleUpdateDetails.scale` directly against the scale-start window with no product-level sensitivity/amplification contract, so the physically reachable zoom magnitude depends on the raw recognizer scale produced by the gesture.
- **PROVEN current acceptance gap:** the mounted detailed pinch test only asserts that the time-window semantics label changes (`after != before`) and that the focal midpoint stays stable. It does **not** assert any minimum zoom magnitude, such as reducing a full-year domain to <= ~6 months, nor does it prove that a normal Android pinch can reach a meaningful minimum visible span. A tiny 12→11-month change therefore satisfies the current automated contract even though the physical UX is insufficient.
- **PROVEN current data foundation for inspection:** `MindSumHeatmapFrame.detailPointsForYear` exposes current range-filtered detail anchors from the same admitted financial source. For broad windows they are real daily aggregates centered on the calendar day; at windows of seven days or less they become exact prepared transaction-time anchors retaining ordinal, epoch-minute and amount. This provides a truthful source for tap inspection without Query/repository/Room work.
- **PROVEN current interaction gap:** `mind_detailed_sum_chart.dart` has scale and zoomed horizontal-pan gesture handling but no tap selection state, no `onTapDown`/point hit-resolution path and no detailed-chart infocard. The existing shared anchored-infocard infrastructure is available elsewhere in Mind and should be source-audited for reuse rather than duplicating popup placement policy.
- **Required next evidence:** (1) RED test that a realistic pinch from the full-year home domain can reach a visible span of approximately 6 months or less; (2) source-level product contract for maximum/minimum usable zoom and gesture sensitivity so physical reachability is not accidental; (3) repeated pinch / cumulative zoom test if multiple pinch gestures are supported; (4) tap-nearest-point RED test where the pointer lands between tiny markers and still resolves the correct nearest date/amount; (5) popup bounds/anchor test; (6) broad-window daily-total semantics and deep-window transaction-amount semantics documented/tested without fabricated interpolation; (7) final Android revalidation.
- **UNPROVEN:** whether the shallow physical result is caused primarily by recognizer scale cadence, one-gesture sensitivity, gesture restart behavior, or another device-level factor. Do not claim a specific recognizer defect without additional evidence.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, workflow, tooling graph or milestone file is modified by the prompt writer. Physical validation of the next candidate remains `PENDING — USER ONLY`.

## 2026-09-20 — Sum three-mode refinement and usable detailed inspection

- Application commit `bda65eb9bedcb3cba5793208f059178a299a037e` implements the newest Sum presentation decision without a fresh Drive/runtime-log audit: Sum is local-toggle-only with exactly **heatmap**, **detailed line**, and **monthly overlay** surfaces. The removed exact annual Sum aggregate card remains absent; no Sum `PageView`, horizontal visual-page swipe writer, or stale aggregate surface is retained.
- The detailed chart now maps cumulative physical scale through the explicit focal-time-preserving `zoomForGesture` contract. `SUM3-ZOOM-01` proves two normal `1.12` scale sessions reach a <=184-day window in the pure model; mounted `SUM3-ZOOM-02` proves two real two-pointer sessions reach that threshold in the widget. The initial mounted attempt below Flutter scale-recognizer slop remained at 365 days, which established the test gesture needed an accepted scale spread rather than proving a new application defect. The final mounted gesture crosses recognizer slop and reaches the half-year target. `SUM-GEST-01` retains noisy production-parent pinch proof: no Dashboard expansion starts and the admitted financial frame stays unchanged.
- `MindDetailedSumChart` now resolves every plot tap to the nearest actual current LOD anchor, not an interpolated curve value. The bounded shared `MindAnchoredInfoCard` positions the selected date/amount card from the real tap anchor. Faint dashed calendar-month separators are restored. The one/two/three-plus band policy preserves one expanded band, fits two full bands including the second X-axis, and scrolls internally at three or more bands.
- A single new neutral immutable `MindMonthlyOverlaySeries` plus `MindMonthlyOverlayBarPainter` is shared by Sum and the existing Year partial-bar adapter. At the single existing Sum Core admission, resident selected-direction prepared contributions provide immutable full monthly totals; the current preview frame supplies filtered/range totals. Sum therefore paints gray full bars under heatmap-resolver-colored foreground bars with no second Query, Room, repository or data-store authority. `SUM3-BAR-01/02` and `SUM3-BARS-01/02` cover full/current separation, clamping and live slider/palette response.
- The Sum month tap target is now a `GestureDetector`, avoiding the unneeded `Material` ancestor requirement in production Mind host composition. `SUM3-MATERIAL-01` proves the existing anchored Sum month infocard still opens without a Material ancestor. No Time/Avatar physics/controller/position, canonical Query semantics, score/Header-colour algorithm, Month/Day/Year feature semantics, Room/Kotlin/schema, LogBox, Budget, BottomNav, range-slider owner or `MILESTONE_COMMITS.md` changed.
- **RED/GREEN and validation:** missing zoom/model/overlay APIs were first RED; mounted `SUM3-ZOOM-02` also initially RED at an unchanged 365-day window. After the focused implementation, the Ubuntu/proot Mind domain/projection/viewport/Year suite is PASS (**66 tests**); settings/host/RangeSlider/Core ephemeral-focus suite is PASS (**140 tests**); `flutter analyze --no-pub` is PASS (`No issues found!`, 210.9s); changed-Dart formatter check and `git diff --check` are PASS; `./scripts/test-fluvi-fast.sh` is PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh` is PASS. The first fast-script invocation failed only because its direct `flutter` lookup omitted `/home/flutteruser/flutter/bin`; rerunning the exact script with that required proot PATH passed.
- The shared acceptance checklist records the source/test-complete Sum criteria as `DONE`. Performance delivery remains `PARTIAL` until final CI/profile evidence, and final CI/HUMAN_DIAGNOSTIC APK/exact-source SCIP plus Android revalidation are still pending. The inherited profile evidence gate is not claimed fixed. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Sum three-mode refinement final automated delivery evidence

- Final application source is `bda65eb9bedcb3cba5793208f059178a299a037e` (`feat(mind): refine Sum detailed visualization`). The required application commit was pushed before its journal child `f2efaaa6545de5b8cab60cf77d38d7c96a39d720`; the child modifies only this journal. No application source changed after the build/graph inputs were frozen.
- **Local validation:** Ubuntu/proot focused Mind domain/projection/viewport/Year suite PASS (**66 tests**); settings/host/RangeSlider/Core ephemeral-focus suite PASS (**140 tests**); `flutter analyze --no-pub` PASS (`No issues found!`, 210.9s); changed-Dart format check and `git diff --check` PASS; `./scripts/test-fluvi-fast.sh` with the required Flutter PATH PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh` PASS. Tooling `dart test` PASS (**15 tests**).
- **Actions `35496701673`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly and baseline lanes are skipped. The workflow is **FAIL overall**, never globally green, solely because `run-dashboard-profile` fails at `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`. The same exact failure is present in baseline application run `35491099076` for `f311241b`; its consequent missing `B_year_month_rail_populated` report map is not classified as a new Sum feature failure.
- **Human APK:** release `fluvi-human-diagnostic-bda65eb` targets exact source `bda65eb9bedcb3cba5793208f059178a299a037e`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_bda65eb.apk` exists, is `84,235,781` bytes, SHA-256 `5cf818e5b1a8d0b1ef9e9bae3a4e827fab6c7af9050cd76324428d074eb2488b`, passes APK zip-integrity verification, and contains the full exact application SHA in `libapp.so`. The workflow requires and supplies that SHA through `FLUVI_BUILD_COMMIT`.
- **Exact-source SCIP:** tooling commit `89498fd0201187e54d78b8bdb92a66264f419ce5` is pushed on `tooling/scip-codegraph-v1`. Its manifest has `source_head=bda65eb9bedcb3cba5793208f059178a299a037e`, `source_parent=1427b4abc569068f25714058e7de9f939b05aaa1`, `scip_dart=1.6.2`, raw index SHA-256 `e578d482ed5003a55f2a9c0a450ca8e8a65389d6cdb9a3576b0a34b1eac14735`, 484 documents, 333,571 occurrences and 11,342 repository-defined symbols. Two complete graph generations produced the identical graph-tree SHA-256 `dc98e2f1df7c3238f76a7efc78fbc78f445e744e6ea5c229e7cd7607bd999d83`.
- No fresh Drive log was read, by explicit feature-work instruction. A final reviewer claim was source-checked against the exact application tree: the same-year frame-identity zoom reset (`DSUM-02R`), plot-gutter-excluding focal stability (`DSUM-02/03`), and the accessible Year day-infocard dismissal (`YEAR-DAY-INFO-02`) are already present and green; no speculative rewrite was added. The unresolved boundary is physical Android validation of this exact APK. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Sum synchronized diagnostics and Year direct-grid delivery

- Application commit `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301` is the current application candidate. It retains the existing local top-toggle-only Sum modes (heatmap, detailed line, monthly overlay) and adds bounded `MIND_SUM` lifecycle diagnostics through the existing on-screen **Mind Heatmap** debug filter. Copy now uses the active filtered diagnostic set rather than the whole ring, so the user can export relevant pointer-count, scale/focal/window/span/LOD, synchronized-path and nearest-point inspection evidence without creating another debug UI or source of truth.
- The detailed Sum chart now owns one normalized local viewport above its visible yearly bands. A pinch or zoomed pan updates that shared calendar fraction, so every rendered year maps to the same temporal portion. The corrected normalized-start mapping retains focal stability while allowing the explicit half-year (`<=184` days) zoom contract; frame-identity replacement resets local viewport and selection state rather than carrying stale geometry into a newer financial frame.
- The Year primary no longer owns global MonthCard/surface/layout settings. It draws direct day-cell month groups inside the card and provides a local header selector with only `3x4` and `4x3`. The compact `4x3` solver remains zero-scroll; `3x4` retains its one vertical owner and displays per-month `Scope` and `Zárás` lines. Removed paths include the old `2x6`, MonthCard surface options and the prior special extra envelope allocation. Query, RangeSlider, financial semantics, Time/Avatar motion, Room/Kotlin/schema, Header score/colour, BottomNav, Month/Day, and Year secondary card behavior are intentionally unchanged.
- **RED/GREEN / local validation:** debug clipboard lifecycle coverage, Sum shared-window/noisy-pinch/zoom-depth coverage, Year direct-selector/layout/zero-scroll coverage, settings/tuner/host/range regression all pass. Ubuntu/proot `flutter test --no-pub test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart --reporter expanded` PASS (**15 tests**); query range PASS (**12 tests**); Year viewport PASS (**24 tests**); `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); full `flutter analyze --no-pub` PASS (`No issues found!`, 93.7s); `./scripts/verify-fluvi-boundaries.sh` and `git diff --check` PASS. The Termux/proot formatter's first `--set-exit-if-changed` run reports seven changes, but an immediate second formatting pass is byte-identical across all 15 changed Dart files.
- The exact-source Actions run `35502797850` has been started for application SHA `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301`; its individual lanes, human APK, SHA-256, embedded identity and exact-source SCIP are pending this entry. The checklist keeps Year visual geometry as `PARTIAL` until candidate-APK visual evidence and keeps Android behavior user-only. No Drive log was read for this feature cycle. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Sum diagnostics and Year direct-grid final automated evidence

- Exact final **application** source remains `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301` (`feat(mind): synchronize Sum diagnostics and direct Year grid`). It was pushed before journal children. The application parent is `14fb009b6be090ec2ad4857a2b5c8f0c9dfd4ea2`; this journal's application-evidence child is `8b4c844e1a851bfcbcd08c3a5254e322ac6e127d`, and it changes only this journal file. No application source changed after the final application SHA.
- **Actions `35502797850`:** `dashboard-paths`, `test-core`, `test-flutter`, and `build-human-diagnostic-apk` are PASS; nightly and baseline jobs are skipped. The workflow is **FAIL overall**, never globally green, solely because `run-dashboard-profile` fails at `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`, followed by `B_year_month_rail_populated must be a report map`. This is demonstrated inherited rather than newly introduced: directly preceding app run `35496701673` for `bda65eb9bedcb3cba5793208f059178a299a037e` has the identical two error lines. No earlier failing application lane exists in run `35502797850`.
- **Human APK:** release `fluvi-human-diagnostic-f6d6da7` targets exact `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_f6d6da7.apk` exists, is `84,399,621` bytes, SHA-256 `81355706ab4535a3bef8b1f5623ddd773aeea75197a83abfa7c816329741b11b`, passes zip-integrity verification, and contains the full exact `FLUVI_BUILD_COMMIT` source identity.
- **Exact-source SCIP:** tooling commit `28791a90f091ac6b3e7dcce409aeb50413d09b83` on `tooling/scip-codegraph-v1` contains only deterministic `docs/codegraph` artifacts. Manifest has `source_head=f6d6da7274835eb1f72b3ec1cb6ee5f846f84301`, `source_parent=14fb009b6be090ec2ad4857a2b5c8f0c9dfd4ea2`, `source_ref=HEAD` because the provenance-checked source worktree was detached at the exact application SHA, `scip_dart=1.6.2`, raw index SHA-256 `d21653bcdf1b4ebad6c728ab31f2ba1c0ddfce149a36f978a6fcaf381c57fdb2`, 484 documents, 333,810 occurrences and 11,345 repository-defined symbols. Two complete generations match graph-tree SHA-256 `cd2c4a8655387c49072cb0beda4983fb2e6ecb0102a76be2ed38d8b747e5daf9`; tooling `dart test` is PASS (**15 tests**).
- The source/test criteria for synchronized Sum diagnostics and direct Year presentation are complete, but the acceptance checklist remains honest: Year visual geometry needs candidate-device/screenshot evidence and Android interaction acceptance remains user-only. No fresh Drive log was read. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Fresh Sum physical log: cross-band pinch, pan morphology drift, Year 4x3 shrink regression

- New physical Android feedback is tied to three screenshots and a freshly updated connected `Fluvi mind heatmap` document. The exact tested APK/source SHA is still **MISSING EVIDENCE** because neither the screenshots nor the exported diagnostic snapshot contain a build marker. The current application candidate under review is `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301` (`feat(mind): synchronize Sum diagnostics and direct Year grid`); branch HEAD before this journal-only record is the documentation child `8b4c844e1a851bfcbcd08c3a5254e322ac6e127d`.
- **Frozen fresh Drive evidence:** document `Fluvi mind heatmap`, id `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified `2026-09-20T09:53:46.252Z`, Docs revision `ANLCKQkI9tTJ-QqfktAKNL4HyTxy8DGn3M2L9wd_Ms978Z1Y0VDVRjxV2WUMC_5iPyURba6AFnZX9ejsvt9x1Q`. Full text export is 15,475 bytes, SHA-256 `b86dc484190f3b0b9e8a3be68983b596ffb31ac4c06f9b5f46d3c50b967883cf`. The export contains no `LIVE_TAIL`, session id, build SHA or `USER_MARK`. It contains 61 filtered diagnostic records carrying global `seq=` values, first `3893`, last `4892`. No duplicate/conflicting retained sequence is present. Sequence jumps cannot be called retention gaps because the on-screen Mind Heatmap filter excludes unrelated global diagnostic categories.
- **Fresh physical/log zoom evidence:** retained `MIND_SUM|PAN` records repeatedly show `visibleYears=3 renderedBands=3`, `spanDays=276`, `viewportSpan=0.756`. This is about nine months of a year, not the requested roughly six-month maximum visible span. At seq `4889`, `MIND_SUM|PINCH_OWNERSHIP` records `pointers=2 pinchActive=true` at that same 276-day window. The next retained events are `PAN` seq `4890`/`4891`, followed by `PINCH_OWNERSHIP` false at seq `4892`; no retained `MIND_SUM|SCALE_START|SCALE_UPDATE|SCALE_END` appears for that two-pointer interval. Because the retained snapshot begins already zoomed at `viewportSpan=0.756`, this proves only that the captured two-pointer attempt did not show an accepted scale lifecycle; it does not prove that no earlier scale ever succeeded.
- **PROVEN cross-band pinch owner gap at f6d6da7:** the parent `MindDetailedSumChart` owns the shared normalized viewport and raw active-pointer count, but every `_MindDetailedSumYearBand` still owns its own child `GestureDetector.onScaleStart/onScaleUpdate/onScaleEnd`. Two fingers placed on different visible yearly bands therefore reach the parent pointer counter as two pointers while each child scale recognizer can see only its own pointer. This source topology directly explains why multi-year physical pinch is much harder than one-year pinch and is consistent with the fresh seq-4889 ownership-without-scale evidence. The repair target is one parent-wide scale recognizer over the whole detailed chart interaction surface, with the shared normalized viewport as its sole zoom writer; per-band painters remain consumers, not independent scale owners.
- **PROVEN pan-morphology root cause at f6d6da7:** each year band computes its Y-axis `maximum` from only the current visible LOD sample and paints every Y coordinate as `point.total / maximum`. Horizontal panning can therefore change the visible maximum and rescale every surviving point vertically, so the same underlying data visibly changes shape instead of translating/cropping. In addition, `MindDetailedSumLod.sample` derives bucket membership from `(epochMinute - window.startEpochMinute) / window.visibleMinuteCount`; panning at a constant zoom shifts bucket boundaries and can choose different first/last/min/max anchors in overlapping time. Both mechanisms are source-proven morphology drift.
- **Required morphology invariant:** at an unchanged zoom level, horizontal pan must not change the financial shape of the overlapping time interval. Use a stable per-year Y scale for the current admitted identity/range (not a visible-window maximum), and use pan-stable LOD/bucket boundaries anchored to absolute calendar/normalized-year coordinates for a given resolution. Panning may crop/translate; zoom-level changes may legitimately change resolution. No fake interpolation or financial rescaling is allowed.
- **PROVEN Year 4×3 size regression cause at f6d6da7:** the new Year direct-grid header reserves `headerHeight=30` and the 4×3 solver is called with `viewportHeight = constraints.maxHeight - headerHeight`. The solver then derives `fit.cellExtent` from that reduced height and passes it directly to every month group. Thus the title/3×4–4×3 selector is paid for by shrinking the 4×3 day cells inside the same fixed card envelope. This violates the prior product invariant that adding the selector must not reduce the approved 4×3 heatmap size.
- **Year screenshot/geometry evidence:** the current 4×3 screenshot visibly has substantial vertical/inter-month whitespace available while the day grids are smaller. Product requirement is to reclaim that whitespace instead of shrinking cells: reduce row/month-group gaps/padding/chrome as needed, retain the title + two-button selector in the reclaimed top area, position the heatmap field lower, keep the lowest month/day row at the intended lower boundary, and preserve zero-scroll 4×3. The approved pre-selector 4×3 cell size is the minimum baseline; actual painted cell extent, not only month-group width or theoretical width-derived `cellExtentFor`, must be regression-tested.
- **PROVEN test gaps:** current synchronized Sum tests prove a synthetic two-pinch <=184-day model/widget contract but do not put the two pointers on different yearly bands. Current morphology tests do not assert that an overlapping interval keeps identical anchor identity/Y geometry during same-zoom pan. Current Year zero-scroll tests prove only existence/bounds/scroll extent; they do not compare actual `fit.cellExtent`/painted day-cell size against the approved pre-header 4×3 baseline. These are false-green boundaries for the new physical feedback.
- **Matching SCIP:** exact-source graph for `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301` is tooling commit `28791a90f091ac6b3e7dcce409aeb50413d09b83`, `scip_dart=1.6.2`, raw index SHA-256 `d21653bcdf1b4ebad6c728ab31f2ba1c0ddfce149a36f978a6fcaf381c57fdb2`, 484 documents / 333,810 occurrences / 11,345 repository-defined symbols. Graph/source review confirms the direct production/test neighborhoods for `MindDetailedSumChart`, `MindDetailedSumNormalizedViewport`, `MindDetailedSumLod`, `MindYearHeatmapViewport`, `MindYearHeatmapMonthGroup`, `_MindYearHeatmapFourColumnFit` and the local Year selector.
- **UNPROVEN:** exact tested APK SHA; exact Android recognizer cadence outside the captured interval; whether any additional device-specific factor contributes after parent-wide scale ownership is fixed; the final numeric gap/padding constants needed to restore the approved Year geometry.
- **MISSING EVIDENCE:** cross-band two-finger RED→GREEN production-parent pinch test; fresh log showing parent-wide `SCALE_START/UPDATE/END` and <=~184-day physical span; same-zoom pan morphology/anchor-stability test; stable-Y-scale proof; pan-stable LOD proof; actual painted 4×3 cell-size baseline test against the pre-header approved geometry; candidate-APK screenshots; final CI/APK/final-source SCIP; user Android acceptance.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, test, workflow, graph or milestone file is modified by this record. Physical validation of the next candidate remains `PENDING — USER ONLY`.

## 2026-09-20 — Parent-wide Sum pinch and pan-stable Year-grid repair

- Application commit `cd1368dd083b8d0e8299253a315b586fc86d71d9` repairs the three source-proven boundaries recorded in the fresh physical evidence entry above. It is based on application source `f6d6da7274835eb1f72b3ec1cb6ee5f846f84301`; prompt/planning documentation head before the application commit was `5e3b508a2df74d057c476d73ae8fec00ba4e6422`.
- **Sum gesture ownership:** `MindDetailedSumChart` now owns the one parent-wide two-pointer lifecycle through its existing raw listener. The parent writes the existing shared `MindDetailedSumNormalizedViewport`; individual year bands no longer own competing scale recognizers. A noisy production-host test deliberately places one finger in 2024 and another in 2025, reaches `<=184` days in both bands, records `MIND_SUM|SCALE_START/UPDATE/END owner=parent`, keeps the detailed list at offset zero, and does not start `DashboardExpansionController`. One-pointer pan remains local and the shared RangeSlider/Query authority is unchanged.
- **Sum morphology:** the per-year Y domain is now derived from the full resident current-frame/current-range annual source, not from the cropped visible LOD sample. LOD bucket boundaries are anchored to the year home domain at a given resolution, and the renderer requests one bounded bucket of resident source either side of the cropped domain. `XR-SUM-04` was RED against the viewport-relative grid and is GREEN: same-zoom overlapping interior anchors remain identical through pan. `XR-SUM-03` proves that panning a high outlier into the crop does not re-label/re-normalize the annual Y axis. Deep windows explicitly retain the existing prepared transaction-minute source; no Room/repository/Query path is added.
- **Year 4x3 geometry:** before code change, the pre-selector `bda65eb9bedcb3cba5793208f059178a299a037e` production host was mounted and its actual `MindYearHeatmapMonthPainter.cellExtent` was frozen at `4.333333333333333` logical pixels. The current selector implementation had regressed to `3.111111111111111`. Four-column direct groups now reclaim existing title/gap/padding chrome (compact 2px vertical padding, 10px month title and 1px title gap; grid top/bottom padding 5/0) while retaining the main title, local 3x4/4x3 selector and zero-scroll fit. Mounted `YEAR-HEIGHT-02` is GREEN at or above the baseline; 3x4 footer semantics remain unchanged.
- **RED/GREEN evidence:** RED commands were: `flutter test --no-pub test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart --plain-name "XR-SUM-04 RED" --reporter expanded` (overlap anchor sets differed); `flutter test --no-pub test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart --plain-name "XR-SUM-01/02 RED" --reporter expanded` (cross-band span stayed 366); `flutter test --no-pub test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart --plain-name "YEAR-HEIGHT-02" --reporter expanded` (actual cell extent `3.111111111111111 < 4.333333333333333`). All are GREEN after this application commit.
- **Validation PASS:** Ubuntu/proot `flutter test --no-pub test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart --reporter expanded` (5 tests); `flutter test --no-pub test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart --reporter expanded` (27 tests); `flutter test --no-pub test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart --reporter expanded` (24 tests); `flutter test --no-pub test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart --reporter expanded` (22 tests); `flutter analyze --no-pub` (`No issues found!`, 97.4s); changed-Dart `dart format --output=none --set-exit-if-changed`; `git diff --check`.
- **Intentionally unchanged:** Sum top-toggle modes (heatmap/detailed/monthly overlay), no Sum PageView/exact aggregate restoration, nearest-real-point inspection, dashed separators, Year bar/line secondary pages, Month/Day, inline legend, Query/RangeSlider, Time/Avatar protected milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`, Room/Kotlin/schema, Header, BottomNav and `MILESTONE_COMMITS.md`.
- **Still unproven:** the screenshots and fresh log still lack an exact build marker; Android recognizer cadence and visual acceptance of this new candidate are user-only; final CI, human APK, exact-source SCIP and the inherited profile lane must be re-run/reported. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Parent-wide Sum pinch / pan-stable Year-grid final automated delivery evidence

- **Final application source:** `cd1368dd083b8d0e8299253a315b586fc86d71d9` (`fix(mind): stabilize Sum zoom and Year grid cells`) was pushed before this evidence entry. Its preceding application-evidence journal child is `2d8b0e68`; checklist evidence is `5529b10d`. No application source changed after `cd1368dd`.
- **Local PASS:** Ubuntu/proot focused detailed-model (5), Sum viewport (27), Year viewport (24) and production Mind-host (22) suites; full `flutter analyze --no-pub` (`No issues found!`); changed-Dart format check; `git diff --check`; `./scripts/test-fluvi-fast.sh` (**431 tests**); and `./scripts/verify-fluvi-boundaries.sh` all passed.
- **Actions `35507191218` for exact tag/source `cd1368dd`:** PASS — `dashboard-paths`, `test-flutter`, `test-core`, `build-human-diagnostic-apk`; SKIPPED — nightly and profile-baseline lanes; FAIL — `run-dashboard-profile`. The workflow is **FAIL overall**, not green. Its only reported primary error is the pre-existing `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`; the later missing `B_year_month_rail_populated` report-map error is consequential. The profile prelaunch command itself records `FLUVI_BUILD_COMMIT=cd1368dd083b8d0e8299253a315b586fc86d71d9`.
- **Human APK:** release `fluvi-human-diagnostic-cd1368d` targets exact source `cd1368dd083b8d0e8299253a315b586fc86d71d9`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_cd1368d.apk` exists, has `84,235,781` bytes, SHA-256 `221a59a1d9726d0bdf8738ddfc8151f4e57d9803eb04268b9994730aabd34ea5`, passes ZIP integrity, and contains the full application SHA in `lib/arm64-v8a/libapp.so`.
- **Exact-source SCIP:** tooling commit `37f171c69771f19326571dd9d490a56082629391` is pushed on `tooling/scip-codegraph-v1`. Its manifest has `source_head=cd1368dd083b8d0e8299253a315b586fc86d71d9`, `source_parent=5e3b508a2df74d057c476d73ae8fec00ba4e6422`, `scip_dart=1.6.2`, raw index SHA-256 `6230cd4bce912050aa4062f1e6a4cb47f8569455e86133afb713d53fcc775ebf`, 484 documents, 334,501 occurrences and 11,348 repository-defined symbols. Two complete generations produced identical graph-tree SHA-256 `520efbabb886f6e728ca3ed5ba93338bdf826b906a81c5c5aae5753a968372d8`; tooling `dart test` PASS (**15 tests**).
- **Remaining evidence boundary:** the physical screenshots/frozen log still have no build marker, and no human has tested this newly downloaded, exact candidate APK. Candidate screenshot/Android validation is therefore not inferred from automated evidence. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Exact cd1368 physical Summary freeze, residual Sum pan-detail inconsistency, and 1/2 chart-density request

- New Android feedback is tied to two screenshots plus three refreshed connected diagnostic documents. Unlike the preceding screenshot-only rounds, this capture has an authoritative build marker: `Fluvi logs time fling` ends with `USER_MARK issue=time_fling ... commit=cd1368dd083b8d0e8299253a315b586fc86d71d9 build mode=profile build purpose=HUMAN_DIAGNOSTIC automated scenario runner=false automated input driver=false`. Therefore the physically tested application source for this report is **exactly** `cd1368dd083b8d0e8299253a315b586fc86d71d9` (`fix(mind): stabilize Sum zoom and Year grid cells`). Current branch HEAD before this journal-only feedback entry is docs/checklist child `539fa4ebb767061488d308b6824babb47225234a`; no later application source is present at audit time.
- **Frozen diagnostic snapshot A — Mind:** Google Doc `Fluvi mind heatmap`, id `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified `2026-09-20T11:41:31.124Z`, revision `ANLCKQnlMynoGQ9HuCyU7zhEL26AcHdcbnPEkOZFXd9sxBUEZLqGPgOyHcTFR2774y0JUeL95fXAOAMjhfC6yw`. Complete text export: 342,839 bytes, SHA-256 `ec858862f03d28d0be6e4c40d235e6bcc4060c14614837405febe4aaf6229678`, 966 non-empty records, retained global seq 15668..16663 with no duplicate/conflicting retained seq. The one numeric jump is not classified as a retention gap because this document is the filtered Mind diagnostic view. Stage counts include 610 `MIND_SUM|PAN`, 352 `MIND_SUM|SCALE_UPDATE`, one `SCALE_START`, one `SCALE_END`, and two pinch-ownership events. The retained window begins around `spanDays=154 viewportSpan=.420` and later reaches about `spanDays=22 viewportSpan=.058`; therefore the repaired parent-wide pinch now physically reaches well inside the requested half-year depth.
- **Frozen diagnostic snapshot B — all logs:** Google Doc `Fluvi alllogs`, id `1wDafwN-VeKIRaKEX-zciws4xV2wiXLYTRhbDsyLoXx8`, modified `2026-09-20T11:37:17.312Z`, revision `ANLCKQmttrW8JyGl-WBP7I-KDjf4kdfcxWsg4tVOQFBJ5PFnOFq3ijWUJdqHw5QnYNYpWSgby62gxP5oqIDybg`. Complete export: 446,006 bytes, SHA-256 `aeb2f4801b9f347ea3d0d3e030035b3fd5a4c6eee241c7b4732f1eb89fbd3524`, exactly 1,000 unique seq records 14075..15074 with no gaps/duplicates/conflicts.
- **Frozen diagnostic snapshot C — Time:** Google Doc `Fluvi logs time fling`, id `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, modified `2026-09-20T11:36:55.962Z`, revision `ANLCKQmh_16XId0lReMTM4FvpAybV-TeovZHZCohMuGrxin5OZbzyHjtmU-609PR6-H4tyriCH5oZXustQ8D4w`. Complete export: 447,049 bytes, SHA-256 `e7c68ca1dad065da431985f9f27601b69773648bb0083dc0b6f737cb688b04af`, exactly 1,000 unique seq records 14079..15078. Together with all-logs it forms one overlapping, non-conflicting retained sequence through 15078; the overlap is duplicate snapshot content, not separate runtime evidence.
- **PHYSICAL DEFECT 1 — Summary mode selector freeze:** after a small interaction, the segmented Summary Pill stops responding to vertical swipe and remains stuck in Sum. Fresh exact-build evidence shows repeated direct contacts are not rejected by hit testing: seq 14970, 14972, 14974, 15067, 15069, 15071 and 15073 are all `SUMMARY_POINTER_ACCEPTED accepted=true`; their paired `SUMMARY_POINTER_HIT_CLASSIFIED` records are all `level=sum owner=selector selectorTrack=0 variant=segmented upperVerticalHandling=false`. The accepted selector/controller/ScrollPosition/physics identities remain stable. Starting with seq 14972 and on every later attempt, `priorMotionLanes=summaryShell`; every attempt reports `priorActivity=HoldScrollActivity`. No subsequent mode crossing is recorded and the user physically reports that mode switching is impossible.
- **Source-proven Summary liveness boundary at cd1368:** `CenteredCarousel` reports the raw pointer decision before it interrupts existing motion, then calls `noteDirectPointerDown`, `interruptForDirectPointer`, the feature direct-input callback, and only begins a new user motion command after a real `ScrollStartNotification`. `CenteredCarouselController._scheduleTerminalActivityCheck` gives a terminal `HoldScrollActivity` exactly one additional frame-local retry; if the same Hold remains after that, it returns without `onMotionIdle`/settle. Existing shared-carousel tests explicitly protect the case `a persistent terminal hold receives only one retry frame` and expect active Hold + no settle. The fresh repeated physical sequence — every later raw pointer starts with stable selector ownership, `summaryShell` active and the same `HoldScrollActivity` class — is consistent with an orphaned/persistent terminal Hold leaving the Summary lifecycle without a liveness completion. This identifies the **first source-proven liveness boundary**, but the exact repair mechanism must first be reproduced in a production-parent RED test so stale/superseded settle safety is not weakened.
- The end USER_MARK also retains an earlier `TM|FLIGHT_SUMMARY` with two semantic ticks, two accepted live snapshots, two painted live snapshots, zero root misses/paint rejects and one canonical settle. Thus the frozen Summary is not explained by a blanket failure to publish/paint the preceding time flight. Two retained older exceptional outcomes are explicitly `SUMMARY_SETTLE_REJECTED_UNPAINTED_OR_SUPERSEDED`; they are historical retained records and must not be misclassified as the current freeze without matching generation/identity.
- **PHYSICAL DEFECT 2 — residual detailed-Sum pan/detail inconsistency:** pinch now works and reaches deep zoom, but the paired 13:39 screenshots show that at an apparently unchanged zoom a 2027 band can display only a short line segment; after horizontal pan, materially more 2027 detail becomes visible. The current Mind snapshot confirms long same-span pan runs (e.g. `spanDays=154 viewportSpan=.420`) but current `PAN` diagnostics report only the shared first-year window and `anchors=0` when no plot width is supplied; they do not record per-year source count, selected LOD anchors, stable Y maximum or bucket resolution. Therefore the exact remaining 2027 first-failing data/LOD boundary is **UNPROVEN** from logs alone.
- **Current source facts for residual Sum inconsistency:** cd1368 already uses a stable annual Y maximum and a year-home-anchored LOD bucket grid. `_detailSourceForWindow` requests one bucket of padding on each side and broad windows resolve only current-range **non-empty daily aggregates**; `MindDetailedSumLod.sample` has an early return that emits every visible source point whenever `visible.length <= binCount`. Consequently a horizontal pan can legitimately encounter a calendar region with a different count of non-empty daily observations, while an edge/padding/LOD defect could also change visible anchors. The screenshots alone do not distinguish legitimate sparse calendar coverage from an erroneous refinement/crop discontinuity. Before further LOD mutation, add per-band forensic diagnostics and a RED test using one fixed synthetic 2027 source to prove whether identical overlapping source time/amount observations disappear/reappear solely due to pan.
- **New product setting — Sum graph density:** add a presentation-only settings-menu option controlling maximum simultaneously visible yearly charts for Sum chart surfaces: **2 charts (current/default)** or **1 chart**. It must apply to BOTH detailed-line and monthly-overlay-bar surfaces, not heatmap. In 1-chart mode every yearly chart band fills approximately the entire available chart viewport (roughly 2× the current two-band height); additional years are reached by the existing internal vertical scroll. In 2-chart mode preserve the current exact two-band fit, with 3+ years scrolling. The setting must not create Query/data state or alter financial semantics.
- Current source has no such setting. `MindYearHeatmapPresentationSettings` already owns Sum-only presentation choices (`sumYearRowLayout`, `sumMonthLabelPlacement`) and the existing `Mind hőtérkép` tuner section renders them. Detailed-line height is currently derived locally in `MindDetailedSumChart`; monthly overlay years are currently hard-coded to `height: 144`. The new single shared presentation value should feed both surfaces from the existing presentation controller and replace duplicated/fixed density assumptions rather than adding two independent settings.
- **Matching SCIP:** exact graph for tested source `cd1368dd083b8d0e8299253a315b586fc86d71d9` is tooling commit `37f171c69771f19326571dd9d490a56082629391`, `scip_dart=1.6.2`, raw index SHA-256 `6230cd4bce912050aa4062f1e6a4cb47f8569455e86133afb713d53fcc775ebf`, 484 documents / 334,501 occurrences / 11,348 repository-defined symbols. Graph/source review confirms production/test impact through `DashboardCoreController.noteSummaryDirectPointerDown`, `recordSegmentedPointerDown`, `SummaryPillExperiment`, and shared `CenteredCarouselController` pointer/motion lifecycle, plus the Mind Sum presentation paths.
- **PROVEN:** exact physical build cd1368; raw Summary selector pointers are accepted and hit the correct segmented Sum selector; repeated later attempts begin with `summaryShell` active + `HoldScrollActivity`; source terminal-Hold logic can deliberately stop after one retry without idle; deep Sum pinch works in this build; current settings have no 1/2-chart density control.
- **UNPROVEN:** exact framework activity transition that first creates/retains the orphaned Hold in this physical sequence; whether the remaining 2027 line-detail difference is a true LOD/crop defect or only sparse-data visibility without better per-band evidence; exact desired pixel height beyond the relational one-chart≈full-view/two-chart≈half-view contract.
- **MISSING EVIDENCE:** production-parent RED reproducer for Summary persistent-Hold freeze; activity-lifecycle diagnostics around pointer down/end/ScrollStart/ScrollEnd/Hold→Idle; stale/superseded-settle positive controls; per-band Sum source/LOD/painter diagnostics during same-span pan; overlap-anchor invariance test using a controlled 2027 series; 1-vs-2 chart-density mounted tests for detailed line + monthly overlay; final CI/APK/final-source SCIP; user Android revalidation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, test, workflow, tooling graph or milestone file is modified by this record. Physical validation of the next candidate remains `PENDING — USER ONLY`.

## 2026-09-20 — Year 3-column month-card profitability tint option

- New presentation-only product request for the Mind Year heatmap in the **3-column layout only**. In this layout, each month must always render inside a month card.
- Add an optional profitability tint for those month cards: **light red** when the month is loss-making and **light green** when the month is profitable. The tint is a visual background treatment only; it must not replace or recolor the existing heatmap day-cell encoding.
- This treatment must be user-configurable in Settings: the profitability background can be enabled/disabled independently, and its card-background opacity must be adjustable with a slider.
- The opacity control affects only the red/green month-card background tint, not text, heatmap cells, borders, shadows, or the financial calculation itself.
- Profit/loss classification must use the app's existing monthly financial result/balance semantics rather than inventing a second calculation path. Break-even/zero should remain visually neutral unless an existing product semantic already defines it otherwise.
- Scope lock: this feature applies only to the Year heatmap's 3-column month-card presentation. The 4-column direct-cell layout must remain unchanged.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, tooling graph or milestone file is modified by this record.

## 2026-09-20 — Year 3x4 profitability MonthCard delivery

- Application commit `ecef0ad922d3625b7633c62fcdfdb2b13001e461` adds the requested **3x4-only** profitability MonthCard presentation. The existing `MindYearHeatmapPresentationController` is the only new-preference writer: `yearThreeColumnProfitabilityTintEnabled` defaults to false and `yearThreeColumnProfitabilityTintOpacity` defaults to `.16`; each real change advances only its presentation revision. Neither setting writes Query, changes the immutable annual frame, or recalculates finance data.
- Every 3x4 `MindYearHeatmapMonthGroup` now keeps a rounded `mind-year-month-card-surface-<month>` envelope. Its background is neutral while disabled, positive green when `MindYearHeatmapMonthlyAggregates.netForMonth(month) > 0`, negative red when it is below zero, and neutral at zero/missing value. The color is alpha-blended only into the card background; the existing monthly aggregate is the sole financial authority. The `4x3` construction explicitly keeps `showMonthCard=false`, preserving that renderer's direct-cell surface, geometry, day painter, zero-scroll behavior and financial values.
- The Mind heatmap tuner gains a live Hungarian switch (`Hónapkártya háttér`) and separate `Háttér erőssége` slider. The slider controls only that green/red blend alpha: day-cell painter colors, text, borders, shadows, icons, Scope/Zárás and data semantics remain independent. Semantic positive/negative tint token sources live in `FluviVisualTokens`; no local copied palette is introduced.
- **RED/GREEN:** `YEAR-PROFIT-SETTINGS` first failed because the preferences/controller methods were absent; `YEAR-PROFIT-01` first failed because the 3x4 MonthCard surface did not exist. GREEN coverage now proves default/revision behavior, permanent 3x4 card vs 4x3 isolation, positive/negative/zero backgrounds from `netForMonth`, enable/disable, live opacity, unchanged heatmap cell color, unchanged frame identity and live tuner control publication.
- **Local validation PASS:** Ubuntu/proot `flutter test --no-pub test/features/dashboard/mind/domain/mind_presentation_settings_test.dart --reporter expanded` (8 tests); focused `YEAR-PROFIT-01` and `YEAR-PROFIT-02/03/04`; full `mind_year_heatmap_viewport_test.dart` (26 tests); focused `dashboard_header_visual_tuner_test.dart` Mind presentation case; changed-Dart `dart format --output=none --set-exit-if-changed`; `git diff --check`; and `flutter analyze --no-pub` (`No issues found!`, 203.5s).
- **Intentionally unchanged:** Summary motion lifecycle, Sum detailed/overlay behavior and its density setting, Year 4x3, secondary Year bar/line pages, Month/Day, Query/RangeSlider, Room/Kotlin/schema, Header, BottomNav, Time/Avatar and milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. The Summary repair, Sum pan forensics and Sum density requirements remain active in the dedicated acceptance checklist; they are not claimed delivered by this focused application commit. Online CI/HUMAN_DIAGNOSTIC APK/exact-source SCIP and Android validation for `ecef0ad9` remain pending. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Segmented Summary terminal-Hold liveness repair

- Application commit `812d3981` repairs the first source-proven Summary liveness boundary from the exact physical `cd1368dd083b8d0e8299253a315b586fc86d71d9` evidence. The production symptom was accepted segmented SUM-selector contacts repeatedly beginning with `summaryShell` active and `HoldScrollActivity`, without a later mode crossing. The frozen log evidence remains bounded: acceptance is logged before interrupt/lifecycle completion, so the raw line alone did not prove a post-pointer lane state; the repeated subsequent Hold start states and controller implementation motivated a production-parent reproducer.
- `SUMMARY-HOLD-01` mounts the real `CoreDashboard` segmented Summary in SUM, creates the completed persistent-Hold state at the production controller, then sends a real two-stage upward selector drag. Before repair the drag was accepted but left `TimePlane.sum`; after repair it crosses to `TimePlane.year`, leaves `summaryShell` inactive, and preserves the same `ScrollPosition` and physics creation count. This is the missing RED→GREEN boundary; it does not claim the exact framework transition which originally generated the device Hold.
- The shared controller still grants its existing single frame-local Hold retry. Only if that same current `HoldScrollActivity` remains after the retry, with no pointer down, no scrolling/drag and no stale command, it performs one same-pixel public `jumpTo` structural handoff and uses the already-existing current-command idle/settle gate. This is bounded (no timer, cooldown, repeated frame loop, physics/controller replacement, stale-target settle or semantic fabrication). Active pointer, real ballistic/driven work and stale commands remain excluded by the guard.
- **Local validation PASS:** production `SUMMARY-HOLD-01`; full `summary_pill_experiments_widget_test.dart` (**30 tests**); full shared `centered_carousel_widget_test.dart` (**16 tests**); shared controller test (**7 tests**); Avatar carousel test; dashboard presentation-controller test (**20 tests**); formatter and `git diff --check`; `flutter analyze --no-pub` (`No issues found!`, 200.1s), all through Ubuntu/proot. Summary's direct Time/Avatar shared-controller consumers therefore retain their targeted regression coverage.
- **Intentionally unchanged:** Summary selector hit classification, stable controller/ScrollPosition/physics identities, latest-wins settlement, canonical Query, Time/Avatar direct-manipulation policies, Sum/Year/Month/Day feature semantics and the Sum density/forensics work. The remaining exact-device result is still not self-approved. Online CI/HUMAN_DIAGNOSTIC APK/exact-source SCIP and user validation for `812d3981` remain pending. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Sum pan-continuity forensic boundary and shared chart density

- Application commit `c74bfa56` keeps the two distinct Sum concerns separate in architecture and evidence. The remaining sparse-2027 physical screenshots did **not** prove a general pan morphology regression: the previously repaired stable yearly Y-scale and year-anchored LOD grid remain intact. Instead, `SUM-PAN-EDGE-01` established a narrow edge-path contract: a visible real series may retain at most one true source neighbour beyond each crop edge for drawing continuity, while inspection remains limited to current in-window represented anchors.
- `MindDetailedSumLodSelection` now exposes separate immutable `inspectablePoints` and `paintPoints`. The painter maps outside neighbour anchors beyond plot bounds and clips the canvas, so the real segment reaches the visual crop edge without inventing a boundary amount or placing a marker there. Taps continue to use only `inspectablePoints`. Existing overlap/pan-stability coverage remains GREEN. Bounded `MIND_SUM|BAND_SNAPSHOT` records are emitted only at `SCALE_END` and horizontal `PAN_END`, per rendered year, with source/visible/LOD/paint counts, year window, bucket minutes, stable Y maximum, first/last anchor, deterministic digest, neighbour counts and paint-continuity flags. The on-screen Mind diagnostic filter therefore has enough copyable evidence to distinguish sparse source coverage from representation loss in the next Android test; no source rows or per-pointer flood is emitted.
- The existing `MindYearHeatmapPresentationController` now owns the default-two `MindSumVisibleChartCount` preference. The new Hungarian tuner choice **“Sum grafikonok egyszerre”** offers only `1 grafikon` and `2 grafikon`, advances presentation revision only, and never changes Query or the admitted Sum frame. `MindSumChartDensityGeometry` is the one shared resolver used by detailed line and monthly overlay bars. Two mode fits two complete yearly bands including axes; one mode fills the viewport with one annual band; later years stay on the existing internal vertical scroll. The former independent 144px overlay height is removed. Sum heatmap ignores the preference.
- **RED/GREEN and local validation:** `SUM-PAN-EDGE-01` first failed because no LOD paint-continuity selection existed; `SUM-DENSITY-SETTINGS` first failed because no preference owner existed. GREEN coverage includes the pure edge/no-fake-inspection contract, deterministic overlapping LOD, density geometry, SCALE/PAN per-band snapshot fields, default/live one/two detailed and overlay layout, scroll reachability, frame identity, heatmap isolation and tuner ownership. Ubuntu/proot focused domain/settings suite PASS (**16 tests**); combined full Mind viewport + Year viewport + tuner suite PASS (**69 tests**); `flutter analyze --no-pub` PASS (`No issues found!`, 178.5s); formatter and `git diff --check` PASS; `./scripts/test-fluvi-fast.sh` PASS (**431 tests**); `./scripts/verify-fluvi-boundaries.sh` PASS.
- **Intentionally unchanged:** canonical Query/RangeSlider/frame authority, financial membership, heatmap colors, stable Y maximum, existing Year/Month/Day cards, Summary lifecycle, Time/Avatar, Room/Kotlin/schema and protected milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. The exact physical 2027 cause beyond this verified crop boundary remains an Android observation question, not a fabricated conclusion. Online CI/HUMAN_DIAGNOSTIC APK/exact-source SCIP and user validation for `c74bfa56` remain pending. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Final automated delivery evidence for Summary, Sum density and Year profitability

- The final application source is `c74bfa56572102ddfbadc0dfe276128cfbf60eb3` (`feat(mind): stabilize Sum pan continuity and chart density`), following the separately journaled profitability application commit `ecef0ad922d3625b7633c62fcdfdb2b13001e461` and Summary application commit `812d39818920802a26ee557ab5ddb17e66146092`. Their required journal-only children are respectively `84bcfd55`, `0bdb3658`, and `b8665a17`; each modifies only this journal file. The presentation-only 3x4 MonthCard profitability tint is therefore included in the exact final application source.
- **Actions `35514673033` for exact `c74bfa56`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly and baseline lanes are skipped. The workflow is **FAIL overall**, not globally green, because `run-dashboard-profile` fails at the known inherited assertion `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`; its subsequent missing profile-report map is consequent. This entry does not represent that profile evidence failure as a new Summary, Sum, or profitability failure.
- **Human APK:** release `fluvi-human-diagnostic-c74bfa5` targets exact source `c74bfa56572102ddfbadc0dfe276128cfbf60eb3`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_c74bfa5.apk` exists, is `84,334,085` bytes, SHA-256 `ecd1080496dce504066edea0e4fa1cd16f2827698df5798b1db85891027ba449`, passes archive integrity, and contains the exact full application SHA.
- **Exact-source SCIP:** tooling commit `f2b91d0f503b2dcdb4ac741d0b44c763b156899c` is pushed on `tooling/scip-codegraph-v1`. Its manifest pins `source_head=c74bfa56572102ddfbadc0dfe276128cfbf60eb3`, `source_parent=0bdb365843fa8823b5ccb4b002130c9e7733575a`, `scip_dart=1.6.2`, raw index SHA-256 `08eac118bca46137ee276b95a6e7dc8572182c87e45ee3270e813d3df0c0da64`, 484 documents, 336,305 occurrences and 11,385 repository-defined symbols. Two full provenance-checked generations produced the identical graph-tree digest `ba992e101e47fc5c5943a1d34112b25083717881475b7e8e870077d197929653`; tooling `dart test` is PASS (15 tests). Queries confirm the shared `CenteredCarouselController` has production consumers beyond Summary (including Avatar), the new density resolver is consumed by both detailed and overlay Sum renderers, and the existing Mind presentation settings remain the only preference owner.
- **Remaining evidence boundary:** `SUM-FORENSICS-02` remains deliberately partial. The new per-band, copyable `MIND_SUM|BAND_SNAPSHOT` diagnostics plus the source-only crop-edge repair establish an automated boundary, but the specific sparse-2027 device observation needs a new captured Android diagnostic sequence before it can be classified as real sparse coverage or a remaining renderer defect. No claim of complete physical resolution is made. **PHYSICAL VALIDATION — PENDING, USER ONLY.**

## 2026-09-20 — Sum line-header alignment + Year 3-column MonthCard border customization

- New presentation feedback only; no application implementation requested yet.
- **Sum detailed line chart header parity:** each yearly line-chart band must use the same year-label typography, size and horizontal/vertical placement as the corresponding yearly band in Sum monthly-overlay/bar mode. The right edge of the line-chart band must also show that year's compact total amount in the same position/format as the Sum bar mode. This is visual parity only; do not create a separate financial total authority.
- **Year 3-column MonthCard border customization:** for the Year heatmap 3-column layout, MonthCards must expose a user-selectable border treatment in Settings. This is additive to the already implemented 3-column profitability background tint/opacity option. The border setting is presentation-only and must not affect day-cell colors, profitability calculation, Scope/Zárás semantics, financial data, or the 4-column direct-cell layout.
- The exact border option taxonomy is not yet finalized by the user in this feedback turn; implementation must wait for the final prompt rather than inventing styles prematurely.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, tooling graph or milestone file is modified by this record.

## 2026-09-20 — Year 2x6 MonthCards and Sum curve presentation delivery

- Application commit `f8edad833d2ab4211e2c6a7b262a43dbf3827a71` adds the requested third local Year-card layout selector option: **2×6**. It remains an in-card presentation switch alongside 3×4 and the unchanged direct-cell 4×3 layout; it does not persist data or write Query. The 2×6 renderer uses the existing `MindYearHeatmapMonthGroup` MonthCard surface for every month, with the same existing `Scope` and `Zárás` financial authorities. Six rows are reached through the existing sole vertical scroll owner; there is no horizontal month scroll.
- `MindHeatmapDayNumberOverlay` is a neutral shared Month/Year primitive. The 2×6 Year cards use the exact existing Month heatmap top-left day-number treatment while 3×4 and 4×3 remain label-free. Day-cell paint, palette intensity, and day tap targets stay owned by the existing Year painter/interaction route.
- The existing presentation controller now names MonthCard chrome generically rather than 3×4-only: border enablement, profitability tint enablement, and tint opacity apply to both card layouts only. The background continues to derive from the existing monthly `netForMonth` authority: positive green, negative red, zero neutral. The slider blends only the card background, not day cells, text, borders, shadows, icons, Scope/Zárás, or financial values; 4×3 constructs no MonthCard surface.
- `MindSumYearBandHeader` is now the one shared header for Sum heatmap, detailed line, and monthly-overlay bands. Detailed and overlay rows therefore use identical year-label typography/position and the same compact year-total format from the existing immutable Sum frame, without another total calculation route.
- The same presentation controller adds independent detailed Sum options: linear / monotone cubic / Catmull–Rom interpolation; Catmull–Rom tension; weighted 3/5/7-day temporal smoothing; and separately enabled zoom-adaptive smoothing. The curve painter consumes these as paint-only input. Raw LOD anchors remain the only inspection/infocard values; local extrema are preserved by the smoother, zoom-adaptive strength continuously tends toward raw data as the visible time span narrows, and both cubic control points are clamped to their endpoint ranges to avoid interpolation-only overshoot.
- **RED/GREEN:** settings tests first failed for absent MonthCard/curve controls; the Year 2×6 widget test first exposed lazy ListView mounting and was corrected to prove the sixth row by scrolling the sole owner, rather than weakening the 12-month contract. Focused coverage proves selector/card/footer/day-number behavior, 4×3 isolation, card-only chrome/tint, unchanged cell palette, shared header parity, independent tuner wiring, weighted smoothing/extrema preservation, and bounded cubic controls. A permanent 430×560 2×6 golden (`test/goldens/mind_year_heatmap_2x6.png`) was generated and visually inspected.
- **Local validation before final delivery:** Ubuntu/proot focused settings, detail-model, Year viewport, Sum viewport/header, tuner, and golden tests PASS; changed-file formatter and `git diff --check` PASS. Full analyzer / fast / boundary / exact CI / human APK / final SCIP remain delivery steps after this commit. No Drive logs were read because this is feature work. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Analyzer-clean Year 2x6 / Sum curve candidate

- Application commit `19c1d69a` is a narrow analyzer correction for the `f8edad8` presentation delivery: it removes an unnecessary interpolation brace, unused golden-test import, and ineffective test null assertion. It changes no MonthCard, chart, Query, frame, filter, slider, geometry, or financial behavior.
- **Root cause/evidence:** exact Actions run `35521899354` for `f8edad8` stopped `test-flutter` at Flutter analysis before its curated suite. Local Ubuntu/proot analysis reproduced exactly three static findings in the new presentation files/tests; it did not report a functional implementation failure.
- **Local validation PASS:** `flutter analyze --no-pub` reports `No issues found!` (116.6s). The focused Ubuntu/proot Mind presentation suite reports **91 tests passed**, including settings, detailed-Sum model, Year viewport, 2×6 golden, Sum viewport, and tuner coverage. The existing detailed-Sum gesture test emits a non-fatal offstage-drag warning but completes green; it is unrelated to this lint-only correction.
- Online exact-SHA CI, human APK, final SCIP, and user Android validation are still pending for `19c1d69a`. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Year 2x6 and Sum curve final delivery evidence

- Final application source is `19c1d69af9e9554da6ec99959e3ca406cae92150` (`fix(mind): clear Year presentation analyzer findings`), following feature application commit `f8edad833d2ab4211e2c6a7b262a43dbf3827a71` and required journal children `9f3ddf6fef727e956783aa6db5ed6806a8366550` and `d22532f939175b9eda7a6a39a8f5e78c69d3a168`. The `19c1d69a` change is analyzer-only; it does not alter product behavior.
- **Delivered presentation behavior:** the local Year selector exposes `4×3`, `3×4`, and `2×6`; the new 2×6 path preserves per-month cards, Scope and Zárás authority, and the existing sole vertical scroll owner. `MindHeatmapDayNumberOverlay` provides the 2×6 cards with the Month-view-compatible top-left day label without changing heatmap palette or taps. Generic MonthCard border and profitability tint settings apply only to the 3×4 and 2×6 card renderers; `netForMonth` remains the sole profit/loss authority and opacity blends only the card background. The direct 4×3 grid remains isolated. `MindSumYearBandHeader` provides identical annual label/compact-total placement for detailed and overlay Sum bands. Curve interpolation, weighted smoothing and zoom-adaptive smoothing are independently presentation-owned and paint-only; inspected values remain raw financial anchors.
- **Local validation PASS:** Ubuntu/proot focused Mind settings/detail-model/Year viewport/2×6 golden/Sum viewport/tuner suite (**91 tests**); `flutter analyze --no-pub` (`No issues found!`, 116.6s); changed-Dart format check; `git diff --check`; `./scripts/test-fluvi-fast.sh` (**431 tests**); and `./scripts/verify-fluvi-boundaries.sh`. The permanent `test/goldens/mind_year_heatmap_2x6.png` was generated and visually inspected at 430×560.
- **Exact Actions `35522988828` for `19c1d69a`:** `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS; nightly/baseline lanes are skipped. The workflow is **FAIL overall**, never globally green, because `run-dashboard-profile` fails at the inherited profile-evidence assertion `Mind Year heatmap profile evidence frame_timing_headroom is invalid: null`; the consequent `B_year_month_rail_populated must be a report map` follows the first failure. This profile evidence boundary is not represented as a new Year 2×6, MonthCard, or Sum-curve failure.
- **Human APK PASS:** release `fluvi-human-diagnostic-19c1d69` targets exact application source `19c1d69af9e9554da6ec99959e3ca406cae92150`. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_19c1d69.apk` exists, is `84,481,541` bytes, SHA-256 `70b74f82c6d0e62e0416424fc7780358ed06f8756f8032453122b8d51f18740e`, passes archive-integrity verification, and contains the full exact `FLUVI_BUILD_COMMIT` in `libapp.so`.
- **Exact-source SCIP PASS:** tooling commit `17d457f9` on `tooling/scip-codegraph-v1` contains only `docs/codegraph` artifacts for the exact source. Manifest pins `source_head=19c1d69af9e9554da6ec99959e3ca406cae92150`, `source_parent=9f3ddf6fef727e956783aa6db5ed6806a8366550`, `scip_dart=1.6.2`, and raw index SHA-256 `61e56e56e318be91388e74bf4041b81b6e51beafbc0b5511361e460fd371c47c`; it records 487 documents, 338,449 occurrences and 11,463 repository-defined symbols. Two provenance-checked generations had the identical graph-tree SHA-256 `bd250bd82f31f571cf320cf29ca51cca1ebefa7b3a7a6cf5b1ab280f13a8de3e`; tooling `dart test` PASS (**15 tests**).
- No Drive log was read because this was explicit feature work. Untracked diagnostics were preserved. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Exact 19c1d69 physical recurrence: zoomed 2027 line collapses to a short segment

- New Android feedback with screenshot and refreshed connected `Fluvi mind heatmap` diagnostics. The fresh log now carries an exact build marker: `USER_MARK ... commit=19c1d69af9e9554da6ec99959e3ca406cae92150 build mode=profile build purpose=HUMAN_DIAGNOSTIC`. Therefore this physical recurrence is tied to the exact current application source `19c1d69af9e9554da6ec99959e3ca406cae92150` (`fix(mind): clear Year presentation analyzer findings`). Branch HEAD before this journal-only feedback record is docs-only `0eb5d3e8a033e723b8c85b561fd45f8c6a78b445`.
- **Frozen refreshed Mind log:** Google Doc `Fluvi mind heatmap`, id `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified `2026-09-20T17:20:26.596Z`, revision `ANLCKQnm1eaAv2hfxhg87jGQGxRldOPzWi6Mbx9RUORfyOC13Qw8SQGjlDU3HPlGJuMoH4n6JZ_-vKVdBehBGQ`. Complete text export is 463,973 bytes (999 line breaks). The retained tail reaches `USER_MARK` seq 28742 with exact build identity above.
- **Physical screenshot:** in Sum detailed mode with only the 2027 yearly band visible, the zoomed chart shows a short interior curve segment instead of a line visually continuing across the crop. The user explicitly reports this as the recurrence of the prior “only a small part of the linechart is visible during zoom” defect.
- **Fresh per-band proof at PAN_END:** seq 28736/28737/28738 share `viewportStart=0.45303 viewportSpan=0.05567` (~21-day window). 2025 has `sourcePoints=23 visibleSourcePoints=21 anchors=21 paintAnchors=23 leftNeighbours=1 rightNeighbours=1 leftPaintContinuation=true rightPaintContinuation=true`. 2026 has `18/16/16/18` with both neighbours and both continuations. **2027 has only `sourcePoints=6 visibleSourcePoints=6 anchors=6 paintAnchors=6 leftNeighbours=0 rightNeighbours=0 leftPaintContinuation=false rightPaintContinuation=false`.** Thus the screenshot's short 2027 segment is correlated with missing paint-context neighbours, not with the current LOD dropping visible 2027 anchors: all six fetched/visible points remain selected.
- **Source-proven boundary at 19c1d69:** `_detailSourceForWindow` fetches only the visible window plus exactly one LOD bucket of padding on either side. `MindDetailedSumLod.select` can retain a nearest-before/nearest-after paint neighbour only from the points it was given. Therefore if a sparse year's nearest real source observation lies farther away than one bucket beyond the crop, the current renderer reports no continuation even though later/earlier real points may exist elsewhere in the same year. The 2027 PAN_END snapshot proves this bounded-source failure condition was reached physically.
- This does **not** justify fabricating boundary values or connecting across arbitrary missing-data semantics without a product/test contract. The next coding prompt must first prove with a controlled sparse-year RED fixture that the full current-frame 2027 source has a real nearest observation beyond the one-bucket fetch, then extend **paint-only context** to that nearest real neighbour while keeping inspection restricted to visible real anchors. The financial path may be clipped at the viewport boundary; no fake interpolated transaction/day value may become selectable.
- **PROVEN:** exact physical build 19c1d69; deep zoom is active (`viewportSpan=.05567`); current 2027 visible anchors are not being discarded by LOD in the captured PAN_END; 2027 lacks both fetched paint neighbours while 2025/2026 have them; source fetch is limited to one bucket padding.
- **UNPROVEN:** whether every occurrence of the user's visual symptom is caused only by this sparse-neighbour boundary; whether the desired product should always connect across long intervals with no eligible daily observations; exact maximum temporal gap across which a truthful visual continuation should be drawn.
- **MISSING EVIDENCE:** controlled sparse-2027 RED proving a real full-year neighbour exists outside one-bucket padding; explicit product/test contract for maximum/any-gap paint continuation; post-repair BAND_SNAPSHOT showing real neighbour retrieval without changing inspectable anchors; candidate APK and user Android revalidation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, tooling graph, milestone or feature implementation changed. Physical validation of a future repair remains `PENDING — USER ONLY`.

## 2026-09-20 — First-entry Mind cold-start lag from Budget/Balance

- New physical feedback only; no coding-agent prompt requested yet. On the first app-session transition from Budget or Balance into Mind, the Mind heatmap/charts do not appear immediately; there is a short visible lag before data is shown. After that first successful Mind entry, later mode switches into Mind are immediate.
- Current application source under discussion remains `19c1d69af9e9554da6ec99959e3ca406cae92150`; the current branch HEAD before this journal-only feedback record is `0c67e711923ab359838e794c6a47734031510b2b`, a journal-only child.
- **Source-proven cold-path shape:** `DashboardCoreController.mindTemporalHeatmap` starts as `ValueNotifier<MindTemporalHeatmapFrame?>(null)`, and the cached `_mindSumHeatmapProjection`, `_mindMonthHeatmapProjection`, and `_mindDayHeatmapProjection` start null. On SUM admission, `_installMindSumHeatmapProjection` first publishes/looks up the prepared Mind amount domain and compatible base; if the cached projection identity matches it can immediately publish `existing.preview(...)`, otherwise it builds a new `MindSumHeatmapProjection` from prepared membership contributions and only then publishes the preview. Therefore a real first-entry cold path and a later warm reuse path both exist in source.
- This source structure is **consistent with** the user's “first entry lags, later entries are immediate” observation, but it is not yet sufficient to claim the exact first-lag root cause. The missing timing boundary is whether the delay is dominated by prepared-base admission, projection construction, preview construction, widget/layout/paint warmup, or another first-use resource.
- Required next diagnostic evidence when the user requests the prompt: instrument one exact first Budget/Balance→Mind transition from accepted mode input through Mind prepared-base availability, projection build/reuse, frame publication, first Mind body layout, and first painted heatmap/chart frame; compare it against the second warm transition in the same session. The target product invariant is immediate first-entry visible data without changing Query/data semantics or performing repository/index work on the accepted foreground transition.
- **PROVEN:** first-vs-later cold/warm code paths exist; cached projection reuse is source-visible; the user physically observes first-entry-only lag.
- **UNPROVEN:** exact duration; exact first blocking phase; whether SUM, Year, Month and Day share the same first-use cost; whether prewarming all Mind products is necessary or only the current target.
- **MISSING EVIDENCE:** exact-build USER_MARK for this specific startup reproduction, cold-vs-warm stage timestamps, first-paint acknowledgement for the Mind card, and a production-parent RED latency contract.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, graph, milestone or settings implementation changed. Physical validation of a future repair remains `PENDING — USER ONLY`.

## 2026-09-20 — Sum detailed X-axis label expansion while zoomed

- New presentation feedback only; no coding-agent prompt requested yet.
- In the Mind / Sum detailed line chart, when the user zooms in far enough that there is sufficient horizontal space, the X-axis should stop using only single-letter Hungarian month initials and instead render the full Hungarian month names.
- The axis should therefore be adaptive to the current visible temporal span / available label density: overview may keep compact initials, while zoomed-in states should prefer full names whenever they fit without collision or clipping.
- This is an axis-label presentation change only. It must not alter zoom semantics, viewport state, LOD selection, financial data, tap inspection, or monthly separator positions.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, graph, milestone or settings implementation changed.

## 2026-09-20 — Month comparison rhythm card with Budget-style bars

- New presentation feature feedback only; no coding-agent prompt requested yet.
- In Mind / Month, duplicate the existing daily spending-rhythm card as a separate comparison card rather than replacing the current one.
- The new comparison card should use the same filled-bar visual language shown in the supplied Budget-mode screenshot: narrow rounded vertical bars rising from the baseline.
- Product differences from the Budget screenshot are explicit:
  - if a day has no value, render no bar for that day at all;
  - do not render an empty outline/track or the unused remainder of a partially filled bar;
  - only the actually filled value segment is visible.
- Bar color must be reactive and derived from the existing Mind heatmap dynamic palette/intensity semantics, including current slider/range context; do not introduce a fixed Budget cyan authority for this Month card.
- Preserve the existing daily-axis/month semantics. This is a comparison visualization, not a replacement of the current Month rhythm card.
- The information/stat cards below the chart should be enlarged relative to their current implementation so their labels/values are easier to read; improve legibility without changing the underlying financial/statistical semantics.
- Screenshot source of truth for the requested bar silhouette is the supplied Budget-mode image from this feedback turn. The screenshot's empty outlined columns are specifically NOT part of the new Month comparison card.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, graph, milestone or settings implementation changed.

## 2026-09-20 — Sparse Sum detailed paint-continuity repair

- Application commit `1adf67036e7926f58af404ba50a23dfbbc392c87` repairs the source-proven sparse-year boundary observed in the exact `19c1d69a` physical build. `MindSumHeatmapFrame` now supplies at most the nearest real, current-range-approved point on either side of the actual viewport as **paint-only** context, in addition to the bounded LOD source. The detailed renderer continues to route inspection through `MindDetailedSumLod.inspectablePoints`, so no off-screen point can become selectable and no financial value is invented.
- **Proven boundary:** the previous fetch supplied only one LOD bucket of padding. The frozen 2027 PAN_END record had six visible/selectable anchors but no external paint neighbour, while other years did. A new controlled `SUM-DETAIL-EDGE-01` fixture proves a sparse March window retains its real January/November neighbours in `paintPoints` while keeping only March inspectable.
- The repair does not change Query, range slider, repository, prepared-base, heatmap, or financial aggregate ownership. It uses only the immutable current-frame daily/raw prepared data already admitted for Sum.
- **Local validation PASS:** Ubuntu/proot projection test; detailed-Sum model test; Mind temporal viewport suite (including existing non-fatal offstage drag warning); changed-file formatter; targeted Dart analysis; `git diff --check`. Full `flutter analyze --no-pub` was attempted twice but exceeded this command runner's 30-second observation boundary, so it is not recorded as passed.
- Remaining risk: the physical screenshot proves the previous missing-neighbour state, but Android validation of this candidate is still required. The product policy for visually joining exceptionally long real-data gaps remains a presentation decision. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Mind comparison rhythm and readable temporal detail

- Application commit `f41284df1a747ff6c33e366d8cace2b8a7804b24` adds the requested additive Mind/Month comparison rhythm page. It preserves the original daily-rhythm card and its full-versus-filtered bars. The new page paints only non-zero current-scope bar segments using the existing dynamic Mind heatmap palette resolver: it deliberately has no outlined empty track, gray remainder, or zero-value bar. It reads the same resident daily range-preview points and does not change Query or the amount slider.
- The shared Month/Day stat-card primitive is enlarged once, so both screens retain equal, more legible information-card geometry. Chart body heights were reclaimed to keep the 360×300 widget contract free of overflow.
- Day timeline events now carry the already-admitted prepared contribution's partner label through the immutable Mind transport. Selected marker labels and the strongest-item stat prefer `partner · amount`; time stays on the timeline axis and remains the fallback only when no partner label exists. No painter reads Ledger data.
- Detailed Sum month-axis presentation now has a pure density resolver: full Hungarian month names appear only at a sufficiently narrow viewport with at least 44px real label spacing; overview and constrained states retain Hungarian initials. The resolver cannot change window, separators, LOD, smoothing, or financial values.
- **RED/GREEN:** the Month third-page test first failed because the pager contained only two pages, then proves the original card remains, the new chart mounts, a non-zero bar has an affordance and a zero day has none. Domain coverage proves partner-label retention. The detail-model test first failed for the missing adaptive-density resolver. Focused local suites PASS (52 tests; existing non-fatal offstage detailed-chart drag warning), formatter, targeted Dart analysis, and diff check PASS. Full `flutter analyze --no-pub` remains not recorded as PASS because this command runner cuts observation at 30 seconds. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Bounded cold-versus-warm Mind-entry timing instrumentation

- Application commit `997db06a` adds diagnostics only for the physically reported first Budget/Balance-to-Mind cold-entry delay. A Core-owned `mind-entry:<id>` flow now records `REQUEST_ACCEPTED`, `PREPARED_BASE_READY`, `PROJECTION_BUILT_OR_REUSED`, and `FRAME_PUBLISHED`; the actual production Mind host reports the correlated first post-frame layout acknowledgement and next-frame paint-survival acknowledgement. The renderer reports only immutable frame identity/revision and does not own a second data, mode, or diagnostic state machine.
- **RED/GREEN:** `MIND-COLD-01` was RED before instrumentation because no `MIND_ENTRY|REQUEST_ACCEPTED` lifecycle existed. It is now GREEN through the production `CoreDashboard`/`DashboardCoreModeHost`/Mind surface for one cold and one same-session warm entry, proving ordered stages and distinct flow correlation. Targeted changed-file Dart analysis is clean.
- This commit deliberately does **not** claim a cold-lag root cause or add a prewarm. It is the bounded measurement necessary to distinguish prepared-base admission, projection construction/reuse, publication, and the first rendered body. The trace needs exact candidate-build Android cold/warm capture before a repair is chosen. No Query, prepared contribution, financial frame, slider, visualization, or Budget/Balance semantics changed. The broader directly affected widget suite was still completing when this application commit was made; its final result is recorded only after it finishes. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Cold-entry instrumentation regression completion

- The directly affected production-host regression command completed after the `997db06a` application commit: `flutter test --no-pub test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/presentation/dashboard_core_mode_host_test.dart test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart --reporter expanded` reports **177 tests passed** in Ubuntu/proot. The existing detailed-Sum offstage-drag warning remains non-fatal and unrelated.
- This confirms only that the new trace is non-regressive in the local production host. It does not convert the still-unmeasured physical first-entry lag into a proven source root cause. Physical validation: `PENDING — USER ONLY`.

## 2026-09-20 — Fresh Mind cold-entry evidence gap + Day timeline simplification + Balance carousel phase request

- New physical Android feedback with a Day-mode screenshot and a freshly refreshed connected `Fluvi mind heatmap` document. The user reports that on app initialization the first **Balance → Mind** transition still delays both the dynamic Mind Header content and the Mind card/body; later entries are warm. The refreshed Mind log is too sparse to locate the delay.
- **Frozen fresh Drive evidence:** Google Doc `Fluvi mind heatmap`, id `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, modified `2026-09-20T20:21:26.734Z` (22:21:26 local), revision `ANLCKQnGvQPHhs6I_D-xRP3o8x2tkCFWCIUyetTL0atxOuLR-WWnSLiISeWuU1s9o7mDOBO9xnBM_UeU8IIm4A`. Complete text export is **410 bytes**, SHA-256 `f2a8e253293807c212c2ccf1167179afb30c8d1a73087e7dcca4253723ac9c69`. It contains exactly two retained filtered events: seq 99 `MIND_HEATMAP|DIRECTION_DOMAIN_PREWARM_REQUEST` at 22:20:44.65 with `reason=activeAlreadyReady boundedSlots=2 canonicalDomain=absent`, and seq 105 `...PREWARM_READY` at 22:20:44.69 with `accepted=true ... durationMs=47`. Because this is a filtered Mind document, the numeric jump 99→105 is not by itself a retention gap. There is no LIVE_TAIL, session id, build/commit identity, USER_MARK, or `MIND_ENTRY|*` lifecycle record.
- **Evidence consequence:** the exact APK/source used for this newest physical cold-entry observation is **MISSING EVIDENCE**. Current branch state contains application commit `997db06a5a625f8aca2370d7f5ab656be7e03348` (`chore(mind): instrument cold entry timing`) and docs-only child HEAD `2354c29a5e1de45a6d57aac56367776db24efba3`, but the new physical session cannot be attributed to 997db06a from the current log. The fresh two-line log proves only that one Expense-direction prewarm found an already-ready bounded direction domain and completed in 47 ms while `canonicalDomain=absent`; it does not prove the Balance→Mind mode-input, Header-ready, card-frame-ready or paint timing.
- **Current instrumentation gap:** 997db06a adds Core `MIND_ENTRY|REQUEST_ACCEPTED → PREPARED_BASE_READY → PROJECTION_BUILT_OR_REUSED → FRAME_PUBLISHED` plus Mind-body `FIRST_LAYOUT/FIRST_PAINT`, but it does not measure the dynamic Mind Header's first correct score/content publication and paint. Its production-host test also explicitly invokes `primeMindAmountPreviewDomain()` after mode switch to make the cold domain available, whereas production CoreDashboard starts the trace on mode change and the ordinary UI path currently triggers `primeMindAmountPreviewDomain()` from the amount-range binding/read path once canonical values are available. Therefore the test proves trace ordering, not real first-entry latency or that production prewarm starts early enough.
- **Source-proven cold/warm topology remains:** `mindTemporalHeatmap` and Sum/Month/Day projections start empty and later reuse existing projections by identity. On Sum admission, no compatible prepared base means the temporal frame is cleared/unavailable until admission succeeds. This is a candidate cold boundary, not yet the proven physical root cause. The next repair cycle must correlate mode input, canonical range readiness, prepared base, projection reuse/build, Header score/content publication+paint, Mind card frame publication+layout+paint and final mode-visible acknowledgement in one exact build/session before moving work earlier.
- **Required final diagnostics after repair:** keep a bounded, copyable on-screen Mind diagnostic flow that is actually included in the `Mind heatmap` dropdown/export and carries build SHA/session correlation. It must expose cold vs warm stage timing for mode request, canonical range/domain state, prepared-base readiness, projection build/reuse, Header frame ready/layout/paint, Mind card frame ready/layout/paint, total request→both-painted latency, and whether any repository/index work occurred. One compact terminal summary per entry is required; do not create unbounded per-frame spam.
- **Day physical screenshot / source-proven label collision:** current `MindDayTransactionTimelineCard` already uses partner+amount from commit `f41284df1a747ff6c33e366d8cace2b8a7804b24`, but its painter lays the selected label at fixed `y - 18` after `layout(maxWidth: 45)`. A multi-line partner+amount label can therefore extend downward into the marker dot/stem, matching the screenshot. Final placement must use measured text height and a positive gap above the marker tip/stem, with bounded horizontal/vertical repositioning.
- **Day product simplification:** remove the obsolete hourly 24-cell heatmap page entirely. Day becomes timeline-first/only. Add a presentation setting with two timeline layouts: (1) current enlarged stat/info cards + timeline; (2) timeline-only, with no stat cards and the day's total shown at the card's top-right. In timeline-only mode the chart must expand vertically to consume the freed stat-card area rather than leaving dead space. Any stale Day pager/page-dot affordance must be removed. This is presentation-only; the underlying Day frame may retain hourly aggregates if used elsewhere, but the removed UI must have no active page/gesture owner.
- **Balance feature phase — new branch only after the Mind/Day repair is complete:** after the repair is committed, validated and journaled on the current Fluvi branch, create a NEW Balance feature branch in the Fluvi worktree (suggested `feature/balance-carousel-v1`) from that validated state. Do not mix Balance implementation into the repair commit history.
- **Current Balance source topology:** `BalanceDashboardCoreSurface` is still a placeholder with exactly the requested structural slots already present: a smaller upper `subheaderOne` cascade card, a larger lower `zone2` cascade card, dots, and the Balance Header. `DashboardCoreModeHeaderScaffold` already supports a bounded `detail` layer. The first Balance feature should keep the lower large card as a placeholder and populate only the Header plus upper card.
- **Balance Header requirement:** show the Balance amount `sumIncome - sumExpense` from the existing prepared/current-scope financial authorities; the renderer must not read repository/ledger rows or create a second total authority. Exact scope binding must follow the current active Dashboard temporal/filter scope rather than inventing a new independent scope.
- **Balance upper carousel requirement:** 5 cyclic presentation cards total, only 3 visible at once; selected center card larger, immediate left/right cards smaller. Four cards are empty placeholders; one card shows the latest transaction and should be initially centered so the prototype is visible. The carousel must use the existing shared centered-carousel engine, not copied physics.
- **Budget-avatar mechanism/source evidence:** current Budget rail owns one stable `CenteredCarouselController` and consumes `CenteredCarouselPresets.budgetCategoryAvatarRail`. That preset's geometry is Budget-specific but its motion uses the shared `CenteredCarouselMotionProfiles.timeRefinementRail`: frictionDrag .135, velocityMultiplier .66, min/max fling 140/5200, maxItemsPerFling 5, forceOneItemOnFling=true, spring mass 1/stiffness 420/damping ratio 1, tolerance .01. The Balance carousel must consume this SAME motion profile object/authority while defining only Balance card geometry (3 visible, center/neighbor scale, item extent, clip/layering). Do not modify or fork the shared physics constants. New-pointer interruption of an active ballistic fling, drag/ballistic/settle ownership and stable controller/ScrollPosition behavior must be inherited from the shared engine.
- **Layer/bounds contract for Balance:** because the selected center card is larger than neighbours, its visual, paint, hit-test and semantics bounds must be represented by a real enclosing input/layout surface; do not use a paint-only transform that leaves the selected card outside its interactive parent. Center card must paint above neighbours; side cards below; upper structural card and carousel clips must not cut selected content. Add explicit geometry/hit/semantics tests. Preserve the physically accepted Avatar/Time interaction milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- **SCIP provenance:** the latest available graph manifest is **STALE FOR CURRENT APPLICATION SOURCE**. It indexes `19c1d69af9e9554da6ec99959e3ca406cae92150` at tooling graph commit `17d457f9` (scip_dart 1.6.2, raw index SHA-256 `61e56e56e318be91388e74bf4041b81b6e51beafbc0b5511361e460fd371c47c`, 487 documents / 338,449 occurrences / 11,463 repository-defined symbols), while current application commit is 997db06a. It was used only as historical navigation to locate Balance/Budget/CenteredCarousel neighborhoods, then all cited behavior was source-verified at current 997db06a. A final exact-source graph is required after delivery.
- **PROVEN:** first-vs-warm Mind projection paths exist; latest refreshed Mind log is insufficient and build-unidentified; current retained prewarm is 47 ms and says `activeAlreadyReady`; 997db06a instrumentation lacks dynamic Header paint timing and its test manually primes the Mind domain; Day label geometry can overlap its stem; Day currently has a two-page PageView with obsolete hourly heatmap + timeline; Balance is a two-card placeholder; shared Budget carousel physics authority and current Balance structural bounds are source-visible.
- **UNPROVEN:** exact physical cold-entry APK; exact first blocking cold-entry stage; whether moving prewarm earlier alone resolves Header and card lag; exact latest-transaction prepared source to use in Balance until current source audit on the new branch; final Balance card dimensions/scales.
- **MISSING EVIDENCE:** exact-build cold/warm physical trace with Header and card paint; on-screen retained `MIND_ENTRY` flow; deterministic production cold-entry RED latency test without manual post-switch prime; Day label non-overlap bounds test; Day layout-option tests; new-branch Balance prepared-total/latest-transaction owner audit; Balance three-visible-card geometry and Budget-physics identity no-regression tests; final CI/APK/final-source SCIP; user Android acceptance.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit. No application source, tests, graph, milestone or feature implementation changed. Physical validation of future candidates remains `PENDING — USER ONLY`.

## 2026-09-21 — Proven Core admission repair, full Mind-entry diagnostics, and Day timeline simplification

- Application commit `8146d5f3ae13c32e58481cb4c4e139a2f29759d6` repairs a source-proven circular cold-entry admission gate and performs the requested Day presentation-only simplification. The frozen `Fluvi mind heatmap` evidence remains the 410-byte export (document `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, SHA-256 `f2a8e253293807c212c2ccf1167179afb30c8d1a73087e7dcca4253723ac9c69`); its seq 99/105 `activeAlreadyReady`/47-ms direction prewarm does not itself prove an Android visual-delay stage.
- **Proven first failing boundary:** on committed Mind mode entry, `CoreDashboard` previously started the existing `primeMindAmountPreviewDomain()` only from the amount-range renderer once an exact canonical amount domain already existed. That Core admission is itself the path that publishes the initially missing domain. The deterministic Balance→Mind production-parent `MIND-COLD-02` was RED before repair with only `MIND_ENTRY|REQUEST_ACCEPTED`; it is green after Core starts that existing admission from the committed mode boundary. This is not a timer, blanket warmup, renderer data read, or altered Query semantics.
- **Retained diagnostics:** Core-owned `MIND_ENTRY` now records request/canonical-domain/prepared-base/projection/body-frame/Header-frame/Header+body layout and paint/current acknowledgement, then one bounded `SUMMARY`. Every event carries logger session, compile-time build value, entry/flow, epoch, Core revision, direction/query/scope digests, cold/warm classification and elapsed time. Summary records prepared-base request, repository-admission, prepared-index-admission and projection build/reuse counters. Header and body report only current immutable-frame acknowledgements and Core rejects a stale identity. The on-screen `Mind Heatmap` console filter/export now includes `MIND_ENTRY|*`; there is no per-frame stream.
- **Day:** the obsolete Day `PageView`, `PageController`, 4×6/hour-cell UI and page ownership are removed. The existing `MindYearHeatmapPresentationSettings` authority now owns `statsAndTimeline` (default) versus `timelineOnly`; its tuner is wired to the same controller. Timeline-only hides all stat cards, displays the existing current-frame Day total top-right and gives the plot the released vertical extent. The painter uses measured label height, explicitly reserves annotation headroom, bounds x within the plot and retains more than the positive gap above each marker/stem. Underlying hourly model data remains untouched.
- **Focused local evidence:** Ubuntu/proot MIND-COLD-01 and MIND-COLD-02, DAY-HOST-01, Day topology/layout/geometry tests, Mind settings (11), Header tuner (15), and Mind console filter all PASS; formatter and `git diff --check` PASS. Broad impacted suite/analyzer/CI/APK/final SCIP follow the Balance phase. The stale graph (`17d457f9`, source `19c1d69`) was navigation-only; all changed owners were rechecked from source. Protected physical floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` remains untouched.
- Exact physical APK/source identity for the reported recurrence and device timing remain missing evidence. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Balance prepared net Header and shared five-card carousel

- Application commit `50168f15e8895caf8db08cdc92dd9ebb9c91e668` delivers the requested Balance phase on `feature/balance-carousel-v1`, based on the separately committed/journaled Mind admission and Day repair (`8146d5f3` / `560b058e`). `DashboardCoreController` owns one immutable `DashboardBalancePresentation`: it takes the visible direction's prepared frame and obtains the other direction's frame through the same materialized structural time scope. Its net is exactly `income.totalMinor - expense.totalMinor`; it formats with the existing prepared formatter. Neither the Balance surface nor the Header receives a repository, raw ledger collection, or data-acquisition callback.
- The Core chooses at most one latest transaction from the two already-prepared, bounded LogBox semantic previews, using existing entry time and a deterministic id tie-break. It does not materialize rich log rows. The new Balance Header uses the existing Header detail seam, so Header visual/material ownership remains unchanged. The large lower `zone2` Balance surface remains the existing placeholder.
- The small upper `subheaderOne` surface now owns a stable, feature-local `CenteredCarouselController` and consumes `CenteredCarousel` with exactly `CenteredCarouselMotionProfiles.timeRefinementRail`. It contains five finite cyclic logical cards: the prepared latest transaction at logical index zero, initially centred, plus four intentional empty prototypes. Only three slots are visible. Geometry is responsive to the existing structural bounds; the centre is larger while all selected-card layout/hit/semantics surfaces stay inside the real item canvas. Visual canvases deliberately do not overlap, eliminating a contested paint-order surface; outer clip is `Clip.none` and exactly one selected semantic item is exposed. The local press feedback mirrors the accepted Budget shell (`.8`, 115 ms, `easeOutQuad`) without changing shared or Budget physics.
- **RED/GREEN:** a Core production fixture first exposed that a Mind-only seed could not establish Balance totals; the corrected prepared-frame fixture proves income `120000`, expense `35000`, net `85000`, prepared latest selection and absence of renderer repository-page reads. The Balance widget contract proves five cyclic cards, initial centre, exact profile object identity, three visible slots, centre/side geometry, one selected semantic label, cyclic wrapping, controller/ScrollPosition preservation through presentation updates, ballistic motion and raw-pointer interruption. The shared/Budget source is unchanged.
- **Local validation PASS:** Ubuntu/proot Core Balance focused test; full `core_dashboard_test.dart` (**35 tests**); full `dashboard_core_ephemeral_focus_test.dart` (**101 tests**); shared centered-carousel + Budget Avatar + Balance suite (**45 tests**); Mind Day/settings/mode-host suite (**55 tests**); changed-file `dart format --set-exit-if-changed`; targeted `flutter analyze --no-pub` (`No issues found!`); and `git diff --check`. An initial regression command referenced an absent historical Budget test path; the rerun used `test/features/dashboard/presentation/budget_category_avatar_rail_test.dart` and passed. The existing Mind detailed-chart offstage-drag warning remains non-fatal and unrelated.
- **Evidence/provenance:** frozen Mind document `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, 410 bytes, SHA-256 `f2a8e253293807c212c2ccf1167179afb30c8d1a73087e7dcca4253723ac9c69`, still proves only its retained `activeAlreadyReady`/47-ms prewarm (seq 99/105). The application owners were verified from current source; the available SCIP graph `17d457f9` at source `19c1d69` remains stale/navigation-only. Protected physical milestone `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` is unchanged. Final remote CI, exact normal human APK and exact-source SCIP are delivery steps after this journal commit. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Final remote analyzer correction

- The one intentionally dispatched final workflow attempt, Actions `35573490889` for journal-head `db38ede71f7b744706bf47576c3a15ec720eae02` (application parent `50168f15`), had a clean `test-core` result but stopped in `test-flutter` before curated tests or the human APK. Its full `flutter analyze --no-fatal-infos` output identified exactly two static findings: unused `year_month.dart` import in `mind_temporal_heatmap_viewports.dart` and unnecessary `flutter/foundation.dart` import in `mind_temporal_secondary_cards.dart`. Both files are Mind Phase-A presentation files; this is a delivery lint omission, not evidence against the cold-entry, Day, or Balance contracts.
- Application commit `97445be09f96c465c5e18b7c9862e764fc2a40ce` removes only those two imports. No runtime behavior, visual layout, prepared authority, Query, controller, shared carousel/Budget motion, or test semantics change. Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` is PASS (`No issues found!`, 93.4s); formatter and `git diff --check` are PASS. A new final workflow/APK is required because the failed attempt never produced an APK. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Final APK and exact-source graph delivery

- Actions `35575616897` was explicitly dispatched after `97445be0`, at journal-head `e1f71f0773782a4e3a44f7c0fb3ce88a8d048604`. `test-flutter` (full analyzer plus curated suite), `test-core` (boundary, Room Core, native bridge), and `build-human-diagnostic-apk` are PASS. The normal human diagnostic APK release `fluvi-human-diagnostic-e1f71f0` targets that exact embedded build SHA. `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_e1f71f0.apk` exists, is 84,612,613 bytes, has SHA-256 `ec49404901d2bb2f256914e93a662089ae936652c6a9438d9476355ec439b52c`, matches the release digest, passes archive integrity, and contains the exact embedded SHA. The final application-source commit is `97445be09f96c465c5e18b7c9862e764fc2a40ce`; the release commit is its documentation-only child.
- The one workflow failure is `run-dashboard-profile`, not the human APK or correctness gates. It fails in the pre-existing Mind Year report validator with `frame_timing_headroom is invalid: null`; the subsequent missing `B_year_month_rail_populated` map is consequent. This is the same known profile-evidence boundary recorded before this delivery. No Balance/Mind/Day feature failure, no shared carousel physics regression, and no physical acceptance is inferred from it.
- Tooling commit `12452c7b1e17b44802c8dd85b69a41f8acb632bb` is pushed on `tooling/scip-codegraph-v1`. Its manifest pins `source_head=97445be09f96c465c5e18b7c9862e764fc2a40ce`, parent `db38ede71f7b744706bf47576c3a15ec720eae02`, `scip_dart=1.6.2`, raw index SHA-256 `7eb4da24cf9d1df3dfcb9688c7154b7acbc1952002c86b9c784bbe3e77c1d440`, 490 documents, 341,864 occurrences and 11,593 repository-defined symbols. Two exact generations yielded the same graph-tree digest `f910123f5551967a958168468615e089b47d7d104af220eb6912c1cb6835a902`; tooling tests PASS (15). Queries confirm the new Balance presentation is Core/host/surface-owned and the existing controller still has Budget, Summary, Time and profile consumers. **Physical validation: PENDING — USER ONLY.**


## 2026-09-21 — Physical failure of Mind cold-entry repair + Balance Header/upper-carousel follow-up

- New user physical Android feedback after the delivered Balance/Mind candidate: the first post-startup Balance→Mind entry still visibly delays both the Mind Header and Mind card; the Balance carousel motion works; the Balance net amount is not visibly present in the dark Header; and the old wide white upper placeholder surface is still visible behind the three carousel cards. The user requests the selected/center Balance carousel card to grow until its height equals the former upper placeholder/subheader height. The lower large Balance card remains outside this complaint.
- **Exact physical log/build correlation is now available.** Refreshed Google Doc `Fluvi mind heatmap` (id `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, revision `ANLCKQm80TKbUlV9pZSyJ4Ekc6s2ea-cEuROjzDtxzfhGp4lSg3hbrftxT3lY8RJZrt2Xug1kManrzwf0NN33g`, modified `2026-09-21T08:28:47.937Z`) was frozen as a 13,191-byte text export, SHA-256 `2f8d62b089c3e4a0d8b66ca1e8d59354e80286a417cec50a6b89793fd4468597`. It contains 28 unique retained filtered sequence records, no duplicate seq and no USER_MARK. One session is present: `fluvi-1789979287304736`; every MIND_ENTRY record identifies build `e1f71f0773782a4e3a44f7c0fb3ce88a8d048604`, the delivered human-diagnostic build whose journaled application source is `97445be09f96c465c5e18b7c9862e764fc2a40ce`.
- **Fresh physical cold/warm timing proof:** cold `mind-entry:1` reports `cold=true`, `preparedBase=absent`; PREPARED_BASE_READY only at **939,833 µs**, body/Header frame publication at ~944 ms, first layout at ~964 ms, and both paints at **986,635 µs** total. Same-session warm `mind-entry:2` has `preparedBase=resident`, PREPARED_BASE_READY at **526 µs**, frame publication at ~1.1 ms, and both paints at **20,489 µs**. Cold summary: `preparedBaseRequests=2 repositoryRequests=0 preparedIndexBuilds=0 projectionBuilds=1 projectionReuses=1`; warm summary: one prepared-base request, zero repository/index work, projection reused.
- **Previous repair loop status:** `997db06a` successfully added useful lifecycle instrumentation but did not itself repair the cold path. `8146d5f3` then moved `primeMindAmountPreviewDomain()` to the committed Mind mode-entry boundary and declared the earlier renderer-domain circular gate structurally repaired; current physical evidence proves that this did **not** remove the startup-visible delay. Do not repeat that repair or infer success from stage ordering alone.
- **Current source-proven blocking boundary at application `97445be...`:** `CoreDashboard._onCoreModeChanged()` starts `primeMindAmountPreviewDomain()`. That Future calls `_primeMindAmountPreviewBaseFor(... preparesLiveRows:true)`. When the matching current prepared index is already installed, Core synchronously registers the Mind base, but still awaits `_primeMindAmountLiveRowResources()`; that prepares the broad source-membership live LogBox row-resource window through `DashboardLogBoxPreparedSceneCache`. Only after this await returns does `primeMindAmountPreviewDomain()` publish the structural amount domain and call `ensureMindTemporalVisualProjection()`, so Header/body publication is causally gated behind live LogBox row-resource readiness. Because the cold trace records zero repository requests and zero prepared-index builds, the ~940 ms gap is not the repository/index-builder branch. The filtered Mind document does not retain the inner `MIND|LIVE_ROOT_*` / `RESOURCE|*` timings, so the precise inner row-layout/TextPainter work distribution remains MISSING EVIDENCE and must be instrumented before micro-optimizing it.
- **Duplicate admission request is also source/graph-proven but not yet causal for the ~940 ms:** the exact-source SCIP graph (`source_head=97445be...`) has two production references to `primeMindAmountPreviewDomain()` in `core_dashboard.dart`: committed mode-entry and the Mind range render/read path. The cold summary consequently records `preparedBaseRequests=2`. The shared scene cache joins an identical active `prepareWindow` request to the same Future, so a literal doubled preparation cost is NOT proven. The next repair must restore one Core-owned admission authority / read-only renderer and separately prove request/join behavior.
- **Required cold-path repair direction:** separate semantic Mind base/domain + score/heatmap readiness from the slower live LogBox row-resource readiness. Header/body must be able to publish from the already installed immutable prepared index/base without awaiting TextPainter/Phase-A row-resource preparation that is only needed for readable live LogBox interaction. Keep the row-resource preparation bounded and stale-safe in the background or behind the interaction-specific gate; do not permit slider/LogBox publication without its required exact readable resources. Add correlated `BASE_INSTALLED/SEMANTIC_READY` vs `LIVE_ROOT_REQUEST/READY` timings to the existing MIND_ENTRY flow and prove a delayed resource preparer can no longer delay Header/body first paint.
- **Balance Header source-proven visibility defect:** `_BalanceHeaderAmount` renders `formattedNetTotal` using `FluviVisualTokens.textPrimary = 0xFF172554`; Balance's Header `upcomingHeaderTone` is also exactly `0xFF172554`. The amount widget can therefore exist and still be visually invisible on the supplied dark-navy Header. The existing Balance widget test only asserts that the text/key exists and does not assert visible contrast, creating a false green. Use the established on-dark Header text authority/contrast contract rather than another ad-hoc color.
- **Balance upper placeholder source cause:** the upper `DashboardCoreModeCascadeCard` passes carousel content but leaves `showPlaceholderSurface` at its default `true`; the primitive therefore deliberately stacks `DashboardPlaceholderCard` behind the carousel. This exactly explains the wide white card in the screenshot. Remove the placeholder surface only for the upper Balance carousel host; do not remove the lower large `zone2` placeholder.
- **Balance carousel size source cause:** `_BalanceUpperCarousel` receives the full upper-card height, but its card builder hard-caps `itemHeight` at `min(52, carouselHeight)`. The center has `maxScale=1` and neighbours use `.78`; therefore the center card can never reach the structural upper-card height. The requested contract is: center visual height equals the expanded `subheaderOne` structural height, neighbours remain smaller through the existing carousel scale, and the full selected visual remains inside real layout/hit/semantics bounds. Preserve the already-working shared `CenteredCarouselMotionProfiles.timeRefinementRail` physics/controller/interruption mechanics.
- Existing Balance tests are false-green for the new physical defects: they check Header text presence, carousel count/shared physics/controller identity/width/interruption, but not Header contrast, upper-placeholder absence, or center-card height == upper structural height. Add RED→GREEN coverage for those exact boundaries.
- Protected physical performance floor remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. No Mind repair may regress Avatar/Time controller, ScrollPosition, physics, or direct-manipulation behavior.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, test, workflow, graph, milestone or runtime behavior changed here. Physical validation of the next candidate remains `PENDING — USER ONLY`.

## 2026-09-21 — Mind semantic readiness decoupled from live LogBox resources

- Application commit `b799af3b0bdc0ef683dc198ce6edaa79b2d22bc8` repairs the source-proven cold-entry wait without repeating the failed `8146d5f` “start the same prime earlier” approach. The frozen physical Mind Heatmap export is unchanged: doc `1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, revision `ANLCKQm80TKbUlV9pZSyJ4Ekc6s2ea-cEuROjzDtxzfhGp4lSg3hbrftxT3lY8RJZrt2Xug1kManrzwf0NN33g`, 13,191 bytes, SHA-256 `2f8d62b089c3e4a0d8b66ca1e8d59354e80286a417cec50a6b89793fd4468597`, session `fluvi-1789979287304736`, build `e1f71f0773782a4e3a44f7c0fb3ce88a8d048604`.
- The trace proves cold `mind-entry:1` reached prepared-base readiness at 939,833 µs and both paints at 986,635 µs, versus 526 µs / 20,489 µs warm, with zero repository requests and prepared-index builds. Current-source review showed the installed immutable base was available before that wait, but `primeMindAmountPreviewDomain()` awaited broad `mind-live-root` Phase-A LogBox row/TextPainter resources before structural domain, temporal body and Header publication.
- Core now publishes semantic base/domain/score/heatmap readiness from the exact immutable prepared base before launching the bounded live row-resource lane. Live rows remain fail-closed until their exact resource completes. The Core tracks only one in-flight resource future per exact domain; inactive-direction warmup remains detached Core work, never a render callback.
- The Mind range renderer is now read-only and no longer calls `primeMindAmountPreviewDomain()`. A Summary Month/Year renderer acknowledgement is still an acknowledgement only, but the Core no longer requires an already-existing Month/Year frame before admitting its accepted target; that removed a circular lifecycle dependency uncovered by `LEVEL-MONTH-06`.
- Diagnostics retain compact correlated `BASE_SOURCE_RESOLVED`, `SEMANTIC_BASE_INSTALLED`, `STRUCTURAL_DOMAIN_PUBLISHED`, `LIVE_ROOT_RESOURCE_REQUESTED/JOINED/REUSED/READY`, projection, Header/body layout/paint and terminal summary stages through the existing Mind Heatmap export filter. No transaction text is logged and no per-row/per-frame stream was added.
- **RED/GREEN:** new `MIND-COLD-03` was RED before the change with only `REQUEST_ACCEPTED`, `CANONICAL_DOMAIN_STATE`, `PREPARED_BASE_REQUESTED` while a held live-resource future blocked publication. It is green with current Header/body frame and first paint before release, zero repository/index work and one Core prepared-base request; releasing the Future enables the existing readable lane. Existing `RED MIND-LIVE-RESOURCE-01` and `LEVEL-MONTH-06` exposed two lifecycle regressions during the split and are green after restoring detached Core warmup and Core-owned accepted-target admission.
- **Local validation PASS:** Ubuntu/proot changed-file analyzer (`No issues found`); `dashboard_core_ephemeral_focus_test.dart` (**102 tests**); MIND-COLD-01/02/03 focused run (**3 tests**); CoreDashboard/ModeHost/LogBox cache+preview command (**124 tests**); formatter and `git diff --check`. Shared carousel/Budget physics and Query/repository semantics are unchanged; protected physical floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` remains untouched.
- Inner live row/TextPainter cost attribution is still device diagnostics, not a claimed micro-profile. A new exact APK and user Android observation are required. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Balance Header contrast and upper carousel visual repair

- Application commit `c39f625e753d063dc053a1371bff0b9f4bae0c83` repairs the three independently source-proven Balance visual failures from the exact `e1f71f0` physical diagnostic feedback. The inspected Android image `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260921-103615.png` visibly showed the dark Header, wide upper white surface and undersized centre carousel card that motivated this bounded repair.
- `_BalanceHeaderAmount` now consumes `FluviVisualTokens.textOnAction` rather than `textPrimary`. The former source equality was `textPrimary = 0xFF172554` and Balance `upcomingHeaderTone = 0xFF172554`; the prepared `formattedNetTotal`, Core income/expense authority, Header material and animation policy remain unchanged.
- The upper `subheaderOne` `DashboardCoreModeCascadeCard` explicitly sets `showPlaceholderSurface: false`, so carousel cards are its only visual content. The lower `zone2` cascade still has its default placeholder surface and was not modified.
- Balance cards now take actual upper structural height rather than `min(52, carouselHeight)`. The existing selected scale remains 1 and neighbour scale remains .78, so the center reaches `subheaderOneBounds.height` through real layout/hit/semantic bounds while adjacent cards stay smaller. No shared `CenteredCarousel`, controller, ScrollPosition, `timeRefinementRail`, Budget Avatar or Time physics code changed.
- **RED/GREEN:** Header presence-only coverage failed to prove contrast; `BALANCE-HEADER-VISIBILITY` now asserts canonical on-action foreground and inequality from the active Header background for negative and positive formats. `BALANCE-UPPER-VISUALS` asserts no upper placeholder, retained lower placeholder, center height equal to structural height, shorter immediate neighbours and in-viewport center geometry. Before the source repair both contracts failed (dark source color and default placeholder); after it they pass.
- **Local validation PASS:** Ubuntu/proot Balance/shared centered-carousel/Budget Avatar regression command (**92 tests**); `dashboard_core_ephemeral_focus_test.dart` (**102 tests**); CoreDashboard/ModeHost/LogBox command (**124 tests**); changed-file analyzer (`No issues found`); `dart format --set-exit-if-changed`; `git diff --check`. The protected physical floor is unchanged. New online APK/SCIP delivery and user Android validation remain required. **Physical validation: PENDING — USER ONLY.**


## 2026-09-21 — Balance all-time semantics + Mind-parity Header history chart clarification

- New product clarification supersedes the earlier Balance “current-scope” temporal contract: the Balance Header amount must **always** be the all-time/Sum net, `sum(income) - sum(expense)`, and must not change when the Summary Pill moves between Sum/Year/Month/Day or rail children. The latest-transaction carousel card has the same temporal-independence contract: it always shows the newest transaction from the canonical all-time Balance data authority and must not change merely because Summary navigation selects another temporal scope. This clarification is specifically about Summary/time scope; do not silently discard the existing non-temporal Query/filter identity unless current product/source evidence separately requires that.
- **Current-source mismatch is PROVEN at application source `c39f625e753d063dc053a1371bff0b9f4bae0c83`:** `DashboardCoreController._onVisibleFramePublished()` calls `_publishBalancePresentationForVisibleFrame(frame)`. That method deliberately derives income/expense from the exact `frame.scope.timeScope`, hashes `frame.scope.key` into `presentationId`, computes `net = income.totalMinor - expense.totalMinor`, and chooses `latestTransaction` from those same two temporal frames. Therefore both Header net and latest card currently follow Summary/visible temporal selection, directly contradicting the clarified product contract.
- `DashboardBalancePresentation` is currently documented and shaped as a **current-scope** model and carries no historical series. The repair must establish one canonical all-time Balance presentation/projection upstream of the renderer rather than teaching Header/carousel widgets to query or aggregate ledger rows. Summary/visible-frame movement must not replace this Balance identity when the underlying canonical non-temporal query/core revision is unchanged; real query/filter/revision changes must still update it.
- **Balance historical Header chart request:** the expanded Balance Header must contain a line chart with the same visual composition as the existing expanded Mind Header score chart, but its Y values are historical Balance, not behavioral score. Current Mind reference source is `mind_header_score_chart.dart`: plot left/top/width/height `16/48/346/60`, white `textOnAction` 1.6 line, soft white area fade, dashed guide, outlined latest endpoint, progressive clipping by `headerExpansionProgress`, and optional actual-domain time labels/point inspection. The preferred implementation is a shared/generic Header-chart visual kernel or equivalent single visual authority so Balance does not fork constants; any refactor must keep existing Mind chart/golden output pixel/geometry compatible.
- **Historical X-domain contract:** chart physical width is always fixed to the existing Header plot width. Its temporal domain is exactly the admitted historical data extent: if the available history spans two months, those two months consume the whole plot; if it spans two years, those two years consume the same whole plot. No fixed 12-month window, no Summary-selected window, no future padding, and no blank proportional region for history that does not exist. Earliest and latest admitted timestamps/dates map to the left and right plot boundaries. The exact cumulative-series construction and Y-domain policy are not present in current Balance source and remain an implementation-evidence task; do not fabricate score-like 0–100 semantics.
- **Amount position parity:** current Balance Header uses scaffold insets `detailLeft/right=16, detailTop=20, detailBottom=8` plus center alignment. Mind instead supplies the full Header detail surface and positions its score at `left=16, top=16`. The requested Balance net amount must occupy the same visual vertical anchor as the Mind score (top 16 in the reference composition), while remaining a money value and retaining the already-repaired on-dark foreground contrast.
- **Carousel visual clarification:** Balance carousel card surfaces must be white. Current `_BalanceCarouselCard` uses `Theme.of(context).colorScheme.surfaceContainerHighest`, so exact white is not guaranteed. Use the canonical Fluvi white surface token rather than theme-dependent/ad-hoc colour. Keep the already-working 5-card/3-visible shared carousel mechanics, full-height selected-card geometry from `c39f625e`, stable controller/ScrollPosition and exact `timeRefinementRail` physics untouched.
- **Required false-green guards:** current Balance tests prove current-scope net/latest behavior and therefore encode the superseded temporal contract. Replace/add tests with materially different all-time vs Year/Month/Day totals and latest transactions, then move Summary through multiple temporal states and prove Header net, latest card and historical series are byte/value/identity-stable while the visible temporal frame actually changes. Add a positive control that canonical Query/filter/core revision or new ledger revision does refresh Balance. Add parity tests for Balance amount top position versus Mind score, fixed chart geometry/style/reveal, real-history domain stretching for a two-month and a two-year fixture, and exact white carousel surfaces.
- **Current delivery evidence before this clarification:** latest feature HEAD before this journal entry was `bdf7eaae719118b879299b454dd9dbe17f01f4dc`, a documentation-only child of application commit `c39f625e753d063dc053a1371bff0b9f4bae0c83`. Actions run `35598736240` on `bdf7eaae` has PASS `test-flutter`, PASS `test-core`, PASS `build-human-diagnostic-apk`, and FAIL `run-dashboard-profile`; physical user acceptance of `c39f625e` is still pending. Matching SCIP tooling HEAD `d4b64fd5782eaa37c1dc6ffd97051ccb2453d89c` indexes exact source `c39f625e` with `scip_dart=1.6.2`, raw index SHA-256 `05698661f0c2b27d6124cad458cfa539645dc6449b37dc43f4efb3e5c4948c11`, 490 documents / 342,541 occurrences / 11,593 repository-defined symbols, deterministic graph-tree digest `6189bd7555d6ca502b9590f79e2574c75cbacee1627f5a805e6351ce980f6436`.
- Protected physical performance floor remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. No Balance chart/data repair may alter Budget/Time/Avatar carousel physics, add renderer repository reads, or create Summary-tick financial recomputation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, tooling graph or milestone file changed by this feedback record. Physical validation of the next candidate remains `PENDING — USER ONLY`.


## 2026-09-21 — Current post-repair profile gate audit

- Mandatory delivery audit of Actions run `35598736240` (head `bdf7eaae719118b879299b454dd9dbe17f01f4dc`, application source `c39f625e753d063dc053a1371bff0b9f4bae0c83`) confirms `test-flutter` PASS, `test-core` PASS and `build-human-diagnostic-apk` PASS, while `run-dashboard-profile` FAILS in the A–K integration scenario.
- The current profile failure is **not the previously journaled `frame_timing_headroom=null` validator failure**. The primary runtime assertion is in `integration_test/dashboard_interaction_profile_test.dart:1694`: “Mind score must use the same live canonical range as the heatmap before pointer release.” Expected and actual `QueryAmountRangeValues` differ during `_profileMindYearHeatmapSlider.dragThumb`; the later missing `B_year_month_rail_populated` report-map error is consequential to that aborted scenario.
- Causality is **UNPROVEN** without a RED reproduction/bisect: this audit does not assert that `b799af3b` caused the failure. Because the failure sits in the Mind score/range path touched by the recent semantic-readiness repair, the next coding cycle must classify it before declaring the branch a clean baseline. If reproduced as branch-introduced, repair and journal it before final Balance-feature delivery; if proven pre-existing/unrelated, preserve that evidence explicitly. Do not relabel this run as fully green.
- Prompt-writer action: journal-only `[skip ci]` evidence update; no application source, tests, workflow, graph or milestone changed. Physical validation remains `PENDING — USER ONLY`.

## 2026-09-21 — Held Mind score range survives a delayed complete frame

- Application commit `cb99608df8744c81cc9ccdd4bdd882bb41b03dc7` classifies and repairs the primary score/range ordering defect from Actions `35598736240`. The exact baseline failure was at `integration_test/dashboard_interaction_profile_test.dart:1694`: during the Mind Year slider drag, the Header score no longer used the same live range as the heatmap before pointer release. The later missing B-year report map was consequential.
- A new deterministic Core/store regression first failed with the same shape: after an admitted held range `150000..250000`, a delayed complete visible frame reset the Header score lower bound to `100000`. The test routes the delayed frame through `DashboardVisibleFrameStore.publish`, so Core's normal visible-frame listener—not a test-only notifier assignment—owns the reproduction.
- `DashboardCoreController` now resolves a complete-frame score publication against the current matching `mindRange` live provenance (same revision and direction) and the live interaction's already-admitted structural amount domain. It preserves canonical values whenever that live identity is absent, stale or outside the domain. The change does not mutate Query, read a repository, build an index, alter the Mind heatmap/LogBox, or touch Balance/Budget/Time/Avatar carousel ownership or the `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` physical floor.
- **RED/GREEN:** the new test was RED before the repair (`Expected: 150000; Actual: 100000`) and is GREEN after it. Ubuntu/proot focused command: `flutter test test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart --plain-name "Mind amount drag publishes an exact resident preview"` — **1 passed**. `git diff --cached --check` passed before commit. The longer full Core suite was started locally but its command-runner output was not retained as a final PASS record; remote A–K profile verification is still required.
- This establishes the local Core ordering cause, but does not claim physical Android acceptance or attribute every former profile outcome to `b799af3b`. The final exact APK and remote profile gate remain required. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Core-owned all-time Balance presentation and cumulative history

- Application commit `330730d5` corrects the clarified Balance data contract on `feature/balance-carousel-v1`. `DashboardCoreController` now obtains both income and expense from their exact canonical all-time prepared partitions; it no longer derives Balance provenance from `DashboardVisibleFrame.scope.timeScope` or hashes the Summary frame key into the Balance identity. Existing non-temporal prepared query/filter identity remains part of the frame/index provenance.
- The immutable presentation remains Core-owned. Its Header net is `allTimeIncome - allTimeExpense`; its latest card chooses the latest prepared all-time entry across both directions; pure Summary Sum/Year/Month/Day navigation leaves the same presentation/history identity in place and does not notify the Balance notifier. A genuine new Core prepared revision still rotates the all-time totals, latest entry, history identity and presentation identity through the regular post-frame index-publication gate.
- `DashboardBalanceHistoryProjection` builds exact transaction-order samples from the two prepared focus-membership transport banks. Each sample is cumulative admitted income minus cumulative admitted expense, uses actual local timestamp coordinates, preserves real extrema, and has no renderer/repository/LogBox rich-row dependency. Core only accepts a chart history when its final directional cumulative totals agree exactly with the all-time prepared frames; otherwise it truthfully exposes no chart.
- **RED/GREEN:** the Summary-independent Core test was RED while `presentationId` contained the visible Summary key (the all-time identity changed at a Year frame); it is green after that temporal key is removed from the data identity. The post-revision positive control initially exposed the intentional stable-frame publication boundary, then proved revision 2 after the test drives the actual post-frame gate rather than an arbitrary delay.
- **Local validation PASS:** Ubuntu/proot `BALANCE-ALL-TIME` material-difference test (**1 passed**); prepared revision positive control (**1 passed**); real Core Summary navigation test (**1 passed**); history projection suite (**2 passed**); staged `git diff --check`. Larger Core/analyzer completion output was not retained in this command runner and is explicitly still required before final delivery.
- Evidence/provenance: application base `c39f625e753d063dc053a1371bff0b9f4bae0c83`; matching pre-change SCIP tooling `d4b64fd5782eaa37c1dc6ffd97051ccb2453d89c`; protected interaction floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. This unit does not alter Query semantics, repositories, Header visual material, CenteredCarousel physics, Budget/Time/Avatar behavior, or the separate Mind profile repair.
- Remote profile/APK/SCIP regeneration and Android acceptance remain open. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Balance Header historical trend, shared Mind visual kernel and white card surfaces

- Application commit `7ba0a989` consumes the Core-owned immutable all-time Balance model from `330730d5` without adding a renderer data path. `DashboardHeaderTrendChartStyle` is now the one neutral Header trend visual authority: it contains the reference measurements (`detail 16/16`, plot `16/48/346/60`), white on-action 1.6 line, endpoint, guide and fade treatment. `MindHeaderScoreChartPainter` delegates to this kernel; its score adapter keeps the existing 0–100 Y semantics and its existing Mind chart/golden output remains compatible.
- `BalanceHeaderHistoryChart` is a typed money/time adapter. It passes real cumulative balance values and actual earliest/latest epoch-minute domain to the shared painter, so a two-month and a two-year history each occupy the same fixed 346px plot width from left to right; it does not invent a rolling window, future padding, or score values. A one-point series truthfully occupies the plot centre. The existing Header expansion progress remains the only reveal/clip owner; pointer inspection is passive and formats money/date only from immutable supplied points.
- The Balance amount now shares the same centralized `left=16, top=16` anchor as the Mind score and retains `FluviVisualTokens.textOnAction`. Both Mind and Balance consume that anchor from the shared visual authority rather than retaining duplicated local magic numbers.
- All five logical Balance carousel cards now explicitly use `FluviVisualTokens.surface`. The pre-change `Theme.of(context).colorScheme.surfaceContainerHighest` test fixture produced a non-white actual color; `BALANCE-CAROUSEL-SURFACES` was RED against it, then GREEN after restoring the canonical token. The carousel domain (five / three visible), selected full-height geometry, controller/ScrollPosition, press feedback and exact `CenteredCarouselMotionProfiles.timeRefinementRail` authority remain untouched.
- **Local validation PASS:** shared trend domain/parity suite (**2 passed**); focused Balance Header history (**1 passed**); all-five white-surface contract (**1 passed**); Mind chart/golden suite (**12 passed**); single-runtime Balance boundary suite (**2 passed**); formatter and staged `git diff --check`. An aggregate CoreDashboard/host run was started but its final runner output was not retained; final analyzer/shared/remote gates are still mandatory.
- Evidence/provenance: original application base `c39f625e753d063dc053a1371bff0b9f4bae0c83`; pre-change exact SCIP `d4b64fd5782eaa37c1dc6ffd97051ccb2453d89c`; protected physical floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. No Query/repository/financial authority, Header material, Budget/Time/Avatar or shared carousel physics source changed. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Analyzer-clean Balance and Mind profile follow-up

- Application commit `8810492d` removes the three remaining static analyzer notices found after the all-time Balance/Header trend and held Mind-range units: two now-proven unnecessary non-null assertions and one redundant Material-supplied import. It does not alter a runtime branch, visual constant, data authority, cache, query, prepared-index, carousel or gesture owner.
- **Validation PASS:** Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` completed with `No issues found` in 179.4 seconds. The held Mind-range production-path regression passed (**1** test), as did the canonical white-surface Balance carousel test (**1** test). Formatter and staged `git diff --check` passed before the commit.
- This is intentionally a separate mechanical application unit. The pending comprehensive widget, profile, APK and exact-source graph gates remain to be run from the final branch state. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Late Core score-admission range repair

- Application commit `0a32ea0e` closes the remaining local ordering hole behind the failed Actions profile run `35629171408`: the Mind Year RangeSlider's heatmap already had the held live range, while a late ordinary Core score admission could restore the Header score to the canonical range before pointer release. The original profile assertion is `integration_test/dashboard_interaction_profile_test.dart:1694`; the later missing B-year report map was consequential.
- `cb99608d` had correctly protected the delayed complete visible-frame callback, but it did not cover the other Core score publishers. This unit extracts the same validated live-range check for ordinary `ensureMindBehavioralScoreProjection`, renderer-accepted temporal targets, and complete visible frames. It accepts only the active physical Mind score interaction with matching direction/revision and bounds inside its admitted domain. The range immediately returns to canonical once the interaction identity is ended.
- **RED/GREEN:** the expanded production Core/store case first failed after `ensureMindBehavioralScoreProjection()` with the held `150000..250000` range reset to `100000..300000`; it passes after the repair and additionally proves the post-drag canonical positive control. The direct focused test is **1 passed**. The full Ubuntu/proot `dashboard_core_ephemeral_focus_test.dart --reporter compact` completed **105 passed**, exit 0. Targeted analyzer on both changed files reported `No issues found` in 29.3 seconds; formatter made 0 changes and diff checks passed.
- No Query mutation, repository/index request, prepared data owner, heatmap/LogBox data path, Balance authority, Header material, or shared Budget/Time/Avatar carousel physics changed. The protected milestone remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. The older exact SCIP graph indexes `c39f625e`, so current relationships were checked from source; the final graph must index the final application SHA.
- The remote Android profile, final APK and user physical acceptance remain required. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Exact held-range provenance for the Mind profile gate

- Application commit `ba5f3cc3` follows the still-failing real A–K profile run `35635055929` (profile job failed; `test-flutter`, `test-core`, and `build-human-diagnostic-apk` passed). Its primary assertion remains `dashboard_interaction_profile_test.dart:1694`: while the physical Mind Year RangeSlider pointer is down, `mindBehavioralScore.range` must equal `mindYearHeatmap.range` exactly. The consequent missing B-year report is not an independent failure.
- **Proven current boundary:** after an accepted Mind range preview, the Core already retains `_MindAmountRenderTarget.values`, the immutable full `QueryAmountRangeValues` supplied to the heatmap and accepted narrow LogBox lanes. A late score publisher instead re-derived its structural domain from the live temporal candidate. In the profile fixture that derivation can differ from the accepted range's min/max provenance even when thumb positions agree, leaving the Header score and heatmap unequal.
- The repair uses that existing exact render-target value only when the active Mind score interaction, Core revision, direction and live-interaction generation all match. Any absent, stale or incompatible identity retains the existing canonical fail-closed fallback. This does not change Query state, repository/index work, prepared ownership, heatmap/LogBox admission, Balance data/visuals, or protected Budget/Time/Avatar carousel physics (`6e962187e90e2a82431b1f91b224d2b52a6e0ba7`).
- **Validation PASS:** Ubuntu/proot focused regression (**1 passed**), full `dashboard_core_ephemeral_focus_test.dart` (**105 passed**), changed-file analyzer (`No issues found`), formatter normalization and staged diff check. The regression now asserts whole-range equality after the delayed complete-frame boundary, not just lower/upper thumb equality. A new remote A–K profile and final normal human APK remain mandatory before delivery. **Physical validation: PENDING — USER ONLY.**

## 2026-09-21 — Semantic held range precedes optional Mind preview lanes

- Application commit `4e5a61d1981524571350d0336e82ed2f25fbea19` follows Actions `35639027233`: `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS, but `run-dashboard-profile` still failed in 26m59s at the primary held Mind score/heatmap range assertion in `dashboard_interaction_profile_test.dart:1694`. The later missing `B_year_month_rail_populated` report map remains consequential; this is not represented as a green profile gate.
- **Proven remaining ordering boundary:** `_MindAmountRenderTarget` is intentionally created only after the optional exact LogBox preview lanes publish. Those lanes notify synchronously. A Core score admission re-entering from that listener therefore ran while the Year heatmap already held the live `QueryAmountRangeValues`, but before the LogBox render target existed, and used canonical range provenance instead.
- Core now records a bounded `_MindAmountSemanticRangeTarget` only after the immutable Year heatmap accepts that range, and before LogBox-lane publication. It is accepted only while its interaction generation, direction, core revision and currently visible heatmap identity/range all remain exact. It clears at the physical drag end. This is an interaction-liveness guard under the existing Core authority, not a second range/Query/prepared-data owner; the later LogBox render target and fail-closed fallback remain unchanged.
- **RED/GREEN:** the production Core test first failed by adding a real synchronous `logBoxLane` listener that called `ensureMindBehavioralScoreProjection()` before the render target registration; the observed score range differed from the accepted heatmap range. It is green after the semantic target guard. Ubuntu/proot focused command is PASS (**1**); full `dashboard_core_ephemeral_focus_test.dart --reporter compact` is PASS (**105**); changed-file analyzer is PASS (`No issues found`, 31.0s); formatter and `git diff --check` pass.
- No Query mutation, repository/index work, prepared base, heatmap/LogBox readable-resource gate, Balance authority/visual, Header material, Budget/Time/Avatar or shared carousel physics changed. The existing exact SCIP and prior APK index/build `ba5f3cc3` application state, so final SCIP/APK/profile evidence must be regenerated for `4e5a61d1`. **Physical validation: PENDING — USER ONLY.**


## 2026-09-21 — Balance polish + selectable chart modes; explicit no-refactor scope

- New physical/UI feedback is supplied with Android screenshot `1000124813.png` (21:09 device clock). The screenshot visibly shows the current Balance Header/history chart, Summary 2026 selection, three-card Balance carousel and large lower Balance placeholder. The user reports no currently visible Mind or Balance defect and explicitly says the present shared-chart refactor may remain; however **no further refactor is authorized in this task**. Exact APK/source identity for this screenshot is not embedded in the image and is therefore MISSING EVIDENCE; the screenshot is used as visual/product evidence, not as exact-build runtime proof.
- **Balance carousel vertical geometry request:** increase the entire upper carousel area and its cards by exactly **10% relative to the current Balance upper height**. Keep the carousel→lower-card gap unchanged and keep the overall downstream layout/bottom edge unchanged. Therefore, in Balance only, grow the upper area downward by delta=`0.10 * current upper height`, move the lower Balance card top down by that same delta, and reduce the lower card height by exactly delta so its bottom/indicator/downstream geometry remains unchanged. Do not change shared `DashboardLayoutMetrics.subheaderOneHeight` or shared Budget/Mind geometry. Current reference upper height is 72 logical px before viewport scaling, so the reference delta is 7.2 px.
- **Carousel border/shadow request:** every small Balance carousel card must participate in the same live border and shadow settings as the lower Balance card and use the same default border/shadow profile. Current source proves the lower card renders through `DashboardPlaceholderCard`, which consumes `DashboardBorderScope.profileOf(context).borderFor(DashboardBorderSurface.balanceContent)` and `DashboardShadowStyleScope.profileOf(context).depthFor(DashboardCornerSurfaceFamily.contentCard)`; current carousel cards are plain `DecoratedBox` surfaces and therefore bypass both settings. Fix locally in the Balance card surface; do not refactor the global card system.
- **Balance chart presentation settings:** add Balance-owned user settings, separate from Mind settings. X-axis/time labels must be user-selectable hidden/visible exactly like the Mind chart's user-facing option, but the Balance setting must not share mutable state with Mind. Current Balance chart always renders its time-label widget; current Mind has `MindHeaderScoreChartPresentationController` / hidden-visible radio controls in the existing Header tuner.
- **Balance chart data mode selector:** the Header amount remains invariant in every mode: **all-time Sum income minus all-time Sum expense**. Only the linechart data view changes. Add three user-selectable Balance chart modes: (1) **Adaptive / Summary-linked**: chart view follows the current Summary Pill temporal target while preserving true cumulative Balance Y values; (2) **All-time / Sum**: current behavior, independent of Summary; (3) **Month-end closing (experimental)**: Summary-independent historical trend containing only calendar month-end Balance closes so intra-month sawtooth spikes from lump-sum income are suppressed. Do not change Header net or latest-transaction semantics when switching chart mode.
- The current Core all-time Balance authority from `330730d5` is retained. Current source `DashboardBalanceHistoryProjection.build` already creates truthful transaction-order cumulative Balance from resident prepared membership. New chart modes should be projections/views over already-prepared immutable Balance history/current temporal scope, not new repository/index/renderer acquisition paths. The exact adaptive/month-close projection implementation must remain Balance-local and bounded.
- **Point inspection:** tapping a Balance chart point must display that point's X date and Y Balance amount, analogous to Mind's reactive inspection. Current `BalanceHeaderHistoryChart` already contains selected-point/crosshair/amount/date code, but `DashboardCoreModeHost` forwards the top Header pointer relay only to the Mind observer; therefore a real Balance Header tap path through the production top gesture layer is not currently proven. Wire a Balance-local passive pointer observer through the existing Header pointer layer without modifying Mind behavior or gesture ownership.
- **Settings button placement:** move the single Header/settings menu button out of the physical Header and into the app's upper-right gray brand area above the Header, aligned within the existing dashboard shell/brand region. Keep its function and tuner overlay unchanged. Once the button is outside the Header, remove the obsolete Header-label spacing reservation; do not redesign the Header or settings overlay.
- **Balance carousel customization:** add Balance-owned tuner sliders for (a) side-card/center-card visual spacing, with the current spacing as the default, and (b) card width boost from **0% = current width** to **+30% = current width × 1.30**. These settings are Balance-only presentation inputs. Preserve exactly three visible logical slots, stable `CenteredCarouselController`/`ScrollPosition`, cyclic semantics, and exact `CenteredCarouselMotionProfiles.timeRefinementRail` physics. Do not modify the shared centered-carousel engine or motion profile. Any larger width/spacing must retain truthful layout/hit/semantics bounds and must not silently make off-cell painted regions non-interactive.
- **Explicit scope/efficiency constraint from the user:** these are mostly small presentation changes plus two bounded Balance features (chart mode selection and carousel customization). The previous task consumed >5 hours and many commits; the user considers that unnecessary token/work expansion. This task must not trigger opportunistic architecture work, shared-kernel extraction, Mind redesign, unrelated profile repair, speculative instrumentation, or a series of micro-commits. The existing Mind/Balance implementation stays in place. Use the smallest Balance-local changes and existing setting/tuner patterns. Run focused tests and one final analyzer before committing so lint cleanup does not become a separate application commit.
- Current branch audit at feedback time: remote feature HEAD before this journal entry is `11b559a0e87301d023f6b0b910b4a83fb132a826` (journal-only), current application source is `4e5a61d1981524571350d0336e82ed2f25fbea19`. Actions `35643802690` has PASS `test-flutter`, PASS `test-core`, PASS human diagnostic APK build, while `run-dashboard-profile` is still in progress. This task must **not** enter another Mind profile-repair loop; report the final profile result as baseline evidence, but only touch it if a new failure is directly caused by this task's changed Balance/settings/layout files.
- SCIP: latest tooling commit `42c05070ea428d55766ebc0e5efe4fe24eb06d5b` indexes `ba5f3cc3c0634c428cf00da494c4b16f73b650d1`, not current app `4e5a61d1`; therefore it is **STALE FOR CURRENT APPLICATION HEAD**. The intervening `4e5a61d1` source commit is Mind-only and current Balance relationships were re-verified from `4e5a61d1` source, but the graph remains navigation evidence only until final regeneration.
- Protected physical interaction floor remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. No change may retune shared carousel physics, Budget Avatar, Time/Summary interaction, repository/index ownership, or trade correctness for motion.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source/test/workflow/tooling/milestone change. Final physical acceptance remains **PENDING — USER ONLY**.

## 2026-09-21 — Bounded Balance presentation controls and layout polish

- Application commit `849fdef38218adf985f8f8584dc0365baf25e0cf` implements the requested Balance-only presentation pass on top of application source `4e5a61d1981524571350d0336e82ed2f25fbea19`. The user-supplied screenshot remains visual/product evidence only; its APK/source identity is still unavailable from the image itself.
- `BalancePresentationController` is live-dashboard-only, non-persistent presentation state. Defaults preserve the accepted display: all-time history, visible static time labels, zero card-width boost and neutral spacing. It adds three Balance chart views: immutable all-time history; Summary-adaptive filtering that retains cumulative money values; and experimental truthful completed-calendar-month closes. The Header net and latest transaction remain Core-owned all-time values in every view. No Query, repository, index, renderer data path or Balance financial authority changed.
- Balance-local geometry transfers exactly `0.10 * upperHeight` from the lower placeholder to the upper carousel: the upper becomes 10% taller, the lower top advances by the same delta, the lower height loses that delta, its bottom and the downstream indicator stay fixed, and the upper-to-lower gap is retained. The shared 72px metric and global geometry resolver remain unchanged.
- Carousel cards now consume `DashboardBorderScope.balanceContent` and `DashboardShadowStyleScope.contentCard`, with the canonical white `FluviVisualTokens.surface` fallback. The local controls allow width `0.00..0.30` (30% is exactly 1.30 times the neutral card width) and a geometry-tested safe local spacing range `0.00..0.12`; controller, ScrollPosition, five-card cyclic domain, three-slot layout, press feedback and the exact shared `timeRefinementRail` profile remain unchanged.
- Balance static axis labels can be hidden or restored independently of Mind. Existing Balance inspection is now relayed through the real passive top Header pointer layer in Balance mode; Mind relay behavior is unchanged and Budget receives none. The existing tuner button moved from inside the Header to the right-aligned gray brand lane above it, and the obsolete 62px Header-label reservation was released.
- **RED/GREEN:** tests first failed because the Balance settings/projection types and surface contracts did not exist. Green focused settings/surface/host/tuner run: **40 tests**; shared centered-carousel and Budget regression run: **90 tests**; untouched Mind Header chart/boundary/golden run: **13 tests**; CoreDashboard plus ephemeral-focus run: **140 tests**; repository fast dashboard suite: **432 tests**. The final Core run additionally protects the local 10% geometry transfer in both expanded and collapsed presentation states.
- **Validation PASS:** Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` reported `No issues found` in 265.1s; changed-Dart formatter reported 13 files formatted with 0 changes; `git diff --check` and staged diff check passed. An initial fast-suite invocation used an invalid `/home/flutteruser/flutter/bin/bash` path and exited 127; it was an invocation error, immediately retried with the correct shell and passed as recorded above.
- Actions baseline `35643802690` remains independently classified: test-flutter, test-core and human APK build passed, while its profile lane failed at the existing Mind live canonical-range assertion followed by the consequential B-year report-map error. This Balance-only diff does not touch that code path and makes no Mind profile repair claim. Final push/CI/APK/SCIP evidence and Android acceptance remain required. **Physical validation: PENDING — USER ONLY.**


## 2026-09-22 — Balance primary card design brief (SUM / YEAR / MONTH only)

- The user supplied the product brief for the **first large Balance card**. This is a new primary Balance visualization feature, not a bug repair. DAY is explicitly **OUT OF SCOPE** and must not be designed or implemented from this brief.
- Current branch state at intake: feature HEAD `e765afae4ace085b052527fc0267113ea4af67a2` is journal-only; current application source is `849fdef38218adf985f8f8584dc0365baf25e0cf` (`feat(balance): add bounded presentation controls`). Exact-source SCIP is now AVAILABLE and current: tooling commit `475f1a1a6a64711fb6114ef313de4d8788e78266`, `manifest.source_head=849fdef38218adf985f8f8584dc0365baf25e0cf`, `scip_dart=1.6.2`, raw index SHA-256 `fd0a1a99a384f031e7f89ae0a3d7562e9854804061f2e53c67ee564b9a233337`, 497 documents, 347,454 occurrences, 11,775 repository-defined symbols.
- Current source fact: the large lower Balance card is still a **real placeholder**. `BalanceDashboardCoreSurface` mounts `DashboardCoreModeCascadeCard(bounds: local.lowerBounds, ... semanticKey: dashboard-core-mode-balance-card-2)` with no content. Therefore the requested primary chart does not currently exist and can be implemented without replacing an existing Balance primary visualization.
- Current prepared-data topology is suitable for a renderer-free data source: `PreparedDashboardIndex` already owns the hierarchy AllTime→Year, Year→Month, Month→Day via `DashboardSemanticCatalog`, and `DashboardPreparedFrame.totalMinor` exposes immutable prepared totals per exact scope. This is source evidence that SUM/year bars and YEAR/month bars can be projected from already-prepared income/expense frames without Room/repository reads. MONTH cumulative cashflow can likewise be derived upstream from prepared month/day totals or existing immutable Balance history; the exact projection choice remains an implementation detail to prove before coding. Do not add a renderer-side data query.
- **Shared card header requirement:** the large Balance card keeps one fixed physical footprint/hierarchy across supported dimensions. Top title is the represented period: SUM=`Többéves balance`; YEAR=selected year (e.g. `2026`); MONTH=selected year+month (e.g. `2026. július`). Also show compact secondary metrics for the represented current period: `Bevétel`, `Kiadás`, `Egyenleg`; balance = income − expense. These card-header metrics are local to the selected primary-card period and are distinct from the all-time Balance amount in the main Header.
- **Stable series identity:** Income and Expense keep stable Balance-mode colors across all primary-card dimensions. Income = cool Fluvi purple/violet/blue family; Expense = warm pink/coral/orange family. Do not use red/green as the primary series identity. Optional positive/negative net status may use green/red secondarily.
- **SUM primary chart:** grouped dual vertical columns by complete year. Exactly two adjacent bars per represented year: LEFT=income, RIGHT=expense, both from zero baseline, one shared Y scale for all visible years. Small intra-pair gap, larger inter-year gap. No diverging positive/negative bars and no permanent per-bar numeric labels. Sparse year sets remain sparse; do not invent categories. Many years preserve a minimum readable pair width and become horizontally scrollable rather than compressing bars. Tap selects the entire year pair and shows a floating infocard with year, income, expense, net, and optionally previous-year delta. Selected pair may strengthen while others quiet.
- **YEAR primary chart:** same exact grouped-pair grammar as SUM, but one pair per calendar month. X-axis month labels (compact Hungarian abbreviations acceptable), all 12 months fit comfortably at normal phone width. LEFT=monthly income, RIGHT=monthly expense, common zero baseline and shared Y scale. Tap selects the month pair and shows month/year, income, expense and net; optional comparison/ratio may remain secondary.
- **MONTH primary chart:** the grouped-bar grammar intentionally STOPS. Do not render 28–31 daily income/expense pairs. Use two cumulative **step lines** over days of month: Income cumulative received through each day and Expense cumulative spent through each day. Step geometry is mandatory; no smooth interpolation. Both series use the same stable Income/Expense colors as SUM/YEAR. Optional translucent fills must remain very subtle. The primary interpretation is the vertical distance between the two cumulative series; do not add a third dominant Net line. Tap/scrub selects a day, shows a vertical guide and floating infocard with date, `Bevétel eddig`, `Kiadás eddig`, `Egyenleg`; optional selected/major transaction annotation only, never permanent labels for every transaction. Final-day endpoints must equal the card-header totals for the selected month.
- **Visual continuity:** SUM/YEAR = completed-period comparison; MONTH = within-period cashflow development. Consistency comes from the same card shell, typography, Income/Expense colors, summary metrics and infocard language, not from forcing one chart type across dimensions.
- **Primary-card visual style:** large white rounded Fluvi card, soft low-contrast shadow, generous padding, dark navy primary text, muted blue-gray secondary labels, restrained grid/reference lines, no heavy axes, no 3D, no dense finance-dashboard microtypography, no noisy gradients. Use the available large-card height confidently; visualization is the main object rather than a tiny chart in empty space.
- **Data states:** zero income or zero expense are valid; fully empty scope retains card shell and clean zero/empty state; partial current periods show only actual data and must not invent forecasts.
- **Interaction semantics:** SUM/YEAR selection belongs to the period pair, not one isolated bar. MONTH selection belongs to a day/cumulative state. Infocard interaction should be local to the large Balance card and must not alter Summary navigation unless a separate product decision later explicitly requests drill-down.
- **Current validation baseline:** Actions run `35655272548` for journal head `e765afae...` / application `849fdef...` has PASS `test-flutter`, PASS `test-core`, PASS human diagnostic APK build, and FAIL `run-dashboard-profile` at the already-known Mind Year RangeSlider assertion `dashboard_interaction_profile_test.dart:1694` (“Mind score must use the same live canonical range as the heatmap before pointer release”), with the later missing B-year report map consequential. This is inherited Mind-profile evidence and is not a primary-card requirement.
- Existing user constraint remains active: **no opportunistic refactor**. The shared Header trend kernel, Mind charts, shared carousel engine/physics, global dashboard geometry, Query/repository architecture and protected physical floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` are not redesign targets for this primary-card feature.
- Prompt-writer action for this intake: journal-only, build-trigger-free `[skip ci]`; no application source/test/workflow/tooling/milestone change. No coding-agent prompt is issued until the user explicitly requests one. Physical validation of future implementation remains **PENDING — USER ONLY**.

## 2026-09-22 — Balance primary chart lean implementation / Mind projection reuse

- User clarification: this is a straightforward new Balance visualization feature, **not a forensic repair**. Keep the coding-agent scope lean and implementation-focused; do not turn the chart work into an hours-long evidence/instrumentation project.
- Mind reference branch audited: `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` HEAD `2993868bd37a318cf4ba718a07b4533e3548cbb9` is journal-only; its application source is `997db06a5a625f8aca2370d7f5ab656be7e03348`. The key Mind domain projection blobs are already present unchanged on `feature/balance-carousel-v1`: `mind_temporal_heatmap_projection.dart` = `46a33b3b...` and `mind_year_heatmap_projection.dart` = `5f1ca85c...`.
- Source-proven reuse path: Mind already has Sum/Year/Month/Day immutable temporal projections over resident prepared membership. Current Core reuses an existing Sum/Month/Day projection when identity matches, and preview tests explicitly protect zero repository reads / zero prepared-index builds on the live projection path. Core retains at most one prepared Mind base per ledger direction (bounded by `LedgerDirection.values.length`), and the temporal projection itself is a read model over already-admitted prepared contributions.
- Balance design decision: do **not** build a new data/query/cache architecture and do not couple the Balance renderer to Mind UI state. Add a thin Balance-specific dual-direction projection/read model over the same current prepared temporal data concepts: Income + Expense for the selected Summary target. SUM/YEAR use paired bars; MONTH uses period-local cumulative step lines; DAY remains out of scope.
- **Primary performance requirement:** Balance chart publication must be immediate and visually continuous when Summary mode/year/month changes, matching the current Mind interaction quality. A prepared target change must not wait for repository I/O, index building, scene/TextPainter preparation, or an async post-settle recomputation. Prefer identity-keyed resident projections and synchronous publication from already-prepared data. Validate with focused next-frame tests rather than long profiling/forensics.
- Prompt scope should require only focused architecture/source confirmation, projection correctness, one-frame/no-source-work switching tests, relevant Balance + Mind regression tests, analyze/format, one application commit and the mandatory separate `[skip ci]` journal commit. Do not require a broad new Drive-log campaign, exhaustive historical re-audit, or bespoke instrumentation unless the focused tests expose an actual performance failure.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]` commit; no application source, test, graph, workflow or milestone file changed.

## 2026-09-22 — Balance primary temporal comparison card

- Application commit `7c5cf334145b819e946ba3aadb066a7177ea7f40` (parent journal head `120becbc9dea061fcdea74831a337da0a1894737`, application base `849fdef38218adf985f8f8584dc0365baf25e0cf`) populates the existing `dashboard-core-mode-balance-card-2`; it does not add a second large card or alter the upper carousel/Header authority.
- New `DashboardBalancePrimaryProjection` is a small immutable, identity-keyed Core read model from resident prepared directional membership. It produces SUM real-year Income/Expense pairs, YEAR's twelve calendar-month pairs, and MONTH's calendar-day, **period-local** Income/Expense cumulative points. Empty directional membership remains a truthful zero side. DAY publishes no primary chart. The renderer owns only local pair/day selection and never reads Room/repository, builds a Query, or reconstructs finance data during paint.
- Core keeps the primary presentation active only in Balance mode and uses a bounded 24-entry LRU keyed by exact prepared identity plus temporal scope. `SUM → YEAR → MONTH → SUM` publishes synchronously from resident data; the focused production-Core test proves the returned SUM presentation is the same immutable instance, with zero repository calls and zero prepared-index generation change. Active ephemeral focus uses the retained exact focus membership rather than falling back to an unfiltered base.
- The lower cascade envelope/bottom/gap/dots and the Balance-local 10% upper/lower geometry are retained. SUM/YEAR use local pair selection and shared baseline paired bars; MONTH uses local O(1) nearest-day scrubbing and horizontal-then-vertical step geometry. In deeply collapsed zone2 constraints the primary card deliberately exposes no clipped chart or false hit surface; normal lower-card constraints retain the complete chart.
- **RED/GREEN:** the projection/card/Core types and contracts were absent before implementation. New P2 tests cover annual/monthly exact values, zero-sided data, MONTH rebase to zero/final metric equality, DAY out-of-scope, next-frame resident reuse/no source work, focus preservation, lower-card geometry, local pair/day selection and compact-surface bounds. Existing `CoreDashboard` text selection was corrected to target the stable `fluvi-expense-button` key after the intentional primary metric introduced a second `Kiadás` label.
- **Validation PASS (Ubuntu/proot):** `flutter test test/features/dashboard/presentation/core_dashboard_test.dart` (**35 tests**); `flutter test test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart` (**107 tests**); `scripts/test-fluvi-fast.sh` (**432 tests**); `flutter analyze --no-pub --no-fatal-infos` (`No issues found`, 164.0s); changed-Dart formatter (11 files, 0 changes); and `git diff --check`. A broad concurrent test-file invocation had one transient Mind-only next-frame failure; its isolated full owner suite is green, so it is not used as Balance proof.
- Preflight graph evidence was tooling commit `475f1a1a6a64711fb6114ef313de4d8788e78266`, `source_head=849fdef38218adf985f8f8584dc0365baf25e0cf`, scip-dart 1.6.2 and raw SHA `fd0a1a99a384f031e7f89ae0a3d7562e9854804061f2e53c67ee564b9a233337`. It is stale after this application commit; final delivery must regenerate the graph using `7c5cf334...`, not this later journal commit.
- The protected physical interaction floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` remains untouched: no Mind, Budget, Summary physics, shared carousel/controller/ScrollPosition/profile, global geometry, Query or repository owner change. Baseline Mind profile failure remains separately classified until final Actions evidence is available. **Physical validation: PENDING — USER ONLY.**

## 2026-09-22 — Balance primary card delivery evidence

- Delivery application source is `7c5cf334145b819e946ba3aadb066a7177ea7f40`; its application journal commit is `d02806fea16fb6f044d8572e6ee9be4426411c6c`. Checklist delivery completion is documentation-only `2578d58c66eabe6cc1ac4273ae0dfd854d41a6a6`; it does not change the application source.
- GitHub Actions `35701267409` on the feature branch: `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` are PASS. The released normal human APK is `fluvi-human-diagnostic-d02806f` / `fluvi_HUMAN_DIAGNOSTIC_d02806f.apk`, 85,005,829 bytes, SHA-256 `da74b376e2b7869cf22824e4c2b85882467b2b62f5f6f1ff302a934edea5c2bd`, downloaded to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_d02806f.apk`. Its embedded `FLUVI_BUILD_COMMIT` is `d02806fe...`; that commit is journal-only and its direct application parent is the delivered `7c5cf334...` source.
- `run-dashboard-profile` FAIL is **inherited, not repaired here**: it repeats the exact pre-feature failure at `integration_test/dashboard_interaction_profile_test.dart:1694`, “Mind score must use the same live canonical range as the heatmap before pointer release,” followed by consequential `B_year_month_rail_populated must be a report map`. Baseline run `35655272548` has the same message, line and consequential report-map failure. No Balance primary-card, carousel, Header, Core/test correctness or APK build failure was introduced.
- Final exact-source SCIP tooling commit `3f04e9d5e222648ad476fddc6f14fa54a23d079e` is pushed on `tooling/scip-codegraph-v1`. `manifest.source_head=7c5cf334145b819e946ba3aadb066a7177ea7f40`, parent `120becbc9dea061fcdea74831a337da0a1894737`, source ref detached exact SHA, scip-dart 1.6.2, raw index SHA-256 `7c643831c0503955757bb1629b3410406c4477d2ce9b49f669e3125577b8f536`, 501 documents, 350,417 occurrences, and 11,892 repository-defined symbols. Tooling tests PASS (15); two generations have the same graph-tree digest `3ba654b3c86dbc04147a1ee36d4cc4f58494f281dd29f26c2d1879256a27c91e`.
- A documentation-only workflow run triggered by the checklist update was cancelled, as required; it is not delivery evidence. **Physical validation: PENDING — USER ONLY.**

## 2026-09-23 — Linked Balance carousel detail delivery

- Application commit `2bd7c356502a3e7e8cd55bb5431d72118ac99508` changes only the scoped Balance-detail path. The existing five-slot, three-visible shared `CenteredCarousel` remains the motion, controller and `ScrollPosition` owner; the Balance surface holds only the local selected topic.
- `DashboardCoreController` now publishes a bounded, immutable `DashboardBalanceLinkedPresentation` from resident prepared income/expense membership. It is keyed by prepared identity, Summary scope and active direction; Core retains the 24-entry LRU. Cashflow remains the existing SUM/YEAR/MONTH projection and DAY has no chart. Latest rows are newest-first across both directions and bounded to five; category ranking is active-direction absolute amount and partner ranking is active-direction transaction count.
- The lower renderer reads only that DTO: Cashflow, latest list, Top 5 category, Top 5 partner and the fifth prototype each use the existing lower envelope. The category/partner detail follows the inspected Android references `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260923-001029.png` and `Screenshot_20260923-001026.png` with a featured first rank, entry-derived color/icon, ranked remainder and right-aligned metric.
- Review found and the final regression now covers linked-payload continuity: a new Summary scope/direction payload refreshes previews while preserving the exact Carousel controller, `ScrollPosition` and selected logical index. The DTO itself also bounds all row lists to five so that invariant cannot be bypassed by a future caller.
- **Local validation PASS:** Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` (`No issues found`, 131.3 s); final seven-file Balance/Core suite (**181 tests**); protected Carousel/Mind/Budget guard suite (**122 tests**); changed-file formatter and `git diff --check`. L1–L9 are `DONE` in the acceptance checklist. This unit does not modify Mind, Budget, Summary physics, the shared carousel engine, Header Compound chart, Query/repositories or global geometry. **Physical validation: PENDING — USER ONLY.**


## 2026-09-23 — Compound Balance Header chart mode clarification

- User correction: **Compound mode is a fourth selectable mode of the existing Balance Header linechart only. It is NOT a carousel topic and NOT part of the large lower Balance content card.** Existing Header modes remain: `adaptiveSummary`, `allTime`, and `monthEndClosingExperimental`; Compound is added beside them.
- Compound is deliberately **Summary-dimension-dependent** and switches projection source/aggregation by the current Summary scope while the Header's large numeric balance remains unchanged under the existing all-time authority.
- **SUM / AllTime Summary scope:** Compound shows a continuous sequence of **calendar month-end Balance closing values across all available years**. Example semantic sequence: 2024 Jan close, 2024 Feb close, … 2025 Jan close, … through the latest truthful completed/available month. It does not draw transaction-level sawteeth in SUM.
- **YEAR Summary scope:** Compound shows the **month-end Balance closing values for the selected year only** (up to 12 monthly closing points, subject to truthful available data). It does not draw transaction-level sawteeth in YEAR.
- **MONTH Summary scope:** Compound switches to the **raw Balance evolution inside the selected month**, preserving the transaction-level sawtooth: a large upward jump when salary/large income arrives, followed by the declining staircase/curve as expenses accumulate. The intent is to show one enlarged monthly sawtooth rather than suppress it.
- Product rationale: YEAR and SUM should expose the underlying long-term trend without repeated salary spikes obscuring it; MONTH should preserve those spikes because, at that scale, the monthly cashflow shape itself is meaningful.
- Compound therefore differs from the current three Header modes: it is neither always raw all-time, nor always current-Summary raw, nor always month-end-only at every dimension. It **mixes closing-value trend projections for SUM/YEAR with raw in-period Balance for MONTH**.
- Static X-axis labels and point inspection remain governed by the existing Balance Header settings/interaction contract. The selected Header point must continue to display its truthful date and Balance amount from the active Compound projection.
- Current source at intake: feature HEAD `aa9e6e2a653108a31b1e8aa4408d977c8081fd90` is journal-only; current application source is `2bd7c356502a3e7e8cd55bb5431d72118ac99508`. Current `BalanceHeaderChartMode` source still has exactly three values: `adaptiveSummary`, `allTime`, `monthEndClosingExperimental`; `DashboardBalanceHistoryViewProjection.project` switches only those three, so Compound is not yet implemented.
- Current linked-carousel delivery `2bd7c356...` explicitly leaves the Header Compound path untouched; therefore this request is a small Header-only extension and must not reopen the lower linked-card implementation, Mind chart, shared Header trend kernel, carousel engine/physics, Query/repository architecture or global geometry.
- Graph status: tooling manifest currently indexes `7c5cf334145b819e946ba3aadb066a7177ea7f40`, so it is **STALE FOR CURRENT APPLICATION SOURCE `2bd7c356...`**. Current Header mode/projection relationships were source-verified directly; stale graph may be navigation evidence only until final regeneration.
- Protected physical milestone remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`. No Compound implementation may alter shared motion or unrelated interaction owners.
- Prompt-writer action: journal-only, build-trigger-free `[skip ci]`; no application source/test/workflow/tooling/milestone change. Physical validation of a future Compound candidate remains **PENDING — USER ONLY**.

## 2026-09-23 — Compound Header and Category Movers delivery

- Application commit `76ee16256bdde96d8ea9ae16077e5db1e105170c` adds the requested fourth, Header-only `Compound` chart mode and the first Balance carousel topic, Category Movers. Compound keeps the Core-owned all-time Header amount unchanged: SUM uses calendar month-end closes, YEAR filters those absolute closes to the chosen year, and MONTH/DAY retain the real adaptive transaction series.
- Category Movers is a small immutable Core projection over already-resident, selected-direction prepared membership. It compares the correct logical calendar windows from `logicalAsOfDate`, ranks absolute integer money delta deterministically, carries finite New/zero semantics and supplies the same DTO to the upper hero and lower local overview/detail renderer. The six real Zone2 indicators mirror the shared local topic selection; no Query, repository, LogBox, shared carousel engine, controller, ScrollPosition, physics, Mind, Budget or global geometry owner changed.
- A final hot-path regression exposed an unintended `InkWell` Material-ancestor requirement in a Dashboard surface test. The tappable Movers row now uses `GestureDetector` with opaque hit testing, preserving its local action while remaining valid in the existing Material-free Core harness. `MIND-COLD-02` and `MIND-COLD-03` were RED before that repair and GREEN afterward.
- **Local validation PASS:** Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` reported `No issues found` (140.3 s); changed-Dart formatting was clean; `git diff --check` was clean; Compound/Movers projection and widget suite passed **32 tests**; full Core hot-path suite passed **108 tests**; CoreDashboard passed **35 tests**; shared carousel, Budget Avatar and mode-host guards passed **81 tests**. C1–C4 and M1–M7 are `DONE` in the acceptance checklist.
- Exact-source GitHub Actions human APK delivery, final SCIP regeneration, and device validation still follow this application source. **Physical validation: PENDING — USER ONLY.**

## 2026-09-23 — Balance Closings and Momentum linked-card design

- User-approved product decision: add **two separate linked Balance topics/cards** to the existing upper-carousel → lower-detail architecture: **Zárások / Period Closings** and **Balance Momentum**. This is new feature design, not a defect/root-cause claim. Existing Cashflow, Latest transaction, Top category and Top partner topics remain product features and must not be silently repurposed.
- Current feature branch before this journal-only entry: `feature/balance-carousel-v1` at `4c35adf0af7131f7cf010543fb53978886c7b344` (journal-only). Current application source remains `2bd7c356502a3e7e8cd55bb5431d72118ac99508` (`feat(balance): link carousel details to summary scope`).
- Current Balance architecture at `2bd7c356...`: one shared `CenteredCarousel` with a stable controller/ScrollPosition owns upper-topic motion; local Balance state selects one `BalanceLinkedDetailTopic`; one immutable Core-owned `DashboardBalanceLinkedPresentation` is built from resident prepared directional membership and drives the lower card. The finite topics are Cashflow, Latest transaction, Top category, Top partner and one prototype. The new cards must extend this existing owner chain, not create a second carousel, Query owner, repository path or lower-card surface.
- **Closings semantic contract:** this is NOT cumulative account Balance and NOT another line chart. Each bucket is its own period result, `net = income - expense`, rendered around a centered zero axis: positive net above zero, negative net below. Summary hierarchy is fixed: **SUM → years; YEAR → months; MONTH → calendar days; DAY → exactly six Balance-local dayparts**. The visual grammar is discrete diverging bars/columns; no cumulative line/area. Zero/empty buckets stay truthful at zero. Incomplete current periods show only actual data; never forecast.
- **DAY Closings boundary:** Budget currently has a source-proven eight-bucket, three-hour `SpendingRhythmDayPart` catalogue. Do NOT alter that Budget contract. Balance's six dayparts are a local presentation/analytics taxonomy. Prefer deriving them from the existing local-time facts (or directly from resident `bookedLocalTimeMinutes`) without new storage or hot-path work; freeze the exact six-bucket boundaries in tests. A source-compatible default mapping is: 00:00–05:59, 06:00–08:59, 09:00–11:59, 12:00–17:59, 18:00–20:59, 21:00–23:59. This mapping is an implementation default unless CURRENT source already contains a canonical six-part Balance taxonomy.
- **Momentum semantic contract:** Momentum must answer “is my net financial pace improving or worsening?”, not repeat Closings or the existing Balance Header line history. Moving average / comparable-window averaging is the calculation engine only; **do not render a moving-average line chart**.
- Momentum math: `currentNetPace = average net result over current/comparable window`; `previousNetPace = average net result over the immediately previous comparable window`; `momentum = currentNetPace - previousNetPace`. Keep current pace and momentum as separate dimensions: positive momentum does not mean the current net pace is positive.
- User-approved Momentum windows: **SUM = current year-to-date vs previous year over the same elapsed calendar span; YEAR = current month-to-date vs previous month over the same elapsed-day span; MONTH = rolling last 7 days vs the immediately preceding 7 days; DAY = selected/current day from 00:00 to the logical as-of time vs the previous calendar day from 00:00 to the same logical time. DAY must not use dayparts for Momentum.** For a fully historical selected scope, anchor comparison to that scope's truthful end rather than device wall-clock time; use the app's logical/as-of authority.
- **Momentum visual contract:** large lower card is a **2D four-quadrant Momentum Map**, not a line chart. X axis = current net pace (`deficit ← 0 → surplus`). Y axis = momentum (`worsening ← 0 → improving`). Quadrants: negative current + positive momentum = **Kilábalás**; positive current + positive momentum = **Erősödő többlet**; negative current + negative momentum = **Mélyülő deficit**; positive current + negative momentum = **Gyengülő többlet**. Exact-zero boundaries require explicit stable/break-even semantics, not arbitrary quadrant assignment. Compact metrics show previous pace, current pace and signed momentum. Insufficient comparison history is an explicit unavailable state.
- These cards are intentionally Balance-specific. Budget already owns daily spending-vs-limit pace/average semantics, so Closings/Momentum must stay net-flow/Balancing analytics and must not reintroduce average-spend or outlier analysis here.
- Upper-carousel integration intent: add compact previews for both new topics from the SAME immutable linked payload as the lower card. Do not perform independent calculations in the small-card renderer. The current prototype slot may become one real topic; adding the second topic may expand the finite logical topic list. Preserve the one shared carousel controller/ScrollPosition/physics and update tests rather than creating a second carousel.
- Data/performance invariant: reuse resident prepared Income + Expense membership already admitted by Core. Carousel selection is presentation-only and must perform zero repository/Room/index/scene work. Calculate bounded Closings/Momentum DTOs once per exact prepared identity + Summary scope/as-of identity and render them without rescanning source rows in build/paint.
- Existing primary Cashflow card remains. Header line/history/Compound modes, Mind, Budget, Summary physics, Query/repository architecture and global geometry are no-touch unless direct source evidence proves a necessary shared dependency.
- Protected physical no-regression floor remains `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- Current SCIP tooling head `3f04e9d5e222648ad476fddc6f14fa54a23d079e` indexes `source_head=7c5cf334145b819e946ba3aadb066a7177ea7f40`; therefore it is **STALE FOR CURRENT APPLICATION SOURCE `2bd7c356...`**. Use only as navigation until a matching graph is regenerated; source-verify all current relationships.
- Connected Drive search found no Balance-specific runtime log. Avatar/Time/Slider logs are historical no-regression context, not evidence for the new Closings/Momentum math. No new forensic-log campaign is justified for this product feature unless implementation tests reveal an actual regression.
- Prompt-writer action for this feedback: **journal only**, build-trigger-free `[skip ci]`; no application source, test, workflow, graph, milestone or build configuration change. Physical validation of the eventual implementation remains **PENDING — USER ONLY**.

## 2026-09-23 — Balance Closings and Momentum delivery

- Application commit `c1282a1820acfe6711baed08c8d995209d3383cb` (`feat(balance): add closings and momentum insights`) is based on the audited current application source `76ee16256bdde96d8ea9ae16077e5db1e105170c`, which had advanced beyond the prompt's documented `2bd7c356...` source. The pre-implementation journal merge is `31e61e47`; it preserves the remote Closings/Momentum design entry without rewriting either journal history.
- The existing Core-owned `DashboardBalanceLinkedPresentation` now carries bounded immutable Closings and Momentum DTOs derived once from the resident, canonical Income and Expense prepared memberships. `DashboardCoreController` resolves the logical date and immutable local minute from the same injected/resolved initial `DateTime`; no widget, projection, timer or repository acquires a wall clock. The existing linked-presentation LRU identity includes that logical minute, prepared identity, direction and Summary scope.
- The final six real linked topics are Cashflow, Zárások, Balance Momentum, Legutóbbi tétel, Top kategória and Top partner. The prototype and Category Movers topic are no longer in the finite UI domain. One unchanged `CenteredCarousel` remains the controller, ScrollPosition, physics and gesture owner; Balance keeps only local selected-topic state and one existing lower-card shell dispatches all six details.
- **Closings semantics:** SUM uses sparse, truthful represented years; YEAR has exactly 12 non-cumulative calendar-month buckets; MONTH has actual 28/29/30/31-day non-cumulative buckets; DAY has the Balance-local tested six-daypart taxonomy: **Éjjel 00:00–05:59, Reggel 06:00–08:59, Délelőtt 09:00–11:59, Délután 12:00–17:59, Este 18:00–20:59, Késő este 21:00–23:59**. Every bucket is exact `Income - Expense`, with normalized directional magnitudes. The lower renderer is a stable centered-zero diverging column chart with local-only bucket inspection; it is not a cumulative/line/area chart. The preview reads the same DTO as `N / M pozitív`.
- **Momentum semantics:** SUM compares current YTD to previous-year comparable YTD with leap clamp; current YEAR compares MTD to the preceding calendar month at the clamped day (historical YEAR uses December vs November); MONTH compares rolling seven days to the preceding seven; DAY compares equal elapsed current/previous-day hours or full historical days. Pace is money/day except DAY money/hour; totals stay integer minor units and only rates are fractional. The map has symmetric axes, a single truthfully positioned point, explicit four quadrants and exact zero states; unavailable history remains `Nincs elég összehasonlítható adat` rather than fabricated zero/NaN/infinity. The compact preview and lower map share the same DTO.
- **RED/GREEN evidence:** before production types/bindings existed, focused projection, Core and UI test invocations were RED for missing Closings/Momentum types and logical-time binding. GREEN Ubuntu/proot evidence includes `dashboard_balance_closings_momentum_projection_test.dart` (**14 passed**); final Balance projection/detail/surface/Cashflow grouped test (**46 passed**); final detail renderer test (**10 passed**); the required Core focus/dashboard/mode-host group (**158 passed**); and corrected shared-carousel/Budget/Mind guard group (**67 passed**). The first guard invocation failed only because two obsolete, absent paths were named; the corrected existing paths passed. Its Mind owner emitted one known non-fatal offstage hit-test warning, not a test failure.
- **Final local gates PASS:** Ubuntu/proot `flutter analyze --no-pub --no-fatal-infos` returned `No issues found` in 91.7 seconds; changed-Dart `dart format --output=none --set-exit-if-changed` made 0 changes; `git diff --check` and staged `git diff --cached --check` passed.
- **No-touch/ownership audit:** Cashflow calculation/view, Header/Compound, Mind, Budget and its eight-part `SpendingRhythmDayPart`, shared carousel implementation/profile, Summary physics/global geometry, Query/repository and prepared-scene/cache architecture are unchanged. Closings bar taps and map rendering are lower-card-local and add no competing horizontal pan recognizer. Compact lower bounds render a visible compact state without a chart hit surface.
- The prior tooling graph still has `manifest.source_head=7c5cf334145b819e946ba3aadb066a7177ea7f40`, so it is stale for `c1282a1820acfe6711baed08c8d995209d3383cb`. Exact-source SCIP regeneration, GitHub Actions human diagnostic APK delivery, APK hash/embedded SHA verification and Android user validation remain required. **Physical validation: PENDING — USER ONLY.**

## 2026-09-23 — Balance retention-ratio sibling context + Closings compact break-even insight

- User-approved new Balance insight: **Megtartási arány / Retention ratio** with formula `(income - expense) / income`, expressed as a percentage when income > 0. This feature follows **SIBLING context**, not child/drill-down context.
- Retention context mapping is fixed: **SUM → one all-history aggregate retention ratio; YEAR → sibling years compared against each other; MONTH → sibling calendar months compared against each other; DAY → still the same sibling MONTH comparison, with the selected day's containing month selected/highlighted.** DAY does not introduce a daily retention ratio.
- The monthly sibling view should remain chronologically continuous across year boundaries rather than resetting conceptually at each January; the selected month is highlighted from the current Summary context.
- Retention is distinct from the existing Duel/Cashflow and from Closings: Duel/Cashflow exposes Income and Expense amounts, Closings decomposes net period results, Retention answers what share of Income remained after Expense.
- Retention edge-state contract: if Income is zero, do not divide by zero and do not show infinity. A period with zero income but non-zero expense is an explicit `Nincs bevétel` / undefined-ratio state; fully empty periods are `Nincs adat`. Negative retention is valid when Expense exceeds Income.
- User-approved compact insight for the **Closings small carousel card**: **Break-even ratio**, e.g. `9 / 12 hónap pluszos`. This is NOT a separate large feature/card. It is derived from the SAME Closings bucket DTO: strictly positive-net buckets count as pluszos, exact zero is break-even and is not counted as positive, negative buckets are deficit. The compact preview may expose this count because the full lower Closings chart already makes the bucket distribution visible.
- No implementation prompt is requested by this feedback. Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Balance Cashflow Stability design

- User-approved new Balance insight: **Cashflow stabilitás / Cashflow Stability**. Its purpose is to answer **how predictable the net cashflow is from period to period**, not whether the user is currently positive/negative and not whether the trend is improving/worsening.
- Semantic separation is fixed: **Momentum = direction/change of net pace**; **Stability = dispersion/variability of net results**. A series can have near-zero momentum while remaining highly unstable.
- The primary stability measure should NOT be an arbitrary 0–100 score. Use a real money-denominated robust dispersion metric. Preferred contract: for monthly net results `net_i = income_i - expense_i`, compute `medianNet = median(net_i)` and `typicalDeviation = median(abs(net_i - medianNet))` (MAD-style robust deviation). User-facing label can be **Tipikus cashflow-kilengés**, e.g. `±84 000 Ft / hó`; the UI does not need to expose the statistical term MAD.
- Large-card visual is **not a line chart**. Preferred visualization is a one-dimensional net-cashflow distribution band around a visible `0 Ft` break-even reference: individual monthly net results appear as points/marks; a central/typical band communicates the normal range; the median net is explicitly indicated. Narrow band = stable, wide band = volatile. Avoid duplicating Closings bars, Momentum quadrant map, Cashflow Income/Expense chart, or Header line history.
- Supporting compact metrics may include: **Medián nettó**, **Tipikus sáv**, and **Szélsőséges hónapok**. Any extreme-period classification must be derived from the same robust distribution contract, not copied from Budget/outlier spending logic.
- Approved context mapping is **monthly-base stability at every Summary level**, rather than forcing noisy daily/daypart stability: **SUM → all complete months across all available history; YEAR → the selected year's calendar months; MONTH → the trailing 12-month window ending with the selected month; DAY → same trailing 12-month window ending with the selected day's containing month.**
- For the YEAR scope, only truthful represented months should contribute; current/incomplete month handling must be explicit and tested rather than silently mixing partial and complete periods. For trailing-12 contexts, the selected month anchors the window chronologically across year boundaries.
- Stability remains a Balance-specific net-flow insight and must use Income + Expense together. It must not reuse Budget's daily-spend average/limit semantics.
- No implementation prompt is requested by this feedback. Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Audit correction + three-feature Balance bundle request

- **Audit correction:** the current Balance application source is no longer `2bd7c356502a3e7e8cd55bb5431d72118ac99508`. Application commit `76ee16256bdde96d8ea9ae16077e5db1e105170c` (`feat(balance): add Compound and category movers`) landed after the linked-card delivery and before the later prompt-writer design entries. The intervening later commits `b6c2c3be...`, `b077aa00...`, and `6abcce48...` are journal-only. Any earlier journal sentence in those entries that called `2bd7c356...` the current application source or called the graph stale is superseded by this correction.
- Current branch head before this journal-only commit: `feature/balance-carousel-v1` at `6abcce482f24b1918a8630f9bd91268ea22525ad`. Current application source: `76ee16256bdde96d8ea9ae16077e5db1e105170c`, parent `4c35adf0af7131f7cf010543fb53978886c7b344`.
- Current source now has **six** Balance carousel slots: `categoryMovers`, `cashflow`, `latestTransaction`, `topCategory`, `topPartner`, and one `emptyPrototype`. Category Movers is the initial selected topic. `BalanceInsightIndicators` reflects the same six-slot selection and collects no gestures. The existing shared `CenteredCarouselController`/ScrollPosition remains the sole carousel motion owner.
- Current Core keeps one bounded 24-entry `DashboardBalanceLinkedPresentation` LRU keyed by prepared identity, Summary time scope, selected direction and `logicalAsOfDate`. The linked projection consumes resident Income + Expense membership and now also carries Category Movers. This remains the preferred extension seam for additional Balance analytics; do not introduce separate repository/query/cache authorities.
- **Matching SCIP is now available for the current application source.** Tooling branch head `c3424b2496bfddbd68eade7f926d0b8d44265142` indexes `manifest.source_head=76ee16256bdde96d8ea9ae16077e5db1e105170c`, scip-dart 1.6.2, raw index SHA-256 `aebc4128d1b4592d0004fe1af15d940907ba768349ac95f8349e58dd7215f9e9`. Changed-impact confirms direct production/test consumers around `DashboardBalanceLinkedPresentation`, `DashboardBalanceLinkedProjection`, `BalanceLinkedDetailTopic`, `BalanceCarouselCardKind`, Core and the Balance surface; CURRENT source was re-opened to verify those relationships.
- Application run `35827777536` for `76ee162...`: `dashboard-paths`, `test-core`, `test-flutter`, and `build-human-diagnostic-apk` PASS; `run-dashboard-profile` FAIL. The exact profile failure body was not available in the current audit and therefore is **not** classified as inherited or new here. Human release `fluvi-human-diagnostic-76ee162` exists with `fluvi_HUMAN_DIAGNOSTIC_76ee162.apk`, size 85,235,297 bytes, SHA-256 `c8584aed5b0bce0a0d4ef83fc2f02ee25e7a6558572000ceea4fb2aefb7d8266`. No user physical acceptance of this APK is recorded.
- Current source/search shows no implementation yet for **Retention ratio**, **Cashflow Stability**, or a **Closings break-even compact insight**. The previously designed **Closings / Period Closings** and **Balance Momentum** are also not present in current source; they remain a prior prompt/design contract, not an implemented prerequisite.
- User request for this prompt bundles exactly these **three new items**: **(1) Megtartási arány / Retention ratio**, **(2) Cashflow Stability**, and **(3) Break-even ratio as the compact insight of the Closings small card**. The third item is explicitly **not** a separate large feature/card.
- Because Break-even must be derived from the SAME Closings bucket DTO and current source does not yet contain Closings, implementation must have a prerequisite gate: if the prior Closings feature has not landed by execution time, do not create an independent duplicate break-even aggregation path. Either execute this bundle after Closings lands, or stop only that dependent unit and report the missing prerequisite while keeping Retention/Stability changes logically separable.
- Retention contract remains sibling-context: SUM = one all-history aggregate; YEAR = sibling years; MONTH = chronologically continuous sibling months; DAY = the same month-sibling view with the selected day's containing month highlighted. Formula is `(income - expense) / income` when income > 0; negative values are valid; zero-income periods are explicit undefined/no-income states, not infinity.
- Cashflow Stability contract remains monthly-based at every Summary level: SUM = all complete months in history; YEAR = selected year's truthful complete months; MONTH = trailing 12 months ending at selected month; DAY = same trailing 12 months ending at selected day's month. Hero metric is money-denominated robust typical deviation (MAD-style), not an arbitrary score. Large visual is a one-dimensional net-cashflow distribution band with visible break-even zero and median, not a line chart.
- Break-even compact insight remains derived from Closings buckets: e.g. `9 / 12 hónap pluszos`; strictly positive net counts as pluszos, exact zero does not. It is shown in the Closings small carousel card, not as a new lower-card topic.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed. Physical validation of any future implementation remains **PENDING — USER ONLY**.

## 2026-09-23 — Ghost transaction semantics correction: lifecycle vs persistent provenance

- User correction: a Fluvi **Ghost transaction is not merely a conditional forecast item**. It has two distinct concepts that must not be conflated:
  1. **lifecycle state** — before its trigger fires it is a pending Ghost definition/event and is not yet a real ledger transaction;
  2. **persistent provenance flag** — after the trigger fires, it materializes into a real ledger transaction, but the Ghost-origin flag/badge remains permanently attached to that real transaction.
- Consequence for analytics: materialized Ghost-origin transactions are valid real transactions and may be included in financial totals. However, behavioral analytics may need to **exclude** them because large mandatory/fixed expenses can distort discretionary-spending behavior. Example product distinction: 100k restaurant spend is behaviorally different from 100k mandatory gas/utility/rent spend even though both are real Expense transactions.
- The analytics filtering problem is therefore **not the same as pending-vs-actual forecast state**. Recommended future Balance data lens is over **materialized real transactions by Ghost provenance**:
  - **All actual / With Ghost** = all real transactions, including triggered Ghost-origin rows;
  - **Without Ghost** = only real non-Ghost-origin transactions;
  - **Only Ghost** = only materialized real Ghost-origin transactions.
  Pending untriggered Ghost definitions must NOT silently enter historical actual analytics under any of these three modes.
- Pending Ghosts remain useful in a dedicated Ghost card for lifecycle/obligation visibility and may later feed an explicitly labelled forecast/scenario layer, but forecast inclusion is a separate semantic mode from the provenance filter above.
- Strong product rationale: one global/shared Ghost provenance lens is preferable to duplicating independent toggles on every analytics card, because mixed card-local filter states would make cross-card comparisons ambiguous. Card-specific compatibility can still be explicit where a metric should ignore or restrict Ghost filtering.
- Dedicated Ghost card remains useful even with the global provenance lens because it answers a different question: pending definitions, recently triggered/materialized Ghosts, lifecycle state, amount at risk/expected, and individual selection. The card may show both pending and already-materialized Ghost-origin items with clearly different states.
- Future data model requirement: keep **pending lifecycle state** and **persistent Ghost provenance** as separate fields/authorities. Do not model Ghost as a single transient boolean that disappears on trigger. A real materialized Ghost transaction must remain distinguishable from an ordinary real transaction.
- Current repository search on application source lineage found no existing `ghost`, pending-transaction, fixed-expense, recurring-expense, or triggered-transaction implementation. Therefore this is a forward product/data-model contract, not a current-source behavior claim.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Balance compact Momentum preview delivery correction

- The first Closings/Momentum application delivery candidate `c1282a1820acfe6711baed08c8d995209d3383cb` reached GitHub Actions run `35835098652`. `dashboard-paths` and `test-core` passed, but `test-flutter` failed before the human APK job could start. The exact failure was a `RenderFlex` bottom overflow of 13px in `dashboard_rebuild_isolation_test.dart`, test `structural dashboard changes preserve the rail controller, position and physics`.
- The failure is a Balance-local compact-preview layout defect: a scaled carousel side-card could receive only 39.3px of physical height while the new optional Momentum semantic-state line still rendered. It is neither a Core-data, financial-math, shared-carousel controller/physics, Query nor repository failure.
- Application correction `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9` preserves the primary preview value and renders the optional semantic-state detail only in a normal-height Balance card. The selected normal card retains its state label. Compact side cards have no overflow or clipped extra text.
- **RED/GREEN:** the exact existing structural rebuild test reproduces the 13px overflow before the correction and is PASS after it. Ubuntu/proot `scripts/test-fluvi-fast.sh` is PASS (**432 passed**); Balance surface/detail retest is PASS (**22 passed**); `flutter analyze --no-pub --no-fatal-infos` is PASS (`No issues found`, 152.9 s); formatter and `git diff --check` are PASS.
- The final source is now `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`; the `c1282...` graph is historical and must be regenerated for this source. The previous Actions run produced no human APK, so a new online build, APK hash/embedded identity and exact-source SCIP graph remain required. **Physical validation: PENDING — USER ONLY.**

## 2026-09-23 — Dedicated Ghost card content approved; Forecast card discussion pending

- User approved the dedicated **Ghost / Fix terhek** card concept as a lifecycle/provenance view, distinct from the future global Ghost analytics lens.
- Small Ghost carousel card: user-facing concept **Fix terhek** with Ghost badge/icon. Hero should prioritize amount rather than count, e.g. pending fixed burden amount plus compact count/next-trigger context. If no pending item exists, the compact card may emphasize materialized Ghost-origin burden for the current context.
- Large Ghost card content is lifecycle-first, not another generic spending chart. It should clearly separate at least **materialized/activated real Ghost-origin transactions** from **pending untriggered Ghost definitions/events**. Materialized items are real ledger transactions and retain the Ghost badge/provenance; pending items are not yet actual ledger rows.
- Preferred large-card metrics: **Aktiválódott/materializált amount**, **Pending amount**, and an explicitly forecast-labelled **Várható fix teher** only when summing pending obligations. A projected value must never masquerade as current actual Balance.
- Preferred main composition for Month/Day contexts: **Ghost timeline/list** with concrete entries and lifecycle state. Pending entries use visually ghosted/transparent/dashed treatment; materialized entries use solid real-transaction treatment while retaining the Ghost badge. Tapping an item opens local detail only.
- Ghost detail should distinguish **definition** vs **occurrence/materialized transaction** and may show: name, amount, current lifecycle state, trigger definition, next trigger, last activation/materialization, and historical materialized Ghost-origin total. Triggered/materialized transactions remain marked as Ghost origin after becoming real.
- Suggested Summary behavior for the dedicated Ghost card: **SUM → commitments/definitions overview plus all-history materialized Ghost context and currently pending obligations; YEAR → monthly fixed-burden overview; MONTH → strongest timeline/list of all Ghost occurrences/definitions in that month; DAY → Ghost items on the selected day, with a clean no-item state and optionally the next upcoming Ghost.** Exact final visualization can be source-adapted when the Ghost engine exists.
- Optional secondary metric: **Fix teher aránya** = fixed/Ghost burden relative to income where the denominator is truthful. This is secondary and must not be confused with actual Balance.
- The dedicated Ghost card and the future global provenance lens have separate responsibilities: **Ghost card = lifecycle/obligation/entity inspection**; **Ghost analytics lens = include/exclude materialized Ghost-origin real transactions in behavioral analytics**; **pending forecast = separate explicit scenario layer**.
- User explicitly requested **NO coding-agent prompt yet**. A separate Forecast card will be designed next; Ghost + Forecast are intended to be bundled later in one larger implementation prompt.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Ghost + Forecast placeholder-card bundle approved

- User approved bundling **two new Balance linked topics/cards** into one implementation unit: **Ghost / Fix terhek** and **Forecast**. The Ghost engine/data model does not exist yet, so the immediate delivery is a **truthful presentation placeholder integration**, not a speculative Ghost storage/trigger implementation. Forecast is likewise data-blocked because truthful behavior forecasting must distinguish materialized Ghost-origin transactions from ordinary real transactions and must separately consume pending Ghost obligations; therefore the immediate Forecast delivery is also a presentation placeholder, not fabricated analytics.
- Current feature branch at prompt audit is merge HEAD `36cb417a0337656ece1d2c7a65158cfb7ed28ace`; that merge changes only `docs/FLUVI_ENGINEERING_JOURNAL.md`. Current behavioral application source is `c1282a1820acfe6711baed08c8d995209d3383cb` (`feat(balance): add closings and momentum insights`).
- Current source at `c1282...` has exactly six real Balance linked topics and no prototype: **Cashflow, Zárások, Balance Momentum, Legutóbbi tétel, Top kategória, Top partner**. One unchanged shared `CenteredCarousel` remains the controller/ScrollPosition/physics/gesture owner. Ghost + Forecast must extend this finite topic list without replacing any current real topic. If more real topics land before execution, preserve all of them and append/adapt rather than relying on a hard-coded count.
- Current graph status at prompt audit: tooling head `c3424b2496bfddbd68eade7f926d0b8d44265142` indexes `manifest.source_head=76ee16256bdde96d8ea9ae16077e5db1e105170c`; therefore it is **STALE FOR CURRENT APPLICATION SOURCE `c1282...`**. Stale graph may be used only for historical navigation. The coding agent must source-audit current owners and regenerate a matching pre-change graph before shared/Core impact conclusions if feasible, then regenerate exact final-source SCIP after delivery.
- Current merge-head workflow `35835098652` was still **in progress** at prompt audit time. No exact `c1282...` workflow run or human diagnostic APK/release was found yet. Local tests recorded in the delivery journal are green, but Android physical validation remains **PENDING — USER ONLY**.
- Connected Drive search found **no Ghost/Forecast runtime log**. This is expected because neither feature exists. Existing historical Fluvi interaction logs are not causal evidence for these new placeholder cards.

### Ghost semantic contract

- Ghost has **two separate authorities**:
  1. lifecycle: a pending Ghost definition/event is not yet a real ledger transaction;
  2. persistent provenance: once its trigger fires it materializes into a real ledger transaction and permanently retains Ghost origin/badge metadata.
- A materialized Ghost-origin transaction is financially real and belongs in actual totals, but behavioral analytics may later exclude it because mandatory/fixed spending (rent, utilities, etc.) must remain distinguishable from discretionary behavior.
- Future global analytics lens remains conceptually separate from this card: **All actual / With Ghost**, **Without Ghost**, **Only Ghost** apply to materialized real transactions by persistent Ghost provenance. Pending Ghost definitions do not enter actual historical analytics. This shared lens is future scope, not part of the immediate placeholder implementation.
- Dedicated Ghost card responsibility: lifecycle/obligation/entity inspection, not generic Ghost-only analytics.
- Approved future compact Ghost preview concept: **Fix terhek** with Ghost badge; hero prioritizes pending/materialized amount over count, with compact count/next-trigger context.
- Approved future large Ghost card: clearly separates **materialized/activated real Ghost-origin transactions** from **pending untriggered Ghost definitions**. Preferred metrics are **Aktiválódott/materializált amount**, **Pending amount**, and explicitly forecast-labelled **Várható fix teher**. A projected amount must never masquerade as actual Balance.
- Preferred future Month/Day main composition is a **Ghost timeline/list**. Materialized rows use solid real-transaction treatment while retaining the Ghost badge; pending rows use ghosted/transparent/dashed treatment. Tap opens local detail only.
- Future item detail distinguishes definition vs occurrence/materialized transaction and may show name, amount, lifecycle state, trigger, next trigger, last activation, and historical materialized Ghost-origin total.
- Approved future Summary behavior: **SUM → commitments/definitions overview + all-history materialized Ghost context + current pending obligations; YEAR → monthly fixed-burden overview; MONTH → strongest Ghost timeline/list; DAY → selected-day Ghost items with clean no-item state and optionally next upcoming Ghost.**
- Optional future secondary metric: **Fix teher aránya** relative to truthful Income. It is secondary and never replaces actual Balance.

### Forecast semantic contract

- Forecast answers: **“Given actual financial state, known future obligations, and robust non-Ghost spending behavior, where am I likely to close?”**
- Forecast must distinguish three provenance classes visually and mathematically:
  - **Actual / fact** — already materialized ledger reality;
  - **Known future / committed** — pending Ghost obligations (and source-proven known future Income if such authority later exists);
  - **Estimated future** — statistical non-Ghost behavior forecast.
- Pending Ghost obligations and behavior forecast must never be merged into one anonymous “expected expense” number.
- Historical materialized `ghostOrigin=true` expenses are excluded from the **behavior baseline** so mandatory fixed costs do not train the discretionary-spending estimate; pending Ghost obligations are then added separately. This prevents double counting.
- Approved first forecast model for MONTH/DAY behavior: **remaining-behavior forecast = robust median of the previous six complete months' non-Ghost spending over the same remaining-calendar-span length**. Example: with 7 days left in the selected/current month, take the final 7 days from each of the six previous complete months, exclude Ghost-origin materialized rows, compute each month's spend, then use the median. Do not use a simple mean and do not use ML in v1.
- Category-level decomposition may later explain the aggregate estimate, but sparse categories must not create fake precision; the aggregate robust baseline remains authoritative unless a source-proven category model is explicitly added later.
- Forecast uncertainty must be a **truthful typical range** derived from the historical remainder sample/robust dispersion; do not display arbitrary confidence percentages.
- Forecast large card is approved as **two pages**:
  1. **Forecast Bridge / Zárás** — “Where will I close?” with current actual state, known future Income if available, pending Ghost burden, estimated non-Ghost spending, projected closing amount, and typical range;
  2. **Forward Timeline / Kilátás** — “Why?” with known dated future events as concrete items and estimated behavior as a band/aggregate, never fake future transactions.
- Use subtle page dots/local page selection rather than adding another global segmented controller. Any page interaction stays local to the lower card and must not compete with Header/global horizontal mode navigation or the upper carousel.
- Approved Forecast horizons:
  - **SUM → rolling next 12 months**, not “all-time end”;
  - **YEAR → current year end**;
  - **MONTH → current month end**;
  - **DAY → same containing month end, starting from the selected/current day**, not end-of-day as the hero horizon.
- Page-2 granularity:
  - SUM → months;
  - YEAR → remaining months;
  - MONTH → remaining days;
  - DAY → selected day through month end, daily.
- Historical selected periods must **not** receive fake hindsight forecasts. V1 should expose an explicit unavailable state such as “Forecast csak az aktuális időszakra érhető el.” Historical backtesting is a separate future feature.
- Forecast may expose two conceptually distinct results when the data engine exists:
  - **Ismert terhek után** = actual state adjusted only by source-proven known future items;
  - **Várható zárás** = known future result plus estimated non-Ghost behavior.
  They must not be collapsed into one undocumented number.

### Immediate implementation boundary

- Because neither Ghost lifecycle/provenance storage nor pending-Ghost authority exists in current source, **do not add Room/schema/native/repository/domain trigger machinery in this task**.
- Do not fabricate fake financial numbers, hard-coded example transactions, or treat all current transactions as non-Ghost merely to make Forecast appear functional.
- Immediate deliverable: add **two real finite Balance carousel topics** and their lower-card placeholder surfaces using the existing linked-card architecture, with truthful disabled/coming-soon states. Preserve the approved future semantic contract in tests/docs/code comments only where useful; do not create speculative duplicate data authorities.
- The placeholders must remain presentation-only: selecting them performs zero repository/index/scene/Query work and preserves the exact shared carousel controller/ScrollPosition/physics.
- Future implementation must replace placeholder data through the existing Core-owned immutable linked-presentation seam (or a source-proven equivalent single authority), not by letting widgets query Ghost/Forecast data independently.
- User requested this Ghost + Forecast pair as **one large coding-agent prompt**. It does **not** reopen or bundle Retention, Cashflow Stability, the Ghost analytics lens, Ghost engine/storage, or historical forecast backtesting.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed. Physical validation of the eventual candidate remains **PENDING — USER ONLY**.

## 2026-09-23 — Ghost + Forecast prompt preflight addendum: current Balance branch CI baseline is red

- After the Ghost + Forecast design entry, merge-head workflow `35835098652` for `36cb417a0337656ece1d2c7a65158cfb7ed28ace` completed **FAIL**. `test-core` and `dashboard-paths` passed; `test-flutter` failed, therefore profile/APK jobs were skipped.
- Exact failing curated test: `test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart: structural dashboard changes preserve the rail controller, position and physics`. The retained CI log proves a **vertical RenderFlex overflow by 13 pixels** under constraints approximately `w=53.5, h=39.3`; the suite result was **431 passed, 1 failed**.
- This failure is current **baseline evidence before Ghost/Forecast application changes**. It is not yet proven which specific Balance compact card/body owns the overflowing Column, and no root cause is asserted here.
- Because Ghost + Forecast modify the same finite Balance upper-carousel surface, the coding agent must reproduce this exact baseline failure before mutation, identify the actual offending widget/card and first failing layout boundary, and apply only the smallest source-proven responsive-layout repair required to restore the existing no-overflow contract before/while extending the rail. Do not retune shared carousel physics, controller/ScrollPosition identity, global geometry or unrelated dashboard layout to hide it.
- The new Ghost/Forecast placeholder cards must themselves remain compact-safe at the same constrained heights and may not introduce additional lines/overflow in the compact rail state.
- This addendum does not change the feature semantic scope: Ghost engine/storage, Forecast analytics engine, global Ghost provenance lens, Retention/Stability and historical forecast backtesting remain out of this implementation.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Balance Closings and Momentum delivery finalized

- Final application source is `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9` (`fix(balance): fit momentum preview in compact carousel`) on top of `c1282a1820acfe6711baed08c8d995209d3383cb` (`feat(balance): add closings and momentum insights`). The compact correction was required after the first candidate exposed a 13px Balance Momentum side-card `RenderFlex` overflow; it leaves the normal selected card's semantic state, all Closings/Momentum DTO math, Cashflow, Core ownership and shared carousel implementation unchanged.
- Feature-branch delivery build: GitHub Actions run `35837157590` for merge head `38a32f719f9d1e665f46d2552f48715fb2fe34f5`, whose behavioral application source is the final `b6b55840...`. `dashboard-paths`, `test-core`, `test-flutter`, and `build-human-diagnostic-apk` are **PASS**. The normal human diagnostic APK is `fluvi_HUMAN_DIAGNOSTIC_38a32f7.apk`, 85,235,297 bytes, downloaded to `/storage/emulated/0/Download/fluvi/`; SHA-256 is `3dcf0a824195ee8ccc874765856a6ccf3b5ae54ea54bae28f8ac64c4d069452f`. ZIP integrity passed and its `lib/arm64-v8a/libapp.so` contains the embedded `FLUVI_BUILD_COMMIT=38a32f719f9d1e665f46d2552f48715fb2fe34f5`.
- The run's `run-dashboard-profile` job is **FAIL**, so the workflow as a whole is honestly FAIL. This is an inherited, out-of-scope Mind profile assertion: `integration_test/dashboard_interaction_profile_test.dart:1694`, `Mind score must use the same live canonical range as the heatmap before pointer release.` The same `QueryAmountRangeValues` assertion, source line, scenario `B_year_month_rail_populated`, and post-failure report-map symptom occur in baseline run `35827777536` at application source `76ee16256bdde96d8ea9ae16077e5db1e105170c`, before this feature. No Mind code, profile harness, Header, Budget or shared carousel source changed in this delivery.
- Final SCIP graph is tooling commit `40d34345d8ad4b613323fdd57c4f091413b10e16` on `tooling/scip-codegraph-v1`. `docs/codegraph/manifest.json.source_head` is exactly `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`; raw index SHA-256 is `604ccf6e0895422654943c0550e24942aaf22a98c13b34174b7ee254dfc78fa3`; generator is `scip_dart 1.6.2`; two generations produced matching graph-tree SHA-256 `4db8dc2d15eeb2e880dff7a267fd2bdfbf11a18e5c0fe9d0e571f48542e13382`; tooling tests are **15 PASS**. Queries reconfirmed the linked-presentation and topic consumers, with Closings/Momentum projections owned by the existing primary linked projection.
- The two real topics remain complete by their approved contract: shared resident Income+Expense-linked immutable payload; six actual carousel topics; centered-zero non-cumulative Closings; six tested Balance-local dayparts; logical-clock comparable Momentum; four-quadrant map and explicit zero/unavailable states; one lower-card shell and one unchanged shared carousel. No new repository/query/index/scene work is performed by topic selection.
- Remaining acceptance evidence is only physical product validation. **PHYSICAL VALIDATION: PENDING — USER ONLY.**

## 2026-09-23 — Category Insight ownership correction: no partner analytics

- User correction: the **Top Category → category-specific local detail** must contain **category-only analytics**. It must NOT contain partner/vendor metrics, partner ranking, top partner, partner concentration, or partner transaction summaries because Balance already has a dedicated **Top Partner** card/owner for that information.
- Product ownership boundary is explicit: **Category detail = how this category behaves internally over time and by transaction pattern**; **Movers = which categories changed most versus a comparison period**; **Partner card = partner/vendor analytics**. These three views must not duplicate one another.
- Candidate category-only detail content therefore includes: selected category total and share of all spending/income in the current scope; transaction count; median/typical transaction amount; active-day count/frequency; temporal child-profile by Summary level (SUM→years, YEAR→months, MONTH→days, DAY→transactions/time sequence); transaction-size distribution; category-specific spending rhythm/time-of-day; active-day calendar/density; and recent transactions if desired, as rows belonging to the category rather than partner-derived aggregation.
- Category detail should avoid period-over-period mover/delta ranking if Category Movers remains a separate feature; any temporal profile shown here should describe the category's internal composition, not compete with Movers' change-detection responsibility.
- No coding-agent prompt requested. Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Category detail transaction-size distribution approved; Partner detail discussion opened

- User approved a category-specific **Tipikus tranzakcióméret / Typical transaction size** block for the future Top Category local drill-down page.
- Approved visual grammar: a compact horizontal **transaction-count distribution band** with four readable amount buckets (initial product default: `0–5k`, `5–10k`, `10–20k`, `20k+`) and a clearly marked **median transaction amount**. The distribution measures **transaction count per amount bucket**, not money-weighted share, so one large transaction cannot dominate the visual.
- The block may expose one compact textual insight such as the dominant bucket/share (for example “A tranzakciók 57%-a 5–10k közé esik”). The first version should be read-only; no separate bucket interaction/filtering is required.
- Scope behavior: SUM/Year/Month use the selected category's actual transactions in that scope. DAY should not force a histogram when sample size is too small; it may fall back to compact transaction-size stats (median/min/max or an equivalent truthful low-sample treatment). Exact low-sample threshold must be frozen when implementation is specified.
- This remains **category-only analytics**. No partner/vendor aggregation may appear in this block or the category detail.
- User explicitly requested **NO coding-agent prompt yet**. Next product-design topic is a local **partner-specific secondary page** opened by tapping a row in the existing Top Partner list. No partner-detail content contract is approved yet; brainstorming follows in chat.
- Prompt-writer action: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed.

## 2026-09-23 — Category + Partner local drill-down bundle approved

- User approved implementing **two local master/detail extensions inside the existing Balance lower card**: tapping a row in **Top Category** opens a category-specific secondary page; tapping a row in **Top Partner** opens a partner-specific secondary page. Both are local inspection only, with Back returning to the original Top 5 list. They must NOT mutate Query/category focus/partner focus, Summary scope, global Balance topic selection, or the upper carousel.
- Current behavioral application source for this design is `b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`; branch descendants at design time are documentation-only. Matching SCIP tooling commit is `40d34345d8ad4b613323fdd57c4f091413b10e16` with exact `manifest.source_head=b6b5584030de0ae41e40cc4d2cc91e68d36e61c9`.
- Current source facts: `DashboardBalanceLinkedProjection` ranks Top Category by absolute amount and Top Partner by transaction count on the **active direction only**, from the already scope-filtered resident directional membership. `DashboardBalanceRankedItem` currently carries only id/label/direction/amount/count/category visual metadata. `_RankedDetail` / `_RankedRow` are currently read-only and have no tap/drill-down state. The renderer has no repository/runtime/prepared-index dependency.
- Graph audit confirms `DashboardBalanceLinkedPresentation` is consumed by Core, Balance surface, the one linked-detail renderer, mode host and focused tests; `BalanceLinkedDetailTopic` is consumed by the Balance surface/detail and their tests. Any new insight DTOs must extend this existing Core-owned immutable linked-presentation seam rather than creating widget-side data acquisition.

### Category-specific secondary page — approved ownership

- Category detail answers **“How does this category behave internally?”** It must remain strictly **category-only analytics**.
- Explicit no-duplication boundary: **NO partner/vendor aggregation**, no top partner, no partner concentration, no partner ranking, and no partner-derived transaction summary may appear on the category page because Top Partner owns that domain.
- Category detail also avoids Movers/change-detection ownership: no “+31% vs previous period”, mover ranking, or period-over-period category delta as a headline insight. A future/separate Movers feature remains responsible for “which category changed most”.
- Approved category hero/current-scope metrics: selected category total amount, share of the active-direction scoped total, transaction count, active-day count, and median/typical transaction amount.
- Approved category temporal child profile: **SUM → yearly category amounts; YEAR → 12 monthly category amounts; MONTH → daily category amounts; DAY → chronological category transaction/time sequence without partner labels.**
- Approved signature block: **Tipikus tranzakcióméret / Typical transaction size**. It is a compact horizontal transaction-count distribution band, not money-weighted. Initial display buckets: **0–5k Ft, 5–10k Ft, 10–20k Ft, 20k+ Ft**, using absolute transaction amount and canonical money scaling. A median marker is shown. Optional one-line insight may state the dominant bucket/share.
- DAY must not fabricate a histogram from a tiny sample. Freeze the implementation threshold at **4 transactions**: with <4 selected-category transactions in the day scope, show truthful compact min/median/max transaction-size stats instead of the four-bucket distribution.
- Distribution bucket boundaries are lower-inclusive / upper-exclusive except the open-ended final bucket: `[0,5k)`, `[5k,10k)`, `[10k,20k)`, `[20k,+∞)`. Exact minor-unit conversion must use the current canonical money scale rather than renderer magic numbers.

### Partner-specific secondary page — approved ownership

- Partner detail answers **“What is my financial relationship with this partner?”** It must remain partner/entity-specific and must NOT contain category ranking, category concentration or category-distribution analytics.
- Approved current-scope hero: partner name, total amount for the active direction/current Summary scope, and transaction count. Compact current-scope metrics may include active-day count and latest occurrence.
- Approved signature visualization: **Partner cadence / recurrence timeline**. It shows the partner’s recurrence pattern and intervals between occurrences rather than another generic spending bar chart. The primary cadence metric is **typical time between transactions**, calculated robustly as the median of consecutive local occurrence intervals. Do not call one interval “typical”: cadence requires at least **3 transactions / 2 intervals**; otherwise expose an explicit insufficient-cadence state.
- Cadence chronology uses the canonical local ledger facts (`bookedLocalEpochDay` + `bookedLocalTimeMinutes`, with existing occurrence ordering rules where relevant). The rendered cadence strip must be bounded; show at most the **most recent 8 occurrences** with interval annotations while computing the metric from the full admitted partner history used by that metric.
- The partner page also has an **amount-consistency block**: median/typical transaction amount plus a truthful **typical amount range**. Freeze v1 range semantics as the middle 50% (Q1–Q3) of absolute materialized transaction amounts using one deterministic tested quantile rule; do not create an arbitrary 0–100 stability score.
- Approved relationship-history block: first transaction, latest transaction, and all-time transaction count for that partner, clearly labelled as all-history relationship context when the current Summary scope is narrower.
- Approved scope-local temporal activity profile: **SUM → activity by year; YEAR → activity by month; MONTH → activity by day; DAY → concrete occurrences/time order.** This profile should emphasize occurrence/frequency so it remains semantically distinct from the amount-led Category profile.
- Approved recent-occurrence section may show a bounded list of the most recent **5** partner transactions in the current scope using date/time + amount; do not add category labels/aggregation there. Future Ghost-origin badges may later decorate concrete rows, but Ghost implementation is not part of this task.

### Shared local-state / data contract

- Both pages are **local drill-down states inside the same lower Balance card**, not new carousel topics or new dashboard modes. Upper Top Category / Top Partner cards and their ranking semantics remain unchanged.
- Row tap stores only the selected entity id in local presentation state. Back returns to the existing rank list. If a linked-presentation replacement changes scope/direction and the selected id no longer has a current detail payload, clear the local selection back to the list. If the same id remains, update its immutable detail in place.
- Detail data must be computed once from the existing resident prepared membership in the Core-owned linked projection and delivered as bounded immutable DTOs. No row tap, build or paint may query repository/Room/index/scene or rescan ledger rows.
- Preferred bounded computation: preserve current rank semantics, identify the top-5 category and top-5 partner ids, then collect their detail analytics in at most one additional pass over the already scope-admitted directional membership (and only explicitly labelled all-history partner relationship fields from the resident full directional membership). Avoid N×5 rescans and avoid unbounded raw-row retention in the 24-entry linked-presentation LRU.
- Render DTOs must be bounded: Top 5 detail entities each; recent partner rows max 5; cadence markers max 8; DAY event markers should be bounded to a source/test-justified card-safe count while aggregate metrics still use all admitted rows.
- Existing lower-card ListView/vertical ownership can be reused where appropriate; no new global controller, Query authority, carousel controller or competing global horizontal gesture owner.

### Delivery request

- User now requests **one production-grade coding-agent prompt containing both Category and Partner drill-down features**.
- Scope does NOT include Retention, Cashflow Stability, Ghost/Forecast, Ghost analytics lens, Category Movers implementation, changes to Top Category/Top Partner ranking rules, Header/Compound, Closings, Momentum, Cashflow or shared carousel physics.
- Prompt-writer action for this feedback: journal only, build-trigger-free `[skip ci]`; no application source, tests, workflow, graph, milestone or build configuration changed. Physical validation of the future candidate remains **PENDING — USER ONLY**.


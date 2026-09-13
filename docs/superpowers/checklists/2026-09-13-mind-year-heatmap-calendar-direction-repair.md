# Mind Year Heatmap physical repair acceptance checklist

Source of truth: the 2026-09-13 physical-repair instruction, the supplied
Android screenshot, `MILESTONE_COMMITS.md`, and the current repair source on
`fix/mind-year-heatmap-calendar-direction-fluvi-20260913`.  This supersedes
the completion claims in the earlier feature checklist only for the defects
listed here; it does not erase that feature's historical evidence.

| ID | Requirement source | Intended owner/area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MYHR-01 | §1–3 topology directive | canonical Fluvi checkout / Git refs | Work is on the canonical Fluvi checkout and repair branch; old feature history is fast-forward-reachable; obsolete extra heatmap worktree and old branch are absent. | `worktree list`, ancestry, refs, status | DONE |
| MYHR-02 | §0/4 journal gate | journal + audited feature history | Full journal, milestones, prompt rules, diffs, tests, artifacts, and graph provenance are reviewed; factual missing evidence is backfilled before a repair application commit. | source/CI audit + journal commit | PARTIAL — audit complete; backfill commit pending |
| MYHR-03 | §5 graph gate | SCIP tooling graph | A matching graph is generated before shared-symbol decisions and again for the final app SHA; every graph hit is verified in current source. | manifest/source-head/hash + source inspection | PARTIAL — d279 pre-repair graph generated; final graph pending |
| MYHR-04 | §6–9 physical calendar repair | Mind heatmap geometry + viewport | Month cards are calendar-height-driven: no fixed global aspect-ratio tail, exactly 12 months remain in 3 visual columns × 4 rows, square cells remain square, and the footer stays outside the scroll area. | pure geometry + narrow widget/layout tests + screenshot after build | NOT DONE |
| MYHR-05 | §8/16 weekday geometry | immutable calendar geometry owner + painter | Monday–Sunday seven-column placement uses local first-day weekday; leading/trailing non-days paint nothing and have no cell semantics; real no-data days paint gray; real data days paint colored. | Monday/Wednesday/Sunday, 2025, leap/year/month painter/widget tests | NOT DONE |
| MYHR-06 | §10–12 exact membership | Core controller / prepared direction partition | The first causal direction boundary is evidenced. Income and expense have exact, disjoint colored local-day sets from the production-parent controller; all other real days are gray; range is only a secondary intersection. | RED then green mounted-parent tests + diagnostic correlation | NOT DONE |
| MYHR-07 | §13 atomic switch | direction request/publication/viewport | Every frame after an Income↔Expense tap has matching chrome and heatmap identity, is nonblank, has no stale repaint, and rapid changes are latest-wins. | frame-by-frame mounted-parent tests | NOT DONE |
| MYHR-08 | §14–15 performance | bounded projection/publication path | Warmed direction reaches a correct paint by the next render frame; no repository/index/Room rebuild on slider path; source work stays bounded; cache/prewarm appears only if measured necessary. | timing/profile counters, FrameTiming and large fixture | NOT DONE |
| MYHR-09 | §17 diagnostics | existing logger + DebugConsole only | The existing debug console provides `Mind Heatmap` as a distinct log filter; All retains heatmap events; events are bounded, correlated, coalesced for slider activity and privacy-safe. | logger/panel tests + source inspection | NOT DONE |
| MYHR-10 | §19 no-regression lock | Dashboard shared systems | Avatar/Time physics/controllers/positions, Query authority/menu, unrelated modes, and direction-circle behavior remain untouched unless new evidence proves the first failure there. | diff audit + focused regressions | NOT DONE |
| MYHR-11 | §20–22 verification | tests/profile | RED evidence is captured before repair; focused and production-parent green tests, analysis, large data profile, timing/rebuild/paint evidence all pass. | exact command output/artifacts | NOT DONE |
| MYHR-12 | §21 journal loop | commit history + journal | Every new application commit has required evidence body and a following `[skip ci]` factual journal commit. | `git log`, journal | NOT DONE |
| MYHR-13 | global Flutter delivery rule | GitHub Actions / Download | Each pushed production commit gets its exact online human APK; final normal APK is in `/storage/emulated/0/Download/fluvi` with size, SHA-256 and source identity proof. | Actions run/artifact/hash | NOT DONE |
| MYHR-14 | §24–25 final state | refs/worktree/graph | Final canonical branch, remote, status, old branch/worktree absence, untracked-file preservation and final matching graph are all proven. | git/ref/hash checks | NOT DONE |
| MYHR-15 | §6/24 physical acceptance | user Android device | Human visual smoothness, direction-membership correctness, and final physical acceptance are made only by the user. | user test | PENDING — USER ONLY |

# Dashboard vertical LogBox pagination acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VLOG-01 | §§1, 35 | Git refs / frozen source | 3e61da2 milestone ref/tag exists; every frozen file hash remains unchanged | refs, SHA-256, `git diff 3e61da2 -- <paths>` | DONE (baseline) |
| VLOG-02 | §§2–3 | paging controller, codec, render surface | Source-proven full-page publish/rail-cache boundary defect is documented | design call graph + controller regression | DONE |
| VLOG-03 | §§4–5, 27–30 | LogBox application/presentation | Rail preview cache and committed vertical cache have distinct canonical owners | ownership tests + source inspection | DONE |
| VLOG-04 | §§5, 18 | rail scene cache/core | Rail scene always uses at most preview page size for 1/24/94/1k rows and never prepares vertical text on rail settle | frozen hashes + full rail matrix + profile gate | PARTIAL (local rail matrix green; profile rerun pending) |
| VLOG-05 | §§6–10 | committed page/cache/render surface | Vertical scrolling is page-backed, virtualized, O(visible + overscan), and never layouts/formats/decodes in paint | cache/widget counter tests + source inspection | DONE |
| VLOG-06 | §§7–8, 11, 23 | page/cache owner | Keyset pages have stable identity; retained page/row/layout bounds, distance eviction and reload are explicit | cache/controller tests + report | DONE |
| VLOG-07 | §§9, 31 | vertical page preparation/painter | Page publishing is atomic; no avatar-only/text-less row or normal vertical cache miss | atomic cache and virtual-surface tests | DONE (automated) |
| VLOG-08 | §§12, 15–17 | cache/controller/scroll surface | No visible-row disappearance, no offset jump/shrink, true end cursor semantics, separate total/loaded/visible counts | regression/widget tests | PARTIAL (automated cache ordering is covered; physical scroll continuity remains) |
| VLOG-09 | §§13–14, 21–22 | paging controller/core coordination | One cursor has one in-flight request; stale results discard; rail motion has priority | unit/controller tests | DONE |
| VLOG-10 | §§19–20, 33 | fixtures/profile metrics | 24/94/658/1k/10k/50k/100k matrix records vertical page metrics and rail isolation | deterministic test/report matrix | PARTIAL (all size bounds/reachability are automated; physical UI/raster/RSS matrix is pending) |
| VLOG-11 | §26 | diagnostics | Vertical events, cache/memory/row state and miss taxonomy are bounded and reportable in profile | diagnostic/source review | DONE |
| VLOG-12 | §32 | end-to-end tests | 658 all reachable; 1k same-day row 1000; 10k/50k/100k random/last row reachable; back-scroll/reload/rapid/stale/rail overlap pass | integration/widget + scale harness | PARTIAL (deterministic cache/controller harness covers bounds, last row, back reload, stale/rail overlap; device scrolling remains) |
| VLOG-13 | §§24, 34 | all modified areas | No full list widgets/layout cache, paint fallback, rail cache expansion, physics change, DB replacement, or golden | diff/test inventory | DONE |
| VLOG-14 | §35 | verification | Relevant non-golden suite and Ubuntu analysis pass, including no rail-settle vertical layout regression | proot Flutter commands + GitHub profile gate | PARTIAL (317 Flutter tests and analyze green locally; profile rerun pending) |
| VLOG-15 | §35 | delivery | GitHub profile diagnostic APK builds, downloads to `/storage/emulated/0/Download/fluvi`, SHA-256/ZIP checks pass | Actions + local artifact check | NOT DONE |
| VLOG-16 | §§20, 35 | physical device | Physical vertical scroll and rail no-regression report meets targets | user device report | BLOCKED |

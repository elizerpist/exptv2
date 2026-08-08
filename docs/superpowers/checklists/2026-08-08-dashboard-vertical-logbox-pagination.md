# Dashboard vertical LogBox pagination acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VLOG-01 | §§1, 35 | Git refs / frozen source | 3e61da2 milestone ref/tag exists; every frozen file hash remains unchanged | refs, SHA-256, `git diff 3e61da2 -- <paths>` | DONE (baseline) |
| VLOG-02 | §§2–3 | paging controller, codec, render surface | Source-proven full-page publish/rail-cache boundary defect is documented | design call graph + red regression | DONE (root cause); regression NOT DONE |
| VLOG-03 | §§4–5, 27–30 | LogBox application/presentation | Rail preview cache and committed vertical cache have distinct canonical owners | ownership tests + source inspection | NOT DONE |
| VLOG-04 | §§5, 18 | rail scene cache/core | Rail scene always uses at most preview page size for 1/24/94/1k rows | rails tests/counters | NOT DONE |
| VLOG-05 | §§6–10 | committed page/cache/render surface | Vertical scrolling is page-backed, virtualized, O(visible + overscan), and never layouts/formats/decodes in paint | unit/widget counter tests | NOT DONE |
| VLOG-06 | §§7–8, 11, 23 | page/cache owner | Keyset pages have stable identity; retained page/row/layout bounds, distance eviction and reload are explicit | unit tests + report | NOT DONE |
| VLOG-07 | §§9, 31 | vertical page preparation/painter | Page publishing is atomic; no avatar-only/text-less row or normal vertical cache miss | widget/integration tests | NOT DONE |
| VLOG-08 | §§12, 15–17 | cache/controller/scroll surface | No visible-row disappearance, no offset jump/shrink, true end cursor semantics, separate total/loaded/visible counts | regression/widget tests | NOT DONE |
| VLOG-09 | §§13–14, 21–22 | paging controller/core coordination | One cursor has one in-flight request; stale results discard; rail motion has priority | unit/controller tests | NOT DONE |
| VLOG-10 | §§19–20, 33 | fixtures/profile metrics | 24/94/658/1k/10k/50k/100k matrix records vertical page metrics and rail isolation | deterministic test/report matrix | NOT DONE |
| VLOG-11 | §26 | diagnostics | Vertical events, cache/memory/row state and miss taxonomy are bounded and reportable in profile | diagnostic tests/source review | NOT DONE |
| VLOG-12 | §32 | end-to-end tests | 658 all reachable; 1k same-day row 1000; 10k/50k/100k random/last row reachable; back-scroll/reload/rapid/stale/rail overlap pass | integration/widget + scale harness | NOT DONE |
| VLOG-13 | §§24, 34 | all modified areas | No full list widgets/layout cache, paint fallback, rail cache expansion, physics change, DB replacement, or golden | diff/test inventory | NOT DONE |
| VLOG-14 | §35 | verification | Relevant non-golden suite and Ubuntu analysis pass | proot Flutter commands | NOT DONE |
| VLOG-15 | §35 | delivery | GitHub profile diagnostic APK builds, downloads to `/storage/emulated/0/Download/fluvi`, SHA-256/ZIP checks pass | Actions + local artifact check | NOT DONE |
| VLOG-16 | §§20, 35 | physical device | Physical vertical scroll and rail no-regression report meets targets | user device report | BLOCKED |

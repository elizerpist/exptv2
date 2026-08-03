# Dashboard LogBox acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LGB-01 | User §§1–5; Spendee source audit | mapping doc, tokens, group/row widgets | Audited Balance geometry is ported; Fluvi token/resolver owns color/icon/radius | source inspection + 10 golden states | DONE |
| LGB-02 | User §§6–10 | committed snapshot, coordinator | Exact committed query key/revision/facets bind summary metrics and LogBox; preview cannot rebind it | snapshot/coordinator/controller tests | DONE |
| LGB-03 | User §§11–14 | core read service, bridge/domain models | Local-date day group page is keyset paged, sorted and contains complete days with joined projections | Room test is compiled locally; clean execution awaits GitHub Actions Ubuntu | PARTIAL |
| LGB-04 | User §§15–17 | LRU cache/prefetch coordinator | Bounded data-only cache; final-target/tap prefetch is latest-wins and invisible | prefetch/cache/row-budget tests | DONE |
| LGB-05 | User §§18–20, 26–29 | log area state/coordinator | Explicit loading/data/empty/error states, stale rejection, guarded append, no retained old list | coordinator/widget tests | DONE |
| LGB-06 | User §§21–25 | main scroll/LogBox UI/projector | Sliver lazy rendering, stable group/row identity, preformatted models and central category badge | dense-day lazy widget test + goldens | DONE |
| LGB-07 | User §§30–33 | boundaries/debug | UI has no repository/SQL; coordinator owns cache/paging; structured deduplicated logs added | boundary script + diagnostic widget tests | DONE |
| LGB-08 | User §§35, 43 | presentation tests | Ten required visual states plus semantics are covered | 10 passing golden tests + widget semantics | DONE |
| LGB-09 | User §§36–39 | e2e/Room tests | Month/Day/Income consistency, open-close cache hit, stable paging and constant query count | Dart tests pass; in-memory Room execution awaits GitHub Actions Ubuntu | PARTIAL |
| LGB-10 | User §§40–42 | rail/perf tests | 100 preview ticks cause 0 LogBox query/rebind; physics unchanged; targeted rebuilds only | full 234-test Flutter suite + rail regression tests | DONE |
| LGB-11 | User §§41, 45 | profile notes/CI | 100/500/1000 row evidence, cold/cache timing and all required acceptance statuses | deterministic renderer evidence recorded; device profile and clean CI still pending | PARTIAL |

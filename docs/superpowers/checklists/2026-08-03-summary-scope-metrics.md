# Summary scope metrics acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCM-01 | User invariant | `query/domain`, metrics controller | Amount and count originate from one immutable `ScopeSummaryMetrics` value | Unit identity test | NOT DONE |
| SCM-02 | Parent/child mapping | navigation-to-metrics resolver | SUM/YEAR/MONTH, rail open/closed scopes resolve exactly as specified | Scope mapping tests | NOT DONE |
| SCM-03 | Preview semantics | metrics controller and child index | Preview child takes precedence and updates amount/count atomically with zero query work | 100-tick regression | NOT DONE |
| SCM-04 | Child index contract | Room service, bridge, Dart DTO | One grouped read yields child `SUM`, `COUNT`, canonical key, revision, and complete-index metadata | In-memory Room integration test | NOT DONE |
| SCM-05 | Zero/loading boundary | metrics controller | Missing bucket in a complete index is zero; cache miss is loading/stale and never parent fallback | Zero and cache-miss tests | NOT DONE |
| SCM-06 | Presentation boundary | SummaryPill and LogBox header | Both widgets consume one `SummaryMetricsPresentation` snapshot | Widget test | NOT DONE |
| SCM-07 | Diagnostics | metrics controller | Deduplicated `SUMMARY_METRICS_SELECTED` contains source, scope, key, revision, total, and count | Diagnostic test | NOT DONE |
| SCM-08 | Query regressions | query and rail tests | Preview starts 0 detailed queries; settled child starts exactly 1 | Controller integration tests | NOT DONE |
| SCM-09 | Physics regressions | existing carousel tests | Physics constants and fling outcome remain unchanged | Snapshot/regression suite | NOT DONE |
| SCM-10 | Delivery | repository and GitHub Actions | All checklist rows are DONE before push/build/download handoff | Checklist review and CI | NOT DONE |

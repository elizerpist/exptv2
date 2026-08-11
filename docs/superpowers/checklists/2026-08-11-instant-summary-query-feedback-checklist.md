# Instant Summary Navigation and Query Feedback Checklist

| ID | Source requirement | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SP-01 | Summary Pill must not wait for a full rail bank | `DashboardCoreController`, scene-window projection | Closed and open rail plane transitions require an O(1) first-frame publication window | Focused RED/GREEN controller tests | DONE |
| SP-02 | Preserve first fling and sibling continuity | Prepared-scene cache / rail interaction warmup | Every non-empty first-fling sibling has an exact scene and drawable rows | Deterministic scene-cache stress tests | DONE |
| SP-03 | No Query CTA count flash | `QueryMenuDataController`, `QueryMenuSheet` footer | Last confirmed numeric count stays visible while a latest-wins request is pending | Controller and widget tests with controlled completions | DONE |
| SP-04 | Apply dismisses immediately without stale publication | `FluviAppShell`, Query composer/core apply lifecycle | Accepted immutable draft begins slide-down in the originating UI turn; only latest accepted operation may publish | Shell/controller tests with blocked preparation | DONE |
| SP-05 | 2026 expense count is intentional | fluvi-core demo seed/read service | Income/expense counts for 2025, 2026, and all time exactly partition the seeded data | Kotlin core/SQL tests | DONE — GitHub clean Room and native bridge jobs passed |
| SP-06 | Protected architecture | Dashboard time navigation, paging, rail physics, Query ownership | No changes to physics, paging, SQL ownership, or applied-query ownership | Focused regression and boundary suites | DONE |
| SP-07 | Delivery | `query` GitHub Actions human APK workflow | Code commit is pushed, exact-sha workflow passes, human APK downloaded and SHA verified | GitHub run and local SHA-256 | DONE — human diagnostic APK for `5d29cc5` downloaded and SHA-256 matched the release |

# Dashboard time navigation acceptance checklist

This checklist is the implementation gate for the SummaryPill/TimeRail
hierarchical time-navigation work. The accepted user specification is the
source of truth; this file records the code owner and verification evidence.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DTN-01 | User §1, §6 | `time_navigation/domain` | SUM, YEAR, MONTH planes and typed `AllTimeScope`, `YearScope`, `MonthScope`, `DayScope` exist; date values are validated. | Domain unit tests | DONE — scope, plane, date and leap-year tests pass. |
| DTN-02 | User §6 | `time_scope_boundaries.dart` | Scope boundaries are half-open; persisted local-date semantics stay outside widgets. | Boundary/domain unit tests | DONE — AllTime/Year/Month/Day boundaries are tested; widgets contain no timezone arithmetic. |
| DTN-03 | User §3, §7–§11 | `DashboardTimeNavigationController` | Parent cursor, committed child, preview child, plane, rail visibility, promotion, month rollover and day clamping have one state owner. | State-transition tests | DONE — transition, promotion, demotion, clamp and rail-preservation tests pass. |
| DTN-04 | User §9 | time rail adapter/data-source factory | SUM uses generated years; YEAR uses cyclic months; MONTH uses cyclic days; the existing `CenteredCarousel` engine is reused without physics changes. | Adapter/source tests + source audit | DONE — mapping tests pass and the shared physics remains centralized. |
| DTN-05 | User §2, §18–§20 | SummaryPill interaction layer | Vertical axis changes plane, horizontal axis changes parent, chevron only toggles rail, and axis lock prevents diagonal double activation. | Widget gesture tests | DONE — vertical, horizontal and chevron-only tests pass. |
| DTN-06 | User §3, §15, §18 | query application layer | Closed rail selects parent scope; open rail selects committed child scope; preview never queries; settled/open/close changes query exactly once. | Query-controller tests | DONE — effective-scope and preview/settled wiring is tested through `DashboardCoreController`. |
| DTN-07 | User §4, §12, §14, §16 | query domain/data bridge | Direction + canonical time scope + future facets produce one immutable query key; summary and list read contracts share it; SQL/core remains the aggregation owner. | Query-key, bridge and Kotlin read tests | PARTIAL — Dart contract tests and Kotlin compile pass; the ARM64 local Room test runtime is blocked by missing Conscrypt JNI. |
| DTN-08 | User §14, §16, §17 | query coordinator | Distinct scope deduplication, latest-wins cancellation and revision-aware summary cache are implemented. | Coordinator/cache tests | DONE — deduplication, stale-result, 36-entry cache and revision/refresh behavior are covered. |
| DTN-09 | User §11, §15, §20 | SummaryPill presentation | Label/plane/amount/loading/error come from a view model; no hardcoded `Aktuális hónap`; amount corresponds to the committed effective scope. | Presenter/widget tests | DONE — presenter tests and gesture/widget coverage pass; compatibility fallback retains the old primitive-test API only. |
| DTN-10 | User §5 | controller/rail lifecycle | Plane changes swap data sources and center the valid child without initial haptic or visible jump; existing carousel tap-retarget, haptic and rebase behavior remains unchanged. | Carousel regression tests + source diff audit | DONE — silent center transition and all existing carousel regression tests pass. |
| DTN-11 | User §24 | docs/specs | Dashboard UI spec and core foundation document the SummaryPill → TimeRail → CurrentQueryScope relationship and preview/settled semantics. | Direct document inspection | DONE — both documents and this checklist are updated. |
| DTN-12 | Structuring Apps | boundary tests | Domain/application/presentation/data dependencies remain directional; no widget owns repository/DAO/query workflow; shared carousel physics remains single-source. | Boundary suite | DONE — boundary script/test pass; presentation remains storage-free. |

## Current baseline

- `DashboardSummaryPill` is a view-model-driven navigation projection with
  axis-locked plane/parent gestures and a chevron-only rail intent.
- `DashboardTimeNavigationController` owns plane, parent cursor, child
  committed/preview selection and plane-specific data-source mapping.
- `FluviLedgerReadService` owns SQL timeline/total aggregation; the Android
  MethodChannel adapter sends one canonical scope for both results.
- The existing `CenteredCarousel` physics/controller behavior remains intact;
  only silent child recentering was added for data-source transitions, with no
  haptic/settled emission.

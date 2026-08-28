# Dashboard cache-independent hardening checklist

Source: user follow-up prompt of 2026-08-28, Fluvi Logs revision 48, and
Android screenshots `Screenshot_20260828-191823.png`,
`Screenshot_20260828-191827.png`, and `Screenshot_20260828-192125.png`.

| ID | Requirement / evidence | Intended owner | Acceptance and verification | Status |
| --- | --- | --- | --- | --- |
| CACH-01 | Live frame is temporal truth; scene coverage is only LogBox render resource. | `DashboardLiveInteractionCoordinator` + typed Budget projection | One immutable generation/scope/target input exists; a direction tap changes the direction owner in the same turn even while structural scene coverage is held. `dashboard_core_query_application_test`. | DONE |
| CACH-02 | Header, progress and partition must paint live scope on cache miss. | `DashboardBudgetPresentationController` | Same direct-turn data for warmed and forced-miss crossing; no I/O. `dashboard_budget_presentation_controller_test`. | DONE |
| CACH-03 | Rhythm must not wait for `DashboardVisibleFrame`. | `DashboardSpendingRhythmController` | DAY/MONTH/YEAR/SUM prepared projection changes immediately with live generation, including a retained old visible frame. `dashboard_budget_presentation_controller_test`. | DONE |
| DIST-01 | `foregroundInputMotion -> return` must not retain old Card2 scope. Logs rev 48: cold 38–97 ms. | `CoreDashboard`, drawable controller | Cache hit/miss bind same current semantic distribution synchronously; exact scope only. `dashboard_budget_distribution_drawable_readiness_test`. | DONE |
| DIST-02 | Optional distribution hotset is bounded and preemptible. | drawable hotset scheduler | One/small measured grant per opportunity; input/generation supersedes it; stale work cannot publish. `dashboard_budget_distribution_drawable_readiness_test`. | DONE |
| LOG-01 | Avatar focus cache miss shows Category facet, amount, count and first rows without rich scene. | core focus first-viewport path | Withheld rich scene cannot retain old rows or block B/C/aggregate; category facet, amount, count, and first-row viewport identity are asserted before rich-scene release. `dashboard_core_ephemeral_focus_test`. | DONE |
| PROV-01 | Leaves report one generation under hot/cold crossings. | diagnostics | Debug-gated `BUDGET_LIVE_ANALYSIS_BOUND`, header, progress, partition and Rhythm have one-generation test evidence; distribution/first-view paths carry the same projection generation by direct code inspection. | DONE |
| RHY-01 | Partner rhythm real plot lane >=32dp, target ~40dp. Screenshot proves current lane ~16dp. | `SpendingRhythmBarChart` geometry | Named title/gap/plot/axis lanes; widget layout test at 190dp, 217dp and tall dimensions. | DONE |
| RHY-02 | Reserve rhythm first; shrink Partner donut/list, not Card2 or Category. | pure `BudgetPartnerDistributionLayout` | Resolved 110dp donut and 40dp plot at the 217dp reference Card2 height; compact legend and Category geometry remain covered by widget tests. | DONE |
| COLL-01 | No opaque grey slab through collapse/expand. Screenshot `191823`. | cascade/card hierarchy | Production Card2 opts into opaque-content clipping; 0/.25/.5/.75/1 raster and production-composition tests pass. | DONE |
| SUM-01 | Real colored SUM raster: green starts clockwise of top; 3/6 green; warning .75; danger .9; red reaches top. | SUM scale shader/painter | Pixel/raster samples on both colored styles plus marker-coordinate test pass. | DONE |
| REG-01 | Preserve live-interaction/search/query identities, fling, direct Category/Partner focus and LogBox identities. | regression suites | `scripts/test-fluvi-fast.sh`: 280 passing tests. | DONE |
| VERIFY-01 | Analyze, diff check, prescribed online Android CI and human APK. | verification | `flutter analyze --no-fatal-infos` clean (73.3s); `scripts/test-fluvi-fast.sh` 280 passing; GitHub Actions run `33213729885` for `6544b714fd0f4b858d117a441ba9a1e14aed7458` succeeded, including the A–J profile gate; downloaded `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_6544b71.apk`, SHA-256 `474d3cb94ea369301a314f6025f183242db05a44f39f4ae6384724c86e19a47e`. | DONE |
| VERIFY-02 | Physical Android acceptance. | human-device validation | Warm/cold, mixed input, rhythm, collapse and both SUM styles tested. | BLOCKED (no attached/ADB device yet) |

## Recorded root-cause evidence

- Revision 48 has equal navigation inputs that commit in `0 ms` on a cache hit
  and `38`, `46`, `48`, `60`, `61`, `79`, and `97 ms` after scene coverage on
  cold crossings.
- `CoreDashboard._onBudgetDistributionVisibleFrame` binds a cached drawable but
  explicitly returns on a cache miss while `foregroundInputMotion` is active.
  That leaves Card2 on the prior scope.
- `DashboardBudgetPresentationController` and
  `DashboardSpendingRhythmController` derive their scope from
  `DashboardVisibleFrame`, so they can also trail a live interaction frame.
- The screenshot's grey slab is a real opaque rectangular child in the Card2
  composition, not the transparent `DashboardCollapseHandle`.

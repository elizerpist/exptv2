# Committed Paging Identity Correctness Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CPI-01 | User root-cause report | `FluviLedgerReadService` identity projection | A `navigation` transport group yields only `all`, `year:`, `month:`, or `day:` as the structural dashboard time key. | Cloud Room identity tests | DONE |
| CPI-02 | User root-cause report | Shared core dashboard identity helper | Prepared frames and committed slices use the same canonical query-key construction. | Cloud Room parity test | DONE |
| CPI-03 | User root-cause report | Core SQL/read path | Query temporal groups stay separate as one `periods:` suffix and combine with navigation by AND. | Cloud Room query test | DONE |
| CPI-04 | User root-cause report | Flutter committed-page decoder | The strict scope identity guard remains enabled and accepts the ordinal-one response for a canonical scope. | Focused Dart codec test | DONE |
| CPI-05 | User root-cause report | `ExplicitCommittedPagingController` | A 156-entry month paged at 24 rows advances beyond ordinal zero without scope mismatch. | Focused paging-controller test | DONE |
| CPI-06 | User constraints | Dashboard motion/render systems | Rail physics, scroll physics, scene preparation, RailCriticalSceneBank and prepared-cache behavior are unchanged. | Diff inspection + 120-test fast suite | DONE |
| CPI-07 | User delivery request | GitHub Actions human build | The correctness commit is pushed, cloud build succeeds, and the ordinary human APK is downloaded to `Download/fluvi`. | GitHub Actions + local SHA-256 | DONE |

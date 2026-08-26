# Summary experiment and surface-customization acceptance checklist

Baseline: `separated-core-modes` at `70589bf32e1c7849eebbafcacdc2c65200ce1a91`.
Source inputs: current Fluvi source/tests, `MILESTONE_COMMITS.md`, Fluvi Logs
Drive revision `AIroW34nIJy1wCZ3BJSyKifmBnRgD2j88pFYc0CSogqG2oMe-ELTN5F6-texkowLLHnp9wtW-ghrXcWcOn1QCg`, and the read-only `spendeetest`
worktree at `144d78c30dc4cc5e9f230903fd6274c98e62e118`.

| ID | Source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CAT-01 | User Task A | `SummaryPillVariant`, host, tuner | Runtime catalog is exactly Legacy and Segmented; Swipe has no selectable production path. | Enum/menu/widget/architecture tests | DONE |
| CAT-02 | User Task A | docs | Current experiment documentation marks Swipe discarded but preserves historical records. | Doc review | DONE |
| SEG-01 | User Task B | navigation projection | Segmented MONTH wraps only within its current availability-aware year; no arithmetic carry changes YEAR. | Controller and physical selector tests | DONE |
| SEG-02 | User Task B | navigation projection | Segmented DAY cycles only in current valid year/month, including leap and restricted domains. | Controller tests | DONE |
| SEG-03 | User Task B | navigation projection | YEAR changes only the year; only calendar-validity reconciliation may change a hidden day. | Controller validity/isolation tests | DONE |
| SEG-04 | User Task B | centered-carousel adapter | Each field keeps real ballistic ticks and one-field gesture/haptic ownership; no per-pixel query work. | Widget/controller/boundary tests | DONE |
| CARD-01 | User Task C | dashboard presentation preference | Session-default ON Card2 chrome switch reaches Category and Partner pages without owning Budget state. | Tuner and pager tests | DONE |
| CARD-02 | User Task C | `BudgetDistributionPageCard` | OFF removes only Card2 surface/border/shadow while preserving bounds, padding, pager, controllers, drawable constraints, query and focus. | Widget/state identity tests | DONE |
| RND-01 | User Task D | central corner profile | One stepped dashboard-lifetime scalar maps each named surface family from exact current baseline to safe rounder endpoint. | Profile unit tests, 0/25/50/75/100 assertions | DONE |
| RND-02 | User Task D | shape leaves | Header shell+clip, content cards, directions, both SummaryPills, SearchPill, LogBox group ends and enabled Card2 consume the profile. | Widget/paint propagation tests | DONE |
| RND-03 | User Task D | LogBox paint path | Slider style update preserves committed index/query/extent and vertical controller/position identities; no TextPainter/query work. | Scene/viewport boundary test and source audit | DONE |
| PRS-01 | User | dashboard-level preference owners | Variant, body order, Card2 surface and roundness survive rebuild/mode switches without business/query resets. | Host/tuner preservation tests | DONE |
| REG-01 | MILESTONE | protected dashboard architecture | Budget preview amount, Legacy rail, Segmented rail reclaim, body-order geometry, one vertical scroll owner and bounded preparation remain unchanged. | Existing protected suites and diff audit | DONE |
| DOC-01 | User | experiment docs | Active documentation accurately records two variants, independent spinner policy and tunable presentation controls. | Doc review | DONE |
| DEL-01 | Global delivery workflow | GitHub Actions artifact | Pushed production SHA has a successful human diagnostic APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256. | Exact workflow/artifact evidence | NOT DONE |

## Architecture card

| Concern | Existing owner to extend | Write path | Explicit non-owner |
| --- | --- | --- | --- |
| Active SummaryPill variant | `SummaryPillVariantController` | tuner → controller → Summary host | temporal/query state |
| Segmented component projection | `DashboardTimeNavigationController` through `DashboardPresentationController`/`DashboardCoreController` | discrete carousel tick → canonical candidate → existing prepared selection bridge | widget-local date state |
| Card2 chrome | new dashboard-lifetime presentation controller | tuner → controller → pager shell | Budget selection, page and query controllers |
| Roundness | new dashboard-lifetime presentation controller + central profile | tuner → scalar → shape leaves / LogBox paint input | layout resolver, data/query pipeline |

The generic `CenteredCarousel`, prepared amount slot, prepared-index/visible-frame
pipeline, fixed Ledger geometry and body-order resolver are reused. Legacy keeps
its existing renderer and physical rail policy unchanged.

### Baseline-control note

`dashboard_scroll_milestone_test.dart`'s first vertical-ballistic diagnostic
assertion currently fails at both the task baseline `70589bf3` and this change:
the expected `VERTICAL_INTERACTION_PERF_SUMMARY` is absent before task code can
affect the direct LogBox-only harness. It was therefore not changed in this
presentation-focused task. The companion horizontal rail/query milestone and
all affected targeted scroll, scene-window, viewport and prepared-focus suites
pass on this branch.

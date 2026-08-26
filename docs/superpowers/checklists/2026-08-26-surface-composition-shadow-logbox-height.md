# Surface composition, shadow and LogBox-height acceptance checklist

Baseline: `separated-core-modes` at
`65031792b1428e798c54816433f5d51700fa7363`.

Source inputs: the user follow-up prompt, current Fluvi source/tests,
`MILESTONE_COMMITS.md`, Fluvi Logs Drive revision
`AIroW34nIJy1wCZ3BJSyKifmBnRgD2j88pFYc0CSogqG2oMe-ELTN5F6-texkowLLHnp9wtW-ghrXcWcOn1QCg`
(last modified 2026-08-24T22:17:38Z), current Android screenshots, and the
read-only `spendeetest` worktree at `144d78c30dc4cc5e9f230903fd6274c98e62e118`.

| ID | Source | Intended code owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCL-01 | Task A | `BudgetContentCardStyleController` | Catalog is exactly Split and Unified Card; default is Split and no diagram-cardless value remains. | Controller/tuner test | DONE |
| BCL-02 | Task A | Budget core surface/pager/card | Split preserves the background avatar rail plus one Card2 shell, geometry, pager and selected state. | Widget/identity test | DONE |
| BCL-03 | Task A | Central Budget content envelope | Unified uses exactly one shared outer shell, suppresses Card2 chrome, and preserves controller/query/focus state. | Widget/identity/geometry test | DONE |
| SHD-01 | Task B | central shadow controller/profile | Catalog is None/Current/Soft; default Current returns exact authored Fluvi shadows. | Profile regression test | DONE |
| SHD-02 | Task B | dashboard surface leaves/LogBox painter | None removes all controlled outer shadows; Soft uses documented Spendee-derived blurred family values and no hard foot. | Leaf/painter profile tests | DONE |
| LHB-01 | Task C | LogBox height controller/profile | Slider is stepped, default 0 equals baseline and max equals 1.5× baseline. | Profile endpoint test | DONE |
| LHB-02 | Task C | manifest/index/render/hit-test | One resolved row height controls rows, groups, dividers, hit RRects, scene/terminal extents and cache/paint identity. | Geometry matrix tests | DONE |
| LHB-03 | Task C | committed viewport cache/controller | A complete new geometry generation is atomically reconciled; old-height paint cannot overwrite it; text/data reuse remains bounded. | Generation test | DONE |
| LHB-04 | Task C | stable viewport | Row-height changes preserve one controller/position, valid/clamped pixels and query identity. | Scroll-owner test | DONE |
| COR-01 | Task D | compact corner settings/controller | Seven independent positions default to 0; changing one cannot mutate another. | Model/controller test | DONE |
| COR-02 | Task D | `DashboardCornerProfile` | Existing family endpoints, interpolation and geometry safety stay centralized. | Profile endpoint/safety test | DONE |
| COR-03 | Task D | shape leaves/custom painter | Each named family receives only its own radius; Header shell and animated clip match; Budget radius works in Split/Unified. | Widget/paint tests | DONE |
| TNR-01 | Task E | existing Header tuner | Accessible grouped controls change only their presentation setting and survive rebuild/mode switch. | Tuner/state test | DONE |
| REG-01 | Protected milestone | core/viewport/presentation | Budget preview amount, Legacy rail, Segmented reclaim, body order, SearchPill and prepared query path remain unchanged. | Existing regression suites/diff audit | DONE (the known direct-LogBox milestone harness failure was reproduced at the baseline and excluded per task instruction) |
| DOC-01 | Documentation | active customization docs | Documents superseded controls and new experimental presentation controls without declaring a winner. | Doc review | DONE |
| DEL-01 | Global delivery workflow | GitHub Actions artifact | Pushed production SHA completes human diagnostic APK; exact normal APK is downloaded under `/storage/emulated/0/Download/fluvi` and SHA-256 verified. | Workflow/artifact evidence | NOT DONE |

## Ownership boundary

| Concern | Reused owner | New/presentational responsibility | Explicit non-owner |
| --- | --- | --- | --- |
| Budget composition | `BudgetContentCardStyleController` | Split/Unified surface selection only | avatar, page, query and focus state |
| Shadows | central dashboard shadow profile | one family-aware style lookup | component-local shadow branches |
| Corners | `DashboardCornerProfile` | family-local normalized positions | layout/data/query state |
| LogBox height | committed geometry manifest + viewport cache | stepped height profile and atomic geometry generation | query/index/text formatting ownership |

All rows start `NOT DONE`; this checklist must be re-read before commit and
delivery.

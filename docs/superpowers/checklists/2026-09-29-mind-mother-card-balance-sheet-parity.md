# Mind Mother Card and Balance Sheet Parity Checklist

## Architecture card

| Concern | Owner | Single write/render path |
| --- | --- | --- |
| Seamless mother-card bounds | `DashboardHeaderContentMotherCardBounds` over `subheaderEnvelopeBounds` | Mind, settled Balance, settled unified Budget renderers |
| Balance Havi/Éves child allocation | `BalanceExtendedSheetLayout` plus Core principal geometry | `_BalanceExtendedSheetFrame` via `CoreDashboard` |
| HTML visual metrics | `BalanceAlternativeHtmlTokens` | Core geometry resolver input and extended-sheet child renderers |
| Havi/Éves values | existing `BalanceAlternative*Presentation` models | existing Balance projection path |

## Acceptance tracking

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MOM-01 | User, 2026-09-29; Mind surface | shared surface primitive + Mind/Balance/Budget | Mind is the authoritative lower-edge rule; settled Balance and unified Budget resolve the identical Header/body mother-card boundary, while their data and transitions retain ownership | widget geometry, boundary test, Balance/Budget goldens | DONE |
| MOM-02 | User, 2026-09-29 | shared Dashboard geometry consumers | The common Mother Card ends at the Mind envelope. Existing split-mode Budget avatar and indicator cascade remain in their own downstream lane rather than extending the Mother Card | mounted Budget bounds tests | DONE |
| SHEET-01 | HTML Havi 2; screenshot `061327`; user, 2026-09-29 | Core principal geometry + extended sheet minimum-size policy | Havi 2 typography, padding, insight region and daily plot use CSS-derived direct dimensions at 412×892; no card-wide scale-down | failing→passing widget test + 412×892 surface golden | DONE |
| SHEET-02 | HTML Éves; screenshot `061335`; user, 2026-09-29 | Core principal geometry + extended sheet minimum-size policy | Éves typography, legend, both charts and small cards use CSS-derived direct dimensions at 412×892; no card-wide scale-down | failing→passing widget test + 412×892 surface golden | DONE |
| REG-01 | Existing accepted Balance/Budget/Mind behavior | affected presentation and boundary suites | no projection, query, carousel, selection or split/cascade regression | focused Balance/Budget/widget/boundary suites; final analysis pending Actions build | PARTIAL |
| DEL-01 | Global Flutter delivery rule | GitHub Actions | production commit is pushed, exact human APK job succeeds, and the normal APK is downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256 | Actions + local digest | NOT DONE |

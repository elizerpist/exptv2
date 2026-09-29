# Restore Balance Child Layout Checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| RBL-01 | User instruction; SUM screenshot `081112` | `dashboard_content_card_height_policy.dart`, shared geometry | Current shared Mother Card height and lower edge remain unchanged for Mind, Balance and Budget. | Existing geometry matrix plus direct code inspection. | NOT DONE |
| RBL-02 | HTML prototype; pre-patch `685c534`; Havi screenshot `061344` | `balance_extended_sheet_layout.dart` | Havi uses Card 3 `70% x 60%`, Cards 4/5 stacked right at `30% x 30%`, and full-width combined bottom `100% x 40%`. | Failing-then-passing unit layout test and Havi golden inspection. | NOT DONE |
| RBL-03 | HTML prototype; pre-patch `685c534`; Éves screenshot `061349` | Balance extended card renderers/tokens | Éves restores its former child-card and chart composition inside RBL-02's fixed parent rectangle, without changing the Mother Card size. | Failing-then-passing focused widget/golden test and direct reference comparison. | NOT DONE |
| RBL-04 | User instruction | `budget_content_card_style.dart`, Budget surface | A fresh Budget controller opens in `unifiedCard`; Budget remains dot-free. | Focused controller and widget tests. | NOT DONE |
| RBL-05 | User instruction | `dashboard_geometry_resolver.dart` | Settled Mind and Budget action rows have the same padding below their equal Mother Card bounds. | Failing-then-passing geometry/widget comparison. | NOT DONE |
| RBL-06 | Global architecture rule | Balance layout, shared geometry, boundary tests | One outer-height owner, one Balance child-layout owner, and no new state or duplicate visual policy. | Boundary suite and source inspection. | NOT DONE |
| RBL-07 | Explicit visual acceptance | Android screenshots and HTML prototype | Havi, Éves, Mind, and Budget device screenshots match the accepted topology and spacing. | Fresh Android screenshots inspected. | NOT DONE |
| RBL-08 | Flutter delivery rule | GitHub Actions and Download folder | Application commit is pushed; exact human APK job succeeds; normal APK is downloaded and SHA-256 verified. | Actions/job log, local file check, `sha256sum`. | NOT DONE |

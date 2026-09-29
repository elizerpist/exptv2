# Restore Balance Child Layout Checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| RBL-01 | User instruction; SUM screenshot `081112` | `dashboard_content_card_height_policy.dart`, shared geometry | Current shared Mother Card height and lower edge remain unchanged for Mind, Balance and Budget. | Existing CCH geometry case and direct code inspection; no outer-height source changed. | DONE |
| RBL-02 | HTML prototype; pre-patch `685c534`; Havi screenshot `061344` | `balance_extended_sheet_layout.dart` | Havi uses Card 3 `70% x 60%`, Cards 4/5 stacked right at `30% x 30%`, and full-width combined bottom `100% x 40%`. | Failing-then-passing layout unit test and inspected Havi golden. | DONE |
| RBL-03 | HTML prototype; pre-patch `685c534`; Éves screenshot `061349` | Balance extended card renderers/tokens | Éves restores its former child-card and chart composition inside RBL-02's fixed parent rectangle, without changing the Mother Card size. | Focused widget/golden suite and inspected Éves golden; direct HTML comparison. | DONE |
| RBL-04 | User instruction | `budget_content_card_style.dart`, Budget surface | A fresh Budget controller opens in `unifiedCard`; Budget remains dot-free. | Focused controller test and dot-free surface boundary test. | DONE |
| RBL-05 | User instruction | `dashboard_geometry_resolver.dart` | Settled Mind and Budget action rows have the same padding below their equal Mother Card bounds. | Failing-then-passing `RBL-05` geometry test. | DONE |
| RBL-06 | Global architecture rule | Balance layout, shared geometry, boundary tests | One outer-height owner, one Balance child-layout owner, and no new state or duplicate visual policy. | Focused boundary suite and source inspection. | DONE |
| RBL-07 | Explicit visual acceptance | Android screenshots and HTML prototype | Havi, Éves, Mind, and Budget device screenshots match the accepted topology and spacing. | Fresh Android screenshots inspected. | NOT DONE |
| RBL-08 | Flutter delivery rule | GitHub Actions and Download folder | Application commit is pushed; exact human APK job succeeds; normal APK is downloaded and SHA-256 verified. | Actions/job log, local file check, `sha256sum`. | NOT DONE |

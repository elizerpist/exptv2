# Balance carousel reference-locked redesign acceptance checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RCR-01 | User “DO NOT CHANGE”; `carousel2.png` | `balance_dashboard_core_surface.dart` | Carousel physics, focus scales, external card bounds and row placement remain unchanged. | Existing geometry/engine tests and source inspection of the unchanged shared carousel adapter. | DONE |
| RCR-02 | `carousel2.png` card shell | `_BalanceCarouselCard` | Every mini card has rounded white shell, faint accent tint, fine coloured outline and soft shadow. | `RCR-RED-01` structural assertions and inspected golden. | DONE |
| RCR-03 | `carousel2.png` lower decorative field | private reference wave layer | Every mini card includes one subtle, clipped, lower-half decorative wave derived from its accent. | `RCR-RED-01` wave assertions and inspected golden. | DONE |
| RCR-04 | `carousel2.png` layout | reference metric/content renderer | Quiet title is top-left; compact icon tile top-right; primary/secondary lines occupy the lower-left lane with reference-relative spacing and bounded ellipsis. | `RCR-RED-01` geometry assertions and inspected golden. | DONE |
| RCR-05 | `carousel2.png` selected centre card | selected mini-card decoration | Centre emphasis uses the same tint/border language with only restrained additional strength. | `RCR-RED-01` compares selected and neighbouring outline strengths; golden inspected. | DONE |
| RCR-06 | Global architecture rules | renderer and category visual dependencies | Immutable presentation data, existing category palette/badge, and existing shared carousel remain the only owners; no repository/Query/gesture duplication is added. | Dependency/source audit, `BX6`, focused suite and analyzer. | DONE |
| RCR-07 | User delivery rules | branch, CI, APK | All production changes are committed, pushed, verified through the exact SHA’s normal human diagnostic APK job, and the APK is downloaded with SHA-256. | `743311f6…`; Actions run `36260528417` human job PASS; downloaded APK SHA-256 and embedded build SHA verified. | DONE |

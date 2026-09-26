# Balance carousel reference-locked redesign acceptance checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RCR-01 | User “DO NOT CHANGE”; `carousel2.png` | `balance_dashboard_core_surface.dart` | Carousel physics, focus scales, external card bounds and row placement remain unchanged. | Existing geometry/engine test and source inspection. | NOT DONE |
| RCR-02 | `carousel2.png` card shell | `_BalanceCarouselCard` | Every mini card has rounded white shell, faint accent tint, fine coloured outline and soft shadow. | Widget structure assertions and golden inspection. | NOT DONE |
| RCR-03 | `carousel2.png` lower decorative field | private reference wave layer | Every mini card includes one subtle, clipped, lower-half decorative wave derived from its accent. | Widget test and golden inspection. | NOT DONE |
| RCR-04 | `carousel2.png` layout | reference metric/content renderer | Quiet title is top-left; compact icon tile top-right; primary/secondary lines occupy the lower-left lane with reference-relative spacing and bounded ellipsis. | Geometry widget test and golden inspection. | NOT DONE |
| RCR-05 | `carousel2.png` selected centre card | selected mini-card decoration | Centre emphasis uses the same tint/border language with only restrained additional strength. | Selected-card golden and source inspection. | NOT DONE |
| RCR-06 | Global architecture rules | renderer and category visual dependencies | Immutable presentation data, existing category palette/badge, and existing shared carousel remain the only owners; no repository/Query/gesture duplication is added. | Dependency/source audit and existing boundary checks. | NOT DONE |
| RCR-07 | User delivery rules | branch, CI, APK | All production changes are committed, pushed, verified through the exact SHA’s normal human diagnostic APK job, and the APK is downloaded with SHA-256. | Git, Actions and artifact verification. | NOT DONE |

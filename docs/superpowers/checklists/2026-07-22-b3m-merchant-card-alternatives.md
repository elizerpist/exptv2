# B3M Merchant Card Alternatives - Acceptance Checklist

Reference artifact: `balance_latest_layout.html` first B3M-A test screen and
the B3M canvas below it.

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MER-001 | User clarification, 2026-07-22 | `balance_latest_layout.html` B3M canvas | A new merchant-alternatives row is below the B3M carousel, containing exactly four card-sized alternatives side by side. It contains no full phone screen. | DOM/static contract and screenshot | NOT DONE |
| MER-002 | User clarification, 2026-07-22 | Merchant-alternatives row | The row is not a new carousel: it has no dedicated horizontal overflow, scroll-snap, swipe handler, or test-screen navigation. | Static interaction contract | NOT DONE |
| MER-003 | User request + FastInfo resolver | Merchant fixture and card renderers | Every card uses Lidl, 8 transactions, 14-day scope, 5 active days, 31 640 Ft, and Élelmiszer only. The visual fixture has 14 points, total 8, and 5 active days. | Static data assertion and source review | NOT DONE |
| MER-004 | User request | Merchant-card visual variants | The four card treatments are visibly distinct while all top-level surfaces remain cards; inner boxes are allowed. | Screenshot review | NOT DONE |
| MER-005 | User clarification, 2026-07-22 | Existing B3M-A detail carousel | This pass does not insert a merchant page into the existing detail carousel. After a user selection, exactly one chosen design is eligible for that existing carousel and inherits its swipe behavior. | DOM/static contract | NOT DONE |
| MER-006 | User scope | Flutter/Pulse boundaries | No Flutter resolver/catalog or pulse-engine files are modified by this prototype comparison. | Git diff review | NOT DONE |
| MER-007 | User request | Delivery | The linked local HTML remains available at port 8790. | HTTP 200 check | NOT DONE |

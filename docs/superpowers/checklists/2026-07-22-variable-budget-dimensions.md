# Variable Budget Dimensions - Acceptance Checklist

Reference artifact: `balance_latest_layout.html` B3M-A lower `Napi változó keret` detail card and the approved Stage2 screenshot.

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BUD-001 | User request, 2026-07-22 | Existing B3M-A lower budget detail | One existing detail card becomes `Változó keret` with native `Napi`, `Heti`, `Havi` controls; no new detail carousel child is added. | Static DOM contract and visual screenshot | NOT DONE |
| BUD-002 | User request | Napi view | Napi is initially selected and preserves the existing daily remaining amount, daily spent amount, daily expense count, and daily progress bar. | Evaluated fixture/helper and renderer contract | NOT DONE |
| BUD-003 | User request | Heti view | Heti renders weekly remaining budget, 46 800 Ft weekly spent, 17 weekly expense transactions, and the weekly budget progress bar in the daily layout. | Evaluated fixture/helper and renderer contract | NOT DONE |
| BUD-004 | User clarification: `havi tranzakciódarab legyen` | Havi view | Havi renders monthly remaining budget, monthly spent amount, a visible monthly transaction count, and monthly budget progress in the same layout. | Evaluated fixture/helper and renderer contract | NOT DONE |
| BUD-005 | User request | Shared layout | Each selection updates one already-mounted card's labels, values, ARIA state, and progress custom property while preserving the cart tile, dividers, fact grid, and progress bar. | Static interaction contract and visual screenshot | NOT DONE |
| BUD-006 | User constraint: do not delete old screens | Legacy cards | `heti_koltes` and `havi_koltes` catalog data and their upper-carousel presence remain intact. | Static preservation contract | NOT DONE |
| BUD-007 | User constraint | Interaction boundary | No extra carousel/swipe listener is created, and legacy rhythm/comparison details are not moved or removed. | Static absence/preservation contract and visual screenshot | NOT DONE |
| BUD-008 | User scope | Boundaries | No Flutter resolver/catalog or Pulse-engine file changes are made. | Targeted diff review | NOT DONE |

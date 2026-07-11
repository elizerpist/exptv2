# Sum Mode Page 1 YearCards Acceptance Checklist

Reference HTML: `docs/prototypes/stats_common_2025_final_0710.html`

Working HTML: `docs/prototypes/stats_sum_mode_page1_yearcards.html`

Scope: this is only Sum mode Page 1. It must remain a 100% common Page 1 copy for the accepted header, FastInfo chart, magnet, scope selector, threshold slider/manual input, score functions, graph functions, and live coloring. The only intended visible content change is replacing month cards with year cards that contain month cells.

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUM-YEAR-01 | User: "100% copyt akarok... ez csak a page 1" | Prototype shell | The sum HTML is based on `stats_common_2025_final_0710.html`; header, FastInfo SVG area, type buttons, scope selector, controls, slider, and manual threshold input remain unchanged in structure and styling | Static test comparing reference snippets + file inspection | DONE |
| SUM-YEAR-02 | User: "a függvények, a slider, a grafikon pixelre egyezzen" | JS graph/slider functions | The accepted FastInfo/chart/header/slider functions remain present and keep their original calculation/rendering code; only the data source is extended to multiple years and the card renderer is replaced | Static test comparing key function snippets + code inspection | DONE |
| SUM-YEAR-03 | User: "month cardok helyett évcardok" | Card grid | The old month-card renderer is replaced by `drawYearCards`; the grid renders year cards, not month cards | Static test + HTTP inspection | DONE |
| SUM-YEAR-04 | User: "az évcardokban pedig hónapcellák vannak" | Year card cells | Each year card contains 12 month cells with month labels and threshold-aware live heat coloring | Static test + code inspection | DONE |
| SUM-YEAR-05 | User: "legalább 10 évre" | Test transaction database | The prototype builds transactions for at least 10 years, and every transaction has a `year` field | Static test + code inspection | DONE |
| SUM-YEAR-06 | User: "tesztelni lehessen" | Interactions | Tapping a year card changes the active year; existing graph, magnet, slider max, header score, and year card coloring recompute from that active year and current category/threshold scope | Static test + code inspection | DONE |
| SUM-YEAR-07 | User: "élő színezést akarok látni" | Live coloring | Month cells in year cards use the same active scope color rule: single category uses the category color, multi/all uses the heatmap color, and threshold changes hide/show cells dynamically | Static test + code inspection | DONE |
| SUM-YEAR-08 | User: "a cellák szélesség magasság aránya egyezzen a napcellákkal, de a szélesség marad, azaz a magasaága nő"; superseded by "nem jó, túl magas, túl nagy, most 3 ,soros layoutot tervezz" | Year card cell geometry | Superseded: the too-tall 3-column/4-row layout is removed | Static test + CSS inspection | DONE |
| SUM-YEAR-09 | User: "nem jó, túl magas, túl nagy, most 3 ,soros layoutot tervezz"; superseded by "2x6" | Year card cell geometry | Superseded: the 4-column by 3-row layout is removed | Static test + CSS inspection | DONE |
| SUM-YEAR-10 | User: "2x6"; superseded by "2 sor 6 oszlop" | Year card cell geometry | Superseded: the 2-column by 6-row layout is removed | Static test + CSS inspection | DONE |
| SUM-YEAR-11 | User: "2 sor 6 oszlop"; superseded by "fele ekkora cellamagasság" | Year card cell geometry | Superseded: the 6-column by 2-row layout remains, but the original common card height is no longer required | Static test + CSS inspection | DONE |
| SUM-YEAR-12 | User: "fele ekkora cellamagasság"; superseded by "50% magasabb cellák" | Year card cell geometry | Superseded: the 58px month-cell grid is increased by 50% | Static test + CSS inspection | DONE |
| SUM-YEAR-13 | User: "50% magasabb cellák"; superseded by "20% alacsonyabb cellák" | Year card cell geometry | Superseded: the 87px month-cell grid is reduced by about 20% | Static test + CSS inspection | DONE |
| SUM-YEAR-14 | User: "20% alacsonyabb cellák" | Year card cell geometry | Year-card month cells keep the 6-column by 2-row layout, with the month-cell grid reduced from 87px to 70px and card height adjusted accordingly | Static test + CSS inspection | DONE |
| SUM-YEAR-15 | User: "sum mode grafikonjai adaptóvak, nem a hónapokat írják, hanem az évwket" | FastInfo graph x-axis | Sum mode FastInfo graphs use an adaptive yearly graph source built from all year cards; x-axis labels are years, not month names | Static test + code inspection | DONE |
| SUM-YEAR-16 | User: "az évcellák szélességét úgy állítsd, hogy köztük a padding annyi legyen, mint a napcelláké az éviben" | Year card cell spacing | Year-card month cells keep the 6-column by 2-row layout, but remove grid gap so the visible spacing between colored cells is produced by the same `inset: 1px` rule used by day cells | Static test + CSS inspection | DONE |
| SUM-YEAR-17 | User: "mi lesz az x tengellyel, ha 20 év van?" + "rakd bele" | FastInfo graph x-axis | The prototype uses 20 years of test transactions and thins x-axis year labels adaptively: all data points remain, but 20-year charts show first/last plus 5-year ticks instead of every year label | Static behavior test + code inspection | DONE |

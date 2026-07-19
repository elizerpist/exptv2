# Spendee Mind D1-D5 Design

## Source Of Truth

- `docs/prototypes/color_lab.html:417-542`: Mind header colors, D1 font lockup variables.
- `docs/prototypes/color_lab.html:1787-1821`: D1 strong header glass and soft logbox glass attributes.
- `docs/prototypes/color_lab.html:2168-2412`: common stage1/stage2 glass container geometry.
- `docs/prototypes/color_lab.html:2806-2925`: D1 score ribbon and D stage merged income/expense graph shells.
- `docs/prototypes/color_lab.html:3262-3385`: D2 boxed graph layout and mini graph cards.
- `docs/prototypes/color_lab.html:4034-4215`: score, income/expense, helper bar graph CSS.
- `docs/prototypes/color_lab.html:14135-14255`: D3/D4/D5 heatmap markup sources.
- `docs/prototypes/color_lab.html:14315-14483`: D3G, D4, D5, D5G screen clone behavior.
- `docs/prototypes/color_lab.html:14617-14623`: stage2 graph panel presentation rule.

## Design

The existing Budget header remains the default. A new Mind D header background mode adds five horizontal pages: D1, D2, D3G, D4, and D5. A horizontal swipe on the header background loops through these pages in both directions. Vertical handle dragging keeps the existing three Flutter stages: `stage0`, `stage1`, and `stage2`.

Mind D content uses the Color Lab mapping. D1 supplies the static header background, strong glass shell, and compact score ribbon. D2 supplies the stage1 boxed graph layout. Stage2 content follows the active summary pill: monthly shows D4 monthly heatmap, yearly shows D3G yearly separated-glass heatmap, and all-time/sum shows D5 summary heatmap. The visible D page label still advances with horizontal swipe so the background can be inspected independently.

All Budget and Mind containers use the same surface vocabulary: no/background, old/original glass, C2 CSS glass, liquid glass, and Acrylic. Each configurable surface family gets its own softness value so changing one slider does not alter another container.

Mind charts are live. A small adapter builds `StatsRenderFrame` instances from the existing `TransactionStore`, using the store period, active filters, categories, vendors, query, and the existing default Stats threshold. The score chart reads `StatsCategoryScopeSeries.scoreLine` and `kontrollScore`; income/expense volume reads `incomeComparisonBars`; pattern/helper bars read `helperBars`; heatmaps read `StatsYearData.graphMonths`, `months`, and `sumYearSummaries`.

## Verification

Widget tests cover menu options, D page swipe looping, summary-window stage mapping, scoped softness sliders, and the absence of header pink/purple shadow. Data tests cover the adapter mapping for monthly/yearly/sum scopes, expense score/helper data, income score/comparison data, and filtering.

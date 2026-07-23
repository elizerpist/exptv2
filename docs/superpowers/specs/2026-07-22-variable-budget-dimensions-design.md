# Variable Budget Dimensions Design

## Goal

Turn the existing B3M-A lower `Napi változó keret` detail card into one
`Változó keret` card with native `Napi`, `Heti`, and `Havi` in-place views.
The three views keep the daily card's existing composition: remaining budget,
spent amount, expense-transaction count, and the same budget progress bar.

## Approved scope

- The selector lives in the existing lower B3M-A detail card. It does not add
  a carousel page, a swipe surface, or an upper-carousel screen.
- `Napi` is the initial state and retains today's existing content.
- `Heti` shows `A héten még elkölthető`, `Héten elköltve`, `Heti kiadási
  tételek`, and `Heti költés a kerethez képest` in that same card layout.
- `Havi` mirrors the same anatomy with the corresponding monthly labels,
  including a visible monthly expense-transaction count.
- The separate legacy `Heti költés` and `Havi költés` catalog cards/screens
  remain unchanged. Their rhythm and comparison information is deliberately
  retained unchanged in this iteration.

## Data model

Add a scoped `variableBudgetDimensionFixture` and a pure resolver for three
periods. The new card never reparses display text from the legacy catalog
cards.

| Dimension | Remaining | Spent | Transactions | Budget | Progress presentation |
| --- | ---: | ---: | ---: | ---: | --- |
| `day` | 6 500 Ft | 8 900 Ft | 4 db | 15 400 Ft | daily ratio and existing 30-day daily average |
| `week` | 18 200 Ft | 46 800 Ft | 17 db | 65 000 Ft | 72% weekly budget use |
| `month` | 98 800 Ft | 151 200 Ft | 79 db | 250 000 Ft | 60.48% bar ratio; retained 61% legacy label |

The monthly transaction count is an explicit prototype fixture because the
current monthly FastInfo catalog has no raw monthly transaction-count source.
The fixture must preserve the visible legacy monetary values. The resolver
validates positive budget/count values, non-negative spend/remaining values,
and returns a calculated numeric progress rounded to two decimals plus a presentation label. The
monthly bar uses the exact 151 200 / 250 000 ratio while the displayed label
stays `61%` to preserve the legacy monthly-card wording.

## Card interaction and accessibility

- Header title: `Változó keret`.
- Header control order: `Napi`, `Heti`, `Havi`.
- Each option is a native `button type="button"`; only the selected button has
  `aria-pressed="true"`.
- A click updates only the already-mounted card: its `data-variable-budget-
  dimension`, ARIA label, remaining copy/value, fact grid, progress text, and
  progress-bar custom property.
- The cart tile, dividers, fact-grid layout, and threshold/progress-bar markup
  are retained rather than duplicated into separate per-period cards.

## Non-goals and boundaries

- Do not delete, hide, rename, or repurpose the current upper-carousel
  `heti_koltes` or `havi_koltes` cards.
- Do not migrate rhythm, comparison, or other extra legacy information into
  the new selector in this iteration.
- Do not change Flutter resolver/catalog files, Pulse-engine files, or the
  B3M-A detail-carousel swipe behavior.

## Verification

The Node static contract must first fail for the absent three-dimensional
fixture/selector, then evaluate each summary's values and progress. It must
check the native button/ARIA update contract, one in-place card renderer, the
preserved progress markup, and the continued presence of both legacy cards.
Inline script parsing, HTTP 200 from the linked page, a targeted diff check,
and a non-disruptive visual screenshot when available are required.

# B3M Top 5 Merchants Dimension Switch Design

## Goal

Keep one `Top kereskedők` page in the existing B3M-A lower detail carousel,
but turn its header into a testable dimension selector. The visible title is
`Top 5 kereskedő`; the header provides `Éves`, `Havi`, and `Összesen`
buttons, with `Havi` selected on first render.

## Approved interaction

The approved solution is an in-place segmented control, not a cosmetic state
change and not three separate carousel pages.

- The three native `<button type="button">` controls share one header rail.
- `Havi` is selected initially and exposes `aria-pressed="true"`.
- A click on `Éves`, `Havi`, or `Összesen` updates the selected button,
  the card's dimension state, the accessible card label, and all five visible
  merchant rows without reloading the screen.
- The card remains one child of the existing
  `.stage2-redesign-detail-carousel`; the selector adds no carousel, swipe
  listener, or new detail page.

## Data model

`allTransactionMerchantFixture` becomes a flat, date-stamped transaction
input. Every raw record has a merchant, absolute or signed amount, icon,
avatar color, and ISO calendar date.

The dimension resolver is anchored to the prototype's current month and year:

| Dimension | Included records |
| --- | --- |
| `Havi` | Records in July 2026 |
| `Éves` | Records in calendar year 2026 |
| `Összesen` | Every fixture record, including earlier years |

For every active dimension, the renderer groups raw transactions by merchant,
orders groups by descending transaction count, then descending absolute summed
amount, then merchant name, and takes exactly five. Thus a button press
changes real count, amount, and potentially ranking data, rather than only its
visual pressed state.

## Card anatomy and visual behavior

- Header left: `Top 5 kereskedő`.
- Header right: a compact three-button segmented control in the existing
  white-card visual family. It fits in the current 210px detail-card height.
- The selected segment is visibly filled and has `aria-pressed="true"`; the
  other two are quiet, tappable buttons with `aria-pressed="false"`.
- The existing divider and five compact Top-categories-style rows stay in
  place. Every row contains only avatar, merchant name, `N tranzakció`, and
  aggregate HUF amount.
- The card's ARIA label names the active dimension so a screen-reader user can
  verify the state after a click.

## Implementation boundaries

- Modify only `balance_latest_layout.html`,
  `docs/prototypes/balance_stage2_mother_child_gallery_static_test.js`, and
  this task's plan/checklist/spec documentation.
- Keep Flutter resolver/catalog and all Pulse-engine files untouched.
- Reuse the existing B3M-A detail-carousel and its swipe behavior.
- Do not alter the other three lower carousel pages.

## Verification

The static Node contract must evaluate the three dimension summaries, verify
the `Havi` default, verify title/button/ARIA markup, and verify a click handler
updates both button state and row rendering. It must also retain the existing
no-extra-carousel and removed-sample guarantees. Inline script parsing and
HTTP 200 remain required. A visual screenshot is required for full visual
acceptance when a non-disruptive browser capture route is available.

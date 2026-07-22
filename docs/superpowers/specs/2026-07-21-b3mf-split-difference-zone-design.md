# B3M-F Split Difference Zone Design

## Scope

Add one focused `koltesi_trend` Stage2 alternative, `B3M-F`, to the existing
Balance mother-child gallery. It retains the actual Color Lab B3M shell and
changes only the inner child-panel content.

## Data Contract

- Current rolling 30-day variable spending: `191 200 Ft`.
- Previous rolling 30-day variable spending: `162 000 Ft`.
- Difference: `+29 200 Ft`, `+18%`.
- Fixed, repeating, and scheduled entries remain excluded.
- The visual is derived from both rolling-window totals, not from a signed
  delta scale.

## Panel Anatomy

1. The primary block is the existing B3M-A red delta container, with the
   label `Eltérés a két ablak között`, the amount `+29 200 Ft`, and `+18%`.
2. All three existing B3M secondary facts follow: current 30-day total,
   previous 30-day total, and fixed exclusion.
3. The final, bottom block is `Eltérés zónája`: one two-period composition
   stripe.

## Split Zone Behavior

- The stripe's `100%` is `previous + current = 353 200 Ft`.
- Left segment: previous period, gray, `162 000 / 353 200 = 45.87%`.
- Right segment: current period, `191 200 / 353 200 = 54.13%`.
- The right segment is green if current spending is lower than previous,
  red if it is higher, and neutral if they are equal.
- The stripe is `8px` high. The previous-period gray is light, and a two-sided
  legend directly below identifies `Előző 30 nap` on the left and
  `Aktuális 30 nap` on the right.
- There is no centered scale, threshold tick, marker, axis, or second bar.

## Visual Constraints

- Reuse the B3M source phone, header, Stage1 belt, panel, source variables,
  type scale, and zoom behavior.
- Reuse the B3M-A delta container class rather than recreate a red card.
- Use a scoped B3M-F zone layout only for the final single composition stripe.
- Do not show the generic avatar, generic SVG trend, daily bars, a line chart,
  centered scale, threshold tick, marker, axis, or a second bar.

## Verification

- Static test verifies a B3M-F sibling is appended after B3M-E.
- Static test verifies the B3M-A delta container and all B3M fact rows are
  reused, and no unrelated generic child anatomy is retained.
- The period-share helper is verified for the exact `45.87% / 54.13%` split
  and the `353 200 Ft` combined total.
- Inline script syntax, HTTP `200`, and browser refresh verify delivery.

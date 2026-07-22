# B3M Merchant Card Alternatives Design

## Goal

Show several visual alternatives for the existing `Leggyakoribb kereskedő`
FastInfo metric directly below the B3M gallery. The alternatives are a design
comparison surface only. After the user chooses one, that single design may be
added as a page to B3M-A's existing lower detail carousel.

## Approved layout decision

- Add one new row below the primary B3M carousel in
  `balance_latest_layout.html`.
- Render four card-sized alternatives side by side on the existing Color Lab
  zoom canvas. Each is approximately the width and height of an in-screen
  lower-detail card, not a complete phone screen.
- Do not create a second carousel, horizontal scroll container, or swipe
  handler for this row. The existing zoom canvas remains responsible for
  viewing the side-by-side gallery.
- Do not add any merchant card to B3M-A's current lower detail carousel in
  this pass. That happens only after one alternative is selected.

## Data contract

Every alternative presents the existing merchant metric only:

- merchant: `Lidl`;
- frequency: `8` transactions in the last `14` days;
- active days: `5`;
- variable-expense total: `31 640 Ft`;
- category: `Élelmiszer`.

The Flutter resolver already exposes the production 14-day activity sequence
as `metric.visual.points`. The prototype may use a clearly labelled,
sum-consistent visual fixture while it is still a test screen. It must contain
14 points, sum to 8 transactions, and have exactly 5 active days. It must not
claim an unmodelled latest purchase, transaction value, or merchant ranking
evidence.

## Four comparison cards

1. **Aktivitási sáv** — a calm 14-day strip with per-day frequency height,
   plus the `5 aktív nap` and total-spend facts.
2. **Visszatérési térkép** — a five-day activity map that makes repeat visits
   immediately scannable, with the category avatar as the identity anchor.
3. **Gyakoriság fókusz** — `Lidl · 8×` is the large value; compact inner boxes
   carry active-day count, total spend, and derived average per visit.
4. **Költési ritmus** — a denser, receipt-like day ledger whose marks still
   derive only from the activity points, not invented purchase facts.

All four outer surfaces are cards. Some use inner information boxes so the
comparison covers both requested visual treatments without adding non-card
top-level elements.

## Future selection path

The chosen design will become one full-width
`.stage2-redesign-top-merchant-detail` sibling of the existing
`.stage2-redesign-detail-carousel` pages. It will inherit that carousel's
native horizontal swipe, scroll-snap, collapse state, and touch containment.
The other three comparison cards will remain gallery-only references and will
not be shipped into the B3M-A screen.

## Scope boundaries

- Keep the supplied B3M-A screenshot and its current carousel pages intact.
- Do not change Flutter FastInfo resolver, catalog, or pulse-engine work.
- Do not create a complete phone shell for any merchant alternative.
- Do not add a new independent interactive surface.

## Verification

- Extend the Node static contract with row topology, four-card count,
  non-carousel interaction, and fixture consistency checks.
- Run the static test and JavaScript syntax check.
- Confirm the linked page returns HTTP 200.
- Review a current browser/Android screenshot of the B3M canvas before marking
  visual requirements done.

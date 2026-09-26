# Reference-locked Balance carousel mini-card redesign

## Scope and sources

- User requirement: redesign only the internal visual presentation of the
  Balance-mode mini carousel cards.
- Source of truth: `/storage/emulated/0/spendee/reference/carousel2.png`,
  inspected directly on 2026-09-26.
- Existing implementation: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`, especially `_BalanceCarouselCard`, `_BalanceCarouselMiniCardVisualSpec`, `_BalanceCarouselMiniCardContent`, and `_BalanceCarouselVisual`.
- Existing verification: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart` and `test/goldens/balance_carousel_canonical_layout.png`.

## Reference contract

The reference has one visual grammar for all three mini cards:

- a white rounded shell with an accent-tinted lower field, a fine accent
  outline, restrained elevation, and a soft lower-half wave;
- a quiet title at the top-left;
- a compact, rounded, accent-tinted icon tile at the top-right;
- a single prominent primary label and an accent-coloured secondary line in
  the lower-left content lane;
- a selected centre card with the same grammar, but a slightly stronger
  accent outline/shadow than the neighbouring cards.

The reference is authoritative for visual anatomy, relative padding, type
hierarchy, tint intensity, wave placement, icon placement, and softness. The
existing carousel's actual outer bounds remain authoritative for the rendered
envelope because the user explicitly forbids changing external card size,
placement, or centre/side scale behaviour. Reference proportions therefore
scale only inside those unchanged bounds.

## Architecture card

### Single source and write path

- Source of truth: immutable `BalanceCarouselCard` presentation data plus the
  reference image above.
- Rendering owner: `_BalanceCarouselCard` and its private visual-style helper
  in `balance_dashboard_core_surface.dart`.
- Only write path: no new write path; the change is build-time rendering from
  immutable card data.
- Error/retry owner: none; this renderer does not perform I/O or asynchronous
  work.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Carousel selection, drag, inertia and focus scale | Existing `CenteredCarousel` | Existing widget lifetime | Unchanged semantic selection callback |
| Mini-card accent, tint and wave geometry | Private immutable visual-style value | One build | Derived only from supplied card/category identity |
| Financial/category/partner text | Existing immutable `BalanceCarouselCard` | Existing prepared frame | Read-only in UI |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Carousel interactions and selected-vs-side scale | `CenteredCarousel` | Preserve without wrappers or physics changes. |
| Category colour/icon identity | `CategoryColorCatalog`, `CategoryAvatarPaletteCatalog`, and `BalanceCategoryVisualBadge` | Reuse through one mini-card accent resolver; no local palette. |
| Shared Balance mini-card grammar | `_BalanceCarouselCard` | Extend the one existing renderer rather than create topic-specific cards. |
| Card border/corner/shadow configuration | Existing Dashboard style scopes | Preserve semantic scope ownership; layer only reference-specific accent treatment inside the card. |

### Layer flow

`prepared Balance presentation → immutable BalanceCarouselCard → existing CenteredCarousel → reference-styled mini-card renderer`

No controller, repository, Query, financial calculation, prepared-index, or
gesture state changes are in scope.

## Design

The renderer will become a clipped, layered `Stack` inside the existing
card-size `SizedBox`:

1. The existing rounded material shell keeps its normal size, corner and soft
   shadow ownership. A light, accent-derived tint and fine accent outline make
   the card match the reference.
2. A passive, clipped lower-wave painter draws one broad, low-opacity accent
   lobe across the lower half. It is not animated, interactive, or a second
   layout owner.
3. A reference metric object owns every internal offset and text/tile scale,
   based on the unchanged supplied card size. The title stays top-left; the
   icon tile occupies top-right; primary and secondary text remain in a
   bounded lower-left lane with single-line ellipsis.
4. The current canonical category badge becomes the visual inside the small
   top-right tile. Cards without a category identity use the existing semantic
   icon fallback and the same tile grammar.
5. The existing `CenteredCarouselItemMetrics.isSelected` flag is forwarded as
   an immutable render input so the selected centre card receives only the
   reference's restrained stronger outline/elevation treatment.
   `CenteredCarousel` remains the sole owner of whether the item is centred or
   scaled as a side card.

## Verification

- Add a failing widget test that asserts all card topics retain one title,
  top-right tile, primary line, secondary line, accent shell, and wave layer.
- Add geometric widget assertions for the title/top-right tile/text lanes and
  for the unchanged outer card bounds/engine configuration.
- Replace the mini-card golden only after the reference renderer is green,
  then inspect the generated image directly against
  `carousel2.png`.
- Run the focused Balance surface suite and Flutter analysis in Ubuntu proot.
- Treat a physical Android install/visual decision as user-only evidence.

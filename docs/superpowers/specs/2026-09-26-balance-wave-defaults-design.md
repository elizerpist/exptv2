# Balance wave, content-border, and startup defaults design

## Approved intent

The user explicitly approved immediate implementation of the supplied
`FLUVI — BALANCE CAROUSEL CUSTOMIZATION + ANIMATED WAVE + CONTENT-BORDER COLOR
MATCH + APP DEFAULTS` specification. This design extends the accepted carousel
without changing its shared motion, outer geometry, selected-card semantics,
financial data, or ranked-list semantics. The approved mini-card reference
remains `/storage/emulated/0/spendee/reference/carousel2.png`.

## Architecture card

### Scope and sources

- User requirement: sections 0–16 of the current Balance customization request.
- Accepted reference: `/storage/emulated/0/spendee/reference/carousel2.png`.
- Existing carousel/settings: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart` and `balance_dashboard_core_surface.dart`.
- Existing shared ranked-list resolver: `balance_linked_detail_card.dart`.
- Existing startup owners: `dashboard_header_visual_engine.dart`, `dashboard_header_balance_color_scale.dart`, `mind_behavioral_score_settings.dart`, and `mind_year_heatmap_presentation_settings.dart`.

### Single source and write path

`BalancePresentationSettings` is the immutable Balance read model and
`BalancePresentationController` is its only writer. The visual tuner only
forwards user intent to that controller. The shared carousel remains the only
gesture, selection and physics owner. Header, Mind-score and heatmap defaults
remain owned by their existing immutable settings models and controllers.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Balance card appearance | `BalancePresentationController` | Dashboard session | Publishes an immutable settings replacement only after a real user change. |
| Wave phase | `_BalanceUpperCarouselState` | Existing carousel state lifetime | One ticker phase is read only by wave painters; it never writes selection/settings. |
| Carousel selection/motion | `CenteredCarouselController` | Existing carousel state lifetime | Unchanged shared engine contract. |
| Header/Mind defaults | Existing default model factories | App/controller initialization | Seed state only; later controller writes retain normal user override behavior. |

### Reuse and centralization

| Candidate | Existing owner | Shared invariant | Decision |
| --- | --- | --- | --- |
| Carousel motion/selection | `CenteredCarouselController` | Physics, focus, scale, selection | Reuse unchanged; add no controller. |
| Accent color | `_BalanceCarouselReferenceAccent` | Entity/category color family | Reuse it for both mini-card and selected content-card color. |
| Rank geometry | `_RankedOverviewLayout` | Category/partner page-one row/avatar layout | Reuse unchanged; validate parity regression. |
| Wave phase | New field on existing `_BalanceUpperCarouselState` | One continuous phase across cards/selection | Add one shared ticker, not one ticker per card. |

### Layer flow

`visual tuner → BalancePresentationController → BalancePresentationSettings → carousel/content renderers`.

The wave ticker is local paint state only. It has no repository, Query,
projection, ranking, page-controller, or persistence dependency.

## Design decisions

- Preserve the current accepted defaults for the pre-existing carousel controls:
  tint and outline enabled, their opacity and wave opacity at 100%.
- Seed the new wave-animation toggle as `false`, so the current static
  reference image stays the default. When enabled, a 6-second shared phase
  changes only the wave path by a 2–5 px-equivalent vertical deformation and
  a small horizontal drift. `MediaQuery.disableAnimations` makes it static.
- Seed the new colored-content-border toggle as `false`, preserving the
  current neutral content shell. When enabled, the selected carousel card's
  existing accent resolver supplies the color; its independently stored
  opacity controls only that colored outline. When disabled, the accepted
  neutral dashboard border remains the baseline and the stored color opacity
  is preserved.
- Keep the already implemented shared stretch resolver. This pass adds
  regression evidence that both ranked first pages still use its fixed rank-1
  / bounded-equal ranks 2–5 geometry.
- Apply requested startup seeds only at existing model defaults: all Header
  text and icons softened; Balance/Mind charts softened; Balance opacity 100%;
  Balance window 15%; Balance chart function compound; Mind function centered;
  Mind heatmap scale mode dynamic mixed.

## Verification strategy

Run test-first controller/default tests, widget tests for keys/paint and
animation/reduced-motion behavior, existing ranked-list geometry parity tests,
the reference golden, architecture boundary tests, formatter and Ubuntu-proot
Flutter analyze/test. Capture a representative changed visual state if the
available harness permits it. Human physical validation remains user-only.

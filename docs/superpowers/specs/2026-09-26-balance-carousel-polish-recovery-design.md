# Balance carousel polish recovery design

## Scope and sources

- User request: finish the interrupted Balance carousel polish work.
- Approved visual guidance: `/storage/emulated/0/spendee/reference/balancecarousel.png` and `/storage/emulated/0/spendee/reference/topcategory.png` (inspected directly; written requirements remain authoritative).
- Recovered interrupted-session contract: canonical mini-card anatomy, Top Partner/Top Category metric parity, and count-safe global flat-BottomNav geometry.
- Existing implementation owners: `balance_dashboard_core_surface.dart`, `balance_linked_detail_card.dart`, and `dashboard_shell_presentation.dart`.

## Architecture card

### Single source and write path

- Carousel selection and motion remain owned by the existing shared `CenteredCarousel` engine; this change supplies only Balance renderers.
- Balance data remains immutable `DashboardBalanceLinkedPresentation`; widgets make no repository, Query, index, or financial-calculation call.
- Rank detail selection remains local to `_RankedDetail`; it does not publish to Core, Summary, or Query.
- Flat-navigation stretch remains a pure `DashboardFlatBottomNavStretchLayout` calculation, configured only through `DashboardShellPresentationController`.

### Reuse and centralization

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Carousel gesture, inertia, snap, selection | shared `CenteredCarousel` | Preserve; do not fork or retune it. |
| Mini-card anatomy | `_BalanceCarouselMiniCardContent` | Make it the one Balance renderer for entity and icon-only topics. |
| Entity list/detail metrics | `_RankedDetail` and a shared entity detail scaffold | Use one ranked-row and detail-page template; vary only immutable entity data. |
| Dynamic entity colour | category palette catalog and `BalanceCategoryVisualBadge` | Reuse; no local colour literals. |
| BottomNav body gain | `DashboardFlatBottomNavStretchLayout` | Extend the one resolver with both physical-release and count-safe bounds. |

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Carousel motion/selection | existing shared controller + Balance surface | widget lifetime | existing semantic selection callback only |
| Rank-detail selection | `_RankedDetailState` | lower-card lifetime | local `setState`; never leaves the card |
| Flat-nav visual setting | `DashboardShellPresentationController` | shell lifetime | controller notifier; no persistence |
| Financial/rank data | existing prepared presentation | Core-produced immutable frame | read-only in UI |

### Evidence

- Widget tests cover card anatomy, category/partner metric parity, 210px detail envelope, and mounted BottomNav geometry.
- Golden evidence covers the canonical mini card and compact entity detail states.
- Direct reference inspection confirms the intended visual hierarchy; physical Android acceptance remains user-only.
- No new async, storage, network, retry, or data-preparation path is permitted.

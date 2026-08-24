# SummaryPill ballistic-primary-controls prototype

## Scope

This approved, deliberately narrow experiment withdraws the temporary
background-only Ledger amount while retaining the SearchPill, then evaluates
two orthogonal ballistic primary controls inside the existing SummaryPill.
It is not a decision to replace the current mother--child time model.

## Architecture card

### Sources and current owners

- User-approved task specification, 2026-08-24.
- `MILESTONE_COMMITS.md`: the accepted single LogBox vertical owner,
  immutable committed virtual geometry, prepared query promotion, and the
  existing child-rail physical contracts are regression boundaries.
- `DashboardLayoutMetrics` owns the fixed Ledger header height;
  `DashboardLogBoxHeader` renders that real structural extent; and
  `DashboardLogBoxViewport` derives the remaining scroll extent from it.
- `DashboardNavigationController` owns the canonical `SUM` / `YEAR` /
  `MONTH` selection and its temporal anchor. `DashboardCoreController` owns
  preparation and publication before a structural selection is committed.
- `CenteredCarouselController` and `CenterSnapScrollPhysics` own drag,
  velocity-aware fling, snapping, cancellation, and settled callbacks for the
  accepted child rail.

### Single source and write path

| State | Owner | Publication rule |
| --- | --- | --- |
| Primary axis/mother visual preview | local centered-carousel controllers | never writes query state |
| Settled primary target | `DashboardCoreController` | prepared scene/data coverage precedes canonical navigation commit |
| Canonical plane, parent, child, and query | `DashboardNavigationController` through `DashboardPresentationController` | one existing structural navigation path |
| Ledger fixed header size | `DashboardLayoutMetrics` / `DashboardGeometryResolver` | rendered and scrollable extent use the same metric |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Fling, snap, velocity bands, gesture cancellation | `CenteredCarousel` | extend it with an axis parameter; retain horizontal child-rail behavior unchanged |
| Time/query selection | `DashboardNavigationController` and core/presentation controllers | add target/offset candidate adapters, not a second temporal model |
| Ledger header geometry | `DashboardLayoutMetrics` | remove the amount lane from the token sum and reuse the lower real extent |
| Summary visual values | existing tokens and formatting | reuse them; introduce no feature-local palette or formatter |

The compact axis selector has its own local vertical carousel controller. It
is an interaction-local controller, not the LogBox/dashboard vertical scroll
owner; the existing Ledger `Scrollable`, controller, physics, and position
are not touched.

## Design

The Ledger header becomes `handler -> count -> SearchPill -> date groups`.
The count and SearchPill retain their current semantics and visual roles. The
standalone amount and its structural slot are removed; the SummaryPill keeps
the only visible query amount.

The fixed-height SummaryPill becomes, from left to right: compact vertical
axis selector, a one-pixel design-token separator, horizontal mother selector,
the existing prepared amount, and the existing chevron. The axis displays an
icon for each of the existing three `TimePlane` values; no project mapping was
found to reuse, so the mapping lives with the SummaryPill presentation only.
The mother selector is absent as a physical carousel in `SUM`, where it is a
non-interactive all-time label; it invents no siblings.

Both selectors use the same centered-carousel engine as the child rail. A
carousel may preview several items during a fling, but invokes the existing
prepared structural navigation path exactly once at its settled target. The
axis uses the current cyclic plane order. The mother selector asks the
canonical navigation owner for a direct existing-sibling target at the settled
relative offset. The existing expanded child rail remains its own horizontal
carousel and query behavior is unchanged. While that rail is open, its live
child/context label continues below the mother label inside the current
SummaryPill height and consumes the existing rail-tick Y-impulse lane; it
overlays the mother text without taking over the mother carousel's horizontal
hit region. In that open-rail state, accessibility exposes one actionable
mother-period node (increment/decrement when siblings exist) and a separate
read-only active-child context label, rather than announcing the overlaid
visual text twice.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LRS-01 | Task A | metrics/header/viewport | standalone Ledger amount and its space are gone; count then SearchPill remain | widget geometry tests | DONE |
| LRS-02 | Task A | SummaryPill | prepared query amount remains in SummaryPill only | widget test | DONE |
| LRS-03 | Task A | LogBox viewport | fixed header and first date/scroll lane derive from the smaller real extent | metrics + viewport tests | DONE |
| AX-01 | Task B | shared carousel | the existing fling/snap engine supports a vertical axis without changing horizontal consumers | shared widget/controller tests | DONE |
| AX-02 | Task B | SummaryPill | separate compact left vertical `SUM`/`YEAR`/`MONTH` zone, separator, and right mother zone fit the current pill height | widget geometry/semantics test | DONE |
| AX-03 | Task B | time navigation | vertical settled target commits only canonical valid plane through the existing prepared path | controller + widget fling test | DONE |
| AX-04 | Task B | time navigation | horizontal settled mother target changes existing YEAR/MONTH sibling; SUM is a no-op | controller + widget fling test | DONE |
| AX-05 | Task B | SummaryPill/rail | chevron, child rail, child ballistic interaction, live child feedback/Y impulse, and current mother--child semantics remain | focused + existing regression tests | DONE |
| AX-06 | Task B | interaction boundaries | one pointer has one zone owner; no axis/mother double commit; Ledger vertical ownership remains stable | focused gesture and protected LogBox tests | DONE |
| DOC-01 | Task docs | prior Ledger and new prototype docs | amount withdrawal and experimental/deferred status are accurate | documentation review | DONE |
| DEL-01 | Global delivery rules | git/GitHub artifact | focused production commit pushed; exact human APK downloaded and hashed | CI/job/artifact evidence | NOT DONE |

## Explicitly deferred

No fourth `DAY` primary axis, no removal of mother--child semantics or child
rail, no fixed child overlay, no Balance/Budget/Mind semantic change, no
SummaryPill outer-height state, no Ledger scroll architecture change, and no
motion-timing redesign are included.

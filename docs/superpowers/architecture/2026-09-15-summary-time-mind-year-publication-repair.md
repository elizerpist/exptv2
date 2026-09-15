# Summary Time / Mind Year publication repair architecture card

## Scope and evidence

This repair has two independent physical defect classes on application commit
`288cc35584ec5cb6e41eb237523104922a2c7393`, not one presumed common cause.
The frozen sources are Drive `Fluvi logs time fling`
(`1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, session
`fluvi-1789452354097594`, SHA-256
`08c630714ed985a7d646a368ac70b7b0b7f4e80a5e9593d62e6e12aeabd1b594`)
and `Fluvi mind heatmap` (`1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`,
same session, SHA-256
`2c4ab4c366e0ba884dd8a48d0597f82eabf3f81e1408bb6d6289e362fadd1605`).

The Time trace proves a 2024 -> 2020 candidate after a back-to-back direct
pointer; it does not yet prove the smallest source line or literal 2000
arithmetic. The Mind trace proves a visible Summary Year can precede matching
heatmap identity by 0.80--1.60 s while projection itself takes 84--123 µs.

## Structuring Apps rules applied

The governing skill is `structuring-apps` at
`/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
(local skill, no version metadata). This is a full gate: one owner/write path
per state, UI only renders/forwards intent, controllers coordinate feature
state, shared gesture machinery is extended rather than copied, and a
cross-file state change requires an architecture card, acceptance checklist,
and fail-closed boundary tests.

## Ownership and visible-generation contracts

| State / work | Existing sole owner | Allowed repair boundary |
| --- | --- | --- |
| Carousel physical position, logical index, physics and motion command | `CenteredCarouselController` | Extend its existing structural-rebase contract; preserve controller, ScrollPosition and physics identity. |
| Summary semantic navigation and accepted Time candidate | `DashboardNavigationController` plus Core's prepared temporal publication path | No second Year controller; selector emits intent and Core remains the semantic/publication coordinator. |
| Selector-local gesture view state | `_HierarchyValueSelectorState` | May request an existing controller rebase at the exact direct-pointer/preemption boundary, never own canonical navigation. |
| Canonical query/navigation commit | existing `DashboardCoreController` / `CurrentQueryController` paths | Never commit canonical Query per transient Year tick. |
| Mind projection and bounded immutable data | `DashboardCoreController` + `MindYearHeatmapProjection` | Consume the accepted transient Year identity from the existing Time publication; no repository/index/scene/text preparation or new authority. One `_MindAmountPreparedBaseSlot` retains the compatible base and its annual contribution membership together, bounded to the existing two direction slots. |
| Heatmap paint | existing `MindYearHeatmapLiveProjection` / viewport | Renders the immutable frame only; cannot choose Year or mutate navigation. |

For Time, a new direct pointer may begin only from an atomically aligned pair:
semantic origin `Y` and controller physical/logical zero point representing
`Y`. A stale old offset may never be reapplied relative to a newly promoted
semantic origin.

For Mind, an accepted Summary Year candidate that actually paints as `Y` with
interaction generation `G` must publish heatmap `Y/G` in that transition or
the next frame. The pre-existing `MindYearHeatmapIdentity.navigationEpoch`
now records `G` for this transient path (canonical callers remain `0`), and
the viewport includes it in its bounded paint diagnostic. Coalesced candidates
that never paint do not trigger a heatmap frame. The latest painted Summary
generation wins; a stale heatmap frame cannot overwrite it.

## No-touch / invariant matrix

| Protected boundary | Invariant | Required verification |
| --- | --- | --- |
| Summary / carousel | controller, ScrollPosition and physics identities survive back-to-back pointer, HoldScrollActivity, fling and Month/Day tracks | mounted widget tests plus controller identity assertions |
| Avatar | controller/position/physics and 6e962187 performance floor are untouched | Avatar motion/lifecycle regressions and diff audit |
| Query / LogBox | one canonical Query owner; paging/scroll and visible rows are not remounted or flushed | query/LogBox tests and source audit |
| Mind direction repair | 288 prepared-base readiness, two-slot bound and visible-row provenance remain | existing DRR tests plus focused source checks |
| Mind slider | transient Year publication performs zero repository calls, index builds, source-row scans and rich-scene/text preparation | work-counter/boundary tests |
| Calendar / debug UX | geometry, 12-card layout, fixed footer, existing filter and bug marker remain | existing geometry/debug tests |

Forbidden: controller/position/physics recreation, widget Key/remount, Year
clamps, debounce/cooldown, delayed pointer acceptance, mode toggling, cache
flush, duplicate Time/Year or Query authority, or heatmap-owned transaction
state.

## Required boundary tests before production mutation

1. A mounted real segmented Year selector must capture the old raw logical
   index, semantic origin, promoted semantic Year, first new candidate and
   controller identities through pointer preemption; it must fail on the
   current source for stale-offset reuse.
2. A production-parent Mind + Year test must capture visible Summary Year and
   heatmap identity/frame each render step; it must fail when a painted Summary
   Year leaves the old heatmap for more than one render frame.
3. A fail-closed structural/boundary test must reject a second temporal
   authority or repository/index work on transient heatmap publication.

## Implemented boundary

The Time boundary is the selector-local physical adapter, not the semantic
navigation controller: `CenteredCarousel` reports a direct-pointer
interruption, Core synchronously promotes its last exact semantic target, and
`_HierarchyValueSelectorState` then calls the existing
`interruptAndJumpToIndexSilently(0)`. That API preserves the controller,
`ScrollPosition`, and physics object while invalidating the obsolete command
and aligning raw logical offset zero with the newly promoted origin. It does
not create a new carousel or change the Core temporal authority.

The Mind boundary is a renderer-to-coordinator acknowledgement. An exact
selector target schedules a post-frame acknowledgement only if it is still
the latest accepted target; coalesced/interrupted targets are invalidated by
the local frame epoch. `DashboardCoreController` consumes that report only
for a current Year/Mind identity and derives a projection from the existing
resident prepared-base slot. That single slot derives its immutable annual
ordinal/day/amount membership only at base registration and evicts it with its
base. A transient Year therefore selects its focused ordinal subset and scans
only the selected year's compact contributions: it does not revisit
`DashboardLedgerEntry`, commit canonical Query, call a repository, build an
index, prepare a scene, or prepare text. Its identity guard requires the exact
accepted target object and current interaction generation, so a late callback
cannot overwrite a newer year.

## Local RED-to-GREEN evidence

Before this boundary was changed, the mounted `TIME-01` production selector
had semantic origin 2024 while its raw centered logical index was `-4.0678`;
the first replacement candidate was 2019 rather than local 2023. After the
direct-pointer structural rebase it is zero before the replacement gesture and
the first candidate is 2023. The same test retains controller,
`ScrollPosition`, and physics identities.

Before the Mind publication boundary was changed, mounted `MYTP-01` visibly
painted Summary Year 2025 while `mindYearHeatmap.identity.year` was still
2026. It now publishes 2025 in that transition with temporal generation `1`,
and the viewport paints it on the following render frame. Its coalesced
2025→2023 continuation emits only the terminal 2023 heatmap paint, never a
stale 2024, and retains one repository preparation call. A second RED showed
that this still visited two raw ledger rows; the prepared annual membership
repair makes the exact transient publication log `sourceRows=0` and
`preparedContributions=1` instead.

The current focused Summary/Core/Mind/debug suite passed 152 tests locally,
and the complete `dashboard_core_ephemeral_focus_test.dart` passed 73 tests.
An earlier full-repository run executed 1590 tests but failed 22 unrelated
Header golden/ticker and dashboard-scroll-milestone tests in this
Termux/proot environment; it is deliberately not classified as green pending
online CI.

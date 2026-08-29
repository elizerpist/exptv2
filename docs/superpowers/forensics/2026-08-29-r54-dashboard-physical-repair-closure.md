# R54 Dashboard physical repair closure record

This is the superseding closure record for the Dashboard reliability/palette
package. The previous 2026-08-29 record labelled `G1`–`G5` and its APK
delivery `DONE`; revision 54 and the subsequent physical APK screenshots
invalidated that declaration. Passing tests and that older APK are not used as
acceptance evidence here.

## Baseline

| Item | Value |
|---|---|
| Branch | `separated-core-modes` |
| Starting local / remote SHA | `4e62e81801520e409ce3b73c4e6dcc5894f42e2f` |
| Previous production source SHA | `05f4693555de5c4ff63ea4ab1bd6c2d048838cec` |
| Fluvi Logs | revision 54, re-read before source work |
| Intermediate Android builds | none |

## Corrected causes and ownership

### G1 — first Avatar limit edit and draft retention

The selected Avatar's `GestureDetector` conditionally omitted every long-press
callback when `presentation.value.header.editContext` was temporarily null.
That Header value is a render projection, so a valid first pointer had no
recognizer. The subsequent gesture controller also rejected a context derived
from that transient projection.

The selected Avatar now keeps its direct input surface/recognizer installed
independently of Header readiness. `DashboardBudgetPresentationController`
provides a typed direct-input edit authority from the selected target and
canonical period; the active quick-edit session remains the optimistic draft
owner across same-target prepared-frame gaps and only an exact incompatible
semantic target may invalidate it. Bounded trace points record pointer down,
context acceptance/rejection, session generation, tick, release and write.

The regression coverage includes cold/Header-gap first input, active-draft
frame replacement, existing/no-limit values, YEAR batch semantics, stale
same-key acknowledgement and cross-target write isolation. The G1 package ran
87 tests successfully.

### G2 — Avatar crossing critical path

R54 recorded 7 and 8 semantic crossings with an equal number of preview and
focus requests, followed by foreground scene work (`5452` and `5547` UI-isolate
microseconds). The direct Avatar path synchronously derived a focus root for
each crossing; the time rail did not take that path.

The rail now requests a fixed, idle-only selected-target neighbourhood
(`0, -1, +1, ... ±8`, capacity 17). `DashboardCoreController` prepares the
immutable focus derivations through the existing latest-generation boundary;
a crossing promotes the exact cached derivation and never starts rich scene
work. Raw Avatar contact cancels lower-priority preparation before the
carousel's first semantic crossing. The 8-crossing gate observes 8 prepared
promotions, 0 hotset misses, `uiIsolateMicros=0` for each promoted derivation,
and no repository/scenes started by raw motion. It preserves the existing
CenteredCarousel controller, position, physics, category count and crossing
semantics.

### G3 — Summary post-time-fling takeover

The r54 `SUMMARY_PARENT_HOTSET_PREPARE_*` path could run retained speculative
scene preparation for 126–140 ms. More importantly, the Summary did not own a
raw-pointer preemption boundary, and an active time ScrollPosition retained its
ballistic activity until natural decay.

`DashboardSummaryPill` now invokes its foreground callback from an opaque
`Listener.onPointerDown`, before its pan arena resolves. The core immediately
cancels retained Summary/scene/rail warmup and calls the motion kernel's
foreground takeover, which stops the existing time ScrollPosition without a
semantic crossing or a controller replacement. The real CoreDashboard test
starts a time fling, then shows the Summary pointer changes the old motion to
idle before Summary chooses its own axis at 0, 16, 50 and 100 ms, and again
immediately after settle; the scheduler test confirms the retained parent
hotset is cancelled at that same boundary. No cooldown or global IgnorePointer
is used.

### G4 — Rhythm collapse slab provenance

The transparent zero-bar tracks were not the present grey owner. The failure
topology was two independently transformed physical Card2/common materials in
Unified mode: the lower transparent Rhythm lane could expose the differently
moving inner distribution shell while the Partner upper donut/list continued
to paint opaque page content. That is why the upper Partner region remained
correct while the lower lane became a uniform slab.

The repaired hierarchy has exactly one material owner per layout:

```text
Split:   Card2 FluviRoundedBox -> rounded content viewport -> PageView -> Partner upper + Rhythm footer
Unified: common FluviRoundedBox -> rounded content viewport -> PageView -> Partner upper + Rhythm footer
```

The Unified common material follows the same top-centred lower-card cascade as
the content viewport. The PageView remains content-only (`Clip.none`); the
one rounded shell owns clipping. Dense 1.00→0.00→1.00 raster sampling covers
both Category and Partner interior along with controller/position stability;
the production Budget surface regression also guards against a progress-based
Card2 clip/reparenting.

### G5 — Mind amount range authority

Mind already used `QueryAmountRangeControl`, but it resolved from nullable
`facetPresentationFor(direction)?.amountDomain`. Null flowed to
`QueryAmountRange.resolve`, which interpreted it as a 1,000 HUF maximum. This
produced the visible `1000/1000`, coincident thumbs and disabled callbacks.

`QueryAmountRangeBinding` is now the single scope-plus-`QueryMenuAmountDomain`
resolver/mutator used by Query Menu and Mind. `CurrentQueryController` retains
the exact accepted `QueryMenuData` on a same-scope transient projection gap.
If no canonical domain exists, both hosts represent explicit unavailability;
they never fabricate a disabled 1,000/1,000 control. CoreDashboard host tests
seed the canonical domain and assert its exact two-ended values; a separate
cold-domain test asserts no slider is constructed. Binding, controller,
Query-menu, control and CoreDashboard groups passed (33 tests in the combined
host/domain run).

### G6 — Unified physical card ownership

The old Unified tree painted both `_BudgetUnifiedContentCard` and a complete
`BudgetDistributionCardShell`. The inner shell owned its own colour, border,
radius and shadow, creating the visible duplicated card.

`BudgetDistributionSurfaceOwner` makes the topology explicit. Split owns one
Card2 shell. Unified leaves the persistent shell as a clip-only content
viewport and gives the common card the sole physical material. Switching
Split→Unified→Split preserves the single `PageController` and attached
`ScrollPosition`.

### G7 — Rhythm geometry

The previous actual plot range was 44.0 dp normal / 35.2 dp compact. The new
resolver first derives that prior allocation and then scales it by 1.10:
48.4 dp normal and 38.72 dp compact. The 4.4 dp normal delta is reclaimed from
the Partner upper section; Card2 outer height, dots, handle and LogBox bounds
are unchanged. Numeric checks cover 208 dp and 217 dp cards in both layout
modes and assert exact conservation.

### P1 — protected Category Header colours

No Header palette/engine identity was redesigned. The compressed V1/Spectrum40
category identity, aggregate mapping, retained program/backend/shader and one
ticker remain on the prior semantic path. The palette/backend/material test
matrix passed 100 tests after the G1/G2 changes.

## Verification before delivery

| Command/group | Result |
|---|---|
| G1 Avatar rail/edit/presentation package | 87 passed |
| G2 focus/query/carousel/zero-I/O package | 114 passed |
| G3 Core Dashboard time-fling takeover + Summary package | passed |
| G4/G6/G7 Budget surface/pager/Partner/Rhythm package | 39 passed |
| G5 Query/Mind host/domain package | 33 passed |
| P1 Header palette/visual/material package | 100 passed |
| `flutter analyze` (Ubuntu proot) | no issues |
| `git diff --check` | clean before delivery documentation update |

The first full-suite run exposed
`dashboard_logbox_stable_render_surface_test.dart` (`Too many elements` at
its unscoped `find.byType(Scrollable)`). It reproduces unchanged at the exact
starting SHA above, so it is an inherited baseline failure, not hidden or
attributed to this repair. It changes none of the requested source owners.

## Delivery fields

The fields below are completed only after the one permitted final push/build
and APK download. No intermediate APK build was performed.

| Item | Value |
|---|---|
| Final source SHA | pending |
| Final remote SHA | pending |
| GitHub Actions run | pending |
| Human APK filename | pending |
| APK SHA-256 | pending |
| Device acceptance matrix | pending final APK |

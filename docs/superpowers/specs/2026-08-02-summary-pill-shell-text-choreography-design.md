# SummaryPill shell-to-text choreography design

## Approved outcome

Restore horizontal SummaryPill feedback as the axis-swapped counterpart of
the accepted vertical shell-to-text choreography:

drag
→ complete pill shell follows the gesture
→ shell smoothly returns to the zero offset
→ navigation title + subtitle slide and crossfade

The visual sequence is local to presentation. Navigation, canonical scope,
query, amount read, and LogBox/read-model updates still begin at the accepted
gesture commit; they never wait for either presentation stage.

## Evidence and root cause

The current DashboardSummaryPill has one outer GestureDetector and a child
Transform.translate around the complete FluviRoundedBox. On a vertical drag,
the local offset is Offset(0, clamp(accumulatedDy * 0.10, -8, 8)). Therefore
the icon, text, amount, chevron, surface, border, and shape move as one
paint-only shell. A cancellation uses the local 125 ms easeOutCubic return
controller. A committed vertical gesture currently resets the shell position
synchronously before publishing the plane callback, and the subsequent
SummaryPillTextTransition animates the title + subtitle.

Horizontal behavior diverged in the Summary navigation motion recovery
(6d844dc). That change intentionally removed the former complete-shell X
offset and introduced a drag-preview crossfade only inside
SummaryNavigationMotionRegion. The result is that title + subtitle move while
the icon, amount, chevron, and pill surface remain still.

The approved design makes the observed vertical intent explicit and shared:
both committed vertical and committed horizontal gestures use an animated
shell return before their text transition. This removes the committed
position jump and creates actual axis parity.

## Architecture card

### Ownership

| Concern | Owner | Writes |
| --- | --- | --- |
| Parent cursor, plane ring, YearMonth boundaries and rail index | DashboardTimeNavigationController | Existing committed gesture callbacks only |
| Canonical scope, repository watch, stale-result rejection and LogBox/read-model | CurrentQueryController through DashboardCoreController | Existing committed-navigation listener only |
| Amount and loading/stale projection | DashboardSummaryAmountController | Existing query/index projection only |
| Shell offset, shell-return lifecycle and immutable outgoing/incoming text snapshots | DashboardSummaryPill presentation state | Gesture rendering and local animation callbacks only |
| Rail tick intent and staged navigation-text presentation intent | SummaryNavigationMotionController | Presentation event publication only |
| Text crossfade, clipped layout and rail tick paint impulse | SummaryNavigationMotionRegion / SummaryPillTextTransition | Local animation lifecycle only |

Neither presentation owner can calculate an effective scope, mutate a parent
cursor, start a query, create a repository subscription, or emit rail haptic.

### Shared mechanisms and extraction decision

- Do not duplicate the vertical and horizontal shell implementation. One
  local shell-motion state machine in DashboardSummaryPill owns both axes.
- Do not add another text transition. SummaryPillTextTransition remains the
  one clipped, latest-wins title + subtitle transition; its existing
  direction, fade curve, duration, incoming/outgoing ratios, and axis math
  are reused.
- The current horizontal inner drag-preview path is removed. During drag only
  the shell moves; a horizontal text transition begins only after the shell
  return completion.
- SummaryNavigationMotionController remains presentation-only. Its
  horizontal interactive-drag state is replaced by immutable staged-text
  snapshots and generation-safe events as needed; it does not become an
  application-state owner.

### Layer composition and hit testing

The hit region stays in its original bounds while the visual child moves:

GestureDetector(opaque, fixed SummaryPill bounds)
→ Transform.translate(shellOffset)
→ complete FluviRoundedBox
→ icon + navigation text region + amount + chevron

The Transform is paint-only: no padding, margin, width, height, constraint,
or surrounding-dashboard geometry changes. The child TimeRefinementRail
remains in its distinct positioned gesture region; its drag cannot enter the
SummaryPill gesture arena.

## Motion contract

### Shell state

The DashboardSummaryPill-local state has this conceptual value:

| Phase | Axis | Visible content | Effect |
| --- | --- | --- | --- |
| idle | none | canonical navigation text | zero shell offset |
| dragging | horizontal or vertical | canonical outgoing text | clamped full-pill gesture follow |
| returningAfterCancel | locked gesture axis | canonical outgoing text | smooth shell return only |
| returningBeforeTextTransition | locked gesture axis | frozen outgoing text | smooth shell return, then text event |
| textTransitioning | none | outgoing + incoming snapshots | shell at zero; navigation text only transitions |

Each new gesture increments a generation, stops a prior shell return, clears
cross-axis residue, and invalidates old completion callbacks. A stale shell or
text completion cannot start an old transition, restore old text, or write an
offset.

### Constants

| Property | Existing evidence | Approved target |
| --- | --- | --- |
| Vertical gesture factor | 0.10 | 0.10 |
| Vertical maximum travel | 8 logical px | 8 logical px |
| Horizontal YEAR/MONTH factor and cap | previously absent from current shell | 0.10 and 8 logical px, axis-swapped parity |
| SUM resistance cap | inner-text implementation used 5 logical px | 5 logical px full-shell resistance |
| Existing cancellation return | 125 ms, easeOutCubic | superseded for shared shell return |
| Shared shell return | none on committed gesture | 100 ms, easeOutCubic |
| Text transition | 190 ms, easeOutCubic | unchanged |

The 100 ms shell return is inside the approved 70–110 ms range. It retains
the existing easeOutCubic motion language while making the committed vertical
and horizontal paths genuinely consistent.

### Commit timeline

At T0, a successful gesture release creates immutable presentation snapshots:

- outgoingContent is the text currently owned by the presentation layer;
- incomingContent is the pure YEAR/MONTH parent candidate or the committed
  vertical plane content;
- transition axis and direction are explicit semantic values.

At the same T0, without awaiting presentation:

1. DashboardTimeNavigationController commits the navigation state.
2. DashboardCoreController accepts the canonical scope and starts the query
   path through its existing listener.
3. DashboardSummaryPill starts its local shell return animation.

During T0 through T1, the text region displays outgoingContent even though the
canonical navigation state is already new. Query and amount updates may arrive
in this interval; they cannot restart or alter the frozen text.

At T1, only if the shell generation is still current and shell offset is
exactly zero, the presentation event starts SummaryPillTextTransition from
outgoingContent to incomingContent. It reuses X + fade for horizontal and Y +
fade for vertical. No post-frame delay, Timer, debounce, repository future,
or query future exists between T0 and T1.

### Snapshot capture protocol

DashboardSummaryPill keeps an immutable semantic display snapshot only for the
brief presentation handoff. It is not canonical navigation state.

1. On release it freezes outgoingContent from the currently accepted
   presentation target and starts the generation-tagged shell return.
2. It immediately calls the existing navigation callback. That synchronously
   publishes the new navigation state and triggers the existing query-scope
   listener.
3. Still in the same gesture-release turn, it reads the committed
   navigationPresentationBuilder result and freezes incomingContent. The
   DashboardTimeNavigationController remains the only component that produced
   its YEAR/MONTH/plane result.
4. SummaryNavigationMotionRegion renders outgoingContent while the shell is
   returning, regardless of ordinary navigation or amount rebuilds.
5. The matching shell completion publishes one staged text request with both
   snapshots. The region starts its common axis text transition and clears the
   request only when that request generation completes.

When a new gesture begins, presentation stops the current shell/text
controller, selects its most recently accepted semantic display target as the
next outgoing snapshot, clears both cross-axis offsets, and increments the
generation. This produces latest-wins semantics without a queue and prevents
an old completion from publishing content after the newer gesture.

### Gesture-specific behavior

- Horizontal forward: shell dx follows the left drag; after return, outgoing
  text exits left and incoming text enters from the right.
- Horizontal backward: every X sign is reversed.
- Vertical behavior uses the exact same shell return and then the existing
  Y-only text direction mapping.
- Cancel: start shell return, then stop. Do not commit, query, change amount,
  trigger text motion, or emit committed haptic.
- SUM horizontal: expose only clamped 5 px full-shell resistance; no incoming
  candidate, text transition, navigation commit, query, or committed haptic.
- Rail ticks remain text-only. When shell dragging/returning or a vertical or
  horizontal text transition is active, the visual tick impulse is ignored
  and reset so it cannot compose into a diagonal transform. The existing rail
  haptic remains unchanged.

## Boundary invariants

1. Horizontal shell and text frames always have dy == 0. Vertical shell and
   text frames always have dx == 0.
2. The full shell transform includes the amount, but the amount is a sibling
   of the navigation text inside the shell and never takes part in the
   internal title/subtitle crossfade.
3. Parent preview remains a pure application-controller projection. The
   shell uses its resulting immutable text only as a presentation snapshot.
4. No rail preview can start a query. No rail physics, snap, fling,
   tap-retarget, infinite/rebase, or haptic implementation changes.
5. Navigation/query work and shell return start in the same gesture release
   turn. The text transition waits only for the local shell completion.
6. Existing amount updates are immediate and cannot trigger shell or
   navigation-text motion.

## Verification design

The implementation must add widget tests that observe these chronological
frames:

1. Horizontal drag: the complete pill shares a nonzero X transform, while
   the text-axis transition progress is zero.
2. Committed release: navigation/query accept at T0; shell return is active
   and text transition remains absent until the shell reaches zero.
3. Shell completion: the text transition starts immediately, uses X-only
   offsets, and retains simultaneous outgoing/incoming opacity.
4. Cancel and SUM: shell returns without text transition, query, parent
   cursor mutation, or committed haptic.
5. Vertical: same staged shell-return-before-text sequence, Y-only.
6. A new gesture during return or text transition invalidates stale callbacks
   and wins without a queue.
7. Amount moves with the shell but is outside the internal text transition.
8. Rail fling does not produce a horizontal shell transform; normal rail tick
   still moves only the text and keeps zero query count during preview.

Run the existing rail physics, query preview/settle, amount, gesture
isolation, centered-carousel, and vertical plane-ring suites unchanged. Add
goldens for horizontal drag, shell return, and post-return text transition.

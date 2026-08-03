# Dashboard rail continuity repair design

## Goal

Restore the exact `5b71141` centered-carousel behaviour while making the
dashboard's own render and display-data boundaries guarantee that a visible
finite rail can only traverse a complete immutable child deck. A rail fling
therefore changes amount, transaction count and LogBox content for every
logical crossing, without an empty LogBox, `—`, or a mixed snapshot frame.

## User-visible contract

1. A closed dashboard does not mount a `TimeRefinementRail`; no cyclic
   viewport can attach, recenter, or scroll during startup.
2. The shared centered-carousel engine is byte-for-byte behaviourally aligned
   with milestone `5b71141`; this repair changes no physics, velocity,
   snapping, haptic or crossing policy.
3. A visible finite rail has a complete active parent deck. Each preview
   crossing, including every crossing in one fling, synchronously selects the
   exact target `DashboardLogPreviewSnapshot` from that deck.
4. The same deck projection stays visible between `childPreviewIndex` and
   `childSettledIndex`; a committed query may promote it but may not replace
   it with a loading state first.
5. A direction transition is staged: the current coherent frame remains until
   the target direction's complete deck and committed first page are ready,
   then direction, query and deck become visible in one synchronous turn.
   There is never a `—` or loading LogBox frame between concrete snapshots.
6. An explicit empty child is a valid immediate `DashboardLogEmpty` snapshot,
   not a loading/absent signal.

## Root-cause evidence

- `CoreDashboard` always builds `TimeRefinementRail` below `Opacity` and
  `IgnorePointer`. Ignoring input does not prevent the cyclic carousel's
  physical `ScrollPosition` from attaching at offset zero.
- Commit `5406f71` changed the shared `CenteredCarousel` and
  `CenteredCarouselController` to suppress the resulting callbacks. This
  hides some startup effects but alters normal gesture/rebase lifecycle from
  milestone `5b71141`.
- `DashboardSummaryMetricsController._synchronize` publishes
  `stalePreviousValue` with null values when a finite deck is loading;
  `SummaryMetricsPresentation` renders that as `— Ft` and `—`.
- `DashboardLogPageCoordinator._publishPreviewCacheMiss` publishes
  `DashboardLogPreviewLoading`, whose widget is the empty loading sliver.
  It also stops using the deck when the source changes from
  `childPreviewIndex` to `childSettledIndex`, allowing the committed query's
  transient loading state to flash.
- Device FLOW logs show exactly those states: repeated `D12
  source=stalePreviousValue` with null values and `LOG_QUERY_COMMITTED
  cacheHit=false` after rail settle, while valid complete preview records are
  available before and after the gap.

## Architecture card

### State ownership and write paths

| State | Owner | Write path | Visible rule |
| --- | --- | --- | --- |
| Carousel physics/crossing/settle | shared centered-carousel | restored milestone controller/widget | unchanged from `5b71141` |
| Rail lifecycle | `CoreDashboard` render adapter | `DashboardMotionHost.railReveal` plus active finite-deck predicate | no widget exists at reveal `0`; fade-out retains the mounted rail until `0` |
| Navigation and logical child | `DashboardTimeNavigationController` | existing rail gesture callbacks | no I/O and no cache mutation |
| Finite child snapshots | `DashboardParentDisplayBundleController` | complete native payload -> validation -> atomic activation | O(1), exact key/revision lookup only |
| Amount/count projection | `DashboardSummaryMetricsController` | active deck snapshot; fallback retains prior concrete metrics | no null metric publication between concrete finite states |
| LogBox projection | `DashboardLogPageCoordinator` | active deck snapshot for preview **and settled** child | no `DashboardLogPreviewLoading` replaces a concrete frame |
| Direction/query transition | `DashboardCoreController` | prepare target deck + exact first page -> activate -> set query direction | old coherent frame or new coherent frame only |
| UI | `CoreDashboard`, SummaryPill, LogBox | renders narrow controller states | no repositories, channel calls, cache policy or navigation writes |

### Layer flow

```text
pointer fling
  -> centered-carousel (milestone physics)
  -> TimeRefinementRail / navigation logical child
  -> active complete parent display deck lookup
  -> Summary metrics + LogBox immutable snapshot

direction intent
  -> core transition coordinator
  -> target deck + exact first page prepared
  -> activate deck + commit query direction
  -> same exact snapshot is promoted by committed query
```

### Centralization decisions

- Do not add a second carousel, gesture, selection, animation, cache or
  prefetch mechanism. The shared rail motor is restored, not extended.
- Do not allow a presentation widget to inspect a repository. The dashboard
  core supplies the rail-render eligibility and stages direction work;
  metrics and LogBox own only their established read-only projections.
- Reuse `DashboardParentDisplayBundleController` as the sole finite deck
  source. Its explicit-empty snapshots distinguish empty content from absent
  content without a new cache type.
- Retaining a prior concrete state is a failure/cold-transition guard only;
  it is not used for normal rail crossings. A normal tick has an exact target
  deck entry and updates immediately.

## Non-goals

- No changes to centered-carousel physics constants, fling distance, snap,
  haptics, layout or rebasing semantics.
- No per-tick native query, cache warm, formatting, view-model projection or
  root-dashboard notification.
- No placeholder, `—`, loading sliver or blank LogBox between two concrete
  finite child snapshots.

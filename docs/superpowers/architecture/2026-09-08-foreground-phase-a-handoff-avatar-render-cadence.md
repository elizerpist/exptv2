# Architecture card — foreground Phase-A handoff and Avatar render cadence

## Existing owners retained

| Concern | Owner | Repair boundary |
| --- | --- | --- |
| User-intent ordering | `DashboardVisibleFrameStore` | Claim the next direct-manipulation order at raw pointer down; resource completion never invents a newer order. |
| Motion lifecycle | `DashboardCoreController` and existing carousel controllers | Add only an epoch/foreground handoff between producers. Physical controller and physics instances remain owned by their existing widgets. |
| Painter-readable rows | `DashboardLogBoxPreparedSceneCache` | Use its existing typed `budgetAvatarPreview` and `timePreview` lanes and `bindLiveInteractionReadablePhaseA`. |
| Semantic publication | Existing Core / `DashboardPresentationController` | Publish a non-empty target only after its exact Phase-A binding succeeds. |
| Visible authority | `DashboardVisibleFrameStore` | Preserve the prior valid visible frame while a newer cold candidate waits. |
| Budget presentation | `DashboardBudgetPresentationController` | Preserve atomic target promotion; add a paint acknowledgement at the actual visual boundary only. |

## Direct-manipulation contract

```text
raw pointer-down
  -> claim typed foreground producer + interaction order
  -> supersede old producer's logical callbacks / foreground resource lease
  -> request the incoming producer's bounded exact resource immediately
  -> semantic crossing derives only prepared data
  -> exact Phase-A cache bind
  -> atomic visible publication
  -> target-correlated paint acknowledgement
  -> optional rich work / canonical settle
```

The foreground claim is coordination only: it is not a second cache, store,
controller, LogBox or semantic authority. A physical outgoing carousel may
finish its own lifecycle, but it has no later visible or foreground-resource
authority after a newer producer claim.

## Implemented handoff details

`_DashboardForegroundDirectProducer` has only two values:
`summaryTime` and `budgetAvatar`. It exists inside the existing Core
controller, owns no data and carries no cache payload. A claim increments the
existing interaction ordering path, revokes the old producer's typed cache
lease and rejects old callbacks by producer/epoch. It is symmetrical:

```text
Avatar pointer active -> Summary pointer
  Avatar deferred candidate / lease / lane invalidated
  prior visible frame retained
  Time exact timePreview resource requested immediately
  exact Time bind -> visible store -> paint -> optional settle

Time pointer active -> Avatar pointer
  Time deferred candidate / lease / lane invalidated
  prior visible frame retained
  existing protected Avatar Phase-A candidate machinery continues
```

The controller deliberately does not cancel or recreate either physical
`CenteredCarouselController`/`ScrollPosition`; it only prevents an obsolete
producer's *logical* settle or resource continuation from acquiring newer
authority.

## Cold Time contract

For a non-empty Time target with no exact `timePreview` Phase-A resource, the
controller stores only the latest candidate with its original interaction
order, starts bounded preparation immediately, and promotes it from the actual
completion boundary if still current. Superseded candidates are terminally
classified. Empty Time targets may publish as explicit exact-empty targets.

This intentionally differs from the historical Time behavior, which published
the semantic frame on a `SUMMARY_LIVE_ROOT_MISS` and left the renderer with an
unreadable 13 px non-empty payload.

The cache reuse check is exact at the painter boundary: an equal semantic key
is not a hit when surface metrics changed. This retains one cache while
preventing reuse of a stale live `timePreview` bank.

## Render investigation boundary

Avatar's prepared semantic transaction is already fast in the retained device
trace. Measurements therefore begin after store acceptance. Any isolation
must be justified by measured rebuild/layout/repaint/raster evidence and must
not stagger financially related surfaces or retune carousel physics.

The implemented diagnostics observe Header build/paint, Budget-progress
build/paint/raster and the first Avatar target pipeline with target,
interaction-generation and frame correlation. They are gated by
`FLUVI_PHYSICAL_RAIL_DIAGNOSTICS` outside debug builds. No rendering isolation
has yet been applied because no new device trace identifies a safe target.

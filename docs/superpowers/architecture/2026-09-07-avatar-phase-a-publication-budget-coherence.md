# Architecture card — Avatar Phase-A publication repair

## One owner per responsibility

| Concern | Existing owner retained | Change boundary |
| --- | --- | --- |
| User-intent ordering | `DashboardVisibleFrameStore` | Reuse the order issued at the crossing; resource completion never mints a later order. |
| Avatar semantic derivation / latest target | `DashboardCoreController` | Add one bounded latest pending Avatar candidate here; it is not a cache or a second visible-frame store. |
| Painter-readable row resources | `DashboardLogBoxPreparedSceneCache`, lane `budgetAvatarPreview` | Reuse `bindLiveInteractionReadablePhaseA` and its existing resource-completion future. |
| Visible lanes | `DashboardVisibleFrameStore` through `DashboardPresentationController` | Publish exactly once only after exact Phase-A binding succeeds. |
| Budget selection/Header/progress | `DashboardBudgetPresentationController` | Existing `onVisibleSemanticCommit -> setTargetHandle` remains the promotion boundary. |
| Canonical installation | Existing deferred focus-scene install | Remains optional Phase-B/canonical work; cannot be first visible Avatar data. |

## Transaction

```text
Avatar crossing (intent order issued)
  -> derive exact prepared focused payload
  -> bind exact payload through budgetAvatarPreview resource authority
  -> publish visible interaction lanes
  -> accept live interaction / promote Budget target
  -> Header + Summary + LogBox share identity
  -> exact Phase-A paint acknowledgement
  -> optional rich/canonical work
```

If the exact resource is cold, the controller retains only the latest immutable candidate and completes it from the existing resource preparation completion. Superseded candidates complete false with a bounded diagnostic; they cannot later overwrite a newer target. This is event-driven continuation, not a timer, retry loop, new cache, or new authority.

## Protected boundaries

Time and Mind/Slider retain their current cache/store behavior. The shared cache may only be consumed through the existing `budgetAvatarPreview` lane. Carousel physics, ScrollEnd lifecycle, dashboard geometry, and financial/query semantics remain unchanged.

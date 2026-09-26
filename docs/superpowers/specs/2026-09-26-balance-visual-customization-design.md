# Balance visual customization design

## Intent

Parameterize the accepted Balance carousel treatment without changing its
geometry, selection mechanics, data, or interaction.  Defaults must render the
same appearance as commit `743311f6`.

## Ownership and data flow

`BalancePresentationSettings` is the sole session-state model and
`BalancePresentationController` is its sole writer.  The existing
`DashboardHeaderVisualTuner` emits user intent only; it does not persist or
derive visual state.  `BalanceDashboardCoreSurface` reads that immutable state
and supplies it to the existing carousel renderer and the large content-card
host.

```
visual tuner -> BalancePresentationController -> BalancePresentationSettings
                                                   |            |
                                             mini carousel   content shell
```

The carousel resolves effective alpha by multiplying its existing authored
accent alpha by the independent user setting.  It retains an identically sized
transparent border at zero alpha, so border controls cannot move layout.

## Ranked-list stretch

The large Balance card host derives additional height from its actual card
bounds versus the canonical, width-scaled base Dashboard layout.  It passes
only that scalar to `BalanceLinkedDetailCard`.  A single ranked-list layout
resolver owns category and partner page-one geometry.  Rank one remains at its
baseline avatar size; ranks two through five use one capped, uniform secondary
avatar size and the remaining height is distributed through list spacing.

No repository, ranking, carousel controller, page controller, or outer layout
owner is changed.

# Three-mode host refactor design

## Goal

Split the experimental dashboard's runtime logic into three independent mode
hosts without changing any existing menu, label, menu position, UI variant,
or A/B comparison control.

The refactor makes the active dashboard variant the only mounted mode tree.
It isolates the Balance, Budget, and Mind data-flow lifecycles while retaining
the five existing selectable visual variants.

## Scope and non-goals

In scope:

- Separate the three mode families: Balance, Budget, and Mind.
- Keep the existing five `SpendeeDashboardMode` values and their menu entries.
- Treat Balance/Balance V2 as Balance variants and Budget/Budget V2 as Budget
  variants.
- Make a mode or variant change dispose the old mode's timers, animations,
  gesture state, and widget tree before the new host builds.
- Preserve shared `TransactionStore` filter state across switches while
  resetting local visual motion state.

Out of scope:

- Changing any menu's copy, ordering, position, visual styling, or available
  A/B controls.
- Removing a UI variant.
- Changing the visual design of any screen.
- Altering TransactionStore filtering semantics or business calculations.
- Fixing unrelated experimental dashboard behavior.

## Variant-to-family mapping

| Existing selectable variant | Mode family | Owner of runtime data flow |
| --- | --- | --- |
| `balance` | Balance | `SpendeeBalanceModeHost` |
| `balanceV2` | Balance | `SpendeeBalanceModeHost` |
| `budget` | Budget | `SpendeeBudgetModeHost` |
| `budgetV2` | Budget | `SpendeeBudgetModeHost` |
| `mind` | Mind | `SpendeeMindModeHost` |

`SpendeeDashboardMode` remains the menu-facing selection type.  It gains a
family mapping only; no current caller needs to know about the new host types.

## Runtime architecture

`SpendeeTestDashboard` remains the public entry point and retains the existing
menu implementation.  It owns menu-facing presentation values and forwards
the existing callbacks unchanged.  It becomes a thin router:

```text
SpendeeTestDashboard
  ├── existing menu / A-B selection UI
  └── switch (dashboardMode.family)
        ├── SpendeeBalanceModeHost(variant: balance | balanceV2)
        ├── SpendeeBudgetModeHost(variant: budget | budgetV2)
        └── SpendeeMindModeHost(variant: mind)
```

The router must use a direct switch with a mode-and-variant key, rather than
an `IndexedStack`.  Therefore only one host is mounted at once.  Switching
mode or variant removes the old host from the element tree, invokes its
`dispose`, and creates the new host with a clean local interaction state.

The hosts receive a small immutable dependency object containing the store,
application callbacks, and presentation values currently driven by the
unchanged menus.  A host may not reach into another host's controller, timer,
cache, or widget cache.

## Host responsibilities

### Balance host

Owns construction and cache lifecycle of `BalanceFrameInput`,
`SpendeeBalanceDashboard`, normal Balance, and Balance V2 presentation.
It owns Balance-only callbacks such as scope, query, merchant, transaction-log
and summary interactions.

### Budget host

Owns the legacy Budget header flow and the Budget V2 avatar-belt flow.
It owns the budget carousel controllers, filter publication timer, long-press
limit editing state, budget preview revision, and both Budget variants'
selection callbacks.  It may reuse shared Balance rendering components for the
Budget V2 visual, but it is still the single owner of Budget state and
selection/filter publication.

### Mind host

Owns Mind frame caches, stage state, global time rail presentation, year
carousel controller, and Mind-specific chart/header interactions.

## State and lifecycle rules

- `TransactionStore` is the only shared application data source.  Its active
  type, date scope, category filter, merchant filter, and search query survive
  a mode or variant switch.
- Carousel residual offset, in-flight animation, drag state, locally selected
  visual item, collapse position, and host-local caches do not survive a
  switch.  The new visual starts from the shared store state.
- No inactive host may remain mounted, receive a ticker frame, run a timer,
  retain a gesture recognizer, or compute a render frame.
- A menu action may select another existing variant exactly as it does today;
  only the internal host routing changes.

## File boundaries

```text
lib/features/transactions/widgets/experimental/
  spendee_test_dashboard.dart             # public facade and unchanged menus
  spendee_dashboard_mode.dart             # variant enum and family mapping
  modes/
    spendee_dashboard_dependencies.dart   # immutable shared host inputs
    spendee_balance_mode_host.dart        # Balance family runtime owner
    spendee_budget_mode_host.dart         # Budget family runtime owner
    spendee_mind_mode_host.dart           # Mind family runtime owner
```

Existing visual components remain in their current files unless they are
needed by one of the hosts.  The refactor moves ownership and orchestration,
not visual design.

## Verification strategy

- Unit test the five-variant to three-family mapping.
- Widget-test that only the selected host is mounted and that a switch removes
  the previous host.
- Add lifecycle coverage proving that a host-local disposable is released when
  its variant is replaced.
- Retain the current menu keys and run existing dashboard interaction and
  contract tests to prove the menus still drive the same variants.
- Run targeted Balance, Budget V2, Mind, dashboard-mode, and dashboard
  interaction tests in the Ubuntu Flutter environment.

## Migration value

This is an intermediate architecture, not a blank-app migration.  It creates
the same three feature boundaries required later while preserving the current
prototype and A/B menu surface unchanged.  The clean migration can then port
one mode host at a time rather than excavating a monolithic dashboard.

# Architecture and Centralization Checklist

Use this reference after selecting structuring-apps. Complete the compact gate
for every code edit. Complete the full card for any new behavior, cross-file
change, data/state change, shared mechanism, UI component, or refactor.

## Compact gate

| Question | Required answer |
| --- | --- |
| Existing owner | Exact file, class, or public contract being changed |
| Shared mechanism | Existing engine/token/component to extend, or evidence that none exists |
| State boundary | Local UI only, or the controller/use case/repository owner |
| Verification | Exact focused test, static check, or direct inspection |

## Full architecture card

~~~markdown
## <Feature> architecture card

### Scope and sources
- User requirement:
- Accepted reference paths:
- Existing implementation paths:

### Single source and write path
- Source of truth:
- Read model:
- Only write path:
- Error and retry owner:

### State ownership
| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Drag preview | Local interaction controller | Pointer interaction | Never writes persistent data |
| Settled selection | Feature controller | Screen lifetime | Emits a semantic selection |
| Committed selection | Repository-backed filter | Persistent/feature lifetime | Starts data refresh |

### Reuse and centralization decision
| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Ticker belt | TickerBeltController | drag, inertia, snap, cancellation | Extend engine | Both renderers pass engine tests |

### Layer flow
UI → controller/view-model → use case/coordinator → repository → adapter

### Verification
- Domain/unit:
- Widget/integration:
- Screenshot/reference:
- Performance/cancellation:
~~~

## Centralization decision table

| Signal | Required action | Do not do |
| --- | --- | --- |
| Same state machine, swipe/drag/scroll behavior, gesture arbitration, algorithm, formatter, cache policy, or retry policy has a second consumer | Extract a small neutral engine before the second implementation | Copy it into a sibling feature and promise a later refactor |
| A deadline or an instruction to preserve a working component conflicts with shared-core extraction | Preserve public behavior while extracting internals, or stop for direction if behavior must change | Ship a copied mechanism as release debt |
| Existing component differs only in content renderer or semantic callback | Keep one shared shell and provide an adapter/builder | Fork the complete widget |
| Same semantic visual role occurs in multiple features | Route every call site through one theme token | Copy values into a feature palette |
| Dynamic entity color occurs in multiple features | Add or extend one identity-based, theme-aware resolver | Assign colors ad hoc in widgets |
| UI action triggers multiple I/O or domain operations | Add or extend a use case or coordinator | Put picking, copying, writing, processing, and retry in a screen |
| A coordinator invokes storage, network, import, processing, or multiple domain operations | Put it in its own non-presentation, independently testable file | Hide it as a private helper in a screen file |
| A file mixes visual rendering with data/cache/business logic | Extract the pure logic or coordinator by responsibility | Split only into part files while retaining one hidden owner |

## Dependency direction

| From | May depend on | Must not depend on |
| --- | --- | --- |
| Presentation | feature contract, view model, controller interface, design system | concrete repository, database, HTTP client, domain engine implementation |
| Controller/view-model | use case contract, immutable models | widget tree, persistence implementation |
| Use case/coordinator | repository and domain contracts | Flutter UI |
| Repository/adapter | storage, remote API, platform adapter | presentation |
| Domain | typed domain models and pure libraries | Flutter, database, network, platform APIs |

## Boundary-contract test layer

For every non-trivial feature, cross-file change, new UI component, state
change, shared mechanism, or refactor, add or extend a project-native
architecture/boundary test suite before implementation.

The suite should fail closed for:

- invalid dependency direction or forbidden imports/paths;
- presentation code reaching concrete persistence, network, platform, or
  domain-engine implementations;
- controllers/view-models depending on widgets, `BuildContext`, or persistence;
- multiple owners or write paths for the same state;
- storage, network, import, processing, retry, or domain workflows in UI files;
- duplicated gesture, animation, token, formatter, resolver, or other shared
  mechanisms.

Exceptions require an explicit owner, reason, scope, and removal condition.
Run focused boundary checks during implementation and the complete boundary
suite with the relevant full suite and CI before handoff. Isolated compact-gate
edits need only a focused structural check.

## Feature acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | User requirement | <path> | One source of truth and write path | Unit/integration test | NOT DONE |
| ARC-02 | Existing mechanism audit | <path> | Shared engine/token/resolver extended or no match evidenced | Code inspection plus focused test | NOT DONE |
| ARC-03 | UI reference | <path> | Shared visual tokens and reusable primitive used | Screenshot plus code inspection | NOT DONE |
| ARC-04 | Performance requirement | <path> | Expensive work begins only after committed state and can be cancelled | Performance/integration test | NOT DONE |
| ARC-05 | Delivery requirement | <path> | Every required item has truthful final status | Checklist reread | NOT DONE |
| ARC-06 | Architecture boundary | <paths> | Layer direction, forbidden dependencies, state ownership, UI workflow boundaries, and centralization contracts hold | Boundary-contract test plus direct dependency inspection | NOT DONE |

## Review triggers

- More than 500 lines: name responsibilities and identify the next clean split.
- More than 800 lines: record a coherent-unit justification or a split plan.
- New global/singleton state: prove why an injected owner cannot work.
- New raw color, duration, layout constant, or formatter: search for the
  existing semantic token or resolver first.
- New feature-local copy of a working interaction: stop and compare state
  transitions before coding.

---
name: structuring-apps
description: Use when planning, modifying, or writing any application code, including small edits, feature work, UI, data/state changes, refactors, and bug fixes, especially when a new implementation could duplicate an existing engine, workflow, resolver, formatter, visual token, or UI component.
---

# Structuring Apps

## Core rule

Create one official implementation for each shared mechanism and one owner for
each kind of state. Before changing code, read applicable instructions,
references, and the real implementation; then use
[the architecture checklist](references/architecture-checklist.md).

Do not treat different feature names or different visual renderers as evidence
that their mechanism is different.

## Run the gate before code

Use the compact gate only when the change is isolated to one responsibility and
adds no state, data flow, reusable behavior, token, or component. Record:

1. the existing owner being changed;
2. whether a shared mechanism or token already exists;
3. the focused verification.

Otherwise create an architecture card and an acceptance checklist before code.
For a non-trivial feature, present the card and obtain approval before
implementation.

Always identify:

- the single source of truth and only write path;
- local UI, feature, derived, and persistent state owners;
- UI to controller/view-model to use case/coordinator to repository to adapter
  flow;
- the existing engine, resolver, formatter, token, or component to extend;
- the required unit, widget/integration, screenshot, and performance evidence.

## Centralize mechanisms, not just widgets

Compare state transitions, algorithms, gestures, cache behavior, formatting, and
semantic decisions. If a second known consumer shares one of these, extract the
neutral shared core before implementing the second consumer.

The ticker belt is only an example. Apply the same rule to every repeated
behavioral mechanism: swipe and drag handling, gesture arbitration, scrolling,
inertia, snap, selection/commit state, animation sequencing, debouncing,
retry, caching, pagination, validation, and formatting. Different screens,
item types, or visual renderers do not make the mechanism feature-local.

For example, avatar and box ticker belts must share a TickerBelt engine for
drag, inertia, snap, preview/settled/committed selection, and cancellation.
Feature wrappers may provide typed items, an item renderer, and a semantic
callback; they must not reimplement that state machine.

Do not postpone a proven second-consumer extraction to a hypothetical third
consumer. Do not create a configurable god-widget: expose only stable
variation points and keep feature semantics in adapters.

A release deadline, a request not to alter a working component, or a need to
preserve a public API never permits a second copy of the mechanism. Preserve
the public behavior while extracting its internals; if that cannot be done
without an approved behavior change, stop and obtain direction instead of
shipping a duplicate as debt.

## Keep data and UI boundaries honest

| Layer | Owns | Must not own |
| --- | --- | --- |
| UI | rendering, input, dialogs, focus, drag preview | persistence, multi-step workflows, domain aggregation |
| Controller/view-model | feature view state and intent mapping | storage implementation |
| Use case/coordinator | multi-domain workflow, cancellation, result mapping | widgets or BuildContext |
| Repository/adapter | one persistence or remote boundary | presentation state |
| Domain engine | typed rules, validation, calculations | Flutter, database, network, platform objects |

Pass immutable view models to UI. A screen may choose a file, but a use case
must coordinate copying, persistence, processing, retries, and refresh.

Do not satisfy this boundary by hiding an I/O coordinator in a screen file. A
unit that coordinates storage, network, import, processing, or multiple domain
operations must be a non-presentation unit in its own responsibility-focused
file and be testable without a widget tree.

## Mandatory boundary-contract test layer

For every non-trivial application feature, cross-file change, new UI component,
state change, shared mechanism, or refactor, add or extend a project-native
architecture/boundary test suite before implementation.

The boundary suite must fail when any of these contracts are violated:

1. **Dependency direction**
   - presentation does not depend on concrete repositories, databases, HTTP
     clients, platform adapters, or domain-engine implementation;
   - controllers/view-models do not depend on widgets, `BuildContext`, or
     persistence implementations;
   - use cases/coordinators do not depend on Flutter UI;
   - domain code does not depend on Flutter, database, network, or platform
     APIs.
2. **Forbidden dependencies**
   - no legacy package, deprecated module, forbidden import, or forbidden path
     enters the feature;
   - forbidden dependencies are checked in production source, not only in
     tests.
3. **State ownership**
   - each state kind has one declared owner and one write path;
   - leaf widgets do not create hidden feature state, persistence workflows, or
     duplicate controllers.
4. **UI boundary**
   - UI renders supplied immutable view data and forwards intents;
   - multi-step storage, network, import, processing, retry, or domain
     workflows do not live in widgets or screen files;
   - animation and gesture engines are not duplicated in sibling widgets.
5. **Centralization**
   - shared mechanisms, tokens, formatters, resolvers, and visual policies have
     one official implementation;
   - a second implementation requires an explicit architecture decision.

Boundary tests must fail closed. Do not silence a violation with a broad
allowlist, test skip, or renamed import. Every exception must identify the
owner, reason, scope, and removal condition.

Run the focused boundary suite during implementation and run the complete
boundary suite with the relevant full test suite and CI verification at task
milestones and before handoff.

For isolated edits that qualify for the compact gate, a full boundary suite is
not required; record the owner, reuse decision, and focused structural check.

## Centralize visual decisions

Use semantic theme tokens, not feature-local raw colors. A token is centralized
only after every current use of that semantic role reads the same theme/token
source; copying old values into a new palette is a second source, not a
migration.

Use one theme-aware resolver for dynamic entity colors such as category, tag,
avatar, or chart colors. It maps stable identity and semantic role to a color,
handles contrast and fallbacks, and is not recreated in widgets.

Promote a visual primitive after two real consumers share its behavior. Keep
feature-specific composition in the feature layer.

## Protect maintainability

Review files above 500 lines for mixed responsibilities. Above 800 lines,
write a responsibility justification or split plan. Size alone is not a
failure; a cohesive renderer can be large. A file mixing UI, lifecycle, cache,
domain calculation, and persistence is a boundary failure at any size.

Keep experiments in ui_lab, demo routes, or prototypes. Move only approved
behavior into a feature. For migration, classify behavior as keep, drop, or
later; rebuild the stable data core first and move one tested vertical slice at
a time.

## Verify the structure

Add focused tests to the shared core when extracting it. Verify dependency
direction, a single write path, central token/resolver use, and every acceptance
item. Boundary-contract tests must run independently of feature behavior tests
and must be included in the project's normal CI test command. For UI
references, inspect screenshots; for expensive flows, test real data volume and
cancellation. Follow the applicable TDD, debugging, plan, and completion
workflows rather than replacing them with this skill.

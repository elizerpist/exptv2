# Pulse Engine Group Rail Design

## Status

User-approved design direction, 2026-07-22. This document governs the
standalone HTML prototype only; it is not a Flutter implementation plan.

## References

- `docs/prototypes/pulse_engine_panel_mockup.html`
- `docs/prototypes/pulse_engine_panel_mockup_acceptance.md`
- `docs/superpowers/specs/2026-07-13-hidden-forecast-pulse-design.md`
- Android visual reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260722-145619.png`

## Goal

Replace the current top-level `Manual / Forecasts / Triggers / Stories /
Tuning` rail with a group rail. Selecting a group exposes that group's complete
Pulse dossier in one vertically ordered panel, so a user can understand and
tune the calculation, forecast, trigger, story contribution, lifecycle, and
delivery without changing to five unrelated global tabs.

The three top-level groups are:

1. **Budget pressure**
2. **Cashflow pressure**
3. **Data quality**

The group rail is the primary navigation of the Pulse Engine Panel. It is not a
filter nested inside a separate Trigger page.

## Scope and invariants

- Modify only `docs/prototypes/pulse_engine_panel_mockup.html` and its related
  prototype acceptance material in this worktree.
- Do not edit `balance_latest_layout.html`.
- Keep the panel local, deterministic, AI-free, and diagnostic rather than a
  notification inbox.
- Preserve every accepted Pulse source, including visibly deferred
  `HF-008_INCOME_GOAL_RISK`.
- Preserve the original source-domain identity (`fixed_load`, `behavior_shift`,
  `engine`, and so on) as metadata on the relevant cards even when a card is
  shown inside one of the three broader display groups.
- Do not add a second nested `Manual / Forecasts / Triggers / Stories / Tuning`
  navigation. A selected group is one scrollable dossier.

## Rail and panel model

### Group rail

The existing sticky horizontal rail becomes three buttons:

```text
Budget pressure | Cashflow pressure | Data quality
```

It retains the mobile horizontal-scroll behavior and a single active tab. The
active button exposes one matching group panel and updates `aria-selected`; the
other group panels are hidden. Keyboard focus and left/right arrow navigation
should follow the tab pattern.

The existing high-level group rows above the rail remain a concise engine
summary. Each row becomes an affordance that selects its corresponding rail
group, so the summary and the detailed panel never disagree.

### Group dossier order

Every group panel uses the same ordered sections:

1. **How this group works** — plain-language purpose, source inputs, formula or
   calculation path, current signal count, and confidence considerations.
2. **Forecasts and calculations** — only charts and calculated states that feed
   this group.
3. **Trigger events** — one complete audit card per relevant HF source. Each
   card retains its current value/state, trigger condition, mini-chart or
   formula evidence, transition/lifecycle details, and local user-defined
   control.
4. **Story, lifecycle, and header path** — how the group's signals combine,
   wait, become eligible, are suppressed or superseded, and reach the single
   header story.
5. **Tuning** — group-level controls plus the existing per-card controls.

This removes the need to mentally collect a forecast from one global tab, its
trigger from another, and its delivery rules from a third.

## Trigger placement

### Budget pressure

Display these sources in the Budget pressure dossier:

| Source | Role in this display group |
| --- | --- |
| HF-001 | Month-end expense forecast |
| HF-002 | Monthly category-limit burn |
| HF-003 | Daily safe-spend coach signal |
| HF-004 | Weekly variable-spend pace |
| HF-012 | Top-category rolling-30-day spike (`behavior_shift`) |
| HF-013 | Total rolling-30-day spend trend (`behavior_shift`) |
| HF-014 | Existing score direction (`behavior_shift`) |
| HF-015 | Budget-target zone supersede |
| HF-020 | Yearly category-limit burn |

The dossier must make clear that `HF-012` through `HF-014` retain their
`behavior_shift` source domain even though the user understands them through
the broader Budget pressure group.

### Cashflow pressure

Display these sources in the Cashflow pressure dossier:

| Source | Role in this display group |
| --- | --- |
| HF-005 | Monthly fixed-cost load (`fixed_load`) |
| HF-006 | Next-seven-days recurring expense (`fixed_load`) |
| HF-007 | Missing or overdue expected income |
| HF-008 | Income-goal risk, visible as explicitly deferred / not active |
| HF-009 | Expense-to-income ratio |
| HF-010 | Saving-goal forecast |
| HF-011 | Balance-buffer days |

The group must explain that fixed-load signals can compose with cashflow or
budget stories but remain distinct raw signals.

### Data quality

Display `HF-021_UNCATEGORIZED_STATUS` in the Data quality dossier. Its panel
must show the inspected data condition, confidence impact on affected forecasts,
delayed/grouped eligibility, resolution after categorization, and the
user-defined delay/feedback control.

## Shared engine trace

The following mechanisms do not become a fourth rail item. Instead, each group
ends with a compact, clearly labelled **Shared engine trace** that explains how
that group's signals pass through the common engine:

| Source | Shared mechanism |
| --- | --- |
| HF-016 | Priority, relevance filtering, grouping, scoring, and selection of one header story |
| HF-017 | Fingerprint, lifecycle, suppress, resolve, and retrigger rules |
| HF-018 | Selected-story header morph delivery |
| HF-019 | The inspectable Pulse Engine Panel itself and its diagnostic depth |

The trace must identify these as engine mechanics, not additional financial
detectors. It must be visible from every selected group so no Pulse-affecting
rule is hidden behind an unrelated menu.

## Content and interaction rules

- The old five top-level labels must not remain as primary rail navigation.
- Do not drop a source simply because its forecast is also represented in a
  higher-level chart; every source retains its own audit card in exactly one
  display group.
- Deferred `HF-008` remains readable in Cashflow pressure but cannot be shown
  as an active V1 trigger.
- The header preview continues to show only one selected composed story. Group
  navigation never turns the panel into a queue or changes header delivery by
  itself.
- Existing range/select controls continue to update their visible outputs where
  applicable. New group-level controls are constrained and explainable.
- Empty, waiting, suppressed, resolved, and recovery states remain visibly
  distinct from an active trigger.

## Verification

1. Static HTML checks confirm exactly three group rail buttons and no old
   five-item primary rail.
2. Static checks verify each accepted HF source is present in its prescribed
   group, that HF-008 is deferred, and that HF-016 through HF-019 appear in the
   shared engine trace.
3. Browser checks on `http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html`
   verify all three group buttons, mobile horizontal rail behavior, readable
   sequential dossiers, and working group summary affordances.
4. Android screenshots verify that the replacement rail and each group panel
   remain readable without clipping or control overlap.

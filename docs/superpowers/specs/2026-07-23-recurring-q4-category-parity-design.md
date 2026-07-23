# Recurring Wizard Q3A and Q4 Category Parity Design

## Goal

Simplify the pre-step trigger chooser and make the Push-trigger basics screen use the approved Q2 inline category-picker pattern without visual drift in text-input pills.

## Approved Inputs

- User instruction, 2026-07-23: Q3A is initialization only, so it must not show a progress bar or the `0. lépés a 9-ből` label.
- User instruction, 2026-07-23: Q4 contains only name, category selection, and `Tovább`; categories appear in the same small inline window as Q2, followed by `Új kategória`; partner and note are absent.
- User instruction, 2026-07-23: every wizard text-input pill matches Q2 in color and shape.
- Mandatory HTML reference: `docs/prototypes/color_lab.html`, Q2 (`alt-query-add-transaction-duplicate`) and the Q3A/Q4 recurring screens.

## Design

### Q3A: Trigger Type Initialization

Keep the existing Q2-height recurring sheet, navigation shell, Push/Idő trigger choices, default Push selection, and `Tovább` CTA. Remove only the pre-step progress markup and the `0. lépés a 9-ből` kicker. Q3A remains structurally distinct from Push step 1 and never receives `data-recurring-push-step="0"`.

### Q4: Push Basics

Q4 retains the shared Push step-1 chrome (including its step-1 progress state), but its editable content is limited to:

1. One Q2-styled name pill, using the existing Q2 `pill-field transaction-name-pill` presentation.
2. The existing Q2 inline category picker structure (`transaction-inline-category-picker`, window, list, and selectable rows). The Q4 default selection is the existing `Lakás` row, which matches the `Lakbér` sample name.
3. The existing Q2 `Új kategória` action directly below the inline window.
4. The existing wizard `Tovább` CTA.

Q4 does not show a separate category pill, Partner/Kedvezményezett, or Megjegyzés fields. It does not add a new category-picker implementation or a new popup flow.

### Wizard Text-Input Pill Parity

Use the Q2 pill visual contract for every recurring text-input field (`.recurring-wizard-field` and the Q4 name pill): white translucent fill, Q2 border color, soft-card shadow, and pill-shaped rounding. Preserve existing two-line label/value content where a later wizard screen already uses it. Do not restyle choice cards, tokens, notification cards, summary cards, or progress indicators as input pills.

## Test Strategy

Extend `docs/prototypes/color_lab_static_test.js` before HTML changes. The scoped tests must prove:

- Q3A has no progress element, no trigger-progress data attribute, and no zero-step kicker while retaining the chooser and CTA.
- Q4 contains one Q2 name pill, one Q2-shaped inline category picker, `Lakás` selected, and `Új kategória` immediately after the picker.
- Q4 excludes the legacy category pill, Partner/Kedvezményezett, and Megjegyzés content.
- The recurring text-field CSS carries the same Q2 pill fill, border, shadow, and round profile; Q2 itself remains unchanged.
- The full static suite passes after the change.

## Scope Boundaries

- No runtime wizard routing changes.
- No changes to Q5–Q12 content or step progress behavior beyond shared text-input pill styling.
- No changes to the Q2 prototype content or its category-create wizard.

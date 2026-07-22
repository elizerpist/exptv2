# Q4–Q12 Recurring Push Wizard Redesign

## Goal

Replace the obsolete Q2A category-route screen and the old shared/time/push recurring-wizard branch with nine reference-faithful Push-trigger wizard screens. The target is the active Color Lab prototype, not the Flutter application.

## Mandatory reference

Re-read and inspect `/storage/emulated/0/spendee/recurring_new.png` before implementation and before final visual verification. The 1024×1536 reference is the approved visual/interaction source for this package.

The screenshot defines a nine-step Push-trigger flow:

1. Alapadatok
2. Összeg beállítása
3. Gyakoriság és időzítés
4. Trigger forrása
5. Értesítés kiválasztása
6. Mezők kijelölése
7. Egyezési szabályok
8. Trigger viselkedése
9. Összegzés

## Scope and screen order

The Query row keeps Q1A, Q2, Q3, and Q13–Q15. Delete Q2A completely. Replace the existing Q4–Q12 shared chooser, four time-based screens, and four push-based screens in place with the nine Push-trigger screens above.

The resulting Query row order is:

`Q1A → Q2 → Q3 → Q4 → Q5 → Q6 → Q7 → Q8 → Q9 → Q10 → Q11 → Q12 → Q13 → Q14 → Q15`.

The green `Visszatérő tranzakció létrehozva!` completion panel shown in the reference is not a tenth Query-row screen. Q12 is the final numbered summary step and owns the `Létrehozás` CTA.

## Layout and behavior

Each Q4–Q12 screen renders one edge-to-edge recurring-wizard bottom sheet inside its phone mockup. The sheet uses the current Q2 inline-category geometry contract: `--query-inline-category-sheet-h: 570px`, `left: 0`, `right: 0`, `bottom: 0`, and `26px 26px 0 0` top radius. It has one grabber, one route header, a scrollable content region, a progress indicator, and a bottom CTA; it must not create nested sheets, dialogs, or extra floating cards.

The screens are intentionally visible side by side in the prototype. Controls remain independently tappable within a screen, updating local `selected` and `aria-pressed` state; cross-screen navigation is represented by the ordered screen sequence rather than a runtime router.

| Screen | Reference content |
| --- | --- |
| Q4 | `Alapadatok`: name, category, partner/beneficiary, optional note. |
| Q5 | `Összeg beállítása`: fixed/range/any amount selection, amount and tolerance fields. |
| Q6 | `Gyakoriság és időzítés`: frequency, interval/day, first due date, and completion window. |
| Q7 | `Trigger forrása`: choose an already received notification, wait for the next one, or paste an example. |
| Q8 | `Értesítés kiválasztása`: notification cards with one selected example. |
| Q9 | `Mezők kijelölése`: notification preview plus selectable amount, partner, date, and optional-note fields. |
| Q10 | `Egyezési szabályok`: amount tolerance, partner matching, date window, and required keywords. |
| Q11 | `Trigger viselkedése`: automatic creation, confirmation, or candidate-only behavior and actual-amount treatment. |
| Q12 | `Összegzés`: an auditable review of all configured data with the final `Létrehozás` CTA. |

## Acceptance checklist

| ID | Source instruction / reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| RPW-001 | User: `a legfrissebbet fogod szerkeszteni` | `spendeetest-worktree/docs/prototypes/color_lab.html` | Only the active `spendeetest-worktree` Color Lab prototype is changed for this package. | `git diff --name-only` and direct source inspection. | NOT DONE |
| RPW-002 | User: `q2a törlöd` | Query-row markup and `color_lab_static_test.js` | The Q2A title, `alt-query-category-route-sheet` block, its route-only contracts, and its static-test expectations are absent; Query row has 15 screen columns. | Targeted no-match `rg` plus static test. | NOT DONE |
| RPW-003 | User: `q4-q12 fogod teljesen újratervezni. töröld is` | Q4–Q12 recurring markup, CSS, initializer, and static test | The old shared chooser plus time/push branch contracts are removed rather than cosmetically retained. | Targeted no-match `rg`, DOM count/order assertions, and source review. | NOT DONE |
| RPW-004 | User: `a wizard minden lépésének új screent fogsz csinálni` + approved mapping | Q4–Q12 markup | Exactly nine new ordered screens exist, one for each approved Push-trigger step from `Alapadatok` through `Összegzés`. | Static screen-count/order assertions and direct source inspection. | NOT DONE |
| RPW-005 | User: `a screenben egy sheet legyen, ami olyan magas, mint q2` | Recurring-sheet CSS and nine screen blocks | Every Q4–Q12 screen has exactly one edge-to-edge bottom sheet using Q2's current 570px `--query-inline-category-sheet-h` geometry; no nested dialog, popup, or extra sheet exists. | CSS/DOM assertions and HTTP-served visual inspection. | NOT DONE |
| RPW-006 | `/storage/emulated/0/spendee/recurring_new.png` | Q4–Q12 sheet content and styling | Each step's hierarchy, fields, option cards, progress treatment, and CTA match the named reference step rather than the former time/push design. | Re-inspect reference; side-by-side manual screenshot comparison; static content assertions. | NOT DONE |
| RPW-007 | Existing prototype interaction contract | Recurring-wizard initializer and controls | Choices remain tappable and update local `selected`/`aria-pressed` state without affecting Q1A or category-wizard behavior. | Focused DOM interaction smoke, inline JavaScript parse, and static test. | NOT DONE |
| RPW-008 | User: `annyi screen lesz ahány lépés` | Query-row order and Q12 final CTA | Q12 is the ninth and final numbered wizard screen. The reference completion card is not added as Q13 or another Query-row screen. | Screen-order/count assertion and source inspection. | NOT DONE |

## Non-goals

- Do not change the Q2 expense sheet, Q3 income sheet, or Q13–Q15 category wizard content except for required Query-row count/order assertions.
- Do not modify the Flutter runtime implementation; this package is limited to the HTML prototype and its static checks.
- Do not keep the old time-based or generic Push branch as hidden fallback markup.

## Verification plan

After implementation, re-inspect the mandatory PNG and compare the rendered Q4–Q12 row against it. Run the focused Color Lab static test, parse the inline JavaScript, run `git diff --check`, and perform an HTTP source/asset smoke. The acceptance table above must be updated honestly; no feature-complete claim is valid while an item remains `PARTIAL`, `BLOCKED`, or `NOT DONE`.

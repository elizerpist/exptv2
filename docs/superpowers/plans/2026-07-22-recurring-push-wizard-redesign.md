# Recurring Push Wizard Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Q2A and the former dual-branch recurring wizard with nine Q4–Q12 Push-trigger reference screens that each use one Q2-sized bottom sheet.

**Architecture:** The Query row remains a static, side-by-side HTML prototype. Q2A is deleted with its private CSS, then Q4–Q12 become nine explicit phone-screen blocks using one reusable recurring-sheet CSS shell and scoped selectable-control initializer. The static Node test is the structural regression harness; visual comparison against the approved PNG proves the layout/content contract.

**Tech Stack:** HTML, CSS, inline browser JavaScript, Node.js `assert` static test runner, Git.

## Global Constraints

- Work only in `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree`.
- Treat `/storage/emulated/0/spendee/recurring_new.png` as mandatory visual reference before editing and final verification.
- Keep Q1A, Q2, Q3, and Q13–Q15 content unchanged, except for Query-row ordering/count assertions caused by Q2A deletion.
- Q4–Q12 must use one edge-to-edge `570px` sheet (`--query-inline-category-sheet-h`, the current Q2 token) per screen; no nested dialog, popup, or extra sheet.
- The final numbered wizard screen is Q12. Do not add a tenth Query-row success screen.
- Do not stage or commit pre-existing unrelated worktree changes. Stage only paths named in each task.

## File Structure

- Modify: `docs/prototypes/color_lab.html`
  - Delete Q2A markup at the current Query-row position and the CSS selectors used only by that route.
  - Replace the existing Q4–Q12 chooser/time/push markup, branch-only CSS, and selection grouping with a nine-step Push-trigger presentation.
- Modify: `docs/prototypes/color_lab_static_test.js`
  - Change the Query-row count/order, remove Q2A contracts, assert the nine new screen contracts, and retain the Q2 geometry and scoped-selection checks.
- Modify after verified implementation: `docs/superpowers/specs/2026-07-22-recurring-push-wizard-redesign-design.md`
  - Update `RPW-001` through `RPW-008` from `NOT DONE` only with observed verification evidence.
- Create: this plan file.

The implementation tasks are sequential because both alter the same large HTML file and the same static-test file. Do not run them in parallel.

---

### Task 1: Delete Q2A and its orphaned category-route implementation

**Files:**

- Modify: `docs/prototypes/color_lab.html:11384-11668,14372-14427`
- Modify: `docs/prototypes/color_lab_static_test.js:1095-1240,5608-5700`

**Interfaces:**

- Consumes: Query row identifiers `alt-query-add-transaction-duplicate`, `alt-query-add-income-transaction`, and the unchanged old Q4–Q12 identifiers.
- Produces: a 15-column Query row ordered `Q1A → Q2 → Q3 → Q4–Q12 → Q13–Q15`; no `alt-query-category-route-sheet`, `data-transaction-category-route`, or `category-route-*` implementation remains.

- [x] **Step 1: Write the failing Q2A-removal assertions in the static test**

  Replace the 16-column/Q2A portion of the Query-row test with the following exact expectations. Keep the old recurring identifiers in this task; Task 2 changes them.

  Also reduce the global phone-screen expectation from `35` to `34` and remove the Q2A reference from its message:

  ```js
  assert.strictEqual(
    screenCount,
    34,
    'Expected cleaned lower Fluvi/dashboard/edit screens, common-header B3M mother-child preview, B/C/D rows, Q1A, Q2/Q3, nine recurring wizard screens, and three category wizard popup screens',
  );
  ```

  ```js
  assert.strictEqual(
    (queryMenuBlock.match(/<div class="screen-column"/g) || []).length,
    15,
    'Query Menu row must render Q1A, Q2, Q3, nine recurring screens, and Q13-Q15 after Q2A deletion',
  );

  const queryRowScreenOrder = [
    queryMenuBlock.indexOf('data-screen="alt-query-menu-category-vendor-hierarchy"'),
    queryMenuBlock.indexOf('data-screen="alt-query-add-transaction-duplicate"'),
    queryMenuBlock.indexOf('data-screen="alt-query-add-income-transaction"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-type"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-time-frequency"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-time-timepoint"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-time-duration"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-time-review"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-push-message"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-push-elements"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-push-selection"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-wizard-push-review"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-icon-popup"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-name-popup"'),
  ];
  assert(
    queryRowScreenOrder.every((index) => index >= 0) &&
      queryRowScreenOrder.every((index, indexInOrder, entries) =>
        indexInOrder === 0 || entries[indexInOrder - 1] < index,
      ) &&
      !queryMenuBlock.includes('Q2A ·') &&
      !queryMenuBlock.includes('data-screen="alt-query-category-route-sheet"') &&
      !queryMenuBlock.includes('data-transaction-category-route') &&
      !queryMenuBlock.includes('data-sheet-route-stack="category-picker-create"'),
    'Q2A category-route markup must be fully removed while the remaining Query row stays ordered',
  );

  const queryQ2ScreenBlock =
    queryQ2ScreenStart >= 0 && queryQ3ScreenStart > queryQ2ScreenStart
      ? queryMenuBlock.slice(queryQ2ScreenStart, queryQ3ScreenStart)
      : '';
  ```

  Delete `queryQ2AScreenStart`, `queryQ2ATitleStart`, `queryQ2AScreenBlock`, and the old positive Q2A assertion. Change the six header/logo counter expectations that include Q2A: `14 → 13`, `10 → 9`, `14 → 13`, `14 → 13`, `10 → 9`, and `10 → 9`; change the two lower-lockup counts `18 → 17`.

- [x] **Step 2: Run the focused static test and confirm it is red**

  Run:

  ```sh
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
  node docs/prototypes/color_lab_static_test.js
  ```

  Expected: failure at the 15-column assertion or a Q2A absence assertion, because the current source still contains Q2A.

- [x] **Step 3: Remove the Q2A markup and its route-only CSS**

  In `color_lab.html`, delete the entire `<div class="screen-column">` headed `Q2A · Kategória sheet route`, from its opening wrapper through its matching closing wrapper. Do not alter Q2 or Q3 markup.

  Delete the CSS implementation that has no remaining consumer:

  ```css
  .transaction-category-route-card .transaction-form-redesign
  .transaction-route-nav
  .transaction-route-nav button
  .transaction-route-title
  .transaction-route-title span
  .transaction-route-title strong
  .transaction-category-route-stack
  .category-route-search
  .transaction-category-route-scroll
  .category-route-section
  .category-route-section-title
  .category-route-row
  .category-route-row.selected
  .category-route-icon
  .category-route-icon .slot-icon
  .category-route-copy
  .category-route-copy strong
  .category-route-copy span
  .category-route-check
  .category-inline-create-panel
  .category-inline-create-panel header
  .category-inline-create-panel header strong
  .category-inline-create-panel header span
  .category-create-actions
  .category-create-actions button
  .category-create-actions button:first-child
  .category-create-actions button:last-child
  ```

  Preserve category-wizard popup classes used by Q13–Q15; delete only selectors whose names and source search are limited to the removed Q2A route.

- [x] **Step 4: Run the static test and the no-orphan search**

  Run:

  ```sh
  node docs/prototypes/color_lab_static_test.js
  if rg -n 'Q2A|alt-query-category-route-sheet|data-transaction-category-route|data-sheet-route-stack|category-route-' \
    docs/prototypes/color_lab.html; then exit 1; fi
  if rg -n 'queryQ2AScreenStart|queryQ2ATitleStart|queryQ2AScreenBlock' \
    docs/prototypes/color_lab_static_test.js; then exit 1; fi
  ```

  Expected: the static test prints `Color lab static checks passed`; both no-match guards exit zero. The test is allowed to retain Q2A strings only in explicit negative assertions.

- [x] **Step 5: Commit the independently passing Q2A removal**

  Run:

  ```sh
  git add -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
  git diff --cached --check
  git commit -m "feat: remove Q2A category route"
  ```

### Task 2: Replace Q4–Q12 with the approved nine-step Push-trigger wizard

**Files:**

- Modify: `docs/prototypes/color_lab.html:9456-9917,14514-14777,21612-21630`
- Modify: `docs/prototypes/color_lab_static_test.js:1393-1498`

**Interfaces:**

- Consumes: the one-sheet frame `recurring-wizard-screen`, `recurring-wizard-sheet`, `recurring-wizard-scroll`, `recurring-wizard-footer`, and Q2's `--query-inline-category-sheet-h` token.
- Produces: nine blocks with `data-recurring-push-step="1"` through `data-recurring-push-step="9"`, nine unique `data-screen` values, and scoped selectable controls bound by `initRecurringWizardPrototype()`.

- [x] **Step 1: Replace the old chooser/time/push test contract with the new red contract**

  Replace the recurring assertion block with this screen interface. Each anchors array is an explicit content requirement, not optional copy.

  ```js
  const recurringPushWizardScreens = [
    ['Q4 · Push trigger · Alapadatok', 'alt-recurring-push-basics', '1', ['Várható tranzakció', 'Név', 'Kategória', 'Partner / Kedvezményezett', 'Megjegyzés (opcionális)']],
    ['Q5 · Push trigger · Összeg beállítása', 'alt-recurring-push-amount', '2', ['Várható összeg', 'Fix összeg', 'Tartomány', 'Bármilyen', 'Tolerancia (opcionális)']],
    ['Q6 · Push trigger · Gyakoriság és időzítés', 'alt-recurring-push-schedule', '3', ['Gyakoriság', 'Ismétlődés', 'Minden hónap', 'Első esedékesség', 'Időablak a teljesítéshez']],
    ['Q7 · Push trigger · Trigger forrása', 'alt-recurring-push-source', '4', ['Hogyan ismerjük fel?', 'Válassz egy elkapott értesítést', 'Várj a következő értesítésre', 'Illessz be egy példát']],
    ['Q8 · Push trigger · Értesítés kiválasztása', 'alt-recurring-push-notification', '5', ['Elkapott értesítések', 'Revolut', 'Több megjelenítése']],
    ['Q9 · Push trigger · Mezők kijelölése', 'alt-recurring-push-fields', '6', ['Jelöld ki a megfelelő mezőket', 'Összeg', 'Partner', 'Dátum', 'Megjegyzés (opcionális)']],
    ['Q10 · Push trigger · Egyezési szabályok', 'alt-recurring-push-matching', '7', ['Egyezési beállítások', 'Összeg egyezése', 'Partner egyezése', 'Dátumablak', 'Kötelező szavak (opcionális)']],
    ['Q11 · Push trigger · Trigger viselkedése', 'alt-recurring-push-behavior', '8', ['Teljesítéskor történjen', 'Automatikus teljesítés', 'Megerősítést kérek', 'Csak jelölje lehetséges egyezésként', 'Tényleges összeg']],
    ['Q12 · Push trigger · Összegzés', 'alt-recurring-push-summary', '9', ['Ellenőrizd az adatokat', 'Trigger összefoglaló', 'Létrehozás']],
  ];

  const recurringPushScreenStarts = recurringPushWizardScreens.map(([title]) =>
    queryMenuBlock.indexOf(`<div class="screen-title">${title}</div>`),
  );
  assert.strictEqual(
    (queryMenuBlock.match(/data-recurring-push-step="[1-9]"/g) || []).length,
    9,
    'Q4-Q12 must render exactly one Push-trigger sheet for every approved reference step',
  );
  assert.strictEqual(
    (queryMenuBlock.match(/data-recurring-wizard-reference="\/storage\/emulated\/0\/spendee\/recurring_new\.png"/g) || []).length,
    9,
    'Every Push-trigger screen must point directly at the approved recurring_new reference',
  );
  assert(
    recurringPushScreenStarts.every((start) => start >= 0) &&
      recurringPushScreenStarts.every((start, index) => index === 0 || recurringPushScreenStarts[index - 1] < start),
    'Q4-Q12 Push-trigger screens must be present once and in reference-step order',
  );
  for (const [index, [title, screenName, step, anchors]] of recurringPushWizardScreens.entries()) {
    const start = recurringPushScreenStarts[index];
    const end = recurringPushScreenStarts[index + 1] ?? queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"');
    const screenBlock = start >= 0 && end > start ? queryMenuBlock.slice(start, end) : '';
    assert(
      screenBlock.includes(`data-screen="${screenName}"`) &&
        screenBlock.includes(`data-recurring-push-step="${step}"`) &&
        screenBlock.includes('data-recurring-wizard-size="q2-inline-sheet"') &&
        screenBlock.includes('data-recurring-push-progress') &&
        (screenBlock.match(/class="recurring-wizard-sheet"/g) || []).length === 1 &&
        anchors.every((anchor) => screenBlock.includes(anchor)),
      `Missing scoped Push-trigger wizard contract for ${title}`,
    );
  }
  assert(
    !queryMenuBlock.includes('alt-recurring-wizard-type') &&
      !queryMenuBlock.includes('alt-recurring-wizard-time-frequency') &&
      !queryMenuBlock.includes('alt-recurring-wizard-time-timepoint') &&
      !queryMenuBlock.includes('alt-recurring-wizard-time-duration') &&
      !queryMenuBlock.includes('alt-recurring-wizard-time-review') &&
      !queryMenuBlock.includes('alt-recurring-wizard-push-message') &&
      !queryMenuBlock.includes('alt-recurring-wizard-push-elements') &&
      !queryMenuBlock.includes('alt-recurring-wizard-push-selection') &&
      !queryMenuBlock.includes('alt-recurring-wizard-push-review') &&
      !queryMenuBlock.includes('data-recurring-wizard-branch='),
    'The former chooser/time/push branch implementation must not remain in the Query row',
  );
  ```

  Require Q2's `--query-inline-category-sheet-h: 570px` token and require `.recurring-wizard-sheet` to use `height: var(--query-inline-category-sheet-h)`. The assertion must reject `height: var(--query-sheet-h)` for this wizard. Remove the old four-step chooser-only assertions.

- [x] **Step 2: Run the focused static test and confirm it is red**

  Run:

  ```sh
  node docs/prototypes/color_lab_static_test.js
  ```

  Expected: failure naming Q4 `alt-recurring-push-basics`, because no new Push-trigger screen exists yet.

- [x] **Step 3: Implement the shared nine-step sheet shell, markup, and scoped interaction**

  Replace the legacy Q4–Q12 blocks with nine explicit `<div class="screen-column">` blocks. Every block must include this outer contract; only the content inside `recurring-wizard-scroll` varies:

  ```html
  <section class="phone-screen spendee-dashboard-screen recurring-wizard-screen"
    data-screen="alt-recurring-push-basics"
    data-recurring-wizard-screen="push-basics"
    data-recurring-push-step="1"
    data-recurring-wizard-size="q2-inline-sheet"
    data-recurring-wizard-reference="/storage/emulated/0/spendee/recurring_new.png"
    aria-label="Push trigger wizard: Alapadatok">
    <div class="recurring-wizard-bg" aria-hidden="true"></div>
    <section class="recurring-wizard-sheet" role="dialog" aria-label="Alapadatok">
      <div class="recurring-wizard-grabber"></div>
      <header class="recurring-wizard-nav"><button type="button" aria-label="vissza">‹</button><h3>Visszatérő tranzakció</h3><button type="button" aria-label="bezárás">×</button></header>
      <div class="recurring-wizard-scroll">
        <div class="recurring-wizard-progress" data-recurring-push-progress aria-label="1. lépés a 9-ből"><span class="active"></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span></div>
        <span class="recurring-wizard-kicker">1. lépés a 9-ből</span>
        <h3 class="recurring-wizard-title">Alapadatok</h3>
        <p class="recurring-wizard-subtitle">Add meg a várható visszatérő tranzakció alapadatait.</p>
        <div class="recurring-wizard-field-grid">
          <div class="recurring-wizard-mini-field"><span>Név</span><strong>Lakbér</strong></div>
          <div class="recurring-wizard-mini-field"><span>Kategória</span><strong>Lakhatás</strong></div>
          <div class="recurring-wizard-mini-field"><span>Partner / Kedvezményezett</span><strong>Kovács Péter</strong></div>
          <div class="recurring-wizard-mini-field"><span>Megjegyzés (opcionális)</span><strong>Albérlet díja</strong></div>
        </div>
      </div>
      <footer class="recurring-wizard-footer"><button class="recurring-wizard-back" type="button">‹</button><button class="recurring-wizard-primary" type="button">Tovább</button></footer>
    </section>
  </section>
  ```

  For Q5–Q12, use the same shell. For step `n`, give the first `n - 1` progress spans `complete`, give the nth span `active`, and leave the remaining spans plain. Add the following exact screen-specific content:

  | Screen | Required interactive/content blocks |
  | --- | --- |
  | Q4 | Fields for `Név`=`Lakbér`, `Kategória`=`Lakhatás`, `Partner / Kedvezményezett`=`Kovács Péter`, and `Megjegyzés (opcionális)`=`Albérlet díja`; CTA `Tovább`. |
  | Q5 | A single-select `data-recurring-wizard-choice-group` for `Fix összeg`, `Tartomány`, `Bármilyen`; mini-fields `Összeg`=`180 000 Ft` and `Tolerancia (opcionális)`=`± 5 000 Ft`; CTA `Tovább`. |
  | Q6 | Selectable `Ismétlődés`=`Havonta`, mini-fields for `Minden hónap`=`5. napján`, `Első esedékesség`=`2025.08.05.`, and the completion window `-3 nap` / `+5 nap`; CTA `Tovább`. |
  | Q7 | A single-select group with `Válassz egy elkapott értesítést`, `Várj a következő értesítésre`, and `Illessz be egy példát`; keep the reference explanatory lines; CTA `Tovább`. |
  | Q8 | A notification-card single-select group headed `Elkapott értesítések`, with selected `Revolut · Ma 13:42` and two additional Revolut notifications plus `Több megjelenítése`; CTA `Tovább`. |
  | Q9 | A Revolut notification preview containing `180 000 Ft összeget küldtél neki: Kovács Péter`, then multi-select field tokens `Összeg`, `Partner`, `Dátum`, and `Megjegyzés (opcionális)`; CTA `Tovább`. |
  | Q10 | Selectable matching fields for `Összeg egyezése`=`± 5 000 Ft`, `Partner egyezése`=`Tartalmazza a nevet`, `Dátumablak`=`-3 nap és +5 nap`, and keyword chips `küldtél`, `neki`, `+ kulcsszó`; CTA `Tovább`. |
  | Q11 | A single-select behavior group for `Automatikus teljesítés`, `Megerősítést kérek`, and `Csak jelölje lehetséges egyezésként`; select `Megerősítést kérek`; add `Tényleges összeg`=`A pushból származó összeg`; CTA `Tovább`. |
  | Q12 | Review rows for name, partner, amount/tolerance, schedule/window, and trigger source; a `Trigger összefoglaló` card naming Revolut and the matching conditions; final CTA `Létrehozás`. |

  Remove the legacy type-choice CSS and all selectors tied to `data-recurring-wizard-branch`, `data-recurring-type-nav`, `data-recurring-wizard-choice`, four-column `.recurring-wizard-stepper`, and its pseudo-line. Add a compact nine-dot CSS contract:

  ```css
  .recurring-wizard-progress {
    display: grid;
    grid-template-columns: repeat(9, minmax(0, 1fr));
    gap: 6px;
    margin: 2px 0 14px;
  }

  .recurring-wizard-progress span {
    height: 5px;
    border-radius: 999px;
    background: rgba(203,213,225,.72);
  }

  .recurring-wizard-progress span.active,
  .recurring-wizard-progress span.complete {
    background: #06b6d4;
  }
  ```

  Set `.recurring-wizard-sheet` to `height: var(--query-inline-category-sheet-h)` and preserve its edge-to-edge geometry. Reuse existing card, token, mini-field, info-box, and footer styles where they match the reference; add only scoped selector names needed for notification cards, field tokens, matching rows, and review rows.

  Replace the initializer's hard-coded legacy container selector with an attribute-scoped group implementation:

  ```js
  function initRecurringWizardPrototype() {
    document.querySelectorAll('[data-recurring-wizard-selectable]').forEach((control) => {
      if (control.dataset.recurringWizardBound === 'true') return;
      control.dataset.recurringWizardBound = 'true';
      control.addEventListener('click', () => {
        const group = control.closest('[data-recurring-wizard-choice-group]');
        const allowMultiple = control.hasAttribute('data-recurring-wizard-multiselect');
        if (group && !allowMultiple) {
          group.querySelectorAll('[data-recurring-wizard-selectable]').forEach((peer) => {
            peer.classList.remove('selected');
            peer.setAttribute('aria-pressed', 'false');
          });
        }
        const nextState = allowMultiple ? !control.classList.contains('selected') : true;
        control.classList.toggle('selected', nextState);
        control.setAttribute('aria-pressed', nextState ? 'true' : 'false');
      });
    });
  }
  ```

  Wrap each exclusive radio-like set in `data-recurring-wizard-choice-group`; put `data-recurring-wizard-multiselect` on field and keyword tokens that may be selected together.

- [x] **Step 4: Run structural, syntax, and removal checks until green**

  Run:

  ```sh
  node docs/prototypes/color_lab_static_test.js
  node -e "const fs=require('fs');const h=fs.readFileSync('docs/prototypes/color_lab.html','utf8');for(const [,s] of h.matchAll(/<script>([\\s\\S]*?)<\\/script>/g))new Function(s);console.log('inline scripts parsed');"
  rg -n 'alt-recurring-wizard-type|alt-recurring-wizard-time-|alt-recurring-wizard-push-|data-recurring-wizard-branch|data-recurring-type-nav|data-recurring-wizard-choice=' docs/prototypes/color_lab.html
  ```

  Expected: static test prints `Color lab static checks passed`; inline parser prints `inline scripts parsed`; the last search prints no matches.

- [x] **Step 5: Commit the independently passing nine-screen rewrite**

  Run:

  ```sh
  git add -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
  git diff --cached --check
  git commit -m "feat: redesign recurring push wizard"
  ```

### Task 3: Verify the reference match and update the acceptance evidence

**Files:**

- Modify: `docs/superpowers/specs/2026-07-22-recurring-push-wizard-redesign-design.md`
- Verify: `docs/prototypes/color_lab.html`
- Verify: `docs/prototypes/color_lab_static_test.js`

**Interfaces:**

- Consumes: the Q2A-free Query row and the nine Push-trigger screen contracts from Tasks 1–2.
- Produces: evidence-backed `DONE` statuses for `RPW-001`–`RPW-008`, or explicit `PARTIAL` statuses for any unverified visual condition.

- [ ] **Step 1: Re-open the mandatory image and compare each screen intentionally** *(PARTIAL — the reference was re-opened and compared to source, but no local browser renderer was available for a rendered side-by-side capture.)*

  Inspect `/storage/emulated/0/spendee/recurring_new.png` beside the rendered/served prototype. Confirm the following visible mapping: Q4 basics, Q5 amount selection, Q6 schedule, Q7 source choice, Q8 notifications, Q9 highlighted fields, Q10 rules, Q11 behavior, Q12 summary. Confirm Q12 has `Létrehozás` and no Q13 completion screen was created.

- [x] **Step 2: Perform a local HTTP source smoke**

  Run:

  ```sh
  cd docs/prototypes
  python3 -m http.server 4173 >/tmp/color-lab-http.log 2>&1 &
  server_pid=$!
  trap 'kill "$server_pid"' EXIT
  curl -fsS http://127.0.0.1:4173/color_lab.html | rg -q 'data-recurring-push-step="9"'
  curl -fsS http://127.0.0.1:4173/color_lab.html | rg -q 'data-recurring-wizard-reference="/storage/emulated/0/spendee/recurring_new.png"'
  ```

  Expected: both `curl` checks exit zero. Stop the server when the shell exits.

- [x] **Step 3: Run final automated verification**

  Run:

  ```sh
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
  node docs/prototypes/color_lab_static_test.js
  node -e "const fs=require('fs');const h=fs.readFileSync('docs/prototypes/color_lab.html','utf8');for(const [,s] of h.matchAll(/<script>([\\s\\S]*?)<\\/script>/g))new Function(s);console.log('inline scripts parsed');"
  git diff --check HEAD
  git diff --name-only HEAD
  ```

  Expected: the static test and inline parser both pass; `git diff --check HEAD` prints nothing; the changed-file list contains only the prototype, static test, design-spec status update, and this plan where applicable.

- [x] **Step 4: Update the acceptance checklist honestly**

  In `2026-07-22-recurring-push-wizard-redesign-design.md`, set `RPW-001`–`RPW-008` to `DONE` only after the corresponding source, interaction, and visual checks above have been observed. If the rendered visual comparison cannot be performed, keep `RPW-006` as `PARTIAL` and state the missing visual evidence in the verification-plan paragraph.

- [x] **Step 5: Commit the verification evidence without unrelated files**

  Run:

  ```sh
  git add -- docs/superpowers/specs/2026-07-22-recurring-push-wizard-redesign-design.md
  git diff --cached --check
  git commit -m "docs: verify recurring push wizard redesign"
  ```

## Plan self-review

- `RPW-001` is covered by Tasks 1–3 through the explicit active-worktree paths and changed-file verification.
- `RPW-002` is covered by Task 1's red/green test, source deletion, orphan search, and commit.
- `RPW-003`, `RPW-004`, `RPW-006`, and `RPW-008` are covered by Task 2's replacement contracts and Task 3's reference comparison.
- `RPW-005` is covered by Task 2's geometry assertions and Task 3's served-source/visual check.
- `RPW-007` is covered by Task 2's scoped initializer and syntax/static verification.
- The plan has no unresolved placeholders; every source token, screen order, command, and expected result is specified.

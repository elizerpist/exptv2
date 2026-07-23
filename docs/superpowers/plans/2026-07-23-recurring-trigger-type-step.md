# Recurring Trigger Type Step Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore a Q3A, 0. lépés trigger-type chooser between Q3 and Q4 without renumbering or changing the nine existing Push-trigger screens.

**Architecture:** The Query row stays a static, side-by-side prototype. Insert one new `recurring-wizard-screen` with a `data-recurring-trigger-step="0"` marker and reuse the existing recurring-sheet shell and selection initializer. The existing Q4–Q12 screens remain the Push-only continuation, so they retain `data-recurring-push-step="1"` through `"9"`.

**Tech Stack:** HTML, scoped CSS already in `color_lab.html`, inline browser JavaScript, Node.js `assert` static test runner, Git.

## Global Constraints

- Work only in `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree` on the existing `spendeetest` linked worktree.
- Implement the approved [0. lépés design](/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/superpowers/specs/2026-07-23-recurring-trigger-type-step-design.md).
- Keep Q4–Q12 numbering and all nine `data-recurring-push-step="1"`…`"9"` contracts intact.
- Q3A belongs directly between Q3 and Q4 and uses exactly one 570px Q2-inline bottom sheet.
- Use the existing `initRecurringWizardPrototype()` attribute-scoped selection behavior; do not add a runtime route or restore the time-trigger branch.
- Do not stage or alter pre-existing unrelated worktree changes.

---

### Task 1: Add a failing Q3A/0. lépés static contract

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js:655-660,1100-1140,1369-1455`

**Interfaces:**

- Consumes: the existing Q3 `alt-query-add-income-transaction` and Q4 `alt-recurring-push-basics` screen IDs.
- Produces: a static contract for `alt-recurring-trigger-type`, `data-recurring-trigger-step="0"`, 16 Query-row columns, ten recurring wizard shells, and unchanged nine Push steps.

- [ ] **Step 1: Write the failing screen-count and Query-row order assertions**

  Change the global count from `34` to `35` and the Query row from `15` to `16`. Insert the Q3A ID between Q3 and Q4 in `queryRowScreenOrder`:

  ```js
  assert.strictEqual(
    screenCount,
    35,
    'Expected the Query row to include Q3A trigger-type step plus the nine Push-trigger wizard screens',
  );

  assert.strictEqual(
    (queryMenuBlock.match(/<div class="screen-column"/g) || []).length,
    16,
    'Query Menu row must render Q1A, Q2, Q3, Q3A, nine Push screens, and Q13-Q15',
  );

  const queryRowScreenOrder = [
    queryMenuBlock.indexOf('data-screen="alt-query-menu-category-vendor-hierarchy"'),
    queryMenuBlock.indexOf('data-screen="alt-query-add-transaction-duplicate"'),
    queryMenuBlock.indexOf('data-screen="alt-query-add-income-transaction"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-trigger-type"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-basics"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-amount"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-schedule"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-source"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-notification"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-fields"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-matching"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-behavior"'),
    queryMenuBlock.indexOf('data-screen="alt-recurring-push-summary"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-color-popup"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-icon-popup"'),
    queryMenuBlock.indexOf('data-screen="alt-category-wizard-name-popup"'),
  ];
  ```

- [ ] **Step 2: Add a failing scoped Q3A sheet and choice assertion**

  Add a block between the Q3 and Push-wizard assertions. It must isolate Q3A between the Q3 start and Q4 start and prove one sheet, one 0-step marker, two mutually exclusive controls, the default Push state, and the Q2-inline geometry contract:

  ```js
  const triggerTypeScreenStart = queryMenuBlock.indexOf(
    '<div class="screen-title">Q3A · Recurring wizard · Trigger típusa</div>',
  );
  const triggerTypeScreenEnd = queryMenuBlock.indexOf(
    'data-screen="alt-recurring-push-basics"',
    triggerTypeScreenStart,
  );
  const triggerTypeScreenBlock =
    triggerTypeScreenStart >= 0 && triggerTypeScreenEnd > triggerTypeScreenStart
      ? queryMenuBlock.slice(triggerTypeScreenStart, triggerTypeScreenEnd)
      : '';
  assert(
    triggerTypeScreenBlock.includes('data-screen="alt-recurring-trigger-type"') &&
      triggerTypeScreenBlock.includes('data-recurring-wizard-screen="trigger-type"') &&
      triggerTypeScreenBlock.includes('data-recurring-trigger-step="0"') &&
      triggerTypeScreenBlock.includes('data-recurring-wizard-size="q2-inline-sheet"') &&
      (triggerTypeScreenBlock.match(/class="recurring-wizard-sheet"/g) || []).length === 1 &&
      triggerTypeScreenBlock.includes('0. lépés a 9-ből') &&
      triggerTypeScreenBlock.includes('data-recurring-wizard-choice-group') &&
      triggerTypeScreenBlock.includes('Push alapú') &&
      triggerTypeScreenBlock.includes('Idő alapú') &&
      /<button class="recurring-wizard-card selected"[^>]*data-recurring-wizard-selectable[^>]*aria-pressed="true">[\s\S]*?<strong>Push alapú<\/strong>/.test(triggerTypeScreenBlock),
    'Q3A must be a 0. lépés trigger-type chooser with one Q2-sized sheet and Push selected by default',
  );
  ```

- [ ] **Step 3: Preserve the existing Push-flow contract explicitly**

  Change only the total recurring-shell count from `9` to `10`; retain the existing `data-recurring-push-step="[1-9]"` count of `9` and add a direct no-zero-push guard:

  ```js
  assert.strictEqual(
    (queryMenuBlock.match(/data-recurring-wizard-screen=/g) || []).length,
    10,
    'Q3A plus the nine Push-trigger wizard screens must render in the Query row',
  );
  assert.strictEqual(
    (queryMenuBlock.match(/data-recurring-push-step="[1-9]"/g) || []).length,
    9,
    'Q4-Q12 must remain the exact nine Push-trigger steps after adding Q3A',
  );
  assert(
    !queryMenuBlock.includes('data-recurring-push-step="0"'),
    'The trigger chooser must be a distinct pre-step, not a tenth Push-trigger step',
  );
  ```

- [ ] **Step 4: Run the focused test and confirm the expected RED failure**

  Run:

  ```sh
  cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree
  node docs/prototypes/color_lab_static_test.js
  ```

  Expected: a failure at the new 35-screen, 16-column, or `alt-recurring-trigger-type` contract because Q3A does not yet exist.

### Task 2: Insert the minimal Q3A sheet and reuse the selection initializer

**Files:**

- Modify: `docs/prototypes/color_lab.html:after Q3, before Q4`

**Interfaces:**

- Consumes: `.recurring-wizard-screen`, `.recurring-wizard-sheet`, `.recurring-wizard-progress`, `.recurring-wizard-card`, `.recurring-wizard-footer`, and `initRecurringWizardPrototype()`.
- Produces: one type-chooser screen with local single-select behavior and no new JavaScript routing code.

- [ ] **Step 1: Insert the Q3A phone-screen block immediately before Q4**

  Use the established shell and these required attributes/content:

  ```html
  <div class="screen-column">
    <div class="screen-title">Q3A · Recurring wizard · Trigger típusa</div>
    <section class="phone-screen spendee-dashboard-screen recurring-wizard-screen"
      data-screen="alt-recurring-trigger-type"
      data-recurring-wizard-screen="trigger-type"
      data-recurring-trigger-step="0"
      data-recurring-wizard-size="q2-inline-sheet"
      data-color-target="app-background"
      data-color-var="--app-bg"
      aria-label="Recurring wizard: Trigger típusa">
      <div class="recurring-wizard-bg" aria-hidden="true"></div>
      <section class="recurring-wizard-sheet" role="dialog" aria-label="Trigger típusa">
        <div class="recurring-wizard-grabber"></div>
        <header class="recurring-wizard-nav"><button type="button" aria-label="vissza">‹</button><h3>Visszatérő tranzakció</h3><button type="button" aria-label="bezárás">×</button></header>
        <div class="recurring-wizard-scroll">
          <div class="recurring-wizard-progress" data-recurring-trigger-progress><span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span></div>
          <span class="recurring-wizard-kicker">0. lépés a 9-ből</span>
          <h3 class="recurring-wizard-title">Válassz trigger típust</h3>
          <p class="recurring-wizard-subtitle">Hogyan jöjjön létre a visszatérő tranzakció?</p>
          <div class="recurring-wizard-card-list" data-recurring-wizard-choice-group>
            <button class="recurring-wizard-card selected" type="button" data-recurring-wizard-selectable aria-pressed="true"><span class="recurring-wizard-icon">ϟ</span><span><strong>Push alapú</strong><span>Értesítés (push) alapján teljesül.</span></span><span class="recurring-wizard-chev">●</span></button>
            <button class="recurring-wizard-card" type="button" data-recurring-wizard-selectable aria-pressed="false"><span class="recurring-wizard-icon">◷</span><span><strong>Idő alapú</strong><span>Előre beállított időpontokban jön létre.</span></span><span class="recurring-wizard-chev">○</span></button>
          </div>
        </div>
        <footer class="recurring-wizard-footer has-back"><button class="recurring-wizard-back" type="button" aria-label="vissza">‹</button><button class="recurring-wizard-primary" type="button">Tovább</button></footer>
      </section>
    </section>
  </div>
  ```

- [ ] **Step 2: Keep JavaScript unchanged and verify actual selection scope**

  Do not modify `initRecurringWizardPrototype()`: it already finds `data-recurring-wizard-choice-group`, clears only sibling `data-recurring-wizard-selectable` controls for exclusive groups, and synchronizes `aria-pressed`. Run an isolated Node smoke against the extracted function with two exclusive Q3A-like controls; clicking `Idő alapú` must clear the initially selected `Push alapú` control.

- [ ] **Step 3: Run the focused test and confirm GREEN**

  Run:

  ```sh
  node docs/prototypes/color_lab_static_test.js
  ```

  Expected: `Color lab static checks passed`.

### Task 3: Verify, update acceptance evidence, and commit

**Files:**

- Modify: `docs/superpowers/specs/2026-07-23-recurring-trigger-type-step-design.md`
- Verify: `docs/prototypes/color_lab.html`, `docs/prototypes/color_lab_static_test.js`

**Interfaces:**

- Consumes: Q3A green static contract and the existing Q4–Q12 Push-flow contracts.
- Produces: evidence-backed RTS checklist states and commits that contain only this package's files.

- [ ] **Step 1: Run final static, parse, structural, and whitespace verification**

  Run:

  ```sh
  node docs/prototypes/color_lab_static_test.js
  node -e "const fs=require('fs');const h=fs.readFileSync('docs/prototypes/color_lab.html','utf8');for(const [,s] of h.matchAll(/<script>([\\s\\S]*?)<\\/script>/g))new Function(s);console.log('inline scripts parsed');"
  if rg -n 'data-recurring-push-step="0"' docs/prototypes/color_lab.html; then exit 1; fi
  git diff --check -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
  ```

  Expected: static test and parser pass, no zero-valued Push-step match, and no diff whitespace output.

- [ ] **Step 2: Mark the acceptance checklist with observed evidence**

  Update RTS-001 through RTS-005 to `DONE` only after the commands above show the specified Q3A order, geometry, selection behavior, zero-step marker, and unchanged Q4–Q12 Push sequence. If a rendered screenshot cannot be captured locally, document the visual-capture gap as `PARTIAL` rather than claiming it was checked.

- [ ] **Step 3: Commit only the source/test implementation and acceptance evidence**

  First commit the implementation:

  ```sh
  git add -- docs/prototypes/color_lab.html docs/prototypes/color_lab_static_test.js
  git diff --cached --check
  git commit -m "feat: restore recurring trigger type step"
  ```

  Then commit the acceptance evidence and this plan's checked steps:

  ```sh
  git add -- docs/superpowers/specs/2026-07-23-recurring-trigger-type-step-design.md docs/superpowers/plans/2026-07-23-recurring-trigger-type-step.md
  git diff --cached --check
  git commit -m "docs: verify recurring trigger type step"
  ```

## Plan self-review

- Spec coverage: RTS-001 through RTS-005 are mapped to Tasks 1–3.
- Test-first order: Task 1 creates and observes the red contract before Task 2 edits production HTML.
- Scope is intentionally limited to one pre-step; no time-trigger branch or runtime router is introduced.
- No incomplete markers, ambiguous screen names, or unscoped file paths remain.

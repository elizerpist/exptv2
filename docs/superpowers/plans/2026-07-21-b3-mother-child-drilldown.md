# B3 Strict Mother-Child Drilldown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an adjacent Color Lab B3M screen that demonstrates a strict `Legnagyobb kiadás` parent-to-child Stage 2 drilldown without changing the original B3 diagnostics screen.

**Architecture:** B3M duplicates B3's header and preserved Stage 1 layer, marks `Legnagyobb kiadás` as the active parent, and replaces the multi-insight diagnostic list with one detailed expense child surface. The prototype remains static and uses explicit data attributes so future runtime wiring can distinguish the parent card from its child detail.

**Tech Stack:** HTML, CSS, vanilla JavaScript static prototype checks run with Node.js.

## Global Constraints

- Keep the original B3 screen and existing balance-diagnostics behavior unchanged.
- Use the existing Balance glass, typography, color, and spacing language from `docs/prototypes/color_lab.html`.
- The static Balance overview remains independent from transaction-list type selection.
- Do not commit because this shared worktree contains unrelated user changes.

---

### Task 1: Add The B3M Strict Drilldown Prototype

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`
- Modify: `docs/superpowers/checklists/2026-07-21-b3-mother-child-drilldown.md`

**Interfaces:**
- Consumes: the existing B3 header, `.common-stage2-stage1-layer`, and Balance visual language.
- Produces: `data-screen="alt-common-header-stage2-mother-child"`, `data-balance-mother-child-parent="largest-expense"`, and `data-balance-mother-child-child="largest-expense"` for future interaction wiring.

- [ ] **Step 1: Write the failing static assertion**

```javascript
const strictMotherChildScreen = /data-screen="alt-common-header-stage2-mother-child"/.test(html) &&
  /data-balance-mother-child-parent="largest-expense"/.test(html) &&
  /data-balance-mother-child-child="largest-expense"/.test(html) &&
  /Albérlet/.test(html) &&
  /-176 370 Ft/.test(html) &&
  /A havi kiadás 43%-a/.test(html);
assert(strictMotherChildScreen, 'B3M must render the strict largest-expense mother-child drilldown');
```

- [ ] **Step 2: Run the static test and verify RED**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: FAIL with `B3M must render the strict largest-expense mother-child drilldown`.

- [ ] **Step 3: Add the B3M markup and CSS**

Create an adjacent B3M screen by duplicating B3's structural header. Mark its Stage 1 `Legnagyobb kiadás` fastinfo card active, then add one scrollable Stage 2 child panel showing the parent title, merchant, amount, timestamp/category, monthly-share progress, previous-month comparison, next recurring context, and a compact twelve-month trend.

- [ ] **Step 4: Run static verification and inspect the served document**

Run: `node docs/prototypes/color_lab_static_test.js` and `curl -I http://127.0.0.1:8787/color_lab.html`.

Expected: the static test passes and the served page returns HTTP 200.

- [ ] **Step 5: Update checklist status**

Set every row in `docs/superpowers/checklists/2026-07-21-b3-mother-child-drilldown.md` to `DONE` only after the fresh verification above, and record any unavailable visual evidence honestly.

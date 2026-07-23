# Pulse Panel teljes magyar feliratozás Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Pulse Engine Panel minden felhasználónak szóló szövege legyen egyszerű, következetes magyar.

**Architecture:** Egyetlen HTML-prototípus tartalmazza a statikus felületet és a JavaScriptből felépülő dinamikus feliratokat. A fordítás csak megjelenített karakterláncokat módosít; a belső azonosítók változatlanok maradnak. Egy statikus Node-teszt védi a tiltott angol feliratok visszakerülését.

**Tech Stack:** HTML, CSS, böngészőben futó JavaScript, Node.js `assert`.

## Global Constraints

- Csak a `docs/prototypes/pulse_engine_panel_mockup.html` embernek szóló szövege változhat.
- `Pulse`, HF-azonosítók és belső HTML/CSS/JavaScript-azonosítók változatlanok maradnak.
- Az alsó `assets/pulse-egyszeru-mukodes.png` kép változatlan marad.
- Minden új viselkedési elváráshoz a kód előtt hibázó teszt készül.

---

### Task 1: Fordítási szerződés

**Files:**

- Create: `docs/prototypes/pulse_hungarian_copy_test.js`
- Test: `docs/prototypes/pulse_hungarian_copy_test.js`

**Interfaces:**

- Consumes: `docs/prototypes/pulse_engine_panel_mockup.html` UTF-8 tartalma.
- Produces: sikeres Node-futtatás, ha a kiemelt látható angol feliratok nem maradnak a prototípusban és a PNG-flowchart még be van kötve.

- [ ] **Step 1: Write the failing test**

```js
assert.doesNotMatch(html, />[^<]*(?:selected|suppressed|priority)[^<]*</i);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node docs/prototypes/pulse_hungarian_copy_test.js`

Expected: `AssertionError`, mert a jelenlegi látható feliratok angol szavakat tartalmaznak.

- [ ] **Step 3: Write minimal implementation**

Fordítsd le a statikus és dinamikus embernek szóló szövegeket, majd egészítsd ki a tesztet a kulcsfontosságú chip- és állapotfeliratokkal.

- [ ] **Step 4: Run test to verify it passes**

Run: `node docs/prototypes/pulse_hungarian_copy_test.js`

Expected: `pulse_hungarian_copy_test: PASS`.

- [ ] **Step 5: Commit**

```bash
git add docs/prototypes/pulse_hungarian_copy_test.js docs/prototypes/pulse_engine_panel_mockup.html
git commit -m "feat: translate Pulse panel copy to Hungarian"
```

### Task 2: Teljes felirat-átvizsgálás és regresszió

**Files:**

- Modify: `docs/prototypes/pulse_engine_panel_mockup.html`
- Modify: `docs/prototypes/pulse_hungarian_copy_test.js`
- Modify: `docs/superpowers/checklists/2026-07-23-pulse-teljes-magyar-feliratok.md`

**Interfaces:**

- Consumes: Task 1 fordítási szerződése és a meglévő Pulse tesztek.
- Produces: teljesen magyar, továbbra is működő Pulse prototípus.

- [ ] **Step 1: Write the failing test**

```js
assert.doesNotMatch(dynamicCopy, /\\b(?:ready|waiting|source|story|evidence|confidence)\\b/i);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node docs/prototypes/pulse_hungarian_copy_test.js`

Expected: `AssertionError`, mert a JavaScript-forgatókönyvek még angol látható szöveget tartalmaznak.

- [ ] **Step 3: Write minimal implementation**

Fordítsd le a teljes statikus és dinamikus felületet; hagyd meg a kódazonosítókat, HF-azonosítókat, számokat, a `Pulse` nevet és az alsó PNG-t.

- [ ] **Step 4: Run test to verify it passes**

Run: `node docs/prototypes/pulse_hungarian_copy_test.js && node docs/prototypes/pulse_plain_language_png_flowchart_test.js && node docs/prototypes/pulse_semantic_flowchart_test.js && node docs/prototypes/pulse_engine_decision_trace_test.js && node docs/prototypes/pulse_engine_panel_group_rail_test.js`

Expected: minden teszt `PASS`.

- [ ] **Step 5: Commit**

```bash
git add docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_hungarian_copy_test.js docs/superpowers/checklists/2026-07-23-pulse-teljes-magyar-feliratok.md
git commit -m "docs: verify Hungarian Pulse panel copy"
```

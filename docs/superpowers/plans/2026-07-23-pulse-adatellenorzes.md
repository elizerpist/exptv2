# Pulse bemeneti adatok ellenőrzése Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Pulse pontozása előtt konkrét, hatókörhöz kötött adatellenőrzés döntsön, és ne létezzen homályos adatminőségi pontlevonás.

**Architecture:** A prototípus egyetlen HTML-fájlban tartja a folyamatábrát, a döntési példákat és a dinamikus kirajzolást. Az új `inputChecks` forgatókönyvadat a versenybe kerülés lépésében jelenik meg; a jelölt csak ezután kapja meg a jelenlegi fontossági pontszámát. A statikus Node-teszt rögzíti a mezőnkénti szabályokat és tiltja a régi `−20` modellt.

**Tech Stack:** HTML, beágyazott böngészős JavaScript, Node.js `assert`.

## Global Constraints

- A jóváhagyott referencia: `docs/prototypes/pulse_engine_panel_mockup.html` és az alsó `assets/pulse-egyszeru-mukodes.png`.
- `bizonytalan adat` és `− bizonytalan adat −20` nem maradhat embernek szóló szövegben vagy pontozási képletben.
- A hiányzó kategória csak HF-002/HF-012/HF-020-at állíthatja meg; teljes költés- és pénzáramlási jelből nem vonhat le pontot.
- HF-021 önálló adatpontossági jel marad, de nem módosítója pénzügyi jel pontszámának.
- A már működő három elsődleges csoport, a döntési példák, a kijelölt HF-hivatkozások és az alsó PNG megmaradnak.

---

### Task 1: Az adatellenőrzési szerződés tesztje

**Files:**

- Create: `docs/prototypes/pulse_data_input_rules_test.js`
- Modify: `docs/prototypes/pulse_semantic_flowchart_test.js`
- Test: `docs/prototypes/pulse_data_input_rules_test.js`

**Interfaces:**

- Consumes: `pulse_engine_panel_mockup.html` UTF-8 tartalma.
- Produces: hibázó teszt, amely a régi súlylevonást és a hiányzó konkrét adatellenőrzést jelzi.

- [ ] **Step 1: Write the failing test**

```js
assert.doesNotMatch(html, /bizonytalan adat/i);
assert.doesNotMatch(html, /−\s*bizonytalan adat\s*−20/i);
assert.match(html, /data-flow-branch="input-check"/);
assert.match(html, /Hiányzó összeg vagy dátum[\s\S]*pontszám nélkül/);
assert.match(html, /Hiányzó kategória[\s\S]*HF-002[\s\S]*HF-012[\s\S]*HF-020/);
assert.match(html, /HF-021[\s\S]*nem von le pontot/);
assert.match(html, /inputChecks:/);
assert.match(html, /function traceInputCheck\(check\)/);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node docs/prototypes/pulse_data_input_rules_test.js`

Expected: `AssertionError`, mert a régi `bizonytalan adat −20` még létezik és nincs `inputChecks` kirajzoló.

- [ ] **Step 3: Update the existing semantic-flow expectation**

```js
assert.doesNotMatch(html, /bizonytalan adat −20/);
assert.match(html, /Adatellenőrzés a pontszám előtt/);
assert.match(html, /Hiányzó kategória csak a kategóriaalapú jeleket állítja meg/);
```

- [ ] **Step 4: Run the two tests to verify the intended red state**

Run: `node docs/prototypes/pulse_data_input_rules_test.js && node docs/prototypes/pulse_semantic_flowchart_test.js`

Expected: az új teszt a hiányzó szabályokra hibázik; a folyamatábra-teszt még a régi `−20` elvárás miatt hibázik.

### Task 2: Pontozás előtti adatellenőrzés és döntési nyomvonal

**Files:**

- Modify: `docs/prototypes/pulse_engine_panel_mockup.html:1456-1538`
- Modify: `docs/prototypes/pulse_engine_panel_mockup.html:1810-1834`
- Modify: `docs/prototypes/pulse_engine_panel_mockup.html:1940-2410`
- Test: `docs/prototypes/pulse_data_input_rules_test.js`

**Interfaces:**

- Consumes: `inputChecks: Array<{ status: string, scope: string, reason: string }>` minden `decisionTraceScenarios`-elemben.
- Produces: `traceInputCheck(check)` HTML-kártyát ad, `renderDecisionTrace` pedig a második szakasz elején kirajzolja őket.

- [ ] **Step 1: Write minimal implementation in the flowchart**

Add `data-flow-branch="input-check"` to the source gate and show exactly these consequences:

```html
<strong>Adatellenőrzés a pontszám előtt</strong>
<p>Hiányzó összeg vagy dátum: az érintett jel várakozik, pontszám nélkül.</p>
<p>Hiányzó kategória csak a kategóriaalapú HF-002, HF-012 és HF-020 jeleket állítja meg; a teljes költés és pénzáramlás tovább számolható.</p>
<p>A várt, de meg nem érkezett bevétel nem adathiba: a HF-007 saját szabály szerint számolható.</p>
```

Replace the formula with:

```text
pontszám = fő jel alapértéke + pénzben nagy eltérés +15 + 3 napon belüli esedékesség +10 + kapcsolódó jel +10 − nemrég elutasított −30
```

- [ ] **Step 2: Add scenario input-check records**

Give `risk` and `recovery` a `számolható` record explaining that all inputs used by the selected situation exist. Give `data` these two records:

```js
{ status: "számolható", scope: "Teljes költés és pénzáramlás", reason: "Mindhárom tétel összege és dátuma megvan; a kategória hiánya ezt nem érinti." },
{ status: "várakozik, pontszám nélkül", scope: "Kategóriaalapú jelek: HF-002, HF-012, HF-020", reason: "Három tételnek nincs kategóriája. Csak ezek állnak meg; a HF-021 külön magyarázó jel." }
```

Replace the data example's non-related waiting HF-014 with the affected HF-002 and state that it is not scored. Keep HF-021 as a selected 35-point explanatory candidate with no modifiers, and explicitly state that it does not subtract from financial candidates.

- [ ] **Step 3: Render input checks before eligibility signals**

```js
function traceInputCheck(check) {
  const tone = check.status === "számolható" ? "good" : "warn";
  return '<article class="trace-candidate"><div class="trigger-top"><span class="tag ' + tone + '">' + check.status + '</span></div><strong>' + check.scope + '</strong><p>' + check.reason + '</p></article>';
}

stage("eligibility").innerHTML =
  '<h3>2. Adatellenőrzés és verseny</h3>…' +
  scenario.inputChecks.map(traceInputCheck).join("") +
  scenario.signals.map(traceSignal).join("");
```

- [ ] **Step 4: Make group explanations use the same scope**

Update the Keretnyomás, Pénzáramlási nyomás and Adatpontosság manuals, HF-021 card and story so they distinguish missing category from missing amount/date and state that HF-021 is not a financial score penalty.

- [ ] **Step 5: Run the focused tests**

Run: `node docs/prototypes/pulse_data_input_rules_test.js && node docs/prototypes/pulse_semantic_flowchart_test.js && node docs/prototypes/pulse_engine_decision_trace_test.js && node docs/prototypes/pulse_engine_panel_group_rail_test.js`

Expected: every command prints `PASS`.

- [ ] **Step 6: Commit**

```bash
git add docs/prototypes/pulse_engine_panel_mockup.html docs/prototypes/pulse_data_input_rules_test.js docs/prototypes/pulse_semantic_flowchart_test.js
git commit -m "feat: gate Pulse scores on input data"
```

### Task 3: Teljes regresszió és elfogadási bizonyíték

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-23-pulse-adatellenorzes.md`
- Modify: `docs/superpowers/plans/2026-07-23-pulse-adatellenorzes.md`
- Test: `docs/prototypes/pulse_hungarian_copy_test.js`

**Interfaces:**

- Consumes: Task 2 működő prototípusa.
- Produces: minden PAE-ellenőrzési pont `DONE` állapotú bizonyíték és célzott dokumentációs commit.

- [ ] **Step 1: Run the full test set and syntax check**

Run:

```bash
node docs/prototypes/pulse_data_input_rules_test.js
node docs/prototypes/pulse_hungarian_copy_test.js
node docs/prototypes/pulse_plain_language_png_flowchart_test.js
node docs/prototypes/pulse_semantic_flowchart_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
```

Then parse every embedded script with `new Function(script)` and request the HTML and PNG from the live `127.0.0.1:8790` server. Expected: every check `PASS`, both HTTP requests `200`.

- [ ] **Step 2: Mark acceptance items honestly**

Set PAE-001 through PAE-006 to `DONE` only after the preceding checks succeed. Add the exact test names and a concise statement that the generic `−20` was removed rather than merely renamed.

- [ ] **Step 3: Commit the evidence**

```bash
git add docs/superpowers/checklists/2026-07-23-pulse-adatellenorzes.md docs/superpowers/plans/2026-07-23-pulse-adatellenorzes.md
git commit -m "docs: verify Pulse input data rules"
```

## Plan self-review

- PAE-001 through PAE-006 are covered respectively by Tasks 1–3.
- No task uses a general data-quality multiplier; all prescribed labels and code interface names are explicit.
- The plan keeps the existing three-rail structure and does not alter the approved PNG.

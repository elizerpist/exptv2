# Pulse Plain-Language PNG Flowchart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Add one local, plain-Hungarian PNG flowchart at the bottom of the Pulse mockup so a user understands why a message appears, waits, or does not appear.

**Architecture:** Generate one flat infographic PNG, inspect it directly, then embed it as a responsive figure immediately before the current footer. A focused Node contract proves the PNG is real, local, correctly placed, and responsive. The asset explains the current motor; it does not modify its calculation or scenario behavior.

**Tech Stack:** Built-in image generation, PNG asset, static HTML/CSS, Node.js static tests.

## Global Constraints

- Final asset: docs/prototypes/assets/pulse-egyszeru-mukodes.png.
- Use everyday Hungarian only in the PNG. Do not use domain, target, fingerprint, eligibility, priority, trigger, source, selected, suppressed, background, foreground, or header.
- The central visual rule is exactly: A pontszám önmagában nem elég.
- Explain: score inspection is only information; data change starts checking; wait/no-message; enough reasons; one winner; app-open delivery; non-repeat; true-change recheck.
- Put one figure with data-plain-language-flowchart immediately before .footer-note.
- The image is local, responsive with max-width: 100%, and never horizontally cropped.
- Preserve the three group rails and do not edit balance_latest_layout.html.
- Inspect the generated PNG directly; this is asset validation, not an Android screenshot request.

---

## File Map

- Create: docs/prototypes/pulse_plain_language_png_flowchart_test.js — static asset/embed contract.
- Create: docs/prototypes/assets/pulse-egyszeru-mukodes.png — accepted generated diagram.
- Modify: docs/prototypes/pulse_engine_panel_mockup.html — bottom figure and scoped CSS.
- Modify: docs/superpowers/checklists/2026-07-23-pulse-plain-language-png-flowchart.md — evidence/status.
- Modify: docs/superpowers/plans/2026-07-23-pulse-plain-language-png-flowchart.md — execution record.

### Task 1: Write the PNG embed contract

**Files:**

- Create: docs/prototypes/pulse_plain_language_png_flowchart_test.js

**Produces:** A failing contract that requires a valid asset and its semantic bottom figure.

- [x] **Step 1: Create the failing test**

~~~js
#!/usr/bin/env node

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const prototypeDir = __dirname;
const html = fs.readFileSync(
  path.join(prototypeDir, "pulse_engine_panel_mockup.html"),
  "utf8",
);
const assetPath = path.join(
  prototypeDir,
  "assets",
  "pulse-egyszeru-mukodes.png",
);

assert.ok(fs.existsSync(assetPath), "plain-language PNG asset is required");
const png = fs.readFileSync(assetPath);
assert.deepEqual(
  [...png.subarray(0, 8)],
  [137, 80, 78, 71, 13, 10, 26, 10],
  "asset must be a PNG",
);
assert.ok(png.length > 20_000, "asset must contain a substantial diagram");

const figureStart = html.indexOf("data-plain-language-flowchart");
const footerStart = html.indexOf('<p class="footer-note">');
assert.notEqual(figureStart, -1, "bottom PNG figure is required");
assert.ok(figureStart < footerStart, "PNG figure must appear before the footer");
const figure = html.slice(figureStart, footerStart);
assert.match(figure, /src="assets\/pulse-egyszeru-mukodes\.png"/, "figure needs local PNG source");
assert.match(figure, /alt="[^"]*pontszám[^"]*"/, "figure needs Hungarian explanatory alt");
assert.match(figure, /A pontszám önmagában nem elég/, "figure needs central rule fallback");
assert.match(
  html,
  /\.plain-language-flowchart-image img\s*\{[\s\S]*max-width:\s*100%/,
  "responsive image CSS is required",
);
assert.equal((html.match(/data-group-rail=/g) || []).length, 3, "no fourth primary rail");

console.log("pulse_plain_language_png_flowchart_test: PASS");
~~~

- [x] **Step 2: Confirm it fails**

Run:

~~~sh
node docs/prototypes/pulse_plain_language_png_flowchart_test.js
~~~

Expected: fails with plain-language PNG asset is required.

### Task 2: Generate and persist the explanatory PNG

**Files:**

- Create: docs/prototypes/assets/pulse-egyszeru-mukodes.png

**Produces:** One direct-inspection-approved, readable Hungarian infographic.

- [x] **Step 1: Generate one image with the built-in image tool**

Use exactly this prompt:

~~~text
Use case: infographic-diagram
Asset type: bottom-of-page explanatory PNG for a Hungarian personal-finance app mockup
Primary request: Create one clean, wide, flat, highly legible Hungarian decision flowchart. It explains in everyday language when a financial app shows a short message and when it waits or shows nothing. Rounded white cards, dark navy text, teal arrows, amber wait exits, red no-message exits, green shown exits. No people, no phone mockup, no charts, no logos, no watermark, no English technical jargon.
Composition: wide landscape infographic, clear left-to-right flow with visible side exits, generous whitespace, large Hungarian typography, one central large highlighted rule.
Text (verbatim):
"MEGNÉZED A PONTSZÁMOT" → "CSAK INFORMÁCIÓ, NEM ÜZENET"
"AZ ADATOK VÁLTOZNAK" → "A RENDSZER ELLENŐRIZ"
"ELÉG ÚJ ÉS ELÉG FONTOS?" → "HA NEM: VÁR VAGY NEM JELENIK MEG"
"VAN ELÉG OK UGYANAHHOZ A HELYZETHEZ?" → "HA NEM: MÉG VÁR"
"TÖBB ÜZENET KÖZÜL MELYIK A FONTOSABB?" → "EGY MARAD"
"AZ APP NYITVA VAN?" → "IGEN: MEGJELENIK FELÜL" / "NEM: ELTÁROLJA, ÉS APPNYITÁSKOR MEGMUTATJA"
"UGYANAZ VOLT MÁR?" → "NEM ISMÉTLI FELESLEGESEN"
"HA A HELYZET TÉNYLEG VÁLTOZIK" → "ÚJRA ELLENŐRZI"
Central large rule: "A PONTSZÁM ÖNMAGÁBAN NEM ELÉG."
Constraints: render every Hungarian sentence accurately and exactly, with correct accents; readable at web-page width; do not add any other words; do not use these words anywhere: domain, target, fingerprint, eligibility, priority, trigger, source, selected, suppressed, background, foreground, header.
Avoid: garbled text, pseudo-language, tiny type, dashboard UI, code, mathematical formulas, gradient-heavy backgrounds.
~~~

- [x] **Step 2: Inspect and copy the accepted output**

Inspect the generated image directly. Verify all Hungarian text, accents, arrows,
central sentence, wait/no-message exits, and lack of prohibited jargon. If a
single text or legibility issue exists, do one targeted regeneration that changes
only that issue.

Persist the accepted result:

~~~sh
generated_root=/data/data/com.termux/files/home/.codex/generated_images
candidate=$(find "$generated_root" -type f -name '*.png' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
test -f "$candidate"
mkdir -p docs/prototypes/assets
cp "$candidate" docs/prototypes/assets/pulse-egyszeru-mukodes.png
file docs/prototypes/assets/pulse-egyszeru-mukodes.png
~~~

Expected: PNG image data.

### Task 3: Embed and verify the asset

**Files:**

- Modify: docs/prototypes/pulse_engine_panel_mockup.html
- Test: docs/prototypes/pulse_plain_language_png_flowchart_test.js

**Consumes:** The accepted PNG asset and existing footer note.

**Produces:** A full-width responsive bottom figure, without changing current engine behavior.

- [x] **Step 1: Add this scoped CSS near the footer styles**

~~~css
.plain-language-flowchart-image {
  margin-top: 18px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: var(--r);
  background: #fff;
}

.plain-language-flowchart-image img {
  display: block;
  width: 100%;
  max-width: 100%;
  height: auto;
  border-radius: 6px;
}

.plain-language-flowchart-image figcaption,
.plain-language-flowchart-rule {
  margin-top: 10px;
  color: var(--muted);
  font-size: 13px;
  line-height: 1.45;
}

.plain-language-flowchart-rule {
  color: var(--ink);
  font-weight: 850;
}
~~~

- [x] **Step 2: Insert this immediately before the footer note**

~~~html
<figure class="plain-language-flowchart-image" data-plain-language-flowchart>
  <img src="assets/pulse-egyszeru-mukodes.png" loading="lazy" decoding="async"
    alt="Egyszerű folyamatábra: a pontszám megtekintése csak információ; egy adatváltozást a rendszer ellenőriz, majd vagy vár, vagy kiválaszt egy üzenetet, amely az app megnyitásakor jelenik meg. A pontszám önmagában nem elég.">
  <figcaption>Egyszerű magyarázat: mikor lesz egy adatváltozásból üzenet, és mikor nem.</figcaption>
  <p class="plain-language-flowchart-rule">A pontszám önmagában nem elég.</p>
</figure>
~~~

- [x] **Step 3: Run contracts and commit the feature**

~~~sh
node docs/prototypes/pulse_plain_language_png_flowchart_test.js
node docs/prototypes/pulse_semantic_flowchart_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
node -e 'const fs=require("fs"); const html=fs.readFileSync("docs/prototypes/pulse_engine_panel_mockup.html","utf8"); for (const item of html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/g)) new Function(item[1]); console.log("embedded script parse: PASS");'
git add docs/prototypes/assets/pulse-egyszeru-mukodes.png docs/prototypes/pulse_plain_language_png_flowchart_test.js docs/prototypes/pulse_engine_panel_mockup.html
git diff --cached --check
git commit -m "feat: add plain-language Pulse flowchart PNG"
~~~

### Task 4: Record fresh evidence

**Files:**

- Modify: docs/superpowers/checklists/2026-07-23-pulse-plain-language-png-flowchart.md
- Modify: docs/superpowers/plans/2026-07-23-pulse-plain-language-png-flowchart.md

**Produces:** Honest static, direct-image, server, and scope evidence.

- [x] **Step 1: Run final verification**

~~~sh
node docs/prototypes/pulse_plain_language_png_flowchart_test.js
node docs/prototypes/pulse_semantic_flowchart_test.js
node docs/prototypes/pulse_engine_decision_trace_test.js
node docs/prototypes/pulse_engine_panel_group_rail_test.js
curl -fsS -o /dev/null -w 'HTTP %{http_code} %{size_download} bytes\n' http://127.0.0.1:8790/docs/prototypes/pulse_engine_panel_mockup.html
git diff --check
test "$(git hash-object balance_latest_layout.html)" = "a4b940489c11582f7252d6d2f5b86c0114f9817a"
~~~

- [x] **Step 2: Update checklist, plan, and commit evidence**

Set PLPF-001, PLPF-002, PLPF-006, PLPF-007, and PLPF-008 to DONE only after
direct checks pass. Set PLPF-003 through PLPF-005 to DONE only after direct
image inspection. Record final prompt, inspection outcome, test output, HTTP
result, whitespace result, and protected hash; then commit:

~~~sh
git add docs/superpowers/checklists/2026-07-23-pulse-plain-language-png-flowchart.md docs/superpowers/plans/2026-07-23-pulse-plain-language-png-flowchart.md
git diff --cached --check
git commit -m "docs: verify plain-language Pulse PNG flowchart"
~~~

## Plan Self-Review

- The test, asset filename, HTML source, and figure anchor use the same paths.
- The image carries the explanation; the HTML repeats the central rule as an accessible fallback.
- Direct asset inspection is mandatory before claiming readable Hungarian wording.

## Execution Record — 2026-07-23

- TDD red/green: the focused contract first failed because the PNG asset did
  not exist, then failed at the expected missing-bottom-figure checkpoint, and
  passed after the generated PNG and responsive figure were added.
- The accepted generated asset is a `1694 × 928` project-local PNG. Direct
  inspection confirmed readable Hungarian text and no forbidden technical
  terms.
- Fresh verification passed for the PNG contract, existing Pulse contracts,
  embedded-script parsing, both live HTTP resources, whitespace, and the
  protected Balance-layout hash.

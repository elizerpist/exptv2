# Color Lab HTML Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and serve a horizontally scrollable, source-derived HTML color lab for the ExpenseTracker home screen and three opened sheet states.

**Architecture:** A single static HTML file contains CSS constants copied from Flutter layout metrics and JS-only interaction for color selection/recoloring. A Node static test verifies that required source-derived constants, palette data, screen panels, recolor targets, and interactions are present before the prototype is served with Python's local HTTP server.

**Tech Stack:** Static HTML/CSS/JavaScript, Node.js static test, Python `http.server`.

## Global Constraints

- Work only in `docs/prototypes` and `docs/superpowers`; do not modify existing dirty Flutter source files.
- Source-of-truth files are listed in `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`.
- The prototype must use code-derived values from Flutter source, not visually similar invented values.
- The canvas must be four screen-width panels side by side, with an extended lower palette area.
- Every checklist item must be marked `DONE`, `PARTIAL`, or `BLOCKED` honestly before final handoff.

---

### Task 1: Static test for the requested prototype contract

**Files:**
- Create: `docs/prototypes/color_lab_static_test.js`
- Later consumed by: `node docs/prototypes/color_lab_static_test.js`

**Interfaces:**
- Consumes: `docs/prototypes/color_lab.html` as static text.
- Produces: a failing-then-passing static contract test for the prototype.

- [ ] **Step 1: Write the failing static test**

Create `docs/prototypes/color_lab_static_test.js` with checks for:

```javascript
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const htmlPath = path.join(__dirname, 'color_lab.html');
assert(fs.existsSync(htmlPath), 'Missing docs/prototypes/color_lab.html');
const html = fs.readFileSync(htmlPath, 'utf8');

const required = [
  'data-source="lib/features/transactions/widgets/header_card/transaction_header_metrics.dart"',
  '--screen-w: 412px',
  '--header-h: 188px',
  '--content-top: 192px',
  '--type-pill-h: 52px',
  '--summary-pill-h: 70px',
  '--search-pill-h: 46px',
  '--logbox-h: 72px',
  '--sheet-card-h: 150px',
  '--bottom-nav-h: 80px',
  '--fab-size: 66px',
  'data-screen="home"',
  'data-screen="category-sheet"',
  'data-screen="vendor-sheet"',
  'data-screen="add-transaction-sheet"',
  'id="colorPalette"',
  'function toggleColorSelection',
  'function applySelectedColor',
  'data-color-target="app-background"',
  'data-color-target="sheet-background"',
  'data-color-target="header-card"',
  'data-color-target="magnet-strip"',
  'data-color-target="logbox-background"',
  'data-color-target="vendor-card-background"',
  'data-color-target="category-card-background"',
  'data-color-target="text-pill"',
  'stats-threshold-sheet-background',
  'CategoryColorManager',
  'CategoryIconManager',
];

for (const token of required) {
  assert(html.includes(token), `Missing required token: ${token}`);
}

const screenCount = (html.match(/class="phone-screen/g) || []).length;
assert.strictEqual(screenCount, 4, 'Expected exactly four phone screens');

const swatchCount = (html.match(/class="color-swatch/g) || []).length;
assert(swatchCount >= 45, `Expected at least 45 color swatches, got ${swatchCount}`);

const sourceColorCount = (html.match(/data-palette-group="app-source"/g) || []).length;
assert(sourceColorCount >= 30, `Expected at least 30 app-source color slots, got ${sourceColorCount}`);

const proposedColorCount = (html.match(/data-palette-group="proposed-neutral"/g) || []).length;
assert(proposedColorCount >= 12, `Expected at least 12 proposed neutral color slots, got ${proposedColorCount}`);

console.log('Color lab static checks passed');
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: FAIL with `Missing docs/prototypes/color_lab.html`.

### Task 2: Build the static color lab prototype

**Files:**
- Create: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: source constants documented in the checklist.
- Produces: static prototype consumed by `color_lab_static_test.js`.

- [ ] **Step 1: Implement HTML/CSS/JS**

Create `docs/prototypes/color_lab.html` containing:

- Four `.phone-screen` sections with `data-screen` values `home`, `category-sheet`, `vendor-sheet`, `add-transaction-sheet`.
- CSS variables for source-derived metrics: `--screen-w: 412px`, `--header-h: 188px`, `--content-top: 192px`, `--type-pill-h: 52px`, `--summary-pill-h: 70px`, `--search-pill-h: 46px`, `--logbox-h: 72px`, `--sheet-card-h: 150px`, `--bottom-nav-h: 80px`, `--fab-size: 66px`.
- Home panel: header card, magnet strip, type pills, summary pill, search pill, transaction count header, logboxes, FAB, bottom nav.
- Category sheet panel: header card plus opened `CategoryMenuPanel`-style sheet with real seed category names, color slots, and lucide SVG icon assets.
- Vendor sheet panel: header card plus opened `VendorFilterPanel`-style sheet with real vendor names and category-derived avatars.
- Add transaction sheet panel: header card plus `AddTransactionSheet`-style panel and pill fields.
- Palette area with app-source and proposed-neutral swatches.
- JS functions `toggleColorSelection` and `applySelectedColor`.

- [ ] **Step 2: Run static test to verify it passes**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: PASS with `Color lab static checks passed`.

### Task 3: Update checklist and serve locally

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`

**Interfaces:**
- Consumes: verification output from Task 2 and HTTP fetch.
- Produces: final checklist statuses and running local server.

- [ ] **Step 1: Update checklist statuses**

For each `COLOR-LAB-*` row, set status to `DONE` if the implemented prototype satisfies it, otherwise set `PARTIAL` or `BLOCKED` with honest wording.

- [ ] **Step 2: Start server**

Run from the repository root: `python3 -m http.server 8765`

Expected: server listens on port `8765`.

- [ ] **Step 3: Verify HTTP access**

Run: `python3 - <<'PY'
from urllib.request import urlopen
url='http://127.0.0.1:8765/docs/prototypes/color_lab.html'
with urlopen(url, timeout=5) as r:
    body=r.read().decode('utf-8')
assert 'Color Lab' in body
assert 'data-screen="home"' in body
print(url)
PY`

Expected: prints `http://127.0.0.1:8765/docs/prototypes/color_lab.html`.

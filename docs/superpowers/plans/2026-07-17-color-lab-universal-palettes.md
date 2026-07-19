# Color Lab Universal Palettes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Color Lab portal header color sources and energy-field modes freely combinable, then replace the lower logo recommendation controls with five reusable custom gradient palette slots.

**Architecture:** Keep the existing standalone Color Lab prototype structure. Split portal state into an active color palette contract (`data-mind-portal-active-palette`, positions, field split) and an independent energy-mode contract (`data-mind-portal-mode`). Custom gradient slots become normal `.color-swatch` palette entries so existing app/background/logo application paths keep working.

**Tech Stack:** Static HTML/CSS/JavaScript prototype, Node-based static assertions in `docs/prototypes/color_lab_static_test.js`.

## Global Constraints

- Do not run local Flutter/Termux builds for this task; verification is static prototype tests.
- UI work must be verified against an acceptance checklist before claiming completion.
- Write failing tests before production changes.
- Preserve the large Fluvi logo editor; remove only the lower logo color recommendation panel and A/B/C scale controls.

---

### Task 1: Failing static assertions

**Files:**
- Modify: `docs/prototypes/color_lab_static_test.js`
- Create: `docs/superpowers/checklists/2026-07-17-color-lab-universal-palettes.md`

**Interfaces:**
- Consumes: current Color Lab HTML and portal energy module.
- Produces: failing assertions for new palette sliders, universal energy sampling, and custom gradient slots.

- [ ] **Step 1: Add assertions for the three new signature sliders**

Assert `data-signature-kind="meadow-green"`, `soft-rainbow`, and `ocean-blue-serenity` exist with range + `mind-portal-signature-window-input`, and assert every requested hex color exists.

- [ ] **Step 2: Add assertions for universal energy mode/color decoupling**

Assert color changes do not call `setMindPortalEnergyMode(header, 'static')`, mode changes do not call `applyMindPortalMoneyFlow`, and frame capture/render code samples from an active palette helper.

- [ ] **Step 3: Add assertions for custom gradient slots**

Assert the logo recommendation preview and A/B/C scale are gone, the large editor remains, and five `data-custom-gradient-slot` controls exist with swatch + boundary slider + left/right endpoint buttons.

- [ ] **Step 4: Run the static test and verify RED**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: FAIL because the new UI/state contracts are not implemented yet.

### Task 2: Test header palette sources

**Files:**
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: existing `balanceScaleStops`, `limitsScaleStops`, `coolScaleStops`, `applyMindPortalSignature`.
- Produces: `mindPortalSignaturePalettes`, `sampleMindPortalSignatureColor`, active palette data attributes.

- [ ] **Step 1: Add the three rows under Money flow**

Use the existing signature row layout with a range, percent label, and window input for each new palette source.

- [ ] **Step 2: Add palette constants and generic signature sampling**

Replace the hardcoded three-source sampler map with `mindPortalSignaturePalettes[kind]`.

- [ ] **Step 3: Store active palette metadata**

Every color-source apply path writes active palette colors, palette positions, field split, source label, and static background gradient.

- [ ] **Step 4: Run static test**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: remaining failures only in universal energy/custom gradient tasks.

### Task 3: Universal energy-field colors

**Files:**
- Modify: `docs/prototypes/color_lab.html`
- Modify: `docs/prototypes/color_lab_portal_energy.js`

**Interfaces:**
- Consumes: active palette attributes from Task 2.
- Produces: `MindPortalEnergy.samplePaletteColor`, `getMindPortalActivePalette`, `sampleMindPortalActivePaletteColor`.

- [ ] **Step 1: Add generic palette sampling to the portal energy module**

Factor the existing Money-flow palette color interpolation into an exported generic sampler.

- [ ] **Step 2: Remove color/mode forced coupling**

`setMindPortalEnergyMode` must not auto-apply Money flow for Balance modes. Signature changes must not reset Balance modes to static.

- [ ] **Step 3: Render both Balance and non-Balance fields through the active palette**

Use Balance samplers for Balance field geometry and normal samplers for other field geometry, then sample the active palette for final colors.

- [ ] **Step 4: Run static test**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: remaining failures only in custom gradient task.

### Task 4: Custom gradient palette row

**Files:**
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**
- Consumes: existing palette selection state, `setLogoPathGradient`, `applySelectedColor`.
- Produces: five custom gradient swatches that select a `linear-gradient(...)` string through the normal palette path.

- [ ] **Step 1: Remove logo recommendation and A/B/C controls**

Delete `fluviLogoVariantPreview`, `logo-abc-scale-panel`, and their initialization call.

- [ ] **Step 2: Add five custom gradient slots below the fixed color palette**

Each slot has a swatch, left endpoint button, right endpoint button, and compact range slider.

- [ ] **Step 3: Wire custom gradient state**

Endpoint buttons consume the currently selected palette color; boundary sliders update swatch `data-color`, `--swatch`, labels, and selected gradient if the swatch is active.

- [ ] **Step 4: Make generic background application gradient-safe**

When selected color contains `gradient`, use `target.style.background` instead of `backgroundColor`.

- [ ] **Step 5: Run static test**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: PASS.

### Task 5: Checklist and verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-17-color-lab-universal-palettes.md`

**Interfaces:**
- Consumes: implementation and static test output.
- Produces: honest DONE/PARTIAL/BLOCKED/NOT DONE statuses.

- [ ] **Step 1: Re-read the checklist**

Update every row status from direct code/test evidence.

- [ ] **Step 2: Run final static verification**

Run: `node docs/prototypes/color_lab_static_test.js`

Expected: PASS with no assertion output.


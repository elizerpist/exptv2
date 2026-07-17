# Portal Message Background Response Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a six-option, independently controlled background response lab to the existing reversible Portal Balance/message relay.

**Architecture:** A pure UMD module owns response schemas, bounds, seam mapping, keyframes, and endpoint rest styles. The HTML adds one pointer-transparent overlay below touch/content and one compact dropdown/control panel. The existing foreground controller starts the selected response in the same active animation group so rapid opposite taps reverse content and background together.

**Tech Stack:** HTML, CSS, browser JavaScript, Web Animations API, CommonJS-compatible UMD helpers, Node `assert` tests.

## Global Constraints

- HTML prototype only; do not edit Flutter code or run a Flutter build.
- `none` is the default and must be an exact no-effect baseline.
- Do not write portal A/B colors, signature values, Money-flow ratio, energy canvas settings, touch variables, or content styles from the response module.
- Preserve the protected touch function/CSS hashes and existing foreground-morph test suite.
- Keep all new controls phone-width, active-mode-only, and vertically scrollable.
- Execute inline; do not use subagents.

---

### Task 1: Pure background-response module

**Files:**

- Create: `docs/prototypes/color_lab_portal_background.js`
- Create: `docs/prototypes/color_lab_portal_background_test.js`

**Interfaces:**

- Produces global/CommonJS `PortalMessageBackground` with `modeOrder`, `modeLabels`, `modeControls`, `controlsForMode(mode)`, `createModeSettings(mode)`, `normalizeValue(meta, value)`, `moneyFlowSeamPercent(income)`, and `buildResponse(mode, settings, targetState, context, reducedMotion)`.
- `buildResponse` returns `{ mode, duration, easing, keyframes, balanceRest, messageRest, configuration }`.

- [x] Write a failing test that requires exact mode order/labels, `none` zero output, exact 8/50/92 seam mapping, bounded schemas, per-control sensitivity, forward/backward endpoints, monotonic offsets, ≤0.45 chromatic opacity, and 160 ms reduced-motion behavior.
- [x] Run `node docs/prototypes/color_lab_portal_background_test.js`; expect `MODULE_NOT_FOUND` for `color_lab_portal_background.js`.
- [x] Implement the pure UMD module with the exact schemas from `docs/superpowers/specs/2026-07-16-portal-message-background-response-design.md` and five distinct descriptor builders.
- [x] Run `node docs/prototypes/color_lab_portal_background_test.js` and `node --check docs/prototypes/color_lab_portal_background.js`; expect `Portal message background checks passed` and exit 0.

### Task 2: Overlay, six-option dropdown, and controls shell

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**

- Adds `data-portal-background-response`, `data-portal-background-panel`, `data-portal-background-mode-select`, `data-portal-background-controls`, and `data-portal-background-controls-scroll`.

- [x] Add failing static assertions for the overlay appearing after the energy canvas and before content, `z-index:0`, `pointer-events:none`, exact six-option order/default, module load order, separate panel, hidden `none` controls, and shared width/scroll CSS.
- [x] Run `node docs/prototypes/color_lab_static_test.js`; expect failure at the new background-response markup assertion.
- [x] Add the overlay and mode-scoped CSS visuals, load `color_lab_portal_background.js` after the foreground module, and add the compact panel below `Portal üzenetváltás`.
- [x] Run `node docs/prototypes/color_lab_static_test.js`; expect `Color lab static checks passed`.

### Task 3: Shared reversal, rest-state commit, and detailed controls

**Files:**

- Modify: `docs/prototypes/color_lab_static_test.js`
- Modify: `docs/prototypes/color_lab.html`

**Interfaces:**

- Extends the existing `portalMessageMorphStates` state with `backgroundMode`, `backgroundSettingsByMode`, and `backgroundPreviewAnimation`.
- Adds `renderPortalBackgroundControls`, `setPortalBackgroundMode`, `resetPortalBackgroundMode`, `configurePortalBackgroundOverlay`, `applyPortalBackgroundRestState`, and `previewPortalBackgroundMode`.

- [x] Add failing static/runtime assertions proving background descriptors enter `activeAnimations`, the existing `animation.reverse()` path covers them, Balance/none clear endpoint styles, message hold is committed, background settings remain independent, only the active background mode resets, manual inputs defer commit, and the background viewport joins vertical scroll routing.
- [x] Run `node docs/prototypes/color_lab_static_test.js`; expect failure at the new integration contract.
- [x] Implement state/control/render functions, append the response animation to the existing active group, apply endpoint rest styles after animation cancellation, and implement a 180 ms mode-preview fade while a message is already visible.
- [x] Run focused tests: static, foreground pure module, background pure module, portal-energy suite, and all JavaScript syntax checks; expect all green.

### Task 4: Verification and evidence

**Files:**

- Modify: `docs/superpowers/checklists/2026-07-11-color-lab-html-prototype-checklist.md`

- [x] Run the full fresh suite, inline-script parse, `git diff --check`, and HTTP smoke for HTML plus all three portal modules.
- [x] Change `COLOR-LAB-324`–`327` from `NOT DONE` to `PARTIAL` and record witnessed RED/GREEN evidence plus remaining Android visual checks.
- [x] Re-run the complete verification after documentation edits.

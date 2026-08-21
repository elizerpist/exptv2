# Header Deep Drift Implementation Plan

> **For agentic workers:** Execute inline because the user explicitly disallowed subagents. Steps use checkbox syntax for tracking.

**Goal:** Make the retained runtime shader authoritative for every normal Header quality, prove its runtime observability, and add the production Deep Drift effect without new animation/data owners.

**Architecture:** Extend the existing Header effect catalog, render plan, fragment input cache and single shader asset. A bounded fixed numeric skeleton supplies 15 low-frequency blob transforms to the retained shader. The Header controller remains the only source of time/tuner state and the visual frame remains the sole A/B palette authority.

**Tech Stack:** Flutter runtime shaders, Dart unit/widget tests, existing Fluvi diagnostics, GitHub Actions human APK.

## Global constraints

- Work only on `separated-core-modes`; no physics edits or new persistence/I/O.
- TDD: each production behavior gets a RED run before its minimal implementation.
- Mesh is failure fallback only; no quality setting can select it.
- Shared Header clock/program stay single and retained.
- Build normal `lib/main.dart` APK online only.

### Task 1: Runtime backend contract and stable ABI

**Files:** `dashboard_header_fragment_backend.dart`, `dashboard_header_visual_engine.dart`, `dashboard_header_fragment_backend_test.dart`.

- [x] Write RED tests for .35/.60/.95/1.00 fragment plans, explicit shader IDs, and backend diagnostic sequence.
- [x] Run the focused test and record the expected legacy-mesh/index failure.
- [x] Make fragment selection depend only on shader availability; add explicit effect shader IDs and diagnostic emission ownership.
- [x] Re-run the focused tests green.
- [ ] Commit with the coupled retained-program change after the final verification pass.

### Task 2: Deep Drift pure model and catalog

**Files:** new `dashboard_header_deep_drift.dart`, visual engine, focused new test.

- [x] Write RED checkpoints for cubic kernel, analytic derivative, 3×5 fixed slots, depth order and catalog controls.
- [x] Run RED.
- [x] Add retained numeric skeleton and catalog metadata with the supplied control defaults.
- [x] Run GREEN; keep phase storage identity stable.

### Task 3: Shader and integration

**Files:** fragment backend, `dashboard_header_field.frag`, tuner, engine/widget tests.

- [x] Write RED shader-input/tuner/isolation tests.
- [x] Run RED.
- [x] Pack skeleton uniforms, add Deep Drift field branch before existing Portal/tap composition, and expose the existing tuner catalog entry.
- [x] Run focused tests and shader bundle build green.
- [x] Refactor duplicated IDs/uniform packing.

### Task 4: Verification and delivery

- [x] Run analyzer/focused protected suites; confirm no physics diff. The full local suite has five unrelated rail/scroll failures and is recorded in the checklist.
- [ ] Push, wait for all required GitHub Actions, download normal human APK and hash it.
- [ ] Re-read this checklist. Leave physical/log-reference items explicitly pending until a normal APK device log proves them.

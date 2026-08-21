# Header Fragment Fidelity Implementation Plan

> **For agentic workers:** execute inline; the user explicitly prohibits subagents.

**Goal:** make the maximum-quality Header field a retained, native-resolution
runtime-shader surface while preserving Color Lab tap-wave and motion owners.

**Architecture:** retain the controller, immutable palette frame, visual paint
boundary and bounded wave state. Replace only the maximum-quality field
sampling backend; use retained shader instances and fixed uniform slots.

## Task 1: Freeze source/backend gap

- [ ] Add failing renderer contract tests proving maximum quality cannot select
  a `/4` mesh and that DPR has fragment backend semantics.
- [ ] Add failing fixed ripple/uniform-capacity tests.
- [ ] Run the focused suite and record expected missing-backend failures.

## Task 2: Retained runtime shader

- [ ] Declare the `.frag` asset in `pubspec.yaml`.
- [ ] Add source-math shader helpers and fixed ripple uniform slots.
- [ ] Add a retained program/shader owner with async load, one-time fallback
  diagnostic and no phase-tick semantic publication.
- [ ] Draw common and enabled Portal channels with retained shader instances.
- [ ] Run focused GREEN tests.

## Task 3: Integrate and refactor

- [ ] Route maximum quality through the shader; leave mesh only explicit
  low-quality/setup-failure fallback.
- [ ] Keep Canvas tap overlay/trail only if source-contract tests remain exact.
- [ ] Add low-frequency backend/fidelity diagnostics.
- [ ] Run analyzer, protected motion suite, CI-required suite and physics diff.
- [ ] Commit focused code, push, wait CI and download normal human APK.

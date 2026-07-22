# Pulse Semantic Flowchart Design

**Working artifact:** `docs/prototypes/pulse_engine_panel_mockup.html`
**Reference design:** `docs/superpowers/specs/2026-07-22-pulse-engine-decision-trace-design.md`
**Accepted direction:** User, 2026-07-22 — put a detailed semantic flowchart at
the very top of the Pulse mockup so every route from a trigger to a shown or
discarded header message is understandable.

## Problem

The existing phone preview and Decision Trace explain a selected scenario, but
they do not give a first-glance answer to these questions:

- Does selecting or viewing a score itself create a Pulse?
- Is a high score enough to produce a header message?
- Which checks happen before scoring?
- Where do waiting, muted, stale, deferred, suppressed, and superseded states
  go?
- When is a message stored, shown, not repeated, replaced, or recalculated?

## Chosen approach

Add one full-width `Pulse decision flow` card immediately after the top bar and
before the phone/overview hero. It is a semantic HTML flow diagram, made from
numbered stages, decision nodes, labelled branch lanes, and a compact legend.
It does not add a rail, a new calculation engine, a server call, or a separate
interactive simulator.

The chart has two jobs:

1. Explain the invariant motor policy once, above every scenario.
2. Link conceptually to the existing Decision Trace below, which demonstrates
   those rules with Risk, Recovery, and Data-quality fixtures.

### Rejected alternatives

1. **One giant SVG diagram — rejected.** It would make the dependency arrows
   look precise on desktop but be difficult to read, traverse, and test on
   Android width.
2. **A fourth engine rail — rejected.** The approved rail still has only
   Budget pressure, Cashflow pressure, and Data quality.
3. **A second editable simulator — rejected.** The existing Decision Trace is
   already the scenario simulator; a static policy flow avoids duplicate state
   and conflicting results.

## Flow semantics

The chart must show these stages in order, including every exit path.

1. **Entry lanes.** A user may select or inspect a score, but that is
   inspection-only and does not create a header Pulse. A raw signal begins only
   from a changed metric/forecast, due-date transition, data-quality threshold,
   scheduled calculation, app open/resume, or date change.
2. **Recalculation and raw signal.** The local engine computes a current
   signal with source, domain/target, state, confidence, and fingerprint.
3. **Source gate.** Deferred and engine-only sources make no V1 header copy.
   Stale, muted, unchanged shown/dismissed fingerprints, insufficient-confidence,
   and below-delay signals leave through a `wait / no score` lane. A lower but
   still eligible confidence can instead take the visible `-20` priority
   modifier. Neither route is resurrected by a large number.
4. **Evidence gate and story formation.** An eligible signal must satisfy one
   of the published evidence rules. Related signals share a domain or target
   and may form one candidate story; unrelated signals become independent
   candidates. A forming candidate waits for missing evidence.
5. **Priority calculation.** Only a ready candidate gets a priority:
   `clamp(0..100, dominant base + material + due-window + related evidence -
   low confidence - recent dismiss)`. Supporting bases never sum blindly.
6. **Score answer.** The diagram states explicitly: score alone is not enough.
   `eligible + ready + current fingerprint + delivery opportunity` are also
   required. There is no universal display threshold: a ready Data-quality
   story at `35` can win when no stronger ready story exists.
7. **Selection.** Ready candidates are ranked. The winner becomes `selected`;
   lower ready candidates become `suppressed`, not queued. Equal priorities use
   a deterministic tie-break: urgent due state, newer materially changed
   fingerprint, then stable source-ID order.
8. **Composition and delivery.** Only allowed source roles compose the
   headline, evidence, time/cause, caveat, and recovery slots. In foreground,
   the selected story is delivered and shown. In background it is stored as
   pending and delivered on open/resume.
9. **Lifecycle loops.** An unchanged shown/dismissed fingerprint does not
   replay. A stronger fresh candidate can supersede a pending/selected story.
   A resolved state or changed fingerprint re-enters recalculation. No valid
   ready candidate ends in `no header; keep the trace only`.

## Information architecture and accessibility

- The root uses `data-pulse-semantic-flowchart` and precedes `.hero-grid`.
- Each stage has `data-flow-stage`; each explicit outcome uses
  `data-flow-branch`. The static contract tests these names rather than visual
  placement alone.
- The flow is an ordered list of semantic `article` steps. Decision wording is
  text, not only color or arrows. An `aside` legend explains active, waiting,
  stopped, and delivery states.
- On narrow screens, the grid becomes one readable vertical path; branch labels
  wrap rather than clip. No screenshot is required by the user for this change.
- The chart preserves all three existing primary rail entries and does not
  modify `balance_latest_layout.html`.

## Verification

The static contract must verify the top-level chart root, all nine stages, all
important branch lanes, the score-is-not-enough rule, formula/tie-break copy,
no-copy exclusions, background delivery, same-fingerprint non-repeat, and the
existing three-rail invariant. The existing Decision Trace and group-rail
contracts must remain green. Script parsing, HTTP `200`, whitespace checks,
and the protected Balance hash remain required.

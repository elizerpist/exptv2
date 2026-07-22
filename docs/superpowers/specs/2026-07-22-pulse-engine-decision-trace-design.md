# Pulse Engine Decision Trace Design

**Working artifact:** `docs/prototypes/pulse_engine_panel_mockup.html`
**Source register:** `docs/superpowers/specs/2026-07-13-hidden-forecast-pulse-design.md`
**Accepted direction:** User, 2026-07-22 — the existing HTML mockup must make
the Pulse motor understandable: appearance timing, eligibility, relative
strength, story evolution, and the source of every header sentence part.

## Problem

The grouped rail answers what each detector watches and when it triggers. It
does not yet let someone follow one current state through the engine:

```text
raw signals -> eligibility -> related candidate stories -> priority -> one header thought
```

As a result, the panel shows a selected score without exposing why the story
can appear, why it beats another ready story, or how individual signals become
specific pieces of header copy.

## Scope and boundaries

The feature is a deterministic, inspectable **decision trace** inside the
existing Pulse mockup. It does not add a fourth top-level rail, a notification
inbox, an AI generator, or a second financial calculation engine.

It makes the already accepted rules visible. The three primary rail groups
remain `Budget pressure`, `Cashflow pressure`, and `Data quality`.

## Considered approaches

1. **Global Decision Trace + Copy Map — selected.** One cross-domain module,
   placed before the grouped dossiers, follows a concrete state from raw
   signal to header delivery. The group dossiers keep their detector-level
   detail. This is the only option that makes a mixed Budget + fixed-load +
   ghost-income story legible in one place.
2. **Repeat an engine panel inside every group — rejected.** It would repeat
   the same priority/lifecycle explanation three times and obscure stories
   that span Budget and Cashflow.
3. **Add an Engine fourth rail — rejected.** It would contradict the approved
   three-group rail and turn the motor into another disconnected menu.

## Information architecture

Add one full-width `Engine decision trace` card directly after the existing
Pulse operating overview and before the three group dossiers. It is not a
rail item. It contains a compact scenario selector and these fixed stages:

1. **Recalculation entry.** Shows why the engine ran: foreground data change,
   app open/resume, or date change. It states that a background recalculation
   stores current state but waits for open/resume before header delivery.
2. **Raw signal and eligibility gate.** Every active, waiting, muted,
   superseded, or same-fingerprint source has an explicit outcome and reason.
   A high score never bypasses this gate.
3. **Story formation.** Related signals are grouped by domain and target;
   unrelated signals do not add together. The view shows forming versus ready
   candidates and the evidence rule they passed or missed.
4. **Priority ledger.** Candidate stories are ranked side by side. Each score
   displays its base, modifiers, and final clamped priority rather than only a
   mysterious number. Ready-but-losing candidates are marked `suppressed`,
   not queued.
5. **Header delivery and lifecycle.** The winner is shown as `selected ->
   delivered -> shown`; unchanged shown/dismissed fingerprints cannot replay.
   A stronger fresh state can supersede, and a resolved state can later become
   eligible again through a new fingerprint.
6. **Story copy map.** The final title and detail are split into visible
   sentence slots. Every displayed slot names its contributing HF source;
   excluded sources say why they added no text.

The trace stays above the selected group dossier so it can explain mixed-domain
stories. Clicking a source reference may select and scroll to that source's
existing group/card; it must not change source ownership.

## Scenario model

The mockup exposes three deterministic, local examples; changing one updates
the phone-header preview and every trace stage together.

| Scenario | Intended teaching point | Selected result |
| --- | --- | --- |
| `risk` | Several related Budget/Cashflow signals form one urgent month-end story; a lower ready candidate loses. | `A hónap vége szoros lesz.` |
| `recovery` | A resolved important risk can create a meaningful recovery rather than routine praise. | `Visszajött a kereten belüli pálya.` |
| `data` | Delayed/grouped data quality becomes eligible only after its delay and threshold; it is not a financial emergency. | `Találtam 3 kategorizálatlan tételt.` |

Each scenario includes raw source IDs, state, target/domain, fingerprint
outcome, confidence, evidence group, candidate status, and header result.
The trace is a transparent mockup dataset, not a claim that live Flutter data
already runs this policy.

## Eligibility and evidence contract

A raw signal joins a candidate only when it is current, not stale, not muted,
not an unchanged shown/dismissed fingerprint, and has enough confidence. The
trace states that eligibility means *can compete*; it does not guarantee
header delivery.

The evidence rules remain exactly those in the accepted source register:

```text
1 critical signal
1 high signal with high confidence and material impact
2 related medium signals in one domain or target
3 related low signals in one domain or target
1 meaningful recovery after a prior important risk
data quality after its delay plus count/money threshold
```

Signals can be `waiting`, `eligible`, `superseded`, `muted`, `resolved`, or
`suppressed`. `HF-015` is a lifecycle/supersede rule, not a separate headline
source; `HF-008` stays explicitly deferred/not active.

## Priority-score contract

The trace must distinguish a detector's **base weight** from a composed
story's **priority**.

For each candidate shown by the mockup:

```text
story priority = clamp(0..100,
  dominant eligible source base weight
  + material-money modifier        (+15 when applicable)
  + due-within-3-days modifier     (+10 when applicable)
  + related-evidence modifier      (+10 when applicable)
  - low-confidence modifier        (-20 when applicable)
  - recent-dismiss modifier        (-30 when applicable)
)
```

Only one dominant base starts a story score. Supporting sources prove or
explain the same story through the documented related-evidence modifier; their
base weights are not blindly summed. That prevents many unrelated small
signals from beating one critical signal. A score is computed only after the
eligibility/evidence gates; it cannot resurrect an excluded signal.

The ledger displays the existing base weights and every applied/non-applied
modifier. Group tuning is displayed as a policy control but is not silently
folded into a sample score unless its exact production semantics are shown in
the same ledger. This avoids a fake, untraceable adjustment.

If two ready candidates end at the same priority, the trace shows a
deterministic tie-break explanation in this order: more urgent due state,
newer materially changed fingerprint, then stable source-ID order. The
selected row must state which tie-break resolved it.

## Story composition and copy contract

The composer produces one current story, not a list of trigger sentences.
Every candidate uses these visible sentence slots:

| Slot | Purpose | Eligible contributors |
| --- | --- | --- |
| **Headline claim** | The one main, current financial or app-state truth. | Dominant forecast/pressure/recovery/data-quality signal. |
| **Evidence phrase** | Up to two grounded facts proving the claim. | Related category burn, fixed load, due date, pace, ratio, trend, buffer, or goal signal. |
| **Time/cause clause** | Why now, or what is due/changed. | Recurring due window, missing expected income, transition, or forecast direction. |
| **Confidence caveat** | Qualifies interpretation without stealing the headline. | HF-021 data-quality, low confidence, or early-period condition. |
| **Recovery clause** | Explains what resolved a previously shown important risk. | Resolved forecast/limit state, ghost income arrival, improved buffer, or score movement. |

Role rules are explicit:

- `HF-001`, `HF-007`, `HF-009`, `HF-010`, and `HF-011` can lead when they are
  the dominant eligible risk.
- `HF-002`, `HF-004`, `HF-005`, `HF-006`, `HF-012`, `HF-013`, `HF-014`, and
  `HF-020` normally prove, time, or explain a stronger claim; `HF-014` never
  invents a cause beyond the existing score movement.
- `HF-003` is a coach/evidence detail, not a standalone daily header pulse
  unless it has reached its meaningful zone rule.
- `HF-021` is a caveat in a financial story, or the headline/evidence of its
  own delayed data-quality story.
- `HF-015` controls supersession; `HF-016`–`HF-019` explain engine operation;
  none generates user-facing financial copy. `HF-008` generates no V1 copy.

The trace renders the final mock header sentence as labelled fragments, for
example:

```text
[Headline · HF-001] A hónap vége szoros lesz.
[Evidence · HF-002] 3 keret túlfutás felé tart,
[Time/cause · HF-005] és még 42 000 Ft fix kiadás várható.
```

It also lists related signals omitted from the sentence because they were
redundant, waiting, superseded, low confidence, or suppressed by a stronger
story. The group dossiers expose the same role badge next to their existing
source cards, so every accepted source remains discoverable from its owner.

## Interaction and mobile behavior

- Scenario buttons must have tab semantics and update the phone preview,
  trace, score ledger, lifecycle, candidate rows, and sentence map in one
  deterministic render.
- Source references in the trace must be keyboard-accessible and locate the
  existing owner group/card without creating duplicate source cards.
- The source/copy map can horizontally scroll on a phone; sentence fragments
  wrap and never hide the selected outcome. No active content can remain
  hidden behind the sticky rail.
- Existing three-group rail keyboard navigation and existing group controls
  remain functional.

## Verification

Static checks will require all trace stages, all three scenario keys, the
published priority formula/modifiers, lifecycle outcomes, copy-slot source
mapping, and the rule that engine-only/deferred sources cannot create header
copy. Browser review will verify changing each scenario updates the full trace
and phone preview coherently at Android width.

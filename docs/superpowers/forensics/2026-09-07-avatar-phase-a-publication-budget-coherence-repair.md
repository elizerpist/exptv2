# Forensics — Avatar smooth-but-empty regression

## Evidence freeze

The immutable local evidence manifest is
`docs/superpowers/evidence/2026-09-07-avatar-phase-a-publication-budget-coherence-session-fluvi-1788752412870045/manifest.json`.

Both frozen documents identify session `fluvi-1788752412870045`, build
`profile/5ba6c01eb391`, and application SHA
`5ba6c01eb391339c27861762ba888e29aae38593`. Avatar contains two LIVE_TAIL
snapshots (`1726–2725`, `1811–2810`): 2,000 copies, 1,085 unique sequences,
915 byte-identical duplicates, and no differing duplicate. Budget contains
`8760–9759`: 1,000 unique events. The cross-document retention gap is
`2811–8759`; no claim is made about it. USER_MARK events are labels, not
mechanism proof.

The frozen local export hashes differ from the prompt-authoring hashes. This is
recorded in the manifest; no later Drive content is blended into this cycle.

## Recomputed current evidence

The deduplicated Avatar snapshot contains 43 `AV|PREVIEW_REQUESTED`, 43
`AV|PREVIEW_REJECTED`, 38 `CATEGORY_FOCUS_REQUESTED`, 38
`FOCUS_DERIVED_SCOPE_READY`, 38 `AV|LIVE_ROOT_MISS`, 38
`AV|PHASE_A_PUBLICATION_DEFERRED`, and 38 `BUDGET_PROGRESS_IDENTITY_MISMATCH`.
It contains no `LIVE_INTERACTION_ACCEPTED`, no
`FOCUS_PHASE_A_INTERACTION_FRAME_PUBLISHED`, no
`BUDGET_TARGET_SELECTION_CHANGED`, and no Avatar target paint event. The
representative sequence 1919–1923 derives a 37-row focus in 275 microseconds
without repository/index/TextPainter/rich projection work, then rejects it
because `actualPainterReadablePhaseAUnavailable`.

## Current source finding

`_bindBudgetAvatarLivePhaseA` combines exact resource identity with
`budgetAvatarLiveRootReady`. The latter additionally requires all 17 fixed
hotset candidates. A cold or still-maintaining global hotset therefore blocks
the actual per-payload binder. `_requestEphemeralFocus` returns false before
the visible store, live interaction, focus replacement, and Budget promotion.
`_primeBudgetAvatarLiveRowResources` records a later resource-ready event but
does not replay the dropped input. This conflicts with the method comment that
resource preparation is background work rather than an input gate.

## Reproducer and repair result

The current-5ba production-component reproducer holds only the existing
`budgetAvatarPreview` resource preparation. It uses the real
`DashboardCoreController`, `DashboardVisibleFrameStore`,
`DashboardLogBoxPreparedSceneCache`, Budget presentation controller and
drilldown coordinator. Before the repair it failed as expected: the cold
preview completed `true`/rejected instead of remaining pending, which is the
reject-and-forget boundary from the physical trace. It did not use a null
Phase-A binder or a preinstalled ready resource bank.

The repair makes exact cache-visible readiness authoritative for the warm
path. It removes the unrelated all-target `budgetAvatarLiveRootReady` flag
from that exact bind decision, while retaining the flag for prewarm telemetry.
For a real cold resource miss it keeps one controller-owned pending candidate
with the original interaction order. The existing resource-completion callback
revalidates and publishes only that latest candidate; a later crossing
completes the older candidate as `coalescedBeforeReadiness` and cannot be
overwritten by its late completion. No timer, new cache, visible-frame store,
controller, query apply, index build, database call, rich projection or
TextPainter creation was introduced.

The aggregate and exact-empty paths are explicit: target 0 may claim an
already-exact aggregate visual without inventing a raster callback, and an
exact-empty category is accepted with zero rows rather than being treated as a
readable-resource failure.

### Cross-producer completion correction

Pre-commit review found one additional cold-path race: the initial candidate
validity closure checked only Avatar focus/base identity. A later Mind or Time
intent can claim a newer shared visible-frame interaction order while the
Avatar resource is still preparing. The old completion would then be rejected
by `DashboardVisibleFrameStore` as `sharedInteractionEpochStale`, while the
pending candidate remained unresolved awaiting a completion that could never
succeed. The added production-parent red test reproduced that exact timeout by
claiming the real visible-store Mind order between cold Avatar request and
resource completion. The repair makes pending Avatar validity require that its
saved order is still the current owner or newer than the current owner. A
newer owner now produces the required `staleRejected` terminal outcome and
completes the original future `false`; it cannot strand motion/settlement.

The focused controller regression verifies the coherent identity through the
selected Budget target, Header target/title, selected progress visual, visible
scope, Phase-A cache binding and LogBox payload. The rail widget regression
adds a separate fail-closed guard for the physical split-brain edit window:
the hit target, presentation target, progress visual and edit-context target
must match before a long press can start or persist an edit. A matching
positive-limit target continues to render the existing ring through live edit
and persistence. No ring geometry, clipping or z-order was changed.

## Budget consequence

The Budget evidence records a visually hit target that differs from the
presentation target. Existing chrome intentionally returns `SizedBox` on that
mismatch, explaining the absent ring as downstream identity protection rather
than a persistence or clipping defect. A target mismatch must never be used to
start an edit.

## Previous work reused and corrected

| Artifact | Retained conclusion | Correction / missing acceptance |
| --- | --- | --- |
| `docs/superpowers/forensics/2026-09-06-summary-repeat-swipe-avatar-phase-a-frame-latency-repair.md` | The rail painter must use cache-visible Phase-A resources. | The aa26 defer implementation became a reject-and-forget input gate; production-parent replay was missing. |
| `docs/superpowers/checklists/2026-09-06-summary-repeat-swipe-avatar-phase-a-frame-latency-repair.md` | Resource authority needs strict identity. | Marking authority complete was false-green while end-to-end Avatar outcome remained partial. |
| `docs/superpowers/plans/2026-09-06-summary-repeat-swipe-avatar-phase-a-frame-latency-repair.md` | Preserve sparse bounded resources. | Still valid; the repair must reuse the same lane and cache. |
| `docs/superpowers/specs/2026-09-06-summary-repeat-swipe-avatar-phase-a-frame-latency-design.md` | No physics retuning without measurements. | Still valid; smoothness with zero accepted data is an automatic failure. |

## Graph provenance

The matching tooling manifest at `2d175fe0a6ed96a038c5655153df0a020cac4ff6`
indexes `5ba6c01eb391339c27861762ba888e29aae38593` with raw index SHA
`7102df2a16f9a8127bf22e75d786cbfdfca010d5512f99ca3f354b5c999ed035`.
The graph is used for impact navigation only; all causal findings above are
source- and trace-verified.

## Validation recorded during implementation

- Current-source red baseline: the cold replay test failed on unmodified 5ba
  with `Expected: false / Actual: true`, proving the old preview had been
  permanently rejected rather than retained.
- Pre-commit cross-producer red/green: a cold Avatar candidate followed by a
  real newer Mind visible-store order timed out before the correction; after
  the order-validity check it terminates `false` as `staleRejected`.
- Targeted current-source green: the three cold replay tests, exact-empty
  acceptance and the target-mismatch quick-edit test pass after the repair.
- Focused controller suite: `dashboard_core_ephemeral_focus_test.dart` passed
  all 53 tests after the final exact-empty and cross-producer-order additions.
- Focused Avatar rail suite: `budget_category_avatar_rail_test.dart` passed
  43 tests, including the mismatched target fail-closed and ring continuity
  regressions.
- Protected Time/Summary and Mind range tests passed in an unchanged-source
  batch of 146 tests. The eleven adjacent Avatar/Budget/cache/ring suites
  passed 177 tests. The full dashboard application suite changed from the
  exact-5ba baseline's 278 passing tests to 283 passing tests: the five added
  controller-level cold/warm/replay/empty/cross-producer regressions explain
  the delta.
- `dart format --output=none --set-exit-if-changed` passed for all five changed
  Dart files; `flutter analyze` passed with no issues.
- The repaired presentation suite result was `+586 -19`; the clean exact-5ba
  baseline was `+584 -19`. The two additional passing cases are the new
  regressions; all 19 failures have the same normalized baseline signatures
  (known geometry golden drift, reference-count drift, and stale harness
  failures), not an Avatar publication failure.
- The exact fast-suite list passed on clean 5ba through the JSON reporter and
  passed on the final repair branch through the canonical
  `./scripts/test-fluvi-fast.sh` command with 291 tests. One earlier canonical
  repair-branch attempt ended after `+290 -1`, but the retained terminal stream
  did not contain a case name or failure payload. The immediate JSON-reporter
  repetition and two later canonical repetitions (including after the
  cross-producer correction) passed; no code was changed in response to that
  unnormalized transient result.

## Remaining delivery and physical limits

The local tests establish the bounded correctness contract but do not claim
device smoothness. FrameTiming must be collected from the resulting
human-diagnostic APK only after accepted Avatar publications are present. The
human APK, matching final-SHA SCIP graph, and physical validation remain
delivery gates at this point in the document.

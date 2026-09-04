# shared live-publication authority repair — engineering journal

## [STEP 01]

Question: Is Avatar preview rejection after Mind interaction an input failure,
resource-cache failure, or shared visible-publication ordering failure?

Evidence:

- Fresh physical session `fluvi-1788482472212507` retains Time seq 1–598 and
  Avatar/Mind seq 1354–2353. The session has a retention gap 599–1353; that
  gap is not treated as evidence.
- The Avatar tail has 31 `AV|PREVIEW_REQUESTED`, 31 `AV|PREVIEW_REJECTED`, 28
  `AV|SEMANTIC_FRAME_REJECTED reason=visibleFrameStoreRejected`, 28
  `BUDGET_PROGRESS_IDENTITY_MISMATCH`, and six
  `FLING_SETTLE_AWAITING_SEMANTIC_FRAME` outcomes. It also has
  `AV|POINTER_ACCEPTED`, so hit testing is not the failed edge.
- Mind preview generations reach 63 earlier in the same retained tail. Avatar
  focus generations then begin at 2 and rise through 34.
- `DashboardVisibleFrameStore.publishPreparedInteractionPreview` compares its
  single `_interactionPreviewGeneration` directly with the caller's
  `previewGeneration`; Mind and Avatar pass unrelated local counters through
  `DashboardPresentationController`.

Conclusion: **CONFIRMED.** The store treats producer-local counters as a
shared order clock. A later Avatar intent can be rejected merely because a
prior Mind producer used more ticks.

Decision: Add typed producer plus store-owned/global intent ordering at the
shared publication seam. Keep a local target generation for same-producer
stale-result rejection. Do not remove stale rejection or alter motion physics.

Validation: deterministic same-store Mind → Avatar, delayed old-Mind,
reverse-order, and alternating-producer regressions pass after the repair.

## [STEP 02]

Question: Why can a valid Mind held-drag preview fail to apply canonically?

Evidence:

- In the fresh Avatar/Mind tail, the held-drag frames publish successfully,
  but seq 1388/1389 and 1921/1922 report
  `QUERY_CANDIDATE_SCENE_RETENTION_REJECTED` followed by
  `QUERY_DRAFT_PREPARE_FAILED`.
- `_prepareQueryCandidate` creates a complete semantic index/bundle, then
  throws when optional candidate scene retention is absent.
- `applyQuery` repeats this as a fatal restage requirement before publishing
  the candidate.

Conclusion: **CONFIRMED.** Optional Phase-B scene retention is still a fatal
dependency of canonical semantic Query application.

Decision: Test the real retention rejection, then publish a valid mandatory
semantic candidate with `sceneStaged=false`; retain/retry rich scene only as a
bounded Phase-B augmentation. Keep scope/index identity strict.

Validation: a protected candidate-bank regression reaches the real canonical
application path and now applies the exact amount-refined query once while
recording the optional Phase-B retention failure.

## [STEP 03]

Question: Does the Phase-A renderer satisfy the user-visible row contract?

Evidence:

- The user screenshot shows count text but Phase-A cards with a purple bar,
  gray strokes and a dot, not merchant/amount/date glyphs.
- The Time session has semantic acceptance with rich-root misses, which
  matches the fallback path.
- `DashboardLogBoxRenderSurface._paintSemanticPreviewSlots` deliberately
  paints geometric placeholder-like marks when no rich scene is available.

Conclusion: **CONFIRMED.** Exact row identity/paint count is not readable
transaction content.

Decision: Reuse bounded immutable prebuilt row text resources from the
prepared scene cache for Phase A; no `TextPainter` or rich projection in
`CustomPainter.paint`. Add a visual/resource contract test.

Validation: prepared-readable-row and painter regressions prove merchant,
amount, secondary text and time/date glyph layouts are selected for Time,
Mind and Avatar Phase A. Paint only consumes immutable prepared resources.

## [STEP 04]

Question: What exact identity rule rejects a correct Time
preview-to-committed acknowledgement?

Evidence:

- The fresh Time tail has accepted live snapshots without query/index work per
  tick and a `railPreview → committedVertical` render-domain change before a
  current-target paint rejection/settle rejection.
- The acknowledgement guard required `drawableRowCount == payloadRowCount`.
  That equality is valid for the bounded rail-preview window, but a correct
  committed-vertical snapshot may expose the same exact target with a larger
  full-scope drawable range.
- The new physical-order regression models live ticks, a rich-root miss,
  readable Phase-A paint, promotion, and delayed old/current extent reports.
  It proves the old report remains rejected while the current same-target
  acknowledgement succeeds without a visual republish.

Conclusion: **CONFIRMED.** This is not the Avatar ordering collision. It is
a too-strict geometry-cardinality guard across a valid render-domain
promotion. Exact target/query/revision/presentation/frame/viewport/geometry
guards remain strict; only the full-scope cardinality relation is widened to
permit `drawableRowCount >= payloadRowCount`.

Decision: Preserve the existing owner and identity checks; repair only this
source-proven cardinality constraint.

Validation: promotion regression passes; stale old reports stay rejected.

## [STEP 05]

Question: What constructs the `Prepared frame scope identity mismatch` seen
at fresh-session seq 1682?

Evidence:

- The typed mismatch diagnostics capture expected and actual scope tuples at
  the existing fail-closed boundary.
- Dart `CurrentLedgerQueryScope` serialized amount refinements in insertion
  order, while the native canonical scope key uses the stable order
  `minimumAmount`, `maximumAmount`, then `note`.
- A deterministic codec/index regression constructs the physical Mind amount
  path and reproduces the differing key tuple. A negative incompatible-scope
  test remains rejected.

Conclusion: **CONFIRMED.** The source construction defect was divergent
canonical refinement ordering, not an invalid identity assertion.

Decision: align Dart serialization with the native canonical ordering and
retain all revision, direction, parent-scope and effective-scope guards.

Validation: binary-codec and prepared-index regressions pass.

## [STEP 06]

Implementation outcome:

- `DashboardVisibleFrameStore` now owns a typed producer and monotonic
  interaction/publication epoch. Local generations remain per-producer stale
  guards rather than a cross-producer clock.
- Query candidate preparation distinguishes mandatory semantic readiness from
  optional rich-scene staging. A rich candidate-bank miss is diagnosed and
  deferred, never allowed to invalidate an exact canonical query.
- Phase A carries a bounded immutable readable row bank from the existing
  prepared-resource architecture. The stable painter draws those layouts and
  reports readable/rich row counters without constructing text in its hot
  path.
- Avatar Budget surfaces defer until their matching accepted visible semantic
  target commits, so selected handle, header, distribution, count, focus and
  LogBox share one identity. Late Phase B remains non-authoritative.

Automated validation is recorded in the checklist. Physical validation is
**PENDING — USER ONLY**.

## [STEP 07]

Review finding: an initially public `DashboardInteractionPreviewOrder`
constructor would have allowed a caller to fabricate a future-valued token and
advance the shared cursor. This would violate the store-owned authority model.

Repair: token construction is now internal and each issued token carries the
private identity of its issuing visible-frame store. A foreign-store token is
rejected before either local-generation or shared-epoch comparison, so it
cannot change the current owner or poison the local cursor.

Validation: the new foreign-store rejection regression passes; the local store
then issues epoch 1 and publishes normally. Independent review found no other
concrete defect in the Mind optional-scene, strict scope, Phase-A, Time, or
Avatar repair paths.

# Avatar target-local Phase-A architecture card

Sources: current implementation-authorized user prompt, docs/superpowers/evidence/2026-09-09-avatar-target-liveness/user-prompt.txt (read fully), exact aa61242 production source and c8a49968 graph. Acceptance: ../checklists/2026-09-09-avatar-target-liveness.md.

## Single source and write path

BudgetTargetAvatarRail collects physical crossing/settle intents; DashboardBudgetLogboxDrilldownCoordinator maps an existing target handle to focus. DashboardCoreController retains one latest derived candidate and its original DashboardInteractionPreviewOrder. Existing budgetAvatarPreview lane in DashboardLogBoxPreparedSceneCache owns actual row/header resources. Core publishes through DashboardVisibleFrameStore; only its semantic callback changes DashboardBudgetPresentationController target. Existing actual Header/progress/LogBox acknowledgements provide evidence, not another authority. The existing deferred focused installation canonically adopts the final target.

| State | Owner | Lifetime/publication |
|---|---|---|
| Physical position/motion | Existing Avatar shared carousel/ScrollPosition | Persistent widget, untouched |
| Desired exact candidate/order | Core existing pending slot | Latest request only; stale/dispose/coalesce terminal |
| Exact Phase-A resources | Existing prepared-scene-cache Avatar lane | Bounded lease; old readable visual retained during replacement |
| Visible frame | DashboardVisibleFrameStore | Exact binder success only |
| Budget/Header/progress selection | DashboardBudgetPresentationController | Existing matching visible semantic callback only |
| Canonical focus | Core existing deferred focus install | Generation/order fenced, final target only |

## Reuse decision

Extend existing candidate with immutable exact payload already derived for its visible scope, not a second focus index/cache. Reuse _prepareLiveInteractionRowResource and scene cache lane for bounded one-target resource preparation. Broad hotset remains optional prearming; it cannot be the liveness dependency of a current candidate. Do not change the shared helper's Time/Mind behavior. Preserve existing semantic/paint/canonical guards; tighten Avatar-only stale fencing if red tests prove a gap. Typed pure resource-window classification may be factored into an Avatar-only application value/helper, with no new mutable owner.

Alternatives rejected by supplied design: retrying broad hotset depends on unrelated entries; bypassing binder paints unreadable non-empty data; per-surface Header/list fixes split authority. No physics/visual redesign is proposed.

## Large-file justification

Core is an inherited >800-line orchestration owner. This task is restricted to its existing Avatar candidate/resource/deferred-install seam. A cross-controller rewrite would mix protected Time/Mind responsibilities into scope. Keep any new pure classification/value object in a focused application file; do not add another controller or copy the shared preparation algorithm. Rail changes, if needed, are semantic terminal accounting only, never motion engine.

## Verification

Test-first persistent CoreDashboard with eight disjoint non-empty category payloads and their non-empty aggregate (aggregate necessarily contains those categories, so nine mutually disjoint row sets would contradict aggregate semantics). Actual pointer/scroll crossings, no Time interaction, final identities and actual paints, 20 forward/reverse cycles. Separate sparse, null-branch, delayed-completion, final8/earlier1, aggregate0, endpoint7/8 tests. Existing architecture suites extended to forbid new owners and changes to protected paths. K negative fixtures and real exact-SHA JSON must prove non-empty final-target coherence. No new approved visual reference is supplied: layout/design is immutable; actual paint identity is required, not blanket goldens.

## Execution mode

Inline: resource candidate, publication, settle and composition reproducer are sequential and share Core state. Independent profile review may be delegated only after its evidence contract is stable. User prompt already authorizes this design and implementation; no repeated design approval gate.

## Implemented review refinements

The existing candidate's immutable payload identifies its one-target scene window. Cancelling a superseded Avatar lease lets the latest target prepare before an older suspended slice returns. The shared cache task scheduler and other resource lanes are unchanged.

A return to the still-visible category while another target is pending cannot use the already-active shortcut: it follows the existing focus generation, candidate supersession and deferred canonical installation path. Category and aggregate reuse one small Avatar admission predicate for a new accepted interaction order with unchanged pixels. Category paint retention additionally requires an existing exact paint acknowledgement; semantic equality alone never manufactures a paint.

The coordinator observes actual renderer completion asynchronously while preserving the rail's existing semantic-return timing. Each preview records one typed terminal; the existing Avatar admission guards classify Time ownership and disposal explicitly. No additional listener owner or request queue is added.

Typed window resolution is stateless and records the expected and actual offending payload queries. Cache-only exact row/header counts correlate with Core target/order metadata through resource and payload digests. Unknown cache coverage at the application-only window boundary is labeled unknown, not zero. Actual scheduling is emitted at the real preparer call, separately from the earlier rejection.

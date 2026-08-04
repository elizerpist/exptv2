# Dashboard interaction performance isolation design

## Scope and sources

- Baseline: `40f8431` on `feature/dashboard-open-rail-parent-transition`.
- Historical comparison: `milestone/dashboard-rail-smoothness-3dd650c`.
- Preserved behavior: child preview crossings, open-rail atomic parent transition,
  retained/clamped child ordinal, direct/no-op preview amount, zero-result
  snapshots, stable Flutter `Scrollable` ownership and direction/filter parity.
- User constraint: single-agent inline execution, no physics tuning before
  side-effect isolation, no golden tests.

## Architecture card

### Single source and write path

- Visible UI truth: `DashboardPresentationStore`.
- Canonical reusable data owner: `DashboardParentBundleRegistry`.
- Only visible write path: a coherent immutable snapshot accepted by
  `DashboardPresentationStore` after query/revision/epoch validation.
- Background error/retry owner: `DashboardBackgroundWorkCoordinator`.

### State ownership

| State | Owner | Lifetime | Publication rule |
|---|---|---|---|
| Rail physical motion | shared `CenteredCarousel` | widget State | Never owns query or I/O |
| Child/parent motion epoch | dashboard interaction coordinator | interaction | Invalidates pending work and stale callbacks |
| Visible presentation | `DashboardPresentationStore` | dashboard | Atomic immutable publication only |
| Complete parent bundle | `DashboardParentBundleRegistry` | bounded cache | Parent summary and child deck enter together |
| Core data revision | stable native revision stream | app/database | Marks entries stale; never selects UI scope |
| Background jobs | `DashboardBackgroundWorkCoordinator` | dashboard | Idle-only, keyed, deduplicated, latest-wins |
| LogBox preview model | canonical bundle entry | bundle revision | Projected before interaction, selected O(1) |

### Reuse and centralization

| Candidate | Existing owner | Decision |
|---|---|---|
| Child rail drag/ballistic/snap | `CenteredCarousel` | Preserve and extend only no-op configuration filtering |
| Visible snapshot validation | `DashboardPresentationStore` | Preserve as sole UI truth |
| Child bundle cache | `DashboardSummaryMetricsController` | Extract/migrate into canonical registry; remove duplicate ownership |
| Exact-scope live lease | `CurrentQueryController` | Replace per-selection watch ownership with stable revision invalidation |
| Adjacent prewarm timer | `DashboardAdjacentParentPrewarmCoordinator` | Fold into the central background-work scheduler |
| LogBox view-model projection | `DashboardLogViewModelProjector` | Run during bundle construction, never during preview publication |

### Layer flow

```text
Interaction / presentation lane

gesture or semantic selection
  -> motion/interaction epoch
  -> synchronous DashboardParentBundleRegistry lookup
  -> DashboardPresentationStore atomic publish
  -> narrow UI selectors

Background synchronization lane

stable core-revision invalidation
  -> DashboardBackgroundWorkCoordinator
  -> repository/native parent bundle read
  -> canonical registry atomic replace
  -> guarded visible refresh only when still current
```

### Canonical bundle identity

`DashboardParentBundleKey` contains direction, parent scope, categories,
partners, refinements, child kind and preview payload schema/page budget. The
core revision is entry version/freshness metadata, not a second semantic
identity. Motion epoch, navigation revision, rail index, `railOpen`, widget
keys and animation generation never enter the cache key.

Each complete entry contains:

- exact parent query and summary snapshot;
- one core revision and semantic content identity;
- the complete aggregate child metrics deck including explicit zero buckets;
- bounded immutable LogBox viewport models for immediate child preview;
- paging cursors for committed vertical scrolling only;
- completeness, freshness and estimated byte weight.

The current parent is pinned. Adjacent entries use a bounded byte-aware LRU.
Startup, cold load, live refresh and prewarm write the same registry; parent
navigation, rail open/close, child preview and settle read the same registry.

### Interaction invariants

- No repository read, child bundle build, native subscribe or adjacent prewarm
  starts while a parent/child gesture, ballistic activity, rail/plane/direction
  transition or local navigation animation is active.
- A stable invalidation subscription may remain active; selection never
  restarts it.
- A fresh child settle is presentation promotion only and has no I/O.
- Cached parent navigation is one synchronous lookup and one atomic publish.
- Old callbacks and results can populate only a semantically matching cache
  entry and cannot publish after epoch/query/revision mismatch.
- The child rail controller, `ScrollPosition`, physics parameters and widget
  State remain stable.

### Rebuild boundaries

- Direction pulse animation rebuilds/repaints only its icon subtree.
- Amount animation updates only the amount subtree.
- Rail configuration notifies only when semantic configuration changes.
- Query/live/cache events do not rebuild `DashboardMotionHost` or the entire
  `CoreDashboard`.
- LogBox snapshot changes retain one viewport State and `ScrollController`.

### Native boundary

- SQL/native aggregation returns child `SUM`/`COUNT` buckets and bounded first
  viewport rows; preview never scans or transports a full parent transaction
  list.
- Room I/O runs off Android main; grouping/mapping/serialization run on an
  appropriate background dispatcher; only the completed channel reply is
  handed to main.
- Requests carry generation/cancellation identity and unchanged semantic
  content is not republished.

## Alternatives rejected

1. Pinning the current three-entry cache and skipping only selected lease
   activations leaves split ownership, root rebuilds and native full scans.
2. Adding another SummaryPill or preview cache creates a second UI/data truth.
3. Physics/friction tuning masks variable frame load and changes product
   behavior without addressing the cause.
4. A full dashboard rewrite risks the already-correct parent/child state
   machine and motion identity.

## Verification strategy

- Test-first unit/controller/widget tests with observed RED before production
  changes.
- Architecture boundary tests enforce one cache owner, no repository imports
  from widgets and no query-key viewport keys.
- Deterministic 5k/20k/100k native and Dart fixtures.
- Profile-mode `FrameTiming` and `TimelineTask` measurements on one physical
  device, with verbose FLOW logging disabled.
- No golden tests.

# Dashboard bootstrap, preview diagnostics and stress design

## Goal

Preserve the current live child-preview baseline while making its frame-visible
behavior measurable, preventing an invalid cold-start dashboard frame, and
keeping preview payloads bounded for large ledgers.

## Architecture card

### Single source of truth

`DashboardPresentationStore` remains the only visible owner for amount, count,
LogBox rows, query key and revision. `DashboardSummaryMetricsController`
continues to resolve child previews; the rail only emits semantic crossings.
`CurrentQueryController` remains the committed read/watch owner.

The store snapshot carries two independent facts:

- `presentationMode`: why the snapshot is visible now (`preview` or `committed`);
- `dataOrigin`: where the immutable data was obtained (`childPreviewBundle`,
  `childPreviewIndex`, `memoryCache`, `persistentCache`, `freshQuery` or
  `liveObserver`).

Data origin never determines interaction mode.

### Diagnostics lane

The motion callback records a compact typed crossing event. The presentation
lane records snapshot selection and publication. A frame scheduler records at
most one presented event per display frame, for the latest pending generation.
Diagnostics use a bounded ring buffer and numeric counters; existing verbose
FLOW logs remain optional compatibility output and are not extended on the hot
path.

The event flow is:

`rail crossing → snapshot selected → full snapshot published → frame presented`

The settle path only promotes an already-visible preview. Identical visual
content is a metadata-only no-op.

### Bootstrap lane

`DashboardBootstrapController` owns only lifecycle readiness. It does not own a
second query/cache/presentation path. It runs the initial one-shot critical
read/readiness operation, waits for the current parent bundle preparation, and
exposes `DashboardBootstrapPhase`. The shell renders the existing external
skeleton until `ready`, then mounts the unchanged `CoreDashboard` exactly once.
Live observation may begin after the ready publish and never gates the first
valid frame.

### Bounded stress data

The existing immutable child bundle remains data-only. Preview row budgets are
explicit and bounded; aggregate totals/counts remain exact. Deterministic
seeded fixtures live in a test/debug-only pure generator. Cache diagnostics
track bounded rows and estimated bytes. No widget, render object, hidden list
or per-child crossing query is added.

## Required guards

- A late committed result can update the query/cache but can only activate when
  its key, revision, interaction epoch and generation are current.
- Bootstrap never publishes a null/loading dashboard snapshot as the first
  visible dashboard state.
- Zero-result is a valid `0 Ft`/`0` snapshot, not a dash placeholder.
- Preview selection remains synchronous and memory-only.
- No rail physics, ScrollController, ScrollPosition, simulation, snap,
  velocity mapping or gesture ownership changes.

## Verification

RED tests precede production edits. Focused tests cover typed diagnostics,
frame coalescing, late result rejection, bootstrap readiness/no-dash,
deterministic stress fixtures, bounded rows and cache eviction. The complete
non-golden suite and analyze run through Ubuntu proot. Physical profile values
are reported only when actually measured.

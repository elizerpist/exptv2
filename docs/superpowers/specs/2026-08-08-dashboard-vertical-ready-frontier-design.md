# Dashboard vertical ready-frontier design

## Architecture card

- **Runtime base:** `534bf791081495d263f92a1b4abf2b910d53af28`.
- **Performance freeze:** the rail motion kernel, rail widgets/controllers,
  carousel, physics, prepared rail scene cache and PreparedDashboardIndex
  navigation path are read-only for this change.
- **Single vertical state owner:** `CommittedLogViewportCache` owns page state,
  drawable geometry, retained page resources and visible/drawable windows.
- **Single page acquisition owner:** `ExplicitCommittedPagingController` owns
  the keyset request identity, request state and cursor/ordinal advancement.
- **UI responsibility:** `DashboardLogBoxViewport` forwards a bounded demand
  from scroll state; it does not issue repository calls. The render surface
  paints only the drawable window and never starts work or creates layouts.
- **Diagnostics owner:** `FluviDiagnosticLogger` owns bounded general and
  explicit-capture rings. The debug dialog only renders and controls it.

## Evidence and root-cause flow

`ScrollUpdate → pageOrdinalForOffset → updateVisibleRowWindow → retention →
onLoadNextPage → ExplicitCommittedPagingController.loadNextPage → native
keyset page → DATA_READY → CommittedLogViewportCache.commit → exact-width
page preparation → cursor/ordinal advancement → geometry publication → paint`.

The former `_CommittedPageGeometry` constructed base height for every ordinal
from `totalEntryCount` at seed time. Therefore 658 metadata rows yielded a
658-row scroll extent while only ordinal zero was drawable. The painter then
encountered an absent page and intentionally painted nothing after reporting
`VERTICAL_CACHE_MISS`: this is the observed phantom area.

The page-zero-to-page-one audit found two additional concrete failure paths.
First, `DashboardLogBoxRenderSurface.build` re-seeded an externally owned
`CommittedLogViewportCache` on every cache-listener rebuild. A successful page
commit could therefore be replaced immediately by page zero, leaving its
cursor/ordinal frontier at zero. Second, every new `ScrollStart` demanded two
pages beyond the *already prepared frontier*, rather than beyond the actual
scroll position. Repeated drag starts could prepare far-ahead pages and cause
retention to evict the page the user was about to see.

The old controller had no request identity/state table: an unsuccessful cache
acceptance or preparation left `_nextPageOrdinal` and `_nextCursor` unchanged,
then a later scroll event could request the same ordinal again after the
in-flight boolean cleared. It returned only `false`, so the exact predicate
was not observable. The new identity uses a sorted key/value cursor digest
(never ephemeral `MapEntry` identity), and terminal rejects are explicit.

## Chosen state model

Only a contiguous `DRAWABLE` page prefix contributes to content extent:

`REQUESTED → DATA_READY → PRESENTATION_PREPARING → PRESENTATION_READY →
COMMITTED → DRAWABLE`.

`totalEntryCount` remains display metadata. A page prepares text, headers,
geometry, assets and cursor metadata before a transactionally atomic commit.
The commit advances the frontier and publishes its real geometry together;
failure leaves prior content and extent unchanged. A bounded demand
coordinator requests the contiguous frontier plus two pages of lookahead, with
one request per `(query, revision, generation, ordinal, cursor digest)`.

Page zero retains the already-ready rail preview resource. Page one and later
have independent vertical page resources. The vertical retained heavy window
is bounded; lightweight cursor/geometry metadata may cover a larger prefix.
Retention runs after an atomic drawable commit and is centered on the actual
drawable viewport. It never uses a speculative target ordinal. Scroll-start
lookahead is calculated from the actual offset, never from an already-growing
extent.

## Verification strategy

Test-first coverage proves no phantom extent, successful/rejected commit
terminality, failure retry only on a new explicit demand epoch, duplicate
suppression, target-safe eviction, page-zero reuse, full 658/1k scrolling and
synthetic 10k/50k/100k frontier traversal. Logger tests prove O(1) rings,
aggregated repeated misses and frozen captures. Widget coverage crosses every
page-zero boundary. No golden test is added.

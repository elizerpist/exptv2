# Dashboard LogBox implementation plan

> Execute continuously after the architecture audit. Every production change
> follows red → green → focused regression; commits are grouped by completed
> vertical slice.

1. Add failing domain/boundary tests for exact committed snapshot identity,
   day grouping and no preview ListBox activity.
2. Extend native core query models/read service and Android bridge with a
   complete-day keyset page: select bounded local dates, batch-fetch rows and
   return aggregate + page metadata from one read snapshot.
3. Extend the Flutter ledger repository/result contract and method-channel
   decoder. Maintain canonical query/revision metadata through page mapping.
4. Add immutable LogBox domain models, presentation projector and bounded LRU
   page cache. Make missing/old revisions unavailable rather than stale data.
5. Implement `DashboardLogPageCoordinator`; it observes only committed query
   state, provides explicit area states, binds first pages atomically, guards
   paging and emits structured diagnostics.
6. Extend the shared centered carousel with a target-resolved callback that
   preserves all physics constants. Route its logical target to the
   coordinator prefetch path; add tap-target support.
7. Compose a committed snapshot in `DashboardCoreController`, route the main
   dashboard through a single vertical `CustomScrollView`, and keep fixed
   header/rail gesture regions isolated from the LogBox slivers.
8. Build day header, joined group, row, loading/empty/error/footer widgets
   with Fluvi tokens, central category badge and stable identity.
9. Add golden, widget, integration, Room, paging/N+1, rail/rebuild and
   performance coverage. Record measured results in the mapping/checklist.
10. Run full Flutter, Android core, boundary and online CI; commit, push,
    monitor the APK workflow and download the verified release asset.

## Floating count follow-up plan

1. Add widget tests which demonstrate the entry-count label scrolls with the
   LogBox today and which require it to remain fixed below the collapse handle.
   Add a geometry assertion that the day-group surface uses the same outer
   left/right bounds as the SummaryPill.
2. Separate the existing LogBox header into a fixed presentation-only sibling
   layer and leave only a same-height sliver spacer in `DashboardLogArea`.
   Paint the fixed layer with the page surface so rows disappear beneath it;
   it receives no pointer or query responsibility.
3. Change the now-duplicated LogBox-internal outer gutter to zero because the
   LogBox region already receives `DashboardGeometryResolver`’s shared
   content bounds. Keep all row-internal inset tokens unchanged.
4. Re-run focused widget tests and inspect the resulting screenshot. Keep the
   change uncommitted until the user’s next grouped UI instructions arrive.

## Preview LogBox performance-recovery plan

1. Capture failing controller/widget regressions for a preview-child sequence:
   metrics count and LogBox page must both change for every cached child, while
   the committed query stays unchanged until settle. Capture collapse-frame
   rebuild counts for the LogBox subtree.
2. Extend the existing `CurrentQueryController` first-page LRU rather than
   introducing a parallel raw-data cache. Add a bounded data-only warm batch:
   complete finite child domains (12 months/28–31 days) and a small
   `maxItemsPerFling`-derived window for unbounded years. It must never create
   a watch or mutate the current query.
3. Extend `DashboardLogPageCoordinator`, the existing paging/cache owner, with
   a presentation-only preview selector. It consumes immutable summary metrics
   and cached first-page data, emits exact scope/key/revision list snapshots,
   and renders a scoped skeleton on a cache miss. The committed state remains
   independently owned by `CurrentQueryController`.
4. Keep preview emissions O(1): select an already projected first-page state
   by canonical scope key. Do no page formatting, native call, watch,
   subscription, rail physics change, or root-dashboard notification per tick.
5. Make the `CoreDashboard` retain one identical LogBox subtree instance across
   `DashboardMotionHost` frames. Geometry may move/resize its render box, but
   collapse/expand must not rebuild the scroll/list widgets.
6. Run the focused preview, warm-cache, rebuild, paging and physics suites;
   then full Flutter test/analyze in Ubuntu. Commit, push, monitor GitHub
   Actions and download the generated APK.

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

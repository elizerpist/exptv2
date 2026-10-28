# Ghost transaction diagnostic intake — 2026-10-28

Starting source: `5aaca45fbcddc1d12ad97fece43edab44acda2fc`.

This is an evidence log, not a claim that the device-reported missing ghost
transactions have been reproduced or repaired.

| Question | Evidence | Conclusion | Change / next measurement | Result |
| --- | --- | --- | --- | --- |
| Does changing the Ghost control form alter membership? | The existing Core owns `applyGhostFilterMode`; the presentation preference is outside `CurrentLedgerQueryScope`. | It must be presentation-only. | Added a separate persisted presentation enum and kept all controls bound to the existing Core operation. | Automated widget/preference coverage. |
| Can a direct Ghost tap issue a Room/index rebuild? | `DashboardCoreController._applyGhostFilterMode` selects a resident ghost-neutral hotset and logs `repositoryRequests=0 indexBuilds=0` on publish. | A quick-filter tap is expected to be cache-only. | Added `GHOST|UI_INTENT`, projection-derived and publish/reject boundaries. | Static path proven; device timing remains pending. |
| Which native conditions can exclude a pending ghost? | `FluviLedgerReadService.ghostPresentationWhere` requires pending status, active/non-archived rule, matching direction/period/refinements/joins and `show_pending_ghosts_in_ledger=1`. | A missing pending row can be a valid configured exclusion; it is not safe to change that setting automatically. | Native index result now emits bounded preview classification for normal, realized ghost and pending ghost rows. | Requires Ghost capture on the affected dataset. |
| Is the `Prepared frame repeats a row reference` exception proven to be the cause? | It is thrown by `_DeferredRichProjectionBuilder._projectOneRow`; the supplied screenshot names it, but no matching runtime trace was available locally. | Not proven as the universal ghost root cause. | Preserve uniqueness invariant and log ordinal, table index, first occurrence, bounded source/unique counts and ghost flags immediately before the throw. | Requires capture if reproduced. |
| Can Ghost export leak unrelated diagnostics? | The former console copied the active live filter but capture export copied the entire frozen buffer. | Ghost capture/export needs a domain filter at ingestion and export. | `GHOST|` is now the stable classifier; Ghost capture retains only those events and its marker selects the Ghost view. | Logger/widget tests cover mixed events. |

Required physical follow-up: use the Ghost capture protocol supplied with the
diagnostic APK, on the known period, before changing a source predicate or
financial aggregation. The expected final status before that capture is
`TEST-CLEAN / DEVICE-PENDING`.

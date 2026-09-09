# Avatar ownership and retention verification

Scope: user §10.12, AVL-15. The final 20-cycle test checks forty forward/reverse flights without remounting the CoreDashboard, rail controller, ScrollPosition, or actual scene cache. It now retains the diagnostic ring across flights, selecting each flight's evidence by monotonic event sequence rather than clearing the logger.

## Runtime assertions in the persistent composition

At every final target: pending Avatar candidate=0; hotset entries≤17; pending plans≤17; retained candidate banks≤6; retained unique candidate rows≤fixture rows×6; retained candidate bytes≤the existing16MiB cap; active bank scenes≤the existing32768 cap; prepared query candidates≤6; diagnostic ring entries≤1000. All requests have one terminal, and no terminal is an explicit invariant failure. The same rail controller, ScrollPosition, physics creation count and CoreDashboard State remain attached.

The final full presentation run passes all eight Avatar scenarios, including these scene/byte/query-candidate and cumulative diagnostic assertions. Earlier focused green logs precede these last test-only assertions.

## Static ownership proof and measurement limits

The Core Avatar hotset holds at most17 derivations/indexes. Its `_focusBaseIndex` and `_provisionalFocusBaseIndex` are single slots, as are pending Avatar candidate, deferred focus install and deferred augmentation. The unchanged ephemeral deriver retains a view of its base rather than assembling another full index. The six-entry prepared-query candidate count is a separate speculative-query bound, not a complete heap count of focus indexes.

The existing cache has at most six retained candidate banks and two enum-owned retained active snapshot slots; every admitted window obeys the existing scene cap. `preparedSceneCount` reports the active bank only. This combines actual active-scene/bank/row/byte measurements with the unchanged finite slot and per-window bounds; it does not claim a total-scene heap census.

Avatar rail listeners register once in initState, use paired remove/add when an owner changes, and are removed in dispose. Budget presentation, CoreDashboard and render-surface listener lifecycles are unchanged. The final production diff adds no listener registration, ValueNotifier, or collection of listeners. Paint completions reuse the existing single candidate/completer contract; the runtime terminal accounting proves no unfinished preview at a checked endpoint. This is a source/lifecycle proof of bounded listener ownership, not an instrumented numeric listener-count or heap measurement after20cycles.

The new resource-window helper is stateless. It owns neither cache nor timer, listener, index collection, store, controller or retry loop. Resource preparation and cancellation remain in the existing Avatar lane of the sole scene cache. The unchanged diagnostic sink is a fixed1000-entry ring; the revised stress also measures its cumulative retention without clearing it between flights.

Read-only review covered the final production diff, Core hotset eviction, index slots, rail init/update/dispose, cache retention slots/caps and composition assertions. Protected-source hashes are in `protected-production-source-hashes.json`.

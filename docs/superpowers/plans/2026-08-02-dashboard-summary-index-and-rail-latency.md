# Dashboard summary index and rail latency implementation plan

Status: approved by the user's explicit “csináld, commit push build download”.

## 1. Prove and specify the contracts (TDD)

- Add failing Flutter tests for a child-summary index decode, bounded cache,
  loaded-index preview behaviour, cache miss/latest-wins handling, and amount
  transition lifecycle.
- Add failing Kotlin tests for `GROUP BY` year/month/day using the existing
  local-date predicate and facets.
- Add/extend a core-controller test that 100 previews do not create detailed
  watches while the amount projection can update independently.

## 2. Extend the shared query read contract, not the rail

- Add typed child-summary models to the dashboard repository domain.
- Extend `FluviLedgerReadService` with a grouped child-period read which calls
  its existing `where` builder and derives canonical child query keys.
- Expose one `readDashboardChildSummaries` MethodChannel method from
  `MainActivity`, decoding the same `DashboardQueryArguments` contract.
- Decode that response in `MethodChannelDashboardLedgerRepository`.

## 3. Add an isolated summary amount/application owner

- Implement `DashboardSummaryAmountController`: it listens to navigation and
  current query state, loads/caches only parent indices, and presents the
  displayed child with a map lookup while the rail is open.
- Keep `CurrentQueryController` untouched as the owner of detailed settled
  queries.  Wire the amount controller into `DashboardCoreController` and
  dispose it there.

## 4. Isolate the amount subtree and add truthful timings

- Add an amount listenable/builder slot to `DashboardSummaryPill`, symmetrical
  with the existing navigation slot, so preview cannot rebuild the motion host.
- Replace ambiguous D10 diagnostics with D10A–D10D.  Add R1–R4 at observable
  adapter/application boundaries; do not fabricate an engine-private R0.

## 5. Verify, deliver, and record evidence

- Run targeted Flutter suites and unchanged centered-carousel suites in Ubuntu
  proot; run analyzer and inspect its known unrelated lints.
- Run native tests through the required GitHub Action after push.
- Re-read the checklist, update every status from fresh evidence, commit,
  push, wait for the online APK artifact/release, download it to the mandated
  directory and verify checksum.

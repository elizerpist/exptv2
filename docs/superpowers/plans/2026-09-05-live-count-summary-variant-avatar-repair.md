# Implementation plan — live count and Summary-variant / Avatar authority

Base: `fcc574b6cf2e58a181e0b841d6252a475ca9342c`.
Branch: `fix/live-logbox-count-summary-variant-authority-codex-20260905`.

The count binder and the variant/Avatar forensic path share the same visible
frame/core production parent and must be sequenced.  Inline execution is less
risky than parallel implementation because a second worker could otherwise
change the authority seam while the reproducer is being established.  A
separate read-only review is appropriate only after the implementation diff is
stable.

1. **COMPLETED — Establish evidence baseline.**  Record ref/status, fully
   read fcc lineage/docs/source/tests, deduplicate the three Drive tails,
   verify matching graph manifest, and run relevant fcc baseline tests.
2. **COMPLETED — Red count coverage.**  Add a focused header/production-parent
   test that publishes committed A then accepted live B/C/D from Mind, Avatar,
   and eligible Summary paths; prove the current header stays on A and that
   row payload length is not substituted for total count.
3. **COMPLETED — Small count binding repair.**  Reuse the typed count lane at
   `DashboardLogBoxHeader`, identity-gate it against the active visible
   projection, retain a small rebuild boundary, then prove red → green and
   canonical/cancel/stale reconciliation.
4. **COMPLETED — Variant / Avatar reproducer and diagnostics.**  Keep one real
   `CoreDashboard`, controller, store, Budget owner and LogBox owner through
   the required A→B→A motion/rail/header/tuner sequences.  Add bounded
   transition/paint/geometry diagnostics only where the test cannot otherwise
   expose ownership.
5. **COMPLETED — Diagnose then repair only a proven edge.**  Classify the
   actual variant failure or paint-accounting discrepancy.  If reproduced,
   implement the smallest transition boundary and stale-callback/layer fix;
   otherwise ship only the count repair plus forensic instrumentation and
   report the physical-only blocker honestly.
6. **COMPLETED — Validate and review impact.**  Formatter, analyzer, focused
   and broad suites were run in Ubuntu proot; the fcc stable-render baseline
   failure was reproduced unchanged; matching graph consumers and CURRENT HEAD
   source were reviewed.
7. **IN PROGRESS — Commit, delivery, graph provenance.**  Commit/push only
   evidence-backed app changes, monitor/download/hash the exact GitHub human
   APK, then separately regenerate/validate/commit the SCIP graph for the
   final app SHA.

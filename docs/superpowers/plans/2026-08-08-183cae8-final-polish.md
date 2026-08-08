# 183cae8 final polish implementation plan

Approved design source: the user’s 183cae8 final-polish specification. Execution is inline because the lifecycle, diagnostics and SummaryPill changes share the same presentation identity and are tightly coupled.

1. Prove the two ownership gaps from the current call paths and add focused failing regressions:
   - metadata-only committed settlement must reset a deep stable viewport;
   - one viewport must survive July → June → May → April with preview/no-reset and committed/one-reset semantics;
   - diagnostics must not label cached committed data as current preview rendering;
   - SummaryPill must project live typed child temporal labels.
2. Move vertical reset subscription from the complete visible-frame store to `logBoxPresentationLane`; retain the existing controller/position and emit one counter/event through the core controller callback.
3. Make render-extent snapshots domain-specific while retaining committed-cache fields explicitly for diagnostics.
4. Extend the existing summary projector with a pure typed live-child formatter and route the open-rail SummaryPill presentation through it.
5. Run focused tests red/green, then the complete non-golden suite and `flutter analyze` inside Ubuntu/proot.
6. Re-read this checklist, audit frozen paths against the milestone, commit and push. Run the GitHub HUMAN_DIAGNOSTIC build, monitor it, download only its normal-app artifact to `/storage/emulated/0/Download/fluvi`, then verify SHA-256 and ZIP/APK integrity.

# Fluvi physical-feedback round implementation plan

1. Establish red tests for the exact 1000-entry logger, virtualized follow UX,
   marker/export metadata, and bounded notification behavior.
2. Replace the whole-document console projection with a lazy rolling tail and
   low-noise, frame-batched UI publication.
3. Add red domain-identity and Mind interaction tests. Centralize the
   amount-domain identity that excludes only its own amount refinement, retain
   compatible ready data, and add a prepared in-memory, frame-coalesced preview
   path with one release commit.
4. Add deterministic Avatar and time flight workload tests. Remove synchronous
   full publication/navigation from transient crossings, preserve retained
   visual preview, and perform latest semantic commit at settle.
5. Add low-frequency Rhythm slot-owner diagnostics and gray-state invariants;
   fix rendering only if the exact owner is reproduced and proven. Preserve the
   intermediate-collapse coverage. Audit no-catalog and budget events without a
   speculative Budget behavior patch.
6. Re-read the checklist and references. Run diff checks, affected analysis,
   targeted suites, broader dashboard regressions, and protected Header tests.
   Create evidence-backed coherent commits only after the corresponding gates
   pass.
7. Once every agent-authority pre-build row is DONE, push the exact clean HEAD,
   run the repository-prescribed GitHub human diagnostic APK workflow once,
   download it to `/storage/emulated/0/Download/fluvi`, and verify SHA-256.

The implementation is sequential because the Mind preview and both rails share
the current prepared-index/presentation ownership. Parallel edits would overlap
the same state and publication paths and increase integration risk.

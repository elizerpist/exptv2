# Direct Query-Chip and Pointer Priority Acceptance Checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DCP-01 | User §10 | `dashboard_core_controller.dart` | Every direct structural chip publication arms a generation-scoped committed-readiness barrier before query/rail/summary speculation. | Focused controller ordering test | DONE |
| DCP-02 | User §§1,10 | `dashboard_core_controller.dart` | Sheet Apply preserves route completion → committed readiness → speculation ordering. | Existing route lifecycle regression test | DONE |
| DCP-03 | User §§5,11 | `dashboard_logbox_viewport.dart`, `dashboard_core_controller.dart` | Raw LogBox pointer intent preempts lower-priority speculation before formal vertical drag begins and releases on tap/cancel. | Widget/controller lifecycle test | DONE |
| DCP-04 | User §§6,12 | `explicit_committed_paging_controller.dart` | An in-flight exact page read is retained, while presentation/commit is deferred during raw pointer intent and resumes once safe without reread. | Paging unit test | DONE |
| DCP-05 | User §§3,4,9 | Existing Core/paging owners | Background readiness cannot overlap a running query-chip prewarm, and speculative work resumes only after current committed readiness settles. | Controller ordering and gate tests | DONE |
| DCP-06 | User §§12,14,20 | Existing generation/geometry owners | Structural supersede remains fail-closed; controller, position, physics, virtual geometry, and cache limits remain unchanged. | Existing paging/geometry/boundary suites | DONE |
| DCP-07 | User §16 | Core/paging diagnostics | Low-volume ordering/defer diagnostics distinguish direct-publication readiness and pointer-intent page deferral. | Focused test and source inspection | DONE |
| DCP-08 | AGENTS.md delivery | GitHub Actions / human APK | Pushed production commit has a successful online normal human APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256. | GitHub Actions + checksum | DONE |
| DCP-09 | User §17 | Physical Android | Human verifies direct chip removal then immediate vertical flick; no foreground competing work or input latency regression. | Physical device trace | PARTIAL — human verification pending |

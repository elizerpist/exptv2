# R06 exact-source graph and native inventory

This tooling record indexes application source `93161f4ea304a3fb18a7a4dc2336bdab678de4b1`, whose parent is `57d091bc23fe1fb12db579014497ff8d706a0552`. The tooling branch is `tooling/orb-retirement-93161f4e`, based on existing tooling commit `4d1ddfa84f5f5d4f8f37cf64068c40a89e5c324c`.

**Runtime validation was pending when this record was generated.** Exact-source diagnostic [run43347794272](https://github.com/elizerpist/exptv2/actions/runs/43347794272) was running. This graph does not establish an instrumentation PASS, service recovery, Human APK delivery, or physical acceptance.

## Provenance and verification

A separate detached checkout at the exact application SHA was created at `/workspace/r06-source-93161f4e`. Frozen Flutter dependency resolution left tracked source unchanged. A fresh `scip_dart 1.6.2` invocation generated `index.scip`; no previous index was relabeled. The raw index is not committed.

| Evidence | Result |
| --- | --- |
| Source tracked cleanliness before/after indexing | PASS |
| Index bytes | 67,531,867 |
| Index SHA256 | `f0275be7fafea1be6ee35fdeaf684d368096bfe4151937ee3a81b71ebedcb23e` |
| Manifest SHA256 | `009500c472e0ea1061ef571254d5049c84d05c57e86770ed6a83ccf8ea069b89` |
| Dart documents | 807 |
| Repository symbols / references / edges | 20,252 / 136,383 / 42,214 |
| Shard hashes and record counts | All 102 PASS |
| Tooling tests | 16 PASS |
| Tooling analysis | PASS, no issues |
| Queried definitions checked against exact source | All 5 PASS |

The initial sandboxed analysis failed because its home cache directory was read-only; an approved run outside that sandbox passed without tooling changes. Package locks were preserved. No APK was built by this tooling lane.

Executed generation commands, after sourcing `/workspace/.toolchains/android-env.sh`:

```bash
# In the clean detached application checkout:
flutter pub get --enforce-lockfile
git diff --exit-code
git diff --cached --exit-code
dart pub global run scip_dart ./
sha256sum index.scip

# In /workspace/r06-tooling/tools/codegraph:
dart run bin/fluvi_codegraph.dart generate \
  --index /workspace/r06-source-93161f4e/index.scip \
  --graph ../../docs/codegraph \
  --source-root /workspace/r06-source-93161f4e \
  --source-head 93161f4ea304a3fb18a7a4dc2336bdab678de4b1 \
  --source-ref 93161f4ea304a3fb18a7a4dc2336bdab678de4b1 \
  --expected-index-sha256 f0275be7fafea1be6ee35fdeaf684d368096bfe4151937ee3a81b71ebedcb23e
```

The generator verified the exact source root against SCIP metadata, HEAD/ref, tracked cleanliness and raw index hash. `manifest.json` and `changed-impact.json` now identify this application source. Dart shard contents are unchanged from the prior graph because this candidate changes Kotlin and the journal. Zero indexed changed symbols does **not** mean zero native impact.

[The query transcript](codegraph-orb-retirement-queries-2026-11-13.txt) covers `KeyguardTimingCaptureBridge`, `KeyguardTimingCaptureSnapshot`, `DebugConsoleDialog`, `FluviDiagnosticBridge` and `DashboardKeyguardMaterialBridge`. The existing CLI prints SCIP **zero-based** line/column coordinates. The JSON report also records verified one-based source definition lines for editor/GitHub navigation. These queries are Dart navigation evidence only.

## Native ownership inventory

[The machine-readable report](codegraph-orb-retirement-2026-11-13.json) records exact source file hashes, Git blobs, definitions, source-observed references and GitHub links for the renderer, controller, window and regression tests. **Kotlin SCIP coverage is false.** This is a focused source inventory, not an indexed native call graph or exhaustive transitive certification.

| Risk | Source ownership and verification boundary |
| --- | --- |
| R1 | Worker accepts an exact steady publication; Main immediately revokes and hides its captured child; the existing Worker queue applies a final buffer-null transaction to that child. The regression holds the accepted use across Main hide/reattach and requires its real receipt, fence completion and exact lease drain. |
| R2 | Main reuses an active identical lease/child grant. Every displaced grant deactivates. Real same-size layout callbacks must retain the accepted grant identity and output. |
| R3 | Worker retirement/disposal remains asynchronous and lease-scoped. Main exclusively owns visibility, parenting and child removal. Old cleanup cannot resolve through replacement B. Dispose regression requires Main to return while the accepted use remains held. |
| R4 | Worker exclusively owns all three slots, including retired uses. Actual release callbacks and required fences control reuse/destruction; clear/commit/timeout never does. First/on-draw behavior and existing early receipt replay remain. |
| R5 | Construction-captured no-op hooks expose immutable Worker observations. Production logging is bounded to 64 records/60s with suppression reporting; 200ms starvation observation adds no recovery authority or watchdog. |

The controller remains the immutable lease/spec owner. Its existing Main guards select the isolated route and current-lease failure fallback; CARD/OFF/API<34 routing and shader preparation are unchanged. `KeyguardCardWindow.hide` applies root invisibility before controller retirement and root removal. The new tests use the same renderer over three replacement cycles, exact request/lease/slot/use identities, real compositor crops and the existing calibrated producer path; they do not fabricate release callbacks.

The selected H1 ordering defect is distinct from its occurrence in the historical stalled capture, which remains unproven. H2 early steady receipts and H3 pending fences or deferred first-publication ordering remain diagnostic alternatives. Graph generation cannot resolve them.

**PHYSICAL VALIDATION — PENDING, USER ONLY.**

# Fluvi SCIP code graph

This package converts a local, generated SCIP index into small, deterministic
repository-intelligence artifacts for source review. It is intentionally a
navigation and one-hop impact-analysis aid, not a runtime analysis system.

## Architecture card

`ScipGraphExtractor` is the only owner of SCIP-to-graph interpretation.
`GraphArtifactWriter` is the only owner of canonical JSON materialization and
optional measured sharding. `SourceProvenanceVerifier` is the only owner of
Git/index provenance checks. `GraphArtifactReader` is the only owner of local
query loading. No Flutter application package imports this tooling package.

The extractor uses SCIP `Document`, `SymbolInformation`, `Occurrence`, and
`SymbolRole` protobuf fields. It does not infer definitions or references from
text search. A normal SCIP reference is never described as a runtime call,
data-flow, state-flow, or causal edge.

Useful global repository symbols are retained. Local symbols plus SCIP
file/namespace/parameter/type-parameter records are intentionally omitted:
they make a reviewer-facing graph noisy while not forming a stable public
source neighborhood. The manifest retains the full SCIP defined-symbol count
for auditability.

## Generate

Run the tooling package from its own directory; it has no dependency on the
Flutter application package:

```sh
cd tools/codegraph
dart pub get
dart run bin/fluvi_codegraph.dart generate \
  --index ../../index.scip \
  --graph ../../docs/codegraph \
  --source-head "$(git -C ../.. rev-parse HEAD)" \
  --source-ref "$(git -C ../.. branch --show-current)"
```

The command consumes a SCIP index rather than treating source text as graph
input. It obtains the indexed source root from `metadata.project_root` unless
`--source-root` is supplied, verifies the exact Git head and source ref, and
rejects tracked source changes. `--expected-index-sha256` is available for an
external build/index provenance gate. It neither commits nor pushes anything.

For a future clean current-checkout generation, use the wrapper from the
repository root:

```sh
sh tools/codegraph/generate.sh
```

It checks tracked Git cleanliness, records the exact checked-out head/ref,
runs `dart pub get`, rejects tracked dependency changes, invokes the upstream
`dart pub global run scip_dart ./`, hashes `index.scip`, and then calls the
same provenance-checked extractor. It never commits, pushes, or builds an APK.

The direct command above is retained for a verified historical index that was
created in a different, exact source worktree; in that case the supplied
`--source-root` must match SCIP's `metadata.project_root` exactly.

`/index.scip` is intentionally ignored and must never be committed. The
compact, deterministic `docs/codegraph/` artifacts are the review inputs.

## Query

```sh
cd tools/codegraph
dart run bin/fluvi_codegraph.dart query \
  --graph ../../docs/codegraph \
  --symbol DashboardLiveInteractionResourceLane
```

The query accepts a unique human-readable name or an exact raw SCIP symbol.
It prints the definition, supported class/constructor family members,
reference counts, consumer files, and production/test reference locations.

## Artifact layout

`manifest.json` pins the source commit, parent, ref, index hash, SCIP version,
and counts. `symbols`, `refs`, and `edges` remain monolithic only while the
measured JSON fits under 2 MiB. Larger payloads are sorted JSONL shards with a
small `*.index.json` containing stable first/last target keys and shard hashes.
That lets local queries load only the reference shards that can contain a
known target. `changed-impact.json` is a conservative source-parent-to-source
head, one-hop file-consumer summary; its candidate symbol list is intentionally
file-level, not a claim that every symbol body changed.

## Acceptance checklist

| ID | Source requirement | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CG-01 | User prompt §§1–3 | provenance | Bootstrap graph names exact 7cfc source and known index hash | provenance test + manifest inspection | verification gate |
| CG-02 | §§4–6 | extractor/writer | Only tooling/docs artifacts change; raw `index.scip` stays ignored/uncommitted | diff/name check | verification gate |
| CG-03 | §§5, 8–11 | extractor | Local SCIP definitions, references, and evidence-labeled edges come from protobuf records | synthetic protobuf tests | verification gate |
| CG-04 | §9 | symbol family | Class queries include protocol-derived constructor members without fragile text reference scraping | QueryAmountRangeControl/DashboardCoreController tests | verification gate |
| CG-05 | §§7, 12, 18 | writer | Manifest and graph artifacts are deterministic; changed impact is conservative and one-hop | double-generation hashes + tests | verification gate |
| CG-06 | §§13–14, 21 | CLI/reader | Local query answers definitions, family, production/test references from committed artifacts | query test + five source checks | verification gate |
| CG-07 | §§16–20, 22–23 | workflow | Exact 7cfc graph is committed and only tooling branch is pushed; no APK/application change | Git/remote validation | verification gate |

## Deliberate limits

SCIP provides an index/reference graph. It does not prove runtime state flow,
gesture sequencing, Flutter rebuild causality, or regression causality. Source,
logs, tests, and physical validation remain authoritative for those questions.

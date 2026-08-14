# Virtual Vertical Geometry Redesign — Acceptance Checklist

Source: user request of 2026-08-14, current `origin/query` baseline
`324f212e78e0a376415e8e65476d4f481986838a`.

| ID | Requirement / source | Intended ownership / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VVG-01 | Full exact geometry is independent from loaded pages | `PreparedDashboardIndex`, `CommittedVerticalGeometryManifest` | A committed scope has immutable exact page tops and total extent before vertical activation | manifest unit tests + cache tests | DONE |
| VVG-02 | No page commit changes Flutter geometry | `CommittedLogViewportCache`, render surface | Page commit changes resource generation only; `contentHeight`, geometry generation and surface height stay unchanged | cache + widget ballistic probe | DONE |
| VVG-03 | Use existing native daily aggregates, no new SQL shape | Kotlin prepared-index read + binary codec | Daily count seed is derived from the existing aggregate query; SQL call count remains five | Kotlin/native + boundary tests | DONE |
| VVG-04 | Exact page geometry, not estimation | manifest compiler | Handles day spans, exact boundaries, partial final page, empty scopes and all temporal scopes | focused manifest tests | DONE |
| VVG-05 | Directional Query partition reuse | prepared-index partitions | Income/Expense own independent immutable seeds; reuse retains unchanged seed | Dart partition/query tests | DONE |
| VVG-06 | Atomic Query publication | core/presentation/paging handoff | Query/frame/geometry manifest publish as one exact identity; cancel leaves active manifest untouched | query lifecycle tests | DONE |
| VVG-07 | Bounded resources | cache + paging demand | Five movable pages, root pinned and 2 MiB limit remain; virtual metadata may cover all pages | cache retention tests | DONE |
| VVG-08 | Visible-only paint | `DashboardLogBoxRenderSurface` painter | Painter maps offsets through manifest and touches only intersecting retained prepared pages; no row widgets or paint-time text layout | painter/widget tests + source review | DONE |
| VVG-09 | Fail closed on mismatch/miss | cache/painter diagnostics | Payload geometry mismatch and visible virtual-page miss do not mutate geometry or paint stale/partial content | transition tests + diagnostics assertions | DONE |
| VVG-10 | Keep live same-axis paging and reverse signed gate | viewport + paging controller | Forward demand remains live; forward updates never request prior keyset page; real structural changes still supersede | existing paging/viewport tests | DONE |
| VVG-11 | Resumable text preparation | committed cache/paging preparation owner | Private page preparation slices resume, publish atomically, dispose on structural supersession, and never create `TextPainter` in paint | deterministic work-probe tests | DONE |
| VVG-12 | Priority isolation | core background work policy | Active committed vertical resource work outranks unrelated rail/query speculation without deleting rail-critical guarantees | controller/unit tests + source review | DONE |
| VVG-13 | Preserve scroll identities and physics | viewport/render path | No `ScrollController`, `ScrollPosition` or physics replacement/tuning | widget identity tests + source review | DONE |
| VVG-14 | Binary contract is versioned and fail closed | Kotlin encoder + Dart decoder | Seed transport round trips order/counts/empty/large scopes; missing/invalid seed is rejected rather than converted to dynamic geometry | codec tests | DONE |
| VVG-15 | Flutter contract is recorded | forensic report | Installed Flutter `ff37bef603` call path and resulting design rationale are documented | report review | DONE |
| VVG-16 | No zero-velocity/physics workaround | scope discipline | No physics or synthetic-velocity change; remaining zero-velocity issue is explicitly reported | diff review + report | DONE |
| VVG-17 | Diagnostics remain aggregate | diagnostics | Virtual geometry activation/mismatch/miss and summary generations are present without per-row/frame logging | tests + source review | DONE |
| VVG-18 | Verification and delivery | CI + GitHub Actions | focused, fast, analyze, relevant native tests; normal online human APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256 | fresh command output + artifact hash | DONE — 155f18b6 human APK SHA-256 `10ff1e7481894fab2f33ec9d9c99b0617f4367ebe7923418e0e840c558903d24` |
| VVG-19 | Physical truth remains human-owned | final report | Do not claim smoothness from tests; zero-velocity status and physical APK status are explicit | final report + forensic report | DONE — explicitly not physically verified |

## Architecture Card

```text
native existing daily aggregates
        │ compact ordered daily counts (per directional partition)
        ▼
PreparedDashboardIndex ── exact scope ──► immutable geometry manifest
                                                  │
committed frame + manifest atomic handoff ───────┤
                                                  ▼
CommittedLogViewportCache
  full geometry (immutable) + bounded page/text resources (mutable)
                                                  │
                                                  ▼
stable RenderBox/SizedBox extent ──► viewport offset ──► visible page resources
```

The cache remains the one committed vertical resource owner. The paging
controller remains the one serial keyset owner. The viewport remains the one
scroll-demand observer. The painter only consumes already complete resources.

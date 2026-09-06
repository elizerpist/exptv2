# Time LogBox visual continuity / Avatar frame-cadence — acceptance checklist

Source of truth: the user's 2026-09-06 physical-feedback prompt, its copied
forensic specification, the two screenshots named in the design document,
and CURRENT HEAD source evidence.  `DONE` requires the listed verification;
an APK or green compilation alone is not completion.

| ID | Source instruction / evidence | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| PREFLIGHT-01 | User §§1–7 | Git/Drive/SCIP lineage | Exact `a8ad6e5` base and parent, clean dedicated worktree, full global log dedupe, current matching graph | Recorded commands, parser output, manifest/hash inspection | DONE |
| EVIDENCE-01 | User §§4–6 | Commit/docs/log audit | a8ad body, fcc→a8ad diff, milestones, prior docs and current Drive tails are reviewed without treating duplicate tails as separate trials | Audit journal with source/log links and limitations | DONE |
| TIME-TRACE-01 | User §§6, 10–11, 18–19 | Summary/Core target lifecycle diagnostics | Every accepted Time target has one terminal visual classification; existing 0/1 summary flag is not misreported as a count | Production-parent one-frame and multi-target tests; bounded lifecycle records | DONE — automated; physical validation remains separate |
| TIME-PAINT-01 | User §§10–11, §30.3–7 | presentation binding, render surface, target acknowledgement | A current Time target that survives a render opportunity paints exact readable rows or exact empty before settle; coalesced/stale targets are explicit | Deterministic production-parent paint/ack tests and exact identity assertions | DONE — automated; physical validation remains separate |
| EMPTY-01 | User §§2, 8.3, 12, 19.3–4 | `DashboardLogBoxRenderSurface` empty path | Zero rows keep correct header and stable host but paint no bar, dot, shell, skeleton, loading copy or fake row semantics | Painter command/pixel regression, viewport/controller identity test | DONE — automated pixel/semantics coverage |
| PHASE-A-01 | User §§8.4, 11, 19.5–6 | prepared scene cache + Phase-A painter | Nonempty target paints readable prebuilt Phase-A resources without rich scene, TextPainter construction, query/index/DB work, or invariant marker as normal UI | Production-parent rich-miss test plus cache/resource assertions | DONE — existing and extended production-parent coverage |
| HOTSET-01 | User §§11, 15, 22, 25 | `DashboardLogViewportState` + prepared-scene cache | Sparse/deferred payload construction must not eagerly materialize every readable-row geometry bank; only the bounded selected resource owner arms it | Deferred-payload unit regression plus focused Time/LogBox suite | DONE — lazy immutable Phase-A geometry is armed by the bounded resource owner |
| DOMAIN-01 | User §§6.3–4, 13–14, 19.7–10 | render-domain selector, binding, extent snapshot | One domain/identity/geometry/extent authority per frame; preview→committed causes no blank, padding jump, stale extent or oscillation | Domain/extent matrix and stale-ack regressions | DONE — automated; actual device handoff still pending |
| EXTENT-01 | User §13, §19.9 | terminal extent + viewport consumer | Empty/content-fitting targets have zero terminal tail/max scroll extent; tail never shifts card origin or crosses a domain | Direct extent tests and production viewport matrix | DONE — direct and production viewport coverage |
| STALE-01 | User §§6.4, 11.8, 14 | strict identity acknowledgement | A rejected old paint cannot clear/revert the newest valid visual or publish its extent | Delayed stale acknowledgement test | DONE — strict identity tests retained and expanded |
| AVATAR-MEASURE-01 | User §§6.5, 15, 19.11 | Avatar rail, performance diagnostics | FrameTiming and staged latency/rebuild/layout/repaint aggregation distinguish continuous carousel motion from discrete financial target changes | Bounded flight instrumentation and production-parent test | PARTIAL — bounded FrameTiming/latency/build instrumentation is present; next physical diagnostic flight must supply device samples |
| AVATAR-PERF-01 | User §§15, 22 | Avatar presentation boundary | No physics change unless a specific frame/pipeline defect is reproduced; retain exact paint accounting and zero tick DB/index/scene/canonical work | Before/after counters and source/diff review | DONE — no physics change; existing zero-heavy-work contract retained |
| SLIDER-01 | User §§2, 6.6, 16, 19.12 | Existing Mind/Count path | Live rows/count, exact total, canonical reconciliation and stable LogBox identities remain green; no drag-tick heavy work | Existing a8ad production regression rerun | DONE — production regression rerun; fresh trace remains missing |
| LAYERS-01 | User §17 | CoreDashboard/LogBox boundaries | One LogBox surface/controller; stable Stack order, clipping, hit test and semantics; no empty overlay | Existing/new production-parent bounds/semantics checks and source review | PARTIAL — no Stack ownership change; focused stable-owner coverage remains green, while the known baseline test harness failure is retained |
| PERF-01 | User §§11, 24–25 | Time render path | Per Time tick: query/index/scene/DB/TextPainter/controller/render-surface work remains zero; readable Phase-A target is prompt | Flight counters plus focused performance-structure tests | PARTIAL — structural counters and tests are green; physical latency distribution is pending the new APK |
| SCOPE-01 | User §22 | All changed symbols | No slider/query/finance/physics/paging/controller/Phase-A/B/epoch semantic regression or speculative cleanup | Diff and graph impact review with protected tests | DONE — matching a8ad graph was used for discovery and every modified/shared consumer was source-verified; final graph regeneration remains a separate delivery gate |
| DELIVERY-01 | User §§27–28 and global AGENTS | app branch + GitHub Actions + tooling branch | App commit/push, matching normal human APK download/hash, and separately regenerated SCIP graph at final SHA | Action artifact, SHA-256, manifest/tooling validation | NOT DONE |
| PHYSICAL-01 | User §§1, 28–30 | User device | New APK physical visual acceptance | User-only device test | PENDING — USER ONLY |

## Required pre-commit reread

Before every application commit, reread this checklist and the two screenshots.
No checklist item may be relabelled `DONE` from a compile, an APK, or a test
that only observes publication rather than real paint.

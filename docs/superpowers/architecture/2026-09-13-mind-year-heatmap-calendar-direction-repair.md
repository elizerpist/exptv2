# Mind Year direction-regression repair architecture card

## Evidence and decision boundary

This reopens the earlier direction-completion claim. The authoritative physical
artifact is `Fluvi logs other` (Drive ID
`1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`), frozen from the live
connector at `2026-09-14T06:26:41.451Z`: session
`fluvi-1789367123468683`, build `profile/2fc02e143197`, retained sequence
`6151–7150`, and supplied raw-export SHA-256
`07e64e2eeb84c65c25e27deeea64026a314981978a022c47d0fb3edf996f3c96`.

It proves that the generic direction chrome is prompt and that an Income
direction request can first be rejected as `preparedBaseUnavailable`. It does
not yet prove the first owner of the actual painted LogBox rows. The current
SCIP review graph is provenance-checked for application source
`101ac1a4c60f2790cbeee7a8ae5e9fe31abcd28b` (index SHA-256
`944aeb5c12d445a72554264f6b67ddd73fb0c96ea0cc3674e574b935d8dd75dd`).
SCIP is navigation evidence only; source, RED tests, and physical evidence
remain causal authority.

## Structuring Apps ownership map

The governing skill is
`/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
(local skill; no version metadata). Its applicable rules are: one authoritative
state/write path per shared mechanism; UI only renders and forwards intent;
multi-step workflows belong in controller/coordinator/use-case layers; shared
mechanisms must be extended rather than copied; every cross-file change has an
architecture card, acceptance checklist, and fail-closed boundary test.

| Concern | Sole owner / boundary | Repair rule |
| --- | --- | --- |
| Applied directional Query and amount domains | `CurrentQueryController` | Keeps the two canonical directional scopes and domains; no Mind-local query or duplicate direction controller. |
| Direction intent and cross-surface orchestration | `DashboardCoreController.selectDirection` and its existing presentation/navigation collaborators | Core may coordinate bounded resident data, but must not make a heatmap or a renderer the query owner. |
| Prepared immutable index and candidate construction | `DashboardDataRuntime` / `PreparedDashboardIndex` / existing `prepareQueryDraft` cache lane | Reuse this lane; no repository work or unbounded second index cache on a tap. |
| Mind base residency and annual projection | `DashboardCoreController` plus existing `MindYearHeatmapProjection` | Core retains at most one non-amount immutable base per direction (two total), revision/scope checked. Candidate index readiness is published before optional Phase-B scene staging; Query remains the sole domain owner. |
| Complete visible snapshot ordering | `DashboardVisibleFrameStore` | Navigation, amount, count and LogBox payload must represent one exact visible identity; no renderer-side repair. |
| Actual LogBox row paint | `DashboardLogBoxRenderSurface` / `_DashboardLogBoxSurfacePainter` | Renderer only reports actual painted identity; it never chooses direction, mutates query, remounts, or flushes cache. |
| Diagnostics | `FluviDiagnosticLogger` and `DebugConsoleDialog` | One bounded ring/panel. Diagnostics use digests and aggregates, never transaction text, names, categories, or amounts. |

## Explicit visible-generation contract

For an accepted direction generation, visible chrome, heatmap identity, and
actual painted LogBox rows must either all retain the prior complete generation
or all carry the same target canonical query/direction/revision identity. A
target chrome with a blank heatmap caused only by a missing prepared base, or
with source rows from the old direction, is rejected. A LogBox presentation
metadata promotion may retain its exact payload only when the payload has the
same query/revision/direction identity.

## No-touch / invariant matrix

| Protected owner | Invariant | Verification |
| --- | --- | --- |
| Avatar controller, `ScrollPosition`, physics | identity and motion behavior unchanged | focused Avatar lifecycle/physics tests and diff audit |
| Time controller, `ScrollPosition`, physics | identity and rail navigation unchanged | focused Time navigation tests and diff audit |
| Summary navigation | existing semantic navigation/pill ownership unchanged | existing summary/visible-frame tests |
| Query Menu / canonical query | one `CurrentQueryController` authority; category/partner/search semantics preserved | query application and menu tests |
| LogBox paging/scroll | no remount/re-key/cache flush; scroll reset only existing scope contract | viewport/paging tests and source inspection |
| Mind slider | no repository/index build/source scan per tick | slider hot-path counters and focused tests |
| Calendar geometry/footer | Monday–Sunday, 12 cards/3×4, fixed footer unchanged | existing geometry/mode-host tests |
| Debug ring | bounded retention/copy/capture unchanged | logger/debug-widget tests |

Forbidden mechanisms: force remount or `Key` replacement, automatic mode
leave/re-enter, cache flush on a direction switch, arbitrary retry/delay, a
second query controller, and a renderer-owned direction state.

## 2026-09-14 repair decision

`PreparedQueryCandidatePreparation.indexFuture` now exposes only the exact,
validated immutable index. It does not publish the candidate, mutate canonical
Query, or grant a scene cache lease. `DashboardCoreController` consumes that
one shared readiness boundary to retain a maximum of two direction-specific
Mind bases; optional LogBox scene preparation and active slider-readable
resources remain separate consumers. If the target is genuinely unavailable,
Core retains the old complete direction until the target base arrives instead
of publishing mixed chrome/heatmap generations. The LogBox painter remains
diagnostic-only: it reports actual hashed painted row identities and has no
filter, cache, remount, or query mutation path.

The one native prepared-index builder is an explicit scheduling boundary: the
active Mind base must settle before Core admits the bounded sibling prewarm.
Its supersession generation is keyed by `LedgerDirection`, never by every
transient scope. An exact hotset promotion also receives `indexFuture`, not
the Phase-B candidate-completion future. The LogBox composition captures the
read-only Core provenance during build and emits the row digest directly from
the matching paint, so a later controller read cannot attach a new direction
to older pixels. These are ownership safeguards, not retries, remounts, cache
flushes, or a second query authority.

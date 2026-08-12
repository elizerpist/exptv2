# Rail Scene Readiness Checklist

## Architecture card

### Scope and sources

- User requirements: eliminate scene starvation and blank non-empty LogBox
  scopes without weakening fail-closed rendering; stage interaction-ready Query
  candidates; keep Summary parent switches O(1); retain 1,000 diagnostics.
- Existing owners: `DashboardLogBoxPreparedSceneCache`,
  `DashboardCoreController`, `PreparedQueryCandidate`,
  `DashboardPreparedRevisionBundle`, and the committed vertical viewport.
- Behavioral comparison: `e64e84aededa61f7f41124100309e819eceb269e` only.

### Single source and write path

| State | Owner | Rule |
| --- | --- | --- |
| Active and retained scene banks/layouts | `DashboardLogBoxPreparedSceneCache` | Only atomic activation makes a bank renderable |
| Scene demand and supersession | `DashboardCoreController` | Input may preempt work but only a different immutable target discards it |
| Query staging | `PreparedQueryCandidate` through core | Candidate stays invisible until Apply activation |
| Vertical render promotion | committed viewport/render surface | Non-empty root requires an exact scene or prepared root fallback |

### Reuse and centralization

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| Cooperative scene preparation | `DashboardLogBoxPreparedSceneCache` | Replace fixed row/frame waits with its one time-budget scheduler |
| Candidate/parent hotsets | retained scene-bank support in same cache | Extend typed retained-bank keys; no second cache |
| Layout reuse and lifetime | prepared scene cache | Add exact width/DPR/content keyed immutable pool if evidence needs it |
| Diagnostics ring buffer | `FluviDiagnosticLogger` | Keep existing ring; change capacity only |

## Acceptance checklist

| ID | Source requirement | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RS-01 | Time-budget preparation | Scene cache/Core dashboard | Small UI slices do not each wait an entire frame | Deterministic scheduler test + profile diagnostics | DONE |
| RS-02 | Query interaction-ready Apply | Candidate/Core/cache | Apply activates current rail sibling domain without a post-dismiss correctness warmup | Candidate/apply and first-fling regression tests | DONE |
| RS-03 | Same target pause/resume | Core/cache | Temporary input preserves progress; only immutable target supersession discards it | Controlled cancellation/resume test | DONE |
| RS-04 | O(1) Summary parent publication | Core/bundle/cache | Parent switch commits from structural scene and uses bounded adjacent hotset | Parent hotset/prepared-hit tests | DONE |
| RS-05 | Blank root prevention | Committed viewport/render surface | Non-empty vertical root never publishes positive geometry without paint source | Root fallback and promotion regression tests | DONE |
| RS-06 | Preserve directional Query/paging/physics | Core/navigation/paging | Independent directions, paging and rail physics untouched | Existing focused suites and boundary tests | DONE |
| RS-07 | Diagnostics capacity | Logger | Ring retains 1,000 ordered entries without list shifting | Ring-buffer regression test | DONE |
| RS-08 | Delivery | CI/release/download | Online build verified and human APK downloaded/hash checked after production-code commit | GitHub Actions and SHA-256 | NOT DONE |

## Local verification record

- `./scripts/test-fluvi-fast.sh`: 175 tests passed.
- `flutter analyze`: no issues.
- `./scripts/verify-fluvi-boundaries.sh`: passed.
- Authoritative core seed tests already state that 2026 expense count `658`
  is intentional (`7 × 94`); no seed or SQL behavior was changed here.

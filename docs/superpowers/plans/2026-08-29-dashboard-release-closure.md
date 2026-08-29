# Dashboard release-closure implementation plan

**Goal:** close the five physical Dashboard release gates without weakening the
accepted foreground-input, retained-Header, or LogBox ownership boundaries.

**Architecture:** one latest-wins Budget semantic commit will own the selected
target, category Query facet, palette identity, Header/progress/distribution
projection, and LogBox-visible scene identity. Avatar pixels remain rail-only;
expensive scene realization is deferred, bounded, preemptible work. The two
Query hosts render one extracted RangeSlider component, and the Header samples
the approved `category_palette_variation_lab.html` COMPRESSED V1 scale using
`remaining = 1 - spent / limit` as its window position.

## Acceptance checklist

| ID | Requirement source | Code boundary | Acceptance / evidence | Status |
| --- | --- | --- | --- | --- |
| G1 | r51 Avatar sequence; release prompt | Avatar rail → drilldown/core | crossing keeps semantic preview but does not synchronously schedule scene work; time-vs-avatar counters and ballistic regression pass | DONE |
| G2 | r51 `targetHandle=8` + empty Query categories; screenshots A/B/C | live interaction, Budget presentation, Query/LogBox visible commit | specific category target, Header/progress/distribution/palette and visible Query share one current semantic identity; late generations drop | DONE |
| G3 | release prompt; current source | Query menu and Mind hosts | both instantiate one exported two-ended RangeSlider with canonical min/max Query state; no threshold fork remains | DONE |
| G4 | screenshot C; actual composition | Card2 cascade, shell, pager and rhythm surface | realistic-density raster locates and removes the slab owner while retaining 44dp rhythm plot and Partner behavior | DONE |
| G5 | approved COMPRESSED V1 card; 2026-08-22 spec | category catalog → Header retained frame | Cool/category setting; selected category uses V1 compressed scale, window size remains user-owned, remaining-percent drives window center, stale palette rejects | DONE |

## Execution order

1. Add five production-owner red tests and run each against `f4a3fe2d`.
2. Unify the semantic Budget commit and move Avatar preview scene realization
   below direct input; prove G1/G2 with deterministic races and counters.
3. Extract `QueryAmountRangeControl`, adopt it in both hosts, and delete the
   lower-only Mind control; prove G3.
4. Reproduce Card2 at Android geometry with owner-colour raster probes, repair
   the actual layer, then prove G4 and preserve 40→44dp allocation.
5. Add the V1 compressed category-scale source and bind it through the same
   committed target identity into the retained Header material; prove G5.
6. Update the 2026-08-29 checklist only with measured evidence; run focused
   suites, analyzer and diff check. **Completed:** 176 focused application and
   gate tests passed; `flutter analyze` reported no issues; `git diff --check`
   is clean. The one normal human APK build may now be triggered for the
   pushed exact SHA, then D1 is recorded only after download, SHA-256 and
   physical changed-state evidence.

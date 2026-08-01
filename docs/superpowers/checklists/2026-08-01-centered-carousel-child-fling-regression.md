# Centered Carousel Child Fling Regression Acceptance Checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| CCF-01 | User §1–4 | shared carousel | Child rails use the existing `CenteredCarousel`/`CenterSnapScrollPhysics`; no PageView or manual ±1 replacement | direct source audit + boundary test | DONE |
| CCF-02 | User §5–7 | `centered_carousel.dart` | The child `ListView` receives raw drag/release velocity and the custom physics is the outer applied physics | widget/source test | DONE |
| CCF-03 | User §12–13 | `centered_carousel.dart` lifecycle | Preview-triggered parent rebuild does not schedule `jumpToIndex` or interrupt an active ballistic simulation | failing-then-passing widget regression test | DONE |
| CCF-04 | User §8–11, §20 | shared physics/spec | Existing friction projection, velocity bands, max step, attenuated spring, tolerance, and haptics remain unchanged | physics snapshot + existing physics tests | DONE |
| CCF-05 | User §18 | time rail adapters | Generated years and cyclic months/days all use the same shared engine and preserve logical mapping | adapter/source tests + widget tests | DONE |
| CCF-06 | User §16–19 | SummaryPill/rail boundary | Parent swipe remains one-step and does not capture the child rail fling | gesture isolation test | DONE |
| CCF-07 | User §19, §21 | controller lifecycle | Tap retarget, haptics, infinite/rebase, preview/settled semantics do not regress | focused regression suite | DONE |
| CCF-08 | User delivery instruction | CI/download workflow | Commit, push, successful online APK build, direct APK download, and verified local file | GitHub run `30711351150` + local file/hash evidence | DONE |
| CCF-09 | User delivery correction | `.github/workflows/fluvi-core.yml` | Future builds publish a direct Release asset link and do not use `actions/upload-artifact` | workflow audit + successful run summary | DONE |

## Root-cause record

- `CenterSnapScrollPhysics` and the shared multi-item physics were still present and unchanged.
- After commit `646b7f0`, preview callbacks rebuilt the dashboard. `CenteredCarousel.didUpdateWidget` unconditionally scheduled a post-frame `jumpToIndex` on every rebuild.
- That jump interrupted the active ballistic/spring activity after the first crossed index, producing the apparent one-step child rail behavior.
- The fix only schedules initial recentering when the controller instance is replaced. Same-controller preview rebuilds now preserve the active `ScrollActivity`; genuine configuration changes remain handled by `updateConfiguration`.

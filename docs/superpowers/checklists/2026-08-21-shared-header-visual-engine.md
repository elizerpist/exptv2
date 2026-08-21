# Shared Header Visual Engine — acceptance checklist

This is the approved execution checklist for the Color Lab production binding.
The user supplied the architecture and asked implementation to begin without a
separate planning/approval step.  The source-of-truth references must be
re-read before each feature commit.

| ID | Source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HVE-01 | `docs/prototypes/color_lab.html`, `color_lab_portal_energy.js` | shared header visual controller/catalog | Exactly one dashboard-lifetime animation owner exposes every non-Portal `MindPortalEnergy` mode and its source controls. | Pure catalog/projection tests; controller identity test. | DONE |
| HVE-02 | User architecture contract | `DashboardCoreModeHeaderScaffold` paint lane | Physical shell, clipping, semantic content and action remain separate; phase ticks repaint only the visual lane. | Widget/owner tests and direct code inspection. | DONE |
| HVE-03 | User architecture contract | mode color policies | Balance and Mind retain their current static header tone; only Budget receives financial dynamic color semantics. | Policy tests across mode changes. | DONE |
| HVE-04 | `color_lab.html` BGD-05/BGD-08 | Budget policy projection | Positive Budget limit samples the exact white-to-canonical-target scale at the clamped moving-window edges for Header A/B. | Pure Color Lab projection tests at 0/25/50/100/>100. | DONE |
| HVE-05 | `color_lab.html` BGD-03/BGD-04 | Budget policy/controller settings | Width starts at the current source default (28%), is mutable in RAM, never changes scale distribution, and edge clamping matches the source. | Projection tests and tuner widget tests. | DONE |
| HVE-06 | User architecture contract | Budget policy + live presentation | No positive limit uses the target's complete existing canonical gradient; positive-limit data uses the exact optimistic `actual / effectiveLimit` path. | Live/pending/TimeRail tests. | DONE |
| HVE-07 | `color_lab.html` opacity scale | shared visual frame | Opacity samples source stops `[.16,.24,.32,.42,.52,.62,.72,.82,.91,1]` rather than guessed alpha logic. | Pure projection tests. | DONE |
| HVE-08 | `color_lab.html` pulse idle field | shared visual controller | Tuner pulse is a one-shot 1560ms linear envelope adding the source light contribution; it does not morph semantic Header content. | Fake-clock controller tests. | DONE |
| HVE-09 | User architecture contract | former fullscreen owner + dashboard tuner | The existing fullscreen button is replaced by one hamburger action; its bounded, scrollable tuner stays below the current Header in collapsed/partial/expanded geometry. | Widget geometry tests. | DONE |
| HVE-10 | User performance/diagnostic contract | controller/painter/diagnostics | No I/O/Room/repository/bridge/SVG/prewarm/prepared rebuild/category aggregation or semantic dashboard rebuild during frame/tuner ticks; semantic diagnostics are deduplicated and never frame-spam. | Owner tests and direct inspection. | DONE |
| HVE-11 | User build/delivery contract | repository/CI | Focused commits are pushed, required Actions succeed, and the normal `lib/main.dart` APK is downloaded with SHA-256. | GitHub Actions run 32486410643 succeeded; `fluvi_HUMAN_DIAGNOSTIC_6f51954.apk` downloaded and SHA-256 verified. | DONE |

## Explicit exclusions

`Portal Morph`, its semantic Balance/message replacement, portal navigation,
and portal transition/content-field systems are not product Header effects.
They must not be ported.  The reusable idle-field pulse envelope is retained
under HVE-08 because it is an independent Header paint effect.

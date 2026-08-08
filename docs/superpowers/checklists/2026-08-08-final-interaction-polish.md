# Final interaction polish — acceptance checklist

Base: `5f48c3151ffcb5bb82668b26aa3c4df19d84a528`

Visual diagnostic evidence inspected before implementation:
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260808-200550.png`.
It records the reported sibling-scope presentation failure and remains the
physical-device reference for INT-10.

| ID | Source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| INT-01 | §3–13 | `DashboardLogBoxViewport` | A different visible sibling scope resets a deep stable vertical position synchronously before the sibling payload can paint. | Widget frame-sequence regression | DONE |
| INT-02 | §5, 9–12 | visible-scope identity | Identity is `queryKey + coreRevision + viewportId`, excludes preview/committed mode and epoch, and cancels a live vertical activity through native `jumpTo`. | Preview/committed and ballistic regressions | DONE |
| INT-03 | §8, 15 | `DashboardVisibleFrameStore` | Presentation metadata listeners run before LogBox payload listeners while all lanes remain staged atomically. | Lane-order unit regression | DONE |
| INT-04 | §18–19 | viewport diagnostics | One `VERTICAL_VISIBLE_SCOPE_RESET` is logged only when a real top mutation occurs; a same-scope settle does not double reset. | Diagnostic/counter assertions | DONE |
| INT-05 | §20–24 | stable viewport behavior | May→April first preview, rapid May→January, Month/day and SUM/year sibling transitions are top-aligned without controller, position, state or render-surface replacement. | Widget regressions | DONE |
| INT-06 | §25–27 | frozen runtime | Paging, scene rebase and rail hot paths remain unchanged; no SQL, layout, preparation or async work is introduced on rail crossing. | Frozen diff + existing suites | DONE |
| INT-07 | §28–35 | `DashboardSummaryPill` | Down gesture maps to finer (`sum → year → month`); up maps to broader, with unchanged plane order and labels. | Gesture widget matrix | DONE |
| INT-08 | §41 | regression safety | No Text/rail/vertical cache miss, no extent mismatch and no golden test. | Focused/full non-golden suite | DONE |
| INT-09 | delivery | GitHub Actions | A normal-entrypoint HUMAN_DIAGNOSTIC profile APK is built, downloaded, hashed and ZIP-verified. | CI release + local integrity check | NOT DONE |
| INT-10 | §36–37 | physical validation | Device capture proves the April preview begins at top and Summary vertical cycles have the requested order. | User physical capture | BLOCKED |

## Verification evidence

- Focused widget/unit regression set: **28/28 PASS**.
- Full non-golden Flutter suite: **369/369 PASS** (`3m17s`).
- `flutter analyze`: **PASS**, no issues.
- Frozen-file audit against the base: **0 diff** for the MotionKernel,
  TimeRefinementRail, CenteredCarousel/controller, CenterSnapScrollPhysics,
  demand planner and paging controller paths.

## Architecture card

- **One scroll owner:** `DashboardLogBoxViewport` remains the only `ScrollController`/`ScrollPosition` owner. It observes the already-existing lightweight presentation lane.
- **One scope identity:** a local immutable visible-scope identity uses exact query, revision and viewport identity. Mode and presentation epoch are intentionally excluded, preserving the visual no-op preview→committed settle.
- **Pre-paint order:** `DashboardVisibleFrameStore` stages every lane first, then flushes presentation metadata before the LogBox payload listener. The viewport's immediate native top jump therefore precedes the payload render notification.
- **Gesture mapping only:** SummaryPill keeps the canonical controller plane order. Only vertical physical gesture mapping changes: down=finer, up=broader.
- **Frozen paths:** rail/physics, paging, prepared scenes, post-settle rebase, stable viewport identity and Summary child formatter are not modified.

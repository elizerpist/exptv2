# Centered Carousel B3M Tuning Acceptance Checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| B3M-01 | Balance HTML B3M year rail, lines 4684–4754 | `AppSelectorMetrics` | B3M height, width formula, gap, padding, border, radius, and typography are centralized and documented | direct HTML inspection + token tests | DONE |
| B3M-02 | User §1–3 | time rail/shared spec | Tile width is responsive B3M width; tile height is compact B3M height; slot remains tile width + existing gap; five complete tiles remain visible | widget geometry tests | DONE |
| B3M-03 | User §4–5 | direction toggle/time rail | Income/Expense and base year tile use the same compact height/radius tokens; inactive controls remain white | widget/token tests | DONE |
| B3M-04 | User §6–10 | shared carousel/time tile | Rail has no painted surface, selected time tile has no shadow, and scrollbar/overscroll indicators are disabled | widget/decoration tests + static audit | DONE |
| B3M-05 | User §11–15 | shared physics/spec | New item/s velocity bands and multiplier 0.66 are used without replacing friction/spring snapping | physics unit tests + direct inspection | DONE |
| B3M-06 | User §14 | shared physics | Debug-only release telemetry reports raw/effective velocity, item/s, band, projection, target, delta, and settling estimate | source inspection + physics tests | DONE |
| B3M-07 | User §16–19 | shared controller/adapter | Generated belt, rebase, haptic, preview/settled callbacks, single highlight, and no-bounce snap regressions remain green | focused + full non-golden tests | DONE |
| B3M-08 | User final workflow | repository/CI | Golden tests skipped; commit, push, successful APK build, and direct APK download completed | git/CI/file evidence | NOT DONE |

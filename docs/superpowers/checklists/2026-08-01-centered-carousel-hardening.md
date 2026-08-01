# Centered Carousel Hardening Acceptance Checklist

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| CCH-01 | User §1–2 | shared data source/controller | bounded, cyclic, generated modes exist and adapters share one engine | unit + boundary tests | NOT DONE |
| CCH-02 | User §3 | controller/carousel | 200001 physical belt, 100000 anchor, logical mapping, idle rebase | controller/widget tests | NOT DONE |
| CCH-03 | User §5–8 | shared physics | velocity is normalized to items/s; friction proposes landing; step cap and attenuated spring are applied | physics unit tests | NOT DONE |
| CCH-04 | User §9–10 | math/spec | drag follows continuously; scale is 1.00/0.84/0.72/0.62 at 0/1/2/3 distance | math unit tests | NOT DONE |
| CCH-05 | User §11 | controller/metrics | exactly one nearest physical index is selected/highlighted | math/widget tests | NOT DONE |
| CCH-06 | User §14–15 | controller | one throttled selection tick per logical index; preview and settled callbacks are distinct | controller tests | NOT DONE |
| CCH-07 | User §12–13 | carousel widget | item slots/gap remain fixed; centered rail shows five complete tiles and clips edges | widget test + screenshot inspection | NOT DONE |
| CCH-08 | User §16–19 | design tokens/widgets | no control uses stadium/pill shape; time and direction controls share fixed radius and height | shape/primitive tests + audit | NOT DONE |
| CCH-09 | User “layout alapvetően jó” | dashboard geometry | rail top, search/date, action position, and bottom nav position remain unchanged | geometry regression tests | NOT DONE |
| CCH-10 | User final workflow | repository/CI | golden tests skipped; commit, push, successful APK build, direct APK download | git/CI/stat evidence | NOT DONE |


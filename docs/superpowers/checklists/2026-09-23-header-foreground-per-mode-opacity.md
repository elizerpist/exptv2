# Header foreground, palette and per-mode opacity acceptance checklist

Scope authority: the user-approved **FLUVI — HEADER FOREGROUND CUSTOMIZATION
+ MIND/BALANCE PALETTE OPTIONS + PER-MODE OPACITY** request, 2026-09-23.
Implementation base: behavioural application source `616e87cb25ef08f6dbfb72fd4b1629418a4782e5`.

| ID | Requirement source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HFC-01 | Mind/Balance foreground controls | Header visual tuning, mode surfaces, trend charts | Mind and Balance each expose independent white/black text and line-chart choices; all four combinations work. | Unit + mounted widget tests inspect frame/style inputs. | DONE |
| HPL-01 | Mind Traffic (Color Lab) | Mind Header palette model/sampler | `Current` remains available and `Traffic (Color Lab)` has the ten authored colours at the exact equal stops. | Palette/order/window tests. | DONE |
| HPL-02 | Balance extra scales | Balance palette catalog/sampler | Existing palettes remain and `Limit (Color Lab)` plus `Custom Balance` have the exact authored ten-colour orders. | Catalog/order/window tests. | DONE |
| HOP-01 | Dedicated opacity per mode | `DashboardHeaderVisualTuning` and three color policies | Balance, Mind and Budget material opacity are separate 0–100% settings and cannot overwrite each other. | Policy/controller + tuner tests. | DONE |
| HOP-02 | Opacity composition | Header physical shell / static + fragment render path | 0% exposes clipped white base, 50% blends once, 100% is full material; text/chart content do not fade. | Composition/pixel-path source and widget tests. | DONE |
| HINV-01 | Presentation-only boundary | Header controller/policies | Palette, foreground and opacity changes do not mutate Balance amount/history, Mind score/chart points, Summary, Query, finances or the shared ticker identity. | Policy invariants and production-parent tests. | DONE |
| HUX-01 | Existing Header UI ownership | Header visual tuner | One existing controller/ticker, per-mode controls in tuner, no widget-local persistence or new gesture/geometry owner. | Tuner/controller identity tests and source audit. | DONE |
| HVAL-01 | Delivery validation | Focused Flutter suites, analyzer, Actions | Tests, formatter, analyzer and diff check have factual outcomes; a single final online APK is downloaded and hashed after all app work. | Command log / Actions evidence. | DONE — app `65f33a4e`; run `35895355192` Core/Flutter/APK PASS; profile failure recorded as inherited Mind evidence; APK downloaded and hashed. |
| HGRAPH-01 | Exact-source graph | Tooling branch | SCIP manifest source head equals final application SHA. | Tooling regeneration and deterministic hash. | DONE — tooling `d6eb121b`; manifest source head equals `65f33a4e`; two generations identical. |
| HPHYS-01 | User physical acceptance | Android user | Human device appearance/touch validation is not inferred from automated evidence. | User-only validation. | PENDING — USER ONLY |

## No-touch boundary

Balance financial values and history, Mind score and chart data, Summary/Query
semantics, Header geometry, Dashboard gesture physics, carousel ownership,
Budget financial logic, and the shared Header ticker remain outside this scope.

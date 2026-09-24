# Header typography and softened foreground acceptance checklist

Scope authority: user-approved **Fluvi — Header typography comparison and
independent softened-dark foreground options** request, 2026-09-24.

Implementation base: behavioral application source
`65f33a4e388f6f796b77f31a5360e8f2f82a6f01`; documentation-only feature head
at intake: `c1bf550017aff5a3b0bd689c83c18ec815bbd8bc`.

## Architecture card

`DashboardHeaderVisualController` remains the sole dashboard-lifetime settings
and ticker owner. `DashboardHeaderVisualTuning` owns one Header-only
typography profile and existing independent Balance/Mind foreground state.
Policies project those immutable tokens into `DashboardHeaderVisualFrame`;
Balance and Mind Header widgets only render the tokens. No financial/score
projection, query, palette, opacity, chart-series, global theme or gesture
owner is changed.

| ID | Requirement source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HTF-01 | User §§1, 7, 13 | `DashboardHeaderForegroundColor` | Fehér and literal Fekete remain; Lágyított resolves exactly to Color Lab Portal `rgba(20,33,58,.82)`. | Pure catalog/frame tests. | DONE — focused PASS |
| HTF-02 | User §§1, 11–13 | Existing mode visual state/controller | Balance text and chart independently select all three foreground tokens, without changing Balance values, series or ticker identity. | Controller/frame + mounted Balance tests. | DONE — focused PASS |
| HTF-03 | User §§1, 11–13 | Existing mode visual state/controller | Mind text and chart independently select all three foreground tokens, without changing score values, series or ticker identity. | Controller/frame + mounted Mind tests. | DONE — focused PASS |
| HTF-04 | User §12 | `DashboardHeaderVisualTuner` | The real tuner has stable controls for all Balance/Mind text/chart choices; every tap updates only its target state. | Mounted tuner test. | DONE — focused PASS |
| HTY-01 | User §§1, 9, 13 | `DashboardHeaderVisualTuning` | One selector exposes App (default) and Color Lab; setting is dashboard-lifetime only and creates no controller/ticker. | Controller/tuner/repeated-selection tests. | DONE — focused PASS |
| HTY-02 | User §§7, 9, 13 | Header typography token | App exactly preserves current Balance amount, Mind score and mode-label TextStyles. | Style baseline regression tests. | DONE — focused PASS |
| HTY-03 | User §§7, 9, 13 | Local Inter asset + Header-only typography token | Color Lab uses an official, locally bundled Inter font with SIL OFL notice; no runtime font fetch or global theme change. Browser fallback parity remains explicitly unclaimed. | Asset/license audit + frame/widget tests. | DONE — local asset/license audit + focused PASS |
| HTY-04 | User §§11–14 | Header mode surfaces | Typography and foreground are orthogonal; only intended Balance/Mind Header text consumers change, while chart geometry and data remain exact. | Production-parent + trend-kernel tests. | DONE — focused PASS |
| HINV-02 | User §§10, 14 | Existing presentation path | Palettes, opacity, financial/score data, Summary/Query, header geometry, hit testing, physics and controller identities remain unchanged. | Source/diff audit and regression suite. | DONE — diff audit + fast PASS |
| HVAL-02 | User §§15–18 | Focused Flutter/CI gates | RED evidence, focused tests, fast suite, analyzer, format and diff outcomes are recorded honestly. | Exact command logs. | DONE — local gates PASS |
| HBUILD-02 | User §18 | GitHub Actions | One final workflow builds a human diagnostic APK from the final application SHA and it is downloaded, hashed and marker-verified. | Actions/release/APK checks. | DONE — run `35935767678`; APK `fluvi_HUMAN_DIAGNOSTIC_f4699d6.apk`, `86,518,385` bytes, SHA-256 `a76d77bbc7f65e0db0aaab401c164fee729196fe9dcda41f1d49495c95ab7238`; embedded build SHA `f4699d69…` contains behavioral source `fef29410…`. |
| HGRAPH-02 | User §§6, 18 | Tooling worktree | Separate SCIP tooling commit pins `manifest.source_head` to final app SHA and is deterministic. | Two generations + tooling tests. | DONE — tooling `fe45a213…`; `source_head=fef29410…`; raw index SHA-256 `37f0d513…`; two generations match; 15 tooling tests PASS. |
| HPHYS-02 | User §§3, 20 | Android user | Physical look/readability validation is never inferred from tests or APK. | User-only. | PENDING — USER ONLY |

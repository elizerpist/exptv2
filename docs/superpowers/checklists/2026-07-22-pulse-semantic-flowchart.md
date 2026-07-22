# Pulse Semantic Flowchart Acceptance Checklist

Working artifact: `docs/prototypes/pulse_engine_panel_mockup.html`.

Reference design: `docs/superpowers/specs/2026-07-22-pulse-semantic-flowchart-design.md`.

| ID | Source instruction or approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| PSF-001 | User, 2026-07-22: detailed semantic flowchart at the top | HTML before `.hero-grid` | A full-width semantic `Pulse decision flow` appears directly below the top bar, before the phone/overview content. | Static order/anchor test. | NOT DONE |
| PSF-002 | User example: user selects score; is score enough? | Entry and priority stages | The chart distinguishes score inspection from a trigger and says score alone cannot create a header message. | Static text/branch test. | NOT DONE |
| PSF-003 | Existing engine decision trace design | Recalculation and raw-signal stages | Changed data, scheduled calculation, resume/date change, source state, confidence, and fingerprint visibly enter the engine. | Static stage test. | NOT DONE |
| PSF-004 | Existing eligibility contract | Source/evidence gates | Deferred, engine-only, stale, muted, same-fingerprint, insufficient-confidence, below-delay, and missing-evidence paths are visible and stop before scoring; a lower but eligible confidence is visibly penalized instead. | Static branch test. | NOT DONE |
| PSF-005 | Existing priority-score contract | Priority and selection stages | The formula, dominant-base rule, modifiers, no-universal-threshold rule, rank, and deterministic tie-break are visible. | Static formula/branch test. | NOT DONE |
| PSF-006 | User: shown/discarded message paths | Composition, delivery, and lifecycle stages | The diagram visibly distinguishes selected, suppressed/not queued, background pending, delivered/shown, no-header, superseded, and retrigger paths. | Static branch test. | NOT DONE |
| PSF-007 | Existing copy-role contract | Composition stage | Only eligible roles can populate headline/evidence/time-cause/caveat/recovery; deferred and engine-only sources have no header copy. | Static text test. | NOT DONE |
| PSF-008 | Approved three-group rail design | Existing rail | No fourth primary rail is created; exactly Budget pressure, Cashflow pressure, and Data quality remain. | Existing rail contract test. | NOT DONE |
| PSF-009 | Mobile mockup constraint | Flowchart CSS | The chart turns into a vertical, non-clipping semantic path on narrow width. | CSS/static check; no screenshot by user request. | NOT DONE |
| PSF-010 | User, 2026-07-22 | Scope protection | `balance_latest_layout.html` is untouched. | Baseline hash comparison. | NOT DONE |

# Header Fragment Fidelity Acceptance Checklist

| ID | Requirement/source | Code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| HF-01 | HTML field is per-source-pixel, not `/4` mesh | shader backend | Maximum quality chooses a fragment backend; geometry test rejects mesh | DONE — `dashboard_header_fragment_backend_test.dart` |
| HF-02 | DPR must not only enlarge sparse triangles | renderer contract | DPR 1/2/3 backend tests | DONE — fragment plan has physical DPR output and no mesh dimensions |
| HF-03 | Existing Color Lab common field semantics | shader source | fixed source-math checkpoints / shader uniform contract | PARTIAL — source formulas are ported into the shader; direct HTML↔APK frame comparison remains human/device work |
| HF-04 | Portal `.55`/`.48` must not get second `/4` decimation | Portal renderer | Portal shader backend test | DONE — high-fidelity renderer has no Portal mesh geometry |
| HF-05 | Tap ripple displaces field before sampling | shader + wave state | fixed ripple-coordinate test and no CPU field loop | DONE — fixed 10-slot shader bank plus existing source ripple checkpoints |
| HF-06 | Pink overlay/trail source parity remains | tap painter | existing source-contract tests plus widget gesture test | PARTIAL — source constants/tests preserved; physical composite comparison remains required |
| HF-07 | One shared clock / bounded resources | visual controller | 1,000-tick identity and bounded ripple tests | PARTIAL — one retained program/shader and 10-slot wave bank covered; device memory profile remains required |
| HF-08 | No semantic or motion regression | protected owners | Header isolation + CenteredCarousel/TimeRail suites; physics diff | PARTIAL — focused suites/physics diff are clean; full-suite/CI still running |
| HF-09 | Current log audit | local Fluvi export | 2026-08-21 20:40 UTC 502,852-byte file locate/read | BLOCKED: inaccessible locally |
| HF-10 | Visual physical parity | normal APK/manual device | direct HTML vs APK comparison | NOT DONE: human acceptance required |

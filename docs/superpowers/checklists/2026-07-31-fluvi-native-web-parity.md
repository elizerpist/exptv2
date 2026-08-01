# Fluvi native-to-web visual parity checklist

Native source of truth: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260731-230254.png`.
The five-item BNB-03 is the only explicitly permitted visual substitution.

Status: rolled back one iteration per user feedback; the preceding Fluvi web
state is restored, including the app-owned fullscreen control and visible SVG
brand/action assets.

| ID | Source requirement | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| PARITY-01 | Native Android screenshot is the only visual source of truth | `docs/`, screenshot path above | Native screenshot is retained as the comparison reference; no redesign is introduced | Direct screenshot inspection | DONE |
| PARITY-02 | Determine whether top black band/fullscreen control belongs to host or app | `web/index.html`, `FluviAppShell`, static host | Static host has no iframe/toolbar/spacer; fullscreen control is identified as app code and removed | Host HTML/source inspection; runtime DOM `getBoundingClientRect` still requires browser capture | PARTIAL — source result is clear, runtime DOM measurement unavailable locally |
| PARITY-03 | Android and web use the same widget tree | `lib/app/fluvi_app.dart`, `fluvi_app_shell.dart` | No `kIsWeb` header wrapper or web-only top padding remains; only the shared shell is used | Source inspection and targeted test | DONE |
| PARITY-04 | Root top is 0; no duplicate top safe area | `web/index.html`, `fluvi_app_shell.dart` | `html`, `body`, and `flt-glass-pane` are marginless/full viewport; shell has no top `SafeArea` or manual status-bar padding | Source inspection and release build | DONE |
| PARITY-05 | Only width responsiveness may change vertical spacing | `dashboard_layout_metrics.dart` | Dashboard scale is width-driven; a short viewport does not compress vertical anchors | Geometry regression test | DONE |
| PARITY-06 | Earlier user instruction: restore the app fullscreen button | `fluvi_app_shell.dart`, platform files | Fullscreen control is present in the app widget tree and remains web-capable | App widget test and source inspection | DONE |
| PARITY-07 | Restore the previous Fluvi header asset state | `fluvi_brand_lockup.dart` | The supplied visible SVG mark, wordmark, and motto are rendered together | Widget test and source inspection | DONE |
| PARITY-08 | Restore the previous Bevétel/Kiadás asset state | `transaction_direction_toggle.dart` | Both tabs render their supplied SVG action assets and labels | Widget test and source inspection | DONE |
| PARITY-09 | Use native typography | `dashboard_mode_palette.dart`, BNB03 | No unavailable SF Pro override is forced; widgets inherit the shared Flutter/native font | Source inspection and targeted analyze | DONE |
| PARITY-10 | Produce a 690×1536 comparison screenshot | `artifacts/` | Native and web comparison artifacts are exactly 690×1536 | Image dimensions | PARTIAL — baseline comparison exists; final post-fix web capture pending |
| PARITY-11 | Iterate to ≤2–3 px main-element delta | visual verification | Overlay/pixel-diff of final web capture vs native reference meets tolerance | Final browser screenshot + diff | BLOCKED — no local browser/DOM screenshot runner is available; user capture required |

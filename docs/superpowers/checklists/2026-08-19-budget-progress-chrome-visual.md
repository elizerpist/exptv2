# Budget progress-chrome visual acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BPC-01 | User §3–7; `spendeetest@144d78c` Budget2 painter | Avatar progress painter | `visualProgress` paints a continuous clockwise sweep: 0, .25, .50, .75, .99, 1 map to 0, .5π, π, 1.5π, 1.98π, 2π. | Painter-contract test without a golden. | DONE |
| BPC-02 | User §8–13 | Artwork + selected composition | Positive-limit chrome is mounted only for the exact selected live target; null/zero limit removes it in the next frame while the pointer remains down and restores it on upward crossing. | Widget tests using the existing quick-edit state. | DONE |
| BPC-03 | User §14–19 | `BudgetCategoryAvatarArtwork`, rail prepared variants | Side = normal SVG shadow; centre+positive = centred core/no avatar shadow + chrome shadow; centre+nonpositive = normal authored SVG shadow/no chrome; sphere and glyph geometry unchanged. | SVG-source and geometry widget tests. | DONE |
| BPC-04 | User §17, §23 | Rail prepared avatar source cache | The static normal/centred SVG sources are prepared once per immutable avatar; live ticks select, but do not generate, SVG or decode icons. | Direct source inspection plus focused rail test. | DONE |
| BPC-05 | User §25–27 | Flutter delivery | Format, analyzer, focused and relevant existing Budget regressions green; only visual files/tests staged, pushed and normal APK downloaded. | Local test/analyzer output; `Fluvi Verification` run `32210089887`; downloaded APK SHA-256 `a4e672d005b8c80a1a8a896369a5ec8fd77023f5865cdc11afa903cc20b1fa29`. | DONE |

## Compact architecture card

- Existing owner: `BudgetCategoryAvatarArtwork` owns the SVG/chrome composition; `_PreparedBudgetTargetAvatar` owns immutable prepared source variants.
- Shared mechanism: reuse the existing direct `selectedLiveSelectionListenable`; no new notifier, controller, data or persistence path.
- State boundary: `DashboardBudgetPresentationController` publishes immutable live selection; UI only selects prebuilt artwork and paints its chrome.
- Focused verification: painter geometry contract and the rail widget's zero-crossing/shadow matrix tests.

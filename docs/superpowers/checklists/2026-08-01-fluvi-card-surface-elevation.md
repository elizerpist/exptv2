# Fluvi Shared Card Surface Elevation Acceptance Checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| CARD-01 | Balance B3M HTML + structuring-apps centralization rule | `FluviRoundedBox`, `FluviVisualTokens` | One shared card-surface owner supplies the default material treatment | source audit + unit test | DONE |
| CARD-02 | Balance/Budget 3D lower-edge treatment | `FluviVisualTokens.cardFootShadow` | Every default rounded surface gets a small neutral blur-free lower foot | token unit test + widget tests | DONE |
| CARD-03 | Balance card soft elevation | `FluviVisualTokens.cardElevationShadow` | Every default rounded surface also gets the shared soft downward shadow | token unit test + widget tests | DONE |
| CARD-04 | User requirement | `FluviRoundedBox` consumers | Header, subheaders, summary, year chips, and income/expense active/inactive states inherit the same shadows | consumer audit + widget tests | DONE |
| CARD-05 | User requirement | palette/surface tokens | The treatment is neutral and does not depend on a pink border | source inspection | DONE |
| CARD-06 | Existing Fluvi visual system | `FluviRoundedBox` | Existing colors, gradients, radii, dimensions, and interaction behavior remain intact | focused regression tests | DONE |
| CARD-07 | User delivery request; golden tests explicitly deferred by user | Flutter test/analyze | All non-golden tests pass; analyzer reports no new errors (only the existing web `dart:html` infos remain) | Ubuntu proot test + analyze | DONE |
| CARD-08 | User delivery request | GitHub/Download | Commit `14b2714`, push, CI run `30695927558` with all three jobs successful, and direct APK download completed at `/storage/emulated/0/Download/fluvi/fluvi_14b2714.apk` | git/CI/file evidence | DONE |

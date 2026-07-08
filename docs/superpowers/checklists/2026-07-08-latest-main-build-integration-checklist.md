# Latest Main Build Integration Checklist

Goal: produce a `main` build that contains the latest stats menu work plus the latest center-badge/backheader/magnet/FAB work from `origin/feature/center-badge-backheader-partition`.

Mandatory source refs:

- `origin/main` at `3ba457c` before this integration.
- `origin/feature/stats-menu-main-redesign` at `3ba457c`.
- `origin/feature/center-badge-backheader-partition` at `ec8f535`.
- User-listed required commits: `ec8f535`, `2e9a8c3`, `d05048a`, `cc6a1ac`, `d5bb08b`, `681b85b`, `82015ae`, `6f4ea44`, `1049783`, `7503f12`, `a0eb20d`, `2190b86`, `52764f3`, `734983a`, `fc24f95`, `f947a6c`, `01ae71d`, `d339020`, `c404457`, `e513212`, `8b33a8b`, `bae1df5`.

| ID | Source instruction / approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| LATEST-MAIN-001 | User: "mindenbol a legfrissebb legyen" | Git branch integration | `main` includes the current stats head `3ba457c` and does not lose stats menu commits. | `git merge-base --is-ancestor 3ba457c origin/main`. | PARTIAL |
| LATEST-MAIN-002 | User: "feature/center-badge-backheader-partition ... magnescsik ... backheader ... tuner sor" | Header card, magnet strip, backheader, center badge settings | `main` includes `origin/feature/center-badge-backheader-partition` head `ec8f535`, including the user-listed center-badge/backheader/magnet commits. | `git merge-base --is-ancestor ec8f535 origin/main` and listed commit containment check. | PARTIAL |
| LATEST-MAIN-003 | User: "Kozben ezen a branchen volt meg a nav/FAB vonal is" | Shell navigation, FAB settings | `main` includes `bae1df5`, `8b33a8b`, and `e513212`, so configurable nav layout and FAB shape/size settings are present. | Commit containment check plus Flutter tests covering settings/shell where available. | PARTIAL |
| LATEST-MAIN-004 | User: "backheader sheet (reszletes vizual beallitas)" | Settings/backheader tuner sheet widgets | The detailed grouped backheader/center-badge tuner sheet from the center-badge branch is present after integration. | Commit containment for `d5bb08b`, `cc6a1ac`, `d05048a`, `2e9a8c3`; targeted widget tests where available. | PARTIAL |
| LATEST-MAIN-005 | User asked for a build from the latest main state | GitHub Actions workflow | A new debug APK is built from the integrated `main` commit, not from a partial feature branch. | GitHub Actions run head SHA equals integrated `origin/main` SHA and completes successfully. | NOT DONE |
| LATEST-MAIN-006 | User previously: do not delete existing files in Downloads | `/storage/emulated/0/Download/exptv2` | Download the new APK into the existing folder without deleting older APKs. | List folder before/after; verify new APK exists by exact filename and size/hash. | NOT DONE |
| LATEST-MAIN-007 | Engineering verification | Flutter/Dart/Android tests | Integration does not break local targeted Flutter checks or online full build checks. | Proot `flutter test`/`flutter analyze` where practical; GitHub Actions analyze, Flutter tests, Android unit tests, APK build. | PARTIAL |

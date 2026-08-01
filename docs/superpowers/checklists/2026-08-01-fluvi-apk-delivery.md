# Fluvi APK Delivery Acceptance Checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| APK-01 | User request: direct APK, not artifact | `.github/workflows/fluvi-core.yml` | The build workflow does not call `actions/upload-artifact` | direct workflow audit | DONE |
| APK-02 | User request: download link only | `build-debug-apk` job | A successful build uploads the raw APK as a GitHub Release asset and writes its direct browser download URL to the job summary | successful workflow run + summary URL | NOT DONE |
| APK-03 | User request: Fluvi worktree delivery | Git remote/worktree | The build source is the Fluvi worktree on `refactor/fluvi-production`; the repository name is taken from its configured `origin` | `git remote -v`, workflow checkout | DONE |
| APK-04 | User request: remove intermediate zip | local download staging | No intermediate artifact zip created by the interrupted delivery remains | explicit file audit | DONE |

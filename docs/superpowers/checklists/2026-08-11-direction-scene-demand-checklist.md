# Direction scene-bank and required-demand correctness checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DSC-01 | User report: direction-switch paint hole, sections 3–8 | `DashboardPreparedRevisionBundle` | The publication-critical window contains the current temporal parent and immediate rail domain for income and expense, once each. | Scene-window direction-twin test | DONE |
| DSC-02 | User report, section 6 | `DashboardCoreController` scene-window identity | Payload identity is independent of insertion/selected-direction order and coverage is based on exact canonical query keys. | Direction-switch test and direct source inspection | DONE |
| DSC-03 | User report, sections 9–14 | `DashboardCoreController` rebase coordinator | Input can cancel preparation but cannot discard the latest required coverage demand; idle retries it, while a newer target supersedes the old one. | In-flight cancellation and supersession tests | DONE |
| DSC-04 | User report, sections 18–22 | Dashboard scene preparation boundary | The fix does not restore a full synchronous bank, change rail physics, alter paging, or alter SQL/query UI. | Diff inspection and fast correctness suite | DONE |
| DSC-05 | Global APK delivery rule | GitHub Actions + `/storage/emulated/0/Download/fluvi` | Exact pushed SHA’s normal human APK succeeds and is downloaded with a verified SHA-256. | GHA run 31479490465, release asset size/hash comparison | DONE |

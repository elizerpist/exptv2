# Summary preview and body-layout follow-up checklist

## Architecture card

### Scope and sources

- User requirements: follow-up prompt dated 2026-08-25.
- Physical evidence: Fluvi Logs revision
  `AIroW34nIJy1wCZ3BJSyKifmBnRgD2j88pFYc0CSogqG2oMe-ELTN5F6-texkowLLHnp9wtW-ghrXcWcOn1QCg`,
  final avatar-preview sequence `[17:53:45.57–17:53:46.64]`.
- Existing owners: `DashboardVisibleFrameStore`, `DashboardCoreController`,
  `DashboardBudgetPresentationController`, `CenteredCarousel`, and
  `DashboardGeometryResolver`.

### Single source and write paths

| State | Owner | Publication rule |
| --- | --- | --- |
| Budget target visual preview | `DashboardBudgetPresentationController` | one discrete avatar crossing selects one prepared target cell |
| Focused amount preview | `DashboardCoreController` / `DashboardVisibleFrameStore` | exact prepared focus scalar, ordered by existing focus generation; does not rotate the scene |
| Summary amount | `DashboardVisibleFrameStore.amountLane` | prepared scalar preview first; later complete frame uses the same query/revision |
| Summary variant and body order | dashboard-lifetime presentation controllers | session-only, no query/state reset |
| Body geometry | `DashboardGeometryResolver` | one ordered component cursor plus explicit physical-rail policy |

### Reuse / centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Avatar ballistic cadence | `CenteredCarousel` + avatar preview coalescer | reuse; publish only each semantic crossing |
| Stale focus suppression | `DashboardCoreController._focusPublicationGeneration` | reuse for preview and settled focus |
| Amount formatting | prepared visible-frame amount lane | reuse; no widget aggregation/formatting |
| Gesture arbitration | bounded `CenteredCarousel` surfaces | make Swipe surface an intentional lower layer, not an invisible blocker |
| Placement/order | `DashboardGeometryResolver` | extend resolver; no widget translations or six coordinate trees |

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| A-01 | Task A | Budget preview/focus/visible frame | each accepted avatar tick publishes its target amount before scene settle; complete LogBox frames remain atomic and stale-safe | `dashboard_core_ephemeral_focus_test.dart` lifecycle tests | DONE |
| B-01 | Task B | Swipe surface | real horizontal pointer input changes cyclic mode; vertical fields retain ownership | `summary_pill_experiments_widget_test.dart` pointer + semantics tests | DONE |
| C-01 | Task C | metrics/resolver/frame | Segmented/Swipe transfer exactly rail height + rail-to-handler gap to ModeContent; Legacy unchanged | resolver matrix for all three core modes | DONE |
| C-02 | Task C | Budget pager | lower card and donut use enlarged constraints; upper card unchanged | category/pager constraint tests | DONE |
| D-01 | Task D | presentation order controller | one validated three-member order; default Direction/Summary/ModeContent | model + tuner widget tests | DONE |
| D-02 | Task D | resolver/CoreDashboard/tuner | all six orders centrally position three bodies; handler and Ledger follow | exhaustive resolver permutation test | DONE |
| ARC-01 | Milestone | controller/viewport | no second vertical owner, no per-pixel query/formatting, stable committed geometry | focused inspection plus motion/visible-frame/scene-window/LogBox boundary suites | DONE |
| DOC-01 | Task docs | selectable-experiment spec | records experimental-only changes and no business semantic change | documentation review | DONE |
| DEL-01 | Global workflow | delivery | commit/push/CI human APK download and SHA-256 | GitHub Actions/release evidence | DONE |

## Delivery evidence

- Production commit: `5cbea530d3f5b04ed40febcb799052c9ac6a08b2`.
- GitHub Actions run: `32801997151`; the `build-human-diagnostic-apk` job
  completed successfully.
- Human APK: `fluvi_HUMAN_DIAGNOSTIC_5cbea53.apk`, downloaded to
  `/storage/emulated/0/Download/fluvi/`.
- SHA-256:
  `a25e1393b4b51bd5d37b2270a6571e94853adbd132fb7137f8c3ba5bd38dae47`.

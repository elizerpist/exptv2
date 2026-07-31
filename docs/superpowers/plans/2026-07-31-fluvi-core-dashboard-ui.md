# Fluvi Core Dashboard UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Deliver a runnable Android Flutter application whose first screen is the accepted, data-free Fluvi Core Dashboard UI.

**Architecture:** The app shell supplies one immutable DashboardModeSpec to one CoreDashboard renderer. Headless controllers own interaction state; DashboardMotionHost owns Flutter tickers; DashboardGeometryResolver transforms central metrics into a single layout frame consumed by leaf widgets. The existing android:fluvi-core library remains independent and is linked only as a future-ready Android dependency, with no Dart or UI call into it.

**Tech Stack:** Flutter 3.41.4 / Dart 3.11.1, Material, flutter_svg 2.3.0, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, existing Room core, flutter_test, flutter_lints, GitHub Actions.

## Global Constraints

- Work only in /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi on branch refactor/fluvi-production.
- The accepted specification is docs/superpowers/specs/2026-07-31-fluvi-core-dashboard-ui-design.md. Re-read it before every implementation and final verification.
- Keep android/fluvi-core as an Android library. It must not import Flutter, Android application code, or presentation code.
- The Flutter package is fluvi and Android package/applicationId is com.fluvi.app.
- The first UI slice has no database, Room, repository, query, sync, logbox, route other than the root dashboard, or data-derived calculation.
- No file, asset, import, URL, or runtime dependency may come from Spendee/Exptv2. The three SVG assets are created locally under assets/fluvi.
- Use exactly one CoreDashboard for Balance, Budget, and Mind. Mode variation is DashboardModeSpec plus slot content only.
- Use DashboardLayoutMetrics and DashboardGeometryResolver as the only shared layout source. Downstream vertical positions must be derived from upstream metrics.
- Controllers are headless and never receive BuildContext or own AnimationController. DashboardMotionHost owns Flutter animation controllers.
- The 412 x 892 reference metrics are: Grey 100 #F1F5F9, 17 px gutters, 378 px content width, header top 104 px, header 126/104 px, 11 px standard gap, 72 px first subheader, 208 px Zone2, 4/6 px dots, action 42 px, summary 59 px, search 39 px, rail 37 px, handle hit area 20 px, collapse travel 180 px.
- At the expanded reference endpoint, action, summary, search and rail begin at 553, 606, 676 and 726 px respectively. They are resolver verification results, not leaf widget constants.
- The action pulse is 0.90 -> 1.12 -> 0.98 -> 1.00 over 420 ms. The active income palette is purple-to-pink; the active expense palette is orange-to-pink.
- Use Ubuntu/proot for flutter pub get, flutter test and flutter analyze. Do not run a local Flutter APK build on Termux; GitHub Actions produces the APK artifact.
- Every production behaviour follows RED -> observed failure -> GREEN -> verification. Flutter/Android generated configuration is the only bootstrap exception.

---

## File structure

    pubspec.yaml
    analysis_options.yaml
    lib/
      main.dart
      app/
        fluvi_app.dart
        shell/
          fluvi_app_shell.dart
          fluvi_bottom_navigation.dart
          fluvi_center_fab.dart
      core/
        design/
          fluvi_visual_tokens.dart
          dashboard_layout_metrics.dart
          dashboard_layout_frame.dart
          dashboard_geometry_resolver.dart
          dashboard_mode_palette.dart
          dashboard_motion_tokens.dart
        motion/
          dashboard_motion_host.dart
      features/dashboard/
        application/
          dashboard_core_controller.dart
          dashboard_expansion_controller.dart
          dashboard_rail_controller.dart
          transaction_direction_controller.dart
          dashboard_mode_spec.dart
        presentation/
          core_dashboard.dart
          widgets/
            fluvi_brand_lockup.dart
            dashboard_placeholder_card.dart
            transaction_direction_toggle.dart
            dashboard_summary_pill.dart
            dashboard_search_filter.dart
            time_refinement_rail.dart
            dashboard_collapse_handle.dart
    assets/fluvi/
      brand/fluvi_mark.svg
      actions/income_wallet.svg
      actions/expense_bag.svg
    test/
      app/fluvi_app_test.dart
      core/design/dashboard_geometry_resolver_test.dart
      features/dashboard/application/dashboard_expansion_controller_test.dart
      features/dashboard/application/dashboard_rail_controller_test.dart
      features/dashboard/application/transaction_direction_controller_test.dart
      features/dashboard/presentation/core_dashboard_test.dart
      features/dashboard/presentation/core_dashboard_golden_test.dart
      support/test_pump.dart
    scripts/verify-fluvi-boundaries.sh
    .github/workflows/fluvi.yml


## Task 1: Create the Flutter/Android host boundary and minimal bootable app

**Files:**
- Create: pubspec.yaml
- Create: analysis_options.yaml
- Create: lib/main.dart
- Create: lib/app/fluvi_app.dart
- Create: test/app/fluvi_app_test.dart
- Modify: android/settings.gradle.kts
- Modify: android/build.gradle.kts
- Create: android/app/build.gradle.kts
- Create: android/app/src/main/AndroidManifest.xml
- Create: android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt
- Create: android/app/src/main/res/drawable/launch_background.xml
- Create: android/app/src/main/res/drawable-v21/launch_background.xml
- Create: android/app/src/main/res/values/styles.xml
- Create: android/app/src/main/res/values-night/styles.xml
- Modify: .gitignore

**Consumes:** Existing android/fluvi-core Gradle library and wrapper.

**Produces:** A standard Flutter Android host with an app module, a minimal FluviApp public root widget, and a working flutter test command.

- [ ] **Step 1: Add generated bootstrap configuration**

Create pubspec.yaml with package name fluvi, version 0.1.0+1, SDK constraint ^3.11.1, Flutter SDK dependency, flutter_svg ^2.3.0, flutter_test, flutter_lints ^6.0.0, Material design, and assets/fluvi/. Add the recommended flutter_lints include to analysis_options.yaml.

Convert Android settings to load the Flutter Gradle plugin and include both app and fluvi-core:

    plugins {
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
        id("com.android.application") version "8.11.1" apply false
        id("org.jetbrains.kotlin.android") version "2.2.20" apply false
        id("com.google.devtools.ksp") version "2.2.20-2.0.4" apply false
    }

    include(":app", ":fluvi-core")

Make android/app a com.android.application Flutter host with applicationId com.fluvi.app, minSdk 24, Java/Kotlin 17, dev.flutter.flutter-gradle-plugin, source ../.., and implementation(project(":fluvi-core")). Create only the Flutter embedding activity and launch-theme resources; do not introduce permissions, services, receivers, Room construction, or platform channels.

- [ ] **Step 2: Write the failing root-app widget test**

Create test/app/fluvi_app_test.dart:

    testWidgets('boots into the active Dashboard placeholder', (tester) async {
      await tester.pumpWidget(const FluviApp());
      expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter pub get && /home/flutteruser/flutter/bin/flutter test test/app/fluvi_app_test.dart'

Expected: the test fails because FluviApp has not yet rendered the shell and Dashboard text.

- [ ] **Step 3: Implement the smallest root app**

Create main.dart with runApp(const FluviApp()). Create FluviApp as a MaterialApp with debug banner disabled, Grey 100 canvas background, and home set to a keyed temporary root surface that renders Dashboard. This is only the bootstrap seam; Task 4 replaces the temporary root content with FluviAppShell without changing FluviApp's public API.

- [ ] **Step 4: Verify the bootable root**

Run the test in Step 2 again. Expected: PASS, 1 test.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze'

Expected: No issues found.

- [ ] **Step 5: Commit the host boundary**

    git add pubspec.yaml pubspec.lock analysis_options.yaml .gitignore lib/main.dart lib/app/fluvi_app.dart test/app/fluvi_app_test.dart android
    git commit -m "feat(fluvi): add runnable Flutter host"


## Task 2: Implement and prove the headless dashboard geometry and interaction core

**Files:**
- Create: lib/core/design/dashboard_layout_metrics.dart
- Create: lib/core/design/dashboard_layout_frame.dart
- Create: lib/core/design/dashboard_geometry_resolver.dart
- Create: lib/features/dashboard/application/dashboard_mode_spec.dart
- Create: lib/features/dashboard/application/dashboard_expansion_controller.dart
- Create: lib/features/dashboard/application/dashboard_rail_controller.dart
- Create: lib/features/dashboard/application/transaction_direction_controller.dart
- Create: lib/features/dashboard/application/dashboard_core_controller.dart
- Create: test/core/design/dashboard_geometry_resolver_test.dart
- Create: test/features/dashboard/application/dashboard_expansion_controller_test.dart
- Create: test/features/dashboard/application/dashboard_rail_controller_test.dart
- Create: test/features/dashboard/application/transaction_direction_controller_test.dart

**Consumes:** Flutter foundation only; no presentation widget, repository, Android, or asset dependency.

**Produces:** Immutable mode specifications, metric-derived layout frames, and headless controllers with test-proven state transitions.

- [ ] **Step 1: Write the geometry RED tests**

Write tests that require this public API:

    final metrics = DashboardLayoutMetrics.reference;
    final frame = DashboardGeometryResolver.resolve(
      metrics: metrics,
      mode: DashboardModeSpec.balance,
      collapseProgress: 0,
      isRailExpanded: false,
    );

    expect(frame.actionBounds.top, 553);
    expect(frame.summaryBounds.top, 606);
    expect(frame.searchBounds.top, 676);
    expect(frame.collapseHandleBounds.top, 726);

Write a parameterized test for DashboardModeSpec.balance, .budget and .mind. Copy metrics with zone2CardHeight: 240 and require each resulting action top to be 32 px lower than 553. Also require the Mind unified subheader surface to occupy the same outer envelope as split Balance/Budget subheaders.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/core/design/dashboard_geometry_resolver_test.dart'

Expected: compilation/test failure because the geometry API does not exist.

- [ ] **Step 2: Implement metrics, specs and geometry minimally**

Implement immutable metrics with derived getters:

    double get subheaderOneTop => headerTop + headerExpandedHeight + standardGap;
    double get zone2Top => subheaderOneTop + subheaderOneHeight + standardGap;
    double get actionTop => zone2Top + zone2CardHeight + dotGap + dotHeight + standardGap;
    double get summaryTop => actionTop + actionHeight + standardGap;
    double get searchTop => summaryTop + summaryHeight + standardGap;

Implement DashboardMode as balance, budget, mind and DashboardSubheaderComposition as split or unified. Provide const static Balance, Budget and Mind specifications. Resolve expanded layout from the derived metrics. Resolve collapsed action top as headerTop + headerCollapsedHeight + standardGap, interpolate lower stack positions between endpoints, shrink header 126 -> 104, and stage first/Zone2 opacity without changing the shared endpoints.

- [ ] **Step 3: Verify geometry GREEN**

Re-run the geometry test. Expected: PASS and all expanded/derived/mode cases succeed.

- [ ] **Step 4: Write controller RED tests**

Write tests for these precise interactions:

    final controller = DashboardExpansionController();
    controller.beginDrag();
    controller.dragBy(-100);
    expect(controller.progress, 100);
    expect(controller.endDrag(), DashboardExpansionTarget.collapsed);

    final direction = TransactionDirectionController();
    direction.select(TransactionDirection.expense);
    expect(direction.direction, TransactionDirection.expense);
    expect(direction.pulseRevision, 1);

Test that a 90 px expansion drag snaps to expanded, an upward drag clamps at 180, a downward drag clamps at 0, rail toggles false -> true -> false, and selecting the already active direction does not increment pulseRevision.

Run the four focused test files. Expected: failure because controller types and APIs do not exist.

- [ ] **Step 5: Implement headless controllers**

Implement controllers using ChangeNotifier from foundation only. DashboardExpansionController exposes progress, isDragging, beginDrag, dragBy, endDrag, cancelDrag, toggleTarget, setProgress and toggle. It clamps 0..180 and uses 90 as the snap threshold. DashboardRailController owns only isExpanded and toggle/setExpanded. TransactionDirectionController owns direction and pulseRevision. DashboardCoreController creates exactly one instance of each controller and disposes them.

- [ ] **Step 6: Verify controller GREEN**

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/application'

Expected: PASS.

- [ ] **Step 7: Commit the headless core**

    git add lib/core/design lib/features/dashboard/application test/core/design test/features/dashboard/application
    git commit -m "feat(fluvi): add shared dashboard state and geometry"


## Task 3: Create local Fluvi assets, visual tokens, and reusable presentation primitives

**Files:**
- Create: assets/fluvi/brand/fluvi_mark.svg
- Create: assets/fluvi/actions/income_wallet.svg
- Create: assets/fluvi/actions/expense_bag.svg
- Create: lib/core/design/dashboard_mode_palette.dart
- Create: lib/core/motion/dashboard_motion_host.dart
- Create: lib/features/dashboard/presentation/widgets/fluvi_brand_lockup.dart
- Create: lib/features/dashboard/presentation/widgets/dashboard_placeholder_card.dart
- Create: lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart
- Create: lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart
- Create: lib/features/dashboard/presentation/widgets/dashboard_search_filter.dart
- Create: lib/features/dashboard/presentation/widgets/time_refinement_rail.dart
- Create: lib/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart
- Create: test/features/dashboard/presentation/dashboard_primitives_test.dart

**Consumes:** Task 2 controllers, metrics, layout frame, and token interfaces.

**Produces:** Local SVG renderers and dumb/reusable widgets. No widget owns shared layout geometry or business state.

- [ ] **Step 1: Write primitive RED tests**

Write a widget test that pumps FluviBrandLockup and requires keys fluvi-brand-mark, fluvi-wordmark and fluvi-motto. Write an action-toggle test that injects TransactionDirection.expense and scale 1.12, requires local asset keys fluvi-income-wallet and fluvi-expense-bag, and verifies the active label is Kiadás.

Write a handle test that taps its key and records one supplied callback. Write a rail test that pumps five static visual pills and requires the horizontal Scrollable. Do not test Flutter SVG internals.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/dashboard_primitives_test.dart'

Expected: failure because primitive widgets and assets do not exist.

- [ ] **Step 2: Create the three Fluvi-owned SVG assets**

Draw a new two-arc Fluvi mark SVG and new wallet/bag SVG illustrations under assets/fluvi. Use only SVG paths, gradients and shapes authored in this repository. Do not reference image URLs, embed external images, or reproduce a legacy source file. Keep the wallet/bag view boxes compatible with the 50 px / 48 px action-icon containers.

- [ ] **Step 3: Implement central visual and motion primitives**

Put page background, shared radii, neutral surfaces, borders, action gradients and text colours in FluviVisualTokens and DashboardModePaletteResolver. Put 420 ms pulse and 180 ms rail durations in DashboardMotionTokens.

Implement DashboardMotionHost as the only StatefulWidget with ticker controllers. Its builder receives a DashboardVisualFrame containing geometry, rail reveal value, income icon scale, and expense icon scale. It listens to DashboardCoreController, drives controller progress toward the requested expansion endpoint, uses the exact 0.90 -> 1.12 -> 0.98 -> 1.00 pulse curve, and honours MediaQuery.disableAnimations.

Implement each visual leaf as an input-only widget:
- FluviBrandLockup receives bounds and renders the local mark, wordmark and motto.
- DashboardPlaceholderCard receives bounds, radius and semantic key only.
- TransactionDirectionToggle receives selected direction, two icon scales and an intent callback; it never creates an AnimationController.
- DashboardSummaryPill receives rail visibility and chevron callback.
- DashboardSearchFilter is an inert search/filter visual row.
- TimeRefinementRail owns a horizontal SingleChildScrollView of static presentation pills only.
- DashboardCollapseHandle receives vertical-drag/tap callbacks and draws the shared handle bar.

- [ ] **Step 4: Verify primitives GREEN**

Re-run dashboard_primitives_test.dart. Expected: PASS.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze'

Expected: No issues found.

- [ ] **Step 5: Commit presentation primitives**

    git add assets/fluvi lib/core/design/dashboard_mode_palette.dart lib/core/motion lib/features/dashboard/presentation/widgets test/features/dashboard/presentation/dashboard_primitives_test.dart pubspec.yaml pubspec.lock
    git commit -m "feat(fluvi): add dashboard visual primitives"


## Task 4: Compose the common CoreDashboard and the fixed Fluvi shell

**Files:**
- Create: lib/features/dashboard/presentation/core_dashboard.dart
- Create: lib/app/shell/fluvi_app_shell.dart
- Create: lib/app/shell/fluvi_bottom_navigation.dart
- Create: lib/app/shell/fluvi_center_fab.dart
- Modify: lib/app/fluvi_app.dart
- Modify: test/app/fluvi_app_test.dart
- Create: test/support/test_pump.dart
- Create: test/features/dashboard/presentation/core_dashboard_test.dart
- Create: test/features/dashboard/presentation/core_dashboard_golden_test.dart
- Create: test/goldens/core_dashboard_expanded.png
- Create: test/goldens/core_dashboard_collapsed.png

**Consumes:** Tasks 1-3 public APIs.

**Produces:** The one rendered dashboard core and the actual root shell.

- [ ] **Step 1: Write composition and gesture RED tests**

Write a root test that requires:
- fluvi-app-shell, core-dashboard, dashboard-nav-item and disabled fluvi-center-fab keys;
- no tap response from center FAB or Settings;
- exactly one CoreDashboard for each injected Balance, Budget and Mind spec.

Write a gesture test that:
1. starts at expanded state,
2. drags the collapse handle upward by 180 px and verifies the action row moves to the collapsed anchor,
3. taps the handle and verifies return to expanded,
4. taps the Summary chevron and requires the rail,
5. drags the rail horizontally and verifies expansion progress does not change,
6. taps Kiadás and verifies active action state changes.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/core_dashboard_test.dart'

Expected: failure because the composition and shell do not exist.

- [ ] **Step 2: Implement CoreDashboard through one layout frame**

Implement a CoreDashboard host that receives DashboardModeSpec and DashboardCoreController. It uses DashboardMotionHost and places every shared element from DashboardVisualFrame bounds. It must not contain numerical spacing/position constants. Its header/subheader gesture region and collapse handle route into the same expansion controller. Its TimeRefinementRail only owns horizontal scroll. It reserves the split envelope for Balance/Budget and draws one unified placeholder surface over that envelope for Mind.

Implement FluviAppShell as a full-screen Stack with the dashboard behind a fixed bottom navigation. Render Dashboard active at left, a visibly centered but disabled FAB, and visibly disabled Settings at right. It owns the default Balance specification and a single DashboardCoreController lifecycle. Replace Task 1's temporary root with this shell.

- [ ] **Step 3: Verify composition GREEN**

Re-run app and CoreDashboard tests. Expected: PASS.

Run all tests:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test'

Expected: PASS.

- [ ] **Step 4: Add 412 x 892 golden evidence**

In test/support/test_pump.dart, configure a deterministic 412 x 892 surface and fixed text scale. Golden-test the core dashboard with rail closed/expanded dashboard and after a fully collapsed controller state. Generate the two files with:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/core_dashboard_golden_test.dart --update-goldens'

Then verify without update:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/core_dashboard_golden_test.dart'

Expected: PASS.

- [ ] **Step 5: Commit the composed UI**

    git add lib/app lib/features/dashboard/presentation/core_dashboard.dart test/app test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/presentation/core_dashboard_golden_test.dart test/support test/goldens
    git commit -m "feat(fluvi): compose shared core dashboard UI"


## Task 5: Update boundaries, documentation and GitHub APK verification

**Files:**
- Create: scripts/verify-fluvi-boundaries.sh
- Delete: scripts/verify-clean-core-boundary.sh
- Modify: .github/workflows/fluvi-core.yml
- Modify: README.md
- Modify: docs/architecture/fluvi-core-foundation.md
- Modify: docs/superpowers/specs/2026-07-31-fluvi-core-dashboard-ui-design.md
- Create: test/boundary/fluvi_boundary_test.dart

**Consumes:** All app and core paths introduced by Tasks 1-4.

**Produces:** An honest repository boundary, current documentation, and a CI workflow that tests the Flutter app and uploads a debug APK.

- [ ] **Step 1: Write the boundary RED test**

Write test/boundary/fluvi_boundary_test.dart to read tracked source text and require:
- android/fluvi-core does not contain dev.flutter, io.flutter or com.android.application;
- lib does not contain FluviCoreFactory, Room, repository imports, query imports, legacy package names or Spendee paths;
- pubspec lists only local Fluvi asset directories;
- scripts/verify-fluvi-boundaries.sh exists.

Run:

    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/boundary/fluvi_boundary_test.dart'

Expected: failure because the boundary script does not exist.

- [ ] **Step 2: Implement the repository boundary**

Create scripts/verify-fluvi-boundaries.sh. It must verify pubspec.yaml, android/app and android/fluvi-core exist; settings include both app and fluvi-core; Flutter is absent from android/fluvi-core; legacy package names are absent from Flutter/Android production source; and the dashboard source imports no database/repository/query/logbox feature. Make it executable.

Delete the old core-only script because its prohibition of Flutter and android/app is obsolete. Update README and core-foundation.md to say the repository now contains a separate Flutter consumer while the original core module boundary remains independent. Update every CORE-UI checklist row truthfully after local verification; do not claim GitHub APK success until the workflow actually succeeds.

- [ ] **Step 3: Add Flutter CI and APK artifact**

Rename the workflow display name to Fluvi Verification. Retain the Java 17/Android setup and core unit test. Add a Flutter 3.41.4 job that runs flutter pub get, flutter analyze and flutter test. Add an Android build job after both tests:

    flutter build apk --debug
    actions/upload-artifact@v4

Upload build/app/outputs/flutter-apk/app-debug.apk with artifact name fluvi-debug-apk. The workflow must run on push and workflow_dispatch.

- [ ] **Step 4: Verify boundaries and local suites**

Run:

    ./scripts/verify-fluvi-boundaries.sh
    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze'
    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test'
    proot-distro login --user flutteruser ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi/android && ./gradlew :fluvi-core:testDebugUnitTest --no-daemon'
    git diff --check

Expected: every command exits successfully. The final Android APK build remains CI-only.

- [ ] **Step 5: Commit verification infrastructure**

    git add scripts .github README.md docs/architecture docs/superpowers/specs test/boundary
    git rm scripts/verify-clean-core-boundary.sh
    git commit -m "ci(fluvi): verify Flutter shell and core boundaries"


## Task 6: Final review, push, build and download

**Files:**
- Modify: docs/superpowers/specs/2026-07-31-fluvi-core-dashboard-ui-design.md only if a checklist status needs an honest correction.

**Consumes:** Every previous task and their test evidence.

**Produces:** A reviewed, pushed branch and a locally downloaded GitHub Actions debug APK artifact.

- [ ] **Step 1: Re-read the accepted spec and plan**

Check every CORE-UI row against the implementation and test evidence. Inspect the expanded/collapsed golden PNGs directly. Confirm no requested element is missing and no data layer is connected.

- [ ] **Step 2: Run final local verification**

Run the Task 5 commands again, then:

    git status --short
    git log --oneline --decorate -10
    git diff --check

Expected: no uncommitted change, all local tests green, and no formatting error.

- [ ] **Step 3: Perform code review and final branch checks**

Use the requesting-code-review and verification-before-completion skills. Resolve every Critical or Important review finding, re-run its covering test, and re-review before proceeding.

- [ ] **Step 4: Push and wait for CI**

    git push -u origin refactor/fluvi-production

Use GitHub Actions to wait for the Fluvi Verification workflow on the pushed commit. Require both the core test, Flutter test and debug APK jobs to succeed.

- [ ] **Step 5: Download the artifact**

Download the exact successful run's fluvi-debug-apk artifact into a new explicit directory under the Fluvi worktree, such as artifacts/github-run-<run-id>/. Verify app-debug.apk exists and report its local link and the GitHub workflow URL.

- [ ] **Step 6: Final truthful handoff**

Report the commit SHA, pushed branch, workflow URL, artifact path, local test/analyze evidence, and any explicitly deferred requirement. Do not claim an APK was locally built on Termux.

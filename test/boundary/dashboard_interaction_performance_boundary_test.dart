import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps dashboard interaction ownership fail closed', () {
    final root = Directory.current;
    final libSources = _sources(root, 'lib');
    final dashboardWidgets = [
      _sources(root, 'lib/features/dashboard/presentation'),
      _sources(root, 'lib/features/dashboard/widgets'),
    ].join('\n');
    final logViewport = _read(
      root,
      'lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart',
    );
    final visibleFrameStore = _read(
      root,
      'lib/features/dashboard/visible/application/'
      'dashboard_visible_frame_store.dart',
    );
    final nativeReadService = _read(
      root,
      'android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt',
    );
    final profileHarness = _read(
      root,
      'integration_test/dashboard_interaction_profile_test.dart',
    );
    final profileRunner = _read(root, 'scripts/run-dashboard-profile.sh');
    final baselineHarnessPatch = _read(
      root,
      '.github/patches/dashboard-profile-baseline-harness.patch',
    );
    final profileWorkflow = _read(root, '.github/workflows/fluvi-core.yml');
    final preparedIndex = _between(
      nativeReadService,
      '    suspend fun preparedDashboardIndex(',
      '    suspend fun summaryByCategory(',
    );

    for (final owner in <String>[
      'DashboardDataRuntime',
      'GlobalCoreRevisionObserver',
      'PreparedDashboardIndexBuilder',
      'PreparedDashboardIndex',
      'DashboardPresentationController',
      'ExplicitCommittedPagingController',
    ]) {
      expect(
        RegExp('class\\s+$owner\\b').allMatches(libSources),
        hasLength(1),
        reason: '$owner must have exactly one production owner.',
      );
    }
    for (final obsolete in <String>[
      'DashboardParentBundleRegistry',
      'DashboardBackgroundWorkCoordinator',
      'DashboardAdjacentParentPrewarmCoordinator',
      'DashboardPreparedDeckCache',
      'DashboardPreparedDeckPipeline',
      'DashboardCommittedQueryController',
    ]) {
      expect(
        RegExp('class\\s+$obsolete\\b').allMatches(libSources),
        isEmpty,
        reason: '$obsolete is an obsolete parallel owner.',
      );
    }

    for (final forbidden in <String>[
      'dashboard_ledger_repository.dart',
      'method_channel_dashboard_ledger_repository.dart',
      "import 'dart:ffi'",
      "import 'dart:io'",
      'MethodChannel(',
      'EventChannel(',
    ]) {
      expect(
        dashboardWidgets,
        isNot(contains(forbidden)),
        reason: 'Dashboard widgets must render state and emit intent only.',
      );
    }

    expect(
      logViewport,
      isNot(
        matches(
          RegExp(
            r'(?:ValueKey|ObjectKey|PageStorageKey)\s*\([^)]*(?:queryKey|scopeKey)',
            caseSensitive: false,
          ),
        ),
      ),
      reason: 'A query change must not replace the stable LogBox viewport.',
    );
    expect(
      logViewport,
      contains("ValueKey('dashboard-logbox-flat-sliver-list')"),
      reason: 'Prepared LogBox content must use one stable lazy flat sliver.',
    );
    for (final obsolete in <String>[
      'SliverMainAxisGroup',
      'DecoratedSliver',
      'shrinkWrap:',
    ]) {
      expect(
        logViewport,
        isNot(contains(obsolete)),
        reason: '$obsolete reintroduces density-dependent viewport structure.',
      );
    }
    for (final lane in <String>[
      'navigationLane',
      'amountLane',
      'countLane',
      'logBoxLane',
    ]) {
      expect(
        visibleFrameStore,
        contains(lane),
        reason: 'Missing narrow atomic presentation lane: $lane',
      );
    }

    final nonCarouselSources = libSources.replaceFirst(
      _sources(root, 'lib/shared/motion/centered_carousel'),
      '',
    );
    expect(nonCarouselSources, isNot(contains('FrictionSimulation(')));
    expect(nonCarouselSources, isNot(contains('ScrollSpringSimulation(')));

    expect(
      preparedIndex,
      isNot(contains('.groupBy')),
      reason:
          'A prepared index must never materialize and group the full '
          'transaction list in Kotlin.',
    );
    expect(
      preparedIndex,
      isNot(contains('sumOf { it.amountScaled100 }')),
      reason: 'Child totals and counts must come from the SQL aggregate row.',
    );
    expect(
      profileHarness,
      contains('..remove(frameKey)\n    ..remove(timelineKey);'),
      reason:
          'Raw frame and VM timeline maps must not enter the bounded driver '
          'response payload.',
    );
    expect(
      profileHarness,
      isNot(contains('watchPerformance(')),
      reason:
          'Frame timing collection must not nest watchPerformance GC tracing '
          'around an explicit VM timeline session.',
    );
    expect(
      profileHarness,
      contains("streams: const <String>['GC']"),
      reason:
          'Per-scenario VM tracing must remain bounded to the GC evidence '
          'that is not already captured by explicit counters.',
    );
    expect(
      profileHarness,
      isNot(contains('pumpAndSettle(')),
      reason:
          'Live profile completion must not depend on global scheduler idle.',
    );
    expect(
      profileHarness,
      contains('Future<void>.delayed(const Duration(milliseconds: 1500))'),
      reason:
          'Profile settling must use a bounded real-time live frame window.',
    );
    expect(
      profileHarness,
      isNot(contains('jumpToIndexSilently(13)')),
      reason:
          'Cold/warm profile resets must not move the rail while leaving the '
          'visible frame on another child.',
    );
    expect(
      profileHarness,
      contains('await _resetRailToIndex(tester, controller, 13);'),
      reason:
          'First and tenth flings must start from one coherent physical and '
          'visible child frame.',
    );
    expect(
      profileHarness,
      contains('await _waitForMotionIdle(controller);'),
      reason:
          'Repeated profile flings must wait for the motion owner, not a '
          'renderer-dependent fixed delay.',
    );
    expect(
      profileHarness,
      contains('DashboardMotionActivity.idle'),
      reason:
          'The profile harness must observe the canonical motion lifecycle.',
    );
    expect(
      profileHarness,
      contains('carousel.hasActiveScrollActivity'),
      reason:
          'The profile reset must also reject a still-active Flutter '
          'ScrollActivity before retargeting the rail.',
    );
    expect(
      profileHarness,
      contains('await _waitForVisibleReset(tester, controller, entry);'),
      reason:
          'A repeated-fling reset must await the frame-coalesced preview '
          'before settle can be asserted as a visual no-op.',
    );
    expect(
      profileHarness,
      contains('!controller.frameCoalescer.hasPendingTarget'),
      reason:
          'The reset barrier must reject a still-pending display-frame target.',
    );
    expect(
      profileHarness,
      contains('DashboardProfileReport.validateMotionIsolationGate(reports);'),
      reason:
          'The A-J gate must validate data isolation and UI-isolate work while '
          'still reporting software-renderer misses.',
    );
    expect(profileHarness, contains("'rail_flight': _railFlightReport("));
    expect(profileHarness, contains('_expectEquivalentRailFlight('));
    expect(
      profileHarness,
      isNot(contains('validateNoMissedFrames')),
      reason:
          'A software rasterizer budget miss is not evidence of motion/data '
          'coupling and must not replace the causal counters.',
    );
    expect(profileWorkflow, isNot(contains('-gpu software')));
    expect(profileWorkflow, isNot(contains('-gpu lavapipe')));
    expect(profileWorkflow, isNot(contains('-gpu swiftshader')));
    expect(
      RegExp(
        r'-no-window -gpu swangle -feature -Vulkan -accel on(?:\s|$)',
      ).allMatches(profileWorkflow).length,
      2,
      reason:
          'Current and milestone profiles must use the same explicit '
          'supported software renderer and KVM acceleration path.',
    );
    expect(
      RegExp(
        r'^  run-dashboard-profile(?:-baseline)?:\n'
        r'    needs: \[test-core, test-flutter\]\n'
        r'    runs-on: ubuntu-latest$',
        multiLine: true,
      ).allMatches(profileWorkflow).length,
      2,
      reason:
          'Both profiles must run in the reproducible Linux KVM benchmark '
          'environment.',
    );
    expect(
      RegExp(r'arch: x86_64').allMatches(profileWorkflow).length,
      2,
      reason:
          'Current and milestone profiles must use the KVM-compatible x86_64 '
          'system image.',
    );
    expect(
      RegExp(r'-no-window').allMatches(profileWorkflow).length,
      2,
      reason:
          'Both CI emulators must use the same explicit headless launch mode.',
    );
    expect(
      RegExp(r'- name: Enable KVM').allMatches(profileWorkflow).length,
      2,
      reason: 'Both profile jobs must enable the same VM acceleration path.',
    );
    expect(
      RegExp(r'test -r /dev/kvm').allMatches(profileWorkflow).length,
      2,
      reason: 'Both profile jobs must fail closed when KVM is unavailable.',
    );
    expect(
      RegExp(r'sudo chmod 0666 /dev/kvm').allMatches(profileWorkflow).length,
      2,
      reason:
          'Both ephemeral runners must grant KVM access without relying on '
          'a udev daemon.',
    );
    expect(
      profileWorkflow,
      isNot(contains('udevadm')),
      reason:
          'GitHub runner images do not guarantee a live udev control socket.',
    );
    expect(
      profileWorkflow,
      isNot(contains('system_profiler SPDisplaysDataType')),
      reason: 'The Linux benchmark must not retain the failed macOS probe.',
    );
    expect(
      RegExp(r'- name: Enable KVM').allMatches(profileWorkflow).length,
      2,
      reason: 'Current and milestone jobs must share one explicit KVM setup.',
    );
    expect(
      RegExp(r'target: default').allMatches(profileWorkflow).length,
      2,
      reason:
          'Both profiles must use the minimal AOSP image without unrelated '
          'Google service workload.',
    );
    expect(
      RegExp(r'emulator-build: 15081367').allMatches(profileWorkflow).length,
      2,
      reason:
          'Current and milestone profiles must pin Android Emulator 36.5.10.',
    );
    expect(
      profileWorkflow,
      isNot(contains('ram-size: 4096M')),
      reason: 'Profile builds must not compete with a 4 GiB running emulator.',
    );
    expect(
      RegExp(r'ram-size: 2048M').allMatches(profileWorkflow).length,
      2,
      reason: 'Current and milestone profiles must use the same bounded RAM.',
    );
    expect(
      RegExp(
        'pre-emulator-launch-script: >-',
      ).allMatches(profileWorkflow).length,
      2,
      reason: 'Both profile APKs must be built before their emulator starts.',
    );
    expect(
      RegExp(r'flutter build apk --profile').allMatches(profileWorkflow).length,
      2,
      reason: 'Current and milestone profile binaries need an explicit build.',
    );
    expect(
      RegExp(
        r'FLUVI_RAIL_FLIGHT_RECORDER=true',
      ).allMatches(profileWorkflow).length,
      2,
      reason: 'Both profile binaries must enable the bounded flight recorder.',
    );
    expect(
      profileRunner,
      contains('--dart-define=FLUVI_RAIL_FLIGHT_RECORDER=true'),
      reason: 'The canonical profile drive must retain recorder configuration.',
    );
    expect(
      RegExp(
        r'--use-application-binary=build/app/outputs/flutter-apk/app-profile.apk',
      ).allMatches(profileWorkflow).length,
      2,
      reason: 'Profile drives must reuse the prebuilt APK without Gradle.',
    );
    final broadcastBarrier = profileRunner.indexOf(
      'wait-for-broadcast-barrier --flush-broadcast-loopers '
      '--flush-application-threads',
    );
    final applicationBarrier = profileRunner.indexOf(
      'wait-for-application-barrier',
    );
    final flutterDrive = profileRunner.indexOf('flutter drive');
    expect(
      broadcastBarrier,
      isNonNegative,
      reason:
          'The profile driver must flush post-boot broadcasts before launch.',
    );
    expect(
      applicationBarrier,
      greaterThan(broadcastBarrier),
      reason:
          'The profile driver must wait for application-thread configuration '
          'after the broadcast barrier.',
    );
    expect(
      flutterDrive,
      greaterThan(applicationBarrier),
      reason:
          'Flutter must launch only after Android post-boot work is stable.',
    );
    expect(
      RegExp(
        r'^\s*--no-dds\s*\\$',
        multiLine: true,
      ).allMatches(profileRunner).length,
      1,
      reason: 'The canonical profile runner must own the no-DDS launch mode.',
    );
    expect(
      profileWorkflow,
      isNot(contains('./scripts/run-dashboard-profile.sh --no-dds')),
      reason: 'Workflow jobs must not override the canonical runner flags.',
    );
    expect(
      profileRunner,
      contains('trap capture_profile_host_diagnostics EXIT'),
      reason: 'Profile exits must retain host and emulator crash evidence.',
    );
    expect(
      profileRunner,
      contains(
        'diagnostic_timeout=(timeout --signal=TERM --kill-after=2s 10s)',
      ),
      reason:
          'Crash collection must have one explicit, bounded timeout policy.',
    );
    expect(
      RegExp(
        r'"\$\{diagnostic_timeout\[@\]\}"',
      ).allMatches(profileRunner).length,
      3,
      reason:
          'Kernel, journal and adb capture must not hold the Actions job open.',
    );
    expect(
      profileRunner,
      contains(
        'profile_run_timeout=(timeout --foreground --signal=TERM '
        '--kill-after=30s 12m)',
      ),
      reason: 'A lost VM-service connection must not hold a profile job open.',
    );
    expect(
      profileRunner,
      contains(r'"${profile_run_timeout[@]}" flutter drive'),
      reason: 'The timeout must own the complete flutter drive process.',
    );
    for (final evidenceSource in <String>[
      '/sys/fs/cgroup/memory.events',
      '/proc/pressure/memory',
      'dmesg --ctime',
      '/tmp/android-runner/emu-crash-*',
      'logcat -b all -d',
    ]) {
      expect(
        profileRunner,
        contains(evidenceSource),
        reason: 'Missing profile crash evidence source: $evidenceSource',
      );
    }
    expect(
      RegExp(
        r'build/dashboard-profile-diagnostics',
      ).allMatches(profileWorkflow).length,
      2,
      reason: 'Current and milestone jobs must upload crash diagnostics.',
    );
    expect(
      baselineHarnessPatch,
      contains('diff --git a/scripts/run-dashboard-profile.sh'),
      reason:
          'The milestone benchmark must receive the same Android launch gate.',
    );
    expect(
      baselineHarnessPatch,
      contains(
        'wait-for-broadcast-barrier --flush-broadcast-loopers '
        '--flush-application-threads',
      ),
      reason:
          'Current and milestone profiles must cross the same boot barrier.',
    );
    expect(
      baselineHarnessPatch,
      contains('wait-for-application-barrier'),
      reason:
          'Current and milestone profiles must share the application barrier.',
    );
    expect(
      baselineHarnessPatch,
      contains('trap capture_profile_host_diagnostics EXIT'),
      reason: 'The milestone runner must capture the same crash evidence.',
    );
    expect(
      baselineHarnessPatch,
      contains(
        'diff --git a/android/app/src/profile/AndroidManifest.xml '
        'b/android/app/src/profile/AndroidManifest.xml',
      ),
      reason:
          'The milestone profile APK must declare its VM-service network '
          'permission.',
    );
    expect(
      baselineHarnessPatch,
      contains(
        '<uses-permission android:name="android.permission.INTERNET" />',
      ),
      reason:
          'Without INTERNET permission flutter drive cannot connect to the '
          'milestone profile VM service.',
    );
    expect(
      baselineHarnessPatch,
      contains(
        'profile_run_timeout=(timeout --foreground --signal=TERM '
        '--kill-after=30s 12m)',
      ),
      reason: 'The milestone profile must share the bounded drive lifetime.',
    );
  });
}

String _sources(Directory root, String relativePath) {
  final directory = Directory('${root.path}/$relativePath');
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

String _read(Directory root, String relativePath) =>
    File('${root.path}/$relativePath').readAsStringSync();

String _between(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start);
  expect(start, isNonNegative, reason: 'Missing source marker: $startMarker');
  expect(end, greaterThan(start), reason: 'Missing source marker: $endMarker');
  return source.substring(start, end);
}

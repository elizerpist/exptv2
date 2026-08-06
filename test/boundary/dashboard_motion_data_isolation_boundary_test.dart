import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps dashboard motion and data ownership fail closed', () {
    final root = Directory.current;
    final dashboard = _sources(root, 'lib/features/dashboard');
    final motion = _sources(root, 'lib/features/dashboard/motion');
    final presentation = _sources(root, 'lib/features/dashboard/presentation');
    final widgets = <String>[
      presentation,
      _sources(root, 'lib/features/dashboard/widgets'),
      _read(root, 'lib/core/categories/presentation/category_icon_view.dart'),
    ].join('\n');
    final readService = _read(
      root,
      'android/fluvi-core/src/main/kotlin/com/fluvi/core/query/'
      'FluviLedgerReadService.kt',
    );
    final nativePreparedIndex = _between(
      readService,
      '    suspend fun preparedDashboardIndex(',
      '    suspend fun summaryByCategory(',
    );

    for (final owner in <String>[
      'DashboardMotionKernel',
      'DashboardDataRuntime',
      'PreparedDashboardIndex',
      'DashboardPresentationController',
      'DashboardVisibleFrameStore',
      'ExplicitCommittedPagingController',
    ]) {
      expect(
        RegExp('class\\s+$owner\\b').allMatches(dashboard),
        hasLength(1),
        reason: '$owner must have exactly one production owner.',
      );
    }

    for (final forbidden in <String>[
      'Repository',
      'MethodChannel',
      'EventChannel',
      'DashboardDataRuntime',
      'PreparedDashboardIndexBuilder',
      'DashboardVisibleFrameStore',
      'DashboardLogViewportState',
      'DashboardPresentationStore',
      'DashboardLogPresentationAdapter',
      'DateFormat',
      'formatTotalMinor',
      'readChildPreviewBundle',
      'oneShotRead',
      'liveLease',
    ]) {
      expect(
        motion,
        isNot(contains(forbidden)),
        reason: 'The Motion Kernel must not depend on $forbidden.',
      );
    }

    for (final forbidden in <String>[
      'method_channel_dashboard_ledger_repository.dart',
      'dashboard_ledger_repository.dart',
      'MethodChannel(',
      'EventChannel(',
      'readChildPreviewBundle(',
      '.read(',
      '.watch(',
      'SvgPicture.asset(',
    ]) {
      expect(
        widgets,
        isNot(contains(forbidden)),
        reason:
            'Dashboard UI must render immutable state, emit intent, and use '
            'precompiled vector assets.',
      );
    }

    expect(
      nativePreparedIndex,
      isNot(
        matches(
          RegExp(
            r'(?:forEach|for\s*\()[\s\S]{0,900}(?:queryTimelinePage|queryDashboardDailyAggregates)\s*\(',
          ),
        ),
      ),
      reason: 'The global index must not issue SQL once per semantic period.',
    );

    final semanticCallbacks = <String>[
      _methodBody(
        _read(root, 'lib/features/dashboard/widgets/time_refinement_rail.dart'),
        '  void _semanticCrossed(',
        '  void _motionStarted(',
      ),
      _methodBody(
        _read(
          root,
          'lib/shared/motion/centered_carousel/'
          'centered_carousel_controller.dart',
        ),
        '  void _emitPreview(',
        '  void _emitHapticIfNeeded(',
      ),
    ].join('\n');
    expect(
      semanticCallbacks,
      isNot(
        matches(
          RegExp(
            r'\b(?:async|await|read|watch|lease|repository|MethodChannel|'
            r'EventChannel|project|format|group|sort)\b',
            caseSensitive: false,
          ),
        ),
      ),
      reason: 'Semantic crossing callbacks must be synchronous memory lookup.',
    );

    final oldProductionOwners = <String>[
      'DashboardSummaryMetricsController',
      'DashboardParentBundleRegistry',
      'DashboardPresentationStore',
      'DashboardLogPresentationAdapter',
      'DashboardAdjacentParentPrewarmCoordinator',
      'DashboardBackgroundWorkCoordinator',
      'DashboardRailMotionCoordinator',
      'CurrentQueryController',
      'DashboardLiveQueryLeaseCoordinator',
      'DashboardCommittedQueryController',
      'DashboardPreparedDeckPipeline',
      'DashboardPreparedDeckCache',
    ];
    for (final owner in oldProductionOwners) {
      expect(
        RegExp('class\\s+$owner\\b').allMatches(dashboard),
        isEmpty,
        reason: '$owner is an obsolete parallel production owner.',
      );
    }

    final logViewport = _read(
      root,
      'lib/features/dashboard/presentation/widgets/'
      'dashboard_logbox_viewport.dart',
    );
    expect(
      logViewport,
      isNot(
        matches(
          RegExp(
            r'(?:ValueKey|ObjectKey|PageStorageKey)\s*\('
            r'[^)]*(?:queryKey|scopeKey)',
            caseSensitive: false,
          ),
        ),
      ),
      reason: 'Query changes must not remount the stable LogBox viewport.',
    );

    expect(
      dashboard,
      isNot(
        matches(
          RegExp(
            r'Timer\s*\(|debounce|trailingThrottle|settleOnly|'
            r'ignoreWhileBallistic',
            caseSensitive: false,
          ),
        ),
      ),
      reason:
          'Timing and ballistic guards cannot own presentation correctness.',
    );
  });
}

String _sources(Directory root, String relativePath) {
  final directory = Directory('${root.path}/$relativePath');
  if (!directory.existsSync()) return '';
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

String _methodBody(String source, String startMarker, String endMarker) =>
    _between(source, startMarker, endMarker);

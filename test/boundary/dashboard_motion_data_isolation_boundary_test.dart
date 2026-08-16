import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'records live committed demand while deferring ready work during vertical input',
    () {
      final root = Directory.current;
      final paging = _read(
        root,
        'lib/features/dashboard/runtime/application/'
        'explicit_committed_paging_controller.dart',
      );
      final committedViewport = _read(
        root,
        'lib/features/dashboard/logbox/application/'
        'committed_log_viewport_cache.dart',
      );

      for (final forbidden in <String>[
        'shouldPauseForVerticalInput',
        'pausedForVerticalInput',
        'resumeVerticalInputPresentation',
        'publishPreparedRunway',
        'exposedFrontierOrdinal',
        'PreparedPagePreparation',
      ]) {
        expect(
          '$paging\n$committedViewport',
          isNot(contains(forbidden)),
          reason:
              'The recovered architecture has one exact ready frontier and '
              'no drag/ballistic runway publication state.',
        );
      }
      expect(paging, contains('Future<bool> prepareReadyAheadAtIdle'));
      expect(paging, contains('isVerticalInteractionActive'));
      expect(paging, contains('_CommittedPagingWorkOrigin.liveViewportDemand'));
      expect(paging, contains('bool _canRunReadyWork()'));
      expect(paging, contains('bool _canCommitCurrentPage()'));
      expect(
        paging,
        contains('!(isVerticalInteractionActive?.call() ?? false)'),
        reason:
            'Vertical input may record exact demand but must not start a new '
            'repository/page-publication pipeline in the interaction lane.',
      );
      expect(paging, isNot(contains('recordVisiblePage')));
    },
  );

  test('keeps committed page preparation free of scheduler handoffs', () {
    final cache = _read(
      Directory.current,
      'lib/features/dashboard/logbox/application/'
      'committed_log_viewport_cache.dart',
    );

    for (final forbidden in <String>[
      'SchedulerBinding',
      'scheduleTask',
      'Priority.animation',
      'frontierCritical',
      'preparedFrontier',
      'exposedFrontier',
    ]) {
      expect(cache, isNot(contains(forbidden)));
    }
    expect(cache, contains('Complete exact pages are ready geometry'));
    expect(cache, contains('bool updateForwardDemand('));
  });

  test(
    'keeps reverse committed-page demand owned by signed viewport intent',
    () {
      final root = Directory.current;
      final viewport = _read(
        root,
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_viewport.dart',
      );
      final paging = _read(
        root,
        'lib/features/dashboard/runtime/application/'
        'explicit_committed_paging_controller.dart',
      );

      expect(
        viewport,
        contains('final movingBackward ='),
        reason:
            'The viewport owns signed ScrollUpdate intent for reverse page '
            'demand.',
      );
      expect(
        viewport,
        contains(
          'notification.scrollDelta != null && notification.scrollDelta! < 0',
        ),
        reason:
            'A lower retained boundary alone is not previous-page intent; the '
            'real ScrollPosition delta must be negative.',
      );
      expect(
        viewport,
        contains('if (movingBackward &&'),
        reason:
            'Previous keyset acquisition must remain gated by reverse intent.',
      );
      expect(
        paging,
        isNot(contains('ScrollUpdateNotification')),
        reason:
            'The keyset paging owner must not duplicate presentation scroll '
            'direction detection.',
      );
    },
  );

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
    final categoryIconView = _read(
      root,
      'lib/core/categories/presentation/category_icon_view.dart',
    );
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

    for (final forbidden in <String>[
      'SvgPicture(',
      'VectorGraphic(',
      'AssetBytesLoader(',
      '.loadPicture(',
    ]) {
      expect(
        categoryIconView,
        isNot(contains(forbidden)),
        reason: 'LogBox category rows must paint a bootstrap-prepared picture.',
      );
    }

    for (final forbidden in <String>[
      'SvgPicture(',
      'VectorGraphic(',
      'AssetBytesLoader(',
      '.loadPicture(',
    ]) {
      expect(
        presentation,
        isNot(contains(forbidden)),
        reason:
            'Dashboard widgets must paint bootstrap-prepared vector pictures.',
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

    // Query state is deliberately centralized in CurrentQueryController.  It
    // replaced the legacy parallel dashboard-query owners above, so rejecting
    // it here would make this boundary test contradict the production
    // architecture it protects.
    expect(
      RegExp(r'class\s+CurrentQueryController\b').allMatches(dashboard),
      hasLength(1),
      reason: 'Dashboard must retain exactly one applied-query owner.',
    );

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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'dashboard production has one index runtime and no live/deck fallback',
    () {
      final root = Directory.current;
      final dashboard = _sources(root, 'lib/features/dashboard');
      final androidApp = _sources(
        root,
        'android/app/src/main/kotlin/com/fluvi/app',
        extension: '.kt',
      );
      final androidCore = _sources(
        root,
        'android/fluvi-core/src/main/kotlin',
        extension: '.kt',
      );
      final nativeReadService = File(
        '${root.path}/android/fluvi-core/src/main/kotlin/com/fluvi/core/query/'
        'FluviLedgerReadService.kt',
      ).readAsStringSync();
      final navigationPresentation = <String>[
        _sources(root, 'lib/features/dashboard/motion'),
        _sources(root, 'lib/features/dashboard/time_navigation'),
        _sources(root, 'lib/features/dashboard/presentation'),
        _sources(root, 'lib/features/dashboard/widgets'),
        _sources(root, 'lib/features/dashboard/visible'),
      ].join('\n');

      for (final owner in <String>[
        'DashboardDataRuntime',
        'GlobalCoreRevisionObserver',
        'PreparedDashboardIndexBuilder',
        'PreparedDashboardIndex',
        'DashboardPresentationController',
        'ExplicitCommittedPagingController',
      ]) {
        expect(
          RegExp('class\\s+$owner\\b').allMatches(dashboard),
          hasLength(1),
          reason: '$owner must have exactly one production owner',
        );
      }

      for (final forbidden in <String>[
        'DashboardPreparedLiveRepository',
        'DashboardCommittedQueryController',
        'DashboardPreparedDeckPipeline',
        'DashboardPreparedDeckCache',
        'watchCommittedFrame(',
      ]) {
        expect(
          dashboard,
          isNot(contains(forbidden)),
          reason: '$forbidden is part of the superseded dual pipeline',
        );
      }

      for (final forbidden in <String>[
        'runtime/data/',
        'dashboard_data_runtime_repository.dart',
        'MethodChannel(',
        'EventChannel(',
        'prepareIndex(',
        'readCommittedPage(',
      ]) {
        expect(
          navigationPresentation,
          isNot(contains(forbidden)),
          reason:
              '$forbidden would let navigation/presentation acquire dashboard data',
        );
      }

      expect(
        androidCore,
        isNot(contains('observeSlice(')),
        reason:
            'The retired exact-scope observer must not remain as a fallback.',
      );
      expect(
        RegExp(r'fun\s+observeCoreRevision\s*\(').allMatches(nativeReadService),
        hasLength(1),
        reason: 'Native dashboard invalidation must have one global observer.',
      );

      for (final forbidden in <String>[
        'DASHBOARD_STREAM_CHANNEL',
        'dashboard_query_stream',
        'DashboardObservationSession',
        'NATIVE_WATCH_SUBSCRIBED',
        'NATIVE_WATCH_CANCELLED',
      ]) {
        expect(
          androidApp,
          isNot(contains(forbidden)),
          reason: '$forbidden must disappear with the per-query native watch',
        );
      }
    },
  );
}

String _sources(
  Directory root,
  String relativePath, {
  String extension = '.dart',
}) {
  final directory = Directory('${root.path}/$relativePath');
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith(extension))
      .map((file) => file.readAsStringSync())
      .join('\n');
}

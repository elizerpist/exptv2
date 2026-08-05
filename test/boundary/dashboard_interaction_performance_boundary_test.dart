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
    final nativeReadService = _read(
      root,
      'android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt',
    );
    final profileHarness = _read(
      root,
      'integration_test/dashboard_interaction_profile_test.dart',
    );
    final preparedDeck = _between(
      nativeReadService,
      '    suspend fun preparedDeck(',
      '    private fun finiteChildValues(',
    );

    expect(
      RegExp(
        r'class\s+DashboardPreparedDeckCache\b',
      ).allMatches(libSources).length,
      1,
      reason: 'Complete immutable prepared decks must have one cache owner.',
    );
    expect(
      RegExp(
        r'class\s+DashboardPreparedDeckPipeline\b',
      ).allMatches(libSources).length,
      1,
      reason: 'Required and prewarm work must have one in-flight owner.',
    );
    for (final obsolete in <String>[
      'DashboardParentBundleRegistry',
      'DashboardBackgroundWorkCoordinator',
      'DashboardAdjacentParentPrewarmCoordinator',
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

    final nonCarouselSources = libSources.replaceFirst(
      _sources(root, 'lib/shared/motion/centered_carousel'),
      '',
    );
    expect(nonCarouselSources, isNot(contains('FrictionSimulation(')));
    expect(nonCarouselSources, isNot(contains('ScrollSpringSimulation(')));

    expect(
      preparedDeck,
      isNot(contains('.groupBy')),
      reason:
          'A prepared deck must never materialize and group the full '
          'parent transaction list in Kotlin.',
    );
    expect(
      preparedDeck,
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

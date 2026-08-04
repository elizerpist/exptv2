import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps dashboard interaction ownership fail closed', () {
    final root = Directory.current;
    final libSources = _sources(root, 'lib');
    final dashboardApplication = _sources(
      root,
      'lib/features/dashboard/application',
    );
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
    final childPreviewBundle = _between(
      nativeReadService,
      '    suspend fun childPreviewBundle(',
      '    private fun finiteChildValues(',
    );

    expect(
      RegExp(
        r'class\s+DashboardParentBundleRegistry\b',
      ).allMatches(libSources).length,
      1,
      reason: 'Reusable parent/child bundles must have exactly one owner.',
    );
    expect(
      RegExp(
        r'class\s+DashboardBackgroundWorkCoordinator\b',
      ).allMatches(libSources).length,
      1,
      reason: 'Refresh and prewarm jobs must have exactly one queue owner.',
    );
    expect(
      dashboardApplication.replaceFirst(
        _read(
          root,
          'lib/features/dashboard/application/dashboard_parent_bundle_registry.dart',
        ),
        '',
      ),
      isNot(
        matches(
          RegExp(
            r'(?:LinkedHashMap|Map)\s*<\s*DashboardParentBundleKey\s*,\s*DashboardParentBundleEntry',
          ),
        ),
      ),
      reason: 'No feature-local second parent bundle cache is permitted.',
    );

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
      childPreviewBundle,
      isNot(contains('.groupBy')),
      reason:
          'A child preview bundle must never materialize and group the full '
          'parent transaction list in Kotlin.',
    );
    expect(
      childPreviewBundle,
      isNot(contains('sumOf { it.amountScaled100 }')),
      reason: 'Child totals and counts must come from the SQL aggregate row.',
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

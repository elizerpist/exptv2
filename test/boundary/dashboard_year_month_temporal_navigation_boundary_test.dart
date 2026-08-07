import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps one temporal owner and a data-independent rail boundary', () {
    final root = Directory.current;
    final state = _read(
      root,
      'lib/features/dashboard/time_navigation/application/'
      'dashboard_time_navigation_state.dart',
    );
    final controller = _read(
      root,
      'lib/features/dashboard/time_navigation/application/'
      'dashboard_time_navigation_controller.dart',
    );
    final prepared = _read(
      root,
      'lib/features/dashboard/runtime/domain/prepared_presentation_frame.dart',
    );
    final rail = _read(
      root,
      'lib/features/dashboard/widgets/time_refinement_rail.dart',
    );
    final logViewport = _read(
      root,
      'lib/features/dashboard/presentation/widgets/'
      'dashboard_logbox_viewport.dart',
    );
    final presentationController = _read(
      root,
      'lib/features/dashboard/runtime/application/'
      'dashboard_presentation_controller.dart',
    );

    expect(state, contains('final DashboardTemporalAnchor temporalAnchor;'));
    for (final competingField in <String>[
      'final int yearCursor;',
      'final YearMonth monthCursor;',
      'final int dayCursor;',
      'final int retainedChildYear;',
      'final int retainedChildMonth;',
      'final int retainedChildDay;',
    ]) {
      expect(
        state,
        isNot(contains(competingField)),
        reason: '$competingField would be a second temporal source of truth.',
      );
    }
    expect(controller, contains('temporalAnchor'));
    expect(controller, isNot(contains('postFrameCallback')));
    expect(controller, isNot(contains('Future.delayed')));
    expect(controller, isNot(contains('Timer(')));
    expect(controller, isNot(contains('async ')));
    expect(controller, isNot(contains('await ')));

    final dashboardSources = root
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.contains('/lib/features/dashboard/') &&
              file.path.endsWith('.dart') &&
              !file.path.endsWith(
                'dashboard_time_navigation_controller.dart',
              ) &&
              !file.path.endsWith('dashboard_time_navigation_state.dart'),
        );
    for (final source in dashboardSources) {
      expect(
        RegExp(
          r'copyWith\(\s*temporalAnchor:',
        ).hasMatch(source.readAsStringSync()),
        isFalse,
        reason: '${source.path} would be a second temporal anchor writer.',
      );
    }

    expect(prepared, contains('final class PreparedSummaryFrame'));
    expect(prepared, contains('final class PreparedLogViewportPayload'));
    expect(prepared, contains('final PreparedSummaryFrame summary;'));
    expect(prepared, contains('final PreparedLogViewportPayload logViewport;'));
    expect(prepared, isNot(contains('operator ==')));
    expect(prepared, isNot(contains('DeepCollectionEquality')));
    expect(prepared, isNot(contains('ListEquality')));

    final crossingHotPath = _between(
      presentationController,
      'void _onSemanticCrossed(',
      'void _onSettled(',
    );
    for (final forbiddenWork in <String>[
      'toList(',
      'List.of(',
      'Map.of(',
      '.sort(',
      'format(',
      'project',
      'Future',
      'await ',
    ]) {
      expect(
        crossingHotPath,
        isNot(contains(forbiddenWork)),
        reason: 'Rail crossing hot-path work: $forbiddenWork',
      );
    }

    for (final forbiddenDependency in <String>[
      'DashboardVisibleFrame',
      'DashboardPreparedFrame',
      'DashboardLogViewportState',
      'entryCount',
      'logViewportId',
      'amountPresentationId',
    ]) {
      expect(
        rail,
        isNot(contains(forbiddenDependency)),
        reason: 'Rail presentation dependency: $forbiddenDependency',
      );
    }
    expect(logViewport, isNot(contains('shrinkWrap:')));
    expect(logViewport, isNot(contains('AnimatedSize')));
    expect(logViewport, isNot(contains('IntrinsicHeight')));
  });
}

String _read(Directory root, String path) =>
    File('${root.path}/$path').readAsStringSync();

String _between(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  expect(startIndex, isNonNegative);
  expect(endIndex, greaterThan(startIndex));
  return source.substring(startIndex, endIndex);
}

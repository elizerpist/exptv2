import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'core-mode controller stays headless and uses the existing mode ring',
    () {
      final source = _read(
        'lib/features/dashboard/application/dashboard_core_mode_controller.dart',
      );

      expect(source, contains('DashboardModeSpec.values'));
      for (final forbiddenImport in <String>[
        'runtime/data/',
        'presentation/',
        'dashboard_core_controller.dart',
        'BuildContext',
        'TickerProvider',
        'AnimationController',
        'PageView',
        'TabBarView',
      ]) {
        expect(source, isNot(contains(forbiddenImport)));
      }
      expect(
        RegExp(r'\b(?:pageIndex|currentPage|pageNumber)\b').hasMatch(source),
        isFalse,
        reason: 'The semantic ring must not grow a fake paging coordinate.',
      );
    },
  );

  test('mode host remains a bounded presentation-only domain', () {
    final source = _read(
      'lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart',
    );

    for (final forbidden in <String>[
      'PageView',
      'TabBarView',
      'IndexedStack',
      'DashboardLogBoxViewport',
      'DashboardCoreController',
      'MethodChannel',
      'EventChannel',
      'Repository',
      'Future.microtask',
      'Timer(',
      'Velocity(',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
    expect(source, contains('GestureDirectionArbiter.resolve'));
    expect(source, contains('DragStartBehavior.down'));
  });

  test('CoreDashboard hosts one mode domain outside its singleton LogBox', () {
    final source = _read(
      'lib/features/dashboard/presentation/core_dashboard.dart',
    );

    expect(source, contains('DashboardCoreModeHost'));
    expect(
      RegExp(r'\bDashboardLogBoxViewport\b').allMatches(source),
      hasLength(1),
    );
    expect(source, isNot(contains('PageView')));
    expect(source, isNot(contains('IndexedStack')));
  });

  test(
    'shell owns one stable core-mode controller beside dashboard runtime',
    () {
      final source = _read('lib/app/shell/fluvi_app_shell.dart');

      expect(
        RegExp(r'late final DashboardCoreModeController\b').allMatches(source),
        hasLength(1),
      );
      expect(source, contains('DashboardCoreModeController('));
      expect(source, contains('_modeController.dispose()'));
      expect(source, contains('modeController: _modeController'));
      expect(source, contains('CORE_MODE_TRANSITION_STARTED'));
      expect(source, contains('CORE_MODE_TRANSITION_COMMITTED'));
      expect(source, contains('CORE_MODE_TRANSITION_CANCELLED'));
    },
  );
}

String _read(String relativePath) =>
    File('${Directory.current.path}/$relativePath').readAsStringSync();

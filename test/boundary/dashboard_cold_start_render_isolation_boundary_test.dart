import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cold-start readiness has one owner and LogBox has one stable surface',
    () {
      final shell = File(
        'lib/app/shell/fluvi_app_shell.dart',
      ).readAsStringSync();
      final logBox = <String>[
        File(
          'lib/features/dashboard/presentation/widgets/'
          'dashboard_logbox_viewport.dart',
        ).readAsStringSync(),
        File(
          'lib/features/dashboard/presentation/widgets/'
          'dashboard_logbox_render_surface.dart',
        ).readAsStringSync(),
      ].join('\n');

      expect(shell, contains('DashboardInteractionReadiness'));
      expect(shell, isNot(contains('DashboardBootstrapController')));
      expect(logBox, contains('dashboard-logbox-stable-render-surface'));
      expect(logBox, isNot(contains('SliverList.builder')));
      expect(logBox, isNot(contains('SliverFillRemaining')));
      expect(logBox, isNot(contains('CategoryVisualBadge(')));
      expect(logBox, isNot(contains('addRepaintBoundaries: true')));
      expect(logBox, contains('drawImageNine('));
      expect(logBox, isNot(contains('createBoxPainter()')));
      expect(
        logBox,
        isNot(contains('PreparedVectorAssetAtlas.instance.logBoxRastersFor')),
        reason:
            'The stable surface must render the exact raster set captured by '
            'bootstrap, never calculate a second runtime cache key.',
      );
      expect(logBox, isNot(contains('onFirstFramePresented')));
    },
  );

  test('implementation contains no prohibited warmup or motion workaround', () {
    final sources = <String>[
      File('lib/app/shell/fluvi_app_shell.dart').readAsStringSync(),
      File(
        'lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart',
      ).readAsStringSync(),
      File(
        'lib/features/dashboard/presentation/widgets/'
        'dashboard_logbox_render_surface.dart',
      ).readAsStringSync(),
      File(
        'lib/features/dashboard/application/dashboard_interaction_readiness.dart',
      ).readAsStringSync(),
    ].join('\n');

    for (final prohibited in <String>[
      'IndexedStack(',
      'Offstage(',
      'Visibility(maintainState: true',
      'Timer(',
      'debounce',
      'throttle',
      'velocityMultiplier',
      'frictionMultiplier',
      'renderAfterIdle',
      'Future.delayed(',
    ]) {
      expect(sources, isNot(contains(prohibited)), reason: prohibited);
    }
  });

  test('profile fixture executes the first fling before process warmup', () {
    final profileSource = File(
      'integration_test/dashboard_interaction_profile_test.dart',
    ).readAsStringSync();
    final scenarioDeclaration = profileSource.indexOf(
      'enum _ProfileScenario {',
    );
    final firstScenario = profileSource.indexOf(
      'firstFling,',
      scenarioDeclaration,
    );
    final firstWarmableScenario = profileSource.indexOf(
      'summaryPlane,',
      scenarioDeclaration,
    );

    expect(firstScenario, isNonNegative);
    expect(
      firstScenario,
      lessThan(firstWarmableScenario),
      reason:
          'The cold-first scenario must execute before process-scoped vector, '
          'text and raster resources can be warmed by another Dashboard.',
    );
    expect(
      profileSource,
      contains('preCaptureDelay: scenario == _ProfileScenario.firstFling'),
      reason: 'The first fling must not receive a synthetic warmup delay.',
    );
    expect(
      profileSource,
      contains('dashboard_density_first_ten_fling_timelines'),
      reason:
          'Empty/populated month/day and year/month lanes must retain their '
          'first, second, fifth and tenth gesture evidence.',
    );
  });
}

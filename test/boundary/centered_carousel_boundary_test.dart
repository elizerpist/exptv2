import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps carousel motion centralized and adapters thin', () {
    final root = Directory.current;
    final shared = Directory(
      '${root.path}/lib/shared/motion/centered_carousel',
    );
    final requiredFiles = <String>[
      'centered_carousel.dart',
      'centered_carousel_controller.dart',
      'centered_carousel_physics.dart',
      'centered_carousel_spec.dart',
      'centered_carousel_metrics.dart',
      'centered_carousel_math.dart',
    ];

    for (final file in requiredFiles) {
      expect(File('${shared.path}/$file').existsSync(), isTrue, reason: file);
    }

    final timeRail = File(
      '${root.path}/lib/features/dashboard/widgets/time_refinement_rail.dart',
    ).readAsStringSync();
    final avatar = File(
      '${root.path}/lib/features/profile/widgets/avatar_carousel.dart',
    ).readAsStringSync();

    expect(timeRail, contains('CenteredCarousel<DashboardSemanticEntry>'));
    expect(timeRail, isNot(contains('dashboard_presentation_diagnostics')));
    expect(timeRail, isNot(contains('onSemanticChildCrossed')));
    expect(avatar, contains('CenteredCarousel<T>'));
    for (final adapter in [timeRail, avatar]) {
      expect(adapter, isNot(contains('ScrollController')));
      expect(adapter, isNot(contains('FrictionSimulation')));
      expect(adapter, isNot(contains('ScrollSpringSimulation')));
      expect(adapter, isNot(contains('CarouselSlider')));
      expect(adapter, isNot(contains('PageView')));
    }

    final sharedSource = shared
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(sharedSource, contains('FrictionSimulation'));
    expect(sharedSource, contains('ScrollSpringSimulation'));
  });

  test('Budget category rail is a thin shared-motion presentation adapter', () {
    final root = Directory.current;
    final rail = File(
      '${root.path}/lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart',
    ).readAsStringSync();
    final presentation = File(
      '${root.path}/lib/features/dashboard/application/dashboard_budget_presentation_controller.dart',
    ).readAsStringSync();

    expect(rail, contains('CenteredCarousel<_PreparedBudgetTargetAvatar>'));
    expect(rail, contains('budgetCategoryAvatarRail'));
    expect(rail, contains('CyclicCarouselDataSource'));
    expect(rail, isNot(contains('ScrollController')));
    expect(rail, isNot(contains('PageView')));
    expect(rail, isNot(contains('FrictionSimulation')));
    expect(rail, isNot(contains('CenterSnapScrollPhysics')));
    expect(rail, isNot(contains('Repository')));
    expect(rail, isNot(contains('CurrentQueryController')));
    expect(presentation, contains('ValueListenable<List<FluviCategory>>'));
    expect(presentation, contains('DashboardBudgetTargetCatalog'));
    expect(presentation, isNot(contains('CurrentQueryController')));
    expect(presentation, isNot(contains('QueryMenuData')));
    expect(presentation, isNot(contains('Repository')));
  });
}

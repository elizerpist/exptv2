import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Avatar transaction reuses the single Core/cache/visible/focus owners', () {
    final files = Directory('lib/features/dashboard')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final source = files.map((file) => file.readAsStringSync()).join('\n');
    for (final owner in [
      'DashboardCoreController',
      'DashboardEphemeralFocusController',
      'DashboardEphemeralFocusDeriver',
      'DashboardVisibleFrameStore',
      'DashboardBudgetPresentationController',
      'DashboardLogBoxPreparedSceneCache',
      'BudgetTargetAvatarRail',
    ]) {
      expect(
        RegExp('class\\s+$owner\\b').allMatches(source),
        hasLength(1),
        reason: owner,
      );
    }
    final coordinator = File(
      'lib/features/dashboard/application/dashboard_budget_logbox_drilldown_coordinator.dart',
    ).readAsStringSync();
    expect(coordinator, contains('onVisibleSemanticCommit:'));
    expect(
      coordinator,
      contains('presentation!.setTargetHandle(target.handle)'),
    );
    for (final forbidden in [
      'widgets.dart',
      'material.dart',
      'BuildContext',
      'Timer(',
      'Future.delayed',
      'Repository',
    ]) {
      expect(coordinator, isNot(contains(forbidden)), reason: forbidden);
    }
    final rail = File(
      'lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'prepareLiveInteractionResourceWindow(',
      'prepareIndex(',
      'readCommittedPage(',
      'Future.delayed',
      'Timer(',
      'FrictionSimulation(',
      'ScrollController(',
    ]) {
      expect(rail, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(rail, contains('CenteredCarousel<_PreparedBudgetTargetAvatar>'));
    expect(rail, contains('CyclicCarouselDataSource'));
  });
}

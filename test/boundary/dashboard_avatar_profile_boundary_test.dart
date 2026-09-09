import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('K observes production owners and validates each actual fling', () {
    final source = File(
      'integration_test/dashboard_interaction_profile_test.dart',
    ).readAsStringSync();
    expect(
      source.contains(
        'DashboardProfileReport.validateAvatarFinalTargetEvidence(',
      ),
      isTrue,
    );
    expect(
      source,
      contains("budgetAvatarFocusHotsetDiagnostics['pendingCandidate']"),
    );
    expect(source, contains("eventsFor('BUDGET_HEADER_PAINTED')"));
    expect(source, contains("eventsFor('BUDGET_PROGRESS_PAINTED')"));
    expect(source, isNot(contains('if (avatarPaints.isNotEmpty) return;')));
    final report = File(
      'integration_test/support/dashboard_profile_report.dart',
    ).readAsStringSync();
    for (final forbidden in [
      'package:flutter/',
      'dashboard_core_controller.dart',
      'DashboardLogBoxPreparedSceneCache(',
      'Timer(',
      'Future.delayed',
    ]) {
      expect(report, isNot(contains(forbidden)));
    }
  });
}

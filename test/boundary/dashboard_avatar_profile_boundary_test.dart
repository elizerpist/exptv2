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
    expect(
      'DashboardProfileReport.hasExactNonemptyAvatarPaint('.allMatches(source),
      hasLength(3),
    );
    expect(source, isNot(contains('.hasReadablePhaseAPaint')));
    for (final field in [
      'exact_renderer_all_nonempty_painted',
      'exact_paint_exact_empty',
      'exact_paint_readable_phase_a_rows_painted',
      'exact_paint_rich_phase_b_rows_painted',
      'exact_paint_core_revision',
      'visible_core_revision',
    ]) {
      expect(source, contains("'$field':"));
    }
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

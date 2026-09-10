import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile host persists raw response before fail-closed acceptance', () {
    final driver = File(
      'test_driver/dashboard_profile_driver.dart',
    ).readAsStringSync();
    expect(driver, contains('support/dashboard_profile_report.dart'));
    expect(driver, contains('writeResponseOnFailure: true'));
    expect(driver, isNot(contains('if (data == null) return;')));
    final persist = driver.indexOf('await writeResponseData(');
    final validate = driver.indexOf(
      'DashboardProfileReport.validateCompleteSuite(data)',
    );
    expect(persist, greaterThanOrEqualTo(0));
    expect(validate, greaterThan(persist));
    expect(
      driver,
      contains("testOutputFilename: 'dashboard_profile_complete_response'"),
    );
  });

  test('suite completion is written after every existing suite assertion', () {
    final source = File(
      'integration_test/dashboard_interaction_profile_test.dart',
    ).readAsStringSync();
    final main = source.substring(0, source.indexOf('\nenum _ProfileScenario'));
    final marker = main.indexOf('DashboardProfileReport.suiteCompletionKey');
    expect(
      marker,
      greaterThan(main.indexOf('validatePhysicalFrameTargets(reports)')),
    );
    expect(
      marker,
      greaterThan(main.indexOf('validateMotionIsolationGate(reports)')),
    );
    expect(
      'DashboardProfileReport.suiteCompletionKey'.allMatches(main),
      hasLength(1),
    );
    expect(main, contains("'scenario_report_keys': reports.keys.toList"));
  });

  test('suite budgets are finite and leave reporting and teardown margins', () {
    final source = File(
      'integration_test/dashboard_interaction_profile_test.dart',
    ).readAsStringSync();
    final driver = File(
      'test_driver/dashboard_profile_driver.dart',
    ).readAsStringSync();
    final script = File('scripts/run-dashboard-profile.sh').readAsStringSync();
    final workflow = File(
      '.github/workflows/fluvi-core.yml',
    ).readAsStringSync();
    final profileJob = workflow
        .split('  run-dashboard-profile:\n')[1]
        .split('    steps:')[0];
    final suiteMinutes = int.parse(
      RegExp(
        r'timeout:\s*const Timeout\(Duration\(minutes:\s*(\d+)\)\)',
      ).firstMatch(source)!.group(1)!,
    );
    final sdkMinutes = int.parse(
      RegExp(
        r'timeout:\s*const Duration\(minutes:\s*(\d+)\)',
      ).firstMatch(driver)!.group(1)!,
    );
    final shellMatch = RegExp(
      r'--kill-after=(\d+)s\s+(\d+)m',
    ).firstMatch(script)!;
    final killGraceSeconds = int.parse(shellMatch.group(1)!);
    final shellMinutes = int.parse(shellMatch.group(2)!);
    final workflowMinutes = int.parse(
      RegExp(r'timeout-minutes:\s*(\d+)').firstMatch(profileJob)!.group(1)!,
    );
    for (final budget in [
      suiteMinutes,
      sdkMinutes,
      shellMinutes,
      workflowMinutes,
    ]) {
      expect(budget, greaterThan(0));
    }
    expect(killGraceSeconds, greaterThan(0));
    expect(suiteMinutes, lessThan(sdkMinutes));
    expect(sdkMinutes, lessThan(shellMinutes));
    expect(
      shellMinutes * 60 + killGraceSeconds,
      lessThan(workflowMinutes * 60),
    );
  });

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

  test(
    'G waits for its final direction visible publication before evidence',
    () {
      final source = File(
        'integration_test/dashboard_interaction_profile_test.dart',
      ).readAsStringSync();
      final finalExpenseTap = source.indexOf(
        "await tester.tap(find.byKey(const ValueKey('fluvi-expense-button')));",
        source.indexOf(
          'final directionOnlySequence = _lastDiagnosticSequence();',
        ),
      );
      final evidence = source.indexOf(
        'final evidence = _directionCircleEvidence(',
        finalExpenseTap,
      );

      expect(finalExpenseTap, greaterThanOrEqualTo(0));
      expect(evidence, greaterThan(finalExpenseTap));
      expect(
        source.substring(finalExpenseTap, evidence),
        contains('await _waitForDirectionVisiblePublication('),
      );
      final directionWait = source.substring(
        source.indexOf(
          'Future<List<FluviDiagnosticEvent>> '
          '_waitForDirectionVisiblePublication(',
        ),
        source.indexOf('Map<String, Object?> _directionCircleEvidence('),
      );
      expect(
        directionWait,
        contains(
          'final deadline = DateTime.now().add(const Duration(seconds: 20));',
        ),
      );
    },
  );

  test('K waits for each fling-local Avatar motion transition', () {
    final source = File(
      'integration_test/dashboard_interaction_profile_test.dart',
    ).readAsStringSync();
    final fling = source.substring(
      source.indexOf('Future<void> _flingBudgetAvatar('),
      source.indexOf('Future<void> _waitForBudgetAvatarTarget('),
    );
    final motionWait = source.substring(
      source.indexOf('Future<void> _waitForBudgetAvatarMotionEnd('),
      source.indexOf('Future<Map<String, Object?>> _waitForAvatarExactPaint('),
    );

    expect(fling, isNot(contains('avatarMotionLaneObserved')));
    expect(motionWait, contains('var motionWasActive = false;'));
    expect(
      motionWait.indexOf('motionWasActive = motionWasActive || active;'),
      greaterThanOrEqualTo(0),
    );
    expect(
      motionWait.indexOf('if (motionWasActive && !active) return;'),
      greaterThan(
        motionWait.indexOf('motionWasActive = motionWasActive || active;'),
      ),
    );
  });
}

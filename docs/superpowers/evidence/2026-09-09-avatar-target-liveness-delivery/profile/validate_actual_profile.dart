import 'dart:convert';
import 'dart:io';

import 'file:///data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909/integration_test/support/dashboard_profile_report.dart';

void main(List<String> args) {
  final root = Directory(args.single);
  final files = root.listSync(recursive: true).whereType<File>().toList();
  final completeFile = files.singleWhere(
    (file) => file.path.endsWith('/dashboard_profile_complete_response.json'),
  );
  final response = Map<String, Object?>.from(jsonDecode(completeFile.readAsStringSync()) as Map);
  DashboardProfileReport.validateCompleteSuite(response);
  for (final key in [
    ...DashboardProfileReport.requiredSuiteScenarioKeys,
    DashboardProfileReport.suiteCompletionKey,
    'dashboard_profile_comparisons',
    'dashboard_avatar_final_target_evidence',
  ]) {
    final file = files.singleWhere((file) => file.path.endsWith('/dashboard_profile_$key.json'));
    final separate = jsonDecode(file.readAsStringSync());
    if (jsonEncode(separate) != jsonEncode(response[key])) {
      throw StateError('Raw full response disagrees with separately exported $key.');
    }
  }
  final firstTen = response['dashboard_first_ten_fling_timeline'];
  if (firstTen is! List || firstTen.length != 10) {
    throw StateError('Missing final ten-fling timeline.');
  }
  final densities = response['dashboard_density_first_ten_fling_timelines'];
  if (densities is! Map || densities.length != 4 ||
      densities.values.any((value) => value is! List || value.length != 10)) {
    throw StateError('Missing complete density flight timelines.');
  }
  final kFile = files.singleWhere(
    (file) => file.path.endsWith('/dashboard_profile_K_avatar_first_target.json'),
  );
  final report = Map<String, Object?>.from(jsonDecode(kFile.readAsStringSync()) as Map);
  DashboardProfileReport.validateRequiredScenarioMetrics(report);
  final evidence = Map<String, Object?>.from(report['avatar_first_target'] as Map);
  DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence);
  if (evidence['real_fling_count'] != 4) {
    throw StateError('Expected all four actual K flings.');
  }
  final finalFile = files.singleWhere(
    (file) => file.path.endsWith('/dashboard_profile_dashboard_avatar_final_target_evidence.json'),
  );
  final finalEvidence = Map<String, Object?>.from(jsonDecode(finalFile.readAsStringSync()) as Map);
  DashboardProfileReport.validateAvatarFinalTargetEvidence(finalEvidence);
  final result = <String, Object?>{
    'validation': 'passed',
    'full_response_file': completeFile.path,
    'completion': response[DashboardProfileReport.suiteCompletionKey],
    'comparisons': response['dashboard_profile_comparisons'],
    'motion_isolation': 'passed committed validateCompleteSuite',
    'first_ten_fling_count': firstTen.length,
    'density_flight_counts': {for (final entry in densities.entries) entry.key: (entry.value as List).length},
    'artifact_source_sha': '33ee878b070345c336bb73df2b087d9a63c87c5a',
    'k_report_file': kFile.path,
    'post_renderer_final_file': finalFile.path,
    'real_fling_count': evidence['real_fling_count'],
    'fixture_category_row_counts': evidence['fixture_category_row_counts'],
    'fixture_category_rows_disjoint': evidence['fixture_category_rows_disjoint'],
    'fixture_aggregate_row_count': evidence['fixture_aggregate_row_count'],
    'exact_renderer_paint_count': evidence['exact_renderer_paint_count'],
    'exact_renderer_target_handles': evidence['exact_renderer_target_handles'],
    'exact_phase_a_paint_count': evidence['exact_phase_a_paint_count'],
    'exact_phase_a_target_handles': evidence['exact_phase_a_target_handles'],
    'final_target': finalEvidence,
    'flights': evidence['flights'],
  };
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}

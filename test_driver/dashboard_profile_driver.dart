import 'package:integration_test/integration_test_driver.dart';

import '../integration_test/support/dashboard_profile_report.dart';

Future<void> main() => integrationDriver(
  // The app's finite 35-minute suite budget needs response/teardown headroom.
  timeout: const Duration(minutes: 38),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    // Preserve even null/malformed/partial responses before rejecting them.
    await writeResponseData(
      data,
      testOutputFilename: 'dashboard_profile_complete_response',
    );
    if (data != null) {
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        await writeResponseData(
          Map<String, dynamic>.from(value),
          testOutputFilename: 'dashboard_profile_${entry.key}',
        );
      }
    }
    // The SDK awaits this callback before exit(0), including false success
    // after a test_api timeout that did not become a Flutter Failure entry.
    DashboardProfileReport.validateCompleteSuite(data);
  },
);

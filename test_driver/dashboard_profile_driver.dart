import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      await writeResponseData(
        Map<String, dynamic>.from(value),
        testOutputFilename: 'dashboard_profile_${entry.key}',
      );
    }
  },
);

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_build_identity.dart';

void main() {
  test(
    'maps explicit build-purpose values to distinct diagnostic products',
    () {
      expect(
        fluviBuildPurposeFromRaw('human_diagnostic'),
        FluviBuildPurpose.humanDiagnostic,
      );
      expect(
        fluviBuildPurposeFromRaw('automated_profile_test'),
        FluviBuildPurpose.automatedProfileTest,
      );
      expect(fluviBuildPurposeFromRaw('unknown'), FluviBuildPurpose.normalApp);
    },
  );

  test('labels the human product as the normal app entrypoint', () {
    expect(
      FluviBuildPurpose.humanDiagnostic.diagnosticLabel,
      'HUMAN_DIAGNOSTIC',
    );
    expect(FluviBuildPurpose.humanDiagnostic.entrypoint, 'app');
    expect(
      FluviBuildPurpose.automatedProfileTest.diagnosticLabel,
      'AUTOMATED_PROFILE_TEST',
    );
    expect(
      FluviBuildPurpose.automatedProfileTest.entrypoint,
      'integration_test',
    );
  });

  test('rejects automation flags in a human diagnostic product', () {
    expect(
      fluviHumanBuildConfigurationIsValid(
        purpose: FluviBuildPurpose.humanDiagnostic,
        automatedScenarioRunnerPresent: false,
        automatedInputDriverActive: false,
      ),
      isTrue,
    );
    expect(
      fluviHumanBuildConfigurationIsValid(
        purpose: FluviBuildPurpose.humanDiagnostic,
        automatedScenarioRunnerPresent: true,
        automatedInputDriverActive: false,
      ),
      isFalse,
    );
    expect(
      fluviHumanBuildConfigurationIsValid(
        purpose: FluviBuildPurpose.automatedProfileTest,
        automatedScenarioRunnerPresent: true,
        automatedInputDriverActive: true,
      ),
      isTrue,
    );
  });
}

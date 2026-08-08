/// Immutable compile-time identity for a Fluvi build product.
///
/// This is diagnostic metadata only. It never starts a scenario, changes
/// navigation, or participates in the Dashboard runtime.
enum FluviBuildPurpose { normalApp, humanDiagnostic, automatedProfileTest }

const String _rawFluviBuildPurpose = String.fromEnvironment(
  'FLUVI_BUILD_PURPOSE',
  defaultValue: 'normal_app',
);

const bool kFluviAutomatedScenarioRunnerPresent = bool.fromEnvironment(
  'FLUVI_AUTOMATED_SCENARIO_RUNNER_PRESENT',
);

const bool kFluviAutomatedInputDriverActive = bool.fromEnvironment(
  'FLUVI_AUTOMATED_INPUT_DRIVER_ACTIVE',
);

FluviBuildPurpose get kFluviBuildPurpose =>
    fluviBuildPurposeFromRaw(_rawFluviBuildPurpose);

FluviBuildPurpose fluviBuildPurposeFromRaw(String raw) => switch (raw) {
  'human_diagnostic' => FluviBuildPurpose.humanDiagnostic,
  'automated_profile_test' => FluviBuildPurpose.automatedProfileTest,
  _ => FluviBuildPurpose.normalApp,
};

extension FluviBuildPurposeX on FluviBuildPurpose {
  String get diagnosticLabel => switch (this) {
    FluviBuildPurpose.normalApp => 'NORMAL_APP',
    FluviBuildPurpose.humanDiagnostic => 'HUMAN_DIAGNOSTIC',
    FluviBuildPurpose.automatedProfileTest => 'AUTOMATED_PROFILE_TEST',
  };

  String get entrypoint => switch (this) {
    FluviBuildPurpose.automatedProfileTest => 'integration_test',
    _ => 'app',
  };
}

/// A human diagnostic app must be a quiet normal app. If a build pipeline ever
/// injects automated-test flags into that product, fail at startup rather than
/// handing a self-driving APK to a person.
void verifyFluviHumanBuildIntegrity() {
  if (fluviHumanBuildConfigurationIsValid(
    purpose: kFluviBuildPurpose,
    automatedScenarioRunnerPresent: kFluviAutomatedScenarioRunnerPresent,
    automatedInputDriverActive: kFluviAutomatedInputDriverActive,
  )) {
    return;
  }
  throw StateError(
    'Human diagnostic build cannot contain an automated scenario or input '
    'driver.',
  );
}

bool fluviHumanBuildConfigurationIsValid({
  required FluviBuildPurpose purpose,
  required bool automatedScenarioRunnerPresent,
  required bool automatedInputDriverActive,
}) =>
    purpose != FluviBuildPurpose.humanDiagnostic ||
    (!automatedScenarioRunnerPresent && !automatedInputDriverActive);

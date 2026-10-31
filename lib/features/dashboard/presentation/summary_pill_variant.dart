/// Test-fixture presentation choice for the isolated Summary components.
///
/// Production always mounts the segmented presentation. The legacy value is
/// retained only so component-level regression fixtures can still measure the
/// retired rail independently of the application shell.
enum SummaryPillVariant { legacy, segmented }

extension SummaryPillVariantPresentation on SummaryPillVariant {
  String get label => switch (this) {
    SummaryPillVariant.legacy => 'Klasszikus',
    SummaryPillVariant.segmented => 'Szekciós',
  };
}

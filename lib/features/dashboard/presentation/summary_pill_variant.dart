import 'package:flutter/foundation.dart';

/// Runtime-only presentation choice for the SummaryPill comparison.
///
/// This deliberately owns no temporal, query, or Ledger state. The selected
/// implementation projects the one canonical dashboard navigation state.
enum SummaryPillVariant { legacy, segmented, swipeMode }

extension SummaryPillVariantPresentation on SummaryPillVariant {
  String get label => switch (this) {
    SummaryPillVariant.legacy => 'Klasszikus',
    SummaryPillVariant.segmented => 'Szekciós',
    SummaryPillVariant.swipeMode => 'Swipe mód',
  };
}

/// Dashboard-lifetime, session-only owner for the experiment choice.
///
/// There is no existing settings persistence owner for this development
/// comparison, so persistence would be a separate product decision.
final class SummaryPillVariantController
    extends ValueNotifier<SummaryPillVariant> {
  SummaryPillVariantController() : super(SummaryPillVariant.legacy);

  void select(SummaryPillVariant variant) {
    if (value != variant) value = variant;
  }
}

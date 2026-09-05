import 'package:flutter/foundation.dart';

/// Runtime-only presentation choice for the SummaryPill comparison.
///
/// This deliberately owns no temporal, query, or Ledger state. The selected
/// implementation projects the one canonical dashboard navigation state.
enum SummaryPillVariant { legacy, segmented }

extension SummaryPillVariantPresentation on SummaryPillVariant {
  String get label => switch (this) {
    SummaryPillVariant.legacy => 'Klasszikus',
    SummaryPillVariant.segmented => 'Szekciós',
  };
}

/// Dashboard-lifetime, session-only owner for the experiment choice.
///
/// There is no existing settings persistence owner for this development
/// comparison, so persistence would be a separate product decision.
final class SummaryPillVariantController
    extends ValueNotifier<SummaryPillVariant> {
  SummaryPillVariantController() : super(SummaryPillVariant.legacy);

  int _transitionEpoch = 0;

  /// Monotonically identifies a real presentation-adapter replacement.
  ///
  /// It deliberately has no query, navigation, or data authority. Consumers
  /// use it only to reject callbacks emitted by a disposed adapter.
  int get transitionEpoch => _transitionEpoch;

  void select(SummaryPillVariant variant) {
    if (value == variant) return;
    _transitionEpoch += 1;
    value = variant;
  }
}

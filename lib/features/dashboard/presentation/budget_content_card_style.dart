import 'package:flutter/foundation.dart';

/// The two intentionally comparable Budget content compositions.
///
/// This is presentation only: avatar selection, page selection, query state
/// and LogBox focus remain owned by their existing controllers.
enum BudgetContentLayout {
  split('Szétválasztva'),
  unifiedCard('Közös kártya');

  const BudgetContentLayout(this.label);

  final String label;
}

/// Dashboard-lifetime, session-only owner for Budget content composition.
///
/// The historical boolean allowed a cardless diagram. That is deliberately no
/// longer representable: [split] keeps Card2 and [unifiedCard] moves both
/// authored content regions inside one common outer surface.
final class BudgetContentCardStyleController
    extends ValueNotifier<BudgetContentLayout> {
  BudgetContentCardStyleController() : super(BudgetContentLayout.split);

  void select(BudgetContentLayout layout) {
    if (value != layout) value = layout;
  }
}

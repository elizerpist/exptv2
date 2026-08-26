import 'package:flutter/foundation.dart';

/// Dashboard-lifetime, session-only presentation choice for Budget Card2.
///
/// This intentionally owns only Card2 chrome. Budget selection, PageView,
/// query and LogBox state all remain in their existing controllers.
final class BudgetContentCardStyleController extends ValueNotifier<bool> {
  BudgetContentCardStyleController() : super(true);

  bool get showCardSurface => value;

  void setShowCardSurface(bool showCardSurface) {
    if (value != showCardSurface) value = showCardSurface;
  }
}

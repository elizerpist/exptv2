import 'package:flutter/foundation.dart';

/// Single compile-time policy for every onscreen diagnostics producer and UI.
const bool kFluviOnscreenDiagnosticsEnabled =
    kDebugMode || bool.fromEnvironment('FLUVI_ONSCREEN_DIAGNOSTICS');

@visibleForTesting
bool fluviOnscreenDiagnosticsEnabledFor({
  required bool debugMode,
  required bool requestedByCompileTimeFlag,
}) => debugMode || requestedByCompileTimeFlag;

import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';

/// Intentionally non-interactive visual placeholder for the future add flow.
class FluviCenterFab extends StatelessWidget {
  const FluviCenterFab({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        key: const ValueKey('fluvi-center-fab'),
        button: true,
        enabled: false,
        label: 'Új tranzakció',
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: FluviVisualTokens.navigationFabGradient,
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: FluviVisualTokens.centerFabSize,
            height: FluviVisualTokens.centerFabSize,
            child: Icon(
              Icons.add_rounded,
              color: FluviVisualTokens.textOnAction,
              size: FluviVisualTokens.navigationIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

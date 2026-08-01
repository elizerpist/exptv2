import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../core/platform/fullscreen_controller.dart';

class FluviFullscreenButton extends StatelessWidget {
  const FluviFullscreenButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Teljes képernyő',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('fluvi-fullscreen-button'),
          borderRadius: BorderRadius.circular(14),
          onTap: toggleFullscreen,
          child: Container(
            width: FluviVisualTokens.fullscreenButtonSize,
            height: FluviVisualTokens.fullscreenButtonSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.fullscreen_rounded,
              color: FluviVisualTokens.navigationInactiveIcon,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

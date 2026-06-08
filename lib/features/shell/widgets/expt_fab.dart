import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';

class ExptFab extends StatefulWidget {
  const ExptFab({
    super.key,
    required this.onPressed,
    this.primaryColor = AppColors.primary,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.onLongPress,
  });

  final VoidCallback onPressed;
  final Color primaryColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final VoidCallback? onLongPress;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  @override
  Widget build(BuildContext context) {
    final materialFeedback = ExpenseSurface.materialFeedbackEnabled(
      widget.surfaceStyle,
    );
    return ExpensePressable(
      enabled: widget.surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        return ExpenseSurfaceContainer(
          surfaceKey: const ValueKey('expt-fab'),
          style: widget.surfaceStyle,
          color: widget.primaryColor,
          borderRadius: BorderRadius.circular(AppDimensions.fabSize / 2),
          pressed: pressed,
          primary: true,
          primaryColor: widget.primaryColor,
          width: AppDimensions.fabSize,
          height: AppDimensions.fabSize,
          neutralShadow: const [
            BoxShadow(
              color: AppColors.fabShadow,
              offset: Offset(0, 5),
              blurRadius: 12,
            ),
          ],
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkResponse(
              containedInkWell: true,
              customBorder: const CircleBorder(),
              overlayColor: materialFeedback
                  ? null
                  : ExpenseSurface.transparentOverlayColor,
              splashColor: materialFeedback ? null : Colors.transparent,
              highlightColor: materialFeedback
                  ? Colors.white30
                  : Colors.transparent,
              onTap: _handleTap,
              onLongPress: _handleLongPress,
              child: Icon(
                Icons.add,
                color: AppColors.white,
                size: AppDimensions.fabSize * AppDimensions.fabIconScale,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    DebugConsole.log('[FAB] single tap immediate dispatch');
    widget.onPressed();
  }

  void _handleLongPress() {
    DebugConsole.log('[FAB] long press dispatch');
    widget.onLongPress?.call();
  }
}

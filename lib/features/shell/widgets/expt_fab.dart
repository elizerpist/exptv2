import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class ExptFab extends StatefulWidget {
  const ExptFab({
    super.key,
    required this.onPressed,
    this.onLongPress,
  });

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('expt-fab'),
      dimension: AppDimensions.fabSize,
      child: Material(
        color: AppColors.primary,
        elevation: 5,
        shadowColor: AppColors.fabShadow,
        shape: const CircleBorder(),
        child: InkResponse(
          containedInkWell: true,
          customBorder: const CircleBorder(),
          highlightColor: Colors.white30,
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
